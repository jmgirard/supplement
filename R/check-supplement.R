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
#' * `"renv-mismatch"`: only with `renv_lock = TRUE`, a `.qmd` report
#'   directly in `analyses/`, from the same list of reports, whose stored
#'   output names an R or package version other than the one that the
#'   site's `renv.lock` records. The check reads the same `result.markdown`
#'   text as the `"stale-script"` check. In it, it reads the versions in the
#'   forms that `print_environment()` prints. From
#'   `sessioninfo::session_info()`, these are the package table after a line
#'   that starts with `─ Packages` or `- Packages`, read at the positions of
#'   the `package` and `version` columns of its header line, and the setting
#'   line that starts with ` version`, spaces, and R's version string, such
#'   as `R version 4.6.1 (2026-06-24)` or `R version 4.6.1 Patched (...)`.
#'   From `utils::sessionInfo()`, these are the first line that starts with
#'   R's version string, and the `name_version` entries on the lines that start
#'   with `[1]`, `[2]`, and so on, after any spaces, after
#'   `other attached packages:` and after
#'   `loaded via a namespace (and not attached):`. A line that holds an ANSI
#'   escape is not read, and output that knitr prints after a comment prefix
#'   such as `## ` is not found. A CR at the end of a line is ignored.
#'
#'   A package differs when one of its stored versions is not equal to the
#'   `Version` that `renv.lock` records for it under `Packages`. The R
#'   version differs when a stored R version is not equal to the `Version`
#'   under `R`. Versions are compared as [package_version()] values, so
#'   `1.0-5` equals `1.0.5`. A package that `renv.lock` does not record,
#'   such as a base package, is not compared; the `"renv-missing"` check
#'   gives a row for such a package that a report attached. Nor is a version that
#'   [package_version()] cannot read on either side, such as `devel`, or
#'   the R version when `renv.lock` records none. A development build of R
#'   prints `R Under development (unstable)`, which the check does not read
#'   as an R version. The report gets one row. It names the files that hold a
#'   version that differs, in the same way as the `"stale-script"` row.
#'   Then it names the R versions that differ, and each package that
#'   differs, in byte order of name, each with its stored versions that
#'   differ, in version order and each version once, and the version in
#'   `renv.lock`. It says to
#'   run `renv::restore()` and take the render steps, or, if the library now
#'   holds the versions of the report, to run `renv::snapshot()` and commit
#'   `renv.lock`. When another of these files holds a version that is
#'   compared and none that differ, the row also gives the format hint and
#'   delete steps of the `"stale-script"` row. A file that does not parse
#'   holds no versions, and a report that cannot be read, such as a link to
#'   a missing file, gives no row.
#'
#'   `renv.lock` gets one row of its own, and no report gets a row, when it
#'   is a folder, a link to a missing file, a file that cannot be opened,
#'   text that is not valid UTF-8, text that is not JSON, or JSON whose top
#'   level or `Packages` is not an object. So does a file that repeats a key
#'   that the check reads, such as two records of one package, because
#'   jsonlite keeps both and renv may read the other. A UTF-8 byte order
#'   mark at the start of the file is skipped. A package record is named by
#'   its `Package` text, or by its key when it has none, and a record with
#'   no `Version` text is left out of the comparison. A site with no `renv.lock` gets no row,
#'   and the function says that it skipped this check and the
#'   `"renv-missing"` check. [release_supplement()] does not run this
#'   check, so its rows never stop a release.
#'
#'   `renv.lock` also gets a row of its own when the check reads it but a
#'   folder or file in its path is listed under another spelling, such as
#'   `Renv.lock`. renv finds such a file only where the file system treats
#'   both spellings as one name, as macOS and Windows do for letter case by
#'   default, and [write_dockerfile()] refuses it. The row names the path as
#'   listed, when it can tell, and says to rename it. The reports still get
#'   their rows.
#'
#'   In this item and the next, `renv.lock` is the lockfile that renv 1.3.1
#'   picks for the site's renv profile. The profile's name comes from the
#'   `RENV_PROFILE` environment variable of the R session that runs the
#'   check, when it is not empty. Otherwise it comes from the first line of
#'   `renv/profile` in the site folder, untrimmed, when that file exists. The
#'   name `default`, an empty name, or no name means no profile, and the
#'   lockfile is `renv.lock` in the site folder. With a profile, the lockfile
#'   is `renv/profiles/<name>/renv.lock`, with the name joined as given. The
#'   function then says which profile it picked and where the name came
#'   from. When `RENV_PROFILE` and the first line of `renv/profile` give
#'   the same name, as in an R session that the site's `renv/activate.R`
#'   started, because it copies that line into `RENV_PROFILE`, the message
#'   names both. The rows name that path where they name `renv.lock`, and they say
#'   to run the renv commands with the profile active. When `renv/profile`
#'   is read and is a folder or a file that cannot be opened, it gets one
#'   row of its own, and no report gets a row. The check does not read
#'   `RENV_PATHS_LOCKFILE` or `RENV_PATHS_RENV`, which renv reads to move
#'   the lockfile and the `renv` folder.
#' * `"renv-missing"`: only with `renv_lock = TRUE`, a report from the same
#'   list whose stored output shows that it attached a package that the
#'   site's `renv.lock` does not name under `Packages`, so
#'   `renv::restore()` does not install it from `renv.lock`. The check reads the same
#'   `.json` files, in the same forms, as the `"renv-mismatch"` check. A
#'   package counts as attached when a line of the sessioninfo package
#'   table has `*` under the `*` of the table's header line, or when it is
#'   an entry after `other attached packages:` in `utils::sessionInfo()`
#'   output. A package that is loaded and not attached, such as knitr
#'   during a render or a package after
#'   `loaded via a namespace (and not attached):`, gives no row, since the
#'   render tools and not the report's code can load it. renv's default
#'   (implicit) snapshot records the packages that `renv::dependencies()`
#'   finds in the project, with their dependencies. A package that the
#'   user's R profile attaches during a render, or that renv's settings
#'   leave out of `renv.lock`, also gives a row, which `renv::snapshot()`
#'   and a new render do not clear.
#'   `renv.lock` names a package when it holds a record under `Packages`
#'   with that name, whatever its `Version`. A record is named as for the
#'   `"renv-mismatch"` check, and a record whose name is empty names no
#'   package. The report gets one row. It names the files that show such a
#'   package attached, in the same way as the `"renv-mismatch"` row, and
#'   each such package once, in byte order of name. It says to run
#'   `renv::snapshot()` and commit `renv.lock`, or, if the report no longer
#'   uses the packages, to take the render steps. When another of these
#'   files holds a package table or list and attaches none of them, the row
#'   also says that these files can be from a format that the report no
#'   longer renders, with the delete steps of the `"renv-mismatch"` row. A
#'   report that cannot be read gives no row. When `renv.lock` is missing,
#'   this check gives no row, and the function says that it skipped it.
#'   When `renv.lock` cannot be read, this check gives no row, and the one
#'   `"renv-mismatch"` row for `renv.lock` reports the problem. The
#'   `"renv-missing"` rows come after the
#'   `"renv-mismatch"` rows. [release_supplement()] does not run this
#'   check.
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
#'   `https:` are not checked here, except a `#` link under a local base
#'   (below). Only the `"web-link"` check, with
#'   `web_links = TRUE`, requests web addresses. GitHub
#'   Pages matches letter case, so a link whose case differs from the file
#'   name counts as broken, also on a disk that ignores case. A link that
#'   also differs from the name in Unicode form (for example `é` written
#'   as `e` plus an accent) is not caught.
#'
#'   Links are read from start tags only, as a browser reads them. Comments,
#'   `<!...>` and `<?...>` markup, end tags, and the text of `<script>`,
#'   `<style>`, `<textarea>`, and `<title>` elements are skipped, and so is
#'   page text such as `<code>` text. These parts end as the HTML Standard
#'   says, except as listed below. A comment ends at the `>` of `<!-->` or
#'   `<!--->`, and otherwise at its first `-->` or `--!>`. `</` followed by
#'   a character that is not an ASCII letter or `>` starts a bogus comment,
#'   which ends at the next `>`. An end tag is read through its attributes,
#'   so a `>` in a quoted value does not end it. In the text of a script,
#'   `<!--` starts escaped text, which ends at the next `-->`, whose dashes
#'   can be those of the `<!--`. In escaped text, `<script` followed by a
#'   space, tab, line break, form feed, `/`, or `>` makes the next
#'   `</script>` part of the text, unless a `-->` comes first. Any other
#'   `</script>` ends the script. Attribute names match in any letter case, and
#'   only whole names count, so `data-href` and `data-src` are not read. A
#'   value can be in double quotes, in single quotes, or unquoted, where it
#'   runs to the next space or `>`. An attribute with no `=`, such as
#'   `<a href>`, has an empty value and is not checked. A start tag that the
#'   end of the page cuts off is not read, as a browser drops it. A page
#'   whose markup goes past the limits of the PCRE pattern engine gives one
#'   row that says so, in place of its link rows. Such a page holds one tag
#'   with millions of attributes (3 million did and 1 million did not, with
#'   PCRE2 10.47 in R 4.6.1 on macOS). The size of a comment, or of the
#'   text of a script, style, textarea, or title element, does not count
#'   toward the limits, so a large one does not reach them.
#'   Each value is handled in this order:
#'   character references are decoded; spaces, tabs, line breaks, and form
#'   feeds at its ends are removed and tabs and line breaks inside it are
#'   dropped; links with a scheme, `/`, or `#` at the start are skipped,
#'   except a `#` link under a local base (below); then `%` escapes are
#'   decoded. The decoded references are `&amp;`,
#'   `&lt;`, `&gt;`, `&quot;`, and `&apos;` (in lower case, with the `;`),
#'   and number references such as `&#38;` or `&#x26;` with the `;` that
#'   name a code point from 1 to 0x10FFFF, other than a surrogate or 128 to
#'   159. A row shows the link after the references are decoded, the ends
#'   removed, and the tabs and line breaks inside it dropped.
#'
#'   A `<base>` tag changes where the links of its page lead. Only the
#'   first `<base>` tag with an `href` counts, and its `href` is not a link
#'   itself. Its value is read as a link value is. If the value is empty,
#'   starts with `#` or `?`, or starts with `data:` or `javascript:` in any
#'   letter case, links resolve against the page's own folder, as with no
#'   base. If the value
#'   has another scheme, such as `https:`, or starts with `/`, the page's
#'   relative links are not checked. Any other value is a local base.
#'   Relative links then resolve against the folder of the base address,
#'   with its `?` and `#` parts removed. A base whose last part is `.` or
#'   `..` names a folder. A link of only a `#` or `?` part resolves to the
#'   base address itself. A row shows the link before it is resolved
#'   against the base.
#'
#'   These are the main cases where the check reads a page differently
#'   from a browser. Every other reference (such as `&eacute;`, `&AMP;`, or
#'   `&#38` with no `;`) stays as written. Other control characters at the
#'   ends of a link, such as `&#1;`, stay, while a browser removes them. The
#'   text of `<noscript>`, `<xmp>`, `<iframe>`, `<noembed>`, `<noframes>`,
#'   and `<plaintext>` elements is read as markup, and so is the text of a
#'   `<![CDATA[...]]>` section after its first `>`. The four skipped
#'   elements are also skipped inside `<svg>` and `<math>`. The end tags of
#'   those four elements end at their first `>`, also inside a quoted
#'   value. A `<base>` tag inside `<template>`, or inside `<svg>` but not in
#'   its `<foreignObject>` or `<desc>`, counts as a base, though a browser
#'   does not use it. A base with a scheme whose address a browser cannot
#'   read, such as `http://`, leaves the page's relative links unchecked,
#'   while a browser resolves them against the page's own folder. A `\` in
#'   a base is not read as `/`, while a browser reads it so. An empty link,
#'   such as `href=""`, is not checked, also under a local base, while a
#'   browser resolves it to the base address. Under a base with another
#'   scheme or a leading `/`, a browser can follow the page's relative links
#'   to a place that the check does not read, and the check does not check
#'   them. A `"` or `'` with no closing quote starts an unquoted
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
#' @param renv_lock `TRUE` to also compare the R and package versions in the
#'   stored output of each report with the site's `renv.lock` and give the
#'   `"renv-mismatch"` rows, and to give the `"renv-missing"` rows for
#'   attached packages that `renv.lock` does not name. With an renv profile,
#'   the check reads the profile's lockfile instead, as the
#'   `"renv-mismatch"` item says. The default, `FALSE`, does not read
#'   `renv.lock`.
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
#'   or `web_links` or `renv_lock` is not `TRUE` or `FALSE`.
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
# one call of system2 for git; quarto_run() holds the one for Quarto.
# Sys.which(), here and in the check_tools() lookups
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

# The push address of the `origin` remote of the repository that holds
# `path`, as `git remote get-url --push origin` prints it, or NULL when git
# is not on the PATH, the folder is not in a repository, it has no such
# remote, or the address is not valid UTF-8. With no push url set, git
# prints the fetch url after any `pushInsteadOf` rewrite.
origin_url <- function(path) {
  out <- git_run(c("remote", "get-url", "--push", "origin"), path)
  if (is.null(out) || !identical(out$status, 0L) || !validUTF8(rawToChar(out$stdout))) {
    return(NULL)
  }
  url <- trimws(strsplit(rawToChar(out$stdout), "\n", fixed = TRUE)[[1]][1])
  if (!is.na(url) && nzchar(url)) url
}

# The branch that HEAD names in the repository that holds `path`
# (`current`), and the branch of origin that refs/remotes/origin/HEAD
# names (`default`). Each is NULL when git cannot read it, as for a
# detached HEAD, or when its name is not valid UTF-8.
release_branches <- function(path) {
  list(
    current = symbolic_ref(path, "HEAD", "refs/heads/"),
    default = symbolic_ref(path, "refs/remotes/origin/HEAD", "refs/remotes/origin/")
  )
}

# The name that the symbolic ref `ref` points to, less `prefix`, or NULL.
# The full name is read, since `--short` prints `heads/<name>` when a tag
# has the same name, and `remotes/origin/<name>` when a local branch is
# named `origin/<name>`.
symbolic_ref <- function(path, ref, prefix) {
  out <- git_run(c("symbolic-ref", "--quiet", ref), path)
  if (is.null(out) || !identical(out$status, 0L) || any(out$stdout == as.raw(0))) {
    return(NULL)
  }
  name <- rawToChar(out$stdout)
  if (!validUTF8(name)) {
    return(NULL)
  }
  Encoding(name) <- "UTF-8"
  name <- sub("\r?\n$", "", name)
  if (!startsWith(name, prefix) || nchar(name) == nchar(prefix)) {
    return(NULL)
  }
  substring(name, nchar(prefix) + 1L)
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

# The report's front matter as a named list, or NULL when it has none or
# it is not a YAML map. The front matter starts at a first `---` line that
# only blank lines come before and that a line that is not blank follows,
# and it ends at the next `---` or `...` line. Quarto also accepts an
# indented first `---`; this reader needs `---` at the start of its line.
report_front_matter <- function(lines) {
  blank <- grepl("^[ \\t]*\\z", lines, perl = TRUE, useBytes = TRUE)
  first <- which(!blank)[1]
  if (is.na(first) || !grepl("^---[ \\t]*\\z", lines[first], perl = TRUE, useBytes = TRUE) ||
      first == length(lines) || blank[first + 1]) {
    return(NULL)
  }
  ends <- which(grepl("^(---|\\.\\.\\.)[ \\t]*\\z", lines, perl = TRUE, useBytes = TRUE))
  last <- ends[ends > first][1]
  if (is.na(last) || last == first + 1) {
    return(NULL)
  }
  # yaml_read_lines() keeps sequences as lists and gives NULL for front
  # matter that does not parse.
  front <- suppressWarnings(yaml_read_lines(lines[seq.int(first + 1, last - 1)]))
  if (is.list(front) && !is.null(names(front))) front else NULL
}

# TRUE when the report's front matter is a YAML map whose top-level
# `engine` is the text "knitr", not a list such as `engine: [knitr]`.
engine_is_knitr <- function(lines) {
  identical(report_front_matter(lines)[["engine"]], "knitr")
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
                        "_freeze/, docs/, and figures/. In R, render_supplement() with the report's name",
                        "does both renders.")

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

# The rows of the renv.lock comparison: the "renv-mismatch" rows, then the
# "renv-missing" rows. The lockfile is that of the site's renv profile,
# from lock_source(). Rows and messages show its path with show_text(),
# since a profile name need not be valid UTF-8, and cli stops on such text.
# A site with no lockfile gets a message and no row, a lockfile that cannot
# be read gets one row, and so does a renv/profile that cannot be read. A
# lockfile listed under another spelling gets one row before the report
# rows.
check_renv_lock <- function(path) {
  source <- lock_source(path)
  if (isFALSE(source)) {
    return(problem_rows(
      "renv-mismatch", "renv/profile",
      paste("renv reads the name of the site's renv profile from its first line, but it is a folder or a file",
            "that cannot be opened. Make it a file whose first line names the profile, or delete it to use",
            "renv.lock, then commit the change.")
    ))
  }
  # Values, not templates, carry the names to cli, since a name can hold
  # `{` or `}`.
  shown <- show_text(source$file)
  active <- ""
  if (!is.null(source$profile)) {
    active <- paste0(" with the renv profile ", quote_path(show_text(source$profile)), " active")
  }
  inform_lock_source(source)
  lock <- lock_versions(path, source$file)
  if (is.null(lock)) {
    cli::cli_alert_info(paste("Skipped the {.val renv-mismatch} check: the site has no {.file {shown}}.",
                              "Skipped the {.val renv-missing} check too."))
    return(problem_rows())
  }
  if (isFALSE(lock)) {
    return(problem_rows(
      "renv-mismatch", shown,
      paste0("It cannot be read as an renv lockfile. It is a folder, a link to a missing file, or a file that ",
             "cannot be opened, or it is not UTF-8 text that holds a JSON object with a Packages object, or it ",
             "repeats a key. Run renv::snapshot()", active, " to write it again, then commit it.")
    ))
  }
  # Where the file system ignores letter case, renv reads the lockfile under
  # another spelling, which a case-sensitive file system and the Docker
  # build of write_dockerfile() do not find.
  # A profile name with `/`, or on Windows with `\` or a trailing space or
  # `.`, is not one folder name, and the system finds the file by another
  # path, so its parts cannot be matched with what the folders list.
  parts <- strsplit(source$file, "/", fixed = TRUE)[[1]]
  rewritten <- !all(nzchar(parts)) ||
    (.Platform$OS.type == "windows" && any(grepl("[ .]$|\\\\", parts, useBytes = TRUE)))
  spelling <- problem_rows()
  if (!rewritten && !listed_exactly(path, parts)) {
    listed <- listed_path(path, parts)
    spelling <- problem_rows("renv-mismatch", shown, paste0(
      if (is.null(listed)) "A folder or file in its path is listed under another spelling" else
        paste0("It is listed as ", quote_path(show_text(listed))),
      ". renv finds it only where the file system treats both spellings as one name, as macOS and Windows ",
      "do for letter case by default, and write_dockerfile() refuses it. Rename it to ", quote_path(shown),
      ", then commit the change."
    ))
  }
  lock$file <- shown
  lock$active <- active
  reports <- analysis_reports(path)
  problems <- vapply(reports, function(report) {
    name <- sub("\\.qmd$", "", basename(report))
    dir <- file.path("_freeze", "analyses", name, "execute-results")
    files <- list.files(file.path(path, dir), pattern = "\\.json$")
    files <- files[!startsWith(files, ".") & !dir.exists(file.path(path, dir, files))]
    stored <- lapply(file.path(path, dir, files), function(file) {
      markdown <- stored_markdown(file)
      if (is.null(markdown)) {
        return(list(r = character(), packages = character(), attached = character(), listed = FALSE))
      }
      stored_versions(markdown)
    })
    problem <- c(mismatch_problem(lapply(stored, version_diffs, lock), files, dir, lock),
                 missing_problem(stored, files, dir, lock))
    # A report that cannot be read, such as a link to a missing file,
    # cannot be rendered again, so it gets no row, as in check_stale_output().
    if (all(is.na(problem)) || is.null(report_hash(report))) {
      return(c(NA_character_, NA_character_))
    }
    problem
  }, character(2), USE.NAMES = FALSE)
  files <- file.path("analyses", basename(reports))
  mismatch <- !is.na(problems[1, ])
  missing <- !is.na(problems[2, ])
  rbind(spelling,
        problem_rows("renv-mismatch", files[mismatch], problems[1, mismatch]),
        problem_rows("renv-missing", files[missing], problems[2, missing]))
}

# The problem text of the "renv-mismatch" row of a report whose stored
# output files `files` in `dir` hold the versions `found`, from
# version_diffs(), or NA when no version differs.
mismatch_problem <- function(found, files, dir, lock) {
  differs <- vapply(found, function(x) length(x$r) > 0 || length(x$packages) > 0, logical(1))
  if (!any(differs)) {
    return(NA_character_)
  }
  # Each version once, so `1.0-5` and `1.0.5` print as one.
  in_order <- function(v) {
    v <- v[order(package_version(v))]
    paste(v[!duplicated(as.character(package_version(v)))], collapse = " and ")
  }
  r <- unlist(lapply(found, `[[`, "r"))
  packages <- unlist(lapply(found, `[[`, "packages"))
  entries <- c(
    if (length(r) > 0) paste0("R ", in_order(r), " (", lock$file, ": ", lock$r, ")"),
    vapply(sort_bytes(unique(as.character(names(packages)))), function(p) {
      paste0(p, " ", in_order(packages[names(packages) == p]), " (", lock$file, ": ", lock$packages[[p]], ")")
    }, character(1), USE.NAMES = FALSE)
  )
  named <- paste(quote_path(show_text(sort_bytes(file.path(dir, files[differs])))), collapse = ", ")
  stale <- paste0("Its stored output was made with other versions than ", lock$file, " records, in ", named, ": ",
                  paste(entries, collapse = ", "), ".")
  steps <- paste0("To use the versions in ", lock$file, ", run renv::restore()", lock$active,
                  ", then take these steps. ", rerender_steps,
                  " If the library now holds the versions of the report, run renv::snapshot()", lock$active,
                  " and commit ", lock$file, " instead.")
  matches <- vapply(found, function(x) x$compared, logical(1)) & !differs
  if (!any(matches)) {
    return(paste(stale, steps))
  }
  # Quarto keeps the file of a format that the report no longer renders.
  paste(stale,
        paste0("Other stored output of the report matches ", lock$file, ", so these files can be from a format that"),
        "the report no longer renders. If so, delete them, render the whole site, and commit the report with",
        "_freeze/, docs/, and figures/.",
        "If not, take the steps that follow.", steps)
}

# The problem text of the "renv-missing" row of a report whose stored
# output files `files` in `dir` hold the versions `stored`, from
# stored_versions(), or NA when no file shows an attached package that
# the lockfile `lock` does not name. renv::restore() does not install such
# a package from the lockfile.
missing_problem <- function(stored, files, dir, lock) {
  missing <- lapply(stored, function(x) setdiff(x$attached, lock$names))
  shows <- lengths(missing) > 0
  if (!any(shows)) {
    return(NA_character_)
  }
  named <- paste(quote_path(show_text(sort_bytes(file.path(dir, files[shows])))), collapse = ", ")
  packages <- paste(sort_bytes(unique(unlist(missing))), collapse = ", ")
  stale <- paste0("Its stored output shows that the report attached packages that ", lock$file,
                  " does not record, in ", named, ": ", packages, ".")
  steps <- paste0("renv::restore() does not install them. To record them, run renv::snapshot()", lock$active,
                  " and commit ", lock$file, ". If the report no longer uses them, take these steps instead. ",
                  rerender_steps)
  listed <- vapply(stored, function(x) x$listed, logical(1)) & !shows
  if (!any(listed)) {
    return(paste(stale, steps))
  }
  # Quarto keeps the file of a format that the report no longer renders.
  paste(stale,
        "Other stored output of the report attaches none of them, so these files can be from a format that the",
        "report no longer renders. If so, delete them, render the whole site, and commit the report with",
        "_freeze/, docs/, and figures/.",
        "If not, take the steps that follow.", steps)
}

# The versions in `stored`, from stored_versions(), that differ from those
# in `lock`, from lock_versions(): a list of `r`, the R versions that
# differ, `packages`, the package versions that differ, named by package,
# and `compared`, TRUE when at least one version was compared. A version
# that package_version() cannot read on either side is not compared, nor
# is a package that the lockfile does not record.
version_diffs <- function(stored, lock) {
  compare <- function(versions, recorded) {
    vapply(seq_along(versions), function(i) {
      a <- package_version(versions[[i]], strict = FALSE)
      b <- package_version(recorded[[i]], strict = FALSE)
      if (is.na(a) || is.na(b)) NA else a != b
    }, logical(1))
  }
  r <- compare(stored$r, rep(if (is.null(lock$r)) NA_character_ else lock$r, length(stored$r)))
  packages <- compare(stored$packages, unname(lock$packages[names(stored$packages)]))
  list(r = stored$r[r %in% TRUE], packages = stored$packages[packages %in% TRUE],
       compared = any(!is.na(c(r, packages))))
}

# The lockfile that renv 1.3.1 reads for the site in `path`, by the rules
# of renv_bootstrap_profile_load(), for the profile's name, and
# renv_paths_lockfile(), for the path: a list of `file`, its path from the site
# folder, `profile`, the name of the renv profile or NULL, and `from`,
# where the name came from. The name comes from the R session's
# RENV_PROFILE when it is not empty, else from the first line of
# renv/profile, untrimmed, and `default` or an empty name means no
# profile. FALSE when renv/profile is read and is a folder or cannot be
# opened. `from` is "both" when RENV_PROFILE names the profile and the
# first line of renv/profile is the same name, byte for byte, because
# renv's activate.R copies that line into RENV_PROFILE; renv/profile
# then does not change the pick.
lock_source <- function(path) {
  profile <- Sys.getenv("RENV_PROFILE")
  from <- "RENV_PROFILE"
  if (!nzchar(profile)) {
    from <- "renv/profile"
    profile <- profile_line(path)
    if (is.null(profile)) {
      return(FALSE)
    }
  }
  if (profile %in% c("", "default")) {
    return(list(file = "renv.lock", profile = NULL, from = NULL))
  }
  if (from == "RENV_PROFILE") {
    line <- profile_line(path)
    if (!is.null(line) && identical(charToRaw(line), charToRaw(profile))) {
      from <- "both"
    }
  }
  list(file = paste("renv", "profiles", profile, "renv.lock", sep = "/"), profile = profile, from = from)
}

# The first line of renv/profile in the site `path`, as renv reads it: ""
# when the file is missing or empty, and NULL when it is a folder or
# cannot be opened. renv tests the file with file.exists(), so a link to a
# missing file names no profile, except on Windows, where file.exists() is
# TRUE for it. A folder is refused before readLines(), so that its row does
# not depend on what readLines() does with a folder.
profile_line <- function(path) {
  file <- file.path(path, "renv", "profile")
  if (!file.exists(file)) {
    return("")
  }
  lines <- if (!dir.exists(file)) {
    suppressWarnings(tryCatch(readLines(file, warn = FALSE), error = function(e) NULL))
  }
  if (is.null(lines)) {
    return(NULL)
  }
  if (length(lines) > 0) lines[[1]] else ""
}

# TRUE when each of `parts`, a path from the folder `path`, is listed in
# its folder under its exact name, letter case included. A folder that
# lists nothing, such as one that can be entered but not read, counts as
# listing the part.
listed_exactly <- function(path, parts) {
  for (i in seq_along(parts)) {
    folder <- do.call(file.path, as.list(c(path, parts[seq_len(i - 1)])))
    names <- list.files(folder, all.files = TRUE)
    if (length(names) > 0 && !parts[[i]] %in% names) {
      return(FALSE)
    }
  }
  TRUE
}

# The path `parts`, from the folder `path`, with each part as its folder
# lists it, or NULL when a part is not found so. A part is the one name in
# its folder that differs from it only in letter case, by fold_case(),
# else, when it is not a link, the name that fs::path_real() gives it,
# which is the stored name on macOS and Windows.
listed_path <- function(path, parts) {
  listed <- character()
  for (part in parts) {
    folder <- do.call(file.path, as.list(c(path, listed)))
    names <- list.files(folder, all.files = TRUE)
    if (part %in% names) {
      listed <- c(listed, part)
      next
    }
    same <- tryCatch(names[fold_case(names) == fold_case(part)], error = function(e) character())
    # fs::path_real() follows a link, so it would give the target's name.
    if (length(same) != 1 && !is_link(file.path(folder, part))) {
      real <- tryCatch(basename(as.character(fs::path_real(file.path(folder, part)))), error = function(e) "")
      same <- if (real %in% names && !is_link(file.path(folder, real))) real
    }
    if (length(same) != 1) {
      return(NULL)
    }
    listed <- c(listed, same)
  }
  paste(listed, collapse = "/")
}

# A message that names the lockfile and the renv profile in `source`, from
# lock_source(), when it names a profile.
inform_lock_source <- function(source) {
  if (is.null(source$profile)) {
    return(invisible())
  }
  shown <- show_text(source$file)
  profile <- show_text(source$profile)
  if (source$from == "both") {
    cli::cli_alert_info(paste("Picked {.file {shown}}, the lockfile of the renv profile {.val {profile}},",
                              "which {.envvar RENV_PROFILE} and {.file renv/profile} both name."))
  } else if (source$from == "RENV_PROFILE") {
    cli::cli_alert_info(paste("Picked {.file {shown}}, the lockfile of the renv profile {.val {profile}},",
                              "which {.envvar RENV_PROFILE} names."))
  } else {
    cli::cli_alert_info(paste("Picked {.file {shown}}, the lockfile of the renv profile {.val {profile}},",
                              "which {.file renv/profile} names."))
  }
  invisible()
}

# `bytes` without the UTF-8 byte order mark at their start, if they have
# one. An editor can save a lockfile with it, and jsonlite warns about it.
drop_bom <- function(bytes) {
  if (length(bytes) >= 3 && identical(bytes[1:3], as.raw(c(0xef, 0xbb, 0xbf)))) bytes[-(1:3)] else bytes
}

# The versions that the lockfile `file`, a path from the site folder
# `path`, records: NULL when nothing, not even a link, is at that path,
# FALSE when it cannot be read, a link to a missing file among them, and
# otherwise a list of `r`, the
# R version or NULL, `packages`, a character vector of versions named by
# package, and `names`, the name of each package record. A package record
# with no `Version` text is left out of `packages` and kept in `names`, and
# a record whose name is empty is left out of both.
lock_versions <- function(path, file = "renv.lock") {
  file <- file.path(path, file)
  # On Windows, file.exists() stops with "file name conversion problem" on
  # a profile name that is not valid UTF-8, so such a path counts as a file
  # that cannot be read.
  exists <- tryCatch(file.exists(file) || is_link(file), error = function(e) NA)
  if (is.na(exists)) {
    return(FALSE)
  }
  if (!exists) {
    return(NULL)
  }
  if (dir.exists(file)) {
    return(FALSE)
  }
  json <- tryCatch({
    text <- rawToChar(drop_bom(readBin(file, "raw", n = file.size(file))))
    if (!validUTF8(text)) stop("not UTF-8")
    Encoding(text) <- "UTF-8"
    jsonlite::parse_json(text, simplifyVector = FALSE)
  }, error = function(e) NULL, warning = function(w) NULL)
  packages <- if (is_map(json)) json[["Packages"]]
  if (!is_map(packages)) {
    return(FALSE)
  }
  # jsonlite keeps both copies of a repeated key, and `[[` takes the first,
  # while renv may read another, as read_lockfile_versions() also notes.
  repeated <- function(map, key) is_map(map) && sum(names(map) == key) > 1
  records_repeat <- vapply(packages, function(record) {
    repeated(record, "Package") || repeated(record, "Version")
  }, logical(1))
  if (repeated(json, "R") || repeated(json, "Packages") || repeated(json[["R"]], "Version") ||
      anyDuplicated(names(packages)) > 0 || any(records_repeat)) {
    return(FALSE)
  }
  text_value <- function(record, key) {
    value <- if (is_map(record)) record[[key]]
    if (is.character(value) && length(value) == 1 && !is.na(value)) value else NA_character_
  }
  versions <- vapply(packages, text_value, character(1), key = "Version", USE.NAMES = FALSE)
  # renv names a record by its key and also writes the name as `Package`.
  named <- vapply(packages, text_value, character(1), key = "Package", USE.NAMES = FALSE)
  names(versions) <- ifelse(is.na(named), names(packages), named)
  if (anyDuplicated(names(versions)) > 0) {
    return(FALSE)
  }
  r <- text_value(json[["R"]], "Version")
  list(r = if (!is.na(r)) r, packages = versions[!is.na(versions) & nzchar(names(versions))],
       names = names(versions)[nzchar(names(versions))])
}

# The R and package versions that print_environment() printed into stored
# output text, as a list of `r`, a character vector of R versions,
# `packages`, a character vector of versions named by package, `attached`,
# the names of the packages that the session attached, and `listed`, TRUE
# when the text holds a package table or list. It reads the
# package table after a `─ Packages` or `- Packages` rule of
# sessioninfo::session_info() and its `version` setting line, and the
# `R version` line and the two package lists of utils::sessionInfo(). A
# table line marks an attached package with `*` under the `*` of its
# header, and utils::sessionInfo() lists them after
# `other attached packages:`. A line that holds an ANSI escape is not
# read. The patterns that find lines run on the first 200 characters of a
# line, so a long line stays fast. The entries of a package list are read
# from the whole line.
stored_versions <- function(markdown) {
  lines <- strsplit(markdown, "\n", fixed = TRUE)[[1]]
  cr <- endsWith(lines, "\r")
  lines[cr] <- substr(lines[cr], 1, nchar(lines[cr]) - 1L)
  lines[grepl("\033", lines, fixed = TRUE)] <- ""
  head <- substr(lines, 1, 200)
  first_word <- function(x) sub(" .*$", "", sub("^ +", "", x))

  # R's version string, such as `R version 4.6.1 (2026-06-24)` or
  # `R version 4.6.1 Patched (2026-07-01 r88000)`.
  version_string <- "R version [0-9][^ ]*( [A-Za-z]+)? \\([0-9]{4}-[0-9]{2}-[0-9]{2}"
  setting <- grepl(paste0("^ version +", version_string), head)
  first <- which(grepl(paste0("^", version_string), head))[1]
  r <- c(first_word(sub("^ version +R version ", "", head[setting])),
         if (!is.na(first)) first_word(sub("^R version ", "", head[first])))

  packages <- character()
  attached <- character()
  listed <- FALSE
  rules <- which(startsWith(head, "\u2500 Packages") | startsWith(head, "- Packages"))
  for (rule in rules[rules < length(head)]) {
    header <- head[rule + 1]
    if (!grepl("^ (! +)?package +\\* +version ", header)) next
    listed <- TRUE
    name_at <- regexpr("package", header, fixed = TRUE)
    star_at <- regexpr("*", header, fixed = TRUE)
    version_at <- regexpr("version", header, fixed = TRUE)
    i <- rule + 2
    while (i <= length(head) && nzchar(head[i])) {
      name <- first_word(substring(head[i], name_at))
      version <- first_word(substring(head[i], version_at))
      if (grepl("^[A-Za-z][A-Za-z0-9.]*$", name) && nzchar(version)) {
        names(version) <- name
        packages <- c(packages, version)
        if (substr(head[i], star_at, star_at) == "*") attached <- c(attached, name)
      }
      i <- i + 1
    }
  }

  lists <- which(head == "other attached packages:" | head == "loaded via a namespace (and not attached):")
  for (start in lists) {
    listed <- TRUE
    i <- start + 1
    while (i <= length(head) && grepl("^ *\\[[0-9]+\\] ", head[i])) {
      words <- strsplit(lines[i], " ", fixed = TRUE)[[1]]
      words <- words[grepl("^[A-Za-z][A-Za-z0-9.]*_[^_]+$", words)]
      at <- regexpr("_", words, fixed = TRUE)
      versions <- substring(words, at + 1)
      names(versions) <- substring(words, 1, at - 1)
      packages <- c(packages, versions)
      if (head[start] == "other attached packages:") attached <- c(attached, names(versions))
      i <- i + 1
    }
  }
  list(r = r, packages = packages, attached = unique(attached), listed = listed)
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
    # Quarto writes UTF-8. Unmarked text is read in the native encoding,
    # which in a Latin-1 locale misreads characters such as `─`.
    text <- rawToChar(bytes)
    Encoding(text) <- "UTF-8"
    jsonlite::parse_json(text, simplifyVector = FALSE)
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
    # link_ok() skips that test. Each link is tested at its target, the
    # path that a base on the page makes of it.
    broken <- links[!vapply(attr(links, "targets"), link_ok, logical(1), docs = docs, page = page,
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
# tag_links(), such as a PCRE match limit on a tag with millions of
# attributes, which makes regexpr() fail. The attribute `targets` holds the path of each link
# relative to the page's folder, after a local base (base_kind()). Under
# such a base a link of only a `#` or `?` part points to the base address,
# so it is kept. A base that points to a place that this check does not
# read leaves no link.
page_links <- function(file) {
  values <- page_values(file)
  if (!is.character(values)) {
    return(values)
  }
  base <- attr(values, "base")
  kind <- base_kind(base)
  if (kind == "away") {
    return(structure(character(), targets = character()))
  }
  skip <- !nzchar(values) | grepl("^([A-Za-z][A-Za-z0-9+.-]*:|/)", values)
  if (kind == "page") {
    skip <- skip | startsWith(values, "#")
  }
  links <- unique(values[!skip])
  if (kind == "page") {
    return(structure(links, targets = links))
  }
  address <- base_address(base)
  part_only <- grepl("^[#?]", links)
  targets <- paste0(ifelse(part_only, address, sub("[^/]*$", "", address)), links)
  structure(links, targets = targets)
}

# How the links of a page resolve under `base`, the value of the page's
# first <base> href, or NULL (whatwg-html, 4.2.3). "page": against the
# page's own folder, as with no base. This holds for an empty value, one
# that starts with `#` or `?`, and a data: or javascript: base. "away": to
# a place that this check does not read, for another scheme or a value
# that starts with `/`. "local": against the base, a path relative to the
# page.
base_kind <- function(base) {
  if (is.null(base) || !nzchar(base) || grepl("^[#?]", base) ||
      grepl("^(data|javascript):", ascii_lower(base))) {
    return("page")
  }
  if (grepl("^([A-Za-z][A-Za-z0-9+.-]*:|/)", base)) {
    return("away")
  }
  "local"
}

# The address that a local base names, with its `?` and `#` parts
# removed. A last part of `.` or `..`, also when written with `%2e`,
# names a folder, so it gets a `/`.
base_address <- function(base) {
  address <- sub("[?#].*$", "", base)
  last <- percent_decode(sub("^.*/", "", address))
  if (!is.na(last) && last %in% c(".", "..")) paste0(address, "/") else address
}

# Every href, src, and xlink:href value on a page, decoded and trimmed, each
# once, or NULL or FALSE as for page_links(). The attribute `base` holds
# the value of the first <base> href, read the same way, or NULL.
page_values <- function(file) {
  html <- read_page_text(file)
  if (is.null(html)) {
    return(NULL)
  }
  links <- tryCatch(tag_links(html), warning = function(w) FALSE)
  if (isFALSE(links)) {
    return(FALSE)
  }
  base <- attr(links, "base")
  structure(unique(link_text(unique(links))), base = if (!is.null(base)) link_text(base))
}

# Link values with their character references decoded and their ends
# trimmed. A browser trims spaces and control characters from the ends of
# a link; here only spaces, tabs, line breaks, and form feeds are trimmed.
# Tabs and line breaks inside a link are dropped, as the URL standard's
# parser does.
link_text <- function(values) {
  values <- decode_refs(values)
  values <- gsub("^[\t\n\f\r ]+|[\t\n\f\r ]+$", "", values, perl = TRUE)
  gsub("[\t\n\r]", "", values)
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

# Parts of the patterns that read tags, after the HTML standard's
# tokenizer: an attribute name runs to a space, `/`, `>`, or `=`, and an
# unquoted value runs to a space or `>`.
# Every repeat in the html_* parts is possessive (`*+`, `++`), so PCRE
# never backtracks into it and the time stays linear. PCRE's match limit
# counts the steps of one match, so one tag with millions of attributes
# can still reach it (3 million did and 1 million did not, PCRE2 10.47,
# R 4.6.1, macOS, 2026-10-29). page_links() then returns FALSE.
# tag_links() walks comments and element text in R. The one scan that
# repeats a group over them, the scan of whole tags, is caught when it
# reaches the limit.
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

# The heads of the markup on a page, which tag_links() walks: a comment
# start, with its end when it is `<!-->` or `<!--->`; `<!` and `<?` markup,
# and `</` with a character that is not an ASCII letter, each to its first
# `>`; and the `<` or `</` and the name of a tag, with no attributes. No
# head holds a `>` but as its last character, so none runs past the `>`
# that ends a comment, an element, or a tag, and the heads after such an
# end are those that a scan from there would find.
html_heads <- "<!--(?:-?+>)?+|<[!?][^>]*+(?:>|\\z)|</(?![A-Za-z])[^>]*+(?:>|\\z)|</?[A-Za-z][^\t\n\f\r />]*+"

# The heads again, but with each tag's attributes and `>`, for the tag ends
# that tag_links() looks up. The comment start is matched alone, so the
# scan goes on inside comments and element text.
html_tag_scan <- paste0(
  "<!--|<[!?][^>]*+(?:>|\\z)|</(?![A-Za-z])[^>]*+(?:>|\\z)|</?[A-Za-z][^\t\n\f\r />]*+", html_tag_rest
)

# A pattern that matches `word` in any ASCII letter case, such as
# `[Tt][Ii][Tt][Ll][Ee]`. PCRE's `(?i)` on bytes, and toupper() and
# tolower(), follow the locale, where `i` and `I` need not pair (Turkish).
ascii_any_case <- function(word) {
  chars <- strsplit(word, "", fixed = TRUE)[[1]]
  upper <- chartr("abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZ", chars)
  paste0("[", upper, chars, "]", collapse = "")
}

ascii_lower <- function(x) chartr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz", x)

# The raw values of the href, src, and xlink:href attributes in the start
# tags of `html`, other than <base> tags. The attribute `base` holds the
# raw href of the first <base> tag that has one, or NULL. Comments, `<!...>`
# and `<?...>` markup, end tags, and the text of script, style, textarea,
# and title elements are not read, as a browser reads no tags there. Each
# start tag of those four elements is kept, so `<script src>` is read.
# A start tag that the end of the page cuts off is not read, as a browser
# drops it. A quote that never closes is read as the start of an unquoted
# value instead, so that tag ends at the next `>` and is read.
# One scan finds the heads (html_heads), and an R loop walks them from the
# start of the page: each comment and each element's text is passed over
# to its end (comment_end(), text_end(), script_end()), and each tag to the
# end of its attributes. The rules follow whatwg-html, 13.2.5.
tag_links <- function(html) {
  # The page is read as bytes. Without that, R turns the byte offset of
  # each match into a character offset when the text holds a non-ASCII
  # character, at a cost that grows with the offset, so a page with many
  # tags took time that grew with the square of their count, and substr()
  # counts characters from the start. Bytes are safe here because
  # read_page_text() returns valid UTF-8 and every delimiter in these
  # patterns is ASCII. The tags are marked UTF-8 again, since strings
  # marked "bytes" make file.path() and sprintf() stop.
  Encoding(html) <- "bytes"
  size <- nchar(html, type = "bytes")
  heads <- gregexpr(html_heads, html, perl = TRUE, useBytes = TRUE)[[1]]
  # Positions are kept as doubles: findInterval() turns an integer vector
  # into one on each call, which took 3 of the 3.4 s that the walk of a
  # page of 60,000 heads took (macOS, R 4.6, 2026-10-29).
  starts <- if (heads[1] == -1L) numeric() else as.numeric(heads)
  ends <- starts + attr(heads, "match.length")[seq_along(starts)]
  # The kind of each head from its second to fourth bytes: 1 a comment
  # start, 2 other markup that ends at its own `>`, 3 an end tag, 4 a start
  # tag. Indexing past the page gives byte 0.
  bytes <- charToRaw(html)
  byte <- function(offset) as.integer(bytes[starts + offset])
  letter <- function(b) (b >= 65L & b <= 90L) | (b >= 97L & b <= 122L)
  second <- byte(1L)
  third <- byte(2L)
  kinds <- ifelse(letter(second), 4L, ifelse(second == 47L & letter(third), 3L,
                  ifelse(second == 33L & third == 45L & byte(3L) == 45L, 1L, 2L)))
  # The end of each tag, from one scan of whole tags. A tag that the walk
  # reaches at the start of a scanned tag ends where that one does, since
  # the same pattern matched from the same place. Other tags, and every tag
  # when this scan reaches PCRE's match limit (a tag in a comment or in
  # element text with millions of attributes), are matched one at a time.
  tag_scan <- tryCatch(gregexpr(html_tag_scan, html, perl = TRUE, useBytes = TRUE)[[1]],
                       warning = function(w) -1L)
  scan_starts <- if (tag_scan[1] == -1L) numeric() else as.numeric(tag_scan)
  scan_ends <- scan_starts + attr(tag_scan, "match.length")[seq_along(scan_starts)]
  marks <- page_marks(html)
  from <- integer(length(starts))
  to <- integer(length(starts))
  kept <- 0L
  at <- 1L
  i <- 1L
  while (i <= length(starts)) {
    if (starts[i] < at) {
      i <- findInterval(at - 1L, starts, checkSorted = FALSE, checkNA = FALSE) + 1L
      if (i > length(starts)) break
    }
    start <- starts[i]
    end <- ends[i]
    kind <- kinds[i]
    if (kind == 1L) {
      # `<!-->` and `<!--->` are whole comments.
      at <- if (end - start > 4L) end else comment_end(marks, start + 4L)
    } else if (kind == 2L) {
      at <- end
    } else {
      j <- findInterval(start - 1L, scan_starts, checkSorted = FALSE, checkNA = FALSE) + 1L
      at <- if (j <= length(scan_starts) && scan_starts[j] == start) scan_ends[j] else tag_end(html, end, size)
      if (kind == 4L) {
        kept <- kept + 1L
        from[kept] <- start
        to[kept] <- at - 1L
        # The text of these elements starts after the start tag. The name
        # must end at a space, `/`, or `>`, not at the end of the page.
        if (end <= size && (end - start - 1L) %in% c(5L, 6L, 8L) && all(letter(as.integer(bytes[(start + 1L):(end - 1L)])))) {
          name <- ascii_lower(rawToChar(bytes[(start + 1L):(end - 1L)]))
          if (name == "script") {
            at <- script_end(marks, at)
          } else if (name %in% c("style", "textarea", "title")) {
            at <- text_end(marks, name, at)
          }
        }
      }
    }
    i <- i + 1L
  }
  tags <- if (kept > 0L) substring(html, from[seq_len(kept)], to[seq_len(kept)]) else character()
  Encoding(tags) <- "UTF-8"
  # No unquoted value or name holds `>`, so a tag that ends with `>`
  # closed before the end of the page. Tags with no href or src are not
  # parsed further.
  tags <- tags[endsWith(tags, ">") & grepl("[Hh][Rr][Ee][Ff]|[Ss][Rr][Cc]", tags)]
  rests <- sub("^<[^\t\n\f\r />]*", "", tags)
  per_tag <- regmatches(rests, gregexpr(html_attr, rests, perl = TRUE))
  attrs <- unlist(per_tag)
  attr_names <- ascii_lower(sub("(?s)^([^=\t\n\f\r ]*).*", "\\1", attrs, perl = TRUE))
  # A <base> href is not a link. The first href of the first <base> tag
  # that has one sets the address that the other links resolve against.
  tag_names <- ascii_lower(sub("(?s)^<([^\t\n\f\r />]*).*", "\\1", tags, perl = TRUE))
  in_base <- (tag_names == "base")[rep(seq_along(per_tag), lengths(per_tag))]
  base <- attrs[in_base & attr_names == "href"]
  links <- attrs[!in_base & attr_names %in% c("href", "src", "xlink:href")]
  # An attribute with no `=`, such as `<a href>`, has an empty value.
  links <- links[grepl("=", links, fixed = TRUE)]
  structure(attr_value(links), base = if (length(base) > 0) attr_value(base[1]))
}

# The places on a page, read as bytes, where comments and element text
# can end, or where script text changes state. mark_at() finds each kind
# once, on its first use.
page_marks <- function(html) {
  marks <- new.env(parent = emptyenv())
  marks$html <- html
  marks$size <- nchar(html, type = "bytes")
  marks
}

# The positions of `key` on the page: each `>`, `-->`, `--!>`, or `<!--`,
# or each `<name` or `</name` (`key` "start name" or "end name") in any
# ASCII letter case and followed by a space, tab, line break, form feed,
# `/`, or `>`. A `-->` or `--!>` cannot overlap another, so a scan finds
# each one, and a `-->` in a longer run of `-` is found at its end. The
# keys are matched with PCRE, where none of their characters is special:
# gregexpr(fixed = TRUE) took 15 s for the 360,000 `>` of a 6 MB page
# where PCRE took 0.01 s. A name is matched in a copy of the page with its
# ASCII letters in lower case, which keeps each byte's position: a pattern
# such as `</[Ss][Tt][Yy][Ll][Ee]` took 0.52 s for 20,000 end tags where
# `</style` took 0.003 s (macOS, R 4.6, 2026-10-29).
mark_at <- function(marks, key) {
  if (is.null(marks[[key]])) {
    parts <- strsplit(key, " ", fixed = TRUE)[[1]]
    if (length(parts) == 1L) {
      text <- marks$html
      pattern <- key
    } else {
      if (is.null(marks$lower)) {
        lower <- marks$html
        Encoding(lower) <- "UTF-8"
        lower <- ascii_lower(lower)
        Encoding(lower) <- "bytes"
        marks$lower <- lower
      }
      text <- marks$lower
      pattern <- paste0(if (parts[1] == "end") "</" else "<", parts[2], "[\t\n\f\r />]")
    }
    at <- gregexpr(pattern, text, perl = TRUE, useBytes = TRUE)[[1]]
    marks[[key]] <- if (at[1] == -1L) numeric() else as.numeric(at)
  }
  marks[[key]]
}

# The first position of `key` at `from` or later, or Inf when none.
next_mark <- function(marks, key, from) {
  at <- mark_at(marks, key)
  found <- at[findInterval(from - 1L, at, checkSorted = FALSE, checkNA = FALSE) + 1L]
  if (is.na(found)) Inf else found
}

# The position after an end tag that starts at `from`: after its first
# `>`, or after the page.
after_end_tag <- function(marks, from) {
  if (is.infinite(from)) {
    return(marks$size + 1L)
  }
  gt <- next_mark(marks, ">", from)
  if (is.infinite(gt)) marks$size + 1L else gt + 1L
}

# The position after a comment whose text starts at `from`: after its first
# `-->` or `--!>`, or after the page.
comment_end <- function(marks, from) {
  end <- min(next_mark(marks, "-->", from) + 3, next_mark(marks, "--!>", from) + 4)
  if (is.infinite(end)) marks$size + 1L else as.integer(end)
}

# The position after a style, textarea, or title element whose text starts
# at `from`: after its first `</name` end tag, or after the page.
text_end <- function(marks, name, from) {
  after_end_tag(marks, next_mark(marks, paste("end", name), from))
}

# The position after a script whose text starts at `from`, by the script
# data states (whatwg-html, 13.2.5.4 and 13.2.5.15 to 13.2.5.31). In plain
# text, `<!--` starts escaped text. Escaped text returns to plain text at
# its first `-->`, whose dashes can be those of the `<!--`, and `</script`
# there ends the script. In escaped text, `<script` starts double escaped
# text, which returns to escaped text at `</script` and to plain text at
# `-->`. A `<script` or `</script` that starts or ends double escaped text
# takes the character after it with it.
script_end <- function(marks, from) {
  state <- "plain"
  at <- from
  dashes_from <- from
  repeat {
    end <- next_mark(marks, "end script", at)
    if (state == "plain") {
      open <- next_mark(marks, "<!--", at)
      if (open >= end) {
        return(after_end_tag(marks, end))
      }
      state <- "escaped"
      dashes_from <- open + 2L
      at <- open + 4L
    } else if (state == "escaped") {
      dashes <- next_mark(marks, "-->", dashes_from)
      start <- next_mark(marks, "start script", at)
      if (end < dashes && end < start) {
        return(after_end_tag(marks, end))
      }
      if (is.infinite(dashes) && is.infinite(start)) {
        return(marks$size + 1L)
      }
      if (dashes < start) {
        state <- "plain"
        at <- dashes + 3L
      } else {
        state <- "double"
        at <- start + 8L
      }
    } else {
      dashes <- next_mark(marks, "-->", at)
      if (is.infinite(dashes) && is.infinite(end)) {
        return(marks$size + 1L)
      }
      if (dashes < end) {
        state <- "plain"
        at <- dashes + 3L
      } else {
        state <- "escaped"
        at <- end + 9L
        dashes_from <- at
      }
    }
  }
}

# The position after the attributes and `>` of a tag whose name ends at
# `from`, or after the page. The attributes are matched in a window that
# grows until the match ends inside it with no quote that could close past
# it, so the result is that of a match over the rest of the page.
tag_end <- function(html, from, size) {
  width <- 4096L
  repeat {
    to <- min(size, from + width - 1L)
    window <- substr(html, from, to)
    used <- attr(regexpr(html_tag_rest_start, window, perl = TRUE, useBytes = TRUE), "match.length")
    if (to >= size || (used < to - from + 1L && !open_quote(window, used))) {
      return(from + used)
    }
    width <- width * 8L
  }
}

html_tag_rest_start <- paste0("^", html_tag_rest)

# Whether the last `"` or `'` in `window` falls in its first `used` bytes,
# where a quoted value that the window cuts off could start.
open_quote <- function(window, used) {
  if (!grepl("[\"']", substr(window, 1L, used), useBytes = TRUE)) {
    return(FALSE)
  }
  last <- function(quote) max(gregexpr(quote, window, perl = TRUE, useBytes = TRUE)[[1]])
  last('"') %in% seq_len(used) || last("'") %in% seq_len(used)
}

# The raw value of each attribute, such as `href="x"` or `href=x`, or ""
# for one with no `=`.
attr_value <- function(attrs) {
  values <- sub(paste0("(?s)^[^=]*=", html_space, "*"), "", attrs, perl = TRUE)
  values[!grepl("=", attrs, fixed = TRUE)] <- ""
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
# the default branch has held, so that a site made from an older template
# also gets its row. Each entry is named by the commit that made it, or
# `current` for a version added before its merge, whose commit on the
# default branch is not known yet; the change after it renames it by that
# commit. The entries named by commit are `text_hash()` of
# `git show <commit>:inst/template/<file>` for the commits that
# `git log --follow -- inst/template/<file>` listed on 2026-10-26. A change
# to either template file adds its version here, and a test fails until it
# does.
example_versions <- list(
  "analyses/example.qmd" = c(
    "current" = "634316e199f1a43ab7fb88ce59bf5161",
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
