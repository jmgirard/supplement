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
  site <- new_site()
  # With both DOIs, the home page shows a Zenodo badge from Quarto's own
  # output, and CITATION.cff holds the concept DOI.
  yml <- file.path(site, "_supplement.yml")
  set_supplement_value(yml, "version-doi", "10.5281/zenodo.222")
  set_supplement_value(yml, "concept-doi", "10.5281/zenodo.111")
  write_citation(site)
  rendered <- run_in(site, "quarto", "render")
  expect_identical(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))
  local_plain_git()
  expect_identical(git_in(site, c("init", "-q"))$status, 0L)
  expect_match(read_text(file.path(site, "docs", "index.html")),
               "https://zenodo.org/badge/DOI/10.5281/zenodo.222.svg", fixed = TRUE)

  expect_message(result <- check_supplement(site), "No problems")
  expect_s3_class(result, "data.frame")
  expect_identical(names(result), c("check", "file", "problem"))
  expect_identical(nrow(result), 0L, info = paste(result$file, result$problem, collapse = "\n"))
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
  expect_setequal(
    paste(result$check, result$file),
    c("large-file data/big.csv", "saved-object fits-shared/model.qs2", "no-stored-output analyses/new.qmd",
      "broken-link docs/extra.html", "doi-mismatch CITATION.cff")
  )
})

test_that("separators at the end of a path are dropped, except for a root", {
  expect_identical(drop_trailing_sep(c("site/", "site//", "a\\b\\", "/", "C:/", "C:\\", "site")),
                   c("site", "site", "a\\b", "/", "C:/", "C:\\", "site"))
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
  expect_match(rows$problem, "^104,857,601 bytes is more than", fixed = FALSE)
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
  rev_parse <- function(status, out) {
    function(args, dir) {
      if (identical(args, "--version")) list(status = 0L, stdout = charToRaw("git version 2"))
      else list(status = status, stdout = charToRaw(out))
    }
  }
  cases <- list(
    "not on the PATH" = function(args, dir) NULL,
    "`git --version` failed" = function(args, dir) list(status = 69L, stdout = raw()),
    "`git rev-parse` failed, or the folder is not in a git work tree" = rev_parse(128L, ""),
    # Inside .git/, rev-parse exits 0 and prints false.
    "`git rev-parse` failed, or the folder is not in a git work tree" = rev_parse(0L, "false\n")
  )
  for (i in seq_along(cases)) {
    case <- names(cases)[i]
    calls <- list()
    mock <- cases[[i]]
    local_mocked_bindings(git_run = function(args, dir) {
      calls[[length(calls) + 1]] <<- args
      mock(args, dir)
    })
    msgs <- testthat::capture_messages(result <- check_supplement(site))
    expect_identical(attr(result, "skipped"), c("large-file", "saved-object"), info = case)
    expect_false(any(result$check %in% c("large-file", "saved-object")), info = case)
    # cli wraps long lines, so compare with each run of spaces as one.
    shown <- gsub("\\s+", " ", paste(msgs, collapse = " "))
    expect_true(grepl("Skipped", shown, fixed = TRUE) && grepl(case, shown, fixed = TRUE), info = case)
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
  # A hidden file is not stored output.
  qmd("hidden-only", c("```{r}", "1 + 1", "```"))
  touch(file.path(site, "_freeze", "analyses", "hidden-only", "execute-results", ".DS_Store"))
  # A report that is a link to a missing file cannot be read and gives no
  # row and no error.
  file.symlink(file.path(site, "no-such.qmd"), file.path(site, "analyses", "dangling.qmd"))

  expect_no_error(rows <- rows_of(check_quiet(site), "no-stored-output"))
  # example.qmd from the template has R chunks and no stored output yet.
  expect_setequal(rows$file, file.path("analyses", c("r-chunk.qmd", "python-chunk.qmd", "callout.qmd",
                                                      "hidden-only.qmd", "example.qmd")))
})

# Write a report from its lines, with no front matter added.
report_lines <- function(site, name, lines) {
  writeLines(lines, file.path(site, "analyses", paste0(name, ".qmd")))
}

test_that("chunk starts in more shapes give a no-stored-output row", {
  site <- new_site()
  chunk <- function(name, start, end = "```") {
    report_lines(site, name, c("---", "title: Fixture", "---", "", start, "1 + 1", end))
  }
  chunk("space-r", "``` {r}")
  chunk("upper-r", "```{R}")
  chunk("mixed-python", "```{Python}")
  chunk("upper-julia", "```{JULIA}")
  chunk("four-backticks", "````{r}", "````")
  chunk("space-python", "``` {python}")
  chunk("julia-label", "```{julia label}")
  chunk("quote", "> ```{r}", "> ```")
  chunk("quote-nested", "> > ```{r}", "> > ```")
  chunk("quote-tight", ">```{python}", ">```")
  chunk("tab-quote", "\t> ```{r}", "\t> ```")
  chunk("tab-indent", "\t```{r}", "\t```")
  chunk("tab-brace", "```\t{r}")
  # knitr runs a chunk that a four-backtick block shows as text, and a
  # chunk inside an HTML comment.
  report_lines(site, "shown-chunk", c("````markdown", "```{r}", "1 + 1", "```", "````"))
  report_lines(site, "html-comment", c("<!--", "```{r}", "1 + 1", "```", "-->"))

  rows <- rows_of(check_quiet(site), "no-stored-output")
  expected <- c("space-r", "upper-r", "mixed-python", "upper-julia", "four-backticks", "space-python",
                "julia-label", "quote", "quote-nested", "quote-tight", "tab-quote", "tab-indent",
                "tab-brace", "shown-chunk", "html-comment", "example")
  expect_setequal(rows$file, file.path("analyses", paste0(expected, ".qmd")))
})

test_that("inline R code gives a row only under engine: knitr in the front matter", {
  site <- new_site()
  inline <- "Two is `r 1 + 1`."
  report_lines(site, "inline-knitr", c("---", "engine: knitr", "---", "", inline))
  # Blank lines may come before the front matter, spaces may follow its
  # first line, and `...` may end it.
  report_lines(site, "inline-knitr-blank", c("", "  ", "--- ", "engine: knitr", "...", "", inline))
  report_lines(site, "inline-no-engine", c("---", "title: Fixture", "---", "", inline))
  report_lines(site, "inline-markdown", c("---", "engine: markdown", "---", "", inline))
  report_lines(site, "inline-no-front", c("engine: knitr", "", inline))
  # A blank line after the first `---` means no front matter.
  report_lines(site, "inline-blank-second", c("---", "", "engine: knitr", "---", "", inline))
  report_lines(site, "inline-bad-yaml", c("---", "engine: knitr", "title: [open", "---", "", inline))
  report_lines(site, "inline-scalar", c("---", "knitr", "---", "", inline))
  report_lines(site, "inline-list", c("---", "engine: [knitr]", "---", "", inline))
  # Inline code counts only on one line, and only as `r` and a space.
  report_lines(site, "inline-split", c("---", "engine: knitr", "---", "", "Two is `r 1 +", "1`."))
  report_lines(site, "inline-hash", c("---", "engine: knitr", "---", "", "Two is `r# 1 + 1`."))
  report_lines(site, "knitr-no-code", c("---", "engine: knitr", "---", "", "Plain text."))

  expect_no_error(rows <- rows_of(check_quiet(site), "no-stored-output"))
  expect_setequal(rows$file, file.path("analyses", c("inline-knitr.qmd", "inline-knitr-blank.qmd",
                                                     "example.qmd")))
})

test_that("reading front matter runs no !expr code", {
  site <- new_site()
  withr::local_options(yaml.eval.expr = TRUE)
  marker <- expr_marker()
  engine <- paste("engine:", expr_value(marker, "knitr"))
  report_lines(site, "inline-expr", c("---", engine, "---", "", "Two is `r 1 + 1`."))

  rows <- rows_of(check_quiet(site), "no-stored-output")
  expect_identical(rows$file, "analyses/example.qmd")
  expect_false(file.exists(marker))
})

test_that("reading CITATION.cff runs no !expr code", {
  site <- new_site()
  withr::local_options(yaml.eval.expr = TRUE)
  marker <- expr_marker()
  writeLines(paste("doi:", expr_value(marker, "10.5281/zenodo.1")), file.path(site, "CITATION.cff"))

  # The value is read as the text of its code, which is not a DOI.
  expect_no_error(rows <- rows_of(check_quiet(site), "doi-mismatch"))
  expect_identical(rows$file, "CITATION.cff")
  expect_match(rows$problem, "not a DOI", fixed = TRUE)
  expect_false(file.exists(marker))
})

test_that("code blocks that are not chunks give no no-stored-output row", {
  site <- new_site()
  block <- function(name, start) {
    report_lines(site, name, c("---", "title: Fixture", "---", "", start, "1 + 1", "```"))
  }
  block("dot-class", "```{.r}")
  block("escaped", "```{{r}}")
  block("rust", "```{rust}")
  block("rcpp", "```{Rcpp}")
  block("text-after-brace", "```{r} x")

  rows <- rows_of(check_quiet(site), "no-stored-output")
  expect_identical(rows$file, "analyses/example.qmd")
})

test_that("glob characters in the site path do not hide reports", {
  # Windows does not allow * or ? in a file name.
  name <- if (.Platform$OS.type == "windows") "site [draft]" else "site [draft]*?"
  site <- file.path(withr::local_tempdir(), name)
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
    '<a href="data/Upper.csv">right case</a>',
    '<a href="data/ok.csv/">file with a slash</a>',
    # A `%` that starts no escape, before a non-ASCII character.
    '<a href="a%20b%aé.html">stray percent</a>',
    '<a href="data%2Fok.csv">encoded slash</a>',
    # A browser drops tabs and line breaks from a link, so this one works.
    '<a href="data/\nok.csv">line break</a>'
  ))
  # A page in Latin-1 with a NUL byte, and a link to a missing page.
  latin <- c(charToRaw('<p>caf'), as.raw(0xe9), as.raw(0), charToRaw('</p><a href="gone-latin.csv">x</a>'))
  writeBin(latin, file.path(site, "docs", "latin.html"))
  file.symlink(file.path(site, "docs", "no-such-page.html"), file.path(site, "docs", "dangling.html"))

  expect_warning(rows <- rows_of(check_quiet(site), "broken-link"), NA)
  # The page that is a link to a missing file gives its own row.
  unread <- !grepl("`", rows$problem, fixed = TRUE)
  expect_identical(rows$file[unread], "docs/dangling.html")
  expect_match(rows$problem[unread], "cannot be read")
  rows <- rows[!unread, ]
  links <- regmatches(rows$problem, regexpr("`[^`]*`$", rows$problem))
  expect_setequal(
    paste(rows$file, links),
    c("docs/names.html `café.html`",
      "docs/names.html `data/ok.csv/`",
      "docs/names.html `a%20b%aé.html`",
      "docs/names.html `data%2Fok.csv`",
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

# The broken-link rows of a site as "file `link`" strings.
broken_pairs <- function(site) {
  rows <- rows_of(check_quiet(site), "broken-link")
  paste(rows$file, regmatches(rows$problem, regexpr("`[^`]*`$", rows$problem)))
}

test_that("link-shaped text outside start tags gives no broken-link row", {
  site <- new_site()
  tags <- '<a href="gone-a.csv">a</a><img src="gone-b.png">'
  text <- 'href="gone-a.csv" src="gone-b.png"'
  write_page(site, "text.html", c(
    sprintf("<!-- %s %s -->", tags, text),
    '<a href="after-comment.csv">x</a>',
    "<!--", tags, text, "-->",
    '<a href="after-long-comment.csv">x</a>',
    sprintf("<script>document.write('%s'); var x = '%s';</SCRIPT>", tags, text),
    '<a href="after-script.csv">x</a>',
    sprintf("<style>/* %s %s */</Style>", tags, text),
    '<a href="after-style.csv">x</a>',
    sprintf("<textarea>%s %s</textarea>", tags, text),
    '<a href="after-textarea.csv">x</a>',
    sprintf("<title>%s %s</TITLE>", tags, text),
    '<a href="after-title.csv">x</a>',
    sprintf("<code>%s</code>", text),
    '<a href="after-code.csv">x</a>',
    sprintf("<p>%s</p>", text),
    '<a href="after-p.csv">x</a>',
    # A text `<` before a comment does not join the text after it.
    '<p>a <<!-- c -->a href="gone-joined.csv">x</p>',
    '<script src="gone.js"></script>'
  ))
  expect_setequal(
    broken_pairs(site),
    paste("docs/text.html", c(
      "`after-comment.csv`", "`after-long-comment.csv`", "`after-script.csv`",
      "`after-style.csv`", "`after-textarea.csv`", "`after-title.csv`",
      "`after-code.csv`", "`after-p.csv`", "`gone.js`"
    ))
  )
})

test_that("only href, src, and xlink:href attributes are read, in any letter case", {
  site <- new_site()
  write_page(site, "names.html", c(
    '<a HREF="gone-upper.csv">x</a>',
    '<img Src="gone-mixed.png">',
    '<svg><use XLINK:HREF="gone-xlink.svg"/></svg>',
    '<a href = "gone-spaced.csv">x</a>',
    '<a title="a > b" href="gone-after-gt.csv">x</a>',
    '<div data-href="gone-data.csv" data-src="gone-data.png"></div>',
    '<img ng-src="gone-ng.png">'
  ))
  expect_setequal(
    broken_pairs(site),
    paste("docs/names.html", c(
      "`gone-upper.csv`", "`gone-mixed.png`", "`gone-xlink.svg`",
      "`gone-spaced.csv`", "`gone-after-gt.csv`"
    ))
  )
})

test_that("quoted and unquoted values are read and trimmed", {
  site <- new_site()
  touch(file.path(site, "docs", "data", "ok.csv"))
  write_page(site, "values.html", c(
    '<a href=" data/ok.csv ">spaces</a>',
    '<a href="\f\tdata/ok.csv\n">form feed</a>',
    "<a href=data/ok.csv>unquoted</a>",
    "<a href=gone-c.csv>unquoted</a>",
    "<a href='gone-d.csv'>single</a>",
    "<a href=data/ok.csv/>slash</a>",
    '<a href="&#109;ailto&#58;a@example.org">mail</a>',
    # An attribute with no `=` has an empty value, so it is no link.
    "<a href>bare</a><script src></script><a HREF >bare</a>"
  ))
  expect_setequal(
    broken_pairs(site),
    paste("docs/values.html", c("`gone-c.csv`", "`gone-d.csv`", "`data/ok.csv/`"))
  )
})

test_that("character references in a link are decoded by the stated rules", {
  site <- new_site()
  touch(file.path(site, "docs", "R&D.csv"))
  touch(file.path(site, "docs", "it's.csv"))
  touch(file.path(site, "docs", "data", "a b.csv"))
  kept <- c("R&eacute;.csv", "R&AMP;D.csv", "R&ampD.csv", "R&#38D.csv",
            "R&#0;.csv", "R&#xD800;.csv", "R&#x110000;.csv", "R&#x80;.csv")
  write_page(site, "refs.html", c(
    '<a href="R&amp;D.csv">x</a>',
    '<a href="R&#38;D.csv">x</a>',
    '<a href="R&#x26;D.csv">x</a>',
    '<a href="R&#X26;D.csv">x</a>',
    '<a href="it&apos;s.csv">x</a>',
    '<a href="data/a&#37;20b.csv">x</a>',
    sprintf('<a href="%s">x</a>', kept)
  ))
  expect_setequal(broken_pairs(site), paste0("docs/refs.html `", kept, "`"))
  expect_identical(decode_refs("&lt;&gt;&quot;&apos;&amp;&#233;&#x1F600;"), "<>\"'&é\U0001F600")
  expect_identical(decode_refs(c("é&amp;", "", "&amp;amp;", "none")), c("é&", "", "&amp;", "none"))
})

test_that("large skipped text and unclosed markup give the stated rows", {
  site <- new_site()
  # Over 5 MB of script text, as a large htmlwidget writes, is still
  # skipped, and the reader then goes on.
  rows <- strrep('{"cell": "<a href=\\"gone-big.csv\\">x</a>"}, ', 120000)
  write_page(site, "big.html", c(
    sprintf('<script type="application/json">[%s]</script>', rows),
    '<a href="after-big.csv">x</a>'
  ))
  # Each page ends inside markup that never closes.
  write_page(site, "end-comment.html", c('<a href="before-1.csv">x</a>', '<!-- <a href="gone-1.csv">'))
  write_page(site, "end-script.html", c('<a href="before-2.csv">x</a>', '<script> <a href="gone-2.csv">'))
  write_page(site, "end-title.html", c('<a href="before-3.csv">x</a>', '<TITLE> <a href="gone-3.csv">'))
  # writeLines() ends the file with a line break, so these tags run to the
  # end of the page with no `>`.
  writeLines(c('<a href="before-4.csv">x</a>', "<div title=\"<a href='gone-4.csv'>\""),
             file.path(site, "docs", "end-tag.html"))
  # Many tags that never close, which took time that grew with the square
  # of their count.
  writeLines(c('<a href="before-5.csv">x</a>', strrep("<a ", 60000)),
             file.path(site, "docs", "many-open.html"))
  time <- system.time(expect_warning(pairs <- broken_pairs(site), NA))[["elapsed"]]
  expect_setequal(pairs, c(
    "docs/big.html `after-big.csv`",
    "docs/end-comment.html `before-1.csv`", "docs/end-script.html `before-2.csv`",
    "docs/end-title.html `before-3.csv`", "docs/end-tag.html `before-4.csv`",
    "docs/many-open.html `before-5.csv`"
  ))
  # 20,000 such tags took 11 s with the earlier pattern, so 60,000 would
  # take about 100 s.
  expect_lt(time, 10)
})

test_that("a long page with non-ASCII text is read in linear time", {
  site <- new_site()
  touch(file.path(site, "docs", "données.csv"))
  write_page(site, "index.html", c(
    "<p>café</p>",
    strrep('<p>text — more</p><a href="données.csv">x</a>', 20000),
    '<a href="gone-é.csv">x</a>'
  ))
  time <- system.time(pairs <- broken_pairs(site))[["elapsed"]]
  expect_identical(pairs, "docs/index.html `gone-é.csv`")
  expect_true(validUTF8(pairs))
  expect_lt(time, 10)
})

test_that("a page whose markup the reader cannot finish gives the PCRE-limit row", {
  site <- new_site()
  write_page(site, "index.html", '<a href="gone.csv">x</a>')
  local_mocked_bindings(tag_links = function(html) {
    warning("PCRE error 'match limit exceeded'")
    "gone.csv"
  })
  rows <- rows_of(check_quiet(site), "broken-link")
  expect_identical(rows$file, "docs/index.html")
  expect_match(rows$problem, "cannot read this page: its markup goes past the limits", fixed = TRUE)
})

# The broken-link rows of a site as "file: problem" strings, sorted, so
# that a row given twice shows.
link_rows <- function(site) {
  rows <- rows_of(check_quiet(site), "broken-link")
  sort(sprintf("%s: %s", rows$file, rows$problem))
}

page_row <- function(page, link) {
  sprintf("docs/%s: The page links to a file that is not in the site: `%s`", page, link)
}

outside_row <- function(link) {
  sprintf("docs/%s: It is a link to a place outside docs/, so the published site does not have its target.", link)
}

# A symbolic link at `link` to `target`, or a skip where none can be made.
# On Windows a link to a folder is a junction, because unlink() cannot
# remove a folder symbolic link there and the cleanup warns.
symlink_or_skip <- function(target, link) {
  make <- if (.Platform$OS.type == "windows" && dir.exists(target)) Sys.junction else file.symlink
  made <- suppressWarnings(make(target, link))
  skip_if_not(made, "cannot make a symbolic link here (Windows without developer mode)")
}

test_that("pages in hidden folders and hidden pages are read", {
  site <- new_site()
  write_page(site, ".hidden/page.html", '<a href="gone-1.csv">x</a>')
  write_page(site, ".page.html", '<a href="gone-2.csv">x</a>')
  write_page(site, "sub/.deep/page.html", '<a href="gone-3.csv">x</a>')
  expect_identical(link_rows(site), sort(c(
    page_row(".hidden/page.html", "gone-1.csv"),
    page_row(".page.html", "gone-2.csv"),
    page_row("sub/.deep/page.html", "gone-3.csv")
  )))
})

test_that("the page listing does not enter a linked folder", {
  site <- new_site()
  docs <- file.path(site, "docs")
  write_page(site, "index.html", '<a href="gone-1.csv">x</a>')
  write_page(site, "sub/page.html", '<a href="gone-2.csv">x</a>')
  symlink_or_skip(docs, file.path(docs, "loop"))
  symlink_or_skip(file.path(docs, "sub"), file.path(docs, "inner"))
  expect_identical(link_rows(site), sort(c(
    page_row("index.html", "gone-1.csv"),
    page_row("sub/page.html", "gone-2.csv")
  )))
})

test_that("a link in docs to a place outside docs gives one row", {
  site <- new_site()
  docs <- file.path(site, "docs")
  outside <- withr::local_tempdir("outside-")
  writeLines("secret", file.path(outside, "secret.txt"))
  # The page that docs/out.html points to is not read.
  writeLines('<a href="gone-out.csv">x</a>', file.path(outside, "out.html"))
  # Nor is a page in the folder that docs/ext points to.
  dir.create(file.path(outside, "folder"))
  writeLines('<a href="gone-ext.csv">x</a>', file.path(outside, "folder", "page.html"))
  touch(file.path(docs, "data", "ok.csv"))
  symlink_or_skip(file.path(site, "_supplement.yml"), file.path(docs, "meta.yml"))
  symlink_or_skip(file.path(outside, "secret.txt"), file.path(docs, "secret.txt"))
  symlink_or_skip(file.path(outside, "out.html"), file.path(docs, "out.html"))
  symlink_or_skip(file.path(outside, "folder"), file.path(docs, "ext"))
  # Links whose targets are inside docs/ give no row.
  symlink_or_skip(file.path(docs, "data", "ok.csv"), file.path(docs, "alias.csv"))
  symlink_or_skip(file.path(docs, "data"), file.path(docs, "inner"))
  expect_identical(link_rows(site), sort(outside_row(c("meta.yml", "secret.txt", "out.html", "ext"))))
})

test_that("a page link through a link to a place outside docs gives a row", {
  site <- new_site()
  docs <- file.path(site, "docs")
  outside <- withr::local_tempdir("outside-")
  touch(file.path(outside, "private", "x.csv"))
  touch(file.path(outside, "data.csv"))
  touch(file.path(docs, "sub", "y.csv"))
  symlink_or_skip(file.path(outside, "private"), file.path(docs, "private"))
  symlink_or_skip(file.path(outside, "data.csv"), file.path(docs, "data.csv"))
  symlink_or_skip(file.path(docs, "sub"), file.path(docs, "inner"))
  symlink_or_skip(file.path(docs, "sub", "y.csv"), file.path(docs, "alias.csv"))
  write_page(site, "index.html", c(
    '<a href="private/x.csv">x</a>',
    '<a href="data.csv">x</a>',
    '<a href="inner/y.csv">x</a>',
    '<a href="alias.csv">x</a>'
  ))
  expect_identical(link_rows(site), sort(c(
    outside_row(c("private", "data.csv")),
    page_row("index.html", c("private/x.csv", "data.csv"))
  )))
})

test_that("a page link to a folder whose index.html is a link outside docs gives a row", {
  site <- new_site()
  docs <- file.path(site, "docs")
  outside <- withr::local_tempdir("outside-")
  writeLines("<p>outside</p>", file.path(outside, "page.html"))
  dir.create(file.path(docs, "sub"), recursive = TRUE)
  symlink_or_skip(file.path(outside, "page.html"), file.path(docs, "index.html"))
  symlink_or_skip(file.path(outside, "page.html"), file.path(docs, "sub", "index.html"))
  write_page(site, "page.html", c(
    '<a href="sub/">a</a>', '<a href="sub">b</a>', '<a href="sub/index.html">c</a>',
    '<a href="./">d</a>', '<a href=".">e</a>'
  ))
  expect_identical(link_rows(site), sort(c(
    outside_row(c("index.html", "sub/index.html")),
    page_row("page.html", c("sub/", "sub", "sub/index.html", "./", "."))
  )))
})

test_that("a page name that is not valid UTF-8 does not stop the link check", {
  site <- new_site()
  write_page(site, "index.html", '<a href="gone.csv">x</a>')
  # "caf<e9>.html" sorts before "index.html" in byte order.
  bad <- rawToChar(as.raw(c(0x63, 0x61, 0x66, 0xe9, 0x2e, 0x68, 0x74, 0x6d, 0x6c)))
  # Windows stops with an error on such a name, and macOS refuses it.
  made <- tryCatch(suppressWarnings(file.create(file.path(site, "docs", bad))), error = function(e) FALSE)
  skip_if_not(made && length(list.files(file.path(site, "docs"))) == 2,
              "this file system cannot hold a name that is not valid UTF-8")
  expect_identical(link_rows(site), page_row("index.html", "gone.csv"))
})

test_that("relative link targets and links in hidden folders are judged by where they resolve", {
  # A relative target written with `/` is not tested on Windows.
  skip_on_os("windows")
  site <- new_site()
  docs <- file.path(site, "docs")
  touch(file.path(docs, "data", "ok.csv"))
  dir.create(file.path(docs, ".hidden"))
  symlink_or_skip("../_supplement.yml", file.path(docs, "rel.yml"))
  symlink_or_skip("../../_supplement.yml", file.path(docs, ".hidden", "meta.yml"))
  symlink_or_skip("data/ok.csv", file.path(docs, "alias.csv"))
  symlink_or_skip(".", file.path(docs, "self"))
  expect_identical(link_rows(site), sort(outside_row(c("rel.yml", ".hidden/meta.yml"))))
})

test_that("the Windows link test gives the rules' answer for each path of a folder", {
  # is_reparse_point() is plain R, so its rules run on every system.
  dir <- withr::local_tempdir()
  outside <- withr::local_tempdir("outside-")
  touch(file.path(dir, "file.txt"))
  dir.create(file.path(dir, "folder"))
  touch(file.path(dir, "sub", "deep.txt"))
  writeLines("x", file.path(outside, "target.txt"))
  symlink_or_skip(file.path(outside, "target.txt"), file.path(dir, "file-link"))
  symlink_or_skip(outside, file.path(dir, "folder-link"))
  symlink_or_skip(file.path(outside, "missing.txt"), file.path(dir, "dangling"))
  names <- c("file.txt", "folder", "file-link", "folder-link", "dangling", "not-there", "sub/deep.txt", "folder/",
             "FILE.TXT", "FILE-LINK")
  # The folder lists "FILE.TXT" and "FILE-LINK" only in another letter
  # case. On a disk that ignores case, "FILE.TXT" is the plain file. On a
  # disk that does not, it does not exist, so the rules count it as a link,
  # as they count "FILE-LINK" on both.
  ignores_case <- file.exists(file.path(dir, "FILE.TXT"))
  # On Windows, a file link to a missing file reads as a plain file
  # (candidate row "Detect broken file links on Windows").
  dangling <- .Platform$OS.type != "windows"
  expect_identical(
    is_reparse_point(file.path(dir, names)),
    c(FALSE, FALSE, TRUE, TRUE, dangling, FALSE, FALSE, FALSE, !ignores_case, TRUE)
  )
  expect_identical(is_reparse_point(character()), logical())
})

test_that("on Windows, a junction in docs to a folder outside docs gives the rows of a link", {
  skip_on_os(c("mac", "linux", "solaris"))
  site <- new_site()
  docs <- file.path(site, "docs")
  outside <- withr::local_tempdir("outside-")
  touch(file.path(outside, "x.csv"))
  touch(file.path(docs, "sub", "y.csv"))
  stopifnot(Sys.junction(outside, file.path(docs, "private")))
  stopifnot(Sys.junction(file.path(docs, "sub"), file.path(docs, "inner")))
  write_page(site, "index.html", c('<a href="private/x.csv">x</a>', '<a href="inner/y.csv">x</a>'))
  expect_identical(link_rows(site), sort(c(
    outside_row("private"),
    page_row("index.html", "private/x.csv")
  )))
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
  # A badge that is not a DOI does not hide a wrong badge beside it.
  rows <- doi_rows(site_with("10.5281/zenodo.2", badges = c("nota", "10.5281/zenodo.9")))
  expect_length(rows$problem, 2L)
  expect_match(rows$problem, "nota, which is not a DOI", all = FALSE)
  expect_match(rows$problem, "shows 10.5281/zenodo.9, and", all = FALSE)
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
    expect_match(doi_rows(site)$problem, "cannot be read, or it is not a YAML map")
  }
  # A CITATION.cff that is a link to a missing file, or that holds Latin-1
  # bytes, gives the same row and no warning.
  site <- site_with("10.5281/zenodo.2")
  file.symlink(file.path(site, "no-such.cff"), file.path(site, "CITATION.cff"))
  expect_match(doi_rows(site)$problem, "cannot be read, or it is not a YAML map")
  site <- site_with("10.5281/zenodo.2")
  writeBin(c(charToRaw("title: caf"), as.raw(0xe9), charToRaw("\n")), file.path(site, "CITATION.cff"))
  expect_no_warning(rows <- doi_rows(site))
  expect_length(rows$problem, 1L)
  # A readable map with no final line break, or with a number that YAML
  # warns about, still compares its DOI.
  site <- site_with("", "10.5281/zenodo.9", cff = "")
  writeBin(charToRaw("count: 99999999999999999999\ndoi: \"10.5281/zenodo.9\""), file.path(site, "CITATION.cff"))
  expect_identical(nrow(doi_rows(site)), 0L)
  # A one-item sequence is not one text value.
  site <- site_with("", "10.5281/zenodo.9", cff = "")
  writeLines("doi: [10.5281/zenodo.9]", file.path(site, "CITATION.cff"))
  expect_match(doi_rows(site)$problem, "not one text value")
  # An index.qmd that cannot be read stops nothing.
  site <- site_with("10.5281/zenodo.2", badges = character())
  index <- file.path(site, "index.qmd")
  Sys.chmod(index, "000")
  withr::defer(Sys.chmod(index, "644"))
  skip_if(file.access(index, 4) == 0, "the file can still be read, as for root")
  expect_no_error(doi_rows(site))
})

test_that("git output in a folder with pattern characters removes only its own file", {
  skip_if_not(nzchar(Sys.which("git")), "git is not on the PATH")
  base <- withr::local_tempdir()
  # "tmp[ab]" read as a pattern matches "tmpa".
  dir.create(file.path(base, "tmp[ab]"))
  dir.create(file.path(base, "tmpa"))
  writeLines("mine", file.path(base, "tmpa", "git-out"))
  out <- file.path(base, "tmp[ab]", "git-out")
  local_mocked_bindings(git_out_file = function() out)
  result <- git_run("--version", base)
  expect_identical(result$status, 0L)
  expect_match(rawToChar(result$stdout), "^git version")
  expect_false(file.exists(out))
  expect_identical(readLines(file.path(base, "tmpa", "git-out")), "mine")
})
