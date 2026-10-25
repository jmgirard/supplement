# M056: Give site builds read-only access

**Status:** done (2026-10-25, PR #57 https://github.com/jmgirard/supplement/pull/57)

**Goal:** Run every build of the package site with a read-only token, so that only the deploy from main holds write access.

**Outcome:** `.github/workflows/pkgdown.yaml` has two jobs. `build` runs on every trigger with `contents: read`, keeps the Quarto, Pandoc, R, dependency, `Leave CLAUDE.md off the site`, and `Build site` steps, and uploads `docs/` as artifact `site` with `actions/upload-artifact@v7` (`include-hidden-files: true` for `.nojekyll`, `if-no-files-found: error`, `retention-days: 1`). `deploy` (`needs: build`, `if: github.ref == 'refs/heads/main'`, `contents: write`) runs `actions/checkout@v7`, `actions/download-artifact@v8` to `docs`, then the unchanged SHA-pinned JamesIves step with `clean: true`. The concurrency group moved to the workflow level with the same expression. Workflow-level `permissions: read-all` stays as the default. The opening comment and DESIGN.md's pkgdown paragraph name each job's access. No NEWS entry, since no package behavior changed.

**Decisions:** none. D-025 and D-026 stand.

**Review:** Reduced criteria audit fixed 3 findings at plan (AC2 and AC3 narrowed; the hidden-file upload gap added to AC2 and T1). Evidence: run 40228325533 at the head (build read-only, deploy skipped, artifact holds `.nojekyll`); dry-run probe 40228005061 ran the deploy job on the branch with every step `success`, reverted in 9d31e99; a full re-run (attempt 2) re-uploaded `site` with no conflict. `devtools::check()` 0/0/1 (local `.claude`); `devtools::test()` 391 tests, 0 failed. Four-lens review: 14 findings, 4 fixed in 4eaa49d (a comment on the one-day artifact life; the DESIGN.md "so" sentence), 2 to the new row "Pin the deploy job's actions by SHA", 8 rejected (false, planned, style). CI green on 7 checks. Graduated "Give site builds read-only access"; pruned the M053 row. No LESSONS line: the hidden-file fact lives in the workflow comment. The M019 lesson took no `used` mark, since it is over 450 bytes (see `/cairn-triage lessons`).
