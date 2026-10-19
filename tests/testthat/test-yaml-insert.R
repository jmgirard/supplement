menu_path <- list("website", "navbar", "left", yaml_item("text", "Analyses"), "menu")
data_path <- list("supplement", "data")
menu_item <- c(href = "analyses/new.qmd", text = "New \"report\": #1")
data_item <- c(file = "data/new.csv", description = "New data, \\ and '")

expect_appended <- function(before, path, item, n_lines = length(item)) {
  after <- yaml_append_lines(before, path, item)
  expect_length(added_lines(before, after), n_lines)
  list_after <- yaml_list(after, path)
  expect_identical(list_after[-length(list_after)], yaml_list(before, path))
  expect_identical(list_after[[length(list_after)]], as.list(item))
  expect_true(yaml_appended(before, after, path, item))
  after
}

test_that("an item goes at the end of the template's lists", {
  quarto <- readLines(file.path(template_dir(), "_quarto.yml"))
  after <- expect_appended(quarto, menu_path, menu_item)
  expect_identical(
    added_lines(quarto, after),
    c('          - href: "analyses/new.qmd"', '            text: "New \\"report\\": #1"')
  )

  supplement <- readLines(file.path(template_dir(), "_supplement.yml"))
  after <- expect_appended(supplement, data_path, data_item)
  expect_identical(utils::tail(after, 2), c(
    '    - file: "data/new.csv"', '      description: "New data, \\\\ and \'"'
  ))
})

test_that("a 4-space indent and wide item heads are kept", {
  before <- c(
    "website:",
    "    navbar:",
    "        left:",
    "            -   href: index.qmd",
    "                text: Home",
    "            -   text: Analyses",
    "                menu:",
    "                    -   href: analyses/a.qmd",
    "                        text: A"
  )
  after <- expect_appended(before, menu_path, menu_item)
  expect_identical(utils::tail(after, 2), c(
    '                    -   href: "analyses/new.qmd"',
    '                        text: "New \\"report\\": #1"'
  ))
})

test_that("an item after the Analyses menu and a comment stay below the new item", {
  before <- c(
    "website:",
    "  navbar:",
    "    left:",
    "      - text: Analyses",
    "        menu:",
    "          - href: analyses/a.qmd",
    "            text: A",
    "        # a comment after the menu",
    "      - href: about.qmd",
    "        text: About",
    "    right:",
    "      - icon: github"
  )
  after <- expect_appended(before, menu_path, menu_item)
  expect_identical(after[8:9], c('          - href: "analyses/new.qmd"', '            text: "New \\"report\\": #1"'))
  expect_identical(after[10], "        # a comment after the menu")
})

test_that("a key after the data list stays below the new item", {
  before <- c(
    "supplement:",
    "  data:",
    "    - file: data/a.csv",
    "      description: A",
    "",
    "  # Zenodo values",
    "  zenodo:",
    '    version-doi: ""'
  )
  after <- expect_appended(before, data_path, data_item)
  expect_identical(after[5:6], c('    - file: "data/new.csv"', '      description: "New data, \\\\ and \'"'))
  expect_identical(after[7:10], before[5:8])
})

test_that("a list at the indent of its key gets an item at that indent", {
  before <- c("supplement:", "  data:", "  - file: data/a.csv", "    description: A", "  other: 1")
  after <- expect_appended(before, data_path, data_item)
  expect_identical(after[5], '  - file: "data/new.csv"')
})

test_that("an item whose keys start on the line after its dash is read", {
  before <- c("supplement:", "  data:", "    -", "      file: data/a.csv", "      description: A")
  after <- expect_appended(before, data_path, data_item)
  expect_identical(after[6:7], c('    - file: "data/new.csv"', '      description: "New data, \\\\ and \'"'))
})

test_that("a file with no line break at the end keeps its other bytes", {
  file <- withr::local_tempfile(fileext = ".yml")
  text <- "supplement:\n  data:\n    - file: data/a.csv\n      description: A"
  writeChar(text, file, eos = NULL)
  before <- suppressWarnings(readLines(file))

  read <- read_text_lines(file)
  expect_identical(utils::tail(read$lines, 1), "      description: A")
  write_text_lines(read, yaml_append_lines(read$lines, data_path, data_item), file)
  after <- suppressWarnings(readLines(file))
  expect_length(added_lines(before, after), 2)
  bytes <- readBin(file, "raw", file.size(file))
  expect_identical(bytes[seq_len(nchar(text, "bytes"))], charToRaw(text))
  expect_false(identical(utils::tail(bytes, 1), charToRaw("\n")))
})

test_that("line endings, a byte order mark, and UTF-8 text are written back", {
  file <- withr::local_tempfile(fileext = ".yml")
  lines <- c("# Données", "supplement:", "  data:", "    - file: data/a.csv", "      description: été")
  bytes <- c(as.raw(c(0xef, 0xbb, 0xbf)), charToRaw(enc2utf8(paste0(paste(lines, collapse = "\r\n"), "\r\n"))))
  writeBin(bytes, file)

  read <- read_text_lines(file)
  expect_identical(read$lines, c(paste0(enc2utf8(lines), "\r"), ""))
  write_text_lines(read, read$lines, file)
  expect_identical(readBin(file, "raw", file.size(file)), bytes)

  item <- c(file = "data/b.csv", description = "über")
  write_text_lines(read, yaml_append_lines(read$lines, data_path, item), file)
  after <- readBin(file, "raw", file.size(file))
  expect_identical(after[seq_along(bytes)], bytes)
  new <- rawToChar(after[-seq_along(bytes)])
  Encoding(new) <- "UTF-8"
  expect_identical(new, enc2utf8('    - file: "data/b.csv"\r\n      description: "über"\r\n'))
})

# Write `bytes` to a temporary file, add `data_item` with the helpers, and
# return the new bytes.
append_bytes <- function(bytes, env = parent.frame()) {
  file <- withr::local_tempfile(fileext = ".yml", .local_envir = env)
  writeBin(bytes, file)
  read <- read_text_lines(file)
  new <- yaml_append_lines(read$lines, data_path, data_item)
  expect_true(yaml_appended(read$lines, new, data_path, data_item))
  write_text_lines(read, new, file)
  readBin(file, "raw", file.size(file))
}

added <- '    - file: "data/new.csv"%s      description: "New data, \\\\ and \'"'

test_that("a CRLF file with no line break at the end gets CRLF between lines only", {
  text <- "supplement:\r\n  data:\r\n    - file: data/a.csv\r\n      description: A"
  after <- rawToChar(append_bytes(charToRaw(text)))
  expect_identical(after, paste0(text, "\r\n", sprintf(added, "\r\n")))
})

test_that("a file with mixed line endings keeps each line's ending", {
  text <- "# CRLF line\r\nsupplement:\n  data:\n    - file: data/a.csv\n      description: A\n"
  after <- rawToChar(append_bytes(charToRaw(text)))
  expect_identical(after, paste0(text, sprintf(added, "\n"), "\n"))

  text <- "supplement:\r\n  data:\r\n    - file: data/a.csv\n      description: A\r\n"
  after <- rawToChar(append_bytes(charToRaw(text)))
  expect_identical(after, paste0(text, sprintf(added, "\r\n"), "\r\n"))
})

test_that("a block scalar at the end of the file reads the same after the insert", {
  for (end in c("\n", "")) {
    text <- paste0("supplement:\n  data:\n    - file: data/a.csv\n      description: >\n        Folded\n        text", end)
    after <- rawToChar(append_bytes(charToRaw(text)))
    expect_identical(substr(after, 1, nchar(text)), text)
  }
})

test_that("a one-key item is one line", {
  before <- c("supplement:", "  data:", "    - data/a.csv")
  after <- yaml_append_lines(before, data_path, c(file = "b"))
  expect_identical(after, c(before, '    - file: "b"'))
})

test_that("the key offset of a bare dash item comes from its next content line", {
  before <- c("supplement:", "  data:", "    -", "", "# note", "        file: data/a.csv", "        description: A")
  after <- expect_appended(before, data_path, data_item)
  expect_identical(after[8:9], c('    -   file: "data/new.csv"', '        description: "New data, \\\\ and \'"'))
})

test_that("a file with NUL bytes, such as UTF-16 text, is not UTF-8", {
  file <- withr::local_tempfile(fileext = ".yml")
  writeBin(as.raw(c(0xff, 0xfe, 0x73, 0x00, 0x75, 0x00, 0x70, 0x00, 0x3a, 0x00)), file)
  expect_error(read_text_lines(file), class = "supplement_error_encoding")
  writeBin(charToRaw("supplement:\n  title: caf\xe9\n"), file)
  expect_error(read_text_lines(file), class = "supplement_error_encoding")
})

test_that("a write that fails partway restores the old bytes", {
  file <- withr::local_tempfile(fileext = ".yml")
  text <- "supplement:\n  data:\n    - file: data/a.csv\n"
  writeChar(text, file, eos = NULL)
  read <- read_text_lines(file)
  # An error, a warning (R only warns when the disk is full), and a short
  # write with no condition at all.
  fails <- list(
    error = function(bytes, con) {
      writeBin(bytes[1:5], con)
      stop("disk full")
    },
    warning = function(bytes, con) {
      writeBin(bytes[1:5], con)
      warning("No space left on device")
    },
    short = function(bytes, con) writeBin(bytes[1:5], con)
  )
  for (name in names(fails)) {
    local_mocked_bindings(write_bytes = fails[[name]])
    expect_error(write_text_lines(read, c(read$lines, "more"), file), class = "supplement_error_write")
    expect_identical(readBin(file, "raw", file.size(file)), charToRaw(text), info = name)
  }
})

test_that("yaml_appended() rejects a change outside the list", {
  before <- c("supplement:", "  title: A", "  data:", "    - file: a")
  after <- c("supplement:", "  title: B", "  data:", "    - file: a", "    - file: b")
  expect_false(yaml_appended(before, after, data_path, c(file = "b")))
  after[2] <- "  title: A"
  expect_true(yaml_appended(before, after, data_path, c(file = "b")))
})

test_that("a list that is missing or not in block form is not found", {
  missing <- list(
    no_key = c("supplement:", "  title: x"),
    flow = c("supplement:", "  data: []"),
    flow_items = c("supplement:", "  data: [{file: a, description: b}]"),
    empty = c("supplement:", "  data:", "  title: x"),
    at_end = c("supplement:", "  data:"),
    map = c("supplement:", "  data:", "    file: a"),
    nested_deeper = c("other:", "  supplement:", "    data:", "      - file: a"),
    no_supplement = c("data:", "  - file: a")
  )
  for (name in names(missing)) {
    expect_null(yaml_append_lines(missing[[name]], data_path, data_item), label = name)
  }

  menus <- list(
    flow_menu = c("website:", "  navbar:", "    left:", "      - text: Analyses", "        menu: [a]"),
    other_text = c("website:", "  navbar:", "    left:", "      - text: Reports", "        menu:", "          - href: a"),
    no_menu = c("website:", "  navbar:", "    left:", "      - text: Analyses", "        href: a.qmd")
  )
  for (name in names(menus)) {
    expect_null(yaml_append_lines(menus[[name]], menu_path, menu_item), label = name)
  }
})

test_that("a quoted Analyses text and a menu before its text are found", {
  before <- c(
    "website:",
    "  navbar:",
    "    left:",
    "      - menu:",
    "          - href: analyses/a.qmd",
    "            text: A",
    "        text: \"Analyses\" # the menu",
    "      - href: b.qmd"
  )
  after <- expect_appended(before, menu_path, menu_item)
  expect_identical(after[7], '          - href: "analyses/new.qmd"')
})

test_that("yaml_appended() rejects a result that does not read as the item added", {
  before <- c("supplement:", "  data:", "    - file: a")
  wrong <- c(before, "    - file: b")
  expect_false(yaml_appended(before, wrong, data_path, c(file = "c")))
  expect_false(yaml_appended(before, c(before, "  : bad: ["), data_path, c(file = "c")))
  expect_true(yaml_appended(before, wrong, data_path, c(file = "b")))
})

test_that("quoted values read back as written", {
  values <- c(
    "plain", "a \"b\": #c \\d 'e'", "No", "1.10", "- x", "[x", "*x", "été 中文",
    "tab\there", " ", "", "~", "null", "true", "@x", "%x", "!x", "&x", "|", ">", "x ￾ y ￿"
  )
  for (value in values) {
    expect_identical(yaml::yaml.load(yaml_quote(value)), enc2utf8(value), label = value)
  }
})

# Value replacement -------------------------------------------------------

version_path <- c("supplement", "version")

# Write `bytes` to a temporary file, set the version to "1.3.0" with the
# helpers, and check that the bytes after are `bytes` with `old` replaced
# by `new` once, and that the yaml package reads the new version.
expect_version_replaced <- function(bytes, old, new) {
  file <- withr::local_tempfile(fileext = ".yml")
  writeBin(bytes, file)
  read <- read_text_lines(file)
  lines <- yaml_replace_lines(read$lines, version_path, "1.3.0")
  expect_false(is.null(lines))
  expect_true(yaml_replaced(read$lines, lines, version_path, "1.3.0"))
  write_text_lines(read, lines, file)
  after <- readBin(file, "raw", file.size(file))

  # The bytes before and after the changed line are the same.
  text <- rawToChar(bytes)
  at <- regexpr(old, text, fixed = TRUE)
  expect_true(at > 0)
  expect_identical(
    after,
    c(bytes[seq_len(at - 1)], charToRaw(new), bytes[-seq_len(at - 1 + nchar(old, "bytes"))])
  )
  expect_identical(yaml::read_yaml(file, readLines.warn = FALSE)$supplement$version, "1.3.0")
}

test_that("the version in the template's _supplement.yml is replaced", {
  file <- file.path(template_dir(), "_supplement.yml")
  bytes <- readBin(file, "raw", file.size(file))
  expect_version_replaced(bytes, '  version: ""\n', '  version: "1.3.0"\n')
})

test_that("a comment, CRLF line endings, and quoted or plain values are kept or replaced", {
  head <- "# A comment\nsupplement:\n  paper-title: \"A paper\"\n"
  tail <- "  license:\n    code: MIT\n"
  cases <- list(
    comment = c('  version: "1.2.3"   # the site version\n', '  version: "1.3.0"   # the site version\n'),
    single = c("  version: '1.2.3'\n", '  version: "1.3.0"\n'),
    plain = c("  version: 1.2.3\n", '  version: "1.3.0"\n'),
    plain_comment = c("  version: 1.2.3 # c\n", '  version: "1.3.0" # c\n'),
    empty = c("  version:\n", '  version: "1.3.0"\n'),
    empty_comment = c("  version:  # none yet\n", '  version: "1.3.0"  # none yet\n'),
    wide = c('  version:    ""\n', '  version:    "1.3.0"\n'),
    quoted_key = c('  "version": "1.2.3"\n', '  "version": "1.3.0"\n')
  )
  for (name in names(cases)) {
    old <- cases[[name]][1]
    new <- cases[[name]][2]
    expect_version_replaced(charToRaw(paste0(head, old, tail)), old, new)
  }

  crlf <- function(x) gsub("\n", "\r\n", x, fixed = TRUE)
  expect_version_replaced(
    charToRaw(crlf(paste0(head, '  version: "1.2.3"\n', tail))),
    '  version: "1.2.3"\r\n', '  version: "1.3.0"\r\n'
  )
  # The last line of a file with no line break at the end.
  expect_version_replaced(
    charToRaw(paste0(head, '  version: "1.2.3"')),
    '  version: "1.2.3"', '  version: "1.3.0"'
  )
})

test_that("a version that is not a one-line value of the supplement map is not found", {
  missing <- list(
    no_key = c("supplement:", "  paper-title: A"),
    other_map = c("supplement:", "  zenodo:", "    version: \"1.2.3\""),
    top_level = c("version: \"1.2.3\"", "supplement:", "  paper-title: A"),
    deeper = c("supplement:", "  paper-title: A", "    version: \"1.2.3\""),
    flow_map = c("supplement: {version: \"1.2.3\"}"),
    flow_value = c("supplement:", "  version: [1.2.3]"),
    literal = c("supplement:", "  version: |", "    1.2.3"),
    folded = c("supplement:", "  version: >-", "    1.2.3"),
    continued = c("supplement:", "  version: 1.2", "    .3"),
    nested = c("supplement:", "  version:", "    major: 1"),
    anchor = c("supplement:", "  version: &v 1.2.3"),
    tag = c("supplement:", "  version: !!str 1.2.3"),
    open_quote = c("supplement:", "  version: \"1.2.3")
  )
  for (name in names(missing)) {
    expect_null(yaml_replace_lines(missing[[name]], version_path, "1.3.0"), label = name)
  }
})

test_that("yaml_replaced() rejects a result that is not the old map with the new value", {
  before <- c("supplement:", "  paper-title: A", "  version: \"1.2.3\"")
  after <- c("supplement:", "  paper-title: B", "  version: \"1.3.0\"")
  expect_false(yaml_replaced(before, after, version_path, "1.3.0"))
  expect_false(yaml_replaced(before, before, version_path, "1.3.0"))
  # A key that the old file does not have.
  expect_false(yaml_replaced(before[1:2], c(before[1:2], "  version: \"1.3.0\""), version_path, "1.3.0"))
  after[2] <- "  paper-title: A"
  expect_true(yaml_replaced(before, after, version_path, "1.3.0"))
  # A file with a duplicate key does not read.
  dup <- c(before, "  version: \"1.2.3\"")
  expect_false(yaml_replaced(dup, yaml_replace_lines(dup, version_path, "1.3.0"), version_path, "1.3.0"))
})
