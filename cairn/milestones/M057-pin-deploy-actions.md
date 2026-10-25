# M057: Pin the deploy job's actions by SHA

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — the CI workflow that deploys the package's own site; no package user or site reader relies on how its actions are referenced
- **Branch/PR:** m057-pin-deploy-actions

## Goal

Pin each action that the site's deploy job runs to a full commit hash, so that a moved tag cannot change what the one job with write access runs.

## Scope

**In:** In `.github/workflows/pkgdown.yaml`, the `deploy` job's `actions/checkout@v7` and `actions/download-artifact@v8` become full commit hashes, each with a `# <release tag>` comment, as the `JamesIves/github-pages-deploy-action` step already is. A comment in the deploy job and DESIGN.md's pkgdown paragraph state the rule: the job with write access pins every action by hash, and other jobs use version tags (D-027).

**Out:** hash pins in the `build` job and in `.github/workflows/R-CMD-check.yaml`, and a Dependabot file that updates pins (both declined by the user at the M057 plan; D-027). The deploy events and clean deploys (D-026, unchanged). Job permissions (M056, unchanged).

## Acceptance criteria

- [x] AC1: In `.github/workflows/pkgdown.yaml`, each `uses:` line in the `deploy` job (the lines from `  deploy:` to the end of the file, as `grep -n 'uses:'` lists them) names a 40-character hexadecimal commit hash followed by a `# <tag>` comment that names a full release tag, such as `v7.0.1`. For `actions/checkout` and `actions/download-artifact`, the hash equals what `gh api repos/actions/<name>/commits/<tag in the comment> --jq .sha` reads.
- [x] AC2: The branch's diff against main, `git diff main...HEAD -- .github/`, changes only `uses:` lines and comment lines, all inside the `deploy` job of `.github/workflows/pkgdown.yaml`.
- [x] AC3: A `workflow_dispatch` run on the milestone branch whose deploy job uses the pinned `uses:` lines has every deploy-job step at `success` in `gh run view <id> --json jobs`.
- [x] AC4: DESIGN.md's paragraph on `pkgdown.yaml` and a comment in the `deploy` job state that the deploy job pins each action to a commit hash because it is the one job with write access, and that other jobs use version tags. The comment also gives the `gh api` command that reads the commit a tag points to, for updating a pin.

## Coverage

- AC1 → T1
- AC2 → T1, T3
- AC3 → T3
- AC4 → T1, T2

## Tasks

- [x] T1: In `.github/workflows/pkgdown.yaml`, read each tag's commit from the action's own repository (`gh api repos/actions/checkout/commits/v7 --jq .sha`, and the same for `download-artifact` at `v8`; on 2026-10-25 these read `3d3c42e5…` and `9000827c…`). Find the full release tag at that commit with `gh api repos/actions/<name>/git/matching-refs/tags/v` (`v7.0.1` and `v8.0.2` on 2026-10-25). Replace the deploy job's two `uses:` lines (lines 80 and 83) with `<owner>/<name>@<hash> # <tag>`. Add a comment at the top of the deploy job that states the rule and the update command. Leave the build job's tags as they are.
- [x] T2: Add one sentence on the rule to the pkgdown paragraph at `cairn/DESIGN.md:279-291`.
- [x] T3: Commit a probe that differs from the branch head only in the deploy job's `if:` (also admitting the branch) and an added `dry-run: true` on the deploy step. Push, run `gh workflow run pkgdown.yaml --ref <branch>` once the user allows manual runs, watch the run in the background, and read `gh run view <id> --json jobs`. Then revert the probe in its own commit and push.

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
- 2026-10-25: T1 done: `v7` and `v8` read `3d3c42e5aac5ba805825da76410c181273ba90b1` and `9000827ccba6bdab643e8b6fd33ac0654aef8333` from the actions' own repositories, the release tags at those commits are `v7.0.1` and `v8.0.2`, and the deploy job now pins both with tag comments; the rule comment sits under `deploy:`, so the diff stays inside the job. R's yaml reads the three deploy `uses:` values as hash pins.
- 2026-10-25: T2 done: DESIGN.md's pkgdown paragraph states the pin rule with D-027 and notes that the build job's actions still make the artifact the deploy job publishes.
- 2026-10-25: stop: asked the user before T3's push and manual run, since the question set had not covered it; the user allowed the probe run.
- 2026-10-25: T3 done: probe abc2f87 (deploy `if:` also admits the branch, `dry-run: true`) pushed; run 40233620162 on abc2f87 ended `success`, and every deploy-job step, `Run actions/checkout@3d3c42e5…` and `Download site` included, was `success`; the deploy log shows `dry-run: true` and "Dry run complete", and `gh-pages` stayed at a57adeb. Reverted in 1cb2390; `git diff main...HEAD -- .github/` now holds only the rule comment and the two `uses:` lines.
- 2026-10-25: claim audit: not owed — internal tier.
- 2026-10-25: verify slot not run, as the plan's test-scope line says: no R file or file the tests read changed. Status set to `review`.

## Decisions

## Review

- 2026-10-25: route (d): no PR for the branch; Copilot round off (no `# Copilot review:` line). Branch contains `origin/main` at bb5da4f, so no sync was needed.
- AC1 evidence: `sed -n '/^  deploy:/,$p' .github/workflows/pkgdown.yaml | grep -n 'uses:'` lists 3 lines, and all 3 match `@[0-9a-f]{40} # v<x.y.z>$`. `gh api repos/actions/checkout/commits/v7.0.1 --jq .sha` reads `3d3c42e5aac5ba805825da76410c181273ba90b1` and `gh api repos/actions/download-artifact/commits/v8.0.2 --jq .sha` reads `9000827ccba6bdab643e8b6fd33ac0654aef8333`, each equal to its pin.
- AC2 evidence: `git diff main...HEAD -U0 -- .github/` has three hunks (two at the default context; corrected after diff-bug #1), at new lines 73-78 (six `#` comment lines), 86, and 89 (the two `uses:` lines), all after `  deploy:` at line 72 of the 103-line file; no other file under `.github/` changes.
- AC3 evidence: run 40233620162 (`workflow_dispatch`, head abc2f87) concluded `success`; its deploy job's steps `Set up job`, `Run actions/checkout@3d3c42e5…`, `Download site`, `Deploy to GitHub Pages`, the post step, and `Complete job` are all `success`, and `Set up job` downloaded the three actions at the pinned hashes. `git diff abc2f87 HEAD -- .github/` changes only the deploy `if:` and the `dry-run: true` line, so the run's `uses:` lines are the head's.
- AC4 evidence: `cairn/DESIGN.md:286-289` says the deploy job, which has write access, pins each action to a full commit hash with the release tag in a comment, and that the build job and the check workflow use version tags. The comment at `.github/workflows/pkgdown.yaml:73-78` says the same and gives `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha`.
- spawned: diff-bug, blame-history, prior-review, ripple (four-lens fan-out, since the diff touches `.github/workflows/`).
- diff-bug #1: the AC2 evidence line said three hunks, but the default diff has two — fix now (evidence line corrected to name `-U0`), fixed 6f6a41c.
- diff-bug #2: the Review section and AC ticks were uncommitted — reject (false): committed in 0b57354 before the report arrived.
- diff-bug #3: DESIGN.md's "Because …, and the build job … use version tags" put both clauses under "Because" — fix now (split into two sentences), fixed 6f6a41c.
- diff-bug #4: DESIGN.md named the build job's artifact without the consequence D-027 records — fix now (adds "so the pins guard the write token, not the site's content"), fixed 6f6a41c.
- diff-bug #5: DESIGN.md left a short unwrapped line — fix now (reflowed), fixed 6f6a41c.
- diff-bug #6: the workflow comment names `R-CMD-check.yaml` as using tags, a claim about another file — reject (planned change): AC4 requires the comment to say other jobs use version tags.
- blame-history #1: the build job's `upload-artifact@v7` still runs by tag and makes the published artifact — reject (planned change): the user chose deploy-job pins only, and D-027 and DESIGN.md state the limit.
- blame-history #2: `git blame` puts the deploy `if:` line on revert 1cb2390 — reject (false): the squash merge makes one commit, so the line's blame on main does not name the branch commits.
- blame-history #3: the probe commit stays in branch history — reject (planned change): T3 calls for a probe and a revert, and the squash merge drops both from main's history.
- prior-review #1: the comment's update command omits finding the full release tag — fix now (the comment names a full tag such as v7.0.1, not v7, and says to put it in the comment), fixed 67dff9c.
- prior-review #2: the comment implies the pins protect the site, which only DESIGN.md qualified — fix now (the comment states that the pins guard the write token, not the site's content), fixed 67dff9c.
- prior-review #3: three "The build job" sentences in a row in DESIGN.md — fix now (the `CLAUDE.md` sentence reworded), fixed 67dff9c.
- ripple #1: the candidate row "Pin the deploy job's actions by SHA" still says the deploy job runs both actions by tag — reject (planned change): post-merge hygiene removes the row when M057 graduates it.
- re-evidence after the fixes at 67dff9c: AC2 — `git diff main...HEAD -U0 -- .github/` has three hunks, new lines 73-81 (nine `#` comment lines), 89, and 92 (the two `uses:` lines), all after `  deploy:` at line 72 of the 106-line file; a filter for changed lines that are neither comments nor `uses:` lines prints nothing. AC3 — `git diff abc2f87 HEAD -- .github/` still changes no `uses:` line. AC4 — the comment at `.github/workflows/pkgdown.yaml:73-81` and `cairn/DESIGN.md:286-290` state the rule, and the comment gives the `gh api` command. AC1 unchanged (the `uses:` lines did not change). R's yaml still parses the workflow.
- consistency gate: `cairn_validate.py` all checks passed; no principle changed, so `cairn_impact` skipped; `devtools::document()` left no diff; no README.Rmd; `pkgdown::check_pkgdown()` "No problems found"; no changelog entry, since no package behavior changed; no new top-level file.
- full check: the first `devtools::check()` run (tree at 0b57354) gave 1 error, 0 warnings, 1 note; the run printed only the counts, so the error was not identified. A rerun at 8743778, whose R files and tests equal 0b57354's, gave 0 errors, 0 warnings, 1 note. The note is the local `.claude` folder, which is untracked and not in the built package from a clone. M057 changes no R file or test, so the first run's error did not come from this diff.
