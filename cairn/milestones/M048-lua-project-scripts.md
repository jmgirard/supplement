# M048: Run the template scripts without Deno

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the template's project scripts ship to every new site
- **Branch/PR:** m048-lua-project-scripts

## Goal

A render of a site made from the template runs its two project scripts in Lua through Pandoc, so the render starts no Deno process and the macOS Deno crash (exit 139) cannot fail it there.

## Scope

**In:**
- `inst/template/_scripts/setup.lua` and `nojekyll.lua` replace `setup.ts` and `nojekyll.ts`, with the behavior D-004 and D-006 give them (D-023), and `inst/template/_quarto.yml` names them.
- Tests for each setup case, the no-Deno render, a script failure's exit code, and a site folder whose path holds `é`.
- Every mention of the old script names outside `cairn/` and `NEWS.md`, the template guide's script lines (`inst/template/_README.md` near line 272), the DESIGN.md template entries, and one NEWS bullet.
- The crash write-up `cairn/references/deno-script-crash.md` (synthesis note) with Deno's symbols, and a drafted issue for quarto-dev/quarto-cli, posted only after the user reads the draft.

**Out:**
- Sites made before this change: no helper; the NEWS bullet says how to switch.
- The Windows per-process Quarto cache in the tests (`quarto_cache_env()` in `helper-template.R`): the new candidate row "Drop the Windows Quarto cache in tests".
- A fix inside Deno or Quarto: upstream, through the issue this milestone drafts.
- The template test flake (`setup.ts` renders that exit 1): the row "template test flake" stays; review narrows it only on evidence.
- Quarto versions below 1.10: recorded as untested in DESIGN.md Known issues, no test.

## Acceptance criteria

- [x] AC1: `inst/template/_quarto.yml` sets `pre-render: _scripts/setup.lua` and `post-render: _scripts/nojekyll.lua`, and `git ls-files 'inst/template/*.ts'` lists nothing.
- [x] AC2: A test in `tests/testthat/test-template.R` runs a full `quarto render` of a site made by `create_supplement()` with `QUARTO_LOG_LEVEL=DEBUG` and asserts that it exits 0 and writes `docs/.nojekyll`; off Windows it also asserts that the output holds a line containing `--lua-filter _scripts/setup.lua`, a line containing `--lua-filter _scripts/nojekyll.lua`, and no line matching `deno(\.exe)?"? run`.
- [x] AC3: A render with `setup.lua` gives these results, each case run by a test in `tests/testthat/`, where an existing `.gitignore` means the file as the script finds it, after Quarto's own `.gitignore` step: (1) `_gitignore` and no `.gitignore`: `_gitignore` is renamed to `.gitignore` with its bytes; (2) `_gitignore` and an existing `.gitignore`: the existing file's bytes are the new file's prefix, followed by the non-blank `_gitignore` lines other than `!docs/` and `!_freeze/` that the file lacks, in `_gitignore` order, then `!docs/` and `!_freeze/`, each appended line ending in LF, and `_gitignore` is removed; (3) in (2), `!docs/` and `!_freeze/` are left off only when no other line is appended and the existing file's last two non-blank lines are `!docs/` then `!_freeze/`, so they are appended even when the file holds them on earlier lines; (4) in (2), lines are compared after splitting on CRLF or LF, and one LF goes before the appended lines when the existing file lacks a final line break, and none when it ends in LF; (5) an existing `.gitignore` that holds every `_gitignore` line and whose last two non-blank lines are `!docs/` then `!_freeze/` keeps its bytes; (6) no `README.md`: `_README.md` is renamed to `README.md` with its bytes; (7) a `README.md` and no `SUPPLEMENT.md`: `_README.md` becomes `SUPPLEMENT.md`; (8) both present: `_README.md` is removed; in (7) and (8) `README.md` and `SUPPLEMENT.md` keep their bytes; (9) from a `.gitignore` of the LF lines `mine`, `/.quarto/`, and `**/*.quarto_ipynb` and a `README.md`, a second full render leaves `.gitignore`, `README.md`, and `SUPPLEMENT.md` with the bytes the first render left; (10) with a folder named `_gitignore` beside an existing `.gitignore`, or with a read-only existing `.gitignore` that lacks a template line, the render exits with a status other than 0, its output holds `Error running filter '_scripts/setup.lua'`, and `.gitignore` keeps its bytes.
- [ ] AC4: The tests of AC2 and AC3 run without skipping and pass on the Windows, macOS, and Ubuntu jobs of the R-CMD-check workflow, and a test, run on all three jobs, renders a site with an existing `.gitignore` and `README.md` under a folder path that holds `é`, and asserts the results of AC3 cases (2) and (7) and that `docs/.nojekyll` exists.
- [x] AC5: `git grep -n -E 'setup\.ts|nojekyll\.ts' -- . ':!cairn' ':!NEWS.md'` lists no line.
- [x] AC6: `NEWS.md` has one bullet saying that the template's project scripts are now Lua files that Quarto runs through Pandoc with no Deno process, and that a site made earlier switches by copying `setup.lua` and `nojekyll.lua` from `system.file("template", "_scripts", package = "supplement")` into its `_scripts/` folder, changing the `pre-render` and `post-render` lines of `_quarto.yml`, and deleting the two `.ts` files.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T1, T3
- AC4 → T2, T3, T7
- AC5 → T4, T5
- AC6 → T5

## Tasks

- [x] T1: Write `inst/template/_scripts/setup.lua` and `nojekyll.lua` from the `.ts` files: use file names relative to the project folder, where Quarto runs the script, read `QUARTO_PROJECT_OUTPUT_DIR` with `os.getenv()`, test whether a file exists by the error number of `io.open()` (only error 2, no such file, reads as missing, so an unreadable file never does), open files in binary mode (`rb`, `wb`, `ab`) so Windows never turns LF into CRLF, and make every failed rename, remove, or write stop the script with `error()` (Pandoc then exits 83). Switch `_quarto.yml`, delete the `.ts` files, and update the file list in `tests/testthat/test-create-supplement.R:7`. Run the template tests.
- [x] T2: Add the AC2 test. Show its log matcher fails on a site that keeps the default branch's `.ts` scripts and `_quarto.yml` lines (LESSONS M010 method), then restore.
- [x] T3: Map each AC3 case to a test in `test-template.R`, and add a test for each case none covers (CRLF and no-final-break prefixes compared as bytes with `writeBin()`, an empty `.gitignore`, an earlier `!docs/`, a complete one left as it is, the second render, a `.gitignore` folder). Add the `é` folder test of AC4.
- [x] T4: Port the exit-code test (`test-template.R:48`, `Deno.exit(3);`) to a `setup.lua` that calls `os.exit(3)`, keeping its `QUARTO_LOG_LEVEL=DEBUG` read of `code: 3`. Change the made-up Deno log line in `tests/testthat/test-renv.R:38` to a script name the template does not ship.
- [x] T5: Update `inst/template/_README.md`, the DESIGN.md template entries, and the Known issues sentence "`quarto-required: \">=1.4.0\"` is untested below 1.10" to cover the Lua scripts; add the NEWS bullet; run the AC5 grep.
- [x] T6: Write `cairn/references/deno-script-crash.md` and its `INDEX.md` line from the macOS crash reports in `~/Library/Logs/DiagnosticReports/deno-*.ips`, CI run 39891081546, and the 2026-10-23 loops. Download the Deno 2.7.14 aarch64-apple-darwin symbol file from Deno's GitHub release page into the scratch folder and name the crashing functions if it resolves them. Draft the quarto-cli issue in the note, show the draft to the user, and post it only on the user's yes.
- [x] T7: `devtools::test()` and `devtools::check()` clean on the Mac; CI on all three systems at review.

## Work log

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: milestone — the request names a crash with no known cause, and the chosen fix changes the shipped template's scripts and a recorded decision.
- 2026-10-23: idea vet: one concern, framing: tracing a crash inside Quarto's Deno, which ships without symbols and did not reproduce on demand, may end with no cause, so the set offered moving the scripts off Deno; the user asked for the Lua move's downsides (Windows non-ASCII paths, existence checks, older sites, untested Quarto versions) and chose the Lua move.
- 2026-10-23: investigation (inline): 18 crash reports dated 2026-10-18 to 2026-10-22 share one six-frame stack, a jump to address 0 in a `tokio-runtime-worker` thread, each process 39 to 100 ms old; CI run 39891081546 logged `deno run … _scripts/nojekyll.ts` then `Success: false, code: 139`; 400 serial and 2,000 parallel bare script runs and 300 parallel renders (600 script runs) gave no crash; a Lua post-render probe ran through `pandoc --lua-filter`, `os.exit(3)` gave `code: 3`, `error()` gave `code: 83`.
- 2026-10-23: plan gate chose Lua scripts over a trace-only milestone because the Lua move removes the Deno launch whatever the crash's cause; falsified by an exit-139 crash report from Pandoc or from Quarto's own process during renders with the Lua scripts.
- 2026-10-23: approach: existence through `pandoc.system.list_directory()` over opening the file, because an unreadable file opens as missing and would be renamed over; falsified by `list_directory()` failing on a non-ASCII folder on Windows.
- 2026-10-23: question set: outside actions — the user allowed downloading Deno's symbol file and posting an issue on quarto-dev/quarto-cli, the issue only after the user sees the draft.
- 2026-10-23: question set: older Quarto — record the Lua scripts as untested below 1.10 in DESIGN.md Known issues.
- 2026-10-23: criteria audit (full mode): 9 findings, all fixed: setup case list grown from 7 to 10 and corrected (last non-blank lines, byte prefix, LF ends); Deno matcher covers `deno.exe` and runs off Windows with positive `--lua-filter` lines; new exit-code criterion; the crash write-up moved from a criterion to T6; grep, DESIGN, D-entry, NEWS, and skip wording narrowed; older Quarto versions not promised.
- 2026-10-23: collisions: the candidate row "Trace the post-render crash on macOS" absorbed in full; "template test flake" cross-referenced (its `setup.ts` exit-1 failures may be this crash); D-004 and D-006 superseded by D-023 in the plan commit; inbox sweep found 0 open issues and 0 open PRs; added the low row "Drop the Windows Quarto cache in tests".
- 2026-10-23: lessons harvest: M010 (prove a test fails by copying main's file), M011 (`writeBin()` for byte edits), M019 and M020 (`[execProcess]` lines), M004 (Lua `error()` in filters only prints; project scripts exit 83). `LESSONS.md` is at 19,994 of 20,000 bytes, so a new lesson needs a trim first.
- 2026-10-23: second criteria audit (full mode, after the question set): 9 findings. Fixed 7: AC3 (2) and (3) reworded to setup.ts's real order and repeat rule, (4) gained the no-LF side, (10) added for a failed write; the planted `os.exit(3)` criterion dropped as a Quarto property (its test port stays in T4); the DESIGN wording and D-entry left AC5 (now the grep alone; D-023 is in the plan commit); the `é` test covers the merge and SUPPLEMENT cases; NEWS names where to copy from and the `.ts` deletion. Rejected 1: a Windows "no `deno` line" check, since Quarto can log a safe-exec batch file there, so the check passes with the `.ts` scripts in place. Already covered 1: Quarto below 1.10 is recorded as untested (Out, T5).
- 2026-10-23: implement started on branch m048-lua-project-scripts, cut from main at d8667fd.
- 2026-10-23: minor amendment to T1: Quarto 1.10.19 runs project scripts with `cwd: projDir` (quarto.js `runScripts`), so `setup.lua` uses relative names and reads no `QUARTO_PROJECT_DIR`, which keeps the site path out of its file calls; existence is read from `io.open()`'s error number instead of `pandoc.system.list_directory()`, because a listing compares names exactly while macOS and Windows ignore letter case, so `readme.md` would read as no `README.md` and be renamed over (the plan's approach line is falsified by this).
- 2026-10-23: T1 done: `setup.lua` and `nojekyll.lua` written, `_quarto.yml` switched, the `.ts` files removed, the template file list in `test-create-supplement.R` updated. "Non-blank" is Lua's `%s` (ASCII spaces), where `setup.ts`'s `trim()` also dropped Unicode spaces; a line of only Unicode spaces is now appended. `test-template.R` 40 tests, 0 failed after T4.
- 2026-10-23: T4 done (moved before T2, since T1's test run needed it): the exit-code test writes `os.exit(3)` to `setup.lua` and still reads `code: 3`; the `test-renv.R` fixture line names `_scripts/build.ts`. `test-renv.R` and `test-create-supplement.R` pass (2 Windows-only skips, as on main).
- 2026-10-23: T2 done: "a full render runs the project scripts through Pandoc and starts no Deno" passes (5 expectations); with main's `.ts` scripts and `_quarto.yml` copied back it failed 3 (both `--lua-filter` lines missing, the `deno run` lines matched) and passed the 2 status checks, then the files were restored.
- 2026-10-23: re-audit: AC3 (full) — 4 findings on the first amended wording (an existing `.gitignore` defined as the file after Quarto's own `.gitignore` step, the empty case dropped, (10) a `_gitignore` folder): (9) fails from case (1)'s start because the template's `.quarto/` is not Quarto's `/.quarto/`, so Quarto rewrites the file on render 2 (pre-existing; narrowed to the starts of (2) and (7), new row "Add Quarto's ignore lines to _gitignore"); (10) narrowed to the failed read the test makes; the fixture sentence moved to T3; Quarto's trim of a `.gitignore` lacking its lines goes in that row.
- 2026-10-23: T5 done: `_README.md` "Setup scripts" names the Lua scripts; DESIGN.md's convention line (corrected M048), template entries, and the shortcode Known issues sentence (Lua scripts untested below 1.10) updated; NEWS bullet added. AC5 grep lists no line (exit 1); DESIGN.md names neither `.ts` file. The simple-english hook flags a long sentence at `_README.md:171` that is on main, outside this change, so it stays.
- 2026-10-23: T6 started: Deno's v2.7.14 release has no symbol file for any system, so nothing was downloaded; the bundled binary is stripped (666 exported symbols, none at the crash frames). Disassembly: the frame at offset 29888468 follows `ldr x8, [x8, #0x5f8]; blr x8`, a call through a function pointer at `deno.__DATA.__data + 103928` (0x105df55f8), whose stored value in the binary is 0.
- 2026-10-23: re-audit: AC3 (full) — second reader, 6 findings on the fixed wording: (3) contradicts (5) for a file ending in the two lines that also holds `!docs/` earlier; (2)'s "unless" clause is wrong when other lines are appended; (10)'s "names `_scripts/setup.lua`" holds for every render (Quarto prints `Running script`); (10) drops failed writes, reachable with a read-only `.gitignore` (probed on macOS); (9) claims every start but one is tested; (1) and (6) are tested by existence only. This is AC3's second re-audit line, so the wording goes to the user.
- 2026-10-24: substantive amendment: AC3 reworded at the user's choice of the proposed text (over the same text without the read-only case, and over stopping): an existing `.gitignore` is the file after Quarto's own step, the empty case is gone, (3) says when the two lines are left off, (1) and (6) keep bytes, (9) names its tested start, (10) covers a failed read and a failed write and matches `Error running filter '_scripts/setup.lua'`. T3 gains the matching tests; each test `.gitignore` holds Quarto's two lines so Quarto leaves it as written.
- 2026-10-24: T3 done: cases (1), (6) "setup renames _gitignore and _README.md with their bytes"; (2) to (5) "setup appends the template's missing lines after the existing bytes" (6 inputs, 18 expectations); (7), (8) "setup leaves the bytes of an existing README.md and SUPPLEMENT.md"; (9) "a second render leaves the files that setup wrote"; (10) "a setup step that fails stops the render and names the script" (a `_gitignore` folder and a read-only `.gitignore`); AC4's "the scripts run in a site folder whose path holds a non-ASCII letter". Planted defects in `setup.lua` (no separator, the two lines always appended, no check for present lines) failed the append test 1, 1, and 5 times; main's `setup.ts` passed the same cases (15 of 15, before the sixth input was added).
- 2026-10-24: T6 note written: `cairn/references/deno-script-crash.md` and its `INDEX.md` line, with the crash-report facts, the null function-pointer call, the loops that did not reproduce it, and the draft quarto-cli issue. The simple-english hook still flags the six `—` markers that the synthesis-note template requires. The draft goes to the user before any post.
- 2026-10-24: T6 done: a search of quarto-cli issues found #10426 (open, reopened 2026-10-20 by a maintainer who traced the crash to a SQLite start-up race in Deno on arm64) and denoland/deno#37045 (open, Deno 2.7.14, same faulting stack); the note records both. The user chose to post nothing (over a comment on #10426 and over the duplicate issue), so nothing went to GitHub.
- 2026-10-24: claim audit: 37 claims read, 2 corrected — NEWS.md, inst/template/_README.md, inst/template/_quarto.yml, inst/template/_scripts/setup.lua, inst/template/_scripts/nojekyll.lua, tests/testthat/test-template.R. Corrected: the no-Deno test's comment that Quarto on Windows can log a batch file in place of a script's command (in 1.10.19 `execProcess` logs `cmd` and `args`, and `safeWindowsExec` serves only reg.exe, unzip, tlmgr, fmtutil, and the browser), so the test now checks the log on every system, which also reverses the second plan audit's rejection of a Windows check; and the `appended()` comment. Open: the `é` test is unchecked on Windows until CI runs it.
- 2026-10-24: T7 done on the Mac: `devtools::test()` 392 tests, 0 failed, 0 errors, 10 skipped; `devtools::document()` no diff; `devtools::check()` 0 errors, 0 warnings, 0 notes. The crash-report count stayed at 18 through this session's renders. CI on the three systems runs at review. Status set to review.

## Decisions

## Review

Evidence at 22be1f2, branch level with origin/main d8667fd, 2026-10-24.

- AC1: `_quarto.yml:21-22` read `pre-render: _scripts/setup.lua` and `post-render: _scripts/nojekyll.lua`; `git ls-files 'inst/template/*.ts'` lists 0 files.
- AC2: "a full render runs the project scripts through Pandoc and starts no Deno" passed, 5 expectations (exit 0, `docs/.nojekyll`, both `--lua-filter` lines, no `deno run` line), with the log checks on every system since the claim audit. With main's `.ts` scripts copied back it failed its 3 log checks (T2).
- AC3: in a fresh `test-template.R` run, the tests T3 maps pass: cases (1) and (6) 5 expectations, (2) to (5) 18, (7) and (8) 8, (9) 3, (10) 6 (a `_gitignore` folder and a read-only `.gitignore`). Planted defects failed the append test (T3).
- AC5: `git grep -n -E 'setup\.ts|nojekyll\.ts' -- . ':!cairn' ':!NEWS.md'` printed nothing, exit 1.
- AC6: `NEWS.md:3-11` says the scripts are Lua files run through Pandoc with no Deno process, and gives the switch: copy both files from `system.file("template", "_scripts", package = "supplement")` into `_scripts/`, change the `pre-render` and `post-render` lines, delete the two `.ts` files.
- AC4 (local part): `test-template.R` 47 tests, 0 failed, 0 skipped on macOS, the `é` test (7 expectations) included. The Windows, macOS, and Ubuntu CI jobs run after the PR opens.
- Consistency gate: `cairn_validate.py` all checks passed; no principle changed, so no impact report; `devtools::document()` no diff; no README.Rmd and no pkgdown site; NEWS.md has the entry; no new top-level file; `devtools::check()` 0 errors, 0 warnings, 0 notes at 22be1f2 (T7; only `cairn/` changed since).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: `nojekyll.lua` opened the absolute `QUARTO_PROJECT_OUTPUT_DIR` through C `fopen`, which on Windows can fail on a name outside the code page where Deno used wide calls — fix now (it reads the path with `pandoc.system.environment()` and opens it relative to the project folder; a probe showed `docs` opened from `/private/tmp` and `/var/folders`)
- diff-bug #2: the `é` test cannot catch #1, since `é` is in Windows-1252 and `setup.lua` opens only relative names — fix now (the folder name also holds U+4E2D)
- diff-bug #3: on Windows a dangling `.gitignore` or `README.md` link now stops the render, where `Deno.renameSync` replaced it — reject, edge: a dangling link at a setup target in a new site is outside documented and common use, and the effect is an error
- diff-bug #4: `wb` truncates the author's `.gitignore` before writing, so a failed write loses its lines (as `setup.ts` did) — fix now (only the appended bytes are written, with `ab`)
- diff-bug #5: the failure test asserts no failure identity — fix now (it matches `_gitignore: Permission denied|Is a directory` and `\.gitignore: Permission denied`)
- diff-bug #6: the root skip covered the folder case too — fix now (it comes after that case)
- diff-bug #7: Pandoc prints one blank stdout line per script — reject, style: no wrong result, and Quarto prints its own blank line after the scripts (`info("")` in `runScripts`)
- diff-bug #8: AC2 says the log check runs off Windows while the test runs it everywhere — reject, false: the test meets AC2 as written
- diff-bug #9: the second-render test checks Quarto more than setup — reject, planned change (AC3 case 9)
- diff-bug #10: three older setup tests repeat the new byte tests with weaker checks and full R renders — fix now (removed: "setup adds the template rules to an existing .gitignore", "setup keeps an existing README.md and writes the guide beside it", "setup keeps both files when README.md and SUPPLEMENT.md exist")
- diff-bug #11: two append cases take the same branches — reject, planned change (AC3 case 3)
- diff-bug #12: the `é` test repeats covered branches — reject, planned change (AC4)
- blame-history #1: without `QUARTO_PROJECT_DIR`, setup does nothing in a render run from a subfolder — reject, false: a full render and `quarto render a.qmd` run from `analyses/` renamed both files and wrote `docs/.nojekyll`; `runScripts` passes `cwd: projDir`
- blame-history #2: Windows non-ASCII paths in `io.open` — fix now (diff-bug #1)
- blame-history #3: `exists()` treats any open error but error 2 as present, so an unsearchable path stops the render — reject, edge: an unreadable name in the site folder is outside documented and common use, the effect is an error, and the comment states it
- blame-history #4: the Windows cache rationale in `helper-template.R` and DESIGN.md is stale — fix now
- blame-history #5: the `test-renv.R` fixture names `_scripts/build.ts` — reject, planned change (T4 chose a name the template does not ship)
- prior-review #1: the M003 class of Windows path failure in `nojekyll.lua` — fix now (diff-bug #1)
- prior-review #2: M018's "Lua read error" fix may repeat — reject, false: that fix was in the shortcode extension's file reading, not a project script
- prior-review #3: the `helper-template.R` cache comment — fix now (blame-history #4)
- ripple #1: the candidate row "Trace the post-render crash on macOS" names `nojekyll.ts` — reject, planned change: hygiene removes the row the plan absorbed
- ripple #2: the row "Drop the Windows Quarto cache in tests" now holds its condition — reject, planned change: the row was written for after this merge
- ripple #3: `helper-template.R:71-72` — fix now (names TypeScript or JavaScript scripts)
- ripple #4: `cairn/DESIGN.md:251-253` — fix now (corrected M048, points to the row)
- ripple #5: the M019 lesson's `setup.ts` example — fix now (corrected M048: a TypeScript script prints only "Running script", a Lua one also prints Pandoc's error)
- ripple #6: the `test-renv.R` fixture name — reject, planned change (blame-history #5)
