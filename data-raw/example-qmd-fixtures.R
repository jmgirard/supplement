# Writes tests/testthat/fixtures/example-qmd/<commit>.qmd: each version of
# inst/template/analyses/example.qmd that the default branch has held,
# byte for byte. Run from the package root in a clone with full history:
#   Rscript data-raw/example-qmd-fixtures.R
# The commits are those that `git log --follow` lists up to 6873c34, the
# default branch on 2026-10-26. Each version ends in one line break, which
# `writeLines()` restores. `example_versions` in R/check-supplement.R holds
# the `text_hash()` of each one.

file <- "inst/template/analyses/example.qmd"
out <- file.path("tests", "testthat", "fixtures", "example-qmd")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
commits <- system2("git", c("log", "--follow", "--format=%h", "6873c34", "--", file), stdout = TRUE)
for (commit in commits) {
  bytes <- system2("git", c("show", paste0(commit, ":", file)), stdout = TRUE)
  writeLines(bytes, file.path(out, paste0(commit, ".qmd")), sep = "\n", useBytes = TRUE)
}
