<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M066: Read the lockfile of the active renv profile

- **Status:** in-progress
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

- [ ] AC1: With `renv_lock = TRUE`, `check_supplement()` reads the lockfile that this rule picks. If the R session's `RENV_PROFILE` is not empty, it names the profile. Otherwise, when `file.exists()` finds `renv/profile` in the site folder, its first line as `readLines()` reads it, untrimmed, names the profile. A missing or empty file names none. The names `""` and `default` mean no profile. With profile `<p>` the lockfile is `renv/profiles/<p>/renv.lock`, the name joined as given, and with no profile `renv.lock`. Tests in `tests/testthat/test-check-supplement.R` cover these cases: the variable, the file, the variable over the file, `RENV_PROFILE=default` with a file that names another profile, `default` in the file, an empty file, a blank first line with a name on line 2, a CR LF line end, a name with spaces around it, a name that holds `..`, a `renv/profile` link to a missing file (skipped on Windows), and no file. In each case `renv.lock` and the profile's lockfile record different versions of one package, so the rows show which file was read.
- [ ] AC2: When a profile is in use, the function prints one message. It names the profile, its lockfile's path from the site folder, and its source, `RENV_PROFILE` or `renv/profile`. The "renv-mismatch" row text, the "renv-missing" row text, the row for a lockfile that cannot be read (its `file` column and text), and the skip message name that path where they name `renv.lock` on main. The renv steps in the two report rows say to run them with that profile active. A test asserts the exact text of these six outputs under a profile named `dev` and under one that holds `{`, `}`, and a space.
- [ ] AC3: When a profile is in use and its lockfile does not exist, `check_supplement(renv_lock = TRUE)` gives no "renv-mismatch" or "renv-missing" row. It prints the skip message with the profile's lockfile, also when `renv.lock` in the site folder exists and differs from the reports. A test covers it.
- [ ] AC4: When `RENV_PROFILE` is empty and `renv/profile` is a folder or a file that cannot be opened, `check_supplement(renv_lock = TRUE)` gives one "renv-mismatch" row with the file `renv/profile` and no report rows. A test asserts that row's exact text for a folder and for a file with no read permission (skipped on Windows and as root). When `RENV_PROFILE` is not empty, the same folder gives no such row, and a test covers it.
- [ ] AC5: The help of `check_supplement()` (the `renv_lock` argument and the "renv-mismatch" and "renv-missing" items) states the profile rule. It also says that the check reads `RENV_PROFILE` from the R session that runs it, and that `RENV_PATHS_LOCKFILE` and `RENV_PATHS_RENV` are not read. NEWS.md's unreleased `renv_lock` bullet, the renv part of `inst/template/GUIDE.md`, and the `renv_lock` paragraph of `cairn/DESIGN.md` say that the check reads the active profile's lockfile. `grep -n 'Only .renv.lock. in the site folder is read' R/check-supplement.R` finds nothing.
- [ ] AC6: `devtools::document()` leaves no diff, `devtools::test()` reports 0 failures, and `devtools::check()` reports 0 errors and 0 warnings.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T2
- AC4 → T1, T2
- AC5 → T3
- AC6 → T4

## Tasks

- [x] T1: Write the AC1 and AC4 tests first. Then add a helper in `R/check-supplement.R` that applies the rule to the site folder. It returns the profile, its source, and the lockfile's path from the site folder, or marks `renv/profile` as unreadable. `lock_versions()` (near line 1060) takes that path. The existing renv tests unset `RENV_PROFILE` with withr.
- [x] T2: Write the AC2 and AC3 tests first. Then pass the helper's result through `check_renv_lock()`, `mismatch_problem()`, and `missing_problem()`. This covers the row text, the steps with the profile active, the unreadable-lockfile row, the skip message, the profile message, and the `renv/profile` row. Pass the profile name to cli as a value, never in the template.
- [x] T3: Update the roxygen help and run `devtools::document()`. Edit the unreleased `renv_lock` bullet of NEWS.md, the renv part of GUIDE.md, and the `renv_lock` paragraph of DESIGN.md.
- [ ] T4: Run `devtools::test()` and `devtools::check()`.

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
