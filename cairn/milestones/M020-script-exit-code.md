# M020: A failed project script shows its exit code in the test log

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — a change to the test helpers only, which no package user runs
- **Branch/PR:** m020-script-exit-code

## Goal

When a project script fails during a template test's render, the test log shows the script's exit code.

## Scope

**In:** `run_in()` in `tests/testthat/helper-template.R` runs `quarto` with `QUARTO_LOG_LEVEL=DEBUG`, so a failed `_scripts/setup.ts` prints Quarto's `[execProcess] Success: false, code: <n>` line in the output that `expect_status()` shows on failure. A test that plants a silent failing script. Repeat full-suite runs on the Mac to catch the "template test flake" failure with the new output, and a record of what they show.

**Out:** a retry of a failed render (the question set kept diagnostics only); a fix for a cause outside this repo; posting an issue on quarto-dev/quarto-cli (the user posts a draft if they choose); `run_split()` and the status checks in other test files → the "status check output" row. A cause found in this repo → its fix comes in through an amendment of this milestone (`/milestone-implement` step 6) or `/hotfix`.

## Acceptance criteria

- [x] AC1: When `_scripts/setup.ts` in a site from `use_template()` holds only `Deno.exit(3);`, `quarto render` run through `run_in()` returns an exit status other than 0 and output that holds the line `[execProcess] Success: false, code: 3`.
- [ ] AC2: The AC1 behavior holds on Windows: the test of AC1 passes in the `R-CMD-check` workflow's Windows job on the milestone's pull request.
- [x] AC3: Setting `QUARTO_LOG_LEVEL=DEBUG` in `run_in()` changes no existing test's result in `devtools::test()` on the Mac.

## Coverage

- AC1 → T1, T2
- AC2 → T2, T4
- AC3 → T2, T4

## Tasks

- [x] T1: In `tests/testthat/test-template.R`, add a test (skips with `skip_if_no_quarto()`) that makes a site with `use_template()`, writes `Deno.exit(3);` as the whole of `_scripts/setup.ts`, runs `run_in(dir, "quarto", "render")`, and checks `expect_command_fails()` and a fixed-string match of the code line. Run it before T2 and see it fail on the missing line (failure identity: the match, not the status).
- [x] T2: In `run_in()` (`helper-template.R:32`), when `command` is `"quarto"`, run the command inside `withr::with_envvar(c(QUARTO_LOG_LEVEL = "DEBUG"), …)`; not through `system2(env =)`, which Windows does not pass to commands such as quarto. Leave `run_split()` and `git_in()` as they are. Update the helper's comment and the `cairn/DESIGN.md` test paragraph (around line 155) from a same-session read of the code. Run `devtools::test()`.
- [x] T3: Run the full suite 20 times on the Mac in the background, counting failures from `as.data.frame(devtools::test(reporter = "silent"))`. For each failure, record in the work log the test name and the `code:` line or its absence. If a failure shows a cause in this repo, stop and amend this milestone for the fix. If it shows a cause in Quarto or Deno, write a draft issue for quarto-dev/quarto-cli (Quarto version, exit code, steps) to `cairn/references/quarto-script-exit.md` with its `INDEX.md` line.
- [x] T4: Run `devtools::check()` on the Mac (0 errors, 0 warnings). The check that the T1 test is not in the Windows job's skip list in CI waits for the PR's CI run at review.

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: not run — work named at the question set.
- 2026-10-19: question set: what to plan — the "template test flake" row; if the cause is upstream — diagnostics only, no retry; an issue on quarto-dev/quarto-cli — draft only, the user posts it.
- 2026-10-19: collision check: absorbs the "template test flake" candidate row (the row stays until review hygiene narrows or graduates it); extends M019 (done), whose plan gate also chose no retry; "status check output" row is a separate scope; DECISIONS.md headings (D-001 to D-016) hold no match; GitHub inbox: 0 open issues, 0 open PRs.
- 2026-10-19: lessons applied: M019 (`QUARTO_LOG_LEVEL=DEBUG` gives the `[execProcess]` code line; `system2()` quoting), M014 (count failures with the silent reporter), M010 (prove the test can fail), M018 (Windows runner).
- 2026-10-19: criteria audit (reduced, run after the question set because the work was chosen there): AC1 named the test, an instrument, and was reworded to the helper's behavior; the draft AC2 ("suite and three-system CI pass") was too wide and bound instruments, and was split into AC2 (the AC1 behavior on Windows) and AC3 (debug logging changes no existing test result); the three-system CI stays a merge-gate condition.
- 2026-10-19: plan gate chose debug logging inside `run_in()` for every `quarto` command over a new `quarto_in()` helper at each `run_in(…, "quarto", …)` call site, because the change stays in one place and debug lines go to stderr, which a passing check never prints; falsified by a test that matches `run_in()` output and fails on the added lines.
- 2026-10-19: plan gate kept `run_split()` without debug logging, because the shortcode and agreement tests match text in its stderr; falsified by a flake failure seen in a `run_split()` render.
- 2026-10-19: a dry run in a scratch site: a `setup.ts` holding `Deno.exit(3)` printed `[execProcess] Success: false, code: 3` under debug logging; a good render printed 317 debug lines on stderr and nothing on stdout, and `quarto inspect` stdout stayed valid JSON.
- 2026-10-19: no NEWS.md entry, because the change is in tests only.
- 2026-10-19: started on branch m020-script-exit-code.
- 2026-10-19: T1: the new test failed before T2 on the match only (status check passed; output held only "Running script '_scripts/setup.ts'"); it uses `skip_if_no_quarto(needs_r = FALSE)` because the script fails before any R code runs.
- 2026-10-19: T2: `run_in()` wraps the call in `withr::with_envvar()` with `QUARTO_LOG_LEVEL=DEBUG` when `command` is "quarto"; the T1 test passes; DESIGN.md test paragraph updated; `devtools::test()` 252 tests, 0 failed, 0 errors, 5 skipped (4 min 23 s).
- 2026-10-19: T3: 20 full-suite runs on the Mac (testthat 3.3.2, run in the background with no other job): each 252 tests, 0 failed, 0 errors, 5 skipped (the same 5 each run: four Windows-only tests and one case-sensitive-disk test). No failure, so no exit code was read, no cause was found, and no issue draft was written. M019 saw 1 failure in 10 runs.
- 2026-10-19: T4: `devtools::check()` 0 errors, 0 warnings, 0 notes. Minor amendment: the CI skip-list part of T4 moved to review, because CI runs only after review pushes the branch.
- 2026-10-19: claim audit: not owed — internal tier.

## Decisions

## Review

- Sync: branch cut from origin/main e47a7dc, which has not moved.
- AC1 evidence: on the branch, the test "a render whose setup script fails with no output shows the script's exit code" passes (3 expectations) before and after the fix-now changes; with main's `helper-template.R` copied over the branch's, it fails on the code line (the status check passes), and with `QUARTO_LOG_LEVEL=INFO` set by the caller it fails the same way.
- AC3 evidence: `devtools::test()` run per test on the branch and on an export of origin/main, results compared line by line: main 251 tests (246 pass, 5 skip, 0 fail), branch 252 (247 pass, 5 skip, 0 fail); the only difference is the new AC1 test. After the fix-now changes: 252 tests, 0 failed, 0 errors, 5 skipped.
- AC2: waits for the PR's CI run; checked before the merge from the Windows job's result and skip list.
- Gate: `cairn_validate.py` all checks passed; `devtools::document()` no diff; no README.Rmd or `_pkgdown.yml`; no new top-level file; no NEWS.md entry (tests only); `devtools::check()` 0 errors, 0 warnings, 0 notes after the fix-now changes.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the code-line match was a substring of the joined output, so "code: 30" would also match — fix now (exact line with `expect_contains()`).
- diff-bug #2: `quarto inspect` output in `run_in()` now holds debug lines before the JSON — reject, planned change: the inspect test's regex matches pass (AC3 evidence), and no test parses that output.
- diff-bug #3: the helper comment said debug lines go to standard error, which `run_in()` merges into `output` — fix now (comment says the lines are in `output` and a match must allow for them).
- diff-bug #4: a caller's own `QUARTO_LOG_LEVEL` was overridden — fix now (`run_in()` sets the variable only when it is unset; DESIGN.md says so).
- diff-bug #5: `identical(command, "quarto")` missed a full path or `quarto.exe` — fix now (compares the base name without `.exe`).
- diff-bug #6: each failed quarto check now prints about 317 debug lines — reject, planned change (Scope In).
- diff-bug #7: the criteria boxes were unticked and AC2 unproven — reject, false at review: review ticks each box against its evidence, and AC2 waits on PR CI.
- blame-history #1: the AC1 test matches a Quarto log line that a Quarto upgrade can change — reject, planned change: AC1 names that line, and CI pins Quarto 1.10 (D-016).
- blame-history #2: the inspect test reads merged debug output — reject, same as diff-bug #2.
- blame-history #3: the `env` argument of `run_in()` has no caller since M018 — follow-up, new row "run_in env argument" (pre-existing).
- prior-review #1: the Windows behavior rests on CI, as M019's review asked — reject, planned change: AC2 is checked from the PR's Windows job before the merge.
- prior-review #2: the inspect test reads merged debug output — reject, same as diff-bug #2.
- ripple #1: the "template test flake" row's next step (run the suite with debug logging) is now done for `run_in()` renders — follow-up, review hygiene narrows that row.
- ripple #2: DESIGN.md "shows everything the command printed" now includes debug lines — reject, false: the text is still true.
- ripple #3: the inspect test reads merged debug output — reject, same as diff-bug #2.
- ripple #4: the M019 lesson on `QUARTO_LOG_LEVEL=DEBUG` — reject, false: still accurate.
- ripple #5: the new DESIGN.md text matches the code — reject, no disagreement.
