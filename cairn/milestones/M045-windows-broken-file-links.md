<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M045: Detect broken file links on Windows

- **Status:** in-progress
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes what `release_supplement()`, `write_citation()`, `write_zenodo()`, and `write_dockerfile()` refuse on Windows
- **Branch/PR:** m045-windows-broken-file-links

## Goal

On Windows, `is_link()` counts a file symbolic link whose target is missing as a link, so the link refusals that read it refuse such a link as they do on macOS and Linux.

## Scope

**In:** fs under Imports in DESCRIPTION. On Windows, `is_link()` (`R/supplement-yml.R` about line 317) also counts each path that `fs::is_link()` reports as a link. `is_reparse_point()` stays as it is, so junctions are still found. The other callers of `is_link()` change with it on Windows: `add_data()`, `add_report()` and `create_supplement()` (through `path_occupied()` and their own checks), and the link, large-file, and figure checks of `check_supplement()`; AC4 and the full suite in AC6 guard them. The Windows skips of the link tests named in AC2 and AC3 go, and their folder-link cases use a junction on Windows. The roxygen, man pages, and NEWS.md bullet that say Windows misses such a link, the code comments that say so, and the DESIGN.md text on it.

**Out:** `check_tools()` reads `file.exists()`, not `is_link()` → candidate "Report broken Quarto links on Windows" (kept out at the question set). A page link in `docs/` to a file link whose target is missing, and names that end in a space or `.` that `is_reparse_point()` counts as links → candidate "Read odd-named folders on Windows". Replacing `is_reparse_point()` with fs → the same row, if the probe in T1 shows that fs finds junctions.

## Acceptance criteria

- [ ] AC1: `is_link()` returns TRUE for a file symbolic link that `file.symlink()` makes to a missing file, for a file link to an existing file, and for a link to a folder (a junction on Windows), and FALSE for a plain file, a plain folder, and a path that does not exist. When the fs call stops with an error for a path, `is_link()` gives the answer of its other rules for that path and no error. Tests in `tests/testthat/test-check-supplement.R` assert each case, the error case with the fs call mocked to stop, and pass on the windows-latest, macos-latest, and ubuntu-latest CI jobs.
- [ ] AC2: On the windows-latest CI job, `release_supplement()` stops with `supplement_error_file_exists` when `CITATION.cff` or `.zenodo.json` is a file link to a missing file. The file names in the site folder and the bytes of `_supplement.yml` stay as they were, and the link's target stays missing. The test "a link to a missing output file is refused before any write" in `tests/testthat/test-release-supplement.R` runs in that job with no skip and passes.
- [ ] AC3: On the windows-latest CI job, `write_citation()`, `write_zenodo()`, and `write_dockerfile()` stop with `supplement_error_file_exists` when an output path is a link to a file, a junction to a folder, or a file link to a missing file, with `overwrite = TRUE` and with `overwrite = FALSE`. The tests "a link at the output path is refused, with overwrite TRUE and FALSE" in `tests/testthat/test-write-metadata-errors.R` and "a link at either path is refused, with overwrite TRUE and FALSE" in `tests/testthat/test-write-dockerfile.R` run in that job with no skip and pass.
- [ ] AC4: On the windows-latest CI job, the test "links to files missing from the site give a broken-link row" in `tests/testthat/test-check-supplement.R` passes. Its `docs/dangling.html` is a file link to a missing file, so `check_supplement()` still gives that page its one "cannot be read" `broken-link` row there.
- [ ] AC5: The roxygen of `write_citation()` and `write_dockerfile()`, the man pages `write_citation.Rd`, `write_zenodo.Rd`, and `write_dockerfile.Rd`, and the NEWS.md bullet on the writers' link refusal do not say that Windows misses a file link to a missing file. That bullet says that Windows now refuses one. `grep -n -A1 'Windows' R/write-citation.R R/write-dockerfile.R man/write_citation.Rd man/write_zenodo.Rd man/write_dockerfile.Rd NEWS.md` shows no line that says such a link is not seen.
- [ ] AC6: DESCRIPTION lists fs under Imports. `devtools::document()` leaves `man/` and `NAMESPACE` with no diff, `devtools::test()` passes, and on the review machine `devtools::check()` gives 0 errors, 0 warnings, and no note that the default branch does not also give there. Every job of the R-CMD-check workflow passes on the PR head.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T4, T7
- AC3 → T2, T5, T7
- AC4 → T2, T7
- AC5 → T6
- AC6 → T2, T6, T7

## Tasks

- [x] T1: Probe on Windows CI first. On the branch, add a temporary test that prints, for each of these paths, `fs::is_link()`, `fs::file_info()$type`, `file.exists()`, and `is_reparse_point()`: a file link to a missing file, a file link to an existing file, a junction, a plain file, a plain folder, a missing path, and a path over 260 characters. Push the branch, read the windows-latest job log, write one work-log line with the results, and remove the probe. If `fs::is_link()` is not TRUE for the file link to a missing file, stop: the approach is wrong.
- [x] T2: Add fs to Imports in DESCRIPTION (D-022, written at the plan). In `is_link()`, on Windows, OR in the result of a small internal helper that calls `fs::is_link(path.expand(path))` for each path that is valid UTF-8 and gives FALSE when that call stops with an error (fs expands `~` from USERPROFILE, R from R_USER). Update the comments in `R/supplement-yml.R` about lines 272 to 278, 308 to 312, and 326 to 332.
- [x] T3: Move `symlink_or_skip()` from `tests/testthat/test-check-supplement.R` about line 909 to a helper file. Add the AC1 tests beside "the Windows link test gives the rules' answer for each path of a folder" (about line 1028). That test keeps its `dangling` flag, since `is_reparse_point()` does not change; the new tests assert `is_link()`, and one mocks the fs helper to stop. Run the tests on the Mac.
- [x] T4: In `tests/testthat/test-release-supplement.R`, remove the `skip_on_os("windows")` and its comment from "a link to a missing output file is refused before any write" (about line 563). In `expect_link_refused()`, make the link with `symlink_or_skip()` so that a failed link skips with "cannot make a symbolic link here", which `.github/scripts/check-skips.R` fails on.
- [x] T5: Remove `skip_on_os("windows")` from the AC3 tests (`test-write-metadata-errors.R` about line 373, `test-write-dockerfile.R` about line 293). Make each link with `symlink_or_skip()`, so the folder case is a junction on Windows (LESSONS M022).
- [x] T6: Edit the roxygen in `R/write-citation.R` about line 78 and `R/write-dockerfile.R` about line 124, then run `devtools::document()`. Edit the NEWS.md bullet about lines 115 to 118. In DESIGN.md, correct the text about lines 65 to 76, and the "Release edge cases" known issue against the Windows results that T7 shows. In the "Figure check edge cases" known issue, mark the Windows `ignored-output` sentence as not checked since M045, because no test makes that case. Remove the candidate-row comments in the tests (`test-release-supplement.R` about line 561, `test-check-supplement.R` about line 1046).
- [ ] T7: Push and read the three CI jobs and the skip list that the check-skips step prints, to see that the AC2 to AC4 tests ran on Windows. Run `devtools::test()` and `devtools::check()` on the Mac, and compare any note with a check of the default branch.

## Work log

- 2026-10-23: created by /milestone-plan.
- 2026-10-23: tier check: milestone — the fix changes what four exported functions refuse on Windows and needs a choice of detection method.
- 2026-10-23: idea vet: one concern. Base R cannot read the link flag on Windows, so a base R rule would infer a link from a listed name that `file.info()` cannot read, which can also count other names. The user chose fs "if it's not too bad": fs 2.1.0 is 1.05 MB installed, imports only `methods`, needs R 4.1 or later and compiled code, and already comes with rmarkdown through bslib and sass.
- 2026-10-23: question set: detection method — fs, on the user's condition that it is light (measured above); push the milestone branch during implement to run the Windows CI job — yes; also fix `check_tools()` — no, it stays in its own row.
- 2026-10-23: plan gate chose `fs::is_link()` over a base R rule (a listed name that `file.exists()` reports and `file.info()` cannot read) because fs reads the link flag and the user chose it; falsified by `fs::is_link()` giving FALSE for a file link to a missing file on the Windows runner (T1).
- 2026-10-23: collision check: absorbs the candidate rows "Detect broken file links on Windows" and "Test the link refusals on Windows" in full; "Report broken Quarto links on Windows" and "Read odd-named folders on Windows" stay as rows (Out); D-009 and D-017 kept the imports to yaml, jsonlite, and cli and chose base R for the link reader, and D-022 extends D-009; inbox sweep found 0 open issues and 0 open PRs.
- 2026-10-23: lessons surfaced: M018 (a file link to a missing file reads as an existing file on Windows; `Sys.readlink()` gives `""`), M022 (`file.symlink()` works on the runner, `unlink()` cannot remove a folder link, so use `Sys.junction()`), M009 (criteria as a rule plus listed tests), M012 (`expect_error(class =)` also matches a parent class).
- 2026-10-23: criteria audit (full mode, fresh Opus reader, on the base R draft): 5 findings, all fixed. `check_supplement()` also reads `is_link()`, so AC4 now holds its broken-link test on Windows; the folder case of AC3 uses a junction (T5); AC2 dropped the link-target claim, since `Sys.readlink()` gives `""` on Windows, and T4 makes a failed link skip with a reason the CI step fails on; AC1 names its cases; AC5 names its files and the NEWS.md bullet in place of "user docs".
- 2026-10-23: criteria re-audit (full mode, fresh Opus reader, after the switch to fs): 5 findings, all fixed. T3 keeps the rules test's `dangling` flag, since `is_reparse_point()` is unchanged; an fs error gives FALSE through a helper, and AC1 names that case (fs may stop on access denied or a long path; the T1 probe adds a long path); the helper passes `path.expand()` paths, since fs and R read `~` from different variables; Scope names the other `is_link()` callers, and T6 marks the figure-check sentence as not checked in place of a correction no test backs; AC6 names every workflow job.
- 2026-10-23: D-022 written in the plan commit in place of T2, and the plan's files were first committed as a local checkpoint while the re-audit ran.
- 2026-10-23: T1 probe (workflow run 40025299259, windows-latest, R 4.6.1, fs 2.1.0): `fs::is_link()` is TRUE for a file link to a missing file (where `is_link()` gives FALSE and `file.info()` warns "cannot open file"), a file link, a junction, and a folder link, and FALSE with no error for a plain file, a folder, a missing path, and a 311-character path; `fs::path_expand("~")` gave `C:/Users/runneradmin` and `path.expand("~")` gave `C:\Users\runneradmin\Documents`. Approach holds. Probe removed; the R-CMD-check run on the probe commit was cancelled.
- 2026-10-23: T2/T3: `fs_link()` in `R/supplement-yml.R` calls `fs::is_link()` once for the valid UTF-8 paths and, if that stops, once per path, each error giving FALSE; it drops trailing separators as `is_reparse_point()` does. The `path_occupied()` comment still holds, so it was not changed. `symlink_or_skip()` moved to `helper-files.R`; two new tests (`is_link()` cases; fs mocked to stop). The fs mock was shown to reach `fs_link()` (a TRUE mock gave TRUE; a stopping mock ran 3 times and gave FALSE). Mac `devtools::test()`: 380 tests, 0 failed, 10 skipped.
- 2026-10-23: T4/T5: the Windows skips are gone from the AC2 and AC3 tests, and their links come from `symlink_or_skip()`. The release test "a value error comes before the refusal of a linked output" keeps its own `file.symlink()`, since no criterion names it. On the Mac the three files pass (88 tests, 0 failed; the 1 skip is the Docker image test).
- 2026-10-23: T6: roxygen of `write_citation()` and `write_dockerfile()` now says a link to a missing file is refused, man pages rebuilt; the NEWS.md bullet says Windows now refuses one and that fs is imported; DESIGN.md architecture text and the "Release edge cases" and "Figure check edge cases" known issues corrected or marked not checked; the test comment now names `fs_link()`. The AC5 grep shows no "not seen" line. These docs rest on the T1 probe and on the Windows CI run in T7.

## Decisions

## Review
