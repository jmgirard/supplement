# M009: release_supplement() raises the version and prints release commands

- **Status:** in-progress
- **Priority:** high
- **Depends on:** M008
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a new exported R function and a new `_supplement.yml` field
- **Branch/PR:** m009-release-supplement

## Goal

Export `release_supplement()`, which raises the site version in `_supplement.yml` after `check_supplement()` finds no problem and prints the commands that make the release.

## Scope

**In:** A `version` field in the template's `_supplement.yml`, which `write_citation()` and `write_zenodo()` write. `release_supplement(bump, path = ".")` runs `check_supplement()`, raises the version, writes `CITATION.cff` and `.zenodo.json` again, and prints the git and GitHub commands for the author to run. It runs none of them. Tests, a help page, README, `_README.md`, NEWS, and DESIGN text.

**Out:**
- The checks themselves: M008.
- A release date in `CITATION.cff` (`date-released`): not planned. Add a candidate row if it is needed.
- Calls to the GitHub or Zenodo API: out of scope for version 1 (DESIGN Purpose & Scope).

## Acceptance criteria

- [x] AC1: The template's `_supplement.yml` has `version: ""` under `supplement:`, with a comment. `write_citation()` writes `version` to `CITATION.cff`, and `write_zenodo()` writes `version` to `.zenodo.json`, with the value of `supplement.version` when it is not empty. Both leave the field out when it is empty. Both stop with `supplement_error_version` for a value that is not three whole numbers joined by `.`, each `0` or without a leading zero. A test writes `1.0.0` and `0.10.2` to both files and reads them back, and it fires the error for `1.0`, `v1.0.0`, `01.0.0`, `1.0.0-rc1`, and `1. 0.0`.
- [x] AC2: `release_supplement(bump, path = ".")` takes `bump` as `"patch"`, `"minor"`, `"major"`, or a version in the AC1 form. A word raises that part of the current version by 1 and sets the parts after it to 0. An empty current version counts as `0.0.0`. A version in `bump` must be greater than the current version, part by part as numbers. It stops with `supplement_error_argument` for any other `bump`, with `supplement_error_version` for a version that is not greater or a current version not in the AC1 form, and with `supplement_error_field_type` for a current version that YAML reads as a number, such as an unquoted `1.10`. A test checks: `1.2.3` with each word, `0.9.9` with `"major"` (`1.0.0`), `1.9.0` with `"minor"` (`1.10.0`), an empty version with `"patch"` (`0.0.1`), `1.2.3` with `"1.10.0"` (accepted), and `1.2.3` with `"1.2.3"` and `"1.2.2"` (refused).
- [x] AC3: Before it writes, the function runs `check_supplement()`. It stops with `supplement_error_release_check`, and gives the number of problems, when the result's `skipped` attribute is not empty or the result has a row other than a `"doi-mismatch"` row for `CITATION.cff`, which the release writes again. When `_supplement.yml` has no `version:` key with a one-line value at the child indent of the block-style `supplement:` map, it stops with `supplement_error_no_version` and shows the line to add by hand. A test fires each error, and a release that only a `CITATION.cff` DOI row would block, and finds the file list and the bytes of every file in the site the same after each error.
- [x] AC4: The function changes only the value on that `version:` line and writes the new value in double quotes. A byte comparison finds every other byte of `_supplement.yml` the same. Before the write, the yaml package reads the changed text, and the function stops unless the result is the old map with the new version. A test uses the template's file, a file with a comment after the value, a file with CRLF line endings, a single-quoted value, and an unquoted value.
- [ ] AC5: The function then writes `CITATION.cff` and `.zenodo.json` with `overwrite = TRUE`, and both hold the new version. If any step after the `_supplement.yml` write stops, for any reason, the function puts back the old bytes of each file it changed, removes each file it made, and stops. A test reads both files after a release. It mocks a failing write of `CITATION.cff` and a failing write of `.zenodo.json`, and uses an empty `citation`, which stops `write_zenodo()`. Each time it finds the three files as they were before.
- [x] AC6: The function prints, and returns invisibly as a character vector, the commands for version `X.Y.Z`: `git status`, `git add -A`, `git commit -m "Release vX.Y.Z"`, `git tag vX.Y.Z`, `git push`, `git push origin vX.Y.Z`, and `gh release create vX.Y.Z --generate-notes`. `git add -A` adds the files that `check_supplement()` checked, so `docs/` and `_freeze/` reach the tagged commit. It also prints that, after Zenodo archives the release, the author adds the new version DOI to `_supplement.yml` and renders the site again. `R/release-supplement.R` does not call M008's git helper, so the function starts git only through `check_supplement()`, which M008's AC3 search covers.
- [x] AC7: The package README and the template's `_README.md` describe `release_supplement()` and the `version` field. Its help page has an example in `\dontrun{}`, because the function needs a rendered site in a git repository. NEWS.md has an entry for the function and the field.

## Coverage

- AC1 → T1
- AC2 → T3, T4
- AC3 → T3, T4, T6
- AC4 → T2, T3, T4
- AC5 → T3, T4
- AC6 → T3, T4
- AC7 → T5

## Tasks

- [x] T1: Add `version: ""` with a comment to `inst/template/_supplement.yml`. Add a version check to `R/supplement-yml.R`, and write `version` in `R/write-citation.R` and `R/write-zenodo.R`. Cite the CFF 1.2.0 schema and Zenodo's deposit metadata in code comments. Add the AC1 tests and update the two help pages.
- [x] T2: Add a helper to `R/yaml-insert.R` that replaces the value on one line of a block-style map and checks the result with the yaml package, as D-010 asks of inserts. Test it directly against the AC4 fixture files. Append a D-entry that extends D-010 to a one-line value change.
- [x] T3: Write `tests/testthat/test-release-supplement.R` for AC2 to AC6. Mock `check_supplement()`, so the tests need no render, and add one test that searches `R/release-supplement.R` for the git helper's name.
- [x] T4: Write `R/release-supplement.R`. Check `bump`, `_supplement.yml`, and the `version:` line before `check_supplement()` runs, and reuse `write_checked()` from `R/yaml-insert.R` for the restore.
- [x] T5: Add roxygen documentation and run `devtools::document()`. Describe the function and the field in `README.md` and `inst/template/_README.md`, add a NEWS.md entry, and update DESIGN.md Architecture.
- [x] T6: Make the `supplement_error_release_check` message give the number of problems also when only the git checks were skipped, and test it (review return 1).

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: not run — work named at the question set.
- 2026-10-18: question set: where the site version lives — a new `supplement.version` value in `_supplement.yml` that `write_citation()` and `write_zenodo()` also write.
- 2026-10-18: question set: what `check_supplement()` does on a problem — return the problems with no error; `release_supplement()` stops when the list is not empty.
- 2026-10-18: plan split the "release checks" row: M008 covers `check_supplement()`, and M009 covers `release_supplement()` and the site version.
- 2026-10-18: plan chose `bump` as a word or a version over a word only, because a site's first release is often `1.0.0`, which no word reaches from `0.0.0` but `"major"`; falsified by authors who never give a version by hand.
- 2026-10-18: plan chose to stop with the line to add when a site has no `version:` line over inserting it, because D-010's insert finds lists, not single keys; falsified by sites made before this field that authors find hard to fix by hand.
- 2026-10-18: criteria audit (full mode, fresh Opus reader) returned 11 findings across M008 and M009, 5 on M009. Fixed all: AC3 also stops when a check was skipped, ignores the `CITATION.cff` DOI row that the release fixes, and defines the `version:` line by indent; AC2 stops on a current version that is invalid or read as a number; AC5 restores on any stop after the first write and probes three failures; AC6 prints `git status` and `git add -A`, so `docs/` and `_freeze/` reach the tag, and its process promise is now a property of the code, not of a mock.
- 2026-10-18: plan chose to print `git add -A` over a release stop on uncommitted files, because the stop needs a git command outside M008's read list and `git add -A` adds the same files that `check_supplement()` checked; falsified by sites where authors keep unignored work files that must not reach the release.
- 2026-10-18: collision check: D-010 covers YAML edits by line inserts only, so T2 appends a D-entry that extends it to a one-line value change under the same re-read check.
- 2026-10-18: implement started on branch m009-release-supplement.
- 2026-10-18: T1 done: `read_version()` in `R/supplement-yml.R`, `version` written after `title` in both files; the error tests also refuse `1.00.0`, `1.0.0.0`, and `-1.0.0`; 1448 tests pass.
- 2026-10-18: T2 done: `yaml_replace_lines()` and `yaml_replaced()` in `R/yaml-insert.R`, with the re-read moved to `yaml_read_lines()`; an empty value (`version:`) is also replaced; D-011 extends D-010.
- 2026-10-18: T2 checkpoint commit c2759a3 went in after a `devtools::test()` run with 3 failures at `test-template.R:140` (`git check-ignore` output not empty); two later full runs and three runs of that file passed, so the failure did not repeat and its cause is unknown.
- 2026-10-18: T3 done: `tests/testthat/test-release-supplement.R` mocks `check_supplement()`; planted defects (no restore, DOI row counted, skipped checks ignored, versions compared as text) each turn tests red.
- 2026-10-18: T4 done: `R/release-supplement.R`. Choices: parts compare by length then as text, so parts beyond R's whole numbers stay exact; a failed write stops with a new class `supplement_error_release_write` whose `parent` is the write's error; a failed re-read stops with `supplement_error_yaml`, as in `add_report()`; the no-version error shows the line with the current value; an empty `version:` line is replaced; 1672 tests pass.
- 2026-10-18: T5 done: README "Make a release" section, template `_README.md` "Make a release" section and version mentions, NEWS entries, DESIGN Architecture lines; no `_pkgdown.yml` exists, so no reference row. A real run on a rendered `create_supplement()` site in a git repository found no problems, set `1.0.0` in all three files, and printed the seven commands.
- 2026-10-18: claim audit: 84 claims read, 9 corrected — R/release-supplement.R, man/release_supplement.Rd, README.md, inst/template/_README.md, NEWS.md
- 2026-10-18: after the audit: a write-back that fails is now named in the `supplement_error_release_write` message (new test), and `compare_versions()` compares the first differing digit as a number, not by locale text order; 1676 tests pass.
- 2026-10-18: claim audit found that `git add -A` stages the whole repository while `check_supplement()` reads the site folder only, so AC6's "adds the files that check_supplement() checked" holds only for a site at the top of its repository; the help page says so, and a "release from a subfolder" candidate row holds the fix.
- 2026-10-18: status review; handing off to /milestone-review.
- 2026-10-18: review return 1: AC3 fails as written: when `check_supplement()` skipped its git checks and found no blocking row, the `supplement_error_release_check` message names the skipped checks but does not give the number of problems; every other criterion's tests pass, `cairn_validate` passes, `document()` makes no diff, and `devtools::check()` gives 0 errors, 0 warnings, 0 notes.
- 2026-10-18: implement resumed for review return 1; added T6 (minor amendment) and mapped AC3 to it.
- 2026-10-18: T6 done: the release-check message always opens with the number of problems ("found 0 problems …" when only the git checks were skipped); the skipped-checks test now asserts the number in both cases; 1680 tests pass; status review.
- 2026-10-18: claim audit: 3 claims read, 0 corrected — R/release-supplement.R, tests/testthat/test-release-supplement.R (the T6 diff, same reader); its note that the hint "Fix the problems that check_supplement() printed" is wrong when only checks were skipped led to "Fix what check_supplement() printed".
- 2026-10-18: review return 2: AC5 fails as written: a dangling-link `CITATION.cff` gets a target file outside the site that a failed release does not remove (diff-bug #1), and a failure while printing the commands is not rolled back (diff-bug #11); the return also carries the fix-now findings diff-bug #2, #3, #4, #6, #9, #12, and blame-history #1 (Review section).

## Review

Pass 2 (after review return 1), on b7bff12, main not moved since the cut.

- AC1: `inst/template/_supplement.yml:12-15` has `version: ""` under `supplement:` with a three-line comment. test-write-metadata.R (17 tests, 0 failed) writes `1.0.0`, `0.10.2`, `0.0.0`, and `12.345.6789` to both files and reads them back, and finds no `version` in either file for empty, absent, null, and template values. test-write-metadata-errors.R (21 tests, 0 failed) fires `supplement_error_version` in both writers for `1.0`, `v1.0.0`, `01.0.0`, `1.0.0-rc1`, `1. 0.0`, and three more.
- AC2: test-release-supplement.R (18 tests, 159 expectations, 0 failed) covers `1.2.3` with each word (`1.2.4`, `1.3.0`, `2.0.0`), `0.9.9` major (`1.0.0`), `1.9.0` minor (`1.10.0`), empty patch (`0.0.1`), `1.2.3` with `"1.10.0"` accepted, and `"1.2.3"` and `"1.2.2"` refused with `supplement_error_version`. Twelve other `bump` values give `supplement_error_argument`. A current `01.0.0` or `1.0` gives `supplement_error_version`, and an unquoted `1.10` or `2` gives `supplement_error_field_type`.
- AC3: `release_supplement()` calls `check_supplement()` before `write_release_files()` (R/release-supplement.R). The tests fire `supplement_error_release_check` for 3 rows ("2 problems", which leaves out the `CITATION.cff` DOI row), for one row of each of the 5 other checks ("1 problem"), and for skipped checks ("0 problems", and "1 problem" when skipped with a row). A release with only the `CITATION.cff` DOI row goes ahead. A missing `version:` line and a `|` block value give `supplement_error_no_version`, and the message shows the line to add. After each error, `folder_state()` finds the same file list and bytes.
- AC4: The "only the value on the version line changes" test compares the whole `_supplement.yml` byte for byte against the old bytes with the one line replaced by `version: "0.1.0"`. It does this for the template's file, a comment after the value, a single-quoted value, and an unquoted value, each with LF and with CRLF line endings (8 cases). `yaml_replaced()` runs before the write, and a mocked `FALSE` stops with `supplement_error_yaml` and no file changed. test-yaml-insert.R (24 tests, 0 failed) tests the helper directly on the same shapes and on 13 shapes that it must not find.
- AC5: `write_release_files()` calls `write_citation(path, overwrite = TRUE)` and `write_zenodo(path, overwrite = TRUE)`. After a release, both files hold `2.0.0`. A mocked failing `write_utf8()` for `CITATION.cff`, and then for `.zenodo.json`, each with the two files present and absent (4 cases), and an empty `citation` that stops `write_zenodo()` with `supplement_error_missing_field`, each leave `folder_state()` as before. The error class is `supplement_error_release_write`, with the write's error as `parent`. A planted no-restore defect turned 2 tests red (work log, T3).
- AC6: The commands test finds the returned vector identical to the seven commands for `1.3.0`, finds each one in the printed messages with "version-doi" and "render", and finds the result invisible. A real run on a rendered site in a git repository printed the same seven commands for `1.0.0` (work log, T5). `release_commands()` holds `git add -A`, and `check_supplement()` lists the files with `git ls-files --cached --others --exclude-standard`, the files that `git add -A` stages in the site folder. The search test finds no `git_run`, `git_files`, `system`, `system2`, `processx`, `callr`, or `shell` call in R/release-supplement.R, and the same pattern finds `git_run(` in R/check-supplement.R. For a site in a subfolder, `git add -A` also stages files outside it. That case is the "release from a subfolder" candidate row.
- AC7: README.md has a "Make a release" section on `release_supplement()` and the `version` field. inst/template/_README.md names the site version in its field list and in "Citation files", and has a "Make a release" section. man/release_supplement.Rd:104 holds the example in `\dontrun{`. NEWS.md has an entry for the function and one for the field.
- Gate: `cairn_validate` all checks passed. `devtools::document()` makes no diff. There is no README.Rmd and no `_pkgdown.yml`. NEWS.md has the entries, with no milestone numbers. `.Rbuildignore` needs no new entry, because no new top-level file exists. `devtools::check()`: 0 errors, 0 warnings, 0 notes. `devtools::test()`: 1680 passed, 0 failed, 1 skipped (a disk that ignores case). No principle changed, so `cairn_impact` was skipped.
- spawned: diff-bug, blame-history, prior-review
- diff-bug #1: a dangling-link `CITATION.cff` (or `.zenodo.json`) passes the check as an exempt DOI row, `write_citation()` creates the link's target outside the site, and a later failed write leaves that file while the message says nothing changed — fix now (shows AC5 failing: a file the release made is not removed; floor return 2).
- diff-bug #2: a write that only warns (a full disk) leaves a truncated `CITATION.cff` or `.zenodo.json` and the release reports success, because `write_utf8()` checks neither warnings nor size — fix now.
- diff-bug #3: `restore()` rewrites all three files even when the failure came before any change, so a read-only `_supplement.yml` gives "could not be put back" for a file that never changed — fix now.
- diff-bug #4: after an interrupt, a failed put-back is not reported — fix now.
- diff-bug #5: `version: " 1.0.0 "` is accepted as `1.0.0` — reject (false): every value in `_supplement.yml` is read with outer spaces removed (the documented rule of `write_citation()` and AC1's own "not empty" test), so the value is `1.0.0`.
- diff-bug #6: a `CITATION.cff` that cannot be read gives R's unclassed "cannot open file" error, against the Errors section — fix now.
- diff-bug #7: a folder-shaped output or an empty `citation` is found only after `_supplement.yml` is written, then rolled back — reject (planned change): AC5 specifies this rollback and probes it with an empty `citation`.
- diff-bug #8: `version\t: "1.0.0"` (a tab before the colon) is valid YAML but gives `supplement_error_no_version`, and the hint invites a duplicate key — follow-up: "release edge cases" candidate row.
- diff-bug #9: for an empty version, the not-greater message calls the current version "0.0.0" — fix now.
- diff-bug #10: the exempt `CITATION.cff` row lets the release replace a hand-made `CITATION.cff` without notice — reject (planned change): AC3 and AC5 make the release write that file again.
- diff-bug #11: `release_commands()` and `report_release()` run after the restore guard, so a failure while printing does not restore the files — fix now (shows AC5 failing: "any step after the write"; floor return 2).
- diff-bug #12: no test ties the exempt row to the real check's row shape, and the process search misses `pipe(` — fix now.
- blame-history #1: `full_supplement()` has no `version`, so the "writes every field" tests do not cover it — fix now.
- blame-history #2: the no-version hint uses the current value, which for a flow map can invite a duplicate key — reject (false): the hint also says to make the existing `version:` line look like it, so it does not ask for a second key.
- blame-history #3: the unexplained `test-template.R:140` failure during T2 — follow-up: "template test flake" candidate row.
- prior-review #1: a CR-only `_supplement.yml` reads as one line, so its `version:` line reads as missing (the M007 review's CR-only finding) — follow-up: "release edge cases" candidate row.
- prior-review #2: the Errors section documents the unclassed YAML parse error — reject (false): the help text states what the function does now (derived-claims rule), and the "YAML parse errors" row still holds the fix.
- prior-review #3: the new tests use `local_mocked_bindings()`, which needs testthat 3.1.7, above the `>= 3.0.0` floor — follow-up: absorbed into the "testthat floor" row.
- prior-review #4: writes through a linked output file are not checked — fix now, with diff-bug #1.
