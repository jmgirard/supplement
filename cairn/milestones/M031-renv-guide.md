# M031: An author can record and restore a site's R packages with renv

- **Status:** review
- **Priority:** normal
- **Depends on:** M030
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the template guide's renv part and the tested behavior of a site set up with renv
- **Branch/PR:** m031-renv-guide

## Goal

The template guide shows how to record and restore a site's R packages with renv, and tests show that a site set up with renv still renders, checks, and commits as before.

## Scope

**In:** a renv part in `inst/template/_README.md`, a pointer in `README.md`, renv under Suggests, tests that set up renv in a temporary site, a D-entry for the dependency, and a NEWS.md bullet.

**Out:** supplement does not call renv, and `create_supplement()` gets no renv argument (question set). A check that compares `renv.lock` with the versions in each report's section is the candidate row "Compare renv.lock with report records". A container recipe goes to M032.

## Acceptance criteria

- [x] AC1: The test site is a git repository that holds a site from `create_supplement()`, rendered and committed. The test then runs `renv::init()` with `Rscript` in the site folder. A full `quarto render` of that site then starts no R process through the process calls that Quarto logs. The procedure is a render with `QUARTO_LOG_LEVEL=DEBUG` that exits 0, in which no `[execProcess]` line holds a space-separated word whose base name, ignoring case, quotes, and a trailing `.exe`, is `R`, `Rscript`, or `Rterm`. A lookup line, `which` or `CMD /C where` followed by `R` or `Rscript`, is exempt.
- [x] AC2: `check_supplement()` on that site returns zero rows.
- [x] AC3: In that site, `git ls-files --others --exclude-standard` lists `renv.lock`, `.Rprofile`, `renv/activate.R`, and `renv/settings.json`. It lists no path that starts with `renv/library/`.
- [x] AC4: The template guide has a part on renv with three commands. `renv::init()` sets up renv. `renv::snapshot()` runs after the author renders a report. `renv::restore()` runs on another machine, before a render of one report by name. The part says that a full render runs no R when every report has stored output in `_freeze/`. It also says that `renv.lock` shows the packages at the last snapshot. Each report's Computing environment section shows the packages of its own last render.
- [ ] AC5: DESCRIPTION lists renv under Suggests. NEWS.md has one bullet for the renv guide. `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3
- AC3 → T2, T3
- AC4 → T4
- AC5 → T3, T4, T5

## Tasks

- [x] T1: Probe in a scratch site on macOS, and read Quarto's source for Windows. Find the lookup line that a frozen full render logs on each system. Find whether `renv::init()` in a subprocess needs a network when every package that the site uses is installed. Find what it writes outside the site when `RENV_PATHS_ROOT` points to a temporary folder. Record each result in the work log.
- [x] T2: Add a helper in `tests/testthat/helper-template.R` that makes the AC1 site. It runs `renv::init()` through `Rscript` in the site folder with `RENV_PATHS_ROOT` set to a temporary folder, so the test never activates renv in its own session. It skips when renv is not installed for that `Rscript` and when a network is needed and missing.
- [x] T3: Add the AC1 to AC3 tests in a new `tests/testthat/test-renv.R`. Use `expect_status()` for each command. Show that the AC1 pattern finds an R call in each form, one log line per form (`Rscript`, `/usr/bin/R`, `"C:\Program Files\R\bin\Rscript.exe"` quoted and unquoted, `Rterm.exe`, `R.exe`, upper and lower case, short names, `.bat` and `.cmd`), and finds none in Quarto's own tool lines, the lookup lines, and near misses such as `Rscript.lua`. Make the R-CMD-check workflow's skip list count a skip for missing renv as a missing tool (`.github/workflows/R-CMD-check.yaml:86`). Add renv to Suggests in DESCRIPTION and write the D-entry.
- [x] T4: Write the renv part of `inst/template/_README.md`, after "Rendering on the machine with the private data" (line 237), and a short pointer in `README.md`. Add a NEWS.md bullet.
- [x] T5: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

## Work log

- 2026-10-21: created by /milestone-plan.
- 2026-10-21: tier check: milestone — a new dependency and a new guide part, with design choices about how far supplement goes with renv.
- 2026-10-21: idea vet: see M030's idea-vet line. For this milestone, the guide states that a lockfile shows the packages at the last snapshot.
- 2026-10-21: question set: renv depth — a guide and tests, and supplement never calls renv. renv joins Suggests for the tests.
- 2026-10-21: question set: permission to add renv to Suggests — granted with the renv-depth answer.
- 2026-10-21: plan gate chose a guide and tests over a `renv` argument to `create_supplement()`, because `renv::init()` can download packages and restart R, and authors can run it themselves; falsified by authors who skip renv because setup takes more than one command.
- 2026-10-21: depends on M030, because the guide refers to each report's Computing environment section.
- 2026-10-21: observed in a scratch site on macOS (Quarto 1.10.19, renv 1.3.1): after `renv::init()`, a full frozen render logged `which Rscript` and ran no R. `check_supplement()` gave zero rows. git listed `renv.lock`, `.Rprofile`, and three files in `renv/`, and no file in `renv/library/`.
- 2026-10-21: collision check: no ROADMAP row, archived milestone, or D-entry covers renv. D-005, D-007, and D-009 set the earlier dependency records that the new D-entry extends.
- 2026-10-21: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-21: lessons surfaced: M019 and M020 (match exact `[execProcess]` lines, because Quarto logs its own processes), M018 (`QUARTO_R` and the Windows runner's short folder names), M015 (git config in test repositories).
- 2026-10-21: criteria audit (full mode, fresh Opus reader): 5 findings for M031, all taken. AC1 now states the deliverable (a full render runs no R), and it allows the Windows lookup line and every form of an R call. The test isolates renv's cache and skips offline (T2). AC4 now limits the no-R claim to reports with stored output. The skip check for renv in the subprocess moved to T2, and CI counting a renv skip as missing moved to T3. AC2 and AC3 had no finding.
- 2026-10-21: changelog: one new bullet in NEWS.md under 0.0.0.9000.
- 2026-10-21: cross-reference: M033 moves the workflow's missing-tool list into `.github/scripts/check-skips.R`. If M033 merges first, T3 adds the renv text there.
- 2026-10-22: branch m031-renv-guide cut from main at 1810bd5; status in-progress.
- 2026-10-22: a probe command with an unset path variable committed the two status edits on the branch under a throwaway author; undone with a soft reset before any push.
- 2026-10-22: T1: macOS (Quarto 1.10.19, renv 1.3.1, R 4.6.1), a site from `create_supplement()`, rendered and committed, then `renv::init()` through Rscript: init exited 0, and a frozen full render exited 0 with `which Rscript` as its only R-related `[execProcess]` line. Every render also logs deno, sass, and pandoc `[execProcess]` lines.
- 2026-10-22: T1: Quarto's bundled source (`rBinaryPath`, `which` in quarto.js): with R_HOME set it finds Rscript by a file check and runs no lookup process; otherwise it logs `which Rscript`, or `CMD /C where Rscript` on Windows, and on Windows then reads the registry through `cmd /c <temp>.bat`. No lookup line names an R executable.
- 2026-10-22: T1: with a dead proxy and an unreachable package repository, `renv::init()` exited 0 in 2 s, so it needs a network only when a package the site uses is not installed.
- 2026-10-22: T1: with only RENV_PATHS_ROOT set, renv also wrote a sandbox under `~/Library/Caches/org.R-project.R/R/renv/sandbox`; with RENV_PATHS_SANDBOX also set to a temporary folder, it wrote nothing outside the site and those two folders.
- 2026-10-22: T1: git also listed `renv/.gitignore` beside the four files AC3 names, and nothing in `renv/library/`. `check_supplement()` gave zero rows.
- 2026-10-22: substantive amendment: AC1 — every render logs deno, sass, and pandoc `[execProcess]` lines, so the plan's wording could not be met; the new wording reads only lines that name R, and narrows the claim to the process calls that Quarto logs. The deliverable the user sees is unchanged.
- re-audit: AC1 (full) — first reader: "names a file" did not fit Quarto's unquoted log; the lookup exemption missed `which R` (quarto.js calls the lookup for R too); "runs no R process" was wider than the logged calls; T3's probe was one line with no near misses; the Windows lookup line is known from source only. All taken.
- re-audit: AC1 (full) — second reader: no separator rule for a base name; `where` can return `.bat` or `.cmd` forms; the promise carries the instrument's reach; init's exit status is not required. Wording kept as audited, since a further change goes to the user; the test splits at `/` and `\`, strips `.exe`, `.bat`, and `.cmd`, adds short-name, `.bat`, `.cmd`, and safe-exec probes, and requires `renv::init()` to exit 0.
- 2026-10-22: minor amendment: T3 now names one probe line per form of an R call and near-miss lines that must not match.
- 2026-10-22: the guide's no-R claim rests also on test-template.R's "a full render with R unreachable runs no report code"; an R process started outside Quarto's logged calls, such as from a Lua filter, is outside AC1, and the template has no such filter.
- 2026-10-22: Windows evidence: the tests run with R_HOME set, so Quarto finds R by a file check and logs no lookup line; CI is the first Windows run of the test.
- 2026-10-22: T2: `renv_site()` in `helper-template.R` checks renv, knitr, rmarkdown, and sessioninfo for `home_rscript()` in a separate process, skips when one is missing, and runs `renv::init()` with `--no-init-file` from a script outside the site, with RENV_PATHS_ROOT and RENV_PATHS_SANDBOX in temporary folders.
- 2026-10-22: T3: `test-renv.R` holds the probe test and one test for AC1 to AC3 on one site, so the site renders once; it asserts a pandoc `[execProcess]` line is present and that `renv/library/` holds files. Both renv skip texts count as a missing tool in `check-skips.R`; planted skip logs failed the script for each and passed for "On Windows". renv added to Suggests; D-021 written.
- 2026-10-22: T4 probe: a clone of a committed renv site with an empty renv root bootstrapped renv by download, `renv::restore()` installed 26 packages in 7 s, and `quarto render analyses/example.qmd` ran R with the `renv/library/` packages.
- 2026-10-22: T4: guide part "Recording R packages with renv" after "Rendering on the machine with the private data"; a README paragraph in "Add reports and data"; one NEWS bullet. `devtools::test()`: 0 failures, renv tests ran.
- 2026-10-22: T5: `devtools::check()` 0 errors, 0 warnings, 0 notes on macOS. The R-CMD-check workflow runs at the PR.
- 2026-10-22: claim audit: 23 claims read, 1 corrected — inst/template/_README.md (renv's start-up script uses only the project library, so it copies renv from renv's cache or downloads it); the test-renv.R header comment's loose "commits" wording was also tightened; the same reader re-read both and found them holding.
- 2026-10-22: after the corrections, test-create-supplement.R, test-template.R, and test-renv.R pass; status review.

## Decisions

## Review

- AC1 evidence (2026-10-22, macOS, branch head cca88fe): `test_file("tests/testthat/test-renv.R")` ran with no skip. "a site set up with renv renders with no R, checks clean, and keeps its library out of git" passed 13 expectations: `renv_site()` built a `create_supplement()` site in a git repo, rendered and committed it, and ran `renv::init()` through Rscript (exit 0); the `QUARTO_LOG_LEVEL=DEBUG` full render exited 0, its log held a pandoc `[execProcess]` line, and `r_process_lines()` returned none. The probe test (2 expectations) showed the check finds each of 13 R-call forms and none of 11 other lines.
- AC2 evidence (same run): in that test, `check_supplement()` on the renv site returned a data frame with 0 rows.
- AC3 evidence (same run): in that test, `git ls-files --others --exclude-standard` exited 0 and its output contained `renv.lock`, `.Rprofile`, `renv/activate.R`, and `renv/settings.json`; `renv/library/` held files on disk, and no listed path started with `renv/library/`.
- AC4 evidence (read 2026-10-22 at cca88fe): `inst/template/_README.md` has the part "Recording R packages with renv" with three commands: step 1 `renv::init()` sets up renv; step 2 `renv::snapshot()` runs "After you render a report"; step 3 `renv::restore()` runs "On another machine", then "render one report by name". It says that when every report holds stored output in `_freeze/`, a full render runs no R; that `renv.lock` shows the packages at the last snapshot; and that each report's Computing environment section shows the packages of its own last render.
