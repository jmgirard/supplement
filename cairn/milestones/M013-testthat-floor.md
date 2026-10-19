<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M013: DESCRIPTION asks for testthat 3.2.0, and the tests pass under it

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** high   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — DESCRIPTION's Suggests field is read by anyone who installs or checks the package   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m013-testthat-floor   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

DESCRIPTION's testthat floor is 3.2.0, the floor the user chose (D-013), and the tests are shown to pass under testthat 3.2.0.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** change `testthat (>= 3.0.0)` to `testthat (>= 3.2.0)` in DESCRIPTION Suggests. Run the tests under testthat 3.2.0, built from the CRAN archive into a scratch library outside the repository. Check that 3.2.0 exports each testthat function that the tests call.

**Out:** a floor lower than 3.2.0 (the user chose 3.2.0; D-013). Rewriting `expect_no_error()` as `expect_error(x, NA)` (it cannot keep the old floor, because `local_mocked_bindings()` needs 3.1.7). A check that keeps the floor true as tests change, and floors for withr, knitr, and rmarkdown → candidate row "Suggests floor guard". A NEWS.md entry (no package behavior changes).

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: `DESCRIPTION` lists `testthat (>= 3.2.0)` under Suggests. With quarto and git on PATH and `NOT_CRAN=true`, `testthat::test_local()`, run with testthat 3.2.0 loaded from a library outside the repository, reports 0 failures and 0 errors over `tests/testthat/`, and it skips no test that the same run under the installed testthat does not skip. When its only failure is at `test-template.R:140` (the known flake), one clean rerun meets this.
- [ ] AC2: testthat 3.2.0 exports every testthat function that a file in `tests/testthat/` calls by name: the `SYMBOL_FUNCTION_CALL` tokens from `getParseData()` on each file that name an export of the installed testthat, less names that a file under `tests/testthat/` assigns or takes as a function argument (today `source_file` and `setup`).
- [ ] AC3: Under the installed testthat, `devtools::test()` reports 0 failures and 0 errors, and `devtools::check()` reports 0 errors and 0 warnings, with no NOTE that names DESCRIPTION's Suggests field or testthat. When, in either run, the only test failure is at `test-template.R:140`, one clean rerun of that run meets this.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1, T2
- AC2 → T3
- AC3 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive change is amend-via-gate. -->

- [x] T1: Edit `DESCRIPTION` Suggests to `testthat (>= 3.2.0)`.
- [ ] T2: Install `testthat_3.2.0.tar.gz` from `https://cran.r-project.org/src/contrib/Archive/testthat/` into a scratch library outside the repository with `install.packages(<url>, repos = NULL, type = "source", lib = <scratch>)`. devtools 2.5.2 needs testthat 3.3.2, so run `NOT_CRAN=true Rscript -e '.libPaths(c("<scratch>", .libPaths())); print(packageVersion("testthat")); testthat::test_local(reporter = "summary")'`, and run the same command without the scratch library for the skip comparison. Compare the two skip lists. If the 3.2.0 install or run fails at any test other than the flake, stop: the floor the user chose does not hold.
- [ ] T3: In a session with the scratch library first, parse each file in `tests/testthat/` with `getParseData()`, keep the `SYMBOL_FUNCTION_CALL` tokens that name an export of the installed testthat, drop names that a test file assigns or takes as an argument, and test each against `getNamespaceExports("testthat")` of 3.2.0.
- [ ] T4: Run `devtools::test()` and `devtools::check()` under the installed testthat.

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

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive. -->
