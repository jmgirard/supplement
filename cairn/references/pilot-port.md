# Pilot port of pilot-ptsd-markers to the freeze layout (M001, M002)

**Provenance.** Ingested 2026-10-18 by M001, extended by M002. Source: the port of `~/github/pilot-ptsd-markers` on branch `freeze-layout` (commits 63a8adb, c638e1f, 2a4a51e, f541444, 4b620d7 in this session, and dddad4a, the user's render on the data machine).
Pagination: —.
Extraction: first-hand record, nothing to re-verify against — observed 2026-10-18.

**Scope.** This page records what the port changed and the problems met, as input to template extraction. It is a reference, not an authority. Status lives in `ROADMAP.md`, decisions in `DECISIONS.md`, and architecture in `DESIGN.md`.

**Evidence snapshot.**

- Pilot branch `freeze-layout` at dddad4a on origin. Origin `main` is still 54684dc — observed 2026-10-18.
- The user reported no problems from the data-machine render — observed 2026-10-18.

## Paths changed

The lines that `git diff --name-status main...origin/freeze-layout` prints in the pilot repo at dddad4a, with tabs shown as spaces. The order is regrouped: lines without a `_files/` path first, then lines with one.

```
M .gitignore
M LICENSE-CC-BY.md
M README.md
A _freeze/analyses/demographics/execute-results/html.json
A _freeze/analyses/feature_descriptives/execute-results/html.json
A _freeze/analyses/verbal_analyses/execute-results/html.json
A _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-8-1.png
A _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-8-2.png
A _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-8-3.png
A _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-8-4.png
A _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-8-5.png
A _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-8-6.png
A _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-8-7.png
A _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-8-8.png
A _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-8-9.png
A _freeze/analyses/visual_analyses/execute-results/html.json
A _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-8-1.png
A _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-8-2.png
A _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-8-3.png
A _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-8-4.png
A _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-8-5.png
A _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-8-6.png
A _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-8-7.png
A _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-8-8.png
A _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-8-9.png
A _freeze/analyses/vocal_analyses/execute-results/html.json
A _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-7-1.png
A _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-7-2.png
A _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-7-3.png
A _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-7-4.png
A _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-7-5.png
A _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-7-6.png
A _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-7-7.png
A _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-7-8.png
A _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-7-9.png
M _quarto.yml
D analyses/demographics.html
R100 docs/src/demographics.qmd analyses/demographics.qmd
D analyses/feature_descriptives.html
R100 docs/src/feature_descriptives.qmd analyses/feature_descriptives.qmd
D analyses/verbal_analyses.html
R100 docs/src/verbal_analyses.qmd analyses/verbal_analyses.qmd
D analyses/visual_analyses.html
R100 docs/src/visual_analyses.qmd analyses/visual_analyses.qmd
D analyses/vocal_analyses.html
R100 docs/src/vocal_analyses.qmd analyses/vocal_analyses.qmd
M docs/analyses/demographics.html
M docs/analyses/feature_descriptives.html
M docs/analyses/verbal_analyses.html
M docs/analyses/visual_analyses.html
M docs/analyses/vocal_analyses.html
M docs/index.html
M docs/search.json
M index.qmd
D src/.gitignore
D src/_quarto.yml
D src/demographics.qmd
D src/feature_descriptives.qmd
D src/verbal_analyses.qmd
D src/visual_analyses.qmd
D src/vocal_analyses.qmd
R100 analyses/verbal_analyses_files/figure-html/unnamed-chunk-1-1.png _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-1-1.png
R100 analyses/verbal_analyses_files/figure-html/unnamed-chunk-7-1.png _freeze/analyses/verbal_analyses/figure-html/unnamed-chunk-7-1.png
R100 analyses/visual_analyses_files/figure-html/unnamed-chunk-1-1.png _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-1-1.png
R100 analyses/visual_analyses_files/figure-html/unnamed-chunk-7-1.png _freeze/analyses/visual_analyses/figure-html/unnamed-chunk-7-1.png
R100 analyses/vocal_analyses_files/figure-html/unnamed-chunk-1-1.png _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-1-1.png
R100 analyses/vocal_analyses_files/figure-html/unnamed-chunk-6-1.png _freeze/analyses/vocal_analyses/figure-html/unnamed-chunk-6-1.png
R100 analyses/demographics_files/libs/clipboard/clipboard.min.js _freeze/site_libs/clipboard/clipboard.min.js
R100 analyses/verbal_analyses_files/libs/tabwid-1.1.3/tabwid.css _freeze/site_libs/tabwid-1.1.3/tabwid.css
R100 analyses/verbal_analyses_files/libs/tabwid-1.1.3/tabwid.js _freeze/site_libs/tabwid-1.1.3/tabwid.js
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
D docs/analyses/demographics_files/libs/bootstrap/bootstrap-215b371544c282197b31c8aa00ce3677.min.css
D docs/analyses/demographics_files/libs/bootstrap/bootstrap-icons.css
D docs/analyses/demographics_files/libs/bootstrap/bootstrap-icons.woff
D docs/analyses/demographics_files/libs/bootstrap/bootstrap.min.js
D docs/analyses/demographics_files/libs/clipboard/clipboard.min.js
D docs/analyses/demographics_files/libs/quarto-html/anchor.min.js
D docs/analyses/demographics_files/libs/quarto-html/popper.min.js
D docs/analyses/demographics_files/libs/quarto-html/quarto-syntax-highlighting-64a204ab8560d761af7679ceaba22944.css
D docs/analyses/demographics_files/libs/quarto-html/quarto.js
D docs/analyses/demographics_files/libs/quarto-html/tabsets/tabsets.js
D docs/analyses/demographics_files/libs/quarto-html/tippy.css
D docs/analyses/demographics_files/libs/quarto-html/tippy.umd.min.js
D docs/analyses/feature_descriptives_files/libs/bootstrap/bootstrap-215b371544c282197b31c8aa00ce3677.min.css
D docs/analyses/feature_descriptives_files/libs/bootstrap/bootstrap-icons.css
D docs/analyses/feature_descriptives_files/libs/bootstrap/bootstrap-icons.woff
D docs/analyses/feature_descriptives_files/libs/bootstrap/bootstrap.min.js
D docs/analyses/feature_descriptives_files/libs/clipboard/clipboard.min.js
D docs/analyses/feature_descriptives_files/libs/quarto-html/anchor.min.js
D docs/analyses/feature_descriptives_files/libs/quarto-html/popper.min.js
D docs/analyses/feature_descriptives_files/libs/quarto-html/quarto-syntax-highlighting-64a204ab8560d761af7679ceaba22944.css
D docs/analyses/feature_descriptives_files/libs/quarto-html/quarto.js
D docs/analyses/feature_descriptives_files/libs/quarto-html/tabsets/tabsets.js
D docs/analyses/feature_descriptives_files/libs/quarto-html/tippy.css
D docs/analyses/feature_descriptives_files/libs/quarto-html/tippy.umd.min.js
M docs/analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-1.png
M docs/analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-2.png
M docs/analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-3.png
M docs/analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-4.png
M docs/analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-5.png
M docs/analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-6.png
M docs/analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-7.png
M docs/analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-8.png
M docs/analyses/verbal_analyses_files/figure-html/unnamed-chunk-8-9.png
D docs/analyses/verbal_analyses_files/libs/bootstrap/bootstrap-215b371544c282197b31c8aa00ce3677.min.css
D docs/analyses/verbal_analyses_files/libs/bootstrap/bootstrap-icons.css
D docs/analyses/verbal_analyses_files/libs/bootstrap/bootstrap-icons.woff
D docs/analyses/verbal_analyses_files/libs/bootstrap/bootstrap.min.js
D docs/analyses/verbal_analyses_files/libs/clipboard/clipboard.min.js
D docs/analyses/verbal_analyses_files/libs/quarto-html/anchor.min.js
D docs/analyses/verbal_analyses_files/libs/quarto-html/popper.min.js
D docs/analyses/verbal_analyses_files/libs/quarto-html/quarto-syntax-highlighting-64a204ab8560d761af7679ceaba22944.css
D docs/analyses/verbal_analyses_files/libs/quarto-html/quarto-syntax-highlighting-bf27225e3a48a9273f3daa8f8e829971.css
D docs/analyses/verbal_analyses_files/libs/quarto-html/quarto.js
D docs/analyses/verbal_analyses_files/libs/quarto-html/tabsets/tabsets.js
D docs/analyses/verbal_analyses_files/libs/quarto-html/tippy.css
D docs/analyses/verbal_analyses_files/libs/quarto-html/tippy.umd.min.js
D docs/analyses/verbal_analyses_files/libs/tabwid-1.1.3/tabwid.css
D docs/analyses/verbal_analyses_files/libs/tabwid-1.1.3/tabwid.js
M docs/analyses/visual_analyses_files/figure-html/unnamed-chunk-8-1.png
M docs/analyses/visual_analyses_files/figure-html/unnamed-chunk-8-2.png
M docs/analyses/visual_analyses_files/figure-html/unnamed-chunk-8-3.png
M docs/analyses/visual_analyses_files/figure-html/unnamed-chunk-8-4.png
M docs/analyses/visual_analyses_files/figure-html/unnamed-chunk-8-5.png
M docs/analyses/visual_analyses_files/figure-html/unnamed-chunk-8-6.png
M docs/analyses/visual_analyses_files/figure-html/unnamed-chunk-8-7.png
M docs/analyses/visual_analyses_files/figure-html/unnamed-chunk-8-8.png
M docs/analyses/visual_analyses_files/figure-html/unnamed-chunk-8-9.png
D docs/analyses/visual_analyses_files/libs/bootstrap/bootstrap-215b371544c282197b31c8aa00ce3677.min.css
D docs/analyses/visual_analyses_files/libs/bootstrap/bootstrap-icons.css
D docs/analyses/visual_analyses_files/libs/bootstrap/bootstrap-icons.woff
D docs/analyses/visual_analyses_files/libs/bootstrap/bootstrap.min.js
D docs/analyses/visual_analyses_files/libs/clipboard/clipboard.min.js
D docs/analyses/visual_analyses_files/libs/quarto-html/anchor.min.js
D docs/analyses/visual_analyses_files/libs/quarto-html/popper.min.js
D docs/analyses/visual_analyses_files/libs/quarto-html/quarto-syntax-highlighting-64a204ab8560d761af7679ceaba22944.css
D docs/analyses/visual_analyses_files/libs/quarto-html/quarto-syntax-highlighting-bf27225e3a48a9273f3daa8f8e829971.css
D docs/analyses/visual_analyses_files/libs/quarto-html/quarto.js
D docs/analyses/visual_analyses_files/libs/quarto-html/tabsets/tabsets.js
D docs/analyses/visual_analyses_files/libs/quarto-html/tippy.css
D docs/analyses/visual_analyses_files/libs/quarto-html/tippy.umd.min.js
D docs/analyses/visual_analyses_files/libs/tabwid-1.1.3/tabwid.css
D docs/analyses/visual_analyses_files/libs/tabwid-1.1.3/tabwid.js
M docs/analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-1.png
M docs/analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-2.png
M docs/analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-3.png
M docs/analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-4.png
M docs/analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-5.png
M docs/analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-6.png
M docs/analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-7.png
M docs/analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-8.png
M docs/analyses/vocal_analyses_files/figure-html/unnamed-chunk-7-9.png
D docs/analyses/vocal_analyses_files/libs/bootstrap/bootstrap-215b371544c282197b31c8aa00ce3677.min.css
D docs/analyses/vocal_analyses_files/libs/bootstrap/bootstrap-icons.css
D docs/analyses/vocal_analyses_files/libs/bootstrap/bootstrap-icons.woff
D docs/analyses/vocal_analyses_files/libs/bootstrap/bootstrap.min.js
D docs/analyses/vocal_analyses_files/libs/clipboard/clipboard.min.js
D docs/analyses/vocal_analyses_files/libs/quarto-html/anchor.min.js
D docs/analyses/vocal_analyses_files/libs/quarto-html/popper.min.js
D docs/analyses/vocal_analyses_files/libs/quarto-html/quarto-syntax-highlighting-64a204ab8560d761af7679ceaba22944.css
D docs/analyses/vocal_analyses_files/libs/quarto-html/quarto-syntax-highlighting-bf27225e3a48a9273f3daa8f8e829971.css
D docs/analyses/vocal_analyses_files/libs/quarto-html/quarto.js
D docs/analyses/vocal_analyses_files/libs/quarto-html/tabsets/tabsets.js
D docs/analyses/vocal_analyses_files/libs/quarto-html/tippy.css
D docs/analyses/vocal_analyses_files/libs/quarto-html/tippy.umd.min.js
D docs/analyses/vocal_analyses_files/libs/tabwid-1.1.3/tabwid.css
D docs/analyses/vocal_analyses_files/libs/tabwid-1.1.3/tabwid.js
R100 analyses/visual_analyses_files/libs/tabwid-1.1.3/tabwid.css docs/site_libs/tabwid-1.1.3/tabwid.css
R100 analyses/visual_analyses_files/libs/tabwid-1.1.3/tabwid.js docs/site_libs/tabwid-1.1.3/tabwid.js
```

## Problems

- P1: The fit files move with the reports. The reports call `file.path("fits", feature)`, and knitr runs each report from its own folder, so the fits must now sit in `analyses/fits/`. Fix: the README data-machine section tells the user to move `src/fits/` there, and `.gitignore` blocks `analyses/fits/`.
- P2: A render by name ignores freeze and runs the report's code. Only a full project render reuses `_freeze/`. Fix: the smoke test renders `feature_descriptives` by name because it needs only the shared data. The README says that a render by name always runs the code.
- P3: A render by name does not clean `docs/`. The old per-report `_files/` copies and the other old report pages stay in `docs/`. So do the old `docs/index.html` with its old navbar and the old `docs/src/*.qmd` copies. `docs/site_libs/bootstrap/` holds two theme files. Fix: the full render on the data machine (dddad4a) cleaned `docs/`. The M002 rebuild left one theme file.
- P4: A glob such as `"*.qmd"` in `render:` can pick up files that are not pages. Fix: `render:` lists `index.qmd` and `analyses/*.qmd`, so `README.md` stays out.
- P5: Home-page links pointed at `analyses/<name>.html`. Those links also resolve in a website project, so this is a choice, not a defect. Fix: they point at `analyses/<name>.qmd`, so Quarto checks them against the source files.
- P6: Git reports some deleted per-report files as renames into `_freeze/` and `docs/site_libs/`. Quarto stores figures and shared libraries there. Fix: none needed. The template `.gitignore` must not block `_freeze/`.
- P7: The data machine keeps old ignored render files in `src/`. Also, a full render with a missing fit file refits that model for hours and stores new estimates. Fix: `.gitignore` blocks `/src/`, and the README data-machine steps check the `.rds` files first and stage only `_freeze/` and `docs/` (4b620d7).
- P8: A build with `data/*.csv` deleted drops `docs/data/*.csv`, so the home-page download buttons break. Fix: none in the pilot, where only M002's test clone deletes the data. A data-free build is a test and must never be published.
- P9: The posterior predictive check figures change on every render, because `pp_check(..., ndraws = 100)` draws without a seed (`analyses/verbal_analyses.qmd:393`, and the same call in the vocal and visual reports). The dddad4a render changed all 27 of them, while the 6 other model figures and every printed number match v1.1.0. Fix: none in the pilot, because a merge is not planned. Seeding the draws (`set.seed()` before each call) makes the figures stable.
- P10: The theme file name depends on the machine. The Windows render wrote `docs/site_libs/bootstrap/bootstrap-172ba59….min.css`, the same name as on main. A rebuild on this Mac, with the same Quarto 1.10.19, writes `bootstrap-445b8638….min.css` and changes the link in every page. Fix: none in the pilot. A site gets one publishing machine, or CI builds `docs/`.
- P11: `docs/search.json` now indexes the demographics page, including the default private drive paths in its code and the Table 1 counts. Main's published page already shows that text, so nothing new is public, but site search now finds it. Fix: none in the pilot. A page can leave the search index with `search: false`.

No problems came from the data-machine render: the user reported none, so this section has no entry for it.

## Disposition

- P1 and P2 → the "template extraction" candidate row: the template README carries both facts.
- P3 → closed by the data-machine render, as M002 shows.
- P4, P5, and P6 → the "template extraction" candidate row: the template `_quarto.yml`, `index.qmd`, and `.gitignore` take these forms.
- P7 → the "template extraction" candidate row: the template README carries the fit check and the narrow `git add`.
- P9, P10, and P11 → the "template extraction" candidate row. The template README tells authors to seed random draws and to publish from one machine. It also shows how to keep a page out of search.
- P8 → the "release checks" candidate row: `check_supplement()` refuses to publish a build that lacks the data files `index.qmd` links to.

## Open questions

- Windows output in `_freeze/` (answered M002, corrected M002 review): `_freeze/` from the data machine holds no CR characters and no user paths. Its backslashes come from the source code, such as the default data paths, R `\(x)` lambdas, and `"\n"` strings. The rebuild on this Mac passed — observed 2026-10-18.
- A re-render by name changes the random table ids that gt writes. Each such render shows a diff in `_freeze/` and `docs/` with no change in results — observed 2026-10-18.
