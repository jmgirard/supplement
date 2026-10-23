# The lookups are mocked, so these tests do not depend on the tools that
# this machine has.

# A Quarto install under `root`: `bin/<exe>` and, unless `version` is NULL,
# `share/version` with the bytes of `version` (text or raw). Returns the
# program's path.
fake_quarto <- function(root, version = "1.10.19\n", exe = "quarto") {
  dir.create(file.path(root, "bin"), recursive = TRUE)
  dir.create(file.path(root, "share"))
  program <- file.path(root, "bin", exe)
  file.create(program)
  if (!is.null(version)) {
    bytes <- if (is.raw(version)) version else charToRaw(version)
    writeBin(bytes, file.path(root, "share", "version"))
  }
  program
}

# Mock the lookups. `which` maps program names to paths, `env` maps
# environment variables to values, and `packages` maps package names to
# versions. Names that are absent are not found.
local_tools <- function(which = list(), env = list(), packages = list(),
                        editors = character(), env_frame = parent.frame()) {
  local_mocked_bindings(
    tool_which = function(name) if (is.null(which[[name]])) "" else which[[name]],
    tool_env = function(name) if (is.null(env[[name]])) "" else env[[name]],
    package_version_text = function(pkg) if (is.null(packages[[pkg]])) "" else packages[[pkg]],
    editor_quarto_paths = function(os = tool_os()) editors,
    .env = env_frame
  )
}

all_found <- function(dir, env = parent.frame()) {
  local_tools(
    which = list(quarto = fake_quarto(file.path(dir, "q")), git = "/usr/bin/git", gh = "/usr/bin/gh"),
    packages = list(knitr = "1.52", rmarkdown = "2.30"),
    env_frame = env
  )
}

quarto_result <- function() {
  rows <- suppressMessages(check_tools())
  rows[rows$tool == "Quarto", ]
}

test_that("check_tools() returns the seven rows invisibly", {
  all_found(withr::local_tempdir())
  expect_invisible(suppressMessages(check_tools()))
  rows <- suppressMessages(check_tools())
  expect_identical(names(rows), c("tool", "status", "detail"))
  expect_true(all(vapply(rows, is.character, logical(1))))
  expect_identical(
    rows$tool,
    c("Quarto", "knitr", "rmarkdown", "git", "gh", "GitHub account", "Zenodo account")
  )
  expect_identical(rows$status, c(rep("found", 5), "reminder", "reminder"))
  expect_match(rows$detail[rows$tool == "knitr"], "1.52", fixed = TRUE)
  expect_match(rows$detail[rows$tool == "git"], "/usr/bin/git", fixed = TRUE)
})

test_that("tools that the lookups do not find are missing", {
  local_tools()
  rows <- suppressMessages(check_tools())
  expect_identical(rows$status, c(rep("missing", 5), "reminder", "reminder"))
  expect_match(rows$detail[rows$tool == "knitr"], 'install.packages("knitr")', fixed = TRUE)
  expect_match(rows$detail[rows$tool == "gh"], "gh release create", fixed = TRUE)
})

test_that("check_tools() prints one line per row with its tool and status", {
  dir <- withr::local_tempdir()
  local_tools(
    which = list(git = "/usr/bin/git"),
    env = list(QUARTO_PATH = fake_quarto(file.path(dir, "q"))),
    packages = list(rmarkdown = "2.30")
  )
  withr::local_options(cli.width = 500)
  lines <- capture_messages(check_tools())
  expect_length(lines, 7L)
  expect_match(lines[1], "Quarto: not on path", fixed = TRUE)
  expect_match(lines[2], "knitr: missing", fixed = TRUE)
  expect_match(lines[4], "git: found", fixed = TRUE)
  expect_match(lines[6], "GitHub account: reminder", fixed = TRUE)

  local_tools(which = list(quarto = fake_quarto(file.path(dir, "old"), "1.3.450\n")))
  lines <- capture_messages(check_tools())
  expect_match(lines[1], "Quarto: too old", fixed = TRUE)
})

test_that("the editor list holds the RStudio and Positron copies of each system", {
  env <- list(PROGRAMFILES = "C:/PF", LOCALAPPDATA = "C:/Users/u/AppData/Local")
  local_mocked_bindings(tool_env = function(name) if (is.null(env[[name]])) "" else env[[name]])
  expect_identical(editor_quarto_paths("mac"), c(
    "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto",
    "/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto"
  ))
  expect_identical(editor_quarto_paths("linux"), c(
    "/usr/lib/rstudio/resources/app/bin/quarto/bin/quarto",
    "/usr/share/positron/resources/app/quarto/bin/quarto"
  ))
  expect_identical(editor_quarto_paths("windows"), c(
    "C:/PF/RStudio/resources/app/bin/quarto/bin/quarto.exe",
    "C:/Users/u/AppData/Local/Programs/Positron/resources/app/quarto/bin/quarto.exe",
    "C:/PF/Positron/resources/app/quarto/bin/quarto.exe"
  ))
})

test_that("a copy on the system path is found", {
  program <- fake_quarto(file.path(withr::local_tempdir(), "q"))
  local_tools(which = list(quarto = program))
  row <- quarto_result()
  expect_identical(row$status, "found")
  expect_match(row$detail, program, fixed = TRUE)
  expect_match(row$detail, "1.10.19", fixed = TRUE)
})

test_that("a copy in QUARTO_PATH or an editor folder is not on the path", {
  dir <- withr::local_tempdir()
  local_tools(env = list(QUARTO_PATH = fake_quarto(file.path(dir, "env"))))
  row <- quarto_result()
  expect_identical(row$status, "not on path")
  expect_match(row$detail, "QUARTO_PATH", fixed = TRUE)
  expect_match(row$detail, "`quarto render` in a terminal can miss", fixed = TRUE)

  editor <- fake_quarto(file.path(dir, "editor"))
  local_tools(editors = c(file.path(dir, "absent", "bin", "quarto"), editor))
  row <- quarto_result()
  expect_identical(row$status, "not on path")
  expect_match(row$detail, editor, fixed = TRUE)
  expect_match(row$detail, "RStudio or Positron", fixed = TRUE)
  expect_match(row$detail, "can miss", fixed = TRUE)

  exe <- fake_quarto(file.path(dir, "win"), exe = "quarto.exe")
  local_tools(editors = exe)
  row <- quarto_result()
  expect_identical(row$status, "not on path")
  expect_match(row$detail, "quarto.exe", fixed = TRUE)
})

test_that("a QUARTO_PATH that names no file is passed over", {
  dir <- withr::local_tempdir()
  for (value in list(NULL, "", file.path(dir, "absent"), dir)) {
    local_tools(env = list(QUARTO_PATH = value))
    expect_identical(quarto_result()$status, "missing", info = format(value))
  }
})

test_that("the first place that holds a copy wins", {
  dir <- withr::local_tempdir()
  on_path <- fake_quarto(file.path(dir, "path"))
  local_tools(
    which = list(quarto = on_path),
    env = list(QUARTO_PATH = fake_quarto(file.path(dir, "env")))
  )
  row <- quarto_result()
  expect_identical(row$status, "found")
  expect_match(row$detail, on_path, fixed = TRUE)

  env <- fake_quarto(file.path(dir, "env2"))
  local_tools(env = list(QUARTO_PATH = env), editors = fake_quarto(file.path(dir, "editor")))
  row <- quarto_result()
  expect_match(row$detail, env, fixed = TRUE)
  expect_match(row$detail, "QUARTO_PATH", fixed = TRUE)
})

test_that("the version is compared as a version number", {
  dir <- withr::local_tempdir()
  cases <- c("1.3.450" = "too old", "1.4.0" = "found", "1.10.0" = "found")
  for (version in names(cases)) {
    program <- fake_quarto(file.path(dir, version), paste0(version, "\n"))
    local_tools(which = list(quarto = program))
    row <- quarto_result()
    expect_identical(row$status, cases[[version]], info = version)
    expect_match(row$detail, paste0("version ", version), fixed = TRUE, info = version)
  }
})

test_that("a version file with no final line break is read with no warning", {
  local_tools(which = list(quarto = fake_quarto(file.path(withr::local_tempdir(), "q"), "1.3.0")))
  expect_no_warning(row <- quarto_result())
  expect_identical(row$status, "too old")
})

test_that("a missing or unreadable version keeps the status and says so", {
  dir <- withr::local_tempdir()
  local_tools(which = list(quarto = fake_quarto(file.path(dir, "none"), NULL)))
  row <- quarto_result()
  expect_identical(row$status, "found")
  expect_match(row$detail, "version unknown", fixed = TRUE)

  local_tools(env = list(QUARTO_PATH = fake_quarto(file.path(dir, "text"), "not a version\n")))
  row <- quarto_result()
  expect_identical(row$status, "not on path")
  expect_match(row$detail, "version unknown", fixed = TRUE)
})

test_that("a version file with bytes that are not UTF-8 gives no warning", {
  bytes <- c(as.raw(c(0xe9, 0xff)), charToRaw("1.2\n"))
  local_tools(
    which = list(quarto = fake_quarto(file.path(withr::local_tempdir(), "q"), bytes)),
    packages = list(rmarkdown = "2.30")
  )
  expect_no_warning(row <- quarto_result())
  expect_identical(row$status, "found")
  expect_match(row$detail, "version unknown", fixed = TRUE)

  site <- file.path(withr::local_tempdir(), "site")
  withr::local_options(cli.width = 500)
  expect_no_warning(msgs <- capture_messages(create_supplement(site)))
  expect_match(paste(msgs, collapse = ""), "knitr: missing", fixed = TRUE)
})

test_that("an old copy off the path is too old and names its place", {
  local_tools(env = list(QUARTO_PATH = fake_quarto(file.path(withr::local_tempdir(), "q"), "1.2.0\n")))
  row <- quarto_result()
  expect_identical(row$status, "too old")
  expect_match(row$detail, "QUARTO_PATH", fixed = TRUE)
  expect_match(row$detail, "1.4.0", fixed = TRUE)
})

test_that("a link to a copy is resolved before the version is read", {
  skip_on_os("windows")
  dir <- withr::local_tempdir()
  program <- fake_quarto(file.path(dir, "install"), "1.3.0\n")
  dir.create(file.path(dir, "links"))
  link <- file.path(dir, "links", "quarto")
  file.symlink(program, link)
  local_tools(which = list(quarto = link))
  row <- quarto_result()
  expect_identical(row$status, "too old")
  expect_match(row$detail, "1.3.0", fixed = TRUE)

  # A link to the install folder itself.
  file.symlink(file.path(dir, "install"), file.path(dir, "alias"))
  local_tools(which = list(quarto = file.path(dir, "alias", "bin", "quarto")))
  row <- quarto_result()
  expect_identical(row$status, "too old")
  expect_match(row$detail, "1.3.0", fixed = TRUE)
})

test_that("the minimum version is the template extension's", {
  extension <- file.path(template_path(), "_extensions", "supplement", "_extension.yml")
  expect_true(any(grepl(paste0('quarto-required: ">=', quarto_minimum, '"'), readLines(extension), fixed = TRUE)))
})
