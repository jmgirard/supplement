# Check a supplement site before a release

`check_supplement()` looks for problems that can break a release of a
site, publish files that must stay private, or publish the template's
placeholder values in place of the author's. It changes no file. It
prints each problem it finds and returns all of them as a data frame.

## Usage

``` r
check_supplement(path = ".")
```

## Arguments

- path:

  The folder of the site.

## Value

A data frame with one row per problem and the character columns `check`,
`file` (the path in the site), and `problem`, invisibly. It has zero
rows when the function finds no problem. Its `skipped` attribute names
the git checks (`"large-file"`, `"saved-object"`, and
`"ignored-output"`) that did not run, and is empty when they ran.

## Details

The checks, by the value in the `check` column:

- `"large-file"`: a file larger than 100 MiB (104,857,600 bytes), which
  GitHub refuses. A symbolic link, or on Windows a junction, is not
  counted, because git stores only the link.

- `"saved-object"`: a saved R object (`.rds`, `.rda`, `.rdata`, `.qs`,
  or `.qs2`, in any letter case). A fitted model saved this way can hold
  the data it was fitted to.

- `"ignored-output"`: a file that git ignores in `figures/`, `docs/`, or
  `_freeze/`, so that a release leaves it out of the published site. The
  check takes each regular file in these folders, and in the folders in
  them, that is reached without passing through a symbolic link or, on
  Windows, a junction, and whose path holds no name that starts with
  `.`. The file gets a row when git neither tracks it nor lists it as
  untracked, because its ignore rules exclude it, such as a rule in
  `.gitignore` or `.git/info/exclude`. A file that git tracks gives no
  row, also when a rule matches it. The copy of a data file in
  `docs/data/` gets a row when a rule also matches the copy, as the
  template's rule for `.rds` files does. The problem text says to change
  the rule for a file that the site must publish, and to remove the
  source of a private file and render again.

- `"no-stored-output"`: a `.qmd` report directly in `analyses/`, not in
  a folder inside it, with code and no stored output in `_freeze/`. A
  full render then runs its code, which needs the data. A report has
  code when a line starts a code chunk: any mix of spaces, tabs, and `>`
  characters, three or more backticks, optional spaces or tabs, then `{`
  and a name. The name is the longest run of an ASCII letter followed by
  ASCII letters, digits, `_`, or `.`. Any text without `}` can follow
  the name, then `}`, and the line ends with optional spaces or tabs. A
  chunk named `ojs`, `mermaid`, or `dot`, in any letter case, does not
  count, because Quarto starts no engine for it. Every other name
  counts, such as `{bash}` or `{sql}`, and so does a chunk in a report
  whose front matter sets `engine: markdown`. Quarto also reads other
  white space, line breaks included, between the backticks and `{` and
  after `}`. It lets the text after the name run across lines, and it
  starts a line after U+2028 or U+2029. Such chunk starts are not found.
  A nul byte in a report counts as a character that is none of those
  this rule names. A report with no chunk that counts also has code when
  it has inline R code on one line and the top-level `engine` in its own
  front matter is `knitr`. Inline R code is a backtick, then `r` and a
  space or `#`, or `{r}` and a space, then text with no backtick, then a
  backtick. Inline code that spans lines is not found, nor is inline
  code with a tab after `{r}`, which knitr also runs. Nor is knitr that
  a `knitr` key, `execute: engine`, an included file, or `_metadata.yml`
  turns on. A report has no stored output when
  `_freeze/analyses/<name>/execute-results/` holds no file other than
  hidden files and the files in hidden folders.

- `"stale-output"`: a `.qmd` report directly in `analyses/`, from the
  same list of reports, whose stored output was made from other text
  than the report holds now. The check reads as JSON each file whose
  name ends in `.json` and does not start with `.`, directly in
  `_freeze/analyses/<name>/execute-results/`. Quarto writes the MD5 of
  the report's text there as the top-level `hash`. The report gets one
  row when such a `hash` is one text value that differs from the MD5 of
  the report's bytes with each CR LF pair read as LF. It also gets one
  row, which says that the source hash of its stored output cannot be
  read, when such a file does not parse, its top level is not an object,
  or its top-level `hash` is missing or is not one text value. When one
  file cannot be read and another differs, the one row has this text. A
  report that cannot be read, such as a link to a missing file, gives no
  row. Quarto 1.10.19 hashes only the report file, so a change in a file
  that the report includes, in `_quarto.yml` or `_metadata.yml`, or in
  the data gives no row. Reports in folders inside `analyses/` are not
  read. Quarto reads a report as UTF-8 and hashes each byte that is not
  valid UTF-8 as U+FFFD, so such a report gets a row after each render.
  The row names, by their paths from the site folder in byte order, each
  of these files whose `hash` differs, or in the "cannot be read" text
  only each file whose `hash` cannot be read. Each path stands between
  double quotes, with a `\` before each `\` and `"` in it, so that a
  name that holds a comma and a space reads as one file. The "cannot be
  read" text ends with the render steps and then a delete step. It says
  that if the row stays after the render steps, the files can be from a
  format that the report no longer renders, or damaged. Then it says to
  delete them, render the whole site, and commit the report with
  `_freeze/`, `docs/`, and `figures/`. Quarto keeps the file of a format
  that the report no longer renders, such as `docx.json`, with its old
  hash. So when every `hash` can be read and another of these files has
  a `hash` equal to that MD5 of the report, the row also says that the
  files that differ can be from a format that the report no longer
  renders. If so, delete them, render the whole site, and commit the
  report with `_freeze/`, `docs/`, and `figures/`. If not, follow the
  render steps that the row gives after the hint.

- `"leftover-output"`: a folder directly in `_freeze/analyses/`, whose
  name does not start with `.`, that no file or folder in `analyses/`
  names. A name in `analyses/` names the folder when, cut before its
  last `.` (the whole name when it holds no `.`), it equals the folder's
  name with letter case ignored: the case of ASCII letters always, and
  the case of other letters as
  [`tolower()`](https://rdrr.io/r/base/chartr.html) reads it in the
  session's locale. In a name that is not valid UTF-8, only the case of
  ASCII letters is ignored. A name stored in another Unicode form,
  composed or decomposed, does not match. Quarto 1.10.19 keeps a
  report's folder after the report is deleted or renamed. The row says
  to delete the folder, render the whole site, and commit `_freeze/` and
  `docs/`, and for a deleted or renamed report also its old path and
  `_quarto.yml`. Folders inside subfolders of `_freeze/analyses/` and
  folders directly in `_freeze/` are not read. A file or folder in
  `analyses/` of the same name, such as `<name>.R`, hides a leftover
  folder. So does a report whose name differs only in letter case, as
  after a report is renamed only in letter case on Linux.

- `"not-rendered"`: the site has no `docs/` folder.

- `"broken-link"`: an `href`, `src`, or `xlink:href` link on a page in
  `docs/` to a file that is not in `docs/`, or to a folder there with no
  `index.html`, or a link that ends with `/` to a file. A page that
  cannot be read, such as a link to a missing file, also counts. Pages
  in every folder of `docs/` are read, hidden files and folders (names
  that start with `.`) included. A symbolic link to a folder, or on
  Windows a junction, is not entered. A page in a folder that such a
  link points to is read once, at its own path, when the folder is in
  `docs/`. A symbolic link in `docs/` to a page file in `docs/` is read
  as a page of its own. A symbolic link or junction in `docs/` whose
  target exists and resolves to a place outside `docs/` gives a row of
  its own, because the published site does not have its target. So a
  link to such a link also gives a row. A page that it points to, or a
  page in a folder that it points to, is not read. A link on a page
  whose path passes through or ends at such a link also counts. For a
  link to a folder, the folder's `index.html` is part of that path. A
  symbolic link or junction that resolves to `docs/` or a place in it
  gives no row of its own. Links that start with `/`, `#`, or a scheme
  such as `https:` are not checked, and no web address is requested.
  GitHub Pages matches letter case, so a link whose case differs from
  the file name counts as broken, also on a disk that ignores case. A
  link that also differs from the name in Unicode form (for example `é`
  written as `e` plus an accent) is not caught.

  Links are read from start tags only, as a browser reads them.
  Comments, `<!...>` and `<?...>` markup, and the text of `<script>`,
  `<style>`, `<textarea>`, and `<title>` elements are skipped, and so is
  page text such as `<code>` text. Attribute names match in any letter
  case, and only whole names count, so `data-href` and `data-src` are
  not read. A value can be in double quotes, in single quotes, or
  unquoted, where it runs to the next space or `>`. An attribute with no
  `=`, such as `<a href>`, has an empty value and is not checked. A
  start tag that the end of the page cuts off is not read, as a browser
  drops it. A page whose markup goes past the limits of the PCRE pattern
  engine gives one row that says so, in place of its link rows. Such a
  page holds millions of `-` in one comment, millions of `<` in the text
  of one script, style, textarea, or title element (about 5 million did,
  in a page of 20 MB), or millions of attributes in one tag. Each value
  is handled in this order: character references are decoded; spaces,
  tabs, line breaks, and form feeds at its ends are removed and tabs and
  line breaks inside it are dropped; links with a scheme, `/`, or `#` at
  the start are skipped; then `%` escapes are decoded. The decoded
  references are `&amp;`, `&lt;`, `&gt;`, `&quot;`, and `&apos;` (in
  lower case, with the `;`), and number references such as `&#38;` or
  `&#x26;` with the `;` that name a code point from 1 to 0x10FFFF, other
  than a surrogate or 128 to 159. A row shows the link after the
  references are decoded, the ends removed, and the tabs and line breaks
  inside it dropped.

  These are the main cases where the check reads a page differently from
  a browser. Every other reference (such as `&eacute;`, `&AMP;`, or
  `&#38` with no `;`) stays as written. Other control characters at the
  ends of a link, such as `&#1;`, stay, while a browser removes them.
  The text of `<noscript>`, `<xmp>`, `<iframe>`, `<noembed>`,
  `<noframes>`, and `<plaintext>` elements is read as markup, and so is
  the text of a `<![CDATA[...]]>` section after its first `>`. The four
  skipped elements are also skipped inside `<svg>` and `<math>`. A
  comment ends only at the first `-->`, so `<!-->` and `<!--->` also run
  to the next `-->`, and `--!>` does not end it. A script ends at its
  first `</script>`, also when its text holds `<!--` and `<script>`,
  where a browser reads on to a later `</script>`. A `"` or `'` with no
  closing quote starts an unquoted value, so the next `>` ends that tag
  and it is read, where a browser reads on to the end of the page and
  drops the tag. A byte that is not valid UTF-8 is read as text such as
  `<e9>`; outside a quoted value, its `>` ends the tag, so an unquoted
  value keeps the `<e9` part and the later attributes of that tag are
  not read. A second attribute of the same name is also read.

- `"unpublished-figure"`: a paper figure that the last render did not
  copy into `docs/`. The check takes each regular file in `figures/`,
  and in the folders in it, that is reached without passing through a
  symbolic link or junction, and whose path holds no name that starts
  with `.`. The file gets a row when the same path under `docs/figures/`
  is not a regular file, or when the MD5 of its bytes differs. A render
  copies into `docs/figures/` the files that `figures/` holds when the
  render starts, so a figure saved under a new name or changed after the
  last render gets a row, and a full render or a render of a report by
  name clears it. Hidden files are not compared, though Quarto copies
  them too.

- `"doi-mismatch"`: the DOI in `CITATION.cff` differs from the one that
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md)
  writes from `_supplement.yml`, or the DOI badge on `docs/index.html`
  differs from `zenodo.version-doi` (or `zenodo.concept-doi` when that
  is empty). A home page whose source uses `{{< supplement-doi >}}` but
  that shows no badge, while `_supplement.yml` has a DOI, also counts.
  So does a `CITATION.cff` that cannot be read or is not a YAML map (a
  link to a missing file included), and a DOI in `CITATION.cff` or on
  the badge that is not a DOI.

- `"placeholder"`: a template value that the author has not replaced, so
  that a release would archive it. The check compares the site with the
  template that the installed package holds:

  - `_supplement.yml` gets one row when `paper-title`, `citation`, or
    `contact` equals the template's value, or an `authors` entry has the
    `family` and `given` of a template author. Values are compared with
    each run of white space read as one space and the ends removed. A
    value that is not one text value does not count. The row names the
    fields.

  - `_quarto.yml` gets a row for the line
    `href: https://github.com/OWNER/REPO`, `index.qmd` for the line
    `## Before your first commit`, `LICENSE.md` and `LICENSE-CC-BY.md`
    for the line `Copyright (c) YEAR AUTHORS`, and `README.md`,
    `SUPPLEMENT.md`, and `_README.md` for the line
    `Website: https://OWNER.github.io/REPO/`. `SUPPLEMENT.md` is for a
    site made before the template's guide moved to `GUIDE.md`: when that
    site's first render found a `README.md`, it wrote the guide to
    `SUPPLEMENT.md`. Spaces, tabs, and a carriage return at the ends of
    a line are ignored. A file that is missing, a folder, not UTF-8
    text, or that cannot be read gives no row.

  - `analyses/example.qmd` and `data/example.csv` each get a row when
    their text equals the template's copy, with each CR LF read as LF. A
    file that cannot be read gives no row.

  Only a whole value or a whole line counts, so a value that keeps part
  of a placeholder, such as a citation with `(Year)` in it, gives no
  row. A site made from an older version of the template, whose
  placeholders differ from the installed ones, gives no row for them.

The `"large-file"` and `"saved-object"` checks look at the files that
git tracks or does not ignore, which
`git ls-files --cached --others --exclude-standard` lists, so files that
`.gitignore` blocks are left out. The `"ignored-output"` check reads the
files that `git ls-files --others --ignored --exclude-standard` lists in
`figures/`, `docs/`, and `_freeze/`. For these three git checks the
function runs git only to read: `git --version`,
`git rev-parse --is-inside-work-tree`, and `git ls-files`. When git is
not on the PATH, one of these commands fails, or the folder is not in a
git work tree, it skips these three checks and says so.

## Errors

The function stops with an error of class `supplement_error` and one of
these classes:

- `supplement_error_argument`: `path` is not a single non-empty string.

- `supplement_error_no_metadata`: `path` holds no `_supplement.yml`.

- `supplement_error_parse`: the yaml package cannot read
  `_supplement.yml`, as for
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md).

- `supplement_error_no_map`: `_supplement.yml` has no `supplement:` map.

- `supplement_error_field_type`: a DOI in `_supplement.yml` is not one
  text value, or `zenodo` is not a map.

- `supplement_error_doi`: a DOI in `_supplement.yml` is not a DOI.

## See also

[`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md)
to write `CITATION.cff` again.

## Examples

``` r
site <- file.path(tempdir(), "check-example")
create_supplement(site)
#> ✔ Made a supplement site in /tmp/RtmpTEBvOi/check-example.
#> ℹ Replace `OWNER/REPO` in _quarto.yml, and `OWNER` and `REPO` in the site
#>   address in _README.md, with your GitHub repository.
#> ℹ Put the paper facts in _supplement.yml.
#> ℹ Run `quarto render` in /tmp/RtmpTEBvOi/check-example once before your first
#>   commit.
# A new site has not been rendered, its example report has no stored
# output yet, and it still holds the template's placeholder values.
problems <- check_supplement(site)
#> ℹ Skipped the "large-file", "saved-object", and "ignored-output" checks: `git rev-parse` failed, or the folder is not in a git work tree.
#> ✖ 11 problems found in /tmp/RtmpTEBvOi/check-example:
#> ✖ no-stored-output analyses/example.qmd: The report has code and no stored
#>   output in _freeze/. Render the report by name, render the whole site, then
#>   commit the report with _freeze/, docs/, and figures/. If you added the report
#>   to the Analyses menu, as add_report() does, also commit _quarto.yml.
#> ✖ not-rendered docs: The site has no docs/ folder. Render the site.
#> ✖ unpublished-figure figures/bootstrap-means.png: The copy in docs/figures/ is
#>   missing or differs. Render the whole site, then commit figures/, docs/, and
#>   _freeze/.
#> ✖ placeholder _supplement.yml: Template values left in place: paper-title,
#>   citation, contact, authors. Replace them before a release.
#> ✖ placeholder _quarto.yml: The GitHub link names OWNER/REPO. Write your GitHub
#>   repository in its place.
#> ✖ placeholder index.qmd: The "Before your first commit" box is still on the
#>   home page. Delete it.
#> ✖ placeholder LICENSE.md: The copyright line reads YEAR AUTHORS. Write the year
#>   and the authors in its place.
#> ✖ placeholder LICENSE-CC-BY.md: The copyright line reads YEAR AUTHORS. Write
#>   the year and the authors in its place.
#> ✖ placeholder _README.md: The site address names OWNER and REPO. Write your
#>   GitHub account and repository in their place.
#> ✖ placeholder analyses/example.qmd: This is the template's example report.
#>   Write your own report in it, or delete it and its stored output in
#>   _freeze/analyses/example/, and make the Analyses menu in _quarto.yml list
#>   your own reports.
#> ✖ placeholder data/example.csv: This is the template's example data. Put your
#>   own data in it, or delete it, its entry under data in _supplement.yml, and
#>   the example report, which reads it.
problems$check
#>  [1] "no-stored-output"   "not-rendered"       "unpublished-figure"
#>  [4] "placeholder"        "placeholder"        "placeholder"       
#>  [7] "placeholder"        "placeholder"        "placeholder"       
#> [10] "placeholder"        "placeholder"       
unlink(site, recursive = TRUE)
```
