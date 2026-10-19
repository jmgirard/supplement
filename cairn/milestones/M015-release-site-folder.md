# M015: The release commands stage and commit only the site folder

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes the commands that `release_supplement()` prints and its help page
- **Branch/PR:** m015-release-site-folder

## Goal

For a site in a subfolder of its git repository, the commands that `release_supplement()` prints make a release commit that holds only files under the site folder, the files that `check_supplement()` checked.

## Scope

**In:** the `git status`, `git add`, and `git commit` commands in `release_commands()` (`R/release-supplement.R:474`) limited to the site folder with the pathspec `-- .`; the printed message in `report_release()`; the help page of `release_supplement()`; the release section of `README.md` and of the template's `_README.md`; a NEWS.md entry; DESIGN.md's architecture line for the release.

**Out:** checking the whole repository from its top (the plan gate chose the site folder instead) → not planned. The other release edge cases → candidate rows "release edge cases", "release snapshot remainder", and "release write order remainder". A partial commit during a merge in progress (`git commit -- .` refuses it) → new candidate row "release during a merge".

## Acceptance criteria

- [x] AC1: For version `X.Y.Z`, `release_supplement()` returns these commands, in this order: `git status -- .`, `git add -A -- .`, `git commit -m "Release vX.Y.Z" -- .`, `git tag vX.Y.Z`, `git push`, `git push origin vX.Y.Z`, `gh release create vX.Y.Z --generate-notes`. A test in `tests/testthat/test-release-supplement.R` compares the returned vector with this list for one version.
- [x] AC2: A test makes a git repository whose site folder is the subfolder `site/`, with three changes outside the site: a new file that git does not track, a changed tracked file, and a new file staged with `git add` before the release. It runs `release_supplement()` in `site/` (with `check_supplement()` mocked to find no problem), then runs the returned `git add` and `git commit` commands in `site/`. The test passes when every path that the new commit changes (`git diff-tree --root --no-commit-id --name-only -r HEAD`) starts with `site/`, `site/CITATION.cff` and `site/_supplement.yml` are among them, and `git status --porcelain` still lists the three outside changes. The test skips when git is not on the PATH.
- [x] AC3: The test of AC2 has a second case, with the site folder at the top of the repository, in which the commit (read with the same `git diff-tree --root` command) holds `CITATION.cff`, `_supplement.yml`, and a file in `docs/` that was new before the release.
- [x] AC4: `grep -n "git add -A" R/release-supplement.R man/release_supplement.Rd README.md inst/template/_README.md` finds only the form `git add -A -- .`, and each of these four files says that the printed commands stage and commit only files under the site folder. NEWS.md has an entry that says the same.
- [x] AC5: `Rscript -e 'devtools::document()'` leaves no diff, and `Rscript -e 'devtools::test()'` reports no failure.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T2, T3

## Tasks

- [x] T1: Write the tests of AC1 to AC3 in `tests/testthat/test-release-supplement.R` (use `skip_if_no_git()` from `helper-template.R`; set a repo-local `user.name` and `user.email`, because the test helpers blank the global git configuration). See the AC1 and AC2 tests fail against the current `git add -A` and `git commit` lines. The AC3 case passes before the change too, as a guard that the top-of-repository release keeps working.
- [x] T2: Change `release_commands()` and the `report_release()` message (`R/release-supplement.R:473-492`), and run the tests to green with git on the PATH, so that no test of AC2 or AC3 skips.
- [x] T3: Update the roxygen block of `release_supplement()` (`R/release-supplement.R:61-68`), `README.md:149-161`, `inst/template/_README.md:179-181`, DESIGN.md, and NEWS.md; run `devtools::document()`, then the AC4 grep.

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: not run — work named at the question set.
- 2026-10-19: question set: what to plan — release from subfolder, YAML parse errors, paper figure files; how the subfolder fix works — stage the site folder only.
- 2026-10-19: absorbed candidate row "release from a subfolder" in full.
- 2026-10-19: plan gate chose `-- .` pathspecs on `git add` and `git commit` over checking the whole repository, at the user's answer; falsified by a release whose needed files live outside the site folder.
- 2026-10-19: plan chose `git commit -- .` as well as `git add -A -- .` over `git add` alone, because a file staged outside the site before the release would otherwise reach the commit; falsified by a git version where a pathspec commit leaves out a newly added file.
- 2026-10-19: inbox sweep: 0 open issues, 0 open PRs. Collision sweep: no D-entry, archive, or planned overlap.
- 2026-10-19: lessons harvested: M010 (prove a test can fail against main's file), M011 (write test edits with `writeBin()`).
- 2026-10-19: criteria audit (full mode, fresh Opus reader, shared with M016 and M017): confirmed `git add -A -- .` then `git commit -- .` in a subfolder commits new, changed, and deleted site files and leaves outside staged, changed, and untracked files. Findings taken: AC2 and AC3 read the commit with `git diff-tree --root` (without `--root` a first commit lists nothing); AC2's staged file is a new file; AC3 passes before the change, so T1 keeps it as a guard; AC4 greps four named files and moves NEWS.md to its own clause; T1 sets a repo-local git user; T2 and T3 line numbers fixed; T2 runs with git present so no test skips.
- 2026-10-19: started on branch m015-release-site-folder; status in-progress.
- 2026-10-19: T1 done: `expected_commands()` holds the new forms; two tests run the returned `git add` and `git commit` (split with `scan()`, run through `git_in()`) in a new repository. Before the change the subfolder test failed 2 expectations (outside paths in the commit, `staged.txt` no longer listed as staged) and the top-of-repository test passed, as planned.
- 2026-10-19: T2 done: `release_commands()` adds `-- .` to `git status`, `git add -A`, and `git commit`; the `report_release()` line now says the commands stage and commit only the files in the site folder. `test-release-supplement.R` passes with no skip.
- 2026-10-19: T3 done: roxygen, `man/release_supplement.Rd`, `README.md`, `inst/template/_README.md`, NEWS.md (the unreleased `release_supplement()` entry, edited in place), and DESIGN.md describe the `-- .` commands; the AC4 grep finds only `git add -A -- .`. `devtools::test()`: 239 tests, 0 failed, 1 skipped (the case-sensitive-disk test in `test-add-data.R`, which skips on macOS).
- 2026-10-19: claim audit: 19 claims read, 2 corrected — README.md, inst/template/_README.md ("the files the git checks of `check_supplement()` read"), R/release-supplement.R and its Rd (`docs/` and `_freeze/` reach the release when git does not ignore them). Its merge-in-progress note is the existing row "release during a merge".
- 2026-10-19: all tasks done; `test-release-supplement.R` 43 tests, 0 failed, 0 skipped after the corrections; status review.

## Decisions

## Review

- AC1: `test-release-supplement.R` "the release commands are printed and returned" (11 expectations) and the bump test (20) compare the returned vector with the hand-written `expected_commands()`, which lists `git status -- .`, `git add -A -- .`, `git commit -m "Release vX.Y.Z" -- .`, then tag, push, push tag, `gh release create`; 0 failed. `release_commands("2.3.4")` printed those seven lines.
- AC2: "for a site in a subfolder, the release commit holds only files of the site" ran with git present: 12 expectations, 0 failed, not skipped. It checks every `git diff-tree --root` path starts with `site/`, `site/CITATION.cff` and `site/_supplement.yml` are committed, and `git status --porcelain` still shows ` M tracked.txt`, `?? untracked.txt`, `A  staged.txt`. With `R/release-supplement.R` copied from main, the same test failed 2 expectations; restored, tree clean.
- AC3: "for a site at the top of the repository, the release commit holds its new files" ran with git present: 9 expectations, 0 failed, not skipped; it checks `CITATION.cff`, `_supplement.yml`, and the new `docs/index.html` in the `git diff-tree --root` list. It also passed with main's code, as planned (a guard).
- AC4: `grep -n "git add -A"` over the four named files gives 5 hits, all `git add -A -- .` (R:62, R:483, Rd:80, README.md:150, _README.md:179). Each file says the commands stage and commit only files under the site folder: R:65 (roxygen) and R:496 (message), Rd:83, README.md:159, _README.md:180. NEWS.md:48 says the same.
- AC5: `devtools::document()` left `git status` clean. `devtools::test()`: 239 tests, 0 failed, 1 skipped (the case-sensitive-disk test in `test-add-data.R`, which skips on macOS), 0 errors.
- Gate: `cairn_validate.py` all checks passed. `devtools::check()` 0 errors, 0 warnings, 0 notes. `document()` no diff. No README.Rmd and no `_pkgdown.yml`, so those checks do not apply. NEWS.md has the entry. No new top-level file. No DESIGN principle changed, so `cairn_impact` skipped.
