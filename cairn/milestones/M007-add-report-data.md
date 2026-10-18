# M007: add_report() and add_data() list new site files

- **Status:** in-progress
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

- [ ] AC1: The template's home page lists the reports through a Quarto listing with `type: table`, `contents: analyses/*.qmd`, and `fields: [title, description]`, in place of the hand-written table. `analyses/example.qmd` has a `description:` value. A render of the template shows a row for the example report with its title, its description, and a link whose target ends in `analyses/example.html`.
- [ ] AC2: `add_report(name, title, description = "")` writes `analyses/<name>.qmd` as UTF-8. Its front matter holds `title`, and `description` when it is not empty, as double-quoted and escaped YAML strings. The function adds an item with `href: analyses/<name>.qmd` and `text: <title>`, also double-quoted and escaped, as the last item of the Analyses menu in `_quarto.yml`. A test reads the front matter and `_quarto.yml` with the yaml package and finds each value unchanged. The test uses these titles and descriptions: a plain one, one with `"`, `:`, `#`, `\`, and `'`, `No`, `1.10`, ones that start with `-`, `[`, and `*`, and a non-ASCII one.
- [ ] AC3: If `file` is outside the site's `data/` folder, `add_data(file, description)` copies it byte for byte to `data/<base name>`. If `file` is already `data/<base name>` in the site, the function copies nothing. In both cases it adds an item with `file: data/<base name>` and `description`, double-quoted and escaped, as the last item of the `data` list under `supplement:` in `_supplement.yml`. A test reads `_supplement.yml` with the yaml package and finds the item, for the descriptions that AC2 lists.
- [ ] AC4: For a block-style list, each function keeps the other lines of the file that it edits. A test compares the lines that `readLines()` reads before and after the edit. It finds the original lines unchanged and in order, with only the new item's lines added. The test uses the template's files, and files with a 4-space indent, a navbar item after the Analyses menu, a key after `data`, and no line break at the end.
- [ ] AC5: In each case below, the function stops with an error of class `supplement_error` plus one subclass for the case, and it writes nothing. `add_data()` checks `_supplement.yml` before it copies. A test fires each listed form, asserts the error class, and compares the folder's file list and file bytes before and after.
  - Both functions: `path` is not one non-empty string (`supplement_error_argument`).
  - `add_report()`: `name` is not one string of ASCII letters, digits, `-`, and `_` that starts with a letter or digit (`_x`, `-x`, `a b`, `a.b`, `""`, a non-ASCII name, `c("a", "b")`). `title` is not one string with a character other than a space, or `description` is not one string. `title` or `description` holds a line break. The report file exists. The folder has no `_quarto.yml`. `_quarto.yml` has no Analyses menu in block form, which includes a flow-style `menu: [...]`.
  - `add_data()`: `file` is not one string, does not exist, or is a folder. `description` is not one string, or it holds a line break. `data/<base name>` exists and is not `file`. The file is already in the `data` list. The base name breaks the template's file-name rule of ASCII letters, digits, `.`, `-`, and `_`, with no two symbols in a row and no `.` at the start (a space, `'`, `--`, `._`, `.hidden`, a non-ASCII name). The folder has no `_supplement.yml` (`supplement_error_no_metadata`). `_supplement.yml` has no `data` list in block form under `supplement:`, which includes `data: []`.
  - The two not-found errors, no Analyses menu and no `data` list, show the lines to add by hand.
- [ ] AC6: Start with a site that `create_supplement()` makes, and run `add_report()` and `add_data()` on it with a plain title and plain descriptions. Then `quarto render` exits with status 0. With HTML tags removed, the home page's listing has a row with the new report's title and description, and its data table has a row for the new file. The navbar's Analyses menu links to the new page. Quarto reads these values as Markdown, so the special-character probes stay in AC2 and AC3, which do not render.
- [ ] AC7: The package README describes both functions. Each help page has an example that writes to a temporary folder. NEWS.md has an entry for both functions and for the home page listing.

## Coverage

- AC1 → T1
- AC2 → T2, T3
- AC3 → T2, T4
- AC4 → T2, T3, T4
- AC5 → T3, T4
- AC6 → T5
- AC7 → T6

## Tasks

- [x] T1: In `inst/template/index.qmd`, replace the "Analysis Reports" table with a Quarto listing of `analyses/*.qmd` in table form, with the title and description fields. Add a `description:` to `analyses/example.qmd`. Change `_README.md` text that tells authors to edit the table. Update `tests/testthat/test-template.R`, and add the AC1 render check.
- [x] T2: Write an internal helper that inserts one item at the end of a block-style YAML list as text. It finds the list by its key path, reads the indent of the items, double-quotes and escapes each string, and keeps the file's other lines. Test it directly against the AC4 fixture files, because its logic stands apart from the two callers.
- [x] T3: Write `add_report()` in `R/add-report.R`, with tests for AC2 and its AC5 cases. Check every argument and the menu before the first write.
- [ ] T4: Write `add_data()` in `R/add-data.R`, with tests for AC3 and its AC5 cases. Check every argument and `_supplement.yml` before the copy.
- [ ] T5: Add the AC6 render test. Reuse the skip helpers in `tests/testthat/helper-template.R`, so that the test skips without Quarto, knitr, or rmarkdown.
- [ ] T6: Add roxygen documentation with examples that write to `tempdir()`, and run `devtools::document()`. Describe both functions in the README, and add a NEWS.md entry for them and for the home page listing.

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
