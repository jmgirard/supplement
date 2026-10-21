# M030: Each report shows the R setup that made its stored output

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the template's example report and the report stub that `add_report()` writes
- **Branch/PR:** —

## Goal

The template's example report and each report that `add_report()` writes end with a section that prints the R and package versions of its render, so that a page's stored output records the setup that made it.

## Scope

**In:** a "Computing environment" section at the end of `inst/template/analyses/example.qmd` and of the stub from `report_lines()` (`R/add-report.R:185`). Its code calls `sessioninfo::session_info()` when sessioninfo is installed and `utils::sessionInfo()` otherwise. The milestone also adds a paragraph to the Reports part of `inst/template/_README.md`, tests, and a NEWS.md bullet.

**Out:** a renv lockfile goes to M031, and a container recipe goes to M032. Python reports get no section (candidate row "Record the Python setup of reports"). Reports in existing sites do not change, and the guide shows the code to add by hand. The stub's data path is the candidate row "Make report paths work from any folder".

## Acceptance criteria

- [ ] AC1: Make a site with `create_supplement()` and run a full `quarto render`. Then `docs/analyses/example.html` holds a section with the heading "Computing environment". Its text holds a match of `R version \d+\.\d+\.\d+`. It also holds, as a whole token, the knitr version that `Rscript -e 'cat(as.character(packageVersion("knitr")))'` prints from the same PATH.
- [ ] AC2: If `requireNamespace("sessioninfo", quietly = TRUE)` is TRUE, the section's code prints `sessioninfo::session_info()`. Otherwise it prints `utils::sessionInfo()`. A test runs the code in an `Rscript` where a global `requireNamespace()` returns FALSE for sessioninfo. That output holds "attached base packages" and not "Session info". A second test runs the code with sessioninfo installed, or skips without it. That output holds "Session info".
- [ ] AC3: The report file that `add_report()` writes ends with the same section. Its code is byte-equal to the code of the example report's section. A test reads both files.
- [ ] AC4: The Reports part of the template guide says three things. The section shows the R and package versions of the report's last render. A full render keeps them for a report that already has stored output in `_freeze/`, because it reuses that output. The guide also shows the section's code, for an author who adds it to an older report.
- [ ] AC5: NEWS.md has one bullet for the section in the example report and in `add_report()` stubs. `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T2, T4
- AC4 → T5
- AC5 → T5, T6

## Tasks

- [ ] T1: Probe in a scratch site. Find what `sessioninfo::session_info()` and `sessionInfo()` print inside a knitr chunk, in a collapsed callout and out of one. Find whether the frozen page keeps the text after a second full render. Record each result in the work log, and write the help text from what the probes show (the derived-claims rule).
- [ ] T2: Add the AC1 to AC3 tests in `tests/testthat/test-template.R` and `tests/testthat/test-add-report.R`. Use `expect_status()` for each command (`helper-template.R`). Run each new test against main and record that it fails there (LESSONS M010).
- [ ] T3: Add the section to `inst/template/analyses/example.qmd`. Use a level-2 heading "Computing environment" and one chunk with `#| label: session-info`.
- [ ] T4: Add the same lines to the end of `report_lines()` in `R/add-report.R`. Recheck the tests that compare a whole stub in `tests/testthat/test-add-report.R` and the render tests in `tests/testthat/test-add-render.R`.
- [ ] T5: Add the paragraph and the code to the Reports part of `inst/template/_README.md` (line 19). Add a NEWS.md bullet. Run `devtools::document()` when the `add_report()` help changes.
- [ ] T6: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

## Work log

- 2026-10-21: created by /milestone-plan.
- 2026-10-21: tier check: milestone — a change to the template's report and to the `add_report()` stub, with a design choice of what to record.
- 2026-10-21: idea vet: three concerns, posed at the question set. A lockfile shows the packages at the last snapshot, not those of each report's render. A Dockerfile is a recipe, so a later build can get newer system libraries, and Zenodo keeps the recipe and not the image. All layers cover R only. The user chose all three layers. The per-report section records each render, M031's guide states the lockfile limit, and M032 adds a digest pin, a `.dockerignore`, and `docker save` in the guide.
- 2026-10-21: question set: scope — three milestones, M030 (this), M031 (renv guide and tests), M032 (`write_dockerfile()`), in that order.
- 2026-10-21: plan chose `sessioninfo::session_info()` with a fallback to `sessionInfo()` over sessioninfo alone, because readers who render a report then need no new package; falsified by a report setup where the two outputs confuse readers enough to need one form.
- 2026-10-21: collision check: no ROADMAP row, archived milestone, or D-entry covers environment records. The candidate row "Make report paths work from any folder" also edits `report_lines()`. It stays apart, and this file cross-references it.
- 2026-10-21: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-21: lessons surfaced: M001 (a render by name runs the report again), M010 (prove a test fails on main), M011 (`writeBin()` fixtures), M028 (template folder lists in Windows-only tests).
- 2026-10-21: criteria audit (full mode, fresh Opus reader): 4 findings for M030, all taken. AC1 now matches the R version by pattern and reads the knitr version from the PATH's Rscript. AC2 now hides sessioninfo with a global `requireNamespace()`, because on macOS sessioninfo can sit in `.Library`, and it probes both branches. AC4 now limits the "full render keeps them" claim to reports with stored output. AC3 and AC5 had no finding.
- 2026-10-21: changelog: one new bullet in NEWS.md under 0.0.0.9000.

## Decisions

## Review
