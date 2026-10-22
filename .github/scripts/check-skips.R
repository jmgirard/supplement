# R CMD check prints the test output only when a test fails, but it keeps
# that output in tests/testthat.Rout (testthat.Rout.fail after a failure).
# This script prints the skipped tests from that file and fails when a test
# skipped because a tool is missing, so the tests run once in each job.
#
# Usage: Rscript check-skips.R <the tests folder of supplement.Rcheck>

missing_tool <- c(
  "On CRAN", "quarto is not on PATH", "git is not on PATH",
  "git is not on the PATH", "git --version fails", "knitr cannot be loaded",
  "rmarkdown cannot be loaded", "cannot make a symbolic link here",
  "R has no png device",
  # skip_if_not_installed() names the package in braces.
  "{knitr}", "{rmarkdown}", "{sessioninfo}"
)

args <- commandArgs(trailingOnly = TRUE)
dir <- if (length(args) > 0) args[[1]] else "check/supplement.Rcheck/tests"
candidates <- file.path(dir, c("testthat.Rout.fail", "testthat.Rout"))
found <- candidates[file.exists(candidates)]
if (length(found) == 0) {
  stop("No test output: neither ", paste(candidates, collapse = " nor "), " exists.", call. = FALSE)
}
file <- found[[1]]
lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
lines <- gsub("\033\\[[0-9;]*m", "", lines)

summary_rx <- "^\\[ FAIL [0-9]+ \\| WARN [0-9]+ \\| SKIP ([0-9]+) \\| PASS ([0-9]+) \\]$"
summaries <- grep(summary_rx, trimws(lines), value = TRUE)
if (length(summaries) == 0) {
  stop(file, " has no testthat summary line.", call. = FALSE)
}
last <- summaries[[length(summaries)]]
n_skip <- as.integer(sub(summary_rx, "\\1", last))
n_pass <- as.integer(sub(summary_rx, "\\2", last))
cat(file, ": ", last, "\n", sep = "")
if (n_pass == 0L) stop("No test passed.", call. = FALSE)

# testthat's check reporter writes one bullet per skip reason,
# "<bullet> <reason> (<count>): <locations>", wrapped with a two-space
# indent, under a "Skipped tests" rule and up to the next blank line.
bullet_rx <- "^[*•] "
reasons <- character()
counts <- integer()
start <- grep("Skipped tests (", lines, fixed = TRUE)
if (length(start) > 0) {
  section <- lines[-seq_len(start[[length(start)]])]
  blank <- which(trimws(section) == "")
  if (length(blank) > 0) section <- section[seq_len(blank[[1]] - 1L)]
  cat(section, sep = "\n")
  items <- character()
  for (line in section) {
    if (grepl(bullet_rx, line, perl = TRUE)) {
      items <- c(items, line)
    } else if (length(items) > 0) {
      items[[length(items)]] <- paste(items[[length(items)]], trimws(line))
    }
  }
  item_rx <- paste0(bullet_rx, "(.*) \\(([0-9]+)\\): .*$")
  parsed <- grepl(item_rx, items, perl = TRUE)
  if (!all(parsed)) {
    stop("Cannot read these skip lines:\n", paste(items[!parsed], collapse = "\n"), call. = FALSE)
  }
  reasons <- sub(item_rx, "\\1", items, perl = TRUE)
  counts <- as.integer(sub(item_rx, "\\2", items, perl = TRUE))
}
if (sum(counts) != n_skip) {
  stop("The skip lines count ", sum(counts), " skips, but the summary line counts ", n_skip, ".",
       call. = FALSE)
}

bad <- Reduce(`|`, lapply(missing_tool, grepl, x = reasons, fixed = TRUE), logical(length(reasons)))
if (any(bad)) {
  stop(sum(counts[bad]), " tests skipped because a tool is missing: ",
       paste(reasons[bad], collapse = "; "), call. = FALSE)
}
cat(n_skip, "tests skipped, none because a tool is missing.\n")
