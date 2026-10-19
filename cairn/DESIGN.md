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
(`drop_trailing_sep()`, `path_occupied()`, `is_link()`). `write_citation()` writes `CITATION.cff` (CFF 1.2.0) and
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
`R/release-supplement.R`: `release_supplement()` checks `bump`, the
current `supplement.version`, and the `version:` line, refuses a
`CITATION.cff` or `.zenodo.json` that is a link or cannot be read or
written, or that is missing in a folder it cannot write, then runs
`check_supplement()`. It reads the three files again and stops
(`supplement_error_changed`) when one of them changed, or was made or
removed as a file, during the check; a folder at an output reads as no
file both times. It then stops on any problem but a `CITATION.cff` DOI
row. It then writes `_supplement.yml`, `CITATION.cff`,
and `.zenodo.json` and prints the git and `gh` release commands. When any
of those steps stops, or on an interrupt, it puts back each file whose
bytes changed and removes each file it made. It starts no process
itself.
Imports: cli, jsonlite, yaml (D-009). Roxygen writes Markdown help.

The package ships a Quarto website template in
`inst/template/` (D-003), installed with `quarto use template
jmgirard/supplement/inst/template` or with `create_supplement()`.

- `_quarto.yml`: a website project with `freeze: true` (D-002), output in
  `docs/` (D-001), an Analyses navbar menu, and `data/**` as resources.
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
  `supplement-license`.
- `index.qmd` reads its paper facts from `_supplement.yml` and lists the
  reports in `analyses/` through a Quarto table listing.
  `analyses/example.qmd`, `data/example.csv`, and license files are starter
  content for the author to replace.

Tests in `tests/testthat/` build a site from the template in a temporary
folder with the Quarto CLI and skip on CRAN or when quarto is missing.
The metadata writer tests need no Quarto.

## Known issues

- YAML insert edge shapes: `add_report()` and `add_data()` edit YAML as text, so some valid shapes at the end of the last item are refused: `#` lines inside a block scalar, and `|+` trailing blank lines. A menu that already lists `analyses/<name>.qmd` with the file gone gets a second item. A file with CR-only line endings reads as one line, so its menu or list reads as missing. A block-scalar value at the very end of a file with no final line break gains a trailing line break after the insert. Accepted under the text-insertion rule (D-010); routed from candidates 2026-10-18; added 2026-10-18 — M007 review.
