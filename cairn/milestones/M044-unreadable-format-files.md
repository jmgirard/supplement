<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M044: Advise deleting unreadable format files

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes the row text that `check_supplement()` and `release_supplement()` show authors
- **Branch/PR:** m044-unreadable-format-files

## Goal

The problem text of a `"stale-output"` row shows which stored output files it names, and how to clear a row whose unreadable file no render rewrites.

## Scope

**In:** In `check_stale_output()` (`R/check-supplement.R`), a delete step at the end of every "cannot be read" text, after the render steps, and double quotes with `\` escapes around each stored output file path that the row names, in the text for differing files and in the text for unreadable files. Tests, the help item, and the NEWS.md bullet for both.

**Out:** Reading the formats a report renders from its YAML → declined at the M043 question set (archive `M043-leftover-format-files.md`). The `<xx>` form of bytes that are not valid UTF-8 in a named path stays as it is. Report names that are not UTF-8 → candidate "Read report names that are not UTF-8". The `", "` join of template values in the `"placeholder"` row names values, not files, and is not changed. How cli prints the row (it wraps the text and can change runs of spaces or line breaks in a name) is not changed; the criteria bind the row's `problem` text.

## Acceptance criteria

- [ ] AC1: The problem text of a `"stale-output"` row that says the source hash of its stored output cannot be read ends with the render steps (`rerender_steps`), a space, and then this delete step: "If the row stays after these steps, these files can be from a format that the report no longer renders, or damaged. Delete them, render the whole site, and commit the report with _freeze/, docs/, and figures/." Tests in `tests/testthat/test-check-supplement.R` assert the whole text for these reports: one unreadable file alone, two unreadable files, an unreadable file beside a file whose hash differs, and an unreadable file beside a file whose hash matches.
- [ ] AC2: Each stored output file that a `"stale-output"` row's problem text names (`_freeze/analyses/<name>/execute-results/<file>`), in the text for differing files and in the text for unreadable files, stands between double quotes, with a `\` written before each `\` and `"` in its path. Tests assert the whole text for: two differing files named `a, b.json` and `c.json`; an unreadable file named `x, y.json`; and, on systems other than Windows, which refuses `"` and `\` in file names, a differing file whose name holds `"`, one whose name holds `\`, and a differing file of a report whose name holds `"`.
- [ ] AC3: A test in `tests/testthat/test-add-render.R` that renders with Quarto (skipped when Quarto is missing) shows: (a) when a report's `html.json` is replaced by text that does not parse, the row's problem text starts with "The source hash of its stored output cannot be read", and after a render of the report by name and a render of the whole site the row is gone; (b) when a report drops its `docx` format and its `docx.json` is replaced by text that does not parse, the row stays after those two renders, and after `docx.json` is deleted and the whole site is rendered the row is gone and `html.json` is still there.
- [ ] AC4: The `"stale-output"` item of the `check_supplement()` help page states the condition of the delete step (the row stays after the render steps), its action (delete the named files, render the whole site, commit the report with `_freeze/`, `docs/`, and `figures/`), and the quoting rule with its `\` escapes. The `check_supplement()` bullet in `NEWS.md` states that the row puts each named file in double quotes and that the "cannot be read" text adds a delete step.
- [ ] AC5: `devtools::document()` leaves `man/` with no diff, `devtools::test()` passes, and on the review machine `devtools::check()` gives 0 errors, 0 warnings, and no note that the default branch does not also give there. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T4
- AC5 → T5

## Tasks

- [x] T1: Tests first in `tests/testthat/test-check-supplement.R`: change the `stale_text()` helper (about line 405) and the `unreadable_text()` helper (about line 537) to the quoted form, add the delete step to `unreadable_text()`, change the `endsWith(rows$problem, rerender_steps)` expectation (about line 529) to the AC1 ending, and add the AC1 and AC2 cases. Put the `"` and `\` cases after the `, ` cases, behind `skip_on_os("windows")`, so the other cases still run there (LESSONS M023). See them fail on the default branch's code.
- [x] T2: In `check_stale_output()` (`R/check-supplement.R` about lines 603 to 606), quote each path in `named()` with a small helper and add the delete step after `rerender_steps` in the "cannot be read" text.
- [x] T3: In `tests/testthat/test-add-render.R`, add the AC3 render test beside "the stale-output row names the stored output of a dropped format until it is deleted", and change that test's match on `docx_json` (about line 104) to the quoted form.
- [ ] T4: Update the `"stale-output"` roxygen item (`R/check-supplement.R` about lines 74 to 83) and the `check_supplement()` bullet in `NEWS.md` (about lines 56 to 73), then run `devtools::document()`.
- [ ] T5: Run `devtools::test()` and `devtools::check()`, and compare any note with a check of the default branch on the same machine.

## Work log

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: not run — work named at the question set.
- 2026-10-23: question set: which work — "Advise deleting unreadable format files"; when to give the delete step — always, in every "cannot be read" text; the `, ` join of names — fix it here, in both texts.
- 2026-10-23: idea vet: none found. The delete step is safe because a render writes the stored output of each format the report still renders (AC3 shows it); the edge where non-UTF-8 bytes in a JSON file give the "cannot be read" text is DESIGN.md's accepted "Stored output hash edges" known issue.
- 2026-10-23: collision check: absorbs the candidate row "Advise deleting unreadable format files" in full (both its parts); extends M043 (done); no D-entry matches; inbox sweep found 0 open issues and 0 open PRs.
- 2026-10-23: plan gate chose double quotes with `\` escapes over `encodeString()` (its escapes of non-ASCII text depend on the locale) and over one path per line (a name can hold a line break, and cli wraps the text); falsified by a named path that the quoted form shows as two paths or as another name.
- 2026-10-23: plan gate chose the delete step after the render steps ("if the row stays") over a delete step alone, because a render by name rewrites a live format's unreadable file with nothing deleted; falsified by a render by name that leaves an unreadable live file in place (AC3 (a)).
- 2026-10-23: split tripwire: the goal covers two changes; kept as one milestone because the user chose to fix the join here and both changes edit `named()` and its texts.
- 2026-10-23: lessons surfaced: M009 (criteria as a stated rule plus listed tests), M023 (skip after the expectations that run everywhere), M018 (Windows names cannot hold `"` or `\`), M012 (C collation inside tests), M017 and M043 (Quarto keeps a dropped format's `.json`).
- 2026-10-23: criteria audit (full mode, fresh Opus reader): 8 findings, all fixed toward the narrower promise. AC2 binds only stored output file paths, not `_freeze/` in the steps; AC2 adds a case with `"` in the report name; the Goal and AC1 to AC3 bind the `problem` text, and cli's printing went to Out; AC1 states the exact delete-step sentence and drops "built by a test-side helper"; T1 names the `endsWith(..., rerender_steps)` expectation that AC1 makes false; AC3 (a) names the text's opening; AC4 lists the parts the help and NEWS must state; AC5 compares notes with the default branch and adds the three-system CI. The reader ran AC3's renders with Quarto 1.10.19 on macOS and they held; Linux and Windows not run.
- 2026-10-23: implement started on branch m044-unreadable-format-files, cut from main at b910a43.
- 2026-10-23: T1: test helpers `quoted_paths()`, `delete_step`, and `unreadable_text()` moved to file level in `test-check-supplement.R`; new test "a stale-output row puts each file it names in double quotes". 17 expectations failed in 4 tests on the old code.
- 2026-10-23: T2: `quote_path()` added beside `check_stale_output()`, which wraps each path in `"` and puts `\` before `\` and `"`; `named()` uses it, and the "cannot be read" text adds the delete step. `test-check-supplement.R`: 263 expectations, 0 failed.
- 2026-10-23: T3: render test "the render steps or the delete step clear a stale-output row whose source hash cannot be read" added; the dropped-format test's `docx_json` match quoted. With `NOT_CRAN=true`, `test-add-render.R`: 7 tests, 0 failed. T1 to T3 share one commit because the T1 tests pass only with T2's code.

## Decisions

## Review
