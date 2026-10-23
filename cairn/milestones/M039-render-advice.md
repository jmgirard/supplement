# M039: Align render advice with the new guide

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — authors read the row texts and the guide text
- **Branch/PR:** m039-render-advice

## Goal

Each place that this milestone lists gives the publishing guide's rule for a changed report: render it by name, render the whole site, then commit it with `_freeze/`, `docs/`, and `figures/`.

## Scope

**In:** the `no-stored-output`, `stale-output`, and `unpublished-figure` row texts of `check_supplement()` in `R/check-supplement.R` (near lines 547, 579, and 995) and their tests. In `inst/template/_README.md`: "Computing environment" (near line 66), the figures bullet of "Checks before a release" (near line 188), "How the site renders" (near line 242), "Rendering on the machine with the private data" (near line 278), and "Paper figures" (near line 489). In `vignettes/publishing.Rmd`: step 5 of "8. Replace the template placeholders" (near line 156) and "Render again after a report changes" (near line 226). The `NEWS.md` bullet that describes these rows.

**Out:** splitting the template guide by reader stays the candidate row "Split the template guide by reader". The release commands, the renv part's render on another machine, and the private-data part's fit-file check give advice for other tasks and stay as they are. Advice for a changed report that T5's search finds outside this list goes to a new candidate row.

## Acceptance criteria

- [ ] AC1: Three row texts of `check_supplement()` (the `no-stored-output` text and the two `stale-output` texts) end with the same sentence. That sentence tells the author to render the report by name, render the whole site, then commit the report with `_freeze/`, `docs/`, and `figures/`. A test in `tests/testthat/test-check-supplement.R` asserts, for each of the three texts, that it ends with that sentence.
- [ ] AC2: The `unpublished-figure` row text tells the author to render the whole site, then commit `figures/`, `docs/`, and `_freeze/`. A test in `tests/testthat/test-check-supplement.R` asserts the whole text.
- [ ] AC3: In `inst/template/_README.md`, step 2 of "Rendering on the machine with the private data" tells the author to render a changed report by name and then render the whole site. Step 3's `git add` command names `analyses/<name>.qmd`, `_freeze`, `docs`, and `figures`, and its lead-in names the same paths. A sentence beside the command tells the author to leave out `figures` for a site with no `figures/` folder.
- [ ] AC4: In `vignettes/publishing.Rmd`, the `git add` command of "Render again after a report changes" names the report, `_freeze`, `docs`, and `figures`. A sentence beside it tells the author to leave out `figures` for a site with no `figures/` folder. Step 5 of "8. Replace the template placeholders" no longer says that the commands in the last part fail when `figures/` is missing.
- [ ] AC5: In `inst/template/_README.md`, "Computing environment" and "How the site renders" tell the author to render a changed report by name, then render the whole site, then commit the report with `_freeze/`, `docs/`, and `figures/`. "Paper figures" and the figures bullet of "Checks before a release" tell the author to render the whole site, then commit `figures/`, `docs/`, and `_freeze/`.
- [ ] AC6: The `NEWS.md` bullet that describes the stored-output, stale-output, and unpublished-figure checks says that the rows for those problems give the steps to render and commit the fix.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T2
- AC4 → T3
- AC5 → T2
- AC6 → T4

## Tasks

- [ ] T1: In `R/check-supplement.R`, change the three report row texts (near lines 547 and 579) to end with one sentence of the rule, and the figure row text (near line 995) to the render-and-commit steps. In `tests/testthat/test-check-supplement.R`, assert with `endsWith()` in the two `stale-output` tests (near lines 435 and 465), add the assertion to the `no-stored-output` test (near line 178), and assert the whole text in the figure test (near line 1136). Show each new assertion red against the main copy of `R/check-supplement.R` first.
- [ ] T2: Edit the five template guide parts that AC3 and AC5 name. No test reads their advice text (the second criteria audit found only the `site`-chunk test in `tests/testthat/test-template.R`).
- [ ] T3: Edit the vignette's last part and step 5. Run `tests/testthat/test-publishing.R`.
- [ ] T4: Edit the `NEWS.md` bullet near lines 50 to 62. Add no new bullet, because the rows first appear in this unreleased version.
- [ ] T5: Run `grep -rn -i -E 'by name|render the (whole )?site|git add|commit' R inst/template/_README.md vignettes/publishing.Rmd README.md` and read each hit that advises on a changed report outside the In list. Record such a hit as a new candidate row. Then run `devtools::document()`, `devtools::test()`, and `devtools::check()`.

## Work log

- 2026-10-22: created by /milestone-plan.
- 2026-10-22: tier check: not run — work named at the question set.
- 2026-10-22: idea vet: one concern, answered. The guide's `git add ... figures` exits 128 and stages nothing on a site with no `figures/` folder (tested with git 2.54); the question set chose named paths with a sentence to leave out `figures`. The rule itself matches Quarto 1.10: a render by name never removes a file from `docs/`, and a full render does (LESSONS M017).
- 2026-10-22: question set: work to plan — "Align render advice with the new guide"; commit command — named paths with a note; row text — the full steps in one sentence.
- 2026-10-22: collision check: absorbed the candidate row "Align render advice with the new guide" (from the M038 review). "Split the template guide by reader" stays a separate row. M038 (done) wrote the rule into the vignette. No D-entry conflicts: D-002 keeps freeze and re-runs by name, as the rule does.
- 2026-10-22: inbox sweep: 0 open issues, 0 open PRs on jmgirard/supplement.
- 2026-10-22: lessons harvested: M017 (a render by name never removes from `docs/`), M001 (a render by name runs the code and writes `_freeze/`), M010 (show a test red by copying the main file over the working file).
- 2026-10-22: criteria audit (full mode, fresh Opus reader): 6 findings. Taken: AC1 asserts the end of each text and covers the `no-stored-output` test; AC3 keeps the private-data part's path list and adds the report; AC5's grep ledger bound a review act and a proxy domain, so it became a closed list of four places; AC6 edits the unreleased bullet in place of a "now" bullet; the missed places joined AC4 and AC5. AC4's `git add -A` went to the question set, which chose named paths.
- 2026-10-22: plan gate chose named paths with a leave-out note over `git add -A` in the vignette, because the part runs with the private data in place and `-A` stages what `.gitignore` misses; falsified by authors who stage private files through a named path, or who cannot follow the leave-out note.
- 2026-10-22: plan gate chose the full steps in each row text over a pointer to the guide, because the author can act without opening the guide; falsified by row texts too long to read in the printed table.
- 2026-10-22: plan gate chose a closed list of places over a grep-and-classify criterion, because the grep reads lines and missed wrapped advice; falsified by a listed place found to give no render or commit advice, or by advice that T5 finds in a part this list missed.
- 2026-10-22: criteria re-audit (full mode, second fresh Opus reader, after the question set changed AC4): 6 findings, all taken. AC1 now states its sentence; AC2 and AC5 add `_freeze/` to the figure advice, because a changed figure usually comes from a render by name that also rewrote `_freeze/`, and "Paper figures" already names it; AC4's last clause names the claim to remove; AC6 is reworded; T2 drops a test run that matches nothing. AC3, the part list, and Coverage had no finding.
- 2026-10-22: implement started on branch m039-render-advice, cut from main at cd9509b.
- 2026-10-22: T1 tests written first: the four changed tests failed against the old row texts (1, 2, 7, and 1 failures) and no other test failed; with the new texts `test-check-supplement.R` passes 63 of 63. The rule's sentence is one constant, `rerender_steps`, in `R/check-supplement.R`, and the test file states it again on its own.
- 2026-10-22: implement choice: vignette step 5 now says to delete the example figure and to leave out `figures` from the last part's `git add` for a site with no figures, in place of keeping the figure as a guard against the failing command.
- 2026-10-22: T5 sweep: no hit outside the In list advises on publishing a changed report (the container part runs a render with no commit steps; the release, DOI, renv, and Docker hits are other tasks), so no candidate row.
- 2026-10-22: checkpoint: T1 to T5 edits written; tasks not ticked until the full suite and `devtools::check()` pass.

## Decisions

## Review
