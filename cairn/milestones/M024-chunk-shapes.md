# M024: check_supplement() finds code chunks in more shapes

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — an exported check whose rows stop `release_supplement()`
- **Branch/PR:** m024-chunk-shapes

## Goal

`check_supplement()` gives a `no-stored-output` row for the code chunk shapes and the inline R code that it now misses.

## Scope

**In:** a new code rule and an inline-code rule in `check_stored_output()` (`R/check-supplement.R`). The milestone also adds tests, help text, README and template README text, and a NEWS.md change.

**Out:** stored output that is older than its report goes to the candidate row "Find stale stored output for reports". Reports that turn on knitr by a `knitr:` key, by `execute: engine`, through `{{< include >}}` files, or through `_metadata.yml` are not found, by the answer at the plan question set. The help page states this limit.

## Acceptance criteria

- [ ] AC1: The code rule: a line starts with zero or more spaces, tabs, and `>` characters in any order. Then it has three or more backticks, then optional spaces or tabs, then `{`. Then it has `r`, `python`, or `julia` in any letter case, then a space, a comma, or `}`. The line ends with `}` and optional spaces or tabs. A report has no stored output when `_freeze/analyses/<name>/execute-results/` lists no file. Hidden files and the files in hidden folders do not count. If a report has a line that matches the code rule and has no stored output, `check_supplement()` gives a `no-stored-output` row for it. The test file `tests/testthat/test-check-supplement.R` has one report for each of these chunk starts: `` ``` {r} ``, `` ```{R} ``, `` ```{Python} ``, `` ```{JULIA} ``, ````` ````{r} `````, `` ``` {python} ``, `` ```{julia label} ``, `> ```{r}`, `> > ```{r}`, `>```{python}`, a tab and then `> ```{r}`, a tab-indented `` ```{r} ``, and three backticks, a tab, and `{r}`.
- [ ] AC2: Inline R code is, on one line, a backtick, then `r`, then a space, then one or more characters that are not backticks, then a backtick. The front matter starts after a first `---` line, which spaces or tabs can follow. Only blank lines can come before that line, and the next line is not blank. The front matter ends at the next `---` or `...` line. Take a report with no line that matches the code rule, with inline R code, and with no stored output. If its front matter parses as a YAML map whose top-level `engine` value is the text `knitr`, the report gets a `no-stored-output` row. Any other front matter gives no row, and so does a report with no front matter. Front matter that does not parse, or that is not a map, gives no error. The test file has one report for each case: `engine: knitr`, no `engine` key, `engine: markdown`, no front matter, front matter that does not parse, and front matter that is a scalar. It also has two reports with `engine: knitr` that give no row: one with inline code split over two lines, and one with `` `r#` `` inline code.
- [ ] AC3: These reports give no `no-stored-output` row, and the test file has one report for each: a code block with a class (`` ```{.r} ``), an escaped chunk (`` ```{{r}} ``), the engine names `` ```{rust} `` and `` ```{Rcpp} ``, and a line with text after the closing brace (`` ```{r} x ``). The test file also has a report with a line that matches the code rule and a file in its `execute-results/` folder. It also has a report whose front matter sets `engine: knitr` and that holds no inline R code and no chunk.
- [ ] AC4: A four-backtick block that shows `` ```{r} `` as text gives a row, and so does a chunk inside an HTML comment, because knitr 1.52 runs both. The test file has a report for each.
- [ ] AC5: The `"no-stored-output"` item on the `check_supplement()` help page states the code rule of AC1, the inline rule of AC2, and the limits of both rules. The limits are that inline code counts only on one line, and that only a top-level `engine: knitr` in the report's own front matter is read. `NEWS.md` says that the check finds these chunk shapes.
- [ ] AC6: `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T3
- AC6 → T1, T2, T3, T4

## Tasks

- [x] T1: In `tests/testthat/test-check-supplement.R`, next to the test "reports with code but no stored output give a no-stored-output row" (line 210), add the AC1 to AC4 reports. Write tabs with `"\t"` in R strings. Run the new row cases against the code on main and record that each fails there.
- [x] T2: In `check_stored_output()` (`R/check-supplement.R:299`), replace the regex at line 313 with the code rule. Spell the engine names as `[Rr]` and so on, because `(?i)` with `useBytes` follows the locale (LESSONS M021). Add the inline rule with a small front matter reader. Parse with `yaml::yaml.load()` inside `tryCatch()` and `suppressWarnings()` (LESSONS M008, M005). Check that the result is a named list before reading `engine`.
- [x] T3: Edit the roxygen item for `"no-stored-output"` and run `devtools::document()`. Edit the existing `NEWS.md` bullet for `check_supplement()`, because version 0.0.0.9000 is not released. Read `README.md` line 100 and `inst/template/_README.md` line 145, and edit each one where it no longer holds.
- [x] T4: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: what to work on — the candidate row "Find missing output in more chunk shapes".
- 2026-10-20: question set: inline R code counts only with `engine: knitr` in the report's own front matter — yes. Reports that turn on knitr in other ways are not found, and the help page says so.
- 2026-10-20: question set: plan the stale-output check as a second milestone now — no, it stays a candidate row.
- 2026-10-20: absorbed the candidate row "Find missing output in more chunk shapes" in full. Probes on Quarto 1.10.19 and knitr 1.52 refuted two of its claims. A four-backtick block that shows a chunk runs it, so its row is right (AC4). A report with only inline `r` code runs nothing unless the engine is knitr (AC2).
- 2026-10-20: probes: `` ``` {r} ``, `{R}`, `> ```{r}`, a tab-indented chunk, and a chunk in an HTML comment ran R and wrote stored output. `` ``` {python} ``, `{Python}`, and `> ```{python}` made Quarto start Jupyter.
- 2026-10-20: collision check: M008 shipped the check, and no D-entry or other archive overlaps. The row "Find stale stored output for reports" is distinct and named in Out.
- 2026-10-20: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-20: lessons surfaced: M009 (criteria as stated rules plus listed tests), M021 (spell ASCII letter case with classes, not `(?i)`, under `useBytes`), M008 and M005 (parse YAML text with `yaml.load()` inside `suppressWarnings()`), M010 (prove a test fails against main).
- 2026-10-20: criteria audit (full mode, fresh Opus reader): 11 findings, 8 taken, 3 with no change. The code rule now allows a tab before `{` and needs the line to end at `}`, as knitr and Quarto do. AC1 defines "no stored output" and adds four-backtick, `{julia label}`, mixed-prefix, and tab-before-brace cases. AC2 narrows inline code to one line and the front matter to Quarto's shape, with no error on a bad parse, and lists the cases. AC3 adds `{r} x`. AC5 states the limits. AC3, AC4, and AC6 had no finding.
- 2026-10-20: plan gate chose a code rule that follows knitr's and Quarto's chunk-start patterns over the old rule plus three listed fixes, because the release check exists to predict what a render runs; falsified by a Quarto version whose chunk scan differs from knitr's pattern.
- 2026-10-20: plan gate chose to read only a top-level `engine: knitr` (user answer) over counting any inline R code, because a plain report runs no inline code and a false row stops a release; falsified by a common site setup that turns on knitr with no chunk and no `engine` key.
- 2026-10-20: changelog: the existing 0.0.0.9000 bullet for `check_supplement()` gets the change, with no new bullet.
- 2026-10-20: implement started on branch m024-chunk-shapes, cut from main at ca5edb7.
- 2026-10-20: T1: three tests added (row shapes, inline rule, non-chunk blocks), with a `report_lines()` helper for reports with no front matter added. Against the code on main all three fail: 10 of the 13 AC1 chunk starts and both inline knitr cases give no row, and `{r} x` gives a row. The AC4, four-backtick, `{julia label}`, and tab-indent cases already gave rows. This commit carries the failing tests.
- 2026-10-20: T2: `chunk_start` pattern and `engine_is_knitr()` added in `R/check-supplement.R`. The front matter is parsed with sequences kept as lists, because a probe showed that `engine: [knitr]` otherwise reads as the text `knitr` (LESSONS M005); a test for it was added. A guard covers a `---` line right after the first one, where `seq.int()` counts down. `devtools::test()`: 0 failures, 4259 passes, 7 skips.
- 2026-10-20: T3: the `"no-stored-output"` help item states the code rule, the inline rule, the limits, and what counts as stored output. The `check_supplement()` NEWS bullet names the new shapes. `README.md` line 100 and `inst/template/_README.md` line 145 say only "with code", which still holds, so they are unchanged. `devtools::document()` run.
- 2026-10-20: T4: `devtools::check()` at 96d9a7d: 0 errors, 0 warnings, 0 notes. `devtools::test()` after the claim fixes: 0 failures, 4259 passes, 7 skips. The R-CMD-check workflow runs at the PR.
- 2026-10-20: claim audit: 19 claims read, 2 corrected — R/check-supplement.R, man/check_supplement.Rd. The help item now says the line can end with spaces or tabs after `}`. The `engine_is_knitr()` comment now states the check's own rule and that Quarto also accepts an indented first `---`. The same reader re-read both corrections and found that both hold.

## Decisions

## Review
