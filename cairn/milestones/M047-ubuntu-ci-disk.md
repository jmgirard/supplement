# M047: Keep the Ubuntu CI job within its disk

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — CI workflow configuration that no consumer of the package relies on
- **Branch/PR:** m047-ubuntu-ci-disk

## Goal

The ubuntu-latest CI job runs the render tests with R's temporary folder on the runner's disk, so the job passes on the ubuntu-26.04 image.

## Scope

**In:** A diagnostic CI run that shows the `/tmp` file system and its free space on ubuntu-26.04. A Linux-only step in `.github/workflows/R-CMD-check.yaml` that points `TMPDIR` at a folder under `$RUNNER_TEMP`. The CI paragraph of `cairn/DESIGN.md`.

**Out:** Cutting the disk use of the size fixtures in `tests/testthat/test-shortcodes.R` → the candidate row "Measure the cost of large data files". Pinning `ubuntu-24.04` → not planned (the user chose to keep ubuntu-latest). Merging PR #47 → M046's review, after this milestone merges.

## Acceptance criteria

- [x] AC1: In `.github/workflows/R-CMD-check.yaml`, a step that runs only when `runner.os == 'Linux'` and comes before the `r-lib/actions/check-r-package` step writes a `TMPDIR` line to `$GITHUB_ENV` that names a folder under `$RUNNER_TEMP`. The step makes that folder.
- [ ] AC2: On the head of this milestone's pull request, `gh pr checks` reports pass for the R-CMD-check workflow's `windows-latest (release)`, `macos-latest (release)`, and `ubuntu-latest (release)` checks.
- [x] AC3: The CI paragraph of `cairn/DESIGN.md` (about line 252) says that the Ubuntu job sets `TMPDIR` to a folder under `$RUNNER_TEMP` because `/tmp` on that runner image has too little space for the render tests' large fixtures.

## Coverage

- AC1 → T2
- AC2 → T2, T4
- AC3 → T3

## Tasks

- [x] T1: On the branch, add a temporary Linux-only step before the check that prints `findmnt -T /tmp`, `df -h /tmp "$RUNNER_TEMP"`, and `Rscript -e 'tempdir()'`. Push the branch once (granted at the question set) and read the ubuntu-latest log. If `/tmp` is not a small file system that the fixtures can fill, the goal is wrong: stop and return to `/milestone-plan`.
- [x] T2: Replace the diagnostic step with the `TMPDIR` step of AC1, with a comment that names the reason. Keep `df -h` of the new folder in the step only if T1 shows it helps read a later failure. Push once more and read the three jobs.
- [x] T3: Update the CI paragraph of `cairn/DESIGN.md` (about line 252) for AC3.
- [ ] T4: At review, read `gh pr checks` on the PR head for AC2.

## Work log

- 2026-10-23: created by /milestone-plan from the candidate row "Keep the Ubuntu CI job within its disk".
- 2026-10-23: tier check: milestone — a change to the CI workflow, which runs code, with a design choice between moving the temporary folder and pinning the runner image.
- 2026-10-23: idea vet: one concern. Moving `TMPDIR` hides how much disk the tests write, which can still hurt a contributor whose `/tmp` is small (answer: move the temporary folder to disk; the fixture size stays with the candidate row "Measure the cost of large data files").
- 2026-10-23: collision check: D-016 says CI runs on ubuntu-latest, and this plan keeps it. D-020 (parallel tests) is unchanged. The candidate row "Measure the cost of large data files" overlaps and stays separate. M046 (PR #47) waits on this milestone. No D-entry rejects this work.
- 2026-10-23: inbox sweep: 0 open issues. 1 open PR, #47, is this repo's own M046 and was dropped from the sweep.
- 2026-10-23: evidence at plan: ubuntu-latest run 40037307026 (passed) used image ubuntu-24.04 20261012.334.1. Runs 40037458284 and 40041011698 (failed with "Quota exceeded") used ubuntu-26.04 20261012.163.1.
- 2026-10-23: criteria audit (reduced mode, Opus fresh reader): AC1 no finding. AC2's step clause was outside what `gh pr checks` lists, and the job names were wrong; rewritten to the three check names. AC3's "and why" named no reason; rewritten to name it.
- 2026-10-23: question set: may the branch be pushed early for one diagnostic CI run — yes, with the diagnostic step removed before review.
- 2026-10-23: plan gate chose `TMPDIR` under `$RUNNER_TEMP` over pinning `ubuntu-24.04`, because the user chose to keep testing on the newest Ubuntu; falsified by a T1 log that shows `/tmp` on the runner's disk with room to spare.
- 2026-10-23: minor amendment: T1's diagnostic step and T2's `TMPDIR` step go up in one push, so one CI run shows both the `/tmp` file system and whether the fix holds. The diagnostic step is removed before review, as the question set asked.
- 2026-10-23: T1: run 40055150456 (branch head 4a77524) on ubuntu-26.04 20261012.163.1 showed `/tmp` as `tmpfs` with `usrquota`, 7.9G in size, and `/dev/root` with 88G free. So the "Quota exceeded" failures came from the tmpfs quota, and the goal holds.
- 2026-10-23: T2: in the same run, with `TMPDIR` under `$RUNNER_TEMP`, ubuntu-latest passed (5097 passed, 0 failed, 10 skipped) and windows-latest passed. macos-latest failed in `setup-r-dependencies` with "Failed to download rcmdcheck 1.4.0" before any test ran; the two new steps are skipped on macOS, so the PR run at review is the macOS evidence. The diagnostic step is now removed; the workflow parses in R with 9 steps.
- 2026-10-23: T3: the DESIGN.md CI paragraph names the `TMPDIR` folder and the 7.9 GB tmpfs. No R code changed, so the verify slot's `devtools::test()` was not run; CI at review covers the workflow. Status set to review.
- 2026-10-23: claim audit: not owed — internal tier

## Decisions

## Review

- 2026-10-23: synced: `origin/main` is fa772ad, an ancestor of the branch. No PR yet, and the Copilot round is off.
- AC1 (2026-10-23): `.github/workflows/R-CMD-check.yaml` line 43 is the step "Put the temporary folder on the runner's disk", with `if: runner.os == 'Linux'` (line 44). It runs `mkdir -p "$RUNNER_TEMP/tmp"` and writes `TMPDIR=$RUNNER_TEMP/tmp` to `$GITHUB_ENV` (lines 46-47). It is the second step, before `r-lib/actions/check-r-package@v2` (line 66). Line numbers are those after the comment fix of this review pass. In run 40055150456 this step ran on ubuntu-latest, and that job passed with 5097 tests.
- AC3 (2026-10-23): the CI paragraph of `cairn/DESIGN.md` (lines 252-258) says that the Ubuntu job sets `TMPDIR` to a folder under `$RUNNER_TEMP` because `/tmp` on that runner image has too little space for the render tests' large fixtures.
- gate (2026-10-23): `cairn_validate.py` passed. `devtools::document()` gave no diff. No R code, README.Rmd, `_pkgdown.yml`, NEWS entry, or top-level file is involved. `devtools::check()` is running.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the AC1 evidence line cited the workflow lines one too low — fix now
- diff-bug #2: the workflow comment's "the render tests write files of several GB" was loose; one shortcode test's 1.0, 2.1, and 4.3 GB data files, copied into `docs/`, fill the tmpfs — fix now
- diff-bug #3: `r-lib/actions/setup-r` runs after the new step and could export its own `TMPDIR` — reject (false: run 40055150456 passed on Ubuntu with the step in place, and setup-r does not set `TMPDIR` on Linux)
- diff-bug #4: on Linux `tempdir()` now sits under `$HOME`, which the home-folder tests could notice — reject (false: those tests set their own home or skip, and run 40055150456 passed)
- diff-bug #5: the DESIGN paragraph matches the T1 log — noted
- blame-history #1: the DESIGN paragraph carried a CI run number and date — fix now (dropped; the milestone file keeps the run)
- blame-history #2: the comment names ubuntu-26.04 while the matrix says ubuntu-latest — reject (planned change: the comment names the image where the problem was seen, and D-016 keeps ubuntu-latest)
- blame-history #3: "several GB" was not measured — reject (false: `size_cases` defines 1.0, 2.1, and 4.3 GB; the comment now names them)
- prior-review: no prior-review evidence
- ripple #1: the candidate row "Keep the Ubuntu CI job within its disk" still calls the cause unconfirmed — reject (planned change: step 9 deletes the row)
- ripple #2: the row "Measure the cost of large data files" says the Linux fixture cost was not measured — reject (false: still true; this milestone measured the tmpfs, not the fixtures' cost)
