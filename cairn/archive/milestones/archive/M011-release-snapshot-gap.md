# M011: release_supplement() stops when a file changes during the check

**Status:** done (2026-10-18, PR #12 https://github.com/jmgirard/supplement/pull/12)

**Goal:** `release_supplement()` stops, and writes none of its three files, when `_supplement.yml`, `CITATION.cff`, or `.zenodo.json` changes while `check_supplement()` runs.

**Outcome:** `check_unchanged()` in `R/release-supplement.R` runs right after `check_supplement()` and before `check_release_problems()`. It compares `read_bytes_or_null()` of `_supplement.yml` with the pre-check bytes and a second `read_outputs()` result with the first, and stops with the new class `supplement_error_changed`, naming each changed file. A made or removed file counts as a change; a folder at an output reads as no file both times, and the second `read_outputs()` keeps its link and unreadable refusals. The help page (Details and Errors), NEWS.md, README.md, the template `_README.md`, and DESIGN.md describe the stop and the window that stays: a save after the second read can still be lost. Tests: `mock_check_edit()` edits the site inside the mocked check; `expect_changed_stop()` asserts the class, the named files, `folder_state()`, and no printed commands, over five `_supplement.yml` shapes, five output shapes (two files at once included), the stop order, and a no-change control.

**Decisions:** none promoted. The user chose at the plan gate to stop rather than use the new text, and to cover all three files.

**Review:** criteria audit at plan (8 findings, all fixed), claim audit at implement (24 claims, 6 corrected), one review pass with four lenses (diff-bug, blame-history, prior-review, ripple), 32 findings: 16 fixed on the branch, 8 follow-up, 8 rejected. No returns, no amendments. `R CMD check` 0/0/0. The row "release snapshot gap" graduated. "release edge cases" lost its outputs sentence. New row "release snapshot remainder" holds the remaining window, the folder case, and three gaps that existed before.
