# The error that each function gives when the yaml package cannot read
# _supplement.yml or _quarto.yml.

# Five shapes of text that the yaml package refuses, as lines with `indent`
# before each key: "  " for a line under `supplement:`, or "" for a line at
# the top level. A tab inside a flow sequence is valid YAML, so the tab
# shape is a line indented with a tab under a block map.
bad_shapes <- function(indent) {
  tab <- if (nzchar(indent)) '\tversion: ""' else c("extra:", '\tversion: ""')
  list(
    flow_sequence = paste0(indent, "citation: [x"),
    flow_map = paste0(indent, "zenodo: {a: 1"),
    tab = tab,
    second_value = paste0(indent, "paper-title: a: b"),
    duplicate_key = paste0(indent, c('repeated: "A"', 'repeated: "B"'))
  )
}

# Write `lines` with "\n" after each one, as bytes, and return the text.
write_lines_bytes <- function(lines, file) {
  text <- paste0(paste(lines, collapse = "\n"), "\n")
  writeBin(charToRaw(enc2utf8(text)), file)
  text
}

# Each run of white space, Unicode spaces included, made one space, with
# none at the start or the end.
one_space <- function(x) {
  trimws(gsub("[\\h\\v]+", " ", x, perl = TRUE))
}

# The message of the yaml package's error for `text`, with white space made
# one space. The test fails when the package reads the text.
parser_message <- function(text) {
  err <- tryCatch({
    yaml::yaml.load(text)
    NULL
  }, error = function(e) e)
  expect_false(is.null(err), label = "the yaml package refuses the text")
  one_space(trimws(conditionMessage(err)))
}

# Check that `expr` stops with `supplement_error_parse` and a message that
# names `file_name` and holds `parser`, and that it changes nothing in
# `site`.
expect_parse_error <- function(expr, site, file_name, parser, label) {
  before <- folder_state(site)
  err <- tryCatch({
    force(expr)
    NULL
  }, error = function(e) e)
  expect_true(inherits(err, "supplement_error_parse"), label = label)
  expect_true(inherits(err, "supplement_error"), label = label)
  message <- one_space(conditionMessage(err))
  expect_true(grepl(file_name, message, fixed = TRUE), label = label)
  expect_true(grepl(parser, message, fixed = TRUE), label = label)
  expect_identical(folder_state(site), before, label = label)
}

# A file outside any site for add_data() to copy.
data_source <- function(env = parent.frame()) {
  dir <- withr::local_tempdir("source-", .local_envir = env)
  file <- file.path(dir, "scores.csv")
  writeLines("x", file)
  file
}

test_that("a _supplement.yml that the yaml package cannot read gives supplement_error_parse", {
  template <- readLines(file.path(template_dir(), "_supplement.yml"), encoding = "UTF-8")
  at <- which(template == "supplement:")
  stopifnot(length(at) == 1)
  source <- data_source()
  calls <- list(
    write_citation = function(site) write_citation(site),
    write_zenodo = function(site) write_zenodo(site),
    check_supplement = function(site) check_supplement(site),
    release_supplement = function(site) release_supplement("patch", path = site),
    add_data = function(site) add_data(source, "D", path = site)
  )
  for (shape in names(bad_shapes("  "))) {
    site <- new_site()
    lines <- append(template, bad_shapes("  ")[[shape]], after = at)
    text <- write_lines_bytes(lines, file.path(site, "_supplement.yml"))
    parser <- parser_message(text)
    for (name in names(calls)) {
      expect_parse_error(
        suppressMessages(calls[[name]](site)), site, "_supplement.yml", parser,
        label = paste(name, shape)
      )
    }
  }
})

test_that("a _quarto.yml that the yaml package cannot read gives supplement_error_parse", {
  for (shape in names(bad_shapes(""))) {
    site <- new_site()
    file <- file.path(site, "_quarto.yml")
    lines <- c(bad_shapes("")[[shape]], readLines(file, encoding = "UTF-8"))
    text <- write_lines_bytes(lines, file)
    parser <- parser_message(text)
    expect_parse_error(
      suppressMessages(add_report("x", "X", path = site)), site, "_quarto.yml", parser,
      label = shape
    )
  }
})
