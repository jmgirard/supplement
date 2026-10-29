# M077: Render from short folder names on Windows

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — `render_supplement()` publishes figures it now leaves out on Windows
- **Branch/PR:** m077-windows-short-names

## Goal

On Windows, `render_supplement()` publishes the figures that knitr writes when the path of the site folder holds an 8.3 short name, such as `RUNNER~1`.

## Scope

**In:** In `render_supplement()` (`R/render-supplement.R`, after `setwd(path)` near line 119), on Windows only, when `getwd()` holds `~`, the function sets the working folder to `normalizePath(".")`, the folder's long path, before the first Quarto command. The `on.exit()` restore stays. On macOS and Linux, and on Windows when `getwd()` holds no `~`, Quarto runs in the folder as now. Tests in `tests/testthat/test-render-supplement.R` reach a short path through `utils::shortPathName()`. The function's help page, the template's `inst/template/GUIDE.md` ("How the site renders"), DESIGN.md's `R/render-supplement.R` paragraph, and NEWS.md state the change. The GUIDE tells authors on Windows who run `quarto render` in a terminal to start it in the folder's long path.

**Out:**
- `quarto render` in a terminal started from a short path still leaves the figures out: the package does not start that Quarto, so the GUIDE line is the whole remedy here, and no candidate row follows.
- A hint in the `broken-link` row of `check_supplement()`: the candidate row named it as one possible fix. This milestone fixes the package's own render instead, and no row follows.
- The test helper `long_dir()` stays, since `run_in()` starts Quarto with `system2()` itself, not through `render_supplement()`.

## Acceptance criteria

- [ ] AC1: On windows-latest in the R-CMD-check workflow, a test in `tests/testthat` that R CMD check runs calls `render_supplement(path = utils::shortPathName(site))` on a new site, where that path holds `~`, and then finds `docs/analyses/example_files/figure-html/bootstrap-1.png` in the site and no `broken-link` row in `check_supplement(site)`.
- [ ] AC2: In a test in `tests/testthat` that runs on Windows, with `quarto_run()` mocked, each command of `render_supplement(path = utils::shortPathName(site))`, and of `render_supplement()` called with the working folder set to `utils::shortPathName(site)`, runs with `getwd()`, read without `normalizePath()`, `identical()` to `normalizePath(site, winslash = "/")`; after each call, also one where a command fails, `getwd()` is as it was before the call.
- [ ] AC3: The `render_supplement()` help page states that on Windows, when the path of the site folder holds an 8.3 short name (a part with `~`), the function runs Quarto from the folder's long path; `inst/template/GUIDE.md` "How the site renders" tells Windows authors who run `quarto render` in a terminal to run it from the folder's long path; DESIGN.md's `R/render-supplement.R` paragraph and NEWS.md describe the change.
- [ ] AC4: The `verify` slot is clean: `devtools::document()` leaves no diff, `devtools::test()` has 0 failures, and `devtools::check()` gives 0 errors and 0 warnings; the R-CMD-check workflow passes on windows-latest, macos-latest, and ubuntu-latest for the branch head.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks

- [ ] T1: Write the AC1 test beside "render_supplement() renders a new site" (`tests/testthat/test-render-supplement.R:232`), with `skip_if_no_quarto()` and `skip_on_os(c("mac", "linux"))`. Where `shortPathName()` gives no path with `~` (8.3 names off), it skips, but it fails instead when `Sys.getenv("CI") == "true"`, since `.github/scripts/check-skips.R` lets such a skip pass. Commit the test alone and push the branch (granted at the question set), so windows-latest runs it on the current code: red, on the missing figure file, not on a render error. Record the run in the work log.
- [ ] T2: Change `render_supplement()` as Scope In says. Write the AC2 test beside "render_supplement() runs each render in the site folder" (line 217), Windows only, with `local_runner()`. Push; read windows-latest's `tests/testthat.Rout` to see the AC1 and AC2 tests pass, not skip.
- [ ] T3: Update the help text (`R/render-supplement.R`, the roxygen block), `inst/template/GUIDE.md` "How the site renders", DESIGN.md's `R/render-supplement.R` paragraph (line 103), and NEWS.md; run `devtools::document()`.
- [ ] T4: Run the `verify` slot: `devtools::document()`, `devtools::test()`, `devtools::check()`; wait for the R-CMD-check workflow on the branch head.

## Work log

- 2026-10-29: created by /milestone-plan.
- 2026-10-29: tier check: not run — work named at the question set.
- 2026-10-29: question set: what to work on — "Handle short folder names on Windows"; push the branch early so windows-latest CI runs before the merge question — yes.
- 2026-10-29: idea vet: gap — `normalizePath()` on Windows also resolves links, junctions, and mapped drives, so running Quarto from it always could move the working folder to a UNC path; reading taken: use the long path only when `getwd()` holds `~`, where the render is broken now, and only on Windows. The user's pick named the fix ("run Quarto from the folder's long path"), so a README-only reading no longer fits.
- 2026-10-29: lessons used: 2026-10-19 (M018), 2026-10-28 (M068), 2026-10-28 (M072).
- 2026-10-29: collision check: absorbs the candidate row "Handle short folder names on Windows" in full; extends done M018, whose test helper `long_dir()` works around the same Quarto behavior; D-035 stands (no new process call). Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-29: plan gate chose changing the working folder in `render_supplement()` over a README note or a `broken-link` hint alone, because the package's own render can be fixed and the note reaches only readers of it; falsified by a windows-latest render from the long path that still leaves `example_files/` out of `docs/`.
- 2026-10-29: criteria audit (full mode, Opus reader): 5 findings, all taken. AC1 names R CMD check on windows-latest, not `devtools::test()`; the T1 test fails rather than skips under CI when no short path exists; AC2 compares with `identical()` to `normalizePath(site, winslash = "/")` and adds the `path = "."` call from a short working folder; AC3's help text names an 8.3 short name, not any `~`. No IP or D-entry conflict; AC4 unchanged.
- 2026-10-29: T1 test pushed at abd466a (CI run 40921405582, red expected on windows-latest); the T2 fix and AC2 test and the T3 docs are written and committed locally as an unpushed checkpoint while that run finishes; T1 to T3 not yet ticked.

## Decisions

## Review
