# M077: Render from short folder names on Windows

- **Status:** review
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

- [x] AC1: On windows-latest in the R-CMD-check workflow, a test in `tests/testthat` that R CMD check runs calls `render_supplement(path = utils::shortPathName(site))` on a new site, where that path holds `~`, and then finds `docs/analyses/example_files/figure-html/bootstrap-1.png` in the site and no `broken-link` row in `check_supplement(site)`.
- [x] AC2: In a test in `tests/testthat` that runs on Windows, with `quarto_run()` mocked, each command of `render_supplement(path = utils::shortPathName(site))`, and of `render_supplement()` called with the working folder set to `utils::shortPathName(site)`, runs with `getwd()`, read without `normalizePath()`, `identical()` to `normalizePath(site, winslash = "/")`; after each call, also one where a command fails, `getwd()` is as it was before the call.
- [x] AC3: The `render_supplement()` help page states that on Windows, when the path of the site folder holds an 8.3 short name (a part with `~`), the function runs Quarto from the folder's long path; `inst/template/GUIDE.md` "How the site renders" tells Windows authors who run `quarto render` in a terminal to run it from the folder's long path; DESIGN.md's `R/render-supplement.R` paragraph and NEWS.md describe the change.
- [ ] AC4: The `verify` slot is clean: `devtools::document()` leaves no diff, `devtools::test()` has 0 failures, and `devtools::check()` gives 0 errors and 0 warnings; the R-CMD-check workflow passes on windows-latest, macos-latest, and ubuntu-latest for the branch head.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: Write the AC1 test beside "render_supplement() renders a new site" (`tests/testthat/test-render-supplement.R:232`), with `skip_if_no_quarto()` and `skip_on_os(c("mac", "linux"))`. Where `shortPathName()` gives no path with `~` (8.3 names off), it skips, but it fails instead when `Sys.getenv("CI") == "true"`, since `.github/scripts/check-skips.R` lets such a skip pass. Commit the test alone and push the branch (granted at the question set), so windows-latest runs it on the current code: red, on the missing figure file, not on a render error. Record the run in the work log.
- [x] T2: Change `render_supplement()` as Scope In says. Write the AC2 test beside "render_supplement() runs each render in the site folder" (line 217), Windows only, with `local_runner()`. Push; read windows-latest's `tests/testthat.Rout` to see the AC1 and AC2 tests pass, not skip.
- [x] T3: Update the help text (`R/render-supplement.R`, the roxygen block), `inst/template/GUIDE.md` "How the site renders", DESIGN.md's `R/render-supplement.R` paragraph (line 103), and NEWS.md; run `devtools::document()`.
- [x] T4: Run the `verify` slot: `devtools::document()`, `devtools::test()`, `devtools::check()`; wait for the R-CMD-check workflow on the branch head.

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
- 2026-10-29: T1 done: run 40921405582 on abd466a failed on windows-latest with FAIL 2 (the new test's figure-file and `broken-link` expectations, test-render-supplement.R:256 and :258), after Quarto warned that `...\RUNNER~1\...\SITE-2~3\analyses\example_files\figure-html\bootstrap-1.png` was not found; no render error; macOS and Ubuntu passed.
- 2026-10-29: T2 and T3 done: fix in `render_supplement()` (Windows and `~` only), AC2 mock test with `short_path()` helper, help text, GUIDE.md "How the site renders", DESIGN.md, NEWS.md; `devtools::document()` run.
- 2026-10-29: T4 done: local `devtools::test()` 0 failures (14 skips, the 2 new tests skip on macOS); local `devtools::check()` 0/0/0; CI run 40923761225 on 1e95df7 green on all three systems, windows-latest FAIL 0 SKIP 45 PASS 5931 (was FAIL 2 SKIP 45 PASS 5922), no new test in its skip list.
- 2026-10-29: claim audit: 28 claims read, 3 corrected — R/render-supplement.R, man/render_supplement.Rd, NEWS.md (the code comment named mapped drives, which R's normalizePath() keeps as drive letters; the help said "8.3 short name" where the code tests any `~`; "knitr draws" became "knitr saves from code chunks"); the re-read found all three hold and asked for a NEWS rewrap, done.
- 2026-10-29: review: four reviewers reported; the fix-now edits (help and NEWS example name, `mustWork = FALSE`, a no-`~` assertion in the AC2 test, GUIDE, DESIGN, and NEWS wording, NEWS rewrap) and the follow-up row "Note short Windows paths in the vignette" are committed locally, unpushed, while CI run 40926169509 on 68e083f finishes; dispositions follow in the Review section.

## Decisions

## Review

- AC1: CI run 40926169509 on 68e083f, windows-latest: R CMD check `testthat.Rout` reads FAIL 0 | SKIP 45 | PASS 5931; the test "render_supplement() publishes knitr figures when the site path holds a short name" is not in the step "List skipped tests", so it ran and passed (its figure-file and `broken-link` expectations); on abd466a, before the fix, the same two expectations failed (run 40921405582). `short_path()` stops rather than skips under `CI=true`.
- AC2: same run: the test "render_supplement() runs Quarto from the long path of a short site path on Windows" ran and passed (not in the skip list); it asserts `identical()` working folders to `normalizePath(site, winslash = "/")` for `path = short` and for `render_supplement()` under `withr::with_dir(short, …)`, and the restored `getwd()` after each call, including the failing-command call.
- AC3: read on the branch: `R/render-supplement.R` roxygen and `man/render_supplement.Rd` say that on Windows, for a site folder path holding `~` as an 8.3 short name does, the commands run from the folder's long path; `inst/template/GUIDE.md` "How the site renders" tells Windows terminal users to open the terminal in the folder's long path; DESIGN.md's `R/render-supplement.R` paragraph and the NEWS.md top entry describe the change.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: `normalizePath(mustWork = TRUE)` failing would give an unclassed error — fix now (`mustWork = FALSE`, an unresolved path stays as it is)
- diff-bug #2: the link-resolving reason in the code comment depends on the R version — fix now (comment says "can also resolve")
- diff-bug #3: a `~` in a long name also triggers the long path — reject, planned change (idea vet gap; the folder is the same)
- diff-bug #4: the AC2 test's expected value comes from `normalizePath()`, so it does not show the folder lost its `~` — fix now (`expect_false(any(grepl("~", seen)))`)
- diff-bug #5: no test for a path with no `~` left unnormalized — reject, planned change (that path keeps main's behavior, which the existing working-folder test covers)
- diff-bug #6: `short_path()` fails hard on another CI with `CI=true` and no 8.3 names — reject, edge (a CI other than this repo's GitHub Actions on a volume without short names; effect is a test error)
- diff-bug #7: GUIDE says "figures that the reports draw" where only knitr chunk figures were shown missing — fix now
- diff-bug #8: DESIGN.md equated any `~` with an 8.3 name — fix now
- diff-bug #9: NEWS read as an unconditional long-path run — fix now ("For a path with `~`")
- diff-bug #10: the `withr::with_dir()` and failing-command blocks of the AC2 test repeat code paths — reject, planned change (AC2 names both cases)
- blame-history #1: the long path resolves links the package does not enter — reject, planned change (idea vet; Quarto writes the same folder)
- blame-history #2: `mustWork = TRUE` error is unclassed — fix now (same fix as diff-bug #1)
- blame-history #3: a `~` path on a UNC share gives a UNC working folder — reject, edge (a short name on a network share, outside documented and common use; effect at most an error)
- blame-history #4: help and NEWS cite `RUNNER~1`, the CI runner's name — fix now (`JANEDO~1`, as in GUIDE.md)
- blame-history #5: `short_path()` is a second helper beside `long_dir()` — reject, style
- blame-history #6: NEWS line 5 ran to 85 characters — fix now (rewrapped)
- prior-review #1: ragged NEWS line, as M040's review fixed — fix now (same as blame-history #6)
- prior-review #2: `normalizePath()` resolves links, the class M007 and M045 raised — reject, planned change (idea vet; no write-through found)
- prior-review #3: `short_path()` skips inline rather than through a shared helper — reject, style (the skip states its reason)
- ripple #1: ROADMAP row "Handle short folder names on Windows" still proposes a README note or hint — reject, planned change (hygiene graduates the row)
- ripple #2: `vignettes/publishing.Rmd`, README.md, and `inst/template/index.qmd` give terminal render steps with no Windows note — follow-up, row "Note short Windows paths in the vignette"
- ripple #3: help, DESIGN.md, and NEWS say commands run "in the site folder" — reject, false (the long path is the same folder)
