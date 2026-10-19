# M017: The template publishes paper figures from a figures folder

- **Status:** in-progress
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

- [ ] AC1: In a new site made from the template and set up by its first render, `git check-ignore` finds neither `figures/plot.pdf` nor `figures/plot.png` ignored, and finds `analyses/plot.pdf` and `analyses/plot.png` ignored. A test in `tests/testthat/test-template.R` asserts the four results and skips when git, Quarto, or R is missing.
- [ ] AC2: In a new site made from the template, after `quarto render analyses/example.qmd` and then `quarto render`, the files `figures/bootstrap-means.png` and `docs/figures/bootstrap-means.png` exist and start with the PNG signature bytes. A test in `tests/testthat/test-template.R` asserts this and skips without Quarto or R.
- [ ] AC3: `inst/template/_README.md` lists `figures/` in its Contents list and has a section that says where to save paper figures, how a report in `analyses/` writes there (`file.path("..", "figures", ...)`), that a new or changed figure reaches `docs/` only on the next full render after the report saved it, that `figures/` must be committed, the web address of a figure (`https://OWNER.github.io/REPO/figures/<name>`), and that figures saved in `analyses/` are not published.
- [ ] AC4: NEWS.md has an entry for the `figures/` folder.
- [ ] AC5: `Rscript -e 'devtools::test()'` reports no failure.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T3
- AC5 → T2, T3

## Tasks

- [x] T1: Write the tests of AC1 and AC2 in `tests/testthat/test-template.R` (reuse `new_site()` from `helper-files.R:52` and `run_in()` from `helper-template.R`), and see the AC2 test fail against the current template. The AC1 test passes before the change too, as a guard that `figures/` stays out of the ignore rules.
- [x] T2: Add `"figures/**"` to `project.resources` in `inst/template/_quarto.yml` and the figure chunk to `inst/template/analyses/example.qmd`; run the tests to green with git, Quarto, and R available, so that no test of AC1 or AC2 skips, and check that a new site with no `figures/` folder still renders.
- [ ] T3: Write the README section and Contents line, the NEWS.md entry, and the DESIGN.md template layout; run `devtools::test()`.

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

## Decisions
