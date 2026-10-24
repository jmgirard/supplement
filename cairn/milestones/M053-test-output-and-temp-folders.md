<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M053: Keep test writes in temp folders and show failed command output

- **Status:** in-progress
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

**In:** the `quarto render` in "a site set up with renv renders with no R, checks clean, and keeps its library out of git" (`tests/testthat/test-renv.R`) and the `renv_site()` helper it uses; the link in "a value error comes before the refusal of a linked output" (`tests/testthat/test-release-supplement.R`, about line 797); `command_failure()` in `tests/testthat/helper-template.R`, so that `expect_status()` and `expect_command_fails()` print a `run_split()` result's `stdout` and `stderr` and a `git_run()` result's raw `stdout`; the 26 status checks that the grep in AC3 printed on 2026-10-24 at commit 64f7ca8 (15 in `test-shortcodes.R`, 7 in `test-release-supplement.R`, 4 in `test-check-supplement.R`); the DESIGN.md sentence on exit-status checks.

**Out:** status checks that already pass `info =` or `label =` stay as they are, including those whose `info` is a case label and not the output (`test-agreement.R`, `test-shortcodes.R`); the unused `env` argument of `run_in()` stays for the candidate row "Settle the env argument of run_in"; a record of Sass lock reruns stays for "Log render retries after a cache lock"; no NEWS entry, because only tests change.

## Acceptance criteria

- [ ] AC1: In `tests/testthat/test-renv.R`, the `quarto render` of "a site set up with renv renders with no R, checks clean, and keeps its library out of git" runs with `RENV_PATHS_ROOT` set to the temporary root folder that `renv_site()` gave `renv::init()`, and with `RENV_PATHS_SANDBOX` set to a temporary folder that is empty before the render; the test expects that sandbox folder to hold at least one entry after the render.
- [ ] AC2: `grep -n 'file.symlink(' tests/testthat/test-release-supplement.R` prints nothing, and "a value error comes before the refusal of a linked output" makes its `CITATION.cff` link with `symlink_or_skip()`.
- [ ] AC3: `grep -nE 'expect_(equal|identical|true|false)\(.*\$status *(,|==|!=) *0L' tests/testthat/test-shortcodes.R tests/testthat/test-release-supplement.R tests/testthat/test-check-supplement.R | grep -vE 'info *=|label *='` prints nothing.
- [ ] AC4: In `tests/testthat/test-template.R`, three cases pass: `expect_status()` failing on a `run_split()`-shaped result and on a `git_run()`-shaped result, and `expect_command_fails()` failing on a `run_split()`-shaped result. Each case expects the text of the result's `stdout`, and for `run_split()` also its `stderr`, in the failure message.
- [ ] AC5: Every test in `test-renv.R`, `test-release-supplement.R`, `test-shortcodes.R`, `test-check-supplement.R`, and `test-template.R` passes on the Mac.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T4
- AC4 → T3
- AC5 → T6

## Tasks

- [ ] T1: In `helper-template.R`, let the caller of `renv_site()` reach the root folder it made (about line 209). In `test-renv.R` (about line 56), run the render inside `withr::with_envvar()` with that root, a new empty `withr::local_tempdir()` as `RENV_PATHS_SANDBOX`, `RENV_SANDBOX_LOCKING_ENABLED=FALSE`, the four `NA` unsets that `renv_site()` uses, and `QUARTO_LOG_LEVEL=DEBUG`. Add the expectation that the sandbox folder is not empty after the render, and see it fail first with the render's old variables. Update the `renv_site()` comment so that it covers the render. If the Windows CI job shows that the variables do not reach the R that Quarto runs (LESSONS M018), stop for an amendment; the fallback is a `.Renviron` in the site.
- [ ] T2: Replace the `skip_if_not(file.symlink(...), "cannot make a link")` line in `test-release-supplement.R` with `symlink_or_skip(outside, file.path(dir, "CITATION.cff"))` from `helper-files.R`.
- [ ] T3: In `command_failure()` (`helper-template.R`, about line 108), print `stdout` and `stderr` when the result has no `output`, with raw bytes turned into text. In `test-template.R`, beside the test of the helpers, add cases in which `expect_status()` fails on a `run_split()`-shaped result and on a `git_run()`-shaped result, and `expect_command_fails()` fails on a `run_split()`-shaped result; each case expects the printed text in the failure message, and each is seen failing before the change.
- [ ] T4: Rewrite the 26 lines that AC3's grep prints: a success check becomes `expect_status(<result>)`, and a failure check (`!= 0L`, `expect_false(... == 0L)`) becomes `expect_command_fails(<result>)`. Keep the `status`, `stdout`, and `stderr` fields of the list results that `test-shortcodes.R` builds from `run_split()`, so that `command_failure()` finds them. Run the AC3 grep.
- [ ] T5: In DESIGN.md (the paragraph that names `expect_status()`, about line 241), state which files' status checks go through the helpers, as the AC3 grep shows.
- [ ] T6: Run `devtools::test()` on the Mac, then wait for CI on the PR.

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

## Decisions

## Review
