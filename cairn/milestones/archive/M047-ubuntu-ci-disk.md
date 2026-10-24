# M047: Keep the Ubuntu CI job within its disk

**Status:** done (2026-10-24, PR #48 https://github.com/jmgirard/supplement/pull/48)

**Goal:** The ubuntu-latest CI job runs the render tests with R's temporary folder on the runner's disk, so the job passes on the ubuntu-26.04 image.

**Outcome:** ubuntu-latest moved from ubuntu-24.04 to ubuntu-26.04, where `/tmp` is a 7.9 GB tmpfs with `usrquota`. The shortcode size-fixture test's 1.0, 2.1, and 4.3 GB data files, copied by Quarto into `docs/`, filled it, and pandoc stopped with "hPutBuf: permission denied (Quota exceeded)". `.github/workflows/R-CMD-check.yaml` gained a Linux-only step, "Put the temporary folder on the runner's disk", after checkout: it makes `$RUNNER_TEMP/tmp` and writes `TMPDIR` to `$GITHUB_ENV`. A one-time diagnostic step (`findmnt`, `df`) confirmed the cause in branch run 40055150456 and was removed. DESIGN.md's CI paragraph states the reason. The feature PR cap in `cairn/PROFILE.md` was raised to 2 (8584efa), because PR #47 (M046) held the one slot and waits on this fix.

**Decisions:** none. The user chose `TMPDIR` on the runner's disk over pinning ubuntu-24.04 (D-016's ubuntu-latest stands), and allowed one early diagnostic push.

**Review:** Criteria audit at plan (reduced mode): 2 findings, both fixed. Four-lens review: 10 findings, 3 fix-now (fixed 1ee63cd: exact workflow comment, run number dropped from DESIGN, evidence line numbers), 0 follow-up, 6 rejected (4 false, 2 planned), 1 noted; prior-review found no evidence. `devtools::check()` 0/0/0 on macOS. PR #48 CI passed on all six checks (Ubuntu 12m36s and 21m7s). Graduated the candidate row "Keep the Ubuntu CI job within its disk". Extended the M018 runner lesson.
