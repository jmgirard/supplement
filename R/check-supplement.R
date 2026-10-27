#' Check a supplement site before a release
#'
#' `check_supplement()` looks for problems that can break a release of a
#' site, publish files that must stay private, or publish the template's
#' placeholder values in place of the author's. It changes no file. It
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
#' * `"ignored-output"`: a file that git ignores in `figures/`, `docs/`, or
#'   `_freeze/`, so that a release leaves it out of the published site. The
#'   check takes each regular file in these folders, and in the folders in
#'   them, that is reached without passing through a symbolic link or, on
#'   Windows, a junction, and whose path holds no name that starts with
#'   `.`. The file gets a row when git neither tracks it nor lists it as
#'   untracked, because its ignore rules exclude it, such as a rule in
#'   `.gitignore` or `.git/info/exclude`. A file that git tracks gives no
#'   row, also when a rule matches it. The copy of a data file in
#'   `docs/data/` gets a row when a rule also matches the copy, as the
#'   template's rule for `.rds` files does. The problem text says to change
#'   the rule for a file that the site must publish, and to remove the
#'   source of a private file and render again.
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
#'   space, line breaks included, between the backticks and `{` and after
#'   `}`. It lets the text after the name run across lines, and it starts
#'   a line after U+2028 or U+2029. Such chunk starts are not found.
#'   A nul byte in a report counts as
#'   a character that is none of those this rule names.
#'   A report with no chunk that counts also has code when it has inline R code on
#'   one line and the top-level `engine` in its own front matter is
#'   `knitr`. Inline R code is a backtick, then `r` and a space or `#`, or
#'   `{r}` and a space, then text with no backtick, then a backtick. Inline
#'   code that spans lines is not found, nor is inline code with a tab
#'   after `{r}`, which knitr also runs. Nor is knitr that a `knitr` key,
#'   `execute: engine`, an included file, or `_metadata.yml` turns on.
#'   A report has no stored output when
#'   `_freeze/analyses/<name>/execute-results/` holds no file other than
#'   hidden files and the files in hidden folders.
#' * `"stale-output"`: a `.qmd` report directly in `analyses/`, from the
#'   same list of reports, whose stored output was made from other text than
#'   the report holds now. The check reads as JSON each file whose name ends
#'   in `.json` and does not start with `.`, directly in
#'   `_freeze/analyses/<name>/execute-results/`. Quarto writes the MD5 of
#'   the report's text there as the top-level `hash`. The report gets one
#'   row when such a `hash` is one text value that differs from the MD5 of
#'   the report's bytes with each CR LF pair read as LF. It also gets one
#'   row, which says that the source hash of its stored output cannot be
#'   read, when such a file does not parse, its top level is not an object,
#'   or its top-level `hash` is missing or is not one text value. When one
#'   file cannot be read and another differs, the one row has this text. A
#'   report that cannot be read, such as a link to a missing file, gives no
#'   row. Quarto 1.10.19 hashes only the report file, so a change in a file
#'   that the report includes, in `_quarto.yml` or `_metadata.yml`, or in
#'   the data gives no row. Reports in folders inside `analyses/` are not
#'   read. Quarto reads a report as UTF-8 and hashes each byte that is not
#'   valid UTF-8 as U+FFFD, so such a report gets a row after each render.
#'   The row names, by their paths from the site folder in byte order, each
#'   of these files whose `hash` differs, or in the "cannot be read" text
#'   only each file whose `hash` cannot be read. Each path stands between
#'   double quotes, with a `\` before each `\` and `"` in it, so that a name
#'   that holds a comma and a space reads as one file. The "cannot be read" text ends with
#'   the render steps and then a delete step. It says that if the row stays
#'   after the render steps, the files can be from a format that the report
#'   no longer renders, or damaged. Then it says to delete them, render the
#'   whole site, and commit the report with `_freeze/`, `docs/`, and
#'   `figures/`.
#'   Quarto keeps the file of a
#'   format that the report no longer renders, such as `docx.json`, with
#'   its old hash. So when every `hash` can be read and another of these
#'   files has a `hash` equal to that MD5 of the report, the row also says
#'   that the files that differ can be from a format that the report no
#'   longer renders. If so, delete them, render the whole site, and commit
#'   the report with `_freeze/`, `docs/`, and `figures/`. If not, follow
#'   the render steps that the row gives after the hint.
#' * `"stale-script"`: a `.qmd` report directly in `analyses/`, from the
#'   same list of reports, whose stored output was made with other text of
#'   `_scripts/report.R` than the site holds now. `print_environment()` in
#'   the template's `_scripts/report.R` ends the Computing environment
#'   section with the line `Shared report code: _scripts/report.R, MD5 `
#'   and the file's MD5, with each CR LF pair read as LF. The check reads
#'   the same `.json` files as the `"stale-output"` check. In the top-level
#'   `result.markdown` text of each, it finds that text and the 32
#'   characters after it, when they are lowercase hex. The report gets one
#'   row when one of these hashes differs from the MD5 of the site's
#'   `_scripts/report.R`, read the same way. The row names the files that
#'   hold a hash that differs, in the same way as the `"stale-output"` row,
#'   and gives the render steps. When another of these files holds at least
#'   one such hash and all of its hashes match, it also says that the files
#'   that differ can be from a format that the report no longer renders,
#'   with the same delete steps as the `"stale-output"` row. A report whose
#'   stored output holds no such hash gets no row, for example a report
#'   without the Computing
#'   environment section, or one rendered before the site had a
#'   `_scripts/report.R` that prints the line. A file that does not parse
#'   or has no `result.markdown` text holds no hash. Such a line anywhere in
#'   `result.markdown` counts, also one that the report prints from other
#'   text, such as the stored output of another report. A report that
#'   cannot be read, such as a link to a missing file, gives no row. When
#'   the site has no
#'   `_scripts/report.R` that can be read, for example when the file is
#'   missing, is a folder, is a link to a missing file, or cannot be opened,
#'   the check gives no row.
#'   The hash covers only `_scripts/report.R`, not files that it reads.
#' * `"leftover-output"`: a folder directly in `_freeze/analyses/`, whose
#'   name does not start with `.`, that no file or folder in `analyses/`
#'   names. A name in `analyses/` names the folder when, cut before its
#'   last `.` (the whole name when it holds no `.`), it equals the folder's
#'   name with letter case ignored: the case of ASCII letters always, and
#'   the case of other letters as `tolower()` reads it in the session's
#'   locale. In a name that is not valid UTF-8, only the case of ASCII
#'   letters is ignored. A name stored in another Unicode form, composed or
#'   decomposed, does not match. Quarto 1.10.19 keeps a report's folder
#'   after the report is deleted or renamed. The row says to delete the
#'   folder, render the whole site, and commit `_freeze/` and `docs/`, and
#'   for a deleted or renamed report also its old path and `_quarto.yml`.
#'   Folders inside subfolders of `_freeze/analyses/` and folders directly
#'   in `_freeze/` are not read. A file or folder in `analyses/` of the
#'   same name, such as `<name>.R`, hides a leftover folder. So does a
#'   report whose name differs only in letter case, as after a report is
#'   renamed only in letter case on Linux.
#' * `"missing-script"`: the site has no file `_scripts/report.R`, and a
#'   `.qmd` report directly in `analyses/`, from the same list of reports,
#'   names it. The template's example report and each report from
#'   [add_report()] read it. The file counts as missing when `file.exists()`
#'   is `FALSE` for it, when it is a folder, or when it is a link whose chain
#'   of links ends on a missing file, a folder, or a loop, or one that
#'   `fs::path_real()` cannot resolve. So a file link to a missing file
#'   counts as missing on Windows too, where `file.exists()` is `TRUE` for
#'   it. A link whose path is not valid UTF-8 counts as there. A report
#'   names the file when one of its lines holds `_scripts`, with no ASCII
#'   letter, digit, `_`, or `.` right before it, then a separator, then
#'   `report.R`, with no ASCII letter, digit, `_`, or `.` right after it.
#'   Each such `_scripts` on the line can start the match, so
#'   `_scripts_old/x and _scripts/report.R` names the file. The separator
#'   is `/`, `\`, or `\\`, or it is a `"` or `'`, a `,` with any spaces or
#'   tabs on each side, and a `"` or `'`, after an optional `/`, `\`, or
#'   `\\`. So `source(file.path(site, "_scripts", "report.R"), local = TRUE)`
#'   and `_scripts/report.R` name the file, and `_scripts_old/report.R`,
#'   `_scripts/old-report.R`, and `file.path("_scripts", "x", "report.R")`
#'   do not. A `.` right after `report.R`, as at the end of a sentence,
#'   stops the match. A line of prose or a comment also counts. One row
#'   names each such report by its path from the site folder, in byte order, between double quotes
#'   with a `\` before each `\` and `"` in it, and says to copy the
#'   template's file from
#'   `system.file("template", "_scripts", "report.R", package = "supplement")`
#'   and commit it. A site made before the template had the file gives no
#'   row when its reports do not name it. A line in a file that the report
#'   includes is not read, a line of another form, such as
#'   `source("report.R")` or a call that puts `_scripts` and `report.R` on
#'   two lines, does not count, and the letter case of both names must
#'   match. Reports in folders inside `analyses/` are not read, and a report
#'   that cannot be read, such as a link to a missing file, names nothing.
#'   On a disk that ignores letter case a file such as `_scripts/Report.R`
#'   reads as `_scripts/report.R`, so it gives no row there.
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
#'   `https:` are not checked here. Only the `"web-link"` check, with
#'   `web_links = TRUE`, requests web addresses. GitHub
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
#' * `"web-link"`: only with `web_links = TRUE`, a web address on a page in
#'   `docs/` that fails. The check reads the same pages and values as the
#'   `"broken-link"` check, in the same way, and keeps each value that
#'   starts with `http:` or `https:` in any letter case, with any `#` part
#'   removed. So the cases above where that check reads a page differently
#'   from a browser apply here too: a reference such as `&eacute;` stays as
#'   written, and the address is requested with it. A link that starts with
#'   `//` has no scheme and is not requested. A space in an address is sent
#'   as `%20`, as a browser sends it. A page that the `"broken-link"` check
#'   cannot read gives no `"web-link"` row. Each address is requested once
#'   (addresses that differ only in letter case count as two), one after
#'   another, with a HEAD request that follows redirects and waits up to 10
#'   seconds. A site with many addresses can take minutes.
#'   An address gets a row when the request fails, such as for an unknown
#'   host, a timeout, or a certificate error, or when the last response has
#'   a status of 400 or above. The row names
#'   the first page, in byte order of path, that links the address. For
#'   status 401, 403, 405, or 429, the row says that the server refused the
#'   check's request and that the link can still work in a browser, since
#'   some servers answer a script or a HEAD request that way.
#'   [release_supplement()] does not run this check, so its rows never
#'   stop a release.
#' * `"unpublished-figure"`: a paper figure that the last render did not
#'   copy into `docs/`. The check takes each regular file in `figures/`, and
#'   in the folders in it, that is reached without passing through a
#'   symbolic link or junction, and whose path holds no name that starts
#'   with `.`. The file gets a row when the same path under `docs/figures/`
#'   is not a regular file, or when the MD5 of its bytes differs. A render
#'   copies into `docs/figures/` the files that `figures/` holds when the
#'   render starts, so a figure saved under a new name or changed after the
#'   last render gets a row, and a full render or a render of a report by
#'   name clears it. Hidden files are not compared, though Quarto copies
#'   them too.
#' * `"doi-mismatch"`: the DOI in `CITATION.cff` differs from the one that
#'   [write_citation()] writes from `_supplement.yml`, or the DOI badge on
#'   `docs/index.html` differs from `zenodo.version-doi` (or
#'   `zenodo.concept-doi` when that is empty). A home page whose source uses
#'   `{{< supplement-doi >}}` but that shows no badge, while
#'   `_supplement.yml` has a DOI, also counts. So does a `CITATION.cff`
#'   that cannot be read or is not a YAML map (a link to a missing file
#'   included), and a DOI in `CITATION.cff` or on the badge that is not a
#'   DOI.
#' * `"placeholder"`: a template value that the author has not replaced, so
#'   that a release would archive it. The check compares the site with the
#'   template that the installed package holds:
#'   * `_supplement.yml` gets one row when `paper-title`, `citation`, or
#'     `contact` equals the template's value, or an `authors` entry has the
#'     `family` and `given` of a template author. Values are compared with
#'     each run of white space read as one space and the ends removed. A
#'     value that is not one text value does not count. The row names the
#'     fields.
#'   * `_quarto.yml` gets a row for the line
#'     `href: https://github.com/OWNER/REPO`, `index.qmd` for the line
#'     `## Before your first commit`, `LICENSE.md` and `LICENSE-CC-BY.md`
#'     for the line `Copyright (c) YEAR AUTHORS`, and `README.md`,
#'     `SUPPLEMENT.md`, and `_README.md` for the line
#'     `Website: https://OWNER.github.io/REPO/`. `SUPPLEMENT.md` is for
#'     a site made before the template's guide moved to `GUIDE.md`: when
#'     that site's first render found a `README.md`, it wrote the guide to
#'     `SUPPLEMENT.md`. Spaces, tabs, and a
#'     carriage return at the ends of a line are ignored. A file that is
#'     missing, a folder, not UTF-8 text, or that cannot be read gives no
#'     row.
#'   * `analyses/example.qmd` and `data/example.csv` each get a row when
#'     their text equals the template's copy. `analyses/example.qmd` also
#'     gets one when its text equals the example report of an earlier
#'     version of the template. The text counts as equal when it differs
#'     only by a UTF-8 byte order mark at its start, CR LF or CR line ends
#'     in place of LF, or no line break at its end, as an editor can save
#'     an unchanged file. A file that cannot be read gives no row.
#'
#'   Only a whole value or a whole line counts, so a value that keeps part
#'   of a placeholder, such as a citation with `(Year)` in it, gives no row.
#'   A site made from an older version of the template, whose placeholders
#'   differ from the installed ones, gives no row for them. The example
#'   report is the exception.
#'
#' The `"large-file"` and `"saved-object"` checks look at the files that git
#' tracks or does not ignore, which
#' `git ls-files --cached --others --exclude-standard` lists, so files that
#' `.gitignore` blocks are left out. The `"ignored-output"` check reads the
#' files that `git ls-files --others --ignored --exclude-standard` lists in
#' `figures/`, `docs/`, and `_freeze/`. For these three git checks the
#' function runs git only to read: `git --version`, `git rev-parse
#' --is-inside-work-tree`, and `git ls-files`. When git is not on the PATH,
#' one of these commands fails, or the folder is not in a git work tree,
#' it skips these three checks and says so.
#'
#' @param path The folder of the site.
#' @param web_links `TRUE` to also request each web address on the pages in
#'   `docs/` and give the `"web-link"` rows. This needs a network. The
#'   default, `FALSE`, makes no web request.
#'
#' @return A data frame with one row per problem and the character columns
#'   `check`, `file` (the path in the site), and `problem`, invisibly. It has
#'   zero rows when the function finds no problem. Its `skipped` attribute
#'   names the git checks (`"large-file"`, `"saved-object"`, and
#'   `"ignored-output"`) that did not run, and is empty when they ran.
#'
#' @section Errors:
#' The function stops with an error of class `supplement_error` and one of
#' these classes:
#'
#' * `supplement_error_argument`: `path` is not a single non-empty string,
#'   or `web_links` is not `TRUE` or `FALSE`.
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
#' # A new site has not been rendered, its example report has no stored
#' # output yet, and it still holds the template's placeholder values.
#' problems <- check_supplement(site)
#' problems$check
#' unlink(site, recursive = TRUE)
check_supplement <- function(path = ".", web_links = FALSE, renv_lock = FALSE) {
  check_path(path)
  if (!isTRUE(web_links) && !isFALSE(web_links)) {
    cli::cli_abort(
      "{.arg web_links} must be {.code TRUE} or {.code FALSE}.",
      class = c("supplement_error_argument", "supplement_error")
    )
  }
  if (!isTRUE(renv_lock) && !isFALSE(renv_lock)) {
    cli::cli_abort(
      "{.arg renv_lock} must be {.code TRUE} or {.code FALSE}.",
      class = c("supplement_error_argument", "supplement_error")
    )
  }
  path <- drop_trailing_sep(path)
  meta <- read_supplement(path)

  git <- git_files(path)
  rows <- list(
    if (!is.null(git$files)) check_git_files(path, git$files),
    if (!is.null(git$files)) check_ignored_output(path, git$ignored),
    check_stored_output(path),
    check_stale_output(path),
    check_stale_script(path),
    if (renv_lock) check_renv_lock(path),
    check_leftover_output(path),
    check_missing_script(path),
    check_links(path),
    if (web_links) check_web_links(path),
    check_unpublished_figures(path),
    check_dois(path, meta, call = environment()),
    check_placeholders(path, meta)
  )
  rows <- Filter(Negate(is.null), rows)
  result <- if (length(rows) > 0) do.call(rbind, rows) else problem_rows()
  rownames(result) <- NULL
  attr(result, "skipped") <- if (is.null(git$files)) git_checks else character()

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
      "Skipped the {.val {git_checks}} checks: {skip_reason}."
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
# raw bytes, or NULL when git is not on the PATH. This holds the package's
# one call of system2. Sys.which(), here and in the check_tools() lookups
# that create_supplement() also runs, starts a shell that runs `which` on
# Unix.
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

# The files in `path` that git tracks or does not ignore (`files`), and the
# files in figures/, docs/, and _freeze/ that it ignores (`ignored`), as
# paths relative to `path`, or the reason when git cannot list them.
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
  # The files that git neither tracks nor lists as untracked, because its
  # ignore rules exclude them. git lists each file in an ignored folder, and
  # lists a link as one entry without entering it. Read from git, and not
  # from a walk of the disk, because git on macOS, with the
  # core.precomposeUnicode setting that `git init` turns on there, lists a
  # name stored in decomposed Unicode form in its composed form.
  ignored <- git_run(c("ls-files", "-z", "--others", "--ignored", "--exclude-standard", "--",
                       published_folders), path)
  if (!identical(ignored$status, 0L)) {
    return(list(reason = "`git ls-files` failed"))
  }
  list(files = unique(split_nul(listed$stdout)), ignored = unique(split_nul(ignored$stdout)))
}

# The folders of the site that a release publishes as they are.
published_folders <- c("figures", "docs", "_freeze")

# The checks that need git's file list.
git_checks <- c("large-file", "saved-object", "ignored-output")

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

# The regular files in figures/, docs/, and _freeze/ that git ignores,
# from git_files(). A file whose path holds a name that starts with `.`,
# or that is or passes through a symbolic link or junction, gives no row.
check_ignored_output <- function(path, ignored) {
  # useBytes keeps a name that is not valid UTF-8 in the match.
  files <- ignored[grepl(paste0("^(", paste(published_folders, collapse = "|"), ")/"), ignored, useBytes = TRUE) &
                     !grepl("(^|/)\\.", ignored, useBytes = TRUE)]
  files <- files[plain_paths(path, files)]
  files <- files[!dir.exists(file.path(path, files))]
  shown <- show_text(sort_bytes(files))
  problem_rows(
    "ignored-output", shown,
    rep_len(paste("git ignores this file, so a release leaves it out of the published site.",
                  "If the site must publish it, change the ignore rule that matches it.",
                  "If it is private, such as a saved R object copied from data/, remove its source and render the site again."),
            length(shown))
  )
}

# TRUE for each of `files` (paths relative to `path`) when neither the file
# nor a folder on its path is a symbolic link or junction.
plain_paths <- function(path, files) {
  if (length(files) == 0) {
    return(logical())
  }
  # useBytes, because strsplit() warns on a name that is not valid UTF-8.
  parts <- lapply(strsplit(files, "/", fixed = TRUE, useBytes = TRUE), function(p) {
    Encoding(p) <- "UTF-8"
    p
  })
  prefixes <- lapply(parts, function(p) vapply(seq_along(p), function(i) paste(p[seq_len(i)], collapse = "/"),
                                                character(1)))
  all_prefixes <- unique(unlist(prefixes))
  linked <- all_prefixes[is_link(file.path(path, all_prefixes))]
  !vapply(prefixes, function(p) any(p %in% linked), logical(1))
}

# Strings in byte order, which does not depend on the locale.
sort_bytes <- function(x) {
  x[order_bytes(x)]
}

# The order of strings in bytes. The radix sort stops on a string with no
# encoding mark that is not valid UTF-8, so the sort keys are marked as
# bytes.
order_bytes <- function(x) {
  keys <- x
  Encoding(keys) <- "bytes"
  order(keys, method = "radix")
}

# Stored output ---------------------------------------------------------------

# The start of a code chunk, as Quarto's chunk scan (quarto.js 1.10.19,
# languagesWithClasses()) reads it: any mix of spaces, tabs, and `>`, three
# or more backticks, then a name in braces. When the front matter names no
# engine, Quarto starts one for every name but ojs, mermaid, and dot, in any
# letter case. The letter case is
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
# such as a link whose target is missing, or one too large for rawToChar()
# (2 GiB or more), has no lines.
read_report_lines <- function(report) {
  tryCatch({
    bytes <- readBin(report, "raw", n = file.size(report))
    bytes[bytes == as.raw(0)] <- as.raw(1)
    lines <- strsplit(rawToChar(bytes), "\r\n|\r|\n", perl = TRUE, useBytes = TRUE)[[1]]
    Encoding(lines) <- "UTF-8"
    lines
  }, error = function(e) character(), warning = function(w) character())
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

# The files that the glob analyses/*.qmd matches in the site. A glob over
# the whole path would read `[`, `*`, or `?` in the site's own path as a
# pattern, so list the folder instead. Like a glob, `*` skips names that
# start with a dot.
analysis_reports <- function(path) {
  dir <- file.path(path, "analyses")
  names <- list.files(dir, pattern = "\\.qmd$")
  reports <- file.path(dir, names[!startsWith(names, ".")])
  reports[!dir.exists(reports)]
}

# The steps that publish a changed report, as the publishing guide gives them.
rerender_steps <- paste("Render the report by name, render the whole site, then commit the report with",
                        "_freeze/, docs/, and figures/.")

check_stored_output <- function(path) {
  reports <- analysis_reports(path)
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
    rep_len(paste("The report has code and no stored output in _freeze/.", rerender_steps,
                  "If you added the report to the Analyses menu, as add_report() does, also commit _quarto.yml."),
            length(files))
  )
}

# Quarto 1.10.19 writes the MD5 of the report's text, with each CR LF read
# as LF, as the top-level `hash` of each execute-results/*.json file. The
# hash covers the report file alone, not the files it includes or the
# project's YAML files.
check_stale_output <- function(path) {
  reports <- analysis_reports(path)
  problem <- vapply(reports, function(report) {
    name <- sub("\\.qmd$", "", basename(report))
    dir <- file.path("_freeze", "analyses", name, "execute-results")
    files <- list.files(file.path(path, dir), pattern = "\\.json$")
    files <- files[!startsWith(files, ".") & !dir.exists(file.path(path, dir, files))]
    if (length(files) == 0) {
      return(NA_character_)
    }
    hash <- report_hash(report)
    if (is.null(hash)) {
      return(NA_character_)
    }
    stored <- lapply(file.path(path, dir, files), stored_hash)
    unreadable <- vapply(stored, is.null, logical(1))
    named <- function(hit) paste(quote_path(show_text(sort_bytes(file.path(dir, files[hit])))), collapse = ", ")
    if (any(unreadable)) {
      # Quarto keeps the file of a format that the report no longer
      # renders, so no render rewrites such a file.
      return(paste0("The source hash of its stored output cannot be read from ", named(unreadable), ". ",
                    rerender_steps, " If the row stays after these steps, these files can be from a format",
                    " that the report no longer renders, or damaged. Delete them, render the whole site,",
                    " and commit the report with _freeze/, docs/, and figures/."))
    }
    differs <- unlist(stored) != hash
    if (!any(differs)) {
      return(NA_character_)
    }
    stale <- paste0("Its stored output was made from other text than the report holds now: ", named(differs), ".")
    if (all(differs)) {
      return(paste(stale, rerender_steps))
    }
    # Quarto keeps the file of a format that the report no longer renders.
    paste(stale,
          "Other stored output of the report matches the report, so these files can be from a format that the",
          "report no longer renders. If so, delete them, render the whole site, and commit the report with",
          "_freeze/, docs/, and figures/.",
          "If not, take these steps.", rerender_steps)
  }, character(1), USE.NAMES = FALSE)
  hit <- !is.na(problem)
  problem_rows("stale-output", file.path("analyses", basename(reports[hit])), problem[hit])
}

# The text before the hash of `_scripts/report.R` that print_environment()
# in the template's report.R prints into the output of each report.
script_hash_text <- "Shared report code: _scripts/report.R, MD5 "

# A row for each report whose stored output names another hash of
# `_scripts/report.R` than the MD5 of the file now, with each CR LF read as
# LF. Stored output that names no hash gives no row.
check_stale_script <- function(path) {
  script <- file.path(path, "_scripts", "report.R")
  current <- if (file.exists(script) && !dir.exists(script)) report_hash(script)
  if (is.null(current)) {
    return(problem_rows())
  }
  reports <- analysis_reports(path)
  problem <- vapply(reports, function(report) {
    name <- sub("\\.qmd$", "", basename(report))
    dir <- file.path("_freeze", "analyses", name, "execute-results")
    files <- list.files(file.path(path, dir), pattern = "\\.json$")
    files <- files[!startsWith(files, ".") & !dir.exists(file.path(path, dir, files))]
    hashes <- lapply(file.path(path, dir, files), stored_script_hashes)
    differs <- vapply(hashes, function(x) any(x != current), logical(1))
    # A report that cannot be read, such as a link to a missing file,
    # cannot be rendered again, so it gets no row, as in check_stale_output().
    if (!any(differs) || is.null(report_hash(report))) {
      return(NA_character_)
    }
    named <- paste(quote_path(show_text(sort_bytes(file.path(dir, files[differs])))), collapse = ", ")
    stale <- paste0("Its stored output was made with other text of _scripts/report.R than the site holds now: ",
                    named, ".")
    matches <- vapply(hashes, function(x) length(x) > 0 && all(x == current), logical(1))
    if (!any(matches)) {
      return(paste(stale, rerender_steps))
    }
    # Quarto keeps the file of a format that the report no longer renders.
    paste(stale,
          "Other stored output of the report matches _scripts/report.R, so these files can be from a format",
          "that the report no longer renders. If so, delete them, render the whole site, and commit the report",
          "with _freeze/, docs/, and figures/.",
          "If not, take these steps.", rerender_steps)
  }, character(1), USE.NAMES = FALSE)
  hit <- !is.na(problem)
  problem_rows("stale-script", file.path("analyses", basename(reports[hit])), problem[hit])
}

# The hashes of `_scripts/report.R` that the top-level `result.markdown`
# of a stored output file names after `script_hash_text`, each 32
# characters in [0-9a-f]. A file that does not parse, or that has no such
# text value, names none. The search is for fixed text, so a long line
# does not reach PCRE's match limit.
stored_script_hashes <- function(file) {
  markdown <- stored_markdown(file)
  if (is.null(markdown)) {
    return(character())
  }
  at <- gregexpr(script_hash_text, markdown, fixed = TRUE)[[1]]
  if (at[1] == -1) {
    return(character())
  }
  start <- at + nchar(script_hash_text)
  hashes <- substring(markdown, start, start + 31)
  hashes[grepl("^[0-9a-f]{32}$", hashes)]
}

# renv.lock -------------------------------------------------------------------

# The rows of the renv.lock comparison. A site with no renv.lock gets a
# message and no row, and a renv.lock that cannot be read gets one row.
check_renv_lock <- function(path) {
  lock <- lock_versions(path)
  if (is.null(lock)) {
    cli::cli_alert_info("Skipped the {.val renv-mismatch} check: the site has no {.file renv.lock}.")
    return(problem_rows())
  }
  if (isFALSE(lock)) {
    return(problem_rows(
      "renv-mismatch", "renv.lock",
      paste("It cannot be read as an renv lockfile. It is a folder or a link to a missing file, or it is not",
            "UTF-8 text that holds a JSON object with a Packages object. Run renv::snapshot() to write it",
            "again, then commit it.")
    ))
  }
  problem_rows()
}

# The versions that the site's renv.lock records: NULL when the site has no
# renv.lock, FALSE when it cannot be read, and otherwise a list of `r`, the
# R version or NULL, and `packages`, a character vector of versions named
# by package. A package record with no `Version` text is left out.
lock_versions <- function(path) {
  file <- file.path(path, "renv.lock")
  if (!file.exists(file) && !is_link(file)) {
    return(NULL)
  }
  if (dir.exists(file)) {
    return(FALSE)
  }
  json <- tryCatch({
    bytes <- readBin(file, "raw", n = file.size(file))
    text <- rawToChar(bytes)
    if (!validUTF8(text)) stop("not UTF-8")
    jsonlite::parse_json(text, simplifyVector = FALSE)
  }, error = function(e) NULL, warning = function(w) NULL)
  packages <- if (is.list(json) && !is.null(names(json))) json[["Packages"]]
  if (!is.list(packages) || is.null(names(packages))) {
    return(FALSE)
  }
  version_text <- function(record) {
    version <- if (is.list(record) && !is.null(names(record))) record[["Version"]]
    if (is.character(version) && length(version) == 1 && !is.na(version)) version else NA_character_
  }
  versions <- vapply(packages, version_text, character(1))
  r <- version_text(json[["R"]])
  list(r = if (!is.na(r)) r, packages = versions[!is.na(versions) & nzchar(names(versions))])
}

# The R and package versions that print_environment() printed into stored
# output text, as a list of `r`, a character vector of R versions, and
# `packages`, a character vector of versions named by package. It reads the
# package table after a `─ Packages` or `- Packages` rule of
# sessioninfo::session_info() and its `version` setting line, and the
# `R version` line and the two package lists of utils::sessionInfo(). A
# line that holds an ANSI escape is not read. The patterns run on the first
# 200 characters of a line, so a long line does not reach PCRE's match
# limit.
stored_versions <- function(markdown) {
  lines <- strsplit(markdown, "\n", fixed = TRUE)[[1]]
  lines[grepl("\033", lines, fixed = TRUE)] <- ""
  head <- substr(lines, 1, 200)
  first_word <- function(x) sub(" .*$", "", sub("^ +", "", x))

  setting <- grepl("^ version +R version [^ ]", head)
  first <- grepl("^R version [^ ]", head)
  r <- c(first_word(sub("^ version +R version ", "", head[setting])),
         first_word(sub("^R version ", "", head[first])))

  packages <- character()
  rules <- which(startsWith(head, "─ Packages") | startsWith(head, "- Packages"))
  for (rule in rules[rules < length(head)]) {
    header <- head[rule + 1]
    if (!grepl("^ (! +)?package +\\* +version ", header)) next
    name_at <- regexpr("package", header, fixed = TRUE)
    version_at <- regexpr("version", header, fixed = TRUE)
    i <- rule + 2
    while (i <= length(head) && nzchar(head[i])) {
      name <- first_word(substring(head[i], name_at))
      version <- first_word(substring(head[i], version_at))
      if (grepl("^[A-Za-z][A-Za-z0-9.]*$", name) && nzchar(version)) {
        names(version) <- name
        packages <- c(packages, version)
      }
      i <- i + 1
    }
  }

  lists <- which(head == "other attached packages:" | head == "loaded via a namespace (and not attached):")
  for (start in lists) {
    i <- start + 1
    while (i <= length(head) && grepl("^ *\\[[0-9]+\\] ", head[i])) {
      words <- strsplit(lines[i], " ", fixed = TRUE)[[1]]
      words <- words[grepl("^[A-Za-z][A-Za-z0-9.]*_[^_]+$", words)]
      at <- regexpr("_", words, fixed = TRUE)
      versions <- substring(words, at + 1)
      names(versions) <- substring(words, 1, at - 1)
      packages <- c(packages, versions)
      i <- i + 1
    }
  }
  list(r = r, packages = packages)
}

# A path between double quotes, with `\` before each `\` and `"` in it, so
# that a name holding `, ` or `"` reads as one path in a list.
quote_path <- function(x) {
  paste0('"', gsub('(["\\\\])', "\\\\\\1", x), '"')
}

# Quarto 1.10.19 keeps a report's folder in _freeze/analyses/ after the
# report is deleted or renamed. A file or folder in analyses/ whose name,
# cut before its last `.`, equals the folder's name with letter case
# ignored keeps it: a report of any kind, or a folder of reports. Case is
# ignored because on a file system that ignores case, such as the macOS
# default, a report renamed only in case still writes to its old folder.
check_leftover_output <- function(path) {
  freeze <- file.path(path, "_freeze", "analyses")
  # list.files() leaves out names that start with `.`.
  folders <- list.files(freeze)
  folders <- folders[dir.exists(file.path(freeze, folders))]
  # useBytes keeps a name that is not valid UTF-8 in the match.
  stems <- sub("\\.[^.]*$", "", list.files(file.path(path, "analyses")), useBytes = TRUE)
  Encoding(stems) <- "unknown"
  leftover <- folders[!fold_case(folders) %in% fold_case(stems)]
  problem_rows(
    "leftover-output", file.path("_freeze", "analyses", leftover),
    rep_len(paste("No report in analyses/ has this stored output, as after a report is deleted or renamed.",
                  "Delete the folder, render the whole site, then commit _freeze/ and docs/.",
                  "If you deleted or renamed the report, also commit its old path and _quarto.yml,",
                  "which holds its menu item."),
            length(leftover))
  )
}

# Lower case: ASCII letters first, with chartr(), since tolower() follows
# the locale, where `I` need not lower to `i` (Turkish). tolower() stops on
# a name that is not valid UTF-8, so only the ASCII capitals of such a name
# are lowered, byte by byte.
fold_case <- function(x) {
  ok <- validUTF8(x)
  x[ok] <- tolower(ascii_lower(x[ok]))
  x[!ok] <- vapply(x[!ok], function(name) {
    bytes <- charToRaw(name)
    upper <- bytes >= as.raw(0x41) & bytes <= as.raw(0x5a)
    bytes[upper] <- as.raw(as.integer(bytes[upper]) + 32L)
    rawToChar(bytes)
  }, character(1), USE.NAMES = FALSE)
  x
}

# The MD5 of a report's bytes with each CR LF read as LF, or NULL when the
# report cannot be read, such as a link to a missing file.
report_hash <- function(report) {
  tryCatch({
    bytes <- readBin(report, "raw", n = file.size(report))
    n <- length(bytes)
    if (n > 1) {
      cr <- which(bytes[-n] == as.raw(13) & bytes[-1] == as.raw(10))
      if (length(cr) > 0) bytes <- bytes[-cr]
    }
    file <- tempfile("report-")
    on.exit(unlink(file, expand = FALSE))
    writeBin(bytes, file)
    unname(tools::md5sum(file))
  }, error = function(e) NULL, warning = function(w) NULL)
}

# The MD5 of a file's text as an editor may save it unchanged: a UTF-8 BOM
# at its start is dropped, each CR LF and then each lone CR is read as LF,
# and one LF at its end is dropped. NULL when the file cannot be read.
# Unlike `report_hash()`, this is not Quarto's hash.
text_hash <- function(path) {
  tryCatch({
    bytes <- readBin(path, "raw", n = file.size(path))
    if (length(bytes) >= 3 && identical(bytes[1:3], as.raw(c(0xef, 0xbb, 0xbf)))) {
      bytes <- bytes[-(1:3)]
    }
    n <- length(bytes)
    if (n > 1) {
      cr <- which(bytes[-n] == as.raw(13) & bytes[-1] == as.raw(10))
      if (length(cr) > 0) bytes <- bytes[-cr]
    }
    bytes[bytes == as.raw(13)] <- as.raw(10)
    n <- length(bytes)
    if (n > 0 && bytes[n] == as.raw(10)) bytes <- bytes[-n]
    file <- tempfile("text-")
    on.exit(unlink(file, expand = FALSE))
    writeBin(bytes, file)
    unname(tools::md5sum(file))
  }, error = function(e) NULL, warning = function(w) NULL)
}

# The top-level `hash` of a stored output file, or NULL when the file does
# not parse as JSON, its top level is not an object, or its `hash` is not
# one text value.
stored_hash <- function(file) {
  json <- stored_json(file)
  if (is.null(json)) {
    return(NULL)
  }
  hash <- json[["hash"]]
  if (!is.character(hash) || length(hash) != 1 || is.na(hash)) {
    return(NULL)
  }
  hash
}

# The top-level `result.markdown` text of a stored output file, or NULL
# when the file does not parse or has no such text value.
stored_markdown <- function(file) {
  json <- stored_json(file)
  result <- if (!is.null(json)) json[["result"]]
  if (!is.list(result) || is.null(names(result))) {
    return(NULL)
  }
  markdown <- result[["markdown"]]
  if (!is.character(markdown) || length(markdown) != 1 || is.na(markdown)) {
    return(NULL)
  }
  markdown
}

# A stored output file parsed as JSON, or NULL when it does not parse or
# its top level is not an object.
stored_json <- function(file) {
  json <- tryCatch({
    bytes <- readBin(file, "raw", n = file.size(file))
    jsonlite::parse_json(rawToChar(bytes), simplifyVector = FALSE)
  }, error = function(e) NULL, warning = function(w) NULL)
  if (!is.list(json) || is.null(names(json))) {
    return(NULL)
  }
  json
}

# Shared report code ----------------------------------------------------------

# TRUE when a line holds `_scripts`, with no ASCII letter, digit, `_`, or
# `.` right before it, then a separator, then `report.R`, with none right
# after it, as the template's source() line and its prose do. The separator
# is `/`, `\`, or `\\`, or a quote, a comma, and a quote, as between the
# arguments of file.path(), with an optional `/`, `\`, or `\\` before it.
# No `.*` lies between the names, as one did in the pattern that passed
# PCRE's match limit on a line of a few MB.
names_script <- function(lines) {
  slash <- "(?:/|\\\\{1,2}+)"
  pattern <- paste0("(?<![A-Za-z0-9_.])_scripts(?:", slash, "|", slash, "?[\"'][ \t]*+,[ \t]*+[\"'])",
                    "report\\.R(?![A-Za-z0-9_.])")
  any(grepl(pattern, lines, perl = TRUE, useBytes = TRUE))
}

# FALSE when the chain of links at `path` ends on no file: a missing file,
# a folder, a loop, or a chain that fs::path_real() stops on, which a
# render cannot read either. fs::is_file() never returns on a link to a
# link (fs 2.1.0), so fs::path_real() resolves the chain. On Windows fs
# expands `~` from USERPROFILE and R from R_USER or HOME, so R expands it
# first. A path that is not valid UTF-8 gives TRUE, which keeps the answer
# of file.exists(), since fs cannot read such a path.
link_ends_on_file <- function(path) {
  path <- enc2utf8(path)
  if (!validUTF8(path)) {
    return(TRUE)
  }
  target <- tryCatch(fs_path_real(path.expand(path)), error = function(e) NULL)
  !is.null(target) && file.exists(target) && !dir.exists(target)
}

# fs::path_real() under a name of its own, so that a test can make it stop.
fs_path_real <- function(path) fs::path_real(path)

# A site made before the template had _scripts/report.R lacks the file,
# and its reports do not name it, so only reports that name it give a row.
check_missing_script <- function(path) {
  script <- file.path(path, "_scripts", "report.R")
  # On Windows file.exists() is TRUE for a file link to a missing file.
  if (file.exists(script) && !dir.exists(script) && (!is_link(script) || link_ends_on_file(script))) {
    return(problem_rows())
  }
  reports <- analysis_reports(path)
  reads <- vapply(reports, function(report) {
    names_script(read_report_lines(report))
  }, logical(1), USE.NAMES = FALSE)
  if (!any(reads)) {
    return(problem_rows())
  }
  named <- paste(quote_path(show_text(sort_bytes(file.path("analyses", basename(reports[reads]))))),
                 collapse = ", ")
  problem_rows(
    "missing-script", "_scripts/report.R",
    paste0("The site has no file _scripts/report.R, which these reports name, so a render of them can fail: ",
           named, ". Copy the template's file from ",
           'system.file("template", "_scripts", "report.R", package = "supplement")',
           " to _scripts/report.R, or restore your own copy, then commit _scripts/report.R.",
           " If a file named _scripts or a folder named _scripts/report.R is in the way, move it first,",
           " and make the _scripts folder if it is missing.")
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
  pages <- site_pages(entries, outside)
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
  outside <- sort_bytes(outside)
  outside_rows <- problem_rows(
    "broken-link", file.path("docs", outside),
    rep_len("It is a link to a place outside docs/, so the published site does not have its target.",
            length(outside))
  )
  do.call(rbind, c(list(outside_rows), rows))
}

# The .html pages among the files of docs_entries(), in byte order of path.
# A page that a link outside docs/ points to (`outside`) is not in the
# published site, so it is left out.
site_pages <- function(entries, outside) {
  # useBytes keeps a name that is not valid UTF-8 in the match.
  html <- grepl("\\.html$", entries$files, useBytes = TRUE)
  # The walk lists a folder's files before its subfolders, so sort the
  # pages by path, in byte order.
  sort_bytes(entries$files[html & !(entries$files %in% outside)])
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
  values <- page_values(file)
  if (!is.character(values)) {
    return(values)
  }
  skip <- !nzchar(values) | grepl("^([A-Za-z][A-Za-z0-9+.-]*:|/|#)", values)
  unique(values[!skip])
}

# Every href, src, and xlink:href value on a page, decoded and trimmed, each
# once, or NULL or FALSE as for page_links().
page_values <- function(file) {
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
  unique(values)
}

# Web links -------------------------------------------------------------------

# The http and https addresses on the pages that check_links() reads, each
# once and with any fragment removed, as a data frame with the columns
# `address` and `page`, the first page in byte order that holds it. A page
# that page_values() cannot read is left out; check_links() gives its row.
web_addresses <- function(path) {
  docs <- file.path(path, "docs")
  if (!dir.exists(docs)) {
    return(web_addresses_none())
  }
  entries <- docs_entries(docs)
  pages <- site_pages(entries, outside_links(docs_root(docs), entries$links))
  found <- lapply(pages, function(page) {
    values <- page_values(file.path(docs, page))
    if (!is.character(values)) {
      return(NULL)
    }
    web <- unique(sub("#.*$", "", values[grepl("^[Hh][Tt][Tt][Pp][Ss]?:", values)]))
    data.frame(address = web, page = rep_len(page, length(web)), stringsAsFactors = FALSE)
  })
  found <- do.call(rbind, c(list(web_addresses_none()), found))
  found <- found[!duplicated(found$address), , drop = FALSE]
  rownames(found) <- NULL
  found
}

web_addresses_none <- function() data.frame(address = character(), page = character(), stringsAsFactors = FALSE)

# A web-link row for each address that web_addresses() finds and whose
# request fails or gives a status of 400 or above, in byte order of address. The
# addresses are requested one after another.
check_web_links <- function(path) {
  found <- web_addresses(path)
  if (nrow(found) == 0) {
    return(NULL)
  }
  found <- found[order_bytes(found$address), , drop = FALSE]
  cli::cli_alert_info("Requesting {nrow(found)} web address{?es}, one at a time.")
  problems <- vapply(found$address, function(url) web_problem(url, url_status(url)), character(1),
                     USE.NAMES = FALSE)
  bad <- !is.na(problems)
  problem_rows("web-link", file.path("docs", found$page[bad]), problems[bad])
}

# Statuses that a server can give this check where a browser, perhaps
# after a login, gets the page: it can ask for a login, refuse the HEAD
# request, or limit the number of requests.
refused_statuses <- c(401L, 403L, 405L, 429L)

# The problem text for `url` from its url_status() result, or NA when the
# address works.
web_problem <- function(url, result) {
  if (is.character(result)) {
    return(sprintf("The page links to `%s`, which could not be requested: %s", url, result))
  }
  # libcurl gives status 0 when no HTTP status came.
  if (!is.numeric(result) || length(result) != 1 || is.na(result) || result < 100) {
    return(sprintf("The page links to `%s`, whose response had no HTTP status.", url))
  }
  if (result < 400) {
    return(NA_character_)
  }
  text <- sprintf("The page links to `%s`, which gave HTTP status %d.", url, as.integer(result))
  if (result %in% refused_statuses) {
    text <- paste(text, "The server refused the check's request, so the link can still work in a browser.",
                  "Open it in a browser to see.")
  }
  text
}

# Base R's curlGetHeaders(), bound here so that tests can mock it. A call
# skips this NULL and finds the base function.
curlGetHeaders <- NULL

# The seconds that url_status() waits for each address.
web_timeout <- 10L

# The HTTP status of the last response to a HEAD request for `url`, after
# redirects, or the error message when the request fails, such as for an
# unknown host, a timeout, or a certificate error. libcurl breaks its
# messages with a line break and a tab, so each run of spaces becomes one
# space. libcurl refuses a space in an address, which a browser sends as
# %20.
url_status <- function(url) {
  tryCatch(
    attr(curlGetHeaders(gsub(" ", "%20", url, fixed = TRUE), redirect = TRUE, timeout = web_timeout),
         "status"),
    error = function(e) trimws(gsub("[[:space:]]+", " ", conditionMessage(e)))
  )
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

# Figures ---------------------------------------------------------------------

# Each regular file in figures/ whose copy at the same path under
# docs/figures/ is missing, is not a regular file, or has other bytes.
# Quarto copies figures/** into docs/ at each render, so a figure saved or
# changed after the last render gives a row.
check_unpublished_figures <- function(path) {
  figures <- file.path(path, "figures")
  if (!dir.exists(figures) || is_link(figures)) {
    return(problem_rows())
  }
  files <- plain_files(figures)
  copies <- file.path(path, "docs", "figures", files)
  same <- file.exists(copies) & !dir.exists(copies) & !is_link(copies)
  same[same] <- unname(tools::md5sum(file.path(figures, files[same]))) ==
    unname(tools::md5sum(copies[same]))
  same[is.na(same)] <- FALSE
  shown <- show_text(sort_bytes(file.path("figures", files[!same])))
  problem_rows(
    "unpublished-figure", shown,
    rep_len(paste("The copy in docs/figures/ is missing or differs.",
                  "Render the whole site, then commit figures/, docs/, and _freeze/."),
            length(shown))
  )
}

# The regular files in `dir` and in the folders in it, as paths relative
# to `dir`. A name that starts with `.` is skipped, and a symbolic link or
# junction is neither listed nor entered.
plain_files <- function(dir) {
  files <- character()
  queue <- ""
  while (length(queue) > 0) {
    rel <- queue[1]
    queue <- queue[-1]
    # Without all.files, list.files() skips names that start with `.`.
    names <- list.files(if (nzchar(rel)) file.path(dir, rel) else dir)
    paths <- if (nzchar(rel)) file.path(rel, names) else names
    full <- file.path(dir, paths)
    plain <- !is_link(full)
    folder <- dir.exists(full)
    files <- c(files, paths[plain & !folder])
    queue <- c(queue, paths[plain & folder])
  }
  files
}

# Template placeholders -------------------------------------------------------

# The rows for the template's placeholders that the site still holds.
check_placeholders <- function(path, meta) {
  rbind(placeholder_values(meta), placeholder_line_rows(path), placeholder_example_rows(path))
}

placeholder_example_problems <- c(
  "analyses/example.qmd" = "This is the template's example report. Write your own report in it, or delete it and its stored output in _freeze/analyses/example/, and make the Analyses menu in _quarto.yml list your own reports.",
  "data/example.csv" = "This is the template's example data. Put your own data in it, or delete it, its entry under data in _supplement.yml, and the example report, which reads it."
)

# The `text_hash()` of each version of the template's example files that
# the default branch has held, named by commit, so that a site made from
# an older template also gets its row. Each is `text_hash()` of
# `git show <commit>:inst/template/<file>` for the commits that
# `git log --follow -- inst/template/<file>` listed on 2026-10-26. A change
# to either template file adds its version here, and a test fails until it
# does.
example_versions <- list(
  "analyses/example.qmd" = c(
    "2db94f2" = "9451ca1c54165f4330b7fffbb11dc6c2",
    "fbc2cab" = "23d34b8911258f4f45c248f85689b175",
    "38af327" = "8f89f3479dccb4df43daefa967c4dd56",
    "11fa634" = "d6a37300a8d28a660fd3b27aed36206e",
    "0c312a3" = "2896f71bcfbca7b72ee52eb3c0a82d1b",
    "485be8b" = "098ed269ffa0e7dda0d19b320f2905e9",
    "9ba7e23" = "91353dee4efe2b8d81ee88e769fe7ed9",
    "5563744" = "54257d7e1131bc76018770982f85e763"
  ),
  "data/example.csv" = c(
    "5563744" = "2cc069c36b604f65c85f1b4aed6cfc34"
  )
)

# The size in bytes of the largest version in `example_versions`: the
# report at fbc2cab and the data at 5563744, read with `file.size()` of
# the same `git show` output.
example_version_bytes <- c("analyses/example.qmd" = 5090, "data/example.csv" = 86)

# A row for each example file whose `text_hash()` equals that of the
# installed template's copy or of a version in `example_versions`. A
# missing file, a folder, or a file that cannot be read gives no row. A
# copy of a known version with CR LF line ends and a BOM is under twice
# the largest version's size, so a larger file is not read.
placeholder_example_rows <- function(path) {
  files <- names(placeholder_example_problems)
  template <- system.file("template", package = "supplement", mustWork = TRUE)
  same <- vapply(files, function(file) {
    site_file <- file.path(path, file)
    template_file <- file.path(template, file)
    largest <- max(example_version_bytes[file], file.size(template_file), na.rm = TRUE)
    if (!file.exists(site_file) || dir.exists(site_file) || isTRUE(file.size(site_file) > 2 * largest)) {
      return(FALSE)
    }
    hash <- text_hash(site_file)
    !is.null(hash) && hash %in% c(example_versions[[file]], text_hash(template_file))
  }, logical(1))
  problem_rows("placeholder", files[same], placeholder_example_problems[files[same]])
}

# Lines of the template's files that the author replaces or deletes. The
# reader page is `_README.md` in the template and becomes `README.md` at the
# first render. `SUPPLEMENT.md` serves sites made before the guide moved to
# `GUIDE.md`, where setup wrote the guide there beside an existing README.
placeholder_lines <- list(
  "_quarto.yml" = "href: https://github.com/OWNER/REPO",
  "index.qmd" = "## Before your first commit",
  "LICENSE.md" = "Copyright (c) YEAR AUTHORS",
  "LICENSE-CC-BY.md" = "Copyright (c) YEAR AUTHORS",
  "README.md" = "Website: https://OWNER.github.io/REPO/",
  "SUPPLEMENT.md" = "Website: https://OWNER.github.io/REPO/",
  "_README.md" = "Website: https://OWNER.github.io/REPO/"
)

placeholder_line_problems <- c(
  "_quarto.yml" = "The GitHub link names OWNER/REPO. Write your GitHub repository in its place.",
  "index.qmd" = "The \"Before your first commit\" box is still on the home page. Delete it.",
  "LICENSE.md" = "The copyright line reads YEAR AUTHORS. Write the year and the authors in its place.",
  "LICENSE-CC-BY.md" = "The copyright line reads YEAR AUTHORS. Write the year and the authors in its place.",
  "README.md" = "The site address names OWNER and REPO. Write your GitHub account and repository in their place.",
  "SUPPLEMENT.md" = "The site address names OWNER and REPO. Write your GitHub account and repository in their place.",
  "_README.md" = "The site address names OWNER and REPO. Write your GitHub account and repository in their place."
)

# A row for each file of `placeholder_lines` that has its line, once
# spaces, tabs, and a CR at the ends of each line are removed. A missing
# file, a folder, or a file that is not UTF-8 text gives no row.
placeholder_line_rows <- function(path) {
  files <- names(placeholder_lines)
  found <- vapply(files, function(file) {
    lines <- plain_lines(file.path(path, file))
    placeholder_lines[[file]] %in% gsub("^[ \t\r]+|[ \t\r]+$", "", lines)
  }, logical(1))
  problem_rows("placeholder", files[found], placeholder_line_problems[files[found]])
}

# The lines of a UTF-8 text file, or none when it is missing, a folder, or
# cannot be read as UTF-8 text.
plain_lines <- function(file) {
  if (!file.exists(file) || dir.exists(file)) {
    return(character())
  }
  tryCatch(read_text_lines(file)$lines, error = function(e) character(), warning = function(w) character())
}

# The `supplement:` map of the installed template's _supplement.yml.
template_supplement <- function() {
  read_supplement(system.file("template", package = "supplement", mustWork = TRUE))
}

# One row naming each of paper-title, citation, contact, and authors whose
# value equals the installed template's. An author counts when its family
# and given both equal those of one template author. A value that is not
# one text value never counts, and neither does an empty template value.
placeholder_values <- function(meta) {
  template <- template_supplement()
  fields <- c("paper-title", "citation", "contact")
  left <- fields[vapply(fields, function(field) {
    same_text(meta[[field]], template[[field]])
  }, logical(1))]
  template_authors <- lapply(list_entries(template[["authors"]]), author_key)
  template_authors <- Filter(Negate(is.null), template_authors)
  site_authors <- lapply(list_entries(meta[["authors"]]), author_key)
  if (any(vapply(site_authors, function(key) {
    !is.null(key) && any(vapply(template_authors, identical, logical(1), key))
  }, logical(1)))) {
    left <- c(left, "authors")
  }
  if (length(left) == 0) {
    return(problem_rows())
  }
  problem_rows(
    "placeholder", "_supplement.yml",
    paste0("Template values left in place: ", paste(left, collapse = ", "),
           ". Replace them before a release.")
  )
}

# A value with its spaces cleaned, or NULL when it is not one non-empty
# text value.
plain_text <- function(x) {
  if (!is.character(x) || length(x) != 1 || is.na(x)) {
    return(NULL)
  }
  x <- clean_space(x)
  if (nzchar(x)) x
}

same_text <- function(x, template) {
  x <- plain_text(x)
  !is.null(x) && identical(x, plain_text(template))
}

# The entries of a YAML sequence, or none when `x` is not one.
list_entries <- function(x) {
  if (is.list(x) && is.null(names(x))) x else list()
}

# The cleaned family and given of an author map, or NULL when the entry is
# not a map or either is not one non-empty text value.
author_key <- function(entry) {
  if (!is_map(entry)) {
    return(NULL)
  }
  key <- list(plain_text(entry[["family"]]), plain_text(entry[["given"]]))
  if (any(vapply(key, is.null, logical(1)))) NULL else unlist(key)
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
