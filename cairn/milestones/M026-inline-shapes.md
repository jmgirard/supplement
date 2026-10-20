# M026: check_supplement() finds code of any engine and more inline shapes

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — an exported check whose rows stop `release_supplement()`
- **Branch/PR:** —

## Goal

`check_supplement()` gives a `no-stored-output` row for reports whose only code is a chunk of another engine, `r#` or `{r}` inline code, or code in a file that holds a nul byte.

## Scope

**In:** a wider code rule, a wider inline rule, and a new read of the report text in `check_stored_output()` (`R/check-supplement.R:344`). The milestone also adds tests, help text, template README text if it no longer holds, and a NEWS.md change.

**Out:** stored output that is older than its report goes to M027. A report whose front matter sets `engine: markdown` still counts when it has a chunk, and knitr that a `knitr:` key, `execute: engine`, an included file, or `_metadata.yml` turns on is still not found; the help page states both limits, and no other record holds them.

## Acceptance criteria

- [ ] AC1: The code rule: a line starts with zero or more spaces, tabs, and `>` characters in any order. Then it has three or more backticks, then optional spaces or tabs, then `{`. Then it has a name: the longest run of an ASCII letter followed by zero or more ASCII letters, ASCII digits, `_`, or `.`. Then it has zero or more characters that are not `}`, then `}`, and the line ends with optional spaces or tabs. Only a whole name equal to `ojs`, `mermaid`, or `dot` in any letter case does not count. Quarto's own scan also takes other white space where this rule takes spaces and tabs. If a report has a line that matches the code rule and has no stored output, `check_supplement()` gives a `no-stored-output` row for it. "No stored output" is as M024 defined it. The test file `tests/testthat/test-check-supplement.R` has one report per chunk start, and each gets a row: `` ```{bash} ``, `` ```{sql} ``, `` ```{html} ``, `` ```{include} ``, `` ```{Rcpp} ``, `` ```{rust} ``, `` ```{my_eng2} ``, `` ```{dotnet} ``, and `` ```{ojsx} ``.
- [ ] AC2: These reports give no `no-stored-output` row, and the test file has one report for each: `` ```{mermaid} ``, `` ```{Mermaid} ``, `` ```{mermaid label} ``, `` ```{dot} ``, `` ```{ojs} ``, `` ```{OJS} ``, `` ```{.r} ``, `` ```{=html} ``, `` ```{{r}} ``, `` ```{1r} ``, and `` ```{r} x ``.
- [ ] AC3: Inline R code is, on one line, a backtick, then either `r` and a space or `#`, or `{r}` and a space, then one or more characters that are not backticks, then a backtick. A report with no line that matches the code rule, with inline R code, and with no stored output gets a row when its front matter has a top-level `engine: knitr`, by the M024 front matter rule. The test file has one report with `engine: knitr` per inline shape, and each gets a row: `` `r# 1 + 1` ``, `` `r#1+1` ``, and `` `{r} 1 + 1` ``. It has two reports with no row: `` `{r} 1 + 1` `` with no `engine` key, and `` `{r}1+1` `` with `engine: knitr`.
- [ ] AC4: The check drops each nul byte of a report and splits the text into lines at LF, CR LF, or CR. The test file has three reports with no stored output, and each gets a row: a nul byte on one line and a `` ```{r} `` chunk on another, a nul byte on the chunk line itself, and a CR LF report with a `` ```{bash} `` chunk.
- [ ] AC5: The `"no-stored-output"` item on the `check_supplement()` help page states the code rule of AC1, the inline rule of AC3, and these limits: inline code counts only on one line, only a top-level `engine: knitr` in the report's own front matter is read, and a chunk counts also under `engine: markdown`. `NEWS.md` says that the check finds chunks of any engine and these inline shapes.
- [ ] AC6: `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T1, T2, T3
- AC3 → T2, T3
- AC4 → T1, T2, T3
- AC5 → T4
- AC6 → T2, T3, T4, T5

## Tasks

- [ ] T1: Probe Quarto 1.10.19 for the AC1, AC2, and AC4 shapes not probed at plan: render each report by name in a scratch site with `freeze: true` and record in the work log which ones start an engine (LESSONS M024). Read the engine choice in `/Applications/quarto/bin/quarto.js` (`languagesWithClasses()` at line 31721 and its callers) to confirm that only `ojs`, `mermaid`, and `dot` start no engine. A probe that refutes a criterion goes to the amendment protocol.
- [ ] T2: In `tests/testthat/test-check-supplement.R`, next to the test "chunk starts in more shapes give a no-stored-output row" (line 240), add the AC1 to AC4 reports. Change the M024 cases that this milestone turns: `{rust}` and `{Rcpp}` now give a row (`rust-block` at line 219, and lines 315–316), and so does `r#` inline code (line 287). Write the nul byte with `writeBin()`. Run the new row cases against the code on main and record that each fails there (LESSONS M010).
- [ ] T3: In `R/check-supplement.R`, replace `chunk_start` (line 315) with the code rule, with the three names spelled as `[Oo][Jj][Ss]` and so on (LESSONS M021), and widen the inline pattern at line 359. Replace the `readLines()` call at line 356, which reads a file with a nul byte as empty, with a read that keeps the other lines.
- [ ] T4: Edit the roxygen item for `"no-stored-output"` and run `devtools::document()`. Edit the existing `NEWS.md` bullet for `check_supplement()`. Read `inst/template/_README.md` line 145 and edit it where it no longer holds.
- [ ] T5: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

## Work log

- 2026-10-20: created by /milestone-plan.
- 2026-10-20: tier check: not run — work named at the question set.
- 2026-10-20: question set: what to work on — the candidate rows "Read YAML without running R code", "Find inline code in more shapes", and "Find stale stored output for reports", planned as M025, M026, and M027.
- 2026-10-20: absorbed the candidate row "Find inline code in more shapes" in full.
- 2026-10-20: probes on Quarto 1.10.19 with `freeze: true`: a report with only `{bash}`, `{sql}`, `{html}`, `{include}`, `{embed}`, or `{my_eng2}` chunks and no `engine` key starts Jupyter. `{mermaid}`, `{Mermaid}`, `{dot}`, `{ojs}`, and `{OJS}` start no engine. `{bash}` under `engine: knitr` runs and writes stored output. Under `engine: knitr`, `` `r#1+1` `` and `` `{r} 1+1` `` run, and `` `{r}1+1` `` does not; with no `engine` key, `` `{r} 1+1` `` does not run. Quarto's chunk scan regex is `^[\t >]*```+\s*\{([a-zA-Z][a-zA-Z0-9_.]*)([^}]*)?\}\s*$` (`quarto.js:31723`).
- 2026-10-20: collision check: M024 shipped the current rules, and its tests for `{rust}`, `{Rcpp}`, and `r#` give no row; this milestone turns them to rows, as the candidate row asks. No D-entry overlaps.
- 2026-10-20: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-20: lessons surfaced: M024 (render a probe to learn what runs), M021 (spell letter case with classes under `useBytes`), M009 (criteria as stated rules plus listed tests), M010 (prove a test fails against main).
- 2026-10-20: plan gate chose Quarto's chunk scan with three names left out over a list of knitr engine names, because Quarto picks the engine and starts Jupyter for any other name; falsified by a Quarto version that starts no engine for a name the rule counts.
- 2026-10-20: changelog: the existing 0.0.0.9000 bullet for `check_supplement()` gets the change, with no new bullet.
- 2026-10-20: criteria audit (full mode, fresh Opus reader): 5 findings, all taken. AC1 defines the name as the longest ASCII run, leaves out only a whole `ojs`, `mermaid`, or `dot`, notes Quarto's wider white space, and adds `{dotnet}` and `{ojsx}`; AC2 adds `{mermaid label}`. AC1 and AC3 test one report per shape. AC4 states the nul and line-end rule and adds a nul on the chunk line and a CR LF `{bash}` report. T2 names `rust-block` at line 219. AC5 and AC6 had no finding.

## Decisions

## Review
