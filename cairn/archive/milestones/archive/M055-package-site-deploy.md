# M055: Tighten the package site and its deploy

**Status:** done (2026-10-25, PR #56 https://github.com/jmgirard/supplement/pull/56)

**Goal:** Make the package site on `gh-pages` match the latest build from main, with the README's guide link opening the guide page on that site.

**Outcome:** `.github/workflows/pkgdown.yaml` triggers on pushes to main, pull requests, and manual runs (the `release` trigger is gone). Its deploy step runs only when `github.ref == 'refs/heads/main'` and uses `clean: true`, so files on `gh-pages` that the build did not make are deleted. The action always keeps `.git`, `.github`, and `.ssh`, and keeps a CNAME or `.nojekyll` the build does not write. The concurrency group is `pkgdown-${{ github.ref == 'refs/heads/main' || github.run_id }}`, so runs that do not deploy cannot cancel a pending main deploy. The opening comment names the deploy events. README.md:15 links the guide at `https://jmgirard.github.io/supplement/articles/publishing.html`, which returns 404 until the user sets Pages to serve `gh-pages`. DESIGN.md's pkgdown paragraph and Conventions line match. No NEWS entry, since no package behavior changed.

**Decisions:** D-026 (deploys only from main, no release deploys, clean deploys; supersedes D-025's list of deploy events).

**Review:** Criteria audit narrowed AC1, AC3, and AC4; the claim audit corrected 1 of 10 claims (the clean comment). Manual run 40181089284 on the branch built the site and skipped the deploy, and its log showed `.nojekyll` and `articles/publishing.html` written. Four-lens review: 15 findings, 5 fixed in c2a968c (non-deploying runs got their own concurrency groups, after GitHub's one-pending-run rule; the concurrency and clean comments; DESIGN.md:53-54), 1 to the new row "Give site builds read-only access", 8 rejected (planned, false, style). `devtools::check()` 0/0/1 (local `.claude` folder); `devtools::test()` 391 tests, 0 failed on a second run, after a first run with 2 unnamed failures, which match the "template test flake" row. CI green on all 7 checks. Graduated "Tighten the package site and its deploy"; pruned the M052 row. No LESSONS line: the concurrency fact lives in the workflow comment.
