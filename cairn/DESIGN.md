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
in `_freeze/`, so the site rebuilds without the private data and without R
once each report holds stored output (corrected M041).

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
- tool report: `check_tools()`
- container recipe: `write_dockerfile()`

Status and order live in `ROADMAP.md`.

## Conventions

- Pure R, with no compiled code (chosen at init, 2026-10-18). This covers
  package code. The template may carry Quarto Lua scripts (D-023, corrected
  M048) and a Quarto Lua extension (M004), which need no R.
- One metadata file (`_supplement.yml`) is the single source for citation,
  authors, ORCIDs, DOIs, and licenses. `CITATION.cff` and `.zenodo.json`
  are generated from it.
- The package never runs `git tag`, `git push`, or a GitHub release. It
  prints those commands for the author to run. It never runs Docker or
  renv either: `write_dockerfile()` writes the recipe, and the help and
  the guide show the commands (M032).
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
`is_link()` also counts a path that `fs::is_link()` reports as a link
(D-022), which finds a file link to a missing file, and a path that its
folder lists but that does not exist, or that resolves to a place other
than its folder plus its name (corrected M045).
`write_citation()` writes `CITATION.cff` (CFF 1.2.0) and
`write_zenodo()` writes `.zenodo.json` from that map. Both check each
license id they write with `license_id()`, a shape check only (D-012). Both leave out
empty values and refuse to replace an existing file unless
`overwrite = TRUE`. `check_overwrite()`, which they and
`write_dockerfile()` call, refuses a link at any target first, whatever
`overwrite` is, then a folder, then an existing file (M035), a link to a
missing file included on Windows (corrected M045).
`R/create-supplement.R`: `create_supplement()` copies the installed
template into a folder, refuses any file, folder, or link in its way
before it writes, removes what it made when a write fails, and with
`repo` fills the GitHub placeholders. It never runs git. After the copy
it runs the lookups of `R/check-tools.R` (through `tool_problems()`) and names
each missing, too old, or off-path tool in its closing message; an error
or a warning in the lookups gives no line.
`R/check-tools.R`: `check_tools()` looks for Quarto (system path, then
`QUARTO_PATH`, then `editor_quarto_paths()`, the RStudio and Positron
copies), knitr and rmarkdown (`package_version_text()` reads DESCRIPTION
without loading), git, and gh, and lists two account reminders. It reads
the Quarto version from `share/version` beside `bin/` after following a
link, and compares it with `quarto_minimum` (1.4.0, the template
extension's `quarto-required`). Program lookups use `Sys.which()`, which
on Unix starts a shell that runs `which`; no looked-up tool is run.
`R/add-report.R` and `R/add-data.R`: `add_report()` writes a report stub
in `analyses/`, starting with the example report's `site` chunk
(`site_chunk()`) and ending with its "Computing environment" section
(`environment_section()`), both read from the installed template, and
adds it to the Analyses menu in `_quarto.yml`;
`add_data()` copies a file into `data/` and adds it to the `data` list in
`_supplement.yml`. Both check every argument and the target file before
the first write, and refuse a linked `analyses/` or `data/` folder. Both
refuse names that Windows reserves for a device (`windows_reserved()` in
`R/add-utils.R`), and `add_data()` refuses a base name that ends in `.`.
`R/yaml-insert.R` adds a list item as lines of text, so comments stay
(D-010), and replaces a one-line map value on its line (D-011); it
re-reads the result with the yaml package before any write.
Its `yaml_read_file_text()` reads a site YAML file and turns the yaml
package's error into `supplement_error_parse`, which names the file and
gives the parser's message. `read_supplement()`, the release read, and
`append_item()` call it, so every function that reads `_supplement.yml`
or `_quarto.yml` gives that class for a file that does not parse.
Every YAML parse in `R/` goes through `yaml_load_list()` or
`yaml_scalar()`, and both pass `eval.expr = FALSE`, so no read runs
`!expr` code under `options(yaml.eval.expr = TRUE)` (M025).
`R/add-utils.R` holds the checks the two share.
`R/write-dockerfile.R`: `write_dockerfile()` reads the R and renv versions
of `renv.lock` with jsonlite, refuses a repeated key among the five it
reads before any value check (M035), refuses R before 4.0.0 and renv before 1.3.1,
and writes `.dockerignore` (`*`, `!renv.lock`) and then a `Dockerfile` from
`rocker/r-ver:<R>`, optionally pinned by digest. The build installs Quarto
with Rocker's script, a temporary renv that installs the Ubuntu packages
`renv::sysreqs()` lists, and `renv::restore()` into
`RENV_PATHS_LIBRARY=/opt/renv/library` with renv's cache off. It refuses a
link or folder at either target even with `overwrite = TRUE`, through
`check_overwrite()` of `R/supplement-yml.R`.
`R/check-supplement.R`: `check_supplement()` changes no file and returns
its problems as a data frame (`check`, `file`, `problem`), with a
`skipped` attribute. Its file size and saved-object checks read `git
ls-files -z --cached --others --exclude-standard`, and its ignored-output
check reads `git ls-files -z --others --ignored --exclude-standard` over
`figures/`, `docs/`, and `_freeze/`, both through `git_run()`, the
package's one `system2()` call. Its `Sys.which()` check, like the
lookups of `check_tools()`, starts a shell that runs `which` on Unix. Its unpublished-figure check
compares the MD5 of each file in `figures/` with its copy in
`docs/figures/`, walking with `plain_files()`, which skips hidden names
and links. Its link check lists `docs/`
with `docs_entries()`, a walk that includes hidden names and does not
enter a linked folder (M022), and gives a row for each link in `docs/`
whose existing target resolves outside it (`in_docs()` compares
normalized paths). It reads the
`href`, `src`, and `xlink:href` values of start tags in the `.html` files
it listed, other than those outside links, with `tag_links()`, which first removes comments and the text of script,
style, textarea, and title elements with one PCRE pattern (no HTML parser
package, M021). `decode_refs()` decodes five named and the number
character references, and the check resolves each link by path segments
inside `docs/`, matching each name's
letter case as GitHub Pages does, and fails a link when a part of its
path resolves outside `docs/`. A bad DOI in `CITATION.cff` or on the
badge gives a row; only a bad DOI in `_supplement.yml` stops the check.
Its placeholder check (`check_placeholders()`, M036) compares four
`_supplement.yml` values with the installed template's, read through
`template_supplement()`. It also looks for the lines of
`placeholder_lines` in seven site files and compares the two example
files with the template's copies through `report_hash()`. A file that it
cannot read as UTF-8 text gives no row and does not stop the check.
Its leftover-output check (`check_leftover_output()`, M042) lists the
folders directly in `_freeze/analyses/` and the names in `analyses/`,
cuts each name before its last `.` with `useBytes = TRUE`, and compares
them with letter case folded by `fold_case()`. That lowers ASCII letters
with `chartr()` first, since `tolower()` follows the locale (Turkish `I`),
then other letters with `tolower()`, and lowers only the ASCII capital
letters of a name that is not valid UTF-8.
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
only files under the site folder, the files that the git checks of
`check_supplement()` read. It starts
no process itself.
Imports: cli, jsonlite, yaml (D-009), and fs (D-022, corrected M045). Roxygen writes Markdown help.

The package ships a Quarto website template in
`inst/template/` (D-003), installed with `quarto use template
jmgirard/supplement/inst/template` or with `create_supplement()`.

- `_quarto.yml`: a website project with `freeze: true` (D-002), output in
  `docs/` (D-001), an Analyses navbar menu, and `data/**` and `figures/**`
  as resources. A render lists the files in `figures/` at its start and
  copies them after the report code runs, so a changed figure under an
  existing name reaches `docs/` in the same render, and a figure saved
  under a new name reaches it on the next render.
- `_scripts/setup.lua` (pre-render): gives `_gitignore` and `_README.md`
  their real names, merges missing rules into an existing `.gitignore`, and
  writes the guide to `SUPPLEMENT.md` beside an existing README (D-004,
  D-006, D-023). Quarto runs it through Pandoc (`--lua-filter`) in the
  project folder, so it uses file names relative to that folder.
- `_scripts/nojekyll.lua` (post-render): writes `.nojekyll` into the output
  folder that `QUARTO_PROJECT_OUTPUT_DIR` names. A render starts no Deno
  process for either script (D-023).
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
  runs the same value shapes through both sides, except on Windows, where
  only its null-and-block test runs (D-020).
- `index.qmd` reads its paper facts from `_supplement.yml` and lists the
  reports in `analyses/` through a Quarto table listing.
  `analyses/example.qmd`, `data/example.csv`, and license files are starter
  content for the author to replace. The template ships
  `figures/bootstrap-means.png`, so the first render publishes it. The
  example report finds the site in its `site` chunk: `QUARTO_PROJECT_DIR`
  if it is not empty, else `.` or `..`, whichever holds `_quarto.yml`, else
  a stop (M034). `add_report()` copies that chunk to the start of each new
  report (`site_chunk()` in `R/add-report.R`). The example stops when
  `figures` is a link (a non-empty `Sys.readlink()`, or a folder whose `normalizePath()` differs in lower case from the
  site's plus `figures`, which finds a Windows junction) and then when it is a file (M046). It makes `figures/` when it
  is missing and saves the figure again with `save_png()`, which renames a temporary file into place only when the file
  ends with the 12-byte PNG `IEND` chunk (D-018, M046). It ends with a "Computing
  environment" section, a collapsed callout whose chunk prints
  `sessioninfo::session_info()` or, without sessioninfo,
  `utils::sessionInfo()`, with the home folder shown as `~`.

Tests in `tests/testthat/` build a site from the template in a temporary
folder with the Quarto CLI and skip on CRAN or when a tool they need,
such as quarto, git, or a png device, is missing.
The metadata writer tests need no Quarto.
The one Docker test in `tests/testthat/test-write-dockerfile.R` builds the
image and renders a report in it only when `SUPPLEMENT_TEST_DOCKER=true`;
the CI workflow does not set it, so that test runs only on a local machine.
In `tests/testthat/test-template.R`, each exit-status check of a command
shows everything the command printed when it fails, through
`expect_status()` or `expect_command_fails()` (`helper-template.R`), or
through `info` in the one test of those helpers.
`run_in()` runs `quarto` with `QUARTO_LOG_LEVEL=DEBUG` unless the variable
is already set, so the output of a
render whose project script failed holds the script's exit code;
`run_split()` sets no log level.
Both run a `quarto` command once more when it fails with "database is
locked", which Quarto's Sass cache gives when parallel renders write it at
once. On Windows they give each test process its own Quarto cache folder
(`LOCALAPPDATA`), since parallel renders there clash over the cache's
`deno_std` folder.
Test files run in parallel (`Config/testthat/parallel` in DESCRIPTION), so
no test relies on state that another test file sets.
`.github/workflows/R-CMD-check.yaml` runs `R CMD check` on Windows, macOS,
and Ubuntu with the R release and Quarto 1.10, with `NOT_CRAN=true` so the
render tests run (D-016), and one test process per runner core (D-020).
The Ubuntu job sets `TMPDIR` to a folder under `$RUNNER_TEMP` because
`/tmp` on that runner image has too little space for the render tests'
large fixtures: on ubuntu-26.04 it is a 7.9 GB tmpfs with a user quota
(M047).
`.github/scripts/check-skips.R` then reads the skipped tests from the test
output that R CMD check keeps, with no second test run, and fails on a skip
for a missing tool. A last step runs `tests/testthat/test-source.R`, whose
tests read the package's R files, from the checkout (D-020).

## Known issues

- Leftover output limits: the `"leftover-output"` row of `check_supplement()` reads only the folders directly in `_freeze/analyses/`, so a leftover folder inside a subfolder there, or directly in `_freeze/`, gives no row. Any file or folder in `analyses/` with the folder's name before its last `.`, such as a helper `<name>.R`, hides a leftover, and so does a report whose name differs only in letter case, as after a case-only rename on Linux. The help page states these. Accepted at the M042 plan (the match never tells an author to delete live output); added 2026-10-23 — M042 review. See the candidate row "Match folder names across Unicode forms".
- Format hint on a live file: the `"stale-output"` row's format hint appears whenever one stored output file of a report matches and another differs. After `quarto render <file> --to html`, a live `docx.json` differs while `html.json` matches, so the hint says it can be from a dropped format. The hint says "can be" and gives the render steps for the other case. Accepted at the M043 question set (the user chose naming the files over reading the formats a report renders); added 2026-10-23 — M043 review.
- YAML insert edge shapes: `add_report()` and `add_data()` edit YAML as text, so some valid shapes at the end of the last item are refused: `#` lines inside a block scalar, and `|+` trailing blank lines. A menu that already lists `analyses/<name>.qmd` with the file gone gets a second item. A file with CR-only line endings reads as one line, so its menu or list reads as missing. A block-scalar value at the very end of a file with no final line break gains a trailing line break after the insert. Accepted under the text-insertion rule (D-010); routed from candidates 2026-10-18; added 2026-10-18 — M007 review.
- Shortcode edge cases: the home-page shortcodes read `_supplement.yml` values after Markdown parsing, so some values render wrongly or disagree with `write_citation()`. `file` names with `%`, `#`, `--`, or `_x_` break. A `data` map instead of a list renders nothing, and bare strings give `not found: ''`. A path outside the project or an absolute path renders but is not published. A `{{< meta >}}` value that names an existing path is rewritten on subfolder pages, and a description written as `../data` shows as `data` there. A fresh site has an empty paragraph under "Archived Version". `quarto-required: ">=1.4.0"` is untested below 1.10, and so are the template's Lua project scripts, though `check_tools()` accepts Quarto 1.4.0 and later (added M048). The footer cannot see backslash escapes or HTML entities in a license id, or an unquoted number or `yes` in a license value (these render while `write_citation()` refuses them), and the badge reads `--`, `'`, or a non-breaking space in a DOI suffix after Markdown changes it. Narrowed by M014 (`supplement-license` stops unless it has one argument, `code` or `content`). Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-18 — M004 review, M014 plan.
- Footer and badge remainder: more cases where the footer or badge disagrees with `write_citation()`, as in the shortcode entry above. A DOI with Markdown emphasis (`10.5281/*zenodo*.1`) gives a badge for `10.5281/zenodo.1`, while `CITATION.cff` holds the raw text. `license: "MIT"` or `zenodo: "x"` (text where a map belongs) renders an empty footer or no badge, while `write_citation()` raises `supplement_error_field_type`. Unquoted `code: 1.0` shows "1" linked to spdx.org/licenses/1.html. A site that keeps the old footer (`[{{< supplement-license code >}}](…LICENSE.md)`) and copies in the new extension gets a link inside a link. An id that SPDX lists but the footer's table of 8 does not, written in another letter case (`apache-1.1`), may link to a missing page if spdx.org paths depend on case (not checked). The `supplement-download` link joins a two-paragraph `zenodo.archive-url` into one address. Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-19 — M014 review.
- Release edge cases: `release_supplement()` and the writers edit and read `_supplement.yml` as text (D-010, D-011), so some inputs get the wrong message or result. A tab before the colon (`version\t: "1.0.0"`) is valid YAML, but the release stops with `supplement_error_no_version`, and its hint invites a second `version:` key. A CR-only `_supplement.yml` reads as one line, so its `version:` line reads as missing (as in the YAML insert entry above). A flow map `supplement: {version: …}` gets a hint to add a line at the indent of `paper-title:`, which a flow map does not have. A tagged or anchored value (`version: !!str 1.2.3`) gets a message that says there is no `version:` value. A linked `_supplement.yml` is written through its link, while linked outputs are refused. When the only row is the exempt `CITATION.cff` DOI row, `check_supplement()` prints "1 problem found" and the release then goes ahead. A full disk during a standalone `write_citation(overwrite = TRUE)` or `write_zenodo(overwrite = TRUE)` leaves the old file truncated, with no restore, and so does `write_dockerfile(overwrite = TRUE)` for `.dockerignore` or the `Dockerfile` (added M032). A `bump` with invalid UTF-8 gives the right error and also a base warning from `grepl(perl = TRUE)` in `is_version()` (RR01 finding 5.2), and so does a `quarto` or `digest` of `write_dockerfile()` with invalid UTF-8 (added M032). On macOS `file.exists()` ignores letter case, so a lowercase `citation.cff` is read and replaced as the output. On Windows, the folder check in `read_outputs()` uses `file.access()`, which may misfire there or on network drives (its test skips Windows); since M045 the link refusals of the release and of the three writers find a file link to a missing file there (corrected M045). Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-18 — M009 review.
- Release snapshot remainder: the release is not protected against edits made while `check_supplement()` runs (the help page says so). A save to `_supplement.yml` after `check_unchanged()` reads it again and before the release writes it is lost with no message. `_supplement.yml` is never refused as a link, so a link put in its place during the check, to a file with the same bytes, is written through. When an output becomes a link, a folder, or a file that cannot be read during the check, the `supplement_error_file_exists` or `supplement_error_write` message does not say that `_supplement.yml` also changed. Narrowed by M012 (one read before the check, and a folder at an output refused before and after it). Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-18 — M011 review.
- Release write order remainder: an interrupt after the last write returns and before the restore guard is marked done still puts back all three files, with no warning. An error inside the put-back after a failed write leaves the guard unmarked, so the put-back runs again on exit and warns "The release was interrupted", the wrong word for an error. The release and the writers parse `_supplement.yml` in two ways (`yaml.load()` on lines with a final line break added, and `yaml.load()` on the text that `read_yaml()` would read, with no final line break; corrected M016): a block scalar at the end of a file with no final line break, or a `|+` block, reads with extra line breaks on the release side, and `clean_space()` in `value()` is what keeps the output bytes equal. No test covers such a file, and the parser's line number for an error at the end of the file differs between the two. Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-18 — M012 review.
- Parse error edge cases: `read_supplement()` reads a `_supplement.yml` that is not UTF-8 only up to the bad byte, with a warning, so `write_citation()`, `write_zenodo()`, and `check_supplement()` judge the cut text (a run gave `supplement_error_authors`), while `release_supplement()` and `add_data()` give `supplement_error_encoding`. With `options(warn = 2)`, a yaml warning such as the one for `!!float abc` becomes `supplement_error_parse`. `read_supplement()` keeps the incomplete-final-line warning of `read_yaml()`, which the release read does not give. Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-19 — M016 review.
- Release check edge cases: `check_supplement()` misses or misreports some repository states. A `docs/` folder that is itself a symbolic link is read through, and links that point into its target count as inside `docs/` (added M022). A file in Git LFS reads as its full size in the large-file check. A large or `.rds` file committed earlier and since deleted is not seen, though a push still sends it. A second Zenodo badge on the home page (for a related dataset) gives a `doi-mismatch` row. A large file that is staged and then deleted from disk gives no row. A `docs/` folder with no `index.html` (one report rendered by name) gives no `not-rendered` row. A report that `.gitignore` blocks still gets a `no-stored-output` row. A UTF-16 `CITATION.cff` is judged though GitHub reads only UTF-8. On a Mac without developer tools, `git --version` may open an install dialog (not confirmed). Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-18 — M008 review.
- Release pathspec edge cases: the commit command that `release_supplement()` prints, `git commit -m "Release vX.Y.Z" -- .`, is a partial commit, which git refuses while a merge, a cherry-pick, or a revert with a conflict is in progress, so a release run then stops at that command. A site folder that git ignores, with files added by force, makes `git add -A -- .` exit 1, and the new `CITATION.cff` and `.zenodo.json` are not committed (as before). Running the add and commit again with nothing changed exits 1 and lists files outside the site. Windows PowerShell may drop the `--` (not checked; harmless if so). Accepted at the 2026-10-19 triage; routed from candidates 2026-10-19; added 2026-10-19 — M015 review, M015 plan.
- Link reader limits: `tag_links()` reads some pages differently from a browser, as the `check_supplement()` help page lists. A named character reference other than `&amp;`, `&lt;`, `&gt;`, `&quot;`, and `&apos;` (such as `&eacute;` or `&AMP;`), and a reference with no `;`, stay as written, so a link that holds one gives a row even when the file exists. Other control characters at the ends of a link stay. The text of `<noscript>`, `<xmp>`, `<iframe>`, `<noembed>`, `<noframes>`, and `<plaintext>`, and of a CDATA section after its first `>`, is read as markup. The four skipped elements are also skipped inside `<svg>` and `<math>`. An unclosed quote starts an unquoted value, an invalid byte's `>` ends its tag, and a second attribute of the same name is also read. Accepted at the M021 plan, where the user chose a base R reader over xml2 (D-017); added 2026-10-20 — M021 review. See the candidate rows "Close the link reader's browser gaps" and "Read huge script bodies past PCRE limits".
- Report reading edges: `check_supplement()` reads a report differently from Quarto 1.10 in four cases. A UTF-8 BOM keeps the first line from being `---`, so `engine: knitr` is not read and a report with only inline code gives no row. Bytes that are not UTF-8 in the front matter, such as a Latin-1 `é`, fail the front matter read the same way, though Quarto renders both and runs knitr (`read_text_lines()` in `R/yaml-insert.R` drops a BOM). Inline code with a tab after `{r}` runs and is not counted (the help page says so). Quarto skips `` `{r} x` `` when a backtick comes just before it, and the check counts it. Accepted at the 2026-10-22 triage; routed from candidates 2026-10-22; added 2026-10-20 — M026 review.
- Stored output hash edges: `check_stale_output()` reads differently from Quarto 1.10.19 in these cases. A report byte that is not valid UTF-8 is hashed as the raw byte, while Quarto hashes U+FFFD, so such a report gets a `stale-output` row after each render, which stops `release_supplement()` (the help page says so). `json[["hash"]]` takes the first of two `hash` keys, while `JSON.parse` takes the last. Bytes that are not UTF-8 in a JSON file give the "cannot be read" text, though Quarto reads the file. Each JSON file is parsed whole, and one of 2 GiB or more fails `rawToChar()`; reports and JSON files that large were not tested. A warning from the temporary-file write (a full disk) gives no row. See the report reading entry. Accepted at the 2026-10-22 triage; routed from candidates 2026-10-22; added 2026-10-20 — M027 review.
- Figure check edge cases: `check_unpublished_figures()` reads through a `docs/figures` that is itself a link, so a link to a folder of equal copies inside `docs/` gives no row from any check. On macOS a figure whose name differs from its copy only in letter case gives no row, while GitHub Pages matches case. A figure that cannot be read gets the "missing or differs" text, and the files of a folder in `figures/` that cannot be read give no row. git lists an ignored nested repository in `docs/` as one folder entry, so its files get no `ignored-output` row. On Windows a file link to a missing file in a published folder could get an `ignored-output` row before M045, when `is_link()` missed such a link; not checked since M045, as no test makes that case. A site that ignores all of `docs/` prints one row per file. Accepted at the 2026-10-22 triage; routed from candidates 2026-10-22; added 2026-10-20 — M029 review.
- Placeholder check limits: the `"placeholder"` rows of `check_supplement()` match only a whole value or a whole line of the installed template. A citation that keeps part of a placeholder, such as `(Year)`, gives no row, nor does a site made from an older template whose placeholders differ. A file that cannot be read gives no row, and the check never stops on one. The template guide's placeholder citation, the example figure, the example's `data:` description, and the "Example Analysis" menu item give no row. The help page states the first three. Accepted at the M036 plan; added 2026-10-22 — M036 review. See the candidate rows "Match example files after editor saves" and "Split the template guide by reader".
