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
  skip_if_no_quarto(needs_r = FALSE)

  both <- render_doi_page(zenodo_yaml(version = "10.5281/zenodo.222", concept = "10.5281/zenodo.111"))
  expect_equal(both$status, 0L)
  expect_match(both$html, doi_badge_rx("10.5281/zenodo.222"), perl = TRUE)
  expect_no_match(both$html, "zenodo.111", fixed = TRUE)

  concept <- render_doi_page(zenodo_yaml(concept = "10.5281/zenodo.111"))
  expect_equal(concept$status, 0L)
  expect_match(concept$html, doi_badge_rx("10.5281/zenodo.111"), perl = TRUE)
})

test_that("the DOI badge removes a doi: or doi.org link prefix", {
  skip_if_no_quarto(needs_r = FALSE)

  bare <- "10.5281/zenodo.333"
  prefixes <- c("https://doi.org/", "https://www.doi.org/", "http://dx.doi.org/",
                "doi:", "doi: ", "HTTPS://DOI.ORG/")
  for (prefix in prefixes) {
    page <- render_doi_page(zenodo_yaml(version = paste0(prefix, bare)))
    expect_equal(page$status, 0L, info = paste(prefix, page$stderr))
    expect_match(page$html, doi_badge_rx(bare), perl = TRUE, info = prefix)
  }

  # The concept DOI gets the same treatment.
  page <- render_doi_page(zenodo_yaml(concept = paste0("https://doi.org/", bare)))
  expect_equal(page$status, 0L, info = page$stderr)
  expect_match(page$html, doi_badge_rx(bare), perl = TRUE)
})

test_that("a DOI value that is not a DOI stops the render and names the field", {
  skip_if_no_quarto(needs_r = FALSE)

  good <- "10.5281/zenodo.111"
  # A prefix with no DOI after it does not fall back to the other DOI.
  page <- render_doi_page(zenodo_yaml(version = "doi:", concept = good))
  expect_false(page$status == 0L)
  expect_match(page$stderr, "supplement-doi: supplement.zenodo.version-doi ", fixed = TRUE)

  # The value that the badge does not show is checked too.
  page <- render_doi_page(zenodo_yaml(version = good, concept = "10.528/zenodo.1"))
  expect_false(page$status == 0L)
  expect_match(page$stderr, "supplement-doi: supplement.zenodo.concept-doi ", fixed = TRUE)

  page <- render_doi_page(c("zenodo:", paste0("  version-doi: [", good, "]")))
  expect_false(page$status == 0L)
  expect_match(page$stderr, "supplement-doi: supplement.zenodo.version-doi ", fixed = TRUE)
})

test_that("empty DOI and archive values render nothing", {
  skip_if_no_quarto(needs_r = FALSE)

  empty <- render_doi_page(zenodo_yaml())
  expect_equal(empty$status, 0L)
  expect_match(empty$html, "BEFORE\\s+MID\\s+AFTER", perl = TRUE)
  expect_no_match(empty$html, "zenodo.org/badge", fixed = TRUE)
})

test_that("the download link points at the archive", {
  skip_if_no_quarto(needs_r = FALSE)

  url <- "https://zenodo.org/records/12345"
  page <- render_doi_page(zenodo_yaml(archive = url))
  expect_equal(page$status, 0L)
  expect_match(page$html, paste0('MID\\s*<a [^>]*href="', rx_escape(url), '"'), perl = TRUE)
  # With no DOI, the badge is still left out.
  expect_match(page$html, "BEFORE\\s+MID", perl = TRUE)
})

render_license_page <- function(supplement) {
  dir <- shortcode_site(
    supplement,
    list("index.qmd" = "BEFORE {{< supplement-license code >}} MID {{< supplement-license content >}} AFTER"),
    env = parent.frame()
  )
  rendered <- run_split(dir, "quarto", "render")
  list(status = rendered$status, stderr = rendered$stderr,
       html = if (rendered$status == 0L) read_text(file.path(dir, "docs", "index.html")) else "")
}

license_yaml <- function(code, content) {
  c("license:", sprintf('  code: "%s"', code), sprintf('  content: "%s"', content))
}

test_that("the license shortcode shows readable names for listed ids in any letter case", {
  skip_if_no_quarto(needs_r = FALSE)

  page <- render_license_page(license_yaml("CC-BY-4.0", "cc0-1.0"))
  expect_equal(page$status, 0L, info = page$stderr)
  expect_equal(between_markers(page$html), "BEFORE CC BY 4.0 MID CC0 1.0 AFTER")

  page <- render_license_page(license_yaml("Cc-By-Sa-4.0", "mIT"))
  expect_equal(page$status, 0L, info = page$stderr)
  expect_equal(between_markers(page$html), "BEFORE CC BY-SA 4.0 MID MIT AFTER")
})

test_that("the license shortcode shows an unlisted id as written", {
  skip_if_no_quarto(needs_r = FALSE)

  page <- render_license_page(license_yaml("EUPL-1.2", "GPL-2.0+"))
  expect_equal(page$status, 0L, info = page$stderr)
  expect_equal(between_markers(page$html), "BEFORE EUPL-1.2 MID GPL-2.0+ AFTER")
})

test_that("the license shortcode shows nothing for an empty value or no license map", {
  skip_if_no_quarto(needs_r = FALSE)

  empty <- render_license_page(license_yaml("", ""))
  expect_equal(empty$status, 0L, info = empty$stderr)
  expect_equal(between_markers(empty$html), "BEFORE MID AFTER")

  absent <- render_license_page('paper-title: "A title"')
  expect_equal(absent$status, 0L, info = absent$stderr)
  expect_equal(between_markers(absent$html), "BEFORE MID AFTER")

  # An empty list or map is empty, as it is for write_citation().
  for (empty_value in c("[]", "{}")) {
    page <- render_license_page(c("license:", paste("  code:", empty_value), paste("  content:", empty_value)))
    expect_equal(page$status, 0L, info = paste(empty_value, page$stderr))
    expect_equal(between_markers(page$html), "BEFORE MID AFTER", info = empty_value)
  }
})

# A license map with `value`, a line of YAML, in `field`, and MIT in the
# other field.
license_field_yaml <- function(field, value) {
  other <- setdiff(c("code", "content"), field)
  c("license:", paste0("  ", field, ": ", value), paste0("  ", other, ': "MIT"'))
}

# The render stopped with a message from the license shortcode that names
# `text`.
expect_license_stop <- function(page, text, info) {
  expect_false(page$status == 0L, info = info)
  expect_match(page$stderr, "supplement-license:", fixed = TRUE, info = info)
  expect_match(page$stderr, text, fixed = TRUE, info = info)
}

test_that("a license value that is not one SPDX id stops the render and names the field", {
  skip_if_no_quarto(needs_r = FALSE)

  shapes <- c(
    "a list of two ids" = "[MIT, Apache-2.0]",
    "a map" = "{name: MIT}",
    "a space" = '"CC BY 4.0"',
    "two hyphens" = '"GPL--3.0"',
    "three dots" = '"MIT..."',
    "Markdown emphasis" = '"*MIT*"',
    "a code span" = '"`MIT`"'
  )
  for (field in c("code", "content")) {
    for (shape in names(shapes)) {
      info <- paste(field, shape)
      page <- render_license_page(license_field_yaml(field, shapes[[shape]]))
      expect_license_stop(page, paste0("supplement.license.", field, " "), info)
    }
  }
})

test_that("the license shortcode stops unless its one argument is code or content", {
  skip_if_no_quarto(needs_r = FALSE)

  calls <- c("{{< supplement-license >}}", "{{< supplement-license other >}}",
             "{{< supplement-license code content >}}")
  for (call in calls) {
    dir <- shortcode_site(license_yaml("MIT", "CC-BY-4.0"), list("index.qmd" = call))
    page <- run_split(dir, "quarto", "render")
    expect_license_stop(page, "one argument, code or content", call)
  }
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
  skip_if_no_quarto(needs_r = FALSE)

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
  skip_if_no_quarto(needs_r = FALSE)

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

test_that("a folded YAML description is shown as one line of text", {
  skip_if_no_quarto(needs_r = FALSE)

  dir <- shortcode_site(
    c("data:", '  - file: "data/example.csv"', "    description: >", "      Scores from the",
      "      example study", '  - file: "data/example.csv"', "    description: true"),
    list("index.qmd" = "{{< supplement-data-table >}}")
  )
  dir.create(file.path(dir, "data"))
  file.copy(file.path(template_dir(), "data", "example.csv"), file.path(dir, "data"))

  rendered <- run_split(dir, "quarto", "render")
  expect_equal(rendered$status, 0L, info = rendered$stderr)
  rows <- data_table_rows(read_text(file.path(dir, "docs", "index.html")))
  expect_length(rows, 2)
  expect_equal(rows[[1]][2], "Scores from the example study")
  expect_equal(rows[[2]][2], "true")
})

test_that("data files in a read-only folder are found from a subfolder page", {
  skip_if_no_quarto(needs_r = FALSE)
  skip_on_os("windows")

  dir <- shortcode_site(
    data_yaml("data/example.csv"),
    list("analyses/page.qmd" = "{{< supplement-data-table >}}")
  )
  dir.create(file.path(dir, "data"))
  file.copy(file.path(template_dir(), "data", "example.csv"), file.path(dir, "data"))
  Sys.chmod(file.path(dir, "data"), "0555")
  withr::defer(Sys.chmod(file.path(dir, "data"), "0755"))

  rendered <- run_split(dir, "quarto", "render")
  expect_equal(rendered$status, 0L, info = rendered$stderr)
  rows <- data_table_rows(read_text(file.path(dir, "docs", "analyses", "page.html")))
  expect_length(rows, 1)
  expect_match(rows[[1]][1], 'href="../data/example.csv"', fixed = TRUE)
})

test_that("a folder listed as a data file stops the render", {
  skip_if_no_quarto(needs_r = FALSE)

  dir <- shortcode_site(data_yaml("data"), list("index.qmd" = "{{< supplement-data-table >}}"))
  dir.create(file.path(dir, "data"))
  file.copy(file.path(template_dir(), "data", "example.csv"), file.path(dir, "data"))

  rendered <- run_split(dir, "quarto", "render")
  expect_true(rendered$status != 0L)
  expect_match(rendered$stderr, "supplement-data-table: 'data' is a folder, not a file", fixed = TRUE)
})

test_that("a missing data file stops the render and names the file", {
  skip_if_no_quarto(needs_r = FALSE)

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
  # The shortcode itself stops the render, not a later Lua error.
  expect_no_match(rendered$stderr, "attempt to", fixed = TRUE)
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

footer_center <- function(html) {
  m <- regmatches(html, regexpr('<div class="nav-footer-center">[\\s\\S]*?</div>', html, perl = TRUE))
  if (length(m) == 0) "" else m
}

test_that("the page footer shows the licenses set in _supplement.yml", {
  skip_if_no_quarto()
  dir <- withr::local_tempdir("site-")
  expect_equal(use_template(dir)$status, 0L)

  yml <- file.path(dir, "_supplement.yml")
  set_supplement_value(yml, "code", "CC0-1.0")
  set_supplement_value(yml, "content", "CC-BY-SA-4.0")

  rendered <- run_in(dir, "quarto", "render")
  expect_equal(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))
  for (page in c("index.html", "analyses/example.html")) {
    footer <- footer_center(read_text(file.path(dir, "docs", page)))
    expect_match(footer, "CC0 1.0", fixed = TRUE, info = page)
    expect_match(footer, "CC BY-SA 4.0", fixed = TRUE, info = page)
    expect_no_match(footer, "MIT", fixed = TRUE, info = page)
    expect_no_match(footer, "CC BY 4.0", fixed = TRUE, info = page)
    expect_match(footer, "/LICENSE.md", fixed = TRUE, info = page)
    expect_match(footer, "/LICENSE-CC-BY.md", fixed = TRUE, info = page)
  }
})

test_that("the template home page reads its values from _supplement.yml", {
  skip_if_no_quarto(needs_r = FALSE)

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
