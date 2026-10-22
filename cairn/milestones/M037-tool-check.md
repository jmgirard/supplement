<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M037: Report missing tools before site setup

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
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

- [ ] AC1: `check_tools()` returns, invisibly, a data frame with the character columns `tool`, `status`, and `detail`. It has seven rows in this order: `Quarto`, `knitr`, `rmarkdown`, `git`, `gh`, `GitHub account`, `Zenodo account`. Each `status` is one of `found`, `not on path`, `too old`, `missing`, or `reminder`. The two account rows are always `reminder`. For knitr, rmarkdown, git, and gh, a lookup that finds the tool gives `found`, and one that does not gives `missing`. AC2 and AC3 set the Quarto row. The function prints one message line per row, and the line names the row's tool and status. Tests with mocked lookups cover the found case and the missing case of each of the four tools. They also assert the printed line of one row of each of the five statuses.
- [ ] AC2: `check_tools()` looks for Quarto in three places in this order and takes the first place that holds a file. The first place is the system path. The second is the file that the `QUARTO_PATH` environment variable names. The third is the editor list, in this order: RStudio at `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto` (macOS), `<PROGRAMFILES>/RStudio/resources/app/bin/quarto/bin/quarto.exe` (Windows), and `/usr/lib/rstudio/resources/app/bin/quarto/bin/quarto` (Linux). Positron follows at `/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto` (macOS), `<LOCALAPPDATA>/Programs/Positron/resources/app/quarto/bin/quarto.exe` and `<PROGRAMFILES>/Positron/resources/app/quarto/bin/quarto.exe` (Windows), and `/usr/share/positron/resources/app/quarto/bin/quarto` (Linux). A copy on the system path gives `found`. A copy found only in the second or third place gives `not on path`. Its `detail` names the place and says that `quarto render` in a terminal will not find that copy. No copy gives `missing`. A test asserts the editor list for each of the three systems, with `PROGRAMFILES` and `LOCALAPPDATA` mocked. Tests with mocked lookups over temporary folders cover the path, `QUARTO_PATH`, one editor entry, and one `quarto.exe` entry. They also cover a `QUARTO_PATH` that is unset, empty, names a missing file, or names a folder, and a case where two places hold a copy and the first place wins.
- [ ] AC3: `check_tools()` resolves a link to the copy that it takes. It reads the Quarto version from the file `share/version` beside the copy's `bin` folder and compares it as a version number. A version below 1.4.0 gives `too old`. The value 1.4.0 is the `quarto-required` minimum in `inst/template/_extensions/supplement/_extension.yml`. `too old` wins over `not on path`, and the `detail` then also names the place. If `share/version` is missing or holds no version, the row keeps the status from AC2, and its `detail` says that the version is unknown. Tests cover the versions 1.3.450, 1.4.0, and 1.10.0, a version file with no final line break, a missing version file, a version file with other text, and an old copy off the path. A test with a path entry that links to a folder holding `bin/` and `share/version` checks the link case, and it skips on Windows.
- [ ] AC4: `check_tools()` runs none of the tools it looks for. `R/check-tools.R` calls none of `system()`, `system2()`, `shell()`, `pipe()`, processx, or callr, and the existing test "git runs only through its helper" in `tests/testthat/test-source.R` passes unchanged over all of `R/`.
- [ ] AC5: After `create_supplement()` makes a site, it runs the same lookups. Its closing message adds one line for each row whose status is `missing`, `too old`, or `not on path`. It also adds one line that names `check_tools()`. When no row has one of those statuses, the message has no added line. If the lookups raise an error or a warning, `create_supplement()` still returns `path`, gives no warning, and its message has no added line. Tests with mocked lookups cover a run with one `missing`, one `too old`, and one `not on path` row, a run with only `found` and `reminder` rows, a run whose lookups raise an error, and a run whose lookups raise a warning. Each test checks that the site's files and their bytes equal those of the run with no problem rows.
- [ ] AC6: The `check_tools()` help page lists the seven rows and the five statuses. It names the three Quarto places, the editor list, and the version rule. It says that the function runs none of the tools. `README.md` names `check_tools()` in "Start a new site". `NEWS.md` has an entry for `check_tools()` and for the `create_supplement()` message. `cairn/DESIGN.md` names `check_tools()` in Function Families, and its Architecture names `R/check-tools.R` and says that `create_supplement()` runs its lookups.
- [ ] AC7: `Rscript -e 'devtools::document()'` leaves no change, and `Rscript -e 'devtools::test()'` is clean. `devtools::check()` gives 0 errors, 0 warnings, and 0 notes, and CI passes on the PR head.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T2, T3
- AC2 → T1, T2, T3
- AC3 → T2, T3
- AC4 → T3, T6
- AC5 → T4
- AC6 → T5
- AC7 → T6

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive change is amend-via-gate. -->

- [x] T1: Check each editor path of AC2 against an install (the Positron and Quarto installs on this Mac) or the vendor's own docs or release files. Write one work-log line per path with its source. A path that turns out wrong changes through the amendment protocol.
- [x] T2: Write `tests/testthat/test-check-tools.R` first, for AC1 to AC3. Mock the lookups through small internal helpers with `local_mocked_bindings()` (LESSONS M011). Build version files with `writeBin()` so no line break is added (LESSONS M011).
- [x] T3: Write `R/check-tools.R`: `check_tools()`, the Quarto lookup and its editor list, the version read with `numeric_version()`, and the printed lines through cli. Look programs up with `Sys.which()`, which on Unix runs `which` but no looked-up tool. Add the roxygen help page (AC6 items) and run `devtools::document()`.
- [x] T4: Write the AC5 tests in `tests/testthat/test-create-supplement.R` first, then add the lookups to the closing message at `R/create-supplement.R:113-121`, inside `tryCatch()` for errors and warnings. Existing tests match "Made a supplement site", so they keep passing.
- [ ] T5: Update `README.md` ("Start a new site", line 14), `NEWS.md`, and `cairn/DESIGN.md` (Function Families, Architecture). Widen the candidate row "Record the Python setup of reports" to say that `check_tools()` does not look for Python or Jupyter, and add `check_tools()` to the reference list of "Build a package site with pkgdown".
- [ ] T6: Run the verify slot, `devtools::check()`, and `tests/testthat/test-source.R` from the source tree.

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

## Decisions
<!-- owner: implement / review · append-only; milestone-local -->

## Review
<!-- owner: review · exclusive -->
