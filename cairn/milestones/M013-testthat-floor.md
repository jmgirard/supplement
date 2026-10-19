<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M013: DESCRIPTION asks for testthat 3.3.0, and the tests pass under it

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — DESCRIPTION's Suggests field is read by anyone who installs or checks the package   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m013-testthat-floor   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

DESCRIPTION's testthat floor is 3.3.0, the first CRAN release after 3.2.3; testthat 3.2.0 through 3.2.3 do not compile under R 4.6.1 (D-014). The tests are shown to pass under testthat 3.3.0.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** change `testthat (>= 3.0.0)` to `testthat (>= 3.3.0)` in DESCRIPTION Suggests. Run the tests under testthat 3.3.0, built from the CRAN archive into a scratch library outside the repository. Check that 3.3.0 exports each testthat function that the tests call.

**Out:** a floor lower than 3.3.0 (the 3.2 releases do not compile under R 4.6.1, and the user chose 3.3.0; D-014). Rewriting `expect_no_error()` as `expect_error(x, NA)` (it cannot keep the old floor, because `local_mocked_bindings()` needs 3.1.7). A check that keeps the floor true as tests change, and floors for withr, knitr, and rmarkdown → candidate row "Suggests floor guard". A NEWS.md entry (no package behavior changes).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: `DESCRIPTION` lists `testthat (>= 3.3.0)` under Suggests. With quarto and git on PATH and `NOT_CRAN=true`, `testthat::test_local()`, run with testthat 3.3.0 loaded from a library outside the repository, reports 0 failures and 0 errors over `tests/testthat/`, and it skips no test that the same run under the installed testthat does not skip. When its only failure is at `test-template.R:140` (the known flake), one clean rerun meets this.
- [x] AC2: testthat 3.3.0 exports every testthat function that a file in `tests/testthat/` calls by name: the `SYMBOL_FUNCTION_CALL` tokens from `getParseData()` on each file that name an export of testthat 3.3.2 in the default library, less names that a file under `tests/testthat/` assigns or takes as a function argument (today `source_file` and `setup`).
- [x] AC3: Under the installed testthat, `devtools::test()` reports 0 failures and 0 errors, and `devtools::check()` reports 0 errors and 0 warnings, with no NOTE that names DESCRIPTION's Suggests field or testthat. When, in either run, the only test failure is at `test-template.R:140`, one clean rerun of that run meets this.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive change is amend-via-gate. -->

- [x] T1: Edit `DESCRIPTION` Suggests to `testthat (>= 3.3.0)`.
- [x] T2: Install `testthat_3.3.0.tar.gz` from `https://cran.r-project.org/src/contrib/Archive/testthat/` into a scratch library outside the repository with `install.packages(<file>, repos = NULL, type = "source", lib = <scratch>)`. devtools 2.5.2 needs testthat 3.3.2, so run `NOT_CRAN=true Rscript -e '.libPaths(c("<scratch>", .libPaths())); print(packageVersion("testthat")); testthat::test_local(reporter = "summary")'`, and run the same command without the scratch library for the skip comparison. Compare the two skip lists. If the run fails at any test other than the flake, stop.
- [x] T3: In a session on the default library (testthat 3.3.2), parse each file in `tests/testthat/` with `getParseData()`, keep the `SYMBOL_FUNCTION_CALL` tokens that name a testthat export, and drop names that a test file assigns or takes as an argument. In a second session with the scratch library first, test each name against `getNamespaceExports("testthat")` of 3.3.0.
- [x] T4: Run `devtools::test()` and `devtools::check()` under the installed testthat.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-18: created by /milestone-plan from the [high] candidate row "testthat floor".
- 2026-10-18: tier check: milestone — a dependency change with a choice of floor.
- 2026-10-18: investigation: the tests call 24 testthat functions; the newest are `local_mocked_bindings()` (3.1.7, 25 calls, all of package functions) and `expect_no_error()`/`expect_no_warning()` (3.1.5); devtools 2.5.2 needs testthat 3.3.2, so old-version runs use `test_local()`; no GitHub issues or PRs are open.
- 2026-10-18: collision check: absorbed the "testthat floor" candidate row; D-005's floor superseded by D-013; no archive milestone changed the floor.
- 2026-10-18: question set: testthat floor — 3.2.0 (the user chose it over the lowest passing release, likely 3.1.7); D-013 records it.
- 2026-10-18: question set: download old testthat source releases from the CRAN archive into a scratch folder outside the repository — yes.
- 2026-10-18: plan gate chose raising the floor over rewriting `expect_no_error()` as `expect_error(x, NA)` because `local_mocked_bindings()` needs 3.1.7 either way; falsified by a testthat release below 3.1.7 that exports `local_mocked_bindings()`.
- 2026-10-18: criteria audit (full mode, fresh Opus reader): 6 findings, all taken: skip parity and quarto and git on PATH (AC1), a rerun rule for the flake at `test-template.R:140` (AC1, AC3), install failure counts as not working (old AC2), `source_file` and `setup` excluded from the parse sweep (AC2), "each NOTE justified" replaced by a stated rule (AC3), version print moved to T2.
- 2026-10-18: criteria re-audit after the 3.2.0 answer (full mode, same reader): old AC2 (lowest floor) removed; 3 findings taken: `NOT_CRAN=true` moved into AC1, the AC3 rerun rule covers both runs, and the goal and D-013 make no claim that 3.2.0 is the minimum.
- 2026-10-18: no NEWS.md entry: the floor applies only to running the tests, and no package behavior changes.
- 2026-10-18: added candidate row "Suggests floor guard" for a check that keeps the floors true.
- 2026-10-18: /milestone-implement started; branch m013-testthat-floor cut from main at 538276b.
- 2026-10-18: T1 done: DESCRIPTION Suggests now `testthat (>= 3.2.0)`; `devtools::test()` under testthat 3.3.2 with NOT_CRAN=true: 0 failures, 0 errors, 1 skip (`test-add-data.R:309`, case-insensitive disk).
- 2026-10-18: T2 blocked: testthat 3.2.0 source fails to compile under R 4.6.1 (`reassign.c` calls `SET_FORMALS`, `FORMALS`, `SET_BODY`, `BODY`, `SET_CLOENV`, `CLOENV`, which R 4.6 does not declare); the tarballs of 3.2.1, 3.2.1.1, 3.2.2, and 3.2.3 hold the same calls, and 3.3.0 does not and builds; this machine has only R 4.6, and its one Docker image is `rocker/r-ver:4.6`. Stopped for the user, because AC1 cannot be met as written here.
- 2026-10-18: substantive amendment: at the T2 stop the user chose a 3.3.0 floor over running 3.2.0 in an R 4.5 Docker image or keeping 3.2.0 with no test run; Goal, title, Scope, AC1, AC2, and T1 to T3 now name 3.3.0, and D-014 supersedes D-013; the Goal was re-cut in place at the user's choice instead of returning to /milestone-plan.
- 2026-10-18: re-audit: AC1 (full) — nothing for AC1; the Goal's "oldest release that builds under R 4.6.1" was unbounded (narrowed to "the first CRAN release after 3.2.3"), D-014 says the floor comes from the build, and the title, Scope, and tasks still named 3.2.0 (fixed).
- 2026-10-18: re-audit: AC2 (full) — the filter "an export of the installed testthat" was circular with the scratch library first; narrowed to "testthat 3.3.2 in the default library".
- 2026-10-18: re-audit: AC2 (full) — nothing (second reader on the narrowed wording; it ran the sweep and found 30 names, none missing from 3.3.0).
- 2026-10-18: T1 done: DESCRIPTION Suggests now `testthat (>= 3.3.0)`.
- 2026-10-18: T2 done: testthat 3.3.0 built from the archive tarball into the scratch library; `test_local()` with NOT_CRAN=true under 3.3.0 (printed `3.3.0` and the scratch path first): 0 failures, 0 errors, 1 skip (`test-add-data.R:309`); the same run under 3.3.2: the same one skip.
- 2026-10-18: T3 done: the parse sweep over 15 files keeps 30 testthat names (excluded `source_file` and `setup`); 0 are missing from 3.3.0's exports; a planted name `expect_not_in_testthat` reads as missing, so the check can fail. A first sweep compared parse ids for assignment order, missed `source_file`, and was fixed to compare positions.
- 2026-10-18: T4 done: under testthat 3.3.2, `devtools::test()` with NOT_CRAN=true: 0 failures, 1 skip (`test-add-data.R:309`); `devtools::check()`: 0 errors, 0 warnings, 0 notes.
- 2026-10-18: claim audit: 2 claims read, 0 corrected — DESCRIPTION (the tests pass under 3.3.0: holds; 3.3.0 as a need: 3.2.0's NAMESPACE already exports every called function, so the floor is the oldest release shown to pass, as D-014 states; outside text must not call 3.3.0 required).
- 2026-10-18: implement done; status review.

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive. -->

Pass 1, 2026-10-18, on m013-testthat-floor at f786ce8 (main at 538276b, not moved).

- AC1 evidence: `DESCRIPTION` line 22 reads `testthat (>= 3.3.0),` under Suggests. With quarto 1.10.19 and git on PATH and NOT_CRAN=true, `test_local()` with the scratch library first printed `3.3.0` and the scratch path: exit 0, no failed or errored test, 1 skip (`test-add-data.R:309`, case-insensitive disk). The same run under 3.3.2: exit 0, the same one skip, so no extra skip under 3.3.0.
- AC2 evidence: the parse sweep on the default library (testthat 3.3.2) over the 15 files in `tests/testthat/` kept 30 names after excluding `source_file` and `setup`; with the scratch library first (printed `3.3.0`), 0 of the 30 are missing from `getNamespaceExports("testthat")`. A planted name read as missing at implement (T3), so the check can fail.
- AC3 evidence: under testthat 3.3.2, `devtools::test()` with NOT_CRAN=true: exit 0, no failed or errored test, 1 skip (`test-add-data.R:309`); `devtools::check()`: 0 errors, 0 warnings, 0 notes. No rerun was needed.
- gate: `cairn_validate.py` all checks passed; principle impact skipped (no principle changed); `devtools::document()` leaves no diff; no README.Rmd and no `_pkgdown.yml`; no new top-level files; `check()` clean as above; changelog: no NEWS.md entry, as the plan's Scope Out states (no package behavior changes).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: D-014 calls R 4.6.1 "the only R where the run could take place", though the user declined an R 4.5 Docker run — fix now.
- diff-bug #2: the Goal was edited in place against its owner comment — reject (planned change: the user chose the re-cut at the T2 stop, and the work log records it).
- diff-bug #3: D-014 states "On R below 4.6, the 3.2 releases build" with no check — fix now.
- diff-bug #4: the investigation line says 24 testthat functions, T3 says 30 — fix now (a correcting work-log line; the 24 was a miscount).
- diff-bug #5: AC2's filter depends on the default library's version — reject (false: AC2 names testthat 3.3.2, so a rerun with that version gives the same set).
- diff-bug #6: testthat 3.3.0 declares `Depends: R (>= 4.1.0)` (3.2.0 declares 3.6.0), so the floor means the tests need R 4.1 — fix now (D-014 Consequences states it).
- diff-bug #7: the "testthat floor" candidate row is still open — reject (planned change: post-merge hygiene removes the row that carries "started M013").
- blame-history #1: the floor changed at an implement stop and the Goal was re-cut in place — reject (planned change: the user's choice at the stop, logged).
- blame-history #2: D-014 takes neither option D-013 framed and swaps a function-based reason for a build-based one — reject (false as a defect: D-014 supersedes D-013 by name and records the user's choice and its reason).
- blame-history #3: users of testthat 3.2.0 to 3.2.3 are now asked to update — reject (planned change: D-014 Consequences records it).
- blame-history #4: no NEWS.md entry for the floor — reject (planned change: Scope Out; the package is unreleased and no behavior changes).
- prior-review: no findings (M008 and M009 Review lines raised the floor; the diff answers them; the PR comment probe returned none).
- ripple #1: the "testthat floor" candidate row still describes the old problem — reject (planned change: post-merge hygiene removes it).
