# M056: Give site builds read-only access

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — the CI workflow that builds and deploys the package's own site; no package user or site reader relies on how its jobs are split
- **Branch/PR:** m056-read-only-site-builds

## Goal

Run every build of the package site with a read-only token, so that only the deploy from main holds write access.

## Scope

**In:** `.github/workflows/pkgdown.yaml` splits into a `build` job that runs on every trigger with `contents: read` and uploads `docs/` as a run artifact, and a `deploy` job that needs `build`, runs only when `github.ref` is `refs/heads/main`, holds `contents: write`, downloads the artifact, and runs the pinned `JamesIves/github-pages-deploy-action` step with its current settings. The concurrency group moves to the workflow level so it covers both jobs. The opening comment and DESIGN.md's pkgdown paragraph say which job holds which access.

**Out:** turning on GitHub Pages for `gh-pages` (the user, in the repo settings, as D-025 states). The deploy events and clean deploys of D-026 (unchanged). Template sites' deploy (D-001, unchanged). The check workflow, which already sets `permissions: read-all`. A coverage workflow (candidate row "Add a test coverage report to CI").

## Acceptance criteria

- [x] AC1: At the branch head, `.github/workflows/pkgdown.yaml` has exactly two jobs. The job holding the `Build site` step declares `permissions` with `contents: read` and no `write` value, and has no job-level `if:`. The other job holds the `Deploy to GitHub Pages` step, lists the build job in `needs:`, declares `permissions` with `contents: write`, and has the job-level `if: github.ref == 'refs/heads/main'`. The workflow-level `permissions: read-all` stays, and the workflow-level `concurrency:` group is `pkgdown-${{ github.ref == 'refs/heads/main' || github.run_id }}`. Shown by reading the file.
- [x] AC2: One manual run of the workflow on the milestone branch (`gh workflow run pkgdown.yaml --ref <branch>`) ends with conclusion `success`, with the build job `success` and the deploy job `skipped` (`gh run view <id> --json jobs`). The build job's token holds `contents: read` and no write scope, as its `Set up job` log reports. The run lists one artifact (`gh api repos/jmgirard/supplement/actions/runs/<id>/artifacts`), and that artifact, downloaded with `gh run download <id>`, holds `.nojekyll` and `articles/publishing.html`.
- [x] AC3: One manual run on the branch of the deploy job as it stands at the branch head, admitted on the branch and set to dry-run mode, ends with its artifact download step and its `Deploy to GitHub Pages` step `success` (`gh run view <id> --json jobs`).
- [x] AC4: The deploy step keeps `clean: true`, `branch: gh-pages`, `folder: docs`, and the action pinned at `d92aa235d04922e8f08b40ce78cc5442fcfbfa2f`, and the build job runs the `Leave CLAUDE.md off the site` step before `Build site`. Shown by reading the file.
- [x] AC5: The workflow's opening comment and the pkgdown paragraph of `cairn/DESIGN.md` each state that the build runs with read access on every trigger and that only the deploy job, which runs on main, has write access. Shown by reading both.
- [ ] AC6: The profile's verify slot is clean: `Rscript -e 'devtools::test()'` reports 0 failures.

## Coverage

- AC1 → T1
- AC2 → T1, T2
- AC3 → T3
- AC4 → T1
- AC5 → T1, T4
- AC6 → T5

## Tasks

- [x] T1: In `.github/workflows/pkgdown.yaml`, move the `concurrency:` block (lines 20-22) to the workflow level. Rename the job to `build` with `permissions: contents: read`; keep its checkout, Quarto, Pandoc, R, dependency, `Leave CLAUDE.md off the site`, and `Build site` steps (lines 28-53), then upload `docs/` with `actions/upload-artifact` and `include-hidden-files: true`, since the action skips hidden files such as `docs/.nojekyll` by default. Add a `deploy` job (`needs: build`, `if: github.ref == 'refs/heads/main'`, `permissions: contents: write`) that runs `actions/checkout` (the deploy action works from the git repository in the workspace), downloads the artifact to `docs/`, and runs the deploy step (lines 58-66) unchanged. Rewrite the opening comment (lines 1-4) to name each job's access.
- [x] T2: Push the branch and make the AC2 manual run; read its jobs, the build job's `Set up job` log, and its artifacts.
- [x] T3: Commit the probe, which differs from the branch head only in the deploy job's `if:` (also admitting the branch) and an added `dry-run: true` on the deploy step; push, make one manual run, read the deploy job's steps, then revert the probe in its own commit and push.
- [x] T4: Update the pkgdown paragraph at `cairn/DESIGN.md:279-287` to name the two jobs and their access.
- [x] T5: Run the verify slot (`Rscript -e 'devtools::test()'`) on the branch.

## Work log

- 2026-10-25: created by /milestone-plan.
- 2026-10-25: tier check: not run — work named at the question set.
- 2026-10-25: idea vet: no concern found; a read-only build job with a separate write job for the deploy is GitHub's least-privilege pattern, and GitHub has no expression for job permissions, so a split is the way to drop write access from builds. The build on main also runs package code and third-party dependencies, so the split covers main runs, not only pull requests and other branches.
- 2026-10-25: lessons used: 2026-10-19 (M019), CI jobs on a pull request can run past the 10-minute watch ceiling, so the run's waits use background watches.
- 2026-10-25: question set: may the run start manual runs of this repo's GitHub workflows on the milestone branch — yes; implement or review may use `gh workflow run` on the branch for the workflows the change touches, which covers the AC2 run and the AC3 probe run.
- 2026-10-25: collision check: absorbs candidate "Give site builds read-only access" (from the M055 review). M054 (done) built the workflow and M055 (done) limited deploys to main; D-025 and D-026 read whole, and neither names job permissions, so both stand. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-25: plan gate chose a temporary dry-run probe commit, reverted before review, over making the deploy job also run in dry-run mode on manual runs from other branches, because the second keeps a write-access job running off main and departs from D-026's "only on main" deploy; falsified by a deploy failure on main that a probe run did not show.
- 2026-10-25: plan gate chose a workflow-level concurrency group over a job-level group on the build job, because a job-level group would let an older run's deploy start after a newer one's; falsified by GitHub queuing two deploy jobs of the main group at once.
- 2026-10-25: changelog: no NEWS entry, since only the workflow and DESIGN.md change and no package behavior; test scope: no new test, since no R code changes.
- 2026-10-25: plan checkpoint: committed while the criteria audit (reduced mode, fresh Opus reader) runs; its findings and dispositions follow in a second plan commit before implement starts.
- 2026-10-25: criteria audit (reduced mode, fresh Opus reader): 3 findings, all fixed. AC3's probe-diff clause bound the probe's shape, so it moved to T3; AC3's log clause passed on echoed inputs even when the step fails, so it narrowed to the download and deploy steps' `success`; AC2's token clause reworded to the token's scopes. AC1, AC4, AC5, AC6 passed. The reader also noted that `actions/upload-artifact` skips hidden files by default, which would drop `docs/.nojekyll` with no AC failing, so AC2 now checks the downloaded artifact for `.nojekyll` and T1 sets `include-hidden-files: true`; and that the deploy action needs a git checkout, so T1's checkout step is firm.
- 2026-10-25: implement started on branch m056-read-only-site-builds, cut from main at 4d8a231.
- 2026-10-25: T1 done: `build` job (`contents: read`) uploads `docs/` as artifact `site` with `actions/upload-artifact@v7` (`include-hidden-files: true`, `if-no-files-found: error`, `retention-days: 1`); `deploy` job (`needs: build`, main only, `contents: write`) runs `actions/checkout@v7`, `actions/download-artifact@v8` to `docs`, then the unchanged deploy step; concurrency at workflow level; opening comment rewritten. Chose the latest majors (upload v7.0.2, download v8.0.2) to match `checkout@v7`'s tag pinning; the one-day retention keeps storage low, since only the same run's deploy job reads the artifact.
- 2026-10-25: T4 done ahead of T2 (minor reorder, so the branch is pushed once with both): DESIGN.md's pkgdown paragraph names the `build` job's read access on every trigger and the main-only `deploy` job's write access.
- 2026-10-25: T2 done: manual run 40227803304 at e345861 ended `success`, build job `success`, deploy job `skipped`; the build job's Set up job log lists `Contents: read` and `Metadata: read` only; artifact `site` (1,189,779 bytes) downloaded holds `site/.nojekyll` and `site/articles/publishing.html`.
- 2026-10-25: T3 done: probe commit e8a8ccc (deploy job `if:` also admits the branch, `dry-run: true`) ran as manual run 40228005061, `success`; the deploy job's checkout, `Download site`, and `Deploy to GitHub Pages` steps all `success`, with `Contents: write` in its Set up job log and "Dry run complete" in the deploy log. `gh-pages` stayed at c11de34, the 19:45 deploy from main 35493be, before the probe. The revert restores the workflow to e345861's bytes (`git diff e345861 -- .github/workflows/pkgdown.yaml` is empty).
- 2026-10-25: T5 done: `devtools::test()` on the branch, 391 tests, 0 failed, 10 skipped.
- 2026-10-25: claim audit: not owed — internal tier.
- 2026-10-25: implement complete; status set to review. The probe revert is commit 9d31e99.

## Decisions

## Review

- Route (d): no PR for the branch; Copilot round off (no `# Copilot review:` line in PROFILE.md). Sync: `origin/main` is 4d8a231, an ancestor of the branch head e3f25e6, so no merge was needed.
- AC1 evidence: `yaml::read_yaml()` of the file at e3f25e6 gives jobs `build` and `deploy` only. `build` holds `Build site`, permissions `contents=read`, no `if:`, no `needs:`. `deploy` holds `Deploy to GitHub Pages`, `needs: build`, permissions `contents=write`, `if: github.ref == 'refs/heads/main'`. Workflow `permissions: read-all`; workflow `concurrency.group` is `pkgdown-${{ github.ref == 'refs/heads/main' || github.run_id }}`. Pass.
- AC2 evidence: manual run 40228325533 (`gh workflow run pkgdown.yaml --ref m056-read-only-site-builds`) at the head e3f25e6, attempt 1, ended `success`, build job `success`, deploy job `skipped`. The build job's Set up job log lists `Contents: read` and `Metadata: read` under GITHUB_TOKEN Permissions, no write scope. The artifacts endpoint lists 1 artifact (`site`, 1,189,774 bytes); `gh run download` gives `site/.nojekyll` and `site/articles/publishing.html`. Pass.
- AC3 evidence: probe run 40228005061 at e8a8ccc ended `success`, deploy job steps `Run actions/checkout@v7`, `Download site`, and `Deploy to GitHub Pages` all `success` (`gh run view --json jobs`), its log showing `dry-run: true` and "Dry run complete". `git diff e8a8ccc e3f25e6 -- .github/workflows/pkgdown.yaml` changes only the deploy job's `if:` (the branch clause removed) and the `dry-run: true` line, so the run ran the deploy job as it stands at the head, admitted on the branch and in dry-run mode. `gh-pages` stayed at c11de34 (deployed 19:45 from 35493be, before the probe at 19:53). Pass.
- AC4 evidence: the deploy step at e3f25e6 uses `JamesIves/github-pages-deploy-action@d92aa235d04922e8f08b40ce78cc5442fcfbfa2f` with `clean: TRUE`, `branch: gh-pages`, `folder: docs`; the build job's step order is checkout > Quarto > Pandoc > R > dependencies > `Leave CLAUDE.md off the site` > `Build site` > `Upload site`. Pass.
- Gate: `cairn_validate.py` exit 0 (24 OK/PASS lines); no principle changed, so `cairn_impact` skipped. `devtools::document()` left no diff; `pkgdown::check_pkgdown()` "No problems found"; no README.Rmd; no NEWS entry owed (no package behavior changed); the branch adds no top-level file; `devtools::check()` 0 errors, 0 warnings, 1 NOTE (the local `.claude` folder, the same NOTE as M055, not in the repo).
- spawned: diff-bug, blame-history, prior-review, ripple.
- diff-bug #1: `retention-days: 1` makes "Re-run failed jobs" on a deploy more than a day after its build fail on a missing artifact, and nothing documents it — fix now (comment on the upload step naming the full re-run).
- diff-bug #2: a full re-run may hit a 409 on the second upload of `site` with no `overwrite:` — reject, false: re-run attempt 2 of run 40228325533 ended `success` with `Upload site` `success` and 1 artifact listed.
- diff-bug #3: `actions/checkout@v7` and `actions/download-artifact@v8` run tag-pinned in the job that holds `contents: write` — follow-up, new row "Pin the deploy job's actions by SHA" (the repo tag-pins every first-party action; the branch narrows write access but does not change the pin convention).
- diff-bug #4: the dry-run probe does not prove a real push from the new layout — reject, planned change: the plan chose the dry-run probe and recorded the first push from main as the falsifying evidence; hygiene reads that run.
- diff-bug #5: workflow-level `permissions: read-all` has no effect while both jobs declare their own — reject, planned change: AC1 keeps it as the default for any job added without its own block.
- diff-bug #6: DESIGN.md's "deletes `CLAUDE.md` …, so a local `pkgdown::build_site()` still puts `CLAUDE.md` in `docs/`" has a "so" that does not follow — fix now (sentence rewritten).
- diff-bug #7: DESIGN.md's pkgdown paragraph does not name the workflow-level concurrency group — reject, style: the workflow comment states it and AC5 does not ask for it.
- blame-history #1: same as diff-bug #1 — fix now (same comment).
- blame-history #2: same as diff-bug #3 — follow-up (same row).
- blame-history #3: concurrency moved from job to workflow level — reject, false: the group expression is unchanged and the reviewer found no change in queueing.
- prior-review #1: the concurrency move edits a point M055 settled — reject, false: the reviewer judged it equivalent, and the group expression and its comment are unchanged.
- ripple #1: DESIGN.md's "only the workflow's build is for publishing" can read as the build job, which publishes nothing — fix now (same rewrite as diff-bug #6).
- ripple #2: DESIGN.md:53-54 says the workflow pushes the site from runs on main without naming the job — reject, false: the sentence is true of the workflow, and DESIGN.md:283-284 names the deploy job.
- ripple #3: a required status check named for the old job id `pkgdown` would break — reject, false: `gh api repos/jmgirard/supplement/branches/main/protection` reports "Branch not protected" and the repo has 0 rulesets.
- AC5 evidence: the workflow's lines 1-6 say the build job runs on every trigger with a read-only token, and that only a push to main or a manual run on main also runs the deploy job, "the one job with write access". `cairn/DESIGN.md:281-286` says the `build` job runs on every trigger with read access and that only a run on main also runs the `deploy` job, "the one job with write access (`contents: write`)". Pass.
