<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M060: Tighten the missing report.R check

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate -->
- **Surface tier:** user-facing — it changes which rows `check_supplement()` gives site authors   <!-- owner: plan · create/amend-via-gate -->
- **Branch/PR:** m060-tighten-report-script-check   <!-- owner: implement (branch) / review (PR URL) · create -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

The `"missing-script"` row of `check_supplement()` counts a report line as naming `_scripts/report.R` only when one of the AC1 forms joins the two names, and it treats a file link to a missing file as missing on every system.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** the match rule of `names_script()` in `R/check-supplement.R`; the missing test of `check_missing_script()` for a file link on Windows; the tests in `tests/testthat/test-check-supplement.R`; the `check_supplement()` help page; the missing-script lines of `cairn/DESIGN.md`.

**Out:** a row when `_scripts/report.R` changed since the last render stays the candidate row "Flag reports after report.R changes". Broken Quarto links in `check_tools()` on Windows stay the candidate row "Report broken Quarto links on Windows". Two-line calls, included files, letter case, and disks that ignore letter case stay as limits that the help page states. NEWS.md gets no change, because the M059 bullet describes an unreleased check and stays true.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: For a site with no `_scripts/report.R`, `check_supplement()` counts a report line as naming the file by this rule alone. The line holds `_scripts` with no ASCII letter, digit, `_`, or `.` right before it, and any such `_scripts` on the line can start the match. A separator follows right away. One separator form is `/`, `\`, or `\\`. The other form is an optional `/`, `\`, or `\\`, then a `"` or `'`, a `,` with any spaces or tabs on each side, and a `"` or `'`. Then `report.R` follows, with no ASCII letter, digit, `_`, or `.` right after it. A site whose one report holds one of these lines gets the `"missing-script"` row: `source(file.path(site, "_scripts", "report.R"), local = TRUE)`, `# _scripts/report.R` as the last line of the report, `report.R, then _scripts/report.R`, `source(file.path(site, '_scripts' , 'report.R'))`, `_scripts\report.R`, `source("_scripts\\report.R")`, `file.path(site, "_scripts/", "report.R")`, `"_scripts",` then a tab then `'report.R'`, and `_scripts_old/x and _scripts/report.R`. A site whose one report holds one of these lines gets no such row: `source("_scripts_old/report.R")`, `source("_scripts/old-report.R")`, `file.path("_scripts", "x", "report.R")`, `source("_scripts/report.R.bak")`, and `See _scripts/report.R.`. The seven cases of the existing test "no missing-script row when the file is there or no report names it" also give no row.
- [x] AC2: A report line made of the template's `source()` line and 5 MB of other text gives the `"missing-script"` row with no warning from `check_supplement()`, with the `source()` line placed first and placed last. A report line of `"_scripts" ,` and 5 MB of spaces and tabs gives no warning and no row.
- [ ] AC3: If `_scripts/report.R` is a file link to a missing file and a report names it, `check_supplement()` gives the `"missing-script"` row on Windows, macOS, and Linux. If `_scripts/report.R` is a file link to an existing file, `check_supplement()` gives no `"missing-script"` row on Windows, macOS, and Linux.
- [x] AC4: The `check_supplement()` help page states the AC1 rule, says that a `.` right after `report.R`, as at the end of a sentence, stops the match, and states the AC3 link case. It no longer says that `_scripts` and a later `report.R` anywhere on a line count, and it no longer says that a Windows file link to a missing file gives no `"missing-script"` row.
- [ ] AC5: `devtools::document()` leaves no change, `devtools::test()` passes, `devtools::check()` gives 0 errors and 0 warnings, and the R-CMD-check workflow passes on Windows, macOS, and Ubuntu (D-016).

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T3, T5
- AC4 → T4, T5
- AC5 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive change is amend-via-gate. -->

- [x] T1: Write the tests first. Add the AC1 row lines and no-row lines and the AC2 lines to the missing-script tests in `tests/testthat/test-check-supplement.R` (near lines 656 to 727). Run them on the current code and record which fail.
- [x] T2: Rewrite `names_script()` (`R/check-supplement.R:758`) as one PCRE pattern with possessive runs for the spaces and tabs and no `.*`, and update its comment. Run `devtools::test()`.
- [x] T3: In the link test (`test-check-supplement.R:688`), replace `skip_on_os("windows")` with `symlink_or_skip()` (`tests/testthat/helper-files.R:150`). Add a test with a file link to an existing file. In `check_missing_script()`, the file also counts as missing if `is_link()` is TRUE and `fs::is_file()`, which follows the link, is FALSE. Review reads the Windows CI job's test output to see that the link tests ran there.
- [x] T4: Update the `"missing-script"` help text (`R/check-supplement.R:109` to `133`) and run `devtools::document()`. Update the missing-script lines of `cairn/DESIGN.md` (near line 168). Run `devtools::check()`.
- [x] T5: Review return 1. Replace the `fs::is_file()` link test in `check_missing_script()` with one that ends on a chain of links, expands `~` as R does, and keeps the `file.exists()` answer for a path that is not valid UTF-8 or that fs stops on. Add tests for a link to a link to an existing file and to a missing file. Narrow the possessive-run claim in the `names_script()` comment and DESIGN.md to "no `.*`", add to the help that any boundary `_scripts` can start the match, and correct the LESSONS.md 2026-10-26 (M059) line.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-26: created by /milestone-plan.
- 2026-10-26: tier check: not run — work named at the question set.
- 2026-10-26: idea vet: no concern. Both rows fix the M059 check against its own aim: a row only for reports that read the file, and a missing file read as missing on Windows too.
- 2026-10-26: question set: what to plan — "Tighten report.R check" (the rows "Match report.R names as whole paths" and "Flag dangling report.R links on Windows"); match rule — count a line only when a path separator or a quote-comma-quote run joins `_scripts` and `report.R`.
- 2026-10-26: lessons used: 2026-10-19 (M018, used M059) Windows file links, 2026-10-20 (M021, used M059) PCRE match limit and possessive repeats, 2026-10-26 (M059) a `.*` pattern between two names passes the match limit.
- 2026-10-26: collision check: absorbs candidates "Match report.R names as whole paths" and "Flag dangling report.R links on Windows"; extends M059 (done); distinct from "Flag reports after report.R changes" and "Report broken Quarto links on Windows" (Scope Out); works under D-022 (fs imported, no dependency change) and D-028, no conflict; inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-26: plan gate chose `fs::is_file()` on a link over opening the file for reading, because a read test would also flag a file the user cannot read as missing; falsified by a Windows CI run where `fs::is_file()` is TRUE for a file link to a missing file.
- 2026-10-26: plan gate chose one PCRE pattern over M059's two separate searches, because the new rule puts only a bounded separator between the names, so no `.*` is needed; falsified by a match-limit warning on an AC2 line.
- 2026-10-26: plan gate chose to state in the help page that a `.` after `report.R` stops the match over widening the match to sentence ends, toward the narrower promise; falsified by a site whose reports name the file only in prose that ends a sentence.
- 2026-10-26: changelog: no NEWS.md change; the M059 bullet covers the unreleased check and stays true.
- 2026-10-26: criteria audit (full mode, fresh Opus reader): 10 findings, all fixed. AC1 now binds `check_supplement()` and not `names_script()` or the test file, allows a `/`, `\`, or `\\` before the quote form, lets any `_scripts` start the match, adds probes for `\\`, a tab, mixed quotes, a trailing `/` before the quote, two `_scripts` on one line, `report.R.bak`, and a sentence-end `.`, and names the existing test's seven cases. The Goal names the AC1 forms and the link case. AC2 places the `source()` line first and last and adds a 5 MB run of spaces and tabs. AC3 scopes both sentences to the three systems. AC4 names the old rule text to drop and the sentence-end stop. AC5 adds the CI workflow on three systems. Reachability: `symlink_or_skip()` already makes file links on the Windows runner. Proportionality: no finding.
- 2026-10-26: started on branch m060-tighten-report-script-check.
- 2026-10-26: T1: added the AC1 row and no-row lines and the AC2 long lines as three tests with `script_site()` and `script_rows_for()` helpers; on the current code the three no-row cases `_scripts_old/report.R`, `_scripts/old-report.R`, and `"_scripts", "x", "report.R"` fail, and the rest pass.
- 2026-10-26: T2: `names_script()` is one `grepl()` pattern, a `/`, `\`, or `\\` run or an optional such run then quote, comma, quote with possessive `[ \t]*+` runs; test-check-supplement.R gives 0 failures, and its one warning comes from `file.create()` in the untouched non-UTF-8 name test on macOS before its skip.
- 2026-10-26: T3: `check_missing_script()` also needs `isTRUE(fs::is_file(script))` when `is_link()` is TRUE; the dangling-link test uses `symlink_or_skip()` with no Windows skip, and a new test links `_scripts/report.R` to an existing file. A planted `!is_link(script)` alone fails the existing-link test on macOS. The Windows dangling case is seen only on CI.
- 2026-10-26: T4 checkpoint (half-done): help text and `man/check_supplement.Rd` rebuilt, DESIGN.md missing-script lines updated; full `devtools::test()` and `devtools::check()` still to run.
- 2026-10-26: T4 done: `devtools::test()` 407 tests, 0 failures, 1 warning (the macOS `file.create()` warning of T2); `devtools::check()` 0 errors, 0 warnings, 1 note (local `.claude`).
- 2026-10-26: claim audit: 16 claims read, 3 corrected — R/check-supplement.R, man/check_supplement.Rd (the `names_script()` comment no longer calls the separator bounded, and the help and a comment say `fs::is_file()` is not TRUE rather than FALSE; the re-read found all three hold; the two Windows claims rest on the Windows CI run at review).
- 2026-10-26: all tasks done; status set to review.
- 2026-10-26: review return 1: `check_missing_script()` hangs on a `_scripts/report.R` that links to a link, because `fs::is_file()` (fs 2.1.0) loops on such a chain; the same call skips `fs_link()`'s `~` expansion, UTF-8 check, and error catch. Fix those, narrow the possessive-run claim in the `names_script()` comment and DESIGN.md to "no `.*`", add to the help that any boundary `_scripts` can start the match, and correct the LESSONS.md M059 line.
- 2026-10-26: resumed for review return 1; added T5 (minor amendment) and mapped it to AC3 and AC4 in Coverage.
- 2026-10-26: T5: new `link_ends_on_file()` resolves the link chain with `fs::path_real()` after `path.expand()`; `ENOENT` and `ELOOP` count as no file, and a path that is not valid UTF-8 or another fs error keeps the `file.exists()` answer. This replaces `fs::is_file()`, which loops on a link to a link (fs 2.1.0); falsified by a Windows CI run where `fs::path_real()` signals a class other than `ENOENT` for a file link to a missing file. New test: a link to a link to an existing file gives no row, and to a missing file gives the row. The `names_script()` comment and DESIGN.md now credit only the absent `.*`; the help says each boundary `_scripts` can start the match; LESSONS.md M059 line corrected in place. `devtools::test()` 408 tests, 0 failures, 1 warning (macOS `file.create()`).
- 2026-10-26: review pass 2 paused at the user's request before any finding was settled; the evidence run and three of four lenses were stopped. The prior-review lens reported 4 items (untested guards in `link_ends_on_file()` with no wrapper to make fs stop, its TRUE default on fs errors and non-UTF-8 paths against `fs_link()`'s FALSE, and no catch for a match-limit warning in `names_script()`). Pass 2 reruns in full on resume.
- 2026-10-26: review pass 2 fix-now: `link_ends_on_file()` counts any `fs_path_real()` error as no file and keeps TRUE only for a path that is not valid UTF-8; new `fs_path_real()` wrapper; loop, mocked-error, and UTF-8 tests replace the chain-to-missing half; help rewrapped and states both fallbacks; `R/supplement-yml.R` comment says R_USER or HOME. A planted TRUE-on-error default fails the mocked-error test. test-check-supplement.R: 82 tests, 0 failures.
- 2026-10-26: claim audit: 13 claims read, 1 corrected — R/check-supplement.R (the `link_ends_on_file()` comment now says the `~` expansion differs on Windows and that R reads R_USER or HOME; the re-read found it holds).
- 2026-10-26: all tasks done; status set to review.

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive. -->

Pass 1 (2026-10-26). Gate before the lenses: `devtools::document()` left no change; `devtools::check()` 0 errors, 0 warnings, 1 note (local `.claude`). No criterion was ticked in this pass, because the diff-bug lens found a hang that returns the milestone.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: `fs::is_file()` (fs 2.1.0) loops forever on a link to a link, so `check_supplement()` hangs when `_scripts/report.R` links to a link to an existing file; reproduced with a 5 s time limit — fix now, review return 1.
- diff-bug #2: `fs::is_file()` gets the raw path, and on Windows fs expands `~` from USERPROFILE, not R_USER, so `check_supplement("~/site")` can give a false row — fix now (the review return 1 fix).
- diff-bug #3: the new fs call has no guard for a path that is not valid UTF-8 or for an fs error — fix now (the review return 1 fix).
- diff-bug #4: the 5 MB `"_scripts" ,` test still passes with every possessive `+` removed, so the comment and DESIGN.md line that credit the possessive runs are not backed — fix now: the claim narrows to "no `.*`".
- diff-bug #5: `report.R.bak` and the sentence-end `.` run one path, and the first and last `source()` placements run one path — reject (planned change: AC1 and AC2 name each input).
- diff-bug #6: AC3 on Windows has no evidence if the runner cannot make links — reject (false: `.github/scripts/check-skips.R` fails the job on the "cannot make a symbolic link here" skip).
- diff-bug #7: the help page does not say that any boundary `_scripts` on a line can start the match, which AC4 needs — fix now.
- diff-bug #8: one rewrapped roxygen line is about 97 characters, and DESIGN.md says "possessive space runs" — reject (style); the DESIGN.md line changes with #4.
- blame-history #1: the rule drops lines such as `file.path("_scripts", site, "report.R")` and prose "The _scripts folder holds report.R" — reject (planned change: the user chose the separator rule at the plan).
- blame-history #2: a Windows runner without link rights could skip the link tests — reject (false: the CI skip check fails on that skip reason).
- blame-history #3: an uneven roxygen line — reject (style).
- blame-history #4: "A line of prose or a comment also counts" reads broader than the rule — reject (false: a prose or comment line that fits the rule counts).
- prior-review #1: the fs call skips the guards of `fs_link()` that M045 set (path expansion, UTF-8 check, error catch) — fix now (the review return 1 fix).
- prior-review #2: LESSONS.md 2026-10-26 (M059) says to find each name with its own search "as `names_script()` does", which no longer holds — fix now: correct the lesson in place.
- ripple #1: the candidate row "Flag dangling report.R links on Windows" says the case gives no row — reject (planned change: hygiene graduates the row).
- ripple #2: the candidate row "Match report.R names as whole paths" describes the fixed bug — reject (planned change: hygiene graduates the row).
- ripple #3: `R/add-report.R:34`, `man/add_report.Rd`, and GUIDE.md say the check "looks only at whether the file is there" — reject (false: a link to a missing file is a missing file, so the sentence holds).
- ripple #4: NEWS.md says the same of the unreleased stale-output bullet — reject (false, as #3).
- ripple #5: the `R/supplement-yml.R:309` comment says `file.exists()` is FALSE for a dangling link — reject (false: its parenthesis limits the Windows case to junctions and folder links).
- ripple #6: README.md and GUIDE.md list "reports ... that name a missing `_scripts/report.R` file" — reject (false: still true).
- ripple #7: the M059 NEWS bullet does not name the Windows link case — reject (false: the bullet stays true for the unreleased check).
- Pass 1 fix-now items: diff-bug #1, #2, #3, #4, #7 and prior-review #1, #2 fixed 9de47dc (review return 1, T5).

Pass 2 (2026-10-26), resumed after a pause; the paused pass's reports were discarded and every lens ran again.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: on Windows a dangling link that `fs::path_real()` fails on with a class other than `ENOENT` or `ELOOP` (macOS gives `ENOTDIR` for a link to `real.R/x`; permission errors) falls to the TRUE default and gives no row — fix now: any fs error counts as no file.
- diff-bug #2: the help does not say what an fs error or a path that is not valid UTF-8 counts as — fix now (with #1).
- diff-bug #3: the help's loop case is untested and on Windows rests on libuv's `ELOOP` mapping — fix now: a loop test, and #1 makes any error class count as no file.
- diff-bug #4: the second half of the link-to-link test (chain to a missing file) runs the same path as the dangling-link test — fix now: drop it.
- diff-bug #5: the AC2 long lines do not guard the possessive runs — reject (planned change: AC2 names the inputs; the comment no longer credits the runs).
- diff-bug #6: the two helper comments restate the helpers — reject (style: the file's helpers such as `report_lines()` carry the same one-line comments).
- diff-bug #7: two roxygen lines of 86 and 97 characters — reject (style); rewrapped with #2.
- diff-bug #8: `path.expand()` can warn on a path over PATH_MAX — reject (false: `file.exists()` is FALSE first on Unix, and `fs_link()` already expands the same path on Windows).
- diff-bug #9: the UTF-8 branch is dead because `file.path()` rejects a bytes-encoded path — reject (false: a native string with byte 0xE9 passes `file.path()` and fails `validUTF8()`, checked on macOS).
- blame-history #1: the T5 work log says a Windows run showed another error class, so the fix is incomplete — reject (false: that line names the class of evidence that would falsify the choice, not an observed run).
- blame-history #2: `link_ends_on_file()` repeats `fs_link()`'s guards with the opposite fallback — fix now (with diff-bug #1: the fs-error fallback becomes FALSE; the UTF-8 fallback stays TRUE because fs cannot read such a path).
- blame-history #3: the new fs call has no wrapper, so its error branch cannot be tested, unlike `fs_is_link()` from M045 — fix now: an `fs_path_real()` wrapper and a mocked-error test.
- blame-history #4: no record covers fs use on macOS and Linux — reject (false: D-022 imports fs, and DESIGN.md's missing-script line records `fs::path_real()`).
- blame-history #5: no lesson records that `fs::is_file()` never returns on a link to a link — follow-up: a lesson at hygiene.
- prior-review #1: the guards in `link_ends_on_file()` are untested — fix now (with blame-history #3).
- prior-review #2: the Windows row rests on `ENOENT` being the class there — fix now (with diff-bug #1).
- prior-review #3: the optional `slash?` group is not possessive, against the M021 lesson — reject (false: a group of at most two characters gives PCRE no long run to backtrack into).
- prior-review #4: "(corrected M060)" is an appended note — reject (false: tracking-rules marks an in-place correction that way).
- prior-review #5: `names_script()` does not catch a match-limit warning — reject (false: no `.*` remains, and 9 MB probes in two lenses gave no warning).
- ripple #1: the `R/supplement-yml.R:328` comment says R expands `~` from R_USER while the new comment says R_USER or HOME — fix now.
- ripple #2: the M059 lesson still says a possessive repeat cannot help — reject (false: it speaks of the `.*` pattern, where that holds).
- ripple #3: the M059 NEWS bullet says "has no `_scripts/report.R` file" — reject (false: a link that ends on no file is no file).
- ripple #4: `fs_link()` and `link_ends_on_file()` default in opposite directions — fix now (with diff-bug #1).
- Outside the diff: the Windows job of the main run on 4fad253 (a tracking-only commit) crashed in `test-create-supplement.R` with exit -1073741819, where the run on 918a2d6 passed — follow-up: a candidate row.
- Pass 2 fix-now items: diff-bug #1, #2, #3, #4, blame-history #2, #3, prior-review #1, #2, and ripple #1, #4 fixed c059498. Follow-ups: the candidate row "Trace the Windows crash in create tests" (e895ff3), and blame-history #5 as a lesson at hygiene.

Evidence on head c059498 plus its record commit (2026-10-26, macOS, R 4.6, fs 2.1.0):

- AC1: `devtools::test()`: "lines that join _scripts and report.R by a separator give a missing-script row" 7 of 7 pass, "lines that do not join ... give no missing-script row" 5 of 5, "reports that name a missing _scripts/report.R give one missing-script row" 4 of 4 (the template line, `# _scripts/report.R` as last line, `report.R, then _scripts/report.R`), and "no missing-script row when the file is there or no report names it" 2 of 2 (the seven cases); none skipped.
- AC2: "a long line that names a missing _scripts/report.R gives a missing-script row" 6 of 6 pass: the `source()` line first and last in 5 MB give the row under `expect_no_warning()`, and `"_scripts" ,` plus 5 MB of spaces and tabs gives no row and no warning.
- AC3 (macOS part): "a link to a missing _scripts/report.R gives a missing-script row", "a link to an existing ... gives no missing-script row", "a link to a link to an existing ...", and "a loop of links or a link that fs cannot resolve ..." pass, none skipped. The Windows and Linux parts wait for the R-CMD-check workflow on the PR, whose skip check fails a job that skips "cannot make a symbolic link here".
- AC4: `man/check_supplement.Rd` rendered with `tools::Rd2txt()` states the AC1 rule with each separator form, that each boundary `_scripts` can start the match, that a `.` after `report.R` stops the match, and that a file link to a missing file counts as missing on Windows; `grep -c` finds 0 of "later on that line", "reads as an existing file", and "neither gives a row there" in the Rd file and in `R/check-supplement.R`.
- AC5 (local part): `devtools::document()` left no change (`git status` empty); `devtools::test()` 410 tests, 0 failures, 0 errors, 1 warning (the `file.create()` warning of the untouched non-UTF-8 name test on macOS); `devtools::check()` 0 errors, 0 warnings, 1 note (hidden `.claude`, a local folder that a clone does not have). The workflow part waits for CI on the PR.

Consistency gate: `cairn_validate.py` all checks passed; `devtools::document()` no diff; no README.Rmd; `pkgdown::check_pkgdown()` no problems; changelog: the unreleased M059 NEWS bullet covers the `"missing-script"` check, whose narrowed rule and link case stay true to it, so no new entry (no milestone numbers in user text); no new top-level files.
