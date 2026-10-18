# M006: create_supplement() makes a site from the template

- **Status:** in-progress
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

- [ ] AC1: With `repo` unset, `create_supplement(path)` copies each template file to the same relative path under `path`, with identical bytes. `_gitignore` and `_README.md` keep those names. In a new folder, the recursive file list under `path` equals the template's file list. In an existing folder that holds `README.md`, `.gitignore`, and `data/other.csv`, those three files keep their bytes. A test checks both folders against `system.file("template", package = "supplement")`.
- [ ] AC2: With `repo = "owner/name"`, the function writes `owner/name` in place of each `OWNER/REPO` in `_quarto.yml`. In `_README.md` it writes the GitHub Pages address `https://<owner>.github.io/<name>/` in place of `https://OWNER.github.io/REPO/`, with the owner in lowercase. If the name is `<owner>.github.io`, without regard to case, the address is `https://<owner>.github.io/`. A test uses `JDoe/my_site.v-2` and `jdoe/JDoe.github.io`. It finds the expected value at each replaced site, and it finds no `OWNER/REPO` and no `OWNER.github.io/REPO`.
- [ ] AC3: In each case below, the function stops with an error of class `supplement_error` plus one subclass for the case, and it writes nothing. A `path` that did not exist before the call does not exist after it. An existing folder keeps its file list and its file bytes. A test fires each listed form and asserts the error class.
  - `path` is not one non-empty string: a number, `c("a", "b")`, `NA`, and `""`. The class is `supplement_error_argument`.
  - `path` is an existing file.
  - `path` holds a file or a folder where the template writes a file: `analyses/example.qmd`, and a folder named `index.qmd`. Or `path` holds a file where the template needs a folder: a file named `data`. An existing `data/` folder without `example.csv` is not an error case, and the call succeeds.
  - `repo` is not one string `owner/name` of ASCII letters, digits, `-`, `_`, and `.`: no slash, two slashes, an empty owner, a space, and a non-ASCII letter.
- [ ] AC4: For a site that `create_supplement()` makes with `repo` given, `quarto render` exits with status 0. The render writes `docs/index.html`, `docs/.nojekyll`, and `.gitignore`.
- [ ] AC5: The package README describes `create_supplement()` as a way to start a site. Its help page has an example that writes to a temporary folder. NEWS.md has an entry for it.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T3
- AC5 → T4

## Tasks

- [x] T1: Write `R/create-supplement.R`. Check `path` and `repo` first. Then compare the template's file list with `path` and stop on any conflict before the first write. Copy the files with their bytes unchanged, then replace the placeholders when `repo` is given. End with a cli message that tells the author to render once and then commit. Reuse `supplement_error_argument` from `R/supplement-yml.R` for a bad `path`.
- [x] T2: Write `tests/testthat/test-create-supplement.R` for AC1, AC2, and AC3. Take a snapshot of the folder's file list and file bytes before and after each error case.
- [x] T3: Add a render test for a site made with `repo` given. Reuse the skip helpers in `tests/testthat/helper-template.R`, so that the test skips without Quarto, knitr, or rmarkdown.
- [x] T4: Add roxygen documentation with an example that writes to `tempdir()`, and run `devtools::document()`. Add the R route to the README section "Start a new site", next to `quarto use template`. Add a NEWS.md entry.

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
