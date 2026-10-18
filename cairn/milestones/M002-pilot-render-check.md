# M002: Pilot render on the data machine and data-free rebuild

- **Status:** in-progress
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

- [ ] AC1: For each `analyses/<name>.qmd` that `git ls-files 'analyses/*.qmd'` lists on origin's `freeze-layout`, `git ls-files _freeze/analyses/<name>` lists at least one file.
- [ ] AC2: In a fresh clone of origin's `freeze-layout` with `data/*.csv` deleted, `quarto render` exits 0 and `git status --porcelain _freeze` prints nothing. Each `docs/analyses/<name>.html` for the listed sources matches `id="quarto-header"`, and matches `href="[^"]*<other>\.html"` for every other listed source.
- [ ] AC3: After the AC2 render, `find docs -name 'bootstrap*.min.css'` in the clone returns one file.
- [ ] AC4: The Problems section of `cairn/references/pilot-port.md` has one entry for each `data-machine report:` line in this file's work log. Its path list matches `git diff --name-status main...origin/freeze-layout` run after the user's commits.

## Coverage

- AC1 → T1, T2
- AC2 → T3
- AC3 → T3
- AC4 → T4

## Tasks

- [x] T1: Stop for the user: on the data machine, follow the branch README section, run a full `quarto render`, then commit and push `_freeze/` and `docs/`.
- [x] T2: Fetch origin's `freeze-layout` and run the AC1 listing.
- [ ] T3: Clone it into the scratchpad, delete `data/*.csv`, run a full `quarto render`, then run the AC2 and AC3 checks.
- [ ] T4: Ask the user what went wrong on the data machine and write each problem as a `data-machine report:` work-log line. Add those entries and the new path list to the pilot-port note.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — needs the user's machine and a design check of the freeze layout.
- 2026-10-18: question set: renders of the model reports and demographics happen on the machine that built v1.1.0, with its existing fits and private data.
- 2026-10-18: question set: branch fate — push only, no merge.
- 2026-10-18: criteria audit (reduced mode, Opus): AC1 to AC3 passed. AC4 had no record to check against and an undefined "refreshed". Fixed with `data-machine report:` lines and a named diff command.
- 2026-10-18: T1 done by the user: commit dddad4a "Render all reports" on origin `freeze-layout`, pushed after comparing the demographics page with the live page. Origin `main` still 54684dc. The commit kept `docs/` cleaned of the old `_files/` and `docs/src/` copies.
- 2026-10-18: T2 done: on origin `freeze-layout`, `_freeze/analyses/` holds 1 file each for demographics and feature_descriptives and 12 each for the three model reports. No CR characters in `_freeze/`. The only backslashes are the default Windows data paths already in the demographics source.

## Decisions

## Review
