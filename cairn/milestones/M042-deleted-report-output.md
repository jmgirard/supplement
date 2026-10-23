<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M042: Flag stored output of deleted reports

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — adds a `check_supplement()` row that stops `release_supplement()`
- **Branch/PR:** m042-deleted-report-output

## Goal

Authors who delete or rename a report learn from `check_supplement()` that its stored output is left in `_freeze/analyses/`.

## Scope

**In:** a `"leftover-output"` row in `check_supplement()` for a folder in
`_freeze/analyses/` that no entry of `analyses/` matches. Like every row, it
stops `release_supplement()` (the user's choice at the question set; the
release already stops on any row). The example report's `"placeholder"` row
names `_freeze/analyses/example/`. A render test of the template guide's
steps after a deleted report. The help page and a NEWS entry.

**Out:**
- Leftover format files, such as `docx.json`, inside a live report's
  folder: the candidate row "Name leftover format files in _freeze".
- Folders in subfolders of `_freeze/analyses/` or directly in `_freeze/`,
  and leftovers that a same-named file in `analyses/` hides: not read; the
  help page states it (AC4), and review hygiene adds a DESIGN.md Known
  issues line.
- A release exemption for the row: not built, by the user's choice.

## Acceptance criteria

- [x] AC1: `check_supplement()` gives one row with check `"leftover-output"` and file `_freeze/analyses/<name>` for each folder directly in `_freeze/analyses/` whose name does not start with `.`, unless `analyses/` holds a file or folder whose name, cut before its last `.` (the whole name when it holds no `.`), equals `<name>` with letter case ignored. The row's problem text says to delete the folder, render the whole site, and commit `_freeze/` and `docs/`. Tests in `test-check-supplement.R`, on sites built without a render, show a row for a folder with no report, and no row for a folder beside `analyses/<name>.qmd`, beside `analyses/<name>.ipynb`, beside a folder `analyses/<name>/`, beside a report whose name differs from it only in letter case, for a folder whose name starts with `.`, for a file directly in `_freeze/analyses/`, and for a site with no `_freeze/analyses/` folder.
- [x] AC2: The `"placeholder"` row for `analyses/example.qmd` says to delete `_freeze/analyses/example/` along with the report, and a test in `test-check-supplement.R` asserts the row's full text.
- [x] AC3: A test in `test-add-render.R` that renders with Quarto adds a report that saves a figure under a new name in `figures/`, renders the site in full twice, then deletes the report and its Analyses menu item and renders in full again. `check_supplement()` then gives a `"leftover-output"` row for `_freeze/analyses/<name>` when that folder exists and none when it does not. After the folder is deleted and the site is rendered in full again, `docs/analyses/<name>.html` does not exist, the figure is in `figures/` and `docs/figures/`, and `check_supplement()` gives no `"broken-link"` row and no `"leftover-output"` row.
- [x] AC4: The help page of `check_supplement()` describes the `"leftover-output"` row by the rule of AC1. It says that folders inside subfolders of `_freeze/analyses/` and folders directly in `_freeze/` are not read, and that a file or folder in `analyses/` of the same name, such as `<name>.R`, hides a leftover folder, as does a report whose name differs only in letter case. `NEWS.md` has an entry for the row.
- [x] AC5: The `verify` slot is clean: `devtools::document()` leaves no diff and `devtools::test()` passes.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5

## Tasks

- [x] T1: Add `check_leftover_output()` to `R/check-supplement.R` beside
      `check_stale_output()` (~line 561), call it from `check_supplement()`
      (~line 244), and add the AC1 tests in `test-check-supplement.R` near
      the stale-output tests (~line 403).
- [x] T2: Edit `placeholder_example_problems` (`R/check-supplement.R`
      ~line 1034) and assert the example row's full text in the placeholder
      tests (~line 1334).
- [x] T3: Add the AC3 render test in `test-add-render.R` after the rename
      test (~line 109), with its own report that saves a figure.
- [x] T4: Add the row's bullet to the roxygen of `check_supplement()`
      (~line 56), run `devtools::document()`, and add the NEWS.md entry.
      Grep `README.md`, `vignettes/`, and `inst/template/_README.md` for
      lists of check names and update any that list them.
- [x] T5: Run `devtools::document()` and `devtools::test()`.

## Work log

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: not run — work named at the question set.
- 2026-10-23: idea vet: no concern found; the any-extension, case-ignoring name match keeps `.Rmd` and `.ipynb` reports, report folders, and case-only renames on macOS and Windows from drawing a false row, at the cost of missed leftovers that AC4 names.
- 2026-10-23: question set: should the new row stop release_supplement() — yes, like every other row; no code change, since the release stops on any row, and no release test, since it would run the same path as the existing release tests.
- 2026-10-23: collision check: absorbs the candidates "Flag stored output of deleted reports", "Name stored output in the example row", and "Test the guide's steps after a deletion"; cross-references "Name leftover format files in _freeze" (files inside a live report's folder); M041 (done) added the guide step this row backs; no D-entry bears.
- 2026-10-23: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-23: lessons: M009 (stated rule plus listed tests) shapes AC1; D-018 (a first render does not copy a new figure into docs/figures/) shapes AC3's two renders.
- 2026-10-23: criteria audit (full mode, fresh Opus reader): 6 findings. (1) AC3 with example.qmd empties the menu and fails the render, and its figure ships with the template: fixed, the test adds its own report and renders twice. (2) a case-counted match flags a case-only rename's live output on macOS: fixed, case ignored, the Linux miss named in AC4. (3) the row text skipped the render step: fixed. (4) any extension hides leftovers: kept as the narrower promise, named in AC4. (5) AC3 bound Quarto's keeping of the folder: fixed, the row is asserted when the folder exists. (6) "no page" read two ways: fixed as `docs/analyses/<name>.html`; how a link to a folder reads is left unpromised.
- 2026-10-23: plan gate chose an any-extension, case-ignoring name match over matching only `.qmd`, `.Rmd`, and `.ipynb` with case counted, because the chosen rule never tells an author to delete live output; falsified by a realistic site whose leftover folder a same-named file that is not a report hides.
- 2026-10-23: changelog: one NEWS.md entry for the row (T4).
- 2026-10-23: implement started on m042-deleted-report-output, cut from main at 45cbf0e.
- 2026-10-23: T1 checkpoint: `check_leftover_output()` and `fold_case()` added and called after `check_stale_output()`; the new test failed before the code (2 failures) and passes after; planted defects (no case fold, no extension cut) each fail it; full suite still running, so T1 is not ticked.
- 2026-10-23: T1 done: full suite 370 tests, 0 failed, 8 skipped.
- 2026-10-23: T2 checkpoint: the example report's placeholder row names `_freeze/analyses/example/`; its full-text test failed on the old text and passes; full suite running, so T2 is not ticked.
- 2026-10-23: T2 done: full suite 371 tests, 0 failed, 8 skipped.
- 2026-10-23: T3 checkpoint: deletion render test added to `test-add-render.R`, with a report that writes `figures/trends.png` from a chunk; passes with `NOT_CRAN=true` (12 expectations); with `check_leftover_output()` planted to return no rows it fails, so Quarto 1.10.19 kept `_freeze/analyses/trends/`; the full suite runs with T4.
- 2026-10-23: T4 checkpoint: help-page bullet for `"leftover-output"`, `man/check_supplement.Rd` regenerated, a sentence in the `check_supplement()` NEWS entry, and a DESIGN.md architecture note; no other doc lists check names (grep of README.md, vignettes/, inst/template/_README.md); full suite running.
- 2026-10-23: T3, T4, T5 done: full suite 372 tests, 0 failed, 8 skipped; `devtools::document()` leaves no diff.
- 2026-10-23: claim-audit fixes (checkpoint): NEWS says "no file or folder in `analyses/` names"; the case comment names file systems that ignore case (macOS default) in place of an unshown Windows claim; `fold_case()` now lowers the ASCII capitals of a name that is not valid UTF-8, so AC1's case rule holds there too, with a direct test that failed before the change; the help bullet says only ASCII case is ignored in such a name; full suite and the auditor's re-read running.
- 2026-10-23: claim audit: 43 claims read, 3 corrected — NEWS.md, R/check-supplement.R (case comment, help bullet), man/check_supplement.Rd; the re-read found all three true.
- 2026-10-23: implement done: full suite 373 tests, 0 failed, 8 skipped; status set to review.
- 2026-10-23: review: M041's plan gate chose a guide step over a `check_supplement()` row for a deleted report's stored output; M042 adds the row as well, from the candidate row M041's plan filed, and keeps the guide step.
- 2026-10-23: review fixes committed at fbfd846 (diff-bug 1, 2, 3, 4, 5, 9, 10, 13; blame-history 1, 7; prior-review 1, 2; ripple 1, 2, 3); no finding met the return floor, so status stays review.
- 2026-10-23: step-7 approval: m042-deleted-report-output approved for merge

## Decisions

## Review

- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: a name in `analyses/` that is not valid UTF-8 makes `sub()` stop `check_supplement()` — fix now (byte-mode cut, end-to-end test that runs where the file system allows such a name), fixed fbfd846
- diff-bug #2: the help claim on such names failed for `analyses/` names because of #1 — fix now, fixed fbfd846
- diff-bug #3: the `fold_case()` test's `"Trends"` expectation tests base `tolower()` — fix now (removed; end-to-end case added), fixed fbfd846
- diff-bug #4: the `.`-name filter repeats what `list.files()` does — fix now (filter removed, comment added; the test keeps the contract), fixed fbfd846
- diff-bug #5: `all.files = TRUE` on the `analyses/` listing could never match — fix now (removed), fixed fbfd846
- diff-bug #6: AC1's test cases share one code path — reject: planned change (AC1 names each case)
- diff-bug #7: AC3's render test checks Quarto's behavior — reject: planned change (AC3's shape, set at the criteria audit)
- diff-bug #8: AC3's last no-row check is trivially true — reject: planned change (AC3 names it)
- diff-bug #9: the row text left out committing the old report path and `_quarto.yml` — fix now (text and help page), fixed fbfd846
- diff-bug #10: "letter case ignored" promised more than `tolower()` gives — fix now (help page states ASCII always, other letters as `tolower()` reads them in the locale), fixed fbfd846
- diff-bug #11: names in another Unicode form do not match — follow-up: candidate row "Match folder names across Unicode forms" (help page states it)
- diff-bug #12: the example row names a folder an unrendered site lacks — reject: planned change (AC2)
- diff-bug #13: long NEWS and roxygen lines — fix now (rewrapped), fixed fbfd846
- blame-history #1: `tolower()` follows the locale (Turkish `I`), against LESSONS M021 — fix now (`ascii_lower()` first), fixed fbfd846; no test, since this Mac's tr_TR `tolower("I")` gives `i` and CI has no such locale
- blame-history #2: M041's plan gate chose a guide step over a row — fix now (work-log line records the change)
- blame-history #3: a same-named helper file hides a leftover — reject: planned change (AC4)
- blame-history #4: Linux case-only renames are missed — reject: planned change (AC4, criteria audit item 2)
- blame-history #5: AC3's row assertion is conditional — reject: planned change (AC3)
- blame-history #6: `fold_case()` repeats `utf8_lower()` — reject: style
- blame-history #7: NEWS wrap — fix now (same as diff-bug #13), fixed fbfd846
- prior-review #1: same defect as diff-bug #1 — fix now, fixed fbfd846; the older checks' `sub()` on report names goes to follow-up: candidate row "Read report names that are not UTF-8"
- prior-review #2: NEWS line of 149 characters, a defect earlier reviews fixed — fix now, fixed fbfd846
- prior-review #3: the M041 reversal is not recorded — fix now (same as blame-history #2)
- ripple #1: README.md and the template guide list what the check finds without the new row — fix now (bullet added to both), fixed fbfd846
- ripple #2: the row text left out steps the guide gives — fix now (same as diff-bug #9), fixed fbfd846
- ripple #3: the release test's list of checks lacks `leftover-output` — fix now (added), fixed fbfd846
- AC1 evidence (fbfd846, 2026-10-23): `test-check-supplement.R` "a folder in _freeze/analyses/ that nothing in analyses/ names gives a leftover-output row" passes, 3 expectations: no row on a new site (no `_freeze/analyses/`), then only `_freeze/analyses/deleted` with the full row text, against folders beside `kept.qmd`, `notebook.ipynb`, folder `sub/`, `Cased.qmd` (folder `cased`), a `.hidden` folder, and a file `loose.json`; it failed before the code and under two planted defects (T1). The end-to-end part of the not-valid-UTF-8 test skips on macOS, which refuses such names, and runs where the file system allows them.
- AC2 evidence (fbfd846): "the example report's row names its stored output" passes, asserting the row's full text with `_freeze/analyses/example/`; it failed on the old text (T2).
- AC3 evidence (fbfd846): `test-add-render.R` "the guide's steps after a deletion remove the page and keep the report's figure" passes with `NOT_CRAN=true`, 12 expectations, Quarto 1.10.19; with `check_leftover_output()` planted to return no rows it fails, so the folder stayed and the row assertion ran (T3).
- AC4 evidence (fbfd846): `man/check_supplement.Rd` has the `"leftover-output"` item with the AC1 rule, "Folders inside subfolders of `_freeze/analyses/` and folders directly in `_freeze/` are not read", the `<name>.R` and letter-case hiding cases; NEWS.md's `check_supplement()` entry has the sentence on folders in `_freeze/analyses/`.
- AC5 evidence (fbfd846): `devtools::document()` leaves no diff; `devtools::check()` 0 errors, 0 warnings, 0 notes, its test run included.
- gate: `cairn_validate.py` all checks passed; `document()` no diff; no README.Rmd and no pkgdown site, so those checks do not apply; NEWS.md has the entry, with no milestone number; no new top-level file; `devtools::check()` clean; no principle changed, so `cairn_impact` was skipped.
- note: the simple-english lint hook reports one over-long sentence in the check lists of README.md and the template guide; `main`'s README.md gives the same hit, since the linter reads the bullet list as one sentence
