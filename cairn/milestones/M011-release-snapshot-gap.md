<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M011: release_supplement() stops when a file changes during the check

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes what the exported `release_supplement()` does and documents
- **Branch/PR:** m011-release-snapshot-gap

## Goal

`release_supplement()` stops, and writes none of its three files, when `_supplement.yml`, `CITATION.cff`, or `.zenodo.json` changes while `check_supplement()` runs.

## Scope

**In:** After `check_supplement()` returns, re-read the raw bytes of `_supplement.yml` and what `read_outputs()` returns for `CITATION.cff` and `.zenodo.json`, and stop with a new class `supplement_error_changed` when any differs from the read before the check. The stop comes before the problem stop. Tests, the help page, NEWS.md, and the DESIGN.md Architecture paragraph.

**Out:** A change saved after the re-read, while the files are written. No locking and no temporary-file rename (RR01 rejected the rename). This window stays and the help names it. A folder made or removed at `CITATION.cff` or `.zenodo.json` during the check, and a link made there during the check → the "release edge cases" row. Builders that take the `supplement` map, and the print step inside the restore guard → the "release write order" row.

## Acceptance criteria

- [x] AC1: When the raw bytes of `_supplement.yml` after `check_supplement()` returns differ from the bytes that `release_supplement()` read before it ran the check, `release_supplement()` stops with an error of classes `supplement_error_changed` and `supplement_error`, not `supplement_error_release_check`, also when `check_supplement()` returned a problem row. The compare reads raw bytes and does not decode them, so a file that is no longer UTF-8 also gives `supplement_error_changed`, and a removed file counts as a difference. The function writes none of `_supplement.yml`, `CITATION.cff`, and `.zenodo.json`, and prints no release commands. Verified by tests in `tests/testthat/test-release-supplement.R` with `check_supplement()` mocked to change the file on disk in these shapes: a changed `paper-title` value, a changed `version` value, a change to a comment only, a removed file, and a changed `paper-title` value with the mock also returning a problem row. Each test asserts the error class, that `folder_state(dir)` equals the state the mock left, and that no captured message contains `git tag`.
- [x] AC2: Every clause of AC1 also holds for `CITATION.cff` and `.zenodo.json`, where the compare reads what `read_outputs()` returns (the bytes of a file, or NULL for an absent file or a folder). A file made where none existed, a changed file, and a removed file each count as a difference. Verified by tests with the mock in three shapes: a changed `CITATION.cff`, a `.zenodo.json` made where none existed, and a removed `CITATION.cff`. Each test asserts the error class, that `folder_state(dir)` equals the state the mock left, and that no captured message contains `git tag`.
- [x] AC3: A release in which none of the three files changes during the check finishes as before: it writes the new version, `CITATION.cff`, and `.zenodo.json`, and prints the commands. Every refusal that runs before `check_supplement()` today still stops before it is called, among them a bad `bump`, no `version:` line, a failed yaml re-read of the changed text, and a link, unreadable, or unwritable output or output folder. Verified by the existing finished-release tests and the existing `calls$n == 0L` tests in `tests/testthat/test-release-supplement.R`.
- [x] AC4: The `release_supplement()` help page no longer says that a change saved to the file while the function runs is lost. It says that the function stops, and writes none of the three files, when `_supplement.yml`, `CITATION.cff`, or `.zenodo.json` changes while `check_supplement()` runs. It also says that a change saved after the check, while the files are written, can still be lost. Its Errors section lists `supplement_error_changed`. The `release_supplement()` bullet in NEWS.md and the `R/release-supplement.R` paragraph of `cairn/DESIGN.md` Architecture name the stop. Verified by reading those sentences in `man/release_supplement.Rd`, NEWS.md, and DESIGN.md after `devtools::document()`.
- [x] AC5: After `devtools::document()`, `git diff -- man NAMESPACE` is empty, `devtools::test()` reports 0 failures, and `devtools::check()` reports 0 errors and 0 warnings.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T2, T4
- AC4 → T3
- AC5 → T4

## Tasks

- [x] T1: Add a mock helper to `tests/testthat/test-release-supplement.R` that runs a function on the site folder inside the mocked `check_supplement()`, then write the AC1 and AC2 tests. Run them against the code on main and see each one fail for the reason it names.
- [x] T2: In `release_supplement()` (`R/release-supplement.R:151`), right after `check_supplement()` returns and before `check_release_problems()`, read the raw bytes of `_supplement.yml` and call `read_outputs()` again, and stop with `supplement_error_changed` when any value is not `identical()` to its pre-check value. Leave the refusals before the check where they are.
- [x] T3: Update the help page text at `R/release-supplement.R:26-42` and its Errors section, the NEWS.md `release_supplement()` bullet, and the DESIGN.md Architecture paragraph. Run `devtools::document()`.
- [x] T4: Run `devtools::test()` and `devtools::check()`, and confirm `git diff -- man NAMESPACE` is empty after `devtools::document()`.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — the fix changes documented behavior (the help page says a saved change is lost) and adds an error class.
- 2026-10-18: absorbed candidate "release snapshot gap" in full and the outputs sentence of "release edge cases" in part; "release write order" touches the same function and stays a separate row.
- 2026-10-18: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-18: lessons applied: M009 (criteria as a stated rule plus listed test shapes), M010 (prove a test can fail against main).
- 2026-10-18: question set: on a change during the check — stop with a new error class (not use the new text).
- 2026-10-18: question set: cover CITATION.cff and .zenodo.json too — yes, all three files.
- 2026-10-18: plan gate chose stop over re-reading the new text because the check ran on the old text; falsified by a check result that does not depend on `_supplement.yml`.
- 2026-10-18: plan gate chose a post-check re-read and compare over moving the reads below the check because the early refusals must stay before the slow check; falsified by evidence that no caller relies on refusals coming first.
- 2026-10-18: agent decided a new class `supplement_error_changed` over reusing `supplement_error_yaml`, which means a failed text edit.
- 2026-10-18: criteria audit (full mode, fresh Opus reader): 8 findings, all fixed: folder_state and no-commands asserts, change stop before problem stop with a probe, comment-only probe and raw-byte compare, three output probes, folder and link cases moved out, AC3 bound to the function, AC4 names the remaining window, AC5 diff target.
- 2026-10-18: changelog: edit the existing NEWS.md `release_supplement()` bullet, since the package is unreleased.
- 2026-10-18: implement started on branch m011-release-snapshot-gap; tree clean at the cut.
- 2026-10-18: T1 done: `mock_check_edit()` and `expect_changed_stop()` plus four tests (five yml shapes, the order probe, three output shapes, a no-change control); on main the change tests fail 20 and 12 times (the release finishes), the order probe stops with `supplement_error_release_check`, and the control passes.
- 2026-10-18: T2 done: `check_unchanged()` in `R/release-supplement.R`, called between `check_supplement()` and `check_release_problems()`, compares `read_bytes_or_null()` of `_supplement.yml` and a second `read_outputs()` call with the pre-check values; the message names each changed file. devtools::test(): 219 tests, 0 failures, 1 skip.
- 2026-10-18: agent decided the second `read_outputs()` call keeps its refusals, so a link made at an output during the check stops with `supplement_error_file_exists`; no criterion promises it and the "release edge cases" row keeps the case.
- 2026-10-18: T3 done: help Details paragraph (the stop, and that a change saved while the files are written can still be lost) and an Errors item for `supplement_error_changed`, the NEWS.md bullet, and the DESIGN.md Architecture paragraph; `devtools::document()` rewrote only `man/release_supplement.Rd`.
- 2026-10-18: T4 done: after `devtools::document()`, `git diff -- man NAMESPACE` is empty; devtools::test() 219 tests, 0 failures, 1 skip; devtools::check() 0 errors, 0 warnings, 0 notes.
- 2026-10-18: claim audit: 24 claims read, 6 corrected — R/release-supplement.R, man/release_supplement.Rd, NEWS.md, tests/testthat/test-release-supplement.R (the folder case named in the help, the link and unreadable errors that come first, the window named from the second read to the end, NEWS narrowed to changes saved during the check, two comments); the same reader re-read the six and found that each holds; devtools::test() after: 219 tests, 0 failures.
- 2026-10-18: the help names the remaining window as "after the function reads the files again, until it finishes", which covers AC4's "after the check, while the files are written" and is what the code does; no criterion text changed.
- 2026-10-18: status review; all tasks checked, verify clean.

## Decisions

## Review

Pass 1, 2026-10-18, branch head 2914730, main not moved since the cut.

- AC1 evidence: `test_file(test-release-supplement.R)`: "a change to _supplement.yml during the check stops the release" 25 expectations, 0 failures (five shapes: title, version, comment only, removed, not UTF-8), and "the change stop comes before the stop for a problem from check_supplement()" 5 expectations, 0 failures; each runs `expect_changed_stop()`, which asserts class `supplement_error_changed` and `supplement_error`, `folder_state(dir)` equal to the state the mock left, and no message with `git tag`. On main (T1) these failed 20 times and with `supplement_error_release_check`.
- AC2 evidence: "a change to CITATION.cff or .zenodo.json during the check stops the release" 15 expectations, 0 failures (changed `CITATION.cff`, `.zenodo.json` made where none existed, removed `CITATION.cff`), through the same `expect_changed_stop()` asserts; `check_unchanged()` compares a second `read_outputs()` result with the pre-check one. On main (T1) it failed 12 times.
- AC3 evidence: the release test file runs 33 tests, 0 failures, 0 errors; `git diff main...HEAD -- tests/` removes 0 lines, so every pre-existing test, the finished-release tests and the `calls$n == 0L` tests included, runs as it was and passes; the no-change control "a check that reads the files but changes none lets the release finish" passes (4 expectations). `check_unchanged()` is called after `check_supplement()` (R/release-supplement.R), so the earlier refusals keep their place.
- AC4 evidence: `grep 'is lost'` finds nothing in `man/release_supplement.Rd` or `R/release-supplement.R`. `man/release_supplement.Rd:52-58` says the function stops and "writes none of the three files" when one changed while the check ran, and that a change saved "after the function reads the files again, until it finishes, can still be lost", which includes a change saved while the files are written. `:108` lists `supplement_error_changed` in Errors. NEWS.md:32-35 and DESIGN.md:91-92 name the stop.
- AC5 evidence: after `devtools::document()`, `git diff -- man NAMESPACE` is 0 lines; `devtools::test()` 219 tests, 0 failures, 0 errors, 1 skip; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- Gate: `cairn_validate.py` all checks passed; no principle changed, so no `cairn_impact`; `document()` no diff; no README.Rmd and no `_pkgdown.yml`; NEWS.md has the entry; no new top-level files; R CMD check clean.
