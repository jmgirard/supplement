# M051: Keep the package README to the main steps

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M050
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the package README is the first page a new user reads
- **Branch/PR:** m051-readme-main-steps

## Goal

The package `README.md` shows the main steps of each task, and the edge cases it held are on the help pages it names.

## Scope

**In:** cut from `README.md` the passages on the template's setup file names, the text insertion of `add_report()` and `add_data()`, the link-check limits of `check_supplement()`, and the staging, subfolder, and rollback details of `release_supplement()`. Each part that loses a passage names the help page (`?fn`) that holds it. Any fact a help page lacks goes into that function's roxygen.

**Out:** the template guide and the site's reader README → M050. Rewording the help pages beyond adding the missing facts. A NEWS entry: the change moves text and changes no behavior, so none is written.

## Acceptance criteria

- [ ] AC1: `grep -n -e 'staged' -e 'subfolder' -e 'requests no' -e 'as text' -e '_gitignore' -e 'old text back' -e 'by hand' -e 'comments stay' -e 'With the' README.md` prints nothing, and `README.md` holds each of `create_supplement(`, `add_report(`, `add_data(`, `check_supplement()`, `release_supplement(`, and `write_dockerfile(`.
- [ ] AC2: The help pages hold the cut facts: `man/release_supplement.Rd` matches `staged`, `subfolder`, `old text back`, and `comments`; `man/check_supplement.Rd` matches `web address is requested`; `man/add_report.Rd` and `man/add_data.Rd` each match `as text` and `by hand`; `man/create_supplement.Rd` matches `_gitignore`. `README.md` names `?release_supplement`, `?check_supplement`, `?add_report`, `?add_data`, and `?create_supplement`.
- [ ] AC3: `devtools::document()` leaves no diff, and `devtools::check()` is clean (0 errors, 0 warnings, any NOTE justified).

## Coverage

- AC1 → T1, T3
- AC2 → T1, T2, T3
- AC3 → T2, T3

## Tasks

- [x] T1: In `README.md`, cut the passages that AC1's patterns find, keeping one sentence per part that names its help page. Keep each part's main call.
- [x] T2: For each AC2 pattern its help page lacks, add the fact to that function's roxygen in `R/`, then run `devtools::document()`.
- [ ] T3: Run the AC1 and AC2 greps and `devtools::check()`, and record the outputs in the work log.

## Work log

- 2026-10-24: created by /milestone-plan.
- 2026-10-24: tier check: not run — work named at the question set.
- 2026-10-24: idea vet: no concern found; the cut passages stay on the help pages, so no fact leaves the package docs.
- 2026-10-24: split from the candidate "Split the template guide by reader" with M050; depends on M050, which rewrites README.md lines 58-66 first.
- 2026-10-24: criteria audit (full mode, fresh Opus reader): 3 findings, all fixed: AC2's `requests no` matched no help page (now `web address is requested`, the help page's wording); AC2 named `add_data.Rd` but README was not asked to name `?add_data` (added); AC1's patterns missed three Scope passages (added `by hand`, `comments stay`, `With the`, with their help-page patterns in AC2). Noted for T2: M050 T3 rewrites the `create_supplement()` roxygen that holds `_gitignore`.
- 2026-10-24: plan chose no NEWS entry, because the change moves README text and changes no package behavior; falsified by a cut fact that no help page held before T2 and that users relied on.
- 2026-10-24: implement start: branch m051-readme-main-steps cut from main at 5fb4c05; status in-progress.
- 2026-10-24: T1 done: cut the setup-file-name, .gitignore merge, text-insertion, link-limit, git-skip, release-stop, rollback, and `-- .` passages from README.md (55 lines changed, 41 removed); each part names its help page in one sentence; AC1 grep prints nothing.
- 2026-10-24: T1 choice: the check part's pointer sits above the list and replaces the "(`?check_supplement` lists them all)" bullet tail; the release part's pointer is two sentences, because the simple-english linter refuses a trailing condition.
- 2026-10-24: T1 line count correction: README.md changed by 17 insertions and 38 deletions (`git show --stat` 55); the 41 deletions counted all three files.
- 2026-10-24: T2 done: every AC2 pattern already matched its help page; read each cut fact against the pages, and only the reason for the `_gitignore` and `_README.md` names (from `inst/template/_scripts/setup.lua`) was missing; added it to the `create_supplement()` roxygen; `devtools::document()` rewrote only `create_supplement.Rd`.
- 2026-10-24: claim audit: 18 claims read, 2 corrected — README.md, R/create-supplement.R (README's release sentence now says skipped git checks stop it and a differing CITATION.cff DOI does not; the reader found the "adds the rules it lacks" fact on no help page, so the `create_supplement()` roxygen now says so, and its re-read added that the render ends `.gitignore` with `!docs/` and `!_freeze/`, checked against setup.lua by the session since the rule allows no second pass); also rewrapped README line 61.

## Decisions

## Review
