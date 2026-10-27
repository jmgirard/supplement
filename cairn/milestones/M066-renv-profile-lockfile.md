<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M066: Read the lockfile of the active renv profile

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — it changes which file the exported `check_supplement()` reads and what its rows say
- **Branch/PR:** m066-renv-profile-lockfile

## Goal

With `renv_lock = TRUE`, `check_supplement()` compares the stored output of each report with the lockfile of the renv profile that renv picks for the site.

## Scope

**In:** These parts:

- Pick the lockfile by the profile rule of renv 1.3.1 (`renv_bootstrap_profile_load()`), applied to the site folder.
- Name the picked lockfile, the profile, and where the profile came from in the rows and messages of the two renv checks.
- Give one row for a `renv/profile` file that renv cannot read.
- Update the help, NEWS.md, GUIDE.md, and DESIGN.md.

**Out:** These parts:

- `write_dockerfile()` reads only `renv.lock`. The candidate row "Write Dockerfiles from profile lockfiles" holds this work.
- `RENV_PATHS_LOCKFILE` and `RENV_PATHS_RENV` are not read. This work is not planned, and the help states the limit.
- `release_supplement()` runs neither renv check (D-032). This does not change.

## Acceptance criteria

- [x] AC1: With `renv_lock = TRUE`, `check_supplement()` reads the lockfile that this rule picks. If the R session's `RENV_PROFILE` is not empty, it names the profile. Otherwise, when `file.exists()` finds `renv/profile` in the site folder, its first line as `readLines()` reads it, untrimmed, names the profile. A missing or empty file names none. The names `""` and `default` mean no profile. With profile `<p>` the lockfile is `renv/profiles/<p>/renv.lock`, the name joined as given, and with no profile `renv.lock`. Tests in `tests/testthat/test-check-supplement.R` cover these cases: the variable, the file, the variable over the file, `RENV_PROFILE=default` with a file that names another profile, `default` in the file, an empty file, a blank first line with a name on line 2, a CR LF line end, a name with spaces around it, a name that holds `..`, a `renv/profile` link to a missing file (skipped on Windows), and no file. In each case `renv.lock` and the profile's lockfile record different versions of one package, so the rows show which file was read.
- [x] AC2: When a profile is in use, the function prints one message. It names the profile, its lockfile's path from the site folder, and its source, `RENV_PROFILE` or `renv/profile`. The "renv-mismatch" row text, the "renv-missing" row text, the row for a lockfile that cannot be read (its `file` column and text), and the skip message name that path where they name `renv.lock` on main. The renv steps in the two report rows say to run them with that profile active. A test asserts the exact text of these six outputs under a profile named `dev` and under one that holds `{`, `}`, and a space.
- [x] AC3: When a profile is in use and its lockfile does not exist, `check_supplement(renv_lock = TRUE)` gives no "renv-mismatch" or "renv-missing" row. It prints the skip message with the profile's lockfile, also when `renv.lock` in the site folder exists and differs from the reports. A test covers it.
- [x] AC4: When `RENV_PROFILE` is empty and `renv/profile` is a folder or a file that cannot be opened, `check_supplement(renv_lock = TRUE)` gives one "renv-mismatch" row with the file `renv/profile` and no report rows. A test asserts that row's exact text for a folder and for a file with no read permission (skipped on Windows and as root). When `RENV_PROFILE` is not empty, the same folder gives no such row, and a test covers it.
- [x] AC5: The help of `check_supplement()` (the `renv_lock` argument and the "renv-mismatch" and "renv-missing" items) states the profile rule. It also says that the check reads `RENV_PROFILE` from the R session that runs it, and that `RENV_PATHS_LOCKFILE` and `RENV_PATHS_RENV` are not read. NEWS.md's unreleased `renv_lock` bullet, the renv part of `inst/template/GUIDE.md`, and the `renv_lock` paragraph of `cairn/DESIGN.md` say that the check reads the active profile's lockfile. `grep -n 'Only .renv.lock. in the site folder is read' R/check-supplement.R` finds nothing.
- [x] AC6: `devtools::document()` leaves no diff, `devtools::test()` reports 0 failures, and `devtools::check()` reports 0 errors and 0 warnings.

## Coverage

- AC1 → T1, T5
- AC2 → T2
- AC3 → T2
- AC4 → T1, T2
- AC5 → T3
- AC6 → T4

## Tasks

- [x] T1: Write the AC1 and AC4 tests first. Then add a helper in `R/check-supplement.R` that applies the rule to the site folder. It returns the profile, its source, and the lockfile's path from the site folder, or marks `renv/profile` as unreadable. `lock_versions()` (near line 1060) takes that path. The existing renv tests unset `RENV_PROFILE` with withr.
- [x] T2: Write the AC2 and AC3 tests first. Then pass the helper's result through `check_renv_lock()`, `mismatch_problem()`, and `missing_problem()`. This covers the row text, the steps with the profile active, the unreadable-lockfile row, the skip message, the profile message, and the `renv/profile` row. Pass the profile name to cli as a value, never in the template.
- [x] T3: Update the roxygen help and run `devtools::document()`. Edit the unreleased `renv_lock` bullet of NEWS.md, the renv part of GUIDE.md, and the `renv_lock` paragraph of DESIGN.md.
- [x] T4: Run `devtools::test()` and `devtools::check()`.
- [x] T5: Review return 1. Give the AC1 `dots` case a `..` name that resolves to another profile's lockfile. Carry the fix-now findings of review pass 1: the `show_text()` path in the unreadable-lockfile row with a Linux regression test, the case rename, a no-message assertion, `cli.hyperlink` in `lock_messages()`, three code comments, and the profile text in DESIGN.md, README.md, the publishing vignette, and GUIDE.md.

## Work log

- 2026-10-27: created by /milestone-plan.
- 2026-10-27: tier check: not run — work named at the question set.
- 2026-10-27: idea vet: no concern that changes what the user gets. renv 1.3.1 reads `RENV_PROFILE`, then the first line of `renv/profile`, and treats `default` as no profile, so the check can follow that rule in base R.
- 2026-10-27: question set: which candidate to plan — "Read the lockfiles of renv profiles"; how to find the lockfile — follow the active profile, with `renv_lock` still `TRUE` or `FALSE`. No dependency change or other outward action is foreseen.
- 2026-10-27: lessons used: 2026-10-22 (M031, M032), 2026-10-19 (M016), 2026-10-19 (M018, used M060).
- 2026-10-27: plan gate chose following the active profile over a lockfile path in `renv_lock` because renv itself picks the lockfile this way and the argument keeps its two values; falsified by authors who keep the lockfile at a path that no profile names.
- 2026-10-27: plan chose to apply the profile rule in base R over `renv::paths$lockfile()` because renv is only in Suggests and that function reads `RENV_PROFILE` alone, not `renv/profile`; falsified by a renv release that changes the rule.
- 2026-10-27: inbox sweep: 0 open issues and 0 open PRs on jmgirard/supplement.
- 2026-10-27: collision check: absorbs the candidate row "Read the lockfiles of renv profiles" (from the M064 and M065 plans). D-032 (opt-in, the release does not run it) still holds. The `write_dockerfile()` gap became the candidate row "Write Dockerfiles from profile lockfiles".
- 2026-10-27: criteria audit (full mode, fresh Opus reader): 9 findings, all fixed. The AC5 search matched nothing on main because the sentence wraps, so it now searches one line. AC1 and AC4 now follow renv for a link to a missing `renv/profile` and for bytes that are not UTF-8, and AC4 adds an unreadable file. AC2 asserts the profile message and a name with `{`, `}`, and a space. The message names the profile's source, and the help names the session's variable. The row steps say to run renv with the profile active. AC1 adds `..`, `RENV_PROFILE=default`, a blank first line, CR LF, and spaces. The help names both `RENV_PATHS_*` variables. AC3 and AC6 had no finding.
- 2026-10-27: T1 and T2 done in one commit: `lock_source()` in `R/check-supplement.R` applies the profile rule, `lock_versions()` takes the lockfile path, and `check_renv_lock()` names the lockfile, the profile, and its source. The profile message reads "Picked <lockfile>, the lockfile of the renv profile <name>, which <source> names", so it stays true when the lockfile is missing. A `renv/profile` folder gives the row on every system, since Linux `readLines()` reads a folder as empty. Four planted defects in `lock_source()` (trim, no variable, no `default`, unreadable as no profile) each failed tests. `devtools::test()`: 460 tests, 0 failed.
- 2026-10-27: T3 done: the `check_supplement()` help gives the profile rule in a paragraph of the "renv-mismatch" item and a sentence in `renv_lock`, NEWS.md, GUIDE.md, and DESIGN.md name the profile lockfile, and `devtools::document()` rewrote `man/check_supplement.Rd`. The AC5 grep finds nothing. Checkpoint before the full `devtools::test()` and `devtools::check()` run of T4, which is still running.
- 2026-10-27: claim audit: 34 claims read, 3 corrected — R/check-supplement.R (the `lock_source()` header now names `renv_paths_lockfile()` for the path, the `lock_versions()` header says a link to a missing file gives FALSE, and the folder comment no longer claims behavior on other systems). Unchecked here: the Windows `file.exists()` claim, which rests on the 2026-10-19 (M018) lesson.
- 2026-10-27: T4 done: `devtools::test()` gave 460 tests, 0 failed, 10 skipped. `devtools::check()` gave 0 errors, 0 warnings, 1 note (the local `.claude` folder), both on 4303d92. 4bf6640 changed only plain comments, and `devtools::document()` then left no diff. Status set to review.
- 2026-10-27: review return 1: AC1 fails for the `dots` case, whose name `../..` picks `renv.lock` itself, so `renv.lock` and the profile's lockfile cannot record different versions. The case needs a `..` name that resolves to another profile's lockfile. The same pass settled ten other findings as fix now (see Review, pass 1), which this return also carries.

## Decisions

## Review

Pass 1 (2026-10-27, branch head 4bf6640 plus b339d4d):

- spawned: diff-bug, blame-history, prior-review, ripple
- AC1: not verified. The `dots` case of "the renv.lock check reads the lockfile of the renv profile that renv picks" uses the name `../..`, whose lockfile is `renv.lock` itself, so the two files cannot record different versions as AC1 requires (diff-bug #10). Returned to implement.
- gate: `cairn_validate.py` passed every check. `pkgdown::check_pkgdown()` found no problems. NEWS.md has the entry. No new top-level file. README.md has no README.Rmd source.
- check: with `RENV_PROFILE=dev` set outside, `test-check-supplement.R` gave 123 tests, 0 failed, and the variable read `dev` again after the file, so the file-level unset holds.
- diff-bug #1: the `file` column of the unreadable-lockfile row is the raw path, and a profile name that is not UTF-8 makes `report_problems()` stop with "input string 1 is invalid UTF-8" — fix now.
- diff-bug #2: no test uses a profile name that is not UTF-8 — fix now, as the regression test of #1 (Linux only, as at test-check-supplement.R:745).
- diff-bug #3: on Linux renv reads a `renv/profile` folder as no profile, while the check gives a row — reject, planned change: AC4 asks for the row on every system.
- diff-bug #4: a line break in `RENV_PROFILE` shows as a space in the message — follow-up, new row "Show odd renv profile paths in messages".
- diff-bug #5: on Windows a `renv/profile` link to a missing file gives the unreadable row, untested there — reject, false: the help covers it as a file that cannot be opened, and renv also fails there.
- diff-bug #6: a name ending in `/` shows `renv/profiles/dev//renv.lock` — reject, planned change: the help says the name is joined as given, and it is the same file.
- diff-bug #7: several AC1 cases run the same code path — reject, planned change: AC1 names each case.
- diff-bug #8: the AC3 test asserts the skip message by regex after an exact check — reject, planned change: AC3 asks for a test with `renv.lock` present, a setup the exact check does not have.
- diff-bug #9: the case named `variable` has no variable and no file — fix now (rename).
- diff-bug #10: the `../..` case cannot show which file was read — fix now, through the return (a `..` name that resolves to another profile's lockfile).
- diff-bug #11: no test asserts that no profile gives no "Picked" message — fix now.
- diff-bug #12: `lock_messages()` leaves `cli.hyperlink` unset, so a user setting adds link codes — fix now.
- diff-bug #13: `{.file}` links resolve against the working directory, not the site, as `{.file renv.lock}` did on main — follow-up, the row "Show odd renv profile paths in messages".
- diff-bug #14: one `RENV_PROFILE` applies to every site checked in a session — reject, planned change: the help says the check reads the session's variable, as renv does.
- diff-bug #15: test-add-render.R unsets `RENV_PROFILE` after its render — reject, false: that site has no renv, so the render does not read the variable.
- blame-history #1: `write_dockerfile()` still reads only `renv.lock` — follow-up, the row "Write Dockerfiles from profile lockfiles".
- blame-history #2: the branch removes the M064 limit sentence — reject, planned change.
- blame-history #3: README.md and vignettes/publishing.Rmd name `renv.lock` with no profile case — fix now.
- blame-history #4: the profile rule has no D-entry — reject, planned change: the choice is local to this check, and D-032's opt-in still holds.
- prior-review #1: a BOM in `renv/profile` becomes part of the name — reject, planned change: renv's `readLines()` keeps it too, and AC1 follows renv.
- prior-review #2: test-add-render.R unsets `RENV_PROFILE` after its render — reject, false, as diff-bug #15.
- prior-review #3: the unreadable-lockfile row's `file` column is not passed through `show_text()` — fix now, as diff-bug #1.
- prior-review #4: the help's renv claims were not checked against renv — reject, false: the claim audit read them against renv 1.3.1.
- prior-review #5: the name is untrimmed and accepts `..` — reject, planned change.
- ripple #1: ROADMAP.md says the check reads only `renv.lock` — reject, planned change: hygiene graduates that row.
- ripple #2: DESIGN.md says `check_renv_lock()` reads the site's `renv.lock` — fix now.
- ripple #3: vignettes/publishing.Rmd names only `renv.lock` — fix now, as blame-history #3.
- ripple #4: GUIDE.md's profile paragraph does not say it covers the renv-mismatch steps above it — fix now.
- ripple #5: GUIDE.md's release-check list names only `renv.lock` — fix now.
- ripple #6: README.md names only `renv.lock` — fix now, as blame-history #3.
- ripple #7: DESIGN.md's renv-missing sentence names `renv.lock` — reject, false: the profile paragraph that follows it covers it.
- ripple #8: code comments in `mismatch_problem()` and `missing_problem()` name `renv.lock` — fix now.
- 2026-10-27: T5 added for review return 1 (minor amendment: one task, Coverage AC1 → T1, T5) and done. The `dots` case now uses `x/../other`, which resolves to the `other` profile's lockfile (1.1.2) where `renv.lock` records 1.1.0. The unreadable-lockfile row's `file` column is now the `show_text()` path. With the raw path, `report_problems()` stopped with "input string 1 is invalid UTF-8", and with the shown path it printed. The new Linux-only test skips on macOS. The other fix-now findings landed as the Review section lists. `test-check-supplement.R`: 124 tests, 0 failed. `devtools::document()` left no diff.
- 2026-10-27: claim audit: 16 claims read, 3 corrected — README.md, vignettes/publishing.Rmd, inst/template/GUIDE.md ("uses an renv profile" became "renv picks a profile", since `RENV_PROFILE` alone can pick one), tests/testthat/test-check-supplement.R (the skip comment no longer names Windows, which was not checked). A long comment line in `R/check-supplement.R` was rewrapped. Status set to review.

Pass 2 (2026-10-27, branch head 3dec8e0, then the fix-now test commit):

- spawned: diff-bug, blame-history, prior-review, ripple
- AC1: `test-check-supplement.R` "the renv.lock check reads the lockfile of the renv profile that renv picks" passed 13 of 13 on macOS: the variable, the file, the variable over the file, `RENV_PROFILE=default` with a file naming `other`, `default` in the file, an empty file, a blank first line, CR LF, ` dev `, `x/../other` (reads `other`'s 1.1.2, not `renv.lock`'s 1.1.0), no file, and a link to a missing file (ran, not skipped). Each case asserts the exact row naming the lockfile and its version.
- AC2: "rows and messages name the lockfile and the source of the renv profile" passed 14 of 14, for `dev` from `RENV_PROFILE` and `a{b} c` from `renv/profile`: the exact "Picked" message, the renv-mismatch row with and without the format hint, the renv-missing row, the unreadable-lockfile row (`file` column and text), and the skip message, each naming `renv/profiles/<name>/renv.lock` and the profile-active steps.
- AC3: "a missing lockfile of the renv profile skips the checks when renv.lock exists" passed 2 of 2: the skip message names `renv/profiles/dev/renv.lock`, and no renv row comes although `renv.lock` differs from the report.
- AC4: "a renv/profile that cannot be read gets one renv-mismatch row" passed 5 of 5: a folder gives the exact `renv/profile` row and no report rows; with `RENV_PROFILE=dev` the folder gives the two report rows instead; a mode-000 file gives the exact row (ran on macOS, not as root).
- AC5: `grep -n 'Only .renv.lock. in the site folder is read' R/check-supplement.R` exited 1. The help paragraph (R/check-supplement.R, "In this item and the next") states the rule, the session's `RENV_PROFILE`, and that `RENV_PATHS_LOCKFILE` and `RENV_PATHS_RENV` are not read; the `renv_lock` argument points to it. NEWS.md's unreleased `renv_lock` bullet, GUIDE.md's renv part, and DESIGN.md's `lock_source()` sentences name the profile lockfile.
- gate: `cairn_validate.py` passed. `pkgdown::check_pkgdown()` found no problems. `devtools::check()` on 3dec8e0 gave 0 errors, 0 warnings, 1 note (the local `.claude` folder, untracked and outside the build in CI).
- diff-bug #1: no test covers the format-hint sentence of the renv-mismatch row under a profile — fix now (a planted literal `renv.lock` in that sentence failed 2 tests after the fix).
- diff-bug #2: the "Picked" message says `RENV_PROFILE` names the profile in a session where renv's activation copied `renv/profile` into it — reject, false: in that session the variable does name it, and renv reads the variable first too.
- diff-bug #3: the cli messages have no test with a name that is not UTF-8 outside Linux — fix now (the test now writes the name to `renv/profile` and asserts both messages before its Linux-only part).
- diff-bug #4: a valid non-ASCII name such as `café` shows as `caf<e9>` in a Latin-1 locale — follow-up, the row "Show odd renv profile paths in messages".
- diff-bug #5: on Windows the ` dev ` case reads `renv/profiles/ dev/`, since Windows drops trailing spaces — reject, false: writing and reading go through the same path, and the windows-latest CI job runs the test before the merge.
- diff-bug #6: uneven line wraps in the vignette, GUIDE.md, and NEWS.md — reject, style.
- blame-history: no finding.
- prior-review: no finding; every pass-1 fix is present at 3dec8e0.
- ripple #1: GUIDE.md's renv steps name `renv.lock` above the profile paragraph — reject, false: that paragraph, rewritten in pass 1, covers the steps of both checks.
- ripple #2: DESIGN.md's renv-missing sentence names `renv.lock` — reject, false, as pass 1 ripple #7.
- AC6: on 50a4f1a (87ab3f6 changed only `cairn/ROADMAP.md`), `devtools::document()` left no diff, `devtools::test()` gave 461 tests, 0 failed, 0 errors, 11 skipped (the new Linux-only part among them), and `devtools::check()` gave 0 errors, 0 warnings, 1 note (the local `.claude` folder).
- snapshot: no changed snapshot file.
- 2026-10-27: step-7 approval: m066-renv-profile-lockfile approved for merge
