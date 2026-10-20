# M023: add_report() and add_data() refuse names that Windows cannot use

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — two exported functions refuse more names
- **Branch/PR:** m023-windows-names

## Goal

`add_report()` and `add_data()` refuse file names that Windows cannot use: device names such as `con`, and data file names that end in `.`.

## Scope

**In:** a check in `add_report()` for `name`, and a check in `add_data()` for the base name of `file`. Both checks run before any write and use the existing error classes. The milestone also adds tests, help text, and a NEWS.md change.

**Out:** names of files already in `docs/` that `check_supplement()` cannot read on Windows go to the candidate row "Read odd-named folders on Windows". File links on Windows go to the candidate row "Detect broken file links on Windows".

## Acceptance criteria

- [ ] AC1: If `name` is a name that Windows reserves for a device, in any letter case, `add_report()` stops and changes no file in the site. The 22 names are `CON`, `PRN`, `AUX`, `NUL`, `COM1` to `COM9`, and `LPT1` to `LPT9`. The error has the class `supplement_error_report_name`, and its message names Windows. A test in `tests/testthat/test-add-report.R` runs each of the 176 letter-case spellings of the 22 names. For each one, it checks the error class and checks that the site's files are unchanged. In the same test, `add_report()` writes the reports `console`, `com10`, `com0`, `lpt`, and `nul_x` and adds each one to the Analyses menu.
- [ ] AC2: If the base name of `file` ends in `.`, `add_data()` stops before it copies or changes any file in the site. The stem of a base name is its part before the first `.`, or the whole name when it has no `.`. If the stem is one of the 22 names of AC1, in any letter case, `add_data()` also stops. Both errors have the class `supplement_error_file_name`, and their messages name Windows. A test in `tests/testthat/test-add-data.R` runs each of the 176 spellings alone and followed by `.csv`, and also `nul.tar.gz` and `CoN.TXT`. For the trailing `.`, it runs `data.`, `a.b.`, and `scores.csv.`. Each case checks the error class and that the site's files are unchanged. These cases are skipped on Windows, which cannot make such files. In the same test, on every system, `add_data()` copies `console.csv`, `com10.csv`, `x.con`, and `nul_x.csv` and adds each one to the `data` list.
- [ ] AC3: The help pages `man/add_report.Rd` and `man/add_data.Rd` state the rules of AC1 and AC2 in the `name` and `file` argument entries and in the Errors entries for `supplement_error_report_name` and `supplement_error_file_name`. The entries list the device names and say that letter case does not matter. The `add_data()` entries also say that an extension does not matter and that a name that ends in `.` is refused. The `NEWS.md` entry for `add_report()` and `add_data()` says that both functions refuse names that Windows cannot use.
- [ ] AC4: `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1
- AC2 → T1, T2
- AC3 → T3
- AC4 → T1, T2, T3, T4

## Tasks

- [x] T1: In `R/add-utils.R`, add a helper `windows_reserved(x)`. If `tolower(x)` is one of the 22 device names, it returns TRUE. A code comment cites Microsoft's page "Naming Files, Paths, and Namespaces". In `R/add-report.R`, right after the name check (line 82), stop with `supplement_error_report_name` and a message that names Windows. Add the AC1 tests to `test-add-report.R`.
- [ ] T2: In `R/add-data.R`, right after the Markdown name check (line 112), stop with `supplement_error_file_name` and a message that names Windows. The check fires for a base name that ends in `.` or whose stem gives TRUE from `windows_reserved()`. Add the AC2 tests to `test-add-data.R`. Make each source file in its own folder (`source_file()` does), because macOS ignores letter case.
- [ ] T3: Edit the roxygen text of both functions and run `devtools::document()`. Edit the NEWS.md bullet for `add_report()` and `add_data()`, because version 0.0.0.9000 is not released.
- [ ] T4: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: what to work on — the candidate row "Refuse names that Windows cannot use".
- 2026-10-20: question set: go on into implementation after the plan — yes.
- 2026-10-20: absorbed the candidate row "Refuse names that Windows cannot use" in full (from the M007 review; its junction part closed by M018).
- 2026-10-20: collision check: no D-entry or archive overlap. The rows "Read odd-named folders on Windows" and "Detect broken file links on Windows" are distinct and named in Out.
- 2026-10-20: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-20: lessons surfaced: M009 (criteria as stated rules plus listed tests), M018 (Windows cannot make some names, so those tests skip there), M007 (anchor with `\z`).
- 2026-10-20: criteria audit (full mode, fresh Opus reader): 6 findings, all taken. The name list had COM0 and LPT0, which Microsoft's page does not list (22 names, 176 spellings; checked on the page). AC1 and AC2 now say the tests check that the site is unchanged. AC2 adds multi-extension stems and Windows skip wording. T2 line reference corrected to line 112. AC3 states the detail the help text gives. AC4 adds the three-system CI run.
- 2026-10-20: plan gate chose the existing error classes over a new class such as `supplement_error_windows_name`, because callers that catch the documented classes keep working and the message names Windows; falsified by a caller that must tell the Windows refusal apart from the other name refusals.
- 2026-10-20: plan gate chose Microsoft's list (COM1 to COM9, LPT1 to LPT9) over also refusing COM0 and LPT0, because the page lists neither; falsified by a Windows version that refuses a file named `com0`.
- 2026-10-20: changelog: the existing 0.0.0.9000 bullet for `add_report()` and `add_data()` gets the change, with no new bullet.
- 2026-10-20: implement started on branch m023-windows-names.
- 2026-10-20: T1 done. `windows_reserved()` in `R/add-utils.R`; `add_report()` stops after its name check with a message that names Windows. The test failed before the fix (`con` was written). The tests hold their own copy of the 22 names (`helper-files.R`), not the package's. `devtools::test()`: 3184 expectations, 0 failed, 7 skipped.

## Decisions

## Review
