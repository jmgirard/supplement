# Helpers for tests that compare files before and after a function runs.

read_bytes <- function(path) readBin(path, "raw", file.size(path))

# The relative paths and bytes of every file and folder under `dir`, or
# NULL when `dir` does not exist.
folder_state <- function(dir) {
  if (!file.exists(dir)) {
    return(NULL)
  }
  if (!dir.exists(dir)) {
    return(list(file = readBin(dir, "raw", file.size(dir))))
  }
  paths <- sort(list.files(dir, recursive = TRUE, all.files = TRUE, no.. = TRUE, include.dirs = TRUE))
  lapply(stats::setNames(paths, paths), function(p) {
    full <- file.path(dir, p)
    if (dir.exists(full)) "<folder>" else readBin(full, "raw", file.size(full))
  })
}

# Check that `after` is `before` with one run of lines added, and return
# the added lines.
added_lines <- function(before, after) {
  n <- length(after) - length(before)
  expect_gt(n, 0)
  i <- which(c(after[seq_along(before)] != before, TRUE))[1]
  expect_identical(after[-seq.int(i, i + n - 1)], before)
  after[seq.int(i, i + n - 1)]
}

# The list at `path` in YAML text, read with the yaml package. A step is a
# key, or a list(key, value) that picks the item whose map has that value.
yaml_list <- function(lines, path) {
  doc <- yaml::yaml.load(paste(lines, collapse = "\n"))
  for (step in path) {
    doc <- if (is.character(step)) {
      doc[[step]]
    } else {
      Filter(function(x) identical(x[[step$key]], step$value), doc)[[1]]
    }
  }
  doc
}

# A new site made by create_supplement() in a temporary folder.
new_site <- function(env = parent.frame()) {
  site <- withr::local_tempdir("site-", .local_envir = env)
  suppressMessages(create_supplement(site))
  site
}

# Values that YAML can read as something other than the text, or that
# need escapes in a double-quoted string.
probe_values <- c(
  plain = "Model comparison",
  specials = "A \"quoted\": #1 \\ it's",
  no = "No",
  number = "1.10",
  dash = "- starts with a dash",
  bracket = "[starts with a bracket",
  star = "*starts with a star",
  non_ascii = "Résumé des données 中文"
)

lines_utf8 <- function(path) readLines(path, encoding = "UTF-8", warn = FALSE)
