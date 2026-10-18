# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-10-18 (M002 done and archived, pilot row graduated, template row points at the pilot findings)_

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M003 | Package skeleton and starter template | in-progress | — | high | milestones/M003-template-starter.md |
| M004 | Home page from _supplement.yml with shortcodes | planned | M003 | high | milestones/M004-home-page-shortcodes.md |
| M002 | Pilot render on the data machine and data-free rebuild | done | M001 | high | milestones/archive/M002-pilot-render-check.md |
| M001 | Pilot site restructure to the freeze layout | done | — | high | milestones/archive/M001-pilot-restructure.md |

## Candidates

- template extraction: turn the ported pilot site into a `quarto use template` starter with `_supplement.yml` and license files. Add shortcodes for the citation, DOI badge, Zenodo download, and data-file rows. Add a `.gitignore` that blocks fit files and private-data folders. Inputs: `references/pilot-port.md` problems P1 to P7 and P9 to P11. — added 2026-10-18 — started M003
- scaffolding functions: `create_supplement()`, `add_report()`, and `add_data()`, with tests. — added 2026-10-18
- metadata writers: `write_citation()` and `write_zenodo()` generate `CITATION.cff` and `.zenodo.json` from `_supplement.yml`. — added 2026-10-18
- release checks: `check_supplement()` finds files over 100 MB, tracked `.rds` files, reports with no freeze output, broken links, and mismatched DOIs. `release_supplement()` bumps the version and prints the tag and release commands. — added 2026-10-18
- template install from GitHub: run `quarto use template jmgirard/supplement/inst/template` against the merged main, and recommend a pinned tag (`@vX.Y.Z`) once a release exists. From the M003 review. — added 2026-10-18
- docs site and walkthrough: a package site built with the toolkit itself, plus a first-time guide to GitHub Pages and Zenodo. — added 2026-10-18
- site output location: `docs/` on the default branch keeps rendered reports in the Zenodo archive. A `gh-pages` branch built by GitHub Actions keeps rendered files out of the source. Recommendation from the scope draft: `docs/`, with an optional Actions workflow. — added 2026-10-18 — started M003
- freeze level: `freeze: true` never re-runs a report on a project render. `freeze: auto` re-runs a changed report. If the data is absent, that re-run fails. Recommendation from the scope draft: `true`. — added 2026-10-18 — started M003
- extension packaging: one repository that is the R package, with `_extensions/` at the root (in `.Rbuildignore`) copied into `inst/` at build time, or two repositories. Recommendation from the scope draft: one. — added 2026-10-18 — started M003
- paper figure files: the model reports write the paper figures with ggsave to `analyses/*.pdf` and `analyses/*.png`, which `.gitignore` blocks, so the site does not publish them. Decide if the template gives figures a tracked, published folder. From the M001 review. — added 2026-10-18
- [low] existing-site migration: a helper that converts a site with the old `src/` and `analyses/` layout to the freeze layout. Out of scope for version 1. — added 2026-10-18
