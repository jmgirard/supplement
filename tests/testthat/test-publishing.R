# The local steps of vignettes/publishing.Rmd, in its order: make the site
# in a clone, render, commit, render again after a report changes, and
# render again after the DOIs are added.

test_that("the publishing guide's local steps give a site that Pages can serve and that renders changes", {
  skip_if_no_quarto()
  skip_if_no_git()
  local_plain_git()
  commit <- c("-c", "user.name=Test", "-c", "user.email=test@example.com",
              "-c", "commit.gpgsign=false", "commit", "-q", "-m")

  # A clone of an empty GitHub repository holds only .git/.
  site <- long_dir(withr::local_tempdir("site-"))
  expect_status(git_in(site, c("init", "-q")))
  suppressMessages(create_supplement(site, repo = "owner/name"))
  expect_status(run_in(site, "quarto", "render"))
  expect_status(git_in(site, c("add", "-A")))
  expect_status(git_in(site, c(commit, "Site")))
  tree <- git_in(site, c("ls-tree", "-r", "--name-only", "HEAD"))
  expect_status(tree)
  expect_contains(tree$output, c("docs/index.html", "docs/.nojekyll"))

  # The printed value is built at run time, so the page holds it only in
  # the chunk's output, never in its code.
  report <- file.path(site, "analyses", "example.qmd")
  page <- file.path(site, "docs", "analyses", "example.html")
  shown <- function() read_text(page)
  marker_chunk <- function(value) {
    c("", "```{r}", "#| label: walk-marker", sprintf('cat(paste0("walk-", "%s"))', value), "```")
  }
  original <- readLines(report)
  writeLines(c(original, marker_chunk("old")), report)
  expect_status(run_in(site, "quarto", c("render", "analyses/example.qmd")))
  expect_status(run_in(site, "quarto", "render"))
  expect_match(shown(), "walk-old", fixed = TRUE)

  writeLines(c(original, marker_chunk("new")), report)
  expect_status(run_in(site, "quarto", "render"))
  expect_match(shown(), "walk-old", fixed = TRUE)
  expect_no_match(shown(), "walk-new", fixed = TRUE)

  expect_status(run_in(site, "quarto", c("render", "analyses/example.qmd")))
  expect_status(run_in(site, "quarto", "render"))
  expect_match(shown(), "walk-new", fixed = TRUE)
  expect_no_match(shown(), "walk-old", fixed = TRUE)

  doi <- "10.5281/zenodo.1234567"
  set_supplement_value(file.path(site, "_supplement.yml"), "version-doi", doi)
  expect_status(run_in(site, "quarto", "render"))
  expect_match(read_text(file.path(site, "docs", "index.html")), doi_badge_rx(doi), perl = TRUE)
})
