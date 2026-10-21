# M029: check_supplement() finds site files that git ignores or a render missed

- **Status:** in-progress
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

- [ ] AC1: The ignored rule: take each regular file under `figures/`, `docs/`, or `_freeze/` of the site that is reached without passing through a symbolic link or junction and whose path holds no name that starts with `.`. If git neither tracks it nor lists it as untracked, because its ignore rules exclude it, `check_supplement()` gives one `ignored-output` row for it. The tests in `tests/testthat/test-check-supplement.R` use a site in a git repository. A `.gitignore` that adds `*.png` gives a row for a PNG directly in each of the three folders and for a PNG in a folder inside `docs/` and inside `_freeze/`. It gives no row for an ignored PNG in `analyses/` or for `figures/.DS_Store`. The same rule in `.git/info/exclude` gives the same rows. A site in a subfolder of its repository gives rows whose paths start at the site. A `figures/` rule gives a row for each file in `figures/`. A tracked folder link in `figures/` gives no row for the files in its target. A `data/x.rds` that the template's rule ignores gives a row for its copy `docs/data/x.rds`. A file that git tracks and that an ignore rule matches gives no row.
- [ ] AC2: In three cases the `ignored-output` check does not run: git is not on the PATH, a git command fails, or the folder is not in a git work tree. The `skipped` attribute and the printed skip message then name it with `"large-file"` and `"saved-object"`. The tests cover the three cases that the current git-check tests cover.
- [ ] AC3: The unpublished rule: take each regular file in `figures/` or a folder in it that is reached without passing through a symbolic link or junction and whose path holds no name that starts with `.`. If the same path under `docs/figures/` is not a regular file, or its MD5 differs, `check_supplement()` gives one `unpublished-figure` row for it. The tests give a row for: a figure saved under a new name after a render, `figures/sub/x.png` with no copy in `docs/`, a figure whose bytes changed with no render, and a figure whose path under `docs/figures/` is a folder. A later full render clears the first row, and so does a render of the report by name. These give no row and no error: a site with no `figures/` folder, a file named `figures`, a hidden file in `figures/`, and a site rendered after its last figure change.
- [ ] AC4: `release_supplement()` stops with `supplement_error_release_check` and changes no file in a site whose only problem is an `ignored-output` row, and in one whose only problem is an `unpublished-figure` row. A test in `tests/testthat/test-release-supplement.R` runs the real `check_supplement()`, not a mock, on each site.
- [ ] AC5: The help page of `check_supplement()` has an item for each check that states the rule of AC1 or AC3. The `"unpublished-figure"` item says that hidden files are not compared, though Quarto copies them. The help text on git checks names `ignored-output` with the two other git checks. The `ignored-output` problem text tells the author to change the ignore rule, and the `unpublished-figure` text tells the author to render again. NEWS.md and the check list in `inst/template/_README.md` (line 139) name both checks.
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
- [ ] T2: Add the AC1 to AC4 and AC6 tests. Write fixture bytes with `writeBin()` (LESSONS M011). Run each row case against main and record that each fails there (LESSONS M010). Recheck the tests that match whole row sets in `test-check-supplement.R` and the full-render tests in `test-add-render.R`, which may now give rows.
- [ ] T3: Write the `ignored-output` check from git's list of ignored files (`git ls-files --others --ignored --exclude-standard`), read in `git_files()` (`R/check-supplement.R:256`), with paths relative to the site. Keep the files in the three folders whose path holds no hidden name and no link, tested with `is_link()`. Add the check to the `skipped` attribute and to the skip message in `report_problems()` (line 205).
- [ ] T4: Write the `unpublished-figure` check with `tools::md5sum()` (LESSONS M027) and the same link-free walk. Add both calls to `check_supplement()` (line 186).
- [ ] T5: Add the roxygen items and run `devtools::document()`. Edit the existing NEWS.md bullet for `check_supplement()`. Add two lines to the check list in `inst/template/_README.md`.
- [ ] T6: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

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

## Decisions

## Review
