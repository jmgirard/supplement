doi_badge_rx <- function(doi) {
  paste0(
    '<a [^>]*href="https://doi\\.org/', rx_escape(doi), '"[^>]*>\\s*',
    '<img [^>]*src="https://zenodo\\.org/badge/DOI/', rx_escape(doi), '\\.svg"'
  )
}

render_doi_page <- function(zenodo) {
  dir <- shortcode_site(
    zenodo,
    list("index.qmd" = "BEFORE {{< supplement-doi >}} MID {{< supplement-download >}} AFTER"),
    env = parent.frame()
  )
  rendered <- run_split(dir, "quarto", "render")
  list(status = rendered$status, stderr = rendered$stderr,
       html = if (rendered$status == 0L) read_text(file.path(dir, "docs", "index.html")) else "")
}

test_that("the DOI badge shows the version DOI, then the concept DOI", {
  skip_if_no_quarto()

  both <- render_doi_page(zenodo_yaml(version = "10.5281/zenodo.222", concept = "10.5281/zenodo.111"))
  expect_equal(both$status, 0L)
  expect_match(both$html, doi_badge_rx("10.5281/zenodo.222"), perl = TRUE)
  expect_no_match(both$html, "zenodo.111", fixed = TRUE)

  concept <- render_doi_page(zenodo_yaml(concept = "10.5281/zenodo.111"))
  expect_equal(concept$status, 0L)
  expect_match(concept$html, doi_badge_rx("10.5281/zenodo.111"), perl = TRUE)
})

test_that("empty DOI and archive values render nothing", {
  skip_if_no_quarto()

  empty <- render_doi_page(zenodo_yaml())
  expect_equal(empty$status, 0L)
  expect_match(empty$html, "BEFORE\\s+MID\\s+AFTER", perl = TRUE)
  expect_no_match(empty$html, "zenodo.org/badge", fixed = TRUE)
})

test_that("the download link points at the archive", {
  skip_if_no_quarto()

  url <- "https://zenodo.org/records/12345"
  page <- render_doi_page(zenodo_yaml(archive = url))
  expect_equal(page$status, 0L)
  expect_match(page$html, paste0('MID\\s*<a [^>]*href="', rx_escape(url), '"'), perl = TRUE)
  # With no DOI, the badge is still left out.
  expect_match(page$html, "BEFORE\\s+MID", perl = TRUE)
})

# File sizes from the size rule, stated apart from the code that applies it.
size_cases <- c(
  "0" = "0 B", "999" = "999 B", "1000" = "1.0 KB", "1500" = "1.5 KB",
  "999950" = "1.0 MB", "7690465" = "7.7 MB", "1000000000" = "1.0 GB"
)

write_size_fixture <- function(path, bytes) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  if (bytes < 1e8) {
    writeBin(raw(bytes), path)
  } else {
    # A sparse file: seek past the end and write one byte.
    con <- file(path, "wb")
    seek(con, bytes - 1, rw = "write")
    writeBin(as.raw(0), con)
    close(con)
  }
  stopifnot(file.size(path) == bytes)
}

test_that("the data table lists each file with its size and a page-relative link", {
  skip_if_no_quarto()

  size_files <- sprintf("sizes/f%s.bin", names(size_cases))
  files <- c("data/example.csv", size_files)
  dir <- shortcode_site(
    data_yaml(files),
    list("index.qmd" = "{{< supplement-data-table >}}",
         "analyses/page.qmd" = "{{< supplement-data-table >}}")
  )
  dir.create(file.path(dir, "data"))
  file.copy(file.path(template_dir(), "data", "example.csv"), file.path(dir, "data"))
  for (i in seq_along(size_cases)) {
    write_size_fixture(file.path(dir, size_files[i]), as.numeric(names(size_cases)[i]))
  }

  rendered <- run_split(dir, "quarto", "render")
  expect_equal(rendered$status, 0L)
  expect_true(file.exists(file.path(dir, "docs", "data", "example.csv")))

  expected_sizes <- c(paste(file.size(file.path(template_dir(), "data", "example.csv")), "B"),
                      unname(size_cases))
  for (page in c("index.html", "analyses/page.html")) {
    prefix <- if (page == "index.html") "" else "../"
    rows <- data_table_rows(read_text(file.path(dir, "docs", page)))
    expect_length(rows, length(files))
    for (i in seq_along(files)) {
      cells <- rows[[i]]
      expect_length(cells, 3)
      link_rx <- paste0('<a (?=[^>]*\\bdownload\\b)[^>]*href="', rx_escape(paste0(prefix, files[i])), '"')
      expect_match(cells[1], link_rx, perl = TRUE, info = page)
      expect_match(cells[1], paste0("<code>", rx_escape(basename(files[i])), "</code>"), info = page)
      expect_equal(cells[2], paste("About", basename(files[i])), info = page)
      expect_equal(cells[3], expected_sizes[i], info = page)
    }
  }
})

test_that("a description that names a folder is shown as written on a subfolder page", {
  skip_if_no_quarto()

  # Quarto rewrites a metadata value that names an existing path, so on a
  # page in analyses/ the description "data" would arrive as "../data".
  dir <- shortcode_site(
    c("data:", '  - file: "data/example.csv"', '    description: "data"'),
    list("analyses/page.qmd" = "{{< supplement-data-table >}}")
  )
  dir.create(file.path(dir, "data"))
  file.copy(file.path(template_dir(), "data", "example.csv"), file.path(dir, "data"))

  expect_equal(run_split(dir, "quarto", "render")$status, 0L)
  rows <- data_table_rows(read_text(file.path(dir, "docs", "analyses", "page.html")))
  expect_length(rows, 1)
  expect_equal(rows[[1]][2], "data")
})

test_that("a missing data file stops the render and names the file", {
  skip_if_no_quarto()

  dir <- shortcode_site(
    data_yaml(c("data/example.csv", "data/not_here_42.csv")),
    list("index.qmd" = "{{< supplement-data-table >}}",
         "analyses/page.qmd" = "{{< supplement-data-table >}}")
  )
  dir.create(file.path(dir, "data"))
  file.copy(file.path(template_dir(), "data", "example.csv"), file.path(dir, "data"))

  rendered <- run_split(dir, "quarto", "render")
  expect_true(rendered$status != 0L)
  expect_match(rendered$stderr, "supplement-data-table: data file not found: 'data/not_here_42.csv'",
               fixed = TRUE)
})

test_that("values set in _supplement.yml reach the home page", {
  skip_if_no_quarto()
  dir <- withr::local_tempdir("site-")
  expect_equal(use_template(dir)$status, 0L)

  yml <- file.path(dir, "_supplement.yml")
  new <- c(
    "paper-title" = "Zebra Paper 2071",
    "citation" = "Quill Q 1999 Something Cited",
    "version-doi" = "10.5281/zenodo.98765"
  )
  for (key in names(new)) set_supplement_value(yml, key, new[[key]])

  expect_equal(run_in(dir, "quarto", "render")$status, 0L)
  html <- read_text(file.path(dir, "docs", "index.html"))
  for (value in new) expect_match(html, value, fixed = TRUE)
  expect_match(html, doi_badge_rx(new[["version-doi"]]), perl = TRUE)
})

test_that("the template home page reads its values from _supplement.yml", {
  skip_if_no_quarto()

  index <- read_text(file.path(template_dir(), "index.qmd"))
  yml <- file.path(template_dir(), "_supplement.yml")
  for (key in c("paper-title", "citation")) {
    original <- supplement_value(yml, key)
    expect_true(nzchar(original))
    expect_false(grepl(original, index, fixed = TRUE), info = key)
  }
  for (code in c("{{< supplement-doi >}}", "{{< supplement-download >}}", "{{< supplement-data-table >}}",
                 "{{< meta supplement.paper-title >}}", "{{< meta supplement.citation >}}")) {
    expect_match(index, code, fixed = TRUE)
  }
  for (key in c("version-doi", "concept-doi", "archive-url")) {
    expect_equal(supplement_value(yml, key), "", info = key)
  }
  expect_match(read_text(file.path(template_dir(), "_quarto.yml")),
               "metadata-files:\\s*\\n\\s*- _supplement\\.yml", perl = TRUE)
})

test_that("a new site shows no DOI badge and lists the example data", {
  skip_if_no_quarto()
  site <- site_copy()

  html <- read_text(file.path(site$dir, "docs", "index.html"))
  expect_no_match(html, "zenodo.org/badge", fixed = TRUE)
  rows <- data_table_rows(html)
  file_cells <- vapply(rows, `[`, "", 1)
  expect_true(any(grepl('<a (?=[^>]*\\bdownload\\b)[^>]*href="data/example\\.csv"', file_cells, perl = TRUE)))
  expect_true(file.exists(file.path(site$dir, "docs", "data", "example.csv")))
})
