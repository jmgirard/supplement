# M027: check_supplement() finds stored output older than its report

- **Status:** review
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

- [x] AC1: The stale rule: take a `.qmd` report directly in `analyses/`, from the same list of reports that the `no-stored-output` check reads. Read as JSON each file whose name ends in `.json` and does not start with `.`, directly in `_freeze/analyses/<name>/execute-results/`. If the top-level `hash` of a file is one text value that differs from the MD5 of the report's bytes with each CR LF pair read as LF, `check_supplement()` gives one `stale-output` row for the report. A report that cannot be read, such as a link to a missing file, gives no `stale-output` row. The test file `tests/testthat/test-check-supplement.R` has: a report whose stored hash differs (a row), a report whose stored hash matches (no row), a report with two `.json` files of which one differs (one row), a report with no stored output (no `stale-output` row), and a link to a missing report with a `.json` file (no row). It has four reports whose stored hash is the MD5 that the rule gives, and none gets a row: one with CR LF line ends, one that starts with a UTF-8 byte order mark, one with a lone CR, and one with no final LF.
- [x] AC2: If such a JSON file does not parse, its top level is not an object, or its top-level `hash` is missing or is not one text value, the report gets one `stale-output` row whose problem text says that the source hash of its stored output cannot be read. When one file of a report cannot be read and another differs, the one row has this text. The test file has one report for each: a file that does not parse, a top level of `"abc"`, a top level of `[1]`, a file with no `hash`, a `hash` that is a number, a `hash` that is a list, and a report with one unreadable file and one that differs.
- [ ] AC3: A test that runs Quarto, and skips when Quarto is not on PATH, makes a site from the template and runs a full render. Then `check_supplement()` gives no `stale-output` row. After a change to the bytes of `analyses/example.qmd`, it gives a `stale-output` row for that report. After `quarto render analyses/example.qmd`, it gives none. After the report is written with CR LF line ends and rendered by name again, it gives none. A new report that includes another file with `{{< include >}}`, rendered by name, gives none. The evidence comes from a local run and from the CI jobs where Quarto is installed.
- [x] AC4: `release_supplement()` stops with `supplement_error_release_check` and changes no file in a site whose only problem is a `stale-output` row. A test in `tests/testthat/test-release-supplement.R` runs the real `check_supplement()`, not a mock, on such a site and fails on main.
- [x] AC5: The help page of `check_supplement()` has a `"stale-output"` item that states the rules of AC1 and AC2 and the limit in Out. The problem text of both kinds of row tells the author to render the report by name and commit `_freeze/`. `NEWS.md` and the check list in `inst/template/_README.md` (line 140) name the check.
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
- 2026-10-20: claim audit: 33 claims read, 1 corrected — tests/testthat/test-check-supplement.R (fixture comment said every expected hash came from the LF text; the re-read of the new wording holds).
- 2026-10-20: status → review.
- 2026-10-20: step-7 approval: m027-stale-output approved for merge

## Decisions

## Review

- Sync: `origin/main` at c372f6f, the branch's base; no merge needed. No PR yet; Copilot round off (no header line in PROFILE.md).
- AC1: `devtools::test()` (2026-10-20, Quarto 1.10.19): "stored output made from other report text gives a stale-output row" passes, 7 expectations: rows only for `differs` and `two-files`; none for matches, no-stored, dangling link, CR LF, BOM, lone CR, no final LF, hidden `.json`, `.txt`, or `sub/inner.qmd`. The same test against main's R code (git archive of main plus the branch tests): 2 failures, no rows.
- AC2: "a source hash that cannot be read gives a stale-output row that says so" passes, 17 expectations: one row each for not-json, `"abc"`, `[1]`, no hash, number hash, list hash (holding the right MD5), and `both`, each with "The source hash of its stored output cannot be read". Against main's code: 2 failures, no rows.
- AC3 (local part): "a render by name clears the stale-output row that a changed report gives" in `test-add-render.R` ran (not skipped) and passes, 11 expectations: none after a full render, one row for `analyses/example.qmd` after a byte change, none after a render by name, none after a CR LF rewrite and render, none for a new report with `{{< include >}}` rendered by name. The CI part waits for the PR's checks at step 8; the box is ticked then.
- AC4: "a stale-output row from the real check stops the release" passes, 6 expectations, with the real `check_supplement()` giving only `stale-output analyses/example.qmd` and no skipped checks; the folder state is unchanged; with the report's own hash the same site releases to 1.0.0. Against main's code: 2 failures and 1 error (the release went ahead, so no `supplement_error_release_check`).
- AC5: `man/check_supplement.Rd` has the `"stale-output"` item with the AC1 rule (CR LF read as LF, `.json` not starting with `.`), the AC2 rule and its precedence, the unreadable-report case, and the Out limit (included files, `_quarto.yml`, `_metadata.yml`, data; nested reports). Both row texts end "Render the report by name, then commit _freeze/." (`R/check-supplement.R:453`). NEWS.md lines 33-37 and `inst/template/_README.md:147-148` name the check.
- AC6 (local part): `devtools::test()` 283 results, 0 failed, 0 errors, 7 skipped; `devtools::check()` 0 errors, 0 warnings, 0 notes. The R-CMD-check workflow runs at the PR (step 8); the box is ticked when it is green.
- Gate: `cairn_validate.py` exit 0, all checks passed; no DESIGN principle changed, so no impact report. `devtools::document()` gives no diff; no README.Rmd and no `_pkgdown.yml`, so no knit or pkgdown check; NEWS.md has the entry, with no milestone numbers; no new top-level files; `devtools::check()` 0/0/0.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: a report with bytes that are not valid UTF-8 gets a row after each render, because Quarto hashes each bad byte as U+FFFD (confirmed by a probe: stored hash 4221d00b… equals the U+FFFD form, raw MD5 752d7a73…) — follow-up "Hash stored output as Quarto does"; the limit is stated in the help page (fix now), fixed b014410.
- diff-bug #2: Quarto keeps `docx.json` with its old hash after docx is dropped, so no render clears the row (confirmed by a probe) — follow-up "Name leftover format files in _freeze"; the help page says to delete the file (fix now), fixed b014410.
- diff-bug #3: `json[["hash"]]` takes the first duplicate `hash` key, `JSON.parse` the last — follow-up "Hash stored output as Quarto does".
- diff-bug #4: invalid UTF-8 in a JSON file gives the "cannot be read" text where Quarto reads it — follow-up "Hash stored output as Quarto does".
- diff-bug #5: a warning from the temp-file write gives no row — follow-up "Hash stored output as Quarto does".
- diff-bug #6: each JSON file is parsed whole; 2 GiB or more fails `rawToChar()` — follow-up "Hash stored output as Quarto does".
- diff-bug #7: the `!dir.exists(files)` exclusion has no test — fix now: a folder `old.json` fixture; with the exclusion removed the AC1 test fails 3 expectations, fixed b014410.
- diff-bug #8: the include case never edits the included file — fix now: the AC3 test edits `_part.qmd` after the render and expects no row, fixed b014410.
- diff-bug #9: the header comment of `test-release-supplement.R` says every test mocks the check — fix now, fixed b014410.
- diff-bug #10: NEWS.md line 37 is 90 characters — reject: style.
- blame-history #1: `tools::md5sum()` with no `tools` in Imports would warn in R CMD check — reject: false; `devtools::check()` gives 0 warnings and `tools:::.check_packages_used()` reports nothing.
- blame-history #2: the check depends on one Quarto version's hashing — reject: planned change (the plan gate chose the stored hash and recorded its falsifier); the help page now names 1.10.19, the version probed (fix now), fixed b014410.
- blame-history #3: the candidate row says "older than its report", the check compares hashes — reject: planned change (plan gate).
- blame-history #4: the "one problem of any other check stops the release" list lacks `stale-output` — fix now, fixed b014410.
- blame-history #5: NEWS.md line 37 is 90 characters — reject: style.
- blame-history #6: "changes no file" while `report_hash()` writes a temp file — reject: false; no site file changes, and `git_run()` already uses a temp file the same way.
- prior-review #1: on Windows a link to a missing report may read as an empty file and give a false row — reject: false; `file.size()` on such a link warns (LESSONS M018), and `report_hash()` treats a warning as unreadable; the Windows CI job runs the fixture.
- prior-review #2: a stored JSON of 2 GiB or more fails `rawToChar()` — follow-up "Hash stored output as Quarto does".
- prior-review #3: very large reports are read whole and scanned with logical vectors — follow-up "Hash stored output as Quarto does".
- prior-review #4: NEWS.md line 37 is 90 characters — reject: style.
- ripple #1: README.md's check list omits the new check — fix now, fixed b014410.
- ripple #2: the ROADMAP title says "older than its report" — reject: planned change (plan-owned title).
- ripple #3: the candidate row names the age method — reject: planned change; the row graduates at hygiene.
- ripple #4: the template README omits the unreadable case — fix now, in both READMEs, fixed b014410.
- ripple #5: `tools` is not in Imports — reject: false, as blame-history #1.
- Note: the T5 run with 1 failure has the shape of the parked "template test flake" row, but its output was not kept, so it is not counted there.
- After the fixes: `devtools::test()` 283 results, 0 failed, 0 errors; `devtools::check()` 0 errors, 0 warnings, 0 notes; `cairn_validate.py` all checks passed.
