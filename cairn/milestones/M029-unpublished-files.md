# M029: check_supplement() finds site files that git ignores or a render missed

- **Status:** review
- **Priority:** normal
- **Depends on:** M028
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — an exported check whose rows stop `release_supplement()`
- **Branch/PR:** m029-unpublished-files

## Goal

`check_supplement()` gives a row for each published site file that git ignores, and for each paper figure that the last render did not copy into `docs/`.

## Scope

**In:** two new checks in `R/check-supplement.R`, `"ignored-output"` and `"unpublished-figure"`, called from `check_supplement()`. The milestone also adds tests, help text, the check list in `inst/template/_README.md`, and a NEWS.md change.

**Out:** files outside `figures/`, `docs/`, and `_freeze/` give no `ignored-output` row. A file in `docs/figures/` with no source in `figures/` gives no row, because a full render removes it. A name whose Unicode form differs between the disk and git's index is not handled; T1 probes it, and if it gives false rows, the help page says so. Setup does not edit an author's ignore rules (question set).

## Acceptance criteria

- [x] AC1: The ignored rule: take each regular file under `figures/`, `docs/`, or `_freeze/` of the site that is reached without passing through a symbolic link or junction and whose path holds no name that starts with `.`. If git neither tracks it nor lists it as untracked, because its ignore rules exclude it, `check_supplement()` gives one `ignored-output` row for it. The tests in `tests/testthat/test-check-supplement.R` use a site in a git repository. A `.gitignore` that adds `*.png` gives a row for a PNG directly in each of the three folders and for a PNG in a folder inside `docs/` and inside `_freeze/`. It gives no row for an ignored PNG in `analyses/` or for `figures/.DS_Store`. The same rule in `.git/info/exclude` gives the same rows. A site in a subfolder of its repository gives rows whose paths start at the site. A `figures/` rule gives a row for each file in `figures/`. A tracked folder link in `figures/` gives no row for the files in its target. A `data/x.rds` that the template's rule ignores gives a row for its copy `docs/data/x.rds`. A file that git tracks and that an ignore rule matches gives no row.
- [x] AC2: In three cases the `ignored-output` check does not run: git is not on the PATH, a git command fails, or the folder is not in a git work tree. The `skipped` attribute and the printed skip message then name it with `"large-file"` and `"saved-object"`. The tests cover the three cases that the current git-check tests cover.
- [x] AC3: The unpublished rule: take each regular file in `figures/` or a folder in it that is reached without passing through a symbolic link or junction and whose path holds no name that starts with `.`. If the same path under `docs/figures/` is not a regular file, or its MD5 differs, `check_supplement()` gives one `unpublished-figure` row for it. The tests give a row for: a figure saved under a new name after a render, `figures/sub/x.png` with no copy in `docs/`, a figure whose bytes changed with no render, and a figure whose path under `docs/figures/` is a folder. A later full render clears the first row, and so does a render of the report by name. These give no row and no error: a site with no `figures/` folder, a file named `figures`, a hidden file in `figures/`, and a site rendered after its last figure change.
- [x] AC4: `release_supplement()` stops with `supplement_error_release_check` and changes no file in a site whose only problem is an `ignored-output` row, and in one whose only problem is an `unpublished-figure` row. A test in `tests/testthat/test-release-supplement.R` runs the real `check_supplement()`, not a mock, on each site.
- [x] AC5: The help page of `check_supplement()` has an item for each check that states the rule of AC1 or AC3. The `"unpublished-figure"` item says that hidden files are not compared, though Quarto copies them. The help text on git checks names `ignored-output` with the two other git checks. The `ignored-output` problem text tells the author to change the ignore rule, and the `unpublished-figure` text tells the author to render again. NEWS.md and the check list in `inst/template/_README.md` (line 139) name both checks.
- [ ] AC6: A site made by `create_supplement()` and rendered once in a git repository, with the template's `.gitignore`, gives no row from either check. `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3
- AC3 → T1, T2, T4
- AC4 → T2, T3, T4
- AC5 → T5
- AC6 → T2, T6

## Tasks

- [x] T1: Probe in a scratch site: how `list.files(recursive = TRUE)` and `git ls-files` list a folder link and a file link in `figures/`; a name with `é` in two Unicode forms on macOS (`core.precomposeunicode`); and whether a render by name copies a figure that is new at the start of the render. Record each result in the work log. The help text and Out follow what the probes show (the derived-claims rule).
- [x] T2: Add the AC1 to AC4 and AC6 tests. Write fixture bytes with `writeBin()` (LESSONS M011). Run each row case against main and record that each fails there (LESSONS M010). Recheck the tests that match whole row sets in `test-check-supplement.R` and the full-render tests in `test-add-render.R`, which may now give rows.
- [x] T3: Write the `ignored-output` check from git's list of ignored files (`git ls-files --others --ignored --exclude-standard`), read in `git_files()` (`R/check-supplement.R:256`), with paths relative to the site. Keep the files in the three folders whose path holds no hidden name and no link, tested with `is_link()`. Add the check to the `skipped` attribute and to the skip message in `report_problems()` (line 205).
- [x] T4: Write the `unpublished-figure` check with `tools::md5sum()` (LESSONS M027) and the same link-free walk. Add both calls to `check_supplement()` (line 186).
- [x] T5: Add the roxygen items and run `devtools::document()`. Edit the existing NEWS.md bullet for `check_supplement()`. Add two lines to the check list in `inst/template/_README.md`.
- [x] T6: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: what to work on — the candidate row "Fix edge cases of the figures folder", planned as M028 (template) and M029 (check rows).
- 2026-10-20: question set: ignore rules that keep site files out of git — report them with an `ignored-output` row over `figures/`, `docs/`, and `_freeze/`. A data file that `.gitignore` blocks also gets a row for its copy in `docs/data/`.
- 2026-10-20: question set: figures that a render did not publish — an `unpublished-figure` row, with M028 shipping the example figure.
- 2026-10-20: absorbed part of the candidate row "Fix edge cases of the figures folder"; M028 holds the rest. An uncommitted but not ignored `figures/` needs no row, because `release_supplement()` prints `git add -A -- .`.
- 2026-10-20: plan gate chose a check row over setup rules that put `figures/` back in git, because appended rules can undo rules the author wrote on purpose and do not cover `docs/`; falsified by authors who need setup to fix the rules with no release step.
- 2026-10-20: depends on M028, because without the shipped figure a new site's first render gives an `unpublished-figure` row and AC6 fails.
- 2026-10-20: collision check: M008 shipped the git listing that this reuses, and M022 shipped the link-free walk of `docs/`. No D-entry overlaps.
- 2026-10-20: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-20: lessons surfaced: M008 (list folders, not globs), M011 (`writeBin()` fixtures), M010 (prove a test fails on main), M018 and M022 (links and junctions on Windows), M027 (`tools::md5sum()` needs no Imports entry).
- 2026-10-20: changelog: the existing 0.0.0.9000 bullet for `check_supplement()` gets the change, with no new bullet.
- 2026-10-20: criteria audit (full mode, fresh Opus reader): 10 findings over M028 and M029, all taken. For M029: AC1 no longer enters links, which `list.files()` follows, states git's view in place of the checker's own listing, and adds cases for `.git/info/exclude`, a site in a subfolder, nested files, and `docs/data/`. AC3 adds nested, file-named-`figures`, and folder-in-`docs/` cases and says hidden files are not compared. AC5 names its claims. The Unicode-form case went to T1 and Out. AC2 and AC4 had no finding.
- 2026-10-20: started; branch m029-unpublished-files cut from main at fb80252.
- 2026-10-20: T1 probe (macOS, git 2.54): `list.files(recursive = TRUE)` enters a folder link (`figures/dirlink/t.png`) and lists a file link and a broken link by name; `git ls-files --others` lists each link as one entry and never enters a folder link.
- 2026-10-20: T1 probe: `git init` on macOS sets `core.precomposeunicode=true`, and git then lists a file stored as NFD `café2.png` in NFC form while `list.files()` gives the NFD bytes, so a set difference of the disk walk and git's list gives a false row. `file.exists()` and `tools::md5sum()` on the NFC path find the NFD file on APFS.
- 2026-10-20: T1 probe: `git ls-files -z --others --ignored --exclude-standard -- figures docs _freeze` lists each file inside an ignored folder, lists links, hidden files, and folder links as entries, leaves out a tracked file that a rule matches, and prints paths relative to the folder it runs in.
- 2026-10-20: T1 probe: with Quarto 1.10.19, a render by name of `analyses/example.qmd` or of `index.qmd` copies a figure that is new in `figures/` at the start of the render (`figures/sub/x.png` too); after a full render and after a render by name, `figures/bootstrap-means.png` and its copy in `docs/figures/` have the same MD5.
- 2026-10-20: minor amendment: T3 reads git's list of ignored files in place of a set difference with a disk walk, because of the Unicode-form probe. With it a name stored as NFD gives no false row, so the help page needs no note on Unicode forms (Out's condition did not fire).
- 2026-10-20: T2: tests added for AC1 to AC4 and AC6 in test-check-supplement.R, test-release-supplement.R (new helper `checked_site()`, used by the stale-output release test too), and test-add-render.R; the skip test now expects `ignored-output` in `skipped` and the message. Against main's R code, 10 tests fail: each row case, the skip test, the AC6 site test, the render test, and the release test; the no-figures-folder test passes there, as a no-row test does. Committed failing, before T3 and T4.
- 2026-10-20: T3: `git_files()` runs a second `git ls-files -z --others --ignored --exclude-standard -- figures docs _freeze` and returns `ignored`; `check_ignored_output()` keeps the paths under the three folders with no hidden name and no link on their path (`plain_paths()`), in byte order. `git_checks` names the three git checks for `skipped` and the skip message. Choice: a failure of the second `ls-files` gives the same "`git ls-files` failed" reason and skips all three checks.
- 2026-10-20: T4: `check_unpublished_figures()` walks `figures/` with `plain_files()` (no hidden names, no links) and compares `tools::md5sum()` with `docs/figures/`; a `figures` that is a link gives no row. Rows come after the link rows. Planted defects: dropping the link filter fails "an ignored file link in figures gives no ignored-output row", and a walk that enters links fails "a folder link in figures gives no row for the files in its target".
- 2026-10-20: T5 probe: a render of `index.qmd` by name copied `figures/.hidden.png` to `docs/figures/` (Quarto 1.10.19), the help page's "Quarto copies them too".
- 2026-10-20: checkpoint: T3 to T5 code, help, NEWS, and README written; the three changed test files pass (97 tests); the full suite is running, so T3 to T5 stay unticked.
- 2026-10-20: full `devtools::test()` at b3e757f's code: 299 tests, 0 failing, 7 skipped; T3 to T5 ticked.
- 2026-10-20: claim audit: 38 claims read, 2 corrected — R/check-supplement.R, man/check_supplement.Rd (the `docs/data/` copy holds only for a rule with no `/`; the Unicode comment now names core.precomposeUnicode). The same reader re-read both corrections and found they hold.
- 2026-10-20: T6: `devtools::check()` at b3e757f's code (before the claim-audit wording fix, which changed only help text and a comment): 0 errors, 0 warnings, 0 notes. The R-CMD-check workflow runs at the PR. Status set to review.

## Decisions

## Review

- 2026-10-20: route (d): no PR for the branch; main at fb80252 has not moved since the cut. Copilot round off (no header line in PROFILE.md).
- Fresh evidence at d3e306b: `devtools::test()` 299 tests, 0 failing, 7 skipped. The `devtools::check()` run after it was stopped by the harness before it printed; it reruns after the fixes below.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: the `ignored-output` text says to change the ignore rule, which for a private copy in `docs/data/` (a `private/` folder or an `.rds`) leads to publishing it or to a `saved-object` row — fix now (text now names both cases; not a floor return: no criterion fails, AC5's instruction stays, and the rows were right)
- diff-bug #2: `strsplit()` in `plain_paths()` warns on a name that is not valid UTF-8 and loses the link filter for it — fix now
- diff-bug #3: files of an ignored nested git repository in `docs/` get no row — follow-up ("Close edge cases of the figure checks")
- diff-bug #4: on macOS a figure whose name differs from its copy only in letter case gives no row — follow-up (same row)
- diff-bug #5: an unreadable figure gets the "missing or differs" text, and an unreadable folder in `figures/` gives no row — follow-up (same row)
- diff-bug #6: on Windows a file link to a missing file can get an `ignored-output` row — follow-up (same row)
- diff-bug #7: `release_supplement()` help says its files are those "the git checks" read — fix now
- diff-bug #8: the help names only rules with no `/` for the `docs/data/` copy — fix now (reworded as "a rule that also matches the copy")
- diff-bug #9: no test of a failed second `git ls-files` — fix now
- diff-bug #10: the folder-on-the-path part of `plain_paths()` is untested off Windows — fix now (mocked listing under a folder link)
- diff-bug #11: the `!is_link(copies)` term is untested — fix now
- diff-bug #12: a `docs/figures` that links to a folder inside `docs/` gives no row — follow-up (same row)
- diff-bug #13: `sort_bytes()` repeats two inline sorts, and `plain_files()` sits beside `docs_entries()` — fix now for the sorts; reject for the walk (false: `docs_entries()` lists hidden names and links, a different contract)
- diff-bug #14: a site that ignores all of `docs/` prints one row per file — follow-up (same row)
- blame-history #1: an `.rds` data file goes from `ignored-output` to `saved-object` and back — fix now (same text fix as diff-bug #1, and the template README data paragraph now says to remove the file from `data/`)
- blame-history #2: non-UTF-8 names unguarded and untested — fix now (same as diff-bug #2, with a mocked test)
- blame-history #3: DESIGN.md names only the first git listing — fix now
- blame-history #4: AC2 names only two checks — reject (false: AC2 says the skip names `ignored-output` "with" the two, as the code does)
- blame-history #5: release test lists of check names lack the new ones — fix now
- blame-history #6: release docs sentence on files the git checks read — fix now (same as diff-bug #7)
- blame-history #7: duplicated byte-sort idiom — fix now (same as diff-bug #13)
- blame-history #8: a short line in the NEWS bullet — reject (style)
- blame-history #9: a linked `docs/figures` is read through — follow-up (same row)
- prior-review #1: a silent Windows `if` around `git add` in the folder-link test, a pattern M023 review fixed — fix now (the `if` is gone)
- prior-review #2: non-UTF-8 names untested in the new checks — fix now
- prior-review #3: byte order of rows never observed by a test — fix now (test under en_US.UTF-8 collation, skipped where that locale is missing)
- prior-review #4: junction help backed only by the POSIX path — fix now (with #1, the Windows job runs the same test)
- prior-review #5: link handling differs between the two checks — follow-up (same row)
- prior-review #6: AC2 wording stale — reject (false, as blame-history #4)
- prior-review #7: test comment says the template ignores `analyses/*.png` — reject (false: `_gitignore` has `analyses/*.[Pp][Nn][Gg]`)
- prior-review #8: "Quarto copies them too" rests on a work-log probe — fix now (the render test now checks `docs/figures/.hidden.png`)
- prior-review #9: NEWS line wrap — reject (style)
- ripple #1: README.md says "those two checks" — fix now
- ripple #2: README.md check list lacks the two rows — fix now
- ripple #3: "These are the files that the git checks of check_supplement() read" in README.md, the template README, and the release help — fix now
- ripple #4: the ROADMAP row "Fix edge cases of the figures folder" still says the cases go unreported — follow-up (hygiene narrows the row at merge)
- ripple #5: DESIGN.md git listing — fix now (same as blame-history #3)
- ripple #6: DESIGN.md "the files check_supplement() checked" — fix now
- ripple #7: `git_files()` header comment omits `ignored` — fix now
- ripple #8: release code comment "the files that check_supplement() checked" — fix now
- ripple #9: the Windows odd-named folders row — reject (false: the reviewer found no disagreement)
- ripple #10: `example.qmd` figure comment — reject (false: no disagreement)
- Planted defects for the fix-now tests: a split without `useBytes` that tests only the last part fails the non-UTF-8 and linked-folder tests; a locale sort fails the byte-order test; dropping `!is_link(copies)` fails the docs/figures link test.
- Fresh evidence at cb2a1ad (after the fixes): `devtools::test()` 304 tests, 0 failing, 7 skipped (the 7 predate this branch); `devtools::check()` 0 errors, 0 warnings, 0 notes.
- AC1 evidence: in test-check-supplement.R these pass at cb2a1ad: "a *.png rule gives an ignored-output row for each PNG in the published folders" (7 expectations: rows for PNGs directly in the three folders and nested in docs/ and _freeze/, none for analyses/f.png or figures/.DS_Store; the same rows from .git/info/exclude and from a site in a subfolder); "a figures/ rule …" (each file in figures/); "a folder link in figures …" (tracked link, no row for its target); "a data file that the template ignores …" (row for docs/data/x.rds, none once tracked). Before the branch's code these failed (T2 work-log line).
- AC2 evidence: "the git checks are skipped when git cannot run" passes at cb2a1ad (30 expectations): for git not on the PATH, a failed `git --version`, and a failed or false `git rev-parse`, `skipped` is `large-file`, `saved-object`, `ignored-output` and the message names each. "a failed listing of ignored files skips the three git checks" also passes.
- AC3 evidence: at cb2a1ad, "a figure with no equal copy in docs/figures gives an unpublished-figure row" passes (rows for figures/new.png, figures/sub/x.png, changed bytes of bootstrap-means.png, and figures/z.png with a folder at its docs/figures/ path; none for hidden files); test-add-render.R "a render by name or a full render clears the unpublished-figure row of a new figure" passes (9 expectations: no row after a render, a row for a new figure, cleared by a render of analyses/example.qmd and by a full render); "a site with no figures folder, or a file named figures, …" passes with no error and no row.
- AC4 evidence: test-release-supplement.R "an ignored-output or an unpublished-figure row from the real check stops the release" passes at cb2a1ad (12 expectations): on `checked_site()`, with no mock, the check gives zero rows, then exactly the one planted row; `release_supplement()` stops with `supplement_error_release_check` and `folder_state()` is unchanged, for each of the two checks.
- AC5 evidence (read at cb2a1ad): man/check_supplement.Rd line 33 has the `"ignored-output"` item, which states AC1's rule (regular files in the three folders, no link or junction on the path, no hidden name, not tracked and not listed as untracked because the ignore rules exclude it); line 162 has the `"unpublished-figure"` item, which states AC3's rule and says hidden files are not compared, though Quarto copies them (backed by the render test's `.hidden.png` check). Lines 187-189 name `"ignored-output"` with the two other git checks. The problem texts (R/check-supplement.R:401, :965) say to change the ignore rule, and to render the site again. NEWS.md lines 38-41 and inst/template/_README.md lines 145 and 158 name both checks. `devtools::document()` gives no diff.
- AC6 evidence, local part: "a rendered site in a git repository has no problems" passes at cb2a1ad (13 expectations: a site from `create_supplement()`, rendered once, in a git repository with the template's `.gitignore`, gives zero rows; planted `figures/new.png` and `docs/data/x.rds` then give the two new rows). `devtools::test()` 0 failures and `devtools::check()` 0 errors, 0 warnings at cb2a1ad. The R-CMD-check workflow on Windows, macOS, and Ubuntu runs at the PR, so the AC6 box waits for it.
- Consistency gate at cb2a1ad: `cairn_validate.py` all checks passed; `devtools::document()` no diff; no README.Rmd and no `_pkgdown.yml`, so those checks do not apply; NEWS.md has the entry; no new top-level file; `devtools::check()` 0 errors, 0 warnings, 0 notes.
