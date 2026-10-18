# Pilot port of pilot-ptsd-markers to the freeze layout (M001)

**Provenance.** Ingested 2026-10-18 by M001. Source: the port of `~/github/pilot-ptsd-markers` on branch `freeze-layout` (commits 63a8adb, c638e1f, 2a4a51e, f541444, 4b620d7), done in this session.
Pagination: —.
Extraction: first-hand record, nothing to re-verify against — observed 2026-10-18.

**Scope.** This page records what the port changed and the problems met, as input to template extraction. It is a reference, not an authority. Status lives in `ROADMAP.md`, decisions in `DECISIONS.md`, and architecture in `DESIGN.md`. M002 adds the problems from the data-machine render.

**Evidence snapshot.**

- Pilot branch `freeze-layout` at 4b620d7, pushed to origin. Origin `main` is still 54684dc — observed 2026-10-18.

## Paths changed

The lines that `git diff --name-status main...freeze-layout` prints in the pilot repo at 4b620d7, with tabs shown as spaces. The order is regrouped: source and configuration files first, then the removed per-report files.

```
M .gitignore
M LICENSE-CC-BY.md
M README.md
A _freeze/analyses/feature_descriptives/execute-results/html.json
M _quarto.yml
D analyses/demographics.html
R100 src/demographics.qmd analyses/demographics.qmd
D analyses/feature_descriptives.html
R100 src/feature_descriptives.qmd analyses/feature_descriptives.qmd
D analyses/verbal_analyses.html
R100 src/verbal_analyses.qmd analyses/verbal_analyses.qmd
D analyses/visual_analyses.html
R100 src/visual_analyses.qmd analyses/visual_analyses.qmd
D analyses/vocal_analyses.html
R100 src/vocal_analyses.qmd analyses/vocal_analyses.qmd
M docs/analyses/feature_descriptives.html
M docs/search.json
A docs/site_libs/bootstrap/bootstrap-445b8638c3d06994fee0907d791121c4.min.css
M index.qmd
D src/.gitignore
D src/_quarto.yml
R100 analyses/demographics_files/libs/clipboard/clipboard.min.js _freeze/site_libs/clipboard/clipboard.min.js
D analyses/demographics_files/libs/bootstrap/bootstrap-215b371544c282197b31c8aa00ce3677.min.css
D analyses/demographics_files/libs/bootstrap/bootstrap-icons.css
D analyses/demographics_files/libs/bootstrap/bootstrap-icons.woff
D analyses/demographics_files/libs/bootstrap/bootstrap.min.js
D analyses/demographics_files/libs/quarto-html/anchor.min.js
D analyses/demographics_files/libs/quarto-html/popper.min.js
D analyses/demographics_files/libs/quarto-html/quarto-syntax-highlighting-64a204ab8560d761af7679ceaba22944.css
D analyses/demographics_files/libs/quarto-html/quarto.js
D analyses/demographics_files/libs/quarto-html/tabsets/tabsets.js
D analyses/demographics_files/libs/quarto-html/tippy.css
D analyses/demographics_files/libs/quarto-html/tippy.umd.min.js
D analyses/feature_descriptives_files/libs/bootstrap/bootstrap-215b371544c282197b31c8aa00ce3677.min.css
D analyses/feature_descriptives_files/libs/bootstrap/bootstrap-icons.css
D analyses/feature_descriptives_files/libs/bootstrap/bootstrap-icons.woff
D analyses/feature_descriptives_files/libs/bootstrap/bootstrap.min.js
D analyses/feature_descriptives_files/libs/clipboard/clipboard.min.js
D analyses/feature_descriptives_files/libs/quarto-html/anchor.min.js
D analyses/feature_descriptives_files/libs/quarto-html/popper.min.js
D analyses/feature_descriptives_files/libs/quarto-html/quarto-syntax-highlighting-64a204ab8560d761af7679ceaba22944.css
D analyses/feature_descriptives_files/libs/quarto-html/quarto.js
D analyses/feature_descriptives_files/libs/quarto-html/tabsets/tabsets.js
D analyses/feature_descriptives_files/libs/quarto-html/tippy.css
D analyses/feature_descriptives_files/libs/quarto-html/tippy.umd.min.js
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-1-1.png
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-7-1.png
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-1.png
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-2.png
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-3.png
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-4.png
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-5.png
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-6.png
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-7.png
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-8.png
D analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-9.png
D analyses/verbal_analyses_files/libs/bootstrap/bootstrap-215b371544c282197b31c8aa00ce3677.min.css
D analyses/verbal_analyses_files/libs/bootstrap/bootstrap-icons.css
D analyses/verbal_analyses_files/libs/bootstrap/bootstrap-icons.woff
D analyses/verbal_analyses_files/libs/bootstrap/bootstrap.min.js
D analyses/verbal_analyses_files/libs/clipboard/clipboard.min.js
D analyses/verbal_analyses_files/libs/quarto-html/anchor.min.js
D analyses/verbal_analyses_files/libs/quarto-html/popper.min.js
D analyses/verbal_analyses_files/libs/quarto-html/quarto-syntax-highlighting-64a204ab8560d761af7679ceaba22944.css
D analyses/verbal_analyses_files/libs/quarto-html/quarto-syntax-highlighting-bf27225e3a48a9273f3daa8f8e829971.css
D analyses/verbal_analyses_files/libs/quarto-html/quarto.js
D analyses/verbal_analyses_files/libs/quarto-html/tabsets/tabsets.js
D analyses/verbal_analyses_files/libs/quarto-html/tippy.css
D analyses/verbal_analyses_files/libs/quarto-html/tippy.umd.min.js
D analyses/verbal_analyses_files/libs/tabwid-1.1.3/tabwid.css
D analyses/verbal_analyses_files/libs/tabwid-1.1.3/tabwid.js
D analyses/visual_analyses_files/figure-html/unnamed-chunk-1-1.png
D analyses/visual_analyses_files/figure-html/unnamed-chunk-7-1.png
D analyses/visual_analyses_files/figure-html/unnamed-chunk-8-1.png
D analyses/visual_analyses_files/figure-html/unnamed-chunk-8-2.png
D analyses/visual_analyses_files/figure-html/unnamed-chunk-8-3.png
D analyses/visual_analyses_files/figure-html/unnamed-chunk-8-4.png
D analyses/visual_analyses_files/figure-html/unnamed-chunk-8-5.png
D analyses/visual_analyses_files/figure-html/unnamed-chunk-8-6.png
D analyses/visual_analyses_files/figure-html/unnamed-chunk-8-7.png
D analyses/visual_analyses_files/figure-html/unnamed-chunk-8-8.png
D analyses/visual_analyses_files/figure-html/unnamed-chunk-8-9.png
D analyses/visual_analyses_files/libs/bootstrap/bootstrap-215b371544c282197b31c8aa00ce3677.min.css
D analyses/visual_analyses_files/libs/bootstrap/bootstrap-icons.css
D analyses/visual_analyses_files/libs/bootstrap/bootstrap-icons.woff
D analyses/visual_analyses_files/libs/bootstrap/bootstrap.min.js
D analyses/visual_analyses_files/libs/clipboard/clipboard.min.js
D analyses/visual_analyses_files/libs/quarto-html/anchor.min.js
D analyses/visual_analyses_files/libs/quarto-html/popper.min.js
D analyses/visual_analyses_files/libs/quarto-html/quarto-syntax-highlighting-64a204ab8560d761af7679ceaba22944.css
D analyses/visual_analyses_files/libs/quarto-html/quarto-syntax-highlighting-bf27225e3a48a9273f3daa8f8e829971.css
D analyses/visual_analyses_files/libs/quarto-html/quarto.js
D analyses/visual_analyses_files/libs/quarto-html/tabsets/tabsets.js
D analyses/visual_analyses_files/libs/quarto-html/tippy.css
D analyses/visual_analyses_files/libs/quarto-html/tippy.umd.min.js
D analyses/visual_analyses_files/libs/tabwid-1.1.3/tabwid.css
D analyses/visual_analyses_files/libs/tabwid-1.1.3/tabwid.js
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-1-1.png
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-6-1.png
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-1.png
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-2.png
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-3.png
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-4.png
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-5.png
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-6.png
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-7.png
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-8.png
D analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-9.png
D analyses/vocal_analyses_files/libs/bootstrap/bootstrap-215b371544c282197b31c8aa00ce3677.min.css
D analyses/vocal_analyses_files/libs/bootstrap/bootstrap-icons.css
D analyses/vocal_analyses_files/libs/bootstrap/bootstrap-icons.woff
D analyses/vocal_analyses_files/libs/bootstrap/bootstrap.min.js
D analyses/vocal_analyses_files/libs/clipboard/clipboard.min.js
D analyses/vocal_analyses_files/libs/quarto-html/anchor.min.js
D analyses/vocal_analyses_files/libs/quarto-html/popper.min.js
D analyses/vocal_analyses_files/libs/quarto-html/quarto-syntax-highlighting-64a204ab8560d761af7679ceaba22944.css
D analyses/vocal_analyses_files/libs/quarto-html/quarto-syntax-highlighting-bf27225e3a48a9273f3daa8f8e829971.css
D analyses/vocal_analyses_files/libs/quarto-html/quarto.js
D analyses/vocal_analyses_files/libs/quarto-html/tabsets/tabsets.js
D analyses/vocal_analyses_files/libs/quarto-html/tippy.css
D analyses/vocal_analyses_files/libs/quarto-html/tippy.umd.min.js
D analyses/vocal_analyses_files/libs/tabwid-1.1.3/tabwid.css
D analyses/vocal_analyses_files/libs/tabwid-1.1.3/tabwid.js
```

## Problems

- P1: The fit files move with the reports. The reports call `file.path("fits", feature)`, and knitr runs each report from its own folder, so the fits must now sit in `analyses/fits/`. Fix: the README data-machine section tells the user to move `src/fits/` there, and `.gitignore` blocks `analyses/fits/`.
- P2: A render by name ignores freeze and runs the report's code. Only a full project render reuses `_freeze/`. Fix: the smoke test renders `feature_descriptives` by name because it needs only the shared data. The README says that a render by name always runs the code.
- P3: A render by name does not clean `docs/`. The old per-report `_files/` copies and the other old report pages stay in `docs/`. So do the old `docs/index.html` with its old navbar and the old `docs/src/*.qmd` copies. `docs/site_libs/bootstrap/` holds two theme files. Fix: none in M001. The full render in M002 cleans `docs/`, and M002 AC3 checks that one theme file is left.
- P4: A glob such as `"*.qmd"` in `render:` can pick up files that are not pages. Fix: `render:` lists `index.qmd` and `analyses/*.qmd`, so `README.md` stays out.
- P5: Home-page links pointed at `analyses/<name>.html`. Those links also resolve in a website project, so this is a choice, not a defect. Fix: they point at `analyses/<name>.qmd`, so Quarto checks them against the source files.
- P6: Git reports one deleted per-report library file as a rename into `_freeze/site_libs/`. Quarto stores shared libraries under `_freeze/site_libs/`. Fix: none needed. The template `.gitignore` must not block `_freeze/`.
- P7: The data machine keeps old ignored render files in `src/`. Also, a full render with a missing fit file refits that model for hours and stores new estimates. Fix: `.gitignore` blocks `/src/`, and the README data-machine steps check the `.rds` files first and stage only `_freeze/` and `docs/` (4b620d7).
- P8: A build with `data/*.csv` deleted drops `docs/data/*.csv`, so the home-page download buttons break. Fix: none in the pilot, where only M002's test clone deletes the data. A data-free build is a test and must never be published.

## Disposition

- P1 and P2 → the "template extraction" candidate row: the template README carries both facts.
- P3 → M002 AC3.
- P4, P5, and P6 → the "template extraction" candidate row: the template `_quarto.yml`, `index.qmd`, and `.gitignore` take these forms.
- P7 → the "template extraction" candidate row: the template README carries the fit check and the narrow `git add`.
- P8 → the "release checks" candidate row: `check_supplement()` refuses to publish a build that lacks the data files `index.qmd` links to.

## Open questions

- Output that the data machine writes to `_freeze/` on Windows was not yet read on this Mac. M002 T3 shows whether backslash paths or CRLF line endings break the rebuild — observed 2026-10-18.
- A re-render by name changes the random table ids that gt writes. Each such render shows a diff in `_freeze/` and `docs/` with no change in results — observed 2026-10-18.
