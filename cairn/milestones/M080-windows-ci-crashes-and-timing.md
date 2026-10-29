# M080: Catch Windows test crashes and fix time bounds

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — CI steps and test helpers that no user of the package relies on
- **Branch/PR:** m080-windows-ci-crashes-and-timing

## Goal

Windows CI keeps a trace of each crash of a test process, and the timed tests pass at Windows speed.

## Scope

**In:** A Windows-only step of `.github/workflows/R-CMD-check.yaml` turns on Windows Error Reporting crash dumps before the check. A step after the check reads each dump, prints where the crash happened, and uploads the dumps. Each Windows CI test process logs each test it starts, so a dump can be matched to the last test that started. A `workflow_dispatch` input plants a crash, to show the steps work. A reference page records the two crashes seen so far. One test helper gives Windows 5 times the time bound of each timed test.

**Out:** Finding and fixing the cause of the crash. This waits for a dump, which comes in about 1 of 200 Windows jobs, and lives in the new parked row "Read the next Windows crash dump". A loop that tries to cause the crash now (declined at the plan question set). Speeding up the generated-pages test, which has no time bound (no row: it takes time and fails nothing). The Sass lock rows "Measure Sass lock reruns on Windows" and "Log render retries after a cache lock", which stay as they are.

## Acceptance criteria

- [ ] AC1: On windows-latest, `.github/workflows/R-CMD-check.yaml` turns on Windows Error Reporting crash dumps for every program before the check step. A step after the check runs whether the check passed or failed. For each `.dmp` file in the dump folder, it prints the program name, the process id, the exception code, and the module that holds the fault address, with the offset into that module. If no loaded module holds the address, it prints the address and a note that no module holds it. If the folder holds no `.dmp` file, the step prints one line that says so.
- [ ] AC2: In a Windows CI run, each test process writes the file and the name of each test into a log named by its process id, before the test starts. For each dump whose process id matches a log, the AC1 step prints that log's last line. For any other dump, it prints that no log matches.
- [ ] AC3: If the dump folder holds a `.dmp` file, the job uploads the folder as an artifact.
- [ ] AC4: `cairn/references/windows-test-crash.md` lists each crash that a search finds. The search reads the logs of every attempt of the windows-latest job of R-CMD-check runs from 2026-10-19 to 2026-10-29 that failed, for exit code -1073741819. Each entry gives the run, the attempt, the job, the date, the commit, the test file, and the R, testthat, callr, and processx versions. The page states how many job attempts the search read, and `cairn/references/INDEX.md` carries its line.
- [ ] AC5: Each line that `grep -n 'system.time(' tests/testthat/*.R` lists stores a time that its test compares with a bound from one helper in `tests/testthat/helper-*.R`. On Windows the helper returns 5 times the bound a test passes it, and on other systems it returns that bound unchanged.
- [ ] AC6: `devtools::test()` is clean on macOS, and the three R-CMD-check jobs pass on the PR head.

## Coverage

- AC1 → T2, T4, T7
- AC2 → T3, T4, T7
- AC3 → T2, T7
- AC4 → T1
- AC5 → T5
- AC6 → T7

## Tasks

- [x] T1: Write `cairn/references/windows-test-crash.md` from the synthesis-note template, with `cairn/references/deno-script-crash.md` as a model. List the failed runs of R-CMD-check from 2026-10-19 to 2026-10-29, read every attempt of each one's windows-latest job (`gh api repos/jmgirard/supplement/actions/runs/<id>/attempts/<n>/jobs`, then the job log), and search each log for `-1073741819`. Record each hit (the plan search found run 40310323002 in `test-create-supplement.R` and run 40661210581 in `test-renv.R`, both attempt 1, on commits 4fad253 and 92a82bc that changed only `cairn/` files), the versions from the job's session info, and the count of job attempts read. Add the INDEX line.
- [ ] T2: In `R-CMD-check.yaml`, add a Windows-only step before the check that sets the `LocalDumps` key under `HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting` (no program subkey, so every program) with `DumpFolder` under `$RUNNER_TEMP` and `DumpType` 1. Add an `if: always()` Windows step after the check that reads each `.dmp`: program and process id from the `<program>.<pid>.dmp` name, then the exception code and the module that holds the fault address. Use `cdb.exe` if the runner image has it. Otherwise read the minidump's exception and module-list streams with a small stdlib Python script in `.github/scripts/`. Install no tool. Add an upload step, by version tag (D-027), that runs only when a `.dmp` exists.
- [ ] T3: Add a test helper that, only when `CI` is `true` on Windows and the workflow sets a log-folder variable, uses `testthat::set_state_inspector()` to append `<file> <test name>` to `<folder>/<pid>.log` before each test. Read the test name from the calling `test_that()` frame through its `desc` argument, not testthat internals. The T2 step prints the last line of the log that matches each dump's process id, or that no log matches.
- [ ] T4: Add a `workflow_dispatch` boolean input that plants a crash. The workflow compiles `.github/scripts/plant-crash.c` (one function that writes through a null pointer) with `R CMD SHLIB` and sets a variable naming the DLL. A test file that skips unless that variable is set loads the DLL and calls the function. Keep the input after the merge, off by default.
- [ ] T5: Add the bound helper, for example `time_bound(seconds)`, to a `helper-*.R` file. Its comment ties the factor 5 to its measurements: windows-latest took 10.91 s for one `check_supplement()` call where macOS took 2.33 s (M076), and 10.19 s for the test at `test-check-supplement.R:1340` in run 40953514637, where macOS took 4.06 s. Pass each `expect_lt(time, 10)` in `test-check-supplement.R` (lines 1352, 1358, 1544, 1558) through it. Run the grep of AC5 and record its hits.
- [ ] T6: Update the CI paragraph of `cairn/DESIGN.md` (lines 400 to 410) for the dump, log, and plant steps. Write D-040, "Windows CI keeps crash dumps and logs each test a process starts (extends D-020)", with the plant input and the bound helper in its consequences.
- [ ] T7: Run `devtools::test()` on macOS. Push the branch, then start two `gh workflow run R-CMD-check.yaml --ref <branch>` runs, one with the plant input and one without. Record in the Review evidence what the dump step printed in each: the planted module and offset with the planted test in the first, and the no-dump line in the second. The normal push run gives the three jobs for AC6.

## Work log

- 2026-10-30: created by /milestone-plan.
- 2026-10-30: tier check: milestone — the cause is unknown and the work changes CI and test helpers over more than one sitting.
- 2026-10-30: idea vet: gap — the request names the create tests, but the crash came back on 2026-10-28 in `test-renv.R` (run 40661210581), so the plan covers a crash of any Windows test process; gap — a trace needs a crash, which comes in 2 of about 400 Windows jobs, so the plan took the reading that catches the next crash, and the question set confirmed it; no flaw.
- 2026-10-30: collision check: candidate "Trace the Windows crash in create tests" absorbed in full; candidate "Time the large-page tests on Windows" absorbed in full at the user's choice; the two Sass lock rows cross-referenced as distinct; `cairn/references/deno-script-crash.md` (M048, a macOS Deno crash) is a different crash and serves as the page model; D-016 and D-020 extended by T6; D-035 not touched, since the plant is test code.
- 2026-10-30: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-30: lessons used: 2026-10-29 (M076, used M079) on the Windows time factor; 2026-10-28 (M068, used M079) on pushes that rerun all 9 checks and the 10-minute watch limit; 2026-10-29 (M079) on `gh run rerun --failed`.
- 2026-10-30: criteria audit (reduced mode, Opus fresh reader): 3 findings on AC1 to AC5 of the first draft, all taken (AC2 limited to dumps whose process id matches a log, AC4 reads every attempt, AC1 adds the no-module case); 1 finding on the added timing criterion, taken (the grep is `system.time(`, and the promise binds to the lines it lists).
- 2026-10-30: question set: what to deliver — catch the next crash (dumps, module, last test), no stress loop.
- 2026-10-30: question set: fold in "Time the large-page tests on Windows" — fold it in; one milestone with a goal in two parts, at the user's choice over the split tripwire.
- 2026-10-30: question set: push the branch and start two manual CI runs before review — yes.
- 2026-10-30: plan chose a factor-5 bound on Windows over skipping the time checks there (D-020 style) because a skip drops the guard against time that grows with the square of the input; falsified by a Windows run past the widened bound with no code change, or a slowdown factor above 5 on record.
- 2026-10-30: plan chose reading dumps with `cdb.exe` or a stdlib script over installing a debugger in CI because no new tool enters the workflow; falsified by an image with no `cdb.exe` where the script cannot read the exception stream.
- 2026-10-30: T1 done: the search read 57 windows-latest job attempts of the 52 R-CMD-check runs from 2026-10-19 to 2026-10-29 that failed or ran more than once, and found the two crashes the plan named; `cairn/references/windows-test-crash.md` and its INDEX line written.
