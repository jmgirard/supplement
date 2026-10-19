# The template's files as git tracks them, written out here so that the
# test does not take its expectation from the folder that the function
# copies.
template_tracked <- c(
  "LICENSE-CC-BY.md", "LICENSE.md", "_README.md",
  "_extensions/supplement/_extension.yml", "_extensions/supplement/supplement.lua",
  "_gitignore", "_quarto.yml", "_scripts/nojekyll.ts", "_scripts/setup.ts",
  "_supplement.yml", "analyses/example.qmd", "data/example.csv", "index.qmd"
)

# The whole file as one string, line endings and final newline kept.
read_raw_text <- function(path) rawToChar(read_bytes(path))

test_that("a new folder gets every template file with the same bytes", {
  site <- file.path(withr::local_tempdir(), "new", "site")
  expect_message(out <- create_supplement(site), "Made a supplement site")
  expect_identical(out, site)

  copied <- sort(list.files(site, recursive = TRUE, all.files = TRUE, no.. = TRUE))
  expect_setequal(copied, template_tracked)
  for (file in copied) {
    expect_identical(read_bytes(file.path(site, file)), read_bytes(file.path(template_dir(), file)), info = file)
  }
  expect_true(file.exists(file.path(site, "_gitignore")))
  expect_true(file.exists(file.path(site, "_README.md")))
  expect_false(file.exists(file.path(site, ".gitignore")))
  expect_false(file.exists(file.path(site, "README.md")))
})

test_that("an existing folder keeps its files and gains the template", {
  site <- withr::local_tempdir()
  dir.create(file.path(site, "data"))
  writeLines("# My repository", file.path(site, "README.md"))
  writeLines("*.log", file.path(site, ".gitignore"))
  writeLines("x\n1", file.path(site, "data", "other.csv"))
  before <- folder_state(site)

  expect_message(create_supplement(site), "Made a supplement site")

  kept <- c("README.md", ".gitignore", "data/other.csv")
  expect_setequal(names(before), c(kept, "data"))
  for (file in kept) {
    expect_identical(read_bytes(file.path(site, file)), before[[file]], info = file)
  }
  for (file in template_tracked) {
    expect_identical(read_bytes(file.path(site, file)), read_bytes(file.path(template_dir(), file)), info = file)
  }
  expect_setequal(
    list.files(site, recursive = TRUE, all.files = TRUE, no.. = TRUE),
    c(template_tracked, "README.md", ".gitignore", "data/other.csv")
  )
})

test_that("hidden files and render output in the template folder are not copied", {
  template <- withr::local_tempdir()
  for (f in c(".DS_Store", ".quarto/x", "docs/index.html", "_freeze/a/b.json",
              "_site/x.html", "analyses/.DS_Store", "analyses/r.qmd", "index.qmd")) {
    dir.create(dirname(file.path(template, f)), recursive = TRUE, showWarnings = FALSE)
    writeLines("x", file.path(template, f))
  }
  expect_setequal(template_files(template), c("analyses/r.qmd", "index.qmd"))
})

test_that("repo replaces the placeholders", {
  site <- file.path(withr::local_tempdir(), "site")
  expect_message(create_supplement(site, repo = "JDoe/my_site.v-2"), "Made a supplement site")

  quarto <- read_text(file.path(site, "_quarto.yml"))
  readme <- read_text(file.path(site, "_README.md"))
  template_quarto <- read_text(file.path(template_dir(), "_quarto.yml"))
  n_sites <- lengths(regmatches(template_quarto, gregexpr("OWNER/REPO", template_quarto, fixed = TRUE)))
  expect_gt(n_sites, 0)
  expect_identical(
    lengths(regmatches(quarto, gregexpr("https://github.com/JDoe/my_site.v-2", quarto, fixed = TRUE))),
    n_sites
  )
  expect_match(readme, "https://jdoe.github.io/my_site.v-2/", fixed = TRUE)
  for (text in c(quarto, readme)) {
    expect_false(grepl("OWNER/REPO", text, fixed = TRUE))
    expect_false(grepl("OWNER.github.io/REPO", text, fixed = TRUE))
  }
  # Only the placeholders change, byte for byte.
  expect_identical(
    gsub("JDoe/my_site.v-2", "OWNER/REPO", read_raw_text(file.path(site, "_quarto.yml")), fixed = TRUE),
    read_raw_text(file.path(template_dir(), "_quarto.yml"))
  )
  expect_identical(
    gsub("https://jdoe.github.io/my_site.v-2/", "https://OWNER.github.io/REPO/",
         read_raw_text(file.path(site, "_README.md")), fixed = TRUE),
    read_raw_text(file.path(template_dir(), "_README.md"))
  )
})

test_that("copied files are writable when the template is read-only", {
  skip_on_os("windows")
  template <- withr::local_tempdir()
  file.copy(list.files(template_dir(), full.names = TRUE), template, recursive = TRUE)
  files <- list.files(template, recursive = TRUE, full.names = TRUE)
  Sys.chmod(files, "0444")
  local_mocked_bindings(template_path = function() template)
  site <- file.path(withr::local_tempdir(), "site")
  expect_message(create_supplement(site, repo = "jdoe/site"), "Made a supplement site")
  expect_match(read_text(file.path(site, "_quarto.yml")), "jdoe/site", fixed = TRUE)
  expect_true(all(file.access(list.files(site, recursive = TRUE, full.names = TRUE), 2) == 0))
})

test_that("a user site repo gets the root Pages address", {
  site <- file.path(withr::local_tempdir(), "site")
  expect_message(create_supplement(site, repo = "jdoe/JDoe.github.io"), "Made a supplement site")

  readme <- read_text(file.path(site, "_README.md"))
  expect_match(readme, "Website: https://jdoe.github.io/\n", fixed = TRUE)
  expect_false(grepl("github.io/JDoe.github.io", readme, fixed = TRUE))
  expect_match(read_text(file.path(site, "_quarto.yml")), "https://github.com/jdoe/JDoe.github.io", fixed = TRUE)
})

test_that("a bad path stops with an argument error and writes nothing", {
  dir <- withr::local_tempdir()
  before <- folder_state(dir)
  withr::with_dir(dir, {
    for (bad in list(1, c("a", "b"), NA_character_, NA, "")) {
      expect_error(create_supplement(bad), class = "supplement_error_argument")
    }
  })
  expect_identical(folder_state(dir), before)
})

test_that("an existing file at path stops and is kept", {
  file <- withr::local_tempfile(lines = "not a folder")
  before <- folder_state(file)
  for (given in c(file, paste0(file, "/"), paste0(file, "//"))) {
    expect_error(create_supplement(given), class = "supplement_error_not_folder", info = given)
    expect_identical(folder_state(file), before, info = given)
  }
})

test_that("a broken link at path stops as not a folder", {
  skip_on_os("windows")
  dir <- withr::local_tempdir()
  link <- file.path(dir, "site")
  file.symlink(file.path(dir, "missing"), link)
  for (given in c(link, paste0(link, "/"))) {
    expect_error(create_supplement(given), class = "supplement_error_not_folder", info = given)
  }
  expect_identical(list.files(dir, all.files = TRUE, no.. = TRUE), "site")
  expect_false(file.exists(file.path(dir, "missing")))
})

test_that("a trailing slash on a new or existing folder works", {
  dir <- withr::local_tempdir()
  given <- paste0(file.path(dir, "site"), "/")
  expect_message(out <- create_supplement(given), "Made a supplement site")
  expect_identical(out, given)
  expect_setequal(list.files(file.path(dir, "site"), recursive = TRUE), template_tracked)

  existing <- withr::local_tempdir()
  writeLines("# Mine", file.path(existing, "README.md"))
  expect_message(create_supplement(paste0(existing, "/")), "Made a supplement site")
  expect_setequal(list.files(existing, recursive = TRUE), c(template_tracked, "README.md"))
  expect_identical(readLines(file.path(existing, "README.md")), "# Mine")
})

test_that("a file or folder in the template's way stops before any write", {
  cases <- list(
    "a report at a template path" = function(site) {
      dir.create(file.path(site, "analyses"))
      writeLines("mine", file.path(site, "analyses", "example.qmd"))
    },
    "a folder at a template file path" = function(site) {
      dir.create(file.path(site, "index.qmd"))
    },
    "a file where the template needs a folder" = function(site) {
      writeLines("mine", file.path(site, "data"))
    }
  )
  for (case in names(cases)) {
    site <- withr::local_tempdir()
    cases[[case]](site)
    before <- folder_state(site)
    expect_error(create_supplement(site), class = "supplement_error_file_exists", info = case)
    expect_identical(folder_state(site), before, info = case)
  }
})

test_that("a link at a template path stops, even when its target is missing", {
  skip_on_os("windows")
  site <- withr::local_tempdir()
  file.symlink(file.path(site, "missing"), file.path(site, "index.qmd"))
  before <- list.files(site, recursive = TRUE, all.files = TRUE, no.. = TRUE, include.dirs = TRUE)
  expect_error(create_supplement(site), class = "supplement_error_file_exists")
  expect_identical(list.files(site, recursive = TRUE, all.files = TRUE, no.. = TRUE, include.dirs = TRUE), before)
  expect_identical(Sys.readlink(file.path(site, "index.qmd")), file.path(site, "missing"))
})

test_that("a link where the template needs a folder stops, so nothing is written outside", {
  skip_on_os("windows")
  site <- withr::local_tempdir()
  outside <- withr::local_tempdir()
  file.symlink(outside, file.path(site, "data"))
  expect_error(create_supplement(site), class = "supplement_error_file_exists", regexp = "data")
  expect_identical(list.files(outside, all.files = TRUE, no.. = TRUE), character())
  expect_identical(list.files(site, all.files = TRUE, no.. = TRUE), "data")
})

test_that("on Windows, a junction at a template folder path stops, so nothing is written outside", {
  skip_on_os(c("mac", "linux", "solaris"))
  folders <- setdiff(unique(dirname(template_tracked)), ".")
  expect_setequal(folders, c("_extensions", "_extensions/supplement", "_scripts", "analyses", "data"))
  for (folder in folders) {
    site <- withr::local_tempdir()
    outside <- withr::local_tempdir("outside-")
    dir.create(dirname(file.path(site, folder)), showWarnings = FALSE, recursive = TRUE)
    expect_true(Sys.junction(outside, file.path(site, folder)), info = folder)
    expect_true(is_link(file.path(site, folder)), info = folder)
    expect_error(create_supplement(site), class = "supplement_error_file_exists", info = folder)
    expect_identical(list.files(outside, all.files = TRUE, no.. = TRUE), character(), info = folder)
  }
})

test_that("on Windows, a trailing backslash makes the same files as no trailing separator", {
  skip_on_os(c("mac", "linux", "solaris"))
  plain <- file.path(withr::local_tempdir(), "site")
  suppressMessages(create_supplement(plain))
  expected <- sort(list.files(plain, recursive = TRUE, all.files = TRUE, no.. = TRUE))
  expect_setequal(expected, template_tracked)
  for (ending in c("\\", "\\\\", "\\/")) {
    site <- file.path(withr::local_tempdir(), "site")
    expect_message(create_supplement(paste0(site, ending)), "Made a supplement site", info = ending)
    expect_identical(sort(list.files(site, recursive = TRUE, all.files = TRUE, no.. = TRUE)), expected,
                     info = ending)
  }
})

test_that("a copy or a folder that fails partway leaves an existing folder as it was", {
  skip_on_os("windows")
  skip_if(Sys.info()[["user"]] == "root", "root can read and write any file")
  existing <- function() {
    site <- withr::local_tempdir(.local_envir = parent.frame())
    dir.create(file.path(site, "data"))
    writeLines("# Mine", file.path(site, "README.md"))
    writeLines("x\n1", file.path(site, "data", "other.csv"))
    site
  }

  # A template file that cannot be read makes file.copy() fail after
  # other files were copied.
  template <- withr::local_tempdir()
  file.copy(list.files(template_dir(), full.names = TRUE), template, recursive = TRUE)
  Sys.chmod(file.path(template, "index.qmd"), "0000")
  withr::defer(Sys.chmod(file.path(template, "index.qmd"), "0644"))
  local_mocked_bindings(template_path = function() template)
  site <- existing()
  before <- folder_state(site)
  expect_error(create_supplement(site), class = "supplement_error_write", regexp = "index.qmd")
  expect_identical(folder_state(site), before)

  # A folder that cannot be written makes dir.create() fail for a
  # template folder inside it.
  Sys.chmod(file.path(template, "index.qmd"), "0644")
  site <- existing()
  before <- folder_state(site)
  Sys.chmod(site, "0555")
  withr::defer(Sys.chmod(site, "0755"))
  expect_error(create_supplement(site), class = "supplement_error_write")
  Sys.chmod(site, "0755")
  expect_identical(folder_state(site), before)
})

test_that("a path under a file stops with a write error and leaves nothing", {
  dir <- withr::local_tempdir()
  writeLines("not a folder", file.path(dir, "file"))
  before <- folder_state(dir)
  expect_error(create_supplement(file.path(dir, "file", "site")), class = "supplement_error_write")
  expect_identical(folder_state(dir), before)
})

test_that("a failed write removes what the call made and keeps the rest", {
  local_mocked_bindings(fill_repo = function(path, repo) stop("planted failure"))

  dir <- withr::local_tempdir()
  expect_error(create_supplement(file.path(dir, "n1", "n2"), repo = "jdoe/site"),
               class = "supplement_error_write", regexp = "planted failure")
  expect_identical(list.files(dir, all.files = TRUE, no.. = TRUE), character())

  existing <- withr::local_tempdir()
  dir.create(file.path(existing, "data"))
  writeLines("# Mine", file.path(existing, "README.md"))
  writeLines("x\n1", file.path(existing, "data", "other.csv"))
  before <- folder_state(existing)
  expect_error(create_supplement(existing, repo = "jdoe/site"), class = "supplement_error_write")
  expect_identical(folder_state(existing), before)
})

test_that("a failed write on a path with pattern characters removes only what the call made", {
  local_mocked_bindings(fill_repo = function(path, repo) stop("planted failure"))
  for (name in pattern_names()) {
    base <- withr::local_tempdir()
    sibling <- file.path(base, "sitea")
    dir.create(sibling)
    writeLines("# Mine", file.path(sibling, "README.md"))
    sibling_before <- folder_state(sibling)
    expect_error(create_supplement(file.path(base, name, "inner"), repo = "jdoe/site"),
                 class = "supplement_error_write", regexp = "planted failure")
    expect_identical(folder_state(sibling), sibling_before, info = name)
    expect_identical(list.files(base, all.files = TRUE, no.. = TRUE), "sitea", info = name)
  }
})

test_that("a failed write on a path that starts with ~ removes what the call made", {
  local_mocked_bindings(fill_repo = function(path, repo) stop("planted failure"))
  home <- withr::local_tempdir()
  withr::local_envvar(HOME = home)
  skip_if(path.expand("~") != home, "~ does not follow HOME")
  # The parent exists, so every path that the call made starts with ~.
  expect_error(create_supplement("~/site", repo = "jdoe/site"),
               class = "supplement_error_write", regexp = "planted failure")
  expect_identical(list.files(home, all.files = TRUE, no.. = TRUE), character())
})

test_that("a bad repo stops and leaves no new folder", {
  parent <- withr::local_tempdir()
  site <- file.path(parent, "site")
  bad <- list("jdoe", "a/b/c", "/name", "owner/", "j doe/site", "jdöe/site",
              c("a/b", "c/d"), NA_character_, 1, "o/..", "o/.", "-/_", "-jdoe/site",
              "jdoe-/site", "jd--oe/site", "j_doe/site", "j.doe/site",
              paste0(strrep("a", 40), "/site"), paste0("jdoe/", strrep("a", 101)))
  for (repo in bad) {
    expect_error(create_supplement(site, repo = repo), class = "supplement_error_repo",
                 info = paste(format(repo), collapse = " "))
    expect_false(file.exists(site))
  }
  existing <- withr::local_tempdir()
  before <- folder_state(existing)
  expect_error(create_supplement(existing, repo = "no slash"), class = "supplement_error_repo")
  expect_identical(folder_state(existing), before)
})

test_that("a site made with repo renders", {
  skip_if_no_quarto()
  # A clone of a new GitHub repository often holds these two files.
  site <- withr::local_tempdir()
  writeLines("# my-supplement", file.path(site, "README.md"))
  writeLines("*.log", file.path(site, ".gitignore"))
  readme_before <- read_bytes(file.path(site, "README.md"))
  expect_message(create_supplement(site, repo = "jdoe/my-supplement"), "Made a supplement site")

  rendered <- run_in(site, "quarto", "render")
  expect_equal(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))
  expect_true(file.exists(file.path(site, "docs", "index.html")))
  expect_true(file.exists(file.path(site, "docs", ".nojekyll")))
  expect_true(file.exists(file.path(site, ".gitignore")))
  expect_identical(read_bytes(file.path(site, "README.md")), readme_before)
  expect_true(file.exists(file.path(site, "SUPPLEMENT.md")))
  gitignore <- readLines(file.path(site, ".gitignore"))
  expect_identical(gitignore[1], "*.log")
  expect_identical(utils::tail(gitignore, 2), c("!docs/", "!_freeze/"))
  expect_match(
    quarto_header(read_text(file.path(site, "docs", "index.html"))),
    "https://github.com/jdoe/my-supplement", fixed = TRUE
  )
})
