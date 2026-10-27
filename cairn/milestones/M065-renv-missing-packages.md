<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M065: Flag packages missing from renv.lock

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a new row kind of the exported `check_supplement()`
- **Branch/PR:** m065-renv-missing-packages

## Goal

`check_supplement(renv_lock = TRUE)` gives a `"renv-missing"` row for each report whose stored output shows a package that the report attached and that `renv.lock` does not name, so that `renv::restore()` would not install it.

## Scope

**In:** These parts:

- the attached packages read from the version lists that `stored_versions()` reads
- the package names that `lock_versions()` reads from `renv.lock`, records with no `Version` text included
- the `"renv-missing"` rows, the skip message, and their tests
- the files that AC6's grep lists: the help pages, NEWS.md, README.md, GUIDE.md, the publishing vignette, and DESIGN.md

**Out:** These parts:

- A row for a package that a report loaded but did not attach. The user chose attached packages only at the plan, since `renv::snapshot()` does not add a package that no project code uses. No candidate row holds it.
- A lockfile other than `renv.lock` in the site folder, such as the lockfile of an renv profile. The candidate row "Read the lockfiles of renv profiles" holds it.
- Python reports. The candidate row "Record the Python setup of reports" holds them.

## Acceptance criteria

- [ ] AC1: With `renv_lock = TRUE`, `check_supplement()` gives one `"renv-missing"` row for each report that can be read, in the list of reports that the `"renv-mismatch"` check reads, whose stored output attached a package that the site's `renv.lock` does not name under `Packages`. The stored output is the `result.markdown` text of the `.json` files that the `"renv-mismatch"` check reads, in the forms that check reads. A package counts as attached when any of these files shows it attached, in one of two ways. In the sessioninfo package table, its line has `*` at the position of the `*` in the header line. In `utils::sessionInfo()` output, it is an entry after `other attached packages:`. A record of `renv.lock` names the package of its `Package` text, or of its key when it has no `Package` text, and a record whose name is empty names no package. Tests in `tests/testthat/test-check-supplement.R` give such a row from the sessioninfo table with and without its `!` column, and from an `other attached packages:` list that spans two `[n]` lines, and compare the row's `check`, `file`, and `problem` with exact expected values.
- [ ] AC2: The `problem` text of a `"renv-missing"` row names the `.json` files that show such a package attached, in the same way as the `"renv-mismatch"` row names files. It names each such package once, in byte order of name. It says that `renv::restore()` does not install them, and gives two ways to clear the row: run `renv::snapshot()` and commit `renv.lock`, or, if the report no longer uses the package, take the render steps of the `"stale-output"` row. When another `.json` file of the report holds a package table or list and attaches none of the row's packages, the row also gives the old-format hint and delete steps of the `"renv-mismatch"` row. Tests assert the exact text for a report with two such packages in two `.json` files, one of the packages attached in both, and for the old-format case.
- [ ] AC3: Each of these cases gives no `"renv-missing"` row, in a test in `tests/testthat/test-check-supplement.R`:
  - a package that is loaded and not attached: a sessioninfo table line with no `*`, or an entry after `loaded via a namespace (and not attached):`
  - a package that `renv.lock` names under `Packages` by its `Package` text, at another version or with no `Version` text, or by its key alone
  - `renv_lock = FALSE`
  - a site with no `renv.lock`, where the skip message names both the `"renv-mismatch"` and the `"renv-missing"` check
  - a `renv.lock` that cannot be read, where the `renv.lock` row of the `"renv-mismatch"` check, with its `problem` text unchanged, is the only row of the comparison
  - a report that cannot be read, such as a link to a missing file

  The `"renv-mismatch"` rows do not change: the `"renv-mismatch"` tests that exist at the plan commit pass with no edit to their expected values. A report that gets both rows lists its `"renv-mismatch"` row first, and the `"renv-missing"` rows follow all `"renv-mismatch"` rows, in the order of the report list.
- [ ] AC4: A Quarto render of the template's example report by name, run with `R_PROFILE_USER` set to an empty file, gives no `"renv-missing"` row against a `renv.lock` whose `Packages` names no package. A render of a report that runs `library(jsonlite)`, run the same way, gives a `"renv-missing"` row that names `jsonlite` against that `renv.lock`. Tests in `tests/testthat/test-add-render.R` show both and skip without Quarto.
- [ ] AC5: `release_supplement()` does not run the check. In a test in `tests/testthat/test-release-supplement.R`, `check_supplement(renv_lock = TRUE)` first gives a `"renv-missing"` row for the site. Then `release_supplement()` releases the same site.
- [ ] AC6: Each file that `grep -rl 'renv_lock' R man README.md NEWS.md vignettes inst/template cairn/DESIGN.md` lists, other than `R/release-supplement.R` and `man/release_supplement.Rd`, says that a package that a report attached and that `renv.lock` does not name gives a `"renv-missing"` row. The help of `release_supplement()` says that it gives neither the `"renv-mismatch"` nor the `"renv-missing"` row. The `check_supplement()` help says that a package that is loaded and not attached gives no row. NEWS.md has no second bullet for it: the unreleased `renv_lock` bullet names it.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T3
- AC6 → T4

## Tasks

- [x] T1: In `R/check-supplement.R`, make `stored_versions()` also return the names of attached packages: in the sessioninfo table, read the character at the position of the header's `*`, beside the `package` and `version` positions it reads now; in `utils::sessionInfo()` output, take the entries after `other attached packages:`. Make `lock_versions()` also return every package name under `Packages`, records with no `Version` text included, with the naming rule of AC1. Test the parser from text, the `!` column table and wrapped `sessionInfo()` lists included (LESSONS M064).
- [ ] T2: In `check_renv_lock()` (`R/check-supplement.R:882`), build the `"renv-missing"` rows of AC1 and AC2 after the `"renv-mismatch"` rows, from the same files read once, and make the skip message name both checks. Write the row tests of AC1 to AC3, each test filtering the result by `check` where it asserts one kind. For each no-row case, plant one attached package that `renv.lock` lacks into the same fixture and see the row appear, so the case is shown able to fail (LESSONS M061).
- [ ] T3: Write the two Quarto tests of AC4 in `tests/testthat/test-add-render.R` beside "a rendered report gives a renv-mismatch row against a renv.lock with another knitr version", and the AC5 test beside the `renv-mismatch` release test in `tests/testthat/test-release-supplement.R`.
- [ ] T4: Update the help of `check_supplement()` and `release_supplement()`, the NEWS.md `renv_lock` bullet, README.md, GUIDE.md's renv part and check list, the publishing vignette, and DESIGN.md. Run `devtools::document()`, then the grep of AC6. Run `devtools::test()` and `devtools::check()` and record their counts in the work log.

## Work log

- 2026-10-27: created by /milestone-plan.
- 2026-10-27: tier check: not run — work named at the question set.
- 2026-10-27: idea vet: one concern, that renv's default snapshot leaves out packages no project code uses, so a row for a loaded-only package could not be cleared by `renv::snapshot()`; the user chose attached packages only.
- 2026-10-27: question set: which candidate to plan — "Flag packages missing from renv.lock"; which packages give a row — attached packages only. No dependency change or other outward action is foreseen.
- 2026-10-27: lessons used: 2026-10-27 (M064), 2026-10-26 (M061), 2026-10-19 (M014).
- 2026-10-27: plan gate chose attached packages only over every loaded package because a loaded-only package can be absent from `renv.lock` by renv's design; falsified by sites whose renv.lock omits packages that a report loads through code renv does not scan.
- 2026-10-27: plan chose a new check name `"renv-missing"` over more text in the `"renv-mismatch"` row because the two have different fixes (snapshot against restore); falsified by users filtering `renv-mismatch` and missing these rows.
- 2026-10-27: plan split the candidate row: the renv profile lockfile part became the candidate row "Read the lockfiles of renv profiles"; the changelog edits the unreleased `renv_lock` bullet of NEWS.md rather than adding one.
- 2026-10-27: a real render of the template example (Quarto, sessioninfo 1.2.4) attached no package, checked before the criteria were written.
- 2026-10-27: criteria audit (full mode, fresh Opus reader): 16 findings. 15 fixed: report list and readability (AC1), record naming and key-only case (AC1, AC3), table and wrap forms (AC1), mixed files (AC1, AC2), old-format hint (AC2), a package in both files (AC2), skip message names both (AC3), lock row text unchanged (AC3), empty lock and `R_PROFILE_USER` (AC4), grep over `renv_lock` and checkable wording (AC6), row order and unchanged mismatch rows (AC3). 1 needed no change (AC5 wording).
- 2026-10-27: implement started on branch m065-renv-missing-packages.
- 2026-10-27: decided the skip message keeps its first sentence and adds "Skipped the "renv-missing" check too.", so it names both checks and the existing skip test's expected text still matches (AC3).
- 2026-10-27: T1 done: `stored_versions()` returns `attached` (table `*` under the header's `*`, `other attached packages:` entries) and `listed`; `lock_versions()` returns `names`. Tests from real sessioninfo and `sessionInfo()` output and from text; `devtools::test()` 448 tests, 0 failed, 10 skipped.

## Decisions

## Review
