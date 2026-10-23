# M039: Align render advice with the new guide

- **Status:** review
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
- [x] AC3: In `inst/template/_README.md`, step 2 of "Rendering on the machine with the private data" tells the author to render a changed report by name and then render the whole site. Step 3's `git add` command names `analyses/<name>.qmd`, `_freeze`, `docs`, and `figures`, and its lead-in names the same paths. A sentence beside the command tells the author to leave out `figures` for a site with no `figures/` folder.
- [x] AC4: In `vignettes/publishing.Rmd`, the `git add` command of "Render again after a report changes" names the report, `_freeze`, `docs`, and `figures`. A sentence beside it tells the author to leave out `figures` for a site with no `figures/` folder. Step 5 of "8. Replace the template placeholders" no longer says that the commands in the last part fail when `figures/` is missing.
- [x] AC5: In `inst/template/_README.md`, "Computing environment" and "How the site renders" tell the author to render a changed report by name, then render the whole site, then commit the report with `_freeze/`, `docs/`, and `figures/`. "Paper figures" and the figures bullet of "Checks before a release" tell the author to render the whole site, then commit `figures/`, `docs/`, and `_freeze/`.
- [x] AC6: The `NEWS.md` bullet that describes the stored-output, stale-output, and unpublished-figure checks says that the rows for those problems give the steps to render and commit the fix.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T2
- AC4 → T3
- AC5 → T2
- AC6 → T4

## Tasks

- [x] T1: In `R/check-supplement.R`, change the three report row texts (near lines 547 and 579) to end with one sentence of the rule, and the figure row text (near line 995) to the render-and-commit steps. In `tests/testthat/test-check-supplement.R`, assert with `endsWith()` in the two `stale-output` tests (near lines 435 and 465), add the assertion to the `no-stored-output` test (near line 178), and assert the whole text in the figure test (near line 1136). Show each new assertion red against the main copy of `R/check-supplement.R` first.
- [x] T2: Edit the five template guide parts that AC3 and AC5 name. No test reads their advice text (the second criteria audit found only the `site`-chunk test in `tests/testthat/test-template.R`).
- [x] T3: Edit the vignette's last part and step 5. Run `tests/testthat/test-publishing.R`.
- [x] T4: Edit the `NEWS.md` bullet near lines 50 to 62. Add no new bullet, because the rows first appear in this unreleased version.
- [x] T5: Run `grep -rn -i -E 'by name|render the (whole )?site|git add|commit' R inst/template/_README.md vignettes/publishing.Rmd README.md` and read each hit that advises on a changed report outside the In list. Record such a hit as a new candidate row. Then run `devtools::document()`, `devtools::test()`, and `devtools::check()`.

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
- 2026-10-22: verify: `devtools::test()` 368 tests, 0 failed, 8 skipped; `devtools::document()` changed no file; `devtools::check()` 0 errors, 0 warnings, 0 notes; `test-publishing.R` with `NOT_CRAN=true` passes on the final guide text.
- 2026-10-22: claim audit: 23 claims read, 3 corrected — inst/template/_README.md, vignettes/publishing.Rmd (the `git add` sentence now says a path git still tracks is staged, step 2 says what a full render runs, step 3 covers added reports; the re-read confirmed all three and added "If there is no such report, leave it out").
- 2026-10-22: T1 to T5 done; status review.

## Decisions

## Review

- 2026-10-22: sync: branch level with origin/main (cd9509b); Copilot round off; no PR yet (route d).
- AC3 evidence: `inst/template/_README.md` read at the review head. Step 2 of "Rendering on the machine with the private data" says to render a changed report with `quarto render analyses/<name>.qmd`, then the whole site with `quarto render`. Step 3's block holds `git add analyses/<name>.qmd _freeze docs figures`, its lead-in names the reports added or changed, `_freeze/`, `docs/`, and `figures/`, and the sentence after it says to leave out `figures` for a site with no `figures/` folder.
- AC4 evidence: `vignettes/publishing.Rmd` read at the review head. The last part's block holds `git add analyses/models.qmd _freeze docs figures`, the sentence after it says to leave out `figures` for a site with no `figures/` folder, and step 5 of part 8 now says to delete the example figure and to leave out `figures`; it no longer says the commands fail.
- AC5 evidence: `inst/template/_README.md` read at the review head. "Computing environment" (line 66) and "How the site renders" (line 255) say render by name, render the whole site, then commit the report with `_freeze/`, `docs/`, and `figures/`. "Paper figures" (line 508) and the "Checks before a release" figures bullet (line 190) say render the whole site, then commit `figures/`, `docs/`, and `_freeze/`.
- AC6 evidence: `NEWS.md` lines 63 to 64, inside the `check_supplement()` bullet of the unreleased section: "The rows for missing, old, or unreadable stored output and for such figures give the steps to render and commit the fix." No new bullet was added.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: step 3 of the private-data recipe and the `no-stored-output` row leave `_quarto.yml` out of the commit, though `add_report()` adds a menu item there — fix now in step 3 (a sentence to stage `_quarto.yml` for a report that `add_report()` made); the row's part goes to the new candidate row "Align the remaining render advice", because AC1 fixes one sentence for all three texts.
- diff-bug #2: "names no file on disk and no file that git tracks" is false for an existing empty `figures/` folder, where `git add` exits 0 — fix now (both guides now say "is missing from disk and git tracks no file under it").
- diff-bug #3: "copies into `docs/` the figures that the render by name saved" — fix now ("saved under new names"; DESIGN.md's `_quarto.yml` entry says a changed figure under an existing name reaches `docs/` in the same render).
- diff-bug #4: vignette step 5 goes beyond AC4 by deleting the example figure — reject (false: not a defect; the change follows from the leave-out sentence, is logged as an implement choice, and D-018 covers only the first render).
- diff-bug #5: the colon after "If there is no such report, leave it out:" introduces the command — fix now (the leave-out sentence moved after the block).
- diff-bug #6: NEWS "missing or old stored output" leaves out the unreadable-hash text — fix now ("missing, old, or unreadable").
- diff-bug #7: the two `stale-output` tests assert `endsWith()` once per row over one constant — fix now (one `all(endsWith(...))` after each loop).
- diff-bug #8: new R lines of 103 to 107 characters — reject (style).
- blame-history #1: "How the site renders" lost the commit step for a deleted or renamed report — fix now ("Then commit the change with `_freeze/` and `docs/`.").
- blame-history #2: the private-data step 3 now stages the report — reject (planned change, AC3).
- blame-history #3: vignette step 5 deletes the figure beyond AC4 — reject (false, as diff-bug #4).
- blame-history #4: the `no-stored-output` row does not name the fit-file check — reject (false: that check applies only to reports with private fit files, which the row cannot know; the private-data recipe gives it).
- prior-review #1: vignette step 5 reverses M038's keep-the-figure step — reject (false, as diff-bug #4).
- prior-review #2: no test runs the `git add` leave-out claim — reject (a test would test git, a dependency; three reviewers checked it by experiment on git 2.54).
- prior-review #3: step 3's path list omits `renv.lock`, which the renv part says to add — reject (false: the renv part tells the reader to add it to this command, so the two agree).
- prior-review #4: line lengths — reject (style).
- ripple #1: `inst/template/_quarto.yml` comment says to render one report by name only — follow-up, new candidate row "Align the remaining render advice" (outside the In list, per Scope Out).
- ripple #2: `inst/template/_quarto.yml` comment says "render again" for a new figure name, with no commit — follow-up, the same row.
- ripple #3: NEWS bullet for the publishing guide gives the rule without the commit step — follow-up, the same row.
- ripple #4: the candidate row "Align render advice with the new guide" describes the old texts — reject (false: that row graduates at this milestone's post-merge hygiene).
- gate: the first review `devtools::check()` had 1 test failure, a template render whose `_scripts/nojekyll.ts` exited 139 (the parked row "Trace the post-render crash on macOS", now recorded there); this diff changes no script or render code.
