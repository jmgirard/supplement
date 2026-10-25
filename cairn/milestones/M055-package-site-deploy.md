# M055: Tighten the package site and its deploy

- **Status:** review
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

- [x] AC1: In `.github/workflows/pkgdown.yaml` at the branch head, the `on:` block lists `push` (branches `[main]`), `pull_request`, and `workflow_dispatch` and no other event; the `Deploy to GitHub Pages` step's `if:` is `github.ref == 'refs/heads/main'`; and the file's opening comment says that only a push to main or a manual run on main deploys. Shown by reading the file.
- [x] AC2: One manual run of the workflow on the milestone branch (`gh workflow run pkgdown.yaml --ref <branch>`) ends with conclusion `success`, its `Build site` step `success` and its `Deploy to GitHub Pages` step `skipped`, as `gh run view <id> --json jobs` reports.
- [x] AC3: The `Deploy to GitHub Pages` step sets `clean: true` and no `clean-exclude`, and the AC2 run's `Build site` log shows `.nojekyll` and `articles/publishing.html` being written.
- [x] AC4: README.md's guide link target is `https://jmgirard.github.io/supplement/articles/publishing.html`, and `git grep -n 'blob/main/vignettes' <branch-head> -- . ':!cairn'` prints no line.
- [ ] AC5: The profile's verify slot is clean: `Rscript -e 'devtools::test()'` reports 0 failures.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T1
- AC4 → T2
- AC5 → T4

## Tasks

- [x] T1: In `.github/workflows/pkgdown.yaml`, remove the `release` trigger (lines 9-10), set the deploy step's `if:` to `github.ref == 'refs/heads/main'` (line 57), set `clean: true` (line 60), and rewrite the opening comment (lines 1-4) to name the deploy events.
- [x] T2: Point the guide link at README.md:15 to `https://jmgirard.github.io/supplement/articles/publishing.html`.
- [x] T3: Append a D-entry that supersedes D-025's list of deploy events (only a push to main or a manual run on main; no release deploy; clean deploys), and update the pkgdown paragraph at `cairn/DESIGN.md:279-285`.
- [x] T4: Run the verify slot (`Rscript -e 'devtools::test()'`) on the branch.

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
- 2026-10-25: T2 done: README.md:15 links the guide at `https://jmgirard.github.io/supplement/articles/publishing.html`; README.md has no README.Rmd source, so no render step.
- 2026-10-25: T3 done: D-026 supersedes D-025's list of deploy events; the DESIGN.md pkgdown paragraph names the three triggers, the main-only deploy, and `clean: true`. The Conventions line at DESIGN.md:52-54 cites D-025 for the gh-pages push and stays true.
- 2026-10-25: claim audit: 10 claims read, 1 corrected — .github/workflows/pkgdown.yaml (the clean comment now says the action keeps `.git`, `.github`, and a CNAME the build does not write, read from the action's `src/git.ts` lines 172-194 at d92aa23), README.md. The re-read of the corrected comment found that it holds.
- 2026-10-25: T4 done: `devtools::test()` on the Mac at c1e0858 gave 391 tests, 0 failed, 0 errors, 10 skipped; d1b374c after it changes a workflow comment only. Status set to review.

## Decisions

## Review

- AC1: `git show 894396e:.github/workflows/pkgdown.yaml` shows `on:` with `push` (branches `[main]`), `pull_request`, `workflow_dispatch` and no other event, the deploy step's `if: github.ref == 'refs/heads/main'` (line 58), and lines 1-4 saying only a push to main or a manual run on main pushes to `gh-pages`. Pass.
- AC2: manual run 40181089284 (`gh workflow run pkgdown.yaml --ref m055-package-site-deploy`, head 894396e): conclusion `success`, `Build site` `success`, `Deploy to GitHub Pages` `skipped` (`gh run view --json jobs`). Pass.
- AC3: the deploy step sets `clean: true` (line 61) and no `clean-exclude`; run 40181089284's `Build site` log holds "Writing `articles/publishing.html`" and "Writing `.nojekyll`". Pass.
- AC4: README.md:15 at 894396e links `https://jmgirard.github.io/supplement/articles/publishing.html`; `git grep -n 'blob/main/vignettes' HEAD -- . ':!cairn'` printed no line (exit 1). Pass.
- Gate: `cairn_validate.py` all checks passed; no principle changed, so no `cairn_impact`; `devtools::document()` left no diff; no README.Rmd; `pkgdown::check_pkgdown()` "No problems found"; `devtools::check()` 0 errors, 0 warnings, 1 NOTE (the local untracked `.claude` folder, as in M054); no new top-level files; no NEWS entry, since no package behavior changed and NEWS.md:3-6 already names the site.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the shared concurrency group lets a manual run on another branch, which never deploys, cancel a pending main deploy (GitHub keeps one pending run per group, docs read 2026-10-25) — fix now, fixed c2a968c
- diff-bug #2: the concurrency comment "Only one deploy runs at a time; pull request builds run in parallel" no longer says which runs share the group — fix now (with #1), fixed c2a968c
- diff-bug #3: the README link returns 404 until Pages is on — reject, planned change (the user chose it at the question set, work log line 6)
- diff-bug #4: the clean comment omits `.ssh` and a `.nojekyll` the build does not write, which the action also keeps — fix now, fixed c2a968c
- diff-bug #5: `clean: true` is the action's default, so the line is redundant — reject, style
- diff-bug #6: D-026's consequence understates the change, since no release triggers the workflow — reject, false (D-026's Decision says the `release` trigger is removed)
- diff-bug #7: PR and branch runs keep `contents: write`, though only main runs deploy — follow-up, new row "Give site builds read-only access" (predates the branch)
- diff-bug #8: AC2 and AC3 were unproven when it read — reject, false (run 40181089284 above)
- blame-history #1: the README link resolves only after Pages is on, and no record says so — reject, false (work log line 6 records it) and planned change
- blame-history #2: `clean: true` replaces a value copied from the r-lib example with no decision behind it — reject, planned change (D-026)
- blame-history #3: a release tagged on a commit that never reached main no longer redeploys — reject, planned change (the plan's rejected-alternative line names that case as the falsifier)
- blame-history #4: a manual run on a branch shares the deploy group — fix now (same fix as diff-bug #1), fixed c2a968c
- prior-review: no regression; the three M054 findings this milestone took are each addressed (M054 archive line 11), and the PR comment probe returned `[]` — noted
- ripple #1: vignettes/publishing.Rmd:112-114 says to serve the pushed branch's `/docs` folder, unlike `gh-pages` — reject, false (that step is for the reader's own template site, D-001)
- ripple #2: cairn/DESIGN.md:53-54 says the workflow pushes to `gh-pages` with no condition — fix now, fixed c2a968c
