# M008: check_supplement() lists release problems

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a new exported R function
- **Branch/PR:** m008-check-supplement

## Goal

Export `check_supplement()`, which lists the problems in a site that would break or leak a release.

## Scope

**In:** `check_supplement(path = ".")` checks five things: files too large for GitHub, saved R object files that git would publish, reports with code but no stored output in `_freeze/`, broken links inside the rendered site in `docs/`, and DOIs in `CITATION.cff` or `docs/index.html` that differ from `_supplement.yml`. It prints each problem and returns all of them as a data frame. It runs git only to read the file list. Tests, a help page with an example, README, `_README.md`, NEWS, and DESIGN text.

**Out:**
- `release_supplement()` and the site version: M009.
- Requests to web addresses outside the site: the "web link check" candidate row.
- Stored output that is older than its report source: the "stale stored output" candidate row.
- Path handling on Windows: the "Windows check" candidate row.

## Acceptance criteria

- [ ] AC1: `check_supplement(path = ".")` returns, invisibly, a data frame with the character columns `check`, `file`, and `problem`, with one row per problem and zero rows when it finds none. The result's `skipped` attribute is a character vector that names each check that did not run (AC3), and is empty when all ran. It prints each problem, or one line that says it found none. It stops with `supplement_error_argument` when `path` is not one non-empty string, with `supplement_error_no_metadata` when the folder has no `_supplement.yml`, and with `supplement_error_doi` when a DOI in `_supplement.yml` is not a DOI, as `write_citation()` does. A test makes a site with `create_supplement()`, renders it, and makes it a git repository. The result has zero rows, and each problem that AC2 to AC6 plant gives a row with the `check` value that the criterion names. The test skips without quarto or git.
- [ ] AC2: The git sweep is the list of files that `git ls-files -z --cached --others --exclude-standard` prints in the site folder, split at each NUL byte, which is the files that git tracks or would add. Each listed file larger than 104,857,600 bytes (100 MiB, the limit on GitHub's page "About large files on GitHub") gives a row with check `"large-file"`. Each listed file whose name ends in `.rds`, `.rda`, `.rdata`, `.qs`, or `.qs2`, in any letter case, gives a row with check `"saved-object"`. A test plants a sparse file of 104,857,601 bytes (one row) and one of 104,857,600 bytes (no row). It also plants a `fits/model.RDS` that `git add -f` adds (one row), an untracked `données.rds` that no rule blocks (one row), and an `x.rds` that the template's `.gitignore` blocks (no row).
- [ ] AC3: The function runs git only through one internal helper, and only as `git --version`, `git rev-parse --is-inside-work-tree`, and `git ls-files` with the options in AC2. A search of `R/` for `system(`, `system2(`, `shell(`, `pipe(`, `processx`, `callr`, and `sys::` finds only that helper. When git is not on the PATH, when `git --version` exits with a status other than 0, or when the folder is not in a git work tree, the function skips the AC2 checks, names them in the `skipped` attribute, prints that it skipped them and why, and gives no row for them. A test mocks the helper for each of the three cases.
- [ ] AC4: Each file that `Sys.glob("analyses/*.qmd")` finds in the site and that has a line matching `` ^\s*`{3,}\{(r|python|julia)[\s,}] `` gives a row with check `"no-stored-output"` when `_freeze/analyses/<name>/execute-results/` holds no file. A test plants reports with no stored output that have an R chunk, a Python chunk, and an R chunk indented inside a callout (one row each), a report with no code chunk and one with a `{rust}` block (no row), and the rendered template's example report (no row).
- [ ] AC5: For each file that `list.files("docs", pattern = "\\.html$", recursive = TRUE)` finds, the function reads each `href` or `src` value that the pattern `\b(href|src)\s*=\s*("[^"]*"|'[^']*')` finds. It skips a value that has a URL scheme, starts with `/` or `#`, or is empty. It removes the query and fragment, decodes percent signs, and resolves the rest against the page's folder. A target inside `docs/` that is neither a file nor a folder with an `index.html` gives a row with check `"broken-link"` that names the page and the link. A target outside `docs/` gives the same row. A site with no `docs/` folder gives one row with check `"not-rendered"` and no link rows. A test uses hand-written pages with a link to an existing file, a missing file, `a%20b.csv` for an existing `a b.csv`, a folder with and without `index.html`, a single-quoted link, a link with `?v=1#x`, a `../` link that leaves `docs/`, and `https:`, `mailto:`, and `#top` links. It also uses a page in `docs/analyses/` with a `../index.html` link (no row) and a `../../x.html` link (one row).
- [ ] AC6: Each DOI goes through `bare_doi()` before the comparison, which ignores letter case. A difference gives a row with check `"doi-mismatch"`. When `CITATION.cff` exists, the function compares its `doi` with the DOI that `write_citation()` writes from `_supplement.yml` (`concept-doi`, else `version-doi`), and a DOI on one side only also gives a row. When `docs/index.html` exists, it compares the DOI in each `https://zenodo.org/badge/DOI/<id>.svg` there with the badge DOI in `_supplement.yml` (`version-doi`, else `concept-doi`), and a badge with no badge DOI in `_supplement.yml` also gives a row. A missing badge gives a row only when `_supplement.yml` has a badge DOI and `index.qmd` holds `{{< supplement-doi >}}`. A test covers equal DOIs, a changed DOI in each file, a DOI that differs only in letter case, a missing DOI on each side, a site rendered before its DOI was added, and a missing badge with no shortcode in `index.qmd` (no row).
- [ ] AC7: The package README and the template's `_README.md` describe `check_supplement()`. Its help page has an example that runs on a temporary folder. NEWS.md has an entry for it.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T3
- AC3 → T1, T3
- AC4 → T1, T4
- AC5 → T1, T4
- AC6 → T1, T5
- AC7 → T6

## Tasks

- [x] T1: Write `tests/testthat/test-check-supplement.R` with the fixtures that AC1 to AC6 name. Build git fixtures with `git_in()` and `skip_if_no_git()` from `tests/testthat/helper-template.R`, and reuse `rendered_site()` for the rendered case. Make `skip_if_no_git()` also skip when `git --version` fails.
- [x] T2: Write `R/check-supplement.R` with the exported function, the result frame, the printed report, and the argument and metadata errors. Reuse `check_path()` and `read_supplement()` from `R/supplement-yml.R`.
- [x] T3: Write the git helper and the sweep, with the AC2 and AC3 checks. Cite GitHub's file size page in a code comment beside the limit.
- [x] T4: Write the stored-output check and the link check. Do the link check in base R, with no HTML package.
- [x] T5: Write the DOI check. Reuse `bare_doi()` from `R/supplement-yml.R` and read `CITATION.cff` with the yaml package.
- [x] T6: Add roxygen documentation with an example that writes to `tempdir()`, and run `devtools::document()`. Describe the function in `README.md` and `inst/template/_README.md`, add a NEWS.md entry, and update DESIGN.md Architecture.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: not run — work named at the question set.
- 2026-10-18: question set: which work to plan — release checks, as M008 and M009.
- 2026-10-18: question set: what `check_supplement()` does on a problem — print it and return all problems as a data frame, with no error.
- 2026-10-18: question set: may `check_supplement()` run read-only git commands — yes, `git ls-files` and the commands to find git; never tag, commit, or push.
- 2026-10-18: the link check tests only links inside the site, as the accepted option for the release checks said; requests to web addresses go to the "web link check" row.
- 2026-10-18: plan split the "release checks" row: M008 covers `check_supplement()`, and M009 (planned now, depends on M008) covers `release_supplement()` and the site version.
- 2026-10-18: plan chose a regular expression over quoted `href` and `src` values over an HTML parser such as xml2, because xml2 is a new dependency that the question set did not grant and Quarto writes quoted attributes; falsified by Quarto output with unquoted link attributes.
- 2026-10-18: plan chose the files that git tracks or would add (`--cached --others --exclude-standard`) over tracked files only, because a site before its first commit tracks nothing; falsified by a site where an untracked, unignored file is never meant to be committed.
- 2026-10-18: plan chose a stored-output test of code chunks plus `execute-results/` over a test of every report, because Quarto stores no output for a report without code; falsified by a report with code whose stored output Quarto puts somewhere else.
- 2026-10-18: collision check: no D-entry rejects this work. D-008's consequences name the release check as a place to look for missing data files, which the link check covers through the data table links. The archive holds no release check.
- 2026-10-18: inbox sweep: no open issues or pull requests.
- 2026-10-18: criteria audit (full mode, fresh Opus reader) returned 11 findings across M008 and M009, 6 on M008. Fixed all: AC1 adds a `skipped` attribute and the invalid-DOI stop; AC2 reads `ls-files -z`, so non-ASCII names match, with a `données.rds` probe; AC3 widens its process search to `pipe(`, `callr`, and `sys::`; AC4 matches indented and longer fences by one pattern and probes Python, a callout, and `{rust}`; AC5 adds subfolder pages; AC6 passes both sides through `bare_doi()` and limits the missing-badge row to sites that use the shortcode. The reader confirmed the 100 MiB limit, the freeze path, and the `ls-files` options.
- 2026-10-18: lessons applied: the git on PATH here fails until the Xcode license is accepted, so the git helper treats a failing `git --version` as no git (T1, AC3); a test file of 100 MiB is made sparse, after the M004 lesson on large fixtures; trailing separators are dropped before file checks (M006).
- 2026-10-18: started implement on branch m008-check-supplement.
- 2026-10-18: T1–T5 done in one checkpoint, since the five checks share one file. `devtools::test()`: 1349 pass, 0 fail, 1 skip (case-insensitive disk), run with `/opt/homebrew/bin` first on PATH because `/usr/bin/git` fails here.
- 2026-10-18: implement chose `git_run(args, dir)` as the one process helper; it returns NULL when git is not on the PATH, so one mock covers all three skip cases. It runs git with the folder as the working directory, not with `git -C`, so every call is one of the AC3 commands.
- 2026-10-18: implement chose to resolve each link by its path segments inside `docs/` rather than with `normalizePath()`, so a `../` above `docs/` is broken without a file system read; a percent decoder in base R avoids importing utils.
- 2026-10-18: `bare_doi()` gained a `file` argument, so an invalid DOI in `CITATION.cff` or the badge names that file; an unreadable `CITATION.cff` stops with the yaml package's error.
- 2026-10-18: planted defects turned the new tests red: limit `>=`, no `-z`, no Python, no indent, case-sensitive DOIs, no shortcode test, no percent decoding, `href` only, and `..` dropped above `docs/`. The last needed a `docs/outside.html` fixture before it failed.
- 2026-10-18: T6 done: help page, README and `_README.md` sections, NEWS entry, DESIGN Architecture paragraph. `devtools::test()` 1349 pass, 1 skip; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- 2026-10-18: claim audit: 64 claims read, 6 corrected — R/check-supplement.R, man/check_supplement.Rd, README.md, NEWS.md, inst/template/_README.md, tests/testthat/test-check-supplement.R. Fixes: the Errors section lists `no_map` and `field_type`; an unreadable `CITATION.cff` now gives a `doi-mismatch` row, not an R error; `skipped` names only the git checks; the link and stored-output text names quoted relative links, folders without `index.html`, and reports directly in `analyses/`; the git text names all three commands; the git test fixtures also set `XDG_CONFIG_HOME`. The re-read found the Markdown link wording still short, fixed with the reader's wording.
- 2026-10-18: implement done; status review. `devtools::test()` 1351 pass, 1 skip; `devtools::check()` 0 errors, 0 warnings, 0 notes.
