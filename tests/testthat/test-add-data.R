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
    after <- lines_utf8(meta)
    added <- added_lines(shapes[[name]], after)
    expect_length(added, 2)
    expect_match(added[1], '- file: "data/scores.csv"', fixed = TRUE)
    items <- yaml_list(after, data_list)
    expect_identical(items[[length(items)]], list(file = "data/scores.csv", description = "Scores"), info = name)
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
  for (name in c("a b.csv", "it's.csv", "a--b.csv", "a._b.csv", ".hidden", "café.csv", "_x_.csv", "x.csv\n", "_data_", "_x-y_")) {
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

test_that("_supplement.yml is checked before the copy runs", {
  local_mocked_bindings(copy_file = function(from, to) stop("the copy ran"))
  expect_data_error(
    "supplement_error_no_data_list", file = source_file(), description = "D",
    setup = function(site) writeLines(c("supplement:", "  data: []"), file.path(site, "_supplement.yml"))
  )
  # A listed file that is not on disk, and a file of that name from outside
  # the site, which would be copied if the check came after the copy.
  expect_data_error(
    "supplement_error_already_listed", file = source_file(), description = "D",
    setup = function(site) {
      meta <- file.path(site, "_supplement.yml")
      writeLines(sub("data/example.csv", "data/scores.csv", readLines(meta), fixed = TRUE), meta)
    }
  )
})

test_that("a copy that fails stops with a write error and leaves nothing", {
  local_mocked_bindings(copy_file = function(from, to) FALSE)
  expect_data_error("supplement_error_write", file = source_file(), description = "D")
})

test_that("saved R objects stop, in any letter case", {
  for (name in c("fit.rds", "fit.RDS", "a.rda", "b.RData", "c.qs", "d.QS2",
                 "e.rmarkdown", "f.quarto_ipynb", "g.knit.md", "h.utf8.md")) {
    expect_data_error("supplement_error_ignored_file", file = source_file(name), description = "D")
  }
})

test_that("a linked data folder or data file stops, so nothing is written outside the site", {
  skip_on_os("windows")
  outside <- withr::local_tempdir("outside-")
  outside_before <- folder_state(outside)
  expect_data_error(
    "supplement_error_file_exists", file = source_file(), description = "D",
    setup = function(site) {
      unlink(file.path(site, "data"), recursive = TRUE)
      file.symlink(outside, file.path(site, "data"))
    }
  )
  expect_identical(folder_state(outside), outside_before)

  real <- source_file("real.csv")
  expect_data_error(
    "supplement_error_file_exists", file = real, description = "D",
    setup = function(site) file.symlink(real, file.path(site, "data", "real.csv"))
  )
})

test_that("a name that differs from a file in data/ only in letter case stops", {
  expect_data_error("supplement_error_file_exists", file = source_file("EXAMPLE.csv"), description = "D")
})

test_that("a file listed in another letter case is already listed", {
  expect_data_error(
    "supplement_error_already_listed", description = "D",
    setup = function(site) {
      meta <- file.path(site, "_supplement.yml")
      lines <- readLines(meta)
      writeLines(sub("data/example.csv", "data/EXAMPLE.csv", lines, fixed = TRUE), meta)
      list(file = file.path(site, "data", "example.csv"))
    }
  )
})

test_that("on a case-insensitive disk, a file in data/ is listed under its name on disk", {
  site <- new_site()
  writeBin(as.raw(1:3), file.path(site, "data", "mine.csv"))
  given <- file.path(site, "data", "MINE.csv")
  skip_if_not(file.exists(given), "the disk is case-sensitive")
  suppressMessages(add_data(given, "Mine", path = site))
  items <- yaml_list(lines_utf8(file.path(site, "_supplement.yml")), data_list)
  expect_identical(items[[length(items)]]$file, "data/mine.csv")
  expect_identical(sort(list.files(file.path(site, "data"))), c("example.csv", "mine.csv"))
})

test_that("names with one leading or inner underscore pass the file-name rule", {
  site <- new_site()
  for (name in c("_a.csv", "a_x_b.csv", "a_b_")) {
    suppressMessages(add_data(source_file(name), "D", path = site))
    expect_true(file.exists(file.path(site, "data", name)), info = name)
  }
})

test_that("on a case-sensitive disk, any file in data/ that differs only in letter case stops", {
  site <- new_site()
  writeBin(as.raw(1:3), file.path(site, "data", "mine.csv"))
  writeBin(as.raw(4:6), file.path(site, "data", "MINE.csv"))
  skip_if(length(list.files(file.path(site, "data"))) < 3, "the disk is case-insensitive")
  for (name in c("mine.csv", "MINE.csv")) {
    before <- folder_state(site)
    expect_error(add_data(file.path(site, "data", name), "D", path = site), class = "supplement_error_file_exists")
    expect_identical(folder_state(site), before)
  }
})

test_that("valid UTF-8 text marked as bytes is listed as UTF-8", {
  site <- new_site()
  marked <- "café"
  Encoding(marked) <- "bytes"
  suppressMessages(add_data(source_file(), marked, path = site))
  items <- yaml_list(lines_utf8(file.path(site, "_supplement.yml")), data_list)
  expect_identical(items[[length(items)]]$description, "café")
})

test_that("a missing file or description stops with an argument error", {
  site <- new_site()
  before <- folder_state(site)
  expect_error(add_data(description = "D", path = site), class = "supplement_error_argument")
  expect_error(add_data(source_file(), path = site), class = "supplement_error_argument")
  expect_identical(folder_state(site), before)
})

test_that("a separator after the file name is dropped", {
  site <- new_site()
  file <- source_file()
  suppressMessages(add_data(paste0(file, "/"), "D", path = site))
  expect_identical(read_bytes(file.path(site, "data", "scores.csv")), read_bytes(file))
})

test_that("a description that is not valid UTF-8 stops", {
  bad <- "caf\xe9"
  Encoding(bad) <- "bytes"
  bad <- rawToChar(charToRaw(bad))
  expect_data_error("supplement_error_encoding", file = source_file(), description = bad)
})

test_that("a block-scalar description at the end of _supplement.yml does not stop", {
  site <- new_site()
  meta <- file.path(site, "_supplement.yml")
  lines <- readLines(meta)
  i <- grep("description: \"Example data", lines, fixed = TRUE)
  lines <- c(lines[seq_len(i - 1)], "      description: >", "        Example data for the", "        example report")
  writeLines(lines, meta)
  suppressMessages(add_data(source_file(), "Scores", path = site))
  expect_identical(added_lines(lines, lines_utf8(meta)),
                   c('    - file: "data/scores.csv"', '      description: "Scores"'))
})

test_that("a failed write in a site path with pattern characters removes only its own copy", {
  file <- source_file()
  sites <- list()
  for (name in pattern_names()) {
    base <- withr::local_tempdir()
    site <- file.path(base, name)
    dir.create(site)
    suppressMessages(create_supplement(site))
    sibling <- file.path(base, "sitea")
    dir.create(file.path(sibling, "data"), recursive = TRUE)
    writeLines("mine", file.path(sibling, "data", "scores.csv"))
    sites[[name]] <- list(site = site, sibling = sibling)
  }
  # The data file is copied, then the edit of _supplement.yml fails.
  local_mocked_bindings(write_text_lines = function(...) stop("planted failure"))
  for (name in names(sites)) {
    site <- sites[[name]]$site
    sibling <- sites[[name]]$sibling
    before <- folder_state(site)
    sibling_before <- folder_state(sibling)
    expect_error(add_data(file, "D", path = site), regexp = "planted failure")
    expect_identical(folder_state(site), before, info = name)
    expect_identical(folder_state(sibling), sibling_before, info = name)
  }
})

test_that("a _supplement.yml that does not parse stops with a yaml error", {
  expect_data_error(
    "supplement_error_yaml", file = source_file(), description = "D",
    setup = function(site) write("other: [unclosed", file.path(site, "_supplement.yml"), append = TRUE)
  )
})

test_that("a read-only _supplement.yml gives R's error and the copy is removed", {
  skip_on_os("windows")
  skip_if(Sys.info()[["user"]] == "root", "root can write to read-only files")
  site <- new_site()
  meta <- file.path(site, "_supplement.yml")
  Sys.chmod(meta, "0444")
  withr::defer(Sys.chmod(meta, "0644"))
  before <- folder_state(site)
  err <- tryCatch(suppressWarnings(add_data(source_file(), "D", path = site)), error = function(e) e)
  expect_s3_class(err, "error")
  expect_false(inherits(err, "supplement_error"))
  expect_identical(folder_state(site), before)
})
