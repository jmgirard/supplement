<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M037: Report missing tools before site setup

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate -->
- **Surface tier:** user-facing — a new exported function and a changed `create_supplement()` message   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m037-tool-check   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Authors can see which tools a supplement site needs are missing before a first render fails.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** a new exported `check_tools()` in `R/check-tools.R`, with no arguments. It looks for Quarto, knitr, rmarkdown, git, and gh. It lists a GitHub account and a Zenodo account as reminders. It prints one line per row and returns the rows. `create_supplement()` runs the same lookups after it makes a site and names the problem rows in its closing message. The help page, `README.md`, `NEWS.md`, and `cairn/DESIGN.md` describe the function.

**Out:** Python and Jupyter, which only Python reports need: the candidate row "Record the Python setup of reports". Versions of knitr, rmarkdown, git, and gh: no floor exists to compare them with ("Keep tests within the Suggests floors"). Logging in to check the two accounts: not planned, because calls to web services are out of scope for version 1 (DESIGN.md Purpose & Scope). Tool lookups in `add_report()`, `add_data()`, or `release_supplement()`: not planned.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: `check_tools()` returns, invisibly, a data frame with the character columns `tool`, `status`, and `detail`. It has seven rows in this order: `Quarto`, `knitr`, `rmarkdown`, `git`, `gh`, `GitHub account`, `Zenodo account`. Each `status` is one of `found`, `not on path`, `too old`, `missing`, or `reminder`. The two account rows are always `reminder`. For knitr, rmarkdown, git, and gh, a lookup that finds the tool gives `found`, and one that does not gives `missing`. AC2 and AC3 set the Quarto row. The function prints one message line per row, and the line names the row's tool and status. Tests with mocked lookups cover the found case and the missing case of each of the four tools. They also assert the printed line of one row of each of the five statuses.
- [x] AC2: `check_tools()` looks for Quarto in three places in this order and takes the first place that holds a file. The first place is the system path, as `Sys.which()` searches it from R. The second is the file that the `QUARTO_PATH` environment variable names. The third is the editor list, in this order: RStudio at `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto` (macOS), `<PROGRAMFILES>/RStudio/resources/app/bin/quarto/bin/quarto.exe` (Windows), and `/usr/lib/rstudio/resources/app/bin/quarto/bin/quarto` (Linux). Positron follows at `/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto` (macOS), `<LOCALAPPDATA>/Programs/Positron/resources/app/quarto/bin/quarto.exe` and `<PROGRAMFILES>/Positron/resources/app/quarto/bin/quarto.exe` (Windows), and `/usr/share/positron/resources/app/quarto/bin/quarto` (Linux). A copy on the system path gives `found`. A copy found only in the second or third place gives `not on path`. Its `detail` names the place and says that `quarto render` in a terminal can miss that copy. No copy gives `missing`. A test asserts the editor list for each of the three systems, with `PROGRAMFILES` and `LOCALAPPDATA` mocked. Tests with mocked lookups over temporary folders cover the path, `QUARTO_PATH`, one editor entry, and one `quarto.exe` entry. For the `QUARTO_PATH` copy and the editor copy, they assert that the `detail` names the place and holds `can miss`. They also cover a `QUARTO_PATH` that is unset, empty, names a missing file, or names a folder, and a case where two places hold a copy and the first place wins.
- [x] AC3: `check_tools()` resolves a link to the copy that it takes. It reads the Quarto version from the file `share/version` beside the copy's `bin` folder and compares it as a version number. A version below 1.4.0 gives `too old`. The value 1.4.0 is the `quarto-required` minimum in `inst/template/_extensions/supplement/_extension.yml`. `too old` wins over `not on path`, and the `detail` then also names the place. If `share/version` is missing or holds no version, the row keeps the status from AC2, and its `detail` says that the version is unknown. Tests cover the versions 1.3.450, 1.4.0, and 1.10.0, a version file with no final line break, a missing version file, a version file with other text, and an old copy off the path. A test with a path entry that links to a folder holding `bin/` and `share/version` checks the link case, and it skips on Windows.
- [x] AC4: `check_tools()` runs none of the tools it looks for. `R/check-tools.R` calls none of `system()`, `system2()`, `shell()`, `pipe()`, processx, or callr, and the existing test "git runs only through its helper" in `tests/testthat/test-source.R` passes unchanged over all of `R/`.
- [x] AC5: After `create_supplement()` makes a site, it runs the same lookups. Its closing message adds one line for each row whose status is `missing`, `too old`, or `not on path`. It also adds one line that names `check_tools()`. When no row has one of those statuses, the message has no added line. If the lookups raise an error or a warning, `create_supplement()` still returns `path`, gives no warning, and its message has no added line. Tests with mocked lookups cover a run with one `missing`, one `too old`, and one `not on path` row, a run with only `found` and `reminder` rows, a run whose lookups raise an error, and a run whose lookups raise a warning. Each test checks that the site's files and their bytes equal those of the run with no problem rows.
- [x] AC6: The `check_tools()` help page lists the seven rows and the five statuses. It names the three Quarto places, the editor list, and the version rule. It says that the function runs none of the tools. `README.md` names `check_tools()` in "Start a new site". `NEWS.md` has an entry for `check_tools()` and for the `create_supplement()` message. `cairn/DESIGN.md` names `check_tools()` in Function Families, and its Architecture names `R/check-tools.R` and says that `create_supplement()` runs its lookups.
- [ ] AC7: `Rscript -e 'devtools::document()'` leaves no change, and `Rscript -e 'devtools::test()'` is clean. `devtools::check()` gives 0 errors, 0 warnings, and 0 notes, and CI passes on the PR head.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2, T3, T8
- AC2 → T1, T2, T3
- AC3 → T2, T3, T7, T8, T9
- AC4 → T3, T6
- AC5 → T4
- AC6 → T5, T9
- AC7 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive change is amend-via-gate. -->

- [x] T1: Check each editor path of AC2 against an install (the Positron and Quarto installs on this Mac) or the vendor's own docs or release files. Write one work-log line per path with its source. A path that turns out wrong changes through the amendment protocol.
- [x] T2: Write `tests/testthat/test-check-tools.R` first, for AC1 to AC3. Mock the lookups through small internal helpers with `local_mocked_bindings()` (LESSONS M011). Build version files with `writeBin()` so no line break is added (LESSONS M011).
- [x] T3: Write `R/check-tools.R`: `check_tools()`, the Quarto lookup and its editor list, the version read with `numeric_version()`, and the printed lines through cli. Look programs up with `Sys.which()`, which on Unix runs `which` but no looked-up tool. Add the roxygen help page (AC6 items) and run `devtools::document()`.
- [x] T4: Write the AC5 tests in `tests/testthat/test-create-supplement.R` first, then add the lookups to the closing message at `R/create-supplement.R:113-121`, inside `tryCatch()` for errors and warnings. Existing tests match "Made a supplement site", so they keep passing.
- [x] T5: Update `README.md` ("Start a new site", line 14), `NEWS.md`, and `cairn/DESIGN.md` (Function Families, Architecture). Widen the candidate row "Record the Python setup of reports" to say that `check_tools()` does not look for Python or Jupyter, and add `check_tools()` to the reference list of "Build a package site with pkgdown".
- [x] T6: Run the verify slot, `devtools::check()`, and `tests/testthat/test-source.R` from the source tree.
- [x] T7: Review return 1: make `quarto_version()` read a `share/version` with bytes that are not valid in the locale as no version, with no warning, and add a test for it in `check_tools()` and in `create_supplement()`.
- [x] T8: Pass 1 fix-now items: a real invisibility test, a folder-link case, one line formatter, rename the test helper `quarto_row()`, remove two repeated expectations, the process-start wording in DESIGN.md and the `git_run()` comment, and the README wording.
- [x] T9: Review return 2: read a `share/version` part too big for an R integer as no version with no warning, list the `GitHub account` and `Zenodo account` labels in the help page, and the pass 2 fix-now items (help "system path that R sees", one version-text check, DESIGN.md `tool_problems()` location, `git_run()` as the one `system2()` call).

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-22: created by /milestone-plan.
- 2026-10-22: tier check: not run — work named at the question set
- 2026-10-22: idea vet: three concerns, each answered at the question set. Where the report shows: a function that `create_supplement()` also runs and never stops on (chosen). Quarto bundled with RStudio and Positron is off the system path, so a path-only search would call it missing: look on the path, in `QUARTO_PATH`, and in editor folders (chosen). R cannot check the GitHub and Zenodo accounts: list them as reminders (chosen).
- 2026-10-22: question set: work to plan — "Report missing tools before site setup". No outward action or dependency change is foreseen before the merge question.
- 2026-10-22: collision check: absorbs the candidate row "Report missing tools before site setup". No archive or D-entry overlap; D-007 keeps knitr and rmarkdown in Suggests, which the lookups only read. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-22: plan gate chose reading `share/version` over running `quarto --version` because `git_run()` is the package's one process-start site (test-source.R); falsified by a supported Quarto install that has no `share/version` beside `bin/`.
- 2026-10-22: plan chose the name `check_tools()` over `supplement_sitrep()` because it joins the `check_` family and names what it checks; falsified by users who mistake it for `check_supplement()`.
- 2026-10-22: plan chose `not on path` for a `QUARTO_PATH`-only copy as for an editor copy, because a terminal `quarto render` reads only the system path; falsified by a Quarto release whose CLI reads `QUARTO_PATH`.
- 2026-10-22: criteria audit (full, fresh Opus reader): 12 findings, all taken. AC1 limited to the four non-Quarto tools and asserts a printed line per status. `too old` wins over `not on path`. Editor folders listed in AC2 with a per-system list test, a `quarto.exe` probe, and four `QUARTO_PATH` shapes. Version probes 1.3.450, 1.10.0, no final line break, and a link probe. AC4 narrowed from "starts no process" to "runs none of the tools", because `Sys.which()` runs `which` on Unix. AC5 probes each of three statuses and a warning. DESIGN.md added to AC6.
- 2026-10-22: lessons harvested: M011 (mock a slow step, `writeBin()` for exact bytes), M018 (`Sys.readlink()` gives `""` on Windows, so the link probe skips there), M007 (cli drops leading spaces in message lines).
- 2026-10-22: implement started on branch m037-tool-check, cut from main at 33ebeba.
- 2026-10-22: T1 path RStudio macOS `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto`: rstudio/rstudio `src/cpp/session/CMakeLists.txt` installs the Quarto folder into `RSTUDIO_INSTALL_RESOURCES/app` on Apple, and `cmake/globals.cmake` sets that to `RStudio.app/Contents/Resources`.
- 2026-10-22: T1 path RStudio Windows `<PROGRAMFILES>/RStudio/resources/app/bin/quarto/bin/quarto.exe`: the same CMake rule installs into `RSTUDIO_INSTALL_BIN` (`resources/app/bin` for the Electron build), and a Posit forum `quarto check` output shows `C:\Program Files\RStudio\resources\app\bin\quarto\bin`.
- 2026-10-22: T1 path RStudio Linux `/usr/lib/rstudio/resources/app/bin/quarto/bin/quarto`: the same CMake rule, and a Posit forum post (Linux Mint) that ran `./quarto --version` there.
- 2026-10-22: T1 path Positron macOS `/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto`: present on this Mac with `share/version` 1.10.18 beside `bin/`.
- 2026-10-22: T1 paths Positron Windows `<LOCALAPPDATA>/Programs/Positron/...` and `<PROGRAMFILES>/Positron/...`: the install roots are from positron.posit.co/add-to-path, and posit-dev/positron `build/lib/quarto.ts` puts `quarto/` at the app root that macOS shows as `Resources/app`, which is `resources/app` in a Windows build.
- 2026-10-22: T1 path Positron Linux `/usr/share/positron/resources/app/quarto/bin/quarto`: posit-dev/positron `build/gulpfile.vscode.linux.ts` installs to `/usr/share/${applicationName}`, and `product.json` sets `applicationName` to `positron`. Not checked on an install.
- 2026-10-22: T1 done: all seven paths match AC2, so no amendment. A standalone Quarto 1.10.19 at `/Applications/quarto` also has `share/version` beside `bin/`.
- 2026-10-22: T2/T3: `tests/testthat/test-check-tools.R` (55 expectations) and `R/check-tools.R`. The lookups go through `tool_which()`, `tool_env()`, `tool_os()`, `package_version_text()`, and `editor_quarto_paths()` for mocking. Package versions come from `read.dcf()` on DESCRIPTION, so no package loads. `quarto_minimum` is a constant, and a test matches it against the extension file. The print test sets `cli.width = 500`, because cli wraps long lines. Plants: a string version compare failed 4 tests (1.10.0 read as too old), and dropping `normalizePath()` failed the link test. `devtools::test(filter = "check-tools|source")` clean.
- 2026-10-22: T4: `tool_problems()` in `R/create-supplement.R` wraps `tool_rows()` in `tryCatch()` for errors and warnings, and the closing message refers to each line as `{tools[i]}`, so cli reads tool text as a value. The help page says so. Two tests in `test-create-supplement.R` mock `tool_rows()`. A plant that dropped the warning handler failed the warning test. `devtools::test(filter = "create-supplement")` clean (188 pass, 2 skips that predate the change).
- 2026-10-22: T5: README "Start a new site", a NEWS entry after the `create_supplement()` entry, DESIGN.md Function Families and Architecture, and the two candidate rows widened ("Build a package site with pkgdown", "Record the Python setup of reports"). `cairn_validate` green.
- 2026-10-22: claim audit: 43 claims read, 3 corrected — R/check-tools.R (the `not on path` bullet now says an older copy there is `too old`; "will not find" became "can miss", because R's path can differ from a terminal's; the `@return` text now says what `detail` holds for each kind of row), plus one optional wording fix in the opening paragraph.
- 2026-10-22: substantive amendment: AC2 says the first place is the system path "as `Sys.which()` searches it from R", the `detail` says a terminal "can miss" the copy (was "will not find"), and the tests assert `can miss` and the place for the `QUARTO_PATH` and editor copies. Cause: claim-audit finding 12. The deliverable the user sees is the same apart from that one phrase, so no stop.
- 2026-10-22: re-audit: AC2 (full) — "will not find" → "can miss" cleared; found "system path" loose (R's path) and no test of the terminal sentence; both fixed in the wording above.
- 2026-10-22: re-audit: AC2 (full) — fixed wording cleared on questions 2, 3, 5, 6; noted "names the place" could mean the category or the path (the tests assert both) and that one precedence pair was tested. Answered with a second precedence test (`QUARTO_PATH` over an editor entry) and no wording change, so no further re-entry.
- 2026-10-22: T6 at 50470ab: `devtools::document()` left no change; full `devtools::test()` FAIL 0, ERR 0, SKIP 8, PASS 4994 (test-source.R ran from the source tree); `devtools::check()` 0 errors, 0 warnings, 0 notes. Status set to review.
- 2026-10-22: review return 1: AC3 fails for a `share/version` whose bytes are not valid in the locale: `grepl()` in `quarto_version()` warns ("input string 1 is invalid in this locale") instead of the row reading "version unknown", and `create_supplement()` then drops every tool line (diff-bug #2). The same pass settled these fix-now items for the return to carry: diff-bug #1 (a real invisibility test), #4 (add a folder-link case), #10 (one line formatter), #11 (rename the test helper `quarto_row()`), #12 and #14 (remove two repeated expectations), blame-history #1/#2 and ripple #1/#2 (DESIGN.md and the `git_run()` comment: the one place the package runs a program itself; `Sys.which()` starts `which` on Unix), ripple #5 (README: missing, too old, or not on path). Follow-up row "Report broken Quarto links on Windows" added.
- 2026-10-22: minor amendment: tasks T7 (review return 1) and T8 (pass 1 fix-now items) added; Coverage AC1 → T8, AC3 → T7, T8.
- 2026-10-22: T7: `quarto_version()` checks that the first line's bytes are ASCII digits, dots, spaces, tabs, or CR before `rawToChar()`, so other bytes read as no version with no warning. A new test covers `check_tools()` and `create_supplement()` with such a file; a plant that dropped the byte check failed it.
- 2026-10-22: T8: `expect_invisible(suppressMessages(check_tools()))`; a folder-link case in the link test; `tool_lines()` formats rows for both functions; test helper renamed `quarto_result()`; two repeated expectations removed; DESIGN.md and the `git_run()` comment say "runs a program itself" and that `Sys.which()` starts `which` on Unix; README names missing, too old, and not on path. `devtools::test(filter = "check-tools|create-supplement|source")` clean (256 pass, 2 skips that predate the change).
- 2026-10-22: claim audit: 11 claims read, 2 corrected — R/check-supplement.R (the `git_run()` comment names `create_supplement()` and the shell that `Sys.which()` starts), R/check-tools.R (the byte-check comment names the `trimws()` error as well as the `grepl()` warning). The reader also noted that the folder-link case passes without `normalizePath()`; the file-link case is the one that fails without it (pass 1 plant).
- 2026-10-22: verify at bdb6a0d (9d462e6 changes comments only): `devtools::document()` no change; full `devtools::test()` FAIL 0, ERR 0, SKIP 8, PASS 4999; `devtools::check()` 0 errors, 0 warnings, 0 notes. Status set to review.
- 2026-10-22: review return 2: AC3 fails for a `share/version` whose part is too big for an R integer (`1.99999999999.0`): `numeric_version()` warns and the row reads `too old` with "version 1.NA.0", and `create_supplement()` drops every tool line (pass 2 diff-bug #1). AC6 fails because the help page does not list the row labels `GitHub account` and `Zenodo account` (diff-bug #5). Fix-now items to carry: help wording "the system path that R sees" (diff-bug #2), one version-text check (diff-bug #4), DESIGN.md `tool_problems()` location (blame-history #3), and `git_run()` named as the one `system2()` call in DESIGN.md and its comment (ripple #2).
- 2026-10-22: minor amendment: task T9 (review return 2) added; Coverage AC3 → T9, AC6 → T9.
- 2026-10-22: T9: `quarto_version()` wraps `numeric_version()` in `tryCatch()` for warnings, so a part too big for an integer reads as no version; a new test covers it, and a plant of the old call failed 3 tests. The help page lists the `GitHub account` and `Zenodo account` rows as items and says `found` means the system path that R sees. One version-text check removed from the loop. DESIGN.md and the `git_run()` comment name it as the one call of `system2` (the comment avoids `system2(` so `test-source.R` still counts one site). `devtools::test(filter = "check-tools|create-supplement|source")` clean (256 pass, 2 skips that predate the change).
- 2026-10-22: claim audit: 11 claims read, 0 corrected — R/check-tools.R, R/check-supplement.R, man/check_tools.Rd, tests/testthat/test-check-tools.R (commit 42aa102).
- 2026-10-22: verify at 42aa102: `devtools::document()` no change; full `devtools::test()` FAIL 0, ERR 0, SKIP 8, PASS 4999 (`test-check-tools.R` 16 tests, none skipped; `test-create-supplement.R` 24 tests, 2 Windows-only skips; `test-source.R` 2 tests); `devtools::check()` 0 errors, 0 warnings, 0 notes. Status set to review.
- 2026-10-22: step-7 approval: m037-tool-check approved for merge

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->

Pass 1 (2026-10-22, head b324932). Sync: main at 33ebeba, branch up to date. No Copilot round (PROFILE has no `# Copilot review:` line).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: `expect_invisible(suppressMessages(rows <- check_tools()))` always passes, because the assignment is invisible — fix now (test).
- diff-bug #2: a `share/version` with bytes that are not valid in the locale makes `grepl()` warn ("input string 1 is invalid in this locale", reproduced), so `check_tools()` warns instead of giving "version unknown", and `create_supplement()` then drops every tool line — fix now; AC3 fails for that input, so review return 1.
- diff-bug #3: R built without a `which` program makes `Sys.which()` warn — reject (edge: an R build without `which` is outside documented and common use; effect is a warning, and `create_supplement()` already catches it).
- diff-bug #4: the link test links to the program, while AC3 says "a path entry that links to a folder holding `bin/` and `share/version`" — fix now: add a folder-link case beside the file-link case (the file link is the one that fails without `normalizePath()`).
- diff-bug #5: the editor `detail` does not say which editor — reject (false: the `detail` holds the full path and "in the RStudio or Positron install", which names the place).
- diff-bug #6: backticks in `detail` print literally — reject (style).
- diff-bug #7: long details wrap on screen — reject (false: AC1 counts message conditions, and cli wraps to the console width by design).
- diff-bug #8: mixed separators and 8.3 short names in Windows `detail` paths — reject (style: cosmetic, the lookup and version read still work).
- diff-bug #9: a quoted or space-padded `QUARTO_PATH` is passed over — reject (false: such a value names no file, so passing it over is the stated rule).
- diff-bug #10: the line format "tool: status. detail" is written twice — fix now (one formatter).
- diff-bug #11: the test helper `quarto_row()` shares the name of the internal function — fix now (rename).
- diff-bug #12: `expect_no_match(..., "detail of git")` after the exact count of 3 lines — fix now (remove).
- diff-bug #13: "a copy on the system path is found" repeats the found path — reject (planned: AC2 names a test of the path place, and it adds the path and version checks).
- diff-bug #14: the rmarkdown `install.packages` detail check repeats the knitr one through the same code — fix now (remove).
- diff-bug #15: `NULL` and `""` for `QUARTO_PATH` run the same code — reject (planned: AC2 names both).
- diff-bug #16: existing `create_supplement()` tests now run real `Sys.which()` lookups — reject (false as a defect: no assertion depends on them, and three lookups add milliseconds).
- blame-history #1: `Sys.which()` starts `which` outside `git_run()`, against the "one place that starts a process" rule — fix now: DESIGN.md and the `git_run()` comment state the rule as the one place the package runs a program itself, with `Sys.which()` lookups starting `which` on Unix (`git_run()` already called it).
- blame-history #2: DESIGN.md contradicts itself on process starts — fix now (same edit).
- blame-history #3: `tool_problems()` drops lookup errors and warnings silently — reject (planned: AC5).
- blame-history #4: `create_supplement()` help still promises no Quarto CLI and no network — reject (false: both still hold).
- prior-review #1: on Windows a file link to a missing Quarto reads as existing, so it gives `found` or `not on path` with "version unknown" — follow-up: new row "Report broken Quarto links on Windows" (the "Detect broken file links on Windows" group already holds findings from M018, M022, and M035).
- prior-review #2: existing tests run unmocked lookups — reject (false as a defect, as diff-bug #16).
- ripple #1: DESIGN.md "the package's one place that starts a process" — fix now (with blame-history #1).
- ripple #2: the `git_run()` comment says the same — fix now (with blame-history #1).
- ripple #3: "The template needs Quarto 1.4.0 or later" while DESIGN.md says untested below 1.10 — reject (false: the message states the extension's declared `quarto-required` minimum, which Quarto enforces).
- ripple #4: the candidate row "Report missing tools before site setup" still says nothing checks the tools — reject (planned: the row graduates at post-merge hygiene).
- ripple #5: README says `check_tools()` reports which tools are missing, but it also reports too old and not on path — fix now (README wording).
- ripple #6: "not on the PATH" in `check_supplement()` docs against the new "not on path" status — reject (style).

Pass 2 (2026-10-22, head e63c4bb). Sync: branch up to date with main 33ebeba.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: a `share/version` part too big for an R integer (`1.99999999999.0`) passes the byte check, `numeric_version()` warns and gives `1.NA.0`, and the row reads `too old` (reproduced) — fix now; AC3 fails for a version not below 1.4.0, so review return 2.
- diff-bug #2: when R's own path holds an editor's Quarto, the row is `found` while the help says "the copy is on the system path" — fix now (help wording: the system path that R sees).
- diff-bug #3: the folder-link case passes without `normalizePath()` — reject (planned: AC3 names a link to a folder; the file-link case covers resolution).
- diff-bug #4: the version-text check repeats for each of the three versions through the same code — fix now (keep the status check per version, the text check once).
- diff-bug #5: the help page gives the accounts in prose but not the row labels `GitHub account` and `Zenodo account` — fix now; AC6 says the page lists the seven rows, so this joins review return 2.
- diff-bug #6: a leading-zero part reads as the same version, and a BOM or a first line over 64 bytes reads as unknown — reject (false: the unknown cases follow AC3's rule, and `01.4.0` is the version 1.4.0).
- diff-bug #7: CI on the PR head is not yet shown — reject (false: step 8 waits on CI before the merge).
- blame-history #1: the one-place process rule was reworded instead of kept — reject (planned: AC4 was narrowed at the plan's criteria audit to "runs none of the tools", and `git_run()` has called `Sys.which()` since M008); the wording itself is fixed under ripple #2.
- blame-history #2: DESIGN.md says `release_supplement()` "starts no process itself" — reject (false: the sentence is about its own code, which `test-source.R` pins).
- blame-history #3: DESIGN.md places `tool_problems()` in `R/check-tools.R`, but it is in `R/create-supplement.R` — fix now.
- blame-history #4: `Sys.which()` on Windows may start `where` — reject (false: `?Sys.which` says it uses an emulation on Windows).
- prior-review #1: the link test skips on Windows, so junction links are untested there — reject (planned: AC3 says the test skips on Windows; the row "Report broken Quarto links on Windows" covers the Windows link cases).
- ripple #1: the candidate row still says nothing checks the tools — reject (planned: it graduates at post-merge hygiene).
- ripple #2: "the one place that runs a program itself" sits beside "`Sys.which()` starts `which`", which reads as a contradiction — fix now (name `git_run()` as the one `system2()` call).
- ripple #3: `test-source.R` does not scan for `Sys.which()` — reject (planned: the test pins the one `system2()` site, and `Sys.which()` lookups are allowed by AC4).

Pass 3 (2026-10-22, head 4a404bf; code as at 42aa102). Sync: branch up to date with main 33ebeba.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the Windows editor entries try only `quarto.exe`, while `Sys.which()` also accepts `.cmd` and `.bat` — reject (false: the RStudio and Positron copies are `quarto.exe`, per the T1 sources).
- diff-bug #2: knitr and rmarkdown are looked for in the session's libraries, while Quarto can run another R — fix now (help says so), fixed ca6cd52.
- diff-bug #3: DESIGN.md says `Sys.which()` "runs `which`" in one place and "starts a shell that runs `which`" in another — fix now, fixed ca6cd52.
- diff-bug #4: `check_tools()` sits in a new "tool report" family though the name was chosen to join the `check_` family — reject (style: the family list groups by purpose).
- diff-bug #5: one NEWS bullet covers both `check_tools()` and the `create_supplement()` message — reject (false: AC6 asks for an entry for both, and the bullet names both).
- diff-bug #6: `packages = list(rmarkdown = "2.30")` serves no assertion in two tests — fix now (removed), fixed ca6cd52.
- diff-bug #7: two test comments say what the code shows — fix now for "# A link to the install folder itself." (removed), fixed ca6cd52; the file header stays, since it gives the reason for the mocks.
- diff-bug #8: the error and warning test builds its own clean site — reject (style).
- diff-bug #9: a place-label check after an exact path match — reject (false: it checks the label, a different property).
- blame-history #1: AC4 was narrowed after the plan gate — reject (false: "runs none of the tools" is in the plan commit 33ebeba, from the plan's criteria audit).
- blame-history #2: the Quarto version rule accepts any number of parts while `is_version()` asks for three — reject (false: `is_version()` checks the site's own versions; Quarto writes its own version form).
- blame-history #3: `create_supplement()` help says it never follows a link, while `quarto_version()` resolves a link — reject (false: the sentence is about the site files it writes).
- prior-review #1: a `QUARTO_PATH` that ends in `/` is passed over on macOS — reject (false: a path ending in `/` names a folder, and on Linux `stat()` fails for a file named with a trailing `/` too, so the value names no Quarto program).
- ripple: no ripple evidence.

Evidence (2026-10-22, code at ca6cd52; one `devtools::test(reporter = "silent")` run: FAIL 0, ERR 0, SKIP 8, PASS 4999).
- AC1: `test-check-tools.R` "check_tools() returns the seven rows invisibly" (7 expectations: invisible return, column names and types, row order, statuses), "tools that the lookups do not find are missing" (3: all five `missing`, knitr hint, gh hint), "check_tools() prints one line per row with its tool and status" (6: 7 messages; `not on path`, `missing`, `found`, `reminder` lines, then `too old`) — all pass.
- AC2: "the editor list holds the RStudio and Positron copies of each system" (3: the exact mac, linux, and windows lists with `PROGRAMFILES` and `LOCALAPPDATA` mocked), "a copy on the system path is found" (3), "a copy in QUARTO_PATH or an editor folder is not on the path" (9: `QUARTO_PATH` copy with place and `can miss`, editor copy with path, "RStudio or Positron", and `can miss`, a `quarto.exe` entry), "a QUARTO_PATH that names no file is passed over" (4: unset, empty, missing file, folder), "the first place that holds a copy wins" (4: path over `QUARTO_PATH`, `QUARTO_PATH` over an editor entry) — all pass.
- AC3: "the version is compared as a version number" (1.3.450 too old, 1.4.0 and 1.10.0 found), "a version file with no final line break is read with no warning", "a missing or unreadable version keeps the status and says so" (missing file; other text), "an old copy off the path is too old and names its place", "a link to a copy is resolved before the version is read" (file link and folder link; ran on macOS, skips on Windows), "the minimum version is the template extension's", plus the return tests "a version file with bytes that are not UTF-8 gives no warning" and "a version part too big for an R integer is read as no version" — all pass.
- AC4: `grep -nE 'system\(|system2\(|shell\(|pipe\(|processx|callr' R/check-tools.R` finds nothing; `git diff main..HEAD -- tests/testthat/test-source.R` is empty; `test-source.R` "git runs only through its helper" (2) and "release_supplement() starts no process of its own" (3) pass over all of `R/`.
- AC5: `test-create-supplement.R` "the closing message names each missing, old, or off-path tool" (13: a run with only `found` and `reminder` rows adds no line and no `check_tools` line; a run with one `not on path`, one `missing`, and one `too old` row adds exactly those 3 lines and the `check_tools()` line; site bytes equal), "an error or a warning in the lookups leaves the site and the message as they were" (10: no warning escapes, `path` returned, message and site bytes equal the clean run) — all pass. The 22 earlier tests of that file still pass (2 Windows-only skips).
- AC6: `man/check_tools.Rd` (read 2026-10-22) lists the rows `Quarto`, `knitr`, `rmarkdown`, `git`, `gh`, `GitHub account`, `Zenodo account`; the five statuses; the three Quarto places with the seven editor paths; the version rule; and "It runs none of them". `README.md` "Start a new site" names `supplement::check_tools()`; `NEWS.md` has the `check_tools()` entry naming the `create_supplement()` message; `cairn/DESIGN.md` Function Families lists `check_tools()`, and its Architecture names `R/check-tools.R` and the lookups in `create_supplement()`.
- AC7 (local part): `Rscript -e 'devtools::document()'` left no change (`git status --short` empty after it); `devtools::test()` FAIL 0, ERR 0, SKIP 8, PASS 4999; `devtools::check()` 0 errors, 0 warnings, 0 notes. CI on the PR head is checked at the merge step; the box waits for it.
- Consistency gate: `cairn_validate.py` all checks passed; no principle changed, so no `cairn_impact`; `document()` no diff; no README.Rmd and no `_pkgdown.yml`; NEWS.md has the entry, with no milestone numbers; the new top-level-free files (`R/check-tools.R`, `man/check_tools.Rd`, `tests/testthat/test-check-tools.R`) need no `.Rbuildignore` entry; `devtools::check()` clean. Defect returns so far: 2 (thrash threshold is 3).
