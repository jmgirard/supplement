# M001: Pilot site restructure to the freeze layout

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** internal — an unmerged proof branch of a companion repo that informs template extraction
- **Branch/PR:** m001-pilot-restructure; companion: /Users/jmgirard/github/pilot-ptsd-markers freeze-layout

## Goal

Move pilot-ptsd-markers, on a branch, to one Quarto website project with freeze on, and show on this Mac that a report page rendered there carries the site navbar.

## Scope

**In:** a `freeze-layout` branch of `~/github/pilot-ptsd-markers`. The five reports move from `src/` to `analyses/` as `.qmd` sources. The hand-copied HTML and `src/_quarto.yml` go away. `_quarto.yml` gets freeze, an Analyses navbar menu, and `docs/` output. `index.qmd` links point to the report pages. A smoke render of `feature_descriptives`, which needs only the shared data. README instructions for the data machine. A push of the branch to GitHub. A findings note in this repo.

**Out:**
- Renders of the model reports and of demographics. These run on the data machine → M002.
- The data-free rebuild check → M002.
- A merge to pilot `main`, a change to the live site, or a new Zenodo release. Not planned. Any later merge is a new candidate.
- Refits on this Mac. The user chose to reuse the fits on the data machine.

## Acceptance criteria

- [x] AC1: On branch `freeze-layout`, `git ls-files analyses` lists the five `analyses/<name>.qmd` files and no `.html` file or `_files/` path, and `git ls-files src` lists nothing.
- [x] AC2: `quarto inspect` at the pilot repo root reports `execute.freeze: true` and `project.output-dir: docs`.
- [x] AC3: After `quarto render analyses/feature_descriptives.qmd` at the repo root, `docs/analyses/feature_descriptives.html` matches `id="quarto-header"`. For each other `analyses/<name>.qmd` that `git ls-files 'analyses/*.qmd'` lists, the page also matches `href="[^"]*<name>\.html"`. `git ls-files _freeze/analyses/feature_descriptives` lists at least one file.
- [x] AC4: The branch README has a section for the data machine. It says that the existing fit files go in `analyses/fits/`, and it gives the render command, `quarto render` at the repo root.
- [x] AC5: `git ls-remote origin refs/heads/freeze-layout` prints the local branch HEAD, and `git ls-remote origin refs/heads/main` prints `54684dc` as the start of its hash.
- [x] AC6: `cairn/references/pilot-port.md` lists every path that `git diff --name-status main...freeze-layout` prints in the pilot repo, with its status letter. It has a Problems section in which each entry gives the problem and its fix.

## Coverage

- AC1 → T2
- AC2 → T3
- AC3 → T4
- AC4 → T5
- AC5 → T6
- AC6 → T7

## Tasks

- [x] T1: In `~/github/pilot-ptsd-markers`, cut branch `freeze-layout` from an up-to-date `main`.
- [x] T2: `git mv src/*.qmd analyses/`. Remove `analyses/*.html`, `analyses/*_files/`, `src/_quarto.yml`, and `src/.gitignore`. Move the fit-file and figure ignores in `.gitignore` from `src/` to `analyses/`.
- [x] T3: Rewrite `_quarto.yml`: render all `.qmd` files, `execute: freeze: true`, `output-dir: docs`, an Analyses navbar menu with the five reports, and `resources` for `data/*.csv` only.
- [x] T4: Point `index.qmd` links at the report pages. Run `quarto render analyses/feature_descriptives.qmd` (a single-file render, so no model report runs). Commit the source changes, `_freeze/analyses/feature_descriptives/`, and `docs/`.
- [x] T5: Rewrite the README reproduce and publish sections. Add a data-machine section: move the fits folder to `analyses/fits/`, set the demographics environment variables, run a full `quarto render`, and commit `_freeze/` and `docs/`.
- [x] T6: Push `freeze-layout` to origin. Leave `main` untouched.
- [x] T7: Write `cairn/references/pilot-port.md` (synthesis note) with its INDEX line.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — restructures a companion repo and needs design choices for the template.
- 2026-10-18: question set: model fits — build the layout on this Mac now, render with the existing fits later on the machine that built v1.1.0.
- 2026-10-18: question set: demographics — rendered on that same machine, with the private data, in M002.
- 2026-10-18: question set: branch fate — push `freeze-layout` to GitHub, no merge, live site and Zenodo unchanged.
- 2026-10-18: plan gate chose reusing the v1.1.0 fits on the data machine over refitting on this Mac because the user asked for it and it keeps the published estimates; falsified by fits on that machine that no longer load under its current brms.
- 2026-10-18: criteria audit (reduced mode, Opus, two passes): first pass flagged an undefined grep loop, a `QUARTO_R` check that proves nothing (Quarto falls back to R on PATH), an unbounded problems list, and "exactly the five". Second pass flagged AC2 as two claims and AC4 missing the `analyses/fits/` path. All fixed in the wording above.
- 2026-10-18: companion branch keeps the name `freeze-layout` that the criteria name, not `m001-pilot-restructure`.
- 2026-10-18: verify slot not applicable: the repo has no R package code yet.
- 2026-10-18: T1-T3 done in the pilot repo (commits "Move report sources into analyses/…" and "Render every report as a site page…"). The navbar splits reports into Tables and Analyses menus, matching the index page. `render:` lists `index.qmd` and `analyses/*.qmd` so README.md is not rendered.
- 2026-10-18: T4 done (pilot 2a4a51e): smoke render exited 0, the page has the header and links to the other four reports, and `_freeze/analyses/feature_descriptives/execute-results/html.json` is tracked. A single-file render does not clean `docs/`, so the old per-report `_files/` copies stay until the full render in M002.
- 2026-10-18: T5 done (pilot f541444): README documents the freeze layout and the data-machine steps. The citation sentence in the README stays over the plain-English length limit because it is a quoted reference.
- 2026-10-18: T6 done: `freeze-layout` pushed to origin at f541444. Origin `main` unchanged at 54684dc.
- 2026-10-18: T7 done: `cairn/references/pilot-port.md` written. Its 122-line path list was compared by script with the diff output and matches.
- 2026-10-18: claim audit: not owed — internal tier.
- 2026-10-18: all tasks done; status set to review.
- 2026-10-18: step-7 approval: m001-pilot-restructure approved for merge. The companion branch `freeze-layout` is not merged and gets no PR, per the branch-fate answer in the question set.

## Decisions

## Review

- Sync: origin/main is 6b2872a, an ancestor of the branch. Copilot round off (no header line in PROFILE.md).
- AC1 evidence (2026-10-18, pilot at f541444): `git ls-files analyses` lists the five `.qmd` files and nothing else, so 0 `.html` and 0 `_files/` paths. `git ls-files src` lists 0 paths.
- AC2 evidence (2026-10-18): `quarto inspect` at the pilot root reports `execute.freeze` True and `project.output-dir` docs.
- AC3 evidence (2026-10-18): fresh `quarto render analyses/feature_descriptives.qmd` exited 0. The page matches `id="quarto-header"` once and has one link each to demographics, verbal_analyses, visual_analyses, and vocal_analyses. `git ls-files _freeze/analyses/feature_descriptives` lists 1 file. The re-render changed only gt's random table ids, and that output was restored to the committed state.
- AC4 evidence (2026-10-18): the README section "Rendering on the data machine" says to move the fit files into `analyses/fits/` (step 1) and gives `quarto render` at the repository root (step 3).
- AC5 evidence (2026-10-18): `git ls-remote origin refs/heads/freeze-layout` prints f541444…, equal to the local HEAD. `refs/heads/main` prints 54684dc….
- AC6 evidence (2026-10-18): a script compared the note's path block with a fresh `git diff --name-status main...freeze-layout`, sorted. All 122 lines match. The Problems section has 6 entries (P1 to P6), and each has a `Fix:` clause.
- Consistency gate (2026-10-18): `cairn_validate.py` all checks passed. Toolchain checks of the r-package slot not applicable: no DESCRIPTION, R/, or man/ yet. No principle changed, so `cairn_impact` skipped.
- spawned: diff-bug (one Opus reviewer, internal-tier docs-only primary diff; it also read the companion diff).
- diff-bug #1: README data-machine steps never check that the fits are in `analyses/fits/`, and brms then refits every model and freeze stores new estimates — fix now.
- diff-bug #2: `.gitignore` no longer ignores old `src/` render leftovers on the data machine, so a blanket add would commit them — fix now.
- diff-bug #3: README "Rendering the site" says a full render needs neither data nor R, which is true only after every report has stored output — fix now.
- diff-bug #4: README License section and LICENSE-CC-BY.md still say the code is in `src/` — fix now.
- diff-bug #5: P3 omits the stale `docs/index.html` and the leftover `docs/src/*.qmd` — fix now in the note.
- diff-bug #6: the index link to `tree/main/analyses` is wrong while the branch is unmerged — reject, planned change: the link is right once the layout reaches main, and no merge is planned now.
- diff-bug #7: a data-free build drops `docs/data/*.csv`, so it must never be published — fix now as a note entry (P7), which feeds the template.
- diff-bug #8: `_freeze` written on Windows may carry backslash paths or CRLF endings — follow-up: added to the note's open questions, which M002 T3 answers.
- diff-bug #9: the note calls its path block the diff output, but the lines are regrouped — fix now.
- diff-bug #10: P5 overstates a problem, because `.html` links also resolve in a website — fix now.
- diff-bug #11: Scope and T3 say "an Analyses navbar menu" but the build adds a Tables menu too — reject, false: the Analyses menu exists, and the added Tables menu is in the work log.
- diff-bug #12: ggsave paper figures in `analyses/` are ignored and unpublished, as before the change — follow-up: new candidate row "paper figure files".
- diff-bug #13: demographics `_freeze` holds only the aggregate tables the old page showed — noted, no defect.
- diff-bug #14: the milestone file had uncommitted edits during review — reject, false: those are this Review section's evidence lines, committed at the step-6 checkpoint.
- Return floor: no finding shows a criterion failing, so status stays `review`.
- Fixes: diff-bug #1 to #4 fixed in pilot 4b620d7 (pushed). Diff-bug #5, #7, #9, and #10 fixed in `pilot-port.md` (P3, P8, path-list heading, P5), with P7 added for #1 and #2. Diff-bug #8 is in the note's Open questions. Diff-bug #12 is the candidate row "paper figure files".
- AC6 re-check after the fixes (2026-10-18): the note's path block matches the fresh diff at 4b620d7, 123 lines. The Problems section has 8 entries, each with a `Fix:` clause.
- AC5 re-check after the fixes (2026-10-18): origin `freeze-layout` is 4b620d7, equal to the local HEAD. Origin `main` is still 54684dc.
