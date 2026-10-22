# M036: The release stops on template placeholders

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a new row of the exported `check_supplement()`, which stops `release_supplement()`
- **Branch/PR:** m036-placeholder-check

## Goal

`check_supplement()` gives a `"placeholder"` row for each template placeholder listed in AC1 to AC3 that a site still holds, so `release_supplement()` stops before it writes `CITATION.cff` and `.zenodo.json` from template values.

## Scope

**In:** A new check in `R/check-supplement.R`, run by `check_supplement()` beside the others. It compares four `_supplement.yml` values with the installed template's `_supplement.yml`, looks for a listed placeholder line in seven site files, and compares the text of `analyses/example.qmd` and `data/example.csv` with the installed template's copies. The check only reads, and no file it reads makes it stop. `release_supplement()` needs no change, because every row but the `CITATION.cff` DOI row already stops it. The test helpers get a function that replaces the placeholders, used by the tests that expect a site from the template to give no rows. `?check_supplement`, its example comment, the `NEWS.md` bullet for `check_supplement()`, and `cairn/DESIGN.md` Architecture state the check.

**Out:** `write_citation()` and `write_zenodo()` keep accepting placeholder values when run on their own (question set, 2026-10-22). The template guide's placeholder citation, which the first render puts in the site's public `README.md`, stays with the candidate row "Split the template guide by reader". Other template text gives no row: the example figure, which each render rewrites (D-018), the example's `data:` description, and the "Example Analysis" menu item. A value that keeps only part of a placeholder (a real citation with `(Year)` left in), and the placeholders of an older template that differ from the installed one, give no row either; the help page says so, and no work is planned for them.

## Acceptance criteria

- [ ] AC1: `check_supplement()` gives one row with check `"placeholder"` and file `_supplement.yml` when, in that file's `supplement:` map, one or more of these equals the installed template's value: `paper-title`, `citation`, `contact`, or an `authors` entry whose `family` and `given` both equal those of one template author. Two values are equal when they are the same after each run of white space is read as one space and the ends are removed. An empty template value never counts. A field or an author part that is not one text value, or an `authors` entry that is not a map, gives no row for it and does not make the check stop. The row's problem text names each matched field, and the row is absent when none matches. A test in `tests/testthat/test-check-supplement.R` starts from a site made by `create_supplement()`, whose row names all four. It then leaves each of the four in place alone, in turn, and sees the row name only that one, and sees no row once all four are changed. `authors` is named for a list of a real author and `Author`/`B. B.`, and is not named for `Author`/`Jane` or `Smith`/`A. A.`. `paper-title: 2024` and an `authors` entry that is a string give no row for that field and no error.
- [ ] AC2: For each file and line in this list, `check_supplement()` gives one row with check `"placeholder"` and that file when the file in the site folder has a line that equals the listed line once spaces, tabs, and a carriage return at its ends are removed: `_quarto.yml` with `href: https://github.com/OWNER/REPO`; `index.qmd` with `## Before your first commit`; `LICENSE.md` and `LICENSE-CC-BY.md` with `Copyright (c) YEAR AUTHORS`; `README.md`, `SUPPLEMENT.md`, and `_README.md` with `Website: https://OWNER.github.io/REPO/`. A path that is missing or is a folder, a file that holds a nul byte or is not valid UTF-8, and a file that holds no such line give no row, and none of them makes the check stop. Each listed line is a line of the installed template's copy of its file, with `_README.md` standing for `README.md` and `SUPPLEMENT.md`. Tests in `tests/testthat/test-check-supplement.R` see each of the seven rows on a site made by `create_supplement()` (with the guide copied to `README.md` and `SUPPLEMENT.md`) and see each row go when its line is changed. They see no row and no error for a `README.md` that is a folder, one in UTF-16, and one in Latin-1 that holds the listed line. On a site made by `create_supplement(repo = "owner/name")`, `_quarto.yml` and `_README.md` give no row. A test reads each listed line in the installed template's file.
- [ ] AC3: `analyses/example.qmd` and `data/example.csv` each give one row with check `"placeholder"` and that file when the file's text equals the installed template's copy, with each CR LF pair read as LF on both sides. A file with any other change, a missing path, or a folder gives no row, and none makes the check stop. A test in `tests/testthat/test-check-supplement.R` runs, for each of the two files, the template copy, the copy with CR LF line ends, a changed copy, a missing file, and a folder.
- [ ] AC4: On a site made by `create_supplement()` in a git repository, with stored output for its example report and `docs/figures/` in place, `release_supplement("1.0.0")` stops with `supplement_error_release_check`, and every file in the site folder has the same bytes after the call. With the placeholders of AC1 to AC3 replaced, and the stored output's hash written again from the changed report, the same site releases to version `1.0.0`. A test in `tests/testthat/test-release-supplement.R` runs the real `check_supplement()` for both.
- [ ] AC5: `?check_supplement` has a `"placeholder"` bullet that lists the fields, lines, and files of AC1 to AC3, and says that the values come from the installed template, so a part of a placeholder, or an older template's placeholder that differs, gives no row. Its opening sentence also names template values left in place, and its example comment names the placeholder rows of a new site. In `NEWS.md`, the bullet that starts "`check_supplement()` lists the problems" names the check and says that it stops `release_supplement()`.
- [ ] AC6: `devtools::test()` passes, and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T4, T5

## Tasks

- [x] T1: Write the AC1 tests first and see them fail on main. Then add the check to `R/check-supplement.R`: read the installed template's `_supplement.yml` with `system.file("template", ...)` through `yaml_read_file_text()`, compare the four fields with the site's `meta` without `value()` (which stops on a wrong type), and add the call to the `rows` list in `check_supplement()` (line 213). Run `devtools::test()`.
- [x] T2: Write the AC2 tests first, then add the file and line list and a line reader that turns a read failure into no row (`read_text_lines()` in `R/yaml-insert.R` stops with `supplement_error_encoding`, so catch it or read the bytes and test `validUTF8()`). Run `devtools::test()`.
- [x] T3: Write the AC3 test first, then add the text comparison of the two example files with the template's copies, with CR LF read as LF. Run `devtools::test()`.
- [x] T4: Add a helper in `tests/testthat/helper-files.R` that replaces each placeholder of AC1 to AC3 in a site with valid values that `citation_text()` accepts, edits `_README.md` before a render renames it, and writes bytes with `writeBin()` (LESSONS M011). Call it before any render or stored hash: in the first test of `test-check-supplement.R` (line 29), in `renv_site()` of `helper-template.R` after `git_site()` and before the render (line 218), and in `checked_site()` of `test-release-supplement.R` (line 216) through a `placeholders = TRUE` argument. Write the AC4 test with `checked_site(placeholders = FALSE)`, then replace the placeholders and rewrite `html.json` from the report's new MD5. Run `devtools::test()` and confirm that the zero-row tests pass for their own reason (no row of any check).
- [ ] T5: Add the `"placeholder"` bullet and the opening-sentence change to the roxygen of `check_supplement()`, update the example comment (line 202), and run `devtools::document()`. Edit the `NEWS.md` bullet at line 39. Add the check to the `check_supplement()` paragraph of `cairn/DESIGN.md` Architecture. Run `devtools::check()`.

## Work log

- 2026-10-22: created by /milestone-plan.
- 2026-10-22: tier check: not run — work named at the question set.
- 2026-10-22: idea vet: no concern found. A whole-value match with the installed template finds the values the ease-of-use review saw released (title "Title of the paper", authors "Author, A. A." and "Author, B. B."), and no real paper has those values, so the check gives no row for an author's own text. Users want it: Zenodo archives each release under a DOI that cannot be withdrawn. Framed as a `check_supplement()` row, it shows before a release as the other problems do, and the release stops on it with no new code.
- 2026-10-22: question set: which work to plan — "Refuse placeholder values at release", absorbing that candidate row in full. Example files — they count only when their text equals the template's copies. Writers — `write_citation()` and `write_zenodo()` do not refuse placeholders; only the release stops.
- 2026-10-22: plan chose a `check_supplement()` row over a separate stop inside `release_supplement()`, because every other release stop comes from the check and the author sees the row on any check; falsified by an author who needs `check_supplement()` to give no rows on a draft site.
- 2026-10-22: plan chose to read the `_supplement.yml` placeholders from the installed template over a copy in the R code, so a template edit cannot leave the check behind; the other files' lines are a list in the code, each shown by a test to be in the template; falsified by a site made from an older template whose placeholders the check misses.
- 2026-10-22: collision check: absorbs the candidate row "Refuse placeholder values at release"; the guide's placeholder citation stays with "Split the template guide by reader". No archived milestone or D-entry covers placeholder values; D-018 (the example figure is rewritten by each render) is why the figure is left out. The inbox sweep found 0 open issues and 0 open PRs.
- 2026-10-22: criteria audit (full mode, fresh Opus reader) returned 11 findings, all fixed: AC2 and AC3 now say that a folder or a file that cannot be read as UTF-8 gives no row and no stop, with probes, since `read_text_lines()` stops on such a file; AC4 gets `checked_site(placeholders = FALSE)` and a rewritten stored hash; T4 calls the helper inside `renv_site()` before its render; AC1 defines equality, an empty template value, and wrong types, with mixed-author probes; AC3 reads CR LF as LF for Windows clones; the Goal is narrowed to the listed placeholders; AC2's template-line sentence states a template property; AC5 covers the opening sentence and the example comment; two task line numbers corrected. A dangling-link probe was left out, because on Windows such a link reads as an existing file (LESSONS M018) and on other systems it reads as missing.
- 2026-10-22: lessons applied: M011 (edit test files with `writeBin()`, since `writeLines()` writes CRLF on Windows), M018 (Windows link behavior), M001 and M027 (edit a report before its stored hash is written, or it gets a `stale-output` row).
- 2026-10-22: changelog: AC5 edits the existing unreleased `check_supplement()` bullet in `NEWS.md` and adds none.
- 2026-10-22: implement started on branch m036-placeholder-check, cut from main at 7d391d9.
- 2026-10-22: T1 checkpoint: `check_placeholders()` and `placeholder_values()` in `R/check-supplement.R`, with five tests; the template is read through `template_supplement()`, so a test can mock it. The zero-row test "a rendered site in a git repository has no problems" now fails until T4's helper; T1 to T3 are ticked once the suite is clean.
- 2026-10-22: T2 checkpoint: `placeholder_lines` and `placeholder_line_rows()` give one row per file with its own problem text; `plain_lines()` turns a missing path, a folder, or a read error of `read_text_lines()` into no lines. Five tests added, all passing.
- 2026-10-22: T3 checkpoint: `placeholder_example_rows()` compares the two example files with the template's through `report_hash()`, the CR LF reader of the stale-output check. One test runs the five states for each file and passes.
- 2026-10-22: T4 done: `fill_placeholders()` and `replace_in_file()` in `helper-files.R` (the T2 test's own copy of `replace_in_file()` moved there); called in the first check test, in `renv_site()` before its render, and in `checked_site(placeholders = TRUE)`. The AC4 test sees 8 placeholder rows, a release stop with "8 problems" and an unchanged folder, then a release to 1.0.0 after the fill. Full suite with NOT_CRAN=true: 349 tests, 0 failed, 8 skipped (Windows, case-sensitive disk, Docker; the renv test ran). T1 to T3 ticked with it.

## Decisions

## Review
