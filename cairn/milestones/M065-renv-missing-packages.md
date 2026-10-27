<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M065: Flag packages missing from renv.lock

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a new row kind of the exported `check_supplement()`
- **Branch/PR:** m065-renv-missing-packages, https://github.com/jmgirard/supplement/pull/66

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

- [x] AC1: With `renv_lock = TRUE`, `check_supplement()` gives one `"renv-missing"` row for each report that can be read, in the list of reports that the `"renv-mismatch"` check reads, whose stored output attached a package that the site's `renv.lock` does not name under `Packages`. The stored output is the `result.markdown` text of the `.json` files that the `"renv-mismatch"` check reads, in the forms that check reads. A package counts as attached when any of these files shows it attached, in one of two ways. In the sessioninfo package table, its line has `*` at the position of the `*` in the header line. In `utils::sessionInfo()` output, it is an entry after `other attached packages:`. A record of `renv.lock` names the package of its `Package` text, or of its key when it has no `Package` text, and a record whose name is empty names no package. Tests in `tests/testthat/test-check-supplement.R` give such a row from the sessioninfo table with and without its `!` column, and from an `other attached packages:` list that spans two `[n]` lines, and compare the row's `check`, `file`, and `problem` with exact expected values.
- [x] AC2: The `problem` text of a `"renv-missing"` row names the `.json` files that show such a package attached, in the same way as the `"renv-mismatch"` row names files. It names each such package once, in byte order of name. It says that `renv::restore()` does not install them, and gives two ways to clear the row: run `renv::snapshot()` and commit `renv.lock`, or, if the report no longer uses the package, take the render steps of the `"stale-output"` row. When another `.json` file of the report holds a package table or list and attaches none of the row's packages, the row also gives the old-format hint and delete steps of the `"renv-mismatch"` row. Tests assert the exact text for a report with two such packages in two `.json` files, one of the packages attached in both, and for the old-format case.
- [x] AC3: Each of these cases gives no `"renv-missing"` row, in a test in `tests/testthat/test-check-supplement.R`:
  - a package that is loaded and not attached: a sessioninfo table line with no `*`, or an entry after `loaded via a namespace (and not attached):`
  - a package that `renv.lock` names under `Packages` by its `Package` text, at another version or with no `Version` text, or by its key alone
  - `renv_lock = FALSE`
  - a site with no `renv.lock`, where the skip message names both the `"renv-mismatch"` and the `"renv-missing"` check
  - a `renv.lock` that cannot be read, where the `renv.lock` row of the `"renv-mismatch"` check, with its `problem` text unchanged, is the only row of the comparison
  - a report that cannot be read, such as a link to a missing file

  The `"renv-mismatch"` rows do not change: the `"renv-mismatch"` tests that exist at the plan commit pass with no edit to their expected values. A report that gets both rows lists its `"renv-mismatch"` row first, and the `"renv-missing"` rows follow all `"renv-mismatch"` rows, in the order of the report list.
- [x] AC4: A Quarto render of the template's example report by name, run with `R_PROFILE_USER` set to an empty file, gives no `"renv-missing"` row against a `renv.lock` whose `Packages` names no package. A render of a report that runs `library(jsonlite)`, run the same way, gives a `"renv-missing"` row that names `jsonlite` against that `renv.lock`. Tests in `tests/testthat/test-add-render.R` show both and skip without Quarto.
- [x] AC5: `release_supplement()` does not run the check. In a test in `tests/testthat/test-release-supplement.R`, `check_supplement(renv_lock = TRUE)` first gives a `"renv-missing"` row for the site. Then `release_supplement()` releases the same site.
- [x] AC6: Each file that `grep -rl 'renv_lock' R man README.md NEWS.md vignettes inst/template cairn/DESIGN.md` lists, other than `R/release-supplement.R` and `man/release_supplement.Rd`, says that a package that a report attached and that `renv.lock` does not name gives a `"renv-missing"` row. The help of `release_supplement()` says that it gives neither the `"renv-mismatch"` nor the `"renv-missing"` row. The `check_supplement()` help says that a package that is loaded and not attached gives no row. NEWS.md has no second bullet for it: the unreleased `renv_lock` bullet names it.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T3
- AC6 → T4

## Tasks

- [x] T1: In `R/check-supplement.R`, make `stored_versions()` also return the names of attached packages: in the sessioninfo table, read the character at the position of the header's `*`, beside the `package` and `version` positions it reads now; in `utils::sessionInfo()` output, take the entries after `other attached packages:`. Make `lock_versions()` also return every package name under `Packages`, records with no `Version` text included, with the naming rule of AC1. Test the parser from text, the `!` column table and wrapped `sessionInfo()` lists included (LESSONS M064).
- [x] T2: In `check_renv_lock()` (`R/check-supplement.R:882`), build the `"renv-missing"` rows of AC1 and AC2 after the `"renv-mismatch"` rows, from the same files read once, and make the skip message name both checks. Write the row tests of AC1 to AC3, each test filtering the result by `check` where it asserts one kind. For each no-row case, plant one attached package that `renv.lock` lacks into the same fixture and see the row appear, so the case is shown able to fail (LESSONS M061).
- [x] T3: Write the two Quarto tests of AC4 in `tests/testthat/test-add-render.R` beside "a rendered report gives a renv-mismatch row against a renv.lock with another knitr version", and the AC5 test beside the `renv-mismatch` release test in `tests/testthat/test-release-supplement.R`.
- [x] T4: Update the help of `check_supplement()` and `release_supplement()`, the NEWS.md `renv_lock` bullet, README.md, GUIDE.md's renv part and check list, the publishing vignette, and DESIGN.md. Run `devtools::document()`, then the grep of AC6. Run `devtools::test()` and `devtools::check()` and record their counts in the work log.

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
- 2026-10-27: T2 done: `check_renv_lock()` now builds both rows per report through `mismatch_problem()` (the M064 text, moved unchanged) and `missing_problem()`, and gives the renv-mismatch rows first. The rewrite went in through a python script rather than the Edit tool. A planted defect (every loaded package counted as attached) failed 4 expectations of the no-row test. `devtools::test()` 453 tests, 0 failed, 10 skipped.
- 2026-10-27: T3 done: two Quarto render tests (`R_PROFILE_USER` set through `withr::local_envvar()`, since `run_in()`'s `env` reaches only R commands on Windows) and one release test; both render tests ran with `NOT_CRAN=true` and passed. `devtools::test()` 456 tests, 0 failed, 10 skipped.
- 2026-10-27: T4 docs written (help of both functions, NEWS bullet, README, GUIDE renv part and check list, vignette, DESIGN); `devtools::document()` rewrote the two .Rd files; the AC6 grep lists 9 files and each names `renv-missing`. Full test and check running.
- 2026-10-27: claim audit: 45 claims read, 5 corrected — R/check-supplement.R (unreadable-lock wording, renv snapshot claim, format-hint wording, restore wording), inst/template/GUIDE.md (any attach counts, not only `library()`), NEWS.md (restore wording).
- 2026-10-27: T4 done: `devtools::test()` 456 tests, 0 failed, 10 skipped; `devtools::check()` 0 errors, 0 warnings, 1 note (local `.claude`) before and after the claim fixes; `devtools::document()` regenerated `check_supplement.Rd` for them.
- 2026-10-27: implement complete; status set to review.
- 2026-10-27: step-7 approval: m065-renv-missing-packages approved for merge
- 2026-10-27: CI wait on PR #66 reached the time limit: ubuntu and build passed, macOS and Windows pending, deploy skipped; nothing merged.
- 2026-10-27: resume: PR #66 open, every check passed at 510c594, main unmoved; re-entering at step 7 (route c).

## Decisions

## Review

Evidence (2026-10-27, branch head before review fixes 2fd76ed; `devtools::test()` 456 tests, 0 failed, 10 skipped):

- AC1: "attached packages that renv.lock does not name give a renv-missing row" passed 6 expectations: `flagged` (table with `!` column), `plain` (without it), and `wrapped` (`other attached packages:` over `[1]` and `[3]` lines) each give a row whose `file` and `problem` equal exact expected values, filtered by `check == "renv-missing"`. The parser tests from real sessioninfo and `sessionInfo()` output passed 3 and 4.
- AC2: the same test asserts the exact text for `two` (dplyr attached in `docx.json` and `html.json`, ggplot2 in one; files and packages each named once, byte order) and for `old-format` (the format hint and delete steps).
- AC3: "loaded packages and packages that renv.lock names give no renv-missing row" passed 10 (table without `*`, namespace list, other version, no `Version`, key alone; each with a planted copy that gives the row); "a renv.lock record with an empty name names no package" passed 1; "no renv-missing row without a readable renv.lock or report, or by default" passed 6 (skip message names both checks, unreadable lock gives only its renv-mismatch row with unchanged text, `renv_lock = FALSE`, dangling report); "renv-missing rows follow the renv-mismatch rows" passed 1. `git diff main...HEAD -- tests` removes no line, and the 11 existing renv-mismatch tests passed.
- AC4: "a rendered example report gives no renv-missing row against a renv.lock with no package" passed 2 and "a rendered report that attaches jsonlite gives a renv-missing row that names it" passed 3, both rendered by Quarto under `devtools::test()`.
- AC5: "the release goes ahead with a package that renv.lock does not record" passed 2.
- AC6: the grep lists 9 files (both R files, both .Rd files, README.md, NEWS.md, the vignette, GUIDE.md, DESIGN.md) and `grep -c renv-missing` is at least 1 in each; `man/check_supplement.Rd` says a package loaded and not attached gives no row; `man/release_supplement.Rd` names both rows; NEWS.md holds `renv-missing` once, in the `renv_lock` bullet.

Consistency gate: `cairn_validate.py` all checks passed; `devtools::document()` no diff; no README.Rmd; `pkgdown::check_pkgdown()` no problems; NEWS.md entry present; no new top-level file; no snapshot file in the diff; principles unchanged, so no impact report. `devtools::check()` at af33585: 0 errors, 0 warnings, 1 note (local `.claude`, outside the built package's repo files). After the review fixes, at ebb9280: `devtools::test()` 456 tests, 0 failed, 10 skipped.

spawned: diff-bug, blame-history, prior-review, ripple

- conversation: PR #66 — empty read on resume (0 reviews, 0 comments, 0 unresolved threads).
- ripple #1: sessioninfo marks base packages attached, so they would give rows — reject (false: `sessioninfo::session_info()` with `tools` attached listed no base package).
- ripple #2: help says a package renv.lock does not record "is not compared" with no pointer to the new row — fix now, fixed af33585.
- ripple #3: help says a record with no `Version` "is left out" — fix now ("left out of the comparison"), fixed af33585.
- ripple #4: help says the function skipped "the check" — fix now (names both), fixed af33585.
- ripple #5: GUIDE.md "The same command" has an unclear antecedent — fix now, fixed af33585.
- ripple #6: the ROADMAP candidate row still describes the gap — reject (planned change: post-merge hygiene graduates it).
- diff-bug #1: a package that an R profile attaches, or that renv settings leave out, gives a row that snapshot and render do not clear, and no doc says so — fix now (help and GUIDE.md state it), fixed af33585.
- diff-bug #2: DESIGN.md says renv's snapshot leaves loaded-only packages out — fix now, fixed af33585.
- diff-bug #3: a record with non-text `Package` names its key, and `"Package": ""` names nothing — reject (planned change: AC1's naming rule).
- diff-bug #4: the format hint fires for a file whose only list is the namespace list — reject (planned change: AC2's condition, and the text is true).
- diff-bug #5: the `!` column `*` read is tested from text only — reject (planned change: AC1 names text fixtures; sessioninfo prints `!` only when a package has a problem).
- diff-bug #6: the `flagged_table` parser expectation repeats the row test's `table` case — fix now, fixed ebb9280.
- diff-bug #7: the hand-made wrapped list in the parser test repeats the `wrapped` row case — fix now, fixed ebb9280.
- diff-bug #8: `flagged` and `plain` run the same code — reject (planned change: AC1 requires both).
- diff-bug #9: the jsonlite render test matches a substring — reject (planned change: AC4 asks no exact text; other tests pin it).
- diff-bug #10: `expect_false(stored_versions("x")$listed)` guards a default — reject (false: it tests the new `listed` field, as the reviewer also says).
- blame-history #1: base packages marked attached by sessioninfo — reject (false: same probe as ripple #1).
- blame-history #2: DESIGN.md and help give different reasons for the no-row rule — fix now, fixed af33585.
- blame-history #3: the M064 skip message gained a sentence — reject (planned change: AC3).
- blame-history #4: a report can now get two rows — reject (planned change: AC3 order rule).
- blame-history #5: the renv-missing hint condition differs from the renv-mismatch one — reject (planned change: AC2).
- blame-history #6: no D-entry for the second comparison — reject (planned change: it runs under D-032's opt-in argument and stops no release, as D-032 states for the comparison).
- prior-review #1: the dangling-report case uses bare `file.symlink()` — fix now (`symlink_or_skip()`), fixed ebb9280.
- prior-review #2: the renv claims in the new text have no test — reject (false: the claim audit read them against `?renv::snapshot` and narrowed them; restore now says "from renv.lock").
- prior-review #3: the new release test hashes the report with raw `tools::md5sum()` — reject (style: the template is LF, and it mirrors the renv-mismatch release test beside it).
