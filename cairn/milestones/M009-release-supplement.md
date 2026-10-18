# M009: release_supplement() raises the version and prints release commands

- **Status:** planned
- **Priority:** high
- **Depends on:** M008
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a new exported R function and a new `_supplement.yml` field
- **Branch/PR:** —

## Goal

Export `release_supplement()`, which raises the site version in `_supplement.yml` after `check_supplement()` finds no problem and prints the commands that make the release.

## Scope

**In:** A `version` field in the template's `_supplement.yml`, which `write_citation()` and `write_zenodo()` write. `release_supplement(bump, path = ".")` runs `check_supplement()`, raises the version, writes `CITATION.cff` and `.zenodo.json` again, and prints the git and GitHub commands for the author to run. It runs none of them. Tests, a help page, README, `_README.md`, NEWS, and DESIGN text.

**Out:**
- The checks themselves: M008.
- A release date in `CITATION.cff` (`date-released`): not planned. Add a candidate row if it is needed.
- Calls to the GitHub or Zenodo API: out of scope for version 1 (DESIGN Purpose & Scope).

## Acceptance criteria

- [ ] AC1: The template's `_supplement.yml` has `version: ""` under `supplement:`, with a comment. `write_citation()` writes `version` to `CITATION.cff`, and `write_zenodo()` writes `version` to `.zenodo.json`, with the value of `supplement.version` when it is not empty. Both leave the field out when it is empty. Both stop with `supplement_error_version` for a value that is not three whole numbers joined by `.`, each `0` or without a leading zero. A test writes `1.0.0` and `0.10.2` to both files and reads them back, and it fires the error for `1.0`, `v1.0.0`, `01.0.0`, `1.0.0-rc1`, and `1. 0.0`.
- [ ] AC2: `release_supplement(bump, path = ".")` takes `bump` as `"patch"`, `"minor"`, `"major"`, or a version in the AC1 form. A word raises that part of the current version by 1 and sets the parts after it to 0. An empty current version counts as `0.0.0`. A version in `bump` must be greater than the current version, part by part as numbers. It stops with `supplement_error_argument` for any other `bump`, with `supplement_error_version` for a version that is not greater or a current version not in the AC1 form, and with `supplement_error_field_type` for a current version that YAML reads as a number, such as an unquoted `1.10`. A test checks: `1.2.3` with each word, `0.9.9` with `"major"` (`1.0.0`), `1.9.0` with `"minor"` (`1.10.0`), an empty version with `"patch"` (`0.0.1`), `1.2.3` with `"1.10.0"` (accepted), and `1.2.3` with `"1.2.3"` and `"1.2.2"` (refused).
- [ ] AC3: Before it writes, the function runs `check_supplement()`. It stops with `supplement_error_release_check`, and gives the number of problems, when the result's `skipped` attribute is not empty or the result has a row other than a `"doi-mismatch"` row for `CITATION.cff`, which the release writes again. When `_supplement.yml` has no `version:` key with a one-line value at the child indent of the block-style `supplement:` map, it stops with `supplement_error_no_version` and shows the line to add by hand. A test fires each error, and a release that only a `CITATION.cff` DOI row would block, and finds the file list and the bytes of every file in the site the same after each error.
- [ ] AC4: The function changes only the value on that `version:` line and writes the new value in double quotes. A byte comparison finds every other byte of `_supplement.yml` the same. Before the write, the yaml package reads the changed text, and the function stops unless the result is the old map with the new version. A test uses the template's file, a file with a comment after the value, a file with CRLF line endings, a single-quoted value, and an unquoted value.
- [ ] AC5: The function then writes `CITATION.cff` and `.zenodo.json` with `overwrite = TRUE`, and both hold the new version. If any step after the `_supplement.yml` write stops, for any reason, the function puts back the old bytes of each file it changed, removes each file it made, and stops. A test reads both files after a release. It mocks a failing write of `CITATION.cff` and a failing write of `.zenodo.json`, and uses an empty `citation`, which stops `write_zenodo()`. Each time it finds the three files as they were before.
- [ ] AC6: The function prints, and returns invisibly as a character vector, the commands for version `X.Y.Z`: `git status`, `git add -A`, `git commit -m "Release vX.Y.Z"`, `git tag vX.Y.Z`, `git push`, `git push origin vX.Y.Z`, and `gh release create vX.Y.Z --generate-notes`. `git add -A` adds the files that `check_supplement()` checked, so `docs/` and `_freeze/` reach the tagged commit. It also prints that, after Zenodo archives the release, the author adds the new version DOI to `_supplement.yml` and renders the site again. `R/release-supplement.R` does not call M008's git helper, so the function starts git only through `check_supplement()`, which M008's AC3 search covers.
- [ ] AC7: The package README and the template's `_README.md` describe `release_supplement()` and the `version` field. Its help page has an example in `\dontrun{}`, because the function needs a rendered site in a git repository. NEWS.md has an entry for the function and the field.

## Coverage

- AC1 → T1
- AC2 → T3, T4
- AC3 → T3, T4
- AC4 → T2, T3, T4
- AC5 → T3, T4
- AC6 → T3, T4
- AC7 → T5

## Tasks

- [ ] T1: Add `version: ""` with a comment to `inst/template/_supplement.yml`. Add a version check to `R/supplement-yml.R`, and write `version` in `R/write-citation.R` and `R/write-zenodo.R`. Cite the CFF 1.2.0 schema and Zenodo's deposit metadata in code comments. Add the AC1 tests and update the two help pages.
- [ ] T2: Add a helper to `R/yaml-insert.R` that replaces the value on one line of a block-style map and checks the result with the yaml package, as D-010 asks of inserts. Test it directly against the AC4 fixture files. Append a D-entry that extends D-010 to a one-line value change.
- [ ] T3: Write `tests/testthat/test-release-supplement.R` for AC2 to AC6. Mock `check_supplement()`, so the tests need no render, and add one test that searches `R/release-supplement.R` for the git helper's name.
- [ ] T4: Write `R/release-supplement.R`. Check `bump`, `_supplement.yml`, and the `version:` line before `check_supplement()` runs, and reuse `write_checked()` from `R/yaml-insert.R` for the restore.
- [ ] T5: Add roxygen documentation and run `devtools::document()`. Describe the function and the field in `README.md` and `inst/template/_README.md`, add a NEWS.md entry, and update DESIGN.md Architecture.

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
