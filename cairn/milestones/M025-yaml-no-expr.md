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

- [ ] AC1: Each call in `R/` to `yaml::yaml.load()`, `yaml::yaml.load_file()`, or `yaml::read_yaml()` passes `eval.expr = FALSE`. The calls are the ones that `grep -nE 'yaml\.load|read_yaml' R/*.R` finds, each read to its closing parenthesis, comments left out.
- [ ] AC2: Three tests set `withr::local_options(yaml.eval.expr = TRUE)` and write a `!expr` value whose code, if run, makes a marker file. Each test checks that the call completes and that the marker file does not exist after it. The value is in `_supplement.yml` for `add_data()`, in the `doi` of `CITATION.cff` for `check_supplement()`, and in the `text` of a navbar item before the Analyses item in `_quarto.yml` for `add_report()`.
- [ ] AC3: `NEWS.md` says that package functions read YAML files without running `!expr` code, also when `options(yaml.eval.expr = TRUE)` is set.
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

## Decisions

## Review
