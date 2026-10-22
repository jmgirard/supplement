# M034: Reports find the site folder from any folder

- **Status:** in-progress
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

- [ ] AC1: `inst/template/analyses/example.qmd` has one chunk labeled `site`, before the chunk labeled `data`. The chunk sets `site` to the value of `QUARTO_PROJECT_DIR` if that value is not empty. Otherwise it sets `site` to `"."` if the working folder holds `_quarto.yml`, and to `".."` if only its parent holds one. If neither holds one, it stops with an error that says to run the code from the site folder or from `analyses/`. `grep -n 'site <-' inst/template/analyses/example.qmd` lists only lines inside that chunk. The prose before the chunk states this rule and no longer says that the site folder is `..` when the variable is not set.
- [ ] AC2: The `site` chunk's code, read with `chunk_code()` and run in each setup below, gives the value shown, compared with `identical()`. Evidence is a test in `tests/testthat/test-template.R`. From `analyses/` of a new site: `".."` with `QUARTO_PROJECT_DIR` unset and with it set to `""`. From the site folder: `"."` with it unset and with it set to `""`. From the site folder of a new site made inside a folder that also holds `_quarto.yml`: `"."`. From `analyses/` with it set to another folder's path: that path as set. From a folder where neither it nor its parent holds `_quarto.yml`, unset and set to `""`: the stop, matched by its message.
- [ ] AC3: The report that `add_report()` writes holds a chunk labeled `site` whose lines equal the example's `site` chunk (`chunk_code()` on both files). That chunk comes before every other chunk of the report. The report's text tells the author to read a data file as `file.path(site, "data", "<file name>")`. Apart from the title and description lines, no line of the report holds `"..", "data"`. A test in `tests/testthat/test-add-report.R` checks each of these.
- [ ] AC4: A report from `add_report()` that reads `data/example.csv` through `site` renders in both `execute-dir` setups. Evidence is a test in `tests/testthat/test-template.R`. In each of two new sites, the test adds a report with `add_report()` and appends a chunk that prints `nrow(read.csv(file.path(site, "data", "example.csv")))`. One site keeps the template's `_quarto.yml`, and the other adds `execute-dir: project` under `project:`. A full `quarto render` of each site exits 0. Each report page in `docs/analyses/` holds `[1] <n>` in that chunk's output, where `<n>` is the row count that the test reads from `inst/template/data/example.csv`.
- [ ] AC5: In `inst/template/_README.md`, the "Paper figures" section's first R code block starts with the `site` chunk's lines after its `#|` option lines (a test compares them). Its prose states the rule of AC1 and tells the author to copy the `site` chunk along with `save_png()`. The "Rendering on the machine with the private data" section tells the author to read fit files as `file.path(site, "analyses", "fits", ...)`. `grep -rnF -e 'QUARTO_PROJECT_DIR", ".."' -e 'file.path("fits"' -e 'file.path(\"..\", \"data\"' inst/template R` prints nothing.
- [ ] AC6: `NEWS.md` states the rule of AC1. The bullet that now says the example uses `..` when `QUARTO_PROJECT_DIR` is not set states the new rule in its place. A bullet says that a report from `add_report()` finds the site folder by the same rule, and that a site made before this change can copy the `site` chunk from a new site's `analyses/example.qmd` into its reports.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T3
- AC4 → T4
- AC5 → T5
- AC6 → T6

## Tasks

- [x] T1: Write the AC2 test first, then add the `site` chunk and its prose to `inst/template/analyses/example.qmd` (around lines 9-17). Remove the `site <-` lines from the `data` and `save-figure` chunks.
- [x] T2: In `tests/testthat/test-template.R` (around lines 248-330), make the hand-run, failed-plot, and `save_png()` tests run the `site` chunk before the chunks they run, and update the comment that says `save-figure` finds the site folder itself.
- [ ] T3: Write the AC3 test, then change `report_lines()` in `R/add-report.R` (line 191) to put the example's `site` chunk first, read by a helper beside `environment_section()`, and to name `file.path(site, "data", ...)` in its text.
- [ ] T4: Write the AC4 render test, with one new site for each `execute-dir` setup, because freeze reuses stored output in a second render of one site (D-002).
- [ ] T5: Change `inst/template/_README.md` (around lines 268-272 and 440-455) for AC5, add the README comparison test, and run the AC5 grep.
- [ ] T6: Change the `NEWS.md` bullets (around line 130) for AC6 and the example rule in `cairn/DESIGN.md` Architecture (line 186). Run `devtools::test()` and `devtools::check()`.

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

## Decisions

## Review
