# These tests read the package's R files, which R CMD check does not keep
# beside the tests, so they skip there. The R-CMD-check workflow runs this
# file from the source tree in a step of its own.

test_that("git runs only through its helper", {
  r_dir <- test_path("..", "..", "R")
  skip_if_not(dir.exists(r_dir), "the package source is not here")
  files <- list.files(r_dir, pattern = "\\.[Rr]$", full.names = TRUE)
  hits <- character()
  for (file in files) {
    lines <- readLines(file, warn = FALSE)
    found <- grep("system\\(|system2\\(|shell\\(|pipe\\(|processx|callr|sys::", lines)
    hits <- c(hits, sprintf("%s:%d: %s", basename(file), found, trimws(lines[found])))
  }
  expect_length(hits, 1L)
  expect_match(hits, "^check-supplement\\.R:[0-9]+: .*system2\\(")
})

test_that("release_supplement() starts no process of its own", {
  source <- test_path("..", "..", "R", "release-supplement.R")
  skip_if_not(file.exists(source), "the package source is not here")
  rx <- "\\b(git_run|git_files|system2?|processx|callr|shell|pipe)\\s*(::|\\()"
  lines <- readLines(source)
  expect_gt(length(lines), 0)
  expect_false(any(grepl(rx, lines, perl = TRUE)))
  # The pattern finds the git helper where it is called.
  expect_true(any(grepl(rx, readLines(test_path("..", "..", "R", "check-supplement.R")), perl = TRUE)))
})
