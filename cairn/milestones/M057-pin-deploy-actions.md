# M057: Pin the deploy job's actions by SHA

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — the CI workflow that deploys the package's own site; no package user or site reader relies on how its actions are referenced
- **Branch/PR:** —

## Goal

Pin each action that the site's deploy job runs to a full commit hash, so that a moved tag cannot change what the one job with write access runs.

## Scope

**In:** In `.github/workflows/pkgdown.yaml`, the `deploy` job's `actions/checkout@v7` and `actions/download-artifact@v8` become full commit hashes, each with a `# <release tag>` comment, as the `JamesIves/github-pages-deploy-action` step already is. A comment in the deploy job and DESIGN.md's pkgdown paragraph state the rule: the job with write access pins every action by hash, and other jobs use version tags (D-027).

**Out:** hash pins in the `build` job and in `.github/workflows/R-CMD-check.yaml`, and a Dependabot file that updates pins (both declined by the user at the M057 plan; D-027). The deploy events and clean deploys (D-026, unchanged). Job permissions (M056, unchanged).

## Acceptance criteria

- [ ] AC1: In `.github/workflows/pkgdown.yaml`, each `uses:` line in the `deploy` job (the lines from `  deploy:` to the end of the file, as `grep -n 'uses:'` lists them) names a 40-character hexadecimal commit hash followed by a `# <tag>` comment that names a full release tag, such as `v7.0.1`. For `actions/checkout` and `actions/download-artifact`, the hash equals what `gh api repos/actions/<name>/commits/<tag in the comment> --jq .sha` reads.
- [ ] AC2: The branch's diff against main, `git diff main...HEAD -- .github/`, changes only `uses:` lines and comment lines, all inside the `deploy` job of `.github/workflows/pkgdown.yaml`.
- [ ] AC3: A `workflow_dispatch` run on the milestone branch whose deploy job uses the pinned `uses:` lines has every deploy-job step at `success` in `gh run view <id> --json jobs`.
- [ ] AC4: DESIGN.md's paragraph on `pkgdown.yaml` and a comment in the `deploy` job state that the deploy job pins each action to a commit hash because it is the one job with write access, and that other jobs use version tags. The comment also gives the `gh api` command that reads the commit a tag points to, for updating a pin.

## Coverage

- AC1 → T1
- AC2 → T1, T3
- AC3 → T3
- AC4 → T1, T2

## Tasks

- [ ] T1: In `.github/workflows/pkgdown.yaml`, read each tag's commit from the action's own repository (`gh api repos/actions/checkout/commits/v7 --jq .sha`, and the same for `download-artifact` at `v8`; on 2026-10-25 these read `3d3c42e5…` and `9000827c…`). Find the full release tag at that commit with `gh api repos/actions/<name>/git/matching-refs/tags/v` (`v7.0.1` and `v8.0.2` on 2026-10-25). Replace the deploy job's two `uses:` lines (lines 80 and 83) with `<owner>/<name>@<hash> # <tag>`. Add a comment at the top of the deploy job that states the rule and the update command. Leave the build job's tags as they are.
- [ ] T2: Add one sentence on the rule to the pkgdown paragraph at `cairn/DESIGN.md:279-291`.
- [ ] T3: Commit a probe that differs from the branch head only in the deploy job's `if:` (also admitting the branch) and an added `dry-run: true` on the deploy step. Push, run `gh workflow run pkgdown.yaml --ref <branch>` once the user allows manual runs, watch the run in the background, and read `gh run view <id> --json jobs`. Then revert the probe in its own commit and push.

## Work log

- 2026-10-25: created by /milestone-plan.
- 2026-10-25: tier check: not run — work named at the question set.
- 2026-10-25: idea vet: no concern found. GitHub's hardening guide names a full-length commit hash as the only reference that cannot move. A hash from a fork also resolves in the parent repository, so T1 reads each hash from the tag through the action's own repository. Pins with no updater go stale; the user chose no Dependabot at the question set.
- 2026-10-25: lessons used: 2026-10-19 (M019), CI jobs can run past the 10-minute watch ceiling, so T3's wait uses a background watch.
- 2026-10-25: question set: which candidate to plan — "Pin the deploy job's actions by SHA"; which actions to pin — the deploy job only, with no Dependabot file.
- 2026-10-25: question set: permission for manual workflow runs on the branch was not asked, so implement stops for the user's yes before T3's `gh workflow run`.
- 2026-10-25: collision check: absorbs candidate "Pin the deploy job's actions by SHA" (from the M056 review). M054, M055, and M056 (done) built the workflow, limited deploys to main, and split the jobs; D-025 and D-026 read whole, and neither names how actions are referenced, so both stand. The row's "a change of rule would cover both workflows" was declined at the question set and is recorded in D-027. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-25: plan gate chose hash pins in the deploy job only over hash pins in every job, at the user's choice, because only the deploy job holds write access and the build job's token is read-only (M056); falsified by a moved tag in a read-only job that reaches the repository or the published site.
- 2026-10-25: plan gate chose hand-updated pins over a Dependabot file, at the user's choice, because a Dependabot file is a standing automation that opens PRs on the repo; falsified by a pinned action left on a release with a known security flaw.
- 2026-10-25: plan gate chose a temporary dry-run probe commit, reverted before review, as in M056, over a deploy job that runs in dry-run mode off main, because the second keeps a write-access job running off main against D-026; falsified by a deploy failure on main that a probe run did not show.
- 2026-10-25: changelog: no NEWS entry, since only the workflow, DESIGN.md, and DECISIONS.md change and no package behavior; test scope: no new test and no verify run, since no R file or file the tests read changes.
- 2026-10-25: criteria audit (reduced mode, fresh Opus reader): 2 findings on AC1, 2 on AC3, all fixed. AC1's "tag on the day of the pin" gave a different answer later, so it now checks the hash against the release tag in the comment. AC3 bound the probe and its revert, so those moved to T3, and AC2 now allows only `uses:` and comment lines, which fails a probe left in. AC2 and AC4 passed.
- 2026-10-25: known limit, recorded in D-027: an action in the build job still runs by tag and could change the site artifact that the deploy job publishes, so the pins protect the write token, not the site's content.

## Decisions

## Review
