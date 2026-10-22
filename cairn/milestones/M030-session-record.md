# M030: Each report shows the R setup that made its stored output

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the template's example report and the report stub that `add_report()` writes
- **Branch/PR:** m030-session-record

## Goal

The template's example report and each report that `add_report()` writes end with a section that prints the R and package versions of its render, so that a page's stored output records the setup that made it.

## Scope

**In:** a "Computing environment" section at the end of `inst/template/analyses/example.qmd` and of the stub from `report_lines()` (`R/add-report.R:185`). Its code calls `sessioninfo::session_info()` when sessioninfo is installed and `utils::sessionInfo()` otherwise. The milestone also adds a paragraph to the Reports part of `inst/template/_README.md`, tests, and a NEWS.md bullet.

**Out:** a renv lockfile goes to M031, and a container recipe goes to M032. Python reports get no section (candidate row "Record the Python setup of reports"). Reports in existing sites do not change, and the guide shows the code to add by hand. The stub's data path is the candidate row "Make report paths work from any folder".

## Acceptance criteria

- [x] AC1: Make a site with `create_supplement()`. Run a full `quarto render` with `QUARTO_R` unset, once as it is and once with sessioninfo hidden from the report's code. Then each time `docs/analyses/example.html` holds a section with the heading "Computing environment". Its text holds a match of `R version \d+\.\d+\.\d+`. It also holds the knitr version that `cat(as.character(packageVersion("knitr")))` prints when run by `file.path(Sys.getenv("R_HOME"), "bin", "Rscript")`, right after `knitr_` or after `knitr` and spaces, and followed by white space or the end of the text.
- [x] AC2: If `requireNamespace("sessioninfo", quietly = TRUE)` is TRUE, the section's code prints `sessioninfo::session_info()`. Otherwise it prints `utils::sessionInfo()`. A test runs the code in an `Rscript` where a global `requireNamespace()` returns FALSE for sessioninfo. That output holds "attached base packages" and not "Session info". A second test runs the code with sessioninfo installed, or skips without it. That output holds "Session info".
- [x] AC3: The report file that `add_report()` writes ends with the same section. Its code is byte-equal to the code of the example report's section. A test reads both files.
- [x] AC4: The Reports part of the template guide says three things. The section shows the R and package versions of the report's last render. A full render keeps them for a report that already has stored output in `_freeze/`, because it reuses that output. The guide also shows the section's code, for an author who adds it to an older report.
- [ ] AC5: NEWS.md has one bullet for the section in the example report and in `add_report()` stubs. `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3, T7
- AC3 → T2, T4
- AC4 → T5, T7
- AC5 → T5, T6

## Tasks

- [x] T1: Probe in a scratch site. Find what `sessioninfo::session_info()` and `sessionInfo()` print inside a knitr chunk, in a collapsed callout and out of one. Find whether the frozen page keeps the text after a second full render. Record each result in the work log, and write the help text from what the probes show (the derived-claims rule).
- [x] T2: Add the AC1 to AC3 tests in `tests/testthat/test-template.R` and `tests/testthat/test-add-report.R`. Use `expect_status()` for each command (`helper-template.R`). Run each new test against main and record that it fails there (LESSONS M010).
- [x] T3: Add the section to `inst/template/analyses/example.qmd`. Use a level-2 heading "Computing environment" and one chunk with `#| label: session-info`.
- [x] T4: Add the same lines to the end of `report_lines()` in `R/add-report.R`. Recheck the tests that compare a whole stub in `tests/testthat/test-add-report.R` and the render tests in `tests/testthat/test-add-render.R`.
- [x] T5: Add the paragraph and the code to the Reports part of `inst/template/_README.md` (line 19). Add a NEWS.md bullet. Run `devtools::document()` when the `add_report()` help changes.
- [x] T6: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.
- [x] T7: Review return 1. Show the home folder as `~` in the section's output, so the page does not publish the account name, and add a test that a render's page holds no home folder path. Then make the fix-now findings in the Review section: `utils::sessionInfo()`, `#| cache: false`, the first sentence, `skip_on_cran()` in the session tests, the branch check and the untouched `R_PROFILE_USER` in the unhidden render, the guide's privacy text and render-by-name step and full snippet, and the section in README.md and DESIGN.md.

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
- 2026-10-21: T1 probes (macOS, Quarto 1.10.19): inside a collapsed callout, `sessioninfo::session_info()` prints "Session info", the R version, the Quarto version, each loaded package with its version, and the library folders. `sessionInfo()` (with sessioninfo hidden) prints the R version, BLAS paths, locale, time zone, "attached base packages", and loaded packages as `name_version`. A second full render kept the section on the frozen page.
- 2026-10-21: implement chose a collapsed callout titled "R and package versions" over a plain chunk, so the long output does not fill the page. The guide says that the output shows the R library folders and the time zone, because the page publishes them.
- 2026-10-21: T2: the four new tests failed on the branch before T3 and T4 (the section and its chunk were missing). After T3 to T5, `devtools::test()` gave 308 tests, 0 failed, 7 skipped (existing Windows and case-sensitive-disk skips).
- 2026-10-21: `devtools::check()` first gave 1 error: R CMD check puts a stub `Rscript` first on the PATH, which exits 1 ("should not be used without a path"). Quarto with `QUARTO_R` unset uses `R_HOME/bin/Rscript` first, so the tests now run that one (`home_rscript()`). Then check gave 0 errors, 0 warnings, 0 notes.
- 2026-10-21: re-audit: AC1 (full) — the proposed wording ("the Rscript that Quarto runs: QUARTO_R, else R_HOME, else PATH") misstated Quarto's lookup and bound the test helper. Narrower wording offered: render with `QUARTO_R` unset and compare with `file.path(Sys.getenv("R_HOME"), "bin", "Rscript")`.
- 2026-10-21: re-audit: AC1 (full) — in the `sessionInfo()` branch knitr prints as `knitr_1.52`, which the whole-token match misses. CI renders that branch, because `--as-cran` hides packages outside Suggests. This is the second re-audit line for AC1, so the next wording goes to the user.
- 2026-10-21: question set (stop at the second AC1 re-audit): AC1 wording — the user chose "Both renders": match knitr after `knitr_` or `knitr` and spaces, and render once as the machine is and once with sessioninfo hidden.
- 2026-10-21: substantive amendment: AC1 now renders with `QUARTO_R` unset, twice (once with sessioninfo hidden), reads the knitr version from `R_HOME/bin/Rscript`, and accepts both `knitr_1.52` and `knitr  1.52`. Chosen by the user at the stop, so no further reader ran.
- 2026-10-21: the AC1 test hides sessioninfo with `R_PROFILE_USER` naming a profile that defines `requireNamespace()`, and asserts that the hidden render printed "attached base packages" and not "Session info".
- 2026-10-21: T6: `devtools::check()` gave 0 errors, 0 warnings, 0 notes. Of four full `devtools::test()` runs, three passed (308 tests, 0 failed, 7 skipped) and one gave 2 failures and 1 error whose messages were not kept. This may be the parked "template test flake" row, but that was not confirmed.
- 2026-10-21: claim audit: 19 claims read, 2 corrected — inst/template/_README.md (library folders show only with sessioninfo), tests/testthat/helper-template.R (four named references and `&#39;`).
- 2026-10-21: review return 1: the Computing environment output publishes the author's account name in library, pandoc, and quarto paths under the home folder, which can unblind a double-blind review (diff-bug #1). The fix-now findings in the Review section ride with it.
- 2026-10-21: minor amendment: added T7 for review return 1 and mapped it to AC2 and AC4.
- 2026-10-21: T7: the chunk now prints its output with each spelling of `USERPROFILE` and `HOME` replaced by `~`, calls `utils::sessionInfo()`, and sets `cache: false`. `add_report()` reads the section from the installed template's example (`environment_section()`), so the two copies cannot differ. With the old chunk restored from HEAD, the AC1 test failed 1 expectation (a home path on the unhidden page) and the new home-folder test failed 2. Both pass with the new chunk.
- 2026-10-21: T7: the guide now names the paths the output shows, tells authors to copy the section from `analyses/example.qmd` and render the report by name, and README.md and DESIGN.md mention the section.
- 2026-10-21: question set (implement stop, dependency change): sessioninfo in Suggests — the user chose to add it. DESCRIPTION lists it, the CI skip list counts `{sessioninfo}` as a missing tool, and D-019 records it. Checks after this change are still to run.
- 2026-10-21: claim audit: 31 claims read, 1 corrected — cairn/DECISIONS.md D-019 Context (the CI skip-list step runs outside R CMD check and does not fail on a failed test). D-019 was corrected in place before it reached the default branch.
- 2026-10-21: T7 done: with sessioninfo in Suggests, `devtools::check()` gave 0 errors, 0 warnings, 0 notes. The suite before that change gave 309 tests, 0 failed, 7 skipped.

## Decisions

## Review

- AC1 evidence (2026-10-21, branch head 12a88e8): the test "the example page shows the R and knitr versions of its render" ran fresh with 12 expectations, 0 failed. It renders two new sites with `QUARTO_R` unset, one with sessioninfo hidden through `R_PROFILE_USER`. Both pages hold the heading, an `R version` match, and the knitr version of `R_HOME/bin/Rscript` after `knitr_` or `knitr` and spaces. The hidden render printed "attached base packages" and not "Session info".
- AC2 evidence: "the environment section prints sessionInfo() when sessioninfo is not found" (3 expectations, 0 failed) and "... session_info() when sessioninfo is installed" (3 expectations, 0 failed, not skipped) ran fresh.
- AC3 evidence: "a report stub ends with the example report's Computing environment section" (4 expectations, 0 failed) compares the chunk code and the bytes from the heading to the end of each file.
- AC4 evidence: `inst/template/_README.md` Reports part, "### Computing environment": it says the section shows the R and package versions of the last render, that a full render reuses `_freeze/` so the page keeps them when `_freeze/` holds the report's output, and it shows the section's code.
- AC5 evidence (local part): NEWS.md has one new bullet (line 127). `devtools::test()`: 308 tests, 0 failed, 0 errors, 7 skipped (existing Windows and case-sensitive-disk skips). `devtools::check()`: 0 errors, 0 warnings, 0 notes. The R-CMD-check workflow runs at the PR (step 8).
- Gate: `cairn_validate.py` passed. `devtools::document()` made no diff. No README.Rmd and no `_pkgdown.yml`. No new top-level file. No principle changed.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the page publishes the author's account name in library, pandoc, and quarto paths (`/Users/<name>/…`, `C:/Users/<name>/…`), which can unblind a double-blind review — fix now (floor return 1)., fixed 63c8f8d
- diff-bug #2: the guide's privacy sentence leaves out the account name, the pandoc and quarto paths, and the BLAS paths of `sessionInfo()` — fix now., fixed 63c8f8d
- diff-bug #3: the guide's steps for an older report do not say to render it by name, so a full render keeps the old stored output — fix now., fixed 63c8f8d
- diff-bug #4: the unhidden render never checks which branch ran, and in CI both renders take the fallback — fix now (the unhidden render asserts "Session info" when sessioninfo is installed for that R)., fixed 63c8f8d
- diff-bug #5: `R_PROFILE_USER = NA` in the unhidden render changes its setup from other render tests — fix now., fixed 63c8f8d
- diff-bug #6: the one failing run of four was not explained — follow-up, noted in the candidate row "template test flake".
- diff-bug #7: each render by name changes the date and versions in `_freeze/` — reject, planned change: the section exists to record each render.
- diff-bug #8: the callout's `title` attribute also shows as a browser tooltip — reject, style (Quarto's own markup).
- diff-bug #9: the code calls bare `sessionInfo()` while AC2 names `utils::sessionInfo()` — fix now., fixed 63c8f8d
- diff-bug #10: sessioninfo lists itself among loaded packages — reject, false as a defect: it was loaded to print the list, and the list is accurate.
- diff-bug #11: with `cache: true` the chunk would show an old render's versions with no warning — fix now (`#| cache: false` on the chunk)., fixed 63c8f8d
- diff-bug #12: "Computing environment" is in sentence case while other headings use title case — reject, planned change: AC1 names this heading.
- diff-bug #13: the section's first sentence has no main verb — fix now., fixed 63c8f8d
- diff-bug #14: the guide's snippet leaves out the section's paragraph — fix now., fixed 63c8f8d
- diff-bug #15: DESIGN.md does not mention the new section — fix now., fixed 63c8f8d
- diff-bug #16: Windows behavior of `R_HOME/bin/Rscript` through `system2()` is unverified — reject, planned change: the AC5 CI run on Windows is that check.
- blame-history #1: the published machine data has no recorded decision — fix now, same fix as diff-bug #1., fixed 63c8f8d
- blame-history #2: a test uses sessioninfo (`skip_if_not_installed`) though DESCRIPTION does not list it, against D-007's rule — a dependency change, posed to the user at implement. The user chose to add it, fixed 541a7a9
- blame-history #3: AC2 names `utils::sessionInfo()` and the code does not — fix now, same as diff-bug #9., fixed 63c8f8d
- blame-history #4: existing sites do not get the section — reject, planned change (Scope Out).
- prior-review #1: the two `run_session_code()` tests start Rscript with no `skip_on_cran()`, unlike every other subprocess test — fix now., fixed 63c8f8d
- prior-review #2: the page publishes library folders and the time zone — fix now, same as diff-bug #1., fixed 63c8f8d
- prior-review #3: an empty Rscript output could pass `expect_match()` — reject, false: testthat 3e's `expect_match()` fails on a zero-length value.
- prior-review #4: some new expectations have no `info =` — reject, style.
- ripple #1: the guide's steps for an older report do not say to render it by name — fix now, same as diff-bug #3., fixed 63c8f8d
- ripple #2: README.md and the guide's `add_report()` sentences do not mention the section — fix now., fixed 63c8f8d
- ripple #3: DESIGN.md calls the output a "report stub" — fix now with diff-bug #15., fixed 63c8f8d
- ripple #4: DESIGN.md's list of what the example holds leaves out the section — fix now with diff-bug #15., fixed 63c8f8d
- Pass 2 (2026-10-21, after review return 1, head 2be8587): the five criterion tests ran fresh with 0 failures (AC1 test 19 expectations, the two branch tests 3 each, the home-folder test 3, the AC3 test 4). `cairn_validate.py` passed and `devtools::document()` made no diff.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: replacing the shortest home spelling first mangles a linked home whose real path ends with the linked path (`/private~/lib`, confirmed) — fix now: longest spelling first., fixed 2cee711
- diff-bug #2: no folder-boundary check, so HOME `…/al` turned `…/alice` into `~ice` (confirmed) — fix now: the match must start after white space or at the line start and end at a separator, white space, or the line end., fixed 2cee711
- diff-bug #3: Windows 8.3 short names of the home folder are not replaced — fix now: `utils::shortPathName()` spellings on Windows., fixed 2cee711
- diff-bug #4: the match is case-sensitive, and Windows paths can differ in case — fix now: `ignore.case` on Windows., fixed 2cee711
- diff-bug #5: `nchar(homes) > 3` drops a real home such as `/al` — fix now: drop only a drive root or `/`., fixed 2cee711
- diff-bug #6: NEWS.md states the privacy result as absolute — fix now: NEWS, the guide, and the example's prose say that folders outside the home folder show in full., fixed 2cee711
- diff-bug #7: the chunk leaves `info`, `homes`, `lines`, and `home` in the report's environment — fix now: the chunk runs in `local()`., fixed 2cee711
- diff-bug #8: the AC1 test's home spellings leave out `normalizePath()` forms and check case — fix now., fixed 2cee711
- diff-bug #9: the home-folder test covers neither a prefix home, a linked home, nor the `sessionInfo()` form — fix now: three tests. With the pass-1 chunk restored, the prefix test failed 2 expectations and the linked-home test failed 3., fixed 2cee711
- diff-bug #10: the AC3 byte test cannot catch drift, because the stub reads the section from the example — reject, planned change: AC3 as written, and drift is now impossible by construction.
- diff-bug #11: a missing or edited installed example gives an unclassed error from `environment_section()` — reject, edge: a broken package install, outside documented and common use, and the effect is an error.
- diff-bug #12: no finding (encoding and final newline checked).
- diff-bug #13: session_info() runs `quarto -V` on each render — reject, planned change: session_info() reports the Quarto version.
- diff-bug #14: on Windows `~` stands for USERPROFILE as well as HOME — reject, style.
- blame-history #1: D-019 says `--as-cran` hides packages outside Suggests, but check only prepends its library — reject, false: R 4.6.1 `tools:::.check_packages` sets `R_check_suggests_only` under `--as-cran`, and `setRlibs()` then gives the tests `R_LIBS` with links to declared packages only and `R_LIBS_USER` and `R_LIBS_SITE` as `NULL`.
- blame-history #2: NEWS.md's privacy claim has no caveat — fix now with diff-bug #6., fixed 2cee711
- prior-review #1: `stopifnot()` in `environment_section()` gives an unclassed error — reject, edge, as diff-bug #11.
- prior-review #2: `environment_section()` uses `readLines()`, not `read_text_lines()` — reject, edge: the input is the package's own UTF-8 template, which the AC3 test reads.
- prior-review #3: some expectations have no `info =` — reject, style.
- prior-review #4: the AC1 render test has no `skip_on_cran()` — reject, false: `skip_if_no_quarto()` calls `skip_on_cran()` (`helper-template.R:4`).
- ripple #1: the candidate row "Compare renv.lock with report records" says each report has the section — fix now., fixed 2cee711
- ripple #2: the row "Keep tests within the Suggests floors" lists the Suggests entries with no floor and leaves out sessioninfo — fix now., fixed 2cee711
- ripple #3: the guide's "Publishing from one machine" part does not say a render elsewhere changes the section — fix now., fixed 2cee711
- ripple #4: README.md's render requirements do not name sessioninfo — reject, false as a conflict: sessioninfo is optional.
- ripple #5: DESIGN.md's list of missing tools — reject, false: "such as" covers it.
- ripple #6: the example's "shows the parts of an analysis page" — reject, false: the section is one more part.
- Pass 2 gate (head 2cee711): `devtools::test()` gave 312 tests, 0 failed, 0 errors, 7 skipped (existing Windows and case-sensitive-disk skips). `devtools::check()` gave 0 errors, 0 warnings, 0 notes. `devtools::document()` made no diff.
