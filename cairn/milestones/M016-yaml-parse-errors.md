# M016: A site YAML file with a syntax error gives a supplement error

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes the error class and message of six exported functions
- **Branch/PR:** m016-yaml-parse-errors

## Goal

When the yaml package cannot read `_supplement.yml` or `_quarto.yml`, the package functions that read it stop with a classed `supplement_error` that names the file and shows the parser's message.

## Scope

**In:** a new error class `supplement_error_parse` raised by `write_citation()`, `write_zenodo()`, `check_supplement()`, and `release_supplement()` (through `read_supplement()` in `R/supplement-yml.R:32` and the release read in `R/release-supplement.R:167`), by `add_data()` for `_supplement.yml`, and by `add_report()` for `_quarto.yml` (both through `append_item()` in `R/add-utils.R:74`, which now gives `supplement_error_yaml` with a message about adding an item); the Errors sections of their help pages; a NEWS.md entry; DESIGN.md's note on error classes.

**Out:** a `CITATION.cff` that is not valid YAML (`check_supplement()` already gives a `doi-mismatch` row). Quarto's own message for an invalid `_quarto.yml` at render → not the package's.

## Acceptance criteria

- [x] AC1: Each of `write_citation()`, `write_zenodo()`, `check_supplement()`, `release_supplement()`, and `add_data()` is called on a site whose `_supplement.yml` holds one of five shapes that the yaml package refuses: an unclosed flow sequence (`citation: [x`), an unclosed flow map (`zenodo: {a: 1`), a line under `supplement:` indented with a tab instead of spaces, a second value on a key line (`paper-title: a: b`), and a key given twice in the `supplement:` map. For each call, a test asserts that the error has the classes `supplement_error_parse` and `supplement_error`, and that `folder_state()` of the site is the same before and after the call. It also asserts that the error message, with each run of white space made one space, holds `_supplement.yml` and the trimmed message that `yaml::yaml.load()` gives for the same text, also with white space made one space.
- [x] AC2: `add_report()` is called on a site whose `_quarto.yml` holds each of the five shapes of AC1, at the top level in place of under `supplement:`. A test asserts the classes `supplement_error_parse` and `supplement_error`, `_quarto.yml` and the `yaml::yaml.load()` message in the error message (white space made one space, as in AC1), and an unchanged `folder_state()`.
- [x] AC3: The Errors section of the help page of each of the six functions lists `supplement_error_parse`, and `grep -rn "error of the YAML" R/ man/` finds nothing.
- [x] AC4: NEWS.md has an entry that names `supplement_error_parse` and the six functions.
- [x] AC5: `Rscript -e 'devtools::document()'` leaves no diff, and `Rscript -e 'devtools::test()'` reports no failure.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T3
- AC3 → T4
- AC4 → T4
- AC5 → T2, T3, T4

## Tasks

- [x] T1: Write the tests of AC1 and AC2 (a helper that writes each shape with `writeBin()`, and one that makes each run of white space one space), and see them fail. Pass the parser's message to cli as data, not as a template, because the flow-map message holds `{` or `}`. Replace the test at `tests/testthat/test-release-supplement.R:265`, which expects the parser's unclassed error.
- [x] T2: Parse `_supplement.yml` in one helper that catches the yaml package's error and raises `supplement_error_parse` with the file name and the parser's message. Use it in `read_supplement()` and in the release read; run the AC1 tests to green.
- [x] T3: Check that the file parses before `append_item()` edits it, with the same helper, so `add_data()` and `add_report()` raise `supplement_error_parse`; run the AC2 tests to green.
- [x] T4: Update the roxygen Errors sections of the six functions, DESIGN.md, and NEWS.md; run `devtools::document()` and the AC3 grep.

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: not run — work named at the question set.
- 2026-10-19: question set: what to plan — release from subfolder, YAML parse errors, paper figure files.
- 2026-10-19: absorbed candidate row "YAML parse errors" in full, and widened it to `add_data()` and `add_report()`, which give a misleading `supplement_error_yaml` for the same input.
- 2026-10-19: plan chose a new class `supplement_error_parse` over reusing `supplement_error_yaml`, because that class means "the edited text does not read back as planned"; falsified by a caller that must handle both cases the same way.
- 2026-10-19: inbox sweep: 0 open issues, 0 open PRs. Collision sweep: D-010 and D-011 (text edits) stand and are not touched.
- 2026-10-19: lessons harvested: M008 (`read_yaml()` warns on a file with no final line break; parse text with `yaml.load()`), M012 (`yaml.load(error.label =)` names the file; `expect_error(class =)` passes on a parent's class, so check `inherits()` on the error itself), M009 (name input shapes, not literal strings).
- 2026-10-19: criteria audit (full mode, fresh Opus reader, shared with M015 and M017): confirmed the first three shapes fail to parse at the top level, under `supplement:`, and in `_quarto.yml`. Findings taken: cli wraps the message, so AC1 and AC2 compare with white space made one space; the tab shape names its place (a tab inside a flow sequence is valid YAML); the Goal narrowed from "not valid YAML" to "the yaml package cannot read", with an unclosed flow map and a duplicate key added as shapes; T1 passes the parser message to cli as data. Dropped the conditional "metadata encoding errors" Out item, which no request named.
- 2026-10-19: T1: wrote `tests/testthat/test-parse-errors.R` (five shapes in `_supplement.yml` for five functions, five top-level shapes in `_quarto.yml` for `add_report()`); all 30 calls failed before the fix, with the parser's unclassed error or `supplement_error_yaml`. Replaced the release parser-error test with a class check.
- 2026-10-19: implementation choice: one helper `yaml_read_file_text(text, file)` in `R/yaml-insert.R`. `read_supplement()` reads the text as `yaml::read_yaml()` did (it keeps the incomplete-final-line warning); the release read and `append_item()` parse the lines text that `yaml_lines_text()` gives. The message names the file and puts the trimmed parser message in an `x` bullet; `yaml_parse_lines()` lost its unused `label` argument.
- 2026-10-19: minor amendment to T3: two existing tests (`test-add-data.R`, `test-add-report.R`) expected `supplement_error_yaml` for an unclosed flow sequence; they now expect `supplement_error_parse`.
- 2026-10-19: T1 to T3 in one checkpoint commit, because the T1 tests stay red until T2 and T3; `devtools::test()` clean (1 skip on a case-insensitive disk), 160 expectations in the new file.
- 2026-10-19: T4: added `supplement_error_parse` to the Errors sections of the six functions (`write_zenodo()` inherits `write_citation()`'s), removed the "error of the YAML parser" sentences, added a NEWS.md entry and a DESIGN.md Architecture note on `yaml_read_file_text()`. `devtools::document()` rewrote six Rd files and a second run wrote none; the AC3 grep finds nothing; `devtools::test()` clean.
- 2026-10-19: claim audit: 32 claims read, 2 corrected — NEWS.md (`add_data()` gave `supplement_error_no_data_list`, not `supplement_error_yaml`, for the tab shape before the fix), R/yaml-insert.R (`yaml_lines_text()` removes only the `\r` at the end of each line); the same reader re-read both as true.
- 2026-10-19: status review; `devtools::document()` no diff, `devtools::test()` clean.

## Decisions

## Review

- AC1: `test_file("tests/testthat/test-parse-errors.R")` on the branch: the `_supplement.yml` test ran 130 expectations (5 shapes, each a parser check plus 5 calls with 5 checks: both classes, the file name, the parser message with white space made one space, an unchanged `folder_state()`), 0 failed. The same test file against a `git archive main` copy: 50 of 130 failed. The shapes are `citation: [x`, `zenodo: {a: 1`, a tab-indented `version:` line under `supplement:`, `paper-title: a: b`, and `repeated:` twice under `supplement:`.
- AC2: the same run, `_quarto.yml` test: 30 expectations (the five shapes at the top level, the tab shape as `extra:` with a tab-indented child, each with the parser check and the five `add_report()` checks), 0 failed on the branch, 10 failed on the `main` copy.
- AC3: `tools::parse_Rd()` on the six Rd files: each has one Errors section, and each holds `supplement_error_parse`. `grep -rn "error of the YAML" R/ man/` exits 1 with no output.
- AC4: NEWS.md's new entry names `supplement_error_parse`, `write_citation()`, `write_zenodo()`, `check_supplement()`, `release_supplement()`, `add_data()`, and `add_report()`.
- AC5: `devtools::document()` wrote no file and `git status` showed only this milestone file; `devtools::test()`: 241 tests, 2723 expectations, 0 failed, 0 errors, 1 skipped (a case-sensitive-disk test on this case-insensitive disk).
- gate: `cairn_validate.py` all checks passed; no principle changed, so no impact report; `devtools::document()` no diff; no README.Rmd and no `_pkgdown.yml`; NEWS.md has the entry; no new top-level file; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: a `_supplement.yml` that is not UTF-8 is read only up to the bad byte by `read_supplement()`, so the writers judge cut text while the release and `add_data()` give `supplement_error_encoding` — follow-up, row "parse error edge cases" (as before M016; a run gave `supplement_error_authors` from `write_citation()`)
- diff-bug #2: with `options(warn = 2)`, a yaml warning becomes `supplement_error_parse` — follow-up, row "parse error edge cases" (confirmed with `!!float abc`)
- diff-bug #3: the hint "Fix the YAML at the place that the message names" follows a duplicate-key message that names no place — fix now, fixed a27a8df
- diff-bug #4: `read_supplement()` and the release read parse texts that differ in the final line break — follow-up, absorbed in row "release write order remainder" (as before M016)
- diff-bug #5: `parser_message()` could differ from the read path for a shape at the end of the file — reject (false as a defect: the five shapes sit mid-file, so the tests compare equal texts)
- diff-bug #6: the release parse test checks `supplement_error_parse` only through `expect_error(class =)` — fix now, fixed a27a8df
- diff-bug #7: "so nothing was written" in a `check_supplement()` error, which never writes — reject (style; the sentence is true)
- diff-bug #8: the second `yaml.load()` in `add_data()` can no longer fail — reject (style; behavior unchanged)
- diff-bug #9: the yaml package's text no longer carries the file label — reject (planned change; the cli headline names the file)
- blame-history #1: the narrower meaning of `supplement_error_yaml` has no D-entry — fix now (D-015), fixed a27a8df
- blame-history #2: DESIGN.md's note on `yaml_read_file_text()` does not say that the callers pass texts with different final line breaks — follow-up, absorbed in row "release write order remainder"
- blame-history #3: `read_supplement()` keeps the incomplete-final-line warning that LESSONS.md (M008) calls a wart — follow-up, row "parse error edge cases" (kept on purpose to change nothing for valid files)
- blame-history #4: the replaced release test no longer checks the parser message — reject (planned change: T1 replaced it, and `test-parse-errors.R` checks the message for `release_supplement()`)
- blame-history #5: an 81-character roxygen line in `R/add-report.R` — reject (style)
- prior-review #1: the kept warning contradicts the M008 lesson — follow-up, row "parse error edge cases"
- prior-review #2: a block scalar at the end of the file reads with an extra line break on the release side — follow-up, absorbed in row "release write order remainder" (as before M016)
- ripple #1: row "release write order remainder" says the writers parse with `read_yaml()` — fix now (row corrected in place), fixed a27a8df
- ripple #2: row "YAML parse errors" describes the old behavior — fix now at step 9 hygiene, where the row graduates
