<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M061: Flag reports after report.R changes

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate -->
- **Surface tier:** user-facing — a new `check_supplement()` row and a new line in the output of each report
- **Branch/PR:** m061-flag-report-script-changes   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create -->

`check_supplement()` gives a `"stale-script"` row for each report whose stored output came from other `_scripts/report.R` text than the site holds now, so `release_supplement()` stops before it archives that output.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** `print_environment()` in the template's `_scripts/report.R` prints a hash line for the file. `check_stale_script()` in `R/check-supplement.R` compares the hash lines in each report's stored output with the site's file now. Tests, the help pages, GUIDE.md, NEWS.md, and DESIGN.md follow.

**Out:**
- A row for a report whose stored output holds no hash line, such as a report without the Computing environment section or one rendered before the site copied the new file. The plan chose no row (help page states it). A row for such reports goes to a new candidate row only if a user asks for it.
- Hashes of files that `report.R` itself reads. No candidate row: the template's file reads none.
- A change to `analyses/example.qmd`. Its text stays the same, so the `placeholder` row for an unedited example keeps working (see the candidate row "Flag the old example as a placeholder").

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: `print_environment()` in the template's `_scripts/report.R` prints one more line, after the home-folder replacement, as its last line. The line is `Shared report code: _scripts/report.R, MD5 <hash>`. Here `<hash>` is the 32-character lowercase hex MD5 of the bytes of `file.path(site, "_scripts", "report.R")`, with each CR LF read as LF. A test sources the template's file into an environment that holds `site`, a temporary site. It runs once with that site's `report.R` saved with LF line ends and once with CR LF. Each time, the test compares the last printed line with the line built from `tools::md5sum()` of the LF copy.
- [x] AC2: `check_supplement()` gives one `"stale-script"` row on `analyses/<name>.qmd` for a `.qmd` report directly in `analyses/` under one condition. A `.json` file directly in `_freeze/analyses/<name>/execute-results/`, with a name that does not start with `.`, has a top-level `result.markdown` text value. That value holds the text `Shared report code: _scripts/report.R, MD5 ` and then 32 characters in `[0-9a-f]`. Those 32 characters differ from the MD5 of the site's `_scripts/report.R`, with each CR LF read as LF. Any such line in any such file that differs is enough. The problem text of the row gives the steps of `rerender_steps` in `R/check-supplement.R`. When another such file of the report holds only matching lines, the text also says that the differing files can be from a format that the report no longer renders, with the delete steps that the `"stale-output"` row gives. Tests with hand-written stored output assert the check and file of the row for three cases: a differing hash, two format files of one report where only one differs (one row, with the format text), and one file with a matching line and a differing line. Tests assert no `"stale-script"` row for two cases: an equal hash, and a CR LF `report.R` whose stored hash is the hash of its LF form.
- [x] AC3: `check_supplement()` gives no `"stale-script"` row for a report in each of these cases, and a test covers each case:
  - Its stored output holds no `Shared report code: _scripts/report.R, MD5 ` text.
  - The hash text after that text is uppercase or shorter than 32 characters.
  - The site has no `_scripts/report.R`.
  - The site's `_scripts/report.R` is a folder.
  - The only `.json` file of the report does not parse.
  - The only `.json` file of the report has no `result.markdown` text value.
  - The report has no `_freeze/analyses/<name>/execute-results/` folder.
- [x] AC4: A render test makes a site from the template, adds a report with `add_report()`, and renders the report by name. The test skips where Quarto is unavailable, as the other render tests do. After the render, `check_supplement()` gives no `"stale-script"` row. After the test appends a comment line to `_scripts/report.R`, it gives a `"stale-script"` row on that report. After the test renders the report by name again, it gives no such row.
- [x] AC5: Two tests put 5 MB of text with no line break in the stored `result.markdown`. In one, a line break and a differing hash line follow it. In the other, the differing hash text follows it on the same line. Each test gets the `"stale-script"` row with no warning.
- [x] AC6: Three texts no longer say that a change to `_scripts/report.R` gives no row: the `add_report()` help, the "Shared report code" section of GUIDE.md, and NEWS.md. Each says what AC2 and AC3 state. The `check_supplement()` help lists the `"stale-script"` row. It states that a report whose stored output holds no hash line gets no row. NEWS.md has a bullet for the row.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T2
- AC3 → T2
- AC4 → T3
- AC5 → T2
- AC6 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: In `inst/template/_scripts/report.R`, make `print_environment()` print the hash line after the home-folder loop. Use base R only: `readBin()`, drop each CR before LF, and `tools::md5sum()` on a temporary file. Add the AC1 test beside the home-folder tests.
- [x] T2: Add `check_stale_script()` to `R/check-supplement.R` after `check_stale_output()`, and call it from `check_supplement()`. It reads each execute-results `.json` file with jsonlite, finds the hash text with a fixed-string `gregexpr()`, not PCRE, and compares each hash with `report_hash()` of `_scripts/report.R`. Add the AC2, AC3, and AC5 tests to `tests/testthat/test-check-supplement.R`.
- [x] T3: Add the AC4 render test to `tests/testthat/test-add-render.R`.
- [x] T4: Update the `check_supplement()` and `add_report()` help, GUIDE.md "Shared report code", README.md, NEWS.md (the M058 bullet and a new bullet), and DESIGN.md. Run `devtools::document()`. Also search `grep -rn "report.R\|stale" R/ man/ inst/template/ README.md NEWS.md` and read the lines around each hit for other sentences that the row makes false.
- [x] T5: Run `devtools::test()` and `devtools::check()` until both are clean.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-26: created by /milestone-plan.
- 2026-10-26: tier check: not run — work named at the question set.
- 2026-10-26: idea vet: one concern, posed at the question set. The check sees only reports whose stored output holds the hash line, so reports without the Computing environment section and reports rendered before the site copied the new `report.R` get no row. Answer: build it with the hash printed in the report, and state the limit in the help page.
- 2026-10-26: question set: what to plan — "Flag reports after report.R changes"; hash record — print it in the Computing environment section of each report.
- 2026-10-26: lessons used: 2026-10-21 (M027, used M058) Quarto's hash covers the report alone and reads CR LF as LF, 2026-10-26 (M058) `source(local = TRUE)` and the global chunk environment, 2026-10-20 (M021, used M060) PCRE match limit, 2026-10-26 (M059, used M060) a `.*` pattern between two names.
- 2026-10-26: collision check: absorbs candidate "Flag reports after report.R changes"; extends M058 and M059 (done); narrows D-028's consequence that stored output does not track the file, recorded as D-029; distinct from "Flag the old example as a placeholder" (Scope Out); inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-26: plan gate chose a hash line printed in each report over a comparison of git commit times, because a report.R change that leaves the output the same keeps a git-based row after a render, and uncommitted edits are not seen; falsified by a stored output that lacks the printed line after a render with the new file.
- 2026-10-26: plan chose a new `"stale-script"` check id over more text in the `"stale-output"` row, because the two causes have separate remedies in the docs and one report can have both; falsified by a user report that two rows on one report confuse.
- 2026-10-26: plan chose one row per report over one row on `_scripts/report.R`, because each report must be rendered by name; falsified by sites with many reports where the per-report rows hide other rows.
- 2026-10-26: plan chose to leave `analyses/example.qmd` unchanged, so the `placeholder` row still finds an unedited example.
- 2026-10-26: `release_supplement()` stops on any row of `check_supplement()`, so the goal's stop needs no criterion of its own.
- 2026-10-26: changelog: one new NEWS.md bullet for the row, and the M058 bullet loses its "gives no stale-output row" clause.
- 2026-10-26: criteria audit (full mode, fresh Opus reader): 8 findings, 7 fixed. AC1 prints after the home-folder loop. AC2 names lowercase hex, skips hidden files, takes any differing line, and gives the dropped-format text that `"stale-output"` gives. AC3 now says "only `.json` file" so it does not contradict AC2, and adds the uppercase and short-hash cases. AC5 has two line shapes. AC6 binds three named texts, not a grep (the grep moved to T4). D-028's consequence gets D-029. The `release_supplement()` stop is inherited (line above). AC4: no finding.
- 2026-10-26: implement started on branch m061-flag-report-script-changes.
- 2026-10-26: T1 done: `print_environment()` computes the hash inline, with no new function name in report.R. `run_session_code()` in test-template.R now sets `site` to the template folder, since `print_environment()` reads `site`. The new test runs in process with `source(local = env)`; the four session tests still pass.
- 2026-10-26: T2 done: `check_stale_script()` and `stored_script_hashes()` in `R/check-supplement.R`; `stored_json()` now holds the JSON read that `stored_hash()` used, so both share it. Four tests cover AC2, AC3, and AC5; test-check-supplement.R passes. Planted defect: dropping the `[0-9a-f]{32}` filter turned the uppercase, short, and no-line cases red.
- 2026-10-26: correction to the T2 line: the no-line case turned red because `script_json()` built the hash text with no hash (`paste0()` keeps its prefix for an empty vector), so it did not test AC3's first case. The helper now writes no such line for no hashes, and the case passes; the planted defect showed the uppercase and short cases red.
- 2026-10-26: T3 done: the render test in test-add-render.R passes on macOS with Quarto; the row after the report.R change shows that the render stored the hash line.
- 2026-10-26: T4 done: `"stale-script"` item in the `check_supplement()` help; the `add_report()` help, GUIDE.md "Shared report code", and the M058 NEWS.md bullet drop "a change gives none"; GUIDE.md "Computing environment" names the hash line; README.md and GUIDE.md check lists and a new NEWS.md bullet; DESIGN.md architecture lines. The T4 search found no other outdated sentence; the vignette names no report.R. The simple-english lint flags the new check-list bullet as part of a long sentence because the list has no end periods; the list keeps its style.
- 2026-10-26: claim audit: 41 claims read, 4 corrected — R/check-supplement.R (the files the row names, the hint condition, an unreadable report.R gives no row), NEWS.md and inst/template/GUIDE.md (the MD5 reads CR LF as LF); the reader's re-read found all corrected sentences true. Left as is: a `"stale-script"` row can name a report that is a link to a missing file, where `"stale-output"` skips it; the help claims nothing about it.
- 2026-10-26: T5 done: `devtools::test()` 416 tests, 0 failed, 10 skipped (macOS, before the doc-only claim corrections); `devtools::check()` 0 errors, 0 warnings, 1 note (local `.claude`). Status set to review.
- 2026-10-26: step-7 approval: m061-flag-report-script-changes approved for merge

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive. -->

- 2026-10-26: review started on f4cef35; branch contains origin/main (4e71bd0), no sync needed. Copilot round off (no header line). Tests run with `testthat::test_file(desc =)` under `NOT_CRAN=true` on macOS, R with Quarto 1.10.19.
- AC1: `print_environment()` prints the hash line after the home-folder loop (inst/template/_scripts/report.R, last statement). Test "the environment section ends with the MD5 of report.R read with LF line ends" (test-template.R): 4 expectations, 0 failed. It sources into an env holding `site`, runs LF and CR LF copies, and compares the last line with `tools::md5sum()` of the LF copy.
- AC2: test "stored output made with other report.R text gives a stale-script row": 6 expectations, 0 failed. Rows only for "differs", "format-differs", "one-file-both"; the exact texts match `script_text()`, with the format text for "format-differs" only; "matches" gives none. Test "a report.R with CR LF line ends matches the hash of its LF text": 1 expectation, 0 failed; only "other-hash" gets the row, "lf-hash" none. Hidden `.html.json` gives no row.
- AC3: the same first test gives no row for "no-line" (markdown with no hash text, after the 898fc6c fixture fix), "upper", "short", "not-json" (only file `{`), "no-markdown" (only file with `result: {}`), and "no-stored" (no execute-results folder). Test "a missing report.R or a folder in its place gives no stale-script row": 3 expectations, 0 failed; the row is present first, then gone with the file deleted and with a folder in its place.
- AC4: test "a render by name clears the stale-script row that a changed report.R gives" (test-add-render.R): 5 expectations, 0 failed, not skipped (Quarto 1.10.19). No row after the first render by name, a row on `analyses/models.qmd` after a comment line is appended to `_scripts/report.R`, none after a second render by name.
- AC5: test "a hash line after 5 MB of text on one line gives a stale-script row": 2 expectations, 0 failed. `expect_no_warning()` wraps the check, and both "next-line" (5 MB, line break, hash line) and "same-line" (5 MB, then the hash text on that line) get the row.
- AC6: read on f4cef35. The `add_report()` help (R/add-report.R:33-38) and GUIDE.md "Shared report code" (lines 27-33 of the section) say that `check_supplement()` gives a row for a report whose stored output gives another MD5, and the M058 NEWS.md bullet now says only to render each report by name; none says a change gives no row. The `check_supplement()` help lists `"stale-script"` (R/check-supplement.R:92) and says a report whose stored output holds no such hash gets no row. NEWS.md has the `"stale-script"` bullet (lines 15-24).
- gate on f4cef35: `cairn_validate` all checks passed; `devtools::document()` no diff; no README.Rmd; `pkgdown::check_pkgdown()` no problems; NEWS.md has the bullet; no new top-level file; `devtools::check()` 0 errors, 0 warnings, 1 note (local `.claude`, as in M058-M060). No principle changed, so no `cairn_impact` run.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: `print_environment()` reads `site` at call time, so a report that sets `site <- "Boston"` fails its render — fix now, fixed 934fed2 (hash taken when report.R is sourced; regression test fails on the old code with "cannot open the connection").
- diff-bug #2: a report that is a link to a missing file gets a stale-script row it cannot clear — fix now, fixed 934fed2 (skip when `report_hash()` is NULL; "dangling" case; fails with the skip removed).
- diff-bug #3: a live format file gets the format hint after `--to html` — fix now, fixed 934fed2 (DESIGN.md Known issues "Format hint on a live file" now names `"stale-script"`).
- diff-bug #4: one report can get both stale rows — reject (planned change: the plan chose a separate check id).
- diff-bug #5: 32 hex characters are taken with no end boundary — reject (planned change: AC2 reads 32 characters; an MD5 is 32).
- diff-bug #6: a hash line from other output, such as another report's stored text, also counts — fix now, fixed 934fed2 (help states it).
- diff-bug #7: the AC5 same-line fixture's `sub()` is not checked — fix now, fixed 934fed2 (`stopifnot`).
- diff-bug #8: `skip_on_cran()` on the in-process test is not needed — reject (style; it runs `session_info()` like the other session tests).
- diff-bug #9: `expect_match(expected, ...)` tests `tools::md5sum()` — fix now, fixed 934fed2 (removed).
- diff-bug #10: `expect_true(any(crlf == 13))` tests the fixture — fix now, fixed 934fed2 (removed).
- diff-bug #11: `expect_no_error()` before exact checks — fix now, fixed 934fed2 (removed).
- diff-bug #12: `nrow(rows) == 3` is covered by the exact text checks — fix now, fixed 934fed2 (removed).
- diff-bug #13: the positive control in the missing-file test repeats the "differs" case — reject (false: it shows that the later no-row results are not empty by default, per check discrimination).
- diff-bug #14: "upper"/"short" and the two AC5 tests run one code path — reject (planned change: AC3 and AC5 name each case).
- diff-bug #15: the "A hidden file is not read." comment restates the name — fix now, fixed 934fed2 (removed).
- blame-history #1: DESIGN.md says a report.R change gives no row, against D-029 — fix now, fixed 19c1400.
- blame-history #2: `print_environment()` now depends on `site` at render time — fix now, fixed 934fed2 (same fix as diff-bug #1).
- blame-history #3: `run_session_code()` sets `site`, so no test runs without it — reject (false: the harness follows the documented use, where the `site` chunk sets it; the new test covers a later change of `site`).
- blame-history #4-#6: replaced M059 limit text, `stored_json()` refactor, CR LF handling — noted (no finding).
- blame-history #7: the ROADMAP candidate row still describes the gap — reject (planned change: post-merge hygiene graduates it).
- prior-review #1: a dangling report link gets a row, against the M035/M045 link rule — fix now, fixed 934fed2 (same fix as diff-bug #2).
- prior-review #2: the documented link-to-missing `report.R` case has no test — fix now, fixed 934fed2 (case added).
- prior-review #3: byte order of the named files is untested for this row — fix now, fixed 934fed2 (en_US.UTF-8 order test).
- prior-review #4: a report without `site` fails at the last step — fix now, fixed 934fed2 (same fix as diff-bug #1).
- prior-review #5: `expect_match(expected, ...)` checks the built string — fix now, fixed 934fed2 (same as diff-bug #9).
- prior-review #6: no Windows CI evidence yet — reject (false as a defect: CI on Windows, macOS, and Ubuntu runs on the PR before the merge).
- ripple #1: DESIGN.md:232-233 "gives no row" — fix now, fixed 19c1400.
- ripple #2: ROADMAP.md row describes the gap as open — reject (planned change: hygiene graduates it).
- ripple #3: test-release-supplement.R loop omits "stale-script" — reject (false: `release_supplement()` stops on any row through one code path, and "missing-script" is also absent).
- ripple #4: report.R comment on `print_environment()` omits the MD5 — fix now, fixed 19c1400.
- ripple #5: DESIGN.md example-section text omits the MD5 line — fix now, fixed 19c1400.
- ripple #6: NEWS.md:246-248 says the section prints the versions — reject (false: still true; the M061 bullet states the MD5 line).
- ripple #7: NEWS.md:5-6 M058 bullet — reject (false, same reason).
- ripple #8: `add_report()` help lines 26-29 — reject (false: lines 33-38 of the same help state the MD5 line).
- ripple #9: README.md:81-83 — reject (false: still true; the README check list names the row).
- ripple #10: example.qmd and GUIDE.md section text — reject (planned change for example.qmd, left unchanged so the placeholder row still finds it; the GUIDE.md section now names the MD5 line).
- ripple #11: NEWS.md:108-132 check list omits the row — reject (false: that bullet records an earlier addition; the M061 bullet records this one).
- ripple #12: re-render rules name one report only — reject (false: not contradicted; GUIDE.md "Shared report code" gives the steps after a report.R change).
- after fixes on 934fed2: the AC1-AC5 tests, plus the new site-change and byte-order tests, pass (0 failed). Full `devtools::test()` 418 tests, 0 failed, 10 skipped; `devtools::check()` 0 errors, 0 warnings, 1 note (local `.claude`). No snapshot files changed. Open-PR read: 0 open PRs, under the feature cap of 2. Amendments: 0. Findings: 20 fix now (5 repeat another lens's finding), 17 rejected (none on the edge ground), 0 follow-up, 3 noted.
