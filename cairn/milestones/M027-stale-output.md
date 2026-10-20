# M027: check_supplement() finds stored output older than its report

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — an exported check whose rows stop `release_supplement()`
- **Branch/PR:** m027-stale-output

## Goal

`check_supplement()` gives a `stale-output` row for a report whose stored output in `_freeze/` was made from other text than the report holds now.

## Scope

**In:** a new `check_stale_output()` in `R/check-supplement.R`, called from `check_supplement()` beside `check_stored_output()`. It compares the source hash that Quarto writes in each `execute-results/*.json` file with the MD5 of the report. The milestone also adds tests, help text, template README text, and a NEWS.md change.

**Out:** a change in a file the report includes, in `_quarto.yml` or `_metadata.yml`, or in the data does not count, because Quarto hashes only the report file; the help page states this limit. Reports in folders inside `analyses/` are not read, as for `no-stored-output`, and the help page says so.

## Acceptance criteria

- [ ] AC1: The stale rule: take a `.qmd` report directly in `analyses/`, from the same list of reports that the `no-stored-output` check reads. Read as JSON each file whose name ends in `.json` and does not start with `.`, directly in `_freeze/analyses/<name>/execute-results/`. If the top-level `hash` of a file is one text value that differs from the MD5 of the report's bytes with each CR LF pair read as LF, `check_supplement()` gives one `stale-output` row for the report. A report that cannot be read, such as a link to a missing file, gives no `stale-output` row. The test file `tests/testthat/test-check-supplement.R` has: a report whose stored hash differs (a row), a report whose stored hash matches (no row), a report with two `.json` files of which one differs (one row), a report with no stored output (no `stale-output` row), and a link to a missing report with a `.json` file (no row). It has four reports whose stored hash is the MD5 that the rule gives, and none gets a row: one with CR LF line ends, one that starts with a UTF-8 byte order mark, one with a lone CR, and one with no final LF.
- [ ] AC2: If such a JSON file does not parse, its top level is not an object, or its top-level `hash` is missing or is not one text value, the report gets one `stale-output` row whose problem text says that the source hash of its stored output cannot be read. When one file of a report cannot be read and another differs, the one row has this text. The test file has one report for each: a file that does not parse, a top level of `"abc"`, a top level of `[1]`, a file with no `hash`, a `hash` that is a number, a `hash` that is a list, and a report with one unreadable file and one that differs.
- [ ] AC3: A test that runs Quarto, and skips when Quarto is not on PATH, makes a site from the template and runs a full render. Then `check_supplement()` gives no `stale-output` row. After a change to the bytes of `analyses/example.qmd`, it gives a `stale-output` row for that report. After `quarto render analyses/example.qmd`, it gives none. After the report is written with CR LF line ends and rendered by name again, it gives none. A new report that includes another file with `{{< include >}}`, rendered by name, gives none. The evidence comes from a local run and from the CI jobs where Quarto is installed.
- [ ] AC4: `release_supplement()` stops with `supplement_error_release_check` and changes no file in a site whose only problem is a `stale-output` row. A test in `tests/testthat/test-release-supplement.R` runs the real `check_supplement()`, not a mock, on such a site and fails on main.
- [ ] AC5: The help page of `check_supplement()` has a `"stale-output"` item that states the rules of AC1 and AC2 and the limit in Out. The problem text of both kinds of row tells the author to render the report by name and commit `_freeze/`. `NEWS.md` and the check list in `inst/template/_README.md` (line 140) name the check.
- [ ] AC6: `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3
- AC3 → T1, T2, T3
- AC4 → T2, T3
- AC5 → T1, T4
- AC6 → T2, T3, T4, T5

## Tasks

- [x] T1: Probe Quarto 1.10.19 in a scratch site: change only an included file, then only `_quarto.yml`, and record in the work log whether the stored `hash` changes on a render by name. The Out limit and the help text follow what the probe shows (the derived-claims rule). If the hash covers the included text, AC1 and AC3 go to the amendment protocol.
- [x] T2: Add the AC1, AC2, and AC4 tests, with JSON fixtures that the tests write with `writeBin()` (LESSONS M011). Add the AC3 test beside the full-render tests in `tests/testthat/test-add-render.R`, with `skip_if_no_quarto()` (`helper-template.R:3`). Run the row cases against the code on main and record that each fails there (LESSONS M010). Recheck the tests that match whole row sets (`test-check-supplement.R:88`) and the empty `html.json` at line 221, which now gives a `stale-output` row.
- [x] T3: Write `check_stale_output()`. Read the report with `readBin()`, drop each CR before an LF, and hash the bytes with `tools::md5sum()` on a temporary file or with an MD5 of the raw bytes. Read each JSON file with `jsonlite::fromJSON(simplifyVector = FALSE)` inside `tryCatch()`. List the folder, not a glob over the path (LESSONS M008). Add the call to `check_supplement()` (line 149).
- [x] T4: Add the roxygen item and run `devtools::document()`. Edit the existing `NEWS.md` bullet for `check_supplement()`. Add a line to the check list in `inst/template/_README.md`.
- [x] T5: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: what to work on — the candidate rows "Read YAML without running R code", "Find inline code in more shapes", and "Find stale stored output for reports", planned as M025, M026, and M027.
- 2026-10-20: question set: a `stale-output` row stops `release_supplement()` — yes. Every row other than the `CITATION.cff` DOI row already stops it (`check_release_problems()`, `R/release-supplement.R:388`), so no change there is needed.
- 2026-10-20: absorbed the candidate row "Find stale stored output for reports" in full.
- 2026-10-20: probes on Quarto 1.10.19: `execute-results/html.json` holds the keys `hash` and `result`. Its `hash` equals the MD5 of the report's bytes for an LF file, for a file with a UTF-8 byte order mark (the mark kept), and for a file with a lone CR (kept). For a CR LF file it equals the MD5 of the text with CR LF read as LF.
- 2026-10-20: collision check: M008 shipped `no-stored-output`, and M024 widened it; this is a new check. No D-entry overlaps. jsonlite is already imported.
- 2026-10-20: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-20: lessons surfaced: M001 (a render by name writes stored output; only a full render reuses it), M008 (list the folder, not a glob), M011 (write test bytes with `writeBin()`), M018 (CRLF checkouts on the Windows runner), M010 (prove a test fails against main).
- 2026-10-20: plan gate chose the hash Quarto writes over comparing file times, because git does not keep file times, so a fresh clone has no order to read; falsified by a Quarto version that writes no `hash` or hashes other text than the report file.
- 2026-10-20: changelog: the existing 0.0.0.9000 bullet for `check_supplement()` gets the change, with no new bullet.
- 2026-10-20: criteria audit (full mode, fresh Opus reader): 7 findings, all taken. AC1 adds BOM, lone CR, and no-final-LF fixtures and says an unreadable report gives no row. AC2 counts a non-object top level as unreadable and says the unreadable text wins over the stale text. AC3 adds an include case, and T1 sends AC1 and AC3 to the amendment protocol if the hash covers included text. AC4 needs the real `check_supplement()`, not a mock. AC5 covers both row texts. T2 rechecks whole-row-set tests. AC6 had no finding.
- 2026-10-20: T1 probe (Quarto 1.10.19, scratch website with `freeze: true`): after a change to only an included file, then only `_quarto.yml`, then a new `analyses/_metadata.yml`, each render by name left `hash` equal to the MD5 of the report (3557edfa…), while the stored `result` held the new included text. The hash covers the report file alone, so the Out limit stands and no amendment is needed.
- 2026-10-20: T2: added the AC1 and AC2 tests to `test-check-supplement.R` (expected hashes from `tools::md5sum()` on LF text written in the test), the AC3 test to `test-add-render.R`, and the AC4 test to `test-release-supplement.R` with a matching-hash control that releases. Moved `local_plain_git()` and `git_site()` to `helper-template.R` so the release test can use them. Against main code: 2 failures in each AC1/AC2 test (no rows) and the AC4 test fails because the release does not stop. Rechecked the whole-row-set test (line 88: passes, the rendered report's hash matches) and the empty `html.json` fixture (now also gives an unreadable `stale-output` row; that test reads only `no-stored-output` rows).
- 2026-10-20: T3: `check_stale_output()` with helpers `analysis_reports()` (shared with `check_stored_output()`), `report_hash()` (MD5 via a temp file, since DESCRIPTION sets no R floor for `md5sum(bytes =)`), and `stored_hash()`. Chose `jsonlite::parse_json()` on the read bytes over `fromJSON(path)`, which can read a short invalid text as a file name. Planted defects: no CR LF step fails the AC1 test; a reader that takes the first item of a list hash and accepts any top level fails 3 AC2 expectations. `devtools::test()`: 283 results, 0 failed, 7 skipped (Windows-only and invalid-name cases).
- 2026-10-20: T4: added the `"stale-output"` help item (rules of AC1 and AC2, the Quarto 1.10 limit from the T1 probe, nested reports not read) and ran `devtools::document()`; edited the existing `check_supplement()` NEWS bullet; added one line to the `inst/template/_README.md` check list.
- 2026-10-20: T5: the first `devtools::test()` and `devtools::check()` run (one command) each gave 1 failure and 1 error, with no output kept; the test that failed is not known. Six later `devtools::test()` runs gave 283 results, 0 failed, 0 errors, and a second `devtools::check()` gave 0 errors, 0 warnings, 0 notes. Open concern for review: a possible intermittent test.

## Decisions

## Review
