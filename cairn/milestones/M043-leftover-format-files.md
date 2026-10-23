<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M043: Name leftover format files in _freeze

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes the text of a `check_supplement()` row that authors read and that stops `release_supplement()`
- **Branch/PR:** m043-leftover-format-files

## Goal

The `"stale-output"` row of `check_supplement()` names each stored output file that does not match its report, so that an author can find and delete the file of a format that the report no longer renders.

## Scope

**In:** the `"stale-output"` row names the files whose hash differs or
cannot be read. When another file of the report's stored output matches the
report, the row says that the named files can be from a dropped format and
gives the steps to remove them. A Quarto render test of a dropped `docx`
format. The help page and the `NEWS.md` bullet.

**Out:**
- A check that reads the formats a report renders and skips the files of
  other formats: not built, by the user's choice at the question set.
- Report names that are not valid UTF-8: the candidate row "Read report
  names that are not UTF-8".
- The hash edges in DESIGN.md Known issues ("Stored output hash edges"):
  not changed.

## Acceptance criteria

- [ ] AC1: For each report, the check reads each file directly in `_freeze/analyses/<name>/execute-results/` whose name ends in `.json` and does not start with `.`, and that is not a folder. A `"stale-output"` row with the "made from other text" text names each read file whose top-level `hash` differs from the report's hash. It names the files by their paths from the site folder, in byte order as `sort_bytes()` sorts them, joined by `, `. The list of named files holds no other file. When one or more other read files have a `hash` equal to the report's, the text also gives the format hint. The hint says that the named files can be from a format that the report no longer renders. It says that if so, the author deletes them, renders the whole site, and commits `_freeze/` and `docs/`, and that if not, the author follows the render steps. The text then ends with `rerender_steps`. When no read file has an equal `hash`, the text ends with `rerender_steps` and has no format hint. Tests in `test-check-supplement.R` assert the full problem text for these reports: (a) only `html.json`, which differs; (b) a matching `html.json` and a differing `docx.json`; (c) a matching `docx.json` and a differing `html.json`; (d) a matching `html.json` and a differing `docx.json` and `pdf.json`; (e) a differing `html.json` and `docx.json`, none matching. A test also shows no row for (f) a matching `html.json` beside a differing hidden `.docx.json` and a folder `old.json`.
- [ ] AC2: A `"stale-output"` row with the "cannot be read" text names each read file (the files of AC1) whose source hash cannot be read. It names them by the path, order, and join of AC1, and the list of named files holds no other file. The text then ends with `rerender_steps` and never has the format hint. Tests in `test-check-supplement.R` assert the full problem text for these reports: (a) only `html.json`, which does not parse; (b) an `html.json` and a `docx.json` that both do not parse; (c) an unreadable `docx.json` and a differing `html.json`, where the text names `docx.json` and not `html.json`; (d) an unreadable `docx.json` and a matching `html.json`.
- [ ] AC3: A test in `test-add-render.R` that renders with Quarto adds a report whose front matter sets `format` to `html` and `docx`. It renders the report by name, then renders the site in full. It then sets the report's `format` to `html` only and renders the report by name. The test asserts that `_freeze/analyses/<name>/execute-results/docx.json` exists (Quarto 1.10.19 keeps it, per the M027 lesson). `check_supplement()` then gives one `"stale-output"` row for the report, which names that file and has the format hint. The test then renders the site in full and asserts that `docx.json` still exists and the row remains. It then deletes that file and renders the site in full. After that, `docs/analyses/<name>.docx` does not exist and `check_supplement()` gives no `"stale-output"` row for the report.
- [ ] AC4: The `"stale-output"` item on the help page of `check_supplement()` states the rules of AC1 and AC2 for the named files and the format hint. These replace its sentence that says to delete a kept format file such as `docx.json`. The `NEWS.md` bullet that opens "`check_supplement()` lists the problems in a site" says that the row names each file whose hash differs or cannot be read, and gives the format hint's steps.
- [ ] AC5: The `verify` slot is clean: `devtools::document()` leaves no diff and `devtools::test()` passes.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T2
- AC4 → T3
- AC5 → T4

## Tasks

- [x] T1: In `check_stale_output()` (`R/check-supplement.R` ~line 579),
      keep the state of each read file and build the row text from the
      sorted paths and the format hint. Add the AC1 and AC2 tests beside
      the stale-output tests (`test-check-supplement.R` ~lines 403-476),
      and change the `endsWith(rows$problem, rerender_steps)` assertion
      in the "made from other text" test to full texts.
- [x] T2: Add the AC3 render test in `test-add-render.R` after the
      stale-output render test (~line 37), with its own report.
- [x] T3: Edit the `"stale-output"` item in the roxygen of
      `check_supplement()` (~lines 56-75), run `devtools::document()`, and
      edit the NEWS.md bullet that opens "`check_supplement()` lists the
      problems in a site" (line 47). Grep `README.md`, `vignettes/`,
      and `inst/template/_README.md` for advice on kept format files and
      update any that give it.
- [x] T4: Run `devtools::document()` and `devtools::test()`.

## Work log

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: not run — work named at the question set.
- 2026-10-23: idea vet: one concern, how to treat a file of a format the report no longer renders. Skipping such files needs the check to read the formats from three YAML files, and a wrong reading hides real stale output. Answer at the question set: name the files in the row.
- 2026-10-23: question set: which candidate row to plan — "Name leftover format files in _freeze". How to treat a dropped format's file — name the file in the row, with a hint when another file matches.
- 2026-10-23: plan gate chose naming the files over skipping the files of formats that the report does not render, because naming needs no reading of the YAML formats and never hides stale output; falsified by authors who keep a dropped format's file after the row names it.
- 2026-10-23: collision check: absorbs the candidate "Name leftover format files in _freeze"; extends M027 (done), which added the row; M042 (done) named this row in its Out list; no D-entry bears.
- 2026-10-23: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-23: lessons: M027 (Quarto keeps a dropped format's `.json`) backs AC3's assertion; M017 (only a full render removes a file from `docs/`) sets the hint's full render; M009 (a stated rule plus listed tests) shapes AC1 and AC2.
- 2026-10-23: criteria audit (full mode, fresh Opus reader, which probed Quarto 1.10.19: a by-name render writes `docx.json`, keeps it after `docx` is dropped, and a docx render needs only the bundled pandoc): 9 findings, all fixed. (1) the line 444 `endsWith()` test: the hint ends with `rerender_steps`, and line 444 asserts full texts. (2) "names no other file" read against the render steps: narrowed to the list of named files. (3) name order and join unstated: `sort_bytes()` order joined by `, `. (4) AC2 text after the names unstated: `rerender_steps`, never the hint. (5) AC1 probes: added (c), (e), and (f). (6) AC2 probes: added (b) and (d). (7) AC3's branch on a missing `docx.json` passed whatever Quarto did: the test asserts the file exists. (8) AC3 render order and format edit: fixed. (9) AC4's NEWS bullet: named by line.
- 2026-10-23: plan change after the audit: the format hint also says to render the whole site and commit `docs/`, so the old `.docx` leaves `docs/` (M017 lesson), and AC3 asserts it.
- 2026-10-23: criteria re-check (same reader, changed text only; it probed that a full render removes the old `.docx` from `docs/` and keeps `docx.json` with its old hash): 3 findings, all fixed. (1) AC1's line 444 sentence bound a test, not the package: dropped, and T1 names the assertion by its text. (2) AC3's `.docx` assertion passed without the delete step: a full render before the delete now shows `docx.json` and the row remain. (3) AC4's NEWS bullet named by its opening words.
- 2026-10-23: changelog: edit the `check_supplement()` bullet in NEWS.md (T3), no new entry, since the package has no release.
- 2026-10-23: started on branch m043-leftover-format-files, cut from main at 3f8cf46.
- 2026-10-23: T1 done: `check_stale_output()` builds each row's text from the read files' states. The row names files as `_freeze/analyses/<name>/execute-results/<file>` paths in `sort_bytes()` order, and the hint ends with "If not, take these steps." before `rerender_steps` (implementation choice). Tests: the AC1 cases (a)-(f) and AC2 cases (a)-(d) in `test-check-supplement.R`. The file passes.
- 2026-10-23: T2 done: the AC3 render test in `test-add-render.R` passes with Quarto 1.10.19 (17 expectations, run with `NOT_CRAN=true`). It also asserts that `docs/analyses/formats.docx` exists before `docx` is dropped, so the later absence comes from the full render after the delete.
- 2026-10-23: T3 done: the help item states the naming rules and the format hint in place of the "so delete that file" sentence, `devtools::document()` rewrote `man/check_supplement.Rd`, and the NEWS.md bullet names the files and the hint's steps. A grep of `README.md`, `vignettes/`, and `inst/template/_README.md` for `docx` and "format that" found no advice on kept format files.
- 2026-10-23: T4: `devtools::document()` left no diff, and `devtools::test()` passed (375 tests, 0 failed, 0 errors, 9 skipped) at 4f5cd59.
- 2026-10-23: claim audit: 20 claims read, 5 corrected — R/check-supplement.R, man/check_supplement.Rd, NEWS.md, tests/testthat/test-check-supplement.R. The help text and its Rd copy now say the hint needs every hash to be readable. NEWS says only unreadable files are named when one cannot be read, with the same condition on the hint. A new case, "hidden-match", shows that a hidden matching file gives no hint. The check test file passes after the fixes.
- 2026-10-23: claim audit re-read (same reader): the 5 corrected claims hold, 0 further corrections. T4 done, and the status is review. The full suite last ran at 4f5cd59, and 62b528e changed docs and one test file only, which passes.

## Decisions

## Review
