test_that("a site with an added report and data file renders and lists both", {
  skip_if_no_quarto()
  site <- new_site()
  title <- "Model Comparison"
  description <- "Fits and compares the models."
  data_description <- "Scores of each participant"
  scores <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(data.frame(id = 1:3, score = c(4, 7, 5)), scores, row.names = FALSE)
  suppressMessages({
    add_report("models", title, description, path = site)
    add_data(scores, data_description, path = site)
  })

  rendered <- run_in(site, "quarto", "render")
  expect_equal(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))

  html <- read_text(file.path(site, "docs", "index.html"))
  reports <- listing_rows(html)
  hit <- Filter(function(row) identical(row$cells, c(title, description)), reports)
  expect_length(hit, 1)
  expect_true(any(grepl("(^|/)analyses/models\\.html$", hit[[1]]$links)))

  data_rows <- lapply(data_table_rows(html), strip_tags)
  expect_true(any(vapply(data_rows, function(cells) {
    identical(cells[1:2], c(basename(scores), data_description))
  }, logical(1))))
  expect_true(file.exists(file.path(site, "docs", "data", basename(scores))))

  # The links in the Analyses dropdown, in order.
  menu <- regmatches(html, regexpr('<ul class="dropdown-menu" aria-labelledby="nav-menu-analyses">[\\s\\S]*?</ul>', html, perl = TRUE))
  expect_length(menu, 1)
  links <- regmatches(menu, gregexpr('href="[^"]*"', menu))[[1]]
  expect_identical(links, c('href="./analyses/example.html"', 'href="./analyses/models.html"'))
  expect_true(file.exists(file.path(site, "docs", "analyses", "models.html")))
})

test_that("a render by name clears the stale-output row that a changed report gives", {
  skip_if_no_quarto()
  site <- new_site()
  stale <- function() {
    result <- suppressMessages(check_supplement(site))
    result$file[result$check == "stale-output"]
  }
  render <- function(...) {
    rendered <- run_in(site, "quarto", c("render", ...))
    expect_identical(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))
  }
  render()
  expect_identical(stale(), character())

  report <- file.path(site, "analyses", "example.qmd")
  bytes <- readBin(report, "raw", file.size(report))
  writeBin(c(bytes, charToRaw("\nOne more line.\n")), report)
  expect_identical(stale(), "analyses/example.qmd")
  render("analyses/example.qmd")
  expect_identical(stale(), character())

  # Quarto hashes a CR LF report as its LF text.
  bytes <- readBin(report, "raw", file.size(report))
  bytes <- bytes[bytes != as.raw(13)]
  at_lf <- bytes == as.raw(10)
  crlf <- unlist(lapply(seq_along(bytes), function(i) if (at_lf[i]) as.raw(c(13, 10)) else bytes[i]))
  writeBin(crlf, report)
  expect_true(any(crlf == as.raw(13)))
  render("analyses/example.qmd")
  expect_identical(stale(), character())

  # Quarto hashes only the report, not the files it includes.
  writeBin(charToRaw("Included text.\n"), file.path(site, "analyses", "_part.qmd"))
  writeBin(charToRaw("---\ntitle: Include\n---\n\n```{r}\n1 + 1\n```\n\n{{< include _part.qmd >}}\n"),
           file.path(site, "analyses", "with-include.qmd"))
  render("analyses/with-include.qmd")
  expect_true(dir.exists(file.path(site, "_freeze", "analyses", "with-include", "execute-results")))
  expect_identical(stale(), character())
  writeBin(charToRaw("Other included text.\n"), file.path(site, "analyses", "_part.qmd"))
  expect_identical(stale(), character())
})

test_that("the stale-output row names the stored output of a dropped format until it is deleted", {
  skip_if_no_quarto()
  site <- new_site()
  render <- function(...) {
    rendered <- run_in(site, "quarto", c("render", ...))
    expect_identical(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))
  }
  rows <- function() {
    result <- suppressMessages(check_supplement(site))
    result[result$check == "stale-output", , drop = FALSE]
  }
  report <- file.path(site, "analyses", "formats.qmd")
  body <- "---\n\n```{r}\n1 + 1\n```\n"
  writeBin(charToRaw(paste0("---\ntitle: Formats\nformat:\n  html: default\n  docx: default\n", body)), report)
  render("analyses/formats.qmd")
  render()
  docx_json <- "_freeze/analyses/formats/execute-results/docx.json"
  expect_true(file.exists(file.path(site, docx_json)))
  expect_true(file.exists(file.path(site, "docs", "analyses", "formats.docx")))
  expect_identical(nrow(rows()), 0L)

  writeBin(charToRaw(paste0("---\ntitle: Formats\nformat: html\n", body)), report)
  render("analyses/formats.qmd")
  # Quarto 1.10.19 keeps the stored output of a format that the report no
  # longer renders.
  expect_true(file.exists(file.path(site, docx_json)))
  hint <- "so these files can be from a format that the report no longer renders"
  stale <- rows()
  expect_identical(stale$file, "analyses/formats.qmd")
  expect_match(stale$problem, paste0(": ", docx_json, ". "), fixed = TRUE)
  expect_match(stale$problem, hint, fixed = TRUE)

  render()
  expect_true(file.exists(file.path(site, docx_json)))
  expect_identical(rows()$file, "analyses/formats.qmd")

  expect_true(file.remove(file.path(site, docx_json)))
  render()
  expect_false(file.exists(file.path(site, "docs", "analyses", "formats.docx")))
  expect_identical(nrow(rows()), 0L)
})

test_that("a render by name or a full render clears the unpublished-figure row of a new figure", {
  skip_if_no_quarto()
  site <- new_site()
  unpublished <- function() {
    result <- suppressMessages(check_supplement(site))
    result$file[result$check == "unpublished-figure"]
  }
  render <- function(...) {
    rendered <- run_in(site, "quarto", c("render", ...))
    expect_identical(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))
  }
  render()
  expect_identical(unpublished(), character())

  # A figure saved under a new name after a render, as from a chunk run in
  # an IDE.
  writeBin(as.raw(1:8), file.path(site, "figures", "new.png"))
  expect_identical(unpublished(), "figures/new.png")
  render("analyses/example.qmd")
  expect_identical(unpublished(), character())

  writeBin(as.raw(1:9), file.path(site, "figures", "later.png"))
  expect_identical(unpublished(), "figures/later.png")
  # Quarto also copies a hidden figure, which the check does not compare.
  writeBin(as.raw(1:7), file.path(site, "figures", ".hidden.png"))
  render()
  expect_identical(unpublished(), character())
  expect_true(file.exists(file.path(site, "docs", "figures", ".hidden.png")))
})

test_that("the guide's steps after a rename give the page its new name and keep the menu link", {
  skip_if_no_quarto()
  site <- new_site()
  suppressMessages(add_report("models", "Models", path = site))
  render <- function() {
    rendered <- run_in(site, "quarto", "render")
    expect_identical(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))
  }
  broken <- function() {
    result <- suppressMessages(check_supplement(site))
    result$problem[result$check == "broken-link"]
  }
  rename <- function(from, to) {
    file.rename(file.path(site, "analyses", paste0(from, ".qmd")),
                file.path(site, "analyses", paste0(to, ".qmd")))
  }
  frozen <- function(name) dir.exists(file.path(site, "_freeze", "analyses", name))
  render()
  expect_true(frozen("models"))

  # The steps of "How the site renders", with no render before them.
  expect_true(rename("models", "comparison"))
  unlink(file.path(site, "_freeze", "analyses", "models"), recursive = TRUE, expand = FALSE)
  replace_in_file(file.path(site, "_quarto.yml"), "analyses/models.qmd", "analyses/comparison.qmd")
  render()
  pages <- list.files(file.path(site, "docs", "analyses"))
  expect_contains(pages, "comparison.html")
  expect_false("models.html" %in% pages)
  expect_true(frozen("comparison"))
  expect_identical(broken(), character())

  # A rename alone keeps the old stored output and leaves the menu item
  # linking the old file.
  expect_true(rename("comparison", "results"))
  render()
  expect_true(frozen("comparison"))
  expect_true(any(grepl("analyses/comparison.qmd", broken(), fixed = TRUE)))
})

test_that("the guide's steps after a deletion remove the page and keep the report's figure", {
  skip_if_no_quarto()
  site <- new_site()
  suppressMessages(add_report("trends", "Trends", path = site))
  report <- file.path(site, "analyses", "trends.qmd")
  replace_in_file(report, "set.seed(2026)\n```\n", paste0(
    "set.seed(2026)\n```\n\n```{r}\n",
    "writeBin(as.raw(1:8), file.path(site, \"figures\", \"trends.png\"))\n```\n"
  ))
  render <- function() {
    rendered <- run_in(site, "quarto", "render")
    expect_identical(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))
  }
  rows <- function(check) {
    result <- suppressMessages(check_supplement(site))
    result$file[result$check == check]
  }
  frozen <- file.path(site, "_freeze", "analyses", "trends")
  # The figure is new to the first render, so the second publishes it.
  render()
  render()
  expect_true(file.exists(file.path(site, "docs", "figures", "trends.png")))

  # A deletion without the guide's step for _freeze/ keeps the folder in
  # Quarto 1.10.19.
  expect_true(file.remove(report))
  replace_in_file(file.path(site, "_quarto.yml"),
                  '          - href: "analyses/trends.qmd"\n            text: "Trends"\n', "")
  render()
  expect_identical(rows("leftover-output"),
                   if (dir.exists(frozen)) "_freeze/analyses/trends" else character())

  unlink(frozen, recursive = TRUE, expand = FALSE)
  render()
  expect_false(file.exists(file.path(site, "docs", "analyses", "trends.html")))
  expect_true(file.exists(file.path(site, "figures", "trends.png")))
  expect_true(file.exists(file.path(site, "docs", "figures", "trends.png")))
  expect_identical(rows("broken-link"), character())
  expect_identical(rows("leftover-output"), character())
})
