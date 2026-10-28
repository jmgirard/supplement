# The local steps of vignettes/publishing.Rmd, in its order: make the site,
# render it with render_supplement(), commit, render again after a report
# changes, and render again after the DOIs are added. The guide commits in
# the Git pane, so the test commits with git.

test_that("the publishing guide's local steps give a site that Pages can serve and that renders changes", {
  skip_if_no_quarto()
  skip_if_no_git()
  local_plain_git()
  # git before 2.32 reads the user's global configuration, so the commit
  # sets its own signing and hooks.
  hooks <- long_dir(withr::local_tempdir("hooks-"))
  commit <- c("-c", "user.name=Test", "-c", "user.email=test@example.com",
              "-c", "commit.gpgsign=false", "-c", paste0("core.hooksPath=", hooks),
              "commit", "-q", "-m")

  site <- file.path(long_dir(withr::local_tempdir("site-")), "my-supplement")
  suppressMessages(create_supplement(site, repo = "owner/name"))
  expect_identical(render_quiet(path = site), "quarto render")
  # usethis::use_git() starts the repository and commits the site.
  expect_status(git_in(site, c("init", "-q")))
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
  render_quiet("example", path = site)
  expect_match(shown(), "walk-old", fixed = TRUE)

  writeLines(c(original, marker_chunk("new")), report)
  render_quiet(path = site)
  expect_match(shown(), "walk-old", fixed = TRUE)
  expect_no_match(shown(), "walk-new", fixed = TRUE)

  render_quiet("example", path = site)
  expect_match(shown(), "walk-new", fixed = TRUE)
  expect_no_match(shown(), "walk-old", fixed = TRUE)

  doi <- "10.5281/zenodo.1234567"
  set_supplement_value(file.path(site, "_supplement.yml"), "version-doi", doi)
  render_quiet(path = site)
  expect_match(read_text(file.path(site, "docs", "index.html")), doi_badge_rx(doi), perl = TRUE)
})
