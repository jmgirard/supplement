# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-10-18 (M001 done and archived, pilot row narrowed to M002, figure row added)_

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M002 | Pilot render on the data machine and data-free rebuild | review | M001 | high | milestones/M002-pilot-render-check.md |
| M001 | Pilot site restructure to the freeze layout | done | — | high | milestones/archive/M001-pilot-restructure.md |

## Candidates

- [high] freeze-layout pilot port: show that a fresh clone of the ported pilot site builds without the private data, with the navbar on every report page. This proves the layout before the template is extracted. Narrowed 2026-10-18 by M001, which did the restructure. — added 2026-10-18 — started M002
- template extraction: turn the ported pilot site into a `quarto use template` starter with `_supplement.yml` and license files. Add shortcodes for the citation, DOI badge, Zenodo download, and data-file rows. Add a `.gitignore` that blocks fit files and private-data folders. — added 2026-10-18
- scaffolding functions: `create_supplement()`, `add_report()`, and `add_data()`, with tests. — added 2026-10-18
- metadata writers: `write_citation()` and `write_zenodo()` generate `CITATION.cff` and `.zenodo.json` from `_supplement.yml`. — added 2026-10-18
- release checks: `check_supplement()` finds files over 100 MB, tracked `.rds` files, reports with no freeze output, broken links, and mismatched DOIs. `release_supplement()` bumps the version and prints the tag and release commands. — added 2026-10-18
- docs site and walkthrough: a package site built with the toolkit itself, plus a first-time guide to GitHub Pages and Zenodo. — added 2026-10-18
- site output location: `docs/` on the default branch keeps rendered reports in the Zenodo archive. A `gh-pages` branch built by GitHub Actions keeps rendered files out of the source. Recommendation from the scope draft: `docs/`, with an optional Actions workflow. — added 2026-10-18
- freeze level: `freeze: true` never re-runs a report on a project render. `freeze: auto` re-runs a changed report. If the data is absent, that re-run fails. Recommendation from the scope draft: `true`. — added 2026-10-18
- extension packaging: one repository that is the R package, with `_extensions/` at the root (in `.Rbuildignore`) copied into `inst/` at build time, or two repositories. Recommendation from the scope draft: one. — added 2026-10-18
- paper figure files: the model reports write the paper figures with ggsave to `analyses/*.pdf` and `analyses/*.png`, which `.gitignore` blocks, so the site does not publish them. Decide if the template gives figures a tracked, published folder. From the M001 review. — added 2026-10-18
- [low] existing-site migration: a helper that converts a site with the old `src/` and `analyses/` layout to the freeze layout. Out of scope for version 1. — added 2026-10-18
