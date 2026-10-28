# M071: List reports in menu order on the home page

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes the home page of every new site and the reports `add_report()` writes
- **Branch/PR:** m071-report-table-order

## Goal

Make the home page's report table list reports in the order of the Analyses menu, through an `order` field that the template's example report and `add_report()` write.

## Scope

**In:** `order: 1` in the front matter of the template's `analyses/example.qmd`, with the new `example_versions` hash and fixture that the change of that file needs. `add_report()` reads the `order` of the other reports in `analyses/` and writes `order: N` into the new report, or no `order` line on a site whose reports have none. Quarto 1.10.19's default listing sort already lists reports with a numeric `order` first by that value and the others after them by title, so `index.qmd` keeps its listing settings. Docs: the `add_report()` help, the template's `GUIDE.md` and `index.qmd` comment, `README.md`, `NEWS.md`, and `cairn/DESIGN.md`.

**Out:** editing the reports of an existing site. A changed report gets a new hash, and `check_supplement()` then reports stale output; `GUIDE.md` tells the author how to add `order` by hand, and no row is planned for a migration helper (the package is pre-release). A table that follows a menu the author reorders by hand: `GUIDE.md` says to edit `order` to match.

## Acceptance criteria

- [x] AC1: `create_supplement()` makes a site whose `analyses/example.qmd` front matter holds `order: 1`, shown by a test that reads the front matter of the copied file.
- [x] AC2: `add_report()` writes the new report's `order` field by these rules, where a report "has an `order`" when its front matter, as the yaml package reads it, holds an `order` that is one number whose absolute value is below 1000000. Each rule is shown by its own test in `tests/testthat/test-add-report.R`: (a) when `analysis_reports()` lists no other report, `order: 1`; (b) when at least one other listed report has an `order`, the smallest whole number greater than the largest such value, written as a whole number (`order: 4` after `order: 1` and `order: 3`; `order: 3` after `order: 2.5`); (c) when other reports are listed and none has an `order`, no `order` line, a report with `order: 10000000` included; (d) a listed report whose front matter the yaml package cannot read counts as having no `order`, and `add_report()` still writes the report.
- [ ] AC3: On a site that `create_supplement()` makes and that gets three reports from `add_report()`, at least one of whose titles sorts before "Example Analysis" and which are added in an order that differs from their title order, `quarto render` writes a home page whose report table lists the four reports in the order of the Analyses menu in `_quarto.yml`, the example report first, shown by a render test in `tests/testthat/test-add-render.R` that skips when Quarto is missing.
- [x] AC4: Each text that `grep -rniE 'home page|listing|Analysis Reports'` finds in `README.md`, `NEWS.md`, `vignettes/`, `R/`, `inst/template/`, and `cairn/DESIGN.md` and that describes how the home page's report table orders reports states the rule: reports with an `order` field first, by that value, then the others by title. The `add_report()` help page states when the function writes `order` and when it does not.
- [x] AC5: `devtools::test()` gives 0 failures and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T3
- AC3 → T4
- AC4 → T5, T7
- AC5 → T6

## Tasks

- [x] T1: Tests first. In `test-create-supplement.R`, read the copied example's front matter and expect `order` 1 (AC1). In `test-add-report.R`, add one test for each of AC2's rules (a) to (d), the 10000000 case in (c), and update the two tests the `order` line breaks: "an empty description writes no description key" (front matter equal to `list(title = "Plain")`) and "a report stub reads the shared functions" (`expect_lte(length(lines), 40L)`). See them fail.
- [x] T2: Add `order: 1` to `inst/template/analyses/example.qmd`. Add its `text_hash()` to `example_versions` in `R/check-supplement.R` (near line 2109), named `current`, so the test at `test-check-supplement.R:1945` passes. No fixture: the installed-template copy is already compared, and the next change of the file writes this version's fixture under its squash commit.
- [x] T3: In `R/add-report.R`, read the front matter of each other report that `analysis_reports()` lists, reusing the front-matter reading of `engine_is_knitr()` in `R/check-supplement.R` (factor out a shared helper if it keeps both readers the same), find the largest `order` per AC2, and pass it to `report_lines()`, which writes the `order` line after `description`.
- [x] T4: Add the AC3 render test to `test-add-render.R`, reading the table with `listing_rows()` and the menu from `_quarto.yml`, with titles such as "Alpha Models", "Zeta Checks", "Beta Sample" added in that order.
- [x] T5: Update the `add_report()` roxygen and run `devtools::document()`; update `GUIDE.md`'s Reports section (the rule, adding `order` by hand, editing it to reorder), the `index.qmd` listing comment, `README.md`, `cairn/DESIGN.md`, and add a `NEWS.md` entry. Run AC4's grep and record in the Review section which texts it found describe the table's order.
- [x] T6: Run `devtools::test()` and `devtools::check()`. Build the demo with `.github/scripts/build-demo.R` and confirm its table reads Sample Description, Main Analysis, Robustness Checks.
- [x] T7: Review return 1: make `README.md:93-97` and `inst/template/GUIDE.md:32-35` state the rule (reports with an `order` first, by that value, then the others by title).

## Work log

- 2026-10-28: created by /milestone-plan.
- 2026-10-28: tier check: not run — work named at the question set.
- 2026-10-28: question set: which work to plan — "Order the home page report table"; which order the table follows — the Analyses menu's order (over title order everywhere and file name order).
- 2026-10-28: idea vet: no concern. Quarto 1.10.19 in a scratch site listed numeric `order` values 1, 2, 3, 10 in that order, reports with no `order` after them by title, and a `date` field changed neither; sites made before this change keep title order, since editing their reports would change their stored-output hash, and the package is pre-release (0.0.0.9000).
- 2026-10-28: lessons used: 2026-10-21 (M027), Quarto's freeze hash covers the report file, which shaped the no-edit rule for old sites; 2026-10-28 (M068), CI takes over 10 minutes per push, for the review's CI wait.
- 2026-10-28: collision check: absorbed the candidate row "Order the home page report table"; no D-entry or archived milestone covers report order (D-010 and D-011 cover edits to site YAML, not a new report file); under D-034 the demo table changes from title order to menu order. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-28: plan gate chose an `order` field in each report over an explicit file list in the `index.qmd` listing with `sort: false` because a list would hide a report added by hand until the author also edits `index.qmd`; falsified by a Quarto version whose default listing sort ignores `order`.
- 2026-10-28: plan gate chose writing no `order` on a site whose reports have none over always writing max + 1 because Quarto lists reports with `order` first, so the new report would jump to the top of an old site's table; falsified by finding that old sites' authors add `order` to every report anyway.
- 2026-10-28: criteria audit (full mode, fresh Opus reader) returned 7 findings, all accepted: AC2 bounds `order` below 1000000 in absolute value with a test above it (large values write as `1e+15`, which yaml reads back as a string); AC2 names the yaml package as the reader (quoted `"3"` is a string to it and a number to Quarto); AC3 needs a title that sorts before the example's; AC4 says "orders" not "orders or lists", adds `Analysis Reports` to the grep and `cairn/DESIGN.md` to the paths, and drops its recording sentence, now in T5; T1 names the two existing tests the `order` line breaks; T2 names the `example_versions` hash and fixture that editing `example.qmd` needs.
- 2026-10-28: T1: added the example-order test and five `order` tests (rules a to d, the quoted `"3"` and 10000000 cases under c) and updated the two tests the `order` line breaks; 7 fail on main as planned, and the rule (c) tests pass there, since main writes no `order`.
- 2026-10-28: T2 (minor amendment): `example_versions` keys each version by its squash commit on main, which this branch cannot know, so the new version is keyed `current` and the comment says the next change renames it; no fixture or commit-list change, since `placeholder_example_rows()` already compares the installed template's copy and the fixture can be written from main once the commit exists. New example is 2752 bytes, under `example_version_bytes` (5090). check and create tests pass; the one warning (a non-UTF-8 file name on macOS) also shows on main.
- 2026-10-28: T3: factored `report_front_matter()` out of `engine_is_knitr()` in `R/check-supplement.R`; `next_report_order()` in `R/add-report.R` reads each listed report's `order` through it and `report_lines()` writes the line after `description`, formatted with `sprintf("%.0f")` so it never prints as `1e+06`. A third existing test compared the whole front matter ("valid UTF-8 text marked as bytes") and now compares title and description only. `devtools::test()`: 480 tests, 0 failed, 12 skipped.
- 2026-10-28: T4: render test "the home page lists added reports in the order of the Analyses menu" adds zeta, alpha, beta and expects the table and the menu both to read example, zeta, alpha, beta; it passes with `NOT_CRAN=true`, and with `next_report_order()` replaced by one returning NULL it fails with the table reading example, alpha, beta, zeta.
- 2026-10-28: T5: stated the order rule in the `add_report()` help (new paragraph, `man/` regenerated), `GUIDE.md` Reports section and its `add_report()` note, the `index.qmd` listing comment, `README.md`, `cairn/DESIGN.md`, and a new `NEWS.md` entry. The AC4 grep and its classification go in the Review section at review time. `devtools::test()`: 481 tests, 0 failed, 12 skipped.
- 2026-10-28: T6: `devtools::check()` at 61e304f gave 0 errors, 0 warnings, 1 note (local `.claude`, as in M070). The demo built from the branch (installed to a temp library) passed `check_supplement()` and its table reads Sample Description, Main Analysis, Robustness Checks, the menu's order. After the claim-audit fixes, `devtools::test()`: 481 tests, 0 failed, 12 skipped.
- 2026-10-28: claim audit: 40 claims read, 11 corrected — NEWS.md, R/add-report.R, R/check-supplement.R, README.md, inst/template/GUIDE.md, man/add_report.Rd, tests/testthat/test-add-render.R, tests/testthat/test-add-report.R. The false claims were the cap's reason (`sprintf` never writes `1e+06`; yaml reads 3000000000 as NA) and two test comments; the partly true ones gained the condition that every report has an `order` and the menu follows it, the full-site render step, and "higher than every other report's". The one re-read cleared 9 and found README and one GUIDE line still lacking the menu condition and one comment word, all fixed with no further read.
- 2026-10-28: status review: all tasks checked; verify slot clean.
- 2026-10-28: review return 1: AC4 — `README.md:93-97` and `inst/template/GUIDE.md:32-35` describe the table's order as the menu's without stating the rule (reports with an `order` first, by that value, then the others by title).
- 2026-10-28: T7 (minor amendment, the return's task; Coverage AC4 → T5, T7): `README.md` and `GUIDE.md`'s `add_report()` note now state the rule before the menu-order condition; the added sentences repeat claims the claim audit read true at `index.qmd:4-7` and `GUIDE.md:15-17`. `devtools::test()`: 481 tests, 0 failed, 12 skipped.
- 2026-10-28: status review: T7 checked; verify slot clean.
- 2026-10-28: step-7 approval: m071-report-table-order approved for merge

## Decisions

## Review

Pass 1 (2026-10-28, head 54b39f2, branch level with main at 84e53af; Copilot round off, no PR yet).

- AC1: `test-create-supplement.R` "the example report has order 1, so it lists first on the home page" passed (1 expectation, 0 failed).
- AC2: in `test-add-report.R`, rule (a) "the first report of a site gets order 1" (1 expectation), (b) "a new report gets the next whole number after the largest order" (3: `order: 4` after 1 and 3, `order: 3` after 2.5, `order: 8` beside a report with none), (c) "a site whose reports have no order gets no order line" (3: none, quoted `"3"`, 10000000), (d) "a report whose front matter does not parse counts as having no order" (1: the bad report's 5 ignored, `order: 3` after the good 2, report written) all passed, 0 failed.
- AC3: `test-add-render.R` "the home page lists added reports in the order of the Analyses menu" ran with `NOT_CRAN=true` and Quarto 1.10.19 and passed (3 expectations, 0 failed): menu and table both read example, zeta, alpha, beta; "Alpha Models" and "Beta Sample" sort before "Example Analysis".
- AC4: FAILED. The grep found 41 lines. Texts that describe how the table orders reports: `README.md:93-97`, `NEWS.md:3-10`, `R/add-report.R:9-22` (help), `R/add-report.R:266-275` (comment), `inst/template/index.qmd:4-7`, `inst/template/GUIDE.md:12-20`, `inst/template/GUIDE.md:32-35`, `cairn/DESIGN.md:301-304`. All state the rule except `README.md:93-97` and `GUIDE.md:32-35`, which say the home page lists reports in menu order without the rule (reports with an `order` first by that value, then the others by title). The other 33 lines are about the data table, DOIs, the setup box, the page text, or the listing's existence (`NEWS.md:129-130`, `R/add-report.R:5`), not the order.

Pass 2 (2026-10-28, head c12846a after T7; branch level with main at 84e53af). T7 changed only `README.md`, `inst/template/GUIDE.md`, and tracking, so the AC1 to AC3 test evidence of pass 1 stands on unchanged code and tests.

- AC4: the grep found 41 lines, the same set as pass 1. The texts that describe the table's order are the eight passages of pass 1, now at `README.md:93-99` and `inst/template/GUIDE.md:32-36`; each states the rule (reports with an `order` first, by that number, then the others by title). The `add_report()` help (`R/add-report.R:9-22`, `man/add_report.Rd`) states when the function writes `order` (`order: 1` with no other report, the next whole number otherwise) and when it does not (no other report has one).
- spawned: diff-bug, blame-history, prior-review, ripple (user-facing tier, four lenses).
- diff-bug #1: a report saved with a UTF-8 BOM gives `report_front_matter()` no `---` first line, so `next_report_order()` ignores its `order` while Quarto reads it, and the new report can list before it — fix now, fixed c3c1a90 (BOM dropped from the first line; test "the order of a report saved with a UTF-8 BOM counts", red without the fix).
- diff-bug #2: with a largest `order` of 999999 to 999999.99, the function writes `order: 1000000`, which the next call ignores — follow-up, row "Keep new reports after large orders".
- diff-bug #3: the yaml package reads `010` as 8 and `1e3` and `1_000` as text where Quarto reads YAML 1.2 numbers — reject, planned change: AC2 names the yaml package as the reader, and the help says so.
- diff-bug #4: an `order` set in `analyses/_metadata.yml` is not read — follow-up, row "Keep new reports after large orders".
- diff-bug #5: `next_report_order()` runs after the first folder and file writes — reject, false: it catches its read and parse errors, so it cannot throw, and `on.exit` cleans up on an interrupt.
- diff-bug #6: `report_front_matter()` lives in `R/check-supplement.R`, not a shared-helper file — reject, style.
- diff-bug #7: nothing enforces renaming `current` — reject, false as a defect: no code reads the names, so a missed rename gives no wrong result.
- diff-bug #8: a 117-character line in `GUIDE.md` — reject, style.
- diff-bug #9 (tests): the quoted `"3"` case runs the same path as no `order` — reject, false: it pins the help's stated yaml-text rule (a documented claim).
- diff-bug #10 (tests): `order: 7` beside a report with none repeats the max path — reject, false: it is AC2(b)'s mixed case, where a report without `order` drops out of the max.
- diff-bug #11 (tests): the rule (c) test comment restated its expectation in its second clause — fix now, fixed c3c1a90 (clause removed).
- diff-bug #12 (tests): the render test's menu check repeats the menu-append coverage — reject, false: it is the reference order the table is compared against.
- blame-history #1: existing orders of a million or more are ignored, but Quarto sorts them, so a new report can list before them — reject, planned change (AC2(c)); the remedy joins row "Keep new reports after large orders".
- blame-history #2: a quoted `order` counts as none though Quarto might sort it — reject, false: the claim audit saw Quarto 1.10.19 stop the render on `order: "5"` ("must instead be a number").
- blame-history #3: the stub line cap moved from 40 to 41 — reject, planned change (T1).
- blame-history #4: `current` breaks the key rule — reject, false as a defect (as diff-bug #7); the comment states the `current` rule.
- blame-history #5: a 170-column line in `GUIDE.md` — reject, style.
- blame-history #6: `GUIDE.md` did not say what to do when no other report has an `order` — fix now, fixed c3c1a90 (give it none, and the table lists by title).
- prior-review #1: the BOM gap of the M026 review reaches `add_report()` — fix now, as diff-bug #1, fixed c3c1a90.
- prior-review #2: `current` rename not enforced — reject, false as a defect (as diff-bug #7).
- prior-review #3: the rule is restated in five files that can drift apart — reject, planned change (AC4 requires each to state it).
- prior-review #4: stub cap 40 to 41 — reject, planned change (T1).
- ripple #1: the candidate row "Order the home page report table" describes the old title sort — reject, planned change: step 9 hygiene removes the row at the merge.
- ripple #2: `README.md:89-90` names only the title and description in a new report's front matter — reject, false: the sentence is true, and the same paragraph says the report gets the next `order`.
- ripple #3: `cairn/DESIGN.md:208` says `example_versions` holds versions the default branch has held — reject, false after the merge, which puts this version on the default branch.
- ripple #4: `data-raw/example-qmd-fixtures.R:6-8` says `example_versions` holds each fixture's hash — reject, false: the statement is about the fixtures, and each fixture's hash is still listed.
- After the fixes, `devtools::test()`: 482 tests, 0 failed, 12 skipped.
- AC5: at c3c1a90 (the review fixes), `devtools::test()` gave 482 tests, 0 failed, 12 skipped, and `devtools::check()` gave 0 errors, 0 warnings, 1 note (the local `.claude` folder, not in the built package from a clone; same note as M070).
- Consistency gate: `cairn_validate` all checks passed; no principle changed, so no `cairn_impact` run; `devtools::document()` left no diff; no `README.Rmd`; `pkgdown::check_pkgdown()` found no problems; `NEWS.md` has the entry, with no milestone number; no new top-level files.
- Diffstat outside `cairn/`: 11 files changed, 194 insertions, 24 deletions.
