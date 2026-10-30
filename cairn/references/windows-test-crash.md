# The crash of Windows test processes in CI (M080)

**Provenance.** Ingested 2026-10-30 by M080 from the logs of R-CMD-check runs of jmgirard/supplement, read with `gh run view <run> --job <job> --log`. The other input is the `Windows-X64-rrelease-0-results` artifact of each crashed run.
Pagination: —.
Extraction: first-hand record, nothing to re-verify against — observed 2026-10-30.

**Scope.** This page records what is known about the access violation that ended two testthat worker processes on windows-latest. It is the evidence for a later trace, not a fix and not a source summary. It is a reference, not an authority. Status lives in `ROADMAP.md`, decisions in `DECISIONS.md`, and architecture in `DESIGN.md`.

**Evidence snapshot.**

- The search listed the R-CMD-check runs created from 2026-10-19 to 2026-10-29 that failed or ran more than once: 52 runs. It read every attempt of each one's windows-latest job, 57 job attempts in all, and searched each log for `-1073741819` — observed 2026-10-30.
- All R-CMD-check runs in that window: 397 completed runs, so 397 or more Windows job attempts — observed 2026-10-30.
- The artifacts of runs 40310323002 and 40661210581 hold `tests/testthat.Rout.fail` and no dump — observed 2026-10-30.

## The crashes the search found

| # | Run | Attempt | Job | Date | Commit | Test file |
|---|---|---|---|---|---|---|
| C1 | 40310323002 | 1 | 121529579093 | 2026-10-26 | 4fad253 (main, `plan M060`) | `test-create-supplement.R` |
| C2 | 40661210581 | 1 | 122724404038 | 2026-10-28 | 92a82bc (main, `review M070: done`) | `test-renv.R` |

Both jobs ran R 4.6.1 (2026-06-24 ucrt), testthat 3.3.2, callr 3.8.0, and processx 3.9.0, on runner image `windows-2025-vs2026` version 20261021.278.1. Both commits changed only `cairn/` files, so the package code and tests were the same as in runs that passed.

## What the logs show

R CMD check printed "testthat subprocess exited in file '<file>'" and "R session crashed with exit code -1073741819". That code is 0xC0000005, an access violation. The process that crashed is one of the 4 testthat worker processes (`TESTTHAT_CPUS: 4`), which callr starts. The main test process stopped at once, so the check reports no test counts.

In C1 the crash came 283 s into the tests. In both `testthat.Rout.fail` files, the last output of the crashed file is a blank line after its name. So the logs do not say which test ran. Each of the two files calls `run_in(site, "quarto", "render")` once, and 6 other test files call it too. Nothing in the logs says whether the crash was in R itself, in a package's compiled code, or at the worker's exit.

## What would trace it

A crash dump of the worker process names the module and the offset of the fault. A log of the test that the process started names the R code that ran. M080 adds both to the Windows CI job. The next step lives in the ROADMAP row "Read the next Windows crash dump".
