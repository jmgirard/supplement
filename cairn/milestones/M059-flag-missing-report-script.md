<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M059: Flag a missing _scripts/report.R file

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
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

- [x] AC1: `check_supplement()` gives exactly one row with `check` equal to `"missing-script"` and `file` equal to `"_scripts/report.R"` when both hold: (a) `file.exists()` is FALSE for `_scripts/report.R` in the site, or `dir.exists()` is TRUE for it; and (b) at least one report that `analysis_reports()` lists (`.qmd` names directly in `analyses/` that do not start with `.`, folders left out) has a line that holds `_scripts`, then later on that line `report.R`, where neither has an ASCII letter, digit, `_`, or `.` right before it and `report.R` has none right after it; a line of prose counts. A test in `tests/testthat/test-check-supplement.R` runs a `create_supplement()` site, whose `analyses/example.qmd` sources the file, with the file deleted, with a folder in its place, and (skipped on Windows) with a symbolic link to a missing file in its place, and asserts the one row in each case. It also runs a site with the file deleted whose only report is a new one whose last line is `# _scripts/report.R`, and asserts the one row.
- [x] AC2: The row's `problem` names each report that meets (b) by its path from the site folder, in byte order, each between double quotes with a `\` before each `\` and `"` in it, joined by `, `, as the `"stale-output"` row names files. It also holds the text `system.file("template", "_scripts", "report.R", package = "supplement")` as where to copy the file from, and says to commit `_scripts/report.R`. A test with the file deleted and the reports `B.qmd` and `a.qmd` that meet (b), beside the example, asserts that the `problem` holds the text `"analyses/B.qmd", "analyses/a.qmd", "analyses/example.qmd"` exactly, and that it holds the `system.file()` text. A second case, skipped on Windows, adds a report whose name holds `"` and asserts its escaped name in the text.
- [x] AC3: `check_supplement()` gives no `"missing-script"` row in each of these cases, which a test in `tests/testthat/test-check-supplement.R` runs. First, an unchanged `create_supplement()` site, where the file is a regular file. Second, one site where the file is deleted, `analyses/example.qmd` is deleted, and the only reports are these: one that holds `source("report.R")`, one that holds `_scripts/report.Rmd`, one that holds `source("my_scripts/report.R")`, one that holds `file.path(site, "_scripts", "myreport.R")`, and a report in a folder inside `analyses/` that holds the template's `source()` line.
- [x] AC4: The `check_supplement()` help page has a `"missing-script"` bullet that states the conditions of AC1 (a) and (b) and these limits: a line in an included file is not read, a line of another form does not count, reports in folders inside `analyses/` are not read, and on Windows a file link to a missing file and on a disk that ignores letter case a name such as `_scripts/Report.R` give no row. The check lists in `inst/template/GUIDE.md` and `README.md`, and NEWS.md, name the new row. The sentences in the `add_report()` help ("does not read `_scripts/report.R`"), in GUIDE.md's "Shared report code" section, and in the M058 NEWS.md bullet say that `check_supplement()` looks only at whether `_scripts/report.R` exists and gives no row for a change to it.
- [x] AC5: `devtools::document()` leaves no diff, `devtools::test()` reports no failure, and `devtools::check()` reports 0 errors and 0 warnings.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2, T6
- AC2 → T1, T2
- AC3 → T2
- AC4 → T3, T4
- AC5 → T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive change is amend-via-gate. -->

- [x] T1: Write `check_missing_script()` in `R/check-supplement.R` near `check_leftover_output()`: test the file with `file.exists()` and `dir.exists()`, read each report from `analysis_reports()` with `read_report_lines()`, match with `perl = TRUE, useBytes = TRUE` and the boundaries of AC1 (b), name the reports with `quote_path()`, `show_text()`, and `sort_bytes()`, and build the row with `problem_rows()`. Call it from `check_supplement()` after `check_leftover_output()`.
- [x] T2: Tests first in `tests/testthat/test-check-supplement.R` for AC1 to AC3 (red before T1), using `new_site()` and `report_lines()`. Run the existing `check_supplement()` and `release_supplement()` tests and fix any that now see the new row.
- [x] T3: Add the `"missing-script"` bullet to the `check_supplement()` roxygen after `"leftover-output"`, with the AC1 conditions and the AC4 limits; run `devtools::document()`.
- [x] T4: Update the check lists in GUIDE.md and README.md, GUIDE.md's "Shared report code" section, the `add_report()` help, and a new NEWS.md bullet; reword the M058 NEWS.md sentence per AC4; add the git-ignored case to the "Release check edge cases" entry in DESIGN.md Known issues and the new check to DESIGN.md's `R/check-supplement.R` paragraph. As a review aid, run `grep -rn "report\.R" R/ inst/template/ NEWS.md README.md vignettes/` and read each hit's sentence.
- [x] T5: Run `devtools::document()`, `devtools::test()`, and `devtools::check()`.
- [x] T6: Review return 1: replace `script_line` with `names_script()`, which finds `_scripts` and `report.R` with separate searches and compares the first `_scripts` with the last `report.R`, so a line of a few MB stays under PCRE's match limit; regression test with a 5 MB line, red first.

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
- 2026-10-26: T4 the `add_report()` help, GUIDE.md "Shared report code", and the M058 NEWS.md bullet now say that `check_supplement()` looks only at whether `_scripts/report.R` exists; GUIDE.md and README.md check lists and a new NEWS.md bullet name the row; DESIGN.md gained the architecture lines and the git-ignored case. The review-aid grep's 50 hits hold no other sentence about `check_supplement()` and the file.
- 2026-10-26: claim audit fixes: the `script_line` comment now states the boundaries as the help page does; the `add_report()` help and GUIDE.md say the row comes only when a report names the file; the row text says "which these reports name, so a render of them can fail" (prose lines count, so "read" and "cannot render" overstated), and NEWS.md says "whose render can fail".
- 2026-10-26: claim audit: 31 claims read, 3 corrected — R/check-supplement.R, R/add-report.R, man/add_report.Rd, inst/template/GUIDE.md, NEWS.md; the re-read found all three true, and "a letter" in the `script_line` comment became "an ASCII letter".
- 2026-10-26: T5 a first run, started before the row-text fix and edited under, gave 4 failures that it did not name; the rerun on 88ffee6 gave `devtools::test()` 0 failed, 0 errors, 10 skipped, 403 tests, and `devtools::check()` 0 errors, 0 warnings, 1 note (hidden `.claude`, local only, as in M058); `devtools::document()` left no diff. Status → review.
- 2026-10-26: review return 1: a report line that names `_scripts` and runs past about 3 to 5 MB makes `grepl(script_line, …)` hit PCRE's match limit, so it warns and the report gets no `"missing-script"` row, which fails AC1 (diff-bug #1, prior-review #1). Fix: match `_scripts` and `report.R` with separate searches and compare their positions, and add a regression test with such a line. Status → in-progress.
- 2026-10-26: implement resumed on review return 1; minor amendment: added T6 for the return and mapped AC1 → T6. The 5 MB regression test failed first with the PCRE "match limit exceeded" warning and no row; after `names_script()` the test-check-supplement.R file passes (0 failed, 76 tests).
- 2026-10-26: verify on bdea916: `devtools::document()` no diff; `devtools::test()` 0 failed, 0 errors, 10 skipped, 404 tests; `devtools::check()` 0 errors, 0 warnings, 1 note (hidden `.claude`). claim audit: not rerun for the return, since its stopping rule allows one pass; the prose added at review pass 1 and T6 goes to the pass 2 reviewers. Status → review.

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive. -->

Review pass 1 (2026-10-26), on 01a86dc; the evidence run was stopped once a finding failed AC1, so no criterion is ticked in this pass.

- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: a report line that names `_scripts` and runs past about 3 to 5 MB makes `script_line` hit PCRE's match limit, so `grepl()` warns and the report gets no row — floor return (AC1 fails inside its domain), review return 1.
- diff-bug #2: DESIGN.md says "each a whole name", but `_scripts` has no right boundary and `-` may precede `report.R` — fix now, fixed 63cd7e6.
- diff-bug #3: a site without the file whose reports source `_scripts_old/report.R` or `_scripts/old-report.R` gets a row naming a file they do not use — follow-up, candidate row "Match report.R names as whole paths" (AC1 (b) as planned allows these lines).
- diff-bug #4: the row says to copy into `_scripts/report.R` when `_scripts` is a file, and its folder sentence covers only a folder — fix now, fixed 63cd7e6 (the sentence names both).
- diff-bug #5: the README.md and GUIDE.md list items say reports "read" the file, though prose lines count — fix now, fixed 63cd7e6.
- diff-bug #6: the help page does not say that a report that cannot be read names nothing — fix now, fixed 63cd7e6.
- diff-bug #7: the new section header put `fold_case()`, a leftover-output helper, under "Shared report code" — fix now, fixed 63cd7e6 (section moved before Links).
- diff-bug #8: the release test's list of stopping checks omits `"missing-script"` — reject, false: the release gate has no branch per check, so the value would repeat one code path, which "What gets a test" excludes.
- diff-bug #9: GUIDE.md's "After you change it" starts mid-paragraph with an unclear "it" — fix now, fixed 63cd7e6.
- diff-bug #10: two expectations compare the whole row text, repeating the naming path that the byte-order test checks — fix now, fixed 63cd7e6 (they compare `$file`).
- diff-bug #11: two test comments restate the code — fix now, fixed 63cd7e6 (one names the end-of-line probe, one removed).
- diff-bug #12: `missing_script_text()` copies the row text by hand — reject, false: check discrimination keeps the expected text stated apart from the code.
- blame-history #1: a `source()` call that puts `_scripts` and `report.R` on two lines gives no row, and the help page does not say so — fix now, fixed 63cd7e6.
- blame-history #2: the README.md and GUIDE.md list items read with the wrong subject — fix now, fixed 63cd7e6 (as diff-bug #5).
- blame-history #3: the release test list omits the new value — reject, false (as diff-bug #8).
- blame-history #4: GUIDE.md breaks the paragraph mid-sentence — fix now, fixed 63cd7e6 (as diff-bug #9).
- prior-review #1: the PCRE match limit of LESSONS 2026-10-20 (M021) is not guarded — floor return (as diff-bug #1).
- prior-review #2: the help page does not say that the letter case of `_scripts` and `report.R` in the report text must match — fix now, fixed 63cd7e6.
- prior-review #3: Windows link and folder cases match M018 and M045 — no finding.
- prior-review #4: byte order and quoting match M029 and M043 — no finding.
- prior-review #5: the change-after-render limit matches M058 — no finding.
- ripple #1: the ROADMAP row "Flag a missing _scripts/report.R file" still says no row is given — reject, planned change: the row graduates at hygiene.
- ripple #2: the release test list omits the new value — reject, false (as diff-bug #8).

Review pass 2 (2026-10-26), on 110744f after review return 1.

- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: no test runs the order comparison of `names_script()`, so `> 0` for `> first` or `min` for `max` passes every test — fix now, fixed 1dceb96 (a negative `report.R … _scripts` report and a positive `report.R, then _scripts/report.R` report; each planted defect turned the file red).
- diff-bug #2: the help page and a test title still say a report "reads" the file, while the row, NEWS, and README say "name" — fix now, fixed 1dceb96.
- diff-bug #3: the help page leaves out the `\` before each `\` and `"` in the quoted names, which AC2 states — fix now, fixed 1dceb96.
- diff-bug #4: the 5 MB regression test also compares `$file` after `expect_no_warning()` — reject, false: the two expectations show different facts (no warning, and a row).
- diff-bug #5: the NEWS bullet's last "it" reads as the site — fix now, fixed 1dceb96 (names `check_supplement()`).
- diff-bug #6: the row's copy step fails when the `_scripts` folder is missing — fix now, fixed 1dceb96 (the row says to make the folder).
- diff-bug #7: `gregexpr()` runs on every line, 0.27 s for 200,000 lines — reject, false: no defect at that cost.
- blame-history #1: a file link to a missing `_scripts/report.R` gives no row on Windows — follow-up, candidate row "Flag dangling report.R links on Windows" (Scope Out accepted it; `is_link()` could find it).
- blame-history #2: a `_scripts/report.R` that git ignores gives no row — reject, planned change: Scope Out and DESIGN.md Known issues record it.
- blame-history #3: the "Shared report code" header holds a check and its helper — reject, style.
- prior-review #1: the Windows dangling link of LESSONS 2026-10-19 (M018) — follow-up (as blame-history #1).
- prior-review #2: no test names a report whose name is not valid UTF-8 — reject, false: the naming runs `sort_bytes()` and `show_text()` unchanged, whose such names the stale-output and leftover-output tests already cover.
- prior-review #3: no test puts a nul byte in a line that names the file — reject, false: `read_report_lines()` is unchanged and its nul handling has its own test ("a nul byte or other line ends do not hide a chunk").
- prior-review #4: a later quantifier in `names_script()` could bring the PCRE warning back — no finding now.
- ripple #1: the release test list omits the new value — reject, false (as pass 1 diff-bug #8).
- ripple #2: "looks only at whether the file exists" leaves out a folder at that path — reject, false: a folder there is not the file, so the file does not exist.

Evidence (2026-10-26, on c108f37, `devtools::test()` 0 failed, 0 errors, 10 skipped, 404 tests):

- AC1: "reports that name a missing _scripts/report.R give one missing-script row" (4 expectations: file deleted, folder in its place, a last line `# _scripts/report.R`, and a `report.R` before `_scripts` that does not hide a later one), "a link to a missing _scripts/report.R gives a missing-script row" (1, run on macOS, skipped on Windows), and "a long line that names a missing _scripts/report.R gives a missing-script row" (2) pass; each asserts `file` `"_scripts/report.R"` on the `"missing-script"` rows.
- AC2: "the missing-script row names its reports in byte order" (2 expectations, both run on macOS) passes: the `problem` equals the expected text holding `"analyses/B.qmd", "analyses/a.qmd", "analyses/example.qmd"` and the `system.file("template", "_scripts", "report.R", package = "supplement")` text, then, with `q"r.qmd` added, `… "analyses/q\"r.qmd"`; the text says to commit `_scripts/report.R`.
- AC3: "no missing-script row when the file is there or no report names it" (2 expectations) passes: zero rows for an unchanged `create_supplement()` site, and zero rows for one site with the file and `example.qmd` deleted whose reports hold `source("report.R")`, `_scripts/report.Rmd`, `source("my_scripts/report.R")`, `file.path(site, "_scripts", "myreport.R")`, and `report.R comes before _scripts here.`, plus `analyses/sub/inner.qmd` with the template's `source()` line.
- AC4: read on c108f37. The `check_supplement()` roxygen (R/check-supplement.R) and man/check_supplement.Rd:127 have the `"missing-script"` bullet with conditions (a) and (b) and the limits: a line in an included file is not read, a line of another form (`source("report.R")`, a call across two lines) does not count, reports in folders inside `analyses/` are not read, and on Windows a file link to a missing file and on a case-ignoring disk `_scripts/Report.R` give no row. README.md:135 and GUIDE.md:209 list the row; NEWS.md:20 names `"missing-script"`. The `add_report()` help (R/add-report.R:34-36), GUIDE.md "Shared report code" (:59-61), and the M058 NEWS.md bullet (:15-16) say `check_supplement()` looks only at whether `_scripts/report.R` exists or is there and that a change to it gives no row.
- AC5: on c108f37, `devtools::document()` left no diff (`git status` empty before and after), `devtools::test()` 0 failed, 0 errors, 10 skipped, 404 tests, and `devtools::check()` 0 errors, 0 warnings, 1 note (hidden `.claude`, a local folder, as in M058).

Consistency gate: `cairn_validate.py` all checks passed; `devtools::document()` no diff; `pkgdown::check_pkgdown()` "No problems found"; no README.Rmd to knit. No principle changed, so `cairn_impact` is skipped. Snapshot files: none changed (no `_snaps` path in the diff).
