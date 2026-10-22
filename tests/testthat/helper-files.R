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

# Expect `err` to say that a path is a link, and not to suggest
# `overwrite = TRUE`.
expect_link_message <- function(err, info = NULL) {
  expect_match(conditionMessage(err), "is\\s+a\\s+link", info = info)
  expect_match(conditionMessage(err), "Remove\\s+the\\s+link", info = info)
  expect_no_match(conditionMessage(err), "overwrite", fixed = TRUE, info = info)
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

# Folder names that unlink() reads as patterns that match "sitea". Windows
# does not allow `?` or `*` in a file name.
pattern_names <- function() {
  if (.Platform$OS.type == "windows") "site[ab]" else c("site[ab]", "site?", "site*")
}

# The 22 ASCII names that Windows reserves for devices, written here and not
# read from the package, and every letter-case spelling of each one.
windows_device_names <- c(
  "con", "prn", "aux", "nul", paste0("com", 1:9), paste0("lpt", 1:9)
)
case_spellings <- function(x) {
  chars <- strsplit(x, "")[[1]]
  options <- lapply(chars, function(ch) unique(c(tolower(ch), toupper(ch))))
  grid <- expand.grid(options, stringsAsFactors = FALSE)
  apply(grid, 1, paste, collapse = "")
}
windows_device_spellings <- function() {
  unlist(lapply(windows_device_names, case_spellings), use.names = FALSE)
}

# A new site made by create_supplement() in a temporary folder.
new_site <- function(env = parent.frame()) {
  site <- withr::local_tempdir("site-", .local_envir = env)
  suppressMessages(create_supplement(site))
  site
}

# A path for a marker file in a new temporary folder, with `/` between
# its parts, so that it can go in a double-quoted YAML string on Windows.
expr_marker <- function(env = parent.frame()) {
  dir <- withr::local_tempdir("expr-", .local_envir = env)
  marker <- file.path(normalizePath(dir, winslash = "/"), "ran")
  # A quote in the path would break the value that expr_value() writes, and
  # a test would then pass without reaching the `!expr` code.
  expect_false(grepl("['\"]", marker))
  marker
}

# A YAML `!expr` value. Run as code, it makes `marker` and gives `text`.
expr_value <- function(marker, text) {
  sprintf("!expr \"c(file.create('%s'), '%s')[2]\"", marker, text)
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
