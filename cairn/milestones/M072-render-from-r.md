# M072: Render a site from the R console

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — adds an exported function and changes messages and the template guide that authors read
- **Branch/PR:** m072-render-from-r

## Goal

Let an author render the site, or run changed reports again and then render the site, with one R function and no terminal.

## Scope

**In:** an exported `render_supplement(reports = NULL, path = ".")`. It runs the Quarto copy that `check_tools()` finds, renders each named report by name, then the whole site, and the whole site once more when the full render leaves a file in `figures/` that `docs/figures/` lacks. It returns the commands it ran. Messages in `R/` that name a `quarto render` command, and `check_supplement()`'s render-again hint, also name the function. Docs: its help page, `_pkgdown.yml`, `NEWS.md`, `cairn/DESIGN.md`, and the render parts of the template's `GUIDE.md`, which keep their `quarto render` commands for a site rendered without the package.

**Out:** commits and pushes: the package never commits, tags, or pushes (`cairn/DESIGN.md` Conventions), so the author commits. The publishing guide's switch to the function, and the README's setup steps → M073. A wrapper for `quarto preview`: not planned. Renders in a Docker container keep the commands that `GUIDE.md` gives.

## Acceptance criteria

- [ ] AC1: `render_supplement(path = site)`, on a site that `create_supplement()` makes, runs one full Quarto render in `site` and returns, invisibly, the character vector `"quarto render"`. Afterward `docs/index.html` exists. A render test in `tests/testthat/test-render-supplement.R`, skipped when Quarto is missing, shows the file and the value, and a test with the Quarto runner mocked shows one call with the argument `render`.
- [ ] AC2: With `reports = c("a", "b")`, the function renders `analyses/a.qmd`, then `analyses/b.qmd`, each by name, then the whole site, and returns `c("quarto render analyses/a.qmd", "quarto render analyses/b.qmd", "quarto render")`. A name given twice is rendered once, at its first place. A test with the runner mocked shows the calls in that order and the value, for two names and for a repeated name. A render test changes the printed value of a report that holds stored output, calls the function once with that report's name, and shows that the report's page in `docs/` holds the new value.
- [ ] AC3: When a full render ends with a file in `figures/` that `docs/figures/` lacks, compared by relative path with hidden files included, the function runs the full render once more and never a third time. When files are still missing after that render, it prints their names and returns normally. Tests with the runner mocked show one full render when no file is missing, two when the first leaves one missing, and two plus the printed names when both leave one missing. A render test whose new report has no stored output and saves a figure under a new name shows that figure in `docs/figures/` after one call.
- [ ] AC4: The function runs, by its full path, the Quarto copy that `check_tools()` reports: the one on the system path, else the file that `QUARTO_PATH` names, else the RStudio or Positron copy. A copy whose version cannot be read is used. Before any render it stops with class `supplement_error_no_quarto` when there is no copy, and with class `supplement_error_quarto_version` when the copy's version is below 1.4.0. Each case is shown by a test that mocks the lookups, and a render test with `tool_which()` mocked to find no `quarto` and `QUARTO_PATH` set to the real copy renders the site.
- [ ] AC5: Before any render, the function checks in this order and stops at the first problem: class `supplement_error_argument` when `path` is not one non-empty string, or `reports` is not `NULL` or a character vector of length 1 or more with no `NA`; class `supplement_error_report_name` when an entry of `reports` breaks `add_report()`'s rule for `name`, its pattern or its Windows reserved names; class `supplement_error_no_config` when `path` holds no `_quarto.yml` file; and class `supplement_error_no_report`, naming each entry whose `analyses/<name>.qmd` is not a file. When a render exits with a status other than 0, the function stops with class `supplement_error_render`, names that command, and runs no later command. After every call, a stopped one included, the working directory is the one before the call. Each case is shown by its own test.
- [ ] AC6: The help page of `render_supplement()`, its entry in `_pkgdown.yml`'s reference index, a `NEWS.md` entry, and `cairn/DESIGN.md`'s function families name the function. Each line that `grep -n 'quarto render' R/*.R` finds outside `R/render-supplement.R`, roxygen (`#'`), and code comments also names `render_supplement()`, and so does `rerender_steps` in `R/check-supplement.R`. In `inst/template/GUIDE.md`, the sections "How the site renders" and "Rendering on the machine with the private data" name `render_supplement()` as the way to render from the R console and keep their `quarto render` commands. `cairn/DESIGN.md` and the comment above `git_run()` no longer call `git_run()` the package's one `system2()` call.
- [ ] AC7: `devtools::test()` gives 0 failures and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T1, T2, T6
- AC6 → T3, T4, T6
- AC7 → T5, T6

## Tasks

- [x] T1: Tests first, in `tests/testthat/test-render-supplement.R`: one test per case of AC1 to AC5. The mocked tests replace an internal runner (one function that runs Quarto with its arguments) through `local_mocked_bindings()`. The render tests sit behind `skip_if_no_quarto()` and run from `long_dir()` folders, as `helper-template.R` does. The AC4 lookup tests mock `tool_which()`, `tool_env()`, and `editor_quarto_paths()`, as `test-check-tools.R` does. See them fail.
- [x] T2: Write `R/render-supplement.R`. Reuse `find_quarto()`, `quarto_version()`, and `quarto_minimum` from `R/check-tools.R`, and `check_path()`. Factor `add_report()`'s name rule (`R/add-report.R:134-149`) into a helper both functions call. Run each command through the runner with `system2()` on the quoted full path, its output shown in the console, with `setwd()` undone by `on.exit()`. Compare `figures/` and `docs/figures/` with `list.files(recursive = TRUE, all.files = TRUE)`.
- [x] T3: Run AC6's grep and name the function in each line it finds, among them `R/create-supplement.R:131`, `R/add-report.R:261`, and `R/check-tools.R:151`, and in `rerender_steps` (`R/check-supplement.R:816`). Fix the `system2()` comment above `git_run()` (`R/check-supplement.R:561`). Record the grep's lines in the Review section.
- [x] T4: Write the roxygen and run `devtools::document()`. Add the function to `_pkgdown.yml` and `NEWS.md`. In `cairn/DESIGN.md`, add it to the function families and fix the `system2()` sentence (about line 149). Update the two `GUIDE.md` sections.
- [x] T5: Run `devtools::test()` and `devtools::check()`.
- [ ] T6: Review return 1: make the `R/check-tools.R` line that names `quarto render` name `render_supplement()`; match report names to the files in `analyses/` with exact case; and fix the fix-now findings of review pass 1 (the add_report() hint's folder, the still-missing hint, the status-127 message, the test trims and the Sass-lock rerun, the D-entry, DESIGN.md, GUIDE.md, and NEWS.md). Then run `devtools::test()` and `devtools::check()`.

## Work log

- 2026-10-28: created by /milestone-plan.
- 2026-10-28: tier check: milestone — adds an exported function and changes messages and docs, more than one sitting.
- 2026-10-28: idea vet: no concern. Quarto started from R finds R through `R_HOME/bin` (LESSONS M018), so a render from the console uses that session's R; the function only replaces the terminal commands that the guide already gives.
- 2026-10-28: lessons used: 2026-10-19 (M018, M030, M031), how Quarto finds R; 2026-10-21 (M028), the `figures/**` glob copies hidden files, which set AC3's hidden-file compare; 2026-10-28 (M068), CI takes over 10 minutes per push, for the review's CI wait.
- 2026-10-28: collision check: no candidate row, D-entry, or archived milestone covers a render function; M039 and M040 aligned the render-again texts that AC6 extends; D-028 keeps reports free of package calls, which this function does not change. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-28: question set: shape of the render function — `render_supplement(reports = NULL)` (over `render_report(name)` only, and no function).
- 2026-10-28: plan gate chose `render_supplement(reports = NULL)` over `render_report(name)` because one function covers both the first render and the changed-report steps; falsified by authors who never render the whole site from R.
- 2026-10-28: plan gate chose `system2()` on `find_quarto()`'s copy over the quarto R package because it adds no dependency and finds the copy inside RStudio or Positron; falsified by a Quarto path that `system2()` cannot start on Windows.
- 2026-10-28: agent decided: a repeated report name renders once; a figure still missing after the second full render gives a printed list, not an error, since the render itself succeeded.
- 2026-10-28: criteria audit (full mode, fresh Opus reader) returned 16 findings over M072 and M073, all accepted; for M072: Out says "commits, tags, or pushes", not "runs git"; a mocked runner counts renders and order (AC1 to AC3); repeated names; a third-render cap test and printed names; an unreadable version is used; `tool_which()` is mocked, not `PATH`; the check order and both parts of the name rule; the grep leaves out the new file; `rerender_steps` and the `system2()` notes are in.
- 2026-10-28: set in-progress on branch m072-render-from-r.
- 2026-10-28: T1 done: `test-render-supplement.R` with 9 mocked tests (internal runner `quarto_run(quarto, args)` mocked) and 4 render tests; the mocked tests fail with no function, the render tests skip without `NOT_CRAN`.
- 2026-10-28: T2 done: `R/render-supplement.R`; `check_report_name()` in `R/add-utils.R` now holds the name rule for both functions; `fake_quarto()` and `local_tools()` moved from `test-check-tools.R` to `helper-tools.R` so both test files use them. All 13 render tests pass with `NOT_CRAN=true`.
- 2026-10-28: met the 2026-10-26 (M061) `paste0()` trap: no reports gave the file `analyses/.qmd`; guarded. Found that `system2()` quotes the program path itself, so a `shQuote()` before it gives status 127; removed (lesson candidate for review).
- 2026-10-28: agent decided: `render_supplement()` checks Quarto after the site checks, so an argument or site error comes first even with no Quarto; the error of a failed render lists the commands that ran before it.
- 2026-10-28: T3 done: the AC6 grep finds 3 lines (`R/add-report.R:254`, `R/check-tools.R:152`, `R/create-supplement.R:131`), each now naming `render_supplement()`; `rerender_steps` adds one sentence naming it, with the test copy in `test-check-supplement.R` changed to match; the `git_run()` comment and the `check_tools()` help updated. Affected test files pass.
- 2026-10-28: T4 done: `_pkgdown.yml` gets a "Render a site" group (`pkgdown::check_pkgdown()` finds no problem); `NEWS.md` entry; `cairn/DESIGN.md` adds a rendering family and an architecture paragraph and marks the `git_run()` sentence corrected; `GUIDE.md` names `supplement::render_supplement()` in "How the site renders" and in step 2 of the private-data recipe, keeping the `quarto render` commands.
- 2026-10-28: claim audit: 46 claims read, 2 corrected — `R/check-tools.R` (the row offered `render_supplement()` for a too-old copy it refuses; now only for a copy it runs, with a test) and `R/render-supplement.R` (the code refused a character vector with a class, which the help allows; the `is.object()` check dropped, with a test). One claim the reader could not verify, that Quarto copies hidden files of `figures/`, is backed by LESSONS M028 and the existing `test-add-render.R` test of `.hidden.png`.
- 2026-10-28: first full run (`NOT_CRAN=true`, 5878 expectations) had 3 failures and 1 error: two from test files edited while it ran, and `test-source.R`'s "git runs only through its helper", which pinned one `system2` call in `R/`. That test now allows two, the git call in `check-supplement.R` and `system2(quarto, args)` in `render-supplement.R`, and the `quarto_run()` comment no longer reads as a call. Noted in M073 that `test-source.R` also keeps processes out of `release-supplement.R`.
- 2026-10-28: T5 done at d565fc4: `devtools::test()` with `NOT_CRAN=true` gives 5882 expectations, 0 failed, 0 errors, 12 skipped; `devtools::check()` gives 0 errors, 0 warnings, 1 note for the hidden `.claude/` folder, which is the Claude app's local lock file, ignored by git and absent from a clone, so CI builds do not see it.
- 2026-10-28: status review.
- 2026-10-28: review return 1: AC6 fails as written (`R/check-tools.R:152`, found by the AC6 grep, does not name `render_supplement()`), and diff-bug #1 is a floor defect (a wrong-case report name passes the file check on a case-insensitive file system and renders under that case with no error). Also fix the fix-now findings listed in the Review section: diff-bug #2, #3, #4, #10, #11's test trims; blame-history #2's D-entry; prior-review #1's Sass-lock rerun in the render tests; ripple #1, #5, #6.

## Decisions

## Review

Pass 1, on df5c7c5, branch level with main at 805e91c. Suite: `devtools::test()` with `NOT_CRAN=true`, 5882 expectations, 0 failed, 0 errors, 12 skipped. Check: `devtools::check()` 0 errors, 0 warnings, 1 note (hidden `.claude/`, the app's local lock file, ignored by git).

- AC1: pass — "render_supplement() with no reports runs one full render" (mocked: value `"quarto render"`, one call with `render`, invisible) and "render_supplement() renders a new site" (real Quarto: value and `docs/index.html`) pass in the suite above.
- AC2: pass — "named reports render by name, in order and once each, before the full render" (mocked order and value for `c("a","b")` and `c("b","a","b")`) and "a named report runs its code again, which a full render alone does not" (real Quarto: page holds `marker-new` only after the named call) pass.
- AC3: pass — "a full render that leaves a figure out of docs/figures/ runs once more, and never a third time" (1, 2, and 2 renders plus the printed `figures/new.png`), "a hidden figure missing from docs/figures/ also starts the second render", and "a figure that a full render saves under a new name reaches docs/ in one call" (real Quarto, two full renders, `docs/figures/fig-new.png`) pass.
- AC4: pass — "render_supplement() runs the Quarto copy that check_tools() reports" (path, then `QUARTO_PATH`, then editor copy, and an unknown version used), "render_supplement() stops before any render when Quarto is missing or too old", and "render_supplement() renders with the copy in QUARTO_PATH when none is on the path" (real Quarto) pass.
- AC5: pass — "render_supplement() checks its arguments and the site in order, before any render", "a render that fails stops the function and runs no later command", and "render_supplement() runs each render in the site folder and gives back the working folder" pass.
- AC6: FAIL — the grep finds `R/check-tools.R:152`, `` detail <- paste0(detail, ". `quarto render` in a terminal can miss this copy") ``, which does not name `render_supplement()`; the claim-audit fix moved the name to line 154. The other parts hold: help page, `_pkgdown.yml:26`, `NEWS.md:3`, DESIGN function family, `rerender_steps` (`R/check-supplement.R:818`), the two GUIDE.md sections, and the `git_run()` comment (`R/check-supplement.R:564`).
- AC7: pass — the suite and check above.
- Gate: `cairn_validate.py` all checks passed; `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems (at T4); NEWS entry present; no new top-level file.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: on a file system that ignores case, `render_supplement("Models")` passes the file check for `analyses/models.qmd` and renders under the wrong case with no error — fix now (floor return: a wrong result with no error).
- diff-bug #2: the `add_report()` hint `render_supplement("{name}")` leaves out `path`, so it fails when `add_report()` ran with another `path` — fix now.
- diff-bug #3: the "still missing" hint tells the author to render again, which cannot help when Quarto never copies the file or `docs/figures` is a file — fix now (reword the hint).
- diff-bug #4: when Quarto cannot start (status 127) the error points to Quarto's output, which may be empty — fix now (name the start failure).
- diff-bug #5: on Windows an interrupt may leave Quarto running after the function returns (not verified) — follow-up, row "Check Windows console renders from R".
- diff-bug #6: on Windows Rgui the output of `system2(stdout = "")` may not reach the console (not verified) — follow-up, same row.
- diff-bug #7: a status of length 0 prints an empty status — reject, false: `system2()` returns one value; only a test mock could return none.
- diff-bug #8: `check_report_name()` on invalid UTF-8 may warn or error with another class — reject, edge: a name that is not UTF-8 is outside documented and common use, and the effect is an error; row "Read report names that are not UTF-8" already holds it.
- diff-bug #9: the local `missing` shadows `base::missing()` — reject, style.
- diff-bug #10: `is_plain_file_vec()` duplicates `is_plain_file()` — fix now (the case fix replaces the check).
- diff-bug #11 (tests): repeated inputs on one code path — `bad_reports` holds the profile's R edge cases (empty, `NA`, number, factor, list), kept; the four `path` cases, four pattern names, and the second failing-render case repeat one path — fix now (cut to one each); the `can miss this copy` match in `test-check-tools.R` checks unchanged text — fix now (remove); the full-render-only page check is the discriminating control for the named render — reject, planned test; `test-source.R` relies on alphabetical order — reject, style.
- blame-history #1: the real-Quarto tests skip the Sass-cache rerun that `run_in()` gives (M033) — fix now (same as prior-review #1).
- blame-history #2: the one-`system2` rule of `test-source.R` (M008, M037) changed with no D-entry — fix now (append a D-entry: git only through `git_run()`, Quarto only through `quarto_run()`).
- blame-history #3: GUIDE.md now names a package route beside the Quarto-only route (D-004, D-023) — reject, planned change (AC6), written as conditional on the package.
- blame-history #4: `rerender_steps` names a function a user without the package cannot run — reject, false: those rows come only from `check_supplement()`, so the reader has the package.
- blame-history #5 to #9: wording changes with no pinned text or decision broken — reject, planned change.
- prior-review #1: the real-Quarto tests call `render_supplement()` with no rerun on "database is locked" while tests run in parallel (M033, M052) — fix now: a test helper reruns a render once.
- prior-review #2: `file.exists()` on a `path` whose bytes are not UTF-8 stops on Windows — reject, edge: such a folder name is outside common use and the effect is an error; `add_report()` does the same on main.
- prior-review #3: a FIFO in `figures/` forces the second render and the "still missing" message — reject, edge: a special file in `figures/` is outside documented use and the effect is one extra render and a message; row "Skip FIFOs and other special files" holds it.
- ripple #1: `cairn/DESIGN.md:96` says no looked-up tool is run, above the render paragraph — fix now (scope it to `check_tools()`).
- ripple #2 to #4: the vignette and README still give `quarto render` only — reject, planned change: M073 rewrites them.
- ripple #5: GUIDE.md lines 75-76, 112-113, 441, 451, and 621 give the render steps without the R route — fix now (name it where the steps are render steps).
- ripple #6: `NEWS.md` says the render-again text in the rows names the function, but only `rerender_steps` does — fix now (narrow the NEWS sentence).
