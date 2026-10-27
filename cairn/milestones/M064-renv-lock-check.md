<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M064: Compare renv.lock with report records

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a new argument and check of the exported `check_supplement()`
- **Branch/PR:** m064-renv-lock-check

## Goal

`check_supplement(renv_lock = TRUE)` gives a `"renv-mismatch"` row for each report whose stored output names an R or package version that differs from `renv.lock`. `release_supplement()` does not run this check (D-032).

## Scope

**In:** These parts:

- a new argument `renv_lock = FALSE` of `check_supplement()`
- a reader for `renv.lock`
- a parser for the version lists that `print_environment()` prints into stored output
- the `"renv-mismatch"` rows and their tests
- the help pages, GUIDE.md, NEWS.md, and DESIGN.md

**Out:** These parts:

- A row for a package that the stored output names and `renv.lock` does not record. The candidate row "Flag packages missing from renv.lock" holds it.
- A lockfile other than `renv.lock` in the site folder, such as the lockfile of an renv profile. The same candidate row holds it.
- Python reports. The candidate row "Record the Python setup of reports" holds them.

## Acceptance criteria

- [ ] AC1: `check_supplement(path, renv_lock = TRUE)` reads `renv.lock` in the site folder. It reads the stored output of each report from the list that the `"stale-output"` check reads. The stored output is the top-level `result.markdown` text of each `.json` file that the `"stale-script"` check reads. A file that does not parse gives no versions, and the other files of the report still count. The check reads versions in these forms:
  - From `sessioninfo::session_info()`: the package table after a line that starts with `─ Packages` or `- Packages`, with or without its `!` column, and the `version` setting line. The package version comes from the `version` column.
  - From `utils::sessionInfo()`: the first `R version` line, and the `name_version` entries after `other attached packages:` and after `loaded via a namespace (and not attached):`, also where they wrap over several lines.

  Lines with a knitr comment prefix such as `## ` are not read. Lines with ANSI color codes are not read. A test from text covers each form: both table rules, the `!` column with a `V` flag, and `utils::sessionInfo()` output from `capture.output()` at a width that wraps its entries. A test from text shows that each of the two unread forms gives no row. One more test renders the example report by name with Quarto. It gives a row against a `renv.lock` that records another knitr version.
- [ ] AC2: A report gets one `"renv-mismatch"` row if a package version or the R version differs. If any stored version of a package is not equal to its `Version` under `Packages` in `renv.lock`, the package differs. If any stored R version is not equal to the `Version` under `R`, the R version differs. Versions are compared as `package_version()` values, so `1.0-5` equals `1.0.5`. If `package_version()` cannot read a stored or recorded version, that package or that R version is not compared. An example is `R Under development (unstable)`. Tests show a row for two `.json` files that hold two versions of one package. Tests show no row from a version that cannot be read.
- [ ] AC3: The row names the `.json` files that hold a version that differs, in the same way as the `"stale-script"` row. It names each package that differs, in byte order of name. For each package it gives each distinct stored version once, in `package_version()` order, and the version in `renv.lock`. If the R versions differ, the row names them in the same way. Then it gives two ways to clear the row:
  - Run `renv::restore()`, then take the render steps of the `"stale-output"` row.
  - If the library now holds the versions of the report, run `renv::snapshot()` and commit `renv.lock`.

  Another `.json` file of the report can hold versions and none that differ. Then the row also gives the old-format hint and the delete steps of the `"stale-script"` row. Tests assert the exact text for one package, two packages, the R version alone, the R version and a package, and the old-format case.
- [ ] AC4: Each of these cases gives no `"renv-mismatch"` row for a report, in a test:
  - equal versions, with `1.0-5` against `1.0.5` among them
  - a package in the stored output that `renv.lock` does not record
  - a package in `renv.lock` that the stored output does not name
  - a base package such as `compiler_4.6.1` after `loaded via a namespace`, which `renv.lock` does not record
  - stored output with no version list, such as a report without the Computing environment section
  - a report that cannot be read, such as a link to a missing file

  Also, a test with a line of 5 MB in `result.markdown` before the package table gets the row and no warning.
- [ ] AC5: With the default `renv_lock = FALSE`, the function does not read `renv.lock` and gives no `"renv-mismatch"` row. A test shows this with a `renv.lock` that does not parse and a report that differs. With `renv_lock = TRUE`, the cases below hold, each in a test:
  - If the site has no `renv.lock`, the function gives no row. It prints a message that the check was skipped, and its `skipped` attribute does not change.
  - A `renv.lock` can be a link to a missing file, a folder, text that is not valid UTF-8, or text that does not parse as JSON. Its top level or its `Packages` can be other than a JSON object. In each case, `renv.lock` gets one `"renv-mismatch"` row that says it cannot be read. No report gets a row then.
  - If `renv.lock` has no `R` `Version` text, only package versions are compared.
  - A `renv_lock` that is not `TRUE` or `FALSE` stops the function with `supplement_error_argument`.
- [ ] AC6: `release_supplement()` does not run the check. In a test, `check_supplement(renv_lock = TRUE)` first gives a `"renv-mismatch"` row for the site. Then `release_supplement()` releases the same site.
- [ ] AC7: The `check_supplement()` help lists the `"renv-mismatch"` check and the `renv_lock` argument. The `release_supplement()` help says that it does not run that check. GUIDE.md shows `check_supplement(renv_lock = TRUE)` in the part "Recording R packages with renv" and names the check in its check list. NEWS.md has a bullet. DESIGN.md names the check where it describes `check_supplement()`. `devtools::document()` gives no diff. `devtools::test()` and `devtools::check()` give 0 errors and 0 warnings.

## Coverage

- AC1 → T2, T4
- AC2 → T2, T3
- AC3 → T3
- AC4 → T2, T3
- AC5 → T1, T3
- AC6 → T5
- AC7 → T6

## Tasks

- [x] T1: In `R/check-supplement.R`, add `lock_versions(path)`. It reads `renv.lock` as bytes and refuses text that is not valid UTF-8 (LESSONS M016). It parses the text with jsonlite. It returns the R version and the package versions, or a mark that the file cannot be read. Add the check of the `renv_lock` argument. Write the tests for AC5.
- [x] T2: Add `stored_versions(markdown)`. It finds the version lists of both forms with fixed-string searches and line splits. No PCRE pattern runs across a long line (LESSONS M021, M059). It reads the sessioninfo columns at the positions of the header line. Write the tests from text for AC1, AC2, and AC4.
- [x] T3: Add `check_renv_lock(path)`. If `renv_lock = TRUE`, call it from `check_supplement()` after `check_stale_script()`. Build the rows of AC3 and the skip message of AC5. Write the row tests for AC2 to AC5.
- [x] T4: Write one Quarto test that renders the example report by name and checks it against a `renv.lock` that records another knitr version. It skips without Quarto.
- [x] T5: Write the AC6 test in `test-release-supplement.R`, after the test "the release runs the real check without the web link check".
- [x] T6: Update the help of `check_supplement()` and `release_supplement()`. Update GUIDE.md in the part "Recording R packages with renv" and in its check list. Update NEWS.md and DESIGN.md. Run `devtools::document()`, `devtools::test()`, and `devtools::check()`.

## Work log

- 2026-10-27: created by /milestone-plan.
- 2026-10-27: tier check: milestone — a new check and argument of an exported function, with a design choice about the release.
- 2026-10-27: idea vet: one concern. A row that stops the release would block releases after each package update, because under freeze an older report keeps the versions of its own render (D-002, D-030). Answer at the set: opt-in, and the release does not run it (D-032).
- 2026-10-27: question set: go on into implement and review after the plan — yes, given at the first pass of this plan the same day.
- 2026-10-27: plan gate chose an opt-in check that never stops the release over an always-on row that stops it and an always-on row that the release passes over. A stopping row conflicts with freeze. Falsified by authors who miss mismatches because the check is off by default.
- 2026-10-27: plan gate chose to compare the R version too over package versions only, because `renv::restore()` and the Docker recipe use the R in `renv.lock`. Falsified by R patch rows that authors report as noise.
- 2026-10-27: plan chose to read the sessioninfo columns at the header positions over a split on spaces, because the `!` column is blank on most rows. Falsified by a sessioninfo version whose table is not aligned to its header.
- 2026-10-27: plan chose to leave `## ` prefixed lines and ANSI-colored lines unread over removing the prefix and codes, toward the narrower promise. Falsified by real sites whose reports set a comment prefix or color.
- 2026-10-27: criteria audit (full mode, fresh Opus reader): 12 findings. Fixed 11: the ASCII table rule, versions that cannot be read, two stored versions of one package, the named files and the old-format hint, the snapshot wording, D-032, the skip and link cases, the AC6 precondition, wrapped `sessionInfo()` output, the base package example, and the candidate row. Finding 2 was narrowed: "in no other form" became two named unread forms with tests.
- 2026-10-27: collision check: absorbed the candidate row "Compare renv.lock with report records" (M031 plan). D-030 is extended by D-032. M031's GUIDE.md text that the two can differ stays true.
- 2026-10-27: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-27: lessons used: 2026-10-19 (M016), 2026-10-20 (M021), 2026-10-26 (M059), 2026-10-27 (M063).
- 2026-10-27: added the candidate row "Flag packages missing from renv.lock" for the Out items.
- 2026-10-27: implement started on branch m064-renv-lock-check.
- 2026-10-27: T1 done. `lock_versions()` and `check_renv_lock()` read `renv.lock`, and `renv_lock` is checked. The skip message names the check with cli `{.val}` and `{.file}`. Tests cover the argument, the skip, seven unreadable forms, and the default. The warning at test line 746 (a file name that is not UTF-8) also shows on main.
- 2026-10-27: T2 done. `stored_versions()` reads both forms, and the new `stored_markdown()` now also serves `stored_script_hashes()`. The tests read real sessioninfo output under both rules, real `utils::sessionInfo()` output at width 40, a hand-built `!` table, the unread prefix and color forms, and a 5 MB line. With the `- Packages` rule removed as a planted defect, the rule test went red. Row tests from text come in T3.
- 2026-10-27: T3 done. `check_renv_lock()` builds report rows through the new `version_diffs()`. The row lists R first, then the packages in byte order. For each package it gives only the stored versions that differ, as "1.9.0 and 1.10.0". Exact-text tests cover eight row cases. Ten no-row cases and the no-R lock case have tests. With string comparison planted in place of `package_version()`, the no-row test went red.
- 2026-10-27: T4 done, in `test-add-render.R`. Minor amendment: the test does not skip without sessioninfo, because both printed forms list knitr. The lock records no R version, so the row names knitr alone. The test ran and passed on macOS.
- 2026-10-27: T5 done. The release test first gets exactly one `"renv-mismatch"` row from the real check, then releases the same site to 1.0.0.
- 2026-10-27: T6 checkpoint, not done. The help of both functions, NEWS.md, README.md, GUIDE.md, the publishing vignette, and DESIGN.md are updated, and `devtools::document()` ran. The GUIDE.md check list names the check as its last item. A style hook flagged one long older list item in README.md and in GUIDE.md, so each became two items. The full test run and `devtools::check()` are still owed.
- 2026-10-27: full `devtools::test()`: 447 tests, 0 failed, 0 errors, 10 skipped. The first `devtools::check()` gave 0 errors, 1 warning, and 1 note. The warning was a literal `─` in `stored_versions()`, which is now `─`. The note is the local `.claude` folder. A second check is running.
- 2026-10-27: claim audit (fresh Opus reader): 55 claims read, 6 corrected in NEWS.md, the `check_supplement()` help and Rd, a code comment, the renv.lock row text and its test, and GUIDE.md. The corrected claims are with the same reader for one re-read.
- 2026-10-27: claim audit re-read: all 6 corrections hold at 00fa984.
- 2026-10-27: T6 done. The second `devtools::check()` gave 0 errors, 0 warnings, and 1 note (the local `.claude` folder). Its test run passed. Status set to review.

## Decisions

## Review
