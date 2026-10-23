# M046: Stop the example at a linked figures folder

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — template code that site authors run and copy into their reports
- **Branch/PR:** m046-linked-figures

## Goal

The example report stops with a message when `figures` is a link, and `save_png()` names a figure only when its file ends with the PNG end chunk.

## Scope

**In:** In `inst/template/analyses/example.qmd`, the `save-figure` chunk gets a link stop before its file stop. The chunk uses base R only, because a site renders without the supplement package. `save_png()` reads the end of its temporary file before the rename. The "Paper figures" section of `inst/template/_README.md` points authors at the whole `save-figure` chunk. `NEWS.md` and `cairn/DESIGN.md` describe both changes.

**Out:** Package functions for the report setup code → the candidate row "Shorten the setup code in new reports". A link inside `figures/`, such as `figures/plot.png`, and a linked site folder → not planned (a new candidate row if a review finds a need). The `file.symlink()` call in the release test → the candidate row "Use the link helper in the release test".

## Acceptance criteria

- [ ] AC1: The `save-figure` chunk checks for a link before it checks for a file, and stops before `dir.create()`. On macOS and Linux, a symbolic link at `figures` stops the render with the link message. Tests render the report by name for three shapes: a link to a folder outside the site, a link to a missing path, and a link to a file. On Windows, a junction to a folder outside the site stops with the link message. On Windows, a file link to a missing path stops with the link message or the existing file message. Each test asserts the failed render and the message. For each shape whose target exists, the test also asserts that `folder_state()` of the target is the same before and after.
- [x] AC2: A plain `figures` folder, a missing `figures` folder, and a file named `figures` keep their behavior. These tests in `tests/testthat/test-template.R` pass: "the first full render of a new site publishes the example figure", "the example report saves its figure in the site with either execute-dir", and "a file named figures stops the example report with a message". A new test renders the report by name with no `figures` folder and asserts that `figures/bootstrap-means.png` exists after the render.
- [x] AC3: `save_png()` gives the temporary file the target name only when the file exists and its last 12 bytes are the PNG end chunk (`00 00 00 00 49 45 4E 44 AE 42 60 82`). Otherwise it stops with a message that names the target. The target keeps its earlier state: absent, or its earlier bytes. A test runs the chunk's code through `chunk_code()` with a `dev.off()` that changes the device's file after it closes. The test has four probes: no file, 0 bytes, 11 bytes, and the full file less its last byte. Each probe runs with no target and with a target that holds an earlier figure. Each run asserts the message, the target's state, and that `figures/` holds no `.save-*.png` file.
- [x] AC4: The "Paper figures" section of `inst/template/_README.md` keeps its `site` code block and drops the `figures` lines from it. The test "the README's figure code starts with the example's site chunk" passes. The section tells authors to copy the example's whole `save-figure` chunk after the `site` chunk. It says that the chunk stops when `figures` is a file or a link, and when the PNG file lacks the end chunk.
- [x] AC5: `NEWS.md` has an entry for the link stop and the PNG end check. The template entry of `cairn/DESIGN.md` describes both.
- [ ] AC6: The R-CMD-check workflow is green on the Windows, macOS, and Ubuntu jobs, and `.github/scripts/check-skips.R` lists no new skip reason. Local `devtools::test()` and `devtools::check()` give 0 errors, 0 warnings, and 0 notes.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3, T4
- AC4 → T5
- AC5 → T5
- AC6 → T6

## Tasks

- [x] T1: In `tests/testthat/test-template.R`, after the file test (about line 431), add the AC1 link tests and the AC2 missing-folder test. Make links with `symlink_or_skip()` (`helper-files.R:150`), which makes a junction on Windows for an existing folder. Use `file.symlink()` with a skip for the missing-path and file shapes. Run the tests against `main`'s chunk and see the link tests fail. Confirm that the R error text reaches `rendered$output` for each shape, since Quarto lists `figures/**` at the start of a render.
- [x] T2: In `inst/template/analyses/example.qmd:59-63`, add the link stop before the file stop. On macOS and Linux, `Sys.readlink()` is not NA and not empty for a link. On Windows, a junction shows when `normalizePath(figures)` differs from `normalizePath(site)` plus `figures`. Read LESSONS M006 and M018 for the NA and junction rules. Run the T1 tests green.
- [x] T3: Add the AC3 test. Use `chunk_code()` (`helper-template.R:278`) and an environment with a wrapped `dev.off()` for each probe. See it fail against `main`'s `save_png()`.
- [x] T4: In `save_png()` (`example.qmd:66-80`), check that the temporary file exists and ends with the end chunk before `file.rename()`. Stop with a message that names the target. Keep `on.exit(unlink(tmp))`. Run the T3 test green.
- [x] T5: Rewrite the "Paper figures" section (`inst/template/_README.md:471-526`), the `dir.create()` paragraph included. Add the `NEWS.md` entry. Update the template entry in `cairn/DESIGN.md` (about line 224).
- [x] T6: Run `devtools::document()`, `devtools::test()`, and `devtools::check()`. Read the CI jobs at review.

## Work log

- 2026-10-23: created by /milestone-plan from the candidate row "Stop the example at a linked figures".
- 2026-10-23: tier check: milestone — three parts across report code and the site guide, and the base R link test in a report is a design choice.
- 2026-10-23: idea vet: two concerns. Refusing a link blocks an author who links `figures` to a paper folder on purpose (answer: refuse any link). The PNG end check adds lines to copied code and does not prove the file's middle is whole (answer: add the end check).
- 2026-10-23: collision check: the candidate row is absorbed in full. "Shorten the setup code in new reports" and "Use the link helper in the release test" overlap and stay separate (cross-referenced in Out). M018 made the package refuse linked folders, and M028 added the file stop and `save_png()`. No D-entry rejects this work.
- 2026-10-23: inbox sweep: 0 open issues and 0 open PRs.
- 2026-10-23: criteria audit (full mode, Opus fresh reader) returned 10 findings. Fixed in the wording: the Windows symbolic link shape (now a junction), the Windows file link to a missing path (either message), the link to a file (added), the Quarto resource read before R (T1 probe), the missing-folder test (added to AC2), the single cut-short probe (now four), the "whole file" claim (narrowed to the end chunk), the README test break (the site block stays), and the OS for the checks (CI on three jobs). AC5 had no finding.
- 2026-10-23: plan gate chose a base R link check in the chunk over `fs::is_link()` when fs is installed, because a site renders with only knitr and rmarkdown; falsified by a Windows file link to a missing path that writes outside the site or passes the chunk's checks.
- 2026-10-23: plan gate chose to point the README at the whole `save-figure` chunk over a second copy of the stops in the README block, because two copies drift; falsified by authors who need the `figures` lines without `save_png()`.
- 2026-10-23: plan gate chose the PNG end chunk over a file size check, because a cut-short file can still be large; falsified by a PNG device that writes a whole file with another ending.
- 2026-10-23: T1: added the missing-folder test and three link tests (folder outside the site, missing path, file; the file shape skips on Windows). On macOS against `main`'s chunk the three link tests fail and the missing-folder test passes. A broken link render on `main` prints R's `dev.off()` error ("QuartzBitmap_Output - unable to open file"), so R's error text reaches `rendered$output`.
- 2026-10-23: T2: the link stop compares `normalizePath()` results in lower case, because Windows returns the folder's stored case and macOS folders ignore case by default. The four T1 tests and the four nearby figure tests pass on macOS.
- 2026-10-23: T3: added the end-chunk test with four probes and two targets. Against `main`'s `save_png()` it errors at the first probe (no file) with "Could not write ../figures/new.png.", the old rename message, not the new one.
- 2026-10-23: T4: `save_png()` reads the temporary file's size and last 12 bytes before the rename. The T3 test (24 passes) and the four other `save_png()` and render tests pass on macOS with the quartz device. Linux cairo and Windows devices are read at CI.
- 2026-10-23: T5: the README block now holds the `site` chunk only, and the section says to copy the whole `save-figure` chunk and replace its last `save_png()` call. The existing NEWS figures bullet gained the two stops, since NEWS has one dev section. The README test passes. A plain-English lint hook flags a long sentence at `_README.md:171`, outside this milestone's text; left as it is.
- 2026-10-23: claim audit: 40 claims read, 4 corrected — inst/template/_README.md, inst/template/analyses/example.qmd. "A link puts the figures outside the site" became "can send", "git commits only the link" now names a symbolic link only (a Windows junction was not checked), and "only in a render" now covers code run by hand. The copy instruction now says to put the chunk after the chunks that make the plot's data.
- 2026-10-23: T6: `devtools::document()` gave no diff. Full `devtools::test()` (2 processes, macOS): 5131 passed, 10 skipped, 1 failed, "setup keeps an existing README.md and writes the guide beside it", whose message the silent reporter did not keep. Run alone it passes (5 of 5). The branch changes neither that test nor the setup scripts. `devtools::check()` is running as the second full run.
- 2026-10-23: T6: `devtools::check()` on macOS gave 0 errors, 0 warnings, 0 notes, so its test run, the setup test included, passed. The Windows and Linux jobs are read at review. Status set to review.

## Decisions

## Review

- 2026-10-23: synced: `origin/main` is f471a7c, an ancestor of the branch, so no merge was needed. No PR yet, and the Copilot round is off.
- AC1 (macOS, 2026-10-23): "a figures link to a folder outside the site stops the example report" 3/3, "a figures link to a missing path stops the example report" 3/3, and "a figures link to a file stops the example report" 3/3 pass. The Windows junction and the Windows missing-path shapes run only in the Windows CI job, so the box waits for CI.
- AC2 (macOS, 2026-10-23): "the first full render of a new site publishes the example figure" 3/3, "the example report saves its figure in the site with either execute-dir" 6/6, "a file named figures stops the example report with a message" 2/2, and the new "the example report makes a missing figures folder and saves its figure there" 2/2 pass.
- AC3 (macOS, 2026-10-23): "save_png() keeps its target as it was when the PNG file lacks its end chunk" 24/24 pass: 4 probes, each with `new.png` and `bootstrap-means.png`. The end bytes in `example.qmd` read `0, 0, 0, 0, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82`.
- AC4 (2026-10-23): the "Paper figures" section's r block holds the `site` chunk alone, and "the README's figure code starts with the example's site chunk" 1/1 passes. The section says to copy the whole `save-figure` chunk after the `site` chunk. It names the link stop (and the Windows junction), the file stop, and the PNG end-chunk stop.
- AC5 (2026-10-23): the `NEWS.md` figures bullet names the PNG end chunk and the stop for a file, a link, or a Windows junction. The `cairn/DESIGN.md` template entry describes the link test and the `IEND` check (M046).
- gate (2026-10-23): `cairn_validate.py` passed. `devtools::document()` gave no diff. The repo has no README.Rmd and no `_pkgdown.yml`. NEWS has the entry, and the diff adds no top-level file. The fresh `devtools::check()` is running.
- spawned: diff-bug, blame-history, prior-review, ripple
- ripple #1: the "Paper Figures" prose in `example.qmd` said `save_png()` names the file "only when the plot succeeds" and left out the link stop — fix now
- ripple #2: the candidate row "Stop the example at a linked figures" describes the state before the fix — reject (planned change: step 9 deletes the row)
- blame-history #1: a Windows junction to a missing target is not found by the link check, so the chunk fails later with R's device error — reject (edge: a dangling junction is outside the documented and the common use; the effect is an error, and nothing is written outside the site)
- blame-history #2: the README block lost the `figures` and `dir.create()` lines that M028 added — reject (planned change: the plan gate chose to point at the whole chunk)
- blame-history #3: on Windows the chunk calls a file link to a missing path a file, while the package's `is_link()` calls it a link — reject (planned change: AC1 accepts either message there)
- blame-history #4: Windows and Linux devices and shapes run only in CI — noted (AC1 and AC6 wait for CI at step 8)
- blame-history #5: the README sentence "Then it makes the folder" read as if the folder were made after a stop, and the lines were wrapped unevenly — fix now
- prior-review #1: on Windows a link to a missing path gets the file message, not the link message — reject (planned change: AC1 accepts either message on Windows)
- prior-review #2: on Windows a symbolic link to a folder inside the site may pass — reject (false: `normalizePath()` resolves a link to `figs/` to `site/figs`, which differs from `site/figures`)
- prior-review #3: the "Paper Figures" prose leaves out the new stops — fix now (same fix as ripple #1)
- diff-bug #1: the Windows tests have run only on macOS — noted (AC1 and AC6 wait for CI at step 8)
- diff-bug #2: the setup test failed once in the parallel full run and was not traced — follow-up (absorbed into the candidate row "template test flake"); it passed alone and in `devtools::check()`
- diff-bug #3: a site at a filesystem root gives `//figures`, so a plain folder gets the link message — reject (edge: a site at `/` or `C:/` is outside the documented and the common use; the effect is an error)
- diff-bug #4: if `normalizePath()` fails on one side, on a network or virtual drive, a plain folder gets the link message — reject (edge: a drive where `normalizePath()` fails is outside the common use; the effect is an error)
- diff-bug #5: on Windows a file link to an existing file gets the file message, and no test runs that shape there — reject (planned change: AC1 names the link-to-file shape for macOS and Linux only)
- diff-bug #6: `expect_false(file.exists(file.path(site, "gone")))` also passes on `main` — fix now (removed)
- diff-bug #7: the folder-state check in the link-to-file test cannot fail on `main` — reject (planned change: AC1 asks for it; the message check fails on `main`)
- diff-bug #8: `readBin()` reads the whole PNG to get 12 bytes — reject (edge: only a figure far larger than a paper figure makes the memory matter, and the effect is slow running)
- diff-bug #9: two lines in the copied chunk run to about 90 and 99 characters — reject (style)
- diff-bug #10: `tolower()` adds nothing on Linux — reject (false: no defect; it guards case on macOS and Windows)
- diff-bug #11: a plot that draws no file now gets "Could not write a whole PNG file" — reject (planned change: AC3's "no file" probe pins it)
- diff-bug test-rule #1: the "0 bytes" probe takes the same branch as "no file" and "11 bytes" — reject (planned change: AC3 names the four probes)
- diff-bug test-rule #2: the two targets run the same code — reject (planned change: AC3 asks for both)
- diff-bug test-rule #3: `has_line()` does what `expect_match(all = FALSE)` does — fix now (helper removed)
