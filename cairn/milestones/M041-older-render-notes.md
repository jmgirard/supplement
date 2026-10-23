# M041: Correct two older render notes

- **Status:** review
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

- [x] AC1: In `inst/template/_quarto.yml`, the comment above `render:` says that a full render reuses the stored output in `_freeze/` and runs the code of each report that has no stored output there. It keeps the steps for a changed report in the same order (render it by name, render the whole site, then commit it with `_freeze/`, `docs/`, and `figures/`) and the pointer to README.md or SUPPLEMENT.md.
- [x] AC2: In `inst/template/_README.md`, the paragraph in "How the site renders" on a deleted or renamed report gives three steps in this order; the words "first" and "second" need not appear. Step 1: delete the report's folder in `_freeze/analyses/` and remove or change its item in the Analyses menu of `_quarto.yml`. Step 2: run a full render. Step 3: commit the deleted or renamed report with `_quarto.yml`, `_freeze/`, `docs/`, and `figures/`. The paragraph also says that the full render runs the code of a renamed report, so that render needs the report's data, its fit files, and R.
- [x] AC3: A test in `tests/testthat/test-add-render.R` covers a renamed report; a deleted report is not tested. In a rendered site, it renames a report that `add_report()` made, follows AC2's steps 1 and 2 with no render between the rename and those steps, and asserts three facts. (1) `docs/analyses/` holds the page under the new name and not under the old name. (2) `_freeze/analyses/` holds a folder under the new name. (3) `check_supplement()` gives no `broken-link` row. On the same site it then renames the report again and runs a full render with no other step, and asserts two facts. (4) The folder of the name before that rename stays in `_freeze/analyses/`. (5) `check_supplement()` gives a `broken-link` row whose problem names that name's `.qmd`.
- [x] AC4: `devtools::document()` leaves no diff, and `devtools::test()` passes. `devtools::check()` gives 0 errors and 0 warnings, and each NOTE is justified in the Review section. If a template render fails because `_scripts/nojekyll.ts` exits 139, one re-run counts.

## Coverage

- AC1 → T2
- AC2 → T3
- AC3 → T1
- AC4 → T4

## Tasks

- [x] T1: In `tests/testthat/test-add-render.R`, add the test of AC3. Make a site with `create_supplement()`, add a report with `add_report()`, and run a full render. Rename the report file, delete its old folder in `_freeze/analyses/`, change the menu item's `href` in `_quarto.yml` to the new name, and run a full render. Assert facts 1 to 3 of AC3. Rename the report again and run a full render. Assert facts 4 and 5. Run `devtools::test(filter = "add-render")`.
- [x] T2: Rewrite the comment above `render:` in `inst/template/_quarto.yml` (lines 4 to 8). Keep the steps that M040 set and the pointer to README.md or SUPPLEMENT.md. Run `devtools::test(filter = "template")`, because those tests render the template.
- [x] T3: Rewrite the paragraph at lines 250 to 252 of `inst/template/_README.md` to give AC2's steps.
- [x] T4: Run `grep -rn -i -E 'runs no (report )?code|delete or rename|rename a report' R inst/template vignettes README.md NEWS.md`. Read each hit outside the In list that repeats either wrong note, and record it as a new candidate row. Then run `devtools::document()`, `devtools::test()`, and `devtools::check()`. If a template render fails because `_scripts/nojekyll.ts` exits 139, write a work-log line for the row "Trace the post-render crash on macOS".

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
- 2026-10-23: T2 done: the `_quarto.yml` comment now says a full render reuses `_freeze/` and runs the code of each report that has no stored output there; the changed-report steps and the README.md or SUPPLEMENT.md pointer are unchanged. `devtools::test(filter = "template")`: 0 failures, 201 passes.
- 2026-10-23: T3 done: the paragraph in "How the site renders" now gives AC2's three steps as sentences in order and says a renamed report's code runs and needs its data, fit files, and R; two sentences were split after the simple-english lint hook flagged them over its length limit. `devtools::test(filter = "template|publishing")`: 0 failures, 219 passes (run before the split, which changed no test input).
- 2026-10-23: T4 search: `grep` gave two hits, `_README.md:240` (already limits "runs no code" to a report that holds stored output) and `_README.md:250` (the In-list paragraph); no new candidate row. `devtools::document()` left no diff.
- 2026-10-23: claim audit: 10 claims read, 1 corrected — inst/template/_README.md, inst/template/_quarto.yml, tests/testthat/test-add-render.R. The commit step names `figures/` for a deleted report too, though its figures stay published; the paragraph now says so and points to "Paper figures". The reader's four probe cases (rename and delete, each with and without the steps) matched the other 9 claims. The same reader re-read the corrected claim once and found it correct.
- 2026-10-23: T4 done: `devtools::test()` 0 failures, 0 errors, 8 skips, 5025 passes; `devtools::check()` 0 errors, 0 warnings, 0 notes; no nojekyll exit 139. Both ran at 7e2c72f, before the one-sentence guide fix in 6cfbcb0, which changed no code or test. Set status review.
- 2026-10-23: step-7 approval: m041-older-render-notes approved for merge.

## Decisions

## Review

- 2026-10-23: sync: `origin/main` at 09247c3, the branch's base; nothing to merge. No open PR; the Copilot round is off (no `# Copilot review:` line in PROFILE.md).
- AC1 evidence (`git show HEAD:inst/template/_quarto.yml`, lines 4 to 9): the comment reads "A full render reuses it and runs the code of each report that has no stored output there." Lines 7 to 9 keep the changed-report steps in order (render it by name, render the whole site, commit with `_freeze/`, `docs/`, and `figures/`) and the README.md or SUPPLEMENT.md pointer, unchanged from main. Pass.
- AC2 evidence (`git show HEAD:inst/template/_README.md`, lines 250 to 258): the paragraph says, in order, delete its folder in `_freeze/analyses/` and remove or change its Analyses menu item in `_quarto.yml`; run a full render; commit the deleted or renamed report with `_quarto.yml`, `_freeze/`, `docs/`, and `figures/`. It says a renamed report's full render "runs its code, which needs its data, its fit files, and R". Pass.
- AC3 evidence (fresh run at 7e4beb9, `devtools::test(reporter = "silent")`): `test-add-render.R` "the guide's steps after a rename give the page its new name and keep the menu link" ran 12 expectations, 0 failed, not skipped. Its asserts, in order: `comparison.html` present and `models.html` absent in `docs/analyses/` (fact 1), `_freeze/analyses/comparison` present (2), no `broken-link` problem (3); then after the second rename alone, `_freeze/analyses/comparison` still present (4) and a `broken-link` problem containing `analyses/comparison.qmd` (5). Pass.
- AC4 evidence (fresh run at 7e4beb9): `devtools::document()` left `git status` empty; `devtools::test()` 0 failed, 0 errors, 8 skipped, 5025 passed; `devtools::check()` 0 errors, 0 warnings, 0 notes; no nojekyll exit 139. Pass.
- spawned: diff-bug, blame-history, prior-review, ripple.
- diff-bug #1: the private-data recipe's step 3 stages `_quarto.yml` only for an `add_report()` report and names no old path, so a rename's menu edit and old-file deletion go unstaged — fix now, fixed 8b8930a.
- diff-bug #2: "commit the deleted or renamed report" does not say a rename has an old and a new path — fix now, fixed 8b8930a.
- diff-bug #3: `_README.md:13`, `README.md:6`, and `cairn/DESIGN.md:16` still state the unconditional rebuild claim in other words — fix now, fixed 8b8930a.
- diff-bug #4: the delete path and the figures-stay claim have no test — follow-up, row "Test the guide's steps after a deletion".
- diff-bug #5: facts 1 and 2 pass with or without the steps — reject (planned change): AC3 sets them to test the guide's claims that the page takes its new name and the code runs; fact 3 and the control discriminate the steps.
- diff-bug #6: fact 4 has low power — reject (planned change): AC3 requires it as the reason for the folder step.
- diff-bug #7: two test comments restate the code — reject (style).
- diff-bug #8: the precondition `frozen("models")` tests unchanged behavior — reject (false): it pins the state the later `unlink()` step acts on, which the test relies on.
- diff-bug #9: "its folder" is unclear for a rename — fix now, fixed 8b8930a.
- diff-bug #10: the commit list names `figures/` with no leave-out note — reject (false): the paragraph is prose, not a command; the guide's `git add` commands (private-data recipe, publishing guide) carry the note, as for the changed-report paragraph M039 wrote.
- diff-bug #11: no step for other pages that link the old page — reject (false): `check_supplement()`, which "Checks before a release" runs, gives a `broken-link` row for each such link.
- blame-history #1: same as diff-bug #10 — reject (false), same reason.
- blame-history #2 to #4: no regression of M003, M017, M039, or M040 text; D-002 and D-018 hold — noted.
- prior-review #1: the `figures/` leave-out note is missing (LESSONS M039) — reject (false), as diff-bug #10.
- prior-review #2: M040's reason for no note in the YAML comment no longer holds — reject (false): the guide's command recipes still carry the note.
- ripple #1: the private-data recipe stages `_quarto.yml` only after `add_report()` — fix now, with diff-bug #1, fixed 8b8930a.
- ripple #2: changed-report commit lists lack `_quarto.yml` — reject (false): a changed report does not change the menu (M040's choice).
- ripple #3: the example-report `placeholder` row text omits `_freeze/analyses/example/` — follow-up, row "Name stored output in the example row".
- ripple #4: `cairn/DESIGN.md:14-16` — fix now, with diff-bug #3, fixed 8b8930a.
- ripple #5: `_README.md:13` — fix now, with diff-bug #3, fixed 8b8930a.
- ripple #6: `README.md:6-7` — fix now, with diff-bug #3, fixed 8b8930a.
- ripple #7: the test name at `test-template.R:123` overstates the rule — fix now, fixed 8b8930a.
- fixes 8b8930a: `_README.md:13` and `README.md:6` now limit the rebuild claim to reports that hold stored output; `cairn/DESIGN.md` corrected in place (marked); the delete-or-rename paragraph names the folder under the old name and commits the report under its old path and any new path; the private-data recipe stages `_quarto.yml` and the old path for a deleted or renamed report (git 2.54 stages a rename from `git add <old> <new>`, probe 2026-10-23); the test-template name now says "of a report with stored output". AC1 to AC3 text and asserts are unchanged by it; AC2's three steps and sentence still read as recorded above.
- re-run at 8b8930a: `devtools::document()` no diff; `devtools::test()` 0 failed, 0 errors, 8 skipped, 5025 passed; `devtools::check()` 0 errors, 0 warnings, 0 notes; no nojekyll exit 139.
- consistency gate: `cairn_validate.py` all checks passed. No principle changed, so no `cairn_impact` run. Profile checks: `document()` no diff; no README.Rmd and no pkgdown site, so those checks do not apply; no new top-level file. Changelog: no `NEWS.md` entry, as the plan gate chose — the change corrects guide text and a test name, with no change in what any function or template file does, and NEWS lists features; the two NEWS lines on render reuse (34-35) already limit the claim to stored output.
- conversation: no open PR, so no PR-conversation read. Snapshot files changed: none (`git diff --name-only main...HEAD` lists no `_snaps` path). Open-PR feature cap: 0 open PRs of 1.
- ripple #8: `NEWS.md:34-35` and `_README.md:503` — reject (false): both limit the claim to a render from stored output.
- ripple #9: the ROADMAP row still lists the two notes — reject (planned change): hygiene graduates it at merge.
