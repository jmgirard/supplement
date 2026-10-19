# M017: The template publishes paper figures from a figures folder

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes the template that `create_supplement()` copies into new sites
- **Branch/PR:** m017-paper-figures

## Goal

A site made from the template has a `figures/` folder that git tracks and the site publishes, and the example report shows how a report saves a figure there.

## Scope

**In:** `"figures/**"` in `project.resources` of `inst/template/_quarto.yml`; a chunk in `inst/template/analyses/example.qmd` that saves its bootstrap histogram to `../figures/bootstrap-means.png`, making the folder when it is missing; a "Paper figures" section and a `figures/` line in the Contents list of `inst/template/_README.md`; template tests; a NEWS.md entry; DESIGN.md's template layout.

**Out:** changes to the `analyses/*.pdf` and `analyses/*.png` ignore rules, which stay. A link to the figures from the home page → not planned. A check in `check_supplement()` for figures outside `figures/` → not planned. Sites made before this change (no migration) → candidate row "existing-site migration".

## Acceptance criteria

- [x] AC1: In a new site made from the template and set up by its first render, `git check-ignore` finds neither `figures/plot.pdf` nor `figures/plot.png` ignored, and finds `analyses/plot.pdf` and `analyses/plot.png` ignored. A test in `tests/testthat/test-template.R` asserts the four results and skips when git, Quarto, or R is missing.
- [x] AC2: In a new site made from the template, after `quarto render analyses/example.qmd` and then `quarto render`, the files `figures/bootstrap-means.png` and `docs/figures/bootstrap-means.png` exist and start with the PNG signature bytes. A test in `tests/testthat/test-template.R` asserts this and skips without Quarto or R.
- [x] AC3: `inst/template/_README.md` lists `figures/` in its Contents list and has a section that says where to save paper figures, how a report in `analyses/` writes there (`file.path("..", "figures", ...)`), that after a render saves a figure under a new name, the site must be rendered again before `docs/` holds it, that `figures/` must be committed, the web address of a figure (`https://OWNER.github.io/REPO/figures/<name>`), and that PNG and PDF files saved directly in `analyses/` are not committed, because git ignores `analyses/*.png` and `analyses/*.pdf`.
- [x] AC4: NEWS.md has an entry for the `figures/` folder.
- [x] AC5: `Rscript -e 'devtools::test()'` reports no failure.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T3
- AC5 → T2, T3

## Tasks

- [x] T1: Write the tests of AC1 and AC2 in `tests/testthat/test-template.R` (reuse `new_site()` from `helper-files.R:52` and `run_in()` from `helper-template.R`), and see the AC2 test fail against the current template. The AC1 test passes before the change too, as a guard that `figures/` stays out of the ignore rules.
- [x] T2: Add `"figures/**"` to `project.resources` in `inst/template/_quarto.yml` and the figure chunk to `inst/template/analyses/example.qmd`; run the tests to green with git, Quarto, and R available, so that no test of AC1 or AC2 skips, and check that a new site with no `figures/` folder still renders.
- [x] T3: Write the README section and Contents line, add `figures` to the README's commit steps, fix the `_quarto.yml` resources comment, and write the NEWS.md entry and the DESIGN.md template layout; run `devtools::test()`.

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: not run — work named at the question set.
- 2026-10-19: question set: what to plan — release from subfolder, YAML parse errors, paper figure files.
- 2026-10-19: absorbed candidate row "paper figure files" in full.
- 2026-10-19: plan chose a top-level `figures/` folder published through `project.resources` over removing the `analyses/*.pdf` and `analyses/*.png` ignore rules, because those rules keep files that a render writes next to its source out of git, and a published folder has a stable web address; falsified by a Quarto version that does not copy a `resources` glob into `docs/`.
- 2026-10-19: plan chose to make the folder from the example report over shipping a placeholder file in `figures/`, because `quarto use template` skips dotfiles (M003 lesson) and a README there would be published; falsified by a render that fails when `figures/` is missing.
- 2026-10-19: inbox sweep: 0 open issues, 0 open PRs. Collision sweep: D-001 (render into `docs/`), D-002 (freeze), and D-006 (setup merges `.gitignore`) stand and are not touched.
- 2026-10-19: lessons harvested: M001 (`quarto render <file>` runs that file's code), M002 (figure bytes change between renders), M003 (ignore rules are case-sensitive; template setup merges `.gitignore`).
- 2026-10-19: criteria audit (full mode, fresh Opus reader, shared with M015 and M016): a test project showed one full render of a new site writes `figures/b.png` but copies it to `docs/` only on the next render. Taken narrower: AC2 keeps the render-by-name-then-full order, and AC3 makes the README say a figure reaches `docs/` on the next full render. AC1 passes before the change, so T1 keeps it as a guard, and it now also skips without Quarto or R. "Made with `create_supplement()`" became "made from the template", as the test helpers use `quarto use template`; T1's `new_site()` path fixed; T2 runs with no skip.
- 2026-10-19: started implementation on branch m017-paper-figures, cut from origin/main at e447c97.
- 2026-10-19: implement chose `site_copy()` (a site made with `quarto use template` and set up by one full render) for the AC1 test and a fresh `use_template()` site for the AC2 test, in place of `new_site()`, which calls `create_supplement()` and does not render; AC2 needs its own site because the shared site's one full render does not copy the figure into `docs/`.
- 2026-10-19: T1 done: two tests in `test-template.R`. Against the current template the AC1 test passes and the AC2 test fails at `figures/bootstrap-means.png` not existing (both paths).
- 2026-10-19: implement chose a base-graphics `png()` device at 6 x 4 in, 300 dpi, with `dir.create(showWarnings = FALSE)`, in a new "Paper Figures" section of the example report; ggplot2 is not a template dependency.
- 2026-10-19: T2 done: `"figures/**"` in `project.resources` and the figure chunk. Template tests pass with git, Quarto 1.10.19, and R present, no skips; a fresh site with no `figures/` renders (status 0), its first full render writes `figures/bootstrap-means.png` but no `docs/figures/`, and the second copies it. Full suite: 0 failures, 1 skip (case-insensitive disk).
- 2026-10-19: T3 probes (Quarto 1.10.19, scratch site): a render copies to `docs/` the files that are in `figures/` when it begins, after the report code runs. A new figure name reaches `docs/` on the next render, by name (`analyses/example.qmd`) or full; a changed figure under an existing name reaches `docs/` in the same render; a PNG in `analyses/` that no page links is not in `docs/`. So AC3's "a new or changed figure reaches `docs/` only on the next full render" is false, and the T2 comment in `_quarto.yml` says the same and needs the fix in T3.
- 2026-10-19: re-audit: AC3 (full) — proposed "a figure saved under a new name reaches `docs/` only on a render after the one that saved it" and "figures saved in `analyses/` are not published": the render-by-name case was not probed, "new name" is ambiguous, the clause gives no step to take, and "not published" covers more than one unlinked PNG; fixed to "whose file was not in `figures/` when a render began … only on a later render, by name or full" and "not committed, because git ignores `analyses/*.png` and `analyses/*.pdf`".
- 2026-10-19: re-audit: AC3 (full) — fixed wording: "not committed" covers file types and folders the two rules miss (`.svg`, `.PNG`, `analyses/sub/x.png`), and "by name or full" was probed only for `analyses/example.qmd`. Second re-audit line on AC3, so the wording goes to the user.
- 2026-10-19: substantive amendment: AC3 now asks the README to say that after a render saves a figure under a new name, the site must be rendered again before `docs/` holds it, and that PNG and PDF files saved directly in `analyses/` are not committed, because git ignores `analyses/*.png` and `analyses/*.pdf`. The user chose this wording at the stop. T3 also fixes the `_quarto.yml` resources comment and the README's commit steps, which name only `_freeze/` and `docs/` (minor amendment).
- 2026-10-19: T3 done: README "Paper figures" section after "Stable figures", a `figures/` Contents line, `figures` in both commit steps; `_quarto.yml` comment says to render again after a new figure name; NEWS entry; DESIGN template layout. The NEWS entry leaves out "not published" for `analyses/` figures, because a figure a page links is copied. Full suite: 0 failures, 1 skip (case-insensitive disk).
- 2026-10-19: claim audit: 19 claims read, 0 corrected — NEWS.md, inst/template/_README.md, inst/template/_quarto.yml, inst/template/analyses/example.qmd, tests/testthat/test-template.R. The reader noted that `analyses/plot.PNG` is not ignored on a case-sensitive git (left as is; the README names lowercase rules).
- 2026-10-19: the claim auditor's template test run failed once in "setup keeps both files when README.md and SUPPLEMENT.md exist" (`quarto render` exited 1, a test this branch does not touch); two later template runs passed. Added to the "template test flake" candidate row.
- 2026-10-19: implement done; status review.

## Decisions

## Review

- AC1: `devtools::test()` at d75ca70 with git, Quarto 1.10.19, knitr, and rmarkdown present: ".gitignore keeps figures/ and blocks figures saved in analyses/" ran 3 expectations, 0 failed, not skipped. It asserts `check-ignore` lists exactly `analyses/plot.pdf` and `analyses/plot.png`, and exits 1 with no output for `figures/plot.pdf` and `figures/plot.png`, on a site from `quarto use template` set up by one full render. Planting `figures/*.png` in `inst/template/_gitignore` turned it red (2 failures); reverted.
- AC2: same run: "the example report saves a figure that the next full render publishes" ran 8 expectations, 0 failed, not skipped. On a fresh `quarto use template` site it runs `quarto render analyses/example.qmd` then `quarto render` (both status 0) and asserts `figures/bootstrap-means.png` and `docs/figures/bootstrap-means.png` exist and their first 8 bytes equal the PNG signature `89 50 4E 47 0D 0A 1A 0A`. Before T2 the same test failed on both files missing (work log, T1).
- AC3: read `inst/template/_README.md` at d75ca70. Contents line 12 lists `figures/`. The "Paper figures" section (line 264) says: save each paper figure in `figures/`; a report writes there as `file.path("..", "figures", ...)`; after a render saves a figure under a new name, run `quarto render` again so that `docs/` holds it; commit `figures/` with `_freeze/` and `docs/`; a figure's web address, given as `https://OWNER.github.io/REPO/figures/model-fit.png` (the form `https://OWNER.github.io/REPO/figures/<name>` with an example name); PNG and PDF files saved directly in `analyses/` are not committed, because `.gitignore` blocks `analyses/*.png` and `analyses/*.pdf`.
- AC4: `NEWS.md` line 102, under the development heading, has an entry starting "The template publishes paper figures from a `figures/` folder". No milestone numbers in it.
- AC5: `devtools::test()` at d75ca70: 243 tests, 2735 expectations, 0 failed, 0 errors, 1 skipped ("on a case-sensitive disk, any file in data/ that differs only in letter case stops": the disk is case-insensitive).
- Gate: `cairn_validate.py` all checks passed (exit 0). No principle changed, so `cairn_impact` skipped. `devtools::document()` gave no diff. No README.Rmd and no pkgdown site. NEWS.md has the entry (AC4). No new top-level files. `devtools::check()`: 0 errors, 0 warnings, 0 notes (3m 39s).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the README's `png()` example has no `dir.create()`, and the template has no `figures/` until the example report runs, so a pasted example fails in a site without it — fix now, fixed 9dbe48c (README example adds `dir.create()` and says why)
- diff-bug #2: under freeze, a clone with no committed `figures/` renders without `docs/figures/`, and `check_supplement()` is silent — follow-up ("figures folder edge cases")
- diff-bug #3: the `create_supplement()` message says to render once before the first commit, but that render leaves no `docs/figures/` — follow-up ("figures folder edge cases"; R message outside scope)
- diff-bug #4: DESIGN.md said a render copies `figures/` at its start, but it copies after the report code runs — fix now, fixed 9dbe48c (DESIGN wording)
- diff-bug #5: `figures/**` publishes every file in the folder, and no text says so — fix now, fixed 9dbe48c (README: every file in `figures/` is published)
- diff-bug #6: a renamed or deleted figure stays published, and the README does not say how to take it off — fix now, fixed 9dbe48c (README: delete it and run a full render; probe: a full render removed it, a render by name did not)
- diff-bug #7: the AC2 test checks only the PNG signature, not the image — reject (planned change: AC2 names the signature bytes, and a fresh site has no other PNG)
- diff-bug #8: with `execute-dir: project` the `..` path writes outside the site — follow-up ("figures folder edge cases")
- diff-bug #9: `dir.create(showWarnings = FALSE)` hides a file named `figures` — follow-up ("figures folder edge cases")
- blame-history #1: setup's `!docs/` and `!_freeze/` tail has no `figures/` line, so an existing `*.png` or `figures/` rule hides the folder (D-006 intent) — follow-up ("figures folder edge cases"; setup.ts and its pinned tests outside scope)
- blame-history #2: a figure from a deleted or renamed report stays on the site — fix now, fixed 9dbe48c (same README line as diff-bug #6)
- blame-history #3: the private-data steps render by name, then stage `figures/`, so a new figure name is not yet in `docs/` — fix now, fixed 9dbe48c (step 2 says to render again after a new figure name)
- blame-history #4: no warning that figures made from private data are published — fix now, fixed 9dbe48c (the README's "every file in `figures/` is published, so keep drafts and private files out of it")
- blame-history #5: the example's `png()` has no `on.exit()` guard — follow-up ("figures folder edge cases")
- blame-history #6: committed figures can change between machines, and "Publishing from one machine" does not say so — reject (false: "Stable figures" says every render that runs a report's code redraws its figures, and only such a render writes `figures/`)
- blame-history #7: existing sites get no `figures/` resource — reject (planned change: Scope Out, "existing-site migration" row)
- prior-review #1: `analyses/*.png` and `analyses/*.pdf` match lower case only on Linux, against the M003 lesson, so the README's "not committed" fails for `plot.PNG` there — fix now, fixed 9dbe48c (README says Git on Linux reads these rules in lower case only) and follow-up for bracket patterns ("figures folder edge cases"; the rules are Scope Out)
- ripple #1: setup.ts, `_gitignore`, and the README describe only `!docs/` and `!_freeze/` as kept output — follow-up (same as blame-history #1)
- ripple #2: `LICENSE-CC-BY.md` and the README License section list content without `figures/` — fix now, fixed 9dbe48c (both list figures in `figures/` as content)
- ripple #3: `release_supplement()` help says `docs/` and `_freeze/` reach the release — fix now, fixed 9dbe48c (adds `figures/`; `man/` regenerated)
- ripple #4: the "paper figure files" candidate row is still open — reject (planned change: post-merge hygiene graduates it)
- Return floor: no finding shows a criterion failing or a load-bearing defect; no return.

