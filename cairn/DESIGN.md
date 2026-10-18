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

None built yet. Three families are planned:

- scaffolding: `create_supplement()`, `add_report()`, `add_data()`
- metadata writers: `write_citation()`, `write_zenodo()`
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

The package has no R code yet. It ships a Quarto website template in
`inst/template/` (D-003), installed with `quarto use template
jmgirard/supplement/inst/template`.

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
  `supplement-download`, and `supplement-data-table`. Quarto rewrites any
  metadata value that names an existing path to be page-relative, so the
  data table undoes that for each file and description.
- `index.qmd` reads its paper facts from `_supplement.yml`.
  `analyses/example.qmd`, `data/example.csv`, and license files are starter
  content for the author to replace.

Tests in `tests/testthat/` build a site from the template in a temporary
folder with the Quarto CLI and skip on CRAN or when quarto is missing.

## Known issues

None.
