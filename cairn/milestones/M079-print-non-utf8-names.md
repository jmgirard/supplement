# M079: Print names that are not UTF-8 in messages

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — `check_supplement()` and `render_supplement()` print a row or message where they can now stop with an error
- **Branch/PR:** m079-print-non-utf8-names

## Goal

On Linux, a name that is not valid UTF-8 no longer stops the `"leftover-output"` row of `check_supplement()` or the no-report message of `render_supplement()`.

## Scope

**In:**
- `check_leftover_output()` (`R/check-supplement.R:1532`) passes the `file` value of each row through `show_text()`. A folder name in `_freeze/analyses/` that is not valid UTF-8 then shows each such byte as `<xx>`, in the returned data frame and in the printed row, as the other rows already do. Now `report_problems()` prints the raw name with cli's `{.path}`, which stops on such text (LESSONS, M066).
- `render_supplement()`'s message for a name with no report (`R/render-supplement.R:110`). `check_reports()` lets only ASCII names through, so only the names that `report_file_names()` lists can hold such bytes. On Linux in a UTF-8 locale, `list.files(pattern =)` leaves such a name out (LESSONS, M078). A Linux-only test shows whether the message stops. If it does, `fold_case()` replaces `tolower()` in that line. If it does not, the code stays as it is.
- Tests in `tests/testthat/test-check-supplement.R` and `tests/testthat/test-render-supplement.R`. The help page of `check_supplement()` and NEWS.md describe the change.

**Out:**
- Folder names that differ from a report name only in Unicode form: the candidate row "Match folder names across Unicode forms" holds them.
- macOS and Windows: their file systems refuse such a name (LESSONS, M066), so the tests run on Linux only. No row follows.
- R versions other than the release that CI runs: the render result rests on R 4.6's `list.files()` and `tolower()`. The candidate row "Keep tests within the Suggests floors" holds the lack of a CI job on R 4.1.0.

## Acceptance criteria

- [x] AC1: The site is a new site whose `_freeze/analyses/` holds two folders with `execute-results/html.json`, one named `caf` then byte 0xE9 and one named `deleted`. Its `analyses/` holds no report of either name. On Linux, in a UTF-8 locale and in the C locale, `check_supplement(site)` returns without an error. Its result holds one `"leftover-output"` row whose `file` is `_freeze/analyses/caf<e9>` and one whose `file` is `_freeze/analyses/deleted`.
- [x] AC2: The site is a `plain_site()` (`tests/testthat/test-render-supplement.R:22`) whose `analyses/` holds `models.qmd` and a report named `caf`, byte 0xE9, `.qmd`. On Linux with the R release, in a UTF-8 locale and in the C locale, `render_supplement("Models", path = site)` stops with an error of class `supplement_error_no_report` and runs no Quarto command. The message names `analyses/Models.qmd` and `analyses/models.qmd`.
- [x] AC3: The help page of `check_supplement()` says, in its `"leftover-output"` entry, that the row's `file` shows each byte that is not valid UTF-8 in the folder's name as `<xx>`. NEWS.md describes the change to that row. If the code of `render_supplement()` changes, NEWS.md describes that change too.
- [x] AC4: The `verify` slot is clean: `devtools::document()` leaves no diff, `devtools::test()` has 0 failures, and R CMD check of the committed branch head gives 0 errors and 0 warnings on Windows, macOS, and Linux.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T3
- AC3 → T4
- AC4 → T5

## Tasks

- [x] T1: Write the AC1 test near `tests/testthat/test-check-supplement.R:739`, the test "a name that is not valid UTF-8 matches with ASCII letter case ignored". Write the AC2 test after the no-report test in `tests/testthat/test-render-supplement.R` (line 186 to 210). Make the bad names with `file.create()` or `dir.create()`. Skip on macOS and Windows. If a name cannot be made on Linux, fail and do not skip. Commit the tests alone. Ask before the push, since the question set did not cover a push before review. Then push, so ubuntu-latest runs the tests on the current code. In its `tests/testthat.Rout`, AC1 is to fail on cli's error that the text is not valid UTF-8. If AC1 passes there, or fails for another reason, such as no `caf<e9>` row, that is the goal-wrong stop. Record both results in the work log.
- [x] T2: In `check_leftover_output()`, pass each row's `file` through `show_text()`. Push and read ubuntu-latest's `tests/testthat.Rout` to see the AC1 test pass, not skip.
- [x] T3: If the AC2 test failed in T1, replace `tolower()` with `fold_case()` on both sides of `R/render-supplement.R:110` and push to see it pass on ubuntu-latest. If it passed, change no code and write a work-log line that the row's premise did not hold.
- [x] T4: Update the `"leftover-output"` entry of the roxygen block of `check_supplement()` and NEWS.md as AC3 says. Run `devtools::document()`.
- [x] T5: Run the `verify` slot on the committed branch head: `devtools::document()`, `devtools::test()`, `devtools::check()` (the macOS evidence). Wait for the R-CMD-check workflow on the branch head, the evidence for Windows and Linux.

## Work log

- 2026-10-29: created by /milestone-plan.
- 2026-10-29: tier check: not run — work named at the question set.
- 2026-10-29: question set: what to work on — "Print leftover folders with odd bytes" and "Render by name beside non-UTF-8 reports"; the leftover row's `file` column — `show_text()` with `<xx>`, as the other rows. A branch push before review was not asked, so T1 asks before its push.
- 2026-10-29: idea vet: gap — the render row's stated cause looks unreachable, since `check_reports()` admits only ASCII names, `list.files(pattern =)` leaves such a name out in a UTF-8 locale (M078), and `tolower()` works byte by byte in the C locale (seen on macOS); reading taken: a Linux test decides, and the code changes only if it fails on main. The other two vet questions found no concern.
- 2026-10-29: lessons used: 2026-10-27 (M066), 2026-10-29 (M078), 2026-10-28 (M068).
- 2026-10-29: collision check: absorbs the candidate rows "Print leftover folders with odd bytes" and "Render by name beside non-UTF-8 reports" in full; extends done M078 and M042 (the leftover-output check); no D-entry covers name encoding. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-29: plan gate chose a test-first check of the render message over replacing `tolower()` with `fold_case()` at once, because a change with no failing test on main is not a bug fix under "What gets a test"; falsified by a Linux run where the AC2 test fails on main.
- 2026-10-29: criteria audit (full mode, Opus reader): 7 findings, 6 taken, 1 answered. T1 now stops on any other failure on main; AC1 adds the C locale; AC2 names `plain_site()` and the R release, with an Out item for older R; AC3 says "each byte that is not valid UTF-8 in the folder's name" and ties the NEWS line to a code change, not a task; AC4 and T5 name the committed branch head. Answered: the Goal named all messages, so it now names the two; git-listed names already show `<xx>` in their rows (test "a git file name that is not valid UTF-8 is still checked"), so no row follows. No IP or D-entry conflict; `show_text()` gives `caf<e9>` for the AC1 bytes (run by the reader).

- 2026-10-29: implement started on m079-print-non-utf8-names; status in-progress.
- 2026-10-29: T1 tests written: "a leftover folder whose name is not valid UTF-8 shows its bytes in the row" (test-check-supplement.R) and "a report name that is not valid UTF-8 does not stop the no-report message" (test-render-supplement.R), each in `C.UTF-8` and `C`; both skip on macOS, as planned; not yet run on Linux.
- 2026-10-29: question set: push the branch before review — yes, for T1, T2, and T3, with no further ask (chip at the T1 stop). Pushed ada368c; R-CMD-check run 40950122191.
- 2026-10-29: T1 done: on ubuntu-latest (run 40950122191, ada368c, current code) the leftover test failed in `C.UTF-8` at `expect_no_error()` with "input string 1 is invalid UTF-8", raised from `cli::cli_bullets()` in `report_problems()` (`R/check-supplement.R:603`), after the warning "unable to translate '_freeze/analyses/caf<e9>' to a wide string"; the render test passed in both locales (not in the skip list); FAIL 2 (both from the leftover test).
- 2026-10-29: T2: `check_leftover_output()` passes each row's `file` through `show_text()`.
- 2026-10-29: T3 done: the render test passed on current code, so no code change; the row's premise ("`tolower()` ... stops ... on a name that is not valid UTF-8") did not hold on ubuntu-latest with the R release, since in `C.UTF-8` `report_file_names()` does not list the name and in `C` `tolower()` does not stop. The test stays, as AC2 names it.
- 2026-10-29: T4: help page "leftover-output" entry and NEWS.md updated; `devtools::document()` rewrote man/check_supplement.Rd. Pushed 1c9dd82; R-CMD-check run 40951717214.
- 2026-10-29: claim audit: 8 claims read, 1 corrected — NEWS.md ("as the other rows do" → "as the `"report-name"` row does", since the broken-link and web-link rows do not use `show_text()`; re-read once, holds). Render test name's claim answered from the ubuntu run and the M078 lesson.
- 2026-10-29: T2 done: run 40951717214 on 1c9dd82 passed on all three systems; ubuntu-latest `testthat.Rout` FAIL 0, WARN 0, SKIP 14, PASS 6297, and neither new test is in the skip list. Local `devtools::check()` on 1c9dd82: 0 errors, 0 warnings, 0 notes.
- 2026-10-29: T5: `devtools::document()` no diff and local `devtools::check()` 0/0/0 on e077d4f (macOS). Run 40953514637 on e077d4f: ubuntu and macOS passed; windows-latest failed one test, "pages with many comments, elements, and script state changes are read in time" (`test-check-supplement.R:1357`, 10.19 s against its 10 s bound, M076 code this branch does not touch; it passed on 1c9dd82). Reran the failed job. See the candidate row "Time the large-page tests on Windows".
- 2026-10-29: T5 done: the windows-latest rerun of run 40953514637 on e077d4f passed, so all three systems are green on the last code commit; status review. Later commits change only `cairn/`.

## Decisions

## Review

- Sync: main at 4af27ca, unmoved since the cut; no PR yet (route (d)); Copilot round off. Head 47e2db3 differs from the last code commit e077d4f only in `cairn/` (`git diff --stat e077d4f..HEAD`), which `.Rbuildignore` leaves out of the build.
- AC1 evidence: R-CMD-check run 40953514637 on e077d4f, ubuntu-latest `testthat.Rout` FAIL 0 | WARN 0 | SKIP 14 | PASS 6297, with the 14 skips listed and "a leftover folder whose name is not valid UTF-8 shows its bytes in the row" (`test-check-supplement.R:755`) not among them. The test builds the AC1 site with `new_site()` and `stored_file()` for `caf`+0xE9 and `deleted`, and in `C.UTF-8` and `C` runs `expect_no_error()` on `check_supplement()` and asserts the two `file` values exactly. On ada368c (old code) the same test failed in `C.UTF-8` with cli's "input string 1 is invalid UTF-8" from `report_problems()` (run 40950122191).
- AC2 evidence: the same ubuntu-latest run (R release) passed "a report name that is not valid UTF-8 does not stop the no-report message" (`test-render-supplement.R:212`, not in the skip list). It uses `plain_site("models")` plus a file `caf`+0xE9`.qmd`, and in `C.UTF-8` and `C` asserts class `supplement_error_no_report`, both `analyses/Models.qmd` and `analyses/models.qmd` in the message, and `expect_length(calls(), 0L)`.
- AC3 evidence: `man/check_supplement.Rd:296-297` reads "The row's \code{file} shows each byte that is not valid UTF-8 in the folder's name as \verb{<xx>}." in the leftover-output item (from the roxygen at `R/check-supplement.R:266-267`). NEWS.md's first entry describes the leftover-output change. `git diff main...HEAD -- R/render-supplement.R` is empty, so no render entry is owed.
- AC4 evidence: `devtools::document()` left `git status` clean at review. Local `devtools::check()` on e077d4f (macOS, this session): 0 errors, 0 warnings, 0 notes, tests included. Run 40953514637 on e077d4f: ubuntu-latest and macos-latest passed on the first attempt; windows-latest failed one timing test (10.19 s against 10 s, M076 code) and passed on the rerun of the failed job, so all three are green. The package content of head 47e2db3 equals e077d4f's.
- Consistency gate: `cairn_validate.py` all checks passed; `document()` no diff; no README.Rmd; `pkgdown::check_pkgdown()` "No problems found"; NEWS entry present with no milestone number; no new top-level file; no principle changed, so no `cairn_impact` run.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: `show_text()` marks every name as UTF-8, so a valid native name in a non-UTF-8 session (R 4.1 on Windows, a Latin-1 locale on Linux) now shows as `caf<e9>` where it printed as `café` — follow-up, new row "Show Latin-1 names in rows as text" (the same convention other rows already use, chosen at the question set).
- diff-bug #2: if `C.UTF-8` is missing, `withr::with_locale()` only warns and the test runs in the session locale — fix now: each locale loop asserts `Sys.getlocale("LC_CTYPE")` equals the locale it set.
- diff-bug #3: the `C.UTF-8` half of the render test runs the same path as the existing case test — reject, planned change: AC2 names both locales.
- diff-bug #4: the `C` half of the leftover test runs the same code path as the `C.UTF-8` half, and no run showed it failing on main — reject, planned change: AC1 names both locales, and cli's printing, which the test reaches, depends on the locale.
- diff-bug #5: the NEWS claim that the check stopped was seen in `C.UTF-8` only — reject, false: the claim is not locale-bound, and LESSONS (M078) records that cli stops on the raw bytes in the C locale too; the new test passes in both.
- diff-bug #6: leftover rows follow `list.files()` order, not `sort_bytes()`, and the test sorts before comparing — follow-up, new row "Sort leftover rows in byte order" (pre-existing since M042).
- diff-bug #7: NEWS "each such byte" refers back to the name, not to its bad bytes — fix now: "each byte of the name that is not valid UTF-8".
- diff-bug #8: DESIGN.md's leftover-output paragraph does not say the row shows names through `show_text()` — reject, false: the paragraph describes matching and states nothing the diff changes.
- diff-bug #9: Scope cites `R/check-supplement.R:1532` where the function now starts at 1533, and the AC boxes were unticked — reject, false: 1532 is the line on main that the plan read, and the boxes are ticked against evidence above.
- blame-history #1: leftover rows in `list.files()` order — follow-up, same row as diff-bug #6.
- blame-history #2: the row shows `caf<e9>`, which the author cannot type to find the folder it says to delete — reject, planned change: the user chose `<xx>` in the `file` column at the question set, as the report-name row does.
- blame-history #3: the render test adds coverage with no code change — reject, planned change: AC2 names it.
- prior-review #1: leftover rows not passed through `sort_bytes()` — follow-up, same row as diff-bug #6.
- ripple #1: the row "Print leftover folders with odd bytes" describes the defect this branch fixes — reject, planned change: post-merge hygiene graduates it.
- ripple #2: the row "Render by name beside non-UTF-8 reports" says the stop is possible on Linux, which the branch's test contradicts — reject, planned change: post-merge hygiene graduates it, and the archive records that its premise did not hold.
