# M023: add_report() and add_data() refuse names that Windows cannot use

- **Status:** review
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

- [x] AC1: If `name` is a name that Windows reserves for a device, in any letter case, `add_report()` stops and changes no file in the site. The 22 names are `CON`, `PRN`, `AUX`, `NUL`, `COM1` to `COM9`, and `LPT1` to `LPT9`. The error has the class `supplement_error_report_name`, and its message names Windows. A test in `tests/testthat/test-add-report.R` runs each of the 176 letter-case spellings of the 22 names. For each one, it checks the error class and checks that the site's files are unchanged. In the same test, `add_report()` writes the reports `console`, `com10`, `com0`, `lpt`, and `nul_x` and adds each one to the Analyses menu.
- [x] AC2: If the base name of `file` ends in `.`, `add_data()` stops before it copies or changes any file in the site. The stem of a base name is its part before the first `.`, or the whole name when it has no `.`. If the stem is one of the 22 names of AC1, in any letter case, `add_data()` also stops. Both errors have the class `supplement_error_file_name`, and their messages name Windows. A test in `tests/testthat/test-add-data.R` runs each of the 176 spellings alone and followed by `.csv`, and also `nul.tar.gz` and `CoN.TXT`. For the trailing `.`, it runs `data.`, `a.b.`, and `scores.csv.`. Each case checks the error class and that the site's files are unchanged. These cases are skipped on Windows, which cannot make such files. In the same test, on every system, `add_data()` copies `console.csv`, `com10.csv`, `x.con`, and `nul_x.csv` and adds each one to the `data` list.
- [x] AC3: The help pages `man/add_report.Rd` and `man/add_data.Rd` state the rules of AC1 and AC2 in the `name` and `file` argument entries and in the Errors entries for `supplement_error_report_name` and `supplement_error_file_name`. The entries list the device names and say that letter case does not matter. The `add_data()` entries also say that an extension does not matter and that a name that ends in `.` is refused. The `NEWS.md` entry for `add_report()` and `add_data()` says that both functions refuse names that Windows cannot use.
- [ ] AC4: `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1
- AC2 → T1, T2
- AC3 → T3
- AC4 → T1, T2, T3, T4

## Tasks

- [x] T1: In `R/add-utils.R`, add a helper `windows_reserved(x)`. If `tolower(x)` is one of the 22 device names, it returns TRUE. A code comment cites Microsoft's page "Naming Files, Paths, and Namespaces". In `R/add-report.R`, right after the name check (line 82), stop with `supplement_error_report_name` and a message that names Windows. Add the AC1 tests to `test-add-report.R`.
- [x] T2: In `R/add-data.R`, right after the Markdown name check (line 112), stop with `supplement_error_file_name` and a message that names Windows. The check fires for a base name that ends in `.` or whose stem gives TRUE from `windows_reserved()`. Add the AC2 tests to `test-add-data.R`. Make each source file in its own folder (`source_file()` does), because macOS ignores letter case.
- [x] T3: Edit the roxygen text of both functions and run `devtools::document()`. Edit the NEWS.md bullet for `add_report()` and `add_data()`, because version 0.0.0.9000 is not released.
- [x] T4: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

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
- 2026-10-20: T2 done. `add_data()` stops after the Markdown name check with two messages, one for a final `.` and one for a device stem; the stem is `sub("\\..*", "", base)`. The test failed before the fix (`con` was copied). The 7 skips of `devtools::test()` are the existing OS-specific tests; 4262 expectations, 0 failed.
- 2026-10-20: T3 done. Roxygen `@param` and Errors entries of both functions list the 22 names; `devtools::document()` rewrote `man/add_report.Rd` and `man/add_data.Rd`. The NEWS.md bullet gained two sentences. README.md and the template `_README.md` state no name rules, so they are unchanged. DESIGN.md Architecture names `windows_reserved()`.
- 2026-10-20: T4 done at 76780de: `devtools::test()` 4262 expectations, 0 failed, 7 skipped; `devtools::check()` 0 errors, 0 warnings, 0 notes. The R-CMD-check workflow runs at the PR.
- 2026-10-20: claim audit: 20 claims read, 2 corrected — R/add-data.R (the `supplement_error_file_name` entry now names a leading `.` and `_` at both ends), tests/testthat/helper-files.R ("22 ASCII names"); a test comment in test-add-report.R reworded. After the fixes, `devtools::document()` rewrote `man/add_data.Rd`; the two test files pass (595 and 1325 expectations, 0 failed).
- 2026-10-20: implement complete; status set to review.

## Decisions

## Review

Evidence at e6c82c9 (the review fixes included), macOS, R 4.6, 2026-10-20.

- AC1: "a name that Windows reserves for a device stops and writes nothing" in `test-add-report.R`: 361 expectations, 0 failed, not skipped. It runs the 176 spellings (length checked), the class, a message match on "Windows", the site's `folder_state()` unchanged, and the five accepted names in the Analyses menu.
- AC2: "a file name that Windows cannot use stops" in `test-add-data.R`: 1078 expectations, 0 failed, not skipped on macOS. It runs 176 spellings alone and with `.csv`, `nul.tar.gz`, `CoN.TXT`, `data.`, `a.b.`, and `scores.csv.`, with the class, a "Windows" message match, and `folder_state()` unchanged. The four accepted names run first, on every system; `skip_on_os("windows")` then names its reason.
- AC3: `man/add_report.Rd` lines 12-14 and 57-58, and `man/add_data.Rd` lines 15-19 and 58-63, list the 22 names and say letter case does not matter; the `add_data()` entries also say any extension and a final `.`. NEWS.md lines 22-24 say both functions refuse names that Windows reserves for a device.
- AC4 (local part): `devtools::test()` 4262 expectations, 0 failed, 7 skipped (the existing OS-specific tests); `devtools::check()` 0 errors, 0 warnings, 0 notes (4 min 49 s). The R-CMD-check workflow on Windows, macOS, and Ubuntu runs at the PR, before the merge.
- Consistency gate: `cairn_validate.py` all checks passed; `devtools::document()` gives no diff; no README.Rmd and no pkgdown site; the NEWS.md entry is there with no milestone numbers; no new top-level files. No principle changed, so no `cairn_impact` run.
- Earlier pass at 4554b4f (before the review fixes): the same counts, document no diff, check 0/0/0.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: `con.rds` now gives `supplement_error_file_name` where main gave `supplement_error_ignored_file` — reject (planned change: name checks already ran before the type check, as `_x_.rds` shows on main).
- diff-bug #2: `add_report("con")` with an existing `analyses/con.qmd` gives the name class, not `supplement_error_file_exists` — reject (planned change: name checks run before file checks).
- diff-bug #3: the device message said the name "starts with" `con`, which `console.csv` also does — fix now, fixed e6c82c9 (it now names the part before the first `.`).
- diff-bug #4: Windows CI never runs the `add_data()` refusals — reject (planned change: AC2 skips them on Windows, which cannot make the files).
- diff-bug #5: the `add_data()` messages do not end "Nothing was written." — reject (style; it matches the function's existing name message).
- blame-history #1: whether Windows refuses a file named `com0` was not checked — reject (false as a defect: Microsoft's list omits COM0; the AC1 test writes `com0.qmd` on the Windows CI job, which runs before the merge).
- blame-history #2: the comment should say why the superscript names are left out — fix now, fixed e6c82c9.
- blame-history #3: a broken roxygen line wrap in the `supplement_error_file_name` entry — fix now, fixed e6c82c9.
- blame-history #4: `x.` was accepted before and is now refused — reject (planned change, AC2).
- prior-review #1: the candidate row "Refuse names that Windows cannot use" is still in the ROADMAP — reject (planned change: post-merge hygiene graduates it).
- prior-review #2: the Windows guard in the `add_data()` test was a silent `if`, not a skip with a reason (M018 review) — fix now, fixed e6c82c9 (`skip_on_os()` after the accepted names).
- ripple #1: ROADMAP.md line 19 says the functions accept these names — reject (planned change: the row graduates at hygiene).
- ripple #2: `inst/template/_README.md` and the `inst/template/_supplement.yml` comment state the file-name rule without the Windows refusals — fix now, fixed e6c82c9.
