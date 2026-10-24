# M052: Drop the Windows Quarto cache in tests

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — test helpers in `tests/testthat` only
- **Branch/PR:** m052-drop-windows-quarto-cache

## Goal

The test helpers stop giving each Windows test process its own Quarto cache folder, since the template's project scripts are Lua and no test runs a Deno script.

## Scope

**In:** Remove `quarto_cache_env()` from `tests/testthat/helper-template.R` and its calls in `run_in()` and `run_split()`. Update the DESIGN.md paragraph on the two helpers. A search shows that no test hands Quarto a `.ts` or `.js` script.

**Out:** A check that fails a test render that starts Deno (the user declined it at the plan; the template test "a full render runs the project scripts through Pandoc and starts no Deno" stays the guard for the template). A count or log of Sass lock reruns (candidate row "Log render retries after a cache lock"). The `env` argument of `run_in()` (candidate row "Settle the env argument of run_in").

## Acceptance criteria

- [x] AC1: `tests/testthat/helper-template.R` has no `quarto_cache_env()` function, and neither `run_in()` nor `run_split()` sets `LOCALAPPDATA`; `grep -rn -e quarto_cache_env -e LOCALAPPDATA R tests` lists only lines of `R/check-tools.R` and `tests/testthat/test-check-tools.R`.
- [x] AC2: `grep -rnE '\.(ts|js)([^A-Za-z]|$)' tests/testthat inst/template` and `grep -rn '"run"' tests/testthat` list only `tests/testthat/test-renv.R:38` (a debug-log string), `tests/testthat/test-check-supplement.R:759` and `:766` (an HTML `<script>` link), and `tests/testthat/test-write-dockerfile.R:278` (`docker run`), and `find inst/template -name '*.ts' -o -name '*.js'` lists nothing.
- [ ] AC3: `devtools::test()` passes on the Mac, and the R-CMD-check workflow's Windows job passes on the PR's head commit.
- [x] AC4: The DESIGN.md paragraph on `run_in()` and `run_split()` no longer says that they give each Windows test process its own Quarto cache or points at the candidate row "Drop the Windows Quarto cache in tests", and says that they set no Quarto cache folder, so test processes share the user's Quarto cache, whose Sass database the "database is locked" rerun covers.

## Coverage

- AC1 → T2
- AC2 → T1
- AC3 → T4
- AC4 → T3

## Tasks

- [x] T1: Run the AC2 searches and write one work-log line that classifies each listed line as a string no test hands Quarto as a script.
- [x] T2: In `tests/testthat/helper-template.R`, delete `quarto_cache_env()` and its comment block (about lines 71-84), and drop the `cache` variable from `run_in()` (about line 48) and `run_split()` (about line 302), keeping the `QUARTO_LOG_LEVEL` setting and the Sass lock rerun.
- [x] T3: Rewrite the helper paragraph in `cairn/DESIGN.md` (about lines 245-256) to the AC4 wording.
- [x] T4: Run `Rscript -e 'devtools::test()'` on the Mac; the Windows CI job runs at review. If that job fails with "database is locked" twice on one render, return to plan to keep the helper with the Sass reason.

## Work log

- 2026-10-24: created by /milestone-plan.
- 2026-10-24: tier check: milestone — it changes test code and needs a search of the tests first, so it is not a no-runtime edit.
- 2026-10-24: idea vet: one concern — the Windows `LOCALAPPDATA` override also gives each test process its own Sass cache (`quartoCacheDir("sass")` in Quarto 1.10.19's `quarto.js`), so dropping it makes Windows tests share the Sass cache; answered at the question set: drop it, as macOS and Linux tests already share it with the one-time rerun.
- 2026-10-24: collision check: absorbs the candidate row "Drop the Windows Quarto cache in tests"; M033 (done) added the helper; D-020 and D-023 hold as they are; no D-entry rejects this.
- 2026-10-24: inbox sweep: 0 open issues and 0 open PRs on jmgirard/supplement.
- 2026-10-24: investigation: in Quarto 1.10.19 only `denoRunHandler` (for `.ts` and `.js` project scripts, `quarto run`, and notebook filters) calls `initDenoCache()`, which removes and copies `deno_std`.
- 2026-10-24: criteria audit (reduced mode, fresh Opus reader): AC2 promised what tests write or render, a runtime domain the searches do not enumerate, so it now names the fixed list of hits and adds `inst/template`; AC3 narrowed from three CI jobs to the Windows job, where the change acts; AC4 narrowed to what the helpers do and also drops the pointer to the candidate row; AC1 had no finding.
- 2026-10-24: question set: drop the cache override with Windows sharing the Sass cache — drop it; add a guard that fails a render that starts Deno — no guard.
- 2026-10-24: plan gate chose dropping the helper over keeping it for Sass isolation on Windows because macOS and Linux tests already share the Sass cache with the one-time rerun; falsified by a Windows CI render that fails with "database is locked" twice in a row.
- 2026-10-24: changelog: no NEWS entry, since only test helpers change.
- 2026-10-24: implement started on branch m052-drop-windows-quarto-cache, cut from main at df7c223.
- 2026-10-24: T1: the AC2 searches list 4 lines and `find` lists nothing; `test-renv.R:38` is a debug-log string that `r_process_lines()` must drop, `test-check-supplement.R:759` and `:766` are an HTML `<script src="gone.js">` link and its broken-link row, and `test-write-dockerfile.R:278` is the `docker run` argument of a Linux container render; no test hands Quarto any of them as a script.
- 2026-10-24: checkpoint: T2 and T3 edits made (helper removed, `run_split()` keeps `with_dir()` only; DESIGN.md paragraph rewritten), boxes left open until the running `devtools::test()` passes.
- 2026-10-24: T2-T4: `devtools::test(reporter = "silent")` on the Mac at f4c5572: 390 tests, 0 failed, 0 errors, 10 skipped (2 test processes); the Windows CI job runs at review.
- 2026-10-24: claim audit: not owed — internal tier
- 2026-10-24: status review: all tasks done, handed to /milestone-review.

## Decisions

## Review

- 2026-10-24 AC1: at a734e5f, `grep -n "quarto_cache_env\|LOCALAPPDATA" tests/testthat/helper-template.R` lists nothing, and `grep -rn -e quarto_cache_env -e LOCALAPPDATA R tests` lists only `R/check-tools.R:55`, `R/check-tools.R:194`, and `tests/testthat/test-check-tools.R:90`; `run_in()` passes `log_level` alone to `withr::with_envvar()` and `run_split()` calls `system2()` inside `withr::with_dir()` only. Pass.
- 2026-10-24 AC2: at a734e5f, the two greps list exactly `test-renv.R:38`, `test-check-supplement.R:759`, `test-check-supplement.R:766`, and `test-write-dockerfile.R:278`, and `find inst/template -name '*.ts' -o -name '*.js'` lists nothing. Pass.
- 2026-10-24 AC4: `cairn/DESIGN.md:249-253` now says that both helpers set no Quarto cache folder, so on every system the test processes share the user's Quarto cache, and that the "database is locked" rerun covers its Sass database; the per-process Windows cache sentence and the candidate-row pointer are gone. Pass.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: Windows Sass lock risk is untested until the Windows CI job runs — reject (planned change: the user accepted the shared Sass cache at the plan, and the Windows job is AC3's evidence at the merge step).
- diff-bug #2: the renv render in `test-renv.R` now writes renv's sandbox under the user's real `LOCALAPPDATA` renv folder on Windows, as it already did on macOS and Linux — follow-up (candidate row "Keep renv render tests in temp folders").
- diff-bug #3: the codepage token, editor lookup, and `R_LIBS_USER` under the real `LOCALAPPDATA` do no harm — reject (false: the reviewer reports no defect).
- diff-bug #4: `with_envvar()` with an empty vector and `run_split()`'s `with_dir()` form behave as before — reject (false: no defect).
- diff-bug #5: docs and tracking hold; no tests owed for a helper removal — reject (false: no defect).
- blame-history #1: with the helper gone and DESIGN.md silent on Deno, a future test with a `.ts` or `.js` project script would bring back the Windows `deno_std` clash with no note — fix now (DESIGN.md sentence naming the clash and its cause), fixed e4aff7e.
- blame-history #2: the M033 Windows fix is reverted with only Mac evidence so far — reject (planned change: the Windows job runs at the merge step and AC3 ticks only on it).
- blame-history #3: the Sass database is now shared on Windows with no Windows rate on record — follow-up (candidate row "Measure Sass lock reruns on Windows").
- blame-history #4: the change reverses a D-020 trade-off with no D-entry — reject (false: D-020 records parallel tests and the Windows loop skips, not the cache override, and parallel tests stay).
- blame-history #5: DESIGN.md edit matches the code — reject (false: no defect).
- prior-review #1: the diff reverts the helper M033 added after two red Windows runs — reject (planned change: M048's Lua scripts removed the Deno path, and the plan names a falsifier).
- prior-review #2: the unlogged Sass rerun is now the only Windows guard — follow-up (candidate row "Measure Sass lock reruns on Windows", which points at "Log render retries after a cache lock").
- prior-review #3: no LESSONS line keeps the helper's rationale — reject (false: the diff changes no LESSONS line, and DESIGN.md now states the Deno clash and its cause).
- ripple #1: DESIGN.md's "no test relies on state that another test file sets" sits beside the shared-cache sentence — reject (false: no test reads the cache's contents, and macOS and Linux tests shared it before the diff).
- ripple #2: the `rendered_site()` comment "no test changes what another test sees" — reject (false: it speaks of each test's copy of the rendered site, which the diff does not touch).
