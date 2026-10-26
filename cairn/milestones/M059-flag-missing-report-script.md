<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M059: Flag a missing _scripts/report.R file

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — a new row of the exported `check_supplement()`, which `release_supplement()` stops on   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m059-flag-missing-report-script   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

`check_supplement()` gives a `"missing-script"` row when reports in `analyses/` name `_scripts/report.R` and the site has no such file, so `release_supplement()` stops before it archives reports that cannot be rendered again.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a `check_missing_script()` check in `R/check-supplement.R`, called from `check_supplement()` after `check_leftover_output()`; one row whose `file` is `_scripts/report.R` and whose `problem` names the reports and the restore steps; tests in `tests/testthat/test-check-supplement.R`; the `check_supplement()` help page, the check lists in `inst/template/GUIDE.md` and `README.md`, a NEWS.md entry, and the sentences in the `add_report()` help, GUIDE.md, and NEWS.md that say `check_supplement()` does not read the file; DESIGN.md's `R/check-supplement.R` paragraph.

**Out:**
- A change to `_scripts/report.R` after a report's last render → candidate row "Flag reports after report.R changes".
- A `_scripts/report.R` that git ignores, so a release commit leaves it out → DESIGN.md Known issues, "Release check edge cases" entry (T4). The template's `_gitignore` matches no such file.
- A report that names the file only in an included file, in a line of another form (such as `source("report.R")` from a working folder of `analyses/`), or that lives in a folder inside `analyses/` → no row; the help page states these limits (T3), not planned.
- Whether the file defines the functions that the reports call → not checked, not planned; GUIDE.md already says to keep both functions.
- On Windows a file link to a missing file reads as an existing file (LESSONS 2026-10-19, M018), and on a disk that ignores letter case `_scripts/Report.R` reads as the file, so neither gives a row there → the help page states both (T3).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: `check_supplement()` gives exactly one row with `check` equal to `"missing-script"` and `file` equal to `"_scripts/report.R"` when both hold: (a) `file.exists()` is FALSE for `_scripts/report.R` in the site, or `dir.exists()` is TRUE for it; and (b) at least one report that `analysis_reports()` lists (`.qmd` names directly in `analyses/` that do not start with `.`, folders left out) has a line that holds `_scripts`, then later on that line `report.R`, where neither has an ASCII letter, digit, `_`, or `.` right before it and `report.R` has none right after it; a line of prose counts. A test in `tests/testthat/test-check-supplement.R` runs a `create_supplement()` site, whose `analyses/example.qmd` sources the file, with the file deleted, with a folder in its place, and (skipped on Windows) with a symbolic link to a missing file in its place, and asserts the one row in each case. It also runs a site with the file deleted whose only report is a new one whose last line is `# _scripts/report.R`, and asserts the one row.
- [ ] AC2: The row's `problem` names each report that meets (b) by its path from the site folder, in byte order, each between double quotes with a `\` before each `\` and `"` in it, joined by `, `, as the `"stale-output"` row names files. It also holds the text `system.file("template", "_scripts", "report.R", package = "supplement")` as where to copy the file from, and says to commit `_scripts/report.R`. A test with the file deleted and the reports `B.qmd` and `a.qmd` that meet (b), beside the example, asserts that the `problem` holds the text `"analyses/B.qmd", "analyses/a.qmd", "analyses/example.qmd"` exactly, and that it holds the `system.file()` text. A second case, skipped on Windows, adds a report whose name holds `"` and asserts its escaped name in the text.
- [ ] AC3: `check_supplement()` gives no `"missing-script"` row in each of these cases, which a test in `tests/testthat/test-check-supplement.R` runs. First, an unchanged `create_supplement()` site, where the file is a regular file. Second, one site where the file is deleted, `analyses/example.qmd` is deleted, and the only reports are these: one that holds `source("report.R")`, one that holds `_scripts/report.Rmd`, one that holds `source("my_scripts/report.R")`, one that holds `file.path(site, "_scripts", "myreport.R")`, and a report in a folder inside `analyses/` that holds the template's `source()` line.
- [ ] AC4: The `check_supplement()` help page has a `"missing-script"` bullet that states the conditions of AC1 (a) and (b) and these limits: a line in an included file is not read, a line of another form does not count, reports in folders inside `analyses/` are not read, and on Windows a file link to a missing file and on a disk that ignores letter case a name such as `_scripts/Report.R` give no row. The check lists in `inst/template/GUIDE.md` and `README.md`, and NEWS.md, name the new row. The sentences in the `add_report()` help ("does not read `_scripts/report.R`"), in GUIDE.md's "Shared report code" section, and in the M058 NEWS.md bullet say that `check_supplement()` looks only at whether `_scripts/report.R` exists and gives no row for a change to it.
- [ ] AC5: `devtools::document()` leaves no diff, `devtools::test()` reports no failure, and `devtools::check()` reports 0 errors and 0 warnings.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T2
- AC4 → T3, T4
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive change is amend-via-gate. -->

- [x] T1: Write `check_missing_script()` in `R/check-supplement.R` near `check_leftover_output()`: test the file with `file.exists()` and `dir.exists()`, read each report from `analysis_reports()` with `read_report_lines()`, match with `perl = TRUE, useBytes = TRUE` and the boundaries of AC1 (b), name the reports with `quote_path()`, `show_text()`, and `sort_bytes()`, and build the row with `problem_rows()`. Call it from `check_supplement()` after `check_leftover_output()`.
- [x] T2: Tests first in `tests/testthat/test-check-supplement.R` for AC1 to AC3 (red before T1), using `new_site()` and `report_lines()`. Run the existing `check_supplement()` and `release_supplement()` tests and fix any that now see the new row.
- [x] T3: Add the `"missing-script"` bullet to the `check_supplement()` roxygen after `"leftover-output"`, with the AC1 conditions and the AC4 limits; run `devtools::document()`.
- [ ] T4: Update the check lists in GUIDE.md and README.md, GUIDE.md's "Shared report code" section, the `add_report()` help, and a new NEWS.md bullet; reword the M058 NEWS.md sentence per AC4; add the git-ignored case to the "Release check edge cases" entry in DESIGN.md Known issues and the new check to DESIGN.md's `R/check-supplement.R` paragraph. As a review aid, run `grep -rn "report\.R" R/ inst/template/ NEWS.md README.md vignettes/` and read each hit's sentence.
- [ ] T5: Run `devtools::document()`, `devtools::test()`, and `devtools::check()`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-26: created by /milestone-plan.
- 2026-10-26: tier check: not run — work named at the question set.
- 2026-10-26: idea vet: no concern. The row's premise holds for a render by name and for a reader who reruns a report; a full render from stored output still passes without the file, and the Goal is worded to that.
- 2026-10-26: question set: what to plan — "Flag a missing _scripts/report.R file"; run scope — go on to implement after the plan.
- 2026-10-26: lessons used: 2026-10-19 (M018, used M058) Windows file links, 2026-10-20 (M022) byte-order sort, 2026-10-20 (M026) readBin for nul bytes.
- 2026-10-26: collision check: absorbs candidate "Flag a missing _scripts/report.R file"; distinct from "Flag reports after report.R changes" and "Flag the old example as a placeholder" (cross-referenced in Scope Out); works under D-028, no conflict; inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-26: plan gate chose a row only when a report names the file over a row whenever the file is missing, because a site made before M058 lacks the file and its reports do not need it; falsified by a site whose reports load the file in a form (b) does not match.
- 2026-10-26: plan gate chose one row on `_scripts/report.R` that names the reports over one row per report, because the fix is one file; falsified by users who cannot tell which reports a row affects.
- 2026-10-26: check name `"missing-script"` chosen by the agent, in the noun-phrase form of `"no-stored-output"` and `"leftover-output"`.
- 2026-10-26: criteria audit (full mode, fresh Opus reader): 8 findings, all fixed. AC1 gained a left boundary on `_scripts` and `report.R`, the `analysis_reports()` definition, `file.exists()`/`dir.exists()` as the meaning of missing, prose lines counting, and an end-of-line probe; AC2 probes byte order (`B.qmd`, `a.qmd`) and `"` escaping; AC3 names one site with the example deleted and adds two left-boundary cases; AC4 names the help limits, adds README.md's check list, and names the three stale sentences in place of a per-line grep, which became a T4 review aid. Proportionality: no finding.
- 2026-10-26: implement started on branch m059-flag-missing-report-script, cut from main at 733bbf6.
- 2026-10-26: T2 tests written first: 5 tests in test-check-supplement.R, 7 expectations red before T1. T1 `check_missing_script()` returns an empty `problem_rows()` when the file is there or no report names it; the row text says to copy from `system.file()`, or restore your own copy, then commit, and to move a folder of that name first (agent's wording). `devtools::test()`: 0 failed, 0 errors, 10 skipped, 403 tests; no existing test saw the new row.
- 2026-10-26: T3 `"missing-script"` bullet added to the `check_supplement()` roxygen after `"leftover-output"`, with the AC1 conditions and the AC4 limits; `devtools::document()` rewrote `man/check_supplement.Rd` only.

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive. -->
