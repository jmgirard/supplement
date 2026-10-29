# M078: Read report names that are not UTF-8

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — `check_supplement()` gives a row where it now stops with an error
- **Branch/PR:** m078-non-utf8-report-names

## Goal

`check_supplement()` tells the author to rename a report in `analyses/` whose name is not valid UTF-8, where it now stops with an error.

## Scope

**In:** In `R/check-supplement.R`, a report that `analysis_reports()` lists and whose file name fails `validUTF8()` gets one row of a new kind, `"report-name"`, whose `file` is `analyses/` and the name passed through `show_text()`, so each such byte shows as `<xx>`. The four checks that cut the report's name with `sub()`, `check_stored_output()`, `check_stale_output()`, `check_stale_script()`, and `check_renv_lock()` (lines 908, 930, 986, 1100), leave such a report out. `check_missing_script()` already shows such a name through `show_text()` and stays as it is, and so do `analysis_reports()` and `add_report()`. The row's text is AC3's. Tests in `tests/testthat/test-check-supplement.R`. The help page of `check_supplement()`, NEWS.md, and DESIGN.md's check paragraph describe the row.

**Out:**
- `render_supplement()` beside such a report: its message for a name with no report runs `tolower()` on the listed names (`R/render-supplement.R:113`), which stops on such a name. Not checked here; the new candidate row "Render by name beside non-UTF-8 reports" holds it.
- macOS and Windows: their file systems refuse such a name (LESSONS, M066), so the new row and its tests reach only Linux. No row follows.
- Reports in subfolders of `analyses/`: `analysis_reports()` reads only the top folder, as now. No row follows.

## Acceptance criteria

- [ ] AC1: On a Linux file system in a UTF-8 locale, `check_supplement(site, renv_lock = TRUE)` returns without an error or a warning for a new site whose `analyses/` holds, beside the template's report and `_scripts/report.R`, three reports with an R code chunk: one named `caf`, byte 0xE9, `.qmd`; one named byte 0xFF, `x`, byte 0xC3, `.qmd`; and `café.qmd` in UTF-8. Each has stored output in `_freeze/analyses/<name>/execute-results/html.json` whose hash differs from the report, and the site has a `renv.lock` that holds a `Packages` object. On main the same call stops with the `sub()` error "input string 1 is invalid".
- [ ] AC2: For the AC1 site, the rows whose `file` is `analyses/caf<e9>.qmd` or `analyses/<ff>x<c3>.qmd` are one row each, of kind `"report-name"`; `café.qmd` gets a `"stale-output"` row and no `"report-name"` row.
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

- [ ] T1: Observe Quarto 1.10.19 on Linux: on the branch, a probe test that renders a new site whose `analyses/` holds a report named `caf`, 0xE9, `.qmd` with `run_in()`, and prints Quarto's exit status and output. Push the branch (ask first: the question set did not cover a push before review), read ubuntu-latest's `tests/testthat.Rout`, write one work-log line with the outcome, then delete the probe.
- [ ] T2: Write the AC1 and AC2 test near "a name that is not valid UTF-8 matches with ASCII letter case ignored" (`tests/testthat/test-check-supplement.R:739`). Make the bad names with `file.create()`; skip on macOS and Windows, and on Linux fail rather than skip when a file cannot be made. Assert rows by `file`, since the template's report adds its own rows. Commit the test alone and push, so ubuntu-latest runs it on the current code: red on the error from `sub()`. Record the run in the work log.
- [ ] T3: Add the `"report-name"` check and leave such a report out of the four checks, as Scope In says, with the row text that AC3 picks from T1's outcome. Push; read ubuntu-latest's `tests/testthat.Rout` to see the AC1 and AC2 test pass, not skip.
- [ ] T4: Update the roxygen block of `check_supplement()`, NEWS.md, and DESIGN.md (the check paragraph near line 236); run `devtools::document()`.
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

## Decisions

## Review
