menu <- list("website", "navbar", "left", list(key = "text", value = "Analyses"), "menu")

test_that("a report stub and its menu item read back with each value unchanged", {
  site <- new_site()
  for (i in seq_along(probe_values)) {
    value <- probe_values[[i]]
    name <- paste0("report-", i)
    expect_message(
      out <- add_report(name, value, value, path = site),
      "Analyses menu"
    )
    report <- file.path(site, "analyses", paste0(name, ".qmd"))
    expect_identical(out, report)
    expect_true(validUTF8(rawToChar(read_bytes(report))))

    meta <- front_matter(report)
    expect_identical(meta$title, enc2utf8(value), info = names(probe_values)[i])
    expect_identical(meta$description, enc2utf8(value), info = names(probe_values)[i])

    items <- yaml_list(lines_utf8(file.path(site, "_quarto.yml")), menu)
    expect_identical(
      items[[length(items)]],
      list(href = paste0("analyses/", name, ".qmd"), text = enc2utf8(value)),
      info = names(probe_values)[i]
    )
  }
  # The template's item stays first, and the new items follow in order.
  items <- yaml_list(lines_utf8(file.path(site, "_quarto.yml")), menu)
  expect_identical(
    vapply(items, `[[`, "", "href"),
    c("analyses/example.qmd", paste0("analyses/report-", seq_along(probe_values), ".qmd"))
  )
})

test_that("the non-ASCII title is written as UTF-8 bytes", {
  site <- new_site()
  value <- probe_values[["non_ascii"]]
  suppressMessages(add_report("utf8", value, path = site))
  bytes <- read_bytes(file.path(site, "analyses", "utf8.qmd"))
  expect_true(grepl(enc2utf8(value), rawToChar(bytes), fixed = TRUE, useBytes = TRUE))
})

test_that("an empty description writes no description key", {
  site <- new_site()
  suppressMessages(add_report("plain", "Plain", path = site))
  meta <- front_matter(file.path(site, "analyses", "plain.qmd"))
  expect_identical(meta, list(title = "Plain"))
})

test_that("the edit keeps every other line of the template's _quarto.yml", {
  site <- new_site()
  config <- file.path(site, "_quarto.yml")
  before <- lines_utf8(config)
  suppressMessages(add_report("new", "New \"report\"", path = site))
  expect_identical(
    added_lines(before, lines_utf8(config)),
    c('          - href: "analyses/new.qmd"', '            text: "New \\"report\\""')
  )
})

test_that("other _quarto.yml shapes keep every other line", {
  shapes <- list(
    four_spaces = c(
      "website:",
      "    navbar:",
      "        left:",
      "            - text: Analyses",
      "              menu:",
      "                  - href: analyses/a.qmd",
      "                    text: A"
    ),
    item_after_menu = c(
      "website:",
      "  navbar:",
      "    left:",
      "      - text: Analyses",
      "        menu:",
      "          - href: analyses/a.qmd",
      "            text: A",
      "      - href: about.qmd",
      "        text: About"
    ),
    menu_on_right = c(
      "website:",
      "  navbar:",
      "    right:",
      "      - text: Analyses",
      "        menu:",
      "          - href: analyses/a.qmd",
      "            text: A"
    )
  )
  for (name in names(shapes)) {
    site <- withr::local_tempdir()
    config <- file.path(site, "_quarto.yml")
    writeLines(shapes[[name]], config)
    suppressMessages(add_report("new", "New", path = site))
    after <- lines_utf8(config)
    expect_length(added_lines(shapes[[name]], after), 2)
    side <- if (name == "menu_on_right") "right" else "left"
    items <- yaml_list(after, list("website", "navbar", side, list(key = "text", value = "Analyses"), "menu"))
    expect_identical(items[[length(items)]], list(href = "analyses/new.qmd", text = "New"), info = name)
    expect_true(file.exists(file.path(site, "analyses", "new.qmd")), info = name)
  }
})

test_that("a _quarto.yml with no line break at the end keeps its bytes", {
  site <- withr::local_tempdir()
  config <- file.path(site, "_quarto.yml")
  text <- "website:\n  navbar:\n    left:\n      - text: Analyses\n        menu:\n          - href: analyses/a.qmd"
  writeChar(text, config, eos = NULL)
  before <- suppressWarnings(readLines(config))
  suppressMessages(add_report("new", "New", path = site))
  expect_length(added_lines(before, suppressWarnings(readLines(config))), 2)
  bytes <- read_bytes(config)
  expect_identical(bytes[seq_len(nchar(text, "bytes"))], charToRaw(text))
  expect_false(identical(utils::tail(bytes, 1), charToRaw("\n")))
})

# Fire an add_report() error in a new site and check that it writes
# nothing.
expect_report_error <- function(class, ..., setup = NULL) {
  site <- new_site()
  if (!is.null(setup)) setup(site)
  before <- folder_state(site)
  args <- list(...)
  if (is.null(args$path)) args$path <- site
  expect_error(do.call(add_report, args), class = class)
  expect_error(do.call(add_report, args), class = "supplement_error")
  expect_identical(folder_state(site), before)
}

test_that("a bad path stops with an argument error", {
  for (path in list(NA_character_, "", c("a", "b"), 1, NULL)) {
    site <- new_site()
    before <- folder_state(site)
    expect_error(add_report("x", "X", path = path), class = "supplement_error_argument")
    expect_identical(folder_state(site), before)
  }
})

test_that("a bad name stops and writes nothing", {
  for (name in list("_x", "-x", "a b", "a.b", "", "café", c("a", "b"), NA_character_, 1, "ab\n")) {
    expect_report_error("supplement_error_report_name", name = name, title = "X")
  }
})

test_that("a bad title or description stops and writes nothing", {
  for (title in list("", "   ", NA_character_, c("a", "b"), 1)) {
    expect_report_error("supplement_error_argument", name = "x", title = title)
  }
  for (description in list(NA_character_, c("a", "b"), 1, NULL)) {
    expect_report_error("supplement_error_argument", name = "x", title = "X", description = description)
  }
  for (text in c("a\nb", "a\r\nb", "a\rb")) {
    expect_report_error("supplement_error_line_break", name = "x", title = text)
    expect_report_error("supplement_error_line_break", name = "x", title = "X", description = text)
  }
})

test_that("an existing report file stops and is kept", {
  expect_report_error("supplement_error_file_exists", name = "example", title = "X")
  expect_report_error(
    "supplement_error_file_exists", name = "x", title = "X",
    setup = function(site) {
      unlink(file.path(site, "analyses"), recursive = TRUE)
      writeLines("not a folder", file.path(site, "analyses"))
    }
  )
})

test_that("a folder with no _quarto.yml stops", {
  dir <- withr::local_tempdir()
  writeLines("x", file.path(dir, "other.txt"))
  before <- folder_state(dir)
  expect_error(add_report("x", "X", path = dir), class = "supplement_error_no_config")
  expect_identical(folder_state(dir), before)
  expect_report_error("supplement_error_no_config", name = "x", title = "X",
                      setup = function(site) unlink(file.path(site, "_quarto.yml")))
})

test_that("a _quarto.yml with no block-style Analyses menu stops and shows the lines to add", {
  configs <- list(
    flow = c("website:", "  navbar:", "    left:", "      - text: Analyses", "        menu: [analyses/a.qmd]"),
    renamed = c("website:", "  navbar:", "    left:", "      - text: Reports", "        menu:", "          - href: a.qmd"),
    no_navbar = c("website:", "  title: x")
  )
  for (name in names(configs)) {
    expect_report_error(
      "supplement_error_no_menu", name = "x", title = "X \"y\"",
      setup = function(site) writeLines(configs[[name]], file.path(site, "_quarto.yml"))
    )
  }
  site <- new_site()
  writeLines(configs$flow, file.path(site, "_quarto.yml"))
  err <- tryCatch(add_report("x", "X \"y\"", path = site), error = function(e) e)
  expect_match(conditionMessage(err), "Analyses menu", fixed = TRUE)
  expect_identical(conditionCall(err)[[1]], quote(add_report))
  expect_match(
    conditionMessage(err),
    '          - href: "analyses/x.qmd"\n                text: "X \\"y\\""',
    fixed = TRUE
  )
})

test_that("valid UTF-8 text marked as bytes is written as UTF-8", {
  site <- new_site()
  value <- "café"
  marked <- value
  Encoding(marked) <- "bytes"
  suppressMessages(add_report("bytes", marked, marked, path = site))
  meta <- front_matter(file.path(site, "analyses", "bytes.qmd"))
  expect_identical(meta, list(title = value, description = value))
})

test_that("a missing name or title stops with an argument error", {
  site <- new_site()
  before <- folder_state(site)
  expect_error(add_report(title = "X", path = site), class = "supplement_error_report_name")
  expect_error(add_report("x", path = site), class = "supplement_error_argument")
  expect_identical(folder_state(site), before)
})

test_that("a failed write of the report stub stops and leaves nothing", {
  site <- new_site()
  before <- folder_state(site)
  local_mocked_bindings(write_bytes = function(bytes, con) {
    writeBin(bytes[1:3], con)
    warning("No space left on device")
  })
  expect_error(add_report("x", "X", path = site), class = "supplement_error_write")
  expect_identical(folder_state(site), before)
})

test_that("a title of only Unicode spaces stops", {
  for (title in c(" ", "　  ")) {
    expect_report_error("supplement_error_argument", name = "x", title = title)
  }
})

test_that("text that is not valid UTF-8 stops", {
  bad <- "caf\xe9"
  Encoding(bad) <- "bytes"
  bad <- rawToChar(charToRaw(bad))
  expect_report_error("supplement_error_encoding", name = "x", title = bad)
  expect_report_error("supplement_error_encoding", name = "x", title = "X", description = bad)
})

test_that("a name that differs from an existing report only in letter case stops", {
  expect_report_error("supplement_error_file_exists", name = "Example", title = "X")
})

test_that("stored output of an earlier report with the same name stops", {
  expect_report_error(
    "supplement_error_file_exists", name = "old", title = "X",
    setup = function(site) dir.create(file.path(site, "_freeze", "analyses", "old"), recursive = TRUE)
  )
})

test_that("a linked analyses folder stops, so nothing is written outside the site", {
  skip_on_os("windows")
  outside <- withr::local_tempdir("outside-")
  outside_before <- folder_state(outside)
  expect_report_error(
    "supplement_error_file_exists", name = "x", title = "X",
    setup = function(site) {
      unlink(file.path(site, "analyses"), recursive = TRUE)
      file.symlink(outside, file.path(site, "analyses"))
    }
  )
  expect_identical(folder_state(outside), outside_before)
})

test_that("noncharacters in a description are escaped and read back", {
  site <- new_site()
  value <- "x ￾ y ￿"
  suppressMessages(add_report("nonchar", "Nonchar", value, path = site))
  report <- file.path(site, "analyses", "nonchar.qmd")
  expect_identical(front_matter(report)$description, value)
  expect_true(any(lines_utf8(report) == 'description: "x \\uFFFE y \\uFFFF"'))
})

test_that("a _quarto.yml that is not UTF-8 or does not parse stops and writes nothing", {
  expect_report_error(
    "supplement_error_encoding", name = "x", title = "X",
    setup = function(site) {
      con <- file(file.path(site, "_quarto.yml"), "ab")
      writeBin(as.raw(c(0x23, 0x20, 0xe9, 0x0a)), con)
      close(con)
    }
  )
  expect_report_error(
    "supplement_error_yaml", name = "x", title = "X",
    setup = function(site) write("format: [unclosed", file.path(site, "_quarto.yml"), append = TRUE)
  )
})

test_that("a failed write in a site path with pattern characters removes only its own report", {
  sites <- list()
  for (name in pattern_names()) {
    base <- withr::local_tempdir()
    site <- file.path(base, name)
    dir.create(site)
    suppressMessages(create_supplement(site))
    sibling <- file.path(base, "sitea")
    dir.create(file.path(sibling, "analyses"), recursive = TRUE)
    writeLines("mine", file.path(sibling, "analyses", "x.qmd"))
    sites[[name]] <- list(site = site, sibling = sibling)
  }
  # The report file is written, then the edit of _quarto.yml fails.
  local_mocked_bindings(write_text_lines = function(...) stop("planted failure"))
  for (name in names(sites)) {
    site <- sites[[name]]$site
    sibling <- sites[[name]]$sibling
    before <- folder_state(site)
    sibling_before <- folder_state(sibling)
    expect_error(add_report("x", "X", path = site), regexp = "planted failure")
    expect_identical(folder_state(site), before, info = name)
    expect_identical(folder_state(sibling), sibling_before, info = name)
  }
})

test_that("a folder that cannot be made stops with a write error", {
  skip_on_os("windows")
  skip_if(Sys.info()[["user"]] == "root", "root can write to read-only folders")
  site <- new_site()
  unlink(file.path(site, "analyses"), recursive = TRUE)
  Sys.chmod(site, "0555")
  withr::defer(Sys.chmod(site, "0755"))
  before <- folder_state(site)
  expect_error(add_report("x", "X", path = site), class = "supplement_error_write")
  expect_identical(folder_state(site), before)
})

test_that("a read-only _quarto.yml gives R's error and the report file is removed", {
  skip_on_os("windows")
  skip_if(Sys.info()[["user"]] == "root", "root can write to read-only files")
  site <- new_site()
  config <- file.path(site, "_quarto.yml")
  Sys.chmod(config, "0444")
  withr::defer(Sys.chmod(config, "0644"))
  before <- folder_state(site)
  err <- tryCatch(suppressWarnings(add_report("x", "X", path = site)), error = function(e) e)
  expect_s3_class(err, "error")
  expect_false(inherits(err, "supplement_error"))
  expect_match(conditionMessage(err), "cannot open", fixed = TRUE)
  expect_identical(folder_state(site), before)
})
