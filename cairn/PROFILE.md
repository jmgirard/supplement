# Profile

## Verify

Run by `/milestone-implement` (per task) and `/hotfix` (gate-lite):
- After roxygen changes: `Rscript -e 'devtools::document()'`.
- After code changes, before a task is checked off: `Rscript -e 'devtools::test()'` clean.
- `/hotfix` gate-lite: `devtools::test()` clean; `devtools::document()` if
  roxygen changed; `devtools::check()` if anything structural was touched.

Toolchain checks `/milestone-review` runs *in addition to* the universal
cairn-file checks (`cairn_validate`, coverage completeness, `cairn_impact`):
- `devtools::document()` produces no diff.
- Generated files are never hand-edited: `NAMESPACE`, `man/`, and `data/*.rda`
  regenerate from roxygen and `data-raw/` scripts (the no-diff `document()`
  check catches drift).
- README.md is knitted from README.Rmd; present and out of sync with README.md → `devtools::build_readme()`, commit.
- pkgdown site present → `pkgdown::check_pkgdown()` passes (catches exports missing from `_pkgdown.yml`).
- The declared changelog (`## changelog` slot) has an entry for this milestone's user-visible changes (no milestone numbers in user-facing text).
- New top-level files have `.Rbuildignore` entries (check `check()` NOTEs).
- Full check at review: `Rscript -e 'devtools::check()'` clean (0 errors, 0 warnings; justify NOTEs). In guest
  collaboration mode (tracking-rules "Collaboration mode") the NOTE for the non-standard top-level `cairn` directory
  is justified by the mode itself — the guest writes no `.Rbuildignore` entry, and the maintainers' CI builds from a
  clone that never holds `cairn/`; no other NOTE inherits this justification.

## Changelog

The repo's changelog file, read by `/hotfix`, the release-walk, and the
consistency-gate: **`NEWS.md`** (the R-package convention).

## Release

Followed by `/cairn-release` — a CRAN release walk (never self-submits):
- Version decision (patch/minor/major) from the declared changelog; pre-1.0 conventions per DESIGN.md.
- Changelog consolidation (the declared file): retitle the dev heading to the version; group entries; prune noise.
- Full local verification: `devtools::document()` (no diff), `devtools::test()`
  and `devtools::check()` clean, `devtools::build_readme()`, `pkgdown::check_pkgdown()`,
  `urlchecker::url_check()`.
- Wide checks as applicable: `devtools::check_win_devel()` and/or R-hub; `revdepcheck` if dependents exist.
- Update `cran-comments.md` in its conventional short form (the shape
  `usethis::use_cran_comments()` produces): R CMD check results with the
  error/warning/NOTE counts, one line of justification per NOTE, the test
  environments, and the revdep summary — a few lines in all. Do not restate NEWS
  or describe the release's changes; reviewers read NEWS for that.
- Bump `Version:` in DESCRIPTION.
- Handoff checklist (user runs): `devtools::submit_cran()`, confirm the CRAN
  email, then `usethis::use_github_release()` + `usethis::use_dev_version()`.
