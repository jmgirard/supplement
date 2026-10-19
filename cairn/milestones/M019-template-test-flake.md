# M019: A failing template test prints the cause of the failure

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the flake's cause can lie in the template's setup script `inst/template/_scripts/setup.ts`, which users run
- **Branch/PR:** m019-template-test-flake

## Goal

A failing template test prints the output of the command it checked, and a cause of the template test flake that the repeat runs find is fixed.

## Scope

**In:** the status checks and output checks in `tests/testthat/test-template.R` and `tests/testthat/helper-template.R`; a checked result for each `git init` call in `test-template.R`; repeat runs of the tests on the local Mac and three manual runs of the check workflow on main; a fix and a regression test for a cause the runs find in this repo; a NEWS.md entry if the template's behavior changes; an update of the candidate row "template test flake" with the run counts and any failure output.

**Out:**
- Status checks in the other test files (`test-shortcodes.R`, `test-release-supplement.R`, `test-check-supplement.R`, `test-create-supplement.R`, `test-add-render.R`), and output that `git_run()` and the shortcode test runners do not capture → new candidate row "status check output".
- A retry of a failed command in any test → not planned (plan gate: diagnostics only).
- A cause outside this repo (the Quarto CLI, git, the runner) → the candidate row "template test flake" names it with its output.

## Acceptance criteria

- [ ] AC1: Each of the 20 `expect_` calls that `grep -nE '\$status' tests/testthat/test-template.R tests/testthat/helper-template.R` lists at commit 7f789c5 shows the checked command's printed output (stdout and stderr together, as `run_in()` returns them) in its failure message, through `info` or through a test helper that does so. Each of the four `git_in(..., c("init", "-q"))` results in `test-template.R` (lines 103, 129, 180, 202 at 7f789c5) is checked the same way.
- [ ] AC2: A test uses `expect_failure()` on that helper with a command that prints one known line to stdout and another to stderr and exits 1. The failure message holds both lines when exit 0 is expected and when exit 1 is expected with no output.
- [ ] AC3: The three `expect_length(<x>$output, 0)` checks in `test-template.R` (lines 121, 136, 183 at 7f789c5) are replaced by a check that fails with a message holding `docs/index.html` when the command's output is `"docs/index.html"`, shown by a test.
- [ ] AC4: If one of the T4 runs fails in a test in `test-template.R` and the failure's output names a cause in this repo, the change fixes that cause and adds a test that fails on that cause before the fix and passes after it. If the fix changes `inst/template/`, NEWS.md has an entry that names the user-visible change.
- [ ] AC5: No test that this milestone adds or changes retries a command or calls `skip()` after a command fails, as read from `git diff main -- tests/`.
- [ ] AC6: `Rscript -e 'devtools::test()'` reports no failure on the local Mac, and every job of the check workflow on the branch's last commit passes.

## Coverage

- AC1 → T1, T2
- AC2 → T1
- AC3 → T3
- AC4 → T4, T5
- AC5 → T1, T2, T3, T5
- AC6 → T6

## Tasks

- [x] T1: Add a helper in `helper-template.R` (for example `expect_status(result, 0L)`) that checks a command result's exit status and puts the result's output in the failure message. Add the AC2 test with a command that writes to stdout and stderr and exits 1.
- [x] T2: Change each status check that AC1 lists to use the helper or `info`, and check each `git init` result in `test-template.R`. Confirm with the AC1 grep at 7f789c5 that all 20 calls and the four `git init` calls are covered.
- [x] T3: Replace the three output-length checks with a check that shows the printed lines (for example `expect_identical(x$output, character())`), and add the AC3 test.
- [x] T4: Repeat runs with the new diagnostics: `testthat::test_file("tests/testthat/test-template.R")` 30 times and `devtools::test()` 10 times on the local Mac, and start the check workflow on main 3 times with `gh workflow run R-CMD-check.yaml --ref main`, watched in the background. Write one work-log line with the pass and fail counts, and quote each failure's output in its own line.
- [x] T5: If a run failed: name the cause from its output. For a cause in this repo, write the test that fails on it, fix it, and add the NEWS.md entry if `inst/template/` changes. For a cause outside the repo, write it with the output into the candidate row "template test flake".
- [ ] T6: Run `devtools::test()` and `devtools::check()`, and update the candidate row "template test flake" with the run counts (the review's post-merge hygiene graduates or narrows it).

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: not run — work named at the question set.
- 2026-10-19: absorbs candidate row "template test flake"; the row's `test-template.R:140` points at the M009-era line, now the `expect_length()` in `expect_site_not_ignored()` (line 183); the three M009 failures match its three calls in one test, so a condition that affected the whole run is more likely than one random call.
- 2026-10-19: collision check: no planned or archived milestone and no D-entry covers the flake; M018 sent it to this row. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-19: lessons harvested: M018 (`long_dir()`, RUNNER~1), M010 (copy main's file over the working one to prove a test can fail), M014 (count failures from `as.data.frame(devtools::test(reporter = "silent"))`; `NOT_CRAN=true` for `test_file()`).
- 2026-10-19: criteria audit (full mode, fresh Opus reader): AC1 over 44 checks in four files was a proxy that the refactor itself empties → narrowed to the 20 calls listed at 7f789c5 plus the unchecked `git init` calls; the planted check used one exemplar → AC2 varies stream (stdout, stderr) and expected status (0, 1); AC2 draft had no probe → AC3 names one; AC3 draft had an open set of runs and no outside-cause branch → AC4 names the T4 runs and sends an outside cause to the row; the no-retry clause covered the whole suite → AC5 reads only this milestone's diff; recording the run counts is a record, so it moved to T4 and T6; NEWS entry added to AC4.
- 2026-10-19: scope: status checks outside the template tests go to new candidate row "status check output", because the flake sits in `test-template.R` and those files have other capture paths (`git_run()` drops stderr).
- 2026-10-19: question set: what to work on — template test flake.
- 2026-10-19: question set: if no failure comes back — ship the diagnostics only, no retry.
- 2026-10-19: question set: permission to start the check workflow on main 3 times — granted.
- 2026-10-19: plan gate chose diagnostics only over a one-time retry of failed Quarto renders, because a retry hides an intermittent bug in `setup.ts` from users; falsified by a cause shown to lie outside the repo and to fail often enough to block reviews.
- 2026-10-19: status in-progress; branch m019-template-test-flake cut from main at 46a49bf.
- 2026-10-19: T1: `expect_status(result, status = 0L, output = NULL)` and `expect_command_fails(result)` in `helper-template.R`, built on `expect()`, show the command's printed lines in the failure message; `output` folds the no-output check into the same call (used by T3). Tests "a failed status check shows what the command printed" (stdout and stderr lines, expected 0 and expected 1 with no output) and "a check for no output shows the lines the command printed". R 4.6 `system2()` quotes the command itself, so an `shQuote()`d command path fails with "error in running command"; the test passes the Rscript path unquoted. Template tests pass.
- 2026-10-19: T2: 17 of the 20 AC1 calls and the four `git init` calls now go through `expect_status()` or `expect_command_fails()`; the three `kept$status` calls change with their output checks in T3. Template tests pass.
- 2026-10-19: T3: the three `kept$status` / `expect_length(kept$output, 0)` pairs became `expect_status(kept, 1L, output = character())`; the AC3 grep lists no line. Planted `analyses/plot.png` (an ignored path) in the figures check: it failed with "expected exit status 1 and no output. It printed: analyses/plot.png"; restored. Template tests pass.
- 2026-10-19: T4: ran `devtools::test(filter = "template")` (same file and helpers as `test_file()`) 30 times: 30 passed. `devtools::test()` 10 times: 9 passed, run 5 failed 3 expectations. Check workflow on main 3 times (runs 39326501344, 39326509103, 39326517070, 46a49bf): 9 of 9 jobs passed.
- 2026-10-19: T4 failure, full run 5, test "the example report saves a figure that the next full render publishes": the full `quarto render` after the render by name "exited with status 1; expected exit status 0. It printed: Running script '_scripts/setup.ts'" (nothing else); the two figure checks then failed for `docs/figures/bootstrap-means.png`. Same shape as the M017 failure (`quarto render` exited 1).
- 2026-10-19: T5: Quarto 1.10.19's `runScripts()` throws `new Error()` with no message when a project script fails, and logs the exit code only at debug level. A `setup.ts` that calls `Deno.exit(1)` gives the same bare output; one that throws prints "error: Uncaught (in promise) Error: boom", so the failed run's Deno process ended without output. 1,000 debug-logged full renders of one site and 400 runs of the failed test's sequence (new site, render by name, full render; 800 renders) all exited 0. The output names no cause in this repo, so AC4's fix branch does not apply; no template change and no NEWS entry. The candidate row "template test flake" now holds the output, the counts, and the next step (`QUARTO_LOG_LEVEL=DEBUG` over the full suite).

## Decisions

## Review
