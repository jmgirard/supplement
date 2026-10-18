# M004: Home page from _supplement.yml with shortcodes

- **Status:** in-progress
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

- [ ] AC1: The template's `_quarto.yml` lists `_supplement.yml` under `metadata-files`. `_supplement.yml` has a `supplement:` map holding `paper-title`, `citation`, `preprint`, `contact`, `license` (with `code` and `content`), `authors` (a list of entries with `name`, `orcid`, and `affiliation`), `zenodo` (with `version-doi`, `concept-doi`, and `archive-url`), and `data` (a list of entries with `file` and `description`).
- [ ] AC2: In a fresh template folder made as in M003 AC2, a test sets `supplement.paper-title`, `supplement.citation`, and `supplement.zenodo.version-doi` to new values made of ASCII letters, digits, and spaces (the DOI also `.` and `/`), then runs `quarto render`. `docs/index.html` then contains each new value. The template's `index.qmd` holds none of the template's original values for those keys as literal text.
- [ ] AC3: On a fixture page, `{{< supplement-doi >}}` renders an `<a>` with `href="https://doi.org/<doi>"` that wraps an `<img>` with `src="https://zenodo.org/badge/DOI/<doi>.svg"`. `<doi>` is `version-doi` when it is set, else `concept-doi`. When both are empty, the shortcode renders nothing and the render exits 0. `{{< supplement-download >}}` renders an `<a>` whose `href` equals `archive-url`, and renders nothing when that value is empty.
- [ ] AC4: `{{< supplement-data-table >}}`, alone in a paragraph, renders a table with one row per entry under `supplement.data`, in order. Each row holds the file name, the description, the size, and an `<a>` with a `download` attribute whose `href` is the file path relative to the page: `data/example.csv` on `index.html`, `../data/example.csv` on a page in `analyses/`. Sizes use base 1000 and the units B, KB, MB, and GB: whole bytes below 1000, else one decimal rounded half up, with the unit chosen after rounding. Fixture files of 0, 999, 1000, 1500, 999950, 7690465, and 1000000000 bytes read `0 B`, `999 B`, `1.0 KB`, `1.5 KB`, `1.0 MB`, `7.7 MB`, and `1.0 GB`. After the render, `docs/data/example.csv` exists.
- [ ] AC5: An entry under `supplement.data` whose file does not exist makes `quarto render` exit non-zero, and the render's stderr contains that entry's `file` value.
- [ ] AC6: The template's `index.qmd` uses `supplement-doi`, `supplement-download`, `supplement-data-table`, `{{< meta supplement.paper-title >}}`, and `{{< meta supplement.citation >}}`. The template's `_supplement.yml` ships empty DOI and archive values. After a fresh M003-style render, `docs/index.html` holds no DOI badge `<img>` and has a data-table row for `data/example.csv`.
- [ ] AC7: On a clean checkout, `Rscript -e 'devtools::check()'` reports 0 errors and 0 warnings, and no NOTE contains "hidden files". On this Mac with quarto on PATH, `Rscript -e 'devtools::test()'` reports 0 failures and 0 skips.

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
- [ ] T2: Extension skeleton `_extensions/supplement/_extension.yml` and Lua shortcodes `supplement-doi` (version DOI, then concept DOI, then nothing) and `supplement-download`.
- [ ] T3: `supplement-data-table`: read each file's size from the project root (`quarto.project.directory`), format it by the AC4 rule, write links relative to the page, and call `error()` with the file name when a file is missing.
- [ ] T4: Tests: a fixture project in a temp folder covering AC2 to AC6, with the size fixtures outside the `resources` glob, and a sparse file for the 1000000000-byte case.
- [ ] T5: Planted-defect check in a scratch copy, one at a time: the size rule switched to base 1024; the unit chosen before rounding; the `error()` on a missing file removed; links always written from the project root; the DOI fallback order swapped. Each makes at least one test fail. Record the results in the work log.
- [ ] T6: `_README.md` section on `_supplement.yml` and the shortcodes, a NEWS.md entry, then `devtools::check()`.

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

## Decisions

## Review
