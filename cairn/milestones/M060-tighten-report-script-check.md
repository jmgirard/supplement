<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M060: Tighten the missing report.R check

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate -->
- **Surface tier:** user-facing — it changes which rows `check_supplement()` gives site authors   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m060-tighten-report-script-check   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

The `"missing-script"` row of `check_supplement()` counts a report line as naming `_scripts/report.R` only when one of the AC1 forms joins the two names, and it treats a file link to a missing file as missing on every system.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the match rule of `names_script()` in `R/check-supplement.R`; the missing test of `check_missing_script()` for a file link on Windows; the tests in `tests/testthat/test-check-supplement.R`; the `check_supplement()` help page; the missing-script lines of `cairn/DESIGN.md`.

**Out:** a row when `_scripts/report.R` changed since the last render stays the candidate row "Flag reports after report.R changes". Broken Quarto links in `check_tools()` on Windows stay the candidate row "Report broken Quarto links on Windows". Two-line calls, included files, letter case, and disks that ignore letter case stay as limits that the help page states. NEWS.md gets no change, because the M059 bullet describes an unreleased check and stays true.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: For a site with no `_scripts/report.R`, `check_supplement()` counts a report line as naming the file by this rule alone. The line holds `_scripts` with no ASCII letter, digit, `_`, or `.` right before it, and any such `_scripts` on the line can start the match. A separator follows right away. One separator form is `/`, `\`, or `\\`. The other form is an optional `/`, `\`, or `\\`, then a `"` or `'`, a `,` with any spaces or tabs on each side, and a `"` or `'`. Then `report.R` follows, with no ASCII letter, digit, `_`, or `.` right after it. A site whose one report holds one of these lines gets the `"missing-script"` row: `source(file.path(site, "_scripts", "report.R"), local = TRUE)`, `# _scripts/report.R` as the last line of the report, `report.R, then _scripts/report.R`, `source(file.path(site, '_scripts' , 'report.R'))`, `_scripts\report.R`, `source("_scripts\\report.R")`, `file.path(site, "_scripts/", "report.R")`, `"_scripts",` then a tab then `'report.R'`, and `_scripts_old/x and _scripts/report.R`. A site whose one report holds one of these lines gets no such row: `source("_scripts_old/report.R")`, `source("_scripts/old-report.R")`, `file.path("_scripts", "x", "report.R")`, `source("_scripts/report.R.bak")`, and `See _scripts/report.R.`. The seven cases of the existing test "no missing-script row when the file is there or no report names it" also give no row.
- [ ] AC2: A report line made of the template's `source()` line and 5 MB of other text gives the `"missing-script"` row with no warning from `check_supplement()`, with the `source()` line placed first and placed last. A report line of `"_scripts" ,` and 5 MB of spaces and tabs gives no warning and no row.
- [ ] AC3: If `_scripts/report.R` is a file link to a missing file and a report names it, `check_supplement()` gives the `"missing-script"` row on Windows, macOS, and Linux. If `_scripts/report.R` is a file link to an existing file, `check_supplement()` gives no `"missing-script"` row on Windows, macOS, and Linux.
- [ ] AC4: The `check_supplement()` help page states the AC1 rule, says that a `.` right after `report.R`, as at the end of a sentence, stops the match, and states the AC3 link case. It no longer says that `_scripts` and a later `report.R` anywhere on a line count, and it no longer says that a Windows file link to a missing file gives no `"missing-script"` row.
- [ ] AC5: `devtools::document()` leaves no change, `devtools::test()` passes, `devtools::check()` gives 0 errors and 0 warnings, and the R-CMD-check workflow passes on Windows, macOS, and Ubuntu (D-016).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4
- AC5 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive change is amend-via-gate. -->

- [x] T1: Write the tests first. Add the AC1 row lines and no-row lines and the AC2 lines to the missing-script tests in `tests/testthat/test-check-supplement.R` (near lines 656 to 727). Run them on the current code and record which fail.
- [x] T2: Rewrite `names_script()` (`R/check-supplement.R:758`) as one PCRE pattern with possessive runs for the spaces and tabs and no `.*`, and update its comment. Run `devtools::test()`.
- [x] T3: In the link test (`test-check-supplement.R:688`), replace `skip_on_os("windows")` with `symlink_or_skip()` (`tests/testthat/helper-files.R:150`). Add a test with a file link to an existing file. In `check_missing_script()`, the file also counts as missing if `is_link()` is TRUE and `fs::is_file()`, which follows the link, is FALSE. Review reads the Windows CI job's test output to see that the link tests ran there.
- [ ] T4: Update the `"missing-script"` help text (`R/check-supplement.R:109` to `133`) and run `devtools::document()`. Update the missing-script lines of `cairn/DESIGN.md` (near line 168). Run `devtools::check()`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-26: created by /milestone-plan.
- 2026-10-26: tier check: not run — work named at the question set.
- 2026-10-26: idea vet: no concern. Both rows fix the M059 check against its own aim: a row only for reports that read the file, and a missing file read as missing on Windows too.
- 2026-10-26: question set: what to plan — "Tighten report.R check" (the rows "Match report.R names as whole paths" and "Flag dangling report.R links on Windows"); match rule — count a line only when a path separator or a quote-comma-quote run joins `_scripts` and `report.R`.
- 2026-10-26: lessons used: 2026-10-19 (M018, used M059) Windows file links, 2026-10-20 (M021, used M059) PCRE match limit and possessive repeats, 2026-10-26 (M059) a `.*` pattern between two names passes the match limit.
- 2026-10-26: collision check: absorbs candidates "Match report.R names as whole paths" and "Flag dangling report.R links on Windows"; extends M059 (done); distinct from "Flag reports after report.R changes" and "Report broken Quarto links on Windows" (Scope Out); works under D-022 (fs imported, no dependency change) and D-028, no conflict; inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-26: plan gate chose `fs::is_file()` on a link over opening the file for reading, because a read test would also flag a file the user cannot read as missing; falsified by a Windows CI run where `fs::is_file()` is TRUE for a file link to a missing file.
- 2026-10-26: plan gate chose one PCRE pattern over M059's two separate searches, because the new rule puts only a bounded separator between the names, so no `.*` is needed; falsified by a match-limit warning on an AC2 line.
- 2026-10-26: plan gate chose to state in the help page that a `.` after `report.R` stops the match over widening the match to sentence ends, toward the narrower promise; falsified by a site whose reports name the file only in prose that ends a sentence.
- 2026-10-26: changelog: no NEWS.md change; the M059 bullet covers the unreleased check and stays true.
- 2026-10-26: criteria audit (full mode, fresh Opus reader): 10 findings, all fixed. AC1 now binds `check_supplement()` and not `names_script()` or the test file, allows a `/`, `\`, or `\\` before the quote form, lets any `_scripts` start the match, adds probes for `\\`, a tab, mixed quotes, a trailing `/` before the quote, two `_scripts` on one line, `report.R.bak`, and a sentence-end `.`, and names the existing test's seven cases. The Goal names the AC1 forms and the link case. AC2 places the `source()` line first and last and adds a 5 MB run of spaces and tabs. AC3 scopes both sentences to the three systems. AC4 names the old rule text to drop and the sentence-end stop. AC5 adds the CI workflow on three systems. Reachability: `symlink_or_skip()` already makes file links on the Windows runner. Proportionality: no finding.
- 2026-10-26: started on branch m060-tighten-report-script-check.
- 2026-10-26: T1: added the AC1 row and no-row lines and the AC2 long lines as three tests with `script_site()` and `script_rows_for()` helpers; on the current code the three no-row cases `_scripts_old/report.R`, `_scripts/old-report.R`, and `"_scripts", "x", "report.R"` fail, and the rest pass.
- 2026-10-26: T2: `names_script()` is one `grepl()` pattern, a `/`, `\`, or `\\` run or an optional such run then quote, comma, quote with possessive `[ \t]*+` runs; test-check-supplement.R gives 0 failures, and its one warning comes from `file.create()` in the untouched non-UTF-8 name test on macOS before its skip.
- 2026-10-26: T3: `check_missing_script()` also needs `isTRUE(fs::is_file(script))` when `is_link()` is TRUE; the dangling-link test uses `symlink_or_skip()` with no Windows skip, and a new test links `_scripts/report.R` to an existing file. A planted `!is_link(script)` alone fails the existing-link test on macOS. The Windows dangling case is seen only on CI.

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive. -->
