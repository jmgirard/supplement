<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M012: release_supplement() checks every value before it writes a file

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes the errors, the stop order, and the printing step of the exported `release_supplement()`
- **Branch/PR:** m012-release-write-order

## Goal

`release_supplement()` builds the text of `CITATION.cff` and `.zenodo.json` in memory, so that a value or a folder that would stop either writer stops the release before it writes any file.

## Scope

**In:** Split `write_citation()` and `write_zenodo()` into internal builders that take the `supplement` map and return the file text, plus the exported wrappers that read, build, and write. In `release_supplement()`, read `_supplement.yml` once, and take the current version, the changed lines, and both output texts from that read. Build both texts before `check_supplement()` runs. `read_outputs()` refuses a folder at an output, so before the check and again at M011's re-read after it. The restore guard writes the three built texts. The commands print after the guard finishes, so a print failure keeps the released files (user choice at the plan gate). Writer errors reach the caller with their own class, with no deprecation period (user choice). Tests, the help page, NEWS.md, and the DESIGN.md Architecture paragraph.

**Out:** A folder, a link, or a save made after the re-read and before the writes → the "release snapshot remainder" row. An interrupt after the last write returns and before the guard is marked done still puts the files back (a narrower window than today) → the same row. A full disk during a standalone `write_citation(overwrite = TRUE)` → the "release edge cases" row. Temporary files and rename stay rejected (RR01). Exporting the builders → not planned.

## Acceptance criteria

- [ ] AC1: `write_citation()` and `write_zenodo()` pass their existing tests with the test files unchanged: `tests/testthat/test-write-metadata.R` and `tests/testthat/test-write-metadata-errors.R` pass, and `git diff main -- tests/testthat/test-write-metadata.R tests/testthat/test-write-metadata-errors.R` prints nothing. An error that a builder raises names `write_citation()` or `write_zenodo()` as its call when raised through that writer, and `release_supplement()` when raised through the release. A test asserts `err$call` for an empty `paper-title` through each of the three functions.
- [ ] AC2: When `_supplement.yml` holds one of these five values, `release_supplement()` stops with the listed class, not `supplement_error_release_write`, before `check_supplement()` runs, with the site folder as it was: an empty `citation` (`supplement_error_missing_field`), a `zenodo.concept-doi` that is not a DOI (`supplement_error_doi`), `license.content: "CC BY 4.0"` (`supplement_error_license`), an ORCID iD with a wrong check digit (`supplement_error_orcid`), and an author with no `family` name (`supplement_error_author_name`). The test asserts the class, that a mocked `check_supplement()` was called 0 times, and that `folder_state()` is unchanged. A sixth case puts a link at `CITATION.cff` and an empty `citation` in the file, and asserts `supplement_error_missing_field`: the value error comes before the output refusals.
- [ ] AC3: After a release finishes, `CITATION.cff` and `.zenodo.json` hold the bytes that `write_citation(overwrite = TRUE)` and `write_zenodo(overwrite = TRUE)` write from the released `_supplement.yml`. A test compares the bytes for the template site with `version: "1.2.3"` with LF and with CRLF line endings, and for a site with LF line endings, a UTF-8 BOM, `probe_values` text in `paper-title` and `citation`, one author with an ORCID iD that ends in `X` and an affiliation, a `zenodo.concept-doi`, and both license ids.
- [ ] AC4: A folder at `CITATION.cff` or `.zenodo.json` when the release reads the outputs, before or after `check_supplement()`, stops the release with `supplement_error_file_exists`, also when `_supplement.yml` changed during the check. Tests cover each of the two paths with a folder made before the call, a folder made by a mocked `check_supplement()` where no file was, and one made by the mock in place of a file. A further case has the mock change `_supplement.yml` and make the folder. Each test asserts the class, that `folder_state()` equals the state before the call or the state the mock left, and that no captured message contains `git tag`.
- [ ] AC5: A stop or an interrupt raised by `report_release()` keeps `_supplement.yml`, `CITATION.cff`, and `.zenodo.json` at the raised version. A test mocks `report_release()` to stop with an error, and asserts the three versions and that the caller gets the mock's error unchanged. A second case mocks it to signal an interrupt inside the test's `tryCatch(interrupt =)`, and asserts that the handler ran, the three versions, and that no warning was given.
- [ ] AC6: When a write of `_supplement.yml`, `CITATION.cff`, or `.zenodo.json` stops or is interrupted, the release puts back each file that can be put back (`folder_state()` as before the call). A stop raises `supplement_error_release_write`, and an interrupt reaches the caller. A file that cannot be put back is named in the error, or in the warning after an interrupt. Tests cover a failed write at each of the three files with and without existing outputs, a write that only warns, an interrupt during the `.zenodo.json` write, a site path with `[`, `*`, or `?`, and a put-back that fails after a stop and after an interrupt.
- [ ] AC7: These passages are rewritten to match AC2 to AC5: in the `release_supplement()` help page (`R/release-supplement.R` at main 49590d2), lines 39-40 (a folder is not seen as a change), 48-51 (printing inside the guard, and the `write_zenodo()` example), 75 (every error is a `supplement_error`, which a print error is not), 106-107 (`supplement_error_file_exists` adds a folder), and 111-113 (printing in `supplement_error_release_write`); the `release_supplement()` bullet of NEWS.md; and the `release_supplement()` paragraph of `cairn/DESIGN.md` Architecture (lines 87-99 at main 49590d2). The Errors section says the writers' classes reach the caller directly and states the stop order: argument, metadata, version, version line, writer values, output refusals, check, changed files and output refusals, check problems, writes. `devtools::document()` leaves no diff, and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T2, T4
- AC4 → T3
- AC5 → T5
- AC6 → T4
- AC7 → T6

## Tasks

- [x] T1: In `R/write-citation.R` and `R/write-zenodo.R`, move the code from `require_fields()` to the text into `citation_text(meta, call)` and `zenodo_text(meta, call)`. The wrappers keep `check_args()`, `read_supplement()`, `check_overwrite()`, and `write_utf8()`, and pass their own frame as `call`. Add the `err$call` tests (AC1).
- [x] T2: Tests first for AC2 and AC3. In `release_supplement()`, after the no-metadata check, read the file once with `read_text_lines()`, parse the `supplement` map from those lines with the same sequence handler as `read_supplement()` (a shared helper), and take the current version from it. After the version line is replaced, parse the new lines and build both texts, all before `read_outputs()` and `check_supplement()`. Change the empty-citation test at `test-release-supplement.R:552` from "is put back" to "is refused before any write".
- [x] T3: Tests first for AC4. `read_outputs()` refuses a folder with `supplement_error_file_exists`. Update the M011 tests and comments that read a folder as no file.
- [ ] T4: `write_release_files()` writes the three built texts with `write_checked()` inside the guard. Move the failure tests off `write_utf8()` and `write_zenodo()` mocks to `write_checked()` mocks, and add the failed `_supplement.yml` write (AC6). Add the AC3 byte test.
- [ ] T5: Tests first for AC5. Call `report_release()` after `write_release_files()` returns. Replace the test at `test-release-supplement.R:519`.
- [ ] T6: Rewrite the passages AC7 names, run `devtools::document()` and `devtools::check()`.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — changes the errors and the printing step of an exported function, and the printing step was a design choice for the user.
- 2026-10-18: collision: absorbed the "release write order" candidate row in full, and two sentences of the "release snapshot remainder" row in part (the save between the two reads before the check, and a folder made at an output during the check). The rest of that row stays.
- 2026-10-18: collision: the last sentence of the "footer and badge edge cases" row (the help page does not say that a bad license id stops the release in its write step) becomes moot here; review hygiene narrows that row, which this plan does not take.
- 2026-10-18: collision: D-010 and D-011 still govern the `_supplement.yml` edit and are unchanged; D-012 is unchanged. No standing rejection applies.
- 2026-10-18: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-18: lessons: M009's criterion lesson (stated rule plus listed tests, input shapes over literal strings) shaped every criterion; M011's mock-the-slow-step and `writeBin()` lessons shape the T3 and T4 tests; M005's YAML 1.1 and sequence-handler lessons shape T2's parse helper.
- 2026-10-18: criteria audit (full mode, fresh Opus reader): 9 findings, all fixed. AC1 gained the `err$call` test; AC2 named its five values, dropped the output-existence grid, and fixed the order against a link; AC3 gained a rich-content site with a BOM; AC4 named its read points, the file-replaced case, and the changed-file case, and dropped `expect_changed_stop()`; AC5 split the error and interrupt cases; AC6 split stop from interrupt and the failed put-back; AC7 named each false passage and the stop order; the two changed tests went into T2 and T5.
- 2026-10-18: question set: printing after a finished write — keep the written files (print outside the guard).
- 2026-10-18: question set: writer error class through the release — change directly to the writer's own class, no deprecation period (user waiver; the package is pre-1.0 and unreleased).
- 2026-10-18: plan gate chose printing outside the restore guard over keeping it inside because the files are the product and a print failure should not undo them (RR01 recommendation 6); falsified by a report of a user who ran the printed commands after a release that the function then put back, or of a release kept after a failure that left the files wrong.
- 2026-10-18: plan chose building both texts before `check_supplement()` over building them after it because a bad value then stops before the slow check, and M011's re-read makes the early build safe; falsified by a value whose check depends on a file that `check_supplement()` or the user changes during the check.
- 2026-10-18: plan chose in-memory builders over temporary files and rename because RR01 rejected the rename (no atomic rename across three files, Windows rename, a stray temp file that `git add -A` stages); falsified by a write failure that the byte restore cannot undo.
- 2026-10-18: implement started; branch m012-release-write-order cut from main at 0f2dc40.
- 2026-10-18: T1 done: `citation_text()` and `zenodo_text()` take `meta` and `call` and pass `call` to every value helper; the writer tests pass unchanged; the writer `err$call` test went into a new file, `tests/testthat/test-write-metadata-call.R`, so the two AC1 test files stay unchanged. `devtools::test()` clean.
- 2026-10-18: T2 done: `read_supplement()` split into `supplement_file()` and `supplement_map()`, and `yaml_parse_lines()` (the parser's error kept) under `yaml_read_lines()`; the release reads the file once with `read_text_lines()`, parses the map from those lines, and builds both texts from the changed lines before `read_outputs()`. The five AC2 values failed on the old code (release_write, check called once) and pass now; the old empty-citation put-back test became part of the AC2 loop. The writes still go through `write_citation()` and `write_zenodo()` until T4. `devtools::test()` clean.
- 2026-10-18: implementation choice: a non-UTF-8 `_supplement.yml` now gives `supplement_error_encoding` before the YAML parser runs, because the one read is `read_text_lines()`; the Errors list names classes, not this pair's order.
- 2026-10-18: T3 done: `read_outputs()` refuses a folder with `supplement_error_file_exists`, so before the check and at the re-read after it. The AC4 tests (before the call, made by the mock with and without a file there, and with `_supplement.yml` also changed) failed on the T2 code and pass now. No M011 test read a folder as no file. Found that `expect_error(class =)` also matches a parent error's class, so the AC2 and AC4 helpers now check `inherits()` on the error itself. `devtools::test()` clean.

## Decisions

## Review
