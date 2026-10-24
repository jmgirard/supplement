<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M053: Keep test writes in temp folders and show failed command output

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — test files and test helpers only; no user of the package runs them
- **Branch/PR:** m053-test-output-temp-folders

## Goal

Three test fixes: the renv render test keeps renv's writes in temporary folders, the linked-output release test fails CI when it cannot make its link, and the status checks that pass no `info` show the command's output when they fail.

## Scope

**In:** the link in "a value error comes before the refusal of a linked output" (`tests/testthat/test-release-supplement.R`, about line 797); `command_failure()` in `tests/testthat/helper-template.R`, so that `expect_status()` and `expect_command_fails()` print a `run_split()` result's `stdout` and `stderr` and a `git_run()` result's raw `stdout`; the 26 status checks that the grep in AC2 printed on 2026-10-24 at commit 64f7ca8 (15 in `test-shortcodes.R`, 7 in `test-release-supplement.R`, 4 in `test-check-supplement.R`); the DESIGN.md sentence on exit-status checks.

**Out:** status checks that already pass `info =` or `label =` stay as they are, including those whose `info` is a case label and not the output (`test-agreement.R`, `test-shortcodes.R`); the unused `env` argument of `run_in()` stays for the candidate row "Settle the env argument of run_in"; a record of Sass lock reruns stays for "Log render retries after a cache lock"; no NEWS entry, because only tests change; the renv render test is not changed, because its render starts no R and so never activates renv (dropped at the user's choice, 2026-10-24; see the work log).

## Acceptance criteria

- [x] AC1: `grep -n 'file.symlink(' tests/testthat/test-release-supplement.R` prints nothing, and "a value error comes before the refusal of a linked output" makes its `CITATION.cff` link with `symlink_or_skip()`.
- [x] AC2: `grep -nE 'expect_(equal|identical|true|false)\(.*\$status *(,|==|!=) *0L' tests/testthat/test-shortcodes.R tests/testthat/test-release-supplement.R tests/testthat/test-check-supplement.R | grep -vE 'info *=|label *='` prints nothing.
- [x] AC3: In `tests/testthat/test-template.R`, three cases pass: `expect_status()` failing on a `run_split()`-shaped result and on a `git_run()`-shaped result, and `expect_command_fails()` failing on a `run_split()`-shaped result. Each case expects the text of the result's `stdout`, and for `run_split()` also its `stderr`, in the failure message.
- [ ] AC4: Running `test-release-supplement.R`, `test-shortcodes.R`, `test-check-supplement.R`, and `test-template.R` on the Mac reports 0 failures and 0 errors, and no test whose lines `git diff main...HEAD` changes is skipped.

## Coverage

- AC1 → T1
- AC2 → T3
- AC3 → T2
- AC4 → T5

## Tasks

- [x] T1: Replace the `skip_if_not(file.symlink(...), "cannot make a link")` line in `test-release-supplement.R` with `symlink_or_skip(outside, file.path(dir, "CITATION.cff"))` from `helper-files.R`.
- [x] T2: In `command_failure()` (`helper-template.R`, about line 108), print `stdout` and `stderr` when the result has no `output`, with raw bytes turned into text. In `test-template.R`, beside the test of the helpers, add cases in which `expect_status()` fails on a `run_split()`-shaped result and on a `git_run()`-shaped result, and `expect_command_fails()` fails on a `run_split()`-shaped result; each case expects the printed text in the failure message, and each is seen failing before the change.
- [x] T3: Rewrite the 26 lines that AC2's grep prints: a success check becomes `expect_status(<result>)`, and a failure check (`!= 0L`, `expect_false(... == 0L)`) becomes `expect_command_fails(<result>)`. Keep the `status`, `stdout`, and `stderr` fields of the list results that `test-shortcodes.R` builds from `run_split()`, so that `command_failure()` finds them. Run the AC2 grep.
- [x] T4: In DESIGN.md (the paragraph that names `expect_status()`, about line 241), state which files' status checks go through the helpers, as the AC2 grep shows.
- [x] T5: Run `devtools::test()` on the Mac, then wait for CI on the PR.

## Work log

- 2026-10-24: created by /milestone-plan.
- 2026-10-24: tier check: not run — work named at the question set.
- 2026-10-24: idea vet: found no concern; each row names a test defect that the code shows (no temp root for the render, a skip reason that `check-skips.R` does not list, 26 status checks that print nothing on failure).
- 2026-10-24: question set: which work to plan — the three test rows "Keep renv render tests in temp folders", "Use the link helper in the release test", and "Show output on failed status checks" in one milestone; the report-dependency and pkgdown-publish questions went unused.
- 2026-10-24: collision check: absorbed the three candidate rows above; "Settle the env argument of run_in" is a distinct scope, since T1 sets the render's variables with withr and does not pass `env` to `run_in()`; no D-entry or archived milestone covers these rows.
- 2026-10-24: inbox sweep: 0 open issues and 0 open PRs on jmgirard/supplement.
- 2026-10-24: lessons surfaced: M018 (a variable set for a Windows render may not reach Quarto's R), M031 (renv's path variables and the sandbox lock), M010 (prove a test can fail before trusting it).
- 2026-10-24: scope: AC3 covers only the 26 checks with no `info` or `label`, as the candidate row names them; the other 34 matches of the first grep already pass `info` or `label`.
- 2026-10-24: plan gate chose setting the render's renv variables with `withr::with_envvar()` over writing them into a site `.Renviron`, because `renv_site()` already sets them that way for `renv::init()`; falsified by a Windows CI render whose R does not see them.
- 2026-10-24: plan gate chose rewriting the 26 checks with `expect_status()` and `expect_command_fails()` over adding `info =` to each, because DESIGN.md names those helpers as the form for exit-status checks; falsified by a result shape that `command_failure()` cannot print.
- 2026-10-24: no changelog entry: tests and test helpers only.
- 2026-10-24: criteria audit (reduced mode, fresh Opus reader): AC1 to AC3 no finding; AC4 promised every `run_split()` and `git_run()` result with no procedure over them, narrowed to the three named test cases; AC5 bound a runner's report and six CI jobs (instrument, proportionality), narrowed to the five test files passing on the Mac, with the CI wait kept as T6 and the Windows stop kept in T1.
- 2026-10-24: implement started on branch m053-test-output-temp-folders.
- 2026-10-24: T1 premise refuted: the renv render test asserts that its render starts no R process (`r_process_lines()` empty), and a local run of `test-renv.R` (15 passed, 0 skipped) left no file in `~/Library/Caches/org.R-project.R/R/renv` newer than a mark made before it, so renv never activates in that render and AC1's sandbox folder would stay empty; stopped for the user, since dropping AC1 drops asked-for work.
- 2026-10-24: substantive amendment: at the user's choice, removed AC1 and T1 (the renv render), removed `test-renv.R` from AC5's file list, moved the renv test to Out, and renumbered AC2–AC5 to AC1–AC4 and T2–T6 to T1–T5 with Coverage; the Goal sentence keeps its renv clause, since a goal is never edited in place, and that clause is void by this line; no criterion's wording changed except the label numbers, the AC2 cross-references, and the narrowed file list of AC4, which goes to a re-audit reader; deleted the candidate row "Keep renv render tests in temp folders" as refuted by the 2026-10-24 run above.
- 2026-10-24: T1 done: the linked-output release test calls `symlink_or_skip()`; `grep -n 'file.symlink(' tests/testthat/test-release-supplement.R` prints nothing; `test-release-supplement.R` 46 tests, 0 failed, 0 skipped on the Mac.
- 2026-10-24: re-audit: AC4 (reduced) — nothing; the reader noted that a skipped test does not pass, so review counts skips in the Mac run of the four files (the reader ran after the amended text was written, not before).
- 2026-10-24: T2 done: `command_failure()` prints `stdout` and `stderr` (raw turned into text) when a result has no `output`; new test "a failed status check shows the output of run_split() and git_run()" in `test-template.R` failed 5 of 5 before the change and passes 5 of 5 after; the neighboring helper test passes 13 of 13.
- 2026-10-24: checkpoint: T3's 26 rewrites (the AC2 grep prints nothing; diff 15, 7, and 4 lines) and T4's DESIGN.md sentence are written; boxes stay open until the full suite run finishes.
- 2026-10-24: T3, T4, T5 done: `devtools::test()` on the Mac ran 391 tests, 0 failed, 0 errors, 10 skipped; the four AC4 files ran 186 tests, 0 failed, 4 skipped, all in `test-check-supplement.R` and none in a test M053 edits: "a name that is not valid UTF-8 matches with ASCII letter case ignored", "a page name that is not valid UTF-8 does not stop the link check", "a path that fs stops on gives the other link rules' answer, not an error", and "on Windows, a junction in docs to a folder outside docs gives the rows of a link" (system guards: Windows only, or names the Mac file system refuses); review judges them against AC4. T5's CI wait runs at review's merge step, where the PR opens.
- 2026-10-24: claim audit: not owed — internal tier.
- 2026-10-24: implement complete; status review.
- 2026-10-24: amendment routed: AC4 — the fresh Mac run of the four files skipped 4 tests (system guards in tests M053 does not touch), and a skipped test does not pass, so AC4 as written cannot be met on the Mac; a second rewrite of AC4 would need a second `re-audit: AC4` line, so the wording went to the user at a stop.
- 2026-10-24: amendment return: AC4 — "Running `test-release-supplement.R`, `test-shortcodes.R`, `test-check-supplement.R`, and `test-template.R` on the Mac reports 0 failures and 0 errors, and no test whose lines `git diff main...HEAD` changes is skipped." — the user chose this wording at the stop; no re-audit reader ran, since the stop replaces it; the amendment was written inline by the review session in place of a `/milestone-implement` round trip, the amendment being the only work, and status stayed `review`.

## Decisions

## Review

- AC1 evidence (2026-10-24, branch head 9276769): `grep -n 'file.symlink(' tests/testthat/test-release-supplement.R` printed nothing (exit 1); line 797 reads `symlink_or_skip(outside, file.path(dir, "CITATION.cff"))`, inside "a value error comes before the refusal of a linked output".
- AC2 evidence (2026-10-24, branch head 9276769): the AC2 grep pipeline printed nothing (exit 1).
- AC3 evidence (2026-10-24, branch head 9276769): `devtools::test(filter = "release-supplement|shortcodes|check-supplement|template")` on the Mac ran "a failed status check shows the output of run_split() and git_run()" in `test-template.R`: 5 expectations, 0 failed, not skipped; its cases are the three AC3 names, each expecting the `stdout` text, and the `stderr` text for the `run_split()` shape.
- AC4 evidence (2026-10-24, same run): the four files ran 186 tests, 0 failed, 0 errors, 4 skipped, all in `test-check-supplement.R` and none in a test M053 edits: "a name that is not valid UTF-8 matches with ASCII letter case ignored", "a page name that is not valid UTF-8 does not stop the link check", "a path that fs stops on gives the other link rules' answer, not an error", "on Windows, a junction in docs to a folder outside docs gives the rows of a link". A skipped test does not pass, so AC4 as written fails on the Mac, and no change in this milestone can make a Windows-only test pass there; the criterion is wrong, not the work. Not ticked.
- Gate (2026-10-24): `cairn_validate.py` all checks passed; `devtools::document()` left no diff in `man/` or `NAMESPACE`; no NEWS entry owed (tests only); no new top-level file; no README.Rmd or pkgdown site change. `devtools::check()` runs after the AC4 decision.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: `command_failure()` stops with "embedded nul in string" on raw `stdout` that holds a nul byte, even when the check passes, since testthat builds the message first (reproduced) — fix now
- diff-bug #2: the `expect_status()` comment promises an `output` check for `run_split()` and `git_run()` results, which hold no `output` — fix now (comment narrowed to `run_in()` and `git_in()`)
- diff-bug #3: the shortcode page builders in `test-shortcodes.R` keep `stderr` but not `stdout`, so their failures print stderr only — fix now
- diff-bug #4: the `expect_command_fails()` comment names only `run_in()` results — fix now
- diff-bug #5: `expect_status()` accepts a double `0` that `expect_identical(x$status, 0L)` refused — reject (planned change: DESIGN.md names the helpers as the form; every rewritten site gets an integer from `system2()`)
- diff-bug #6: `expect_equal()` tolerance against `exit_status()` — reject (false: same result for integer statuses)
- diff-bug #7: `expect_false(s == 0L)` against `expect_command_fails()` — reject (false: the reviewer found the same meaning for NA and NULL)
- diff-bug #8: other `command_failure()` cases (invalid UTF-8, several lines, both fields, NULL result) — reject (false: correct; invalid UTF-8 rechecked here)
- diff-bug #9: the two `expect_command_fails(split)` checks run the same branch as the `expect_status(split)` checks — reject (planned change: AC3 names that case)
- diff-bug #10: the DESIGN.md sentence fails for the nul-byte case — fix now (covered by the #1 fix)
- diff-bug #11: rewritten sites pass shapes the helper prints — reject (false: confirms the change)
- diff-bug #12: the symlink change meets AC1 — reject (false: confirms the change)
- diff-bug #13: AC3, AC4 unticked and the CI wait pending at review — reject (false: expected state)
- blame-history #1: the move to `expect_status()` loosens `expect_identical(x$status, 0L)` — reject (planned change, as diff-bug #5)
- blame-history #2: `expect_command_fails()` is stricter than the old forms — reject (false: no regression)
- blame-history #3: the release test's skip reason now fails CI — reject (planned change: AC1)
- blame-history #4: `test-shortcodes.R:173` keeps `expect_false(page$status == 0L, info = info)` — reject (planned change: Out keeps checks with `info`)
- blame-history #5: `command_failure()` reads `stdout` only when `output` is NULL — reject (false: confirms the change)
- prior-review #1: a Windows job without link rights now fails at the skip check — reject (planned change: AC1; `test-template.R` already skips with the same listed reason and the Windows jobs passed in M052)
- prior-review #2: `rawToChar()` output in `sprintf()` may warn on invalid bytes — reject (false: an `\xff` byte printed with no warning or error here)
- ripple #1: the candidate row "Show output on failed status checks" describes the fixed problem — reject (planned change: step 9 hygiene graduates the row)
- ripple #2: the candidate row "Use the link helper in the release test" describes the fixed problem — reject (planned change: step 9 hygiene graduates the row)
- ripple #3: the `expect_command_fails()` comment names only `run_in()` — fix now (same as diff-bug #4)
