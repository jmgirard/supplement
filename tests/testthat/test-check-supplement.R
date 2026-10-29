# check_supplement() lists the problems that would break or leak a release.

check_quiet <- function(path) suppressMessages(check_supplement(path))

rows_of <- function(result, check) result[result$check == check, , drop = FALSE]

# The last sentence of each row for a report with old or unreadable stored
# output, and the second-to-last of the row for a report with none.
rerender_steps <- paste("Render the report by name, render the whole site, then commit the report with",
                        "_freeze/, docs/, and figures/. In R, render_supplement() with the report's name",
                        "does both renders.")
# The sentence after it in the row for a report with no stored output.
menu_step <- "If you added the report to the Analyses menu, as add_report() does, also commit _quarto.yml."

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
  site <- fill_placeholders(new_site())
  # With both DOIs, the home page shows a Zenodo badge from Quarto's own
  # output, and CITATION.cff holds the concept DOI.
  yml <- file.path(site, "_supplement.yml")
  set_supplement_value(yml, "version-doi", "10.5281/zenodo.222")
  set_supplement_value(yml, "concept-doi", "10.5281/zenodo.111")
  write_citation(site)
  rendered <- run_in(site, "quarto", "render")
  expect_identical(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))
  local_plain_git()
  expect_status(git_in(site, c("init", "-q")))
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
  expect_status(git_in(site, c("add", "-f", "fits-shared/model.qs2")))
  writeLines(c("---", "title: New", "---", "", "```{r}", "1 + 1", "```"),
             file.path(site, "analyses", "new.qmd"))
  write_page(site, "extra.html", '<a href="missing.csv">x</a>')
  writeLines(c("doi: \"10.5281/zenodo.99\""), file.path(site, "CITATION.cff"))
  writeBin(as.raw(1:4), file.path(site, "figures", "new.png"))
  dir.create(file.path(site, "docs", "data"), showWarnings = FALSE)
  writeBin(as.raw(1:4), file.path(site, "docs", "data", "x.rds"))
  result <- check_quiet(site)
  expect_setequal(
    paste(result$check, result$file),
    c("large-file data/big.csv", "saved-object fits-shared/model.qs2", "no-stored-output analyses/new.qmd",
      "broken-link docs/extra.html", "doi-mismatch CITATION.cff", "ignored-output docs/data/x.rds",
      "unpublished-figure figures/new.png")
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
  expect_status(git_in(site, c("add", "-f", "fits/model.RDS")))
  touch(file.path(site, "x.rds"))
  # The template's .gitignore blocks *.rds, so only a tracked or force-added
  # one, or one in a folder whose own rules let it through, is listed.
  dir.create(file.path(site, "open"))
  writeLines("!*.rds", file.path(site, "open", ".gitignore"))
  touch(file.path(site, "open", "données.rds"))

  rows <- rows_of(check_quiet(site), "saved-object")
  expect_setequal(rows$file, c("fits/model.RDS", "open/données.rds"))
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
    git_checks <- c("large-file", "saved-object", "ignored-output")
    expect_identical(attr(result, "skipped"), git_checks, info = case)
    expect_false(any(result$check %in% git_checks), info = case)
    # cli wraps long lines, so compare with each run of spaces as one.
    shown <- gsub("\\s+", " ", paste(msgs, collapse = " "))
    expect_true(grepl("Skipped", shown, fixed = TRUE) && grepl(case, shown, fixed = TRUE), info = case)
    for (check in git_checks) expect_match(shown, check, fixed = TRUE, info = case)
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
                                                      "rust-block.qmd", "hidden-only.qmd", "example.qmd")))
  expect_true(all(endsWith(rows$problem, paste(rerender_steps, menu_step))))
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

test_that("chunks of any engine give a no-stored-output row", {
  site <- new_site()
  # Quarto starts Jupyter for a chunk name that no engine claims. Under
  # engine: knitr, knitr runs only engines it knows, such as bash, sql, or
  # Rcpp.
  names <- c("bash", "sql", "html", "include", "Rcpp", "rust", "my_eng2", "dotnet", "ojsx")
  for (name in names) {
    report_lines(site, paste0("engine-", name),
                 c("---", "title: Fixture", "---", "", paste0("```{", name, "}"), "x", "```"))
  }

  rows <- rows_of(check_quiet(site), "no-stored-output")
  expect_setequal(rows$file, file.path("analyses", paste0(c(paste0("engine-", names), "example"), ".qmd")))
})

# Write a report from raw bytes, so that it can hold a nul byte and any line
# ends.
report_bytes <- function(site, name, ...) {
  parts <- lapply(list(...), function(x) if (is.character(x)) charToRaw(x) else x)
  writeBin(unlist(parts), file.path(site, "analyses", paste0(name, ".qmd")))
}

test_that("a nul byte or other line ends do not hide a chunk", {
  site <- new_site()
  nul <- as.raw(0)
  front <- "---\ntitle: Fixture\n---\n\n"
  report_bytes(site, "nul-other-line", front, "a", nul, "b\n\n```{r}\n1 + 1\n```\n")
  report_bytes(site, "nul-in-braces", front, "```{r", nul, "}\n1 + 1\n```\n")
  report_bytes(site, "crlf-bash", "---\r\ntitle: Fixture\r\n---\r\n\r\n```{bash}\r\necho hi\r\n```\r\n")
  report_bytes(site, "cr-bash", "---\rtitle: Fixture\r---\r\r```{bash}\recho hi\r```\r")
  # Quarto's chunk scan reads a nul as a character that is not white space
  # and not part of a name, so these start no engine.
  report_bytes(site, "nul-after-brace", front, "```{r}", nul, "\n1 + 1\n```\n")
  report_bytes(site, "nul-before-ticks", front, nul, "```{r}\n1 + 1\n```\n")
  report_bytes(site, "nul-in-ojs", front, "```{ojs", nul, "}\n1 + 1\n```\n")

  expect_no_error(rows <- rows_of(check_quiet(site), "no-stored-output"))
  expected <- c("nul-other-line", "nul-in-braces", "crlf-bash", "cr-bash", "example")
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
  # Inline code counts only on one line.
  report_lines(site, "inline-split", c("---", "engine: knitr", "---", "", "Two is `r 1 +", "1`."))
  report_lines(site, "knitr-no-code", c("---", "engine: knitr", "---", "", "Plain text."))
  # knitr also runs `r#` code and Quarto's `{r}` syntax with a space.
  report_lines(site, "inline-hash", c("---", "engine: knitr", "---", "", "Two is `r# 1 + 1`."))
  report_lines(site, "inline-hash-tight", c("---", "engine: knitr", "---", "", "Two is `r#1+1`."))
  report_lines(site, "inline-braces", c("---", "engine: knitr", "---", "", "Two is `{r} 1 + 1`."))
  report_lines(site, "inline-braces-no-engine", c("---", "title: Fixture", "---", "", "Two is `{r} 1 + 1`."))
  report_lines(site, "inline-braces-tight", c("---", "engine: knitr", "---", "", "Two is `{r}1+1`."))

  expect_no_error(rows <- rows_of(check_quiet(site), "no-stored-output"))
  expected <- c("inline-knitr", "inline-knitr-blank", "inline-hash", "inline-hash-tight", "inline-braces",
                "example")
  expect_setequal(rows$file, file.path("analyses", paste0(expected, ".qmd")))
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
  block("text-after-brace", "```{r} x")
  block("raw-html", "```{=html}")
  block("digit-first", "```{1r}")
  # Quarto starts no engine for these.
  block("mermaid", "```{mermaid}")
  block("mermaid-upper", "```{Mermaid}")
  block("mermaid-label", "```{mermaid label}")
  block("dot", "```{dot}")
  block("ojs", "```{ojs}")
  block("ojs-upper", "```{OJS}")

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

# Write a file of stored output for report `name` from text or raw bytes.
stored_file <- function(site, name, file, content) {
  dir <- file.path(site, "_freeze", "analyses", name, "execute-results")
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  writeBin(if (is.character(content)) charToRaw(content) else content, file.path(dir, file))
}

# The JSON of a stored output file whose top-level hash is `hash`.
hash_json <- function(hash) sprintf('{"hash": "%s", "result": {"markdown": "x"}}', hash)

# The MD5 of text or raw bytes, from tools::md5sum() on a file that holds
# them.
md5_of <- function(...) {
  parts <- lapply(list(...), function(x) if (is.character(x)) charToRaw(x) else x)
  file <- withr::local_tempfile()
  writeBin(unlist(parts), file)
  unname(tools::md5sum(file))
}

stale_lf <- "---\ntitle: Fixture\n---\n\n```{r}\n1 + 1\n```\n"

# The paths of files `files` of report `name` as a stale-output row names
# them, for names that hold no `\` or `"`.
quoted_paths <- function(name, files) {
  paste0('"', file.path("_freeze/analyses", name, "execute-results", files), '"', collapse = ", ")
}

# The step that a stale-output row adds after the render steps when a
# source hash cannot be read.
delete_step <- paste("If the row stays after these steps, these files can be from a format that the report",
                     "no longer renders, or damaged. Delete them, render the whole site, and commit the report",
                     "with _freeze/, docs/, and figures/.")

# The problem text of a stale-output row whose files `files` of report
# `name` differ, with the format hint when `hint` is TRUE.
stale_text <- function(name, files, hint = FALSE, paths = quoted_paths(name, files)) {
  stale <- paste0("Its stored output was made from other text than the report holds now: ", paths, ".")
  if (!hint) {
    return(paste(stale, rerender_steps))
  }
  paste(stale,
        "Other stored output of the report matches the report, so these files can be from a format that the",
        "report no longer renders. If so, delete them, render the whole site, and commit the report with",
        "_freeze/, docs/, and figures/.",
        "If not, take these steps.", rerender_steps)
}

# The problem text of a stale-output row whose source hash cannot be read
# from files `files` of report `name`.
unreadable_text <- function(name, files, paths = quoted_paths(name, files)) {
  paste0("The source hash of its stored output cannot be read from ", paths, ". ", rerender_steps, " ",
         delete_step)
}

test_that("stored output made from other report text gives a stale-output row", {
  site <- new_site()
  stored <- function(name, ..., file = "html.json", hash) {
    report_bytes(site, name, ...)
    stored_file(site, name, file, hash_json(hash))
  }
  stored("differs", stale_lf, hash = md5_of(stale_lf, "x"))
  stored("matches", stale_lf, hash = md5_of(stale_lf))
  stored("two-files", stale_lf, hash = md5_of(stale_lf))
  stored_file(site, "two-files", "docx.json", hash_json(md5_of(stale_lf, "x")))
  report_bytes(site, "no-stored", stale_lf)
  # A report that cannot be read gives no row.
  file.symlink(file.path(site, "no-such.qmd"), file.path(site, "analyses", "dangling.qmd"))
  stored_file(site, "dangling", "html.json", hash_json(md5_of(stale_lf, "x")))
  # Quarto hashes CR LF text as LF and keeps a byte order mark and a lone
  # CR. The expected hashes are written here from the text that Quarto
  # hashes (the LF text for CR LF, the bytes as they are otherwise), not
  # taken from the check.
  stored("crlf", gsub("\n", "\r\n", stale_lf, fixed = TRUE), hash = md5_of(stale_lf))
  bom <- as.raw(c(0xef, 0xbb, 0xbf))
  stored("bom", bom, stale_lf, hash = md5_of(bom, stale_lf))
  lone_cr <- gsub("\n", "\r", stale_lf, fixed = TRUE)
  stored("lone-cr", lone_cr, hash = md5_of(lone_cr))
  no_final <- sub("\n$", "", stale_lf)
  stored("no-final-lf", no_final, hash = md5_of(no_final))
  # Hidden files, files that do not end in .json, and reports in folders
  # inside analyses/ are not read.
  stored("hidden-json", stale_lf, file = ".html.json", hash = md5_of(stale_lf, "x"))
  stored_file(site, "hidden-json", "notes.txt", "not JSON")
  stored("json-folder", stale_lf, hash = md5_of(stale_lf))
  dir.create(file.path(site, "_freeze", "analyses", "json-folder", "execute-results", "old.json"))
  dir.create(file.path(site, "analyses", "sub"))
  writeBin(charToRaw(stale_lf), file.path(site, "analyses", "sub", "inner.qmd"))
  stored_file(site, file.path("sub", "inner"), "html.json", hash_json(md5_of(stale_lf, "x")))

  expect_no_error(rows <- rows_of(check_quiet(site), "stale-output"))
  expect_setequal(rows$file, c("analyses/differs.qmd", "analyses/two-files.qmd"))
  expect_identical(nrow(rows), 2L)
})

test_that("a stale-output row names each file that differs, with a format hint when another file matches", {
  site <- new_site()
  report <- function(name, matching = character(), differing = character()) {
    report_bytes(site, name, stale_lf)
    for (file in matching) stored_file(site, name, file, hash_json(md5_of(stale_lf)))
    for (file in differing) stored_file(site, name, file, hash_json(md5_of(stale_lf, "x")))
  }
  report("only-html", differing = "html.json")
  report("docx-differs", matching = "html.json", differing = "docx.json")
  report("html-differs", matching = "docx.json", differing = "html.json")
  report("two-differ", matching = "html.json", differing = c("pdf.json", "docx.json"))
  report("none-match", differing = c("html.json", "docx.json"))
  # A hidden file and a folder are not read.
  report("hidden", matching = "html.json", differing = ".docx.json")
  dir.create(file.path(site, "_freeze", "analyses", "hidden", "execute-results", "old.json"))
  report("hidden-match", matching = ".html.json", differing = "docx.json")

  rows <- rows_of(check_quiet(site), "stale-output")
  expect_setequal(rows$file, paste0("analyses/", c("only-html", "docx-differs", "html-differs", "two-differ",
                                                  "none-match", "hidden-match"), ".qmd"))
  text <- function(name) rows$problem[rows$file == paste0("analyses/", name, ".qmd")]
  expect_identical(
    text("only-html"),
    paste("Its stored output was made from other text than the report holds now:",
          '"_freeze/analyses/only-html/execute-results/html.json".', rerender_steps)
  )
  expect_identical(text("docx-differs"), stale_text("docx-differs", "docx.json", hint = TRUE))
  expect_identical(text("html-differs"), stale_text("html-differs", "html.json", hint = TRUE))
  expect_identical(text("two-differ"), stale_text("two-differ", c("docx.json", "pdf.json"), hint = TRUE))
  expect_identical(text("none-match"), stale_text("none-match", c("docx.json", "html.json")))
  expect_identical(text("hidden-match"), stale_text("hidden-match", "docx.json"))
})

test_that("the files a stale-output row names come in byte order, not the locale's order", {
  site <- new_site()
  report_bytes(site, "order", stale_lf)
  for (file in c("a.json", "B.json")) stored_file(site, "order", file, hash_json(md5_of(stale_lf, "x")))
  old <- Sys.getlocale("LC_COLLATE")
  set <- suppressWarnings(Sys.setlocale("LC_COLLATE", "en_US.UTF-8"))
  withr::defer(Sys.setlocale("LC_COLLATE", old))
  skip_if(!nzchar(set), "the en_US.UTF-8 locale is not available")
  # The locale's order differs, so the test can tell the two apart.
  expect_false(identical(sort(c("B.json", "a.json")), c("B.json", "a.json")))
  rows <- rows_of(check_quiet(site), "stale-output")
  expect_identical(rows$problem, stale_text("order", c("B.json", "a.json")))
})

test_that("a source hash that cannot be read gives a stale-output row that says so", {
  site <- new_site()
  cases <- c(
    "not-json" = '{"hash": ',
    "string-top" = '"abc"',
    "array-top" = "[1]",
    "no-hash" = '{"result": {}}',
    "number-hash" = '{"hash": 1}',
    # A list that holds the right hash is still not one text value.
    "list-hash" = sprintf('{"hash": ["%s"]}', md5_of(stale_lf))
  )
  for (name in names(cases)) {
    report_bytes(site, name, stale_lf)
    stored_file(site, name, "html.json", cases[[name]])
  }
  report_bytes(site, "both", stale_lf)
  stored_file(site, "both", "docx.json", "{")
  stored_file(site, "both", "html.json", hash_json(md5_of(stale_lf, "x")))
  report_bytes(site, "two-unreadable", stale_lf)
  stored_file(site, "two-unreadable", "html.json", "{")
  stored_file(site, "two-unreadable", "docx.json", "[1")
  report_bytes(site, "beside-match", stale_lf)
  stored_file(site, "beside-match", "docx.json", "{")
  stored_file(site, "beside-match", "html.json", hash_json(md5_of(stale_lf)))

  expect_no_error(rows <- rows_of(check_quiet(site), "stale-output"))
  extra <- c("both", "two-unreadable", "beside-match")
  expect_setequal(rows$file, file.path("analyses", paste0(c(names(cases), extra), ".qmd")))
  expect_identical(nrow(rows), length(cases) + length(extra))
  for (problem in rows$problem) {
    expect_match(problem, "The source hash of its stored output cannot be read", fixed = TRUE)
  }
  expect_true(all(endsWith(rows$problem, paste(rerender_steps, delete_step))))
  expect_false(any(grepl("_quarto.yml", rows$problem, fixed = TRUE)))
  text <- function(name) rows$problem[rows$file == paste0("analyses/", name, ".qmd")]
  expect_identical(
    text("not-json"),
    paste("The source hash of its stored output cannot be read from",
          '"_freeze/analyses/not-json/execute-results/html.json".', rerender_steps, delete_step)
  )
  expect_identical(text("two-unreadable"), unreadable_text("two-unreadable", c("docx.json", "html.json")))
  expect_identical(text("both"), unreadable_text("both", "docx.json"))
  expect_identical(text("beside-match"), unreadable_text("beside-match", "docx.json"))
})

test_that("a stale-output row puts each file it names in double quotes", {
  site <- new_site()
  differs <- hash_json(md5_of(stale_lf, "x"))
  report_bytes(site, "comma", stale_lf)
  stored_file(site, "comma", "a, b.json", differs)
  stored_file(site, "comma", "c.json", differs)
  report_bytes(site, "comma-unreadable", stale_lf)
  stored_file(site, "comma-unreadable", "x, y.json", "{")
  rows <- rows_of(check_quiet(site), "stale-output")
  text <- function(name) rows$problem[rows$file == paste0("analyses/", name, ".qmd")]
  expect_identical(text("comma"), stale_text("comma", c("a, b.json", "c.json")))
  expect_identical(text("comma-unreadable"), unreadable_text("comma-unreadable", "x, y.json"))

  # Windows file names cannot hold `"` or `\`.
  skip_on_os("windows")
  report_bytes(site, "quote", stale_lf)
  stored_file(site, "quote", 'd"e.json', differs)
  report_bytes(site, "backslash", stale_lf)
  stored_file(site, "backslash", "f\\g.json", differs)
  report_bytes(site, 'q"r', stale_lf)
  stored_file(site, 'q"r', "html.json", differs)
  rows <- rows_of(check_quiet(site), "stale-output")
  expect_identical(text("quote"), stale_text(paths = '"_freeze/analyses/quote/execute-results/d\\"e.json"'))
  expect_identical(text("backslash"),
                   stale_text(paths = '"_freeze/analyses/backslash/execute-results/f\\\\g.json"'))
  expect_identical(text('q"r'), stale_text(paths = '"_freeze/analyses/q\\"r/execute-results/html.json"'))
})

# The JSON of a stored output file whose markdown holds a line naming each
# hash in `hashes` of _scripts/report.R, after the text in `before`.
script_json <- function(hashes = character(), before = "x") {
  lines <- if (length(hashes) > 0) paste0("Shared report code: _scripts/report.R, MD5 ", hashes)
  markdown <- paste(c(before, lines), collapse = "\n")
  as.character(jsonlite::toJSON(list(hash = "h", result = list(markdown = markdown)), auto_unbox = TRUE))
}

# The MD5 of the site's _scripts/report.R as create_supplement() writes it.
site_script_md5 <- function(site) md5_of(read_bytes(file.path(site, "_scripts", "report.R")))

# The problem text of a stale-script row whose files `files` of report
# `name` differ, with the format hint when `hint` is TRUE.
script_text <- function(name, files, hint = FALSE) {
  stale <- paste0("Its stored output was made with other text of _scripts/report.R than the site holds now: ",
                  quoted_paths(name, files), ".")
  if (!hint) {
    return(paste(stale, rerender_steps))
  }
  paste(stale,
        "Other stored output of the report matches _scripts/report.R, so these files can be from a format",
        "that the report no longer renders. If so, delete them, render the whole site, and commit the report",
        "with _freeze/, docs/, and figures/.",
        "If not, take these steps.", rerender_steps)
}

test_that("stored output made with other report.R text gives a stale-script row", {
  site <- new_site()
  current <- site_script_md5(site)
  other <- md5_of("other text")
  report <- function(name, ...) {
    report_bytes(site, name, stale_lf)
    files <- list(...)
    for (file in names(files)) stored_file(site, name, file, files[[file]])
  }
  report("differs", html.json = script_json(other))
  report("format-differs", html.json = script_json(current), docx.json = script_json(other))
  report("one-file-both", html.json = script_json(c(current, other)))
  report("matches", html.json = script_json(current))
  report("no-line", html.json = script_json())
  report("upper", html.json = script_json(toupper(other)))
  report("short", html.json = script_json(substring(other, 1, 31)))
  report("not-json", html.json = "{")
  report("no-markdown", html.json = '{"hash": "h", "result": {}}')
  report("no-stored", NULL)
  report("hidden", .html.json = script_json(other))
  file.symlink(file.path(site, "no-such.qmd"), file.path(site, "analyses", "dangling.qmd"))
  stored_file(site, "dangling", "html.json", script_json(other))

  rows <- rows_of(check_quiet(site), "stale-script")
  expect_setequal(rows$file, paste0("analyses/", c("differs", "format-differs", "one-file-both"), ".qmd"))
  text <- function(name) rows$problem[rows$file == paste0("analyses/", name, ".qmd")]
  expect_identical(text("differs"), script_text("differs", "html.json"))
  expect_identical(text("format-differs"), script_text("format-differs", "docx.json", hint = TRUE))
  expect_identical(text("one-file-both"), script_text("one-file-both", "html.json"))
})

test_that("a report.R with CR LF line ends matches the hash of its LF text", {
  site <- new_site()
  script <- file.path(site, "_scripts", "report.R")
  lf <- read_bytes(script)
  writeBin(charToRaw(gsub("\n", "\r\n", rawToChar(lf), fixed = TRUE)), script)
  report_bytes(site, "lf-hash", stale_lf)
  stored_file(site, "lf-hash", "html.json", script_json(md5_of(lf)))
  report_bytes(site, "other-hash", stale_lf)
  stored_file(site, "other-hash", "html.json", script_json(md5_of("other text")))
  expect_identical(rows_of(check_quiet(site), "stale-script")$file, "analyses/other-hash.qmd")
})

test_that("a stale-script row names its files in byte order, not the locale's order", {
  site <- new_site()
  report_bytes(site, "order", stale_lf)
  for (file in c("a.json", "B.json")) stored_file(site, "order", file, script_json(md5_of("other text")))
  old <- Sys.getlocale("LC_COLLATE")
  set <- suppressWarnings(Sys.setlocale("LC_COLLATE", "en_US.UTF-8"))
  withr::defer(Sys.setlocale("LC_COLLATE", old))
  skip_if(!nzchar(set), "the en_US.UTF-8 locale is not available")
  expect_false(identical(sort(c("B.json", "a.json")), c("B.json", "a.json")))
  rows <- rows_of(check_quiet(site), "stale-script")
  expect_identical(rows$problem, script_text("order", c("B.json", "a.json")))
})

test_that("a missing report.R, a folder, or a link to a missing file gives no stale-script row", {
  site <- new_site()
  report_bytes(site, "differs", stale_lf)
  stored_file(site, "differs", "html.json", script_json(md5_of("other text")))
  expect_identical(rows_of(check_quiet(site), "stale-script")$file, "analyses/differs.qmd")
  script <- file.path(site, "_scripts", "report.R")
  unlink(script)
  expect_identical(nrow(rows_of(check_quiet(site), "stale-script")), 0L)
  dir.create(script)
  expect_identical(nrow(rows_of(check_quiet(site), "stale-script")), 0L)
  unlink(script, recursive = TRUE)
  file.symlink(file.path(site, "no-such.R"), script)
  expect_identical(nrow(rows_of(check_quiet(site), "stale-script")), 0L)
})

test_that("a hash line after 5 MB of text on one line gives a stale-script row", {
  site <- new_site()
  long <- strrep("a", 5e6)
  report_bytes(site, "next-line", stale_lf)
  stored_file(site, "next-line", "html.json", script_json(md5_of("other text"), before = long))
  report_bytes(site, "same-line", stale_lf)
  json <- script_json(md5_of("other text"), before = "")
  same_line <- sub('"markdown":"\\n', paste0('"markdown":"', long), json, fixed = TRUE)
  stopifnot("the 5 MB text is on the hash line" = nchar(same_line) > 5e6)
  stored_file(site, "same-line", "html.json", same_line)
  expect_no_warning(rows <- rows_of(check_quiet(site), "stale-script"))
  expect_setequal(rows$file, c("analyses/next-line.qmd", "analyses/same-line.qmd"))
})

test_that("a folder in _freeze/analyses/ that nothing in analyses/ names gives a leftover-output row", {
  site <- new_site()
  expect_identical(nrow(rows_of(check_quiet(site), "leftover-output")), 0L)

  stored <- function(name) stored_file(site, name, "html.json", hash_json(md5_of(stale_lf)))
  stored("deleted")
  # A report of the folder's name, of any kind, a folder of reports, or a
  # report whose name differs only in letter case keeps the folder.
  report_bytes(site, "kept", stale_lf)
  stored("kept")
  writeBin(charToRaw("{}"), file.path(site, "analyses", "notebook.ipynb"))
  stored("notebook")
  dir.create(file.path(site, "analyses", "sub"))
  writeBin(charToRaw(stale_lf), file.path(site, "analyses", "sub", "inner.qmd"))
  stored(file.path("sub", "inner"))
  report_bytes(site, "Cased", stale_lf)
  stored("cased")
  # Hidden folders and files directly in _freeze/analyses/ are not read.
  stored(".hidden")
  writeBin(charToRaw("{}"), file.path(site, "_freeze", "analyses", "loose.json"))

  rows <- rows_of(check_quiet(site), "leftover-output")
  expect_identical(rows$file, "_freeze/analyses/deleted")
  expect_identical(rows$problem, paste(
    "No report in analyses/ has this stored output, as after a report is deleted or renamed.",
    "Delete the folder, render the whole site, then commit _freeze/ and docs/.",
    "If you deleted or renamed the report, also commit its old path and _quarto.yml,",
    "which holds its menu item."
  ))
})

test_that("a name that is not valid UTF-8 matches with ASCII letter case ignored", {
  # "T" or "t", then a Latin-1 e with an acute accent.
  upper <- rawToChar(as.raw(c(0x54, 0xe9)))
  lower <- rawToChar(as.raw(c(0x74, 0xe9)))
  expect_identical(fold_case(upper), lower)

  # macOS and Windows refuse such a name, so this part runs on Linux.
  site <- new_site()
  made <- tryCatch(file.create(file.path(site, "analyses", paste0(upper, ".R"))), error = function(e) FALSE)
  skip_if_not(isTRUE(made), "the file system refuses a name that is not valid UTF-8")
  stored_file(site, lower, "html.json", hash_json(md5_of(stale_lf)))
  stored_file(site, "deleted", "html.json", hash_json(md5_of(stale_lf)))
  expect_no_error(rows <- rows_of(check_quiet(site), "leftover-output"))
  expect_identical(rows$file, "_freeze/analyses/deleted")
})

test_that("a leftover folder whose name is not valid UTF-8 shows its bytes in the row", {
  # macOS on APFS refuses such a name, and Windows stores names as UTF-16,
  # so this runs on Linux.
  skip_on_os(c("mac", "windows"))
  site <- new_site()
  for (name in c(rawToChar(as.raw(c(0x63, 0x61, 0x66, 0xe9))), "deleted")) {
    stored_file(site, name, "html.json", hash_json(md5_of(stale_lf)))
  }
  for (locale in c("C.UTF-8", "C")) {
    withr::with_locale(c(LC_CTYPE = locale), {
      expect_identical(Sys.getlocale("LC_CTYPE"), locale)
      expect_no_error(rows <- rows_of(check_quiet(site), "leftover-output"))
    })
    expect_identical(sort(rows$file), c("_freeze/analyses/caf<e9>", "_freeze/analyses/deleted"), info = locale)
  }
})

test_that("a report name that is not valid UTF-8 gives a report-name row and no other row", {
  # macOS on APFS refuses such a name, and Windows stores names as UTF-16,
  # so this runs on Linux.
  skip_on_os(c("mac", "windows"))
  site <- new_site()
  bad <- c(rawToChar(as.raw(c(0x63, 0x61, 0x66, 0xe9))), rawToChar(as.raw(c(0xff, 0x78, 0xc3))))
  for (name in c(bad, "café")) {
    writeBin(charToRaw(stale_lf), file.path(site, "analyses", paste0(name, ".qmd")))
    stored_file(site, name, "html.json", hash_json(md5_of("other text")))
  }
  writeLines('{"R": {"Version": "4.6.1"}, "Packages": {}}', file.path(site, "renv.lock"))
  expect_no_error(expect_no_warning(result <- suppressMessages(check_supplement(site, renv_lock = TRUE))))
  for (file in c("analyses/caf<e9>.qmd", "analyses/<ff>x<c3>.qmd")) {
    expect_identical(result$check[result$file == file], "report-name", info = file)
  }
  expect_identical(
    unique(result$problem[result$check == "report-name"]),
    paste("The name of the report is not valid UTF-8 text. On Linux, Quarto 1.10.19 rendered a site",
          "with such a report with no error and left the report out of the site. Rename the report",
          "with a name in UTF-8 text, change its item in _quarto.yml, delete its folder in",
          "_freeze/analyses/ if there is one, and render the whole site. Then commit the old and new",
          "paths with _quarto.yml, _freeze/, docs/, and figures/.")
  )
  good <- result$check[result$file == "analyses/café.qmd"]
  expect_true("stale-output" %in% good)
  expect_false("report-name" %in% good)
  # In the C locale, list.files(pattern =) lists such a name. cli warns
  # there on the UTF-8 name of café.qmd's row, so that report goes first.
  unlink(file.path(site, c("analyses/café.qmd", "_freeze/analyses/café")), recursive = TRUE)
  withr::with_locale(c(LC_CTYPE = "C"), {
    expect_no_error(result <- suppressMessages(check_supplement(site, renv_lock = TRUE)))
  })
  for (file in c("analyses/caf<e9>.qmd", "analyses/<ff>x<c3>.qmd")) {
    expect_identical(result$check[result$file == file], "report-name", info = file)
  }
})

missing_script_text <- function(paths) {
  paste0("The site has no file _scripts/report.R, which these reports name, so a render of them can fail: ",
         paths, ". Copy the template's file from ",
         'system.file("template", "_scripts", "report.R", package = "supplement")',
         " to _scripts/report.R, or restore your own copy, then commit _scripts/report.R.",
         " If a file named _scripts or a folder named _scripts/report.R is in the way, move it first,",
         " and make the _scripts folder if it is missing.")
}

script_of <- function(site) file.path(site, "_scripts", "report.R")

source_line <- 'source(file.path(site, "_scripts", "report.R"), local = TRUE)'

test_that("reports that name a missing _scripts/report.R give one missing-script row", {
  site <- new_site()
  unlink(script_of(site))
  expect_identical(rows_of(check_quiet(site), "missing-script")$file, "_scripts/report.R")

  site <- new_site()
  unlink(script_of(site))
  dir.create(script_of(site))
  expect_identical(rows_of(check_quiet(site), "missing-script")$file, "_scripts/report.R")

  # `report.R` at the end of a line counts.
  site <- new_site()
  unlink(script_of(site))
  unlink(file.path(site, "analyses", "example.qmd"))
  report_lines(site, "last", c("Text.", "# _scripts/report.R"))
  expect_identical(rows_of(check_quiet(site), "missing-script")$file, "_scripts/report.R")

  # A `report.R` before `_scripts` does not hide a later one.
  unlink(file.path(site, "analyses", "last.qmd"))
  report_lines(site, "both", "report.R, then _scripts/report.R")
  expect_identical(rows_of(check_quiet(site), "missing-script")$file, "_scripts/report.R")
})

# A site with no _scripts/report.R and no report yet.
script_site <- function(env = parent.frame()) {
  site <- new_site(env)
  unlink(script_of(site))
  unlink(file.path(site, "analyses", "example.qmd"))
  site
}

# The missing-script rows of `site` once its one report holds `line`.
script_rows_for <- function(site, line) {
  report_lines(site, "case", line)
  rows_of(check_quiet(site), "missing-script")
}

test_that("lines that join _scripts and report.R by a separator give a missing-script row", {
  site <- script_site()
  lines <- c(
    source_line,
    "source(file.path(site, '_scripts' , 'report.R'))",
    "_scripts\\report.R",
    'source("_scripts\\\\report.R")',
    'file.path(site, "_scripts/", "report.R")',
    "\"_scripts\",\t'report.R'",
    "_scripts_old/x and _scripts/report.R"
  )
  for (line in lines) {
    expect_identical(script_rows_for(site, line)$file, "_scripts/report.R", info = line)
  }
})

test_that("lines that do not join _scripts and report.R by a separator give no missing-script row", {
  site <- script_site()
  lines <- c(
    'source("_scripts_old/report.R")',
    'source("_scripts/old-report.R")',
    'file.path("_scripts", "x", "report.R")',
    'source("_scripts/report.R.bak")',
    "See _scripts/report.R."
  )
  for (line in lines) {
    expect_identical(nrow(script_rows_for(site, line)), 0L, info = line)
  }
})

test_that("a long line that names a missing _scripts/report.R gives a missing-script row", {
  site <- script_site()
  for (line in c(paste(source_line, strrep("x", 5e6)), paste(strrep("x", 5e6), source_line))) {
    expect_no_warning(rows <- script_rows_for(site, line))
    expect_identical(rows$file, "_scripts/report.R")
  }

  expect_no_warning(rows <- script_rows_for(site, paste0('"_scripts" ,', strrep(" \t", 2.5e6))))
  expect_identical(nrow(rows), 0L)
})

test_that("a link to a missing _scripts/report.R gives a missing-script row", {
  site <- new_site()
  unlink(script_of(site))
  symlink_or_skip(file.path(site, "no-such.R"), script_of(site))
  expect_identical(rows_of(check_quiet(site), "missing-script")$file, "_scripts/report.R")
})

test_that("a link to an existing _scripts/report.R gives no missing-script row", {
  site <- new_site()
  file.rename(script_of(site), file.path(site, "real.R"))
  symlink_or_skip(file.path(site, "real.R"), script_of(site))
  expect_identical(nrow(rows_of(check_quiet(site), "missing-script")), 0L)
})

test_that("a link to a link to an existing _scripts/report.R gives no missing-script row", {
  site <- new_site()
  file.rename(script_of(site), file.path(site, "real.R"))
  symlink_or_skip(file.path(site, "real.R"), file.path(site, "mid.R"))
  symlink_or_skip(file.path(site, "mid.R"), script_of(site))
  expect_identical(nrow(rows_of(check_quiet(site), "missing-script")), 0L)
})

test_that("a loop of links or a link that fs cannot resolve gives a missing-script row", {
  site <- new_site()
  unlink(script_of(site))
  symlink_or_skip(file.path(site, "loop.R"), script_of(site))
  symlink_or_skip(script_of(site), file.path(site, "loop.R"))
  expect_identical(rows_of(check_quiet(site), "missing-script")$file, "_scripts/report.R")

  site <- new_site()
  file.rename(script_of(site), file.path(site, "real.R"))
  symlink_or_skip(file.path(site, "real.R"), script_of(site))
  local_mocked_bindings(fs_path_real = function(path) stop("planted failure"))
  expect_identical(rows_of(check_quiet(site), "missing-script")$file, "_scripts/report.R")
})

test_that("a link path that is not valid UTF-8 counts as there", {
  # "a", then a Latin-1 e with an acute accent.
  expect_true(link_ends_on_file(rawToChar(as.raw(c(0x61, 0xe9)))))
})

test_that("the missing-script row names its reports in byte order", {
  site <- new_site()
  unlink(script_of(site))
  report_lines(site, "B", source_line)
  report_lines(site, "a", source_line)
  expect_identical(rows_of(check_quiet(site), "missing-script")$problem,
                   missing_script_text('"analyses/B.qmd", "analyses/a.qmd", "analyses/example.qmd"'))

  # Windows file names cannot hold `"`.
  skip_on_os("windows")
  report_lines(site, 'q"r', source_line)
  expect_identical(rows_of(check_quiet(site), "missing-script")$problem, missing_script_text(paste(
    '"analyses/B.qmd", "analyses/a.qmd", "analyses/example.qmd",', '"analyses/q\\"r.qmd"'
  )))
})

test_that("no missing-script row when the file is there or no report names it", {
  expect_identical(nrow(rows_of(check_quiet(new_site()), "missing-script")), 0L)

  site <- new_site()
  unlink(script_of(site))
  unlink(file.path(site, "analyses", "example.qmd"))
  report_lines(site, "plain", 'source("report.R")')
  report_lines(site, "rmd", "See _scripts/report.Rmd.")
  report_lines(site, "my-scripts", 'source("my_scripts/report.R")')
  report_lines(site, "myreport", 'source(file.path(site, "_scripts", "myreport.R"))')
  report_lines(site, "order", "report.R comes before _scripts here.")
  dir.create(file.path(site, "analyses", "sub"))
  writeLines(source_line, file.path(site, "analyses", "sub", "inner.qmd"))
  expect_identical(nrow(rows_of(check_quiet(site), "missing-script")), 0L)
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

test_that("comments end at <!-->, <!--->, --!>, and -->, and nowhere else", {
  site <- new_site()
  write_page(site, "comments.html", c(
    '<!--> <a href="after-1.csv">x</a>',
    '<!---> <a href="after-2.csv">x</a>',
    '<!-- x --!> <a href="after-3.csv">x</a>',
    '<!----!> <a href="after-4.csv">x</a>',
    '<!--!> <a href="in-1.csv">x</a> --> <a href="after-5.csv">x</a>',
    '<!---!> <a href="in-2.csv">x</a> -->',
    '<!-- -!> <a href="in-3.csv">x</a> -->',
    '<!-- - -> <a href="in-4.csv">x</a> -->'
  ))
  expect_setequal(broken_pairs(site), paste0("docs/comments.html `after-", 1:5, ".csv`"))
})

test_that("</ and a non-letter is a bogus comment, and an end tag is read to its >", {
  site <- new_site()
  write_page(site, "end-tags.html", c(
    '</ foo <a href="x.csv"> <a href="after-1.csv">x</a>',
    "</p title=\"<a href='y.csv'>\"> <a href=\"after-2.csv\">x</a>",
    '</> <a href="after-3.csv">x</a>',
    # Inside a script or a comment, </ is plain text.
    '<script>if (a </ b) {}</script><a href="after-4.csv">x</a>',
    '<!-- </ --> <a href="after-5.csv">x</a>'
  ))
  expect_setequal(broken_pairs(site), paste0("docs/end-tags.html `after-", 1:5, ".csv`"))
})

test_that("a script that holds <!-- and <script> runs past its first </script>", {
  site <- new_site()
  inner <- c("<script>", "<SCRIPT/>", "<script\t>")
  for (i in seq_along(inner)) {
    write_page(site, sprintf("double-%d.html", i), sprintf(
      '<script><!--%s</script><a href="in.csv">x</a></script><a href="after.csv">x</a>', inner[i]
    ))
  }
  # Each of these scripts ends at its first </script>.
  ends <- c("<!-- -->", "<!--", "<!--<script>-->", "<!--<scripts>", "<!--><script>")
  for (i in seq_along(ends)) {
    write_page(site, sprintf("single-%d.html", i), sprintf(
      '<script>%s</script><a href="after.csv">x</a><a href="more.csv">x</a></script>', ends[i]
    ))
  }
  expect_setequal(broken_pairs(site), c(
    sprintf("docs/double-%d.html `after.csv`", seq_along(inner)),
    sprintf("docs/single-%d.html `after.csv`", seq_along(ends)),
    sprintf("docs/single-%d.html `more.csv`", seq_along(ends))
  ))
})

test_that("->, <s, and <! that start nothing stay script text", {
  site <- new_site()
  write_page(site, "arrow.html",
             '<script><!--<script>-></script><a href="in-1.csv">x</a></script><a href="after-1.csv">x</a>')
  write_page(site, "s.html",
             '<script><!--<sx<script></script><a href="in-2.csv">x</a></script><a href="after-2.csv">x</a>')
  write_page(site, "bang.html", '<script><!x<script></script><a href="after-3.csv">x</a></script>')
  expect_setequal(broken_pairs(site), c(
    "docs/arrow.html `after-1.csv`", "docs/s.html `after-2.csv`", "docs/bang.html `after-3.csv`"
  ))
})

test_that("1 MB of escaped script text is read", {
  site <- new_site()
  write_page(site, "big.html", c(
    sprintf("<script>%s</script>", strrep("<!--<script></script>-->", ceiling(2^20 / 24))),
    '<a href="after-big.csv">x</a>'
  ))
  expect_warning(pairs <- broken_pairs(site), NA)
  expect_identical(pairs, "docs/big.html `after-big.csv`")
})

test_that("script text with millions of < or of - after <!-- is read", {
  site <- new_site()
  write_page(site, "lt.html", c(sprintf("<script>%s</script>", strrep("<", 3e6)), '<a href="after-lt.csv">x</a>'))
  write_page(site, "dash.html", c(sprintf("<script><!--%s</script>", strrep("-", 5e6)), '<a href="after-dash.csv">x</a>'))
  expect_warning(pairs <- broken_pairs(site), NA)
  expect_setequal(pairs, c("docs/lt.html `after-lt.csv`", "docs/dash.html `after-dash.csv`"))
})

test_that("comments and element text past one PCRE match are read", {
  skip_on_cran()
  site <- new_site()
  words <- paste0("<b", strrep(" w", 3e6))
  pages <- list(
    script = c("<script>", strrep("<", 7e6), "</script>"),
    style = c("<style>", strrep("<", 7e6), "</style>"),
    textarea = c("<textarea>", strrep("<", 7e6), "</textarea>"),
    title = c("<title>", strrep("<", 7e6), "</title>"),
    comment = c("<!--", strrep("-", 7e6), "-->"),
    end = c("<script>", strrep("</a", 7e6), "</script>"),
    bang = c("<script>", strrep("<!x", 7e6), "</script>"),
    s = c("<script><!--", strrep("<sx", 7e6), "</script>"),
    dash = c("<script><!--", strrep("-x", 7e6), "</script>"),
    words_comment = c("<!--", words, "-->"),
    words_script = c("<script>", words, "</script>"),
    words_style = c("<style>", words, "</style>"),
    words_textarea = c("<textarea>", words, "</textarea>"),
    words_title = c("<title>", words, "</title>")
  )
  for (name in names(pages)) {
    part <- pages[[name]]
    write_page(site, paste0(name, ".html"), paste0(
      part[1], part[2], sprintf('<a href="in-%s.csv">x</a>', name), part[3],
      sprintf('<a href="after-%s.csv">x</a>', name)
    ))
  }
  rows <- rows_of(check_quiet(site), "broken-link")
  expect_setequal(
    paste(rows$file, rows$problem),
    sprintf("docs/%s.html The page links to a file that is not in the site: `after-%s.csv`", names(pages), names(pages))
  )
})

# A random page of 4 to 40 pieces of markup, and at times one more that the
# page ends inside, as a list of its `text` and the `forms` it holds:
# "double" for double escaped script text, "cend:" and the form written to
# close a comment, which need not close it, "straddle:" and an element
# whose text holds markup that runs past its end tag, and "end:" and what
# the page ends inside.
random_page <- function() {
  case <- function(word) {
    chars <- strsplit(word, "", fixed = TRUE)[[1]]
    up <- runif(length(chars)) < 0.3
    chars[up] <- toupper(chars[up])
    paste(chars, collapse = "")
  }
  pick <- function(x) x[[sample.int(length(x), 1)]]
  delims <- c("\t", "\n", "\f", "\r", " ", "/", ">")
  names <- c("script", "style", "textarea", "title", "base", "a")
  atoms <- c("<", "</", "<!", "<?", "!", "<!--", "<!-->", "<!--->", "-->", "--!>", names, delims,
             "href", "src", "xlink:href", "=", '"', "'", "-", "a", "b", "é")
  run <- function(extra = character()) {
    paste(sample(c(atoms, extra), sample.int(8, 1), replace = TRUE), collapse = "")
  }
  attr <- function() {
    quote <- pick(c('"', "'", ""))
    paste0(pick(c(" ", "\n", "/")), case(pick(c("href", "src", "xlink:href", "id"))), pick(c("=", " = ", "")),
           quote, pick(c("x.csv", "é.csv", "a b", "", "#top", "?q", "../z.csv", "<!--", "</style>")), quote)
  }
  start_tag <- function(name) {
    paste0("<", case(name), pick(delims), paste(replicate(sample(0:2, 1), attr()), collapse = ""), ">")
  }
  end_tag <- function(name) paste0("</", case(name), pick(delims), if (runif(1) < 0.2) attr(), ">")
  script_extra <- c("<!--", "-->", "<sx", "-", "--", paste0("<", case("script"), pick(delims)),
                    paste0("</", case("script"), pick(delims)))
  text <- character()
  forms <- character()
  size <- 0
  target <- sample(20:200, 1)
  while (size < target) {
    kind <- sample.int(7, 1)
    piece <- switch(kind,
      run(),
      start_tag(pick(c("a", "base", "img"))),
      end_tag(pick(names)),
      {
        open <- pick(c("<!--", "<!-->", "<!--->"))
        close <- pick(c("-->", "--!>", "--->", "-- >", ""))
        forms <- c(forms, paste0("cend:", if (open == "<!--") close else open))
        paste0(open, run(), close)
      },
      {
        name <- pick(names[1:4])
        paste0(start_tag(name), run(if (name == "script") script_extra), if (runif(1) < 0.8) end_tag(name))
      },
      {
        forms <- c(forms, "double")
        paste0(start_tag("script"), "<!--", run(script_extra), "<", case("script"), pick(delims), run(),
               "</", case("script"), pick(delims), run(), "-->", run(), end_tag("script"))
      },
      {
        name <- pick(names[1:4])
        forms <- c(forms, paste0("straddle:", name))
        paste0(start_tag(name), pick(c("<?x ", "<!x ", "</ ", "<a title='", '<a title="')), "</", case(name), ">",
               ' <a href="s.csv">', pick(c("'", '"', ">", "")))
      }
    )
    text <- c(text, piece)
    size <- size + 5
  }
  if (runif(1) < 0.3) {
    end <- pick(c("comment", "element", "tag"))
    forms <- c(forms, paste0("end:", end))
    text <- c(text, switch(end,
      comment = paste0("<!--", run()),
      element = paste0(start_tag(pick(names[1:4])), run(script_extra)),
      tag = paste0('<a href="x.csv', run())
    ))
  }
  list(text = paste(text, collapse = ""), forms = unique(forms))
}

test_that("tag_links() reads generated pages as the reader before the head walk did", {
  skip_on_cran()
  withr::local_seed(76)
  pages <- replicate(10000, random_page(), simplify = FALSE)
  forms <- table(unlist(lapply(pages, `[[`, "forms")))
  wanted <- c("double", paste0("cend:", c("<!-->", "<!--->", "-->", "--!>")),
              paste0("straddle:", c("script", "style", "textarea", "title")),
              paste0("end:", c("comment", "element", "tag")))
  expect_true(all(forms[wanted] >= 100), info = paste(names(forms), forms, collapse = ", "))
  differ <- Filter(function(page) {
    !identical(tag_links(page$text), old_tag_links(page$text))
  }, pages)
  expect_identical(length(differ), 0L, info = if (length(differ) > 0) differ[[1]]$text)
})

test_that("markup in element text that runs past the end tag does not hide later links", {
  pages <- c(
    '<script><?x</script><a href="x1.csv">',
    '<style><!x </style><a href="x2.csv">',
    "<textarea></ </textarea><a href='x3.csv'>",
    '<title><a title="</title>"><a href="x4.csv">',
    '<script><b"}</script><a href="x5.csv">',
    '<!-- <?x --><a href="x6.csv">'
  )
  for (page in pages) {
    expect_identical(tag_links(page), old_tag_links(page))
  }
  expect_identical(as.character(tag_links(pages[1])), "x1.csv")
  expect_identical(as.character(tag_links(pages[4])), "x4.csv")
})

test_that("tags that the scan of whole tags misses are read to their end", {
  # The `<b x="` quote runs past `</style>` in the scan of whole tags, so
  # the tag after it is matched without that scan, in the first two pages
  # with a value longer than the first window and holding `>`.
  pages <- c(
    paste0('<style><b x="</style><a title="', strrep("y > ", 300), '" href="w1.csv"><a href="w2.csv">'),
    paste0('<style><b x="</style><a title=\'', strrep('z "> ', 600), '\' href=\'w3.csv\'><a href="w4.csv">'),
    paste0('<style><b x="</style><a title=it\'s href="w5.csv">', strrep("text ", 2000), '<a href="w6.csv">')
  )
  for (page in pages) {
    expect_identical(tag_links(page), old_tag_links(page))
  }
  expect_identical(as.character(tag_links(pages[1])), c("w1.csv", "w2.csv"))
})

test_that("pages with many comments, elements, and script state changes are read in time", {
  skip_on_cran()
  # The `<b x="` quote runs past `</style>` in the scan of whole tags, so
  # the link after it is matched alone.
  blocks <- c("<!-- c -->", "<script>s</script>", "<style>s</style>", '<style><b x="</style>')
  n <- seq_len(80000)
  links <- ifelse(n %% 1000 == 0, sprintf("gone-%d.csv", n), "here.csv")
  many <- new_site()
  touch(file.path(many, "docs", "here.csv"))
  page <- write_page(many, "index.html", sprintf('%s<a href="%s">x</a>', rep(blocks, each = 20000), links))
  time <- system.time(rows <- rows_of(check_quiet(many), "broken-link"))[["elapsed"]]
  expect_setequal(rows$problem, sprintf("The page links to a file that is not in the site: `gone-%d.csv`", seq(1000, 80000, 1000)))
  expect_lt(time, 10)
  expect_identical(tag_links(read_page_text(page)), structure(links, base = NULL))
  states <- new_site()
  write_page(states, "index.html", c(sprintf("<script>%s</script>", strrep("<!---->", 200000)), '<a href="gone.csv">x</a>'))
  time <- system.time(pairs <- broken_pairs(states))[["elapsed"]]
  expect_identical(pairs, "docs/index.html `gone.csv`")
  expect_lt(time, 10)
})

test_that("a tag with millions of attributes gives its link row or the PCRE-limit row", {
  skip_on_cran()
  site <- new_site()
  write_page(site, "attrs.html", paste0("<a", strrep(" b", 3e6), ' href="gone-attrs.csv">x</a>'))
  expect_no_error(rows <- rows_of(check_quiet(site), "broken-link"))
  expect_identical(rows$file, "docs/attrs.html")
  expect_true(rows$problem %in% c(
    "The page links to a file that is not in the site: `gone-attrs.csv`",
    "The link check cannot read this page: its markup goes past the limits of the PCRE pattern engine."
  ))
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

test_that("relative links resolve against the folder of a local base", {
  site <- new_site()
  # at-base.csv is only in the folders that the bases name, and
  # only-here.csv only in the pages' own folder.
  touch(file.path(site, "docs", "at-base.csv"))
  touch(file.path(site, "docs", "a", "sub", "at-base.csv"))
  touch(file.path(site, "docs", "a", "only-here.csv"))
  bases <- c("../", "..", "sub/", "sub/.", "sub/page.html", "sub/page.html#f", " sub/page.html?v=1 ")
  pages <- sprintf("a/base-%d.html", seq_along(bases))
  for (i in seq_along(bases)) {
    write_page(site, pages[i], c(
      sprintf('<base href="%s">', bases[i]),
      '<a href="at-base.csv">x</a>',
      '<a href="only-here.csv">x</a>'
    ))
  }
  expect_setequal(broken_pairs(site), paste0("docs/", pages, " `only-here.csv`"))
})

test_that("a link of only a # or ? part resolves to the base address", {
  site <- new_site()
  dir.create(file.path(site, "docs", "a", "sub"), recursive = TRUE)
  write_page(site, "a/folder.html", c('<base href="sub/">', '<a href="#x">x</a>', '<a href="?q">x</a>'))
  write_page(site, "a/file.html", c('<base href="sub/page.html">', '<a href="#x">x</a>', '<a href="?q">x</a>'))
  # With no base, such links are not checked.
  write_page(site, "a/none.html", c('<a href="#x">x</a>', '<a href="?q">x</a>', '<a href="">x</a>'))
  # An empty link is not checked, also under a base.
  write_page(site, "a/empty.html", c('<base href="sub/page.html">', '<a href="">x</a>'))
  expect_setequal(broken_pairs(site), c(
    "docs/a/folder.html `#x`", "docs/a/folder.html `?q`",
    "docs/a/file.html `#x`", "docs/a/file.html `?q`"
  ))
  touch(file.path(site, "docs", "a", "sub", "index.html"))
  touch(file.path(site, "docs", "a", "sub", "page.html"))
  expect_identical(broken_pairs(site), character())
})

test_that("a base href is not a link, and only the first base with an href counts", {
  site <- new_site()
  touch(file.path(site, "docs", "a", "here.csv"))
  touch(file.path(site, "docs", "a", "sub", "there.csv"))
  write_page(site, "a/only-base.html", '<base href="missing/">')
  # Each first base value here leaves the links resolved against the
  # page's own folder, so here.csv is found.
  fallback <- c("", "#top", "?q", "data:text/html,x", "javascript:void(0)", "DATA:x")
  pages <- sprintf("a/fallback-%d.html", seq_along(fallback))
  for (i in seq_along(fallback)) {
    write_page(site, pages[i], c(
      sprintf('<base href="%s">', fallback[i]),
      '<a href="here.csv">x</a>',
      '<a href="gone.csv">x</a>'
    ))
  }
  write_page(site, "a/no-value.html", c("<base href>", '<a href="here.csv">x</a>', '<a href="gone.csv">x</a>'))
  # A later base is not used, whether the first is usable or not.
  write_page(site, "a/empty-then-sub.html", c(
    '<base href=""><base href="sub/">', '<a href="here.csv">x</a>', '<a href="gone.csv">x</a>'
  ))
  write_page(site, "a/sub-then-parent.html", c(
    '<base href="sub/"><base href="../">', '<a href="there.csv">x</a>', '<a href="here.csv">x</a>'
  ))
  # A base with no href does not count, so the later one is used.
  write_page(site, "a/target-then-sub.html", c(
    '<base target="_blank"><BASE HREF="sub/">', '<a href="there.csv">x</a>', '<a href="here.csv">x</a>'
  ))
  # These bases leave the page's relative links unchecked.
  away <- c("https://example.org/", "/site/")
  for (i in seq_along(away)) {
    write_page(site, sprintf("a/away-%d.html", i),
               c(sprintf('<base href="%s">', away[i]), '<a href="gone.csv">x</a>', '<a href="#x">x</a>'))
  }
  expect_setequal(broken_pairs(site), c(
    paste0("docs/", pages, " `gone.csv`"),
    "docs/a/no-value.html `gone.csv`",
    "docs/a/empty-then-sub.html `gone.csv`",
    "docs/a/sub-then-parent.html `here.csv`",
    "docs/a/target-then-sub.html `here.csv`"
  ))
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
  # On Windows, a file link to a missing file reads as a plain file to
  # these rules; is_link() finds it with fs_link().
  dangling <- .Platform$OS.type != "windows"
  expect_identical(
    is_reparse_point(file.path(dir, names)),
    c(FALSE, FALSE, TRUE, TRUE, dangling, FALSE, FALSE, FALSE, !ignores_case, TRUE)
  )
  expect_identical(is_reparse_point(character()), logical())
})

test_that("is_link() finds a link to a file, to a folder, and to a missing file, and no plain path", {
  dir <- withr::local_tempdir()
  outside <- withr::local_tempdir("outside-")
  writeLines("x", file.path(outside, "target.txt"))
  touch(file.path(dir, "file.txt"))
  dir.create(file.path(dir, "folder"))
  symlink_or_skip(file.path(outside, "target.txt"), file.path(dir, "file-link"))
  symlink_or_skip(outside, file.path(dir, "folder-link"))
  symlink_or_skip(file.path(outside, "missing.txt"), file.path(dir, "dangling"))
  names <- c("file.txt", "folder", "not-there", "file-link", "folder-link", "dangling")
  expect_identical(is_link(file.path(dir, names)), c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE))
  expect_identical(is_link(character()), logical())
})

test_that("a path that fs stops on gives the other link rules' answer, not an error", {
  dir <- withr::local_tempdir()
  touch(file.path(dir, "file.txt"))
  # fs stops on "bad" only, so the other path keeps fs's answer.
  local_mocked_bindings(fs_is_link = function(paths) {
    if (any(basename(paths) == "bad")) stop("Failed to stat")
    rep(TRUE, length(paths))
  })
  expect_identical(fs_link(file.path(dir, c("file.txt", "bad"))), c(TRUE, FALSE))

  local_mocked_bindings(fs_is_link = function(paths) stop("Failed to stat"))
  skip_on_os(c("mac", "linux", "solaris"))
  outside <- withr::local_tempdir("outside-")
  symlink_or_skip(outside, file.path(dir, "junction"))
  symlink_or_skip(file.path(outside, "missing.txt"), file.path(dir, "dangling"))
  expect_identical(is_link(file.path(dir, c("file.txt", "junction", "dangling"))), c(FALSE, TRUE, FALSE))
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
  expect_status(result)
  expect_match(rawToChar(result$stdout), "^git version")
  expect_false(file.exists(out))
  expect_identical(readLines(file.path(base, "tmpa", "git-out")), "mine")
})

# Ignored output ----------------------------------------------------------------

# Write a few bytes to each of `files`, paths in `dir`, making folders as
# needed.
put_files <- function(dir, files) {
  for (file in files) {
    full <- file.path(dir, file)
    dir.create(dirname(full), showWarnings = FALSE, recursive = TRUE)
    writeBin(as.raw(c(0x89, 0x50, 0x4e, 0x47)), full)
  }
}

# Add a line to an ignore file, with an LF ending on every system.
add_rule <- function(file, rule) {
  con <- file(file, "ab")
  on.exit(close(con))
  writeBin(charToRaw(paste0(rule, "\n")), con)
}

ignored_rows <- function(site) sort(rows_of(check_quiet(site), "ignored-output")$file)

test_that("a *.png rule gives an ignored-output row for each PNG in the published folders", {
  skip_if_no_git()
  published <- c("figures/a.png", "docs/b.png", "_freeze/c.png", "docs/sub/d.png", "_freeze/sub/e.png")
  # An ignored PNG outside the three folders, and hidden files, give no row.
  # The template ignores analyses/*.png and .DS_Store already.
  others <- c("analyses/f.png", "figures/.DS_Store", "docs/.hidden/g.png", "_freeze/.h.png")
  # The shipped figure is a PNG in figures/ too.
  expected <- sort(c(published, "figures/bootstrap-means.png"))

  site <- git_site()
  put_files(site, c(published, others))
  expect_identical(ignored_rows(site), character())
  add_rule(file.path(site, ".gitignore"), "*.png")
  expect_identical(ignored_rows(site), expected)
  rows <- rows_of(check_quiet(site), "ignored-output")
  expect_match(rows$problem, "change the ignore rule", fixed = TRUE)
  expect_match(rows$problem, "remove its source", fixed = TRUE)

  # The same rule in .git/info/exclude.
  site <- git_site()
  put_files(site, c(published, others))
  dir.create(file.path(site, ".git", "info"), showWarnings = FALSE)
  add_rule(file.path(site, ".git", "info", "exclude"), "*.png")
  expect_identical(ignored_rows(site), expected)

  # A site in a subfolder of its repository gives paths that start at the
  # site.
  base <- withr::local_tempdir("repo-")
  site <- file.path(base, "site")
  suppressMessages(create_supplement(site))
  file.copy(file.path(site, "_gitignore"), file.path(site, ".gitignore"))
  expect_status(git_in(base, c("init", "-q")))
  put_files(site, c(published, others))
  add_rule(file.path(site, ".gitignore"), "*.png")
  expect_identical(ignored_rows(site), expected)
})

test_that("a figures/ rule gives an ignored-output row for each file in figures", {
  skip_if_no_git()
  site <- git_site()
  put_files(site, c("figures/a.png", "figures/sub/b.pdf", "docs/c.png"))
  add_rule(file.path(site, ".gitignore"), "figures/")
  expect_identical(ignored_rows(site), c("figures/a.png", "figures/bootstrap-means.png", "figures/sub/b.pdf"))
})

test_that("a data file that the template ignores gives a row for its copy in docs", {
  skip_if_no_git()
  site <- git_site()
  put_files(site, c("data/x.rds", "docs/data/x.rds"))
  expect_identical(ignored_rows(site), "docs/data/x.rds")
  # A file that git tracks and that an ignore rule matches gives no row.
  expect_status(git_in(site, c("add", "-f", "docs/data/x.rds")))
  expect_identical(ignored_rows(site), character())
})

test_that("a folder link in figures gives no row for the files in its target", {
  skip_if_no_git()
  site <- git_site()
  outside <- withr::local_tempdir("outside-")
  put_files(outside, c("t.png", "sub/u.png"))
  symlink_or_skip(outside, file.path(site, "figures", "linked"))
  expect_status(git_in(site, c("add", "figures/linked")))
  add_rule(file.path(site, ".gitignore"), "*.png")
  expect_identical(ignored_rows(site), "figures/bootstrap-means.png")
  # Nor is the target compared with docs/figures/.
  expect_identical(rows_of(check_quiet(site), "unpublished-figure")$file, "figures/bootstrap-means.png")
})

test_that("an ignored file link in figures gives no ignored-output row", {
  skip_if_no_git()
  site <- git_site()
  outside <- withr::local_tempdir("outside-")
  put_files(outside, "t.png")
  symlink_or_skip(file.path(outside, "t.png"), file.path(site, "figures", "flink.png"))
  add_rule(file.path(site, ".gitignore"), "*.png")
  listed <- git_in(site, c("ls-files", "--others", "--ignored", "--exclude-standard", "--", "figures"))
  expect_true("figures/flink.png" %in% listed$output)
  expect_identical(ignored_rows(site), "figures/bootstrap-means.png")
})

# Unpublished figures -----------------------------------------------------------

unpublished_rows <- function(site) sort(rows_of(check_quiet(site), "unpublished-figure")$file)

# Copy figures/ into docs/, as a render does.
publish_figures <- function(site) {
  dir.create(file.path(site, "docs"), showWarnings = FALSE)
  file.copy(file.path(site, "figures"), file.path(site, "docs"), recursive = TRUE)
}

test_that("a figure with no equal copy in docs/figures gives an unpublished-figure row", {
  site <- new_site()
  # A new site has no docs/ folder yet.
  expect_identical(unpublished_rows(site), "figures/bootstrap-means.png")
  publish_figures(site)
  expect_identical(unpublished_rows(site), character())

  # Figures saved after the copy, with hidden files that give no row.
  put_files(site, c("figures/new.png", "figures/sub/x.png", "figures/.hidden.png", "figures/.dir/y.png"))
  # New bytes under a published name.
  shipped <- file.path(site, "figures", "bootstrap-means.png")
  writeBin(c(readBin(shipped, "raw", file.size(shipped)), as.raw(0)), shipped)
  # A folder in docs/figures/ where the figure should be.
  put_files(site, "figures/z.png")
  dir.create(file.path(site, "docs", "figures", "z.png"))
  rows <- rows_of(check_quiet(site), "unpublished-figure")
  expect_identical(sort(rows$file), c("figures/bootstrap-means.png", "figures/new.png", "figures/sub/x.png",
                                      "figures/z.png"))
  expect_identical(unique(rows$problem), paste("The copy in docs/figures/ is missing or differs.",
                                               "Render the whole site, then commit figures/, docs/, and _freeze/."))
})

test_that("a site with no figures folder, or a file named figures, gives no unpublished-figure row", {
  site <- new_site()
  dir.create(file.path(site, "docs"))
  unlink(file.path(site, "figures"), recursive = TRUE)
  expect_no_error(rows <- unpublished_rows(site))
  expect_identical(rows, character())
  writeBin(charToRaw("not a folder"), file.path(site, "figures"))
  expect_no_error(rows <- unpublished_rows(site))
  expect_identical(rows, character())
})

test_that("a link in docs/figures with the figure's bytes gives an unpublished-figure row", {
  site <- new_site()
  publish_figures(site)
  put_files(site, "figures/x.png")
  outside <- withr::local_tempdir("outside-")
  file.copy(file.path(site, "figures", "x.png"), outside)
  symlink_or_skip(file.path(outside, "x.png"), file.path(site, "docs", "figures", "x.png"))
  expect_identical(unpublished_rows(site), "figures/x.png")
})

test_that("rows of the new checks come in byte order, not the locale's order", {
  site <- new_site()
  put_files(site, c("figures/a.png", "figures/B.png"))
  old <- Sys.getlocale("LC_COLLATE")
  set <- suppressWarnings(Sys.setlocale("LC_COLLATE", "en_US.UTF-8"))
  withr::defer(Sys.setlocale("LC_COLLATE", old))
  skip_if(!nzchar(set), "the en_US.UTF-8 locale is not available")
  byte_order <- c("figures/B.png", "figures/a.png", "figures/bootstrap-means.png")
  # The locale's order differs, so the test can tell the two apart.
  expect_false(identical(sort(byte_order), byte_order))
  expect_identical(rows_of(check_quiet(site), "unpublished-figure")$file, byte_order)
})

# The second git listing, of ignored files, mocked to give names that a
# disk cannot hold everywhere.
mock_ignored <- function(names, status = 0L, env = parent.frame()) {
  local_mocked_bindings(git_run = function(args, dir) {
    out <- switch(args[1],
      "--version" = charToRaw("git version 2"),
      "rev-parse" = charToRaw("true\n"),
      "ls-files" = if ("--ignored" %in% args) unlist(lapply(names, function(n) c(n, as.raw(0)))) else raw()
    )
    list(status = if ("--ignored" %in% args) status else 0L, stdout = out)
  }, .env = env)
}

test_that("an ignored name that is not valid UTF-8 gives a row and no warning", {
  # Windows file names are UTF-16, so git lists no such name there, and
  # is_reparse_point() stops on one in drop_trailing_sep().
  skip_on_os("windows")
  site <- new_site()
  mock_ignored(list(c(charToRaw("docs/b"), as.raw(0xe9), charToRaw(".png")), charToRaw("docs/ok.png")))
  expect_no_warning(rows <- ignored_rows(site))
  expect_identical(rows, c("docs/b<e9>.png", "docs/ok.png"))
})

test_that("an ignored file under a linked folder gives no row", {
  site <- new_site()
  outside <- withr::local_tempdir("outside-")
  put_files(outside, "t.png")
  symlink_or_skip(outside, file.path(site, "figures", "linked"))
  # Such a path comes from a git that enters a junction on Windows.
  mock_ignored(list(charToRaw("figures/linked/t.png"), charToRaw("docs/ok.png")))
  expect_identical(ignored_rows(site), "docs/ok.png")
})

test_that("a failed listing of ignored files skips the three git checks", {
  site <- new_site()
  mock_ignored(list(), status = 128L)
  msgs <- testthat::capture_messages(result <- check_supplement(site))
  expect_identical(attr(result, "skipped"), c("large-file", "saved-object", "ignored-output"))
  expect_false(any(result$check %in% c("large-file", "saved-object", "ignored-output")))
  expect_match(gsub("\\s+", " ", paste(msgs, collapse = " ")), "`git ls-files` failed", fixed = TRUE)
})

# Template placeholders ---------------------------------------------------------

placeholder_rows <- function(site) rows_of(check_quiet(site), "placeholder")

# The fields that the _supplement.yml placeholder row names, in its order.
placeholder_fields <- function(site) {
  rows <- placeholder_rows(site)
  rows <- rows[rows$file == "_supplement.yml", , drop = FALSE]
  if (nrow(rows) == 0) {
    return(character())
  }
  expect_identical(nrow(rows), 1L)
  listed <- sub("^Template values left in place: ([^.]*)\\..*$", "\\1", rows$problem)
  strsplit(listed, ", ", fixed = TRUE)[[1]]
}

# Put `lines` in place of the `authors:` list of a site's _supplement.yml.
set_authors <- function(site, lines) {
  yml <- file.path(site, "_supplement.yml")
  old <- readLines(yml, encoding = "UTF-8")
  from <- which(old == "  authors:")
  to <- grep("^  # With Zenodo", old)
  stopifnot(length(from) == 1, length(to) == 1)
  new <- c(old[seq_len(from - 1)], lines, old[to:length(old)])
  writeBin(charToRaw(enc2utf8(paste0(paste(new, collapse = "\n"), "\n"))), yml)
}

set_meta_line <- function(site, key, line) {
  yml <- file.path(site, "_supplement.yml")
  lines <- readLines(yml, encoding = "UTF-8")
  i <- grep(paste0("^  ", key, ":"), lines)
  stopifnot(length(i) == 1)
  lines[i] <- line
  writeBin(charToRaw(enc2utf8(paste0(paste(lines, collapse = "\n"), "\n"))), yml)
}

real_author <- c('    - family: "Doe"', '      given: "Jane"')

change_meta <- list(
  "paper-title" = function(site) set_meta_line(site, "paper-title", '  paper-title: "Effects of sleep"'),
  citation = function(site) set_meta_line(site, "citation", '  citation: "Doe, J. (2026). Effects of sleep. *Sleep*."'),
  contact = function(site) set_meta_line(site, "contact", '  contact: "Jane Doe, University A."'),
  authors = function(site) set_authors(site, c("  authors:", real_author))
)

test_that("template values in _supplement.yml give one placeholder row that names them", {
  site <- new_site()
  expect_identical(placeholder_fields(site), names(change_meta))

  for (kept in names(change_meta)) {
    site <- new_site()
    for (field in setdiff(names(change_meta), kept)) change_meta[[field]](site)
    expect_identical(placeholder_fields(site), kept, info = kept)
  }

  site <- new_site()
  for (field in names(change_meta)) change_meta[[field]](site)
  expect_identical(placeholder_fields(site), character())
})

test_that("an author counts only when both family and given are a template author's", {
  others <- function(env = parent.frame()) {
    site <- new_site(env)
    for (field in c("paper-title", "citation", "contact")) change_meta[[field]](site)
    site
  }
  site <- others()
  set_authors(site, c("  authors:", real_author, '    - family: "Author"', '      given: "B. B."'))
  expect_identical(placeholder_fields(site), "authors")

  for (author in list(c("Author", "Jane"), c("Smith", "A. A."))) {
    site <- others()
    set_authors(site, c("  authors:", sprintf('    - family: "%s"', author[1]), sprintf('      given: "%s"', author[2])))
    expect_identical(placeholder_fields(site), character(), info = author)
  }
})

test_that("a template value with other white space still counts", {
  site <- new_site()
  set_meta_line(site, "paper-title", '  paper-title: "  Title   of the\\tpaper "')
  expect_contains(placeholder_fields(site), "paper-title")
})

test_that("a value that is not text gives no placeholder row for it and no error", {
  site <- new_site()
  set_meta_line(site, "paper-title", "  paper-title: 2024")
  set_authors(site, c("  authors:", '    - "Author, A. A."'))
  expect_no_error(fields <- placeholder_fields(site))
  expect_identical(fields, c("citation", "contact"))

  site <- new_site()
  set_authors(site, '  authors: "Author, A. A."')
  expect_no_error(fields <- placeholder_fields(site))
  expect_identical(fields, c("paper-title", "citation", "contact"))
})

test_that("an empty template value never counts", {
  site <- new_site()
  set_meta_line(site, "paper-title", '  paper-title: ""')
  template <- read_supplement(template_dir())
  template[["paper-title"]] <- ""
  local_mocked_bindings(template_supplement = function() template)
  expect_identical(placeholder_fields(site), c("citation", "contact", "authors"))
})

line_files <- c("_quarto.yml", "index.qmd", "LICENSE.md", "LICENSE-CC-BY.md", "README.md", "SUPPLEMENT.md",
                "_README.md")

# The files other than _supplement.yml that give a placeholder row.
placeholder_files <- function(site) {
  rows <- placeholder_rows(site)
  rows$file[rows$file %in% line_files]
}

test_that("a placeholder line gives a row for its file until it is changed", {
  site <- new_site()
  expect_setequal(placeholder_files(site), c("_quarto.yml", "index.qmd", "LICENSE.md", "LICENSE-CC-BY.md",
                                             "_README.md"))
  file.copy(file.path(site, "_README.md"), file.path(site, c("README.md", "SUPPLEMENT.md")))
  expect_setequal(placeholder_files(site), line_files)

  changes <- list(
    "_quarto.yml" = c("OWNER/REPO", "jdoe/sleep"),
    "index.qmd" = c("## Before your first commit", "## About"),
    "LICENSE.md" = c("YEAR AUTHORS", "2026 Jane Doe"),
    "LICENSE-CC-BY.md" = c("YEAR AUTHORS", "2026 Jane Doe"),
    "README.md" = c("OWNER.github.io/REPO/", "jdoe.github.io/sleep/"),
    "SUPPLEMENT.md" = c("OWNER.github.io/REPO/", "jdoe.github.io/sleep/"),
    "_README.md" = c("OWNER.github.io/REPO/", "jdoe.github.io/sleep/")
  )
  left <- line_files
  for (file in names(changes)) {
    replace_in_file(file.path(site, file), changes[[file]][1], changes[[file]][2])
    left <- setdiff(left, file)
    expect_setequal(placeholder_files(site), left)
  }
})

test_that("a placeholder line counts with spaces, tabs, and a CR at its ends", {
  site <- new_site()
  index <- file.path(site, "index.qmd")
  replace_in_file(index, "\n", "\r\n")
  replace_in_file(index, "## Before your first commit", " \t## Before your first commit\t ")
  expect_contains(placeholder_files(site), "index.qmd")
})

test_that("a README that is a folder or not UTF-8 text gives no row and no error", {
  line <- "Website: https://OWNER.github.io/REPO/"
  forms <- list(
    folder = function(file) dir.create(file),
    utf16 = function(file) {
      writeBin(c(as.raw(c(0xff, 0xfe)), iconv(paste0(line, "\n"), "UTF-8", "UTF-16LE", toRaw = TRUE)[[1]]), file)
    },
    latin1 = function(file) writeBin(c(charToRaw("Caf"), as.raw(0xe9), charToRaw(paste0("\n", line, "\n"))), file)
  )
  for (form in names(forms)) {
    site <- new_site()
    forms[[form]](file.path(site, "README.md"))
    expect_no_error(files <- placeholder_files(site))
    expect_false("README.md" %in% files, info = form)
  }
})

test_that("a site made with repo gives no row for the GitHub address", {
  site <- withr::local_tempdir("site-")
  suppressMessages(create_supplement(site, repo = "owner/name"))
  expect_setequal(placeholder_files(site), c("index.qmd", "LICENSE.md", "LICENSE-CC-BY.md"))
})

test_that("each placeholder line is a line of the template's file", {
  for (file in names(placeholder_lines)) {
    source <- if (file %in% c("README.md", "SUPPLEMENT.md")) "_README.md" else file
    lines <- trimws(readLines(file.path(template_dir(), source), encoding = "UTF-8"))
    expect_true(placeholder_lines[[file]] %in% lines, info = file)
  }
  expect_setequal(names(placeholder_lines), line_files)
})

test_that("an example file gives a row while its text is the template's", {
  for (file in c("analyses/example.qmd", "data/example.csv")) {
    has_row <- function(site) file %in% placeholder_rows(site)$file
    site <- new_site()
    expect_true(has_row(site), info = file)

    replace_in_file(file.path(site, file), "\n", "\r\n")
    expect_true(has_row(site), info = file)

    site <- new_site()
    bytes <- readBin(file.path(site, file), "raw", file.size(file.path(site, file)))
    writeBin(c(bytes, charToRaw("\n")), file.path(site, file))
    expect_false(has_row(site), info = file)

    site <- new_site()
    file.remove(file.path(site, file))
    expect_false(has_row(site), info = file)
    dir.create(file.path(site, file))
    expect_no_error(expect_false(has_row(site), info = file))
  }
})

# data-raw/example-qmd-fixtures.R writes each fixture from git.
example_fixture <- function(commit) test_path("fixtures", "example-qmd", paste0(commit, ".qmd"))

# Write `bytes` as the site's file and say whether it gets its row.
example_row_for <- function(site, file, bytes) {
  writeBin(bytes, file.path(site, file))
  file %in% placeholder_rows(site)$file
}

test_that("each version of the example report on the default branch gives its row", {
  commits <- c("2db94f2", "fbc2cab", "38af327", "11fa634", "0c312a3", "485be8b", "9ba7e23", "5563744")
  site <- new_site()
  for (commit in commits) {
    bytes <- read_bytes(example_fixture(commit))
    expect_true(example_row_for(site, "analyses/example.qmd", bytes), info = commit)
  }
})

test_that("an example file saved with a BOM, CR line ends, or no final line break gives its row", {
  file <- "analyses/example.qmd"
  site <- new_site()
  lf <- read_bytes(file.path(site, file))
  bom <- as.raw(c(0xef, 0xbb, 0xbf))
  first <- which(lf == as.raw(10))[1]
  expect_true(example_row_for(site, file, c(bom, lf)))
  expect_true(example_row_for(site, file, replace(lf, lf == as.raw(10), as.raw(13))))
  expect_true(example_row_for(site, file, append(lf, as.raw(13), first - 1)))
  expect_true(example_row_for(site, file, lf[-length(lf)]))

  old <- read_bytes(example_fixture("fbc2cab"))
  old <- old[-length(old)]
  crlf <- unlist(lapply(old, function(b) if (b == as.raw(10)) as.raw(c(13, 10)) else b))
  expect_true(example_row_for(site, file, c(bom, crlf)))

  data <- "data/example.csv"
  expect_true(example_row_for(site, data, c(bom, read_bytes(file.path(site, data)))))
})

test_that("an example file with other changed text gives no row", {
  file <- "analyses/example.qmd"
  site <- new_site()
  lf <- read_bytes(file.path(site, file))
  first <- which(lf == as.raw(10))[1]
  expect_false(example_row_for(site, file, append(lf, as.raw(c(0xef, 0xbb, 0xbf)), first)))
  expect_false(example_row_for(site, file, append(lf, charToRaw(" "), first - 1)))

  old <- rawToChar(read_bytes(example_fixture("fbc2cab")))
  expect_false(example_row_for(site, file, charToRaw(sub("a", "b", old, fixed = TRUE))))

  data <- "data/example.csv"
  csv <- rawToChar(read_bytes(file.path(site, data)))
  expect_false(example_row_for(site, data, charToRaw(sub("[0-9]", "9", csv))))
})

test_that("the installed template's example files are among the known versions", {
  template <- system.file("template", package = "supplement", mustWork = TRUE)
  for (file in names(placeholder_example_problems)) {
    expect_contains(example_versions[[file]], text_hash(file.path(template, file)))
  }
})

test_that("the example report's row names its stored output", {
  rows <- placeholder_rows(new_site())
  expect_identical(rows$problem[rows$file == "analyses/example.qmd"], paste(
    "This is the template's example report. Write your own report in it, or delete it and its stored output",
    "in _freeze/analyses/example/, and make the Analyses menu in _quarto.yml list your own reports."
  ))
})

# Web links -------------------------------------------------------------------

# A site whose pages hold web addresses of each kind that the check reads
# or leaves out. The page locked.html cannot be read and bad.html makes
# tag_links() warn, so the addresses only on them are not requested.
web_site <- function(env = parent.frame()) {
  site <- new_site(env)
  write_page(site, "index.html", c(
    '<a href="https://example.org/a">a</a>',
    '<a href="https://example.org/a#part">a with a fragment</a>',
    '<img src="http://example.org/b.png">',
    '<a href="https://example.org/q?x=1&amp;y=2">query</a>',
    '<a href="HTTPS://example.org/C">upper-case scheme</a>',
    '<a href=" https://example.org/d\n">spaces</a>',
    '<a href="data/x.csv">relative</a>',
    '<a href="mailto:a@example.org">mail</a>',
    '<a href="ftp://example.org/f">ftp</a>'
  ))
  write_page(site, "analyses/report.html", c(
    '<a href="https://example.org/a">a again</a>',
    '<a href="https://example.org/e">e</a>'
  ))
  write_page(site, "locked.html", '<a href="https://example.org/locked">x</a>')
  write_page(site, "bad.html", '<a href="https://example.org/bad">x</a>')
  real_read <- read_page_text
  real_tags <- tag_links
  local_mocked_bindings(
    read_page_text = function(file) if (basename(file) == "locked.html") NULL else real_read(file),
    tag_links = function(html) {
      if (grepl("example.org/bad", html, fixed = TRUE)) warning("PCRE error 'match limit exceeded'")
      real_tags(html)
    },
    .env = env
  )
  site
}

web_expected <- c(
  "https://example.org/a" = "analyses/report.html",
  "https://example.org/e" = "analyses/report.html",
  "http://example.org/b.png" = "index.html",
  "https://example.org/q?x=1&y=2" = "index.html",
  "HTTPS://example.org/C" = "index.html",
  "https://example.org/d" = "index.html"
)

test_that("web addresses are read once each, with the first page in byte order", {
  site <- web_site()
  found <- web_addresses(site)
  expect_false(anyDuplicated(found$address) > 0)
  expect_setequal(found$address, names(web_expected))
  expect_identical(stats::setNames(found$page, found$address)[names(web_expected)], web_expected)
})

test_that("a site with no docs folder has no web addresses", {
  expect_identical(nrow(web_addresses(new_site())), 0L)
})

check_quiet_web <- function(path, web_links) suppressMessages(check_supplement(path, web_links = web_links))

# Mock url_status() to record each address it gets and return
# `result(address)`.
mock_status <- function(result = function(url) 200L, env = parent.frame()) {
  calls <- new.env()
  calls$urls <- character()
  local_mocked_bindings(url_status = function(url) {
    calls$urls <- c(calls$urls, url)
    result(url)
  }, .env = env)
  calls
}

# A site whose index.html links each name of `results`, and the web-link
# rows when url_status() gives each address its value in `results`.
web_rows_for <- function(results, env = parent.frame()) {
  site <- new_site(env)
  write_page(site, "index.html", sprintf('<a href="%s">x</a>', names(results)))
  mock_status(function(url) results[[url]], env = env)
  suppressMessages(check_web_links(site))
}

test_that("each address that fails gives one web-link row on its first page", {
  results <- list(
    "https://example.org/500" = 500L, "https://example.org/200" = 200L, "https://example.org/301" = 301L,
    "https://example.org/399" = 399L, "https://example.org/404" = 404L, "https://example.org/400" = 400L,
    "https://example.org/error" = "libcurl error code 6: Could not resolve host: example.invalid"
  )
  site <- new_site()
  write_page(site, "index.html", sprintf('<a href="%s">x</a>', names(results)))
  write_page(site, "analyses/report.html", '<a href="https://example.org/404">x</a>')
  mock_status(function(url) results[[url]])
  rows <- suppressMessages(check_web_links(site))
  failing <- c("https://example.org/400", "https://example.org/404", "https://example.org/500",
               "https://example.org/error")
  expect_identical(rows$check, rep("web-link", 4))
  expect_identical(rows$file, c("docs/index.html", "docs/analyses/report.html", "docs/index.html",
                                "docs/index.html"))
  for (i in seq_along(failing)) expect_match(rows$problem[i], paste0("`", failing[i], "`"), fixed = TRUE)
  for (i in 1:3) expect_match(rows$problem[i], paste("status", c(400, 404, 500)[i]), fixed = TRUE)
  expect_match(rows$problem[4], "could not be requested: libcurl error code 6: Could not resolve host", fixed = TRUE)
})

test_that("a row for a status that servers give scripts says the link can work in a browser", {
  refused <- "The server refused the check's request, so the link can still work in a browser."
  results <- list(
    "https://example.org/401" = 401L, "https://example.org/403" = 403L, "https://example.org/405" = 405L,
    "https://example.org/429" = 429L, "https://example.org/404" = 404L,
    "https://example.org/error" = "Operation timed out"
  )
  rows <- web_rows_for(results)
  says <- grepl(refused, rows$problem, fixed = TRUE)
  names(says) <- regmatches(rows$problem, regexpr("https://example.org/[a-z0-9]+", rows$problem))
  expect_identical(says[names(results)], c(
    "https://example.org/401" = TRUE, "https://example.org/403" = TRUE, "https://example.org/405" = TRUE,
    "https://example.org/429" = TRUE, "https://example.org/404" = FALSE, "https://example.org/error" = FALSE
  ))
})

test_that("a status of 0 or none gives the no-status row", {
  for (result in list(0L, NA_integer_, NULL)) {
    expect_match(web_problem("https://example.org/x", result), "had no HTTP status", fixed = TRUE)
  }
})

test_that("web_links must be TRUE or FALSE", {
  site <- new_site()
  for (bad in list(NA, c(TRUE, TRUE), "TRUE", 1, NULL)) {
    expect_error(check_quiet_web(site, bad), class = "supplement_error_argument")
  }
})

test_that("by default check_supplement() requests no web address", {
  site <- web_site()
  local_mocked_bindings(url_status = function(url) stop("url_status() was called"))
  expect_identical(nrow(rows_of(check_quiet(site), "web-link")), 0L)
})

test_that("web_links = TRUE requests each web address on the pages once", {
  site <- web_site()
  calls <- mock_status()
  check_quiet_web(site, TRUE)
  expect_setequal(calls$urls, names(web_expected))
  expect_false(anyDuplicated(calls$urls) > 0)
})

test_that("web_links = TRUE does not request the address of a base", {
  site <- new_site()
  write_page(site, "index.html", c('<base href="https://example.org/base/">', '<a href="https://example.org/a">a</a>'))
  calls <- mock_status()
  check_quiet_web(site, TRUE)
  expect_identical(calls$urls, "https://example.org/a")
})

test_that("url_status() follows redirects with a timeout and gives the status or the error message", {
  got <- NULL
  local_mocked_bindings(curlGetHeaders = function(url, ...) {
    got <<- list(url = url, ...)
    structure("HTTP/2 404", status = 404L)
  })
  expect_identical(url_status("https://example.org/x"), 404L)
  expect_identical(got$url, "https://example.org/x")
  expect_true(got$redirect)
  expect_true(is.numeric(got$timeout) && length(got$timeout) == 1 && got$timeout > 0)
  first <- got$timeout
  url_status("https://example.org/a b")
  expect_identical(got$url, "https://example.org/a%20b")
  expect_identical(got$timeout, first)

  local_mocked_bindings(curlGetHeaders = function(url, ...) stop("libcurl error code 6:\n\tno host\n"))
  expect_identical(url_status("https://example.org/x"), "libcurl error code 6: no host")
})

# renv.lock -------------------------------------------------------------------

# A RENV_PROFILE of the session that runs the tests picks another lockfile.
withr::local_envvar(RENV_PROFILE = NA)

check_lock <- function(path) suppressMessages(check_supplement(path, renv_lock = TRUE))

lock_path <- function(site) file.path(site, "renv.lock")

# The JSON of a renv.lock that records R version `r` and the package
# versions in `packages`, a character vector named by package.
lock_json <- function(packages = character(), r = "4.6.1") {
  records <- lapply(names(packages), function(name) list(Package = name, Version = packages[[name]]))
  names(records) <- as.character(names(packages))
  json <- list(R = list(Version = r), Packages = records)
  as.character(jsonlite::toJSON(json, auto_unbox = TRUE, pretty = TRUE))
}

write_lock <- function(site, ...) writeLines(lock_json(...), lock_path(site))

lock_unreadable <- function(active = "") {
  paste0("It cannot be read as an renv lockfile. It is a folder, a link to a missing file, or a file that ",
         "cannot be opened, or it is not UTF-8 text that holds a JSON object with a Packages object, or it ",
         "repeats a key. Run renv::snapshot()", active, " to write it again, then commit it.")
}
lock_unreadable_text <- lock_unreadable()

test_that("renv_lock must be TRUE or FALSE", {
  site <- new_site()
  for (bad in list(NA, c(TRUE, TRUE), "TRUE", 1, NULL)) {
    expect_error(check_supplement(site, renv_lock = bad), class = "supplement_error_argument")
  }
})

test_that("a site with no renv.lock gets a skip message and no renv-mismatch row", {
  site <- new_site()
  expect_message(result <- check_supplement(site, renv_lock = TRUE),
                 "Skipped the \"renv-mismatch\" check: the site has no .renv\\.lock")
  expect_identical(nrow(rows_of(result, "renv-mismatch")), 0L)
  expect_identical(attr(result, "skipped"), attr(check_quiet(site), "skipped"))
})

test_that("a renv.lock that cannot be read gets one renv-mismatch row", {
  site <- new_site()
  lock <- lock_path(site)
  cases <- list(
    folder = function() dir.create(lock),
    dangling = function() file.symlink(file.path(site, "no-such.lock"), lock),
    latin1 = function() writeBin(c(charToRaw('{"Packages": {"caf'), as.raw(0xe9), charToRaw('": {}}}')), lock),
    not_json = function() writeLines("{", lock),
    array = function() writeLines("[]", lock),
    no_packages = function() writeLines('{"R": {"Version": "4.6.1"}}', lock),
    packages_array = function() writeLines('{"Packages": []}', lock),
    two_r = function() writeLines('{"R": {"Version": "4.6.1"}, "R": {"Version": "4.5.0"}, "Packages": {}}', lock),
    two_packages = function() writeLines('{"Packages": {}, "Packages": {}}', lock),
    two_r_versions = function() writeLines('{"R": {"Version": "4.6.1", "Version": "4.5.0"}, "Packages": {}}', lock),
    two_records = function() {
      writeLines('{"Packages": {"cli": {"Version": "3.6.6"}, "cli": {"Version": "3.6.5"}}}', lock)
    },
    two_versions = function() writeLines('{"Packages": {"cli": {"Version": "3.6.6", "Version": "3.6.5"}}}', lock),
    one_package_twice = function() {
      writeLines(paste('{"Packages": {"a": {"Package": "cli", "Version": "3.6.6"},',
                       '"b": {"Package": "cli", "Version": "3.6.5"}}}'), lock)
    }
  )
  for (case in names(cases)) {
    unlink(lock, recursive = TRUE)
    cases[[case]]()
    rows <- rows_of(check_lock(site), "renv-mismatch")
    expect_identical(rows$file, "renv.lock", info = case)
    expect_identical(rows$problem, lock_unreadable_text, info = case)
  }
})

# The R version that print_environment() prints for this session, or none
# for a development build of R.
session_r <- function() {
  if (startsWith(R.version.string, "R version ")) strsplit(R.version.string, " ", fixed = TRUE)[[1]][3] else character()
}

# A sessioninfo package table with the `!` column, which sessioninfo adds
# when a package has a problem. The `V` row was loaded at another version
# than the one on disk.
flagged_table <- c(
  "\u2500 Packages \u2500\u2500\u2500\u2500\u2500\u2500",
  " ! package * version date (UTC) lib source",
  "   cli       3.6.6   2026-04-09 [1] CRAN (R 4.6.0)",
  " V dplyr     1.1.3   2026-01-01 [1] CRAN (R 4.6.0) (on disk 1.1.4)",
  "",
  " [1] ~/R/library"
)

test_that("stored_versions() reads the sessioninfo table after either rule", {
  skip_if_not_installed("sessioninfo")
  info <- sessioninfo::session_info()
  pkgs <- info$packages
  expected <- ifelse(is.na(pkgs$loadedversion), pkgs$ondiskversion, pkgs$loadedversion)
  names(expected) <- pkgs$package
  for (rule in c("\u2500 Packages", "- Packages")) {
    withr::local_options(cli.unicode = rule != "- Packages", cli.num_colors = 1)
    lines <- utils::capture.output(print(info))
    expect_true(any(startsWith(lines, rule)), info = rule)
    got <- stored_versions(paste(lines, collapse = "\n"))
    expect_identical(got$packages, expected, info = rule)
    expect_identical(got$r, session_r(), info = rule)
  }
})

test_that("stored_versions() reads utils::sessionInfo() with package lists that wrap", {
  info <- utils::sessionInfo()
  withr::local_options(width = 40)
  lines <- utils::capture.output(print(info))
  loaded <- which(lines == "loaded via a namespace (and not attached):")
  stopifnot("the loaded list wraps" = length(loaded) == 1 && grepl("^ *\\[[0-9]+\\] ", lines[loaded + 2]))
  got <- stored_versions(paste(lines, collapse = "\n"))
  records <- c(info$otherPkgs, info$loadedOnly)
  expected <- vapply(records, function(x) x$Version, character(1))
  expect_setequal(paste(names(got$packages), got$packages), paste(names(expected), expected))
  expect_identical(got$r, session_r())
})

# flagged_table with `*` under the header's `*` for dplyr, and a `*` in
# another column for cli.
attached_table <- c(
  flagged_table[1:2],
  "   cli       3.6.6   2026-04-09 [1] CRAN (R 4.6.0) *",
  " V dplyr   * 1.1.3   2026-01-01 [1] CRAN (R 4.6.0) (on disk 1.1.4)",
  flagged_table[5:6]
)

test_that("stored_versions() reads the attached packages of a sessioninfo table", {
  skip_if_not_installed("sessioninfo")
  info <- sessioninfo::session_info()
  stopifnot("a package is attached" = any(info$packages$attached))
  withr::local_options(cli.unicode = TRUE, cli.num_colors = 1)
  got <- stored_versions(paste(utils::capture.output(print(info)), collapse = "\n"))
  expect_setequal(got$attached, info$packages$package[info$packages$attached])
  expect_identical(stored_versions(paste(attached_table, collapse = "\n"))$attached, "dplyr")
})

test_that("stored_versions() reads attached packages from other attached packages only", {
  info <- utils::sessionInfo()
  stopifnot("a package is attached" = length(info$otherPkgs) > 0)
  got <- stored_versions(paste(utils::capture.output(print(info)), collapse = "\n"))
  expect_setequal(got$attached, names(info$otherPkgs))
  expect_true(got$listed)
  expect_false(stored_versions("x")$listed)
})

# The JSON of a stored output file whose markdown holds lines in the form
# of utils::sessionInfo(): R version `r` and the package versions in
# `packages`, a character vector named by package. The lines end with
# `eol`.
env_json <- function(packages, r = "4.6.1", eol = "\n") {
  stopifnot(length(packages) > 0)
  lines <- c(if (length(r) > 0) paste0("R version ", r, " (2026-06-24)"), "",
             "other attached packages:", paste("[1]", paste0(names(packages), "_", packages, collapse = " ")))
  text_json(lines, eol)
}

# The JSON of a stored output file whose markdown is the lines `lines`,
# each ended with `eol`.
text_json <- function(lines, eol = "\n") {
  as.character(jsonlite::toJSON(list(hash = "h", result = list(markdown = paste(lines, collapse = eol))),
                                auto_unbox = TRUE))
}

# Write report `name` and its stored output files, given as `file = json`.
env_report <- function(site, name, ...) {
  report_bytes(site, name, stale_lf)
  files <- list(...)
  for (file in names(files)) stored_file(site, name, file, files[[file]])
}

# The problem text of a renv-mismatch row whose files `files` of report
# `name` hold the versions in `entries`, with the format hint when `hint`
# is TRUE. `lock` is the lockfile, and `active` follows the renv commands.
lock_text <- function(name, files, entries, hint = FALSE, lock = "renv.lock", active = "") {
  stale <- paste0("Its stored output was made with other versions than ", lock, " records, in ",
                  quoted_paths(name, files), ": ", entries, ".")
  steps <- paste0("To use the versions in ", lock, ", run renv::restore()", active, ", then take these steps. ",
                  rerender_steps, " If the library now holds the versions of the report, run renv::snapshot()",
                  active, " and commit ", lock, " instead.")
  if (!hint) {
    return(paste(stale, steps))
  }
  paste(stale,
        paste0("Other stored output of the report matches ", lock, ", so these files can be from a format that the"),
        "report no longer renders. If so, delete them, render the whole site, and commit the report with",
        "_freeze/, docs/, and figures/.",
        "If not, take the steps that follow.", steps)
}

test_that("stored versions that differ from renv.lock give a renv-mismatch row", {
  site <- new_site()
  write_lock(site, c(dplyr = "1.1.4", Rcpp = "1.0.14", abc = "2.0", cli = "3.6.6", Matrix = "1.0-6"))
  env_report(site, "one", html.json = env_json(c(dplyr = "1.1.3")))
  env_report(site, "crlf", html.json = env_json(c(dplyr = "1.1.3"), eol = "\r\n"))
  env_report(site, "spellings", html.json = env_json(c(Matrix = "1.0-5")), docx.json = env_json(c(Matrix = "1.0.5")))
  env_report(site, "two", html.json = env_json(c(abc = "1.9", cli = "3.6.6", Rcpp = "1.0.13")))
  env_report(site, "r-alone", html.json = env_json(c(dplyr = "1.1.4"), r = "4.5.2"))
  env_report(site, "r-and-package", html.json = env_json(c(dplyr = "1.1.3"), r = "4.5.2"))
  env_report(site, "old-format", html.json = env_json(c(dplyr = "1.1.4")), docx.json = env_json(c(dplyr = "1.1.3")))
  env_report(site, "two-versions", docx.json = env_json(c(dplyr = "1.10.0")), html.json = env_json(c(dplyr = "1.9.0")))
  env_report(site, "table", html.json = text_json(flagged_table))
  env_report(site, "not-json", html.json = "{", docx.json = env_json(c(dplyr = "1.1.3")))

  rows <- rows_of(check_lock(site), "renv-mismatch")
  expect_setequal(rows$file, paste0("analyses/", c("one", "crlf", "spellings", "two", "r-alone", "r-and-package",
                                                   "old-format", "two-versions", "table", "not-json"), ".qmd"))
  text <- function(name) rows$problem[rows$file == paste0("analyses/", name, ".qmd")]
  expect_identical(text("one"), lock_text("one", "html.json", "dplyr 1.1.3 (renv.lock: 1.1.4)"))
  expect_identical(text("crlf"), lock_text("crlf", "html.json", "dplyr 1.1.3 (renv.lock: 1.1.4)"))
  expect_identical(text("spellings"), lock_text("spellings", c("docx.json", "html.json"),
                                                "Matrix 1.0.5 (renv.lock: 1.0-6)"))
  expect_identical(text("two"), lock_text("two", "html.json",
                                          "Rcpp 1.0.13 (renv.lock: 1.0.14), abc 1.9 (renv.lock: 2.0)"))
  expect_identical(text("r-alone"), lock_text("r-alone", "html.json", "R 4.5.2 (renv.lock: 4.6.1)"))
  expect_identical(text("r-and-package"), lock_text("r-and-package", "html.json",
                                                    "R 4.5.2 (renv.lock: 4.6.1), dplyr 1.1.3 (renv.lock: 1.1.4)"))
  expect_identical(text("old-format"), lock_text("old-format", "docx.json", "dplyr 1.1.3 (renv.lock: 1.1.4)",
                                                 hint = TRUE))
  expect_identical(text("two-versions"), lock_text("two-versions", c("docx.json", "html.json"),
                                                   "dplyr 1.9.0 and 1.10.0 (renv.lock: 1.1.4)"))
  expect_identical(text("table"), lock_text("table", "html.json", "dplyr 1.1.3 (renv.lock: 1.1.4)"))
  expect_identical(text("not-json"), lock_text("not-json", "docx.json", "dplyr 1.1.3 (renv.lock: 1.1.4)"))
})

test_that("versions that match renv.lock or are not compared give no renv-mismatch row", {
  site <- new_site()
  write_lock(site, c(dplyr = "1.1.4", Matrix = "1.0-5", odd = "not-a-version"))
  env_report(site, "differs", html.json = env_json(c(dplyr = "1.1.3")))
  env_report(site, "equal", html.json = env_json(c(dplyr = "1.1.4", Matrix = "1.0.5")))
  env_report(site, "not-in-lock", html.json = env_json(c(dplyr = "1.1.4", ggplot2 = "3.5.1")))
  env_report(site, "prose-r", html.json = text_json(c("R version 4.2 is what we used.", "",
                                                      "other attached packages:", "[1] dplyr_1.1.4")))
  env_report(site, "second-r", html.json = text_json(c("R version 4.6.1 (2026-06-24)",
                                                       "R version 4.5.0 (2025-04-11)")))
  env_report(site, "base", html.json = text_json(c("R version 4.6.1 (2026-06-24)", "",
                                                   "loaded via a namespace (and not attached):",
                                                   "[1] compiler_4.6.1 dplyr_1.1.4")))
  env_report(site, "unreadable", html.json = env_json(c(odd = "1.0", dplyr = "devel"), r = "devel"))
  env_report(site, "no-list", html.json = text_json("x"))
  env_report(site, "prefixed", html.json = text_json(paste0("## ", flagged_table)))
  colored <- flagged_table
  colored[1] <- paste0("\033[1m\033[36m", colored[1], "\033[39m\033[22m")
  env_report(site, "colored", html.json = text_json(colored))
  file.symlink(file.path(site, "no-such.qmd"), file.path(site, "analyses", "dangling.qmd"))
  stored_file(site, "dangling", "html.json", env_json(c(dplyr = "1.1.3")))

  expect_identical(rows_of(check_lock(site), "renv-mismatch")$file, "analyses/differs.qmd")
})

test_that("a renv.lock with no R version compares only package versions", {
  site <- new_site()
  writeLines('{"Packages": {"dplyr": {"Package": "dplyr", "Version": "1.1.4"}}}', lock_path(site))
  env_report(site, "r-differs", html.json = env_json(c(dplyr = "1.1.4"), r = "4.5.2"))
  env_report(site, "package-differs", html.json = env_json(c(dplyr = "1.1.3"), r = "4.5.2"))
  rows <- rows_of(check_lock(site), "renv-mismatch")
  expect_identical(rows$file, "analyses/package-differs.qmd")
  expect_identical(rows$problem, lock_text("package-differs", "html.json", "dplyr 1.1.3 (renv.lock: 1.1.4)"))
})

test_that("a renv.lock record is named by its Package text, and a byte order mark is skipped", {
  site <- new_site()
  lock <- '{"R": {"Version": "4.6.1"}, "Packages": {"old-key": {"Package": "dplyr", "Version": "1.1.4"}}}'
  writeBin(c(as.raw(c(0xef, 0xbb, 0xbf)), charToRaw(lock)), lock_path(site))
  env_report(site, "differs", html.json = env_json(c(dplyr = "1.1.3")))
  rows <- rows_of(check_lock(site), "renv-mismatch")
  expect_identical(rows$problem, lock_text("differs", "html.json", "dplyr 1.1.3 (renv.lock: 1.1.4)"))
})

test_that("a sessioninfo table is read in a Latin-1 locale", {
  site <- new_site()
  write_lock(site, c(dplyr = "1.1.4"))
  env_report(site, "table", html.json = text_json(flagged_table))
  old <- Sys.getlocale("LC_CTYPE")
  set <- suppressWarnings(Sys.setlocale("LC_CTYPE", "en_US.ISO8859-1"))
  withr::defer(Sys.setlocale("LC_CTYPE", old))
  skip_if(!nzchar(set), "the en_US.ISO8859-1 locale is not available")
  expect_identical(rows_of(check_lock(site), "renv-mismatch")$file, "analyses/table.qmd")
})

test_that("versions after a line of 5 MB give a renv-mismatch row with no warning", {
  site <- new_site()
  write_lock(site, c(dplyr = "1.1.4"))
  env_report(site, "long", html.json = text_json(c(strrep("a", 5e6), flagged_table)))
  expect_no_warning(rows <- rows_of(check_lock(site), "renv-mismatch"))
  expect_identical(rows$file, "analyses/long.qmd")
})

test_that("by default check_supplement() does not read renv.lock", {
  site <- new_site()
  write_lock(site, c(dplyr = "1.1.4"))
  env_report(site, "differs", html.json = env_json(c(dplyr = "1.1.3")))
  expect_identical(rows_of(check_lock(site), "renv-mismatch")$file, "analyses/differs.qmd")
  writeLines("{", lock_path(site))
  expect_identical(nrow(rows_of(check_quiet(site), "renv-mismatch")), 0L)
  expect_identical(rows_of(check_lock(site), "renv-mismatch")$file, "renv.lock")
})

# The problem text of a renv-missing row whose files `files` of report
# `name` attach the packages `packages`, with the format hint when `hint`
# is TRUE.
missing_text <- function(name, files, packages, hint = FALSE, lock = "renv.lock", active = "") {
  stale <- paste0("Its stored output shows that the report attached packages that ", lock, " does not record, in ",
                  quoted_paths(name, files), ": ", paste(packages, collapse = ", "), ".")
  steps <- paste0("renv::restore() does not install them. To record them, run renv::snapshot()", active,
                  " and commit ", lock, ". If the report no longer uses them, take these steps instead. ",
                  rerender_steps)
  if (!hint) {
    return(paste(stale, steps))
  }
  paste(stale,
        "Other stored output of the report attaches none of them, so these files can be from a format that the",
        "report no longer renders. If so, delete them, render the whole site, and commit the report with",
        "_freeze/, docs/, and figures/.",
        "If not, take the steps that follow.", steps)
}

# A sessioninfo package table without the `!` column, with dplyr attached.
plain_table <- c(
  "─ Packages ──────",
  " package * version date (UTC) lib source",
  " cli       3.6.6   2026-04-09 [1] CRAN (R 4.6.0)",
  " dplyr   * 1.1.4   2026-01-01 [1] CRAN (R 4.6.0)",
  "",
  " [1] ~/R/library"
)

test_that("attached packages that renv.lock does not name give a renv-missing row", {
  site <- new_site()
  write_lock(site, c(cli = "3.6.6"))
  env_report(site, "flagged", html.json = text_json(attached_table))
  env_report(site, "plain", html.json = text_json(plain_table))
  env_report(site, "wrapped", html.json = text_json(c("other attached packages:", "[1] tidyr_1.3.1 cli_3.6.6",
                                                      "[3] dplyr_1.1.4")))
  env_report(site, "two", html.json = env_json(c(dplyr = "1.1.4")),
             docx.json = env_json(c(dplyr = "1.1.4", ggplot2 = "3.5.1")))
  env_report(site, "old-format", html.json = env_json(c(cli = "3.6.6")), docx.json = env_json(c(dplyr = "1.1.4")))

  rows <- rows_of(check_lock(site), "renv-missing")
  expect_setequal(rows$file, paste0("analyses/", c("flagged", "plain", "wrapped", "two", "old-format"), ".qmd"))
  text <- function(name) rows$problem[rows$file == paste0("analyses/", name, ".qmd")]
  expect_identical(text("flagged"), missing_text("flagged", "html.json", "dplyr"))
  expect_identical(text("plain"), missing_text("plain", "html.json", "dplyr"))
  expect_identical(text("wrapped"), missing_text("wrapped", "html.json", c("dplyr", "tidyr")))
  expect_identical(text("two"), missing_text("two", c("docx.json", "html.json"), c("dplyr", "ggplot2")))
  expect_identical(text("old-format"), missing_text("old-format", "docx.json", "dplyr", hint = TRUE))
})

test_that("loaded packages and packages that renv.lock names give no renv-missing row", {
  # Each case gets a planted copy that also attaches tidyr, which no
  # renv.lock below names, so each case can give the row.
  cases <- list(
    table = list(lock = lock_json(), lines = flagged_table),
    namespace = list(lock = lock_json(), lines = c("loaded via a namespace (and not attached):", "[1] dplyr_1.1.4")),
    other_version = list(lock = lock_json(c(dplyr = "0.1")), lines = c("other attached packages:", "[1] dplyr_1.1.4")),
    no_version = list(lock = '{"Packages": {"x": {"Package": "dplyr"}}}',
                      lines = c("other attached packages:", "[1] dplyr_1.1.4")),
    key_alone = list(lock = '{"Packages": {"dplyr": {"Version": "1.1.4"}}}',
                     lines = c("other attached packages:", "[1] dplyr_1.1.4"))
  )
  for (case in names(cases)) {
    site <- new_site()
    writeLines(cases[[case]]$lock, lock_path(site))
    lines <- cases[[case]]$lines
    env_report(site, "case", html.json = text_json(lines))
    env_report(site, "planted", html.json = text_json(c(lines, "", "other attached packages:", "[1] tidyr_1.3.1")))
    rows <- rows_of(check_lock(site), "renv-missing")
    expect_identical(rows$file, "analyses/planted.qmd", info = case)
    expect_identical(rows$problem, missing_text("planted", "html.json", "tidyr"), info = case)
  }
})

test_that("a renv.lock record with an empty name names no package", {
  site <- new_site()
  writeLines('{"Packages": {"": {"Version": "1.1.4"}}}', lock_path(site))
  env_report(site, "attached", html.json = text_json(c("other attached packages:", "[1] dplyr_1.1.4")))
  expect_identical(rows_of(check_lock(site), "renv-missing")$file, "analyses/attached.qmd")
})

test_that("no renv-missing row without a readable renv.lock or report, or by default", {
  site <- new_site()
  env_report(site, "attached", html.json = text_json(c("other attached packages:", "[1] dplyr_1.1.4")))
  expect_message(result <- check_supplement(site, renv_lock = TRUE),
                 "renv\\.lock.\\. Skipped the \"renv-missing\" check too\\.")
  expect_identical(nrow(rows_of(result, "renv-missing")), 0L)

  writeLines("{", lock_path(site))
  result <- check_lock(site)
  rows <- result[result$check %in% c("renv-mismatch", "renv-missing"), , drop = FALSE]
  expect_identical(paste(rows$check, rows$file), "renv-mismatch renv.lock")
  expect_identical(rows$problem, lock_unreadable_text)

  write_lock(site)
  expect_identical(nrow(rows_of(check_quiet(site), "renv-missing")), 0L)
  symlink_or_skip(file.path(site, "no-such.qmd"), file.path(site, "analyses", "dangling.qmd"))
  stored_file(site, "dangling", "html.json", text_json(c("other attached packages:", "[1] dplyr_1.1.4")))
  expect_identical(rows_of(check_lock(site), "renv-missing")$file, "analyses/attached.qmd")
})

test_that("renv-missing rows follow the renv-mismatch rows, in the order of the reports", {
  site <- new_site()
  write_lock(site, c(dplyr = "1.1.4"))
  for (name in c("a", "b")) env_report(site, name, html.json = env_json(c(dplyr = "1.1.3", tidyr = "1.3.1")))
  result <- check_lock(site)
  rows <- result[result$check %in% c("renv-mismatch", "renv-missing"), , drop = FALSE]
  expect_identical(paste(rows$check, rows$file), c("renv-mismatch analyses/a.qmd", "renv-mismatch analyses/b.qmd",
                                                   "renv-missing analyses/a.qmd", "renv-missing analyses/b.qmd"))
})

# renv profiles ---------------------------------------------------------------

profile_lock_path <- function(site, profile) file.path(site, "renv", "profiles", profile, "renv.lock")

write_profile_lock <- function(site, profile, ...) {
  dir.create(dirname(profile_lock_path(site, profile)), recursive = TRUE, showWarnings = FALSE)
  writeLines(lock_json(...), profile_lock_path(site, profile))
}

profile_file <- function(site) file.path(site, "renv", "profile")

# The text that follows the renv commands in a row under profile `profile`.
profile_active <- function(profile) paste0(' with the renv profile "', profile, '" active')

# The info messages that check_supplement(renv_lock = TRUE) prints for
# `site` that name renv, without ANSI codes or Unicode.
lock_messages <- function(site) {
  withr::local_options(cli.unicode = FALSE, cli.num_colors = 1, cli.hyperlink = FALSE)
  messages <- character()
  withCallingHandlers(check_supplement(site, renv_lock = TRUE), message = function(m) {
    messages <<- c(messages, conditionMessage(m))
    invokeRestart("muffleMessage")
  })
  messages[startsWith(messages, "i ") & grepl("renv", messages, fixed = TRUE)]
}

test_that("the renv.lock check reads the lockfile of the renv profile that renv picks", {
  site <- new_site()
  write_lock(site, c(dplyr = "1.1.0"))
  write_profile_lock(site, "dev", c(dplyr = "1.1.4"))
  write_profile_lock(site, "other", c(dplyr = "1.1.2"))
  # Windows drops the trailing space of a folder name, so it cannot hold
  # the folder " dev ".
  windows <- .Platform$OS.type == "windows"
  if (!windows) write_profile_lock(site, " dev ", c(dplyr = "1.1.5"))
  write_profile_lock(site, "x", c(dplyr = "1.1.6"))
  env_report(site, "r", html.json = env_json(c(dplyr = "1.1.3")))
  versions <- c("renv.lock" = "1.1.0", dev = "1.1.4", other = "1.1.2", " dev " = "1.1.5", "x/../other" = "1.1.2")
  # Each case: the RENV_PROFILE value (NA to unset it), the bytes of
  # renv/profile (NULL for none), and the profile that renv picks.
  cases <- list(
    none = list(NA, NULL, "renv.lock"),
    variable_set = list("dev", NULL, "dev"),
    file = list(NA, "dev\n", "dev"),
    variable_over_file = list("dev", "other\n", "dev"),
    variable_default = list("default", "other\n", "renv.lock"),
    file_default = list(NA, "default\n", "renv.lock"),
    empty_file = list(NA, "", "renv.lock"),
    blank_first_line = list(NA, "\ndev\n", "renv.lock"),
    crlf = list(NA, "dev\r\n", "dev"),
    spaces = list(NA, " dev \n", " dev "),
    dots = list(NA, "x/../other\n", "x/../other")
  )
  if (windows) cases$spaces <- NULL
  for (case in names(cases)) {
    unlink(profile_file(site))
    bytes <- cases[[case]][[2]]
    if (!is.null(bytes)) writeBin(charToRaw(bytes), profile_file(site))
    rows <- withr::with_envvar(c(RENV_PROFILE = cases[[case]][[1]]), rows_of(check_lock(site), "renv-mismatch"))
    picked <- cases[[case]][[3]]
    lock <- if (picked == "renv.lock") "renv.lock" else paste0("renv/profiles/", picked, "/renv.lock")
    active <- if (picked == "renv.lock") "" else profile_active(picked)
    expect_identical(rows$problem, lock_text("r", "html.json", paste0("dplyr 1.1.3 (", lock, ": ", versions[[picked]], ")"),
                                             lock = lock, active = active), info = case)
  }

  # With no profile, the function names none.
  unlink(profile_file(site))
  expect_identical(lock_messages(site), character())

  # renv tests renv/profile with file.exists(), which is TRUE on Windows
  # for a link to a missing file.
  skip_on_os("windows")
  symlink_or_skip(file.path(site, "no-such-profile"), profile_file(site))
  rows <- rows_of(check_lock(site), "renv-mismatch")
  expect_identical(rows$problem, lock_text("r", "html.json", "dplyr 1.1.3 (renv.lock: 1.1.0)"))
})

test_that("rows and messages name the lockfile and the source of the renv profile", {
  for (profile in c("dev", "a{b} c")) {
    site <- new_site()
    from_variable <- profile == "dev"
    if (from_variable) {
      withr::local_envvar(RENV_PROFILE = profile)
      source <- "`RENV_PROFILE`"
    } else {
      withr::local_envvar(RENV_PROFILE = NA)
      dir.create(dirname(profile_file(site)))
      writeLines(profile, profile_file(site))
      source <- "'renv/profile'"
    }
    lock <- paste0("renv/profiles/", profile, "/renv.lock")
    active <- profile_active(profile)
    picked <- paste0("i Picked '", lock, "', the lockfile of the renv profile \"", profile, "\", which ", source,
                     " names.\n")
    write_profile_lock(site, profile, c(dplyr = "1.1.4"))
    env_report(site, "r", html.json = env_json(c(dplyr = "1.1.3", tidyr = "1.3.1")))

    expect_identical(lock_messages(site), picked, info = profile)
    result <- check_lock(site)
    expect_identical(rows_of(result, "renv-mismatch")$problem,
                     lock_text("r", "html.json", paste0("dplyr 1.1.3 (", lock, ": 1.1.4)"), lock = lock, active = active),
                     info = profile)
    expect_identical(rows_of(result, "renv-missing")$problem,
                     missing_text("r", "html.json", "tidyr", lock = lock, active = active), info = profile)
    env_report(site, "old", html.json = env_json(c(dplyr = "1.1.4")), docx.json = env_json(c(dplyr = "1.1.3")))
    rows <- rows_of(check_lock(site), "renv-mismatch")
    expect_identical(rows$problem[rows$file == "analyses/old.qmd"],
                     lock_text("old", "docx.json", paste0("dplyr 1.1.3 (", lock, ": 1.1.4)"), hint = TRUE,
                               lock = lock, active = active), info = profile)

    writeLines("{", profile_lock_path(site, profile))
    rows <- rows_of(check_lock(site), "renv-mismatch")
    expect_identical(rows$file, lock, info = profile)
    expect_identical(rows$problem, lock_unreadable(active), info = profile)

    unlink(profile_lock_path(site, profile))
    skipped <- paste0("i Skipped the \"renv-mismatch\" check: the site has no '", lock,
                      "'. Skipped the \"renv-missing\" check too.\n")
    expect_identical(lock_messages(site), c(picked, skipped), info = profile)
  }
})

test_that("a missing lockfile of the renv profile skips the checks when renv.lock exists", {
  site <- new_site()
  withr::local_envvar(RENV_PROFILE = "dev")
  write_lock(site, c(dplyr = "1.1.0", cli = "3.6.6"))
  env_report(site, "r", html.json = env_json(c(dplyr = "1.1.3", tidyr = "1.3.1")))
  expect_message(result <- check_supplement(site, renv_lock = TRUE),
                 "the site has no .renv/profiles/dev/renv\\.lock.\\. Skipped the \"renv-missing\" check too\\.")
  expect_identical(nrow(result[result$check %in% c("renv-mismatch", "renv-missing"), ]), 0L)
})

test_that("the message names both sources of the profile when they give the same name", {
  # Each shape of renv/profile beside RENV_PROFILE "dev", and the sources
  # that the message then names.
  alone <- "`RENV_PROFILE` names"
  shapes <- list(
    "the same name" = list(function(site) writeLines("dev", profile_file(site)),
                           "`RENV_PROFILE` and 'renv/profile' both name"),
    "no renv/profile" = list(function(site) unlink(profile_file(site)), alone),
    "an empty renv/profile" = list(function(site) file.create(profile_file(site)), alone),
    "another name" = list(function(site) writeLines("other", profile_file(site)), alone),
    "a folder" = list(function(site) dir.create(profile_file(site)), alone)
  )
  withr::local_envvar(RENV_PROFILE = "dev")
  lock <- "renv/profiles/dev/renv.lock"
  for (shape in names(shapes)) {
    site <- new_site()
    dir.create(dirname(profile_file(site)), showWarnings = FALSE)
    shapes[[shape]][[1]](site)
    write_profile_lock(site, "dev", c(dplyr = "1.1.4"))
    env_report(site, "r", html.json = env_json(c(dplyr = "1.1.3")))
    expect_identical(lock_messages(site), paste0(
      "i Picked '", lock, "', the lockfile of the renv profile \"dev\", which ", shapes[[shape]][[2]], ".\n"
    ), info = shape)
    expect_identical(rows_of(check_lock(site), "renv-mismatch")$problem,
                     lock_text("r", "html.json", paste0("dplyr 1.1.3 (", lock, ": 1.1.4)"), lock = lock,
                               active = profile_active("dev")), info = shape)
  }
})

test_that("a lockfile path listed under another letter case gets a row of its own", {
  # Each case: the RENV_PROFILE value (NA to unset it), the path that renv
  # picks, and the path as the site lists it.
  profile <- "renv/profiles/dev/renv.lock"
  cases <- list(
    list(NA, "renv.lock", "Renv.lock"),
    list("dev", profile, "Renv/profiles/dev/renv.lock"),
    list("dev", profile, "renv/Profiles/dev/renv.lock"),
    list("dev", profile, "renv/profiles/Dev/renv.lock"),
    list("dev", profile, "renv/profiles/dev/RENV.LOCK")
  )
  for (case in cases) {
    site <- new_site()
    lock <- case[[2]]
    listed <- case[[3]]
    # Only the first site holds a report, whose rows must stay.
    report <- identical(case, cases[[1]])
    dir.create(dirname(file.path(site, listed)), recursive = TRUE, showWarnings = FALSE)
    writeLines(lock_json(c(dplyr = "1.1.4")), file.path(site, listed))
    if (report) env_report(site, "r", html.json = env_json(c(dplyr = "1.1.3", tidyr = "1.3.1")))
    withr::with_envvar(c(RENV_PROFILE = case[[1]]), {
      result <- check_lock(site)
      messages <- lock_messages(site)
    })
    if (ignores_case(site)) {
      rows <- rows_of(result, "renv-mismatch")
      expect_identical(rows$file, c(lock, if (report) "analyses/r.qmd"), info = listed)
      expect_identical(rows$problem[1], paste0(
        'It is listed as "', listed, '". renv finds it only where the file system treats both spellings as ',
        "one name, as macOS and Windows do for letter case by default, and write_dockerfile() refuses it. ",
        "Rename it to \"", lock, '", then commit the change.'
      ), info = listed)
      if (report) {
        expect_identical(rows$problem[2], lock_text("r", "html.json", "dplyr 1.1.3 (renv.lock: 1.1.4)"))
        expect_identical(rows_of(result, "renv-missing")$problem, missing_text("r", "html.json", "tidyr"))
      }
    } else {
      expect_identical(nrow(result[result$check %in% c("renv-mismatch", "renv-missing"), ]), 0L, info = listed)
      expect_match(messages[length(messages)], paste0("the site has no '", lock, "'"), fixed = TRUE, info = listed)
    }
  }

  # A lockfile that cannot be read gets the row that says so and no row on
  # its letter case.
  site <- new_site()
  dir.create(file.path(site, "Renv.lock"))
  rows <- rows_of(check_lock(site), "renv-mismatch")
  if (ignores_case(site)) {
    expect_identical(rows$file, "renv.lock")
    expect_identical(rows$problem, lock_unreadable_text)
  } else {
    expect_identical(nrow(rows), 0L)
  }
})

test_that("a lockfile path that the system finds by another path gets no spelling row", {
  # Each case: the RENV_PROFILE value and the folder that holds the
  # lockfile. Windows drops a trailing `.` or space from a name, and there
  # the lockfile of `dev ` can get the row that it cannot be read.
  spelling <- "listed under another spelling|^It is listed as"
  cases <- list(list("dev/", "dev"))
  if (.Platform$OS.type == "windows") cases <- c(cases, list(list("dev.", "dev"), list("dev ", "dev")))
  for (case in cases) {
    site <- new_site()
    write_profile_lock(site, case[[2]], c(dplyr = "1.1.4"))
    rows <- withr::with_envvar(c(RENV_PROFILE = case[[1]]), rows_of(check_lock(site), "renv-mismatch"))
    expect_false(any(grepl(spelling, rows$problem)), info = paste(case[[1]], rows$problem))
  }

  # A folder that can be entered but not listed hides the spelling.
  skip_on_os("windows")
  site <- new_site()
  write_profile_lock(site, "dev", c(dplyr = "1.1.4"))
  folder <- file.path(site, "renv", "profiles", "dev")
  Sys.chmod(folder, "0311")
  on.exit(Sys.chmod(folder, "0755"), add = TRUE)
  skip_if(length(list.files(folder)) > 0, "the folder can still be listed (running as root)")
  rows <- withr::with_envvar(c(RENV_PROFILE = "dev"), rows_of(check_lock(site), "renv-mismatch"))
  expect_false(any(grepl(spelling, rows$problem)))
})

test_that("a profile name that is not valid UTF-8 shows its bytes in messages and the lockfile row", {
  site <- new_site()
  name <- rawToChar(as.raw(c(0x63, 0x61, 0x66, 0xe9)))
  dir.create(dirname(profile_file(site)))
  writeBin(c(charToRaw(name), as.raw(0x0a)), profile_file(site))
  # On Windows the path cannot be tested, so the lockfile gets the
  # unreadable row there, and elsewhere the skip message.
  expect_identical(lock_messages(site)[1], paste0(
    "i Picked 'renv/profiles/caf<e9>/renv.lock', the lockfile of the renv profile \"caf<e9>\", ",
    "which 'renv/profile' names.\n"
  ))

  # macOS refuses such a name, so the test skips where dir.create() fails.
  made <- tryCatch(dir.create(dirname(profile_lock_path(site, name)), recursive = TRUE),
                   error = function(e) FALSE, warning = function(w) FALSE)
  skip_if_not(isTRUE(made), "the file system refuses a name that is not valid UTF-8")
  writeLines("{", profile_lock_path(site, name))
  expect_no_error(rows <- rows_of(check_lock(site), "renv-mismatch"))
  expect_identical(rows$file, "renv/profiles/caf<e9>/renv.lock")
  expect_identical(rows$problem, lock_unreadable(profile_active("caf<e9>")))
})

test_that("a renv/profile that cannot be read gets one renv-mismatch row", {
  profile_text <- paste(
    "renv reads the name of the site's renv profile from its first line, but it is a folder or a file",
    "that cannot be opened. Make it a file whose first line names the profile, or delete it to use",
    "renv.lock, then commit the change."
  )
  site <- new_site()
  write_lock(site, c(dplyr = "1.1.0"))
  write_profile_lock(site, "dev", c(dplyr = "1.1.4"))
  env_report(site, "r", html.json = env_json(c(dplyr = "1.1.3", tidyr = "1.3.1")))
  lock_rows <- function() {
    result <- check_lock(site)
    result[result$check %in% c("renv-mismatch", "renv-missing"), , drop = FALSE]
  }
  dir.create(profile_file(site))
  rows <- lock_rows()
  expect_identical(paste(rows$check, rows$file), "renv-mismatch renv/profile")
  expect_identical(rows$problem, profile_text)

  # RENV_PROFILE names the profile, so renv does not read renv/profile.
  withr::with_envvar(c(RENV_PROFILE = "dev"), {
    rows <- lock_rows()
    expect_identical(paste(rows$check, rows$file), c("renv-mismatch analyses/r.qmd", "renv-missing analyses/r.qmd"))
  })

  unlink(profile_file(site), recursive = TRUE)
  skip_on_os("windows")
  writeLines("dev", profile_file(site))
  Sys.chmod(profile_file(site), "000")
  withr::defer(Sys.chmod(profile_file(site), "644"))
  skip_if(file.access(profile_file(site), 4) == 0, "the file can still be read, for example as root")
  rows <- lock_rows()
  expect_identical(paste(rows$check, rows$file), "renv-mismatch renv/profile")
  expect_identical(rows$problem, profile_text)
})
