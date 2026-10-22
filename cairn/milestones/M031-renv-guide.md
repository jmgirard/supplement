# M031: An author can record and restore a site's R packages with renv

- **Status:** in-progress
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

- [ ] AC1: The test site is a git repository that holds a site from `create_supplement()`, rendered and committed. The test then runs `renv::init()` with `Rscript` in the site folder. A full `quarto render` of that site then runs no R process. The procedure is a render with `QUARTO_LOG_LEVEL=DEBUG` that exits 0, with no `[execProcess]` line other than the R lookup line (`which Rscript` or `where Rscript`). That line must not name an executable whose base name is `R`, `Rscript`, or `Rterm`, in any path, quoting, or `.exe` form.
- [ ] AC2: `check_supplement()` on that site returns zero rows.
- [ ] AC3: In that site, `git ls-files --others --exclude-standard` lists `renv.lock`, `.Rprofile`, `renv/activate.R`, and `renv/settings.json`. It lists no path that starts with `renv/library/`.
- [ ] AC4: The template guide has a part on renv with three commands. `renv::init()` sets up renv. `renv::snapshot()` runs after the author renders a report. `renv::restore()` runs on another machine, before a render of one report by name. The part says that a full render runs no R when every report has stored output in `_freeze/`. It also says that `renv.lock` shows the packages at the last snapshot. Each report's Computing environment section shows the packages of its own last render.
- [ ] AC5: DESCRIPTION lists renv under Suggests. NEWS.md has one bullet for the renv guide. `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3
- AC3 → T2, T3
- AC4 → T4
- AC5 → T3, T4, T5

## Tasks

- [x] T1: Probe in a scratch site on macOS, and read Quarto's source for Windows. Find the lookup line that a frozen full render logs on each system. Find whether `renv::init()` in a subprocess needs a network when every package that the site uses is installed. Find what it writes outside the site when `RENV_PATHS_ROOT` points to a temporary folder. Record each result in the work log.
- [ ] T2: Add a helper in `tests/testthat/helper-template.R` that makes the AC1 site. It runs `renv::init()` through `Rscript` in the site folder with `RENV_PATHS_ROOT` set to a temporary folder, so the test never activates renv in its own session. It skips when renv is not installed for that `Rscript` and when a network is needed and missing.
- [ ] T3: Add the AC1 to AC3 tests in a new `tests/testthat/test-renv.R`. Use `expect_status()` for each command. Show that the AC1 pattern finds an R call by running it over a log line that names `Rscript`, `/usr/bin/R`, `"C:\Program Files\R\bin\Rscript.exe"`, and `Rterm.exe`. Make the R-CMD-check workflow's skip list count a skip for missing renv as a missing tool (`.github/workflows/R-CMD-check.yaml:86`). Add renv to Suggests in DESCRIPTION and write the D-entry.
- [ ] T4: Write the renv part of `inst/template/_README.md`, after "Rendering on the machine with the private data" (line 237), and a short pointer in `README.md`. Add a NEWS.md bullet.
- [ ] T5: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

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

## Decisions

## Review
