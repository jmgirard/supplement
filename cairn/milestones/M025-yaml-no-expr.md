# M025: Package functions read YAML without running R code

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — exported functions that read the site's YAML files
- **Branch/PR:** m025-yaml-no-expr

## Goal

No YAML read in the package's R code runs `!expr` code, also when a user sets `options(yaml.eval.expr = TRUE)`.

## Scope

**In:** pass `eval.expr = FALSE` at the three direct `yaml::yaml.load()` calls that lack it: `R/add-data.R:204` in `add_data()`, `R/check-supplement.R:765` in `check_cff_doi()`, and `R/yaml-insert.R:427` in `yaml_scalar()`. The milestone also adds tests and a NEWS.md bullet.

**Out:** YAML that Quarto, the template's TypeScript scripts, or the Lua extension read is not read by R and runs no `!expr` code, so it needs no work.

## Acceptance criteria

- [x] AC1: Each call in `R/` to `yaml::yaml.load()`, `yaml::yaml.load_file()`, or `yaml::read_yaml()` passes `eval.expr = FALSE`. The calls are the ones that `grep -nE 'yaml\.load|read_yaml' R/*.R` finds, each read to its closing parenthesis, comments left out.
- [x] AC2: Three tests set `withr::local_options(yaml.eval.expr = TRUE)` and write a `!expr` value whose code, if run, makes a marker file. Each test checks that the call completes and that the marker file does not exist after it. The value is in `_supplement.yml` for `add_data()`, in the `doi` of `CITATION.cff` for `check_supplement()`, and in the `text` of a navbar item before the Analyses item in `_quarto.yml` for `add_report()`.
- [x] AC3: `NEWS.md` says that package functions read YAML files without running `!expr` code, also when `options(yaml.eval.expr = TRUE)` is set.
- [ ] AC4: `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T2
- AC2 → T1, T2
- AC3 → T3
- AC4 → T1, T2, T3, T4

## Tasks

- [x] T1: Add the three AC2 tests, in `tests/testthat/test-add-data.R`, `test-check-supplement.R`, and `test-add-report.R`, in the shape of the test "reading front matter runs no !expr code" (`test-check-supplement.R:295`). Put each `!expr` value where the call reaches the parse site under change: for `add_data()`, a key that `read_supplement()` accepts and the `data` list read at `R/add-data.R:204` holds; for `add_report()`, a navbar item that `yaml_find_list()` passes to `yaml_scalar()` before it finds Analyses. Run each test against the code on main and record in the work log that it makes the marker file there (LESSONS M010).
- [x] T2: Add `eval.expr = FALSE` at the three calls, or route the two calls with the sequence handler through `yaml_load_list()` (`R/yaml-insert.R:175`). Run the AC1 grep and record its lines in the work log.
- [x] T3: Add a bullet to `NEWS.md` under 0.0.0.9000, which is not released.
- [x] T4: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: what to work on — the candidate rows "Read YAML without running R code", "Find inline code in more shapes", and "Find stale stored output for reports", planned as M025, M026, and M027.
- 2026-10-20: absorbed the candidate row "Read YAML without running R code" in full.
- 2026-10-20: investigation: `grep -rn 'yaml::\|yaml\.load\|read_yaml' R inst NAMESPACE` lists four parser calls in `R/`, of which only `yaml_load_list()` passes `eval.expr = FALSE`; `inst/` has none. A probe with yaml 2.3.12 under the option: `eval.expr = FALSE` returns the `!expr` text as a string and makes no marker file, and the default call makes it.
- 2026-10-20: collision check: M024 added `eval.expr = FALSE` to `yaml_load_list()` and named this row. No D-entry or other archive overlaps.
- 2026-10-20: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-20: lessons surfaced: M024 (`eval.expr = FALSE` and the marker-file test), M010 (prove a test fails against main).
- 2026-10-20: changelog: a new bullet under 0.0.0.9000.
- 2026-10-20: criteria audit (full mode, fresh Opus reader): 1 finding, taken. AC1 bound a property of the grep and missed a call over several lines; it now promises that each parser call passes `eval.expr = FALSE`, with the grep as the procedure that finds the calls. AC2 to AC4 had no finding.
- 2026-10-20: implement started on branch m025-yaml-no-expr, cut from main at bca59f7.
- 2026-10-20: T1: added "reading _supplement.yml runs no !expr code" (test-add-data.R, value in the example item's `description`), "finding the Analyses menu runs no !expr code" (test-add-report.R, value in the Home item's `text`), and "reading CITATION.cff runs no !expr code" (test-check-supplement.R, value in `doi`). On main's R code each fails with "Expected `file.exists(marker)` to be FALSE", actual TRUE.
- 2026-10-20: T1: new helpers `expr_marker()` and `expr_value()` in helper-files.R build the marker path with `/` (`normalizePath(winslash = "/")`), because a Windows path's `\` in a double-quoted YAML string is an escape. The M024 front matter test now uses them; with `\` on Windows its value did not parse, so it passed without reaching the `!expr` code.
- 2026-10-20: correction to the line above: the Windows claim is reasoned from YAML's escape rules (`\U` needs eight hex digits), not seen on a Windows run.
- 2026-10-20: T2: `add_data()` and `check_cff_doi()` now call `yaml_load_list()`, which has the same sequence handler, and `yaml_scalar()` passes `eval.expr = FALSE`. The AC1 grep lists `R/supplement-yml.R:34` (a comment), `R/yaml-insert.R:176` (`yaml_load_list()`), and `R/yaml-insert.R:427` (`yaml_scalar()`), each a one-line call with `eval.expr = FALSE`. `devtools::test()`: 277 tests, 0 failed, 0 errors, 7 skipped.
- 2026-10-20: T3: added the last bullet under 0.0.0.9000 in NEWS.md. "Read as its text" rests on the plan probe (yaml 2.3.12 returned the `!expr` text as a string).
- 2026-10-20: T4: `devtools::document()` gives no diff; `devtools::check()` 0 errors, 0 warnings, 0 notes. The R-CMD-check workflow runs at the PR.
- 2026-10-20: claim audit: 9 claims read, 1 corrected — NEWS.md ("read as its text" became "read as the text of its R code"; the reader found the old words could mean the value the code gives). The reader also ran the four `!expr` tests against in-memory copies of `yaml_load_list()` and `yaml_scalar()` without `eval.expr = FALSE`, and each failed.
- 2026-10-20: implement done; status set to review.
- 2026-10-20: step-7 approval: m025-yaml-no-expr approved for merge

## Decisions

## Review

- 2026-10-20: sync: `origin/main` is bca59f7, the branch's base; no merge needed.
- AC1 evidence (2026-10-20): `grep -nE 'yaml\.load|read_yaml' R/*.R` gives 3 lines: `R/supplement-yml.R:34` (a comment), `R/yaml-insert.R:176` (`yaml_load_list()`, `eval.expr = FALSE`), and `R/yaml-insert.R:427` (`yaml_scalar()`, `eval.expr = FALSE`). Each call is on one line, so its closing parenthesis is on the line the grep shows.
- AC2 evidence (2026-10-20): fresh `devtools::test()`: "reading _supplement.yml runs no !expr code" (test-add-data.R, 2 expectations), "finding the Analyses menu runs no !expr code" (test-add-report.R, 3), and "reading CITATION.cff runs no !expr code" (test-check-supplement.R, 2) pass with 0 failed. Each sets `yaml.eval.expr = TRUE`, checks that the call completes, and checks that the marker file is absent. On main's R code each failed on the marker (work log, T1), and the claim audit saw each fail without `eval.expr = FALSE`.
- AC3 evidence (2026-10-20): the last bullet under 0.0.0.9000 in NEWS.md reads "Package functions read YAML files without running `!expr` code, also when `options(yaml.eval.expr = TRUE)` is set. Such a value is read as the text of its R code."
- AC4 evidence, local part (2026-10-20): fresh `devtools::test()` 277 tests, 0 failed, 0 errors, 7 skipped; `devtools::check()` 0 errors, 0 warnings, 0 notes. The R-CMD-check workflow part is recorded at the PR; the box stays open until then.
- Consistency gate (2026-10-20): `cairn_validate.py` all checks passed; `devtools::document()` gives no diff; no README.Rmd and no `_pkgdown.yml`; NEWS.md has the entry; no new top-level file; full check as in AC4.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the add_data test has no `expect_length(i, 1)` guard, so a changed template line makes it pass with no `!expr` — fix now.
- diff-bug #2: a quote in the temp path breaks the value, and two tests then pass on main — fix now (`expr_marker()` checks for quotes).
- diff-bug #3: the add_report test's `expect_message()` has no pattern — fix now ("added it to the Analyses menu").
- diff-bug #4: the CITATION test does not show that `check_cff_doi()` read the file — fix now (asserts the `doi-mismatch` row and "not a DOI").
- diff-bug #5: DESIGN.md does not state the `eval.expr = FALSE` rule — fix now (Architecture paragraph on `R/yaml-insert.R`).
- diff-bug #6: `yaml_scalar("[a]")` gives "a", so `text: [Analyses]` matches — follow-up, new row "Match menu items only on plain text" (it was there before M025).
- diff-bug #7: yaml in Imports has no floor though the code needs `eval.expr` — follow-up, absorbed into the row "Keep tests within the Suggests floors" (there before M025).
- blame-history #1: `R/add-data.R:203-204` parsed the text with no final line break, unlike `yaml_lines_text()` (M016) — fix now (the line this diff changed now calls `yaml_lines_text()`).
- blame-history #2: the `eval.expr = FALSE` setting is in two places, and NEWS does not name the menu lookup — reject (planned change): NEWS covers every package read; one place is the follow-up row of diff-bug #6, because that route changes what the lookup matches.
- prior-review #1: `yaml_scalar()` reads a one-item flow sequence as text, against the M005 sequence rule — follow-up, same row as diff-bug #6.
- prior-review #2: `yaml_scalar()` repeats the setting in place of `yaml_load_list()`, against the M024 reuse fix — reject (planned change), as blame-history #2.
- ripple #1: the candidate row "Read YAML without running R code" describes the gap this diff closes — reject (planned change): post-merge hygiene removes the row.
- ripple #2: the M005 lesson tells readers to pass the sequence handler with no `eval.expr` — fix now (lesson corrected in place, pointing at `yaml_load_list()`).
- ripple #3: DESIGN.md Known issue "Release write order remainder" says the release parses with `yaml.load()` — reject (false): the reviewer found it still accurate, and it is about line breaks.
- ripple #4: DESIGN.md says readers of `_supplement.yml` call `yaml_read_file_text()`, but `add_data()` parses again with `yaml_load_list()` — reject (false): that second parse reads text the first read already parsed, so the error-class claim still holds.
- ripple #5: the M024 lesson states the rule the diff applies — reject (false), no conflict.
- ripple #6: test-only YAML reads omit `eval.expr = FALSE` — reject (planned change): Scope covers package code, and no test that sets the option calls them.
- 2026-10-20: after the fixes, `devtools::test()` 277 tests, 0 failed, 0 errors, 7 skipped.
- 2026-10-20: the 7 fix-now items (diff-bug #1 to #5, blame-history #1, ripple #2), fixed 6117ed2; `devtools::check()` after them 0 errors, 0 warnings, 0 notes. Totals: 17 findings, 7 fixed, 3 follow-up, 7 rejected.
