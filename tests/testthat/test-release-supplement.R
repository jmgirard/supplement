# check_supplement() is mocked in these tests, so they need no render and
# no git. Its own tests are in test-check-supplement.R.

# Make check_supplement() return `rows` with the `skipped` attribute, and
# count its calls in the returned environment.
mock_check <- function(rows = problem_rows(), skipped = character(), env = parent.frame()) {
  calls <- new.env()
  calls$n <- 0L
  local_mocked_bindings(
    check_supplement = function(path = ".") {
      calls$n <- calls$n + 1L
      attr(rows, "skipped") <- skipped
      invisible(rows)
    },
    .env = env
  )
  calls
}

# A site whose _supplement.yml is the template's, with its version line
# replaced by `version_line` (or removed when it is NULL). `crlf` gives the
# file CRLF line endings.
release_site <- function(version_line = '  version: ""', crlf = FALSE, env = parent.frame()) {
  dir <- withr::local_tempdir("release-", .local_envir = env)
  lines <- readLines(file.path(template_dir(), "_supplement.yml"), encoding = "UTF-8")
  at <- which(lines == '  version: ""')
  stopifnot(length(at) == 1)
  lines <- if (is.null(version_line)) lines[-at] else replace(lines, at, version_line)
  text <- paste0(paste(lines, collapse = if (crlf) "\r\n" else "\n"), if (crlf) "\r\n" else "\n")
  writeBin(charToRaw(enc2utf8(text)), file.path(dir, "_supplement.yml"))
  dir
}

site_version <- function(dir) {
  yaml::read_yaml(file.path(dir, "_supplement.yml"))$supplement$version
}

release_commands <- function(v) {
  c(
    "git status",
    "git add -A",
    sprintf('git commit -m "Release v%s"', v),
    sprintf("git tag v%s", v),
    "git push",
    sprintf("git push origin v%s", v),
    sprintf("gh release create v%s --generate-notes", v)
  )
}

release <- function(...) {
  suppressMessages(release_supplement(...))
}

# Bump ------------------------------------------------------------------------

test_that("a word raises that part of the version and sets the later parts to 0", {
  mock_check()
  cases <- list(
    c("1.2.3", "patch", "1.2.4"),
    c("1.2.3", "minor", "1.3.0"),
    c("1.2.3", "major", "2.0.0"),
    c("0.9.9", "major", "1.0.0"),
    c("1.9.0", "minor", "1.10.0"),
    c("1.2.9", "patch", "1.2.10"),
    c("", "patch", "0.0.1"),
    c("", "minor", "0.1.0"),
    c("", "major", "1.0.0"),
    # Larger than R's whole numbers, so the parts are not read as numbers.
    c("1.2.99999999999999999999", "patch", "1.2.100000000000000000000")
  )
  for (case in cases) {
    dir <- release_site(sprintf('  version: "%s"', case[1]))
    out <- release(case[2], path = dir)
    expect_identical(site_version(dir), case[3], label = paste(case, collapse = " "))
    expect_identical(out, release_commands(case[3]))
  }
})

test_that("a version in bump is accepted only when it is greater, part by part as numbers", {
  mock_check()
  accepted <- list(
    c("1.2.3", "1.10.0"),
    c("1.2.3", "1.2.4"),
    c("1.2.3", "2.0.0"),
    c("9.9.9", "10.0.0"),
    c("", "1.0.0"),
    c("", "0.0.1")
  )
  for (case in accepted) {
    dir <- release_site(sprintf('  version: "%s"', case[1]))
    release(case[2], path = dir)
    expect_identical(site_version(dir), case[2])
  }

  refused <- list(
    c("1.2.3", "1.2.3"),
    c("1.2.3", "1.2.2"),
    c("1.10.0", "1.9.0"),
    c("10.0.0", "9.9.9"),
    c("", "0.0.0")
  )
  for (case in refused) {
    dir <- release_site(sprintf('  version: "%s"', case[1]))
    before <- folder_state(dir)
    err <- expect_error(release(case[2], path = dir), class = "supplement_error_version")
    expect_match(conditionMessage(err), case[2], fixed = TRUE)
    expect_identical(folder_state(dir), before)
  }
})

test_that("a bump that is not a word or a version is refused before check_supplement() runs", {
  calls <- mock_check()
  bad <- list("Patch", "1.0", "v1.0.0", "01.0.0", "1.0.0-rc1", " patch", "", NA_character_,
              c("patch", "minor"), 1, NULL, character())
  dir <- release_site('  version: "1.2.3"')
  before <- folder_state(dir)
  for (bump in bad) {
    expect_error(release(bump, path = dir), class = "supplement_error_argument")
  }
  expect_error(release(path = dir), class = "supplement_error_argument")
  expect_error(release("patch", path = NA_character_), class = "supplement_error_argument")
  expect_identical(folder_state(dir), before)
  expect_identical(calls$n, 0L)
})

test_that("a current version that is not valid, or that YAML reads as a number, is refused", {
  calls <- mock_check()
  cases <- list(
    supplement_error_version = '  version: "01.0.0"',
    supplement_error_version = '  version: "1.0"',
    supplement_error_field_type = "  version: 1.10",
    supplement_error_field_type = "  version: 2"
  )
  for (i in seq_along(cases)) {
    dir <- release_site(cases[[i]])
    before <- folder_state(dir)
    expect_error(release("patch", path = dir), class = names(cases)[i])
    expect_identical(folder_state(dir), before)
  }
  expect_identical(calls$n, 0L)
})

# Release checks -----------------------------------------------------------

test_that("a problem from check_supplement() stops the release with the number of problems", {
  rows <- problem_rows(
    c("broken-link", "doi-mismatch", "doi-mismatch"),
    c("docs/index.html", "docs/index.html", "CITATION.cff"),
    c("A", "B", "C")
  )
  calls <- mock_check(rows)
  dir <- release_site('  version: "1.2.3"')
  writeLines("old", file.path(dir, "CITATION.cff"))
  before <- folder_state(dir)
  err <- expect_error(release("patch", path = dir), class = "supplement_error_release_check")
  # The CITATION.cff DOI row does not count, because the release writes
  # that file again.
  expect_match(conditionMessage(err), "2 problems", fixed = TRUE)
  expect_identical(folder_state(dir), before)
  expect_identical(calls$n, 1L)
})

test_that("one problem of any other check stops the release", {
  checks <- c("large-file", "saved-object", "no-stored-output", "not-rendered", "broken-link")
  for (check in checks) {
    mock_check(problem_rows(check, "x", "A problem."))
    dir <- release_site('  version: "1.2.3"')
    before <- folder_state(dir)
    err <- expect_error(release("patch", path = dir), class = "supplement_error_release_check")
    expect_match(conditionMessage(err), "1 problem", fixed = TRUE)
    expect_identical(folder_state(dir), before)
  }
})

test_that("skipped git checks stop the release", {
  mock_check(skipped = c("large-file", "saved-object"))
  dir <- release_site('  version: "1.2.3"')
  before <- folder_state(dir)
  err <- expect_error(release("patch", path = dir), class = "supplement_error_release_check")
  expect_match(conditionMessage(err), "large-file", fixed = TRUE)
  expect_identical(folder_state(dir), before)
})

test_that("a release that only the CITATION.cff DOI row would block goes ahead", {
  mock_check(problem_rows("doi-mismatch", "CITATION.cff", "Its DOI is missing."))
  dir <- release_site('  version: "1.2.3"')
  writeLines("old", file.path(dir, "CITATION.cff"))
  release("minor", path = dir)
  expect_identical(site_version(dir), "1.3.0")
  expect_identical(read_cff(dir)$version, "1.3.0")
})

test_that("a site with no one-line version value is refused with the line to add", {
  calls <- mock_check()
  cases <- list(
    missing = list(line = NULL, shown = 'version: ""'),
    literal = list(line = "  version: |\n    1.2.3", shown = 'version: "1.2.3"'),
    flow = list(line = '  version: ["1.2.3"]', shown = NULL)
  )
  for (name in names(cases)) {
    dir <- release_site(cases[[name]]$line)
    before <- folder_state(dir)
    if (is.null(cases[[name]]$shown)) {
      # A list where one value belongs is refused when the version is read.
      expect_error(release("patch", path = dir), class = "supplement_error_field_type")
    } else {
      err <- expect_error(release("patch", path = dir), class = "supplement_error_no_version")
      expect_match(conditionMessage(err), cases[[name]]$shown, fixed = TRUE)
    }
    expect_identical(folder_state(dir), before, label = name)
  }
  expect_identical(calls$n, 0L)
})

test_that("a folder with no _supplement.yml is refused", {
  mock_check()
  dir <- withr::local_tempdir("release-")
  expect_error(release("patch", path = dir), class = "supplement_error_no_metadata")
  expect_identical(list.files(dir, all.files = TRUE, no.. = TRUE), character())
})

# The version line --------------------------------------------------------

test_that("only the value on the version line changes", {
  mock_check()
  cases <- list(
    template = c('  version: ""', '  version: "0.1.0"'),
    comment = c('  version: "0.0.9"  # the site version', '  version: "0.1.0"  # the site version'),
    single = c("  version: '0.0.9'", '  version: "0.1.0"'),
    plain = c("  version: 0.0.9", '  version: "0.1.0"')
  )
  for (crlf in c(FALSE, TRUE)) {
    for (name in names(cases)) {
      old <- cases[[name]][1]
      new <- cases[[name]][2]
      dir <- release_site(old, crlf = crlf)
      file <- file.path(dir, "_supplement.yml")
      bytes <- read_bytes(file)
      release("minor", path = dir)

      end <- if (crlf) "\r\n" else "\n"
      expected <- sub(paste0("\n", old, end), paste0("\n", new, end), rawToChar(bytes), fixed = TRUE)
      expect_false(identical(expected, rawToChar(bytes)))
      expect_identical(read_bytes(file), charToRaw(expected), label = paste(name, crlf))
    }
  }
})

test_that("a change that the yaml package does not read back as the new version is refused", {
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  before <- folder_state(dir)
  local_mocked_bindings(yaml_replaced = function(...) FALSE)
  expect_error(release("patch", path = dir), class = "supplement_error_yaml")
  expect_identical(folder_state(dir), before)
})

# Writes and restore ------------------------------------------------------

test_that("CITATION.cff and .zenodo.json are written with the new version", {
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  writeLines("old", file.path(dir, "CITATION.cff"))
  writeLines("old", file.path(dir, ".zenodo.json"))
  release("major", path = dir)
  expect_identical(read_cff(dir)$version, "2.0.0")
  expect_identical(read_zenodo(dir)$version, "2.0.0")
  expect_identical(read_cff(dir)$title, "Supplemental materials for: Title of the paper")
})

test_that("a failed write puts back the files as they were", {
  mock_check()
  # Write part of the file, then fail.
  fail_on <- function(name) {
    function(text, file) {
      if (basename(file) == name) {
        writeLines("partial", file)
        stop("disk full")
      }
      con <- file(file, open = "wb")
      on.exit(close(con))
      writeLines(enc2utf8(text), con, useBytes = TRUE)
    }
  }
  for (name in c("CITATION.cff", ".zenodo.json")) {
    for (existing in c(TRUE, FALSE)) {
      dir <- release_site('  version: "1.2.3"')
      if (existing) {
        writeLines("old citation", file.path(dir, "CITATION.cff"))
        writeLines("old zenodo", file.path(dir, ".zenodo.json"))
      }
      before <- folder_state(dir)
      local_mocked_bindings(write_utf8 = fail_on(name))
      err <- expect_error(release("patch", path = dir), class = "supplement_error_release_write")
      expect_match(conditionMessage(err$parent), "disk full", fixed = TRUE)
      expect_identical(folder_state(dir), before, label = paste(name, existing))
    }
  }
})

test_that("a file that cannot be put back is named in the error", {
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  writeLines("old citation", file.path(dir, "CITATION.cff"))
  real_write_checked <- write_checked
  local_mocked_bindings(
    write_utf8 = function(text, file) stop("disk full"),
    write_checked = function(bytes, file, ...) {
      if (basename(file) == "CITATION.cff") stop("still full")
      real_write_checked(bytes, file, ...)
    }
  )
  err <- expect_error(release("patch", path = dir), class = "supplement_error_release_write")
  expect_match(conditionMessage(err), "CITATION\\.cff.? could not be put back")
  expect_no_match(conditionMessage(err), "got their old text back", fixed = TRUE)
  expect_identical(site_version(dir), "1.2.3")
})

test_that("an empty citation, which stops write_zenodo(), puts back the files", {
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  file <- file.path(dir, "_supplement.yml")
  lines <- readLines(file)
  lines <- sub("^  citation: .*$", '  citation: ""', lines)
  writeLines(lines, file)
  writeLines("old citation", file.path(dir, "CITATION.cff"))
  before <- folder_state(dir)

  err <- expect_error(release("patch", path = dir), class = "supplement_error_release_write")
  expect_s3_class(err$parent, "supplement_error_missing_field")
  expect_identical(folder_state(dir), before)
})

# Commands ------------------------------------------------------------------

test_that("the release commands are printed and returned", {
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  msgs <- character()
  out <- withCallingHandlers(
    release_supplement("minor", path = dir),
    message = function(m) {
      msgs <<- c(msgs, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(out, release_commands("1.3.0"))
  printed <- paste(msgs, collapse = "")
  for (command in release_commands("1.3.0")) {
    expect_match(printed, command, fixed = TRUE)
  }
  expect_match(printed, "version-doi", fixed = TRUE)
  expect_match(printed, "render", fixed = TRUE)
  expect_invisible(release("patch", path = dir))
})

test_that("release_supplement() starts no process of its own", {
  source <- test_path("..", "..", "R", "release-supplement.R")
  skip_if_not(file.exists(source), "the package source is not here")
  rx <- "\\b(git_run|git_files|system2?|processx|callr|shell)\\s*(::|\\()"
  lines <- readLines(source)
  expect_gt(length(lines), 0)
  expect_false(any(grepl(rx, lines, perl = TRUE)))
  # The pattern finds the git helper where it is called.
  expect_true(any(grepl(rx, readLines(test_path("..", "..", "R", "check-supplement.R")), perl = TRUE)))
})
