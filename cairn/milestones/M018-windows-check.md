# M018: The package checks and template renders pass on Windows in CI

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — fixes how `create_supplement()`, `add_report()`, `add_data()`, and the data table shortcode behave for Windows users
- **Branch/PR:** m018-windows-check

## Goal

`R CMD check`, with the template render tests, runs on Windows, macOS, and Ubuntu in GitHub Actions and passes on all three.

## Scope

**In:** a GitHub Actions workflow `.github/workflows/R-CMD-check.yaml` (the usethis check-standard shape, R release on windows-latest, macos-latest, and ubuntu-latest, Quarto 1.10, `NOT_CRAN=true`) and its `.Rbuildignore` entry; a workflow step that prints each skipped test and its reason; fixes for what fails on Windows, under the gate rule in T2; the no-R render test made to run on Windows; data table sizes for files of 2 GiB and 4 GiB plus one byte; `is_link()` finding a Windows junction; Windows tests for trailing `\` separators; NEWS.md, DESIGN.md, and a D-entry for the CI choice.

**Out:**
- Windows reserved names (`con`) and names that end in `.` in `add_report()` and `add_data()` → candidate row "Windows-safe names" (its junction sentence moves here).
- Directory symbolic links on Windows beyond the existing link tests, which now run there → not planned.
- A coverage job that uploads to Codecov → new candidate row "coverage report".
- The `file.access()` folder check in `read_outputs()` on Windows → stays in DESIGN.md Known issues ("Release edge cases").
- The cause of the template test flake → candidate row "template test flake"; a CI hit is recorded there.
- Jobs on R devel or older R releases → not planned.

## Acceptance criteria

- [ ] AC1: `.github/workflows/R-CMD-check.yaml` runs `R CMD check` with Quarto 1.10 installed on each push and pull request, in jobs that include windows-latest, macos-latest, and ubuntu-latest on the R release, with the check's error level at `warning`. Every job of the run on the PR's last commit ends with 0 errors and 0 warnings, and `Rscript -e 'devtools::test()'` reports no failure on the local Mac.
- [ ] AC2: In the windows-latest job of that run, no test in the package is skipped with the reason "On CRAN", "quarto is not on PATH", "git is not on PATH", "git --version fails", "knitr cannot be loaded", or "rmarkdown cannot be loaded", as recorded in testthat's results for that job.
- [ ] AC3: The test "a full render with R unreachable runs no report code" has no Windows skip, runs without a skip and passes in the windows-latest job of that run, and in the same environment shows that R cannot be reached: a page with an R chunk and no stored output fails to render there.
- [ ] AC4: Both render tests that assert `docs/.nojekyll` exists (in `tests/testthat/test-template.R` and `tests/testthat/test-create-supplement.R`) run without a skip and pass in the windows-latest job of that run.
- [ ] AC5: The data table shows `2.1 GB` for a listed file of 2,147,483,649 bytes, `4.3 GB` for one of 4,294,967,297 bytes, and `1.0 GB` for one of 1,000,000,000 bytes, in a test that runs without a skip and passes in every job of that run.
- [ ] AC6: On Windows, `is_link()` is TRUE for a junction made by `Sys.junction()`. `create_supplement()` refuses a junction at each template folder path, `add_report()` refuses one as `analyses/`, and `add_data()` refuses one as `data/`, each with `supplement_error_file_exists`. These tests run without a skip and pass in the windows-latest job of that run.
- [ ] AC7: On Windows, `create_supplement()` given a path that ends in `\`, `\\`, or `\/` makes the same set of relative file paths as for the same path without that ending, in a test that runs without a skip and passes in the windows-latest job of that run. This is a guard: it may pass with no code change.

## Coverage

- AC1 → T1, T2, T8
- AC2 → T1
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T7

## Tasks

- [ ] T1: Add `.github/workflows/R-CMD-check.yaml` from the usethis check-standard shape, cut to R release on the three runners, with `quarto-dev/quarto-actions/setup` pinned to a 1.10 release, `NOT_CRAN: true`, and `error-on: '"warning"'`. Add a step that runs the tests with a reporter whose results list each skip and its reason, prints them, and fails the job on a reason AC2 names. Add `^\.github$` to `.Rbuildignore`. Append D-016 (GitHub Actions on three systems; coverage job deferred). Push the branch and read the first run.
- [ ] T2: Sort the first run's Windows failures that T3 to T7 do not cover. Fix each one that takes one task or less here. Give a bigger one `skip_on_os("windows")` with a reason that names a new candidate row, and add that row (search first). One work-log line per failure.
- [ ] T3: Make the no-R test work on Windows (`tests/testthat/test-template.R:66`). Replace `env -i` and the `/usr/bin` paths with a way that works on every system, such as `QUARTO_R` set to a stub that records each call and exits 1, with PATH trimmed; Quarto on Windows also finds R through the registry. Add the same-environment proof from AC3. On the Mac, remove one `_freeze/` file and confirm the test fails, then restore it.
- [ ] T4: Confirm in the windows-latest job that both `.nojekyll` render tests run and pass; fix `inst/template/_scripts/nojekyll.ts` if they fail.
- [ ] T5: Add the 2,147,483,649 and 4,294,967,297 byte cases to the size test in `tests/testthat/test-shortcodes.R` (`size_cases`, `write_size_fixture()`). On Windows, mark the fixture sparse (`fsutil sparse setflag`) where it can, so the job does not write gigabytes. If `file_size()` in `inst/template/_extensions/supplement/supplement.lua` fails or wraps there, fall back to counting the bytes by reading the file in blocks.
- [ ] T6: Add Windows tests that make junctions with `Sys.junction()` at each template folder path, at `analyses/`, and at `data/`. If `Sys.readlink()` returns `""` for a junction, change `is_link()` in `R/supplement-yml.R` so it finds one, for example by comparing `normalizePath()` of the path with that of its parent plus its base name.
- [ ] T7: Add a Windows test in `tests/testthat/test-create-supplement.R` for paths that end in `\`, `\\`, and `\/`, comparing the relative file list with the one for the plain path.
- [ ] T8: Add a NEWS.md entry for each user-visible fix. Update DESIGN.md: the CI workflow under Architecture, and remove the junction sentence from the "Release edge cases" Known issues entry if T6 fixes it. Run the `verify` slot and `devtools::check()` on the Mac.

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: milestone — adds CI and changes running code across several files, more than one sitting.
- 2026-10-19: candidate row "Windows check" absorbed in full; "Windows-safe names" absorbed in part (its junction sentence; reserved names and trailing dots stay there).
- 2026-10-19: collision sweep: no decision entry or archived milestone covers CI or Windows; M003 fixed `nojekyll.ts` for Windows but never ran on Windows; the DESIGN.md "Release edge cases" junction note is covered by T6.
- 2026-10-19: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-19: lessons harvested: M014 (`skip_on_cran()` skips unless `NOT_CRAN=true`, so the workflow sets it), M011 (`writeLines()` writes CRLF on Windows; byte-exact edits use `writeBin()`), M009 (criteria as stated rules plus listed tests).
- 2026-10-19: the row's "1 GB fixture copied into `docs/`" item refuted at plan: the size fixtures live under `sizes/`, and `shortcode_site()` publishes no resources, so nothing is copied.
- 2026-10-19: criteria audit (full mode, fresh Opus reader): 8 findings, all taken. "Passes" now also says "runs without a skip" (AC3 to AC7); AC1 names 0 errors and 0 warnings; AC2 names testthat's exact skip reasons and records them from testthat's results, with the printing step moved to T1; AC3 adds a same-environment proof that R is unreachable, since Windows Quarto finds R through the registry; AC4 names both `.nojekyll` tests; AC5 adds a 4 GiB plus one case for a wrapped size and drops the `docs/` clause, which held already; AC6 covers every template folder, `analyses/`, and `data/`; AC7 covers `\`, `\\`, and `\/` and says it is a guard. Directory symbolic links decided toward the narrower promise (Out).
- 2026-10-19: question set: how to get a Windows run — CI on Windows, macOS, and Ubuntu; implement may push the milestone branch early to run it.
- 2026-10-19: question set: Windows failures outside the listed items — fix those of one task or less here; skip a bigger one on Windows with a reason naming a new candidate row.
- 2026-10-19: question set: Codecov coverage job — not now; new candidate row "coverage report".
- 2026-10-19: plan gate chose GitHub Actions over a run by hand because this Mac cannot run Windows and the profile names check-standard; falsified by the Windows runner lacking a tool the tests need (Quarto, git) with no way to install it.
- 2026-10-19: plan gate chose a block-counting fallback in `file_size()` over stopping the render with a "too large to measure" error, because the size stays exact and the slow path runs only where `seek` fails; falsified by a 4 GiB file taking more than a minute to count on the Windows runner.
- 2026-10-19: implement started on branch m018-windows-check; added `.github/workflows/R-CMD-check.yaml`, the `^\.github$` build-ignore entry, and D-016; the skip list runs the tests a second time with `testthat::test_local()`, because R CMD check prints test output only on failure.
