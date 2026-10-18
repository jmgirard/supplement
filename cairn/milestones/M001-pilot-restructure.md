# M001: Pilot site restructure to the freeze layout

- **Status:** in-progress
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

- [ ] AC1: On branch `freeze-layout`, `git ls-files analyses` lists the five `analyses/<name>.qmd` files and no `.html` file or `_files/` path, and `git ls-files src` lists nothing.
- [ ] AC2: `quarto inspect` at the pilot repo root reports `execute.freeze: true` and `project.output-dir: docs`.
- [ ] AC3: After `quarto render analyses/feature_descriptives.qmd` at the repo root, `docs/analyses/feature_descriptives.html` matches `id="quarto-header"`. For each other `analyses/<name>.qmd` that `git ls-files 'analyses/*.qmd'` lists, the page also matches `href="[^"]*<name>\.html"`. `git ls-files _freeze/analyses/feature_descriptives` lists at least one file.
- [ ] AC4: The branch README has a section for the data machine. It says that the existing fit files go in `analyses/fits/`, and it gives the render command, `quarto render` at the repo root.
- [ ] AC5: `git ls-remote origin refs/heads/freeze-layout` prints the local branch HEAD, and `git ls-remote origin refs/heads/main` prints `54684dc` as the start of its hash.
- [ ] AC6: `cairn/references/pilot-port.md` lists every path that `git diff --name-status main...freeze-layout` prints in the pilot repo, with its status letter. It has a Problems section in which each entry gives the problem and its fix.

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
- [ ] T4: Point `index.qmd` links at the report pages. Run `quarto render analyses/feature_descriptives.qmd` (a single-file render, so no model report runs). Commit the source changes, `_freeze/analyses/feature_descriptives/`, and `docs/`.
- [ ] T5: Rewrite the README reproduce and publish sections. Add a data-machine section: move the fits folder to `analyses/fits/`, set the demographics environment variables, run a full `quarto render`, and commit `_freeze/` and `docs/`.
- [ ] T6: Push `freeze-layout` to origin. Leave `main` untouched.
- [ ] T7: Write `cairn/references/pilot-port.md` (synthesis note) with its INDEX line.

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

## Decisions

## Review
