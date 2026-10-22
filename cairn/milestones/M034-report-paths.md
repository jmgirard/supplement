# M034: Reports find the site folder from any folder

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the template's example report, the report that `add_report()` writes, and the site README
- **Branch/PR:** m034-report-paths

## Goal

The example report and each report from `add_report()` find the site folder by one rule, in a render and when their code runs by hand from `analyses/` or from the site folder.

## Scope

**In:** One `site` chunk in `inst/template/analyses/example.qmd`, which the `data` and `save-figure` chunks use. `report_lines()` in `R/add-report.R` copies that chunk from the installed example, as `environment_section()` copies the last section. The site README's "Paper figures" and private-data sections, `NEWS.md`, and the example rule in `cairn/DESIGN.md` Architecture state the same rule. The M028 tests that run example chunks by hand run the `site` chunk first.

**Out:** A linked `figures` folder and the `save_png()` write check stay in the candidate row "Stop the example at a linked figures". Reports in sites made before this change are not edited. The NEWS entry tells authors what to copy, and migration of old sites is out of scope for version 1 (DESIGN Purpose & Scope).

## Acceptance criteria

- [x] AC1: `inst/template/analyses/example.qmd` has one chunk labeled `site`, before the chunk labeled `data`. The chunk sets `site` to the value of `QUARTO_PROJECT_DIR` if that value is not empty. Otherwise it sets `site` to `"."` if the working folder holds `_quarto.yml`, and to `".."` if only its parent holds one. If neither holds one, it stops with an error that says to run the code from the site folder or from `analyses/`. `grep -n 'site <-' inst/template/analyses/example.qmd` lists only lines inside that chunk. The prose before the chunk states this rule and no longer says that the site folder is `..` when the variable is not set.
- [x] AC2: The `site` chunk's code, read with `chunk_code()` and run in each setup below, gives the value shown, compared with `identical()`. Evidence is a test in `tests/testthat/test-template.R`. From `analyses/` of a new site: `".."` with `QUARTO_PROJECT_DIR` unset and with it set to `""`. From the site folder: `"."` with it unset and with it set to `""`. From the site folder of a new site made inside a folder that also holds `_quarto.yml`: `"."`. From `analyses/` with it set to another folder's path: that path as set. From a folder where neither it nor its parent holds `_quarto.yml`, unset and set to `""`: the stop, matched by its message.
- [x] AC3: The report that `add_report()` writes holds a chunk labeled `site` whose lines equal the example's `site` chunk (`chunk_code()` on both files). That chunk comes before every other chunk of the report. The report's text tells the author to read a data file as `file.path(site, "data", "<file name>")`. Apart from the title and description lines, no line of the report holds `"..", "data"`. A test in `tests/testthat/test-add-report.R` checks each of these.
- [x] AC4: A report from `add_report()` that reads `data/example.csv` through `site` renders in both `execute-dir` setups. Evidence is a test in `tests/testthat/test-template.R`. In each of two new sites, the test adds a report with `add_report()` and appends a chunk that prints `nrow(read.csv(file.path(site, "data", "example.csv")))`. One site keeps the template's `_quarto.yml`, and the other adds `execute-dir: project` under `project:`. A full `quarto render` of each site exits 0. Each report page in `docs/analyses/` holds `[1] <n>` in that chunk's output, where `<n>` is the row count that the test reads from `inst/template/data/example.csv`.
- [x] AC5: In `inst/template/_README.md`, the "Paper figures" section's first R code block starts with the `site` chunk's lines after its `#|` option lines (a test compares them). Its prose states the rule of AC1 and tells the author to copy the `site` chunk along with `save_png()`. The "Rendering on the machine with the private data" section tells the author to read fit files as `file.path(site, "analyses", "fits", ...)`. `grep -rnF -e 'QUARTO_PROJECT_DIR", ".."' -e 'file.path("fits"' -e 'file.path(\"..\", \"data\"' inst/template R` prints nothing.
- [x] AC6: `NEWS.md` states the rule of AC1. The bullet that now says the example uses `..` when `QUARTO_PROJECT_DIR` is not set states the new rule in its place. A bullet says that a report from `add_report()` finds the site folder by the same rule, and that a site made before this change can copy the `site` chunk from a new site's `analyses/example.qmd` into its reports.

## Coverage

- AC1 → T1, T7
- AC2 → T1
- AC3 → T3
- AC4 → T4
- AC5 → T5, T8
- AC6 → T6

## Tasks

- [x] T1: Write the AC2 test first, then add the `site` chunk and its prose to `inst/template/analyses/example.qmd` (around lines 9-17). Remove the `site <-` lines from the `data` and `save-figure` chunks.
- [x] T2: In `tests/testthat/test-template.R` (around lines 248-330), make the hand-run, failed-plot, and `save_png()` tests run the `site` chunk before the chunks they run, and update the comment that says `save-figure` finds the site folder itself.
- [x] T3: Write the AC3 test, then change `report_lines()` in `R/add-report.R` (line 191) to put the example's `site` chunk first, read by a helper beside `environment_section()`, and to name `file.path(site, "data", ...)` in its text.
- [x] T4: Write the AC4 render test, with one new site for each `execute-dir` setup, because freeze reuses stored output in a second render of one site (D-002).
- [x] T5: Change `inst/template/_README.md` (around lines 268-272 and 440-455) for AC5, add the README comparison test, and run the AC5 grep.
- [x] T6: Change the `NEWS.md` bullets (around line 130) for AC6 and the example rule in `cairn/DESIGN.md` Architecture (line 186). Run `devtools::test()` and `devtools::check()`.
- [x] T7: Review return 1. In `inst/template/analyses/example.qmd`, make the prose before the `site` chunk state the stop and the empty-variable case. Describe the stub's first `site` chunk in the `add_report()` roxygen and run `devtools::document()`. Name `site_chunk()` in `cairn/DESIGN.md` Architecture, fix NEWS.md's fits sentence, and make the nested-site test comment say why.
- [x] T8: Review return 2. Make the "Paper figures" prose in `inst/template/_README.md` state that an empty `QUARTO_PROJECT_DIR` counts as unset. Remove the repeated "not set" from the example prose, and rewrap the long roxygen line in `R/add-report.R`, then run `devtools::document()`.

## Work log

- 2026-10-22: created by /milestone-plan.
- 2026-10-22: tier check: not run — work named at the question set.
- 2026-10-22: idea vet: no concern found. The `_quarto.yml` lookup is right for reports in `analyses/`, the only folder `add_report()` writes to, and the candidate row came from the M028 review.
- 2026-10-22: question set: which work to plan — the candidate row "Make report paths work from any folder", absorbed in full. How a report finds the site folder — `QUARTO_PROJECT_DIR` when not empty, else `.` or `..`, whichever holds `_quarto.yml`.
- 2026-10-22: plan gate chose the `_quarto.yml` lookup (user) over the current `Sys.getenv("QUARTO_PROJECT_DIR", "..")` rule and over `execute-dir: project` in the template, because the first fails on an empty variable or a run from the site folder and the second breaks a chunk run by hand from `analyses/`; falsified by a supported editor or Quarto setup that runs report code from a folder other than the site folder or `analyses/`.
- 2026-10-22: plan chose one `site` chunk that other chunks use over repeating the lookup in each chunk, because the lookup grows to several lines and would appear three times; falsified by authors who copy single chunks (not the README block) and hit "object 'site' not found".
- 2026-10-22: collision check: absorbs the candidate row "Make report paths work from any folder". It extends M028 (archived), which set the current rule, and stays apart from the row "Stop the example at a linked figures". No D-entry conflicts. The inbox sweep found 0 open issues and 0 open PRs.
- 2026-10-22: criteria audit (full mode, fresh Opus reader) returned 8 findings, all fixed: the M028 tests that run `save-figure` alone (T2), the example and README prose that states the old rule (AC1, AC5), three more AC2 setups and `identical()` comparison, AC3 scoped past the title and description lines, AC4 split into two sites because of freeze and matched on `[1] <n>`, AC5 compared after the `#|` lines, the AC6 grep dropped because it would match the new wording, and `cairn/DESIGN.md` line 186 added to T6.
- 2026-10-22: lessons applied: M028 (`QUARTO_PROJECT_DIR` is set in every render kind), M018 (compare paths as set, because of 8.3 short names on Windows), M001 and D-002 (freeze reuses stored output, so each render leg gets its own site).
- 2026-10-22: changelog: AC6 edits the existing unreleased M028 bullet and adds one bullet.
- 2026-10-22: implement started on branch m034-report-paths, cut from main at 4efd1b9.
- 2026-10-22: T1: the example gets a "Site Folder" section and a `site` chunk (`Find()` over `.` and `..`, then a base `stop()`). The new test failed before the chunk existed (`chunk_code()` found no `site` label) and passes with 8 expectations.
- 2026-10-22: T2: the hand-run, failed-plot, and `save_png()` tests run the `site` chunk first; all three pass with NOT_CRAN=true (3, 7, and 4 expectations). Checkpoint: the full `devtools::test()` run for T1 and T2 was still running at this commit.
- 2026-10-22: the full `devtools::test()` run on 9d3b309 (NOT_CRAN=true): 333 tests, 0 failed, 0 errors, 8 skipped.
- 2026-10-22: T3: `site_chunk()` in `R/add-report.R` copies the example's `site` chunk, fence to fence, and `example_lines()` now serves it and `environment_section()`. The new test failed before the change (no `site` label in the stub); `test-add-report.R` passes whole.
- 2026-10-22: T4: the render test passes in both sites (4 expectations, NOT_CRAN=true). With `R/add-report.R` from main it fails with "object 'site' not found" from the render, then the file was restored.
- 2026-10-22: T5: the README's "Paper figures" block starts with the `site` chunk's code, its prose states the rule and says to copy `save_png()` after the `site` chunk and the `figures` lines, and the fits advice reads `file.path(site, "analyses", "fits", ...)`. The new comparison test passes and fails on main's README. The AC5 grep printed nothing (exit 1).
- 2026-10-22: T6 (checkpoint): NEWS.md's figures bullet states the `site` chunk rule and a new bullet covers `add_report()` reports and old sites; `cairn/DESIGN.md` Architecture states the rule and names `site_chunk()`. `devtools::document()` changed nothing. The full suite and `devtools::check()` were running at this commit.
- 2026-10-22: on 520d810 the full `devtools::test()` (NOT_CRAN=true) gave 336 tests, 0 failed, 0 errors, 8 skipped. The `devtools::check()` run right after it reported 1 error whose text was not kept; two reruns gave 0 errors, 0 warnings, 0 notes (4681 passed, 10 skipped in `tests/testthat.Rout`). The cause of the first error is not known; see the parked row "template test flake".
- 2026-10-22: claim audit: 32 claims read, 3 corrected — NEWS.md (the stub's first code chunk is `site`, and only its text names the data path; the folder order when both `.` and `..` hold `_quarto.yml`), tests/testthat/test-add-report.R (test name). The folder-order wording was also fixed in `inst/template/_README.md` and `inst/template/analyses/example.qmd`, and a README wording note was taken. `test-template.R`, `test-add-report.R`, and `test-create-supplement.R` pass after the edits (NOT_CRAN=true).
- 2026-10-22: review return 1: AC1 fails. The prose before the `site` chunk in `inst/template/analyses/example.qmd` does not say that the code stops when neither folder holds `_quarto.yml`, or that an empty `QUARTO_PROJECT_DIR` counts as unset. The same task carries the pass-1 fix-now items: the `add_report()` roxygen and `man/add_report.Rd` describe the stub's first `site` chunk; `cairn/DESIGN.md` names `site_chunk()`; NEWS.md's fits sentence says the README tells reports to read fit files so; the nested-site comment in `test-template.R` says why.
- 2026-10-22: T7 (checkpoint): example.qmd prose states the empty-variable case and the stop; the `add_report()` roxygen and `man/add_report.Rd` describe the first `site` chunk; DESIGN names `site_chunk()`; NEWS fits sentence and the test comment fixed. Full `devtools::test()` (NOT_CRAN=true): 336 tests, 0 failed, 0 errors, 8 skipped. The claim audit of these lines was running at this commit.
- 2026-10-22: claim audit: 14 claims read, 0 corrected — inst/template/analyses/example.qmd, R/add-report.R, man/add_report.Rd, NEWS.md, tests/testthat/test-template.R (T7 lines, 9a8b3b1..7419829).
- 2026-10-22: review return 2: AC5 fails. The "Paper figures" prose in `inst/template/_README.md` (lines 443-445) omits that an empty `QUARTO_PROJECT_DIR` counts as unset. The same task carries the pass-2 fix-now items: the repeated "not set" in the example prose (lines 12-13) and the 94-character roxygen line in `R/add-report.R` (line 10).
- 2026-10-22: T8 (checkpoint): the README "Paper figures" prose and the example prose now both say the variable is missing when code runs by hand and that a missing or empty value starts the `_quarto.yml` search; the roxygen paragraph is rewrapped (it held a 103-character line after the T7 edit), and `devtools::document()` rewrote `man/add_report.Rd`. Full `devtools::test()` (NOT_CRAN=true): 336 tests, 0 failed, 0 errors, 8 skipped. The claim audit was running at this commit.
- 2026-10-22: claim audit: 15 claims read, 1 corrected — inst/template/_README.md, inst/template/analyses/example.qmd ("the variable is missing" became "usually missing", since a shell or `.Renviron` can set it); the reader re-read the corrected sentence and it holds. R/add-report.R and man/add_report.Rd had no finding. The README and site chunk tests pass after the edit.

## Decisions

## Review

Pass 1, 2026-10-22, on ffface2 (main at 4efd1b9, not moved).

- Gate: `devtools::test()` (NOT_CRAN=true) 336 tests, 0 failed, 0 errors, 8 skipped. `devtools::check()` 0 errors, 0 warnings, 0 notes. `devtools::document()` left no diff. `cairn_validate.py` all checks passed. No principle changed, so no `cairn_impact` run. No README.Rmd and no pkgdown site. NEWS.md has entries for the change. No new top-level files.
- AC1: not met. The chunk and the grep pass (`site <-` only at example.qmd:19 and :21, inside the `site` chunk at :17-25), but the prose before the chunk (:11-15) does not say that the code stops when neither folder holds `_quarto.yml`, or that an empty variable counts as unset (diff-bug #6). Review return 1.
- [x] AC2 evidence: "the example's site chunk finds the site folder from analyses/ or the site folder" passed in the full suite on ffface2 (8 expectations at T1). It covers `..` and `.` with the variable unset and `""`, the nested site (`.`), a set path compared with `identical()`, and the stop matched by its message, unset and `""`.
- [x] AC3 evidence: "a report stub's first chunk is the example's site chunk, and its text reads data through site" passed in the full suite. It compares `chunk_code()` of both files, checks the first chunk's label, the data-path text, and no `"..", "data"` outside the title and description lines.
- [x] AC4 evidence: "a report from add_report() reads data through its site chunk with either execute-dir" passed in the full suite (NOT_CRAN=true), two new sites, each page holding `[1] 10` against the row count read from `inst/template/data/example.csv`. With main's `R/add-report.R` it failed with "object 'site' not found" (T4).
- [x] AC5 evidence: "the README's figure code starts with the example's site chunk" passed. The README prose (`_README.md` "Paper figures") states the rule and says to copy `save_png()` after the `site` chunk and the `figures` lines. The fits advice is at `_README.md:273`. The AC5 grep printed nothing (exit 1).
- [x] AC6 evidence: NEWS.md's figures bullet now states the `site` chunk rule in place of the `..` fallback, and the new bullet covers `add_report()` reports and copying the chunk from a new site's `analyses/example.qmd`.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the `add_report()` help (roxygen in R/add-report.R, man/add_report.Rd) does not describe the stub's new first `site` chunk — fix now (in return 1).
- diff-bug #2: cairn/DESIGN.md:76-79 names only `environment_section()` for the stub, not `site_chunk()` — fix now (in return 1).
- diff-bug #3: a folder named `_quarto.yml` counts as the site in the chunk, while `add_report()` treats it as no config — reject, edge: such a folder is outside documented and common use, and Quarto then fails to render the site with an error.
- diff-bug #4: `site` is the relative `.` or `..`, so a later `setwd()` in report code breaks the paths — reject, edge: changing the working folder inside a report is outside the template's documented and common use, and the effect is a file-not-found error.
- diff-bug #5: `site_chunk()` needs the exact fence "```{r}", fails with an unclear error on a missing closing fence, and its `stopifnot()` error has no `supplement_error` class — reject, false: it reads only the package's own installed example, which no user input changes, as `environment_section()` does.
- diff-bug #6: the prose before the `site` chunk does not state the stop or the empty-variable case, which AC1 asks it to — review return 1.
- diff-bug #7: both AC4 renders take the `QUARTO_PROJECT_DIR` branch, so a render never tests the `.`/`..` fallback — reject, planned change: AC4 is the render case, and AC2 covers the fallback.
- diff-bug #8: NEWS.md "The site's README reads fit files as…" is odd, since the README tells reports to read them so — fix now (in return 1).
- diff-bug #9: the README's figure block leaves out the example's check for a file named `figures` while it tells authors to copy `save_png()` after it — follow-up, absorbed into the row "Stop the example at a linked figures" (the gap predates the branch).
- diff-bug #10: `readLines(stub, encoding = "UTF-8")` in test-add-report.R has no `warn = FALSE` — reject, style.
- diff-bug #11: the `NA` and `""` loops in the AC2 test run the same code path — reject, planned change: AC2 names both, and `""` is the case the old `Sys.getenv(x, "..")` form got wrong.
- diff-bug #12: the comment "A site inside a folder that also holds _quarto.yml." restates the code, not why — fix now (in return 1): say that the case checks that `.` is tried before `..`.
- diff-bug #13: the comment on the output block in the AC4 test is acceptable — reject, false: no defect stated.
- blame-history #1: `data` and `save-figure` no longer run alone, which M028 (0c312a3) gave them — reject, planned change (work-log choice of one `site` chunk).
- blame-history #2: copying the README block now needs the `site` chunk first — reject, planned change; the README says so.
- blame-history #3: the M028 comment that the chunk runs alone is gone, and no test checks "object 'site' not found" — reject, planned change: running `save-figure` alone is no longer a promised use.
- blame-history #4: no D-entry records the `_quarto.yml` search — reject, planned change: it is milestone-local and recorded in this work log; `QUARTO_PROJECT_DIR` stays first, as M028 chose.
- blame-history #5: reports written before this change keep `file.path("..", "data", ...)` — reject, planned change: Scope Out, and NEWS tells authors to copy the chunk.
- blame-history #6: the fits advice now depends on the `site` chunk — reject, planned change (AC5).
- prior-review #1: the lookup is now in every new report through `site_chunk()` — reject, planned change (AC3).
- prior-review #2: the figures write still follows a linked `figures` folder — reject, planned change: Scope Out names the row "Stop the example at a linked figures".
- ripple #1: cairn/ROADMAP.md:34 states the old rule — reject, planned change: it is the candidate row this milestone absorbs, removed at hygiene.
- ripple #2: cairn/DESIGN.md:76-78 omits `site_chunk()` — fix now (same as diff-bug #2).
- ripple #3: man/add_report.Rd and its roxygen omit the new first chunk — fix now (same as diff-bug #1).

Pass 2, 2026-10-22, on 91aff98 (main at 4efd1b9, not moved). The pass-1 lines marked `[x]` are evidence lines; the criterion boxes were not ticked then. This pass ticks each box beside its evidence line below.

- Gate: `devtools::test()` (NOT_CRAN=true) on 7419829, whose code equals 91aff98's: 336 tests, 0 failed, 0 errors, 8 skipped. `devtools::check()` on 91aff98: 0 errors, 0 warnings, 0 notes. `devtools::document()` left no diff. `cairn_validate.py` all checks passed.
- AC1 evidence: example.qmd:11-17 now states the unset or empty case, the `.` then `..` order, and the stop, and no longer says the site folder is `..`. The `site <-` grep lists only lines 21 and 23, inside the `site` chunk. The AC2 test runs the chunk.
- AC2 evidence: "the example's site chunk finds the site folder from analyses/ or the site folder" passed in the 7419829 suite run, covering the eight setups AC2 lists, with values compared by `identical()` and the stop matched by its message.
- AC3 evidence: "a report stub's first chunk is the example's site chunk, and its text reads data through site" passed in the same run: equal `chunk_code()` lines, the first chunk labeled `site`, the data-path text, and no `"..", "data"` outside the title and description lines.
- AC4 evidence: "a report from add_report() reads data through its site chunk with either execute-dir" passed in the same run (NOT_CRAN=true): two new sites, one per `execute-dir` setup, each render exiting 0 and each page holding `[1] 10` against the row count read from `inst/template/data/example.csv`.
- AC5: not met. `inst/template/_README.md:443-445` says the code looks for `_quarto.yml` when `QUARTO_PROJECT_DIR` is not set, and omits the empty case, so its prose does not state the rule of AC1 (pass-2 ripple #1 and diff-bug #1). Pass 1 missed it. Review return 2.
- AC6 evidence: the NEWS.md bullet at line 129 states the `site` chunk rule in place of the `..` fallback, and the bullet at line 151 covers `add_report()` reports and copying the chunk from a new site's `analyses/example.qmd`.
- spawned: diff-bug, ripple, blame-history, prior-review (over 9a8b3b1..91aff98 within the branch)
- diff-bug #1: the README's "Paper figures" prose omits the empty-variable case — review return 2 (AC5).
- diff-bug #2: example.qmd:12-13 says "it is not set" twice in two sentences — fix now (in return 2).
- diff-bug #3: R/add-report.R:10 and man/add_report.Rd:37 run past 80 characters — fix now (in return 2), same as prior-review #1.
- diff-bug #4: inst/template/_README.md:446 breaks a line early — reject, style.
- ripple #1: README prose omits the empty case — review return 2 (same as diff-bug #1).
- ripple #2: NEWS.md says the chunk "stops with a message" while the new prose says "with an error" — reject, false: `stop()` raises an error with that message, so both are true.
- ripple #3: cairn/ROADMAP.md:34 states the old rule — reject, planned change: the row this milestone absorbs, removed at hygiene.
- blame-history: no finding.
- prior-review #1: R/add-report.R:10 is a 94-character roxygen line, the kind of wrap M023's review fixed — fix now (in return 2).

Pass 3, 2026-10-22, on cbdf12d (main at 4efd1b9, not moved).

- Gate: `devtools::test()` (NOT_CRAN=true) 336 tests, 0 failed, 0 errors, 8 skipped. `devtools::check()` 0 errors, 0 warnings, 0 notes. `devtools::document()` left no diff. `cairn_validate.py` all checks passed.
- AC5 evidence: "the README's figure code starts with the example's site chunk" passed in this run. `_README.md:442-448` states the AC1 rule (missing or empty variable, `.` then `..`, the stop), and `_README.md:468-470` says to put `save_png()` after the `site` chunk and the `figures` lines. The fits advice is at `_README.md:271-273`. The AC5 grep printed nothing (exit 1).
- spawned: diff-bug, ripple, blame-history, prior-review (over 8a7ab13..cbdf12d within the branch)
- diff-bug #1: `_README.md:468-470` says to put `save_png()` after the `site` chunk but never says outright to copy the chunk — fix now: say to copy the `site` chunk, the `figures` lines, and the function.
- diff-bug #2: `_README.md:471` breaks a line early after "`figures`. It takes a" — fix now with #1, since the same rewrap covers it.
- diff-bug #3: "the variable is usually missing" is a hedge — reject, false: the T8 claim audit found the plain form overstated, since a shell or `.Renviron` can set the variable.
- ripple #1: "usually" names no case where the variable is set — reject, false: same reason as diff-bug #3.
- blame-history: no finding.
- prior-review: no finding.
