# Scope draft for the supplement toolkit

**Provenance.** Ingested 2026-10-18 at `/cairn-init`. Sources: a read of `jmgirard/llm-depression-assessment` and `jmgirard/pilot-ptsd-markers` on GitHub, the Quarto CI docs, and a web search for related tools.
Pagination: —.
Extraction: a 2026-10-18 snapshot of the two sites and the related tools, which move on independently — observed 2026-10-18.

**Scope.** This page is the scope draft written before the package had a name. It is a reference, not an authority. Status lives in `ROADMAP.md`, decisions in `DECISIONS.md`, and architecture in `DESIGN.md`. The open decisions and milestones below became ROADMAP candidate rows on 2026-10-18.

## Problem

Authors need a place to share the analysis reports, code, and open data that
support a paper. OSF does not serve HTML pages. So Quarto and R Markdown
reports must embed every resource, and readers must download them first. A Quarto website on GitHub Pages, archived on Zenodo, solves this. But
each new site takes hours of hand work. The first two attempts
(`jmgirard/llm-depression-assessment`, `jmgirard/pilot-ptsd-markers`) repeat
the same files almost line for line.

## What the two existing sites do

Both sites use the same layout:

- `src/` holds the `.qmd` reports in a separate `type: default` project.
- Each report renders there as a standalone page. You copy the HTML and its
  `_files/` folder into `analyses/` by hand.
- The root website renders only `index.qmd` and ships `analyses/` as static
  resources into `docs/`, which GitHub Pages serves.
- `index.qmd` holds the citation, the Zenodo DOI badge, a report table, a
  data table with download buttons, and a data-availability statement.
- `.zenodo.json` and `CITATION.cff` repeat the same authors, ORCIDs, title,
  and DOIs by hand.

The navbar drops on analysis pages because those pages render outside the
website. Quarto adds the navbar only to pages that the website project
renders. The copy step also puts a full copy of Bootstrap and the Quarto
scripts (about 900 KB) next to each report.

## The core fix: render reports inside the site with freeze

Quarto has a feature for this case. Freeze stores the computed output of
each document in a `_freeze/` folder. A later site render reuses the stored
output and does not run the code again. With `execute: freeze: true` at the
project level, a project render never re-runs a report that already holds stored output. If you render one report by name, Quarto re-runs that report.

This gives the following result:

- Every report is a normal website page. So every page gets the navbar,
  the footer, site search, and one shared copy of the site libraries.
- A report that needs private data renders once on your machine. After
  that, anyone can rebuild the whole site from the repository without the
  data, and without R.
- The manual copy step and the `src/` versus `analyses/` split go away.

Two facts carry over from the current setup. First, `_freeze/` and `docs/`
contain everything a report prints, so a report that prints raw rows makes
those rows public. Second, model fit files (`.rds`) can embed the data and
must stay out of git.

## Deliverables

The toolkit has two layers. The template layer works for anyone who uses
Quarto, in R or Python. The R package adds the steps that a template cannot
do.

### Layer 1: Quarto template and extension

The template is a set of starter files that `quarto use template` copies.
The extension is a folder of shortcodes and styles that Quarto loads.

- A website `_quarto.yml` with freeze on, `output-dir: docs`, an Analyses
  menu in the navbar, a GitHub icon, and the license footer.
- One metadata file (`_supplement.yml`) that holds the paper citation,
  authors, ORCIDs, affiliations, DOIs, licenses, and contact. The site reads
  it through `metadata-files`.
- Shortcodes for the repeated parts of the home page. These are the
  citation block, the DOI badge, and the "download all from Zenodo" button.
  A fourth shortcode makes a data-file row with its size and a download
  button.
- A home page, one example report, a `data/README.md` codebook stub, and
  MIT and CC BY 4.0 license files.
- A `.gitignore` that blocks `.rds` files, fit folders, caches, and common
  private-data folder names.

### Layer 2: R package

- `create_supplement(path)` asks for the paper title, authors, and
  repository name, then writes the template.
- `add_report(name, title, description)` adds a `.qmd` file and its navbar
  and home-page entries.
- `add_data(file, description)` copies a data file into `data/`, adds its
  row to the home page, and adds a stub section to the codebook.
- `write_citation()` and `write_zenodo()` generate `CITATION.cff` and
  `.zenodo.json` from `_supplement.yml`, so the metadata lives in one place.
- `check_supplement()` runs before each release. It finds files over the
  GitHub 100 MB limit, tracked `.rds` files, and reports with no stored
  freeze output. It also finds broken internal links and DOIs that differ
  between `_supplement.yml` and the README badge.
- `release_supplement(version)` updates the version and date, regenerates
  the metadata files, renders the site, and prints the `git tag` and
  GitHub release commands. You run those commands yourself. Zenodo then
  archives the release through its GitHub integration.

## Decisions to make

1. Where the rendered site lives. The two choices are `docs/` on `main`
   (current setup) or a `gh-pages` branch built by GitHub Actions. With
   `docs/` committed, the Zenodo archive contains the rendered reports, so
   the citable copy is readable without Quarto. With `gh-pages`, the
   archive contains only source and `_freeze/`. Recommendation: `docs/`,
   with an optional Actions workflow for people who prefer `gh-pages`.
2. Freeze level. `freeze: true` protects private-data reports from an
   accidental re-run. If a source file changes, `freeze: auto`
   re-runs that report. If the data is not present, the re-run fails. Recommendation:
   `true` for the project, with a note on how to re-render one report.
3. One repository or two. A Quarto extension installs from a repository
   with `_extensions/` at the root. An R package can carry a copy in
   `inst/`. Recommendation: one repository that is the R package. It
   keeps `_extensions/` at the root, excluded in `.Rbuildignore`, and a
   build step copies that folder into `inst/`. If needed, split it later.
4. How much of `index.qmd` is generated. Shortcodes keep the page as
   editable text. Full generation from YAML gives less freedom.
   Recommendation: shortcodes.

## Out of scope for version 1

- Large data. Files over GitHub limits go to Zenodo directly, and the site
  links to them.
- Calls to the Zenodo API. The GitHub integration already creates the
  records and DOIs.
- Python helper functions. The template works with Python reports, but the
  helpers are R only.
- Migration of the two existing sites. They are good test cases for a
  later `migrate` step, but that step is not part of the first release.

## Related tools

None of these covers a supplement site with Zenodo metadata:

- Quarto manuscripts publish an article with linked notebooks. The article
  is the center, not the supplement.
- workflowr publishes R Markdown analysis sites to GitHub Pages. It
  predates Quarto and has no Zenodo or citation metadata.
- rrtools builds a research compendium as an R package, with no website.
- The Open Research Data Template (Mähr and Twente) uses GitHub, Pages, and
  Zenodo for research-data documentation, not for analysis reports.

## Proposed milestones

1. Template only. Port the pilot-ptsd-markers site to the freeze layout by
   hand. Make sure that the navbar shows on every page and that a fresh
   clone builds without the data. Then extract the template.
2. R package: `create_supplement()`, `add_report()`, `add_data()`, and the
   metadata writers, with tests.
3. `check_supplement()` and `release_supplement()`.
4. Documentation site (built with the toolkit itself) and a walkthrough for
   first-time GitHub and Zenodo users.
