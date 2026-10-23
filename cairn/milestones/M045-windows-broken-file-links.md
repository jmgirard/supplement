<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M045: Detect broken file links on Windows

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes what `release_supplement()`, `write_citation()`, `write_zenodo()`, and `write_dockerfile()` refuse on Windows
- **Branch/PR:** —

## Goal

On Windows, `is_link()` counts a file symbolic link whose target is missing as a link, so the link refusals that read it refuse such a link as they do on macOS and Linux.

## Scope

**In:** fs under Imports in DESCRIPTION. On Windows, `is_link()` (`R/supplement-yml.R` about line 317) also counts each path that `fs::is_link()` reports as a link. `is_reparse_point()` stays as it is, so junctions are still found. The Windows skips of the link tests named in AC2 and AC3 go, and their folder-link cases use a junction on Windows. The roxygen, man pages, and NEWS.md bullet that say Windows misses such a link, the code comments that say so, and the DESIGN.md text on it.

**Out:** `check_tools()` reads `file.exists()`, not `is_link()` → candidate "Report broken Quarto links on Windows" (kept out at the question set). A page link in `docs/` to a file link whose target is missing, and names that end in a space or `.` that `is_reparse_point()` counts as links → candidate "Read odd-named folders on Windows". Replacing `is_reparse_point()` with fs → the same row, if the probe in T1 shows that fs finds junctions.

## Acceptance criteria

- [ ] AC1: `is_link()` returns TRUE for a file symbolic link that `file.symlink()` makes to a missing file, for a file link to an existing file, and for a link to a folder (a junction on Windows), and FALSE for a plain file, a plain folder, and a path that does not exist. A test in `tests/testthat/test-check-supplement.R` asserts each case and passes on the windows-latest, macos-latest, and ubuntu-latest CI jobs.
- [ ] AC2: On the windows-latest CI job, `release_supplement()` stops with `supplement_error_file_exists` when `CITATION.cff` or `.zenodo.json` is a file link to a missing file. The file names in the site folder and the bytes of `_supplement.yml` stay as they were, and the link's target stays missing. The test "a link to a missing output file is refused before any write" in `tests/testthat/test-release-supplement.R` runs in that job with no skip and passes.
- [ ] AC3: On the windows-latest CI job, `write_citation()`, `write_zenodo()`, and `write_dockerfile()` stop with `supplement_error_file_exists` when an output path is a link to a file, a junction to a folder, or a file link to a missing file, with `overwrite = TRUE` and with `overwrite = FALSE`. The tests "a link at the output path is refused, with overwrite TRUE and FALSE" in `tests/testthat/test-write-metadata-errors.R` and "a link at either path is refused, with overwrite TRUE and FALSE" in `tests/testthat/test-write-dockerfile.R` run in that job with no skip and pass.
- [ ] AC4: On the windows-latest CI job, the test "links to files missing from the site give a broken-link row" in `tests/testthat/test-check-supplement.R` passes. Its `docs/dangling.html` is a file link to a missing file, so `check_supplement()` still gives that page its one "cannot be read" `broken-link` row there.
- [ ] AC5: The roxygen of `write_citation()` and `write_dockerfile()`, the man pages `write_citation.Rd`, `write_zenodo.Rd`, and `write_dockerfile.Rd`, and the NEWS.md bullet on the writers' link refusal do not say that Windows misses a file link to a missing file. That bullet says that Windows now refuses one. `grep -n -A1 'Windows' R/write-citation.R R/write-dockerfile.R man/write_citation.Rd man/write_zenodo.Rd man/write_dockerfile.Rd NEWS.md` shows no line that says such a link is not seen.
- [ ] AC6: DESCRIPTION lists fs under Imports. `devtools::document()` leaves `man/` and `NAMESPACE` with no diff, `devtools::test()` passes, and on the review machine `devtools::check()` gives 0 errors, 0 warnings, and no note that the default branch does not also give there. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T4, T7
- AC3 → T2, T5, T7
- AC4 → T2, T7
- AC5 → T6
- AC6 → T2, T6, T7

## Tasks

- [ ] T1: Probe on Windows CI first. On the branch, add a temporary test that prints, for each of these paths, `fs::is_link()`, `fs::file_info()$type`, `file.exists()`, and `is_reparse_point()`: a file link to a missing file, a file link to an existing file, a junction, a plain file, a plain folder, and a missing path. Push the branch, read the windows-latest job log, write one work-log line with the results, and remove the probe. If `fs::is_link()` is not TRUE for the file link to a missing file, stop: the approach is wrong.
- [ ] T2: Add fs to Imports in DESCRIPTION and write D-022 (fs is an imported dependency, granted at the M045 plan). In `is_link()`, on Windows, OR in `fs::is_link()` for each path that is valid UTF-8. Update the comments in `R/supplement-yml.R` about lines 272 to 278, 308 to 312, and 326 to 332.
- [ ] T3: Move `symlink_or_skip()` from `tests/testthat/test-check-supplement.R` about line 909 to a helper file. Add the AC1 test, or extend "the Windows link test gives the rules' answer for each path of a folder" (about line 1028), and remove its Windows-only `dangling` expectation where `is_link()` is asserted. Run the tests on the Mac.
- [ ] T4: In `tests/testthat/test-release-supplement.R`, remove the `skip_on_os("windows")` and its comment from "a link to a missing output file is refused before any write" (about line 563). In `expect_link_refused()`, make the link with `symlink_or_skip()` so that a failed link skips with "cannot make a symbolic link here", which `.github/scripts/check-skips.R` fails on.
- [ ] T5: Remove `skip_on_os("windows")` from the AC3 tests (`test-write-metadata-errors.R` about line 373, `test-write-dockerfile.R` about line 293). Make each link with `symlink_or_skip()`, so the folder case is a junction on Windows (LESSONS M022).
- [ ] T6: Edit the roxygen in `R/write-citation.R` about line 78 and `R/write-dockerfile.R` about line 124, then run `devtools::document()`. Edit the NEWS.md bullet about lines 115 to 118. In DESIGN.md, correct the text about lines 65 to 76, the "Release edge cases" known issue, and the "Figure check edge cases" known issue against the Windows results that T7 shows. Remove the candidate-row comments in the tests (`test-release-supplement.R` about line 561, `test-check-supplement.R` about line 1046).
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

## Decisions

## Review
