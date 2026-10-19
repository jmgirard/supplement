# M016: A site YAML file with a syntax error gives a supplement error

**Status:** done (2026-10-19, PR #17 https://github.com/jmgirard/supplement/pull/17)

**Goal:** When the yaml package cannot read `_supplement.yml` or `_quarto.yml`, the package functions that read it stop with a classed `supplement_error` that names the file and shows the parser's message.

**Outcome:** `yaml_read_file_text()` in `R/yaml-insert.R` turns the yaml package's error into `supplement_error_parse`, with the file name and the trimmed parser message as a cli value. `read_supplement()` (used by `write_citation()`, `write_zenodo()`, and `check_supplement()`) reads the text as `read_yaml()` did and calls it; the release read and `append_item()` (used by `add_data()` and `add_report()`) call it on `yaml_lines_text()` before any write. `yaml_parse_lines()` lost its `label` argument. `tests/testthat/test-parse-errors.R` covers five refused shapes (unclosed flow sequence and flow map, a tab-indented key line, a second value on a key line, a key given twice) for all six functions; two add tests and one release test now expect the new class. The six Errors sections, NEWS.md, and DESIGN.md name the class.

**Decisions:** D-015 (a site YAML file that does not parse gives `supplement_error_parse`; `supplement_error_yaml` keeps its one meaning).

**Review:** claim audit 32 claims, 2 corrected. One review pass, four lenses: 18 findings, 5 fixed (hint wording, release test class check, D-015, two ROADMAP rows), 7 to candidate rows ("parse error edge cases", new, and "release write order remainder"), 6 rejected (style, planned change, or false). No amendments. `R CMD check` 0/0/0; the repo has no CI. Graduated "YAML parse errors".
