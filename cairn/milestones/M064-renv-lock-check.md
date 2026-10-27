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

- [x] AC1: `check_supplement(path, renv_lock = TRUE)` reads `renv.lock` in the site folder. It reads the stored output of each report from the list that the `"stale-output"` check reads. The stored output is the top-level `result.markdown` text of each `.json` file that the `"stale-script"` check reads. A file that does not parse gives no versions, and the other files of the report still count. The check reads versions in these forms:
  - From `sessioninfo::session_info()`: the package table after a line that starts with `─ Packages` or `- Packages`, with or without its `!` column, and the `version` setting line. The package version comes from the `version` column.
  - From `utils::sessionInfo()`: the first `R version` line, and the `name_version` entries after `other attached packages:` and after `loaded via a namespace (and not attached):`, also where they wrap over several lines.

  Lines with a knitr comment prefix such as `## ` are not read. Lines with ANSI color codes are not read. A test from text covers each form: both table rules, the `!` column with a `V` flag, and `utils::sessionInfo()` output from `capture.output()` at a width that wraps its entries. A test from text shows that each of the two unread forms gives no row. One more test renders the example report by name with Quarto. It gives a row against a `renv.lock` that records another knitr version.
- [x] AC2: A report gets one `"renv-mismatch"` row if a package version or the R version differs. If any stored version of a package is not equal to its `Version` under `Packages` in `renv.lock`, the package differs. If any stored R version is not equal to the `Version` under `R`, the R version differs. Versions are compared as `package_version()` values, so `1.0-5` equals `1.0.5`. If `package_version()` cannot read a stored or recorded version, that package or that R version is not compared. An example is `R Under development (unstable)`. Tests show a row for two `.json` files that hold two versions of one package. Tests show no row from a version that cannot be read.
- [x] AC3: The row names the `.json` files that hold a version that differs, in the same way as the `"stale-script"` row. It names each package that differs, in byte order of name. For each package it gives each distinct stored version once, in `package_version()` order, and the version in `renv.lock`. If the R versions differ, the row names them in the same way. Then it gives two ways to clear the row:
  - Run `renv::restore()`, then take the render steps of the `"stale-output"` row.
  - If the library now holds the versions of the report, run `renv::snapshot()` and commit `renv.lock`.

  Another `.json` file of the report can hold versions and none that differ. Then the row also gives the old-format hint and the delete steps of the `"stale-script"` row. Tests assert the exact text for one package, two packages, the R version alone, the R version and a package, and the old-format case.
- [x] AC4: Each of these cases gives no `"renv-mismatch"` row for a report, in a test:
  - equal versions, with `1.0-5` against `1.0.5` among them
  - a package in the stored output that `renv.lock` does not record
  - a package in `renv.lock` that the stored output does not name
  - a base package such as `compiler_4.6.1` after `loaded via a namespace`, which `renv.lock` does not record
  - stored output with no version list, such as a report without the Computing environment section
  - a report that cannot be read, such as a link to a missing file

  Also, a test with a line of 5 MB in `result.markdown` before the package table gets the row and no warning.
- [x] AC5: With the default `renv_lock = FALSE`, the function does not read `renv.lock` and gives no `"renv-mismatch"` row. A test shows this with a `renv.lock` that does not parse and a report that differs. With `renv_lock = TRUE`, the cases below hold, each in a test:
  - If the site has no `renv.lock`, the function gives no row. It prints a message that the check was skipped, and its `skipped` attribute does not change.
  - A `renv.lock` can be a link to a missing file, a folder, text that is not valid UTF-8, or text that does not parse as JSON. Its top level or its `Packages` can be other than a JSON object. In each case, `renv.lock` gets one `"renv-mismatch"` row that says it cannot be read. No report gets a row then.
  - If `renv.lock` has no `R` `Version` text, only package versions are compared.
  - A `renv_lock` that is not `TRUE` or `FALSE` stops the function with `supplement_error_argument`.
- [x] AC6: `release_supplement()` does not run the check. In a test, `check_supplement(renv_lock = TRUE)` first gives a `"renv-mismatch"` row for the site. Then `release_supplement()` releases the same site.
- [x] AC7: The `check_supplement()` help lists the `"renv-mismatch"` check and the `renv_lock` argument. The `release_supplement()` help says that it does not run that check. GUIDE.md shows `check_supplement(renv_lock = TRUE)` in the part "Recording R packages with renv" and names the check in its check list. NEWS.md has a bullet. DESIGN.md names the check where it describes `check_supplement()`. `devtools::document()` gives no diff. `devtools::test()` and `devtools::check()` give 0 errors and 0 warnings.

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
- 2026-10-27: step-7 approval: m064-renv-lock-check approved for merge
- 2026-10-27: T6 done. The second `devtools::check()` gave 0 errors, 0 warnings, and 1 note (the local `.claude` folder). Its test run passed. Status set to review.

## Decisions

## Review

Evidence from `devtools::test()` at 748913e on macOS (447 tests, 0 failed, 0 errors, 10 skipped, none of them M064 tests), read per test from its results.

- AC1: "stored_versions() reads the sessioninfo table after either rule" (6 expectations, real `session_info()` output under the `─` and `-` rules) and "reads utils::sessionInfo() with package lists that wrap" (width 40) pass. The row test gives rows for the `table` case (the `!` column with a `V` row) and for the `utils` form. The no-row test gives no row for the `prefixed` and `colored` cases. The Quarto test "a rendered report gives a renv-mismatch row against a renv.lock with another knitr version" ran a real render and passed.
- AC2: In the row test, the `two-versions` case (two `.json` files that hold 1.9.0 and 1.10.0) gives one row with "dplyr 1.9.0 and 1.10.0", and `package_version()` orders them. In the no-row test, the `unreadable` case (`devel` and `not-a-version`) gives no row. Both pass.
- AC3: The row test asserts the exact text with `expect_identical()` for `one`, `two` (byte order: `Rcpp` before `abc`), `r-alone`, `r-and-package`, and `old-format` (with the hint). It passes.
- AC4: The no-row test passes. Only `differs` gets a row. No row comes from `equal` (with `1.0-5` against `1.0.5`), `not-in-lock`, `lock-only`, `base` (`compiler_4.6.1`), `no-list`, or `dangling`. "versions after a line of 5 MB give a renv-mismatch row with no warning" passes.
- AC5: These pass: "by default check_supplement() does not read renv.lock" (with a differing report and a lock that does not parse); "a site with no renv.lock gets a skip message and no renv-mismatch row" (it checks the message and the unchanged `skipped` attribute); "a renv.lock that cannot be read gets one renv-mismatch row" (folder, dangling link, Latin-1 bytes, `{`, `[]`, no `Packages`, `Packages` as an array); "a renv.lock with no R version compares only package versions"; and "renv_lock must be TRUE or FALSE".
- AC6: "the release runs the real check without the renv.lock comparison" passes. It first asserts the one row `renv-mismatch analyses/example.qmd`, then releases to 1.0.0.
- AC7: `man/check_supplement.Rd` lists `"renv-mismatch"` and documents `renv_lock`. `man/release_supplement.Rd` says the release runs without `renv_lock`. GUIDE.md shows `check_supplement(renv_lock = TRUE)` in "Recording R packages with renv" and has the list item in "Checks before a release". NEWS.md has the top bullet. DESIGN.md names `check_renv_lock()`. `devtools::document()` left `git status` clean. `devtools::test()` gave 0 failed, and `devtools::check()` gave 0 errors, 0 warnings, and 1 note (the local `.claude` folder).

Consistency gate: `cairn_validate.py` all checks passed. No principle changed, so `cairn_impact` was skipped. `devtools::document()` gave no diff, and the repo has no README.Rmd. `pkgdown::check_pkgdown()` found no problems. NEWS.md has the bullet, and no new top-level file was added. `devtools::check()` gave 0 errors, 0 warnings, and 1 note: the local `.claude` folder, which is outside the package build.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: in a Latin-1 locale, `stored_json()` passes unmarked text to jsonlite, so `─` is misread and no sessioninfo table is found — fix now, fixed 0c6223a.
- diff-bug #2: each line in `result.markdown` that starts with `R version` is read, so report text such as "R version 4.2 is what we used." gives a false R version — fix now, fixed 0c6223a (read only the first line in R's version-string form).
- diff-bug #3: CR LF line ends in stored markdown hide the `utils::sessionInfo()` lists and keep the table loop past its blank line — fix now, fixed 0c6223a.
- diff-bug #4: `package_version()` warns on a version part above 2^31−1 — reject (edge: a version such as `1.99999999999` is outside documented and common use, and the effect is a warning).
- diff-bug #5: packages are looked up by their `Packages` key, not their `Package` field, and a repeated key takes its first copy with no warning — fix now, fixed 0c6223a.
- diff-bug #6: `1.0-5` and `1.0.5` both print as distinct stored versions — fix now, fixed 0c6223a (unique by version value).
- diff-bug #7: the unreadable-lock row text is wrong for a `renv.lock` with a UTF-8 BOM — fix now, fixed 0c6223a (skip the BOM and read the file).
- diff-bug #8: each stored `.json` is parsed again by each of three checks — follow-up, the candidate row "Parse each stored output file once".
- diff-bug #9: bare `file.symlink()` in tests fails on Windows without link rights — reject (false: the suite's Windows runner makes file links, LESSONS M060, and older tests use the same call).
- diff-bug #10: one roxygen line is much longer than its neighbors — fix now, fixed 0c6223a, with diff-bug #7's help edit.
- diff-bug (c) #1: the `renv_lock` argument test repeats one path over 5 inputs — reject (false: the test rules ask for each error branch and the input-type edge cases).
- diff-bug (c) #2: the `!` column table is tested by a unit test and by the row case `table` — fix now, fixed 0c6223a (remove the unit test).
- diff-bug (c) #3: the unread forms are tested at unit and row level — fix now, fixed 0c6223a (remove the unit test, as AC1 asks for the row level).
- diff-bug (c) #4: the 5 MB case is tested at unit and row level — fix now, fixed 0c6223a (remove the unit test).
- diff-bug (c) #5: the `lock-only` case adds nothing — fix now, fixed 0c6223a (remove it).
- diff-bug (c) #6: the comment before the last expectation of the default test restates it — fix now, fixed 0c6223a (remove it).
- diff-bug (c) #7: `stopifnot()` guards duplicate testthat — reject (false: they show the fixture domain is not empty, as check discrimination asks).
- diff-bug (c) #8: `lock_path()` is a trivial helper — reject (style).
- blame-history #1: `lock_versions()` lacks the repeated-key refusal that `write_dockerfile()` has (M035) — fix now, fixed 0c6223a, with diff-bug #5.
- blame-history #2: the two renv.lock readers have different rules — reject (planned change: the check compares packages without an R version, AC5, while the Dockerfile needs one).
- blame-history #3: `strsplit()` warns on markdown that is not UTF-8 — reject (false: jsonlite rejects such JSON, so `stored_markdown()` gives NULL first).
- blame-history #4: the split list item can read as a separate check — reject (false: the lists name problems, not check ids, and `"broken-link"` has several items too).
- blame-history #5: a literal `─` stays in roxygen and a comment — reject (style: R CMD check allows it there).
- prior-review #1: repeated keys in renv.lock (M035) — fix now, fixed 0c6223a, with diff-bug #5.
- prior-review #2: `env_json(character())` writes a stray `[1] _` line (LESSONS M061) — fix now, fixed 0c6223a (guard the empty case).
- ripple #1: the publishing vignette's "When the check finds no problem" now follows the renv sentence — fix now, fixed 0c6223a.
- ripple #2: DESIGN.md's DOI sentence now follows the renv paragraph — fix now, fixed 0c6223a.
- ripple #3: the candidate row "Compare renv.lock with report records" is still listed — reject (planned change: hygiene graduates it).
- ripple #4: the GUIDE.md list item sits in the default list — reject (planned change: AC7 asks the check list to name it).
- ripple #5: DESIGN.md does not name `stored_markdown()` — reject (false: the sentence it has stays true).

After the fixes, at 0c6223a: `devtools::test()` gave 446 tests, 0 failed, and 10 skipped. Three duplicate unit tests went, and two tests came in. The row test adds `crlf` and `spellings` (one row, "Matrix 1.0.5"). The no-row test drops `lock-only` and adds `prose-r` and `second-r`. A package in `renv.lock` that the stored output does not name is still covered there by `Matrix` and `odd`. The unreadable-lock test adds six repeated-key forms. New tests cover a record named by its `Package` text, a lock with a byte order mark, and a Latin-1 locale. With the UTF-8 mark in `stored_json()` removed as a planted defect, the Latin-1 test failed. `cairn_validate.py` passed. `devtools::document()` ran.
At 4a39f41, `devtools::check()` gave 0 errors, 0 warnings, and 1 note (the local `.claude` folder). No snapshot file changed. The work log records no amendment.
