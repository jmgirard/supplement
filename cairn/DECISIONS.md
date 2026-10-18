# Decisions

Append-only. Never renumber; supersede with a new entry. D-entries record
choices with rationale — never deferrals ("not now" is a ROADMAP fact).

### D-001 (2026-10-18): New sites render into docs/ on the default branch

**Context:** A site can publish from a committed `docs/` folder or from a `gh-pages` branch built by GitHub Actions.
**Decision:** The template renders into `docs/`, which the author commits and GitHub Pages serves. The user chose this at the M003 plan gate.
**Consequences:** Each Zenodo release archives readable rendered pages. Authors publish from one machine, because the theme file name differs by machine (pilot-port P10).

### D-002 (2026-10-18): Freeze is on for the whole project

**Context:** `freeze: auto` re-runs a report when its source changes, and that re-run fails where the data is absent. The M002 pilot showed that `freeze: true` rebuilds the site with no data and no code runs.
**Decision:** The template sets `execute: freeze: true` at the project level.
**Consequences:** An author re-runs a report by rendering it by name. The template README says so.

### D-003 (2026-10-18): The template lives in inst/template of the package repository

**Context:** Quarto 1.10.19 installs a template or extension from `org/repo/subdir@tag`, so the template need not sit at the repository root.
**Decision:** One repository. The template, with its `_extensions/`, lives in `inst/template/`, where the R package also reads it. There is no build-time copy.
**Consequences:** The install command is `quarto use template jmgirard/supplement/inst/template`. This replaces the scope draft's root-`_extensions/` recommendation.

### D-004 (2026-10-18): Template setup files are renamed on the first render

**Context:** `quarto use template` skips dotfiles, `README.md`, and `LICENSE`, and R CMD check gives a NOTE for hidden files under `inst/`.
**Decision:** The template ships `_gitignore` and `_README.md`. A pre-render script in TypeScript, run by Quarto with no R, renames them when the targets do not exist. A post-render script writes `.nojekyll` into the output folder. The user chose this at the M003 plan gate over two copies of each file and over an R-only setup.
**Consequences:** The "Pure R" convention covers package code only. The template may carry Quarto TypeScript scripts. Users render once before the first commit.

### D-005 (2026-10-18): testthat and withr are suggested dependencies

**Context:** The template needs tests that render it in a temporary folder.
**Decision:** DESCRIPTION lists `testthat (>= 3.0.0)` and `withr` under Suggests, with no Imports. The user granted this at the M003 plan gate.
**Consequences:** Tests skip on CRAN and when quarto is not on PATH.

### D-006 (2026-10-18): Setup merges into existing files and never discards the template's rules (narrows D-004)

**Context:** In a git repository, Quarto writes its own `.gitignore` before pre-render scripts run, and GitHub's R `.gitignore` template ignores `docs/`. D-004's rename alone then left fit files unignored or the site uncommitted.
**Decision:** When `.gitignore` exists, `setup.ts` appends the template's missing lines, and the template's `.gitignore` ends with `!docs/` and `!_freeze/`. When `README.md` exists, the guide goes to `SUPPLEMENT.md`.
**Consequences:** Setup edits an author's existing `.gitignore` by appending only. Existing lines are never removed or reordered.
