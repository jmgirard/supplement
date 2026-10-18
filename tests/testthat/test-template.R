test_that("a new site renders and holds its setup files", {
  skip_if_no_quarto()
  site <- rendered_site()

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
  site <- rendered_site()

  page <- read_text(file.path(site$dir, "docs", "analyses", "example.html"))
  header <- quarto_header(page)
  expect_match(header, 'href="../index.html"', fixed = TRUE)

  frozen <- list.files(file.path(site$dir, "_freeze", "analyses", "example"), recursive = TRUE)
  expect_gt(length(frozen), 0)
})

test_that("the project freezes output and renders into docs", {
  skip_if_no_quarto()
  site <- rendered_site()

  inspect <- run_in(site$dir, "quarto", "inspect")
  json <- paste(inspect$output, collapse = "\n")
  expect_match(json, '"freeze":\\s*true')
  expect_match(json, '"output-dir":\\s*"docs"')
})

test_that("a full render with R unreachable runs no report code", {
  skip_if_no_quarto()
  skip_if(file.exists("/usr/bin/R") || file.exists("/bin/R"), "R is in /usr/bin or /bin")
  site <- rendered_site()

  page <- file.path(site$dir, "docs", "analyses", "example.html")
  before <- readBin(page, "raw", file.info(page)$size)

  quarto <- unname(Sys.which("quarto"))
  no_r <- run_in(
    site$dir, "env",
    c("-i", paste0("HOME=", shQuote(Sys.getenv("HOME"))), "PATH=/usr/bin:/bin", shQuote(quarto), "render")
  )
  expect_equal(no_r$status, 0L)

  after <- readBin(page, "raw", file.info(page)$size)
  expect_identical(after, before)
})

test_that(".gitignore blocks fit files and keeps published output", {
  skip_if_no_quarto()
  skip_if(Sys.which("git") == "", "git is not on PATH")
  site <- rendered_site()

  run_in(site$dir, "git", c("init", "-q"))
  ignored <- run_in(site$dir, "git", c("check-ignore", "analyses/fits/m.rds", "x.rds"))
  expect_setequal(ignored$output, c("analyses/fits/m.rds", "x.rds"))

  kept <- run_in(
    site$dir, "git",
    c("check-ignore", "_freeze/analyses/example/execute-results/html.json", "docs/index.html", "data/example.csv")
  )
  expect_equal(kept$status, 1L)
  expect_length(kept$output, 0)
})

test_that("setup keeps an existing .gitignore", {
  skip_if_no_quarto()
  dir <- withr::local_tempdir("site-")
  expect_equal(use_template(dir)$status, 0L)
  writeLines("mine", file.path(dir, ".gitignore"))

  expect_equal(run_in(dir, "quarto", "render")$status, 0L)
  # Quarto itself appends its own entries; the template's entries must not
  # replace or join the user's file.
  kept <- readLines(file.path(dir, ".gitignore"))
  expect_equal(kept[1], "mine")
  expect_false("*.rds" %in% kept)
  expect_false(file.exists(file.path(dir, "_gitignore")))
})
