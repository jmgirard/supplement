# M001: Pilot site restructure to the freeze layout

**Status:** done (2026-10-18, PR #1 https://github.com/jmgirard/supplement/pull/1)

**Goal:** Move pilot-ptsd-markers, on a branch, to one Quarto website project with freeze on, and show on this Mac that a report page rendered there carries the site navbar.

**Outcome:** Pilot branch `freeze-layout` (4b620d7, pushed, not merged; origin `main` unchanged at 54684dc). The five reports moved from `src/` to `analyses/` as site pages. The hand-copied HTML and `src/_quarto.yml` are gone. `_quarto.yml` sets `execute: freeze: true`, `output-dir: docs`, and Tables and Analyses navbar menus. A smoke render of `feature_descriptives` shows the navbar and links to the other four reports, with its `_freeze/` output tracked. The README has data-machine steps: move fits to `analyses/fits/`, check the `.rds` files, run `quarto render`, and stage only `_freeze/` and `docs/`. Findings are in `cairn/references/pilot-port.md` (P1 to P8).

**Decisions:** none. The companion branch kept the name `freeze-layout`, and the fits are reused on the data machine (both in the plan question set).

**Review:** one Opus diff-bug reviewer, 14 findings. Fixed 9: the README fits check, `/src/` leftovers ignored, freeze wording, license paths, and note corrections. Follow-ups 2: Windows `_freeze` paths go to M002 T3, and paper figures go to the candidate row "paper figure files". Rejected 3: the main-branch link (planned change), the navbar claim (false), and the uncommitted review edits (false). The "freeze-layout pilot port" row narrowed to its M002 remainder.
