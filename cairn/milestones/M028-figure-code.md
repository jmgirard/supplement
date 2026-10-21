# M028: The template saves paper figures safely in more setups

- **Status:** in-progress
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

- [ ] AC1: The template ships `figures/bootstrap-means.png`. A test in `tests/testthat/test-template.R` makes a site with `create_supplement()` and runs one full `quarto render`. Then `docs/figures/bootstrap-means.png` exists and has the same MD5 as `figures/bootstrap-means.png`.
- [ ] AC2: The `data` and `save-figure` chunks of `analyses/example.qmd` build their paths from `QUARTO_PROJECT_DIR`, and from `..` when it is not set. A test renders a new site in two setups: with the template's `_quarto.yml`, and with `execute-dir: project` added to it. In each setup the render succeeds, `figures/bootstrap-means.png` is in the site, and the parent folder of the site holds no `figures/` folder. A third case runs the code of both chunks from `analyses/` with `QUARTO_PROJECT_DIR` not set, and the figure is in the site's `figures/`.
- [ ] AC3: If the plotting call in the `save-figure` chunk fails, the chunk closes the graphics device that it opened. It also leaves `figures/` with the same file names and MD5s as before the chunk ran. A test takes the code of the chunk from `analyses/example.qmd` by its label and runs it in a site folder with `hist()` replaced by a function that stops. It runs once with no `figures/bootstrap-means.png` and once with an earlier one. It checks `grDevices::dev.list()` and the names and MD5s of the files in `figures/`.
- [ ] AC4: If the site holds a file named `figures`, the `save-figure` chunk stops before it opens a graphics device, with an error that says that `figures` is a file, not a folder. A test renders such a site, checks that the render fails, and matches that phrase in the render output. The same test fails on main, where the error reads "unable to open file".
- [ ] AC5: The template's rules for figures next to reports match any mix of letter case. The test uses two sites made by `create_supplement()` and rendered once: one that is a git repository before its first render, and one where `git init` comes after it. In each, `git -c core.ignorecase=false check-ignore` reports `analyses/a.PNG`, `analyses/b.Pdf`, `analyses/c.png`, and `analyses/d.pdf` as ignored. It reports `figures/e.PNG` and `figures/f.PDF` as not ignored.
- [ ] AC6: The "Paper figures" section of `inst/template/_README.md` says that the template ships the example figure, shows the `QUARTO_PROJECT_DIR` path form of AC2, and says that the rules match any letter case. It no longer says that git on Linux reads the rules in lower case only. The NEWS.md bullet for the template's paper figures states the same three changes.
- [ ] AC7: `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T3
- AC2 → T2, T3
- AC3 → T2, T3
- AC4 → T2, T3
- AC5 → T4
- AC6 → T5
- AC7 → T3, T4, T5, T6

## Tasks

- [x] T1: Render the example report in a scratch site and copy its `figures/bootstrap-means.png` to `inst/template/figures/`. Check that `template_files()` (`R/create-supplement.R:131`) lists it and that `R CMD build` keeps it. The README text "the template has no `figures/` folder until a report makes it" (`_README.md:284`) changes in T5.
- [x] T2: Rewrite the two chunks of `analyses/example.qmd` (lines 12 and 35). Take the site folder from `Sys.getenv("QUARTO_PROJECT_DIR", "..")`. Stop with the AC4 error when `figures` exists and is not a folder. Write the PNG to a temporary file inside `local()` with `on.exit(dev.off())`, and copy it into `figures/` only after the plot succeeds. Keep the chunk short, because authors copy it.
- [x] T3: Add the AC1 to AC4 tests beside the figure test at `tests/testthat/test-template.R:194`, with `skip_if_no_quarto()`. Run each against the template on main and record that each fails there (LESSONS M010). For AC3, take the chunk code with `knitr` (a Suggests package) or a label match, not by line numbers.
- [x] T4: Spell the two rules in `inst/template/_gitignore` with bracket patterns, as for `.rds` (LESSONS M003). Extend the tests at `test-template.R:179` and `:251` for AC5, with `-c core.ignorecase=false` on every `check-ignore` (macOS and Windows default to true).
- [ ] T5: Edit the "Paper figures" section of `inst/template/_README.md` (lines 272 to 301) and the NEWS.md template bullet. Each statement comes from a T3 or T4 test run in this branch (the derived-claims rule).
- [ ] T6: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

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

## Decisions

## Review
