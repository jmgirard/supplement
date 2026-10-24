# M052: Drop the Windows Quarto cache in tests

**Status:** done (2026-10-24, PR #53 https://github.com/jmgirard/supplement/pull/53)

**Goal:** The test helpers stop giving each Windows test process its own Quarto cache folder, since the template's project scripts are Lua and no test runs a Deno script.

**Outcome:** `quarto_cache_env()` is gone from `tests/testthat/helper-template.R`, so `run_in()` sets only `QUARTO_LOG_LEVEL` through `withr::with_envvar()` and `run_split()` runs `system2()` inside `withr::with_dir()` alone; neither sets `LOCALAPPDATA`. Windows test processes now share the user's Quarto cache, Sass database included, as macOS and Linux ones did, and the one-time rerun on "database is locked" stays. In Quarto 1.10.19 only `denoRunHandler` (`.ts` and `.js` project scripts, `quarto run`, notebook filters) calls `initDenoCache()`, which removes and copies `deno_std`; a search of `tests/testthat` and `inst/template` found no such script. DESIGN.md's helper paragraph says the helpers set no cache folder and that a `.ts` or `.js` test script would bring back the Windows `deno_std` clash (M033). No NEWS entry: test helpers only. The user declined a guard that fails a render that starts Deno; the template test "a full render runs the project scripts through Pandoc and starts no Deno" stays.

**Decisions:** none. The plan chose dropping the helper over keeping it for Sass isolation on Windows; a Windows render that fails with "database is locked" twice in a row would falsify that.

**Review:** Four-lens review: 16 findings, 1 fixed (e4aff7e: the DESIGN.md `deno_std` sentence), 3 follow-up (new rows "Keep renv render tests in temp folders" and "Measure Sass lock reruns on Windows"), 12 rejected (5 planned, 7 false). Mac suite 390 tests, 0 failed; `devtools::check()` 0/0/1 (a local `.claude/` lock file); CI green on six jobs, both Windows jobs included. The CI wait hit the tool ceiling once and resumed. Graduated the candidate "Drop the Windows Quarto cache in tests". No LESSONS line (file at 49 lines, 19,876 bytes).
