# M040: Align the remaining render advice

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — authors read the template comments, the row text, and NEWS
- **Branch/PR:** m040-remaining-render-advice

## Goal

Each place that this milestone lists gives the guide's steps for its case: a changed report, a new figure name, or a report with no stored output.

## Scope

**In:** the two render comments in `inst/template/_quarto.yml`, above `render:` (lines 4 to 7) and above `resources:` (lines 11 to 13). The `no-stored-output` row text of `check_supplement()` in `R/check-supplement.R` (near line 551) and its test. Two `NEWS.md` bullets: the bullet for `vignette("publishing")` (near line 208) and the `check_supplement()` bullet on the render and commit steps (near line 62).

**Out:** the two `stale-output` texts get no `_quarto.yml` sentence. They are about a changed report, and the guide's steps for a changed report name no `_quarto.yml`. The renv part's render on another machine gives advice for another task and stays as it is, as M039 settled. Splitting the template guide by reader stays the candidate row "Split the template guide by reader". T5's search can find advice on a changed or new report outside this list. Each such hit goes to a new candidate row.

## Acceptance criteria

- [ ] AC1: In `inst/template/_quarto.yml`, the comment above `render:` gives the steps for a changed report. The author renders it by name, then renders the whole site, then commits the report with `_freeze/`, `docs/`, and `figures/`. The comment above `resources:` gives the steps for a new figure name in `figures/`. The author renders the whole site again, then commits `figures/`, `docs/`, and `_freeze/`.
- [ ] AC2: The `no-stored-output` row text of `check_supplement()` ends with two sentences. The first is "Render the report by name, render the whole site, then commit the report with _freeze/, docs/, and figures/." The second is "If you added the report to the Analyses menu, as add_report() does, also commit _quarto.yml." The two `stale-output` texts still end with the first sentence and do not name `_quarto.yml`.
- [ ] AC3: In `NEWS.md`, the bullet for `vignette("publishing")` gives three steps. They are: render the report by name, render the whole site, then commit it with `_freeze/`, `docs/`, and `figures/`. The `check_supplement()` bullet says that the row for a report with no stored output also says to commit `_quarto.yml` for a report in the Analyses menu.
- [ ] AC4: `devtools::document()` leaves no diff, and `devtools::test()` passes. `devtools::check()` gives 0 errors and 0 warnings, with each NOTE justified. If a template render fails because `_scripts/nojekyll.ts` exits 139, one re-run counts. The work log then notes the crash for the row "Trace the post-render crash on macOS".

## Coverage

- AC1 → T3
- AC2 → T1, T2
- AC3 → T4
- AC4 → T5

## Tasks

- [x] T1: In `tests/testthat/test-check-supplement.R`, change the `no-stored-output` test's ending assertion (near line 205). Assert with `endsWith()` against the two sentences of AC2, stated in the test. In both `stale-output` tests (near lines 441 and 471), assert that no problem text contains `_quarto.yml`. Show the `no-stored-output` assertion red against the main copy of `R/check-supplement.R` first.
- [x] T2: In `R/check-supplement.R` (near line 551), add the second sentence after `rerender_steps` in the `no-stored-output` text only. Run `devtools::test(filter = "check-supplement")`.
- [x] T3: Rewrite the two comments in `inst/template/_quarto.yml`. Keep the pointer to README.md or SUPPLEMENT.md. Run `devtools::test(filter = "template")`, because those tests render the template.
- [x] T4: Edit the two `NEWS.md` bullets in place. Add no new bullet, because both features first appear in this unreleased version.
- [x] T5: Run `grep -rn -i -E 'by name|render the (whole )?site|render again|re-run|git add' R inst/template vignettes README.md NEWS.md`. Read each hit that advises on a changed or new report outside the In list, and record it as a new candidate row. Then run `devtools::document()`, `devtools::test()`, and `devtools::check()`.

## Work log

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: not run — work named at the question set.
- 2026-10-23: idea vet: no concern found. The steps match Quarto 1.10: a render by name runs the report's code and never removes a file from `docs/` (LESSONS M001, M017). `add_report()` adds the report's item to the Analyses menu in `_quarto.yml` (`R/add-report.R` lines 3 to 4).
- 2026-10-23: question set: work to plan — "Align the remaining render advice"; run — plan, then implement; pkgdown workflow — granted, but not used by this work.
- 2026-10-23: collision check: absorbed the candidate row "Align the remaining render advice" (from the M039 review). M039 (done) set the rule in the row texts and the template guide; this milestone extends it. "Split the template guide by reader" stays a separate row. No D-entry bears on it: D-002 keeps freeze and re-runs by name, as the steps do.
- 2026-10-23: inbox sweep: 0 open issues, 0 open PRs on jmgirard/supplement.
- 2026-10-23: lessons harvested: M001 and M017 (render by name), M010 (show a test red by copying the main file over the working file), M039 (`git add` of a missing `figures` stages nothing).
- 2026-10-23: criteria audit (full mode, fresh Opus reader): 6 findings, all taken. The Goal now names each case, because the figure and new-report sites give other steps. AC2 quotes both sentences in place of the constant's name and drops "tests show both" (the tests stay in T1). AC3 says the row names `_quarto.yml` only for a report in the menu. AC4 allows one re-run after an exit 139 crash, because that crash came again in the M039 review. T1's line numbers are corrected. The finding on a leave-out note for `figures/` is answered below.
- 2026-10-23: plan gate chose no leave-out note for `figures/` in the `_quarto.yml` comment over adding one, because the comment points to the guide that carries the note, as the M039 row texts do; falsified by an author who runs `git add` with `figures` from the comment on a site with no such folder.
- 2026-10-23: plan gate chose a `_quarto.yml` sentence in the `no-stored-output` row only over one in all three report rows, because only a new report changes the menu; falsified by a stale report whose menu item was never committed.
- 2026-10-23: plan gate chose a grep in T5 that files new rows over a grep-and-classify criterion, as M039's audit did, because the grep reads lines and misses wrapped advice; falsified by advice that T5's grep misses in a part this list leaves out.
- 2026-10-23: implement started on branch m040-remaining-render-advice, cut from main at 2a6379c.
- 2026-10-23: T1 and T2 done. The test states the new sentence as `menu_step` beside `rerender_steps`. Its `no-stored-output` assertion failed at line 207 on the old code and passes with the fix; the two `_quarto.yml` absence checks pass on both, as guards. The code adds the sentence inline in `check_stored_output()`, since only one row uses it. `devtools::test(filter = "check-supplement")` passes.
- 2026-10-23: T3 done. The `render:` comment now gives the three steps for a changed report and keeps the README.md or SUPPLEMENT.md pointer. The `resources:` comment says to render the whole site again, then commit `figures/`, `docs/`, and `_freeze/`. `devtools::test(filter = "template")` passes with no failure.
- 2026-10-23: T4 done. The `check_supplement()` bullet gains one sentence on the `_quarto.yml` step, and the publishing-guide bullet gains the commit step; no new bullet.
- 2026-10-23: T5 done. The grep's hits outside the In list either give the full steps (the template guide's parts that M039 fixed, the vignette's last part) or advise on another task: the first publish, DOIs, the release, private files, renv, and the `figures` stop in the example. No new candidate row. `devtools::document()` left no diff. `devtools::test()`: 5021 tests, 0 failed, 8 skipped. `devtools::check()`: 0 errors, 0 warnings, 0 notes, with no exit 139 crash.
- 2026-10-23: claim audit: 11 claims read, 1 corrected — NEWS.md, R/check-supplement.R, inst/template/_quarto.yml, tests/testthat/test-check-supplement.R. The `check_supplement()` NEWS sentence named a wider case than the row text. The one re-read found the first fix implied the row tests the menu, so the sentence now quotes the row's condition.
- 2026-10-23: the NEWS correction landed after `devtools::check()` built its tarball; review's check covers the final text.

## Decisions

## Review
