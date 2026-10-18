# check_supplement() lists the problems that would break or leak a release.

check_quiet <- function(path) suppressMessages(check_supplement(path))

rows_of <- function(result, check) result[result$check == check, , drop = FALSE]

# Turn off git's global and system configuration and the user's ignore
# file in $XDG_CONFIG_HOME/git/ignore, so that only a repository's own
# rules decide what git ignores.
local_plain_git <- function(env = parent.frame()) {
  empty <- withr::local_tempfile(.local_envir = env)
  file.create(empty)
  config <- withr::local_tempdir(.local_envir = env)
  withr::local_envvar(
    c(GIT_CONFIG_GLOBAL = empty, GIT_CONFIG_NOSYSTEM = "1", XDG_CONFIG_HOME = config),
    .local_envir = env
  )
}

# A site made by create_supplement() in a git repository, with the
# template's .gitignore, under local_plain_git().
git_site <- function(env = parent.frame()) {
  site <- new_site(env)
  file.copy(file.path(site, "_gitignore"), file.path(site, ".gitignore"))
  local_plain_git(env)
  inited <- git_in(site, c("init", "-q"))
  stopifnot(inited$status == 0L)
  site
}

# A file of `size` bytes that takes almost no disk space.
sparse_file <- function(path, size) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  con <- file(path, "wb")
  on.exit(close(con))
  seek(con, size - 1, rw = "write")
  writeBin(as.raw(0), con)
  invisible(path)
}

write_page <- function(site, page, body) {
  path <- file.path(site, "docs", page)
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  writeLines(c("<!DOCTYPE html>", "<html><body>", body, "</body></html>"), path)
  invisible(path)
}

touch <- function(path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  file.create(path)
}

test_that("a rendered site in a git repository has no problems", {
  skip_if_no_quarto()
  skip_if_no_git()
  site <- site_copy()$dir
  local_plain_git()
  expect_identical(git_in(site, c("init", "-q"))$status, 0L)

  expect_message(result <- check_supplement(site), "No problems")
  expect_s3_class(result, "data.frame")
  expect_identical(names(result), c("check", "file", "problem"))
  expect_identical(nrow(result), 0L)
  expect_identical(attr(result, "skipped"), character())
  for (col in names(result)) expect_type(result[[col]], "character")

  # Each planted problem then gives its row.
  sparse_file(file.path(site, "data", "big.csv"), 104857601)
  touch(file.path(site, "fits-shared", "model.qs2"))
  expect_identical(git_in(site, c("add", "-f", "fits-shared/model.qs2"))$status, 0L)
  writeLines(c("---", "title: New", "---", "", "```{r}", "1 + 1", "```"),
             file.path(site, "analyses", "new.qmd"))
  write_page(site, "extra.html", '<a href="missing.csv">x</a>')
  writeLines(c("doi: \"10.5281/zenodo.99\""), file.path(site, "CITATION.cff"))
  result <- check_quiet(site)
  expect_setequal(result$check, c("large-file", "saved-object", "no-stored-output", "broken-link", "doi-mismatch"))
})

test_that("the result is returned invisibly and each problem is printed", {
  site <- new_site()
  expect_invisible(suppressMessages(check_supplement(site)))
  msgs <- testthat::capture_messages(check_supplement(site))
  expect_match(paste(msgs, collapse = ""), "not-rendered")
})

test_that("argument and metadata errors stop the check", {
  for (bad in list(1, c("a", "b"), NA_character_, "")) {
    expect_error(check_supplement(bad), class = "supplement_error_argument")
  }
  dir <- withr::local_tempdir()
  expect_error(check_supplement(dir), class = "supplement_error_no_metadata")

  site <- new_site()
  set_supplement_value(file.path(site, "_supplement.yml"), "version-doi", "not a doi")
  expect_error(check_quiet(site), class = "supplement_error_doi")
})

test_that("files over GitHub's size limit give a large-file row", {
  skip_if_no_git()
  site <- git_site()
  sparse_file(file.path(site, "data", "over.csv"), 104857601)
  sparse_file(file.path(site, "data", "at-limit.csv"), 104857600)
  sparse_file(file.path(site, "private", "ignored.csv"), 104857601)

  rows <- rows_of(check_quiet(site), "large-file")
  expect_identical(rows$file, "data/over.csv")
  expect_match(rows$problem, "^100\\.0 MiB")
})

test_that("a git file name that is not valid UTF-8 is still checked", {
  site <- new_site()
  name <- c(charToRaw("fits/a"), as.raw(0xff), charToRaw(".rds"))
  local_mocked_bindings(git_run = function(args, dir) {
    out <- switch(args[1],
      "--version" = charToRaw("git version 2"),
      "rev-parse" = charToRaw("true\n"),
      "ls-files" = c(name, as.raw(0))
    )
    list(status = 0L, stdout = out)
  })
  rows <- rows_of(check_quiet(site), "saved-object")
  expect_identical(rows$file, "fits/a<ff>.rds")
})

test_that("saved R objects that git would publish give a saved-object row", {
  skip_if_no_git()
  site <- git_site()
  touch(file.path(site, "fits", "model.RDS"))
  expect_identical(git_in(site, c("add", "-f", "fits/model.RDS"))$status, 0L)
  touch(file.path(site, "x.rds"))
  # The template's .gitignore blocks *.rds, so only a tracked or force-added
  # one, or one in a folder whose own rules let it through, is listed.
  dir.create(file.path(site, "open"))
  writeLines("!*.rds", file.path(site, "open", ".gitignore"))
  touch(file.path(site, "open", "données.rds"))

  rows <- rows_of(check_quiet(site), "saved-object")
  expect_setequal(rows$file, c("fits/model.RDS", "open/données.rds"))
})

test_that("git runs only through its helper", {
  r_dir <- test_path("..", "..", "R")
  skip_if_not(dir.exists(r_dir), "the package source is not here")
  files <- list.files(r_dir, pattern = "\\.[Rr]$", full.names = TRUE)
  hits <- character()
  for (file in files) {
    lines <- readLines(file, warn = FALSE)
    found <- grep("system\\(|system2\\(|shell\\(|pipe\\(|processx|callr|sys::", lines)
    hits <- c(hits, sprintf("%s:%d: %s", basename(file), found, trimws(lines[found])))
  }
  expect_length(hits, 1L)
  expect_match(hits, "^check-supplement\\.R:[0-9]+: .*system2\\(")
})

test_that("the git checks are skipped when git cannot run", {
  site <- new_site()
  cases <- list(
    "not on the PATH" = function(args, dir) NULL,
    "--version fails" = function(args, dir) list(status = 69L, stdout = raw()),
    "not in a work tree" = function(args, dir) {
      if (identical(args, "--version")) list(status = 0L, stdout = charToRaw("git version 2"))
      else list(status = 128L, stdout = raw())
    }
  )
  for (case in names(cases)) {
    calls <- list()
    mock <- cases[[case]]
    local_mocked_bindings(git_run = function(args, dir) {
      calls[[length(calls) + 1]] <<- args
      mock(args, dir)
    })
    msgs <- testthat::capture_messages(result <- check_supplement(site))
    expect_identical(attr(result, "skipped"), c("large-file", "saved-object"), info = case)
    expect_false(any(result$check %in% c("large-file", "saved-object")), info = case)
    expect_match(paste(msgs, collapse = ""), "Skipped", info = case)
    for (args in calls) {
      expect_true(identical(args, "--version") || identical(args, c("rev-parse", "--is-inside-work-tree")),
                  info = case)
    }
  }
})

test_that("reports with code but no stored output give a no-stored-output row", {
  site <- new_site()
  qmd <- function(name, body) {
    writeLines(c("---", "title: Fixture", "---", "", body), file.path(site, "analyses", paste0(name, ".qmd")))
  }
  qmd("r-chunk", c("```{r}", "1 + 1", "```"))
  qmd("python-chunk", c("```{python}", "1 + 1", "```"))
  qmd("callout", c("::: {.callout-note}", "  ```{r, echo=FALSE}", "  1 + 1", "  ```", ":::"))
  qmd("no-code", c("Plain text."))
  qmd("rust-block", c("```{rust}", "fn main() {}", "```"))
  qmd("stored", c("````{r label}", "1 + 1", "````"))
  touch(file.path(site, "_freeze", "analyses", "stored", "execute-results", "html.json"))

  rows <- rows_of(check_quiet(site), "no-stored-output")
  # example.qmd from the template has R chunks and no stored output yet.
  expect_setequal(rows$file, file.path("analyses", c("r-chunk.qmd", "python-chunk.qmd", "callout.qmd", "example.qmd")))
})

test_that("glob characters in the site path do not hide reports", {
  site <- file.path(withr::local_tempdir(), "site [draft]*?")
  suppressMessages(create_supplement(site))
  rows <- rows_of(check_quiet(site), "no-stored-output")
  expect_identical(rows$file, "analyses/example.qmd")
  # A path with a separator at the end gives the same rows.
  expect_identical(check_quiet(paste0(site, "/")), check_quiet(site))
})

test_that("the rendered example report has stored output", {
  skip_if_no_quarto()
  site <- site_copy()$dir
  expect_identical(nrow(rows_of(check_quiet(site), "no-stored-output")), 0L)
})

test_that("a site with no docs folder gives one not-rendered row", {
  site <- new_site()
  result <- check_quiet(site)
  expect_identical(nrow(rows_of(result, "not-rendered")), 1L)
  expect_identical(nrow(rows_of(result, "broken-link")), 0L)
})

test_that("links to files missing from the site give a broken-link row", {
  site <- new_site()
  touch(file.path(site, "docs", "data", "ok.csv"))
  touch(file.path(site, "docs", "data", "a b.csv"))
  touch(file.path(site, "docs", "with-index", "index.html"))
  dir.create(file.path(site, "docs", "no-index"))
  touch(file.path(site, "docs", "style.css"))
  # A `../` link that leaves docs/ is broken even when docs/ holds a file of
  # the same name.
  touch(file.path(site, "docs", "outside.html"))
  write_page(site, "index.html", c(
    '<a href="data/ok.csv">ok</a>',
    '<a href="data/missing.csv">missing</a>',
    '<a href="data/a%20b.csv">encoded</a>',
    '<a href="with-index/">folder</a>',
    '<a href="no-index/">folder without index</a>',
    "<link href='style.css' rel='stylesheet'>",
    "<img src='gone.png'>",
    '<a href="data/ok.csv?v=1#x">query</a>',
    '<a href="../outside.html">outside</a>',
    '<a href="../_supplement.yml">outside but present</a>',
    '<a href="https://example.org/x">web</a>',
    '<a href="mailto:a@example.org">mail</a>',
    '<a href="#top">top</a>',
    '<a href="">empty</a>',
    '<a href="/root.html">root</a>'
  ))
  write_page(site, "analyses/report.html", c(
    '<a href="../index.html">home</a>',
    '<a href="../../x.html">outside</a>'
  ))
  # Non-ASCII names, bad percent escapes, and letter case.
  touch(file.path(site, "docs", "data", "données.csv"))
  touch(file.path(site, "docs", "data", "Upper.csv"))
  write_page(site, "names.html", c(
    '<a href="data/donn%C3%A9es.csv">encoded</a>',
    '<a href="data/données.csv">raw</a>',
    '<a href="café.html">missing</a>',
    '<a href="a%00b.html">nul</a>',
    '<a href="a%FFb.html">not UTF-8</a>',
    '<a href="data/upper.csv">wrong case</a>',
    '<a href="data/Upper.csv">right case</a>'
  ))
  # A page in Latin-1 with a NUL byte, and a link to a missing page.
  latin <- c(charToRaw('<p>caf'), as.raw(0xe9), as.raw(0), charToRaw('</p><a href="gone-latin.csv">x</a>'))
  writeBin(latin, file.path(site, "docs", "latin.html"))
  file.symlink(file.path(site, "docs", "no-such-page.html"), file.path(site, "docs", "dangling.html"))

  rows <- rows_of(check_quiet(site), "broken-link")
  links <- regmatches(rows$problem, regexpr("`[^`]*`$", rows$problem))
  expect_setequal(
    paste(rows$file, links),
    c("docs/names.html `café.html`",
      "docs/names.html `a%00b.html`",
      "docs/names.html `a%FFb.html`",
      "docs/names.html `data/upper.csv`",
      "docs/latin.html `gone-latin.csv`",
      "docs/index.html `data/missing.csv`",
      "docs/index.html `no-index/`",
      "docs/index.html `gone.png`",
      "docs/index.html `../outside.html`",
      "docs/index.html `../_supplement.yml`",
      "docs/analyses/report.html `../../x.html`")
  )
})

test_that("DOIs that differ between files give a doi-mismatch row", {
  site_with <- function(version = "", concept = "", cff = NULL, badges = NULL, shortcode = TRUE) {
    site <- new_site(parent.frame())
    yml <- file.path(site, "_supplement.yml")
    set_supplement_value(yml, "version-doi", version)
    set_supplement_value(yml, "concept-doi", concept)
    if (!is.null(cff)) {
      writeLines(if (nzchar(cff)) sprintf('doi: "%s"', cff) else "title: x", file.path(site, "CITATION.cff"))
    }
    if (!is.null(badges)) {
      write_page(site, "index.html", sprintf('<img src="https://zenodo.org/badge/DOI/%s.svg">', badges))
    }
    if (!shortcode) {
      index <- file.path(site, "index.qmd")
      writeLines(sub("{{< supplement-doi >}}", "", readLines(index), fixed = TRUE), index)
    }
    site
  }
  doi_rows <- function(site) rows_of(check_quiet(site), "doi-mismatch")

  # Equal DOIs, and a DOI that differs only in letter case.
  expect_identical(nrow(doi_rows(site_with("10.5281/zenodo.2", "10.5281/zenodo.1",
                                           cff = "10.5281/zenodo.1", badges = "10.5281/zenodo.2"))), 0L)
  expect_identical(nrow(doi_rows(site_with("10.5281/ZENODO.2", "10.5281/zenodo.1",
                                           cff = "https://doi.org/10.5281/Zenodo.1",
                                           badges = "10.5281/zenodo.2"))), 0L)
  # A changed DOI in each file.
  expect_identical(doi_rows(site_with("10.5281/zenodo.2", "10.5281/zenodo.1",
                                      cff = "10.5281/zenodo.9", badges = "10.5281/zenodo.2"))$file,
                   "CITATION.cff")
  expect_identical(doi_rows(site_with("10.5281/zenodo.2", "10.5281/zenodo.1",
                                      cff = "10.5281/zenodo.1", badges = "10.5281/zenodo.9"))$file,
                   "docs/index.html")
  # A missing DOI on each side.
  expect_identical(doi_rows(site_with("", "10.5281/zenodo.1", cff = ""))$file, "CITATION.cff")
  expect_identical(doi_rows(site_with("", "", cff = "10.5281/zenodo.1"))$file, "CITATION.cff")
  expect_identical(doi_rows(site_with("", "", badges = "10.5281/zenodo.1"))$file, "docs/index.html")
  # A site rendered before its DOI was added, with and without the shortcode.
  expect_identical(doi_rows(site_with("10.5281/zenodo.2", badges = character()))$file, "docs/index.html")
  expect_identical(nrow(doi_rows(site_with("10.5281/zenodo.2", badges = character(), shortcode = FALSE))), 0L)
  # No CITATION.cff and no docs/index.html: nothing to compare.
  expect_identical(nrow(doi_rows(site_with("10.5281/zenodo.2"))), 0L)
  # A doi that is not a DOI, in CITATION.cff or on the badge, gives a row
  # and the other checks still run.
  site <- site_with("10.5281/zenodo.2", cff = "not-a-doi")
  result <- check_quiet(site)
  expect_match(rows_of(result, "doi-mismatch")$problem, "not a DOI: not-a-doi")
  expect_identical(nrow(rows_of(result, "not-rendered")), 1L)
  expect_match(doi_rows(site_with("10.5281/zenodo.2", badges = "nota"))$problem, "nota, which is not a DOI")
  # A block-scalar doi in CITATION.cff ends with a line break.
  site <- site_with("", "10.5281/zenodo.1")
  # A key after it keeps the line break in the value.
  writeLines(c("doi: |", "  10.5281/zenodo.1", "", "title: x"), file.path(site, "CITATION.cff"))
  expect_identical(yaml::read_yaml(file.path(site, "CITATION.cff"))$doi, "10.5281/zenodo.1\n")
  expect_identical(nrow(doi_rows(site)), 0L)
  # A CITATION.cff that is not a YAML map, or not YAML at all.
  for (text in c("just text", "doi: [unclosed")) {
    site <- site_with("10.5281/zenodo.2")
    writeLines(text, file.path(site, "CITATION.cff"))
    expect_match(doi_rows(site)$problem, "cannot be read as a YAML map")
  }
})
