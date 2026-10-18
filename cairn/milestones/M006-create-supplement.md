# M006: create_supplement() makes a site from the template

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a new exported R function that authors call
- **Branch/PR:** m006-create-supplement

## Goal

Export `create_supplement()`, which makes a new site folder from the package's template without the Quarto command-line interface.

## Scope

**In:** `create_supplement(path, repo = NULL)` in a new `R/create-supplement.R`. It copies the files of `inst/template/` into `path`. It refuses to write over any file that is already there. With `repo`, it writes the GitHub repository name into the placeholder links. It leaves `_gitignore` and `_README.md` under those names, because the first render renames them (D-004, D-006). Tests, a help page with an example, README and NEWS text.

**Out:**
- `add_report()` and `add_data()`: M007.
- Running `git init` or making the GitHub repository: not planned. The author does it, and the package never runs git (DESIGN Conventions).
- Filling the paper facts in `_supplement.yml`: the author edits that file.
- Release checks and the release helper: the "release checks" candidate row.

## Acceptance criteria

- [x] AC1: With `repo` unset, `create_supplement(path)` copies each template file to the same relative path under `path`, with identical bytes. `_gitignore` and `_README.md` keep those names. In a new folder, the recursive file list under `path` equals the template's file list. In an existing folder that holds `README.md`, `.gitignore`, and `data/other.csv`, those three files keep their bytes. A test checks both folders against `system.file("template", package = "supplement")`.
- [x] AC2: With `repo = "owner/name"`, the function writes `owner/name` in place of each `OWNER/REPO` in `_quarto.yml`. In `_README.md` it writes the GitHub Pages address `https://<owner>.github.io/<name>/` in place of `https://OWNER.github.io/REPO/`, with the owner in lowercase. If the name is `<owner>.github.io`, without regard to case, the address is `https://<owner>.github.io/`. A test uses `JDoe/my_site.v-2` and `jdoe/JDoe.github.io`. It finds the expected value at each replaced site, and it finds no `OWNER/REPO` and no `OWNER.github.io/REPO`.
- [x] AC3: In each case below, the function stops with an error of class `supplement_error` plus one subclass for the case, and it writes nothing. A `path` that did not exist before the call does not exist after it. An existing folder keeps its file list and its file bytes. A test fires each listed form and asserts the error class.
  - `path` is not one non-empty string: a number, `c("a", "b")`, `NA`, and `""`. The class is `supplement_error_argument`.
  - `path` is an existing file.
  - `path` holds a file or a folder where the template writes a file: `analyses/example.qmd`, and a folder named `index.qmd`. Or `path` holds a file where the template needs a folder: a file named `data`. An existing `data/` folder without `example.csv` is not an error case, and the call succeeds.
  - `repo` is not one string `owner/name` of ASCII letters, digits, `-`, `_`, and `.`: no slash, two slashes, an empty owner, a space, and a non-ASCII letter.
- [x] AC4: For a site that `create_supplement()` makes with `repo` given, `quarto render` exits with status 0. The render writes `docs/index.html`, `docs/.nojekyll`, and `.gitignore`.
- [x] AC5: The package README describes `create_supplement()` as a way to start a site. Its help page has an example that writes to a temporary folder. NEWS.md has an entry for it.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2, T5
- AC4 → T3
- AC5 → T4

## Tasks

- [x] T1: Write `R/create-supplement.R`. Check `path` and `repo` first. Then compare the template's file list with `path` and stop on any conflict before the first write. Copy the files with their bytes unchanged, then replace the placeholders when `repo` is given. End with a cli message that tells the author to render once and then commit. Reuse `supplement_error_argument` from `R/supplement-yml.R` for a bad `path`.
- [x] T2: Write `tests/testthat/test-create-supplement.R` for AC1, AC2, and AC3. Take a snapshot of the folder's file list and file bytes before and after each error case.
- [x] T3: Add a render test for a site made with `repo` given. Reuse the skip helpers in `tests/testthat/helper-template.R`, so that the test skips without Quarto, knitr, or rmarkdown.
- [x] T4: Add roxygen documentation with an example that writes to `tempdir()`, and run `devtools::document()`. Add the R route to the README section "Start a new site", next to `quarto use template`. Add a NEWS.md entry.
- [x] T5: Fix review return 1 and the pass-1 fix-now findings in the Review section: an existing file given with a trailing slash, a broken link at `path`, the copied file mode, unclassed `fill_repo()` errors, hidden and rendered files in the template folder, the `repo` owner and name rules, the help wording, the README install line, one shared link check, and the tests that pass with those defects present.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: not run — work named at the question set.
- 2026-10-18: question set: which work to plan — scaffolding, as M006 (`create_supplement()`) and M007 (`add_report()`, `add_data()`).
- 2026-10-18: question set: fill the repository name — an optional `repo` argument.
- 2026-10-18: absorbs the `create_supplement()` part of the candidate row "scaffolding functions"; M007 takes the rest, so the row graduates when M007 is done.
- 2026-10-18: split: the scaffolding row became M006 and M007, because the two parts ship apart and M007's tests build sites with `create_supplement()`. Not a feature series: each part ships its own export and NEWS entry.
- 2026-10-18: plan chose to copy `inst/template/` with R over calling `quarto use template`, because the author then needs no Quarto CLI to start and the copy equals what `quarto use template` writes for a template with no dotfiles; falsified by a file that `quarto use template` writes or changes and that a byte copy does not.
- 2026-10-18: plan chose to leave the `_gitignore` and `_README.md` renames to the first render over doing them in R, so that one code path (`setup.ts`) owns them (D-004, D-006); falsified by an author who commits before the first render and loses the ignore rules.
- 2026-10-18: criteria audit (full mode, fresh Opus reader) returned 11 findings on the M006 draft. Fixed all: AC1 no longer conflicts with AC2 and probes an existing folder; AC2 probes uppercase owners and a user-site name and searches only for the placeholders; AC3 defines "writes nothing" for a new path, names the conflict shapes and the bad-argument forms, and reuses `supplement_error_argument`; AC4 says "exits with status 0" and drops its test-skip clause, which T3 now carries; AC5 adds a help page example.
- 2026-10-18: inbox sweep: no open issues or pull requests.
- 2026-10-18: implement: branch m006-create-supplement cut from main at 36954bf; status in-progress.
- 2026-10-18: implement chose the error classes `supplement_error_repo`, `supplement_error_not_folder`, and `supplement_error_file_exists` (reused from the writers), and moved the `path` check of `check_args()` into `check_path()` so both share it. A link at a template path, even a broken one, counts as a conflict. A failed copy removes what the call made.
- 2026-10-18: T1, T2 done: `R/create-supplement.R` and `tests/testthat/test-create-supplement.R`, 90 expectations; three planted defects (no conflict check, no lowercase owner, no folder creation) each failed tests; full suite 626 passed.
- 2026-10-18: T3 done: render test for a site made with `repo`; it renders with status 0, writes the three files, and its navbar links to the given repository.
- 2026-10-18: T4 done: README "Start a new site" gives the R route first, then the Quarto route; NEWS entry added; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- 2026-10-18: implement: the T3 render test was appended with a shell heredoc, not the Edit tool, so the desktop edit card missed it; the commit 026075c holds it.
- 2026-10-18: claim audit: 37 claims read, 5 corrected — R/create-supplement.R, README.md (README merge wording, `_README.md` placeholder form, unclassed copy error, parent folders left after a failed write, "does the same as quarto use template").
- 2026-10-18: implement: the claim audit fixes added the class `supplement_error_write` for a folder or copy failure and made a failed call remove the missing parents of `path` that it made; two tests cover them (full suite 636 passed). DESCRIPTION gained `Roxygen: list(markdown = TRUE)`, so the Rd lists and links render; `write_citation.Rd` and `write_zenodo.Rd` regenerated; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- 2026-10-18: implement complete: T1-T4 checked, verify clean; status review.
- 2026-10-18: review: branch level with origin/main at 36954bf, no merge needed; no PR yet (route d); Copilot round off (no PROFILE line).
- 2026-10-18: review return 1: AC3 fails for `create_supplement("f/")` with `f` an existing file (`supplement_error_write`, not `supplement_error_not_folder`; diff-bug #2). The same return carries the pass-1 fix-now findings listed in the Review section.
- 2026-10-18: implement: status in-progress; T5 added for review return 1 (minor amendment), Coverage AC3 now maps to T5 too.
- 2026-10-18: T5 done: trailing separators are dropped before the checks, and a broken link at `path` is `supplement_error_not_folder`; copies use `copy.mode = FALSE`; `fill_repo()` errors become `supplement_error_write`; hidden files and `docs`, `_freeze`, `_site` are not copied, and `.Rbuildignore` keeps them out of the build; the owner must be letters and digits with single hyphens and the name must not be `.` or `..`; `path_occupied()` is shared with `check_overwrite()`; help wording and a README install line fixed; tests added for each, including a hard-written template file list and a render in a folder that holds `README.md` and `.gitignore`. Four planted defects (no slash strip, file mode kept, the old `repo` pattern, no copy filter) each failed tests. Full suite 674 passed; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- 2026-10-18: claim audit: 32 claims read, 3 corrected — R/create-supplement.R (`_site` is not render output of this template, the no-guide case when `SUPPLEMENT.md` also exists, and "C:/" lost its separator); the slash rule now keeps a separator after `:` or at a root.
- 2026-10-18: implement complete after return 1: T1-T5 checked, verify clean (138 create_supplement expectations); status review.

## Decisions

## Review

Evidence run 2026-10-18 on m006-create-supplement at edae91d, `NOT_CRAN=true`, `testthat::test_file("tests/testthat/test-create-supplement.R")`: 12 tests, 96 expectations, 0 failed, 0 skipped.

- AC1: "a new folder gets every template file with the same bytes" (21 expectations: file list equal to the template's, bytes equal per file, `_gitignore` and `_README.md` kept) and "an existing folder keeps its files and gains the template" (19: `README.md`, `.gitignore`, `data/other.csv` bytes kept, template files equal) pass.
- AC2: "repo replaces the placeholders" (10: `JDoe/my_site.v-2` at each `_quarto.yml` site, `https://jdoe.github.io/my_site.v-2/` in `_README.md`, no `OWNER/REPO` or `OWNER.github.io/REPO` left, no other change) and "a user site repo gets the root Pages address" (4: `jdoe/JDoe.github.io` gives `https://jdoe.github.io/`) pass.
- AC3: "a bad path stops with an argument error and writes nothing" (1, `c("a", "b")`, `NA_character_`, `NA`, `""`: class `supplement_error_argument`, folder unchanged), "an existing file at path stops and is kept" (`supplement_error_not_folder`), "a file or folder in the template's way stops before any write" (`analyses/example.qmd`, a folder `index.qmd`, a file `data`: `supplement_error_file_exists`, folder state equal before and after), and "a bad repo stops and leaves no new folder" (no slash, two slashes, empty owner, empty name, a space, a non-ASCII letter, length 2, `NA`, a number: `supplement_error_repo`, the new path absent after each call, an existing folder unchanged) pass. The existing `data/` folder case succeeds in the AC1 existing-folder test.
- AC4: "a site made with repo renders" (6 expectations, Quarto 1.10.19, not skipped): `quarto render` status 0, `docs/index.html`, `docs/.nojekyll`, and `.gitignore` exist, and the navbar links to `https://github.com/jdoe/my-supplement`.
- AC5: README.md:17-31 gives the R route with `supplement::create_supplement("my-supplement", repo = "owner/name")`; NEWS.md:11 has the entry; `man/create_supplement.Rd` has an example that writes to `file.path(tempdir(), "my-supplement")`, which `devtools::check()` ran with 0 errors, 0 warnings, 0 notes.

Consistency gate: `cairn_validate.py` all checks passed; `devtools::document()` gives no diff; no README.Rmd and no `_pkgdown.yml`, so those checks do not apply; NEWS.md has the entry; no new top-level file; `devtools::check()` 0 errors, 0 warnings, 0 notes (45.7 s). No principle changed, so `cairn_impact` was skipped.

Pass 1 review, 2026-10-18. spawned: diff-bug, blame-history, prior-review.

- diff-bug #1: `file.copy` keeps the template's file mode, so a read-only package install gives read-only site files, and `fill_repo()` then fails with an unclassed "Permission denied" — fix now.
- diff-bug #2: `create_supplement("f/")` for an existing file `f` gives `supplement_error_write`, not `supplement_error_not_folder`, because `file.exists("f/")` is FALSE on macOS — fix now; AC3 fails for this form, so it is a floor return.
- diff-bug #3: a `path` that is a link to a missing target gives `supplement_error_write`, not a documented class — fix now.
- diff-bug #4: the `repo` pattern accepts `o/..`, `o/.`, and `-/_`, which GitHub rejects, and `o/..` writes `https://o.github.io/../` — fix now.
- diff-bug #5: every file under the installed template is copied, hidden files included, so a stray `.DS_Store`, `.quarto/`, `docs/`, or `_freeze/` from a developer render would reach users — fix now.
- diff-bug #6: failures inside `fill_repo()` are unclassed — fix now; the claim that the made files "were removed" without checking `unlink()` — reject: false in practice, because `unlink()` of files this call just made fails only if another process changes them, and the message stays accurate for the cases the function handles.
- diff-bug #7: `Sys.readlink()` returns `""` on Windows, so a broken link or junction there is not seen; trailing separators on Windows are unchecked — follow-up: added to the "Windows check" row.
- diff-bug #8: "It adds the template's rules" reads as if `create_supplement()` does it — fix now.
- diff-bug #9: the "only the placeholders change" test compares text that lost its line endings — fix now.
- diff-bug #10: no test fails partway through a copy into an existing folder and checks the class and the user's files — fix now.
- diff-bug #11: the expected file list comes from the folder the function copies, so it cannot catch stray files — fix now.
- diff-bug #12: the link test checks only one file, not the whole folder — fix now.
- diff-bug #13: no tests for a trailing slash, a broken link at `path`, or `..` — fix now.
- blame-history #1: refusing conflicts contradicts D-006's merge rule — reject: false, because D-006 governs `setup.ts` at the first render, and `create_supplement()` ships `_gitignore` and `_README.md` under names that never conflict, so the merge still happens.
- blame-history #2: the README says "with this package installed" but gives no install command — fix now.
- blame-history #3: ragged line wrap in README.md:28-30 — reject: style.
- prior-review #1: new path code is untested on Windows — follow-up: added to the "Windows check" row.
- prior-review #2: no render test of a `create_supplement()` site in a folder that already holds `README.md` and `.gitignore` — fix now.
- prior-review #3: `occupied()` copies the link rule of `check_overwrite()` — fix now: one shared helper.
