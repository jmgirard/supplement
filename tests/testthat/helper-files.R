# Helpers for tests that compare files before and after a function runs.

read_bytes <- function(path) readBin(path, "raw", file.size(path))

# The time bound for a test that times a call, 5 times larger on Windows.
# One check_supplement() call took 10.91 s on windows-latest and 2.33 s on
# macOS, 4.7 times as long (M076). The test "pages with many comments,
# elements, and script state changes are read in time" took 10.19 s there
# in CI run 40953514637 (2026-10-29) and 4.06 s on macOS (M076 review), 2.5
# times as long, and failed its 10 s bound.
time_bound <- function(seconds) {
  if (.Platform$OS.type == "windows") seconds * 5 else seconds
}

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

# Expect `err` to say that a path is a link and to run `fn` again, and
# not to suggest `overwrite = TRUE`.
expect_link_message <- function(err, fn, info = NULL) {
  expect_match(conditionMessage(err), "is\\s+a\\s+link", info = info)
  expect_match(conditionMessage(err), paste0("Remove\\s+the\\s+link,\\s+then\\s+run\\s+`", fn, "\\(\\)`\\s+again"),
               info = info)
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

# Replace each `from` with its `to` in a file, keeping its other bytes.
replace_in_file <- function(file, from, to) {
  text <- rawToChar(readBin(file, "raw", file.size(file)))
  for (i in seq_along(from)) text <- gsub(from[i], to[i], text, fixed = TRUE, useBytes = TRUE)
  writeBin(charToRaw(text), file)
}

# Replace the template placeholders that check_supplement() gives a
# "placeholder" row for with values of a real site. A blank line at the end
# of each example file keeps the example's results. Call it before a render
# or a stored hash, since it changes the example report.
fill_placeholders <- function(site) {
  replace_in_file(
    file.path(site, "_supplement.yml"),
    c("Title of the paper", "Author, A. A., & Author, B. B.", "Your Name, Your Institution. Your email address.",
      'family: "Author"', 'given: "A. A."', 'given: "B. B."'),
    c("Effects of sleep", "Doe, J., & Roe, S.", "Jane Doe, University A.",
      'family: "Doe"', 'given: "Jane"', 'given: "Sam"')
  )
  replace_in_file(file.path(site, "_quarto.yml"), "OWNER/REPO", "jdoe/sleep")
  replace_in_file(file.path(site, "index.qmd"), "## Before your first commit", "## About this site")
  for (file in c("LICENSE.md", "LICENSE-CC-BY.md")) {
    replace_in_file(file.path(site, file), "YEAR AUTHORS", "2026 Jane Doe")
  }
  for (file in file.path(site, c("_README.md", "README.md", "SUPPLEMENT.md"))) {
    if (file.exists(file)) replace_in_file(file, "OWNER.github.io/REPO/", "jdoe.github.io/sleep/")
  }
  for (file in file.path(site, c("analyses/example.qmd", "data/example.csv"))) {
    writeBin(c(readBin(file, "raw", file.size(file)), charToRaw("\n")), file)
  }
  invisible(site)
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

# A symbolic link at `link` to `target`, or a skip where none can be made.
# On Windows a link to a folder is a junction, because unlink() cannot
# remove a folder symbolic link there and the cleanup warns. The CI skip
# list fails on this reason.
symlink_or_skip <- function(target, link) {
  make <- if (.Platform$OS.type == "windows" && dir.exists(target)) Sys.junction else file.symlink
  made <- suppressWarnings(make(target, link))
  skip_if_not(made, "cannot make a symbolic link here (Windows without developer mode)")
}

# TRUE when the file system of the folder `dir` ignores letter case.
ignores_case <- function(dir) {
  probe <- file.path(dir, "case-probe")
  file.create(probe)
  on.exit(unlink(probe))
  file.exists(file.path(dir, "CASE-PROBE"))
}
