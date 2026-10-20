#' Check a supplement site before a release
#'
#' `check_supplement()` looks for problems that can break a release of a
#' site or publish files that must stay private. It changes no file. It
#' prints each problem it finds and returns all of them as a data frame.
#'
#' The checks, by the value in the `check` column:
#'
#' * `"large-file"`: a file larger than 100 MiB (104,857,600 bytes), which
#'   GitHub refuses. A symbolic link, or on Windows a junction, is not
#'   counted, because git stores only the link.
#' * `"saved-object"`: a saved R object (`.rds`, `.rda`, `.rdata`, `.qs`,
#'   or `.qs2`, in any letter case). A fitted model saved this way can hold
#'   the data it was fitted to.
#' * `"no-stored-output"`: a `.qmd` report directly in `analyses/`, not in
#'   a folder inside it, with code and no stored output in `_freeze/`. A
#'   full render then runs its code, which needs the data. A report has
#'   code when a line starts a code chunk: any mix of spaces, tabs, and `>`
#'   characters, three or more backticks, optional spaces or tabs, then `{`
#'   and a name. The name is the longest run of an ASCII letter followed by
#'   ASCII letters, digits, `_`, or `.`. Any text without `}` can follow
#'   the name, then `}`, and the line ends with optional spaces or tabs.
#'   A chunk named `ojs`, `mermaid`, or `dot`, in any letter case, does not
#'   count, because Quarto starts no engine for it. Every other name counts,
#'   such as `{bash}` or `{sql}`, and so does a chunk in a report whose
#'   front matter sets `engine: markdown`. Quarto also reads other white
#'   space, line breaks included, where this rule reads spaces and tabs,
#'   and such chunk starts are not found. A nul byte in a report counts as
#'   a character that is none of those this rule names.
#'   A report with no chunk also has code when it has inline R code on
#'   one line and the top-level `engine` in its own front matter is
#'   `knitr`. Inline R code is a backtick, then `r` and a space or `#`, or
#'   `{r}` and a space, then text with no backtick, then a backtick. Inline
#'   code that spans lines is not found. Nor is knitr that a `knitr` key,
#'   `execute: engine`, an included file, or `_metadata.yml` turns on.
#'   A report has no stored output when
#'   `_freeze/analyses/<name>/execute-results/` holds no file other than
#'   hidden files and the files in hidden folders.
#' * `"not-rendered"`: the site has no `docs/` folder.
#' * `"broken-link"`: an `href`, `src`, or `xlink:href` link on a page in
#'   `docs/` to a file that is not in `docs/`, or to a folder there with no
#'   `index.html`, or a link that ends with `/` to a file. A page that
#'   cannot be read, such as a link to a missing file, also counts. Pages
#'   in every folder of `docs/` are read, hidden files and folders (names
#'   that start with `.`) included. A symbolic link to a folder, or on
#'   Windows a junction, is not entered. A page in a folder that such a
#'   link points to is read once, at its own path, when the folder is in
#'   `docs/`. A symbolic link in `docs/` to a page file in `docs/` is read
#'   as a page of its own. A symbolic link or junction in `docs/` whose
#'   target exists and resolves to a place outside `docs/` gives a row of
#'   its own, because the published site does not have its target. So a
#'   link to such a link also gives a row. A page that it points to, or a
#'   page in a folder that it points to, is not read. A link on a page whose
#'   path passes through or ends at such a link also counts. For a link to
#'   a folder, the folder's `index.html` is part of that path. A symbolic
#'   link or junction that resolves to `docs/` or a place in it gives no row
#'   of its own. Links
#'   that start with `/`, `#`, or a scheme such as
#'   `https:` are not checked, and no web address is requested. GitHub
#'   Pages matches letter case, so a link whose case differs from the file
#'   name counts as broken, also on a disk that ignores case. A link that
#'   also differs from the name in Unicode form (for example `é` written
#'   as `e` plus an accent) is not caught.
#'
#'   Links are read from start tags only, as a browser reads them. Comments,
#'   `<!...>` and `<?...>` markup, and the text of `<script>`, `<style>`,
#'   `<textarea>`, and `<title>` elements are skipped, and so is page text
#'   such as `<code>` text. Attribute names match in any letter case, and
#'   only whole names count, so `data-href` and `data-src` are not read. A
#'   value can be in double quotes, in single quotes, or unquoted, where it
#'   runs to the next space or `>`. An attribute with no `=`, such as
#'   `<a href>`, has an empty value and is not checked. A start tag that the
#'   end of the page cuts off is not read, as a browser drops it. A page
#'   whose markup goes past the limits of the PCRE pattern engine gives one
#'   row that says so, in place of its link rows. Such a page holds
#'   millions of `-` in one comment, millions of `<` in the text of one
#'   script, style, textarea, or title element (about 5 million did, in a
#'   page of 20 MB), or millions of attributes in one tag. Each value is
#'   handled in this order:
#'   character references are decoded; spaces, tabs, line breaks, and form
#'   feeds at its ends are removed and tabs and line breaks inside it are
#'   dropped; links with a scheme, `/`, or `#` at the start are skipped;
#'   then `%` escapes are decoded. The decoded references are `&amp;`,
#'   `&lt;`, `&gt;`, `&quot;`, and `&apos;` (in lower case, with the `;`),
#'   and number references such as `&#38;` or `&#x26;` with the `;` that
#'   name a code point from 1 to 0x10FFFF, other than a surrogate or 128 to
#'   159. A row shows the link after the references are decoded, the ends
#'   removed, and the tabs and line breaks inside it dropped.
#'
#'   These are the main cases where the check reads a page differently
#'   from a browser. Every other reference (such as `&eacute;`, `&AMP;`, or
#'   `&#38` with no `;`) stays as written. Other control characters at the
#'   ends of a link, such as `&#1;`, stay, while a browser removes them. The
#'   text of `<noscript>`, `<xmp>`, `<iframe>`, `<noembed>`, `<noframes>`,
#'   and `<plaintext>` elements is read as markup, and so is the text of a
#'   `<![CDATA[...]]>` section after its first `>`. The four skipped
#'   elements are also skipped inside `<svg>` and `<math>`. A comment ends
#'   only at the first `-->`, so `<!-->` and `<!--->` also run to the next
#'   `-->`, and `--!>` does not end it. A script ends at its first `</script>`, also when its text holds
#'   `<!--` and `<script>`, where a browser reads on to a later
#'   `</script>`. A `"` or `'` with no closing quote starts an unquoted
#'   value, so the next `>` ends that tag and it is read, where a browser
#'   reads on to the end of the page and drops the tag. A byte that is not
#'   valid UTF-8 is read as text such as `<e9>`; outside a quoted value,
#'   its `>` ends the tag, so an unquoted value keeps the `<e9` part and
#'   the later attributes of that tag are not read. A second attribute of
#'   the same name is also read.
#' * `"doi-mismatch"`: the DOI in `CITATION.cff` differs from the one that
#'   [write_citation()] writes from `_supplement.yml`, or the DOI badge on
#'   `docs/index.html` differs from `zenodo.version-doi` (or
#'   `zenodo.concept-doi` when that is empty). A home page whose source uses
#'   `{{< supplement-doi >}}` but that shows no badge, while
#'   `_supplement.yml` has a DOI, also counts. So does a `CITATION.cff`
#'   that cannot be read or is not a YAML map (a link to a missing file
#'   included), and a DOI in `CITATION.cff` or on the badge that is not a
#'   DOI.
#'
#' The first two checks look at the files that git tracks or does not
#' ignore, which `git ls-files --cached --others --exclude-standard` lists,
#' so files that `.gitignore` blocks are left out. For these two checks the
#' function runs git only to read: `git --version`, `git rev-parse
#' --is-inside-work-tree`, and `git ls-files`. When git is not on the PATH,
#' one of these commands fails, or the folder is not in a git work tree,
#' it skips these two checks and says so.
#'
#' @param path The folder of the site.
#'
#' @return A data frame with one row per problem and the character columns
#'   `check`, `file` (the path in the site), and `problem`, invisibly. It has
#'   zero rows when the function finds no problem. Its `skipped` attribute
#'   names the git checks (`"large-file"` and `"saved-object"`) that did not
#'   run, and is empty when they ran.
#'
#' @section Errors:
#' The function stops with an error of class `supplement_error` and one of
#' these classes:
#'
#' * `supplement_error_argument`: `path` is not a single non-empty string.
#' * `supplement_error_no_metadata`: `path` holds no `_supplement.yml`.
#' * `supplement_error_parse`: the yaml package cannot read
#'   `_supplement.yml`, as for [write_citation()].
#' * `supplement_error_no_map`: `_supplement.yml` has no `supplement:` map.
#' * `supplement_error_field_type`: a DOI in `_supplement.yml` is not one
#'   text value, or `zenodo` is not a map.
#' * `supplement_error_doi`: a DOI in `_supplement.yml` is not a DOI.
#'
#' @seealso [write_citation()] to write `CITATION.cff` again.
#' @export
#' @examples
#' site <- file.path(tempdir(), "check-example")
#' create_supplement(site)
#' # A new site has not been rendered, and its example report has no
#' # stored output yet.
#' problems <- check_supplement(site)
#' problems$check
#' unlink(site, recursive = TRUE)
check_supplement <- function(path = ".") {
  check_path(path)
  path <- drop_trailing_sep(path)
  meta <- read_supplement(path)

  git <- git_files(path)
  rows <- list(
    if (!is.null(git$files)) check_git_files(path, git$files),
    check_stored_output(path),
    check_links(path),
    check_dois(path, meta, call = environment())
  )
  rows <- Filter(Negate(is.null), rows)
  result <- if (length(rows) > 0) do.call(rbind, rows) else problem_rows()
  rownames(result) <- NULL
  attr(result, "skipped") <- if (is.null(git$files)) c("large-file", "saved-object") else character()

  report_problems(result, path, git$reason)
  invisible(result)
}

problem_rows <- function(check = character(), file = character(), problem = character()) {
  data.frame(
    check = rep_len(as.character(check), length(file)),
    file = as.character(file),
    problem = as.character(problem),
    stringsAsFactors = FALSE
  )
}

report_problems <- function(result, path, skip_reason) {
  if (!is.null(skip_reason)) {
    cli::cli_alert_info(
      "Skipped the {.val large-file} and {.val saved-object} checks: {skip_reason}."
    )
  }
  if (nrow(result) == 0) {
    cli::cli_alert_success("No problems found in {.path {path}}.")
    return(invisible())
  }
  cli::cli_alert_danger("{nrow(result)} problem{?s} found in {.path {path}}:")
  for (i in seq_len(nrow(result))) {
    check <- result$check[i]
    file <- result$file[i]
    problem <- result$problem[i]
    cli::cli_bullets(c("x" = "{.strong {check}} {.path {file}}: {problem}"))
  }
  invisible()
}

# Git -----------------------------------------------------------------------

# Run git in `dir` and return its exit status and its standard output as
# raw bytes, or NULL when git is not on the PATH. This is the one place
# where the package starts a process.
git_run <- function(args, dir) {
  if (!nzchar(Sys.which("git"))) {
    return(NULL)
  }
  out <- git_out_file()
  # expand = FALSE, so that `[`, `*`, or `?` in the temporary folder's path
  # does not match another file.
  on.exit(unlink(out, expand = FALSE))
  owd <- setwd(dir)
  on.exit(setwd(owd), add = TRUE)
  status <- suppressWarnings(system2("git", args, stdout = out, stderr = FALSE))
  bytes <- if (file.exists(out)) readBin(out, "raw", file.size(out)) else raw()
  list(status = status, stdout = bytes)
}

# The temporary file that holds git's standard output.
git_out_file <- function() tempfile("git-")

# The files in `path` that git tracks or does not ignore, as paths relative to
# `path`, or NULL with the reason when git cannot list them.
git_files <- function(path) {
  version <- git_run("--version", path)
  if (is.null(version)) {
    return(list(reason = "git is not on the PATH"))
  }
  if (!identical(version$status, 0L)) {
    return(list(reason = "`git --version` failed"))
  }
  tree <- git_run(c("rev-parse", "--is-inside-work-tree"), path)
  if (!identical(tree$status, 0L) || !identical(trimws(rawToChar(tree$stdout)), "true")) {
    return(list(reason = "`git rev-parse` failed, or the folder is not in a git work tree"))
  }
  # -z prints each name as it is, ended by a NUL byte. Without it, git
  # quotes names with non-ASCII characters.
  listed <- git_run(c("ls-files", "-z", "--cached", "--others", "--exclude-standard"), path)
  if (!identical(listed$status, 0L)) {
    return(list(reason = "`git ls-files` failed"))
  }
  list(files = unique(split_nul(listed$stdout)))
}

# Split raw bytes at each NUL byte into UTF-8 strings.
split_nul <- function(bytes) {
  ends <- which(bytes == as.raw(0))
  if (length(ends) == 0) {
    return(character())
  }
  starts <- c(1L, ends[-length(ends)] + 1L)
  names <- vapply(seq_along(ends), function(i) {
    x <- rawToChar(bytes[seq.int(starts[i], length.out = ends[i] - starts[i])])
    Encoding(x) <- "UTF-8"
    x
  }, character(1))
  names[nzchar(names)]
}

# Strings marked as UTF-8, with each byte that is not valid UTF-8 shown as
# <xx>.
show_text <- function(x) {
  Encoding(x) <- "UTF-8"
  bad <- !validUTF8(x)
  x[bad] <- iconv(x[bad], "UTF-8", "UTF-8", sub = "byte")
  x
}

# The text of a file as UTF-8, with NUL bytes dropped and bytes that are
# not valid UTF-8 shown as <xx>, or NULL when it cannot be read.
read_page_text <- function(file) {
  bytes <- tryCatch(readBin(file, "raw", file.size(file)), error = function(e) NULL,
                    warning = function(w) NULL)
  if (is.null(bytes)) {
    return(NULL)
  }
  show_text(rawToChar(bytes[bytes != as.raw(0)]))
}

# GitHub blocks files larger than 100 MiB:
# https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github
github_file_limit <- 104857600

check_git_files <- function(path, files) {
  full <- file.path(path, files)
  # git can list a name that is not valid UTF-8 from its index, and on
  # Windows file.info() stops on such a name.
  readable <- .Platform$OS.type != "windows" | validUTF8(full)
  size <- rep(NA_real_, length(full))
  size[readable] <- file.info(full[readable], extra_cols = FALSE)$size
  large <- !is.na(size) & size > github_file_limit
  large[large] <- !is_link(full[large])
  # useBytes keeps a name that is not valid UTF-8 in the match.
  saved <- grepl("\\.(rds|rda|rdata|qs|qs2)$", files, ignore.case = TRUE, useBytes = TRUE)
  shown <- show_text(files)
  rbind(
    problem_rows(
      "large-file", shown[large],
      sprintf("%s bytes is more than GitHub's limit of 104,857,600 bytes (100 MiB) for one file.",
              format(size[large], big.mark = ",", scientific = FALSE, trim = TRUE))
    ),
    problem_rows(
      "saved-object", shown[saved],
      rep_len("A saved R object can hold the data. Remove it from git or add it to .gitignore.", sum(saved))
    )
  )
}

# Stored output ---------------------------------------------------------------

# The start of a code chunk, as Quarto's chunk scan (quarto.js 1.10.19,
# languagesWithClasses()) reads it: any mix of spaces, tabs, and `>`, three
# or more backticks, then a name in braces. Quarto starts an engine for every
# name but ojs, mermaid, and dot, in any letter case. The letter case is
# spelled out, because `(?i)` with useBytes follows the locale.
not_engine <- "([Oo][Jj][Ss]|[Mm][Ee][Rr][Mm][Aa][Ii][Dd]|[Dd][Oo][Tt])(?![A-Za-z0-9_.])"
chunk_start <- paste0(
  "^[ \\t>]*`{3,}[ \\t]*\\{(?!", not_engine, ")",
  "[A-Za-z][A-Za-z0-9_.]*+[^}]*\\}[ \\t]*\\z"
)

# Inline R code that knitr runs: `r code`, `r#code`, or Quarto's `{r} code`.
inline_r <- "`(r[ #]|\\{r\\} )[^`]+`"

# The lines of a report, split at LF, CR LF, or CR. A nul byte is read as
# the byte 0x01, which, like a nul in Quarto's chunk scan, is no character
# that the chunk and inline patterns name, so a nul inside the braces of a
# chunk start keeps the match and one before or after it ends the match.
# readLines() would cut each line at its nul. A report that cannot be read,
# such as a link whose target is missing, has no lines.
read_report_lines <- function(report) {
  bytes <- tryCatch(readBin(report, "raw", n = file.size(report)),
                    error = function(e) raw(), warning = function(w) raw())
  bytes[bytes == as.raw(0)] <- as.raw(1)
  lines <- strsplit(rawToChar(bytes), "\r\n|\r|\n", perl = TRUE, useBytes = TRUE)[[1]]
  Encoding(lines) <- "UTF-8"
  lines
}

# TRUE when the report's front matter is a YAML map whose top-level
# `engine` is the text "knitr". The front matter starts at a first `---`
# line that only blank lines come before and that a line that is not blank
# follows, and it ends at the next `---` or `...` line. Quarto also accepts
# an indented first `---`; this check needs `---` at the start of its line.
engine_is_knitr <- function(lines) {
  blank <- grepl("^[ \\t]*\\z", lines, perl = TRUE, useBytes = TRUE)
  first <- which(!blank)[1]
  if (is.na(first) || !grepl("^---[ \\t]*\\z", lines[first], perl = TRUE, useBytes = TRUE) ||
      first == length(lines) || blank[first + 1]) {
    return(FALSE)
  }
  ends <- which(grepl("^(---|\\.\\.\\.)[ \\t]*\\z", lines, perl = TRUE, useBytes = TRUE))
  last <- ends[ends > first][1]
  if (is.na(last) || last == first + 1) {
    return(FALSE)
  }
  # yaml_read_lines() keeps sequences as lists, so `engine: [knitr]` is not
  # the text, and gives NULL for front matter that does not parse.
  front <- suppressWarnings(yaml_read_lines(lines[seq.int(first + 1, last - 1)]))
  is.list(front) && !is.null(names(front)) && identical(front[["engine"]], "knitr")
}

check_stored_output <- function(path) {
  # The files that the glob analyses/*.qmd matches in the site. A glob over
  # the whole path would read `[`, `*`, or `?` in the site's own path as a
  # pattern, so list the folder instead. Like a glob, `*` skips names that
  # start with a dot.
  dir <- file.path(path, "analyses")
  names <- list.files(dir, pattern = "\\.qmd$")
  reports <- file.path(dir, names[!startsWith(names, ".")])
  reports <- reports[!dir.exists(reports)]
  missing <- vapply(reports, function(report) {
    lines <- read_report_lines(report)
    has_code <- any(grepl(chunk_start, lines, perl = TRUE, useBytes = TRUE)) ||
      (any(grepl(inline_r, lines, perl = TRUE, useBytes = TRUE)) && engine_is_knitr(lines))
    name <- sub("\\.qmd$", "", basename(report))
    # Hidden files such as .DS_Store are not stored output.
    stored <- list.files(file.path(path, "_freeze", "analyses", name, "execute-results"),
                         recursive = TRUE)
    has_code && length(stored) == 0
  }, logical(1))
  files <- file.path("analyses", basename(reports[missing]))
  problem_rows(
    "no-stored-output", files,
    rep_len("The report has code and no stored output in _freeze/. Render it by name, then commit _freeze/.",
            length(files))
  )
}

# Links -----------------------------------------------------------------------

check_links <- function(path) {
  docs <- file.path(path, "docs")
  if (!dir.exists(docs)) {
    return(problem_rows("not-rendered", "docs", "The site has no docs/ folder. Render the site."))
  }
  entries <- docs_entries(docs)
  root <- docs_root(docs)
  outside <- outside_links(root, entries$links)
  # A page that a link outside docs/ points to is not in the published
  # site, so it is not read.
  # useBytes keeps a name that is not valid UTF-8 in the match.
  html <- grepl("\\.html$", entries$files, useBytes = TRUE)
  # The walk lists a folder's files before its subfolders, so sort the
  # pages by path, in byte order, which does not depend on the locale.
  # The radix sort stops on a name with no encoding mark that is not valid
  # UTF-8, so the sort keys are marked as bytes.
  pages <- entries$files[html & !(entries$files %in% outside)]
  keys <- pages
  Encoding(keys) <- "bytes"
  pages <- pages[order(keys, method = "radix")]
  rows <- lapply(pages, function(page) {
    links <- page_links(file.path(docs, page))
    if (is.null(links)) {
      return(problem_rows(
        "broken-link", file.path("docs", page),
        "The page cannot be read, or it is a link to a missing file."
      ))
    }
    if (isFALSE(links)) {
      return(problem_rows(
        "broken-link", file.path("docs", page),
        "The link check cannot read this page: its markup goes past the limits of the PCRE pattern engine."
      ))
    }
    # With no link in docs/, no part of a path can resolve outside it, so
    # link_ok() skips that test.
    broken <- links[!vapply(links, link_ok, logical(1), docs = docs, page = page,
                            root = if (length(entries$links) > 0) root)]
    problem_rows(
      "broken-link", rep_len(file.path("docs", page), length(broken)),
      sprintf("The page links to a file that is not in the site: `%s`", broken)
    )
  })
  keys <- outside
  Encoding(keys) <- "bytes"
  outside <- outside[order(keys, method = "radix")]
  outside_rows <- problem_rows(
    "broken-link", file.path("docs", outside),
    rep_len("It is a link to a place outside docs/, so the published site does not have its target.",
            length(outside))
  )
  do.call(rbind, c(list(outside_rows), rows))
}

# The files in `docs`, hidden ones included, and its links (symbolic links,
# and on Windows junctions), as paths relative to `docs`. A linked folder is
# listed as a link and not entered, so a link loop is read once, and the
# pages in a folder that a link inside docs/ points to are read at their
# own path.
docs_entries <- function(docs) {
  files <- character()
  links <- character()
  queue <- ""
  while (length(queue) > 0) {
    rel <- queue[1]
    queue <- queue[-1]
    names <- list.files(if (nzchar(rel)) file.path(docs, rel) else docs, all.files = TRUE, no.. = TRUE)
    paths <- if (nzchar(rel)) file.path(rel, names) else names
    full <- file.path(docs, paths)
    link <- is_link(full)
    folder <- dir.exists(full)
    links <- c(links, paths[link])
    files <- c(files, paths[!folder])
    queue <- c(queue, paths[folder & !link])
  }
  list(files = files, links = links)
}

# The normalized path of `docs`. A drive root keeps its separator ("D:/"),
# so it is dropped before a join.
docs_root <- function(docs) {
  sub("/+$", "", normalizePath(docs, winslash = "/", mustWork = FALSE))
}

# The links among `links` (paths relative to docs/) whose target exists
# and resolves to a place outside `root`, the normalized docs/ path. A link
# whose target is missing is left to the other link checks.
outside_links <- function(root, links) {
  full <- file.path(root, links)
  links[file.exists(full) & !in_docs(full, root)]
}

# TRUE for each path that resolves to `root` (the normalized docs/ path)
# or to a place under it. Each path starts with `root`, so a path that
# normalizePath() cannot resolve stays under it and counts as inside. On
# Windows, letter case is ignored, as in is_reparse_point().
in_docs <- function(paths, root) {
  resolved <- normalizePath(paths, winslash = "/", mustWork = FALSE)
  if (.Platform$OS.type == "windows") {
    root <- utf8_lower(root)
    resolved <- utf8_lower(resolved)
  }
  resolved == root | startsWith(resolved, paste0(root, "/"))
}

# tolower() for each string that is valid UTF-8. tolower() stops on a
# string that is not, so such a string stays as it is.
utf8_lower <- function(x) {
  valid <- validUTF8(x)
  x[valid] <- tolower(x[valid])
  x
}

# The href, src, and xlink:href values on a page that point to a place
# inside the site, each once, or NULL when the page cannot be read, such
# as a link whose target is missing. It is FALSE after a warning from
# tag_links(), such as a PCRE match limit, which makes gsub() return its
# input unchanged.
page_links <- function(file) {
  html <- read_page_text(file)
  if (is.null(html)) {
    return(NULL)
  }
  links <- tryCatch(tag_links(html), warning = function(w) FALSE)
  if (isFALSE(links)) {
    return(FALSE)
  }
  values <- decode_refs(unique(links))
  # A browser trims spaces and control characters from the ends of a
  # link; here only spaces, tabs, line breaks, and form feeds are trimmed.
  # Tabs and line breaks inside a link are dropped, as the URL standard's
  # parser does.
  values <- gsub("^[\t\n\f\r ]+|[\t\n\f\r ]+$", "", values, perl = TRUE)
  values <- gsub("[\t\n\r]", "", values)
  skip <- !nzchar(values) | grepl("^([A-Za-z][A-Za-z0-9+.-]*:|/|#)", values)
  unique(values[!skip])
}

# Parts of the patterns that read start tags, after the HTML standard's
# tokenizer: an attribute name runs to a space, `/`, `>`, or `=`, and an
# unquoted value runs to a space or `>`.
# Every repeat in the html_* parts and in the `skipped` pattern of
# tag_links() is possessive (`*+`, `++`), so PCRE never backtracks into it
# and the time stays linear. PCRE's match limit counts the steps of one
# match, so a comment that holds millions of `-`, a script, style,
# textarea, or title body that holds millions of `<`, or one tag with
# millions of attributes can still reach it (about 5 million `<` in one
# script body did); page_links() then returns FALSE.
html_space <- "[\t\n\f\r ]"
html_attr <- paste0(
  "[^\t\n\f\r />][^\t\n\f\r />=]*+",
  "(?:", html_space, "*+=", html_space, "*+(?:\"[^\"]*+\"|'[^']*+'|[^\t\n\f\r >]*+))?+"
)
# The rest of a start tag after its name: attributes and the spaces or `/`
# between them, then `>`. A `>` inside a quoted value does not end the tag.
# A tag can also run to the end of the page, so a `<` that no `>` follows
# is matched once, not again from each later `<`; tag_links() drops it.
html_tag_rest <- paste0("(?:[\t\n\f\r /]++|", html_attr, ")*+(?:>|\\z)")
html_start_tag <- paste0("<[A-Za-z][^\t\n\f\r />]*+", html_tag_rest)

# A pattern that matches `word` in any ASCII letter case, such as
# `[Tt][Ii][Tt][Ll][Ee]`. PCRE's `(?i)` on bytes, and toupper() and
# tolower(), follow the locale, where `i` and `I` need not pair (Turkish).
ascii_any_case <- function(word) {
  chars <- strsplit(word, "", fixed = TRUE)[[1]]
  upper <- chartr("abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZ", chars)
  paste0("[", upper, chars, "]", collapse = "")
}

ascii_lower <- function(x) chartr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz", x)

# One script, style, textarea, or title element: its start tag (kept, in a
# capture group), then its text up to its end tag or the end of the page.
html_raw_text <- function(name) {
  name <- ascii_any_case(name)
  end <- paste0("/", name, "(?=[\t\n\f\r />])")
  paste0(
    "(<", name, "(?=[\t\n\f\r />])", html_tag_rest, ")",
    "[^<]*+(?:<(?!", end, ")[^<]*+)*+",
    "(?:<", end, "[^>]*+(?:>|\\z))?+"
  )
}

# Comments, `<!...>` and `<?...>` markup, the four raw-text elements (groups
# 1 to 4 keep their start tags), and other start tags (group 5).
html_skipped <- paste0(
  "<!--[^-]*+(?:-(?!->)[^-]*+)*+(?:-->|\\z)|<[!?][^>]*+(?:>|\\z)|",
  paste(vapply(c("script", "style", "textarea", "title"), html_raw_text, character(1)), collapse = "|"),
  "|(", html_start_tag, ")"
)

# The raw values of the href, src, and xlink:href attributes in the start
# tags of `html`. Comments, `<!...>` and `<?...>` markup, and the text of
# script, style, textarea, and title elements are not read, as a browser
# reads no tags there. Each start tag is kept, so `<script src>` is read.
# A start tag that the end of the page cuts off is not read, as a browser
# drops it. A quote that never closes is read as the start of an unquoted
# value instead, so that tag ends at the next `>` and is read.
tag_links <- function(html) {
  # The page is matched as bytes. Without useBytes, R turns the byte
  # offset of each match into a character offset when the text holds a
  # non-ASCII character, at a cost that grows with the offset, so a page
  # with many tags took time that grew with the square of their count.
  # Bytes are safe here because read_page_text() returns valid UTF-8 and
  # every delimiter in these patterns is ASCII. The results are marked
  # UTF-8 again, since strings marked "bytes" make file.path() and
  # sprintf() stop.
  # Each kept start tag, and each removed part, is followed by a space, so
  # a `<` in the text before a removed comment cannot join the text after
  # it into a new tag.
  html <- gsub(html_skipped, "\\1\\2\\3\\4\\5 ", html, perl = TRUE, useBytes = TRUE)
  Encoding(html) <- "UTF-8"
  tags <- regmatches(html, gregexpr(html_start_tag, html, perl = TRUE, useBytes = TRUE))[[1]]
  Encoding(tags) <- "UTF-8"
  # No unquoted value or name holds `>`, so a tag that ends with `>`
  # closed before the end of the page. Tags with no href or src are not
  # parsed further.
  tags <- tags[endsWith(tags, ">") & grepl("[Hh][Rr][Ee][Ff]|[Ss][Rr][Cc]", tags)]
  rests <- sub("^<[^\t\n\f\r />]*", "", tags)
  attrs <- unlist(regmatches(rests, gregexpr(html_attr, rests, perl = TRUE)))
  attr_names <- ascii_lower(sub("(?s)^([^=\t\n\f\r ]*).*", "\\1", attrs, perl = TRUE))
  links <- attrs[attr_names %in% c("href", "src", "xlink:href")]
  # An attribute with no `=`, such as `<a href>`, has an empty value.
  links <- links[grepl("=", links, fixed = TRUE)]
  values <- sub(paste0("(?s)^[^=]*=", html_space, "*"), "", links, perl = TRUE)
  sub("(?s)^([\"'])(.*)\\1$", "\\2", values, perl = TRUE)
}

# Decode the character references `&amp;`, `&lt;`, `&gt;`, `&quot;`, and
# `&apos;`, and number references (`&#38;`, `&#x26;`) with a `;` that name
# a code point from 1 to 0x10FFFF, other than a surrogate or 128 to 159.
# Every other reference stays as written.
decode_refs <- function(x) {
  pattern <- "&(?:amp|lt|gt|quot|apos);|&#[0-9]+;|&#[xX][0-9A-Fa-f]+;"
  refs <- regmatches(x, gregexpr(pattern, x, perl = TRUE))
  regmatches(x, gregexpr(pattern, x, perl = TRUE)) <- lapply(refs, function(ref) {
    named <- c("&amp;" = "&", "&lt;" = "<", "&gt;" = ">", "&quot;" = "\"", "&apos;" = "'")
    vapply(ref, function(r) {
      if (r %in% names(named)) {
        return(named[[r]])
      }
      hex <- grepl("^&#[xX]", r)
      digits <- sub("^&#[xX]?0*([0-9A-Fa-f]*);$", "\\1", r)
      # More than 7 digits is above 0x10FFFF in either base.
      code <- if (nchar(digits) > 7) NA else strtoi(if (nzchar(digits)) digits else "0", if (hex) 16L else 10L)
      if (is.na(code) || code < 1 || code > 0x10FFFF || (code >= 0xD800 && code <= 0xDFFF) ||
          (code >= 128 && code <= 159)) {
        return(r)
      }
      intToUtf8(code)
    }, character(1), USE.NAMES = FALSE)
  })
  x
}

# TRUE when a relative link on `page` (a path inside `docs`) reaches a file
# in `docs`, or a folder there with an index.html, and no part of its path
# resolves to a place outside `docs`. `root` is the normalized path of
# `docs` (docs_root()), or NULL to skip the test of the path's parts.
link_ok <- function(link, docs, page, root = docs_root(docs)) {
  target <- sub("[?#].*$", "", link)
  if (!nzchar(target)) {
    return(TRUE)
  }
  # Split at `/` before decoding, so that `%2F` is not taken as a folder
  # separator. No file name can hold `/`, so such a link counts as broken.
  decoded <- vapply(strsplit(target, "/", fixed = TRUE)[[1]], percent_decode, character(1))
  if (anyNA(decoded) || any(grepl("/", decoded, fixed = TRUE))) {
    return(FALSE)
  }
  # A link that ends with `/` must reach a folder.
  wants_folder <- endsWith(target, "/")
  parts <- c(strsplit(dirname(page), "/", fixed = TRUE)[[1]], decoded)
  kept <- character()
  for (part in parts) {
    if (part %in% c("", ".")) next
    if (part == "..") {
      if (length(kept) == 0) {
        return(FALSE)
      }
      kept <- kept[-length(kept)]
    } else {
      kept <- c(kept, part)
    }
  }
  if (dir.exists(file.path(docs, paste(kept, collapse = "/")))) {
    kept <- c(kept, "index.html")
  } else if (wants_folder) {
    return(FALSE)
  }
  # A path that passes through or ends at a link to a place outside docs/
  # is not in the published site. The index.html of a folder link counts.
  # This also finds a link inside docs/ that a linked folder there leads to.
  if (!is.null(root)) {
    prefixes <- file.path(root, vapply(seq_along(kept), function(i) paste(kept[seq_len(i)], collapse = "/"),
                                       character(1)))
    present <- file.exists(prefixes)
    if (!all(in_docs(prefixes[present], root))) {
      return(FALSE)
    }
  }
  # GitHub Pages matches letter case, so each part must match the name on
  # disk, also on a disk that ignores case.
  dir <- docs
  for (part in kept) {
    if (!exact_name(dir, part)) {
      return(FALSE)
    }
    dir <- file.path(dir, part)
  }
  TRUE
}

# TRUE when `dir` holds `name`. On a disk that ignores letter case,
# file.exists() also finds `Name`, so a name that differs only in case
# from every entry of `dir` counts as missing. A name that differs in
# another way, such as Unicode normalization, is taken as found.
exact_name <- function(dir, name) {
  path <- file.path(dir, name)
  if (!file.exists(path)) {
    return(FALSE)
  }
  entries <- list.files(dir, all.files = TRUE, no.. = TRUE)
  name %in% entries || !(tolower(name) %in% tolower(entries))
}

# Decode %XX escapes, or return NA when the result holds a NUL byte or is
# not valid UTF-8. No file name holds a NUL byte, and a name that is not
# valid UTF-8 cannot match a file on a disk that needs UTF-8 names, such
# as macOS. On Linux such a link counts as broken even when the file
# exists.
percent_decode <- function(x) {
  if (!grepl("%[0-9A-Fa-f]{2}", x, useBytes = TRUE)) {
    return(x)
  }
  bytes <- charToRaw(x)
  out <- raw()
  i <- 1L
  while (i <= length(bytes)) {
    hex <- if (i + 2L <= length(bytes)) rawToChar(bytes[(i + 1L):(i + 2L)]) else ""
    # useBytes, because `hex` can hold half of a UTF-8 character.
    if (bytes[i] == charToRaw("%") && grepl("^[0-9A-Fa-f]{2}$", hex, useBytes = TRUE)) {
      out <- c(out, as.raw(strtoi(hex, 16L)))
      i <- i + 3L
    } else {
      out <- c(out, bytes[i])
      i <- i + 1L
    }
  }
  if (any(out == as.raw(0))) {
    return(NA_character_)
  }
  x <- rawToChar(out)
  Encoding(x) <- "UTF-8"
  if (!validUTF8(x)) NA_character_ else x
}

# DOIs ------------------------------------------------------------------------

check_dois <- function(path, meta, call = parent.frame()) {
  zenodo <- map_field(meta, "zenodo", call = call)
  yml <- lapply(c(version = "version-doi", concept = "concept-doi"), function(key) {
    field <- paste0("supplement.zenodo.", key)
    bare_doi(value(zenodo[[key]], field, call = call), field, call = call)
  })
  cite_doi <- yml$concept %||% yml$version
  badge_doi <- yml$version %||% yml$concept

  rows <- list(problem_rows())
  cff <- file.path(path, "CITATION.cff")
  # path_occupied() also finds a link whose target is missing.
  if (path_occupied(cff) && !dir.exists(cff)) {
    rows <- c(rows, list(check_cff_doi(cff, cite_doi)))
  }
  index <- file.path(path, "docs", "index.html")
  if (file.exists(index) && !dir.exists(index)) {
    rows <- c(rows, list(check_badge_doi(path, index, badge_doi)))
  }
  do.call(rbind, rows)
}

check_cff_doi <- function(cff, expected) {
  # read_page_text() returns NULL for a file that cannot be read, such as a
  # link to a missing file. Read every sequence as a list, as
  # read_supplement() does, so that `doi: [x]` is not one text value. A
  # warning, such as for a large number, does not make the file unreadable.
  text <- read_page_text(cff)
  doc <- if (!is.null(text)) {
    tryCatch(
      suppressWarnings(yaml_load_list(text)),
      error = function(e) NULL
    )
  }
  if (!is_map(doc)) {
    return(problem_rows(
      "doi-mismatch", "CITATION.cff",
      "It cannot be read, or it is not a YAML map. Run write_citation(overwrite = TRUE)."
    ))
  }
  doi <- doc[["doi"]]
  if (!is.null(doi) && (!is.character(doi) || length(doi) != 1)) {
    return(problem_rows("doi-mismatch", "CITATION.cff", "Its doi is not one text value."))
  }
  # As value() does for _supplement.yml, so that a block-scalar doi loses
  # its final line break.
  if (!is.null(doi)) {
    doi <- clean_space(doi)
    if (is.na(doi) || !nzchar(doi)) doi <- NULL
  }
  if (!is.null(doi)) {
    bare <- doi_or_null(doi)
    if (is.null(bare)) {
      return(problem_rows(
        "doi-mismatch", "CITATION.cff",
        sprintf("Its doi is not a DOI: %s. Run write_citation(overwrite = TRUE).", doi)
      ))
    }
    doi <- bare
  }
  if (same_doi(doi, expected)) {
    return(problem_rows())
  }
  problem_rows(
    "doi-mismatch", "CITATION.cff",
    sprintf("Its DOI is %s, and _supplement.yml gives %s. Run write_citation(overwrite = TRUE).",
            doi %||% "missing", expected %||% "none")
  )
}

check_badge_doi <- function(path, index, expected) {
  html <- read_page_text(index)
  if (is.null(html)) {
    return(problem_rows())
  }
  ids <- regmatches(html, gregexpr("https://zenodo\\.org/badge/DOI/([^\"'<>[:space:]]+?)\\.svg", html, perl = TRUE))[[1]]
  ids <- unique(sub("^https://zenodo\\.org/badge/DOI/(.*)\\.svg$", "\\1", ids))
  bare <- lapply(ids, doi_or_null)
  if (length(ids) == 0) {
    if (!is.null(expected) && uses_doi_shortcode(file.path(path, "index.qmd"))) {
      return(problem_rows(
        "doi-mismatch", "docs/index.html",
        sprintf("The home page shows no DOI badge, and _supplement.yml gives %s. Render the site again.", expected)
      ))
    }
    return(problem_rows())
  }
  # The DOIs in _supplement.yml passed bare_doi() already, so a badge that
  # is not a DOI comes from an old render or from HTML written by hand.
  invalid <- vapply(bare, is.null, logical(1))
  valid <- unlist(bare[!invalid])
  wrong <- unique(valid[!vapply(valid, same_doi, logical(1), expected = expected)])
  rbind(
    problem_rows(
      "doi-mismatch", rep_len("docs/index.html", sum(invalid)),
      sprintf("The DOI badge shows %s, which is not a DOI. Render the site again.", ids[invalid])
    ),
    problem_rows(
      "doi-mismatch", rep_len("docs/index.html", length(wrong)),
      sprintf("The DOI badge shows %s, and _supplement.yml gives %s. Render the site again.",
              wrong, expected %||% "none")
    )
  )
}

# The DOI from bare_doi(), or NULL when it is not a DOI, so that a bad DOI
# outside _supplement.yml gives a row and not an error.
doi_or_null <- function(doi) {
  tryCatch(bare_doi(doi, "doi"), supplement_error_doi = function(e) NULL)
}

same_doi <- function(doi, expected) {
  identical(tolower(doi %||% ""), tolower(expected %||% ""))
}

uses_doi_shortcode <- function(file) {
  if (!file.exists(file) || dir.exists(file)) {
    return(FALSE)
  }
  lines <- tryCatch(readLines(file, warn = FALSE, encoding = "UTF-8"),
                    error = function(e) character(), warning = function(w) character())
  any(grepl("\\{\\{<\\s*supplement-doi(\\s|>)", lines, perl = TRUE, useBytes = TRUE))
}
