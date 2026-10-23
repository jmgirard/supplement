# M041: Correct two older render notes

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — site authors read the template's `_quarto.yml` comments and its guide
- **Branch/PR:** m041-older-render-notes

## Goal

The template says what a full render runs and gives the steps after a report is deleted or renamed.

## Scope

**In:** the comment above `render:` in `inst/template/_quarto.yml` (lines 4 to 8). The paragraph on a deleted or renamed report in "How the site renders" in `inst/template/_README.md` (lines 250 to 252). One test that follows that paragraph's steps for a renamed report.

**Out:** a `check_supplement()` row for the stored output of a deleted or renamed report goes to the new candidate row "Flag stored output of deleted reports". The figures that a deleted report saved stay in `figures/`; "Paper figures" in the guide says how to take a figure off the site. Step 4 of `vignette("publishing")` already gives the delete steps for the example report and stays as it is. No `NEWS.md` change, because NEWS does not list the guide's parts. Splitting the template guide by reader stays the row "Split the template guide by reader". T4's search can find another copy of either wrong note. Each such hit goes to a new candidate row.

## Acceptance criteria

- [ ] AC1: In `inst/template/_quarto.yml`, the comment above `render:` says that a full render reuses the stored output in `_freeze/` and runs the code of each report that has no stored output there. It keeps the steps for a changed report in the same order (render it by name, render the whole site, then commit it with `_freeze/`, `docs/`, and `figures/`) and the pointer to README.md or SUPPLEMENT.md.
- [ ] AC2: In `inst/template/_README.md`, the paragraph in "How the site renders" on a deleted or renamed report gives three steps in this order; the words "first" and "second" need not appear. Step 1: delete the report's folder in `_freeze/analyses/` and remove or change its item in the Analyses menu of `_quarto.yml`. Step 2: run a full render. Step 3: commit the deleted or renamed report with `_quarto.yml`, `_freeze/`, `docs/`, and `figures/`. The paragraph also says that the full render runs the code of a renamed report, so that render needs the report's data, its fit files, and R.
- [ ] AC3: A test in `tests/testthat/test-add-render.R` covers a renamed report; a deleted report is not tested. In a rendered site, it renames a report that `add_report()` made, follows AC2's steps 1 and 2 with no render between the rename and those steps, and asserts three facts. (1) `docs/analyses/` holds the page under the new name and not under the old name. (2) `_freeze/analyses/` holds a folder under the new name. (3) `check_supplement()` gives no `broken-link` row. On the same site it then renames the report again and runs a full render with no other step, and asserts two facts. (4) The folder of the name before that rename stays in `_freeze/analyses/`. (5) `check_supplement()` gives a `broken-link` row whose problem names that name's `.qmd`.
- [ ] AC4: `devtools::document()` leaves no diff, and `devtools::test()` passes. `devtools::check()` gives 0 errors and 0 warnings, and each NOTE is justified in the Review section. If a template render fails because `_scripts/nojekyll.ts` exits 139, one re-run counts.

## Coverage

- AC1 → T2
- AC2 → T3
- AC3 → T1
- AC4 → T4

## Tasks

- [x] T1: In `tests/testthat/test-add-render.R`, add the test of AC3. Make a site with `create_supplement()`, add a report with `add_report()`, and run a full render. Rename the report file, delete its old folder in `_freeze/analyses/`, change the menu item's `href` in `_quarto.yml` to the new name, and run a full render. Assert facts 1 to 3 of AC3. Rename the report again and run a full render. Assert facts 4 and 5. Run `devtools::test(filter = "add-render")`.
- [ ] T2: Rewrite the comment above `render:` in `inst/template/_quarto.yml` (lines 4 to 8). Keep the steps that M040 set and the pointer to README.md or SUPPLEMENT.md. Run `devtools::test(filter = "template")`, because those tests render the template.
- [ ] T3: Rewrite the paragraph at lines 250 to 252 of `inst/template/_README.md` to give AC2's steps.
- [ ] T4: Run `grep -rn -i -E 'runs no (report )?code|delete or rename|rename a report' R inst/template vignettes README.md NEWS.md`. Read each hit outside the In list that repeats either wrong note, and record it as a new candidate row. Then run `devtools::document()`, `devtools::test()`, and `devtools::check()`. If a template render fails because `_scripts/nojekyll.ts` exits 139, write a work-log line for the row "Trace the post-render crash on macOS".

## Work log

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: not run — work named at the question set.
- 2026-10-23: idea vet: no concern found. A probe site (Quarto 1.10.19, `create_supplement()` plus `add_report("second")`, then `second.qmd` renamed to `third.qmd` and a full render) showed both notes wrong: the full render ran `third.qmd`, removed `docs/analyses/second.html`, kept `_freeze/analyses/second/`, and warned "Unable to resolve link target: analyses/second.qmd" for the menu item; `check_supplement()` gave three `broken-link` rows for it and no row for the old folder. Step 4 of `vignette("publishing")` already deletes the example's `_freeze/` folder and menu item, so AC2's steps follow the guide.
- 2026-10-23: question set: work to plan — "Correct two older render notes"; run — plan, build, review.
- 2026-10-23: collision check: absorbed the candidate row "Correct two older render notes" (from the M040 review). M039 and M040 (done) set the changed-report steps that AC1 keeps. "Name leftover format files in _freeze" and "Split the template guide by reader" stay separate rows. No D-entry bears on it: D-002 keeps freeze on.
- 2026-10-23: inbox sweep: 0 open issues, 0 open PRs on jmgirard/supplement.
- 2026-10-23: lessons harvested: M001 and M017 (what a render by name and a full render run and copy), M009 (criteria as stated rules plus listed tests), M039 (`git add` of a deleted tracked folder stages the deletion).
- 2026-10-23: criteria audit (full mode, fresh Opus reader): 8 findings, all taken. AC1 now names the kept steps and their order. AC2 numbers its steps, commits the deleted or renamed report, and says the render needs the report's data, fit files, and R. AC3 covers a rename only, tests AC2's path with no render between the rename and the steps, numbers its five facts, and drops the absent-old-folder fact, which only checked the test's own deletion; the rename-alone control now runs after the steps on the same site. AC4 says where NOTEs are justified, and its crash note moved to T4. No principle or D-entry blocks a criterion; no factual contradiction found.
- 2026-10-23: plan gate chose a guide step to delete the old `_freeze/` folder over a `check_supplement()` row for it, because the guide already gives that step for the example report; the row becomes the candidate "Flag stored output of deleted reports"; falsified by authors who skip the step and publish stale stored output.
- 2026-10-23: plan gate chose no `NEWS.md` change over a bullet for the corrected guide, because NEWS lists features and the guide's parts are not listed there (M039 changed four guide parts with no NEWS bullet for them); falsified by a NEWS bullet that repeats either wrong note.
- 2026-10-23: set in-progress on branch m041-older-render-notes, cut from main at 09247c3.
- 2026-10-23: T1 done: the test "the guide's steps after a rename give the page its new name and keep the menu link" in `tests/testthat/test-add-render.R` renames `models` to `comparison` with the guide's steps, then `comparison` to `results` alone; it uses `replace_in_file()` for the menu edit. Its control (facts 4 and 5) is the planted defect for fact 3: the same site without the menu edit gives a `broken-link` row naming the old `.qmd`. `devtools::test(filter = "add-render")`: 0 failures, 41 passes.

## Decisions

## Review
