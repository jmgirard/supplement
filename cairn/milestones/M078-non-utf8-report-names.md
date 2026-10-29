# M078: Read report names that are not UTF-8

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — `check_supplement()` gives a row for a report it now skips with no row
- **Branch/PR:** m078-non-utf8-report-names

## Goal

`check_supplement()` tells the author to rename a report in `analyses/` whose name is not valid UTF-8, where it now stops with an error.

## Scope

**In:** In `R/check-supplement.R`, a new `check_report_names()` lists `analyses/` with no pattern and gives each `.qmd` file directly there whose name fails `validUTF8()` one row of a new kind, `"report-name"`, whose `file` is `analyses/` and the name passed through `show_text()`, so each such byte shows as `<xx>`. On main such a report gets no row: in a UTF-8 locale R 4.6.1's `list.files(pattern =)` in `analysis_reports()` never lists it. The four checks that cut a report's name with `sub()`, `check_stored_output()`, `check_stale_output()`, `check_stale_script()`, and `check_renv_lock()`, read a new `utf8_reports()` that leaves such a report out whatever `list.files()` lists. `check_missing_script()` already shows such a name through `show_text()` and stays as it is, and so do `analysis_reports()` and `add_report()`. The row's text is AC3's. Tests in `tests/testthat/test-check-supplement.R`. The help page of `check_supplement()`, NEWS.md, and DESIGN.md's check paragraph describe the row.

**Out:**
- `render_supplement()` beside such a report: its message for a name with no report runs `tolower()` on the listed names (`R/render-supplement.R:113`), which stops on such a name. Not checked here; the new candidate row "Render by name beside non-UTF-8 reports" holds it.
- macOS and Windows: their file systems refuse such a name (LESSONS, M066), so the new row and its tests reach only Linux. No row follows.
- Reports in subfolders of `analyses/`: `analysis_reports()` reads only the top folder, as now. No row follows.

## Acceptance criteria

- [ ] AC1: On a Linux file system, `check_supplement(site, renv_lock = TRUE)` returns without an error or a warning for a new site whose `analyses/` holds, beside the template's report and `_scripts/report.R`, three reports with an R code chunk: one named `caf`, byte 0xE9, `.qmd`; one named byte 0xFF, `x`, byte 0xC3, `.qmd`; and `café.qmd` in UTF-8. Each has stored output in `_freeze/analyses/<name>/execute-results/html.json` whose hash differs from the report, and the site has a `renv.lock` that holds a `Packages` object.
- [ ] AC2: For the AC1 call, the rows whose `file` is `analyses/caf<e9>.qmd` or `analyses/<ff>x<c3>.qmd` are one row each, of kind `"report-name"`; `café.qmd` gets a `"stale-output"` row and no `"report-name"` row.
- [ ] AC3: The `"report-name"` row's text says that the report's name is not valid UTF-8 and tells the author to rename the report with a valid UTF-8 name, change its item in `_quarto.yml`, delete its folder in `_freeze/analyses/` if there is one, render the whole site, and commit the old and new paths with `_quarto.yml`, `_freeze/`, `docs/`, and `figures/`. It also gives the outcome of a Quarto 1.10.19 render on Linux of a site that holds such a report: when the render stops with an error that the file name is not valid UTF-8, the text says that a render of the site stops on such a name; when the render ends with no page for the report in `docs/`, the text says that Quarto leaves the report out of the site. A render that publishes the report falsifies this plan and is the goal-wrong stop.
- [ ] AC4: The help page of `check_supplement()` lists the `"report-name"` row and states that only a file system that holds such a name, such as one on Linux, can give it; NEWS.md and DESIGN.md's paragraph on the checks of `R/check-supplement.R` describe the change.
- [ ] AC5: The `verify` slot is clean: `devtools::document()` leaves no diff, `devtools::test()` has 0 failures, and R CMD check of the branch head gives 0 errors and 0 warnings on Windows, macOS, and Linux.

## Coverage

- AC1 → T2, T3
- AC2 → T2, T3
- AC3 → T1, T3
- AC4 → T4
- AC5 → T5

## Tasks

- [x] T1: Observe Quarto 1.10.19 on Linux: on the branch, a probe test that renders a new site whose `analyses/` holds a report named `caf`, 0xE9, `.qmd` with `run_in()`, and prints Quarto's exit status and output. Push the branch (ask first: the question set did not cover a push before review), read ubuntu-latest's `tests/testthat.Rout`, write one work-log line with the outcome, then delete the probe.
- [x] T2: Write the AC1 and AC2 test near "a name that is not valid UTF-8 matches with ASCII letter case ignored" (`tests/testthat/test-check-supplement.R:739`). Make the bad names with `file.create()`; skip on macOS and Windows, and on Linux fail rather than skip when a file cannot be made. Assert rows by `file`, since the template's report adds its own rows. Commit the test alone and push, so ubuntu-latest runs it on the current code: red on the error from `sub()`. Record the run in the work log.
- [ ] T3: Add the `"report-name"` check and leave such a report out of the four checks, as Scope In says, with the row text that AC3 picks from T1's outcome. Push; read ubuntu-latest's `tests/testthat.Rout` to see the AC1 and AC2 test pass, not skip.
- [x] T4: Update the roxygen block of `check_supplement()`, NEWS.md, and DESIGN.md (the check paragraph near line 236); run `devtools::document()`.
- [ ] T5: Run the `verify` slot: `devtools::document()`, `devtools::test()`, `devtools::check()`; wait for the R-CMD-check workflow on the branch head, the evidence for Windows and Linux.

## Work log

- 2026-10-29: created by /milestone-plan.
- 2026-10-29: tier check: not run — work named at the question set.
- 2026-10-29: question set: what to work on — "Read report names that are not UTF-8"; go on to implement and review after the plan — yes. A branch push before review was not asked, so T1 asks before its push.
- 2026-10-29: idea vet: gap — run as is, the per-report checks would tell the author to render a report whose name Quarto's Deno may refuse ("File name or path ... is not valid UTF-8" is in Quarto 1.10.19's bundled `deno`), so the advice could not work; reading taken: a `"report-name"` row that says to rename the report, and the report left out of the per-report checks. The other two vet questions found no concern.
- 2026-10-29: lessons used: 2026-10-27 (M066), 2026-10-29 (M077).
- 2026-10-29: collision check: absorbs the candidate row "Read report names that are not UTF-8" in full; extends done M042, whose leftover-output check already cuts names with `useBytes = TRUE`; no D-entry covers name encoding. New [low] row "Render by name beside non-UTF-8 reports" for the `tolower()` stop found in `render_supplement()`. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-29: plan gate chose a rename row with the report left out of the per-report checks over byte-safe name handling that runs those checks as for any report, because their render steps may fail in Quarto for such a name; falsified by a Linux run where Quarto 1.10.19 renders such a site and publishes the report.
- 2026-10-29: criteria audit (full mode, Opus reader): 10 findings, 9 taken, 1 needed no change. AC1 states behavior on Linux in a UTF-8 locale, names a parseable `renv.lock` and `_scripts/report.R` so all four `sub()` sites run, and adds a second bad name (0xFF first, a cut 0xC3 before `.qmd`); AC2 asserts by file; `check_missing_script()` is no longer left out, since it has no `sub()` and shows such names now; AC3 names both Quarto outcomes now, not a later work-log line, and adds the `_freeze/` folder delete and `figures/`; AC5 states R CMD check results, CI as evidence; the unchecked claim that the row stops `release_supplement()` left Scope. Fixture reachability (stale-output row, no leftover-output row, no warning) confirmed with no change. No IP or D-entry conflict.

- 2026-10-29: implement started on branch m078-non-utf8-report-names, cut from main at 39fd866.
- 2026-10-29: T1 probe (`tests/testthat/test-probe-m078.R`, fails on purpose to print Quarto's status, output, and `docs/analyses/`) and the T2 test (`test-check-supplement.R:754`) written; both skip on macOS. Committed together so one push runs both on ubuntu-latest.
- 2026-10-29: question set (implement stop): push the branch before review, after each task, so ubuntu-latest runs the probe and the test — yes.
- 2026-10-29: T1 done: ubuntu-latest, run 40934133441 at 2ef4599: `quarto render` of a new site with `analyses/caf<e9>.qmd` exited 0, its listing step read 2 files (`analyses/example.qmd`, `index.qmd`), and `docs/analyses/` held only `example.html` and `example_files`, so Quarto leaves such a report out of the site with no error. AC3 takes its second outcome. Probe deleted.
- 2026-10-29: T2 first run errored on `write_lock` not found (defined later in the file), not on `sub()`; the test now writes `renv.lock` itself.
- 2026-10-29: T3 and T4 drafted (local commit, not pushed while run 40935940661 judges the test-only head 7def08d): `utf8_reports()` and `check_report_names()` in `R/check-supplement.R`, the four checks read `utf8_reports()`, the row runs before `"no-stored-output"`; help item, NEWS, DESIGN; the test also asserts the row text. Implementation choice: filter in a new helper, so `analysis_reports()` and `add_report()` keep their behavior.
- 2026-10-29: T2 red on main, run 40935940661 at 7def08d (ubuntu-latest, R 4.6.1): no error and no warning; the two failures are the row assertions at `test-check-supplement.R:767`, with no row at all for `analyses/caf<e9>.qmd` or `analyses/<ff>x<c3>.qmd`. The plan's premise is false: R 4.6.1's `list.files(pattern =)` matches with `tre_regexec()` (`src/main/platform.c:1538`, `1557`), which in a UTF-8 locale never matches such a name, so `analysis_reports()` never lists it and main skips the report with no row. The Goal's clause "where it now stops with an error" and AC1's last sentence are wrong; the deliverable (a rename row) stands.
- 2026-10-29: T3 reworked for that cause: `check_report_names()` lists `analyses/` with no pattern and matches `.qmd` and a leading `.` with `useBytes = TRUE`; `utf8_reports()` removed and the four checks read `analysis_reports()` as on main, since in a UTF-8 locale they never see such a name. Help item, DESIGN.md, and NEWS.md now state the skipped-report cause, not a stop. Amended AC1 is with a fresh reader before it is written.
- 2026-10-29: re-audit: AC1 (full) — 2 findings: the "on main" sentence records T2's red run, not the deliverable, so it moves to the work log; the locale axis is not held by the code, so a locale that is not UTF-8 goes Out (new [low] row "Check odd report names in a C locale") and the test skips there except under CI, where it fails.
- 2026-10-29: re-audit: AC2 (full) — 1 finding: "For the AC1 site" becomes "For the AC1 call", so the locale applies. Also noted: Goal, Surface tier, and Scope In still describe a stop; Scope In and Surface tier are amended with AC1, and the Goal stays as created (its deliverable, the rename row, holds; its clause "where it now stops with an error" is false, as recorded above).
- 2026-10-29: re-audit: AC1 (full) — 2 findings on the fixed wording: AC1 and AC2 hold only because R 4.6.1's `list.files(pattern =)` skips such names, and CI runs one R version against the R 4.1.0 floor (D-031), so on another R the `sub()` stop or extra rows could come back; restoring the `validUTF8()` filter in the four checks makes both hold whatever `list.files()` lists. Main also passes AC1, so only AC2 tells them apart.
- 2026-10-29: re-audit: AC2 (full) — the same R-version finding as AC1. Second re-audit line for AC1 and AC2: further churn on them goes to the user.
- 2026-10-29: question set (implement stop, criteria churn): keep a bad-named report from the other report checks by a name filter, by limits named in AC1, or stop — name filter.
- 2026-10-29: substantive amendment: AC1 drops "in a UTF-8 locale" and its last sentence about main (the red evidence stays in the T2 lines above); AC2 reads "For the AC1 call"; Scope In names `check_report_names()` listing `analyses/` with no pattern and `utf8_reports()` in the four checks; Surface tier says main skips such a report. The deliverable the user sees is unchanged. Code: `utf8_reports()` restored, the test's locale skip removed, help and DESIGN.md say the four checks leave such a report out, and the C-locale candidate row added earlier this session deleted, since the filter covers that case.

## Decisions

## Review
