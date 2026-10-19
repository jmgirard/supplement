# M018: The package checks and template renders pass on Windows in CI

- **Status:** review
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

- [x] AC1: `.github/workflows/R-CMD-check.yaml` runs `R CMD check` with Quarto 1.10 installed on each push and pull request, in jobs that include windows-latest, macos-latest, and ubuntu-latest on the R release, with the check's error level at `warning`. Every job of the run on the PR's last commit ends with 0 errors and 0 warnings, and `Rscript -e 'devtools::test()'` reports no failure on the local Mac.
- [x] AC2: In the windows-latest job of that run, no test in the package is skipped with the reason "On CRAN", "quarto is not on PATH", "git is not on PATH", "git --version fails", "knitr cannot be loaded", or "rmarkdown cannot be loaded", as recorded in testthat's results for that job.
- [x] AC3: The test "a full render with R unreachable runs no report code" has no Windows skip, runs without a skip and passes in the windows-latest job of that run, and in the same environment shows that R cannot be reached: a page with an R chunk and no stored output fails to render there.
- [x] AC4: Both render tests that assert `docs/.nojekyll` exists (in `tests/testthat/test-template.R` and `tests/testthat/test-create-supplement.R`) run without a skip and pass in the windows-latest job of that run.
- [x] AC5: The data table shows `2.1 GB` for a listed file of 2,147,483,649 bytes, `4.3 GB` for one of 4,294,967,297 bytes, and `1.0 GB` for one of 1,000,000,000 bytes, in a test that runs without a skip and passes in every job of that run.
- [x] AC6: On Windows, `is_link()` is TRUE for a junction made by `Sys.junction()`. `create_supplement()` refuses a junction at each template folder path, `add_report()` refuses one as `analyses/`, and `add_data()` refuses one as `data/`, each with `supplement_error_file_exists`. These tests run without a skip and pass in the windows-latest job of that run.
- [x] AC7: On Windows, `create_supplement()` given a path that ends in `\`, `\\`, or `\/` makes the same set of relative file paths as for the same path without that ending, in a test that runs without a skip and passes in the windows-latest job of that run. This is a guard: it may pass with no code change.

## Coverage

- AC1 → T1, T2, T8
- AC2 → T1
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6
- AC7 → T7

## Tasks

- [x] T1: Add `.github/workflows/R-CMD-check.yaml` from the usethis check-standard shape, cut to R release on the three runners, with `quarto-dev/quarto-actions/setup` pinned to a 1.10 release, `NOT_CRAN: true`, and `error-on: '"warning"'`. Add a step that runs the tests with a reporter whose results list each skip and its reason, prints them, and fails the job on a reason AC2 names. Add `^\.github$` to `.Rbuildignore`. Append D-016 (GitHub Actions on three systems; coverage job deferred). Push the branch and read the first run.
- [x] T2: Sort the first run's Windows failures that T3 to T7 do not cover. Fix each one that takes one task or less here. Give a bigger one `skip_on_os("windows")` with a reason that names a new candidate row, and add that row (search first). One work-log line per failure.
- [x] T3: Make the no-R test work on Windows (`tests/testthat/test-template.R:66`). Replace `env -i` and the `/usr/bin` paths with a way that works on every system, such as `QUARTO_R` set to a stub that records each call and exits 1, with PATH trimmed; Quarto on Windows also finds R through the registry. Add the same-environment proof from AC3. On the Mac, remove one `_freeze/` file and confirm the test fails, then restore it.
- [x] T4: Confirm in the windows-latest job that both `.nojekyll` render tests run and pass; fix `inst/template/_scripts/nojekyll.ts` if they fail.
- [x] T5: Add the 2,147,483,649 and 4,294,967,297 byte cases to the size test in `tests/testthat/test-shortcodes.R` (`size_cases`, `write_size_fixture()`). On Windows, mark the fixture sparse (`fsutil sparse setflag`) where it can, so the job does not write gigabytes. If `file_size()` in `inst/template/_extensions/supplement/supplement.lua` fails or wraps there, fall back to counting the bytes by reading the file in blocks.
- [x] T6: Add Windows tests that make junctions with `Sys.junction()` at each template folder path, at `analyses/`, and at `data/`. If `Sys.readlink()` returns `""` for a junction, change `is_link()` in `R/supplement-yml.R` so it finds one, for example by comparing `normalizePath()` of the path with that of its parent plus its base name.
- [x] T7: Add a Windows test in `tests/testthat/test-create-supplement.R` for paths that end in `\`, `\\`, and `\/`, comparing the relative file list with the one for the plain path.
- [x] T8: Add a NEWS.md entry for each user-visible fix. Update DESIGN.md: the CI workflow under Architecture, and remove the junction sentence from the "Release edge cases" Known issues entry if T6 fixes it. Run the `verify` slot and `devtools::check()` on the Mac.

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
- 2026-10-19: T3 approach: `QUARTO_R` set to an empty folder, with `R_HOME` unset, in place of `env -i` and a trimmed PATH, because Quarto 1.10's `rBinaryPath()` reads `QUARTO_R` before R_HOME, PATH, and the Windows registry (read in `/Applications/quarto/bin/quarto.js`); the same-environment proof renders `analyses/unfrozen.qmd` and matches "Unable to locate an installed version of R". On the Mac, removing `_freeze/analyses/example/execute-results` made the test fail at its render status, with that message; restored.
- 2026-10-19: T5 tests: added the 2,147,483,649 and 4,294,967,297 byte cases; on Windows the fixture is made sparse with `fsutil sparse setflag` and `fsutil file seteof`. Passes on the Mac; the Lua fallback waits on the Windows result.
- 2026-10-19: T6, T7 tests added (Windows only: junctions at each template folder, `analyses/`, and `data/`; trailing `\`, `\\`, `\/`); they skip on the Mac as "On Mac". DESIGN.md Architecture names the workflow (part of T8). Checkpoint: waiting on the first full CI run (39287132430).
- 2026-10-19: run 39287132430: macOS and Ubuntu pass; Windows has 33 failures, and the skip list shows no skip for a missing tool. Confirmed on Windows: `is_link()` is FALSE for a junction, and `add_data()`, `add_report()`, and `create_supplement()` write through it (T6); the data table shows "-1 B" for 2 GiB plus one and 4 GiB plus one, because `seek("end")` gives -1 (T5); a `create_supplement()` junction test missed the `_extensions` folder (test fixed).
- 2026-10-19: T6 fix: on Windows `is_link()` also counts a path that its parent lists but that does not exist, or that resolves to a place other than its parent plus its name (`is_reparse_point()`); this also catches a file symbolic link to a missing target, which `release_supplement()` read as "Could not read" (test-release-supplement.R:468). T5 fix: when `seek("end")` gives nil or a negative number, `file_size()` counts the bytes in 1 MiB blocks.
- 2026-10-19: T2, small fixes: `.gitattributes` keeps LF in every checkout, because the Windows checkout wrote CRLF into `inst/template/_supplement.yml` (test-yaml-insert.R:314); `check_git_files()` skips `file.info()` for a name that is not valid UTF-8 on Windows, where it stopped (test-check-supplement.R:140), and reads `is_link()` only for large files; test names that Windows does not allow are left out on Windows (test-add-data.R:166, test-check-supplement.R:237); the put-back test writes its fixture with `writeBin()` (test-release-supplement.R:581). Open: an extra broken-link row for `docs/analyses/example.html` on Windows (test-check-supplement.R:70); the test now prints the row.
- 2026-10-19: runs 39290483579 and 39294481647: Windows down to 4 failures, 2 causes. (a) A file symbolic link to a missing file reads on Windows as an existing file: `file.exists()` TRUE, `file.info()$isdir` FALSE, `normalizePath()` gives the link's own path, `file.access(, 4)` 0; base R cannot tell it from a file, and a `file.info()` check on it warns. Over the one-task bar (T2): the missing-target case moved to its own test, which skips on Windows with a comment naming the new candidate row "Windows file links"; the link-to-a-present-file case still runs there. (b) The Windows render of the example report leaves `docs/analyses/example_files/` out, so `example.html` links a missing figure (test-check-supplement.R:70); the test now prints the `analyses/`, `_freeze/`, and `docs/` listings and the render output to find where the figure went.
- 2026-10-19: run 39298613107: the figure is in `_freeze/analyses/example/figure-html/`, and Quarto warned "File 'C:\Users\RUNNER~1\…\analyses\example_files\figure-html\bootstrap-1.png' was not found". The runner's temporary folder holds the 8.3 short name `RUNNER~1`. Fix in the test helpers: `run_in()` and `run_split()` run commands from `normalizePath()` of the folder (`long_dir()`); "report pages carry the site navbar and stored output" now also asserts that the figure is in `docs/`. The diagnostic listing is removed. The other 3 failures are gone; the skip list holds only "On Windows" (16) and "the disk is case-insensitive" (1) on Windows.
- 2026-10-19: T8 docs (commit ac776ad): NEWS.md entry "Fixes on Windows" (junction refusal, sizes of 2 GiB or more, non-UTF-8 git names), each from a failure seen in run 39287132430 or 39290483579; DESIGN.md Architecture describes the Windows branch of `is_link()`, and the "Release edge cases" Known issues entry names the file link to a missing file in place of the junction.
- 2026-10-19: run 39302146526 (head 2c2756c, the short-name fix; the docs commits after it change no code): all three jobs pass, Windows `R CMD check` Status OK with FAIL 0, WARN 0, SKIP 21; the Windows skip list has only "On Windows" (16), "the disk is case-insensitive" (1), "the file can still be read, as for root" (1), and "~ does not follow HOME" (1); the no-R, `.nojekyll`, size, junction, and trailing-backslash tests are not in it. T1 to T7 checked off. Local `devtools::test()` (testthat 3.3.2): 248 tests, 0 failed, 5 skipped.
- 2026-10-19: claim audit: 31 claims read, 3 corrected — .github/workflows/R-CMD-check.yaml (the skip list missed the reason "git is not on the PATH" from test-check-supplement.R:433; added, and the comment now says it fails on the listed reasons), R/supplement-yml.R (`is_reparse_point()` comment: both tests apply after the parent lists the name, letter case ignored), tests/testthat/test-release-supplement.R (`expect_link_refused()` comment narrowed to what `state()` compares).
- 2026-10-19: `devtools::document()` changed only `Config/roxygen2/version` (8.1.0 to 8.1.1, the roxygen2 installed on the Mac); committed so `document()` gives no diff. Checkpoint: `devtools::check()` on the Mac is running; T8 waits on it.
- 2026-10-19: `devtools::check()` on the Mac (tree at ac776ad plus the roxygen stamp): 0 errors, 0 warnings, 0 notes. T8 checked off; status set to review. The last pushed CI run (39302146526) is on 2c2756c; review pushes the later commits and waits on CI for the PR head.
- 2026-10-19: review deviation: pushed the branch at review start (CI run 39307109221 on 9d8364d) to get Windows evidence on the final code before the merge question; the question set allowed early pushes, and the workflow runs on push.
- 2026-10-19: correction to the plan line "1 GB fixture copied into `docs/` refuted at plan": it was wrong. Quarto copies each file the data table links into `docs/`; on the Mac `docs/sizes/f.bin` for a 2 GiB fixture exists and uses 4 KB. The item goes to the new candidate row "Windows large data files".
- 2026-10-19: review fix-now on the branch: the Windows `is_link()` drops a drive root's separator before the join (diff-bug #1), filters names that are not valid UTF-8 before `tolower()` (prior-review #1); the Lua byte count gives nil on a read error; the size fixture falls back to the seek write when fsutil fails; the skip list also matches `{knitr}` and `{rmarkdown}` and fails when no expectation passed; NEWS wording; two comments and the `check_supplement()` help.

## Decisions

## Review

- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: Windows `is_link()` joins a drive root as `D://data`, so a site at `D:\` has its `data/` and `analyses/` refused as links — fix now, fixed d727c59
- diff-bug #2: the 8.3 short-name render problem is hidden by `long_dir()` and not recorded — follow-up, new candidate row "Windows short folder names"
- diff-bug #3: a listed name that `file.exists()` cannot read (trailing space or `.`, a path over 260 characters) counts as a link on Windows — follow-up, added to candidate row "Windows file links"
- diff-bug #4: NEWS "as they do for a link" reads as if links were refused on Windows before — fix now (wording now "as they already did on other systems for a link"), fixed d727c59
- diff-bug #5: on Windows a git name that is not valid UTF-8 gets no size and no skipped note — reject, false: Windows file names are UTF-16, so such a name can come only from the git index and has no file on disk to measure, as for a staged file that was deleted on any system
- diff-bug #6: a read error in the Lua byte count gives a partial size — fix now (nil on a read error), fixed d727c59
- diff-bug #7: the Lua byte count reads each file of 2 GiB or more on every Windows render, and the plan's one-minute falsifier was not measured — follow-up, new candidate row "Windows large data files"
- diff-bug #8: the skip-list step passes when every test skips for a reason not on its list — fix now (fails when no expectation passed), fixed d727c59; its other part (the step reads a second test run, not the R CMD check run) — reject, false: AC2 names testthat's results for that job, which this run is
- diff-bug #9: the size fixture stops when fsutil fails, for example without admin rights — fix now (falls back to the seek write), fixed d727c59
- diff-bug #10: the no-R test matches Quarto's exact message — reject, planned change: the rulebook's failure-identity rule asks the test to name which failure
- diff-bug #11: `is_link()` otherwise sound (names, empty input, NA, mapped drives, UNC, relative paths) — noted, requests nothing
- blame-history #1: the missing-target link case loses its test on Windows — follow-up, candidate row "Windows file links" (narrowed: its stop comes in `read_outputs()` before the writes, and no Windows test checks that nothing is written)
- blame-history #2: same as diff-bug #5 — reject, false (reason above)
- blame-history #3: the skip list matches "knitr cannot be loaded", but testthat 3.3.2 writes "{knitr} is not installed" — fix now (matches `{knitr}` and `{rmarkdown}`), fixed d727c59
- blame-history #4: the short-name figure problem has no tracking entry — follow-up, candidate row "Windows short folder names"
- blame-history #5: the Lua byte count runs only on Windows — reject, false: the windows-latest job runs it on every push, and AC5 reads that job
- blame-history #6: case-only and trailing-dot names untested on Windows; one listing per path — follow-up for trailing dots, candidate row "Windows file links"; the listing cost is reject, style
- blame-history #7: the "Windows check" row is still open, and nothing tests `nojekyll.ts` with a `C:\` path — reject, false: the row graduates at post-merge hygiene, and the two `.nojekyll` render tests pass in the windows-latest job, where Quarto passes a `C:\` output folder
- prior-review #1: `tolower()` stops on a sibling name that is not valid UTF-8, so one such name breaks `is_link()` for the folder (the M008 Latin-1 lesson) — fix now (such names are filtered first), fixed d727c59
- prior-review #2: the M009 dangling-output refusal stays open on Windows — follow-up, candidate row "Windows file links"
- prior-review #3: same as diff-bug #5 — reject, false (reason above)
- prior-review #4: the 2.1 GB and 4.3 GB fixtures are copied into `docs/` (M004 diff-bug #6) — follow-up, candidate row "Windows large data files"; the plan line that called this refuted is corrected in the work log
- prior-review #5: the CI skip check does not flag the Windows skip of the missing-target test — reject, planned change: the plan gate chose a Windows skip that names a candidate row for a failure bigger than one task
- prior-review #6: the `QUARTO_R` claim was not verified — reject, false: `rBinaryPath()` in Quarto 1.10.19's `quarto.js` reads `QUARTO_R` first, and the blame-history reviewer ran it with R on PATH and saw "Unable to locate an installed version of R"
- ripple #1 to #5: the "Windows check" and "Windows-safe names" rows state facts the branch changed — reject, planned change: post-merge hygiene graduates "Windows check" and narrows "Windows-safe names"
- ripple #6: `cairn/PROFILE.md` says CI uses the usethis pair with test-coverage — reject, planned change: the user chose three systems on the R release and no coverage job at the plan gate (D-016, candidate row "coverage report")
- ripple #7: the `path_occupied()` comment says `file.exists()` is FALSE for a link to a missing target — fix now (comment names the Windows case), fixed d727c59
- ripple #8: the M005 lesson's `!is.na(link) && nzchar(link)` misses Windows junctions — reject, false: the lesson is about the NA case, which still holds; a Windows lesson is captured at hygiene
- ripple #9: the `check_supplement()` help says only symbolic links are left out of the large-file check — fix now (names the Windows junction), fixed d727c59
- claim audit (implement step 7): 31 claims read, 3 corrected (work log)
- AC1 evidence: `.github/workflows/R-CMD-check.yaml` triggers on `push` and `pull_request`, its matrix holds windows-latest, macos-latest, and ubuntu-latest on R `release`, it installs Quarto 1.10.19, and it sets `error-on: '"warning"'`. CI run 39308502382 on d727c59: all three jobs succeed, each with R CMD check "Status: OK" (0 errors, 0 warnings, 0 notes) and testthat FAIL 0. The commits after d727c59 change only `cairn/milestones/M018-windows-check.md` (`git diff --stat d727c59..HEAD`); step 8 waits for green on the PR's last commit before the merge. Local `devtools::test()` after the fix-now commit: 248 tests, 0 failed, 0 errors, 5 skipped.
- AC2 evidence: the windows-latest job of run 39308502382 ran 248 tests (2702 expectations passed) under `testthat::test_local()`, and its skip list holds 19 skips: "On Windows" (16), "the disk is case-insensitive" (1), "the file can still be read, as for root" (1), "~ does not follow HOME" (1). None is "On CRAN", "quarto is not on PATH", "git is not on PATH", "git --version fails", "knitr cannot be loaded", or "rmarkdown cannot be loaded", and none names knitr or rmarkdown in any form.
- AC3 evidence: `tests/testthat/test-template.R` "a full render with R unreachable runs no report code" calls only `skip_if_no_quarto()` (no `skip_on_os`); it is not in the windows-latest skip list of run 39308502382, and that job has FAIL 0, so it ran and passed. In the same `QUARTO_R` (empty folder) and unset `R_HOME` environment it renders `analyses/unfrozen.qmd` and asserts a non-zero status and "Unable to locate an installed version of R". On the Mac, removing `_freeze/analyses/example/execute-results` made it fail at its render status (work log).
- AC4 evidence: the two render tests that assert `docs/.nojekyll`, "a new site renders and holds its setup files" (`tests/testthat/test-template.R:10`) and "a site made with repo renders" (`tests/testthat/test-create-supplement.R:351`), call only `skip_if_no_quarto()`; neither is in the windows-latest skip list of run 39308502382, whose job has FAIL 0.
- AC5 evidence: `size_cases` in `tests/testthat/test-shortcodes.R` maps "2147483649" to "2.1 GB", "4294967297" to "4.3 GB", and "1000000000" to "1.0 GB", and "the data table lists each file with its size and a page-relative link" asserts each row's size cell equals that text on two pages. The test calls only `skip_if_no_quarto(needs_r = FALSE)`; it is in no job's skip list in run 39308502382, and all three jobs have FAIL 0. Before the Lua fallback, the Windows job showed "-1 B" for the two large cases (run 39287132430).
- AC6 evidence: three Windows-only tests make junctions with `Sys.junction()`: `tests/testthat/test-create-supplement.R:205` (each template folder path, the list checked as `_extensions`, `_extensions/supplement`, `_scripts`, `analyses`, `data`; asserts `is_link()` TRUE and `supplement_error_file_exists`, and the target stays empty), `tests/testthat/test-add-report.R:274` (`analyses/`), and `tests/testthat/test-add-data.R:273` (`data/`), each with `supplement_error_file_exists` and the outside folder unchanged. They skip only on Mac, Linux, and Solaris; none is in the windows-latest skip list of run 39308502382, whose job has FAIL 0. Before the `is_link()` change they failed there (run 39287132430: `is_link()` FALSE, files written into the target).
- AC7 evidence: `tests/testthat/test-create-supplement.R:221` "on Windows, a trailing backslash makes the same files as no trailing separator" makes a plain site, then one for each ending `\`, `\\`, and `\/`, and asserts the sorted relative file list is identical to the plain one (which equals `template_tracked`). It skips only on Mac, Linux, and Solaris; it is not in the windows-latest skip list of run 39308502382, whose job has FAIL 0. It passed on its first Windows run with no code change, as the criterion allows for a guard.
- consistency gate: `cairn_validate.py` all checks passed; `devtools::document()` gives no diff; no README.Rmd and no pkgdown site; NEWS.md has the "Fixes on Windows" entry with no milestone number; new top-level `.github` and `.gitattributes` have `.Rbuildignore` entries; `devtools::check()` on the Mac at d727c59: 0 errors, 0 warnings, 0 notes; no principle changed, so no `cairn_impact` run. Findings: 9 fixed on the branch, 8 sent to candidate rows, 17 rejected, 1 noted; 0 substantive amendments.
