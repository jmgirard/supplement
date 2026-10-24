# M050: Give a new site a reader README and a separate guide

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes the files a new site holds and the text its GitHub visitors read
- **Branch/PR:** m050-template-guide-split

## Goal

The first render of a new site leaves a short `README.md` for the people who read the site's repository, and the author guide in its own file, `GUIDE.md`.

## Scope

**In:** `inst/template/_README.md` rewritten as a reader page (title, placeholder citation, site address, contents, license). A new `inst/template/GUIDE.md` that holds the author parts of today's `_README.md`, with the edge cases in a `## Reference` part at its end. `_scripts/setup.lua` stops writing `SUPPLEMENT.md`: it renames `_README.md` to `README.md` when no `README.md` exists and otherwise removes it. `create_supplement(repo =)` writes the Pages address into `GUIDE.md` as well as `_README.md`. The text that names the guide files: `index.qmd`'s first-commit box, `_quarto.yml` comments, roxygen of `create_supplement()` and `check_supplement()`, `README.md`, `vignettes/publishing.Rmd`, DESIGN.md's setup entry. Tests and a NEWS entry.

**Out:** trimming the package `README.md` to its main steps → M051. A placeholder row for the reader page's example citation → DESIGN.md Known issues "Placeholder check limits" (unchanged). Moving sites made earlier to the new files: they keep their guide, and the NEWS entry names where to copy `GUIDE.md` from. The `save_png()` copy step the guide describes → candidate "Shorten the setup code in new reports".

## Acceptance criteria

- [x] AC1: `inst/template/_README.md` holds the line `Website: https://OWNER.github.io/REPO/`, a line that names `GUIDE.md`, and a `## License` heading, and `grep -c -e '```' -e 'supplement::' -e 'quarto render' inst/template/_README.md` prints 0.
- [x] AC2: `inst/template/GUIDE.md` exists, and each `## ` heading of `git show bafeb91:inst/template/_README.md`, except `Contents` and `License`, is a level-2 or level-3 heading of `GUIDE.md` with the same text.
- [x] AC3: `GUIDE.md` has one `## Reference` heading, and `grep -n -e 'device name' -e 'SPDX' -e 'a--b' -e '_scripts/' inst/template/GUIDE.md` prints at least one line for each of the four patterns and only lines below that heading.
- [x] AC4: After the first render of a folder that holds the template's setup files and `GUIDE.md`, in each of three cases (no `README.md`; an existing `README.md`; an existing `README.md` and `SUPPLEMENT.md`), `_README.md` is gone and `GUIDE.md` keeps the template's bytes. In the first case `README.md` has the bytes of the template's `_README.md`. In the second and third cases the `README.md` written before the render, and in the third case the `SUPPLEMENT.md`, keep their bytes, and in the second case no `SUPPLEMENT.md` exists. In each case a second render leaves `README.md`, `GUIDE.md`, `.gitignore`, and any `SUPPLEMENT.md` with the same bytes. Shown by `script_site()` tests in `tests/testthat/test-template.R`; with the template's `GUIDE.md` present, the second-case test fails on the default branch's `setup.lua` at its assertion that no `SUPPLEMENT.md` exists.
- [x] AC5: A new site from `create_supplement()` holds `GUIDE.md`. After `repo = "JDoe/my_site.v-2"`, `_README.md` and `GUIDE.md` both hold `https://jdoe.github.io/my_site.v-2/` and neither holds `OWNER.github.io`; after `repo = "jdoe/JDoe.github.io"`, `GUIDE.md` holds `https://jdoe.github.io/figures/` and not `github.io/JDoe.github.io`. Shown by tests in `tests/testthat/test-create-supplement.R`.
- [x] AC6: `grep -rn 'SUPPLEMENT\.md' R man inst/template vignettes README.md` prints only lines of `R/check-supplement.R` and `man/check_supplement.Rd`; the comment above `placeholder_lines` and the roxygen sentence that names `SUPPLEMENT.md` say the file serves sites made before this change; `devtools::document()` leaves no diff.
- [x] AC7: NEWS.md's development heading has an entry that names `GUIDE.md` and says that an existing `README.md` is kept and no `SUPPLEMENT.md` is written; `devtools::test()` and `devtools::check()` are clean (0 errors, 0 warnings, any NOTE justified).

## Coverage

- AC1 → T1
- AC2 → T1, T6
- AC3 → T1, T6
- AC4 → T2
- AC5 → T3
- AC6 → T1, T2, T3, T4, T5
- AC7 → T5, T6

## Tasks

- [x] T1: Split `inst/template/_README.md`. Move its author parts to a new `inst/template/GUIDE.md`, keeping each heading's text, and end it with `## Reference`, holding the Windows device names and names that end in `.` (from "Paper facts"), the license id syntax with the spdx.org link sentence (lines 109-115), the Markdown changes to file names such as `a--b.csv`, and the "Setup scripts" part as a `###` heading, its text rewritten to say setup renames `_README.md` to `README.md`, or removes it when `README.md` exists. Rewrite `_README.md` as the reader page of AC1, with `GUIDE.md` in its contents list. Update `index.qmd`'s "Before your first commit" box and the two `_quarto.yml` comments to name `GUIDE.md`.
- [x] T2: In `inst/template/_scripts/setup.lua` (lines 107-115 and the header comment at 11-13), drop the `SUPPLEMENT.md` branch: rename `_README.md` to `README.md` when no `README.md` exists, else remove `_README.md`. Copy `GUIDE.md` in `script_site()` and rewrite the rename tests in `test-template.R` (about lines 666-698 and 753-760) to AC4. Grep the Windows-only tests for hand-written lists of template files (LESSONS M028) and add `GUIDE.md` where one lists `_README.md`.
- [x] T3: In `R/create-supplement.R`, make `fill_repo()` (line 264) replace the address in `GUIDE.md` too, and update the roxygen at lines 15-19 and 33 and the message at line 123. Update `test-create-supplement.R`: `template_tracked`, the repo tests, and the rendered-site test at about lines 344-355 that expects `SUPPLEMENT.md`. Point `test-template.R:241` at `GUIDE.md` for the "Paper figures" code block.
- [x] T4: In `R/check-supplement.R`, keep the `SUPPLEMENT.md` placeholder keys (lines 1160-1172) for sites made earlier, and say so in the comment at line 1153 and the roxygen at line 210. Leave the placeholder tests' `SUPPLEMENT.md` cases in place.
- [x] T5: Update the package `README.md` (lines 36 and 58-66) and `vignettes/publishing.Rmd` (line 76) to name `README.md` and `GUIDE.md`; update DESIGN.md's `setup.lua` entry to D-024. Add the NEWS entry, with the `system.file("template", "GUIDE.md", package = "supplement")` path for sites made earlier. Run `devtools::document()`.
- [x] T6: Write and run the AC2 heading script and the AC3 grep, run `devtools::test()` and `devtools::check()`, and record the outputs in the work log.

## Work log

- 2026-10-24: created by /milestone-plan.
- 2026-10-24: tier check: not run — work named at the question set.
- 2026-10-24: idea vet: no concern found; splitting the guide by reader keeps every author part in `GUIDE.md`, and sites made earlier are untouched because setup acts only on a `_README.md` that exists.
- 2026-10-24: question set: which work next — "Split the template guide by reader"; where the author guide lives — its own file in the site (over package docs only, and over keeping one guide file).
- 2026-10-24: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-24: collision: absorbs candidate "Split the template guide by reader" in full with M051; D-006's README clause superseded by D-024 at this plan; D-004 and D-023 stand. Archived M036 (placeholder checks) and M038 (publishing vignette) are extended, not repeated.
- 2026-10-24: lessons: M028 (Windows-only hand lists of template paths) shaped T2; M009 (criteria over listed tests and shapes) shaped AC3 and AC4.
- 2026-10-24: plan chose shipping the guide as `GUIDE.md`, copied under its own name, over `_GUIDE.md` renamed by setup, because Quarto 1.10.19's `use template` skip list (`kBuiltInExcludes` in quarto.js) and `create_supplement()` both copy `GUIDE.md`; falsified by a `quarto use template` run that leaves `GUIDE.md` out.
- 2026-10-24: checked: `quarto use template --no-prompt` (Quarto 1.10.19) from a copy of `inst/template` with a `GUIDE.md` added copied `GUIDE.md` into an empty folder.
- 2026-10-24: plan chose the name `GUIDE.md` over keeping `SUPPLEMENT.md`, because the name says the file is for the site's authors; falsified by a user test in which authors look for the guide under `SUPPLEMENT.md`.
- 2026-10-24: plan split the candidate: M050 covers the template guide and reader README; M051 (planned now, depends on M050) trims the package README.
- 2026-10-24: question set: approach, test scope, and changelog decided by the agent as written in the Tasks and Criteria.
- 2026-10-24: criteria audit (full mode, fresh Opus reader, run after the question set because the work was chosen there): 10 findings on M050, all fixed: AC7 said no guide is written beside an existing README (now: no `SUPPLEMENT.md`); AC6 asked each kept line to state its purpose (now: the comment and roxygen sentence) and missed T1 and T2 in Coverage; AC4 "each existing file" covered renamed files, named no case for the second render, and its failing test would fail on the missing `GUIDE.md` alone; AC4 and AC5 bound test files (now behavior, tests as evidence); AC5 used a lowercase owner and skipped the user-site branch; AC2 named a moving ref and its script (now `bafeb91`); T1 did not name the spdx.org sentence or the Setup scripts rewrite.
- 2026-10-24: implement started on branch m050-template-guide-split.
- 2026-10-24: T1 done: `GUIDE.md` (author parts, `## Reference` with License ids, File names in `_supplement.yml`, Setup scripts) and a 26-line reader `_README.md`; `index.qmd` box and `_quarto.yml` comments name `GUIDE.md`. AC1 grep 0, AC2 no missing heading, AC3 Reference at line 515 with hits at 519-539 only. Minor amendment: T1 also took `GUIDE.md` into `template_tracked` and pointed the figure-code test at `GUIDE.md` (from T3), so the suite stays green; `test-create-supplement.R` 0 failed. One check-list bullet reworded to stay under the style hook's sentence limit.
- 2026-10-24: T2 done: `setup.lua` drops the `SUPPLEMENT.md` branch and removes `_README.md` beside an existing `README.md`. `script_site()` copies `GUIDE.md`; the two README tests and the second-render test became "setup keeps an existing README.md and writes no SUPPLEMENT.md" (three cases, second render in each); the non-ASCII test lost its `SUPPLEMENT.md` line. Before the fix, with `GUIDE.md` in the template, the new test failed once, at `test-template.R:694` `file.exists(... "SUPPLEMENT.md")` in case "a README.md"; after it, it and the rename, non-ASCII, and figure-code tests pass. Windows-only tests list template folders only, so none needed `GUIDE.md`.
- 2026-10-24: T3 done: `fill_repo()` writes the Pages address into `_README.md` and `GUIDE.md`; roxygen of `create_supplement()` names the reader page and `GUIDE.md`, `devtools::document()` rewrote `create_supplement.Rd`. The no-repo message still names `_README.md` only, because `GUIDE.md` holds the address only as an example. Tests: "repo replaces the placeholders" and "a user site repo gets the root Pages address" now read `GUIDE.md` and failed (3 failures) before the change; "a site made with repo renders" expects no `SUPPLEMENT.md`. After: 0 failed, 2 Windows-only skips.
- 2026-10-24: T4 and T5 done: the `placeholder_lines` comment and the roxygen sentence say `SUPPLEMENT.md` serves sites made before the guide moved to `GUIDE.md`; README.md and the vignette (lines 63 and 76) name the reader `README.md` and `GUIDE.md`; DESIGN.md's `setup.lua` entry cites D-024; NEWS entry added; `devtools::document()` rewrote `check_supplement.Rd`. AC6 grep prints 7 lines, all in `R/check-supplement.R` and `man/check_supplement.Rd`. One README check-list bullet reworded for the style hook's sentence limit.
- 2026-10-24: T6: full `devtools::test()` 390 tests, 0 failed, 0 errors, 10 skipped; `devtools::check()` 0 errors, 0 warnings, 0 notes (both run at efd3f1d). After the claim-audit fixes (prose and roxygen only): `devtools::document()` rewrote `check_supplement.Rd`; create-supplement and check-supplement tests 95, 0 failed; the three-case setup test passes; AC2 no missing heading; AC3 Reference at line 517, hits at 521-541 only; AC6 grep 9 lines, all in `R/check-supplement.R` and `man/check_supplement.Rd`.
- 2026-10-24: claim audit: 45 claims read, 4 corrected — NEWS.md, inst/template/GUIDE.md, R/check-supplement.R (re-read once: NEWS sentence on old sites corrected again to name `SUPPLEMENT.md`; the SPDX fix then moved "SPDX" above the Reference heading and was reworded to keep AC3). Not changed: the reader noted the no-repo message and README.md:36 name only `_README.md` for OWNER/REPO, while `GUIDE.md` also holds it in an example figure address; the old guide held the same example, so the text is no less complete than before.
- 2026-10-24: implement done; status review.

## Decisions

## Review

Evidence gathered 2026-10-24 on branch head 150a489, default branch level with `origin/main`.

- AC1 evidence: `grep -c -e '```' -e 'supplement::' -e 'quarto render' inst/template/_README.md` printed 0; `_README.md` holds `Website: https://OWNER.github.io/REPO/` (line 6), `## License` (line 20), and the `GUIDE.md` contents line (line 18).
- AC2 evidence: `inst/template/GUIDE.md` exists; the 14 `## ` headings of `git show bafeb91:inst/template/_README.md` other than `Contents` and `License` were each matched as a whole `## ` or `### ` line of `GUIDE.md` by `grep -qxF`; none missing.
- AC3 evidence: one `## Reference` heading, line 517; the AC3 grep found `device name` at 536, `SPDX` at 521, 522, 524, `a--b` at 534, `_scripts/` at 541: each pattern at least once, all below 517.
- AC4 evidence: "setup keeps an existing README.md and writes no SUPPLEMENT.md" (`test-template.R`, three `script_site()` cases with the template's `GUIDE.md`, first and second render) and "setup renames _gitignore and _README.md with their bytes" pass in the full suite at 150a489. With main's `setup.lua` swapped in (`git show main:...`, restored after), the three-case test failed once, at `test-template.R:694` `expect_false(file.exists(... "SUPPLEMENT.md"))` in case "a README.md"; no other expectation failed.
- AC5 evidence: in the full suite at 150a489, `test-create-supplement.R` passes "a new folder gets every template file with the same bytes" (`template_tracked` lists `GUIDE.md`), "repo replaces the placeholders" (`JDoe/my_site.v-2`: `_README.md` and `GUIDE.md` hold `https://jdoe.github.io/my_site.v-2/`, neither holds `OWNER.github.io`), and "a user site repo gets the root Pages address" (`jdoe/JDoe.github.io`: `GUIDE.md` holds `https://jdoe.github.io/figures/`, not `github.io/JDoe.github.io`). Both repo tests failed before T3's code change (work log).
- AC6 evidence: the AC6 grep printed 9 lines, 6 in `R/check-supplement.R` (211, 212, 215, 1157, 1165, 1175) and 3 in `man/check_supplement.Rd` (230, 231, 234); the comment at 1155-1158 above `placeholder_lines` and the roxygen sentence at 212-215 say `SUPPLEMENT.md` serves sites made before the guide moved to `GUIDE.md`. `devtools::document()` left 0 changed files.
- AC7 evidence: NEWS.md's `# supplement 0.0.0.9000` section opens with an entry naming `GUIDE.md` and saying "When the folder already has a `README.md`, the first render keeps it and no `SUPPLEMENT.md` is written." At 150a489: `devtools::test()` 390 tests, 0 failed, 0 errors, 10 skipped; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- Consistency gate: `cairn_validate.py` all checks passed; no principle changed, so `cairn_impact` skipped; `devtools::document()` no diff; no `README.Rmd`, no pkgdown site; NEWS entry present; no new top-level file (`git diff --name-only main..HEAD` outside `cairn/`, `R/`, `man/`, `tests/`, `inst/`, `vignettes/` lists only `NEWS.md` and `README.md`); `devtools::check()` clean as above.
