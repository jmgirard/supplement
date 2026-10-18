# M004: Home page from _supplement.yml with shortcodes

- **Status:** review
- **Priority:** high
- **Depends on:** M003
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the template's home page and its shortcodes are what authors edit and readers see
- **Branch/PR:** m004-home-page-shortcodes

## Goal

Drive the template's home page from one `_supplement.yml` file through a Quarto extension whose shortcodes render the DOI badge, the Zenodo download link, and the data table.

## Scope

**In:** `_supplement.yml` with a `supplement:` map, loaded through `metadata-files`. A Quarto extension in `inst/template/_extensions/supplement/` with Lua shortcodes `supplement-doi`, `supplement-download`, and `supplement-data-table`. The template's `index.qmd` rewritten to use them and `{{< meta >}}`. Tests and README guidance for `_supplement.yml`.

**Out:**
- `CITATION.cff` and `.zenodo.json` written from `_supplement.yml` → the "metadata writers" candidate row.
- R functions → the "scaffolding functions" candidate row.
- A release check that finds missing files or DOIs → the "release checks" candidate row.

## Acceptance criteria

- [x] AC1: The template's `_quarto.yml` lists `_supplement.yml` under `metadata-files`. `_supplement.yml` has a `supplement:` map holding `paper-title`, `citation`, `preprint`, `contact`, `license` (with `code` and `content`), `authors` (a list of entries with `name`, `orcid`, and `affiliation`), `zenodo` (with `version-doi`, `concept-doi`, and `archive-url`), and `data` (a list of entries with `file` and `description`).
- [x] AC2: In a fresh template folder made as in M003 AC2, a test sets `supplement.paper-title`, `supplement.citation`, and `supplement.zenodo.version-doi` to new values made of ASCII letters, digits, and spaces (the DOI also `.` and `/`), then runs `quarto render`. `docs/index.html` then contains each new value. The template's `index.qmd` holds none of the template's original values for those keys as literal text.
- [x] AC3: On a fixture page, `{{< supplement-doi >}}` renders an `<a>` with `href="https://doi.org/<doi>"` that wraps an `<img>` with `src="https://zenodo.org/badge/DOI/<doi>.svg"`. `<doi>` is `version-doi` when it is set, else `concept-doi`. When both are empty, the shortcode renders nothing and the render exits 0. `{{< supplement-download >}}` renders an `<a>` whose `href` equals `archive-url`, and renders nothing when that value is empty.
- [x] AC4: `{{< supplement-data-table >}}`, alone in a paragraph, renders a table with one row per entry under `supplement.data`, in order. Each row holds the file name, the description, the size, and an `<a>` with a `download` attribute whose `href` is the file path relative to the page: `data/example.csv` on `index.html`, `../data/example.csv` on a page in `analyses/`. Sizes use base 1000 and the units B, KB, MB, and GB: whole bytes below 1000, else one decimal rounded half up, with the unit chosen after rounding. Fixture files of 0, 999, 1000, 1500, 999950, 7690465, and 1000000000 bytes read `0 B`, `999 B`, `1.0 KB`, `1.5 KB`, `1.0 MB`, `7.7 MB`, and `1.0 GB`. After the render, `docs/data/example.csv` exists.
- [x] AC5: An entry under `supplement.data` whose file does not exist makes `quarto render` exit non-zero, and the render's stderr contains that entry's `file` value.
- [x] AC6: The template's `index.qmd` uses `supplement-doi`, `supplement-download`, `supplement-data-table`, `{{< meta supplement.paper-title >}}`, and `{{< meta supplement.citation >}}`. The template's `_supplement.yml` ships empty DOI and archive values. After a fresh M003-style render, `docs/index.html` holds no DOI badge `<img>` and has a data-table row for `data/example.csv`.
- [x] AC7: On a clean checkout, `Rscript -e 'devtools::check()'` reports 0 errors and 0 warnings, and no NOTE contains "hidden files". On this Mac with quarto on PATH, `Rscript -e 'devtools::test()'` reports 0 failures and 0 skips.

## Coverage

- AC1 → T1
- AC2 → T1, T4
- AC3 → T2, T4
- AC4 → T3, T4
- AC5 → T3, T4
- AC6 → T1, T4
- AC7 → T4, T5, T6

## Tasks

- [x] T1: Write `inst/template/_supplement.yml` with the AC1 keys and empty DOI and archive values. Add `metadata-files` to `_quarto.yml`. Rewrite `index.qmd` to read the paper title and citation with `{{< meta >}}` and to use the three shortcodes.
- [x] T2: Extension skeleton `_extensions/supplement/_extension.yml` and Lua shortcodes `supplement-doi` (version DOI, then concept DOI, then nothing) and `supplement-download`.
- [x] T3: `supplement-data-table`: read each file's size from the project root (`quarto.project.directory`), format it by the AC4 rule, write links relative to the page, and call `error()` with the file name when a file is missing.
- [x] T4: Tests: a fixture project in a temp folder covering AC2 to AC6, with the size fixtures outside the `resources` glob, and a sparse file for the 1000000000-byte case.
- [x] T5: Planted-defect check in a scratch copy, one at a time: the size rule switched to base 1024; the unit chosen before rounding; the `error()` on a missing file removed; links always written from the project root; the DOI fallback order swapped. Each makes at least one test fail. Record the results in the work log.
- [x] T6: `_README.md` section on `_supplement.yml` and the shortcodes, a NEWS.md entry, then `devtools::check()`.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — new user-facing extension and shortcodes.
- 2026-10-18: question set: licenses — MIT for code, CC BY 4.0 for content, carried into `supplement.license`.
- 2026-10-18: split from M003 because the template extraction row exceeds one milestone's criteria; M003 ships a working template with placeholder text, and this milestone replaces the placeholders.
- 2026-10-18: plan gate chose the DOI badge fallback (version DOI, then concept DOI, then nothing) over a version-DOI-only badge because Zenodo mints the version DOI after the release, so a new site has none; falsified by authors who need a badge before the first release.
- 2026-10-18: plan gate chose a hard error on a missing data file over a marked row because a build without its data must never be published (pilot-port P8); falsified by a site whose data files are fetched after the render.
- 2026-10-18: criteria audit (full mode, Opus): flagged missing authors and license keys against the DESIGN single-source convention (AC1), escaping and placeholder text (AC2), an empty DOI before the first release (AC3, AC6), an underspecified size rule and page-relative links (AC4), a conflict with M003's data-deletion check (AC5), and no probes (AC7). All fixed in the wording above; M003 AC4 now hides R instead of deleting data; probes in T5.
- 2026-10-18: implement started on branch m004-home-page-shortcodes, cut from main at 7fb2527.
- 2026-10-18: T1 done: `_supplement.yml` (licenses as SPDX ids `MIT` and `CC-BY-4.0`, two placeholder authors), `metadata-files` in `_quarto.yml`, `index.qmd` reads the title (as `subtitle`), citation, and contact with `{{< meta >}}`; a scratch render showed the meta values and the not-yet-defined shortcodes as raw text; tests 48 pass.
- 2026-10-18: T2 done: all shortcodes live in one file, `_extensions/supplement/supplement.lua`; the badge is an image with alt text "DOI" inside a link, the download link text is "Download the archive from Zenodo"; a scratch render showed nothing for empty values, the concept DOI alone, then the version DOI over it; tests 48 pass.
- 2026-10-18: T3 done: table columns File (a download link showing the base name), Description, Size; links use `quarto.project.offset`. Found that Quarto rewrites an existing metadata path to be page-relative and leaves a missing one as written (`toInputRelativePaths` in quarto.js), so the shortcode strips the offset back off before it reads the size. Also found that Quarto copies every linked local file into `docs/`, so the size fixtures are copied whatever glob they sit outside. A scratch render showed the seven AC4 sizes, `../data/example.csv` from `analyses/`, and exit 1 with the missing name on stderr only; tests 48 pass.
- 2026-10-18: T4 done: `test-shortcodes.R` with 8 tests and helpers in `helper-template.R`; the AC3 to AC5 tests use a small fixture site with the extension and no R code, the AC2 test edits a fresh `quarto use template` folder, and the AC6 test reads the shared rendered site. The 1000000000-byte fixture is a sparse file made by `seek()`; Quarto copies it into `docs/` because the table links it, which was cheap on this Mac (APFS) and may not be on Linux. Full suite 167 pass, 0 skip.
- 2026-10-18: T5 done: each defect planted alone in a `git archive` copy of fb2edac, shortcode tests run there. Base 1024: 5 failures at the size cell (test-shortcodes.R:105). Unit before rounding: 2 failures at the size cell (the 999950 case on both pages). `error()` removed: render still exits non-zero, 1 failure at the stderr message match (line 123). Root links: 5 failures at the link match (line 102). DOI order swapped: 2 failures (lines 24, 25).
- 2026-10-18: T6 done: `_README.md` gains a "Paper facts in `_supplement.yml`" section and two Contents lines, the package README one paragraph, NEWS.md one entry; DESIGN.md Architecture updated for the new files. `devtools::document()` added `Config/roxygen2/version: 8.1.0` to DESCRIPTION; kept, so the review's no-diff `document()` check holds. `devtools::check()`: 0 errors, 0 warnings, 0 notes, tests run inside it; `devtools::test()`: 167 pass, 0 skip.
- 2026-10-18: claim audit: 62 claims read, 5 corrected — inst/template/_README.md, inst/template/_supplement.yml, tests/testthat/helper-template.R, README.md. The reader also found that Quarto rewrites a description naming an existing folder ("data" became "../data" on an `analyses/` page); fixed test-first in supplement.lua (`as_written`) with a new test, and the same reader confirmed all corrections on one re-read. Left as is: a `{{< meta >}}` value on a subfolder page whose text names an existing path is still rewritten by Quarto; the template shows those values only on the home page. Tests 170 pass, 0 skip.
- 2026-10-18: all tasks done; status set to review.
- 2026-10-18: step-7 approval: m004-home-page-shortcodes approved for merge

## Decisions

## Review

Evidence from a clean clone of the branch at 79a2e41 (scratchpad), 2026-10-18: `devtools::test()` per-test table, 19 tests, 0 failed, 0 skipped, 0 errors; `devtools::check()` 0 errors, 0 warnings, 0 notes.

- AC1: `_quarto.yml` lines 20-21 list `_supplement.yml` under `metadata-files`. grep of `inst/template/_supplement.yml` shows `supplement:` with `paper-title`, `citation`, `preprint`, `contact`, `license` (`code`, `content`), `authors` (two entries with `name`, `orcid`, `affiliation`), `zenodo` (`version-doi`, `concept-doi`, `archive-url`), `data` (one entry with `file`, `description`). Test "values set in _supplement.yml reach the home page" passes, so Quarto loads the file.
- AC2: test "values set in _supplement.yml reach the home page" (6 expectations, pass) runs `quarto use template` in a temp folder, sets `paper-title` "Zebra Paper 2071", `citation` "Quill Q 1999 Something Cited", `version-doi` "10.5281/zenodo.98765", runs `quarto render` (exit 0), and finds each value in `docs/index.html`. Test "the template home page reads its values from _supplement.yml" (13, pass) reads the original `paper-title` and `citation` from the template's `_supplement.yml` and finds neither in `index.qmd`; the original `version-doi` is "" (asserted in the same test).
- AC3: on a fixture site (extension only, no R), tests pass: "the DOI badge shows the version DOI, then the concept DOI" (5) matches `<a href="https://doi.org/<doi>">` wrapping `<img src="https://zenodo.org/badge/DOI/<doi>.svg">` for the version DOI with both set (concept DOI absent from the page) and for the concept DOI alone; "empty DOI and archive values render nothing" (3) gets exit 0, `BEFORE MID AFTER` with nothing between, and no badge URL; "the download link points at the archive" (3) matches `<a href="https://zenodo.org/records/12345">`. T5 log: swapping the fallback order fails 2 of these expectations.
- AC4: test "the data table lists each file with its size and a page-relative link" (84, pass): 8 entries (`data/example.csv` and the seven size fixtures, the 1000000000-byte one sparse) render 8 rows in order on `index.html` and `analyses/page.html`; each row has the base name in `<code>`, the description, the size, and an `<a download>` whose `href` is `data/...` on the home page and `../data/...` in `analyses/`. Sizes read `86 B` (file size of example.csv), `0 B`, `999 B`, `1.0 KB`, `1.5 KB`, `1.0 MB`, `7.7 MB`, `1.0 GB`, stated in the test apart from the code. `docs/data/example.csv` exists after the fixture render and after the template render (test "a new site shows no DOI badge ..."). T5 log: base 1024, unit-before-rounding, and root-relative links each fail this test.
- AC5: test "a missing data file stops the render and names the file" (2, pass): a full `quarto render` of a fixture listing `data/not_here_42.csv` exits non-zero, and stderr, captured apart from stdout, contains `supplement-data-table: data file not found: 'data/not_here_42.csv'`. T5 log: with `error()` removed the render still fails, but this message match fails, so the test asserts which failure.
- AC6: test "the template home page reads its values from _supplement.yml" (13, pass) finds the three shortcodes and the two `{{< meta >}}` calls in `index.qmd` and asserts `version-doi`, `concept-doi`, and `archive-url` are "" in `_supplement.yml`. Test "a new site shows no DOI badge and lists the example data" (3, pass), on the shared `quarto use template` + `quarto render` site, finds no `zenodo.org/badge` in `docs/index.html` and a table row whose link is `<a download href="data/example.csv">`.
- AC7: on the clean clone, `Rscript -e 'devtools::check()'` gives 0 errors, 0 warnings, 0 notes, and "checking for hidden files and directories ... OK"; `devtools::test()` gives 0 failures and 0 skips over 19 tests, quarto 1.10.19 on PATH.
- Consistency gate: `cairn_validate.py` all checks passed (exit 0); no DESIGN principle changed, so no impact report; `devtools::document()` left no diff; no README.Rmd or `_pkgdown.yml`; NEWS.md has the entry; no new top-level files.
- spawned: diff-bug, blame-history, prior-review
- No finding shows a criterion failing; the defects below hit uncommon author input (folded YAML, odd file names, read-only folders, Windows), so none is judged load-bearing for a return, and the in-scope ones are fixed on the branch.
- diff-bug #1: a folded or block YAML `description` (or a boolean) crashes the render in `pandoc.Plain` — fix now, fixed 6a5eadd
- diff-bug #2: Quarto parses `file` values as Markdown, so names with `--`, `'`, `...`, `*x*`, `_x_`, `^x^` are changed before the existence check and the error names a different file — fix now, fixed 6a5eadd (naming rule in the guide and a hint in the error); reading raw values → follow-up row "shortcode edge cases"
- diff-bug #3: `os.rename(p, p)` existence check fails in a read-only folder (error 13), so subfolder pages report existing files missing — fix now, fixed 6a5eadd
- diff-bug #4: a folder listed as a data file renders a row (`128 B`) on macOS and Linux instead of stopping — fix now, fixed 6a5eadd
- diff-bug #5: file names with `%` or `#` publish broken links, and the guide's "Quarto copies each file" is false for `%` — fix now, fixed 6a5eadd (covered by the naming rule); href encoding → follow-up row "shortcode edge cases"
- diff-bug #6: the 1 GB size fixture is copied into `docs/` and may cost 1 GB off macOS — follow-up, absorbed into the "Windows check" row
- diff-bug #7: files of 2 GiB or more may read as missing on Windows (32-bit `ftell`) — follow-up, absorbed into the "Windows check" row
- diff-bug #8: licenses are set in the `_quarto.yml` footer and in `_supplement.yml` — follow-up row "license footer"
- diff-bug #9: a `{{< meta >}}` value naming an existing path is rewritten on subfolder pages, not recorded as a known issue — follow-up row "shortcode edge cases"
- diff-bug #10: a fresh site has an empty paragraph under "Archived Version" — follow-up row "shortcode edge cases"
- diff-bug #11: a `data` map instead of a list renders nothing, and bare strings give `not found: ''` — follow-up row "shortcode edge cases"
- diff-bug #12: a path outside the project or an absolute path renders but is not published — follow-up row "shortcode edge cases"
- diff-bug #13: a description written literally as `../data` shows as `data` on subfolder pages — follow-up row "shortcode edge cases"
- diff-bug #14: sizes of 1 TB or more read in GB — reject, planned change (AC4 fixes the units B to GB)
- diff-bug #15: `quarto-required: ">=1.4.0"` is untested below 1.10 — follow-up row "shortcode edge cases"
- diff-bug #16: the DOI format is not stated, and a pasted `https://doi.org/` URL breaks the badge — fix now, fixed 6a5eadd
- diff-bug #17: `Config/roxygen2/version` rides along in DESCRIPTION — reject, false as a defect: the line keeps `devtools::document()` from making a diff, which the consistency gate requires
- diff-bug #18: shortcode fixture tests skip without knitr and rmarkdown, which they do not use — fix now, fixed 6a5eadd
- blame-history #1: a missing data file stops the render, so a data-free rebuild (M002) no longer completes — reject, planned change: the plan gate chose the hard error over a marked row (work log), P8 says a data-free build must never be published, and M003 AC4 was changed to hide R instead of deleting data; the choice now gets a D-entry (blame-history #4)
- blame-history #2: licenses duplicated against the single-source convention — follow-up row "license footer" (same as diff-bug #8)
- blame-history #3: `os.rename` existence check likely false on Windows — fix now, fixed 6a5eadd (same fix as diff-bug #3)
- blame-history #4: no D-entry for the hard error, and DESIGN's convention allows only TypeScript scripts in the template — fix now, fixed 6a5eadd (D-008, DESIGN Conventions line)
- blame-history #5: the `_supplement.yml` pointer sits after "Then delete this box" — fix now, fixed 6a5eadd
- blame-history #6: a rewritten description loses Markdown — reject, false: Quarto rewrites only a value that names an existing path in full, and the shortcode now keeps the parsed inlines of every value it does not rewrite
- prior-review #1: hard error contradicts M002's data-free rebuild and P8's routing to release checks — reject, planned change (same as blame-history #1)
- prior-review #2: `os.rename` on Windows — fix now, fixed 6a5eadd (same as diff-bug #3)
- prior-review #3: meta rewrite on subfolder pages left unrecorded — follow-up row "shortcode edge cases" (same as diff-bug #9)
- Found while fixing diff-bug #4: Quarto 1.10 redefines the global `error` in its filters to print a message and return (`share/filters/main.lua` line 2614). Before 6a5eadd the shortcode went on after "not found", and the render failed only because `format_size(nil)` then crashed; AC5's observable result held, but by that crash. 6a5eadd stops with `assert(false, message)`. A scratch copy with `error(message)` planted back fails two tests: the folder test (exit 0) and the missing-file test's new check that stderr holds no "attempt to" Lua error.
- AC5 re-verified at 6a5eadd: the missing-file test passes (exit non-zero, stderr holds the message, no "attempt to"); full suite 180 pass, 0 skip; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- Follow-ups written to ROADMAP: new rows "license footer" and "shortcode edge cases"; diff-bug #6 and #7 absorbed into the "Windows check" row. D-008 records the hard-error choice.
