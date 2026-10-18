# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-10-18 (M003 done and archived, three decision rows graduated, template row narrowed to M004)_

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M004 | Home page from _supplement.yml with shortcodes | review | M003 | high | milestones/M004-home-page-shortcodes.md |
| M003 | Package skeleton and starter template | done | — | high | milestones/archive/M003-template-starter.md |
| M002 | Pilot render on the data machine and data-free rebuild | done | M001 | high | milestones/archive/M002-pilot-render-check.md |
| M001 | Pilot site restructure to the freeze layout | done | — | high | milestones/archive/M001-pilot-restructure.md |

## Candidates

- template extraction: drive the template's home page from `_supplement.yml`, with shortcodes for the DOI badge, Zenodo download, and data-file table. Narrowed 2026-10-18 by M003, which shipped the starter template and its `.gitignore`. — added 2026-10-18 — started M004
- scaffolding functions: `create_supplement()`, `add_report()`, and `add_data()`, with tests. — added 2026-10-18
- metadata writers: `write_citation()` and `write_zenodo()` generate `CITATION.cff` and `.zenodo.json` from `_supplement.yml`. — added 2026-10-18
- release checks: `check_supplement()` finds files over 100 MB, tracked `.rds` files, reports with no freeze output, broken links, and mismatched DOIs. `release_supplement()` bumps the version and prints the tag and release commands. — added 2026-10-18
- template install from GitHub: recommend a pinned tag (`@vX.Y.Z`) in the README once a release exists. Narrowed 2026-10-18: the untagged route ran after the M003 merge and rendered. From the M003 review. — added 2026-10-18
- Windows check: run the template tests and a render on Windows (CI or by hand), including the no-R test, which skips there, and `nojekyll.ts` with a `C:\` output path. From the M003 review. — added 2026-10-18
- docs site and walkthrough: a package site built with the toolkit itself, plus a first-time guide to GitHub Pages and Zenodo. — added 2026-10-18
- paper figure files: the model reports write the paper figures with ggsave to `analyses/*.pdf` and `analyses/*.png`, which `.gitignore` blocks, so the site does not publish them. Decide if the template gives figures a tracked, published folder. From the M001 review. — added 2026-10-18
- [low] existing-site migration: a helper that converts a site with the old `src/` and `analyses/` layout to the freeze layout. Out of scope for version 1. — added 2026-10-18
