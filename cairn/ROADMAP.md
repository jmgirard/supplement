# Roadmap

_The only authority on milestone status. Grouped by status, not ID._
_Last hygiene check: 2026-10-18 (M004 done and archived, template row graduated, M001 row pruned, two review rows added)_

## Milestones

| ID | Title | Status | Depends on | Priority | File/Archive |
|---|---|---|---|---|---|
| M005 | Metadata writers for CITATION.cff and .zenodo.json | review | — | high | milestones/M005-metadata-writers.md |
| M004 | Home page from _supplement.yml with shortcodes | done | M003 | high | milestones/archive/M004-home-page-shortcodes.md |
| M003 | Package skeleton and starter template | done | — | high | milestones/archive/M003-template-starter.md |
| M002 | Pilot render on the data machine and data-free rebuild | done | M001 | high | milestones/archive/M002-pilot-render-check.md |

## Candidates

- scaffolding functions: `create_supplement()`, `add_report()`, and `add_data()`, with tests. — added 2026-10-18
- metadata writers: `write_citation()` and `write_zenodo()` generate `CITATION.cff` and `.zenodo.json` from `_supplement.yml`. — added 2026-10-18 — started M005
- release checks: `check_supplement()` finds files over 100 MB, tracked `.rds` files, reports with no freeze output, broken links, and mismatched DOIs. `release_supplement()` bumps the version and prints the tag and release commands. — added 2026-10-18
- template install from GitHub: recommend a pinned tag (`@vX.Y.Z`) in the README once a release exists. Narrowed 2026-10-18: the untagged route ran after the M003 merge and rendered. From the M003 review. — added 2026-10-18
- Windows check: run the template tests and a render on Windows (CI or by hand), including the no-R test, which skips there, and `nojekyll.ts` with a `C:\` output path. From the M003 review. Also from the M004 review: data files of 2 GiB or more may read as missing (32-bit `ftell` in Windows Lua), and the 1 GB sparse size fixture may cost 1 GB of disk off macOS when Quarto copies it into `docs/`. — added 2026-10-18
- license footer: the template footer in `_quarto.yml` names MIT and CC BY 4.0, while `_supplement.yml` holds `license.code` and `license.content`, which no page reads; drive the footer from `_supplement.yml` so the two cannot differ. From the M004 review. — added 2026-10-18
- shortcode edge cases: from the M004 review. `file` values are read as Markdown, so read the raw value or encode it (names with `%`, `#`, `--`, `_x_` break). A `data` map instead of a list renders nothing, and bare strings give `not found: ''`. A path outside the project or an absolute path renders but is not published. A `{{< meta >}}` value that names an existing path is rewritten on subfolder pages, and a description written as `../data` shows as `data` there. A fresh site has an empty paragraph under "Archived Version". `quarto-required: ">=1.4.0"` is untested below 1.10. — added 2026-10-18
- docs site and walkthrough: a package site built with the toolkit itself, plus a first-time guide to GitHub Pages and Zenodo. — added 2026-10-18
- paper figure files: the model reports write the paper figures with ggsave to `analyses/*.pdf` and `analyses/*.png`, which `.gitignore` blocks, so the site does not publish them. Decide if the template gives figures a tracked, published folder. From the M001 review. — added 2026-10-18
- [low] existing-site migration: a helper that converts a site with the old `src/` and `analyses/` layout to the freeze layout. Out of scope for version 1. — added 2026-10-18
