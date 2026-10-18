# M007: add_report() and add_data() list new site files

- **Status:** review
- **Priority:** high
- **Depends on:** M006
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — new exported R functions and a change to the template's home page
- **Branch/PR:** m007-add-report-data

## Goal

Export `add_report()` and `add_data()`, which add an analysis report or a data file to a site and list it in the site's configuration.

## Scope

**In:** The template's home page lists the reports through a Quarto listing, in place of its hand-written table. `add_report(name, title, description = "", path = ".")` writes a report stub and adds it to the Analyses menu in `_quarto.yml`. `add_data(file, description, path = ".")` puts a file in `data/` and adds it to the `data` list in `_supplement.yml`. Both functions insert lines as text, so every comment stays. Tests, help pages with examples, README and NEWS text.

**Out:**
- Removing or renaming a report or a data file: not planned. Add a candidate row if it is needed.
- Python reports: out of scope for version 1 (DESIGN Purpose & Scope).
- Checks of the whole site before a release: the "release checks" candidate row.
- Files in `data/` with names that Quarto reads as Markdown: the file-name rule refuses them, and the "shortcode edge cases" candidate row holds the shortcode side.

## Acceptance criteria

- [x] AC1: The template's home page lists the reports through a Quarto listing with `type: table`, `contents: analyses/*.qmd`, and `fields: [title, description]`, in place of the hand-written table. `analyses/example.qmd` has a `description:` value. A render of the template shows a row for the example report with its title, its description, and a link whose target ends in `analyses/example.html`.
- [x] AC2: `add_report(name, title, description = "")` writes `analyses/<name>.qmd` as UTF-8. Its front matter holds `title`, and `description` when it is not empty, as double-quoted and escaped YAML strings. The function adds an item with `href: analyses/<name>.qmd` and `text: <title>`, also double-quoted and escaped, as the last item of the Analyses menu in `_quarto.yml`. A test reads the front matter and `_quarto.yml` with the yaml package and finds each value unchanged. The test uses these titles and descriptions: a plain one, one with `"`, `:`, `#`, `\`, and `'`, `No`, `1.10`, ones that start with `-`, `[`, and `*`, and a non-ASCII one.
- [x] AC3: If `file` is outside the site's `data/` folder, `add_data(file, description)` copies it byte for byte to `data/<base name>`. If `file` is already `data/<base name>` in the site, the function copies nothing. In both cases it adds an item with `file: data/<base name>` and `description`, double-quoted and escaped, as the last item of the `data` list under `supplement:` in `_supplement.yml`. A test reads `_supplement.yml` with the yaml package and finds the item, for the descriptions that AC2 lists.
- [x] AC4: For a block-style list, each function keeps the other lines of the file that it edits. A test compares the lines that `readLines()` reads before and after the edit. It finds the original lines unchanged and in order, with only the new item's lines added. The test uses the template's files, and files with a 4-space indent, a navbar item after the Analyses menu, a key after `data`, and no line break at the end.
- [x] AC5: In each case below, the function stops with an error of class `supplement_error` plus one subclass for the case, and it writes nothing. `add_data()` checks `_supplement.yml` before it copies. A test fires each listed form, asserts the error class, and compares the folder's file list and file bytes before and after.
  - Both functions: `path` is not one non-empty string (`supplement_error_argument`).
  - `add_report()`: `name` is not one string of ASCII letters, digits, `-`, and `_` that starts with a letter or digit (`_x`, `-x`, `a b`, `a.b`, `""`, a non-ASCII name, `c("a", "b")`). `title` is not one string with a character other than a space, or `description` is not one string. `title` or `description` holds a line break. The report file exists. The folder has no `_quarto.yml`. `_quarto.yml` has no Analyses menu in block form, which includes a flow-style `menu: [...]`.
  - `add_data()`: `file` is not one string, does not exist, or is a folder. `description` is not one string, or it holds a line break. `data/<base name>` exists and is not `file`. The file is already in the `data` list. The base name breaks the template's file-name rule of ASCII letters, digits, `.`, `-`, and `_`, with no two symbols in a row and no `.` at the start (a space, `'`, `--`, `._`, `.hidden`, a non-ASCII name). The folder has no `_supplement.yml` (`supplement_error_no_metadata`). `_supplement.yml` has no `data` list in block form under `supplement:`, which includes `data: []`.
  - The two not-found errors, no Analyses menu and no `data` list, show the lines to add by hand.
- [x] AC6: Start with a site that `create_supplement()` makes, and run `add_report()` and `add_data()` on it with a plain title and plain descriptions. Then `quarto render` exits with status 0. With HTML tags removed, the home page's listing has a row with the new report's title and description, and its data table has a row for the new file. The navbar's Analyses menu links to the new page. Quarto reads these values as Markdown, so the special-character probes stay in AC2 and AC3, which do not render.
- [x] AC7: The package README describes both functions. Each help page has an example that writes to a temporary folder. NEWS.md has an entry for both functions and for the home page listing.

## Coverage

- AC1 → T1
- AC2 → T2, T3
- AC3 → T2, T4
- AC4 → T2, T3, T4
- AC5 → T3, T4, T7
- AC6 → T5
- AC7 → T6

## Tasks

- [x] T1: In `inst/template/index.qmd`, replace the "Analysis Reports" table with a Quarto listing of `analyses/*.qmd` in table form, with the title and description fields. Add a `description:` to `analyses/example.qmd`. Change `_README.md` text that tells authors to edit the table. Update `tests/testthat/test-template.R`, and add the AC1 render check.
- [x] T2: Write an internal helper that inserts one item at the end of a block-style YAML list as text. It finds the list by its key path, reads the indent of the items, double-quotes and escapes each string, and keeps the file's other lines. Test it directly against the AC4 fixture files, because its logic stands apart from the two callers.
- [x] T3: Write `add_report()` in `R/add-report.R`, with tests for AC2 and its AC5 cases. Check every argument and the menu before the first write.
- [x] T4: Write `add_data()` in `R/add-data.R`, with tests for AC3 and its AC5 cases. Check every argument and `_supplement.yml` before the copy.
- [x] T5: Add the AC6 render test. Reuse the skip helpers in `tests/testthat/helper-template.R`, so that the test skips without Quarto, knitr, or rmarkdown.
- [x] T6: Add roxygen documentation with examples that write to `tempdir()`, and run `devtools::document()`. Describe both functions in the README, and add a NEWS.md entry for them and for the home page listing.
- [x] T7: Fix review return 1 and the fix-now findings in the Review section: reject a name or base name that ends in a line break, a linked `analyses/`, `data/`, or `data/<base name>`, and invalid UTF-8 text; then the other fix-now items, each with a test.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: not run — work named at the question set.
- 2026-10-18: question set: which work to plan — scaffolding, as M006 and M007.
- 2026-10-18: absorbs the `add_report()` and `add_data()` part of the candidate row "scaffolding functions".
- 2026-10-18: question set: how the home page lists reports — a Quarto listing of `analyses/*.qmd`.
- 2026-10-18: question set: how to edit `_quarto.yml` and `_supplement.yml` — insert lines as text and keep every comment.
- 2026-10-18: plan gate chose to insert lines as text over a rewrite with the yaml package, because a rewrite drops every comment in the template's files and can change quoting; falsified by a common hand-edited file shape that the text insert cannot handle and that a rewrite can.
- 2026-10-18: plan gate chose a Quarto listing over an `add_report()` edit of the hand-written table in `index.qmd`, because the listing needs no edit to the home page; falsified by a listing that does not render the title and description as the table did.
- 2026-10-18: plan chose to let `add_data()` register a file already in `data/` without a copy, after the criteria audit found that the first draft refused that common case.
- 2026-10-18: criteria audit (full mode, fresh Opus reader) returned 10 findings on the M007 draft and 3 across both milestones. Fixed all: AC2 reads only the front matter, double-quotes values, and probes YAML 1.1 forms; AC3 handles a file already in `data/`; AC4 limits its promise to block-style lists and names its fixture shapes; AC5 adds argument, already-listed, and leading-dot cases, names the not-found errors, reuses classes, and checks before the copy; AC6 drops its test-skip clause, which T5 now carries; AC7 adds help page examples. The home page gap became AC1.
- 2026-10-18: re-audit (full mode, same fresh reader) of AC1 and AC2 after the question set returned 6 findings. Fixed all: AC1 names the listing's fields and matches the link by its end; AC2 double-quotes the menu text and writes UTF-8; AC5 rejects an empty title and line breaks; AC6 renders plain values and compares cell text without tags, because Quarto reads these values as Markdown.
- 2026-10-18: inbox sweep: no open issues or pull requests.
- 2026-10-18: implement started on branch m007-add-report-data.
- 2026-10-18: T1 done: index.qmd lists analyses/*.qmd in a table listing (id `reports`, title column named Report, sort and filter controls off); example.qmd has a description; _README.md has a Reports section; static and render tests added. Suite 696 pass, 0 skip.
- 2026-10-18: T2 implementation choice: the helper in R/yaml-insert.R finds the list by indent and key, inserts after the list's last content line (trailing comments stay with what follows), copies the last item's dash-to-key offset, and keeps the line ending, final line break, and byte order mark. `yaml_appended()` re-reads the result with the yaml package, so callers can stop before writing when the scanner misreads a file. Values are double-quoted with `\`, `"`, control characters, U+2028, U+2029, and U+FEFF escaped.
- 2026-10-18: T2 done: 12 direct tests over the AC4 shapes and not-found forms; a planted insert-at-end defect failed 6 of them. Suite 800 pass, 0 skip.
- 2026-10-18: T3 implementation choices: error subclasses `supplement_error_report_name`, `_line_break`, `_no_config`, `_no_menu`, plus reused `_argument` and `_file_exists`; `_yaml` when the re-read check fails and `_encoding` for a non-UTF-8 file. The menu is looked up under navbar `left`, then `right`. The two not-found errors are base R conditions with a cli header, because cli drops leading spaces from message lines. The stub holds a short note and a `setup` chunk with `set.seed(2026)`.
- 2026-10-18: T3 done: add_report() in R/add-report.R, shared checks in R/add-utils.R, shared test helpers moved to helper-files.R; tests cover the AC2 probes, AC4 shapes for _quarto.yml, and the AC5 add_report() cases. Suite 976 pass, 0 skip.
- 2026-10-18: T4 implementation choices: new subclasses `supplement_error_no_file`, `_file_name`, `_already_listed`, `_no_data_list`, plus reused `_argument`, `_line_break`, `_no_metadata`, `_file_exists`. A file counts as already in `data/` when `normalizePath()` of it equals that of `data/<base name>`. The already-listed check strips leading `./` from listed `file` values. The description may be empty.
- 2026-10-18: T4 done: add_data() in R/add-data.R; tests cover the AC3 probes with a byte-for-byte copy, the no-copy route, AC4 shapes for _supplement.yml, and the AC5 add_data() cases. Suite 1127 pass, 0 skip.
- 2026-10-18: T5 done: tests/testthat/test-add-render.R renders a create_supplement() site after add_report() and add_data(), and finds the listing row, the data table row, and the navbar link; it skips through skip_if_no_quarto(). 7 expectations pass.
- 2026-10-18: T6 done: roxygen pages for add_report() and add_data() with tempdir() examples, both run by hand; README "Add reports and data" section; NEWS entries for both functions and the home page listing; the template's _README.md names both functions. No _pkgdown.yml exists, so no reference row. Suite 1134 pass, 0 skip; devtools::check() 0 errors, 0 warnings, 0 notes.
- 2026-10-18: claim audit: 98 claims read, 6 corrected — R/add-report.R, R/add-data.R, R/add-utils.R, R/yaml-insert.R, README.md, inst/template/_README.md (missing `supplement_error_write` and R's own write errors, white space in the title rule, "directly in data/", the listing text for a report with no description, two internal comments); the same reader confirmed each correction on its re-read.
- 2026-10-18: implement done; status review. Suite 1134 pass, 0 skip.
- 2026-10-18: review started; main at c78239a, not moved since the cut; no PR; Copilot round off.
- 2026-10-18: review return 1: AC5 fails for an add_data() base name ending in `\n` (accepted, diff-bug #6); add_report() and add_data() write through a linked `analyses/` or `data/` folder outside the site (prior-review #1, #2); an invalid UTF-8 description is written as `"NA"` (diff-bug #2). The fix-now findings in the Review section ride on the same return.
- 2026-10-18: implement resumed for review return 1; added T7 (minor amendment).
- 2026-10-18: T7 implementation choices: files are split at "\n" with each line keeping its "\r" and a final "" for a closing line break, so bytes round-trip and mixed endings stay; new lines take the majority ending; a failed write restores the old bytes. New subclass `supplement_error_ignored_file` for saved R objects; `supplement_error_encoding` also covers invalid UTF-8 arguments; links, letter-case clashes, and stale `_freeze/analyses/<name>` stop as `supplement_error_file_exists`. `copy_file()` and `write_bytes()` are wrappers so tests can mock them. CR-only files went to the "YAML insert edge shapes" row. Added D-010 and updated DESIGN.md.
- 2026-10-18: T7 done: every fix-now finding has a test; a render of a description with escaped U+FFFE and U+FFFF exited 0. Suite 1257 pass, 0 skip.
- 2026-10-18: checkpoint: claim audit 2 corrections applied (any letter-case match in `data/` that is not `file` stops; names with `_` at both ends refused, which also fixes blame-history #3, so it left the "YAML insert edge shapes" row; three wording fixes). The auditor's re-read is pending. Suite 1267 pass, 1 skip (the case-sensitive disk test).
- 2026-10-18: claim audit: 125 claims read, 5 corrected — R/add-data.R, R/add-report.R (the letter-case rule now checks every match, names with `_` at both ends are refused, the `.gitignore` wording, "and any folder it made", the file_exists message in the two-file case); the same reader confirmed each on its re-read, the twin case on a case-sensitive disk image.
- 2026-10-18: implement done after review return 1; status review. Suite 1266 pass, 1 skip.

## Review

Evidence run at d5a8b78: `devtools::test()` 1134 expectations, 0 failed, 0 skipped, 0 errors (Quarto 1.10.19 on PATH, so render tests ran).

- AC1: test-template.R "the home page lists the reports through a Quarto listing" reads index.qmd front matter (`type: table`, `contents: analyses/*.qmd`, `fields: [title, description]`, a `::: {#reports}` div, no `|` table line) and finds a non-empty `description` in example.qmd; "the rendered home page lists the example report" renders the template and finds one listing row with cells equal to the example's title and description and a link ending `analyses/example.html`. Pass.
- AC2: test-add-report.R "a report stub and its menu item read back with each value unchanged" uses the 8 probes in helper-files.R (plain; one with `"`, `:`, `#`, `\`, `'`; `No`; `1.10`; leading `-`, `[`, `*`; non-ASCII) as title and description, reads the front matter and `_quarto.yml` with the yaml package, and finds each value unchanged and each new item last in the Analyses menu with `href: analyses/<name>.qmd`. "the non-ASCII title is written as UTF-8 bytes" and "an empty description writes no description key" pass. A direct run showed `title: "No"`, `description: "1.10"`, and `text: "No"` written double-quoted. Pass.
- AC3: test-add-data.R "a file outside the site is copied byte for byte and listed last" copies a 260-byte binary file per probe, compares bytes, and reads `_supplement.yml` with yaml to find `file: data/<base name>` and the probe description as the last `data` item; "a file already in the site's data folder is listed and not copied" finds bytes and mtime unchanged and the item listed, by absolute and by relative path. Pass.
- AC4: `added_lines()` (helper-files.R) compares `readLines()` before and after and requires the original lines unchanged, in order, with one run added. add_report(): the template's `_quarto.yml`, a 4-space indent, a navbar item after the Analyses menu, and no final line break (bytes prefix kept, no newline added). add_data(): the template's `_supplement.yml`, a 4-space indent, a key after `data`, and no final line break. test-yaml-insert.R also tests the helper on these shapes; a planted insert-at-end defect failed 6 of its tests at T2. Pass.
- AC5: `expect_report_error()` and `expect_data_error()` assert the subclass and `supplement_error` and compare `folder_state()` (file list and bytes) before and after. Fired: path NA, "", length 2, numeric, NULL (`_argument`, both functions); name `_x`, `-x`, `a b`, `a.b`, "", `café`, length 2, NA, numeric (`_report_name`); title "", "   ", NA, length 2, numeric and description NA, length 2, numeric, NULL (`_argument`); `\n`, `\r\n`, `\r` in title and description (`_line_break`); existing `example`, `analyses` as a file (`_file_exists`); no `_quarto.yml` (`_no_config`); flow `menu: [...]`, renamed menu, no navbar (`_no_menu`). add_data(): file NA, length 2, numeric, NULL (`_argument`); missing file, a folder (`_no_file`); description cases (`_argument`, `_line_break`); different `data/example.csv`, `data` as a file (`_file_exists`); `data/example.csv` itself (`_already_listed`); a space, `'`, `--`, `._`, `.hidden`, `café`, `_x_` (`_file_name`); no `_supplement.yml` (`_no_metadata`); `data: []`, flow items, no `data`, top-level `data` (`_no_data_list`). The no-data-list cases show no copied file, so the check runs before the copy. Both not-found errors were matched for the indented lines to add by hand and for the user's call. Pass.
- AC6: test-add-render.R makes a site with create_supplement(), runs add_report("models", "Model Comparison", "Fits and compares the models.") and add_data() on a CSV, and runs `quarto render`: exit 0; with tags stripped, one listing row equals the title and description and links to `analyses/models.html`; a data table row holds the file name and description; the navbar header holds `href="./analyses/models.html"`. 7 expectations pass. Pass.
- AC7: README.md lines 63–85 ("Add reports and data") describe both functions; man/add_report.Rd and man/add_data.Rd examples, extracted with `tools::Rd2ex()`, use `tempdir()` and ran clean; NEWS.md has entries for the home page listing and for both functions. Pass.
- Gate: `cairn_validate.py` exit 0, all checks pass; no principle changed, so `cairn_impact` not run; `devtools::document()` gives no diff; no README.Rmd and no `_pkgdown.yml`; NEWS.md has the entries; no new top-level files; `devtools::check()` 0 errors, 0 warnings, 0 notes. Pass.
- spawned: diff-bug, blame-history, prior-review
- diff-bug #1: on a case-insensitive disk, `add_data(".../data/Scores.csv")` for a listed `data/scores.csv` lists `data/Scores.csv` too, which is not on disk — fix now, fixed 8d00fad
- diff-bug #2: an invalid UTF-8 description is written as `"NA"` with no error (title gives a wrong error) — fix now (return floor: load-bearing defect), fixed 8d00fad
- diff-bug #3: a `>` or `|` block-scalar description at the end of `_supplement.yml` gives a false `supplement_error_yaml`, because the re-read joins lines with no final line break — fix now, fixed 8d00fad
- diff-bug #4: U+FFFE and U+FFFF are not escaped; through add_report()'s description they make `quarto render` fail — fix now, fixed 8d00fad
- diff-bug #5: a UTF-16 file (NUL bytes) gives a plain R error, not `supplement_error_encoding` — fix now, fixed 8d00fad
- diff-bug #6: the add_data() file-name rule accepts a name ending in `\n`, because PCRE `$` matches before a final line break — fix now (return floor: AC5 fails), fixed 8d00fad
- diff-bug #7: a file with mixed LF and CRLF endings is split wrongly, so a present menu or list reads as missing — fix now, fixed 8d00fad
- diff-bug #8: `#` lines inside a block scalar, and `|+` trailing blank lines, count as comments, so the insert point is wrong and the re-read refuses valid YAML — follow-up (candidate row "YAML insert edge shapes")
- diff-bug #9: a title of only NBSP or U+3000 passes, though the help page says white space — fix now, fixed 8d00fad
- diff-bug #10: a write that fails after the file is opened leaves `_quarto.yml` or `_supplement.yml` cut short — fix now, fixed 8d00fad (for errors; the disk-full warning path was fixed in f603729 under pass-2 diff-bug #1)
- diff-bug #11: on a case-sensitive disk, `add_report("Example")` makes `Example.qmd` beside `example.qmd` — fix now, fixed 8d00fad; a menu that already lists `analyses/<name>.qmd` with the file gone gets a second item — follow-up (candidate row "YAML insert edge shapes")
- diff-bug #12: a `data/<base name>` link to a file outside the site counts as already in `data/` — fix now, fixed 8d00fad
- diff-bug #13: the site's own files, such as `_supplement.yml`, pass the file-name rule — reject (planned change: AC5 states the rule, and the file is the user's choice)
- diff-bug #14: `yaml_append_lines()` writes a stray `: ` line for a one-key item; no caller passes one — fix now, fixed 8d00fad
- diff-bug #15: for an item written as `-` alone, the key offset is read from the next line, not the next content line — fix now, fixed 8d00fad
- diff-bug #16: no test fires `supplement_error_encoding`, `supplement_error_yaml`, or `supplement_error_write` through the functions, or the R-error cleanup path — fix now, fixed 8d00fad
- diff-bug #17: the navbar check matches the link anywhere in the header, and the add_report() shapes test does not check where the lines went — fix now, fixed 8d00fad
- diff-bug #18: check-before-copy is shown only by folder state, which a copy-then-clean-up version also passes — fix now, fixed 8d00fad (one half of that test was made able to fail in f603729, pass-2 diff-bug #3)
- diff-bug #19: test-add-report.R uses `|>`, which needs R 4.1, with no R floor in DESCRIPTION — fix now, fixed 8d00fad
- diff-bug #20: cairn/DESIGN.md lists add_report() and add_data() as planned, and Architecture does not name the new files — fix now, fixed 8d00fad
- diff-bug #21: Quarto reads every `yaml_quote()` escape the same as R's yaml package — reject (false: no defect; `\slash` rendering as `back` is the Markdown reading that AC6 leaves out)
- blame-history #1: add_data() accepts `.rds`, `.rda`, `.RData`, `.qs`, `.qs2`, which the template's `.gitignore` blocks, so the site's link breaks in a clone and D-008 stops its render — fix now, fixed 8d00fad
- blame-history #2: a stale `_freeze/analyses/<name>/` from a deleted report would be reused for the new stub under `freeze: true` — fix now, fixed 8d00fad
- blame-history #3: a bare base name `_x_` passes the file-name rule but reads as emphasis — follow-up (candidate row "YAML insert edge shapes"); later fixed in 5ea5ec9 by the claim audit, and removed from that row
- blame-history #4: DESIGN.md still says planned — fix now (same as diff-bug #20), fixed 8d00fad
- blame-history #5: the text-insert choice has no D-entry — fix now, fixed 8d00fad (D-010)
- blame-history #6: mixed CRLF and LF endings — fix now (same as diff-bug #7), fixed 8d00fad
- prior-review #1: a `data` link to a folder outside the site passes, and add_data() copies through it (regresses the M006 review lesson) — fix now (return floor: load-bearing defect), fixed 8d00fad
- prior-review #2: an `analyses` link to a folder outside the site passes, and add_report() writes through it — fix now (return floor: load-bearing defect), fixed 8d00fad
- prior-review #3: the report-name rule accepts `--` and `__` — reject (planned change: AC5 states the name rule)
- prior-review #4: the docs suggest rendering a new report, which needs its data — reject (planned change: a new report has no stored output, and the guide says to render on the data machine)

Pass 2 (after review return 1), evidence run at 7bf19c8: `devtools::test()` 1267 expectations, 0 failed, 0 errors, 1 test skipped ("on a case-sensitive disk, any file in data/ that differs only in letter case stops", which needs a case-sensitive disk; the claim-audit reader ran that case on a case-sensitive disk image and it stopped as expected).

- AC1 (pass 2): test-template.R listing tests pass unchanged (57 expectations in the file). Pass.
- AC2 (pass 2): test-add-report.R probe, UTF-8, and empty-description tests pass (218 expectations in the file). Pass.
- AC3 (pass 2): test-add-data.R copy, no-copy, and probe tests pass; the no-copy route now lists the name on disk. Pass.
- AC4 (pass 2): the add_report() and add_data() shape tests pass, and the add_report() shapes now also check the new item is last in the menu; test-yaml-insert.R adds CRLF, mixed-ending, and block-scalar shapes (127 expectations). Pass.
- AC5 (pass 2): every pass-1 case still fires its class with folder state unchanged; `x.csv\n`, `_data_`, `_x-y_`, and `ab\n` now stop too; check-before-copy is shown by a mocked `copy_file()` that fails the test if it runs. Pass.
- AC6 (pass 2): test-add-render.R renders and finds the listing row, the data row, and the Analyses dropdown links in order (`example.html`, `models.html`); 8 expectations pass. Pass.
- AC7 (pass 2): README and NEWS unchanged in substance; both help examples, extracted with `tools::Rd2ex()`, ran clean again at 7bf19c8. Pass.
- Gate (pass 2): `cairn_validate.py` all checks pass; no principle changed (DESIGN.md changed only Function Families and Architecture), so `cairn_impact` not run; `devtools::document()` gives no diff; `devtools::check()` 0 errors, 0 warnings, 0 notes. Pass.
- spawned: diff-bug, blame-history, prior-review
- diff-bug #1 (pass 2): a disk-full write gives only a warning, so the old bytes are not restored, the file is left cut short, and the function reports success; the restore test mocks an error, not this path — fix now, fixed f603729 (a run on a full 2 MB disk image then stopped with `supplement_error_write` and kept all 4090 bytes)
- diff-bug #2 (pass 2): a valid UTF-8 value marked "bytes" stops as `supplement_error_yaml`, because the re-read compares it with a UTF-8 string — fix now, fixed f603729
- diff-bug #3 (pass 2): the already-listed half of the check-before-copy test takes the no-copy route, so it cannot fail — fix now, fixed f603729
- diff-bug #4 (pass 2): the add_data() shapes test does not check where the item went — fix now, fixed f603729
- diff-bug #5 (pass 2): `*.knit.md`, `*.utf8.md`, `*.rmarkdown`, and `*.quarto_ipynb`, which the template's `.gitignore` also blocks, pass add_data() — fix now, fixed f603729
- diff-bug #6 (pass 2): a missing `title` or `description` gives base R's missing-argument error, not `supplement_error_argument` — fix now, fixed f603729
- diff-bug #7 (pass 2): Windows-reserved report names such as `con`, and base names ending in `.`, pass — follow-up (candidate row "Windows-safe names")
- diff-bug #8 (pass 2): a block-scalar value at the very end of a file with no final line break gains a trailing `\n` after the insert, which the re-read cannot see — follow-up (candidate row "YAML insert edge shapes")
- blame-history #1 (pass 2): the same gitignored names as diff-bug #5 — fix now (same fix), fixed f603729
- blame-history #2 (pass 2): the re-read compares only the list, while D-010 says the result must be the old file with the change — fix now, fixed f603729
- blame-history #3 (pass 2): a new stub has no stored output, so a rebuild without R fails on it until the author renders it — reject (planned change: the help, the message, and the guide say to render a new report by name)
- blame-history #4 (pass 2): DESIGN.md Function Families carries status markers, though the file says status lives in ROADMAP.md — fix now, fixed f603729
- blame-history #5 (pass 2): a second menu item for a listed report whose file is gone, and the block-scalar shapes — follow-up (already in "YAML insert edge shapes")
- prior-review #1 (pass 2): the report-name rule accepts `--` and `__`, which Quarto might read as Markdown — reject (false: a render of `a--b` and `c__d__e` gave navbar and listing links `./analyses/a--b.html` and `./analyses/c__d__e.html`, and both pages exist)
- prior-review #2 (pass 2): `is_link()` misses Windows junctions, so a junction `data/` or `analyses/` passes — follow-up (candidate row "Windows-safe names", which points to "Windows check")
- prior-review #3 (pass 2): `add_data("scores.csv/")` says the file does not exist or is a folder — fix now, fixed f603729
- Pass 2 fix-now check at f603729: `devtools::test()` 1298 expectations, 0 failed, 1 test skipped (the case-sensitive disk test); `cairn_validate.py` all checks pass; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- prior-review #4 (pass 2): Quarto might rewrite a path-like report description in the listing — reject (false: a render showed the descriptions `data`, `../data`, and `example.qmd` as written)
