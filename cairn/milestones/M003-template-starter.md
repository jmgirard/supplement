# M003: Package skeleton and starter template

- **Status:** planned
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — other authors start sites from this template
- **Branch/PR:** —

## Goal

Ship a Quarto website template inside a minimal R package, so that one `quarto use template` command and one render give a site with the navbar on every report page and freeze on.

## Scope

**In:** an R package skeleton (DESCRIPTION, MIT LICENSE, NEWS.md, README.md, testthat). The template in `inst/template/`, extracted from the pilot: `_quarto.yml` with freeze, `docs/` output, and an Analyses navbar menu. A home page with placeholder text, one example report over `data/example.csv`, `LICENSE.md` (MIT), and `LICENSE-CC-BY.md`. `_gitignore` and `_README.md`, with a pre-render script that renames them and a post-render script that writes `.nojekyll` (D-004). Tests that render the template in a temporary folder.

**Out:**
- `_supplement.yml` metadata and the shortcodes for citation, DOI badge, Zenodo download, and data table → M004.
- R functions such as `create_supplement()` → the "scaffolding functions" candidate row.
- A tracked figures folder → the "paper figure files" candidate row.
- A release or a CRAN submission. Not planned.

## Acceptance criteria

- [ ] AC1: On a clean checkout of the milestone branch, `Rscript -e 'devtools::check()'` reports 0 errors and 0 warnings, and no NOTE contains the text "hidden files".
- [ ] AC2: With R, knitr, and rmarkdown installed, in a new empty folder, `quarto use template <local path to inst/template> --no-prompt` and then `quarto render` both exit 0. The folder then holds `.gitignore`, `README.md`, `index.qmd`, `analyses/example.qmd`, `data/example.csv`, `LICENSE.md`, `LICENSE-CC-BY.md`, and `docs/.nojekyll`, and holds no `_gitignore` or `_README.md`.
- [ ] AC3: After the AC2 render, the element with `id="quarto-header"` in `docs/analyses/example.html` contains `href="../index.html"`, and `_freeze/analyses/example/` holds at least one file.
- [ ] AC4: `quarto inspect` in the AC2 folder reports `.config.execute.freeze` as true and `.config.project["output-dir"]` as `docs`. A full `quarto render` run with R unreachable (environment cleared to `HOME` and `PATH=/usr/bin:/bin`) exits 0, and `docs/analyses/example.html` is then byte-identical to its copy from the AC2 render.
- [ ] AC5: In the AC2 folder after `git init`, `git check-ignore analyses/fits/m.rds x.rds` prints both paths. `git check-ignore _freeze/analyses/example/execute-results/html.json docs/index.html data/example.csv` prints nothing and exits 1.
- [ ] AC6: The rendered folder's `README.md` states each of these: a render by name always runs that report's code; on the data machine, check the `.rds` fit files before a full render and stage only `_freeze/` and `docs/`; call `set.seed(` before random draws such as `pp_check`; publish from one machine; a page leaves site search with `search: false`; a build with the data deleted is never published. `index.qmd` tells the user to run `quarto render` once before the first commit.
- [ ] AC7: On this Mac, with quarto on PATH, `Rscript -e 'devtools::test()'` reports 0 failures and 0 skips.

## Coverage

- AC1 → T1, T7
- AC2 → T2, T3, T4
- AC3 → T2, T4
- AC4 → T2, T4
- AC5 → T2, T3, T4
- AC6 → T6
- AC7 → T4, T5

## Tasks

- [ ] T1: Package skeleton: DESCRIPTION (`supplement`, Authors@R with Jeffrey M. Girard and ORCID 0000-0002-7359-3746, `License: MIT + file LICENSE`, Suggests per D-005, `Config/testthat/edition: 3`), LICENSE, LICENSE.md, NAMESPACE, NEWS.md, and `.Rbuildignore` entries. No exported function yet.
- [ ] T2: Template files in `inst/template/` from the pilot branch: `_quarto.yml` (render list, `freeze: true`, `output-dir: docs`, Analyses menu, `resources: data/*.csv`, the two scripts), `index.qmd` with placeholder text, `analyses/example.qmd` (an R chunk over `../data/example.csv`, with a seeded random draw), `data/example.csv`, `LICENSE.md`, `LICENSE-CC-BY.md`, `_gitignore`.
- [ ] T3: `_scripts/setup.ts` (pre-render: rename `_gitignore` and `_README.md` when the target is missing, and remove the underscore copy when the target exists) and `_scripts/nojekyll.ts` (post-render: write `.nojekyll` into `QUARTO_PROJECT_OUTPUT_DIR`).
- [ ] T4: `tests/testthat/test-template.R`: `skip_on_cran()`, skip when quarto is not on PATH, `withr::local_tempdir()`, and checks for AC2 to AC5.
- [ ] T5: Planted-defect check in a scratch copy, one at a time: no rename of `_gitignore`; no rename of `_README.md`; an existing `.gitignore` overwritten; `analyses/*.qmd` dropped from `render:`; a nested `analyses/_quarto.yml`; a changed `output-dir`; freeze removed. Each makes at least one test fail. Record the results in the work log.
- [ ] T6: Write `_README.md` with the AC6 facts, and the first-render note in `index.qmd`.
- [ ] T7: Repository `README.md` with the `quarto use template jmgirard/supplement/inst/template` route, a NEWS.md entry, then `devtools::check()`.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — new package skeleton and a user-facing template, with design choices.
- 2026-10-18: question set: setup files — rename `_gitignore` and `_README.md` on the first render (D-004).
- 2026-10-18: question set: site output — `docs/` on the default branch (D-001).
- 2026-10-18: question set: licenses — MIT for code, CC BY 4.0 for reports, text, and data.
- 2026-10-18: question set: dependencies — testthat and withr in Suggests granted (D-005).
- 2026-10-18: plan gate chose renaming on the first render over two copies of each file because one copy cannot drift; falsified by a Quarto version that skips pre-render scripts during `quarto use template` setup or by users who commit before any render.
- 2026-10-18: plan gate chose `inst/template` in one repository over a separate template repository because Quarto 1.10.19 installs from `org/repo/subdir@tag` (D-003); falsified by a Quarto release that drops subdirectory sources.
- 2026-10-18: freeze level decided as `freeze: true` from the M002 evidence (D-002), absorbing the "freeze level" candidate row. The "site output location" and "extension packaging" rows are absorbed by D-001 and D-003.
- 2026-10-18: criteria audit (full mode, Opus): flagged stray render output under `inst/` for AC1, the GitHub form of `quarto use template` (cannot test a branch) for AC2, a one-member link domain and body-link matches for AC3, open decisions and a missing behavior check for AC4, `git check-ignore` exit semantics and the first-render gap for AC5, "a section on" as a proxy for AC6, and an instrument-bound promise and one-exemplar probes for AC7. All fixed in the wording above; probes moved to T5.
- 2026-10-18: AC4's no-code check changed from deleting `data/example.csv` to hiding R, because M004 makes a missing data file stop the render. A frozen render of the pilot clone with `PATH=/usr/bin:/bin` exited 0 with `_freeze/` unchanged, so the new wording can be met.

## Decisions

## Review
