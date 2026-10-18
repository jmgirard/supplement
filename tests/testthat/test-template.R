test_that("a new site renders and holds its setup files", {
  skip_if_no_quarto()
  site <- site_copy()

  expect_equal(site$used$status, 0L)
  expect_equal(site$rendered$status, 0L)

  expected <- c(
    ".gitignore", "README.md", "index.qmd", "analyses/example.qmd",
    "data/example.csv", "LICENSE.md", "LICENSE-CC-BY.md", "docs/.nojekyll"
  )
  expect_true(all(file.exists(file.path(site$dir, expected))))
  expect_false(file.exists(file.path(site$dir, "_gitignore")))
  expect_false(file.exists(file.path(site$dir, "_README.md")))
})

test_that("report pages carry the site navbar and stored output", {
  skip_if_no_quarto()
  site <- site_copy()

  page <- read_text(file.path(site$dir, "docs", "analyses", "example.html"))
  header <- quarto_header(page)
  expect_match(header, 'href="../index.html"', fixed = TRUE)

  frozen <- list.files(file.path(site$dir, "_freeze", "analyses", "example"), recursive = TRUE)
  expect_gt(length(frozen), 0)
})

test_that("the project freezes output and renders into docs", {
  skip_if_no_quarto()
  site <- site_copy()

  inspect <- run_in(site$dir, "quarto", "inspect")
  json <- paste(inspect$output, collapse = "\n")
  expect_match(json, '"freeze":\\s*true')
  expect_match(json, '"output-dir":\\s*"docs"')
})

test_that("a full render with R unreachable runs no report code", {
  skip_if_no_quarto()
  skip_on_os("windows")
  skip_if(any(file.exists(c("/usr/bin/R", "/bin/R", "/usr/bin/Rscript", "/bin/Rscript"))),
          "R is in /usr/bin or /bin")
  site <- site_copy()

  page <- file.path(site$dir, "docs", "analyses", "example.html")
  before <- readBin(page, "raw", file.info(page)$size)
  frozen <- list.files(file.path(site$dir, "_freeze"), recursive = TRUE, full.names = TRUE)
  frozen_times <- file.info(frozen)$mtime

  quarto <- unname(Sys.which("quarto"))
  no_r <- run_in(
    site$dir, "env",
    c("-i", paste0("HOME=", shQuote(Sys.getenv("HOME"))), "PATH=/usr/bin:/bin", shQuote(quarto), "render")
  )
  expect_equal(no_r$status, 0L)

  after <- readBin(page, "raw", file.info(page)$size)
  expect_identical(after, before)
  expect_identical(file.info(frozen)$mtime, frozen_times)
})

test_that(".gitignore blocks fit files and keeps published output", {
  skip_if_no_quarto()
  skip_if_no_git()
  site <- site_copy()

  git_in(site$dir, c("init", "-q"))
  ignored <- git_in(site$dir, c("check-ignore", "analyses/fits/m.rds", "x.rds"))
  expect_setequal(ignored$output, c("analyses/fits/m.rds", "x.rds"))

  kept <- git_in(
    site$dir,
    c("check-ignore", "_freeze/analyses/example/execute-results/html.json", "docs/index.html", "data/example.csv")
  )
  expect_equal(kept$status, 1L)
  expect_length(kept$output, 0)
})

test_that("setup adds the template rules to an existing .gitignore", {
  skip_if_no_quarto()
  dir <- withr::local_tempdir("site-")
  expect_equal(use_template(dir)$status, 0L)
  writeLines("mine", file.path(dir, ".gitignore"))

  expect_equal(run_in(dir, "quarto", "render")$status, 0L)
  kept <- readLines(file.path(dir, ".gitignore"))
  expect_equal(kept[1], "mine")
  expect_true(all(c("*.rds", "analyses/fits/") %in% kept))
  expect_equal(sum(kept == "*.rds"), 1L)
  expect_false(file.exists(file.path(dir, "_gitignore")))
})

test_that("a docs/ rule in an existing .gitignore does not hide the site", {
  skip_if_no_quarto()
  skip_if_no_git()
  dir <- withr::local_tempdir("site-")
  expect_equal(use_template(dir)$status, 0L)
  # GitHub's R .gitignore template ignores docs/.
  writeLines(c(".Rhistory", "docs/"), file.path(dir, ".gitignore"))

  expect_equal(run_in(dir, "quarto", "render")$status, 0L)
  git_in(dir, c("init", "-q"))
  kept <- git_in(dir, c("check-ignore", "docs/index.html", "_freeze/analyses/example/execute-results/html.json"))
  expect_equal(kept$status, 1L)
})

test_that("fit files stay ignored when git init comes before the first render", {
  skip_if_no_quarto()
  skip_if_no_git()
  dir <- withr::local_tempdir("site-")
  expect_equal(use_template(dir)$status, 0L)
  git_in(dir, c("init", "-q"))

  expect_equal(run_in(dir, "quarto", "render")$status, 0L)
  ignored <- git_in(dir, c("check-ignore", "analyses/fits/m.rds", "x.rds"))
  expect_setequal(ignored$output, c("analyses/fits/m.rds", "x.rds"))
})

test_that("setup keeps an existing README.md and writes the guide beside it", {
  skip_if_no_quarto()
  dir <- withr::local_tempdir("site-")
  expect_equal(use_template(dir)$status, 0L)
  writeLines("my readme", file.path(dir, "README.md"))

  expect_equal(run_in(dir, "quarto", "render")$status, 0L)
  expect_equal(readLines(file.path(dir, "README.md")), "my readme")
  expect_true(file.exists(file.path(dir, "SUPPLEMENT.md")))
  expect_false(file.exists(file.path(dir, "_README.md")))
})
