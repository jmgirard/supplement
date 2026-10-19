# M016: A site YAML file with a syntax error gives a supplement error

- **Status:** in-progress
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

- [ ] AC1: Each of `write_citation()`, `write_zenodo()`, `check_supplement()`, `release_supplement()`, and `add_data()` is called on a site whose `_supplement.yml` holds one of five shapes that the yaml package refuses: an unclosed flow sequence (`citation: [x`), an unclosed flow map (`zenodo: {a: 1`), a line under `supplement:` indented with a tab instead of spaces, a second value on a key line (`paper-title: a: b`), and a key given twice in the `supplement:` map. For each call, a test asserts that the error has the classes `supplement_error_parse` and `supplement_error`, and that `folder_state()` of the site is the same before and after the call. It also asserts that the error message, with each run of white space made one space, holds `_supplement.yml` and the trimmed message that `yaml::yaml.load()` gives for the same text, also with white space made one space.
- [ ] AC2: `add_report()` is called on a site whose `_quarto.yml` holds each of the five shapes of AC1, at the top level in place of under `supplement:`. A test asserts the classes `supplement_error_parse` and `supplement_error`, `_quarto.yml` and the `yaml::yaml.load()` message in the error message (white space made one space, as in AC1), and an unchanged `folder_state()`.
- [ ] AC3: The Errors section of the help page of each of the six functions lists `supplement_error_parse`, and `grep -rn "error of the YAML" R/ man/` finds nothing.
- [ ] AC4: NEWS.md has an entry that names `supplement_error_parse` and the six functions.
- [ ] AC5: `Rscript -e 'devtools::document()'` leaves no diff, and `Rscript -e 'devtools::test()'` reports no failure.

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

## Decisions
