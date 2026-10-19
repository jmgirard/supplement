# M015: The release commands stage and commit only the site folder

**Status:** done (2026-10-19, PR #16 https://github.com/jmgirard/supplement/pull/16)

**Goal:** For a site in a subfolder of its git repository, the commands that `release_supplement()` prints make a release commit that holds only files under the site folder, the files that `check_supplement()` checked.

**Outcome:** `release_commands()` in `R/release-supplement.R` prints `git status -- .`, `git add -A -- .`, and `git commit -m "Release vX.Y.Z" -- .`; tag, push, and `gh release create` are unchanged. `report_release()` says `git add` and `git commit` cover only the site folder. A file staged outside the site before the release stays staged and out of the commit. `tests/testthat/test-release-supplement.R` runs the returned add and commit (split with `scan()`, run through `git_in()`) in a real repository, with the site in `site/` and at the top. `git_in()` in `helper-template.R` now unsets `GIT_DIR`, `GIT_WORK_TREE`, and `GIT_INDEX_FILE`. The help page, `README.md`, the template's `_README.md`, NEWS.md, and DESIGN.md describe the commands.

**Decisions:** none promoted. The plan question set chose the site-folder pathspec over checking the whole repository; `git commit -- .` was added so that a file staged outside the site is left out.

**Review:** full criteria audit at plan (11 findings over M015 to M017, all taken narrower); claim audit 19 claims, 2 corrected. One review pass, four lenses: 18 findings, 9 fixed (docs wording, staged-file note, test git setup, test checks), 4 to the new row "release pathspec edge cases", 4 rejected (planned change or false), 1 noted (row "release during a merge"). No amendments. `R CMD check` 0/0/0. Graduated "release from a subfolder".
