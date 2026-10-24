# M048: Run the template scripts without Deno

- **Status:** in-progress
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

- [ ] AC1: `inst/template/_quarto.yml` sets `pre-render: _scripts/setup.lua` and `post-render: _scripts/nojekyll.lua`, and `git ls-files 'inst/template/*.ts'` lists nothing.
- [ ] AC2: A test in `tests/testthat/test-template.R` runs a full `quarto render` of a site made by `create_supplement()` with `QUARTO_LOG_LEVEL=DEBUG` and asserts that it exits 0 and writes `docs/.nojekyll`; off Windows it also asserts that the output holds a line containing `--lua-filter _scripts/setup.lua`, a line containing `--lua-filter _scripts/nojekyll.lua`, and no line matching `deno(\.exe)?"? run`.
- [ ] AC3: A render with `setup.lua` gives these results, each case run by a test in `tests/testthat/`, where an existing `.gitignore` means the file as the script finds it, after Quarto's own `.gitignore` step: (1) `_gitignore` and no `.gitignore`: `_gitignore` is renamed to `.gitignore` with its bytes; (2) `_gitignore` and an existing `.gitignore`: the existing file's bytes are the new file's prefix, followed by the non-blank `_gitignore` lines other than `!docs/` and `!_freeze/` that the file lacks, in `_gitignore` order, then `!docs/` and `!_freeze/`, each appended line ending in LF, and `_gitignore` is removed; (3) in (2), `!docs/` and `!_freeze/` are left off only when no other line is appended and the existing file's last two non-blank lines are `!docs/` then `!_freeze/`, so they are appended even when the file holds them on earlier lines; (4) in (2), lines are compared after splitting on CRLF or LF, and one LF goes before the appended lines when the existing file lacks a final line break, and none when it ends in LF; (5) an existing `.gitignore` that holds every `_gitignore` line and whose last two non-blank lines are `!docs/` then `!_freeze/` keeps its bytes; (6) no `README.md`: `_README.md` is renamed to `README.md` with its bytes; (7) a `README.md` and no `SUPPLEMENT.md`: `_README.md` becomes `SUPPLEMENT.md`; (8) both present: `_README.md` is removed; in (7) and (8) `README.md` and `SUPPLEMENT.md` keep their bytes; (9) from a `.gitignore` of the LF lines `mine`, `/.quarto/`, and `**/*.quarto_ipynb` and a `README.md`, a second full render leaves `.gitignore`, `README.md`, and `SUPPLEMENT.md` with the bytes the first render left; (10) with a folder named `_gitignore` beside an existing `.gitignore`, or with a read-only existing `.gitignore` that lacks a template line, the render exits with a status other than 0, its output holds `Error running filter '_scripts/setup.lua'`, and `.gitignore` keeps its bytes.
- [ ] AC4: The tests of AC2 and AC3 run without skipping and pass on the Windows, macOS, and Ubuntu jobs of the R-CMD-check workflow, and a test, run on all three jobs, renders a site with an existing `.gitignore` and `README.md` under a folder path that holds `é`, and asserts the results of AC3 cases (2) and (7) and that `docs/.nojekyll` exists.
- [ ] AC5: `git grep -n -E 'setup\.ts|nojekyll\.ts' -- . ':!cairn' ':!NEWS.md'` lists no line.
- [ ] AC6: `NEWS.md` has one bullet saying that the template's project scripts are now Lua files that Quarto runs through Pandoc with no Deno process, and that a site made earlier switches by copying `setup.lua` and `nojekyll.lua` from `system.file("template", "_scripts", package = "supplement")` into its `_scripts/` folder, changing the `pre-render` and `post-render` lines of `_quarto.yml`, and deleting the two `.ts` files.

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
- [ ] T6: Write `cairn/references/deno-script-crash.md` and its `INDEX.md` line from the macOS crash reports in `~/Library/Logs/DiagnosticReports/deno-*.ips`, CI run 39891081546, and the 2026-10-23 loops. Download the Deno 2.7.14 aarch64-apple-darwin symbol file from Deno's GitHub release page into the scratch folder and name the crashing functions if it resolves them. Draft the quarto-cli issue in the note, show the draft to the user, and post it only on the user's yes.
- [ ] T7: `devtools::test()` and `devtools::check()` clean on the Mac; CI on all three systems at review.

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

## Decisions

## Review
