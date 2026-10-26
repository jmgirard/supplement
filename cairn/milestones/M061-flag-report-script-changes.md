<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M061: Flag reports after report.R changes

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
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

- [ ] AC1: `print_environment()` in the template's `_scripts/report.R` prints one more line, after the home-folder replacement, as its last line. The line is `Shared report code: _scripts/report.R, MD5 <hash>`. Here `<hash>` is the 32-character lowercase hex MD5 of the bytes of `file.path(site, "_scripts", "report.R")`, with each CR LF read as LF. A test sources the template's file into an environment that holds `site`, a temporary site. It runs once with that site's `report.R` saved with LF line ends and once with CR LF. Each time, the test compares the last printed line with the line built from `tools::md5sum()` of the LF copy.
- [ ] AC2: `check_supplement()` gives one `"stale-script"` row on `analyses/<name>.qmd` for a `.qmd` report directly in `analyses/` under one condition. A `.json` file directly in `_freeze/analyses/<name>/execute-results/`, with a name that does not start with `.`, has a top-level `result.markdown` text value. That value holds the text `Shared report code: _scripts/report.R, MD5 ` and then 32 characters in `[0-9a-f]`. Those 32 characters differ from the MD5 of the site's `_scripts/report.R`, with each CR LF read as LF. Any such line in any such file that differs is enough. The problem text of the row gives the steps of `rerender_steps` in `R/check-supplement.R`. When another such file of the report holds only matching lines, the text also says that the differing files can be from a format that the report no longer renders, with the delete steps that the `"stale-output"` row gives. Tests with hand-written stored output assert the check and file of the row for three cases: a differing hash, two format files of one report where only one differs (one row, with the format text), and one file with a matching line and a differing line. Tests assert no `"stale-script"` row for two cases: an equal hash, and a CR LF `report.R` whose stored hash is the hash of its LF form.
- [ ] AC3: `check_supplement()` gives no `"stale-script"` row for a report in each of these cases, and a test covers each case:
  - Its stored output holds no `Shared report code: _scripts/report.R, MD5 ` text.
  - The hash text after that text is uppercase or shorter than 32 characters.
  - The site has no `_scripts/report.R`.
  - The site's `_scripts/report.R` is a folder.
  - The only `.json` file of the report does not parse.
  - The only `.json` file of the report has no `result.markdown` text value.
  - The report has no `_freeze/analyses/<name>/execute-results/` folder.
- [ ] AC4: A render test makes a site from the template, adds a report with `add_report()`, and renders the report by name. The test skips where Quarto is unavailable, as the other render tests do. After the render, `check_supplement()` gives no `"stale-script"` row. After the test appends a comment line to `_scripts/report.R`, it gives a `"stale-script"` row on that report. After the test renders the report by name again, it gives no such row.
- [ ] AC5: Two tests put 5 MB of text with no line break in the stored `result.markdown`. In one, a line break and a differing hash line follow it. In the other, the differing hash text follows it on the same line. Each test gets the `"stale-script"` row with no warning.
- [ ] AC6: Three texts no longer say that a change to `_scripts/report.R` gives no row: the `add_report()` help, the "Shared report code" section of GUIDE.md, and NEWS.md. Each says what AC2 and AC3 state. The `check_supplement()` help lists the `"stale-script"` row. It states that a report whose stored output holds no hash line gets no row. NEWS.md has a bullet for the row.

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
- [ ] T4: Update the `check_supplement()` and `add_report()` help, GUIDE.md "Shared report code", README.md, NEWS.md (the M058 bullet and a new bullet), and DESIGN.md. Run `devtools::document()`. Also search `grep -rn "report.R\|stale" R/ man/ inst/template/ README.md NEWS.md` and read the lines around each hit for other sentences that the row makes false.
- [ ] T5: Run `devtools::test()` and `devtools::check()` until both are clean.

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

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive. -->
