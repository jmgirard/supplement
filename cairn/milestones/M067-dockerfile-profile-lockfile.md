<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section. -->
# M067: Write Dockerfiles from profile lockfiles

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — it changes which lockfile the exported `write_dockerfile()` reads and what it writes
- **Branch/PR:** m067-dockerfile-profile-lockfile

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

- [ ] AC1: When `lock_source()` names no profile, `write_dockerfile()` prints no message. The `Dockerfile` bytes equal `dockerfile_461` in `tests/testthat/test-write-dockerfile.R`, and the `.dockerignore` bytes equal `*\n!renv.lock\n`. Tests cover these cases with `RENV_PROFILE` unset and no `renv/profile`, with `RENV_PROFILE=default`, with `default` in `renv/profile`, with an empty `renv/profile`, and with a `renv/profile` whose first line is empty.
- [ ] AC2: When `lock_source()` names a profile `<name>`, `write_dockerfile()` reads the R and renv versions from `renv/profiles/<name>/renv.lock`. It writes `.dockerignore` as the lines `*` and `!renv/profiles/<name>/renv.lock`. The Dockerfile sets `RENV_PROFILE=<name>` in its `ENV` instruction. It copies the lockfile with `COPY renv/profiles/<name>/renv.lock renv/profiles/<name>/renv.lock`. The `supplement_error_lockfile` checks apply to the profile lockfile, and their messages name its path. Byte tests pin both files for a name from `RENV_PROFILE` and for a name from `renv/profile`. In one test, `renv.lock` and the profile lockfile record different R versions, and the `FROM` line has the R version of the profile lockfile.
- [ ] AC3: With a profile, `write_dockerfile()` prints one message after every check of AC2 and AC4 passes and before it writes a file. The message names the lockfile path, the profile, and the source of the name (`RENV_PROFILE` or `renv/profile`). A test asserts its text for each source.
- [ ] AC4: Each case below stops `write_dockerfile()` before it writes a file and before it prints the message. Tests show that the file hashes of the site folder do not change. The name check comes before the file checks. The cases:
  - The profile name has a character other than an ASCII letter, a digit, `.`, `_`, or `-`. Or the name starts with `.`. The class is `supplement_error_profile`. The tests use `.dev`, `..`, `a/b`, `a\b`, `a b`, `dev ` with a trailing space, `a"b`, `a$b`, `a*b`, `é`, a UTF-8 byte order mark before `dev`, and a name that is not valid UTF-8. They take each name from `RENV_PROFILE` and from `renv/profile` where the system can store it. A name with a line break comes from `RENV_PROFILE` only.
  - `renv/profile` is a folder, or a file that cannot be opened (skipped on Windows and as root). The class is `supplement_error_profile`.
  - `list.files()` of `renv/profiles` lists no folder named `<name>` with the same letter case. Or that folder holds no file `renv.lock`, or `renv.lock` there is a folder or a link to a missing file. The class is `supplement_error_no_file`, and the message names the path.
- [ ] AC5: With `SUPPLEMENT_TEST_DOCKER=true`, a test builds an image from a renv site whose `renv/profile` names a profile. The site has no `renv.lock` in its top folder. Its lockfile is at `renv/profiles/<name>/renv.lock`. The test renders the example report of the template with `--network none`. The Computing environment section of the page shows the R version of the profile lockfile and a library path under `/opt/renv/library/profiles/<name>/`.
- [ ] AC6: Five texts state which lockfile `write_dockerfile()` reads. They also state that the image sets the profile. The texts:
  - the help page of `write_dockerfile()`, whose Errors section lists `supplement_error_profile`
  - the "Running reports in a container" part of `inst/template/GUIDE.md`
  - the "Record the R setup" part of `README.md`
  - one `NEWS.md` bullet
  - the `R/write-dockerfile.R` paragraph of the Architecture part of `cairn/DESIGN.md`

  No sentence in these texts says that the function always reads `renv.lock` in the site folder. No sentence says that `.dockerignore` always holds `!renv.lock`.
- [ ] AC7: `devtools::document()` leaves no diff, `devtools::test()` reports 0 failures, and `devtools::check()` reports 0 errors and 0 warnings.

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
- [ ] T2: Add the profile case of AC5 to the gated Docker test. Ask the user to start Docker Desktop, then run the test once on this Mac (macOS arm64).
- [ ] T3: Update the roxygen help (title, description, `path`, `.dockerignore` text, Errors), then run `devtools::document()`. Update GUIDE.md, README.md, NEWS.md, and DESIGN.md. Then run `devtools::check()`.

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
