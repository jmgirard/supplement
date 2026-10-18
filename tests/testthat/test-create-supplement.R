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

template_files <- function() {
  sort(list.files(template_dir(), recursive = TRUE, all.files = TRUE, no.. = TRUE))
}

read_bytes <- function(path) readBin(path, "raw", file.size(path))

test_that("a new folder gets every template file with the same bytes", {
  site <- file.path(withr::local_tempdir(), "new", "site")
  expect_message(out <- create_supplement(site), "Made a supplement site")
  expect_identical(out, site)

  copied <- sort(list.files(site, recursive = TRUE, all.files = TRUE, no.. = TRUE))
  expect_identical(copied, template_files())
  expect_gt(length(copied), 5)
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
  for (file in template_files()) {
    expect_identical(read_bytes(file.path(site, file)), read_bytes(file.path(template_dir(), file)), info = file)
  }
  expect_setequal(
    list.files(site, recursive = TRUE, all.files = TRUE, no.. = TRUE),
    c(template_files(), "README.md", ".gitignore", "data/other.csv")
  )
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
  # Only the placeholders change.
  expect_identical(gsub("JDoe/my_site.v-2", "OWNER/REPO", quarto, fixed = TRUE), template_quarto)
  expect_identical(
    gsub("https://jdoe.github.io/my_site.v-2/", "https://OWNER.github.io/REPO/", readme, fixed = TRUE),
    read_text(file.path(template_dir(), "_README.md"))
  )
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
  expect_error(create_supplement(file), class = "supplement_error_not_folder")
  expect_identical(folder_state(file), before)
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
  expect_error(create_supplement(site), class = "supplement_error_file_exists")
  expect_false(file.exists(file.path(site, "_quarto.yml")))
})

test_that("a path under a file stops with a write error and leaves nothing", {
  dir <- withr::local_tempdir()
  writeLines("not a folder", file.path(dir, "file"))
  before <- folder_state(dir)
  expect_error(create_supplement(file.path(dir, "file", "site")), class = "supplement_error_write")
  expect_identical(folder_state(dir), before)
})

test_that("a failed write removes the parent folders that the call made", {
  dir <- withr::local_tempdir()
  local_mocked_bindings(fill_repo = function(path, repo) stop("planted failure"))
  expect_error(create_supplement(file.path(dir, "n1", "n2"), repo = "jdoe/site"), "planted failure")
  expect_identical(list.files(dir, all.files = TRUE, no.. = TRUE), character())
})

test_that("a bad repo stops and leaves no new folder", {
  parent <- withr::local_tempdir()
  site <- file.path(parent, "site")
  bad <- list("jdoe", "a/b/c", "/name", "owner/", "j doe/site", "jdöe/site",
              c("a/b", "c/d"), NA_character_, 1)
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
  site <- file.path(withr::local_tempdir(), "site")
  expect_message(create_supplement(site, repo = "jdoe/my-supplement"), "Made a supplement site")

  rendered <- run_in(site, "quarto", "render")
  expect_equal(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))
  expect_true(file.exists(file.path(site, "docs", "index.html")))
  expect_true(file.exists(file.path(site, "docs", ".nojekyll")))
  expect_true(file.exists(file.path(site, ".gitignore")))
  expect_match(
    quarto_header(read_text(file.path(site, "docs", "index.html"))),
    "https://github.com/jdoe/my-supplement", fixed = TRUE
  )
})
