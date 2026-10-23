<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M042: Flag stored output of deleted reports

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — adds a `check_supplement()` row that stops `release_supplement()`
- **Branch/PR:** —

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

- [ ] AC1: `check_supplement()` gives one row with check `"leftover-output"` and file `_freeze/analyses/<name>` for each folder directly in `_freeze/analyses/` whose name does not start with `.`, unless `analyses/` holds a file or folder whose name, cut before its last `.` (the whole name when it holds no `.`), equals `<name>` with letter case ignored. The row's problem text says to delete the folder, render the whole site, and commit `_freeze/` and `docs/`. Tests in `test-check-supplement.R`, on sites built without a render, show a row for a folder with no report, and no row for a folder beside `analyses/<name>.qmd`, beside `analyses/<name>.ipynb`, beside a folder `analyses/<name>/`, beside a report whose name differs from it only in letter case, for a folder whose name starts with `.`, for a file directly in `_freeze/analyses/`, and for a site with no `_freeze/analyses/` folder.
- [ ] AC2: The `"placeholder"` row for `analyses/example.qmd` says to delete `_freeze/analyses/example/` along with the report, and a test in `test-check-supplement.R` asserts the row's full text.
- [ ] AC3: A test in `test-add-render.R` that renders with Quarto adds a report that saves a figure under a new name in `figures/`, renders the site in full twice, then deletes the report and its Analyses menu item and renders in full again. `check_supplement()` then gives a `"leftover-output"` row for `_freeze/analyses/<name>` when that folder exists and none when it does not. After the folder is deleted and the site is rendered in full again, `docs/analyses/<name>.html` does not exist, the figure is in `figures/` and `docs/figures/`, and `check_supplement()` gives no `"broken-link"` row and no `"leftover-output"` row.
- [ ] AC4: The help page of `check_supplement()` describes the `"leftover-output"` row by the rule of AC1. It says that folders inside subfolders of `_freeze/analyses/` and folders directly in `_freeze/` are not read, and that a file or folder in `analyses/` of the same name, such as `<name>.R`, hides a leftover folder, as does a report whose name differs only in letter case. `NEWS.md` has an entry for the row.
- [ ] AC5: The `verify` slot is clean: `devtools::document()` leaves no diff and `devtools::test()` passes.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T5

## Tasks

- [ ] T1: Add `check_leftover_output()` to `R/check-supplement.R` beside
      `check_stale_output()` (~line 561), call it from `check_supplement()`
      (~line 244), and add the AC1 tests in `test-check-supplement.R` near
      the stale-output tests (~line 403).
- [ ] T2: Edit `placeholder_example_problems` (`R/check-supplement.R`
      ~line 1034) and assert the example row's full text in the placeholder
      tests (~line 1334).
- [ ] T3: Add the AC3 render test in `test-add-render.R` after the rename
      test (~line 109), with its own report that saves a figure.
- [ ] T4: Add the row's bullet to the roxygen of `check_supplement()`
      (~line 56), run `devtools::document()`, and add the NEWS.md entry.
      Grep `README.md`, `vignettes/`, and `inst/template/_README.md` for
      lists of check names and update any that list them.
- [ ] T5: Run `devtools::document()` and `devtools::test()`.

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

## Decisions

## Review
