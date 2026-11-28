# M040: Align the remaining render advice

**Status:** done (2026-10-23, PR #41 https://github.com/jmgirard/supplement/pull/41)

**Goal:** Each place that this milestone lists gives the guide's steps for its case: a changed report, a new figure name, or a report with no stored output.

**Outcome:** In `inst/template/_quarto.yml`, the comment above `render:` gives the steps for a changed report: render it by name, render the whole site, then commit it with `_freeze/`, `docs/`, and `figures/`. The comment above `resources:` says to render the whole site again after a new figure name, then commit `figures/`, `docs/`, and `_freeze/`. The `no-stored-output` row text of `check_supplement()` ends with `rerender_steps` and one more sentence: "If you added the report to the Analyses menu, as add_report() does, also commit _quarto.yml." The `stale-output` texts are unchanged. Tests assert the new ending with `endsWith()` and that neither stale text names `_quarto.yml`. In `NEWS.md`, the publishing-guide bullet gains the commit step, and the `check_supplement()` bullet names the `_quarto.yml` step.

**Decisions:** none cross-cutting. Plan gate: no `figures/` leave-out note in the YAML comment, because it points to the guide that carries one; the `_quarto.yml` sentence goes in the `no-stored-output` row only; T5's grep files new rows in place of a grep-and-classify criterion.

**Review:** Criteria audit at plan (full mode): 6 findings, all taken. Claim audit: 11 claims, 1 corrected twice (the NEWS sentence now quotes the row's condition). One four-lens pass, 16 findings: 5 fixed (eaf6374, a stale test comment and ragged NEWS lines), 9 rejected, and 2 to the new row "Correct two older render notes". `devtools::check()` 0/0/0 with 5021 tests passing. CI passed on all six jobs, one Ubuntu job after 32 minutes. Graduated the row "Align the remaining render advice". No lesson added.
