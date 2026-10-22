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

- [x] AC1: On macOS and Linux, with a `_supplement.yml` that the writer accepts, `write_citation()` and `write_zenodo()` stop with `supplement_error_file_exists` for a symbolic link at the output path, with `overwrite = TRUE` and with `overwrite = FALSE`. After the call the site folder's files are the same, a link target that exists has the same bytes, and a missing target still does not exist. A test in `tests/testthat/test-write-metadata-errors.R` runs both writers, both `overwrite` values, and four link shapes: an absolute link to a file outside the site, an absolute link to a folder, an absolute link to a missing target, and a relative link to a file inside the site (`README.md`). The test skips on Windows.
- [x] AC2: On macOS and Linux, for a link at an output path, the three writers give a message that says the path is a link and tells the author to remove it, with either `overwrite` value, and the message does not suggest `overwrite = TRUE`. This holds for `write_dockerfile()` also when the link is at `.dockerignore` and a plain `Dockerfile` exists with `overwrite = FALSE`. The AC1 test and the `write_dockerfile()` link test in `tests/testthat/test-write-dockerfile.R` assert this text for each writer, and the second test has a case for that `Dockerfile` setup.
- [x] AC3: On macOS and Linux, `write_dockerfile()` refuses a link at `Dockerfile` or `.dockerignore` with `supplement_error_file_exists`, for both `overwrite` values and the three link shapes of its existing link test, and leaves the site folder unchanged. The existing test keeps its inputs.
- [x] AC4: `write_dockerfile()` stops with `supplement_error_lockfile`, writes nothing, and names the repeated key in its message when `renv.lock` holds one of these keys twice in the same object: `R` or `Packages` at the top level, `Version` in `R`, `renv` in `Packages`, or `Version` in `Packages.renv`. The repeated-key error comes before every check of a value. A test in `tests/testthat/test-write-dockerfile.R` runs one lockfile per key with two different values, one that repeats `R` with the same value twice, and one that repeats `Packages.renv.Version` while `R.Version` is `"3.6.0"`. A lockfile that repeats a key the function does not read (a second `cli` entry under `Packages`) still gives a `Dockerfile`, in the same test.
- [x] AC5: The Errors section of `?write_citation` (which `?write_zenodo` inherits) says that a link at the output path is `supplement_error_file_exists` whatever `overwrite` is, except a file link to a missing file on Windows. The Errors section of `?write_dockerfile` says the same for its two targets and lists a repeated key among the `supplement_error_lockfile` cases. In `NEWS.md`, the bullet that starts "`write_citation()` and `write_zenodo()` write" states the link rule, and the bullet that starts "`write_dockerfile()` reads" states the repeated-key rule.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T1
- AC4 → T2, T4
- AC5 → T3

## Tasks

- [x] T1: Write the AC1 test and the AC2 message assertions first, and see the `overwrite = TRUE` cases fail on main. Then change `check_overwrite()` (`R/supplement-yml.R:273`) to take a vector of paths and check links, then folders, then existing files. Make `write_dockerfile()` (`R/write-dockerfile.R:160`) call it once with both targets, and add the `.dockerignore` link plus plain `Dockerfile` case to its link test (line 258). Run `devtools::test()`.
- [x] T2: Write the AC4 test first, then add the repeated-key check to `read_lockfile_versions()` (`R/write-dockerfile.R:190`), at each level before that level's value checks, through `lockfile_error()`. Run `devtools::test()`.
- [x] T3: Update the roxygen Errors sections of `R/write-citation.R` and `R/write-dockerfile.R`, run `devtools::document()`, and edit the two `NEWS.md` bullets (around lines 30 and 80). Update `cairn/DESIGN.md` Architecture (the writers' sentence near line 70 and the `write_dockerfile()` sentence near line 105) and add the writers to the Windows sentence of the "Release edge cases" Known issue. Run `devtools::check()`.
- [x] T4: Review return 1. Move the repeated `cli` case into the AC4 test, and apply the fix-now findings that the `review return 1:` work-log line names. Run `devtools::test()` and `devtools::check()`.

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
- 2026-10-22: review return 1: AC4 fails as written — the repeated `cli` case is its own `test_that()`, not in the same test as the refused lockfiles (diff-bug #1). The fix-now findings ride with it: drop the weaker `file.exists()` checks (diff-bug #6, #7), share `expect_link_message()` through a helper file (diff-bug #9), fix the folder reason in the Errors text (blame-history #4), add the Windows caveat to `check_overwrite()`'s comment (prior-review #1), and fix `cairn/DESIGN.md:235` (diff-bug #11) and the NEWS referent (diff-bug #12). Status back to in-progress.
- 2026-10-22: added T4 for review return 1 (minor amendment); Coverage AC4 → T2, T4.
- 2026-10-22: checkpoint (T4 not checked off): the `cli` case is in the AC4 test (22 expectations, 0 failed), `expect_link_message()` moved to `helper-files.R` and used by both link tests, the weaker `file.exists()` checks dropped, and the wording fixes made; `devtools::document()` rewrote the three Rd files. `devtools::check()` running.
- 2026-10-22: T4 done: `devtools::check()` at 13d5aaf 0 errors, 0 warnings, 0 notes, its test run included. Status set to review.

## Decisions

## Review

Review pass 1, 2026-10-22, at 8db7885 (main not moved since the cut).

- AC1 evidence: `test-write-metadata-errors.R` "a link at the output path is refused, with overwrite TRUE and FALSE" ran 112 expectations (2 writers × 2 `overwrite` values × 4 link shapes × 7), 0 failed, 0 skipped on macOS; it holds `skip_on_os("windows")`. Before the fix (T1 work log) the `overwrite = TRUE` cases raised no error.
- AC2 evidence: the same test asserts "is a link", "Remove the link", and no "overwrite" for both citation writers; the `write_dockerfile()` link test ran 66 expectations, 0 failed, including `expect_link_message()` for all 12 cases and the `.dockerignore` link plus plain `Dockerfile` case with `overwrite = FALSE`, whose message names `.dockerignore`.
- AC3 evidence: that `write_dockerfile()` test passes with `supplement_error_file_exists` and an unchanged folder (`expect_refused()`'s `folder_md5()` check) for both values and three shapes; `git diff main...HEAD` shows its `targets`, files, and `overwrite` loops unchanged, only assertion lines added.
- AC4 evidence: `test-write-dockerfile.R` "a lockfile that repeats a key it reads is refused before its values" ran 21 expectations (7 lockfiles × 3: class, unchanged folder, message names the key), 0 failed, including `R` twice with one value and `Packages.renv.Version` twice with R 3.6.0; "a lockfile that repeats a key it does not read is written" ran 2, 0 failed.
- gate: `cairn_validate.py` all checks passed; `devtools::document()` no diff; no README.Rmd and no `_pkgdown.yml`; NEWS entry present; no new top-level files; no principle changed, so `cairn_impact` skipped. `devtools::check()` at 8db7885 running.
- AC5 evidence: `man/write_citation.Rd:89-92` and `man/write_zenodo.Rd:89-92` state the link rule with the Windows exception; `man/write_dockerfile.Rd:132-134` lists the repeated keys under `supplement_error_lockfile` and line 138 the Windows exception; `NEWS.md:82-86` (bullet "`write_citation()` and `write_zenodo()` write") states the link rule, and `NEWS.md:33-34` (bullet "`write_dockerfile()` reads") the repeated-key rule.
- gate: `devtools::check()` at 8db7885: 0 errors, 0 warnings, 0 notes.
- AC4 tick withdrawn: its evidence line missed that the `cli` case is not in the same test as the criterion says (diff-bug #1).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: AC4 says the repeated `cli` case is "in the same test", but it is its own `test_that()` (`test-write-dockerfile.R:190`) — fix now; AC4 fails as written, so review return 1.
- diff-bug #2: a folder at `.dockerignore` behind a plain `Dockerfile` with `overwrite = FALSE` now says ".dockerignore is a folder" where main said "Dockerfile already exists" — reject (planned change: Scope In orders link, then folder, then existing file).
- diff-bug #3: the link hint says "run this function again" in place of naming `write_dockerfile()`, and differs from the release's link hint — reject (style).
- diff-bug #4: only the first link, folder, or existing file is named, so two broken targets take two runs — reject (edge: two broken targets at once is outside documented and common use; the effect is a second error).
- diff-bug #5: no Windows test of the new behavior; the link tests skip Windows — follow-up, new candidate row "Test the link refusals on Windows".
- diff-bug #6: `expect_false(file.exists(outside/missing))` is a weaker check after `folder_md5(outside)` (`test-write-metadata-errors.R:398`) — fix now.
- diff-bug #7: `expect_true(file.exists(Dockerfile))` is covered by the `read_text()` match after it (`test-write-dockerfile.R:196`) — fix now.
- diff-bug #8: "R, the same value twice" runs the same path as "R" — reject (planned change: AC4 names the case).
- diff-bug #9: the 16 link cases run one `is_link()` branch, and the message checks are inline rather than through `expect_link_message()` — the case count is rejected (planned change: AC1 names the shapes); the helper reuse is fix now (move it to a helper file).
- diff-bug #10: the comment "The link at .dockerignore comes before the plain Dockerfile" restates the setup — reject (false: it states the order the case tests, which the setup does not show).
- diff-bug #11: `cairn/DESIGN.md:235` credits the Windows `is_link()` gap for `write_dockerfile()` to M035, though M032 had it — fix now.
- diff-bug #12: "or its `Version`" in `NEWS.md:33-35` has an unclear referent, and the bullet leaves a short line — fix now.
- diff-bug #13: a long line at `R/write-dockerfile.R:226` — reject (style).
- blame-history #1: the citation writers now refuse a link with `overwrite = TRUE`, reversing M005's write-through — reject (planned change, chosen at the question set; the package is unreleased).
- blame-history #2: on Windows a file link to a missing file still says "Use overwrite = TRUE", and with TRUE writes through it; predates the branch — follow-up, same new row "Test the link refusals on Windows".
- blame-history #3: the `write_dockerfile()` hint lost its function name — reject (style; same as diff-bug #3).
- blame-history #4: "A folder or a link ... because a write would follow the link" gives a reason that fits only links (`R/write-citation.R:76-78`, and the same sentence in `R/write-dockerfile.R`) — fix now.
- blame-history #5: links at both targets are checked before folders and files, and a folder link now says "is a link" — reject (planned change, tested).
- prior-review #1: `check_overwrite()`'s comment says a link is refused whatever `overwrite` is, with no Windows caveat, while the help pages carry one (`R/supplement-yml.R:276`) — fix now.
- prior-review #2: the link tests skip Windows, though M022 practice makes folder links there with `Sys.junction()` — follow-up, same new row.
- ripple #1: `cairn/ROADMAP.md:39` still says the citation writers write through a link — reject (planned change: the row graduates at post-merge hygiene).
- ripple #2: `cairn/ROADMAP.md:40` still says `write_dockerfile()` takes the first repeated key — reject (planned change: the row graduates at post-merge hygiene).
- ripple #3: `inst/template/_README.md:159` says to use `overwrite = TRUE` to write the citation files again — reject (false: that holds for a regular file, and a link now gets a message saying to remove it).
- ripple #4: `inst/template/_README.md:400` and `:416` say to use `overwrite = TRUE` to replace the recipe — reject (false, as ripple #3).
- ripple #5: `inst/template/_README.md:362` lists the lockfile's version needs and not the repeated-key refusal — reject (false: no line disagrees; the help page lists every error).
- fixed 13d5aaf: diff-bug #1, #6, #7, #9 (helper reuse), #11, #12; blame-history #4; prior-review #1.

Review pass 2, 2026-10-22, at 71eeeb3 (main not moved).

- AC1 evidence (pass 2): the link test ran 96 expectations (16 cases × 6, the `file.exists()` check dropped as weaker than `folder_md5(outside)`), 0 failed, 0 skipped; it still skips on Windows.
- AC2 evidence (pass 2): both link tests assert the message through the shared `expect_link_message()` in `helper-files.R`; the `write_dockerfile()` link test ran 66 expectations, 0 failed, with the `.dockerignore` link plus plain `Dockerfile` case.
- AC3 evidence (pass 2): the `write_dockerfile()` link test passes with unchanged inputs, as in pass 1.
- AC4 evidence (pass 2): "a lockfile that repeats a key it reads is refused before its values, and one it does not read is not" ran 22 expectations, 0 failed: 7 refused lockfiles × 3, and the repeated `cli` case in the same `test_that()` writing a `Dockerfile` from R 4.6.1.
- AC5 evidence (pass 2): `man/write_citation.Rd`, `man/write_zenodo.Rd`, and `man/write_dockerfile.Rd` keep the link rule with the Windows exception and the repeated-key list; `NEWS.md` bullets "`write_dockerfile()` reads" (now naming `Packages.renv.Version`) and "`write_citation()` and `write_zenodo()` write" state the two rules.
- gate (pass 2): `cairn_validate.py` all checks passed; `devtools::document()` no diff; `devtools::check()` at 13d5aaf 0 errors, 0 warnings, 0 notes (71eeeb3 changes only `cairn/`).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: on Windows a file link to a missing file gets the "Use `overwrite = TRUE`" hint, and following it writes through the link — follow-up, absorbed by the row "Test the link refusals on Windows", which states it.
- diff-bug #2: the link hint says "run this function again" though `write_dockerfile()` used to name itself — fix now (`check_overwrite()` takes `fn`; `expect_link_message()` asserts the name).
- diff-bug #3: only the first link or folder is named — reject (edge, as pass 1 diff-bug #4).
- diff-bug #4: a folder link at `CITATION.cff` now says "is a link", and NEWS does not say so — reject (planned change; the Errors text covers it, and the package is unreleased).
- diff-bug #5: `expect_link_message()` runs for every link shape, all through one `is_link()` branch — reject (false: on main the shapes reached different messages, so the per-shape check pins what the change altered).
- diff-bug #6: keep the `.dockerignore` name match in the last link case — noted (requests nothing).
- diff-bug #7: the comment on that case restates the setup — fix now (it now says links at both targets are checked before any existing file).
- diff-bug #8: AC4 tests the order only against the R < 4.0.0 check — reject (planned change: AC4 names the cases).
- diff-bug #9: the Windows sentence added to the "Release edge cases" Known issue is hard to read — fix now.
- diff-bug #10: a wide line in `cairn/DESIGN.md:101-102` — reject (style).
- diff-bug #11: NEWS lists `R.Version` as a dotted path where `?write_dockerfile` says `Version` in `R` — reject (style).
- diff-bug #12: cli can wrap a long path so a message line is empty; predates the branch — reject (style).
- blame-history #1: `cairn/DESIGN.md:71-73` states the link refusal with no Windows caveat — fix now.
- blame-history #2: the citation writers now refuse a link with `overwrite = TRUE` — reject (planned change).
- blame-history #3: the hint lost its function name, which M032's review had made specific — fix now (same as diff-bug #2).
- blame-history #4: links at both targets are checked before folders — reject (planned change, tested).
- prior-review #1: Windows still writes through a missing-target file link with `overwrite = TRUE` (M018 review) — follow-up, absorbed by "Test the link refusals on Windows".
- prior-review #2: the link tests skip Windows, though `Sys.junction()` could run the folder cases (M022) — follow-up, same row.
- prior-review #3: the hint wording M032 fixed is changed — fix now (same as diff-bug #2).
- prior-review #4: the new check order — reject (planned change).
- ripple: no ripple evidence.
