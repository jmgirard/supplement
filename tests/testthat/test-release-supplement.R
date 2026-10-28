# check_supplement() is mocked in most of these tests, so they need no
# render and no git. The tests that run the printed commands in a git
# repository, the tests of the release address, which set an origin
# remote in a git repository, and the test of a stale-output row use git,
# and that last test runs the real check. Its own tests are in
# test-check-supplement.R.

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

# The commands for version `v`, written here by hand, not taken from the
# package's own list.
expected_commands <- function(v) {
  c(
    "git status -- .",
    "git add -A -- .",
    sprintf('git commit -m "Release v%s" -- .', v),
    "git push"
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
    expect_identical(out, expected_commands(case[3]))
  }
})

test_that("a bump with names or a class works as the plain string", {
  mock_check()
  methods::setClass("version_string", contains = "character", where = environment())
  # The version cases test the attribute drop, because the version is
  # written as given. A word gives a new string, so its cases pass either
  # way.
  bumps <- list(c(v = "1.3.0"), structure("1.3.0", class = "my_class"),
                methods::new("version_string", "1.3.0"),
                c(v = "minor"), structure("minor", class = "my_class"))
  for (bump in bumps) {
    dir <- release_site('  version: "1.2.3"')
    out <- release(bump, path = dir)
    expect_identical(site_version(dir), "1.3.0")
    expect_identical(out, expected_commands("1.3.0"))
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
              c("patch", "minor"), 1, NULL, character(),
              # A line break or a space before, after, or inside a version:
              # the five values that AC2 names, and the same shapes of a
              # version greater than the current one.
              "1.2.3\n", "1.2.3 ", "1.2.3\r\n", " 1.2.3", "1.2\n.3",
              "1.2.4\n", "1.2.4 ", "1.2.4\r\n", " 1.2.4", "1.2\n.4", "\n1.2.4", "1.2.4\t")
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
    supplement_error_field_type = "  version: 2",
    supplement_error_field_type = "  version: true",
    supplement_error_field_type = '  version: ["1.2.3"]'
  )
  for (i in seq_along(cases)) {
    dir <- release_site(cases[[i]])
    before <- folder_state(dir)
    expect_error(release("patch", path = dir), class = names(cases)[i])
    expect_identical(folder_state(dir), before)
  }
  expect_identical(calls$n, 0L)
})

test_that("a current version is read with its outer spaces and line breaks removed", {
  mock_check()
  # "\n" inside double quotes is a line break in YAML.
  dir <- release_site('  version: "1.2.3\\n"')
  expect_identical(site_version(dir), "1.2.3\n")
  release("patch", path = dir)
  expect_identical(site_version(dir), "1.2.4")
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
  checks <- c("large-file", "saved-object", "ignored-output", "no-stored-output", "stale-output",
              "leftover-output", "not-rendered", "broken-link", "unpublished-figure", "placeholder")
  for (check in checks) {
    mock_check(problem_rows(check, "x", "A problem."))
    dir <- release_site('  version: "1.2.3"')
    before <- folder_state(dir)
    err <- expect_error(release("patch", path = dir), class = "supplement_error_release_check")
    expect_match(conditionMessage(err), "1 problem", fixed = TRUE)
    expect_identical(folder_state(dir), before)
  }
})

# A site in a git repository with a docs/ folder that holds a copy of
# figures/, and stored output for its one report with the report's hash,
# so that the real check finds no problem. With `placeholders = FALSE`, the
# template's placeholders stay in place.
checked_site <- function(env = parent.frame(), placeholders = TRUE) {
  site <- git_site(env)
  if (placeholders) fill_placeholders(site)
  dir.create(file.path(site, "docs"))
  file.copy(file.path(site, "figures"), file.path(site, "docs"), recursive = TRUE)
  report <- file.path(site, "analyses", "example.qmd")
  stored <- file.path(site, "_freeze", "analyses", "example", "execute-results", "html.json")
  dir.create(dirname(stored), recursive = TRUE)
  writeBin(charToRaw(sprintf('{"hash": "%s", "result": {}}', unname(tools::md5sum(report)))), stored)
  site
}

test_that("template placeholders from the real check stop the release", {
  skip_if_no_git()
  site <- checked_site(placeholders = FALSE)
  result <- suppressMessages(check_supplement(site))
  expect_setequal(
    paste(result$check, result$file),
    paste("placeholder", c("_supplement.yml", "_quarto.yml", "index.qmd", "LICENSE.md", "LICENSE-CC-BY.md",
                           "_README.md", "analyses/example.qmd", "data/example.csv"))
  )

  before <- folder_state(site)
  err <- expect_error(release("1.0.0", path = site), class = "supplement_error_release_check")
  expect_match(conditionMessage(err), "8 problems", fixed = TRUE)
  expect_identical(folder_state(site), before)

  fill_placeholders(site)
  report <- file.path(site, "analyses", "example.qmd")
  stored <- file.path(site, "_freeze", "analyses", "example", "execute-results", "html.json")
  writeBin(charToRaw(sprintf('{"hash": "%s", "result": {}}', unname(tools::md5sum(report)))), stored)
  release("1.0.0", path = site)
  expect_identical(site_version(site), "1.0.0")
})

test_that("a stale-output row from the real check stops the release", {
  skip_if_no_git()
  site <- checked_site()
  report <- file.path(site, "analyses", "example.qmd")
  stored <- file.path(site, "_freeze", "analyses", "example", "execute-results", "html.json")
  writeBin(charToRaw('{"hash": "0", "result": {}}'), stored)
  result <- suppressMessages(check_supplement(site))
  expect_identical(paste(result$check, result$file), "stale-output analyses/example.qmd")
  expect_identical(attr(result, "skipped"), character())

  before <- folder_state(site)
  err <- expect_error(release("1.0.0", path = site), class = "supplement_error_release_check")
  expect_match(conditionMessage(err), "1 problem", fixed = TRUE)
  expect_identical(folder_state(site), before)

  # With the report's own hash, the same site releases.
  writeBin(charToRaw(sprintf('{"hash": "%s", "result": {}}', unname(tools::md5sum(report)))), stored)
  release("1.0.0", path = site)
  expect_identical(site_version(site), "1.0.0")
})

test_that("the release runs the real check without the web link check", {
  skip_if_no_git()
  site <- checked_site()
  writeLines('<a href="https://example.org/x">x</a>', file.path(site, "docs", "index.html"))
  calls <- new.env()
  calls$n <- 0L
  local_mocked_bindings(url_status = function(url) {
    calls$n <- calls$n + 1L
    404L
  })
  release("1.0.0", path = site)
  expect_identical(site_version(site), "1.0.0")
  expect_identical(calls$n, 0L)
})

test_that("the release runs the real check without the renv.lock comparison", {
  skip_if_no_git()
  site <- checked_site()
  report <- file.path(site, "analyses", "example.qmd")
  stored <- file.path(site, "_freeze", "analyses", "example", "execute-results", "html.json")
  markdown <- "R version 4.6.1 (2026-06-24)\n\nother attached packages:\n[1] dplyr_1.1.3"
  json <- list(hash = unname(tools::md5sum(report)), result = list(markdown = markdown))
  writeLines(jsonlite::toJSON(json, auto_unbox = TRUE), stored)
  writeLines('{"R": {"Version": "4.6.1"}, "Packages": {"dplyr": {"Package": "dplyr", "Version": "1.1.4"}}}',
             file.path(site, "renv.lock"))
  withr::local_envvar(RENV_PROFILE = NA)
  result <- suppressMessages(check_supplement(site, renv_lock = TRUE))
  expect_identical(paste(result$check, result$file), "renv-mismatch analyses/example.qmd")

  release("1.0.0", path = site)
  expect_identical(site_version(site), "1.0.0")
})

test_that("the release goes ahead with a package that renv.lock does not record", {
  skip_if_no_git()
  site <- checked_site()
  report <- file.path(site, "analyses", "example.qmd")
  stored <- file.path(site, "_freeze", "analyses", "example", "execute-results", "html.json")
  markdown <- "R version 4.6.1 (2026-06-24)\n\nother attached packages:\n[1] dplyr_1.1.4"
  json <- list(hash = unname(tools::md5sum(report)), result = list(markdown = markdown))
  writeLines(jsonlite::toJSON(json, auto_unbox = TRUE), stored)
  writeLines('{"R": {"Version": "4.6.1"}, "Packages": {}}', file.path(site, "renv.lock"))
  withr::local_envvar(RENV_PROFILE = NA)
  result <- suppressMessages(check_supplement(site, renv_lock = TRUE))
  expect_identical(paste(result$check, result$file), "renv-missing analyses/example.qmd")

  release("1.0.0", path = site)
  expect_identical(site_version(site), "1.0.0")
})

test_that("an ignored-output or an unpublished-figure row from the real check stops the release", {
  skip_if_no_git()
  put <- function(site, file) {
    dir.create(dirname(file.path(site, file)), showWarnings = FALSE, recursive = TRUE)
    writeBin(as.raw(1:4), file.path(site, file))
  }
  # The template's .gitignore ignores *.rds, also in docs/.
  cases <- c("ignored-output" = "docs/data/x.rds", "unpublished-figure" = "figures/new.png")
  for (check in names(cases)) {
    site <- checked_site()
    result <- suppressMessages(check_supplement(site))
    expect_identical(nrow(result), 0L, info = check)
    put(site, cases[[check]])
    result <- suppressMessages(check_supplement(site))
    expect_identical(paste(result$check, result$file), paste(check, cases[[check]]))
    expect_identical(attr(result, "skipped"), character())

    before <- folder_state(site)
    err <- expect_error(release("1.0.0", path = site), class = "supplement_error_release_check")
    expect_match(conditionMessage(err), "1 problem", fixed = TRUE)
    expect_identical(folder_state(site), before, info = check)
  }
})

test_that("skipped git checks stop the release", {
  mock_check(skipped = c("large-file", "saved-object"))
  dir <- release_site('  version: "1.2.3"')
  before <- folder_state(dir)
  err <- expect_error(release("patch", path = dir), class = "supplement_error_release_check")
  expect_match(conditionMessage(err), "large-file", fixed = TRUE)
  expect_match(conditionMessage(err), "0 problems", fixed = TRUE)
  expect_identical(folder_state(dir), before)

  # Skipped checks and a problem together give the number too.
  mock_check(problem_rows("broken-link", "docs/index.html", "A"), skipped = c("large-file", "saved-object"))
  err <- expect_error(release("patch", path = dir), class = "supplement_error_release_check")
  expect_match(conditionMessage(err), "1 problem ", fixed = TRUE)
  expect_match(conditionMessage(err), "saved-object", fixed = TRUE)
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

test_that("a _supplement.yml that is not valid YAML stops before the checks", {
  calls <- mock_check()
  dir <- withr::local_tempdir("release-")
  writeLines(c("supplement:", '  citation: [x'), file.path(dir, "_supplement.yml"))
  before <- folder_state(dir)
  err <- expect_error(release("patch", path = dir), class = "supplement_error_parse")
  expect_true(inherits(err, "supplement_error_parse"))
  expect_true(inherits(err, "supplement_error"))
  expect_match(conditionMessage(err), "_supplement.yml", fixed = TRUE)
  expect_identical(folder_state(dir), before)
  expect_identical(calls$n, 0L)
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
  real_write_checked <- write_checked
  for (name in c("_supplement.yml", "CITATION.cff", ".zenodo.json")) {
    for (existing in c(TRUE, FALSE)) {
      dir <- release_site('  version: "1.2.3"')
      if (existing) {
        writeLines("old citation", file.path(dir, "CITATION.cff"))
        writeLines("old zenodo", file.path(dir, ".zenodo.json"))
      }
      before <- folder_state(dir)
      # The first write of `name` writes part of the file and fails. The
      # put-back then writes as usual.
      failed <- FALSE
      local_mocked_bindings(write_checked = function(bytes, file, ...) {
        if (!failed && basename(file) == name) {
          failed <<- TRUE
          writeBin(charToRaw("partial"), file)
          stop("disk full")
        }
        real_write_checked(bytes, file, ...)
      })
      err <- expect_error(release("patch", path = dir), class = "supplement_error_release_write")
      expect_true(failed, label = paste(name, existing))
      expect_match(conditionMessage(err$parent), "disk full", fixed = TRUE)
      expect_identical(folder_state(dir), before, label = paste(name, existing))
    }
  }
})

test_that("the release writes the bytes that the writers write from the released file", {
  mock_check()
  outputs <- c("CITATION.cff", ".zenodo.json")
  expect_writer_bytes <- function(dir, label) {
    release("major", path = dir)
    released <- lapply(file.path(dir, outputs), read_bytes)
    expect_identical(site_version(dir), "2.0.0", label = label)
    write_citation(dir, overwrite = TRUE)
    write_zenodo(dir, overwrite = TRUE)
    expect_identical(lapply(file.path(dir, outputs), read_bytes), released, label = label)
  }
  expect_writer_bytes(release_site('  version: "1.2.3"'), "LF")
  expect_writer_bytes(release_site('  version: "1.2.3"', crlf = TRUE), "CRLF")

  # A site with a UTF-8 byte order mark, every value that the outputs hold,
  # and text that YAML could read as something else.
  for (probe in names(probe_values)) {
    dir <- withr::local_tempdir("release-")
    text <- c(
      "supplement:",
      paste("  paper-title:", yaml_quote(probe_values[[probe]])),
      paste("  citation:", yaml_quote(paste("Cited as", probe_values[[probe]]))),
      '  version: "1.2.3"',
      "  license:",
      '    code: "MIT"',
      '    content: "CC-BY-4.0"',
      "  authors:",
      '    - family: "Müller"',
      '      given: "Änne"',
      '      orcid: "0000-0002-1694-233X"',
      '      affiliation: "Institut B"',
      "  zenodo:",
      '    version-doi: ""',
      '    concept-doi: "10.5281/zenodo.1"',
      '    archive-url: ""'
    )
    bytes <- c(as.raw(c(0xef, 0xbb, 0xbf)), charToRaw(enc2utf8(paste0(paste(text, collapse = "\n"), "\n"))))
    writeBin(bytes, file.path(dir, "_supplement.yml"))
    expect_writer_bytes(dir, probe)
    expect_identical(read_bytes(file.path(dir, "_supplement.yml"))[1:3], as.raw(c(0xef, 0xbb, 0xbf)))
    expect_identical(read_cff(dir)$title, paste("Supplemental materials for:", probe_values[[probe]]), label = probe)
  }
})

test_that("a site path with pattern characters puts back only its own files", {
  mock_check()
  base <- withr::local_tempdir("release-")
  # "site[ab]" read as a pattern matches "sitea", which holds its own
  # CITATION.cff.
  dir <- file.path(base, "site[ab]")
  sibling <- file.path(base, "sitea")
  dir.create(dir)
  dir.create(sibling)
  file.copy(file.path(release_site('  version: "1.2.3"'), "_supplement.yml"), dir)
  writeLines("sibling citation", file.path(sibling, "CITATION.cff"))
  before <- folder_state(dir)
  sibling_before <- folder_state(sibling)
  # CITATION.cff is made in "site[ab]", then the write of .zenodo.json fails.
  made <- FALSE
  real_write_utf8 <- write_utf8
  local_mocked_bindings(write_utf8 = function(text, file, ...) {
    if (basename(file) == ".zenodo.json") {
      made <<- file.exists(file.path(dir, "CITATION.cff"))
      stop("disk full")
    }
    real_write_utf8(text, file, ...)
  })
  err <- expect_error(release("patch", path = dir), class = "supplement_error_release_write")
  expect_match(conditionMessage(err$parent), "disk full", fixed = TRUE)
  expect_true(made)
  expect_identical(folder_state(dir), before)
  expect_identical(folder_state(sibling), sibling_before)
})

test_that("a file that cannot be put back is named in the error", {
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  writeLines("old citation", file.path(dir, "CITATION.cff"))
  real_write_checked <- write_checked
  local_mocked_bindings(
    write_utf8 = function(text, file, ...) {
      writeLines("partial", file)
      stop("disk full")
    },
    write_checked = function(bytes, file, ...) {
      if (basename(file) == "CITATION.cff") stop("still full")
      real_write_checked(bytes, file, ...)
    }
  )
  err <- expect_error(release("patch", path = dir), class = "supplement_error_release_write")
  expect_match(conditionMessage(err), "CITATION\\.cff.? could not be put back")
  expect_no_match(conditionMessage(err), "as they were before the release", fixed = TRUE)
  expect_identical(site_version(dir), "1.2.3")
})

# A link at an output path, to a file that exists or not, stops the release.
# The names, the links, and _supplement.yml stay as they were, and the
# target stays present or missing as before.
expect_link_refused <- function(name, target) {
  dir <- release_site('  version: "1.2.3"')
  outside <- withr::local_tempfile()
  if (target == "present") writeLines("outside", outside)
  symlink_or_skip(outside, file.path(dir, name))
  # folder_state() cannot read a link to a missing file, so compare the
  # names, the links, and _supplement.yml.
  state <- function() {
    names <- list.files(dir, all.files = TRUE, no.. = TRUE)
    list(names, Sys.readlink(file.path(dir, names)), read_bytes(file.path(dir, "_supplement.yml")))
  }
  before <- state()
  expect_true(is_link(file.path(dir, name)), info = paste(name, target))
  expect_error(release("patch", path = dir), class = "supplement_error_file_exists")
  expect_identical(state(), before)
  expect_identical(file.exists(outside), target == "present")
}

test_that("a link to a missing output file is refused before any write", {
  calls <- mock_check()
  for (name in c("CITATION.cff", ".zenodo.json")) expect_link_refused(name, "missing")
  expect_identical(calls$n, 0L)
})

test_that("a linked or unreadable output file is refused before any write", {
  calls <- mock_check()
  for (name in c("CITATION.cff", ".zenodo.json")) expect_link_refused(name, "present")
  expect_identical(calls$n, 0L)

  skip_on_os("windows")
  dir <- release_site('  version: "1.2.3"')
  cff <- file.path(dir, "CITATION.cff")
  writeLines("old", cff)
  Sys.chmod(cff, "000")
  withr::defer(Sys.chmod(cff, "644"))
  skip_if(file.access(cff, 4) == 0, "the file can still be read, for example as root")
  err <- expect_error(release("patch", path = dir), class = "supplement_error_write")
  expect_match(conditionMessage(err), "Could not read", fixed = TRUE)
  expect_identical(site_version(dir), "1.2.3")
  expect_identical(calls$n, 0L)
})

test_that("an output file, or a folder for a missing one, that cannot be written is refused before any write", {
  skip_on_os("windows")
  calls <- mock_check()
  for (name in c("CITATION.cff", ".zenodo.json")) {
    dir <- release_site('  version: "1.2.3"')
    out <- file.path(dir, name)
    writeLines("old", out)
    Sys.chmod(out, "444")
    withr::defer(Sys.chmod(out, "644"))
    skip_if(file.access(out, 2) == 0, "the file can still be written, for example as root")
    before <- folder_state(dir)
    err <- expect_error(release("patch", path = dir), class = "supplement_error_write")
    expect_match(conditionMessage(err), "Could not write", fixed = TRUE)
    expect_identical(folder_state(dir), before)
    expect_identical(calls$n, 0L)
  }

  # A site folder that cannot be written, with a writable _supplement.yml
  # and no output files.
  dir <- release_site('  version: "1.2.3"')
  Sys.chmod(dir, "555")
  withr::defer(Sys.chmod(dir, "755"))
  skip_if(file.access(dir, 2) == 0, "the folder can still be written, for example as root")
  before <- folder_state(dir)
  err <- expect_error(release("patch", path = dir), class = "supplement_error_write")
  expect_match(conditionMessage(err), "Could not write", fixed = TRUE)
  expect_identical(folder_state(dir), before)
  expect_identical(calls$n, 0L)
})

test_that("a write that only warns, as on a full disk, puts back the files", {
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  writeLines("old citation", file.path(dir, "CITATION.cff"))
  before <- folder_state(dir)
  # The first write is _supplement.yml. The second, CITATION.cff, writes
  # part of its bytes and warns.
  n <- 0L
  local_mocked_bindings(write_bytes = function(bytes, con) {
    n <<- n + 1L
    if (n == 2L) {
      writeBin(bytes[1:5], con)
      warning("No space left on device")
    } else {
      writeBin(bytes, con)
    }
  })
  err <- expect_error(release("patch", path = dir), class = "supplement_error_release_write")
  expect_s3_class(err$parent, "supplement_error_write")
  expect_identical(err$parent$call[[1]], quote(release_supplement))
  expect_identical(folder_state(dir), before)
})

test_that("a failure before any change does not report a file that could not be put back", {
  skip_on_os("windows")
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  file <- file.path(dir, "_supplement.yml")
  Sys.chmod(file, "444")
  withr::defer(Sys.chmod(file, "644"))
  skip_if(file.access(file, 2) == 0, "the file can still be written, for example as root")
  before <- folder_state(dir)
  err <- expect_error(suppressWarnings(release("patch", path = dir)), class = "supplement_error_release_write")
  expect_match(conditionMessage(err), "as they were before the release", fixed = TRUE)
  expect_no_match(conditionMessage(err), "could not be put back", fixed = TRUE)
  expect_identical(folder_state(dir), before)
})

test_that("an interrupt puts back the files, and a failed put-back is reported", {
  mock_check()
  interrupt <- function() signalCondition(structure(class = c("interrupt", "condition"), list()))
  dir <- release_site('  version: "1.2.3"')
  # writeBin(), because writeLines() writes CRLF on Windows and the mock
  # below matches these bytes.
  writeBin(charToRaw("old citation\n"), file.path(dir, "CITATION.cff"))
  before <- folder_state(dir)
  # The write of .zenodo.json is interrupted after CITATION.cff is written.
  real_write_utf8 <- write_utf8
  local_mocked_bindings(write_utf8 = function(text, file, ...) {
    if (basename(file) == ".zenodo.json") interrupt()
    real_write_utf8(text, file, ...)
  })
  # The put-back works, so no warning is given.
  expect_no_warning(
    out <- tryCatch(release("patch", path = dir), interrupt = function(c) "interrupted")
  )
  expect_identical(out, "interrupted")
  expect_identical(folder_state(dir), before)

  real_write_checked <- write_checked
  old <- charToRaw("old citation\n")
  local_mocked_bindings(write_checked = function(bytes, file, ...) {
    if (identical(bytes, old)) stop("still full")
    real_write_checked(bytes, file, ...)
  })
  expect_warning(
    tryCatch(release("patch", path = dir), interrupt = function(c) NULL),
    "could not be put back"
  )
})

expect_released <- function(dir, version) {
  expect_identical(site_version(dir), version)
  expect_identical(read_cff(dir)$version, version)
  expect_identical(read_zenodo(dir)$version, version)
}

test_that("a failure while printing the commands keeps the released files", {
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  local_mocked_bindings(report_release = function(...) stop("console closed"))
  err <- expect_error(release("patch", path = dir))
  expect_identical(conditionMessage(err), "console closed")
  expect_identical(class(err), c("simpleError", "error", "condition"))
  expect_released(dir, "1.2.4")
})

test_that("a failure while reading the origin address keeps the released files", {
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  local_mocked_bindings(origin_url = function(path) stop("git failed"))
  err <- expect_error(release("patch", path = dir))
  expect_identical(conditionMessage(err), "git failed")
  expect_identical(class(err), c("simpleError", "error", "condition"))
  expect_released(dir, "1.2.4")
})

test_that("an interrupt while printing the commands keeps the released files", {
  mock_check()
  dir <- release_site('  version: "1.2.3"')
  local_mocked_bindings(report_release = function(...) {
    signalCondition(structure(class = c("interrupt", "condition"), list()))
  })
  ran <- FALSE
  expect_no_warning(
    tryCatch(release("patch", path = dir), interrupt = function(c) ran <<- TRUE)
  )
  expect_true(ran)
  expect_released(dir, "1.2.4")
})

test_that("an empty current version is named as empty in the not-greater error", {
  mock_check()
  dir <- release_site()
  err <- expect_error(release("0.0.0", path = dir), class = "supplement_error_version")
  expect_match(conditionMessage(err), "empty, which counts as 0.0.0", fixed = TRUE)
})

test_that("the CITATION.cff DOI row that check_supplement() makes is the one the release lets through", {
  dir <- release_site('  version: "1.2.3"')
  file <- file.path(dir, "_supplement.yml")
  writeLines(sub('concept-doi: ""', 'concept-doi: "10.5281/zenodo.1"', readLines(file)), file)
  writeLines(c("cff-version: 1.2.0", "doi: 10.5281/zenodo.9"), file.path(dir, "CITATION.cff"))
  rows <- check_dois(dir, read_supplement(dir))
  expect_identical(rows$check, "doi-mismatch")
  expect_identical(rows$file, "CITATION.cff")
  attr(rows, "skipped") <- character()
  expect_no_error(check_release_problems(rows))

  # A badge row from the same check still stops the release.
  rows$file <- "docs/index.html"
  expect_error(check_release_problems(rows), class = "supplement_error_release_check")
})

# Value checks before any write -----------------------------------------------

# A release site with version "1.2.3" whose first line of _supplement.yml
# that matches `pattern` is replaced by `replacement`. It writes "\n" line
# endings on every system, so that only that line changes.
value_site <- function(pattern, replacement, env = parent.frame()) {
  dir <- release_site('  version: "1.2.3"', env = env)
  file <- file.path(dir, "_supplement.yml")
  lines <- readLines(file, encoding = "UTF-8")
  i <- grep(pattern, lines)[1]
  stopifnot(!is.na(i))
  lines[i] <- sub(pattern, replacement, lines[i])
  writeBin(charToRaw(enc2utf8(paste0(paste(lines, collapse = "\n"), "\n"))), file)
  dir
}

# Values that stop write_citation() or write_zenodo(), with the class of
# the error.
bad_values <- list(
  list(pattern = "^  citation: .*$", replacement = '  citation: ""',
       class = "supplement_error_missing_field"),
  list(pattern = '^    concept-doi: ""$', replacement = '    concept-doi: "not a doi"',
       class = "supplement_error_doi"),
  list(pattern = '^    content: "CC-BY-4.0"$', replacement = '    content: "CC BY 4.0"',
       class = "supplement_error_license"),
  # The check digit of the example iD 0000-0002-1825-0097 is 7.
  list(pattern = '^      orcid: ""$', replacement = '      orcid: "0000-0002-1825-0098"',
       class = "supplement_error_orcid"),
  list(pattern = '^    - family: "Author"$', replacement = '    - family: ""',
       class = "supplement_error_author_name")
)

test_that("a value that stops a writer stops the release before the check and before any write", {
  for (bad in bad_values) {
    calls <- mock_check()
    dir <- value_site(bad$pattern, bad$replacement)
    writeLines("old citation", file.path(dir, "CITATION.cff"))
    before <- folder_state(dir)
    err <- expect_error(release("patch", path = dir), class = bad$class)
    # expect_error() also matches the class of a parent error, so check the
    # error itself.
    expect_true(inherits(err, bad$class), label = bad$class)
    expect_false(inherits(err, "supplement_error_release_write"), label = bad$class)
    expect_identical(calls$n, 0L, label = bad$class)
    expect_identical(folder_state(dir), before, label = bad$class)
  }
})

test_that("an error from a value check names release_supplement()", {
  mock_check()
  dir <- value_site("^  paper-title: .*$", '  paper-title: ""')
  err <- expect_error(release("patch", path = dir), class = "supplement_error_missing_field")
  expect_identical(err$call[[1]], quote(release_supplement))
})

test_that("a value error comes before the refusal of a linked output", {
  calls <- mock_check()
  dir <- value_site("^  citation: .*$", '  citation: ""')
  outside <- withr::local_tempfile(lines = "outside")
  symlink_or_skip(outside, file.path(dir, "CITATION.cff"))
  before <- list(Sys.readlink(file.path(dir, "CITATION.cff")), read_bytes(file.path(dir, "_supplement.yml")))
  expect_error(release("patch", path = dir), class = "supplement_error_missing_field")
  expect_identical(list(Sys.readlink(file.path(dir, "CITATION.cff")), read_bytes(file.path(dir, "_supplement.yml"))), before)
  expect_identical(readLines(outside), "outside")
  expect_identical(calls$n, 0L)
})

# Changes during the check ------------------------------------------------

# Make check_supplement() run `edit` on the site folder, keep the folder's
# state after the edit in the returned environment, and return `rows`.
mock_check_edit <- function(edit, rows = problem_rows(), env = parent.frame()) {
  seen <- new.env()
  local_mocked_bindings(
    check_supplement = function(path = ".") {
      edit(path)
      seen$state <- folder_state(path)
      attr(rows, "skipped") <- character()
      invisible(rows)
    },
    .env = env
  )
  seen
}

# Evaluate `expr` and add each message that it prints to `out$msgs`.
capture_messages_to <- function(expr, out) {
  withCallingHandlers(expr, message = function(m) {
    out$msgs <- c(out$msgs, conditionMessage(m))
    invokeRestart("muffleMessage")
  })
}

# Run the release and return the messages that it printed.
release_messages <- function(...) {
  out <- new.env()
  out$msgs <- character()
  capture_messages_to(release_supplement(...), out)
  out$msgs
}

release_files <- c("_supplement.yml", "CITATION.cff", ".zenodo.json")

# Expect the release of `dir` to stop with supplement_error_changed, with
# a message that names the files in `changed` and no other, the folder as
# the edit left it, and no command printed.
expect_changed_stop <- function(dir, seen, changed) {
  out <- new.env()
  out$msgs <- character()
  err <- expect_error(
    capture_messages_to(release_supplement("patch", path = dir), out),
    class = "supplement_error_changed"
  )
  expect_s3_class(err, "supplement_error")
  for (name in release_files) {
    expect_identical(grepl(name, conditionMessage(err), fixed = TRUE), name %in% changed, label = name)
  }
  expect_false(is.null(seen$state))
  expect_identical(folder_state(dir), seen$state)
  expect_false(any(grepl("git push", out$msgs, fixed = TRUE)))
}

# An edit that replaces the one line of _supplement.yml that matches
# `pattern`. It writes "\n" line endings on every system, as release_site()
# does, so that only that line changes.
edit_yml <- function(pattern, replacement) {
  function(path) {
    file <- file.path(path, "_supplement.yml")
    lines <- readLines(file, encoding = "UTF-8")
    stopifnot(sum(grepl(pattern, lines)) == 1)
    text <- paste0(paste(sub(pattern, replacement, lines), collapse = "\n"), "\n")
    writeBin(charToRaw(enc2utf8(text)), file)
  }
}

test_that("a change to _supplement.yml during the check stops the release", {
  edits <- list(
    title = edit_yml('^  paper-title: .*$', '  paper-title: "Saved during the check"'),
    version = edit_yml('^  version: .*$', '  version: "5.0.0"'),
    comment = edit_yml("^  # A link to the preprint, if there is one\\.$", "  # A changed comment."),
    removed = function(path) file.remove(file.path(path, "_supplement.yml")),
    not_utf8 = function(path) {
      file <- file.path(path, "_supplement.yml")
      writeBin(c(readBin(file, "raw", file.size(file)), as.raw(0xff), as.raw(0x0a)), file)
    }
  )
  for (name in names(edits)) {
    seen <- mock_check_edit(edits[[name]])
    dir <- release_site('  version: "1.2.3"')
    writeLines("old citation", file.path(dir, "CITATION.cff"))
    expect_changed_stop(dir, seen, "_supplement.yml")
  }
})

test_that("the change stop comes before the stop for a problem from check_supplement()", {
  seen <- mock_check_edit(
    edit_yml('^  paper-title: .*$', '  paper-title: "Saved during the check"'),
    rows = problem_rows("broken-link", "docs/index.html", "A problem.")
  )
  dir <- release_site('  version: "1.2.3"')
  expect_changed_stop(dir, seen, "_supplement.yml")
})

test_that("a change to CITATION.cff or .zenodo.json during the check stops the release", {
  cases <- list(
    changed_cff = list(edit = function(path) writeLines("changed citation", file.path(path, "CITATION.cff")),
                       zenodo = FALSE, changed = "CITATION.cff"),
    made_zenodo = list(edit = function(path) writeLines("{}", file.path(path, ".zenodo.json")),
                       zenodo = FALSE, changed = ".zenodo.json"),
    removed_cff = list(edit = function(path) file.remove(file.path(path, "CITATION.cff")),
                       zenodo = FALSE, changed = "CITATION.cff"),
    changed_zenodo = list(edit = function(path) writeLines('{"changed": true}', file.path(path, ".zenodo.json")),
                          zenodo = TRUE, changed = ".zenodo.json"),
    two_files = list(edit = function(path) {
      edit_yml('^  paper-title: .*$', '  paper-title: "Saved during the check"')(path)
      writeLines("changed citation", file.path(path, "CITATION.cff"))
    }, zenodo = FALSE, changed = c("_supplement.yml", "CITATION.cff"))
  )
  for (case in cases) {
    seen <- mock_check_edit(case$edit)
    dir <- release_site('  version: "1.2.3"')
    writeLines("old citation", file.path(dir, "CITATION.cff"))
    if (case$zenodo) writeLines("{}", file.path(dir, ".zenodo.json"))
    stopifnot(file.exists(file.path(dir, ".zenodo.json")) == case$zenodo)
    expect_changed_stop(dir, seen, case$changed)
  }
})

test_that("a check that reads the files but changes none lets the release finish", {
  seen <- mock_check_edit(function(path) {
    readLines(file.path(path, "_supplement.yml"))
    readLines(file.path(path, "CITATION.cff"))
    readLines(file.path(path, ".zenodo.json"))
  })
  dir <- release_site('  version: "1.2.3"')
  writeLines("old citation", file.path(dir, "CITATION.cff"))
  writeLines("{}", file.path(dir, ".zenodo.json"))
  msgs <- release_messages("patch", path = dir)
  expect_identical(site_version(dir), "1.2.4")
  expect_identical(read_cff(dir)$version, "1.2.4")
  expect_identical(jsonlite::read_json(file.path(dir, ".zenodo.json"))$version, "1.2.4")
  expect_true(any(grepl('git commit -m "Release v1.2.4" -- .', msgs, fixed = TRUE)))
})

# Folders at an output --------------------------------------------------------

# Expect the release of `dir` to stop with supplement_error_file_exists,
# the folder to be in the state `state`, and no command printed.
expect_folder_stop <- function(dir, state) {
  out <- new.env()
  out$msgs <- character()
  err <- expect_error(
    capture_messages_to(release_supplement("patch", path = dir), out),
    class = "supplement_error_file_exists"
  )
  # expect_error() also matches the class of a parent error, so check the
  # error itself.
  expect_s3_class(err, "supplement_error_file_exists")
  expect_false(inherits(err, "supplement_error_release_write"))
  expect_false(is.null(state))
  expect_identical(folder_state(dir), state)
  expect_false(any(grepl("git push", out$msgs, fixed = TRUE)))
}

test_that("a folder at an output before the release stops it before the check", {
  for (name in c("CITATION.cff", ".zenodo.json")) {
    calls <- mock_check()
    dir <- release_site('  version: "1.2.3"')
    dir.create(file.path(dir, name))
    before <- folder_state(dir)
    expect_folder_stop(dir, before)
    expect_identical(calls$n, 0L, label = name)
  }
})

test_that("a folder made at an output during the check stops the release", {
  for (name in c("CITATION.cff", ".zenodo.json")) {
    for (file_before in c(FALSE, TRUE)) {
      seen <- mock_check_edit(function(path) {
        target <- file.path(path, name)
        if (file.exists(target)) file.remove(target)
        dir.create(target)
      })
      dir <- release_site('  version: "1.2.3"')
      if (file_before) writeLines("old", file.path(dir, name))
      expect_folder_stop(dir, seen$state)
      expect_true(dir.exists(file.path(dir, name)), label = paste(name, file_before))
    }
  }
})

test_that("a folder made during the check stops the release also when _supplement.yml changed", {
  seen <- mock_check_edit(function(path) {
    edit_yml('^  paper-title: .*$', '  paper-title: "Saved during the check"')(path)
    dir.create(file.path(path, "CITATION.cff"))
  })
  dir <- release_site('  version: "1.2.3"')
  expect_folder_stop(dir, seen$state)
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
  expect_identical(out, expected_commands("1.3.0"))
  printed <- paste(msgs, collapse = "")
  for (command in expected_commands("1.3.0")) {
    expect_match(printed, command, fixed = TRUE)
  }
  expect_match(printed, "version-doi", fixed = TRUE)
  expect_match(printed, "render", fixed = TRUE)
  expect_invisible(release("patch", path = dir))
})

# A git repository in a new temporary folder, with a local user so that
# git_in() can commit. Commit signing and hooks are turned off in the
# repository, because a git older than 2.32 still reads the user's global
# configuration.
git_repo <- function(env = parent.frame()) {
  repo <- withr::local_tempdir("release-repo-", .local_envir = env)
  hooks <- withr::local_tempdir("release-hooks-", .local_envir = env)
  for (args in list(c("init", "-q"), c("config", "user.name", "Test"),
                    c("config", "user.email", "test@example.com"),
                    c("config", "commit.gpgsign", "false"),
                    c("config", "core.hooksPath", shQuote(hooks)))) {
    expect_status(git_in(repo, args))
  }
  repo
}

# Write the template's _supplement.yml with version 1.2.3 into `dir`.
write_site_yml <- function(dir) {
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  expect_true(file.copy(file.path(release_site('  version: "1.2.3"'), "_supplement.yml"), dir))
}

# Run the printed `git add` and `git commit` commands in `dir`. scan()
# splits each command at spaces and keeps the quoted message whole.
run_release_commit <- function(commands, dir) {
  run <- commands[startsWith(commands, "git add") | startsWith(commands, "git commit")]
  expect_length(run, 2)
  for (command in run) {
    args <- scan(text = command, what = "", quiet = TRUE)
    out <- git_in(dir, shQuote(args[-1]))
    expect_identical(out$status, 0L, label = paste(c(command, out$output), collapse = "\n"))
  }
}

# The paths that the last commit changed.
committed_paths <- function(repo) {
  out <- git_in(repo, c("diff-tree", "--root", "--no-commit-id", "--name-only", "-r", "HEAD"))
  expect_status(out)
  out$output
}

test_that("for a site in a subfolder, the release commit holds only files of the site", {
  skip_if_no_git()
  mock_check()
  repo <- git_repo()
  site <- file.path(repo, "site")
  write_site_yml(site)
  writeLines("old", file.path(repo, "tracked.txt"))
  expect_status(git_in(repo, c("add", "-A")))
  expect_status(git_in(repo, c("commit", "-q", "-m", "start")))

  # Three changes outside the site: a changed tracked file, a new file that
  # git does not track, and a new file staged before the release.
  writeLines("new", file.path(repo, "tracked.txt"))
  writeLines("new", file.path(repo, "untracked.txt"))
  writeLines("new", file.path(repo, "staged.txt"))
  expect_status(git_in(repo, c("add", "staged.txt")))

  commands <- release("patch", path = site)
  run_release_commit(commands, site)

  paths <- committed_paths(repo)
  expect_true(all(startsWith(paths, "site/")), label = paste(paths, collapse = ", "))
  expect_true(all(c("site/CITATION.cff", "site/.zenodo.json", "site/_supplement.yml") %in% paths))
  status <- git_in(repo, c("status", "--porcelain"))$output
  expect_true(all(c(" M tracked.txt", "?? untracked.txt", "A  staged.txt") %in% status),
              label = paste(status, collapse = ", "))
})

test_that("for a site at the top of the repository, the release commit holds its new files", {
  skip_if_no_git()
  mock_check()
  repo <- git_repo()
  write_site_yml(repo)
  expect_status(git_in(repo, c("add", "-A")))
  expect_status(git_in(repo, c("commit", "-q", "-m", "start")))
  dir.create(file.path(repo, "docs"))
  writeLines("<html></html>", file.path(repo, "docs", "index.html"))

  commands <- release("patch", path = repo)
  run_release_commit(commands, repo)

  paths <- committed_paths(repo)
  expect_true(all(c("CITATION.cff", "_supplement.yml", "docs/index.html") %in% paths),
              label = paste(paths, collapse = ", "))
})

# Release address -------------------------------------------------------------

# The text that the release of a site at the top of a new git repository
# prints, with `address` as its origin remote, or with no remote when
# `address` is NULL. `push` sets a separate push url for origin. HEAD is
# the branch `branch`, or a detached commit when `branch` is NULL.
# `default` makes refs/remotes/origin/HEAD name that branch of origin.
# `setup`, when given, runs on the repository before the release.
release_text_with_origin <- function(address, push = NULL, branch = "main", default = NULL,
                                     setup = NULL) {
  local_plain_git()
  mock_check()
  repo <- git_repo()
  write_site_yml(repo)
  if (is.null(branch)) {
    expect_status(git_in(repo, c("commit", "-q", "--allow-empty", "-m", "start")))
    expect_status(git_in(repo, c("checkout", "-q", "--detach")))
  } else {
    expect_status(git_in(repo, c("symbolic-ref", "HEAD", shQuote(paste0("refs/heads/", branch)))))
  }
  if (!is.null(address)) {
    expect_status(git_in(repo, c("remote", "add", "origin", shQuote(address))))
    got <- git_in(repo, c("remote", "get-url", "origin"))
    expect_identical(got$output, address)
  }
  if (!is.null(push)) {
    expect_status(git_in(repo, c("remote", "set-url", "--push", "origin", shQuote(push))))
    got <- git_in(repo, c("remote", "get-url", "--push", "origin"))
    expect_identical(got$output, push)
  }
  if (!is.null(default)) {
    expect_status(git_in(repo, c("symbolic-ref", "refs/remotes/origin/HEAD",
                                 shQuote(paste0("refs/remotes/origin/", default)))))
  }
  if (!is.null(setup)) setup(repo)
  withr::local_options(cli.width = 1000)
  out <- new.env()
  out$msgs <- character()
  commands <- capture_messages_to(release_supplement("minor", path = repo), out)
  expect_identical(commands, expected_commands("1.3.0"))
  paste(out$msgs, collapse = "")
}

# Expect `text` to say where GitHub makes the tag: on the branch `branch`,
# or on the default branch when `branch` is NULL.
expect_push_first <- function(text, branch = "main") {
  expect_match(text, "Push first", fixed = TRUE)
  where <- if (is.null(branch)) "the default branch" else paste("the branch", branch)
  expect_match(text, sprintf("GitHub makes the tag v1.3.0 on %s when you publish the release", where),
               fixed = TRUE)
}

# Expect `text` to give the new-release address of the GitHub repository
# `repo` ("owner/name") after the commands, with `target` as its target
# field, or with no target field when `target` is NULL. `branch` is the
# branch that the text names.
expect_release_address <- function(text, repo, target = "main", branch = "main") {
  address <- sprintf("https://github.com/%s/releases/new?tag=v1.3.0", repo)
  if (!is.null(target)) address <- paste0(address, "&target=", target)
  printed <- regmatches(text, gregexpr("https://github\\.com/[^<>[:space:]]*", text))[[1]]
  expect_identical(printed, address)
  expect_gt(regexpr(address, text, fixed = TRUE), regexpr("git push", text, fixed = TRUE))
  expect_no_match(text, "open Releases", fixed = TRUE)
  expect_push_first(text, branch)
}

# Expect `text` to give the steps on the Releases page, and no address.
# The steps name the branch `branch` as the target, or the default branch
# when `branch` is NULL.
expect_release_steps <- function(text, branch = "main") {
  expect_no_match(text, "releases/new", fixed = TRUE)
  expect_match(text, "open Releases", fixed = TRUE)
  target <- if (is.null(branch)) "the default branch" else paste("the branch", branch)
  expect_match(text, sprintf("enter v1.3.0 as the tag, pick %s as the target", target), fixed = TRUE)
  expect_gt(regexpr("open Releases", text, fixed = TRUE), regexpr("git push", text, fixed = TRUE))
  expect_push_first(text, branch)
}

# The words of the line that names a release branch other than the default.
other_branch_line <- "not the default branch"

test_that("an https origin gives the release address", {
  skip_if_no_git()
  expect_release_address(release_text_with_origin("https://github.com/jdoe/my-site"), "jdoe/my-site")
})

test_that("an https origin that ends in .git gives the release address", {
  skip_if_no_git()
  expect_release_address(release_text_with_origin("https://github.com/jdoe/my-site.git"), "jdoe/my-site")
})

test_that("an scp-like ssh origin gives the release address", {
  skip_if_no_git()
  expect_release_address(release_text_with_origin("git@github.com:jdoe/my-site"), "jdoe/my-site")
})

test_that("an scp-like ssh origin that ends in .git gives the release address", {
  skip_if_no_git()
  expect_release_address(release_text_with_origin("git@github.com:jdoe/my-site.git"), "jdoe/my-site")
})

test_that("an ssh:// origin gives the release address", {
  skip_if_no_git()
  expect_release_address(release_text_with_origin("ssh://git@github.com/jdoe/my-site"), "jdoe/my-site")
})

test_that("an ssh:// origin that ends in .git gives the release address", {
  skip_if_no_git()
  expect_release_address(release_text_with_origin("ssh://git@github.com/jdoe/my-site.git"), "jdoe/my-site")
})

test_that("a repository name with a dot keeps the dot in the release address", {
  skip_if_no_git()
  expect_release_address(release_text_with_origin("https://github.com/jdoe/my.site.git"), "jdoe/my.site")
})

test_that("a repository with no origin remote gives the steps on the Releases page", {
  skip_if_no_git()
  expect_release_steps(release_text_with_origin(NULL))
})

test_that("an origin that is not on GitHub gives the steps on the Releases page", {
  skip_if_no_git()
  expect_release_steps(release_text_with_origin("https://gitlab.com/jdoe/my-site.git"))
})

test_that("more GitHub url forms give the release address", {
  skip_if_no_git()
  forms <- c(
    "https://github.com/jdoe/my-site/",
    "https://github.com/jdoe/my-site.git/",
    "http://github.com/jdoe/my-site",
    "https://www.github.com/jdoe/my-site",
    "https://GitHub.COM/jdoe/my-site",
    "git@GitHub.com:jdoe/my-site",
    "https://jdoe@github.com/jdoe/my-site",
    "https://jdoe:x@github.com/jdoe/my-site",
    "https://github.com:443/jdoe/my-site",
    "ssh://git@github.com:22/jdoe/my-site.git",
    "ssh://github.com/jdoe/my-site",
    "org-1@github.com:jdoe/my-site.git"
  )
  for (form in forms) {
    expect_release_address(release_text_with_origin(form), "jdoe/my-site")
  }
})

test_that("an owner name with an underscore keeps it in the release address", {
  skip_if_no_git()
  expect_release_address(release_text_with_origin("https://github.com/my_org/my-site"), "my_org/my-site")
})

test_that("a url that only looks like GitHub gives the steps on the Releases page", {
  skip_if_no_git()
  forms <- c(
    "https://github.com.evil.org/jdoe/my-site",
    "https://evil.org/github.com/jdoe/my-site",
    "https://github.com@evil.org/jdoe/my-site",
    "https://github.example.com/jdoe/my-site",
    "https://github.com/jdoe/my-site/tree/main",
    "https://github.com/jdoe/my-site?x",
    "https://github.com/jdoe/my-site//",
    "git://github.com/jdoe/my-site",
    "git@github-work:jdoe/my-site"
  )
  for (form in forms) {
    expect_release_steps(release_text_with_origin(form))
  }
})

test_that("the release address comes from the push url of origin", {
  skip_if_no_git()
  expect_release_address(
    release_text_with_origin("https://gitlab.com/jdoe/my-site", push = "https://github.com/jdoe/my-site"),
    "jdoe/my-site"
  )
  expect_release_steps(
    release_text_with_origin("https://github.com/jdoe/my-site", push = "https://gitlab.com/jdoe/my-site")
  )
})

test_that("the release address names a branch with special characters in percent-encoded form", {
  skip_if_no_git()
  branch <- "rel/v1#b&c+é"
  # A tag of the same name makes `git symbolic-ref --short HEAD` print
  # `heads/<branch>`.
  same_tag <- function(repo) {
    expect_status(git_in(repo, c("commit", "-q", "--allow-empty", "-m", "start")))
    expect_status(git_in(repo, c("tag", shQuote(branch))))
  }
  text <- release_text_with_origin("https://github.com/jdoe/my-site", branch = branch, setup = same_tag)
  expect_release_address(text, "jdoe/my-site", target = "rel%2Fv1%23b%26c%2B%C3%A9", branch = branch)
  expect_match(text, sprintf("check that the tag is v1.3.0 and the target is %s", branch), fixed = TRUE)
})

test_that("a detached HEAD gives the release address with no target", {
  skip_if_no_git()
  text <- release_text_with_origin("https://github.com/jdoe/my-site", branch = NULL)
  expect_release_address(text, "jdoe/my-site", target = NULL, branch = NULL)
  expect_no_match(text, "target", fixed = TRUE)
})

test_that("the Releases-page steps name the branch, or the default branch on a detached HEAD", {
  skip_if_no_git()
  expect_release_steps(release_text_with_origin("https://gitlab.com/jdoe/my-site", branch = "dev"), "dev")
  expect_release_steps(release_text_with_origin("https://gitlab.com/jdoe/my-site", branch = NULL), NULL)
})

test_that("a release on a branch other than origin's default branch names both", {
  skip_if_no_git()
  text <- release_text_with_origin("https://github.com/jdoe/my-site", branch = "dev", default = "main")
  expect_release_address(text, "jdoe/my-site", target = "dev", branch = "dev")
  expect_match(text, "This release is on the branch dev, not the default branch main of origin. GitHub makes the tag on dev.",
               fixed = TRUE)
})

test_that("no other-branch line is printed on the default branch, with no default, or on a detached HEAD", {
  skip_if_no_git()
  on_default <- release_text_with_origin("https://github.com/jdoe/my-site", default = "main")
  expect_release_address(on_default, "jdoe/my-site")
  expect_no_match(on_default, other_branch_line, fixed = TRUE)

  no_default <- release_text_with_origin("https://github.com/jdoe/my-site", branch = "dev")
  expect_release_address(no_default, "jdoe/my-site", target = "dev", branch = "dev")
  expect_no_match(no_default, other_branch_line, fixed = TRUE)

  detached <- release_text_with_origin("https://github.com/jdoe/my-site", branch = NULL, default = "main")
  expect_release_address(detached, "jdoe/my-site", target = NULL, branch = NULL)
  expect_no_match(detached, other_branch_line, fixed = TRUE)
})

test_that("a local branch named origin/main does not change the default branch read", {
  skip_if_no_git()
  local_origin_main <- function(repo) {
    expect_status(git_in(repo, c("commit", "-q", "--allow-empty", "-m", "start")))
    expect_status(git_in(repo, c("branch", "origin/main")))
  }
  text <- release_text_with_origin("https://github.com/jdoe/my-site", branch = "dev", default = "main",
                                   setup = local_origin_main)
  expect_match(text, "not the default branch main of origin", fixed = TRUE)
})
