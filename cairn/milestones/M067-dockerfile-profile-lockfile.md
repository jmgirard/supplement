<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M067: Write Dockerfiles from profile lockfiles

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — it changes which lockfile the exported `write_dockerfile()` reads and what it writes
- **Branch/PR:** m067-dockerfile-profile-lockfile, https://github.com/jmgirard/supplement/pull/68

## Goal

`write_dockerfile()` builds its image from the lockfile of the renv profile that renv picks for the site, and the image restores and renders with that profile active.

## Scope

**In:** These parts:

- Pick the lockfile with `lock_source()` in `R/check-supplement.R`, the rule that `check_supplement(renv_lock = TRUE)` uses since M066.
- With a profile, write `.dockerignore` and Dockerfile lines that copy the profile lockfile and set `RENV_PROFILE` in the image.
- Refuse a profile name that the Dockerfile cannot hold, and an unreadable `renv/profile`, with the new class `supplement_error_profile`.
- Print one message that names the picked lockfile.
- Update the help, GUIDE.md, README.md, NEWS.md, and DESIGN.md.

**Out:** These parts:

- `RENV_PATHS_LOCKFILE` and `RENV_PATHS_RENV` are not read, as in M066. This work is not planned.
- Builds on amd64 and on older R images. The candidate row "Build the Dockerfile on older R images" holds this work.
- The odd-path display of `check_renv_lock()`. The candidate row "Show odd renv profile paths in messages" holds this work.

## Acceptance criteria

- [x] AC1: When `lock_source()` names no profile, `write_dockerfile()` prints no message. The `Dockerfile` bytes equal `dockerfile_461` in `tests/testthat/test-write-dockerfile.R`, and the `.dockerignore` bytes equal `*\n!renv.lock\n`. Tests cover these cases with `RENV_PROFILE` unset and no `renv/profile`, with `RENV_PROFILE=default`, with `default` in `renv/profile`, with an empty `renv/profile`, and with a `renv/profile` whose first line is empty.
- [x] AC2: When `lock_source()` names a profile `<name>`, `write_dockerfile()` reads the R and renv versions from `renv/profiles/<name>/renv.lock`. It writes `.dockerignore` as the lines `*` and `!renv/profiles/<name>/renv.lock`. The Dockerfile sets `RENV_PROFILE=<name>` in its `ENV` instruction. It copies the lockfile with `COPY renv/profiles/<name>/renv.lock renv/profiles/<name>/renv.lock`. The `supplement_error_lockfile` checks apply to the profile lockfile, and their messages name its path. Byte tests pin both files for a name from `RENV_PROFILE` and for a name from `renv/profile`. In one test, `renv.lock` and the profile lockfile record different R versions, and the `FROM` line has the R version of the profile lockfile.
- [x] AC3: With a profile, `write_dockerfile()` prints one message after every check of AC2 and AC4 passes and before it writes a file. The message names the lockfile path, the profile, and the source of the name (`RENV_PROFILE` or `renv/profile`). A test asserts its text for each source.
- [x] AC4: Each case below stops `write_dockerfile()` before it writes a file and before it prints the message. Tests show that the file hashes of the site folder do not change. The name check comes before the file checks. The cases:
  - The profile name has a character other than an ASCII letter, a digit, `.`, `_`, or `-`. Or the name starts with `.`. The class is `supplement_error_profile`. The tests use `.dev`, `..`, `a/b`, `a\b`, `a b`, `dev ` with a trailing space, `a"b`, `a$b`, `a*b`, `é`, and a name that is not valid UTF-8. They take each name from `renv/profile`, and from `RENV_PROFILE` where the system can store it. Four names come from `RENV_PROFILE` only: `dev` with a line feed after it, `dev` with a carriage return after it, `a` and `b` with a line feed between them, and a UTF-8 byte order mark before `dev`. `readLines()` ends a name in `renv/profile` at a line break, and in a UTF-8 locale it drops a byte order mark, as it does for renv.
  - `renv/profile` is a folder, or a file that cannot be opened (skipped on Windows and as root). The class is `supplement_error_profile`.
  - `list.files()` of `renv/profiles` lists no folder named `<name>` with the same letter case. Or that folder holds no file `renv.lock`, or `renv.lock` there is a folder or a link to a missing file. The class is `supplement_error_no_file`, and the message names the path.
- [x] AC5: With `SUPPLEMENT_TEST_DOCKER=true`, a test builds an image from a renv site whose `renv/profile` names a profile. The site has no `renv.lock` in its top folder. Its lockfile is at `renv/profiles/<name>/renv.lock`. The test renders the example report of the template with `--network none`. The Computing environment section of the page shows the R version of the profile lockfile and a library path under `/opt/renv/library/profiles/<name>/`.
- [x] AC6: Five texts state which lockfile `write_dockerfile()` reads. They also state that the image sets the profile. The texts:
  - the help page of `write_dockerfile()`, whose Errors section lists `supplement_error_profile`
  - the "Running reports in a container" part of `inst/template/GUIDE.md`
  - the "Record the R setup" part of `README.md`
  - one `NEWS.md` bullet
  - the `R/write-dockerfile.R` paragraph of the Architecture part of `cairn/DESIGN.md`

  No sentence in these texts says that the function always reads `renv.lock` in the site folder. No sentence says that `.dockerignore` always holds `!renv.lock`.
- [x] AC7: `devtools::document()` leaves no diff, `devtools::test()` reports 0 failures, and `devtools::check()` reports 0 errors and 0 warnings.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T1
- AC4 → T1
- AC5 → T2
- AC6 → T3
- AC7 → T1, T2, T3

## Tasks

- [x] T1: In `R/write-dockerfile.R`, pick the lockfile with `lock_source()`. Make `read_lockfile_versions()` take the lockfile path and name it in its messages. Add the name check and the exact-case folder check of AC4 with `supplement_error_profile`. Add the message, shown through `show_text()`. Pass the profile to `dockerfile_text()` and to the `.dockerignore` lines. In `tests/testthat/test-write-dockerfile.R`, unset `RENV_PROFILE` at the top of the file with `withr::local_envvar()`. Add the tests of AC1 to AC4.
- [x] T2: Add the profile case of AC5 to the gated Docker test. Ask the user to start Docker Desktop, then run the test once on this Mac (macOS arm64).
- [x] T3: Update the roxygen help (title, description, `path`, `.dockerignore` text, Errors), then run `devtools::document()`. Update GUIDE.md, README.md, NEWS.md, and DESIGN.md. Then run `devtools::check()`.

## Work log

- 2026-10-27: created by /milestone-plan.
- 2026-10-27: tier check: not run — work named at the question set.
- 2026-10-27: idea vet: no concern. The image must restore and run with the profile active, because renv 1.3.1 puts the library of a profile under `<RENV_PATHS_LIBRARY>/profiles/<name>/renv`. This is an approach fact, recorded below.
- 2026-10-27: question set: what to work on — the candidate row "Write Dockerfiles from profile lockfiles".
- 2026-10-27: question set: may review run the gated Docker build test, with the user starting Docker Desktop when asked — yes.
- 2026-10-27: collision check: absorbs the candidate row "Write Dockerfiles from profile lockfiles". It extends M032 (`write_dockerfile()`) and M066 (`lock_source()`). No D-entry rejects it. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-27: lessons used: 2026-10-27 (M066), 2026-10-22 (M031, M032), 2026-10-19 (M016).
- 2026-10-27: criteria audit (full mode, fresh Opus reader): 9 findings, all fixed. These fixes were made: AC1 pinned to named bytes and five no-profile probes. AC2 runs the lockfile checks on the profile lockfile. AC3 prints the message after all checks. AC4 adds the unopenable `renv/profile`, folder, and broken-link cases and the check order. AC4 adds probes on every free axis of the name and its source. AC4 adds the exact-case folder match, because Docker matches names with case. AC5 drops the root `renv.lock`, so that the R version shows which file was read, and moves the one review run to T2. AC6 rules out stale sentences and names the new class. No proportionality finding.
- 2026-10-27: plan gate chose to restore with `RENV_PROFILE` set in the image's `ENV` and the lockfile at its profile path over copying the profile lockfile as a plain `renv.lock`. The plain copy loses because renv looks for the library under the profile prefix when the mounted site's `renv/profile` names the profile at render time. Falsified by a gated build in which the render finds no library under `/opt/renv/library/profiles/<name>/`.
- 2026-10-27: plan gate chose a case mismatch between the name and the folder to be `supplement_error_no_file` over a check that ignores case. Docker's `.dockerignore` and `COPY` match names with case, so the build would fail. Falsified by a Docker build on macOS that copies `renv/profiles/dev/renv.lock` for the name `Dev`.
- 2026-10-27: plan gate chose the new class `supplement_error_profile` over reusing `supplement_error_lockfile` for a bad name or an unreadable `renv/profile`. Neither case is a fault in a lockfile. Falsified by a user need to catch both cases with one class.
- 2026-10-27: implement: status in-progress, branch m067-dockerfile-profile-lockfile cut from main at ca0d326.
- 2026-10-27: implement chose to move the "Picked" message of `check_renv_lock()` into `inform_lock_source()` in `R/check-supplement.R`, which `write_dockerfile()` also calls, over a second copy of the text.
- 2026-10-27: implement chose the existing link test of `check_missing_script()` (`is_link()` and `link_ends_on_file()`) for the lockfile, so a file link to a missing `renv.lock` is now `supplement_error_no_file` on Windows too.
- 2026-10-27: T1 done: `dockerfile_lock_source()` and the profile lines in `R/write-dockerfile.R`, 6 new tests, and `expect_refused()` now asserts no message. A planted name check that accepts every name turned the name test red. `devtools::test()`: 467 tests, 0 failed, 11 skipped.
- 2026-10-27: re-audit: AC4 (full) — 3 findings: the BOM claim holds only in a UTF-8 locale; "where the system can store it" belongs to `RENV_PROFILE`; one line-break probe stood for the family. All fixed, and the tests add `dev` CR and `a` LF `b`.
- 2026-10-27: re-audit: AC4 (full) — 4 findings on the fixed wording. 1, no probe of allowed names: answered by a test that `Dev-2`, `a.b`, `_x`, and `-a` pass from both sources. 2, no tab probe: answered by adding `a` tab `b` to the probes. 3, an unstorable `RENV_PROFILE` name drops out with no trace: answered by a skip that names each such name. 4, "as it does for renv" is ambiguous: answered with no change, because the reader confirmed the claim. No wording changed after this audit.
- 2026-10-27: substantive amendment: AC4's first bullet moves the byte order mark probe to `RENV_PROFILE` only, adds the CR and mid-name line feed probes, and moves "where the system can store it" to `RENV_PROFILE`. `readLines()` drops a byte order mark from `renv/profile` in a UTF-8 locale, so that file names `dev`, as it does for renv. What the user gets does not change.
- 2026-10-27: T2: the profile case is in the gated Docker test, which now shares `expect_docker_render()` with the first case. Docker Desktop started at 15:44 but had quit when the run began, so both builds failed with "failed to connect to the docker API". The page sections were the host's renders, with no `/opt/renv/library/` path, so the library checks failed as they must without Docker. The run waits for the user to start Docker.
- 2026-10-27: claim audit (first pass): about 65 claims read, 4 corrected plus one code comment narrowed. The help said "the rule of renv 1.3.1" for the lockfile, and it now says the profile and states that `RENV_PATHS_LOCKFILE` and `RENV_PATHS_RENV` are not read. README and the help said that renv picks, and now `write_dockerfile()` reads. In DESIGN.md the library reason now goes with `ENV`, not `COPY`. The GUIDE.md scope is now "In this part". The re-read of the corrected claims is pending.
- 2026-10-27: claim audit: 65 claims read, 4 corrected — R/write-dockerfile.R, man/write_dockerfile.Rd, README.md, inst/template/GUIDE.md, cairn/DESIGN.md. The same reader re-read the corrections once, and all held.
- 2026-10-27: T3 done: help, GUIDE.md, README.md, NEWS.md, and DESIGN.md updated. `devtools::check()` at 1c6952e: 0 errors, 0 warnings, 1 note (local `.claude`). Later commits change only prose and the regenerated `.Rd`.
- 2026-10-27: stop: T2's Docker run needs the user to start Docker Desktop. `open -a Docker` started it at 15:44, but it had quit when the tests ran.
- 2026-10-27: T2 done: the user started Docker Desktop (29.9.2, arm64). With `NOT_CRAN=true SUPPLEMENT_TEST_DOCKER=true`, both gated tests passed at 20c20d4. The plain case had 11 expectations (21 s, cached layers). The profile case had 12 expectations (90 s). Status set to review.
- 2026-10-27: review: main at ca0d326 is in the branch, so no sync was needed. The Copilot round is off (no header line). Fix-now findings committed in 25365a0. All evidence below is from 25365a0.
- 2026-10-27: step-7 approval: m067-dockerfile-profile-lockfile approved for merge.
- 2026-10-27: PR #68 opened, and the merge marker was written. The 3 checks were pending. The session does not poll CI in this app, so the CI wait stops here. Rerun `/milestone-review M067` to re-read the checks and merge.
- 2026-10-27: resume: PR #68 OPEN with both windows-latest jobs red, at 9607208. `test-write-dockerfile.R:572` expected the letter-case hint for "a link to a missing file". On Windows `file.exists()` is TRUE for a file link to a missing file (LESSONS 2026-10-19 (M018)), while the code rightly gave the no-file hint. The fix is test-only: the case hint is expected only for the three case shapes, where `ignores_case()` finds that the file system ignores case. Re-run locally: 27 tests, 0 failed. Pushed for CI. The fix is trivial, so the approval stands.

## Decisions

## Review

Evidence at 25365a0 (macOS arm64, R 4.6, renv 1.3.1, Docker 29.9.2). `test-write-dockerfile.R` with `NOT_CRAN=true SUPPLEMENT_TEST_DOCKER=true`: 27 tests, 497 expectations, 0 failed, 0 skipped. `devtools::test()`: 469 tests, 5739 expectations, 0 failed, 12 skipped.

- AC1: "with no renv profile, renv.lock is read and no message is printed" covers 5 cases (no profile, `RENV_PROFILE=default`, `default` in `renv/profile`, an empty `renv/profile`, an empty first line). Each gives no message, the `dockerfile_461` bytes, and `*\n!renv.lock\n`. The byte test of main passes unchanged.
- AC2: "with a renv profile, its lockfile is read, copied, and named in a message" pins the `dockerfile_dev` bytes (the `ENV` line `RENV_PROFILE=dev` and `COPY renv/profiles/dev/renv.lock renv/profiles/dev/renv.lock`) and `*\n!renv/profiles/dev/renv.lock\n`, for `RENV_PROFILE` and for `renv/profile`. There `renv.lock` records R 4.6.1 and the profile lockfile R 4.5.2, and `FROM rocker/r-ver:4.5.2` is written. "the lockfile checks apply to the lockfile of the renv profile" refuses R 3.6.3 and `[]` with `supplement_error_lockfile`, and both messages name `renv/profiles/dev/renv.lock`. All the lockfile checks run on that one `file` path in `read_lockfile_versions()`.
- AC3: The same test asserts the one message exactly for each source: `i Picked 'renv/profiles/dev/renv.lock', the lockfile of the renv profile "dev", which <`RENV_PROFILE` | 'renv/profile'> names.` `expect_refused()` asserts no message in every refusal of AC2 and AC4. In `write_dockerfile()`, `inform_lock_source()` runs after `check_overwrite()` and before the first write.
- AC4: "a renv profile name that a Dockerfile cannot hold is refused" refuses the 12 named names with `supplement_error_profile` from `renv/profile` and from `RENV_PROFILE`, because all stored on this Mac and the skip did not fire. `a` tab `b` is the twelfth. It also refuses the 4 `RENV_PROFILE`-only names. "a renv/profile that is a folder or cannot be opened is refused" ran both cases, unskipped. "a missing lockfile of the renv profile is refused, also under another letter case" gives `supplement_error_no_file` naming `renv/profiles/dev/renv.lock` for 7 shapes, among them `Dev`, `RENV.LOCK`, `Profiles`, a folder, and a broken link. Each refusal keeps the site's file hashes. In `write_dockerfile()` the name check runs before `read_lockfile_versions()`. Planted defects turned the tests red: a check that accepts every name, and an exact-case check that always passes (3 failures).
- AC5: "the image of a renv profile restores and renders with the profile's lockfile" passed at 25365a0 with Docker running. Its site has no top-level `renv.lock` and has `renv/profiles/docker/renv.lock` with `docker` in `renv/profile`. It built the image, rendered `analyses/example.qmd` with `--network none`, and matched `R version <the lockfile's R> ` and `/opt/renv/library/profiles/docker/` in the Computing environment section. The plain-lockfile Docker test also passed.
- AC6: These five texts state the lockfile and the image's `RENV_PROFILE`, read at 25365a0. The help (`man/write_dockerfile.Rd`) has a section "renv profiles", and its Errors list `supplement_error_profile`. GUIDE.md "Running reports in a container" has a profile paragraph and defines `renv.lock` for the part. README.md "Record the R setup" has lines 103 to 107. NEWS.md has the `write_dockerfile()` bullet. DESIGN.md has the `R/write-dockerfile.R` paragraph. A grep of the five for `always`, `lets only renv.lock`, `reads renv.lock and`, and `!renv.lock` finds only the help's example `such as !renv.lock` and an unrelated GUIDE.md line 292. A read of each text found no sentence that says it always reads `renv.lock` in the site folder.
- AC7: `devtools::document()` leaves `git status` empty. `devtools::test()`: 469 tests, 0 failed. `devtools::check()`: 0 errors, 0 warnings, 1 note. The note is the local `.claude` folder, which is not in git, as in M066.

Consistency gate: `cairn_validate.py` passes. `cairn_impact` is not run, because no principle changed. `document()` leaves no diff. The repo has no README.Rmd. `pkgdown::check_pkgdown()` finds no problems. NEWS.md has the entry. There is no new top-level file. The check result is under AC7.

spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the case check covered only the profile folder, so `RENV.LOCK` or `Profiles` passed on macOS — fix now, fixed 25365a0 (`listed_exactly()` on each part).
- diff-bug #2: the hint for a case mismatch said to run `renv::snapshot()`, which writes into the same folder again — fix now, fixed 25365a0 (case hint).
- diff-bug #3: the lockfile-error hints left out the profile — fix now, fixed 25365a0.
- diff-bug #4: a lockfile or profile folder that links outside the site passes, and Docker cannot copy it — reject (edge: a link out of the site folder is outside documented and common use, and the effect is a build error; main also accepted such links).
- diff-bug #5: renv's `activate.R` copies `renv/profile` into `RENV_PROFILE`, so the message can name the wrong source — follow-up, row "Name the real source of a profile name".
- diff-bug #6: the name error printed `renv/profile` with other markup than the message — fix now, fixed 25365a0.
- diff-bug #7: GUIDE.md and README.md used `renv.lock` before the profile wording — fix now, fixed 25365a0.
- diff-bug #8: `read_lockfile_versions()` does not drop a byte order mark (pre-existing) — follow-up, row "Read renv.lock with a byte order mark".
- diff-bug #9: the allowed-names test repeated one path over 4 names and 2 sources with a weak check — fix now, fixed 25365a0 (3 names, one source, exact bytes).
- diff-bug #10: the `a` tab `b` probe takes the same path as `a b` — reject (planned change: the AC4 re-audit asked for it).
- diff-bug #11: "no profile folder" and "another letter case" overlap on Linux — reject (false: both shapes are AC4 cases, and the case shape tests the case check where the file system ignores case).
- diff-bug #12: only two lockfile checks run on the profile lockfile — reject (false as a gap: all checks share one `file` path, and a test per check would repeat one code path).
- blame-history #1: same as diff-bug #1 — fix now, fixed 25365a0. The top-level `renv.lock` case is pre-existing — follow-up, row "Match the letter case of renv.lock".
- blame-history #2: the profile Dockerfile was never built — reject (false: built at 6423f39 and 25365a0).
- blame-history #3: the Errors intro left out `renv/profile` — fix now, fixed 25365a0.
- blame-history #4: the skip reason is not in `missing_tool` of `check-skips.R` — reject (false: that list holds missing-tool skips that fail CI, and a system that cannot store a name is not a missing tool).
- blame-history #5: `withr::local_envvar()` at file top level may not restore — reject (false: it holds for that file only, LESSONS 2026-10-27 (M066)).
- prior-review #1: the NEWS.md bullet said `renv.lock` before the profile — fix now, fixed 25365a0.
- prior-review #2: README.md said "reads renv.lock" first — fix now, fixed 25365a0.
- prior-review #3: GUIDE.md used `renv.lock` before its definition — fix now, fixed 25365a0.
- prior-review #4: same as blame-history #3 — fix now, fixed 25365a0.
- prior-review #5: GUIDE.md after the steps relied on the definition — reject (false: the definition now opens the part).
- ripple #1: the candidate row says `write_dockerfile()` reads only `renv.lock` — reject (planned change: hygiene graduates the row).
- ripple #2: DESIGN.md said "The one Docker test" — fix now, fixed 25365a0.
- ripple #3 and #4: the NEWS.md bullet — fix now, fixed 25365a0.
- ripple #5: the test file header named only `renv.lock` — fix now, fixed 25365a0.
- ripple #6 and #8: help sentences use `renv.lock` — reject (planned change: the page defines `renv.lock` as the picked lockfile).
- ripple #7: same as blame-history #3 — fix now, fixed 25365a0.
- ripple #9: GUIDE.md forward reference — fix now, fixed 25365a0.
- ripple #10: README.md line 104 — fix now, fixed 25365a0.
- ripple #11: a test name says renv.lock — reject (false: the file unsets `RENV_PROFILE`, so the name is accurate).
- No snapshot files changed (`git diff --name-only main...HEAD` holds no `_snaps` path).
