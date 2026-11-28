# M003: Package skeleton and starter template

**Status:** done (2026-10-18, PR #3 https://github.com/jmgirard/supplement/pull/3)

**Goal:** Ship a Quarto website template inside a minimal R package, so that one `quarto use template` command and one render give a site with the navbar on every report page and freeze on.

**Outcome:** R package `supplement` 0.0.0.9000 with no R code yet (Suggests: knitr, rmarkdown, testthat, withr). The template is in `inst/template/`: `_quarto.yml` (`freeze: true`, `docs/` output, Analyses menu, `data/**` resources), placeholder `index.qmd`, a seeded `analyses/example.qmd` over `data/example.csv`, MIT and CC BY 4.0 license files, `_gitignore`, and `_README.md`. `_scripts/setup.ts` (pre-render) renames `_gitignore` and `_README.md`, merges missing rules into an existing `.gitignore` ending with `!docs/` and `!_freeze/`, and writes the guide to `SUPPLEMENT.md` beside an existing README. `_scripts/nojekyll.ts` (post-render) writes `.nojekyll` into Quarto's absolute output path. 48 tests build sites in temporary folders. After the merge, `quarto use template jmgirard/supplement/inst/template` from GitHub copied the 10 template files and rendered with exit 0.

**Decisions:** D-001 (docs/ on main), D-002 (freeze true), D-003 (template in inst/template), D-004 (rename on first render), D-005 and D-007 (Suggests only), D-006 (merge into existing files).

**Review:** two passes, three reviewers each, plus two claim audits. One defect return: `nojekyll.ts` broke every render on Windows (fixed, T8). 32 more findings fixed on the branch, among them `.gitignore` rules hidden by GitHub's R template `docs/` rule, case-sensitive object rules on Linux, a silently dropped guide, and test isolation. Follow-ups: "template install from GitHub" (now the tag part only) and "Windows check". 7 findings rejected with reasons. The "site output location", "freeze level", and "extension packaging" rows graduated, and "template extraction" narrowed to M004.
