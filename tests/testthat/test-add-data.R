data_list <- list("supplement", "data")

# A file outside any site, with bytes that are not text.
source_file <- function(name = "scores.csv", env = parent.frame()) {
  dir <- withr::local_tempdir("source-", .local_envir = env)
  file <- file.path(dir, name)
  writeBin(as.raw(c(0:255, 13, 10, 0, 255)), file)
  file
}

test_that("a file outside the site is copied byte for byte and listed last", {
  site <- new_site()
  for (i in seq_along(probe_values)) {
    value <- probe_values[[i]]
    file <- source_file(paste0("file-", i, ".csv"))
    expect_message(out <- add_data(file, value, path = site), "Copied")
    target <- file.path(site, "data", basename(file))
    expect_identical(out, target)
    expect_identical(read_bytes(target), read_bytes(file))

    items <- yaml_list(lines_utf8(file.path(site, "_supplement.yml")), data_list)
    expect_identical(
      items[[length(items)]],
      list(file = paste0("data/", basename(file)), description = enc2utf8(value)),
      info = names(probe_values)[i]
    )
  }
  items <- yaml_list(lines_utf8(file.path(site, "_supplement.yml")), data_list)
  expect_identical(
    vapply(items, `[[`, "", "file"),
    c("data/example.csv", paste0("data/file-", seq_along(probe_values), ".csv"))
  )
})

test_that("a file already in the site's data folder is listed and not copied", {
  site <- new_site()
  file <- file.path(site, "data", "mine.csv")
  writeBin(as.raw(1:10), file)
  before <- file.info(file)$mtime
  Sys.sleep(1.1)
  expect_message(add_data(file, "Mine", path = site), "Added")
  expect_identical(read_bytes(file), as.raw(1:10))
  expect_identical(file.info(file)$mtime, before)
  items <- yaml_list(lines_utf8(file.path(site, "_supplement.yml")), data_list)
  expect_identical(items[[length(items)]], list(file = "data/mine.csv", description = "Mine"))
  expect_identical(sort(list.files(file.path(site, "data"))), c("example.csv", "mine.csv"))

  # The same, with paths relative to the site folder.
  writeBin(as.raw(1:3), file.path(site, "data", "rel.csv"))
  withr::with_dir(site, suppressMessages(add_data("data/rel.csv", "Relative")))
  items <- yaml_list(lines_utf8(file.path(site, "_supplement.yml")), data_list)
  expect_identical(items[[length(items)]], list(file = "data/rel.csv", description = "Relative"))
})

test_that("a site with no data folder gets one", {
  site <- new_site()
  unlink(file.path(site, "data"), recursive = TRUE)
  file <- source_file()
  suppressMessages(add_data(file, "Scores", path = site))
  expect_identical(read_bytes(file.path(site, "data", "scores.csv")), read_bytes(file))
})

test_that("the edit keeps every other line of the template's _supplement.yml", {
  site <- new_site()
  meta <- file.path(site, "_supplement.yml")
  before <- lines_utf8(meta)
  suppressMessages(add_data(source_file(), "Scores \"raw\"", path = site))
  expect_identical(
    added_lines(before, lines_utf8(meta)),
    c('    - file: "data/scores.csv"', '      description: "Scores \\"raw\\""')
  )
})

test_that("other _supplement.yml shapes keep every other line", {
  shapes <- list(
    four_spaces = c(
      "supplement:",
      "    paper-title: \"T\"",
      "    data:",
      "        - file: data/a.csv",
      "          description: A"
    ),
    key_after_data = c(
      "supplement:",
      "  data:",
      "    - file: data/a.csv",
      "      description: A",
      "  # Zenodo values",
      "  zenodo:",
      "    version-doi: \"\""
    )
  )
  for (name in names(shapes)) {
    site <- withr::local_tempdir()
    meta <- file.path(site, "_supplement.yml")
    writeLines(shapes[[name]], meta)
    suppressMessages(add_data(source_file(), "Scores", path = site))
    added <- added_lines(shapes[[name]], lines_utf8(meta))
    expect_length(added, 2)
    expect_match(added[1], '- file: "data/scores.csv"', fixed = TRUE)
  }
})

test_that("a _supplement.yml with no line break at the end keeps its bytes", {
  site <- withr::local_tempdir()
  meta <- file.path(site, "_supplement.yml")
  text <- "supplement:\n  data:\n    - file: data/a.csv\n      description: A"
  writeChar(text, meta, eos = NULL)
  before <- suppressWarnings(readLines(meta))
  suppressMessages(add_data(source_file(), "Scores", path = site))
  expect_length(added_lines(before, suppressWarnings(readLines(meta))), 2)
  bytes <- read_bytes(meta)
  expect_identical(bytes[seq_len(nchar(text, "bytes"))], charToRaw(text))
  expect_false(identical(utils::tail(bytes, 1), charToRaw("\n")))
})

# Fire an add_data() error in a new site and check that it writes and
# copies nothing.
expect_data_error <- function(class, ..., setup = NULL) {
  site <- new_site()
  args <- list(...)
  if (!is.null(setup)) {
    extra <- setup(site)
    if (is.list(extra)) args <- utils::modifyList(args, extra)
  }
  before <- folder_state(site)
  if (is.null(args$path)) args$path <- site
  expect_error(do.call(add_data, args), class = class)
  expect_error(do.call(add_data, args), class = "supplement_error")
  expect_identical(folder_state(site), before)
}

test_that("a bad path stops with an argument error", {
  file <- source_file()
  for (path in list(NA_character_, "", c("a", "b"), 1, NULL)) {
    site <- new_site()
    before <- folder_state(site)
    expect_error(add_data(file, "D", path = path), class = "supplement_error_argument")
    expect_identical(folder_state(site), before)
  }
})

test_that("a bad file stops and writes nothing", {
  for (file in list(NA_character_, c("a", "b"), 1, NULL)) {
    expect_data_error("supplement_error_argument", file = file, description = "D")
  }
  expect_data_error("supplement_error_no_file", file = file.path(tempdir(), "no-such-file.csv"), description = "D")
  expect_data_error("supplement_error_no_file", file = withr::local_tempdir(), description = "D")
})

test_that("a bad description stops and writes nothing", {
  file <- source_file()
  for (description in list(NA_character_, c("a", "b"), 1, NULL)) {
    expect_data_error("supplement_error_argument", file = file, description = description)
  }
  for (text in c("a\nb", "a\r\nb", "a\rb")) {
    expect_data_error("supplement_error_line_break", file = file, description = text)
  }
})

test_that("a file name that Quarto reads as Markdown stops", {
  for (name in c("a b.csv", "it's.csv", "a--b.csv", "a._b.csv", ".hidden", "café.csv", "_x_.csv")) {
    file <- source_file(name)
    expect_data_error("supplement_error_file_name", file = file, description = "D")
  }
})

test_that("a different file at data/<base name> stops and is kept", {
  file <- source_file("example.csv")
  expect_data_error("supplement_error_file_exists", file = file, description = "D")
  expect_data_error(
    "supplement_error_file_exists", file = source_file(), description = "D",
    setup = function(site) {
      unlink(file.path(site, "data"), recursive = TRUE)
      writeLines("not a folder", file.path(site, "data"))
    }
  )
})

test_that("a file that is already listed stops", {
  expect_data_error(
    "supplement_error_already_listed", description = "D",
    setup = function(site) list(file = file.path(site, "data", "example.csv"))
  )
})

test_that("a folder with no _supplement.yml stops before the copy", {
  dir <- withr::local_tempdir()
  before <- folder_state(dir)
  expect_error(add_data(source_file(), "D", path = dir), class = "supplement_error_no_metadata")
  expect_identical(folder_state(dir), before)
})

test_that("a _supplement.yml with no block-style data list stops and shows the lines to add", {
  metas <- list(
    flow_empty = c("supplement:", "  data: []"),
    flow_items = c("supplement:", "  data: [{file: data/a.csv, description: A}]"),
    no_data = c("supplement:", "  paper-title: \"T\""),
    top_level = c("data:", "  - file: data/a.csv")
  )
  for (name in names(metas)) {
    expect_data_error(
      "supplement_error_no_data_list", file = source_file(), description = "D",
      setup = function(site) writeLines(metas[[name]], file.path(site, "_supplement.yml"))
    )
  }
  site <- new_site()
  writeLines(metas$flow_empty, file.path(site, "_supplement.yml"))
  err <- tryCatch(add_data(source_file(), "D \"x\"", path = site), error = function(e) e)
  expect_identical(conditionCall(err)[[1]], quote(add_data))
  expect_match(
    conditionMessage(err),
    '    supplement:\n      data:\n        - file: "data/scores.csv"\n          description: "D \\"x\\""',
    fixed = TRUE
  )
})
