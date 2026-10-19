# Design

_Seeded by `/cairn-init` on 2026-10-18 from the scope draft (commit aef6a1a). Refine with `/design-interview`._

## Purpose & Scope

supplement helps authors publish the supplemental materials for a paper as a
Quarto website. GitHub Pages serves the site, and Zenodo archives each GitHub
release with a DOI. The audience is researchers who share analysis reports,
code, and open data, in R or Python.

The package replaces hand work that the first two sites
(`jmgirard/llm-depression-assessment`, `jmgirard/pilot-ptsd-markers`) repeat
almost line for line. Each analysis report renders as a page of the website,
so every page shows the site navbar. Quarto freeze stores the computed output
in `_freeze/`, so the site rebuilds without the private data and without R.

Planned deliverables:

- A Quarto template and extension. This layer works for any Quarto user.
- An R package with scaffolding, metadata, check, and release helpers. This
  layer works only from R.

Distribution intent: CRAN, eventually. Keep `R CMD check` at 0 errors and 0
warnings from the first commit of package code.

Out of scope for version 1: data files over GitHub limits, calls to the
Zenodo API, Python helper functions, and migration of existing sites.

## Function Families

- metadata writers: `write_citation()`, `write_zenodo()`
- scaffolding: `create_supplement()`, `add_report()`, `add_data()`
- release steps: `check_supplement()`, `release_supplement()`

Status and order live in `ROADMAP.md`.

## Conventions

- Pure R, with no compiled code (chosen at init, 2026-10-18). This covers
  package code. The template may carry Quarto TypeScript scripts (D-004)
  and a Quarto Lua extension (M004), which need no R.
- One metadata file (`_supplement.yml`) is the single source for citation,
  authors, ORCIDs, DOIs, and licenses. `CITATION.cff` and `.zenodo.json`
  are generated from it.
- The package never runs `git tag`, `git push`, or a GitHub release. It
  prints those commands for the author to run.
- No oracle-verification rule for numeric results (declined at init,
  2026-10-18).

## Design Principles

None elicited yet. Run `/design-interview` to add them.

## Architecture

R code: `R/supplement-yml.R` reads `<path>/_supplement.yml` and checks
it, with classed cli errors (`supplement_error` plus one subclass per
case). It also holds the path helpers that several functions share
(`drop_trailing_sep()`, `path_occupied()`, `is_link()`). On Windows,
where `Sys.readlink()` gives `""` for a junction or a symbolic link,
`is_link()` also counts a path that its folder lists but that does not
exist, or that resolves to a place other than its folder plus its name.
`write_citation()` writes `CITATION.cff` (CFF 1.2.0) and
`write_zenodo()` writes `.zenodo.json` from that map. Both check each
license id they write with `license_id()`, a shape check only (D-012). Both leave out
empty values and refuse to replace an existing file unless
`overwrite = TRUE`.
`R/create-supplement.R`: `create_supplement()` copies the installed
template into a folder, refuses any file, folder, or link in its way
before it writes, removes what it made when a write fails, and with
`repo` fills the GitHub placeholders. It never runs git.
`R/add-report.R` and `R/add-data.R`: `add_report()` writes a report stub
in `analyses/` and adds it to the Analyses menu in `_quarto.yml`;
`add_data()` copies a file into `data/` and adds it to the `data` list in
`_supplement.yml`. Both check every argument and the target file before
the first write, and refuse a linked `analyses/` or `data/` folder.
`R/yaml-insert.R` adds a list item as lines of text, so comments stay
(D-010), and replaces a one-line map value on its line (D-011); it
re-reads the result with the yaml package before any write.
Its `yaml_read_file_text()` reads a site YAML file and turns the yaml
package's error into `supplement_error_parse`, which names the file and
gives the parser's message. `read_supplement()`, the release read, and
`append_item()` call it, so every function that reads `_supplement.yml`
or `_quarto.yml` gives that class for a file that does not parse.
`R/add-utils.R` holds the checks the two share.
`R/check-supplement.R`: `check_supplement()` changes no file and returns
its problems as a data frame (`check`, `file`, `problem`), with a
`skipped` attribute. Its file size and saved-object checks read `git
ls-files -z --cached --others --exclude-standard` through `git_run()`, the
package's one place that starts a process. Its link check reads quoted
`href` and `src` values in `docs/**/*.html` with a regular expression and
resolves each link by path segments inside `docs/`, matching each name's
letter case as GitHub Pages does. A bad DOI in `CITATION.cff` or on the
badge gives a row; only a bad DOI in `_supplement.yml` stops the check.
`R/release-supplement.R`: `release_supplement()` checks `bump`, reads
`_supplement.yml` once, and from that read checks the current
`supplement.version` and the `version:` line. It builds the new
`CITATION.cff` and `.zenodo.json` text from the changed lines with
`citation_text()` and `zenodo_text()`, the builders that `write_citation()`
and `write_zenodo()` also use, so a value they refuse stops the release
with their error. It refuses a `CITATION.cff` or `.zenodo.json` that is a
link, a folder, or a file it cannot read or write, or that is missing in
a folder it cannot write, then runs `check_supplement()`. It reads the
three files again and stops (`supplement_error_changed`) when one of them
changed, or was made or removed as a file, during the check; the same
refusals run again on the outputs. It then stops on any problem but a
`CITATION.cff` DOI row. It then writes `_supplement.yml` and the two built
texts. When a write stops, or on an interrupt, it puts back each file
whose bytes changed and removes each file it made. After the writes it
prints the git and `gh` release commands, outside that guard; `git status`,
`git add -A`, and `git commit` end in `-- .`, so the release commit holds
only files under the site folder, the files `check_supplement()` checked. It starts
no process itself.
Imports: cli, jsonlite, yaml (D-009). Roxygen writes Markdown help.

The package ships a Quarto website template in
`inst/template/` (D-003), installed with `quarto use template
jmgirard/supplement/inst/template` or with `create_supplement()`.

- `_quarto.yml`: a website project with `freeze: true` (D-002), output in
  `docs/` (D-001), an Analyses navbar menu, and `data/**` and `figures/**`
  as resources. A render lists the files in `figures/` at its start and
  copies them after the report code runs, so a changed figure under an
  existing name reaches `docs/` in the same render, and a figure saved
  under a new name reaches it on the next render.
- `_scripts/setup.ts` (pre-render): gives `_gitignore` and `_README.md`
  their real names, merges missing rules into an existing `.gitignore`, and
  writes the guide to `SUPPLEMENT.md` beside an existing README (D-004,
  D-006).
- `_scripts/nojekyll.ts` (post-render): writes `.nojekyll` into the output
  folder.
- `_supplement.yml`: the `supplement:` map (title, citation, authors,
  licenses, Zenodo DOIs, data files), loaded through `metadata-files`.
- `_extensions/supplement/supplement.lua`: shortcodes `supplement-doi`,
  `supplement-download`, `supplement-data-table`, and
  `supplement-license`. Quarto rewrites any metadata value that names an
  existing path to be page-relative, so the data table and the license
  shortcode undo that. The DOI badge removes a `doi:` or doi.org prefix.
  The page footer in `_quarto.yml` shows the licenses through
  `supplement-license`, each linked to `spdx.org/licenses/<id>.html`
  (a page only for ids that SPDX lists). The license and
  DOI shortcodes apply the rules of `license_id()` and `bare_doi()` and
  stop the render on a value those refuse; `tests/testthat/test-agreement.R`
  runs the same value shapes through both sides.
- `index.qmd` reads its paper facts from `_supplement.yml` and lists the
  reports in `analyses/` through a Quarto table listing.
  `analyses/example.qmd`, `data/example.csv`, and license files are starter
  content for the author to replace. The example report saves
  `figures/bootstrap-means.png` and makes `figures/` when it is missing; the
  template ships no `figures/` folder.

Tests in `tests/testthat/` build a site from the template in a temporary
folder with the Quarto CLI and skip on CRAN or when quarto is missing.
The metadata writer tests need no Quarto.
`.github/workflows/R-CMD-check.yaml` runs `R CMD check` on Windows, macOS,
and Ubuntu with the R release and Quarto 1.10, with `NOT_CRAN=true` so the
render tests run, then lists the skipped tests and fails on a skip for a
missing tool (D-016).

## Known issues

- YAML insert edge shapes: `add_report()` and `add_data()` edit YAML as text, so some valid shapes at the end of the last item are refused: `#` lines inside a block scalar, and `|+` trailing blank lines. A menu that already lists `analyses/<name>.qmd` with the file gone gets a second item. A file with CR-only line endings reads as one line, so its menu or list reads as missing. A block-scalar value at the very end of a file with no final line break gains a trailing line break after the insert. Accepted under the text-insertion rule (D-010); routed from candidates 2026-10-18; added 2026-10-18 — M007 review.
- Shortcode edge cases: the home-page shortcodes read `_supplement.yml` values after Markdown parsing, so some values render wrongly or disagree with `write_citation()`. `file` names with `%`, `#`, `--`, or `_x_` break. A `data` map instead of a list renders nothing, and bare strings give `not found: ''`. A path outside the project or an absolute path renders but is not published. A `{{< meta >}}` value that names an existing path is rewritten on subfolder pages, and a description written as `../data` shows as `data` there. A fresh site has an empty paragraph under "Archived Version". `quarto-required: ">=1.4.0"` is untested below 1.10. The footer cannot see backslash escapes or HTML entities in a license id, or an unquoted number or `yes` in a license value (these render while `write_citation()` refuses them), and the badge reads `--`, `'`, or a non-breaking space in a DOI suffix after Markdown changes it. Narrowed by M014 (`supplement-license` stops unless it has one argument, `code` or `content`). Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-18 — M004 review, M014 plan.
- Footer and badge remainder: more cases where the footer or badge disagrees with `write_citation()`, as in the shortcode entry above. A DOI with Markdown emphasis (`10.5281/*zenodo*.1`) gives a badge for `10.5281/zenodo.1`, while `CITATION.cff` holds the raw text. `license: "MIT"` or `zenodo: "x"` (text where a map belongs) renders an empty footer or no badge, while `write_citation()` raises `supplement_error_field_type`. Unquoted `code: 1.0` shows "1" linked to spdx.org/licenses/1.html. A site that keeps the old footer (`[{{< supplement-license code >}}](…LICENSE.md)`) and copies in the new extension gets a link inside a link. An id that SPDX lists but the footer's table of 8 does not, written in another letter case (`apache-1.1`), may link to a missing page if spdx.org paths depend on case (not checked). The `supplement-download` link joins a two-paragraph `zenodo.archive-url` into one address. Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-19 — M014 review.
- Release edge cases: `release_supplement()` and the writers edit and read `_supplement.yml` as text (D-010, D-011), so some inputs get the wrong message or result. A tab before the colon (`version\t: "1.0.0"`) is valid YAML, but the release stops with `supplement_error_no_version`, and its hint invites a second `version:` key. A CR-only `_supplement.yml` reads as one line, so its `version:` line reads as missing (as in the YAML insert entry above). A flow map `supplement: {version: …}` gets a hint to add a line at the indent of `paper-title:`, which a flow map does not have. A tagged or anchored value (`version: !!str 1.2.3`) gets a message that says there is no `version:` value. A linked `_supplement.yml` is written through its link, while linked outputs are refused. When the only row is the exempt `CITATION.cff` DOI row, `check_supplement()` prints "1 problem found" and the release then goes ahead. A full disk during a standalone `write_citation(overwrite = TRUE)` or `write_zenodo(overwrite = TRUE)` leaves the old file truncated, with no restore. A `bump` with invalid UTF-8 gives the right error and also a base warning from `grepl(perl = TRUE)` in `is_version()` (RR01 finding 5.2). On macOS `file.exists()` ignores letter case, so a lowercase `citation.cff` is read and replaced as the output. On Windows, the link refusal for `CITATION.cff` and `.zenodo.json` reads `is_link()`, which misses a file link to a missing file (candidate row "Windows file links"; corrected M018, which made `is_link()` find junctions), and the folder check in `read_outputs()` uses `file.access()`, which may misfire there or on network drives (its test skips Windows). Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-18 — M009 review.
- Release snapshot remainder: the release is not protected against edits made while `check_supplement()` runs (the help page says so). A save to `_supplement.yml` after `check_unchanged()` reads it again and before the release writes it is lost with no message. `_supplement.yml` is never refused as a link, so a link put in its place during the check, to a file with the same bytes, is written through. When an output becomes a link, a folder, or a file that cannot be read during the check, the `supplement_error_file_exists` or `supplement_error_write` message does not say that `_supplement.yml` also changed. Narrowed by M012 (one read before the check, and a folder at an output refused before and after it). Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-18 — M011 review.
- Release write order remainder: an interrupt after the last write returns and before the restore guard is marked done still puts back all three files, with no warning. An error inside the put-back after a failed write leaves the guard unmarked, so the put-back runs again on exit and warns "The release was interrupted", the wrong word for an error. The release and the writers parse `_supplement.yml` in two ways (`yaml.load()` on lines with a final line break added, and `yaml.load()` on the text that `read_yaml()` would read, with no final line break; corrected M016): a block scalar at the end of a file with no final line break, or a `|+` block, reads with extra line breaks on the release side, and `clean_space()` in `value()` is what keeps the output bytes equal. No test covers such a file, and the parser's line number for an error at the end of the file differs between the two. Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-18 — M012 review.
- Parse error edge cases: `read_supplement()` reads a `_supplement.yml` that is not UTF-8 only up to the bad byte, with a warning, so `write_citation()`, `write_zenodo()`, and `check_supplement()` judge the cut text (a run gave `supplement_error_authors`), while `release_supplement()` and `add_data()` give `supplement_error_encoding`. With `options(warn = 2)`, a yaml warning such as the one for `!!float abc` becomes `supplement_error_parse`. `read_supplement()` keeps the incomplete-final-line warning of `read_yaml()`, which the release read does not give. Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-19 — M016 review.
- Release check edge cases: `check_supplement()` misses or misreports some repository states. A file in Git LFS reads as its full size in the large-file check. A large or `.rds` file committed earlier and since deleted is not seen, though a push still sends it. A second Zenodo badge on the home page (for a related dataset) gives a `doi-mismatch` row. A large file that is staged and then deleted from disk gives no row. A `docs/` folder with no `index.html` (one report rendered by name) gives no `not-rendered` row. A report that `.gitignore` blocks still gets a `no-stored-output` row. A UTF-16 `CITATION.cff` is judged though GitHub reads only UTF-8. On a Mac without developer tools, `git --version` may open an install dialog (not confirmed). Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-18 — M008 review.
