# M055: Tighten the package site and its deploy

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the published package site and the README that package users read
- **Branch/PR:** m055-package-site-deploy

## Goal

Make the package site on `gh-pages` match the latest build from main, with the README's guide link opening the guide page on that site.

## Scope

**In:** `.github/workflows/pkgdown.yaml` deploys only from main (a push to main or a manual run on main), drops the `release` trigger, and deploys with `clean: true`; its opening comment says so. README.md's guide link points to `https://jmgirard.github.io/supplement/articles/publishing.html`. A new D-entry supersedes D-025's list of deploy events, and DESIGN.md's pkgdown paragraph matches.

**Out:** turning on GitHub Pages for `gh-pages` (the user, in the repo settings, as D-025 states). Template sites' deploy (D-001, unchanged). Checking web links on the rendered site (candidate row "Check web links on the rendered site").

## Acceptance criteria

- [ ] AC1: In `.github/workflows/pkgdown.yaml` at the branch head, the `on:` block lists `push` (branches `[main]`), `pull_request`, and `workflow_dispatch` and no other event; the `Deploy to GitHub Pages` step's `if:` is `github.ref == 'refs/heads/main'`; and the file's opening comment says that only a push to main or a manual run on main deploys. Shown by reading the file.
- [ ] AC2: One manual run of the workflow on the milestone branch (`gh workflow run pkgdown.yaml --ref <branch>`) ends with conclusion `success`, its `Build site` step `success` and its `Deploy to GitHub Pages` step `skipped`, as `gh run view <id> --json jobs` reports.
- [ ] AC3: The `Deploy to GitHub Pages` step sets `clean: true` and no `clean-exclude`, and the AC2 run's `Build site` log shows `.nojekyll` and `articles/publishing.html` being written.
- [ ] AC4: README.md's guide link target is `https://jmgirard.github.io/supplement/articles/publishing.html`, and `git grep -n 'blob/main/vignettes' <branch-head> -- . ':!cairn'` prints no line.
- [ ] AC5: The profile's verify slot is clean: `Rscript -e 'devtools::test()'` reports 0 failures.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T1
- AC4 → T2
- AC5 → T4

## Tasks

- [x] T1: In `.github/workflows/pkgdown.yaml`, remove the `release` trigger (lines 9-10), set the deploy step's `if:` to `github.ref == 'refs/heads/main'` (line 57), set `clean: true` (line 60), and rewrite the opening comment (lines 1-4) to name the deploy events.
- [ ] T2: Point the guide link at README.md:15 to `https://jmgirard.github.io/supplement/articles/publishing.html`.
- [ ] T3: Append a D-entry that supersedes D-025's list of deploy events (only a push to main or a manual run on main; no release deploy; clean deploys), and update the pkgdown paragraph at `cairn/DESIGN.md:279-285`.
- [ ] T4: Run the verify slot (`Rscript -e 'devtools::test()'`) on the branch.

## Work log

- 2026-10-25: created by /milestone-plan.
- 2026-10-25: tier check: not run — work named at the question set.
- 2026-10-25: idea vet: no concern found; deploying only from main, clean deploys, and a README link to the site's own article are standard pkgdown practice, and the user chose all three at the question set.
- 2026-10-25: lessons used: none.
- 2026-10-25: question set: may the review start one manual run of the site workflow on the branch — yes, one manual run (`gh workflow run`); the run needs the branch pushed before the PR opens, which this answer covers.
- 2026-10-25: question set: where the README guide link points — the site's guide page; the user turns on Pages to serve `gh-pages`, and the link returns 404 until then.
- 2026-10-25: collision check: absorbs candidate "Tighten the package site and its deploy"; M054 (done) built the workflow; D-025 lists release and any-ref manual deploys, so T3 supersedes that clause. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-25: criteria audit (full mode, fresh Opus reader): 5 findings. AC1's comment wording narrowed and the D-025 conflict moved to T3; the redundant `github.event_name != 'pull_request'` dropped from the `if:` (a pull request's ref is `refs/pull/N/merge`); AC3 narrowed from a claim about `gh-pages` after a deploy to the step's settings plus the AC2 build log (the action already excludes a missing `.nojekyll` from `--delete`); AC4's `grep -r` replaced by `git grep` at the branch head; AC2 and AC5 unchanged.
- 2026-10-25: plan gate chose dropping the `release` trigger and deploying only when `github.ref` is main over keeping release deploys gated on the newest tag, because a release is cut from main, whose push already deploys; falsified by a release from a non-main ref that the site must show.
- 2026-10-25: plan gate chose an absolute site URL in README over a separate `pkgdown/index.md` home page, because pkgdown 2.2.1.9000 rewrites only relative `.md` links (`tweak_link_md`) and a second home page would repeat README; falsified by a pkgdown setting that rewrites a README link to a vignette source.
- 2026-10-25: changelog: no NEWS entry, since the change touches the workflow and README only and no package behavior; test scope: no new test, since no R code changes.
- 2026-10-25: implement started on branch m055-package-site-deploy, cut from main at 6c27ec2.
- 2026-10-25: T1 done: `release` trigger removed, deploy `if:` is `github.ref == 'refs/heads/main'`, `clean: true` with a comment from the action's `action.yml` (v4.8.0, line 52); the shared concurrency group of non-PR runs is left as it is, so a manual run on a branch can still wait behind a deploy.

## Decisions

## Review
