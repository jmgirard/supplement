# M062: Flag old and re-saved example files

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — it changes which rows `check_supplement()` gives, and so when `release_supplement()` stops
- **Branch/PR:** m062-flag-old-example-files

## Goal

`check_supplement()` gives the `"placeholder"` row for an example file that holds an earlier template version of the example report, or an unchanged copy that an editor saved with other line ends, a BOM, or no final line break, so `release_supplement()` stops before it archives the template's example.

## Scope

**In:** a reader in `R/check-supplement.R` that normalizes text before it is hashed (drops a leading UTF-8 BOM, reads CR LF and lone CR as LF, drops one final LF); a list of the normalized MD5s of each version of `analyses/example.qmd` on main and of `data/example.csv`, which `placeholder_example_rows()` compares with besides the installed template's copy; a size bound taken from the largest known version; fixture copies of the eight report versions in `tests/testthat/`; tests; the help page, `NEWS.md`, and `cairn/DESIGN.md`.

**Out:**
- `report_hash()` and the stale-output and stale-script checks stay as they are, because Quarto's stored hash keeps a BOM (LESSONS 2026-10-21, M027).
- Older template versions of the other placeholders (the `_supplement.yml` values and the lines of `placeholder_lines`) stay a known limit in `cairn/DESIGN.md` Known issues.
- Other editor changes, such as trimmed spaces at line ends or another encoding, give no row and stay in that Known issues entry.
- An example that a site edited stays the author's text and gives no row, as now.

## Acceptance criteria

- [x] AC1: `check_supplement()` gives the `"placeholder"` row for `analyses/example.qmd` when the site's file holds the text of any of the eight versions of `inst/template/analyses/example.qmd` that `git log --follow --format=%h 6873c34 -- inst/template/analyses/example.qmd` lists (`2db94f2`, the current copy, back to `5563744`). A test runs the check on a site holding each of the eight versions and gets the row for each.
- [x] AC2: The row for `analyses/example.qmd` or `data/example.csv` also comes when the file differs from one of its known versions (the eight of AC1 for the report, the template's copy for the data) only by one or more of: a UTF-8 BOM at its start, CR LF or lone CR line ends where the version has LF, or no line break at its end where the version has one. Tests plant a BOM, lone CR line ends, mixed CR LF and LF line ends, and a missing final line break on the template's copy of the report, the three differences together on `fbc2cab` (the largest version), and a BOM on the data file, and get the row each time.
- [x] AC3: A site file that differs from its known versions in other text gives no row: tests cover the report with one line break added at its end, `fbc2cab` with one character changed inside a line, the template's copy of the report with a BOM after its first line and with a space added at the end of one line, and the data file with one value changed.
- [x] AC4: The `"placeholder"` part of `?check_supplement` (roxygen in `R/check-supplement.R`, `man/check_supplement.Rd` regenerated) says the example files count when their text matches the template's copy, or for the report an earlier template version, apart from the differences AC2 names, and its sentence on sites made from an older template names the example report as the exception. `NEWS.md` has a bullet for the change. `cairn/DESIGN.md`'s placeholder-check paragraph and its "Placeholder check limits" Known issues entry describe the new behavior, and the entry no longer points to the row "Match example files after editor saves".
- [x] AC5: `devtools::document()` gives no diff, `devtools::test()` passes, and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T2, T3, T4
- AC2 → T1, T3, T4
- AC3 → T1, T4
- AC4 → T5
- AC5 → T6

## Tasks

- [x] T1: Add a reader beside `report_hash()` (`R/check-supplement.R:824`) that reads the bytes with `readBin()`, drops a leading `EF BB BF`, turns CR LF and then lone CR into LF, drops one final LF, and returns the MD5, or NULL on a read error or warning. Leave `report_hash()` unchanged.
- [x] T2: Copy each AC1 version with `git show <commit>:inst/template/analyses/example.qmd` into `tests/testthat/fixtures/example-qmd/<commit>.qmd`, byte for byte.
- [x] T3: In `placeholder_example_rows()` (`R/check-supplement.R:1345`), compare the site file's normalized MD5 with a list of known normalized MD5s per file (the eight report versions, the one data version) and with the installed template's copy. Set the size bound from the largest known version's byte size, not the current template's. A comment beside the list names the commits and the procedure that produced each MD5 (derived-figures rule).
- [x] T4: Tests in `tests/testthat/test-check-supplement.R`: each fixture gives the row (AC1); the AC2 plants; the AC3 no-row cases, keeping the existing added-line-break case at line 1866; a test that fails when the installed template's report or data is not in the known list, so a later change to the example must add its MD5.
- [x] T5: Update the roxygen `"placeholder"` bullet and the older-template sentence (`R/check-supplement.R:281-289`), run `devtools::document()`, add a `NEWS.md` bullet, and update `cairn/DESIGN.md` (the placeholder paragraph near line 158, the Known issues entry at line 348).
- [x] T6: Run `devtools::document()`, `devtools::test()`, and `devtools::check()`.

## Work log

- 2026-10-26: created by /milestone-plan.
- 2026-10-26: tier check: not run — work named at the question set.
- 2026-10-26: idea vet: no concern found. Comparing normalized text is how "unchanged" reads for an editor's save, all eight versions on main are reachable by GitHub installs of the unreleased package, and the row's problem text holds for every version.
- 2026-10-26: question set: run length — run to the merge question.
- 2026-10-26: collision check: absorbed the candidate rows "Flag the old example as a placeholder" and "Match example files after editor saves"; extends M036 (done), which shipped the example check; no D-entry overlaps (D-029 covers `_scripts/report.R` hashes); GitHub has no open issues or PRs.
- 2026-10-26: lessons used: 2026-10-21 (M027) Quarto's hash keeps a BOM, so the check gets its own reader; 2026-10-26 (M061) `paste0()` with an empty vector, plant the defect to see a case go red.
- 2026-10-26: plan gate chose every version of `example.qmd` on main over only the pre-M058 version the candidate row named, because sites from the six earlier versions miss the row the same way; falsified by a version on main that no site could have been made from.
- 2026-10-26: plan gate chose a list of MD5s in the code plus fixture copies in the tests over shipping old example files in the package, because the package then carries no dead template text; falsified by a known version whose MD5 the fixtures cannot reproduce.
- 2026-10-26: plan gate chose dropping one final line break over dropping all of them, because the existing test (line 1866) treats an added line break as an edit and a narrower rule keeps it; falsified by an editor that adds a second final line break on save.
- 2026-10-26: criteria audit (full mode, fresh Opus reader): 5 findings, all fixed. AC1 names `2db94f2` as the current copy; AC2 tests the three differences together on `fbc2cab`, the version nearest the size bound, and T3 bases the bound on the largest version; AC2 probes lone CR and mixed line ends; AC3 adds a BOM after the first line and a trailing space; AC4 removes the Known issues pointer. The auditor confirmed the eight commits, 8 distinct MD5s after normalization, and no conflict with the current 5,486-byte bound.
- 2026-10-26: T1 done: `text_hash()` added beside `report_hash()`, which is unchanged. Named for what it reads (any text file), since it serves the data file too.
- 2026-10-26: T2 done: eight fixtures in `tests/testthat/fixtures/example-qmd/<commit>.qmd` from `git show`; `.gitattributes` keeps them LF on every checkout. Their normalized MD5s are 8 distinct values; `2db94f2` equals the installed template's.
- 2026-10-26: T3 done: `example_versions` (MD5s by commit) and `example_version_bytes` (5090 and 86) in `R/check-supplement.R`; the size bound is twice the larger of the largest version and the installed copy.
- 2026-10-26: T4 done: four tests. Plants: with the old `report_hash()` comparison, 7 of 8 versions and 5 of 6 editor-save cases failed; with a normalizer that also drops every BOM byte and spaces before LF, both no-row probes failed. Full suite 422 tests, 0 failed, 10 skipped.
- 2026-10-26: T5 done: roxygen bullet and older-template sentence, `man/check_supplement.Rd` regenerated, a `NEWS.md` bullet at the top, `cairn/DESIGN.md` placeholder paragraph and Known issues entry (pointer removed, "narrowed M062").
- 2026-10-26: T6 done: `devtools::document()` no diff; `devtools::check()` 0 errors, 0 warnings, 1 note (hidden `.claude`, local only, as at M058).
- 2026-10-26: claim audit: 20 claims read, 0 corrected — NEWS.md, R/check-supplement.R, man/check_supplement.Rd, tests/testthat/test-check-supplement.R
- 2026-10-26: implement done; status review.
- 2026-10-26: step-7 approval: m062-flag-old-example-files approved for merge

## Decisions

## Review

- AC1 evidence (2026-10-26, HEAD 2fd60e2): the AC1 `git log` command lists 2db94f2 fbc2cab 38af327 11fa634 0c312a3 485be8b 9ba7e23 5563744; each fixture is byte-identical to its `git show` (`cmp`). The test "each version of the example report on the default branch gives its row" passes with 8 expectations; with the old `report_hash()` comparison planted, 7 of them failed (work log, T4).
- AC2 evidence: the test "an example file saved with a BOM, CR line ends, or no final line break gives its row" passes with 6 expectations: BOM, lone CR ends, one CR LF among LF ends, missing final LF on the template's report; BOM with CR LF ends and no final break on `fbc2cab`; BOM on the data file. With the old comparison planted, 5 of 6 failed (the one CR LF case passed, since `report_hash()` already read CR LF as LF).
- AC3 evidence: the test "an example file with other changed text gives no row" passes with 4 expectations (BOM after the first line, a space before the first LF, one changed character in `fbc2cab`, one changed digit in the data); the existing test keeps its added-line-break case and passes. With a normalizer planted that also drops every BOM byte and spaces before LF, the two report probes failed. `test-check-supplement.R` total: 91 tests, 0 failed.
- AC4 evidence: `man/check_supplement.Rd:302-314` (from the roxygen) says the report also counts when its text equals an earlier template version's, names the BOM, CR LF or CR line ends, and missing final line break as equal, and ends the older-template sentence with "The example report is the exception."; `NEWS.md:3-8` has the bullet; `cairn/DESIGN.md:158-162` names `text_hash()` and `example_versions`; `grep -c 'Match example files after editor saves' cairn/DESIGN.md` gives 0, and the Known issues entry names the example-report exception and the editor changes that still give no row.
- Consistency gate (HEAD 2fd60e2 plus the evidence edits): `cairn_validate.py` all checks passed; `devtools::document()` no diff; no README.Rmd; `pkgdown::check_pkgdown()` no problems; NEWS.md has the bullet; `devtools::test()` 422 tests, 0 failed, 10 skipped; `devtools::check()` 0 errors, 0 warnings, 1 note (hidden `.claude`, local only, not in the git tree).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: no test covers the move of the size bound from twice the template's size to twice the largest version's — reject (planned change): T3 called for the bound, and no known version with the allowed differences exceeds the old 5,486-byte bound, so no test can tell the two apart today.
- diff-bug #2: the eight fixtures have no committed generator or provenance header, which the profile's test-doctrine requires — fix now, fixed 6ba8aea.
- diff-bug #3: `example_version_bytes` has no guard, so a later version added without its size would leave the bound at the installed copy's size — reject (false): the newest version is the installed copy, whose size the bound already takes.
- diff-bug #4: the guard test reads `text_hash()` and `example_versions` directly — reject (planned change): T4 names this guard.
- diff-bug #5: the guard test loops over `names(example_versions)`, so an example file added to the problem list with no versions entry is not caught — fix now, fixed 6ba8aea.
- diff-bug #6: `example_version_bytes[[file]]` stops `check_supplement()` for a file with no size entry — fix now, fixed 6ba8aea.
- diff-bug #7: the NEWS bullet lists CR LF line ends as new, though `report_hash()` already read CR LF as LF — fix now, fixed 6ba8aea.
- diff-bug #8: the data-file BOM plant, the mixed-ends plant, and the combined `fbc2cab` plant repeat code paths other cases run — reject (planned change): AC2 names each.
- diff-bug #9: the eight-version loop runs one code path eight times — reject (planned change): AC1 names it, and each case checks its own MD5.
- diff-bug #10: the `fbc2cab` no-row case would pass with `fbc2cab` missing from the list — reject (false): the AC1 test covers that list entry.
- diff-bug #11: `text_hash()` repeats `report_hash()`'s CR LF and temp-file code — reject (style).
- diff-bug #12: a FIFO at `analyses/example.qmd` makes the check wait forever in `readBin()` — follow-up: the diff did not add it (`report_hash()` read the same path on main); new row "Skip FIFOs and other special files".
- diff-bug #13: the help says the data file is compared with the template's copy, while the code also reads `example_versions` — reject (false): that entry is the template copy's MD5, so the help is true.
- blame-history #1: the test name "an example file gives a row only while its text is the template's" no longer holds — fix now, fixed 6ba8aea.
- blame-history #2: the size-bound comment says "at most twice", but a file of only line breaks with a BOM reaches twice plus 3 — fix now, fixed 6ba8aea.
- blame-history #3: no D-entry records the move away from M036's "only while their text equals the template's" — reject (planned change): that was a milestone-local question-set answer, and the user chose this work at the M062 question set.
- prior-review #1: the diff reverses M036's recorded "only while their text equals the template's" on purpose — reject (planned change), as blame-history #3.
- ripple #1: the ROADMAP row "Match example files after editor saves" still reads as open — reject (planned change): post-merge hygiene graduates it.
- ripple #2: the ROADMAP row "Flag the old example as a placeholder" still reads as open — reject (planned change), as ripple #1.
- ripple #3: the stale test name at `test-check-supplement.R:1866` — fix now (the same finding as blame-history #1), fixed 6ba8aea.
- AC5 evidence (HEAD 6ba8aea, after the fixes): `devtools::document()` no diff; `devtools::test()` 422 tests, 0 failed, 10 skipped; `devtools::check()` 0 errors, 0 warnings, 1 note (hidden `.claude`, local only).
