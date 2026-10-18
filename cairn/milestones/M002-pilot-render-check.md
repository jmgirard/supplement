# M002: Pilot render on the data machine and data-free rebuild

- **Status:** review
- **Priority:** high
- **Depends on:** M001
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — an unmerged proof branch of a companion repo that informs template extraction
- **Branch/PR:** m002-pilot-render-check; companion: /Users/jmgirard/github/pilot-ptsd-markers freeze-layout (not merged, no PR)

## Goal

Show that the pilot site, after one full render on the machine that holds the fits and private data, rebuilds from a fresh clone with no data and keeps the navbar on every report page.

## Scope

**In:** the user's full `quarto render` of the `freeze-layout` branch on the data machine, with the commit and push of `_freeze/` and `docs/`. A fresh-clone rebuild on this Mac with `data/*.csv` deleted. The site-library count. Findings from both machines added to the pilot-port note.

**Out:**
- A merge to pilot `main`, a change to the live site, or a new Zenodo release. Not planned.
- A comparison of new estimates with v1.1.0. The fits are reused, so the estimates do not change.
- Template extraction → the "template extraction" candidate row.

## Acceptance criteria

- [x] AC1: For each `analyses/<name>.qmd` that `git ls-files 'analyses/*.qmd'` lists on origin's `freeze-layout`, `git ls-files _freeze/analyses/<name>` lists at least one file.
- [x] AC2: In a fresh clone of origin's `freeze-layout` with `data/*.csv` deleted, `quarto render` exits 0 and `git status --porcelain _freeze` prints nothing. Each `docs/analyses/<name>.html` for the listed sources matches `id="quarto-header"`, and matches `href="[^"]*<other>\.html"` for every other listed source.
- [x] AC3: After the AC2 render, `find docs -name 'bootstrap*.min.css'` in the clone returns one file.
- [x] AC4: The Problems section of `cairn/references/pilot-port.md` has one entry for each `data-machine report:` line in this file's work log. Its path list matches `git diff --name-status main...origin/freeze-layout` run after the user's commits.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: Stop for the user: on the data machine, follow the branch README section, run a full `quarto render`, then commit and push `_freeze/` and `docs/`.
- [x] T2: Fetch origin's `freeze-layout` and run the AC1 listing.
- [x] T3: Clone it into the scratchpad, delete `data/*.csv`, run a full `quarto render`, then run the AC2 and AC3 checks.
- [x] T4: Ask the user what went wrong on the data machine and write each problem as a `data-machine report:` work-log line. Add those entries and the new path list to the pilot-port note.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — needs the user's machine and a design check of the freeze layout.
- 2026-10-18: question set: renders of the model reports and demographics happen on the machine that built v1.1.0, with its existing fits and private data.
- 2026-10-18: question set: branch fate — push only, no merge.
- 2026-10-18: criteria audit (reduced mode, Opus): AC1 to AC3 passed. AC4 had no record to check against and an undefined "refreshed". Fixed with `data-machine report:` lines and a named diff command.
- 2026-10-18: T1 done by the user: commit dddad4a "Render all reports" on origin `freeze-layout`, pushed after comparing the demographics page with the live page. Origin `main` still 54684dc. The commit kept `docs/` cleaned of the old `_files/` and `docs/src/` copies.
- 2026-10-18: T2 done: on origin `freeze-layout`, `_freeze/analyses/` holds 1 file each for demographics and feature_descriptives and 12 each for the three model reports. No CR characters in `_freeze/`. The only backslashes are the default Windows data paths already in the demographics source.
- 2026-10-18: T3 done: fresh clone of origin `freeze-layout` at dddad4a in the scratchpad, `data/*.csv` deleted, full `quarto render` exited 0, `_freeze` status empty, all 5 pages have the header and links to the other 4, and one bootstrap theme file. Extra check: every decimal number on the verbal, vocal, visual, and demographics pages matches the v1.1.0 pages on `main`, except one added "4.0" from the new footer license text, so the fits were reused.
- 2026-10-18: T4 done: asked the user, who answered "Nothing went wrong", so the work log has no report lines and the note's Problems section gains no entry. The note's path list now matches `git diff --name-status main...origin/freeze-layout` at dddad4a (259 lines, script compare). P3 and the Windows open question are marked closed.
- 2026-10-18: verify slot not applicable: the repo has no R package code yet.
- 2026-10-18: claim audit: not owed — internal tier.
- 2026-10-18: all tasks done; status set to review.
- 2026-10-18: correction from review (diff-bug #3): the T2 line's "only backslashes are the default Windows data paths" is wrong. R `\(x)` lambdas and `"\n"` strings in the source also put backslashes in `_freeze/`.
- 2026-10-18: correction from review (diff-bug #1, #6): the T3 number check also matches on feature_descriptives. "So the fits were reused" covers the printed numbers only: the 27 posterior predictive check figures changed, because their draws have no seed (note P9).

## Decisions

## Review

- Sync: origin/main is c5013a0, an ancestor of the branch. Copilot round off.
- AC1 evidence (2026-10-18): pilot checkout at dddad4a, equal to origin `freeze-layout`, clean tree. `git ls-files 'analyses/*.qmd'` lists 5 sources. `git ls-files _freeze/analyses/<name>` lists 1 file for demographics, 1 for feature_descriptives, and 12 each for verbal_analyses, visual_analyses, and vocal_analyses.
- AC2 evidence (2026-10-18): a new fresh clone of origin `freeze-layout` at dddad4a, `data/*.csv` deleted, full `quarto render` exited 0. `git status --porcelain _freeze` printed nothing. All 5 report pages match `id="quarto-header"` once and link to each of the other 4 sources.
- AC3 evidence (2026-10-18): after that render, `find docs -name 'bootstrap*.min.css'` in the clone returns 1 file, `docs/site_libs/bootstrap/bootstrap-445b8638c3d06994fee0907d791121c4.min.css`.
- AC4 evidence (2026-10-18): the work log holds 0 lines that open with `data-machine report:`, because the user reported no problems, so the Problems section owes 0 new entries. A script compared the note's path block with `git diff --name-status main...origin/freeze-layout` at dddad4a, sorted: all 259 lines match.
- Consistency gate (2026-10-18): `cairn_validate.py` all checks passed. The r-package toolchain checks are not applicable, because no package code exists yet. No principle changed.
- spawned: diff-bug (one Opus reviewer, internal-tier docs-only primary diff; it also read the companion commit dddad4a and re-ran the no-data rebuild).
- diff-bug #1: the 27 posterior predictive check figures differ from v1.1.0 because `pp_check(..., ndraws = 100)` draws without a seed (`analyses/verbal_analyses.qmd:393`), so a merge would change published figures. Checked: unnamed-chunk-8-1.png differs and unnamed-chunk-1-1.png matches — fix now: note entry P9 and a work-log correction.
- diff-bug #2: a rebuild on this Mac writes `bootstrap-445b8638…` while the Windows render committed `bootstrap-172ba59…`, so `docs/` differs by machine. Checked with `git ls-tree` — fix now: note entry P10.
- diff-bug #3: the claim that the only backslashes in `_freeze/` are the data paths is false, because R `\(x)` lambdas and `"\n"` strings add more — fix now: note open question corrected and a work-log correction.
- diff-bug #4: `docs/search.json` now indexes the demographics page, including the drive paths and Table 1 counts that main's published page already shows — follow-up: note entry P11, routed to the "template extraction" row.
- diff-bug #5: the data-free build deletes `docs/data/*.csv` — noted, no change: already P8.
- diff-bug #6: the T3 number check omits feature_descriptives, which also matches — fix now: work-log line.
- diff-bug #7: the ticked criteria and Review section were uncommitted during review — reject, false: they are this review's records, committed at the step-6 checkpoint.
- Return floor: no finding shows a criterion failing, so status stays `review`.
