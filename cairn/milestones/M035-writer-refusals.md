# M035: The writers refuse links and repeated lockfile keys

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the errors of the exported `write_citation()`, `write_zenodo()`, and `write_dockerfile()`
- **Branch/PR:** m035-writer-refusals

## Goal

`write_citation()`, `write_zenodo()`, and `write_dockerfile()` refuse a link at an output path by one shared rule, whatever `overwrite` is, and `write_dockerfile()` refuses a `renv.lock` that repeats a key it reads.

## Scope

**In:** `check_overwrite()` in `R/supplement-yml.R` takes one or more paths and refuses, in this order, a link at any of them, then a folder at any of them, then an existing file at any of them when `overwrite` is not `TRUE`. Its link message says the path is a link and tells the author to remove it. `write_dockerfile()` passes both targets in one call and drops its own link loop. `read_lockfile_versions()` in `R/write-dockerfile.R` refuses a repeated key among the five it reads, before any value check. The Errors sections of `?write_citation` and `?write_dockerfile`, the `NEWS.md` bullets for the writers and for `write_dockerfile()`, and `cairn/DESIGN.md` (Architecture and the "Release edge cases" Known issue) state the new rules.

**Out:** A file link to a missing file on Windows, which `is_link()` misses, stays in the candidate row "Detect broken file links on Windows". A repeated key that `write_dockerfile()` does not read, and the JSON reads in `check_supplement()`, are not checked. A linked `_supplement.yml` stays in the "Release edge cases" Known issue.

## Acceptance criteria

- [ ] AC1: On macOS and Linux, with a `_supplement.yml` that the writer accepts, `write_citation()` and `write_zenodo()` stop with `supplement_error_file_exists` for a symbolic link at the output path, with `overwrite = TRUE` and with `overwrite = FALSE`. After the call the site folder's files are the same, a link target that exists has the same bytes, and a missing target still does not exist. A test in `tests/testthat/test-write-metadata-errors.R` runs both writers, both `overwrite` values, and four link shapes: an absolute link to a file outside the site, an absolute link to a folder, an absolute link to a missing target, and a relative link to a file inside the site (`README.md`). The test skips on Windows.
- [ ] AC2: On macOS and Linux, for a link at an output path, the three writers give a message that says the path is a link and tells the author to remove it, with either `overwrite` value, and the message does not suggest `overwrite = TRUE`. This holds for `write_dockerfile()` also when the link is at `.dockerignore` and a plain `Dockerfile` exists with `overwrite = FALSE`. The AC1 test and the `write_dockerfile()` link test in `tests/testthat/test-write-dockerfile.R` assert this text for each writer, and the second test has a case for that `Dockerfile` setup.
- [ ] AC3: On macOS and Linux, `write_dockerfile()` refuses a link at `Dockerfile` or `.dockerignore` with `supplement_error_file_exists`, for both `overwrite` values and the three link shapes of its existing link test, and leaves the site folder unchanged. The existing test keeps its inputs.
- [ ] AC4: `write_dockerfile()` stops with `supplement_error_lockfile`, writes nothing, and names the repeated key in its message when `renv.lock` holds one of these keys twice in the same object: `R` or `Packages` at the top level, `Version` in `R`, `renv` in `Packages`, or `Version` in `Packages.renv`. The repeated-key error comes before every check of a value. A test in `tests/testthat/test-write-dockerfile.R` runs one lockfile per key with two different values, one that repeats `R` with the same value twice, and one that repeats `Packages.renv.Version` while `R.Version` is `"3.6.0"`. A lockfile that repeats a key the function does not read (a second `cli` entry under `Packages`) still gives a `Dockerfile`, in the same test.
- [ ] AC5: The Errors section of `?write_citation` (which `?write_zenodo` inherits) says that a link at the output path is `supplement_error_file_exists` whatever `overwrite` is, except a file link to a missing file on Windows. The Errors section of `?write_dockerfile` says the same for its two targets and lists a repeated key among the `supplement_error_lockfile` cases. In `NEWS.md`, the bullet that starts "`write_citation()` and `write_zenodo()` write" states the link rule, and the bullet that starts "`write_dockerfile()` reads" states the repeated-key rule.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T1
- AC4 → T2
- AC5 → T3

## Tasks

- [x] T1: Write the AC1 test and the AC2 message assertions first, and see the `overwrite = TRUE` cases fail on main. Then change `check_overwrite()` (`R/supplement-yml.R:273`) to take a vector of paths and check links, then folders, then existing files. Make `write_dockerfile()` (`R/write-dockerfile.R:160`) call it once with both targets, and add the `.dockerignore` link plus plain `Dockerfile` case to its link test (line 258). Run `devtools::test()`.
- [x] T2: Write the AC4 test first, then add the repeated-key check to `read_lockfile_versions()` (`R/write-dockerfile.R:190`), at each level before that level's value checks, through `lockfile_error()`. Run `devtools::test()`.
- [x] T3: Update the roxygen Errors sections of `R/write-citation.R` and `R/write-dockerfile.R`, run `devtools::document()`, and edit the two `NEWS.md` bullets (around lines 30 and 80). Update `cairn/DESIGN.md` Architecture (the writers' sentence near line 70 and the `write_dockerfile()` sentence near line 105) and add the writers to the Windows sentence of the "Release edge cases" Known issue. Run `devtools::check()`.

## Work log

- 2026-10-22: created by /milestone-plan.
- 2026-10-22: tier check: not run — work named at the question set.
- 2026-10-22: idea vet: no concern found. A write through a link can change a file outside the site, and `release_supplement()` and `write_dockerfile()` already refuse links, so the rule is the package's own. jsonlite keeps both copies of a repeated key and `[[` takes the first, so the Dockerfile could be built from a version renv does not use; renv never writes such a file, so the check is limited to the five keys the function reads. The package is unreleased (0.0.0.9000), so the changed errors need no deprecation cycle.
- 2026-10-22: question set: which work to plan — "Harden the writers", absorbing the candidate rows "Refuse links in the citation writers" and "Refuse duplicate keys in renv.lock" in full. Site deploy question — not applicable.
- 2026-10-22: plan chose one link rule in `check_overwrite()` for all three writers over a link check in each writer, because three copies of one rule drift, as the citation writers already did; falsified by a writer that must accept a link at its output.
- 2026-10-22: plan chose to refuse a repeated key only among the five keys read over refusing any repeated key in `renv.lock`, because the rest of the file goes to renv, whose reader decides; falsified by a repeated key elsewhere that changes the image the Dockerfile builds.
- 2026-10-22: collision check: absorbs the two candidate rows above; extends M032 (archived), which added the `write_dockerfile()` link refusal, and M009/M012, which added the release's link refusal. No D-entry conflicts. The inbox sweep found 0 open issues and 0 open PRs.
- 2026-10-22: criteria audit (full mode, fresh Opus reader) returned 9 findings, all fixed: AC1 scoped to macOS and Linux and an accepted `_supplement.yml`, with a relative in-site link shape and "still does not exist" for a missing target; AC2's `.dockerignore` link behind a plain `Dockerfile` case, fixed by checking links on both targets first; AC3 restated as behavior, not as the test; AC4's repeated-key check moved before value checks, with a probe that pairs it with R 3.6.0; AC5 given the Windows exception and named bullets. A JSON-escaped spelling of a key was judged optional and left out, because the duplicate is found after parsing.
- 2026-10-22: lessons applied: M018 and M022 (Windows link behavior; the link tests skip Windows as the existing one does), M006 (`Sys.readlink()` NA for a missing path), M012 (assert the error class on the returned condition).
- 2026-10-22: changelog: AC5 edits two existing unreleased `NEWS.md` bullets and adds none.
- 2026-10-22: implement started on branch m035-writer-refusals.
- 2026-10-22: checkpoint (T1 not checked off): `check_overwrite()` takes several paths and refuses links first; the new link test replaces "a dangling link with the output file's name is kept", which it covers. On main it failed with "already exists" for `overwrite = FALSE` and no error for `overwrite = TRUE`; both writer test files pass with the change. Full suite still running.
- 2026-10-22: T1 done: `devtools::test()` 336 tests, 0 failed, 8 skipped.
- 2026-10-22: checkpoint (T2 not checked off): repeated-key check in `read_lockfile_versions()` before any value check; on main the new test failed with no error raised, and the dockerfile test file passes with the change. Full suite running.
- 2026-10-22: T2 done: `devtools::test()` 338 tests, 0 failed, 8 skipped.
- 2026-10-22: checkpoint (T3 not checked off): Errors sections, help pages, two NEWS bullets, and DESIGN Architecture and Known issue updated; the Windows sentence says a missing-target file link is written through only with `overwrite = TRUE`, since with `FALSE` it reads as an existing file (the `is_reparse_point()` comment). `devtools::check()` running.
- 2026-10-22: claim audit: 22 claims read, 1 corrected — NEWS.md (the writers' link bullet gained the Windows exception); also fixed a spacing slip at `R/write-dockerfile.R:233`.
- 2026-10-22: T3 done: `devtools::document()` wrote the three Rd files; `devtools::check()` 0 errors, 0 warnings, 0 notes (built from 43e50d7; the later commit changed one space in R code and one NEWS sentence, and the dockerfile tests pass after it). Status set to review.

## Decisions

## Review
