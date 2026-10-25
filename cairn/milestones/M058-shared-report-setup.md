# M058: Share report setup code through one site file

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — it changes the reports that `add_report()` writes and the template's example report
- **Branch/PR:** m058-shared-report-setup

## Goal

Reports that `add_report()` writes, and the template's example report, get `save_png()` and the Computing environment output from one shared site file, `_scripts/report.R`.

## Scope

**In:** A new template file `inst/template/_scripts/report.R` that defines `save_png()` and `print_environment()`. The `figures` link and file stops move into `save_png()`. The example's `site` chunk ends with a `source()` of that file. Its `save-figure` and `session-info` chunks only call the two functions. `add_report()` writes reports from the new chunks. It copies `_scripts/report.R` into a site that lacks it and never overwrites one. The help of `add_report()`, `inst/template/GUIDE.md`, `NEWS.md`, and `cairn/DESIGN.md` describe the file.

**Out:**
- Package functions for this code. The plan chose a site file, so a site renders without supplement (D-028).
- A `check_supplement()` row for a report rendered before `_scripts/report.R` changed. It goes to the candidate row "Flag reports after report.R changes".
- Changes to reports that already exist in a site. They keep their inline code and still render.

## Acceptance criteria

- [x] AC1: Run `add_report("models", "Model Comparison", "Fits and compares the models.")` in a site from `create_supplement()`. The written `analyses/models.qmd` has at most 40 lines, counted with `length(readLines())`. On main at 1d2f8ca it has 62. The code of its `session-info` chunk is the one line `print_environment()`. No line of the file matches `<- function(`.
- [x] AC2: The template ships `_scripts/report.R`, which defines `save_png()` and `print_environment()`. The `site` chunk of `analyses/example.qmd` ends with `source(file.path(site, "_scripts", "report.R"), local = TRUE)`, and so does the `site` chunk of the report that AC1's `add_report()` call writes. In the example, no line of the `save-figure` chunk's code matches `<- function(` or holds `Sys.readlink(`. The code of the `session-info` chunk is the one line `print_environment()`.
- [x] AC3: `save_png()` from `_scripts/report.R` stops when `figures` is a link or a file. It refuses a folder at its target and a `draw` that is not a function. It leaves its target as it was when the PNG file lacks its end chunk. `print_environment()` passes the four home-folder tests of `test-template.R` at 1d2f8ca (lines 913 to 967), run against `_scripts/report.R`.
- [x] AC4: A first full render of a site from `create_supplement()`, and of one from `quarto use template`, publishes `docs/figures/bootstrap-means.png`. The example page's Computing environment section shows the R version line. `docs/` holds no `_scripts/report.R`. After `add_report("models", ...)`, a render of `analyses/models.qmd` by name succeeds, and its page shows the R version line.
- [x] AC5: In a site with no `_scripts/report.R`, `add_report()` copies the installed template's file there before it writes the report. When `_scripts` is missing, it makes the folder. An existing `_scripts/report.R` stays byte-identical. When `_scripts` is a file or a link, or `_scripts/report.R` is a link or a folder, it stops with `supplement_error_file_exists` and writes nothing. When the write of `_quarto.yml` fails, it removes the copied `report.R` and any `_scripts` folder it made. A test covers each case.
- [ ] AC6: `inst/template/GUIDE.md` says five things. Reports source `_scripts/report.R`. `check_supplement()` compares each report's own text with its stored output, so a change to that file gives no stale-output row. To take the change, render each report by name. An older report adds the `source()` line to use the file. A report that calls a function which the site's `_scripts/report.R` lacks, and does not define itself, fails to render. The help of `add_report()` and `NEWS.md` each say the first three of these. A `grep -F` of GUIDE.md for "copy the whole `save-figure` chunk", "copy the lines from the", "the chunk stops", and "The chunk sets `figures`" returns no match.

## Coverage

- AC1 → T3
- AC2 → T1, T2
- AC3 → T1
- AC4 → T2, T3
- AC5 → T3
- AC6 → T4

## Tasks

- [x] T1: Write `inst/template/_scripts/report.R` with `save_png()` and `print_environment()`, from the code of the example's `save-figure` (lines 59 to 100) and `session-info` (lines 111 to 138) chunks. Point the `save_png()` and home-folder tests of `test-template.R` (lines 364 to 471 and 877 to 967) at the new file.
- [x] T2: Rewrite the example's `site`, `save-figure`, and `session-info` chunks. Update the render tests and the `quarto use template` file list in `test-template.R`.
- [x] T3: In `R/add-report.R`, write reports from the new chunks. Copy `_scripts/report.R` when it is missing, and refuse the link, file, and folder cases. Add the copy to the cleanup after a failed write. Update the roxygen and the tests in `test-add-report.R`, with one render by name.
- [x] T4: Update `inst/template/GUIDE.md`, `NEWS.md`, and the architecture text of `cairn/DESIGN.md`. Read `report_hash()` and the stale-output check in `R/check-supplement.R` before you write the stale-output sentence.

## Work log

- 2026-10-25: created by /milestone-plan.
- 2026-10-25: tier check: milestone — it changes what `add_report()` writes and needs a design choice.
- 2026-10-25: idea vet: (1) package functions would make each render need supplement, which is not on CRAN; answer: shared site file. (2) a change to the shared file shows no stale output; answer: document it, check goes to a candidate row. (3) sites made earlier lack the file; answer: `add_report()` copies it in.
- 2026-10-25: collision check: absorbs the candidate row "Shorten the setup code in new reports". M046 chose base R link checks because a site renders without supplement; this plan keeps that and records it as D-028. M030 and M034 made the copied section and `site` chunk, which this plan reshapes.
- 2026-10-25: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-25: lessons used: 2026-10-21 (M027), 2026-10-21 (M028), 2026-10-19 (M018).
- 2026-10-25: plan gate chose a shared site file over package functions because a render then needs no supplement install; falsified by a site whose render needs supplement for another reason.
- 2026-10-25: plan gate chose a shared site file over shortening the code in place because it removes the code from each report; falsified by authors editing `_scripts/report.R` and losing track of which reports used the old code.
- 2026-10-25: plan gate chose copying `_scripts/report.R` into older sites over stopping with a message; falsified by a site that holds its own unrelated `_scripts/report.R`.
- 2026-10-25: criteria audit (full mode, fresh Opus reader): 7 findings on AC1 to AC6, all fixed. AC1 and AC2 now ban `<- function(` instead of `function(`, because the `site` chunk and the `save_png()` call pass functions. AC3 names the four home-folder tests, not each spelling. AC4 adds a render of an `add_report()` report. AC5 adds a missing `_scripts` and the rollback. AC6 names the GUIDE.md sections and two more phrases, and states the stale gap through what `check_supplement()` compares.
- 2026-10-25: changelog: one NEWS.md entry for the new report shape.
- 2026-10-25: implement started on branch m058-shared-report-setup, cut from main at 1659b8a.
- 2026-10-25: substantive amendment: AC2's `source()` line gains `local = TRUE`, so the shared functions see `site` in the environment the chunk runs in (a render runs chunks in the global environment, so a render is unchanged). AC2 also narrows "each report that `add_report()` writes" to the report of AC1's call.
- 2026-10-25: re-audit: AC2 (full) — no blocking finding; suggested narrowing "each report" to AC1's call, taken.
- 2026-10-25: re-audit: AC2 (full) — "the code of the chunk" can read as counting `#|` lines (AC1 too); answered, not reworded: review reads "code" as the lines other than `#|` chunk options. "Defines" needs no check of its own, since AC3's tests call both functions.
- 2026-10-25: `save_png()` takes the link and file stops for its `dir`, named by `basename(dir)`, so the messages for the default `figures` are main's; the inside check uses the parent's normalized path plus the name (LESSONS 2026-10-19 M018).

- 2026-10-25: T1, T2 done: `_scripts/report.R` holds both functions, the example calls them, and `test-template.R` runs them from the file (new test: a `quarto use template` site renders the example with it). GUIDE.md's guide-code block and its "Shared report code", "Computing environment", and "Paper figures" text moved here from T4, because a T2 test reads that block. `_gitignore`'s comment names the new file. Full suite: 392 results, 0 failed, 10 skipped.
- 2026-10-25: T3 done: `add_report()` refuses a `_scripts` that is a file or link and a `report.R` that is a link or folder (own messages, `supplement_error_file_exists`), copies the template's file when it is missing, and tells the user when it copied. A new report has 40 lines; the example's Computing environment paragraph was rewrapped to keep it there. The rollback test went red with each cleanup line removed. Full suite: 398 results, 0 failed, 10 skipped.
- 2026-10-25: T4 done: NEWS.md entry, DESIGN.md (add-report paragraph, a `_scripts/report.R` entry, the example's figure and environment text). The stale-output sentences were written after reading `check_stale_output()` and `report_hash()` in `R/check-supplement.R`, which hash the report file alone. The four AC6 phrases return no match in GUIDE.md (`grep -cF`, 0 each).
- 2026-10-25: claim audit: 55 claims read, 4 corrected — inst/template/GUIDE.md (the `save_png()` example line, which reports call which function, the copy step for older reports), NEWS.md (the render-without-supplement sentence was true before this change). The reader also found that an unedited old example no longer gives a placeholder row; recorded as the candidate row "Flag the old example as a placeholder".
- 2026-10-25: implement done, status review. Template tests after the claim fixes: 48 results, 0 failed.
- 2026-10-26: amendment routed: AC6 — the criterion names the help, NEWS.md, and two GUIDE.md sections as each saying five things, but the stale-output and missing-function text lives in GUIDE.md's new "Shared report code" section, and the help and NEWS.md give only the source, stale-output, and render-by-name points.
- 2026-10-26: re-audit: AC6 (full) — NEWS.md lacked the "compares each report's own text … no stale-output row" point, fixed in NEWS.md; the missing-function point claimed too much for a report that defines its own `save_png()`, narrowed.
- 2026-10-26: re-audit: AC6 (full) — satisfiable on disk; minor: GUIDE.md's "a report that calls a missing function" has no "does not define itself" clause; answered, not reworded: a report that defines the function does not call a missing one.
- 2026-10-26: amendment return: AC6 — "`inst/template/GUIDE.md` says five things. … A report that calls a function which the site's `_scripts/report.R` lacks, and does not define itself, fails to render. The help of `add_report()` and `NEWS.md` each say the first three of these."
- 2026-10-26: implement done after the AC6 amendment, status review.

## Decisions

## Review

Pass 1, 2026-10-25, branch head 1f303ed, level with main at 1659b8a. Full suite `devtools::test()`: 398 results, 0 failed, 0 errors, 10 skipped (none of the tests cited below). "Code" of a chunk is read as its lines other than `#|` options, as the plan's re-audit line states.

- AC1: `add_report("models", "Model Comparison", "Fits and compares the models.")` in a `create_supplement()` site wrote 40 lines; its `session-info` code is `"print_environment()"`; 0 lines match `<- function(` (scratchpad check script, same session). Test "a report stub reads the shared functions and defines none": 4 expectations, 0 failed.
- AC2: sourcing the template's `_scripts/report.R` into an environment holding `site` defines the functions `print_environment` and `save_png`. The last code line of the example's `site` chunk and of the AC1 report's is `source(file.path(site, "_scripts", "report.R"), local = TRUE)`. The example's `save-figure` code has 0 lines matching `<- function(` and 0 holding `Sys.readlink(`; its `session-info` code is `"print_environment()"`.
- AC3: tests in `test-template.R`, all 0 failed, not skipped: "a figures link to a folder outside the site stops the example report" (3), "a figures link to a missing path …" (2), "a figures link to a file …" (3), "a file named figures stops the example report with a message" (2), "save_png() refuses a folder at its target and a plot that is not a function" (4), "save_png() keeps its target as it was when the PNG file lacks its end chunk" (24). The four home-folder tests, now sourcing the template's `_scripts/report.R` before `print_environment()`: "shows the home folder as ~" (3), "leaves a folder that only starts like the home folder" (3), "shows a linked home folder as ~ by its real path" (4), "the sessionInfo() output shows the home folder as ~" (4).
- AC4: "the first full render of a new site publishes the example figure" (4 expectations, includes no `docs/_scripts/report.R`), "a site from quarto use template renders the example with the shared report file" (3: the figure, no `docs/_scripts/report.R`, the R version line), "a report from add_report() renders by name with the shared report file" (2: render status, R version line). All 0 failed.
- AC5: `test-add-report.R`: "a site with no _scripts/report.R gets the template's copy" (4, both forms), "an existing _scripts/report.R is kept as it is" (2), "a _scripts folder or report.R that is not a plain folder and file stops and writes nothing" (9: all four cases ran on macOS, each with its message and `supplement_error_file_exists`, and the outside folder unchanged), "a failed edit of _quarto.yml removes the copied report.R and the _scripts folder it made" (4). All 0 failed. The rollback test went red with each cleanup line removed (implement work log).
- AC6: FAILS as written. The `grep -F` part passes: 0 matches for each of the four phrases. The five-things part does not: the help of `add_report()` does not give the line an older report adds, NEWS.md gives neither that line nor the missing-`print_environment()` failure, and in GUIDE.md the stale-output and missing-function text sits in the new "Shared report code" section, not in "Computing environment" or "Paper figures".
- Gate: `cairn_validate` all checks passed; `devtools::document()` no diff; no README.Rmd; `pkgdown::check_pkgdown()` no problems; NEWS.md has the entry; no new top-level file. `devtools::check()`: 0 errors, 0 warnings, 1 NOTE (hidden `.claude`, the local Claude folder, not part of the package; same NOTE as M057).
- AC6 routed as an amendment return: the docs say the five things, but the criterion's hand-listed sites do not match where the work put them. Reviewers not yet spawned this pass, so the full review runs once on the amended criterion.
