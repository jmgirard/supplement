# M033: Each CI job runs the tests once, in parallel

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — the CI workflow, test files, and a testthat field in DESCRIPTION; no package user calls them
- **Branch/PR:** m033-ci-test-time

## Goal

Each R-CMD-check job takes at most 60% of its time on the PR #31 run, because the tests run once per job, test files run in parallel, and string-rule loops skip on Windows.

## Scope

**In:** a script that reads the skip section of R CMD check's test output, in place of the second test pass; a short step that runs the two source-reading tests from the checkout; parallel test files; Windows skips for six string-rule loop tests; a D-entry that amends D-016.

**Out:** a coverage report (candidate row "Add a test coverage report to CI"). The render flake (row "template test flake"). Counting a missing renv as a missing tool (M031 T3, which edits the same list). A path filter that skips CI on tracking-only pushes (not asked).

## Acceptance criteria

- [x] AC1: The skip-list step of `.github/workflows/R-CMD-check.yaml` runs no test. It reads `check/supplement.Rcheck/tests/testthat.Rout.fail` when that file exists, else `testthat.Rout` in the same folder, and prints each line of its "Skipped tests" section. It fails when neither file exists, when the file has no summary line of the form `[ FAIL n | WARN n | SKIP n | PASS n ]` or its last such line shows `PASS 0`, or when the counts in its skip lines do not add up to that line's SKIP count.
- [x] AC2: The step joins each skip bullet's wrapped lines into one reason, fails when that reason contains a missing-tool text that its list names, and passes on this milestone's CI `testthat.Rout`, which has none.
- [x] AC3: The two tests that skip under R CMD check with "the package source is not here" sit in `tests/testthat/test-source.R`. A workflow step runs that file from the checkout with `testthat::test_local()` and fails when one of its tests fails or skips, or when it runs no test.
- [x] AC4: On Windows, the tests "write_citation() and the license shortcode accept and refuse the same ids" and "write_citation() and the DOI badge accept and refuse the same DOIs" in `test-agreement.R`, and "the DOI badge removes a doi: or doi.org link prefix", "the license shortcode shows nothing for an empty value or no license map", "a license value that is not one SPDX id stops the render and names the field", and "the license shortcode stops unless its one argument is code or content" in `test-shortcodes.R`, skip with `skip_on_os("windows")`. No skip line in the macOS or Ubuntu job lists a location inside these six tests. For each shortcode that `inst/template/_extensions/supplement/supplement.lua` registers, at least one test that renders a page with it has no Windows skip, and no skip line in the Windows job lists a location inside that test.
- [x] AC5: DESCRIPTION sets `Config/testthat/parallel: true`, and in each CI job testthat runs the suite in at least 2 processes.
- [x] AC6: On the milestone's last CI run, each job takes at most 60% of its time in run 39704929580 (windows-latest 1,824 s, macos-latest 822 s, ubuntu-latest 1,017 s), counted from `startedAt` to `completedAt` in `gh run view <id> --json jobs`.
- [ ] AC7: `devtools::test()` passes with no failures, `devtools::check()` gives 0 errors and 0 warnings, and the R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T6
- AC3 → T2
- AC4 → T4, T6
- AC5 → T3, T6
- AC6 → T6
- AC7 → T6

## Tasks

- [x] T1: Write `.github/scripts/check-skips.R`. It takes the folder of the check's tests, picks `testthat.Rout.fail` or `testthat.Rout`, prints the "Skipped tests" section, joins each bullet (`•` or `*`) with its continuation lines, and stops on each AC1 failure and on a reason that holds a text of the missing-tool list (moved from the workflow, `.github/workflows/R-CMD-check.yaml:81`). Run it on the `testthat.Rout` of a local `devtools::check()`, and on copies with one planted skip line for each list text, with each bullet, and with a reason split across two lines. Show each planted copy fails and the real file passes. Record the runs in the work log.
- [x] T2: Replace the "List skipped tests" step with a step that runs the T1 script (`if: always()`). Move the two source-reading tests (`test-release-supplement.R:1086`, `test-check-supplement.R:140`) to `tests/testthat/test-source.R`, and add a step that runs it with `testthat::test_local(filter = "^source$")` and stops on a failure, a skip, or no test.
- [x] T3: Read the helpers and test files for state that parallel workers share: the `rendered_site()` cache and its `teardown_env()` cleanup, fixed paths outside `tempdir()`, the size fixtures, and Quarto's cache. Fix what breaks. Add `Config/testthat/parallel: true` and `Config/testthat/start-first` for the three slowest files to DESCRIPTION, and set `TESTTHAT_CPUS` in the workflow to each runner's core count. Run `devtools::test()` three times in a row on the Mac and record each time and result in the work log.
- [x] T4: Add `skip_on_os("windows")` to the six AC4 tests, with a comment that the rules do not depend on the system. Find one test per shortcode (`supplement-doi`, `supplement-download`, `supplement-data-table`, `supplement-license`) that keeps a Windows render, and record them in the work log.
- [x] T5: Append a D-entry that amends D-016: the skip list reads R CMD check's own test output, the source-reading tests run in their own step, test files run in parallel, and the six string-rule loops skip on Windows.
- [x] T6: Run `devtools::test()` and `devtools::check()`. Push the branch to start CI. From that run, read each job's time with `gh run view --json jobs`, its "Starting N test processes" line, and its skip lines, and record them in the work log.

## Work log

- 2026-10-21: created by /milestone-plan.
- 2026-10-21: tier check: milestone — three changes to CI and tests, with choices about Windows coverage and parallel tests.
- 2026-10-21: idea vet: two concerns, both posed at the question set. Windows skips drop Windows coverage of about 80 renders of OS-independent string rules: skip, at the user's choice. Parallel tests could make the parked render flake show more often: run in parallel, at the user's choice. The skip parse depends on testthat's check reporter format, so AC1 fails on a missing summary line or a count mismatch.
- 2026-10-21: question set: push the milestone branch during implement to measure CI before review — granted.
- 2026-10-21: question set: time target — at most 60% of the PR #31 run per job.
- 2026-10-21: promoted the candidate row "Cut the test time of each CI job" (added 2026-10-21) in full.
- 2026-10-21: collision check: D-016 sets the second test pass ("The tests run twice in each job"); T5 amends it. M031 T3 edits the missing-tool list in the workflow; if M033 merges first, that list lives in `.github/scripts/check-skips.R`. No other row, archive, or D-entry overlaps.
- 2026-10-21: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-21: baseline, run 39704929580 (PR #31): job times Windows 1,824 s, macOS 822 s, Ubuntu 1,017 s; the second pass took 819 s, 337 s, and 454 s. testthat 3.3.2's check reporter cuts a skip message at its first line break and groups skips as `• reason (n): 'file:line:col', ...`, wrapped with a 2-space indent.
- 2026-10-21: lessons surfaced: M019/M030 (a branch push restarts all six jobs; Windows jobs take about 30 minutes), M030 (R CMD check's stub `R` and `Rscript` on the PATH), M014 (count failures from `as.data.frame()` of the results).
- 2026-10-21: criteria audit (reduced mode, fresh Opus reader): 3 findings, all taken. AC2 no longer names a plant matrix and states the reason join; the plants moved to T1. AC4 counts skip-line locations, since skip lines name no test. AC5 no longer names the log line or the Mac runs; those moved to T3 and T6. AC1, AC3, AC6, and AC7 had no finding.
- 2026-10-21: plan gate chose parsing the check's `testthat.Rout` over keeping a second `test_local()` pass because the second pass took 45% of the Windows and Ubuntu jobs; falsified by a testthat release whose check reporter drops or reshapes the skip section.
- 2026-10-21: plan gate chose moving the two source-reading tests to their own file over finding the source inside `supplement.Rcheck/00_pkg_src`, because that path belongs to R CMD check's layout; falsified by a third source-reading test that cannot move.
- 2026-10-21: changelog: none, since the change touches only CI and tests.
- 2026-10-21: checkpoint (half-done): the T1 script, the T2 steps and `test-source.R` (run locally: 2 tests, 5 passes, no skip), the T3 DESCRIPTION fields and `TESTTHAT_CPUS` per runner (4, 3, 4), the T4 skips, and D-020 are written; no task is checked off but T5. A local `devtools::check()` is running for T1's real `testthat.Rout`.
- 2026-10-21: T4 Windows renders kept: `supplement-doi` in "the DOI badge shows the version DOI, then the concept DOI", `supplement-download` in "the download link points at the archive", `supplement-license` in "the license shortcode shows readable names for listed ids in any letter case", `supplement-data-table` in "the data table lists each file with its size and a page-relative link".
- 2026-10-21: T1: local `devtools::check()` (macOS, before the M033 test edits) gave 0/0/0 in 291 s; its `testthat.Rout` uses `•` bullets and wraps reasons with a 2-space indent. `check-skips.R` passed on it (9 skips, none for a missing tool) and failed with "tests skipped because a tool is missing: <text>" on all 36 planted copies (12 list texts × `•` bullet, `*` bullet, reason split over two lines). It failed with its own message on a missing folder, a missing summary line, a removed rule line (count 0 vs 9), and `PASS 0`, and read `testthat.Rout.fail` before `testthat.Rout`.
- 2026-10-21: T3: the helpers keep state per R process only (the `rendered_site()` cache, `withr` env vars and options, temp folders), so each parallel worker renders its own cached site; no test writes to a fixed shared path. Quarto's user cache is shared, and no run showed a clash. Three `devtools::test()` runs in a row on the Mac with `TESTTHAT_CPUS=4`: 115 s, 117 s, 115 s, each "Starting 4 test processes", 0 failures, 0 errors, 7 skips, 4,486 passes. The workflow sets `TESTTHAT_CPUS` from a `cpus` matrix value (Windows 4, macOS 3, Ubuntu 4).
- 2026-10-21: T2: the source step sets `TESTTHAT_PARALLEL: false`, since one file needs no worker; run locally it gave 2 tests, 5 passes, no skip. The workflow edit for T2 was made with a short python script rather than the Edit tool, so the app's edit card misses it; the diff shows it.
- 2026-10-21: T6: `devtools::document()` gave no diff; local `devtools::check()` (macOS, `TESTTHAT_CPUS=4`) gave 0/0/0 in 120 s, against 291 s before the change. Its `testthat.Rout` shows "Starting 4 test processes" and 9 skips, the 2 source skips now in `test-source.R`; `check-skips.R` passed on it.
- 2026-10-21: T6: CI run 39721032114 (bbca29f): Ubuntu passed in 286 s and Windows in 548 s; macOS failed in 319 s on "the DOI badge shows the version DOI, then the concept DOI" (`test-shortcodes.R:16`, render exit 1, no stderr in the log). Six concurrent cold-cache renders on the Mac, three times, gave 1 failure of 18 with "ERROR: database is locked" raised in Quarto 1.10.19's `sassCache`.
- 2026-10-21: T3 fix (minor amendment, T3's "fix what breaks"), commit 0cfd0cd: `run_in()` and `run_split()` run a Quarto render once more when it fails with "database is locked". A stand-in `quarto` that fails once showed both helpers retry on that message (status 0 after 2 runs) and not on another error (status 1 after 1 run). Thirty-six more cold-cache renders through `run_split()` gave no lock. `devtools::test()` with 4 processes: 0 failures, 7 skips, 4,486 passes.
- 2026-10-21: implement chose the render retry over a per-worker Quarto cache, because a cache per worker compiles the Sass once in each worker and needs a different HOME; falsified by a lock failure that a second render does not clear.
- 2026-10-21: catch-up: commit 0cfd0cd carried the code without these lines because a work-log edit missed its anchor; this commit carries them.
- 2026-10-21: T6: CI run 39722320941 (0cfd0cd) passed on all three jobs: Windows 530 s (29% of 1,824 s), macOS 415 s (50% of 822 s), Ubuntu 413 s (41% of 1,017 s; 286 s on the first run). "Starting 4 test processes" on Windows and Ubuntu, 3 on macOS. Skip lists: Windows 32 (25 "On Windows", including `test-agreement.R:62`, `:118` and `test-shortcodes.R:28`, `:144`, `:181`, `:226`, and none of `test-shortcodes.R` 12, 91, 117, 277), macOS 9, Ubuntu 8, none for a missing tool. The source step ran 2 tests, 0 failures, on each job.
- 2026-10-21: claim audit: not owed — internal tier.
- 2026-10-21: implement done; status review.

## Decisions

- 2026-10-21 (review): the render retry stands beside the M019 and M020 plan choice of "diagnostics only, no retry". That choice was about failed renders whose cause is unknown. The retry here fires only on Quarto's own "database is locked" text, a cause reproduced on the Mac, so a render that fails any other way, the parked flake's "Running script" shape included, still fails at once. Logging each retry is a candidate row ("Log render retries after a cache lock").

## Review

- 2026-10-21 AC1: the workflow's "List skipped tests" step is `Rscript .github/scripts/check-skips.R check/supplement.Rcheck/tests` and runs no test (no `test_local` or `test_check` in the step). Fresh runs: on a local check's `testthat.Rout` (bbca29f tests) it printed the section and passed (9 skips); a missing folder failed "No test output: neither …"; a folder with both files read `testthat.Rout.fail` and failed "No test passed." (`PASS 0`); a copy with no summary line failed "has no testthat summary line"; a copy with the rule line removed failed "The skip lines count 0 skips, but the summary line counts 9." Pass.
- 2026-10-21 AC2: fresh plant run: all 36 copies (12 list texts × `•` bullet, `*` bullet, reason split over two lines) failed with "1 tests skipped because a tool is missing: <text>", the split ones with the joined reason. CI run 39722320941 (0cfd0cd): the step passed on each job's `testthat.Rout` ("none because a tool is missing"; Windows 32, macOS 9, Ubuntu 8 skips). Pass.
- 2026-10-21 AC3: `tests/testthat/test-source.R` holds "git runs only through its helper" and "release_supplement() starts no process of its own"; neither is left in its old file. The step's code, run fresh in scratch copies of HEAD: as is, passed; with a planted skip, and with a planted failure, stopped "A test that reads the package source failed or skipped."; with the file removed, stopped "No test files found". On CI run 39722320941 the step ran 2 tests, 0 failures, on each job. Pass.
- 2026-10-21 AC4: `skip_on_os("windows")` sits in the six named tests (`test-agreement.R` 58, 114; `test-shortcodes.R` 25, 141, 178, 223). CI run 39722320941 skip lines in those two files: Windows `test-agreement.R:62`, `:118`, `test-shortcodes.R:28`, `:144`, `:181`, `:226` (and `:354`, the existing read-only-folder skip); macOS and Ubuntu none. `supplement.lua` registers 4 shortcodes; each keeps a Windows render in a test with no Windows skip and no Windows skip line: `supplement-doi` and `supplement-download` (`test-shortcodes.R:12`, `render_doi_page()`), `supplement-download` (`:91`), `supplement-license` (`:117`), `supplement-data-table` (`:277`). Pass.
- 2026-10-21 AC5: DESCRIPTION has `Config/testthat/parallel: true` (line 26). CI run 39722320941: "Starting 4 test processes." on Windows and Ubuntu, "Starting 3 test processes." on macOS. Pass.
- 2026-10-21 AC6: CI run 39722320941 (0cfd0cd), the last run so far, `gh run view --json jobs`: windows-latest 530 s (29.1% of 1,824 s), macos-latest 415 s (50.5% of 822 s), ubuntu-latest 413 s (40.6% of 1,017 s). Pass; the PR's own run is read again at step 8 before the merge.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: one byte that is not UTF-8 in the Rout makes `gsub()` stop, so the step shows an R error and no skip list — fix now (`iconv(…, sub = "byte")`; a planted bad byte now passes with 9 skips).
- diff-bug #2: testthat keeps only a skip message's first line, so a missing-tool text after a line break would pass silently — fix now as a stated rule in the script's comment; no skip message in the suite has a line break.
- diff-bug #3: a skip line with no location ends "(1):" and stops the step with "Cannot read these skip lines" — fix now (`item_rx` takes an empty location; a planted "git is not on PATH (1):" fails as a missing tool, another reason passes).
- diff-bug #4: a bullet alone on its line, or "Skipped tests (" inside a failure message, misreads the section — reject (edge: a reason whose first word is wider than the 80-column wrap, or a failure message quoting the rule; both give a loud count-mismatch error).
- diff-bug #5: the retry leaves no trace — follow-up, new row "Log render retries after a cache lock". Its sub-points: an expected-failure test gets the same result, and `quarto use template` retried only on the lock text — reject (false: neither changes a result). `test-shortcodes.R:16` lacking `info =` sits in the row "Show output on failed status checks".
- diff-bug #6: `if: always()` runs both new steps after a cancelled or failed setup and adds errors — reject (edge: a job that already failed or was cancelled; the old step did the same).
- diff-bug #7: DESIGN.md cited D-016 for one process per core — fix now (cites D-020). Parallel teardown's 1 s limit could leave temp files on Windows — reject (edge: a slow unlink in the worker's temp folder; all three jobs passed "checking for detritus").
- blame-history #1: `run_split()` looked for the lock text on stderr only — fix now (stdout and stderr; a stand-in `quarto` writing the text to either stream is retried once, and another error is not).
- blame-history #2: the retry discards the first attempt's output and could hide the parked flake — reject (false: the retry fires only on the lock text, and the flake prints "Running script"); the trace part is diff-bug #5's row.
- blame-history #3: the collation test reset `LC_COLLATE` to "C", not the old value, which under parallel workers reaches whichever file runs next — fix now (restores the value read before the change).
- blame-history #4: the six Windows skips drop the R-to-Lua agreement check on Windows — reject (planned change, chosen at the question set; D-020).
- blame-history #5: reasons cut at the first line break — fix now, as diff-bug #2.
- blame-history #6: `skip_on_os()` sits before the cheap `write_citation()` checks, against the M023 skip-after pattern — reject (planned change: the loops run a render and a `write_citation()` call per shape together).
- blame-history #7: a literal `•` in `check-skips.R` — fix now (written as `•`; the file is ASCII).
- prior-review #1: the retry reverses M019/M020's "no retry", and the CI failure was not matched to the lock text — fix now as a milestone-local decision (Decisions above); the unmatched CI failure — follow-up, noted in the row "template test flake".
- prior-review #2: Windows skips placed before the cheap checks — reject (planned change), as blame-history #6.
- prior-review #3: parallel tests can raise the flake rate — reject (planned change; the risk was posed at the question set).
- prior-review #4: the source-reading tests leave R CMD check — reject (planned change, AC3).
- ripple #1: DESIGN.md's CI paragraph described the second test pass — fixed 53fb384.
- ripple #2: the `rendered_site()` comment said one site per test run — fixed 53fb384 (per test process).
- ripple #3: the candidate row "Cut the test time of each CI job" describes the old CI — reject (planned change: post-merge hygiene removes the row).
- ripple #4: DESIGN.md said `test-agreement.R` runs every shape on both sides — fixed 53fb384 (except on Windows).
- ripple #5: DESIGN.md cited only D-016 for the skip list — fixed 53fb384 (cites D-020).
- ripple #6: DESIGN.md did not name the retry — fixed 53fb384.
- ripple #7: the parked row "template test flake" says no cause was found — follow-up: the row gains the lock finding, since the macOS failure's cause was not seen.
