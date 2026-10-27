# M068: Handle renv lockfile edge cases

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the errors, rows, and messages of two exported functions change
- **Branch/PR:** m068-renv-lockfile-edge-cases

## Goal

The lockfile readers of `write_dockerfile()` and `check_supplement(renv_lock = TRUE)` handle three cases from the M066 and M067 reviews: a byte order mark, a path under another letter case, and a profile name that `RENV_PROFILE` and `renv/profile` both give.

## Scope

**In:** `read_lockfile_versions()` drops a UTF-8 byte order mark before it parses the lockfile, as `lock_versions()` does. `write_dockerfile()` checks the exact spelling of `renv.lock` as it does for each part of a profile lockfile's path. `check_supplement(renv_lock = TRUE)` gives a row for a lockfile path listed under another spelling. `lock_source()` notes when `renv/profile` gives the same name as `RENV_PROFILE`, and the "Picked" message and the name error of `write_dockerfile()` then name both. The help pages, `cairn/DESIGN.md`, and the `renv_lock` entry of `NEWS.md` follow.

**Out:** a `renv/profile` file listed under another letter case, which renv reads on macOS and Windows and not on Linux → candidate row "Flag a wrong-case renv/profile file". Showing odd profile paths and native Latin-1 names in messages → candidate row "Show odd renv profile paths in messages". Running the two Docker image tests, which the user chose to skip at the plan gate. The wording of the existing letter-case hint for profile paths outside the spelling change of T2.

## Acceptance criteria

- [ ] AC1: `write_dockerfile()` reads a lockfile that starts with a UTF-8 byte order mark, `renv.lock` or a profile's `renv/profiles/<name>/renv.lock`, with no warning, and writes the same `Dockerfile` and `.dockerignore` bytes as for that lockfile without the mark. A test in `tests/testthat/test-write-dockerfile.R` runs each of the two lockfiles, and for each one the no-warning check fails without the change.
- [ ] AC2: `write_dockerfile()` refuses a site whose `renv.lock` is listed under another letter case, such as `Renv.lock`, with `supplement_error_no_file`, and writes neither `Dockerfile` nor `.dockerignore`. Where the file system ignores letter case, the message holds the hint that a folder or file in that path is listed under another spelling; elsewhere it holds the existing hint to set up renv. A test in `tests/testthat/test-write-dockerfile.R` runs `Renv.lock` and `RENV.LOCK`, and on macOS and Windows it fails without the change. The existing tests where `renv.lock` has its exact letter case still pass.
- [ ] AC3: With `renv_lock = TRUE`, `check_supplement()` gives one `"renv-mismatch"` row for the picked lockfile when `lock_versions()` read it but a folder or file in its path from the site folder is listed under another spelling, such as `Renv.lock` for `renv.lock`. The row's file is the path as renv picks it, and its text names the path as listed and says to rename it to the path renv picks, then commit the change. A lockfile that cannot be read gets the existing unreadable row and no such row. A lockfile path listed with its exact spelling gets no such row. A test in `tests/testthat/test-check-supplement.R` puts another letter case in each part in turn: `renv.lock` at the top, and `renv`, `profiles`, `<name>`, and `renv.lock` of a profile path whose name comes from `RENV_PROFILE`. Where the file system ignores letter case, each case fails without the change, and one site's report keeps its `"renv-mismatch"` and `"renv-missing"` rows. Where it matches letter case, these sites get the message that the site has no lockfile, with and without the change.
- [ ] AC4: When `RENV_PROFILE` names a profile (not empty and not `default`) and the first line of `renv/profile` is that name byte for byte, the "Picked" message of `check_supplement(renv_lock = TRUE)` and of `write_dockerfile()` says that `RENV_PROFILE` and `renv/profile` both name the profile, and the name error of `write_dockerfile()` (`supplement_error_profile`) says that both give the name. When `renv/profile` is missing, empty, names another profile, or is a folder, these texts name `RENV_PROFILE` alone, as on main, and neither function gives an error or a row from `renv/profile`. Tests in `tests/testthat/test-check-supplement.R` and `tests/testthat/test-write-dockerfile.R` run each of these shapes.
- [ ] AC5: When `RENV_PROFILE` is not empty, the `file` and `profile` that `lock_source()` returns do not depend on `renv/profile`, so both functions pick the lockfile that they pick on main.
- [ ] AC6: The help of `write_dockerfile()` says that `renv.lock` must have its exact letter case, as each part of a profile lockfile's path must, and the help of `check_supplement()` describes the row of AC3. The help of both functions says that the "Picked" message names both `RENV_PROFILE` and `renv/profile` when they give the same name. `cairn/DESIGN.md` states the spelling rule of both functions and the both-sources message. `devtools::check()` on macOS gives 0 errors and 0 warnings.

## Coverage

- AC1 → T1
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T4
- AC6 → T2, T3, T4, T5

## Tasks

- [x] T1: Move the byte order mark drop of `lock_versions()` (`R/check-supplement.R:1174`) into a small helper and call it in `read_lockfile_versions()` (`R/write-dockerfile.R:294`) before `rawToChar()`. Test both lockfiles with `expect_no_warning()` and the bytes of `dockerfile_461` and `dockerfile_dev`.
- [x] T2: In `read_lockfile_versions()` run `listed_exactly()` for every lockfile, not only a profile's (`R/write-dockerfile.R:267`), and make the hint at `:271` say "listed under another spelling, such as another letter case". Move `ignores_case()` from `test-write-dockerfile.R:370` into a helper file so T3 can use it. Test `Renv.lock` and `RENV.LOCK`.
- [x] T3: In `check_renv_lock()` (`R/check-supplement.R:960`), after `lock_versions()` returns a list, check the path parts with `listed_exactly()` and add one `"renv-mismatch"` row that names the listed path and the path renv picks, then go on with the comparison. Move `listed_exactly()` beside `lock_source()`. Tests: each of the five part positions, profile name from `RENV_PROFILE`; one site with a report holding a mismatch and a missing package; an unreadable wrong-case lockfile (a folder `Renv.lock`) gets only the unreadable row.
- [ ] T4: In `lock_source()` (`R/check-supplement.R:1104`), when `RENV_PROFILE` names a profile, read the first line of `renv/profile` under the same guards and set `from = "both"` on a byte-for-byte match, leaving `file` and `profile` as they are. Update `inform_lock_source()` (`:1133`) and the name error of `dockerfile_lock_source()` (`R/write-dockerfile.R:234`). Pass names to cli as values (LESSONS M016). Tests in both files for both, missing, empty, other name, and folder; the name-error test uses the ASCII name `a b`.
- [ ] T5: Update the help of `write_dockerfile()` (`R/write-dockerfile.R:40-62`, `:141-144`) and `check_supplement()` (`R/check-supplement.R:177-191`), `cairn/DESIGN.md` (lines 122-126, 187-189), and add one sentence on the letter-case row to the `renv_lock` entry of `NEWS.md`. Run `devtools::document()` and `devtools::check()`.

## Work log

- 2026-10-28: created by /milestone-plan.
- 2026-10-28: tier check: milestone — the profile-source wording needs a design choice, and the letter-case row adds `check_supplement()` behavior.
- 2026-10-28: idea vet: the first run of this plan found one concern in "Show odd renv profile paths in messages" (`show_text()` relabels native Latin-1 text for every row, not only profile paths); the user dropped that row from this plan, and it stays a candidate. No concern in the three rows planned: renv 1.3.1 reads a lockfile with a byte order mark (tested with `renv_lockfile_read()`), and `renv_bootstrap_profile_load()` copies `renv/profile` into `RENV_PROFILE`.
- 2026-10-28: question set: wording when both sources give one name — name both.
- 2026-10-28: question set: should `check_supplement()` also flag the letter case — yes, which adds AC3.
- 2026-10-28: question set: run the two Docker image tests at review — skip them; the Dockerfile byte comparisons stand in.
- 2026-10-28: plan gate chose naming both sources over "renv/profile names, and renv copies it into RENV_PROFILE" because the package cannot tell who set the variable; falsified by evidence that users read "both" as a conflict between the two.
- 2026-10-28: plan gate chose a letter-case row in `check_supplement()` too, at the user's choice, over a rule for `write_dockerfile()` alone; falsified by a renv version that refuses a wrong-case lockfile on every system.
- 2026-10-28: criteria audit (full mode): 11 findings. Fixed 9: per-lockfile fail-without-change, the hint on each file system, `default` excluded, the pick promise bound to `lock_source()` (AC5), named doc rules, macOS for `devtools::check()`, the error-or-row clause, ASCII name test, both-sources doc clause. Answered 1 as a limit (finding 8). Posed 1 at the gate (the `check_supplement()` case row).
- 2026-10-28: criteria re-audit (full mode) of AC3 and AC6: 12 findings. Fixed 8: unreadable row wins, "spelling" for non-case differences (AC2 hint aligned), check only after `lock_versions()` read the file, all five part positions, a report site, profile from `RENV_PROFILE` with `renv/Profile` moved to Out, both paths in the row, the case-sensitive clause. Answered 4: facts confirmed, AC2 changes the code AC6 describes, no D-032 conflict, domain proportionate.
- 2026-10-28: limit: on Windows a non-ASCII profile name can fail the byte-for-byte match after renv's `Sys.setenv()`, and the message then names `RENV_PROFILE` alone, as on main.
- 2026-10-28: changelog: one sentence in the unreleased `renv_lock` entry of `NEWS.md` for the AC3 row; the other changes refine unreleased features whose entries stay true, so they get none.
- 2026-10-28: collision check: absorbs the candidate rows "Read renv.lock with a byte order mark", "Match the letter case of renv.lock", and "Name the real source of a profile name"; extends M066 (`lock_source()`) and M067 (`write_dockerfile()`); D-032 holds, since the new row is a `"renv-mismatch"` row of the opt-in check. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-28: lessons used: 2026-10-27 (M064, used M065), 2026-10-27 (M066, used M067), 2026-10-27 (M067), 2026-10-19 (M018, used M067), 2026-10-19 (M016, used M067).
- 2026-10-28: implement started on m068-renv-lockfile-edge-cases. Checkpoint, half-done: T1 code and test written; both lockfile cases failed on main with the jsonlite byte order mark warning and pass with `drop_bom()`; the full suite is still running, so T1 is not checked off.
- 2026-10-28: T1 done: `devtools::test()` at 64f946f gave 470 tests, 0 failed. `drop_bom()` sits beside `lock_versions()`; the copy in the placeholder check (`R/check-supplement.R:1357`) was left as it is.
- 2026-10-28: T2 done: the `Renv.lock` test failed on main on macOS (no error) and passes with `listed_exactly()` run for every lockfile; the write_dockerfile help states the rule. `devtools::test()` with T2's code gave 471 tests, 0 failed. Checkpoint, half-done: this commit also carries T3's code (`listed_exactly()` moved beside `lock_source()`, new `listed_path()`, the spelling row), not yet tested.
- 2026-10-28: T3 done: the new test passes on macOS, and with the row turned off (`if (FALSE)`) all five part positions failed (15 failures); `devtools::test()` gave 472 tests, 0 failed. `listed_path()` names each part by an ASCII-case match in its folder, else by `fs::path_real()`, else the row says "a folder or file in its path is listed under another spelling" without a listed form (no test reaches that branch). Checkpoint, half-done: T4's code (`profile_line()`, `from = "both"`, both message texts) rides in this commit, not yet tested.

## Decisions

## Review
