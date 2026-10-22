# M036: The release stops on template placeholders

- **Status:** review
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

- [x] AC1: `check_supplement()` gives one row with check `"placeholder"` and file `_supplement.yml` when, in that file's `supplement:` map, one or more of these equals the installed template's value: `paper-title`, `citation`, `contact`, or an `authors` entry whose `family` and `given` both equal those of one template author. Two values are equal when they are the same after each run of white space is read as one space and the ends are removed. An empty template value never counts. A field or an author part that is not one text value, or an `authors` entry that is not a map, gives no row for it and does not make the check stop. The row's problem text names each matched field, and the row is absent when none matches. A test in `tests/testthat/test-check-supplement.R` starts from a site made by `create_supplement()`, whose row names all four. It then leaves each of the four in place alone, in turn, and sees the row name only that one, and sees no row once all four are changed. `authors` is named for a list of a real author and `Author`/`B. B.`, and is not named for `Author`/`Jane` or `Smith`/`A. A.`. `paper-title: 2024` and an `authors` entry that is a string give no row for that field and no error.
- [x] AC2: For each file and line in this list, `check_supplement()` gives one row with check `"placeholder"` and that file when the file in the site folder has a line that equals the listed line once spaces, tabs, and a carriage return at its ends are removed: `_quarto.yml` with `href: https://github.com/OWNER/REPO`; `index.qmd` with `## Before your first commit`; `LICENSE.md` and `LICENSE-CC-BY.md` with `Copyright (c) YEAR AUTHORS`; `README.md`, `SUPPLEMENT.md`, and `_README.md` with `Website: https://OWNER.github.io/REPO/`. A path that is missing or is a folder, a file that holds a nul byte or is not valid UTF-8, and a file that holds no such line give no row, and none of them makes the check stop. Each listed line is a line of the installed template's copy of its file, with `_README.md` standing for `README.md` and `SUPPLEMENT.md`. Tests in `tests/testthat/test-check-supplement.R` see each of the seven rows on a site made by `create_supplement()` (with the guide copied to `README.md` and `SUPPLEMENT.md`) and see each row go when its line is changed. They see no row and no error for a `README.md` that is a folder, one in UTF-16, and one in Latin-1 that holds the listed line. On a site made by `create_supplement(repo = "owner/name")`, `_quarto.yml` and `_README.md` give no row. A test reads each listed line in the installed template's file.
- [x] AC3: `analyses/example.qmd` and `data/example.csv` each give one row with check `"placeholder"` and that file when the file's text equals the installed template's copy, with each CR LF pair read as LF on both sides. A file with any other change, a missing path, or a folder gives no row, and none makes the check stop. A test in `tests/testthat/test-check-supplement.R` runs, for each of the two files, the template copy, the copy with CR LF line ends, a changed copy, a missing file, and a folder.
- [x] AC4: On a site made by `create_supplement()` in a git repository, with stored output for its example report and `docs/figures/` in place, `release_supplement("1.0.0")` stops with `supplement_error_release_check`, and every file in the site folder has the same bytes after the call. With the placeholders of AC1 to AC3 replaced, and the stored output's hash written again from the changed report, the same site releases to version `1.0.0`. A test in `tests/testthat/test-release-supplement.R` runs the real `check_supplement()` for both.
- [x] AC5: `?check_supplement` has a `"placeholder"` bullet that lists the fields, lines, and files of AC1 to AC3, and says that the values come from the installed template, so a part of a placeholder, or an older template's placeholder that differs, gives no row. Its opening sentence also names template values left in place, and its example comment names the placeholder rows of a new site. In `NEWS.md`, the bullet that starts "`check_supplement()` lists the problems" names the check and says that it stops `release_supplement()`.
- [x] AC6: `devtools::test()` passes, and `devtools::check()` gives 0 errors and 0 warnings.

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
- [x] T5: Add the `"placeholder"` bullet and the opening-sentence change to the roxygen of `check_supplement()`, update the example comment (line 202), and run `devtools::document()`. Edit the `NEWS.md` bullet at line 39. Add the check to the `check_supplement()` paragraph of `cairn/DESIGN.md` Architecture. Run `devtools::check()`.

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
- 2026-10-22: T5 done: `?check_supplement` opening sentence, `"placeholder"` bullet, and example comment (the comment checked against a run of the example, which gave 8 placeholder rows); `NEWS.md` bullet; `cairn/DESIGN.md` Architecture. `devtools::document()` rewrote `man/check_supplement.Rd`; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- 2026-10-22: claim audit corrections (re-read by the same reader pending): the example report's problem text no longer says to delete only its menu item, which leaves an empty `menu:` that fails Quarto's validation; the example data's text also names the example report, which reads it; the `NEWS.md` bullet says `OWNER` and `REPO` for the site address, which holds no `OWNER/REPO`.
- 2026-10-22: claim audit: 59 claims read, 3 corrected — R/check-supplement.R, NEWS.md (the same reader re-read the three corrections and found them true).
- 2026-10-22: implement done: suite with NOT_CRAN=true 349 tests, 0 failed, 8 skipped; status set to review.

## Decisions

## Review

Evidence run 2026-10-22 on branch head eb334cf, level with origin/main 7d391d9. Full suite with NOT_CRAN=true: 349 tests, 0 failed, 8 skipped (Windows only, case-sensitive disk, Docker); none of the tests below skipped.

- AC1: `test-check-supplement.R` "template values in _supplement.yml give one placeholder row that names them" (11 expectations: all four on a new site, each alone in turn, none after all are changed), "an author counts only when both family and given are a template author's" (4: a real author plus `Author`/`B. B.` named; `Author`/`Jane` and `Smith`/`A. A.` not), "a template value with other white space still counts" (2), "a value that is not text gives no placeholder row for it and no error" (6: `paper-title: 2024`, a string author entry, a list `contact`, a string `authors`), "an empty template value never counts" (2): all pass.
- AC2: "a placeholder line gives a row for its file until it is changed" (9: five rows on a new site, seven with the guide copied to `README.md` and `SUPPLEMENT.md`, each row going when its line changes), "a placeholder line counts with spaces, tabs, and a CR at its ends" (1), "a README that is a folder or not UTF-8 text gives no row and no error" (6: folder, UTF-16, Latin-1 holding the line), "a site made with repo gives no row for the GitHub address" (1: rows only for `index.qmd` and the two licenses), "each placeholder line is a line of the template's file" (8): all pass.
- AC3: "an example file gives a row only while its text is the template's" (12: for `analyses/example.qmd` and `data/example.csv`, a row for the template copy and the CR LF copy, none for a changed copy, a missing file, or a folder, with no error): passes.
- AC4: `test-release-supplement.R` "template placeholders from the real check stop the release" (5: the real check gives 8 placeholder rows on `checked_site(placeholders = FALSE)`, `release()` stops with `supplement_error_release_check` and "8 problems", `folder_state()` unchanged; after `fill_placeholders()` and a rewritten `html.json`, the release sets version 1.0.0): passes.
- AC5: `man/check_supplement.Rd` (regenerated, no diff) has the opening sentence naming placeholder values (line 22), a `"placeholder"` bullet listing the four fields, the seven files with their lines (lines 195 to 198), the two example files, and the older-template and part-of-a-placeholder limits (line 207), and the example comment (line 241). `NEWS.md` lines 56 to 62, in the bullet that starts "`check_supplement()` lists the problems", name the check and say each row stops `release_supplement()`.
- AC6: `devtools::test()` 349 tests, 0 failed (above); `devtools::check()` on eb334cf: 0 errors, 0 warnings, 0 notes (6m 47s).

Consistency gate: `cairn_validate.py` exit 0, all checks passed. No principle changed, so `cairn_impact` was skipped. `devtools::document()` gives no diff, and `man/check_supplement.Rd` came only from it. No `README.Rmd` and no pkgdown site. The changelog has the edited unreleased `check_supplement()` bullet and no milestone number.

spawned: diff-bug, blame-history, prior-review, ripple

- ripple #1: NEWS.md renv bullet says `check_supplement()` "finds no problem" in a renv site, which a site with placeholders no longer meets — fix now (now "no problem in the files that renv adds").
- ripple #2: the template guide's "It finds:" list in `inst/template/_README.md` lacks the placeholder check — fix now (one bullet added).
- ripple #3: the same list in `README.md` lacks it — fix now (one bullet added).
- prior-review: no regression of an archived review finding or lesson; PR comment probe empty.
- diff-bug #1: an unreadable file (mode 000) gives no row and no message, while the help lists only missing, folder, or not UTF-8 — fix now (the help now names a file that cannot be read for both the line and the example checks; the check never stops on a read, by AC2 and AC3).
- diff-bug #2: an unchanged example file with a BOM, a lost final newline, or CR-only ends gives no row, while the line check drops a BOM — follow-up ("Match example files after editor saves").
- diff-bug #3: `report_hash()` reads and copies all of a large `data/example.csv` on each check — fix now (a file over twice the template's size is not read; a CR LF copy cannot be larger).
- diff-bug #4: the `_quarto.yml` line matches only the exact line, not a quoted URL or a trailing comment — reject, planned change (AC2's whole-line rule, stated on the help page).
- diff-bug #5: a one-item list title, `yes`, a single-map `authors`, and nulls give no row — reject, planned change (AC1: a value that is not one text value does not count).
- diff-bug #6: links behave as other reads do — noted, no finding.
- diff-bug #7: NEWS.md line 61 is 83 characters wide — fix now (rewrapped).
- diff-bug #8: the `contact` list case repeats the `paper-title: 2024` code path — fix now (removed).
- diff-bug #9: `expect_no_error()` around calls an exact expectation follows — reject, false (AC1 to AC3 promise no error, and the wrapper names that promise; the file uses the same form).
- diff-bug #10: `expect_setequal(names(placeholder_lines), line_files)` checks a test list against the code — reject, false (it is the independent statement of the seven files that check discrimination asks for).
- diff-bug #11: the release test comment restates the next lines — fix now (removed).
- diff-bug #12: the per-file and per-field loops run one code path several times — reject, false (each pass pins a different list entry that AC1 and AC2 name).
- blame-history #1: the `_quarto.yml` line scan reads a site YAML file without `yaml_read_file_text()`, which D-015 asks of every function that reads one — reject, false (D-015 governs YAML parses and their parse errors; the scan parses nothing and never stops, so no parse error can arise).
- blame-history #2: the test "one problem of any other check stops the release" does not list `placeholder` — fix now (added).
- blame-history #3: `plain_lines()` and the example comparison read through symbolic links, unlike `plain_files()` — reject, false (the links rule there is about what gets published; these reads yield only an equality, and the stale-output check reads reports through links the same way).
- blame-history #4: `report_hash()` is named for reports and used on a CSV — reject, style.
- blame-history #5: `read_text_lines()` says "nothing was written" in an error the scan catches — reject, style (the message never reaches the user).
- blame-history #6: `checked_site()` puts `placeholders` before `env`, unlike `git_site(env)` — fix now (`env` first).
- blame-history #7: `check_placeholders()` gets no `call`, so an unreadable installed template names an internal helper — reject, edge (a broken package install, outside documented use; the effect is an error).
- blame-history #8: `fill_placeholders()` leaves `(Year)` and `*Journal Name*` in the citation — reject, false (test data; a partial placeholder gives no row by AC1's design, and the release accepts it).
- blame-history #9: loose wording in the help's opening sentence and in "They are also the" in NEWS — reject, style.
- Re-run after the fixes: full suite with NOT_CRAN=true 349 tests, 0 failed, 8 skipped. No snapshot file changed (`git diff --name-only` lists no `_snaps` path).
- `devtools::check()` on cfd053b: 0 errors, 0 warnings, 0 notes. Open PRs by the operator: none, so the feature cap of 1 is not reached.
