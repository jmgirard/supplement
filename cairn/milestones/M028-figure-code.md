# M028: The template saves paper figures safely in more setups

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the template that `create_supplement()` copies into each author's site
- **Branch/PR:** m028-figure-code

## Goal

A new site's first render publishes the example figure, and the example's figure code works with `execute-dir: project`, a failed plot, a file named `figures`, and upper-case file extensions.

## Scope

**In:** `inst/template/figures/bootstrap-means.png` (new), the `data` and `save-figure` chunks of `inst/template/analyses/example.qmd`, the `analyses/*.png` and `analyses/*.pdf` rules in `inst/template/_gitignore`, the "Paper figures" section of `inst/template/_README.md`, NEWS.md, and tests in `tests/testthat/test-template.R`.

**Out:** the two `check_supplement()` rows for ignored site files and for figures that a render did not publish → M029. The `quarto use template` route is not tested for the shipped figure, as for the other template files. Image types other than `.png` and `.pdf` next to reports keep no ignore rule, as now.

## Acceptance criteria

- [x] AC1: The template ships `figures/bootstrap-means.png`. A test in `tests/testthat/test-template.R` makes a site with `create_supplement()` and runs one full `quarto render`. Then `docs/figures/bootstrap-means.png` exists and has the same MD5 as `figures/bootstrap-means.png`.
- [x] AC2: The `data` and `save-figure` chunks of `analyses/example.qmd` build their paths from `QUARTO_PROJECT_DIR`, and from `..` when it is not set. A test renders a new site in two setups: with the template's `_quarto.yml`, and with `execute-dir: project` added to it. In each setup the render succeeds, `figures/bootstrap-means.png` is in the site, and the parent folder of the site holds no `figures/` folder. A third case runs the code of both chunks from `analyses/` with `QUARTO_PROJECT_DIR` not set, and the figure is in the site's `figures/`.
- [x] AC3: If the plotting call in the `save-figure` chunk fails, the chunk closes the graphics device that it opened. It also leaves `figures/` with the same file names and MD5s as before the chunk ran. A test takes the code of the chunk from `analyses/example.qmd` by its label and runs it in a site folder with `hist()` replaced by a function that stops. It runs once with no `figures/bootstrap-means.png` and once with an earlier one. It checks `grDevices::dev.list()` and the names and MD5s of the files in `figures/`.
- [x] AC4: If the site holds a file named `figures`, the `save-figure` chunk stops before it opens a graphics device, with an error that says that `figures` is a file, not a folder. A test renders such a site, checks that the render fails, and matches that phrase in the render output. The same test fails on main, where the error reads "unable to open file".
- [x] AC5: The template's rules for figures next to reports match any mix of letter case. The test uses two sites made by `create_supplement()` and rendered once: one that is a git repository before its first render, and one where `git init` comes after it. In each, `git -c core.ignorecase=false check-ignore` reports `analyses/a.PNG`, `analyses/b.Pdf`, `analyses/c.png`, and `analyses/d.pdf` as ignored. It reports `figures/e.PNG` and `figures/f.PDF` as not ignored.
- [x] AC6: The "Paper figures" section of `inst/template/_README.md` says that the template ships the example figure, shows the `QUARTO_PROJECT_DIR` path form of AC2, and says that the rules match any letter case. It no longer says that git on Linux reads the rules in lower case only. The NEWS.md bullet for the template's paper figures states the same three changes.
- [ ] AC7: `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T3
- AC2 → T2, T3
- AC3 → T2, T3, T7
- AC4 → T2, T3
- AC5 → T4, T7
- AC6 → T5
- AC7 → T3, T4, T5, T6

## Tasks

- [x] T1: Render the example report in a scratch site and copy its `figures/bootstrap-means.png` to `inst/template/figures/`. Check that `template_files()` (`R/create-supplement.R:131`) lists it and that `R CMD build` keeps it. The README text "the template has no `figures/` folder until a report makes it" (`_README.md:284`) changes in T5.
- [x] T2: Rewrite the two chunks of `analyses/example.qmd` (lines 12 and 35). Take the site folder from `Sys.getenv("QUARTO_PROJECT_DIR", "..")`. Stop with the AC4 error when `figures` exists and is not a folder. Write the PNG to a temporary file inside `local()` with `on.exit(dev.off())`, and copy it into `figures/` only after the plot succeeds. Keep the chunk short, because authors copy it.
- [x] T3: Add the AC1 to AC4 tests beside the figure test at `tests/testthat/test-template.R:194`, with `skip_if_no_quarto()`. Run each against the template on main and record that each fails there (LESSONS M010). For AC3, take the chunk code with `knitr` (a Suggests package) or a label match, not by line numbers.
- [x] T4: Spell the two rules in `inst/template/_gitignore` with bracket patterns, as for `.rds` (LESSONS M003). Extend the tests at `test-template.R:179` and `:251` for AC5, with `-c core.ignorecase=false` on every `check-ignore` (macOS and Windows default to true).
- [x] T5: Edit the "Paper figures" section of `inst/template/_README.md` (lines 272 to 301) and the NEWS.md template bullet. Each statement comes from a T3 or T4 test run in this branch (the derived-claims rule).
- [x] T6: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.
- [x] T7: Review return 1. Build both AC5 sites with `create_supplement()`, one with `git init` after the first render and one before it. Apply the fix-now items of the Review section: `save_png(file, draw, dir = figures)` calls `draw()`, writes a hidden temporary file in `figures/`, renames it into place, stops on a folder at the target, and restores the earlier device; the `save-figure` chunk defines `site` itself; `skip_on_cran()` and the CI `missing_tool` reason for the png tests; DESIGN.md:163-165; NEWS wording and width.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: what to work on — the candidate row "Fix edge cases of the figures folder", planned as M028 (template) and M029 (check rows).
- 2026-10-20: question set: a new site's first render misses the example figure — ship the figure in the template and add the M029 `unpublished-figure` row.
- 2026-10-20: absorbed the candidate row "Fix edge cases of the figures folder" in full, split between M028 and M029. Its first and third parts (an uncommitted `figures/` under freeze, and ignore rules that keep `figures/` out of git) go to M029's `ignored-output` row.
- 2026-10-20: plan gate chose shipping the example figure over a setup message that says to render twice, because the first render then publishes the figure with no extra step; falsified by a Quarto version that copies resources before the report code runs, or that skips a resource whose bytes change during the render.
- 2026-10-20: plan chose `QUARTO_PROJECT_DIR` over the `here` package (a new dependency) and over `knitr::opts_knit$set(root.dir)` (which changes every chunk); falsified by a Quarto version that does not set it for knitr. Probe on Quarto 1.10.19: it is set for a full render, a render by name, and a render run from `analyses/`.
- 2026-10-20: collision check: M017 shipped the figures folder; this extends it. D-006 (setup appends only) is not touched. No other row, milestone, or D-entry overlaps.
- 2026-10-20: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-20: lessons surfaced: M017 (resources are listed at the start of a render, so new bytes under an existing name are copied in the same render), M003 (bracket patterns), M010 (prove a test fails on main), M018 (8.3 short names on the Windows runner).
- 2026-10-20: changelog: the existing 0.0.0.9000 bullet for the template's paper figures gets the change, with no new bullet.
- 2026-10-20: criteria audit (full mode, fresh Opus reader): 10 findings over M028 and M029, all taken. For M028: AC2 adds the `data` chunk, because its `..` path fails first under `execute-dir: project`, and adds a run with `QUARTO_PROJECT_DIR` not set. AC3 compares all of `figures/`, so a temporary file there cannot pass. AC4 matches a phrase that main does not print. AC5 uses `core.ignorecase=false` and both setup paths. AC6 names its claims in place of a review promise. The `quarto use template` gap went to Out.
- 2026-10-20: T1: added `inst/template/figures/bootstrap-means.png` (86,686 bytes, from a render by name of the current example on macOS). `template_files()` lists it; `.Rbuildignore` and `.gitattributes` (`text=auto`) leave it as it is.
- 2026-10-20: T2: the `data` chunk sets `site <- Sys.getenv("QUARTO_PROJECT_DIR", "..")`. The `save-figure` chunk stops when `figures` is a file and defines `save_png(file, plot)`, which draws into a `tempfile()` PNG, closes that device in `tryCatch(finally =)`, and then copies the file into `figures/`, stopping if the copy fails. A full render with `execute-dir: project` wrote `figures/` inside the site; a file named `figures` stopped the render with the new message. A full render on macOS wrote the same bytes as the shipped figure.
- 2026-10-20: T3: added five tests in `test-template.R` (first render publishes the figure; both `execute-dir` setups; the code run by hand from `analyses/` with `QUARTO_PROJECT_DIR` unset; a failed plot; a file named `figures`) and the helpers `chunk_code()` (a label match) and `folder_md5()`. The older figure test now removes the shipped figure first. With `NOT_CRAN=true`, all 23 tests in the file pass. With main's `example.qmd` and no shipped figure, the first-render, `execute-dir`, failed-plot, and `figures`-file tests fail; the by-hand test passes there too, because main's `..` path works from `analyses/`.
- 2026-10-20: T4: `_gitignore` now has `analyses/*.[Pp][Dd][Ff]` and `analyses/*.[Pp][Nn][Gg]`, with a comment pointing to `figures/`. `expect_figure_rules()` in `helper-template.R` runs `check-ignore` with `core.ignorecase=false` in the rename-path test and the git-init-first test. 126 expectations pass; with main's `_gitignore` both tests fail.
- 2026-10-20: T5: rewrote the "Paper figures" section of `_README.md` (the `QUARTO_PROJECT_DIR` path, `save_png()`, the `figures`-file stop, the shipped figure, the any-case rules) and the NEWS.md figures bullet; each statement rests on a T3 or T4 test. Left the `file.path("fits", ...)` advice at `_README.md:238`, which is outside this scope.
- 2026-10-20: T6: added `figures/bootstrap-means.png` to `template_tracked` in `test-create-supplement.R`, whose four file-list checks failed on the new template file. With `NOT_CRAN=true`, `devtools::test()` ran 288 tests, 4355 expectations, 0 failed, 7 skipped. `devtools::document()` gave no diff. `devtools::check()` gave 0 errors, 0 warnings, 0 notes. Moved the `_problems/` files that the failed runs wrote out of the tree.
- 2026-10-20: claim audit: 38 claims read, 4 corrected — NEWS.md, inst/template/_README.md, tests/testthat/test-template.R, tests/testthat/helper-template.R. The `figures`-file stop happens only when the report's code runs, not in a full render that reuses `_freeze/`; two comments were made exact. The re-read found all four hold.
- 2026-10-20: all tasks done; after the audit fixes `devtools::test()` (`NOT_CRAN=true`) ran 288 tests, 4355 expectations, 0 failed. Status set to review.
- 2026-10-20: review return 1: AC5 — the tests at `test-template.R:179` and `:344` build their sites with `quarto use template`, not with `create_supplement()` as AC5 states (diff-bug #4). The same round carries the fix-now items listed in the Review section.
- 2026-10-20: minor amendment: added T7 for review return 1 and mapped AC3 and AC5 to it; unticked AC5, whose evidence came from the wrong setup. Two follow-up rows added: "Make report paths work from any folder" and "Stop the example at a linked figures".
- 2026-10-20: T7 checkpoint: `save_png(file, draw, dir = figures)` renames a hidden temporary file in `figures/` into place, stops on a folder at the target, and restores the earlier device; the `save-figure` chunk defines `site`; new test "the figure rules hold in sites made by create_supplement()"; `skip_on_cran()` on the two png tests and "R has no png device" in the CI list; DESIGN.md, README, and NEWS updated. A probe drew a ggplot through `function() print(p)`. All 24 tests in `test-template.R` pass; with main's `example.qmd` the execute-dir, failed-plot, and `figures`-file tests fail, and with main's `_gitignore` the new AC5 test fails. Full suite and `R CMD check` still running.
- 2026-10-20: T7 done: `NOT_CRAN=true devtools::test()` ran 289 tests, 4365 expectations, 0 failed, 7 skipped; `devtools::document()` gave no diff; `devtools::check()` gave 0 errors, 0 warnings, 0 notes.
- 2026-10-20: claim audit: 21 claims read, 0 corrected — inst/template/analyses/example.qmd, inst/template/_README.md, NEWS.md, cairn/DESIGN.md, tests/testthat/test-template.R, .github/workflows/R-CMD-check.yaml (the lines T7 added).
- 2026-10-20: all tasks done; status set to review.
- 2026-10-20: step-7 approval: m028-figure-code approved for merge

## Decisions

## Review

- 2026-10-20: sync: `origin/main` has not moved since the branch was cut; no merge needed. Copilot round off (no `# Copilot review:` line in PROFILE.md).
- AC1: `test-template.R:210` "the first full render of a new site publishes the example figure" passed (3 expectations) in a fresh `NOT_CRAN=true` run of the file, 2026-10-20; it failed with main's template (T3 log line).
- AC2: in the same run, `test-template.R:231` (full render with the template's `_quarto.yml` and with `execute-dir: project`, the shipped figure removed first; figure in the site, no `figures/` in the parent) passed, 6 expectations, and `test-template.R:248` (the three chunks run from `analyses/` with `QUARTO_PROJECT_DIR` unset) passed, 2 expectations. Both chunks read `Sys.getenv("QUARTO_PROJECT_DIR", "..")` (`example.qmd` data chunk). The execute-dir test failed with main's template.
- AC3: in the same run, `test-template.R:266` (the `save-figure` code taken by label, `hist()` replaced by a function that stops, with and then without the shipped figure; `dev.list()` and `folder_md5()` of `figures/` unchanged) passed, 7 expectations; it failed with main's template.
- AC4: in the same run, `test-template.R:295` (a file named `figures`; `quarto render analyses/example.qmd` fails and its output holds "`figures` is a file, not a folder") passed, 2 expectations. The check sits before `png()` in the chunk. It failed with main's template.
- AC5: in the same run, `expect_figure_rules()` (`helper-template.R`, `core.ignorecase=false`; `analyses/a.PNG`, `b.Pdf`, `c.png`, `d.pdf` ignored, `figures/e.PNG`, `f.PDF` kept) passed in `test-template.R:179` (`git init` after the first render) and `:344` (`git init` before it). Both failed with main's `_gitignore` (T4 log line).
- AC6: read at the branch head: the "Paper figures" section of `inst/template/_README.md` says the template ships `figures/bootstrap-means.png`, shows `site <- Sys.getenv("QUARTO_PROJECT_DIR", "..")`, and says `.gitignore` blocks the files "in any letter case"; `grep` finds no "Linux" in the section. The NEWS.md figures bullet (lines 113 to 123) states the shipped figure, the `QUARTO_PROJECT_DIR` path, and "in any letter case".
- AC7 (local part): `NOT_CRAN=true devtools::test()` ran 288 tests, 4355 expectations, 0 failed, 0 errors, 7 skipped; `devtools::check()` gave 0 errors, 0 warnings, 0 notes (2026-10-20, branch head 63b803c). The CI part waits for the PR at step 8; the box is ticked only after the three CI jobs pass.
- gate: `cairn_validate.py` all checks passed. `devtools::document()` gave no diff. No generated file was hand-edited. README.md has no README.Rmd; no pkgdown site. NEWS.md has the entry (no milestone numbers). No new top-level file. No principle changed, so `cairn_impact` is skipped.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: `save_png()` only forces `plot`, so a ggplot or lattice object draws nothing and gives "Could not write" — fix now (take a drawing function).
- diff-bug #2: `file.copy(overwrite = TRUE)` truncates the old figure before it copies, so a failed copy leaves a partial file; a folder at the target path gets the file copied into it — fix now (temporary file in `figures/`, then `file.rename()`; stop on a folder).
- diff-bug #3: `cairn/DESIGN.md:163-165` still says the template ships no `figures/` folder — fix now.
- diff-bug #4: AC5 says the two sites are made by `create_supplement()`, but both tests use `quarto use template` — floor return (the criterion's named setup is not what the tests ran).
- diff-bug #5: the README `fits` advice `file.path("fits", ...)` points at `site/fits/` under `execute-dir: project` — follow-up, row "Make report paths work from any folder".
- diff-bug #6: an empty `QUARTO_PROJECT_DIR` gives `/data` and `/figures` — follow-up, row "Make report paths work from any folder".
- diff-bug #7: the `..` fallback is wrong when an IDE runs chunks from the site folder — follow-up, row "Make report paths work from any folder".
- diff-bug #8: other platforms rewrite the shipped PNG with other bytes — reject (false as a change: before this branch the example rewrote the same tracked file on each render; the README's "Publishing from one machine" section covers it).
- diff-bug #9: `save_png()` reads `figures` from its enclosing environment — fix now (a `dir = figures` argument).
- diff-bug #10: `dev.off(device)` does not restore the device that was current before — fix now (save and restore it).
- diff-bug #11: a `figures` link, or a broken link, makes the example write outside the site or gives the wrong message — follow-up, row "Stop the example at a linked figures".
- diff-bug #12: the two new png tests run on CRAN and their skip reason is not in the CI `missing_tool` list — fix now (`skip_on_cran()`; add the reason to `.github/workflows/R-CMD-check.yaml`).
- diff-bug #13: the by-hand test also passes on main — reject (planned change: the plan's AC2 third case guards the fallback; the T3 log records it).
- diff-bug #14: the failed-plot test does not check the temporary PNG — fix now (with #2 the temporary file sits in `figures/`, which `folder_md5()` reads with hidden files).
- diff-bug #15: NEWS "now in any letter case" applies only to new sites — fix now (say new sites).
- diff-bug #16: NEWS.md:118 is 82 characters wide — fix now.
- blame-history #1: DESIGN.md:164-165 stale — fix now (same as diff-bug #3).
- blame-history #2: shipping the figure reverses M017 with no D-entry — reject (false: the choice is milestone-local and the plan's rejected-alternative line records it).
- blame-history #3: the shipped PNG is rewritten on other platforms — reject (same as diff-bug #8).
- blame-history #4: the `save-figure` chunk uses `site` from the data chunk, so the chunk copied alone fails — fix now (define `site` in the chunk; the AC3 test stops setting it).
- blame-history #5: a junction or link named `figures` is written through — follow-up, row "Stop the example at a linked figures".
- blame-history #6: an empty `QUARTO_PROJECT_DIR` — follow-up (same as diff-bug #6).
- blame-history #7: the removed test line and README claim — no change needed (it says they were removed on purpose).
- blame-history #8: older sites keep the old lower-case lines beside the new ones — reject (planned change: D-006 appends only; NEWS now says new sites).
- prior-review #1: the copy can cut the old figure short — fix now (same as diff-bug #2).
- prior-review #2: DESIGN.md stale — fix now (same as diff-bug #3).
- prior-review #3: a linked `figures/` is written through — follow-up, row "Stop the example at a linked figures".
- prior-review #4: platform bytes — reject (same as diff-bug #8).
- ripple #1: DESIGN.md stale — fix now (same as diff-bug #3).
- ripple #2: the `add_report()` stub (`R/add-report.R:192-193`) still writes `file.path("..", "data", ...)` — follow-up, row "Make report paths work from any folder".
- ripple #3: the README `fits` advice under `execute-dir: project` — follow-up (same as diff-bug #5).
- pass 1 fix-now items diff-bug #1, #2, #3, #9, #10, #12, #14, #15, #16, blame-history #1, #4, prior-review #1, #2, and ripple #1 — fixed 47199b9 (T7).
- 2026-10-20 pass 2: sync: `origin/main` has not moved. The head db75c2c differs from 47199b9, the tree the T7 runs tested, only under `cairn/`, so those runs are this head's evidence.
- AC3 (pass 2): with the T7 code, `test-template.R` "a failed plot in the example closes its device and leaves figures/ as it was" passed (7 expectations; the chunk now runs alone with `QUARTO_PROJECT_DIR` unset, and `folder_md5()` reads hidden files); with main's `example.qmd` it failed.
- AC5 (pass 2): `test-template.R` "the figure rules hold in sites made by create_supplement()" passed (10 expectations): one `create_supplement()` site with `git init` after the first render and one before it, each through `expect_figure_rules()` with `core.ignorecase=false`. With main's `_gitignore` it failed (2 failures).
- AC7 (local part, pass 2): on the T7 tree, `NOT_CRAN=true devtools::test()` ran 289 tests, 4365 expectations, 0 failed, 7 skipped; `devtools::check()` gave 0 errors, 0 warnings, 0 notes. CI waits for the PR.
- gate (pass 2): `cairn_validate.py` all checks passed; `devtools::document()` gave no diff; NEWS.md entry present; no new top-level file.
- spawned: diff-bug, blame-history, prior-review, ripple (pass 2)
- diff-bug #1 (pass 2): a hidden `.save-*.png` left by a hard kill is copied to `docs/figures/` and committed — fix now (`_gitignore` rule `.save-*.png`, checked in `expect_figure_rules()` for `figures/` and `docs/figures/`; README says so).
- diff-bug #2 (pass 2): no test for the device restore or the folder-at-target stop — fix now (a `dev.cur()` check in the by-hand test; new test "save_png() refuses a folder at its target and a plot that is not a function").
- diff-bug #3 (pass 2): a ggplot object passed as `draw` gives "could not find function" or calls another package's `draw()` — fix now (`is.function()` check with a message).
- diff-bug #4 (pass 2): the README snippet lost `dir.create()` and does not say where `save_png()` lives — fix now.
- diff-bug #5 (pass 2): a README paragraph is not reflowed — fix now.
- diff-bug #6 (pass 2): "does not run it" is unclear — fix now ("does not run the report's code").
- diff-bug #7 (pass 2): a `draw` with two pages keeps only the last — reject (false as a change: main's code did the same).
- diff-bug #8 (pass 2): the temporary file may make `quarto preview` reload once more — reject (false: not shown; the reviewer did not probe it, and one reload changes no output).
- blame-history #1 (pass 2): shipping the figure reverses M017 with no D-entry — fix now (D-018; this replaces the pass-1 reject of blame-history #2, since two lenses raised it).
- blame-history #2 (pass 2): D-016 names four skip reasons and the CI list has grown — reject (planned change: D-016 decides where CI runs; the list follows the M018 rule that a missing tool fails CI).
- blame-history #3 (pass 2): `file.rename()` onto an existing file on Windows is not shown — no change needed (R's help says it replaces the target; the Windows CI job runs the first-render test).
- blame-history #4 (pass 2): DESIGN.md omits the stop for a file named `figures` — fix now.
- blame-history #5 (pass 2): a hard kill leaves a hidden temporary file — fix now (same as diff-bug #1 pass 2).
- prior-review #1 (pass 2): no check that the device wrote a whole file before the rename — follow-up, row "Stop the example at a linked figures" (extended).
- prior-review #2 (pass 2): a hard kill leaves the temporary file to be published — fix now (same as diff-bug #1 pass 2).
- prior-review #3 (pass 2): a linked `figures/` — no change needed (already the row "Stop the example at a linked figures").
- ripple #1 (pass 2): the candidate row "Fix edge cases of the figures folder" still describes the fixed defects — reject (planned change: post-merge hygiene narrows the row to M029's part).
- ripple #2 (pass 2): `_README.md:12` says figures are saved by the reports, though the template ships one — fix now.
- ripple #3 (pass 2): DESIGN.md's test-skip sentence names only CRAN and quarto — fix now.
- pass 2 fix-now items diff-bug #1 to #6, blame-history #1, #4, #5, prior-review #2, ripple #2, #3 — fixed 8f249f3.
- AC7 (local part, after 8f249f3): `test-template.R` 25 tests, 149 expectations, all pass; `NOT_CRAN=true devtools::test()` 290 tests, 4378 expectations, 0 failed, 7 skipped; `devtools::document()` no diff; `devtools::check()` 0 errors, 0 warnings, 0 notes; `cairn_validate.py` all checks passed. CI waits for the PR.
