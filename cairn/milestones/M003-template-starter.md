# M003: Package skeleton and starter template

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — other authors start sites from this template
- **Branch/PR:** m003-template-starter

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

- [x] AC1: On a clean checkout of the milestone branch, `Rscript -e 'devtools::check()'` reports 0 errors and 0 warnings, and no NOTE contains the text "hidden files".
- [x] AC2: With R, knitr, and rmarkdown installed, in a new empty folder, `quarto use template <local path to inst/template> --no-prompt` and then `quarto render` both exit 0. The folder then holds `.gitignore`, `README.md`, `index.qmd`, `analyses/example.qmd`, `data/example.csv`, `LICENSE.md`, `LICENSE-CC-BY.md`, and `docs/.nojekyll`, and holds no `_gitignore` or `_README.md`.
- [x] AC3: After the AC2 render, the element with `id="quarto-header"` in `docs/analyses/example.html` contains `href="../index.html"`, and `_freeze/analyses/example/` holds at least one file.
- [x] AC4: `quarto inspect` in the AC2 folder reports `.config.execute.freeze` as true and `.config.project["output-dir"]` as `docs`. A full `quarto render` run with R unreachable (environment cleared to `HOME` and `PATH=/usr/bin:/bin`) exits 0, and `docs/analyses/example.html` is then byte-identical to its copy from the AC2 render.
- [x] AC5: In the AC2 folder after `git init`, `git check-ignore analyses/fits/m.rds x.rds` prints both paths. `git check-ignore _freeze/analyses/example/execute-results/html.json docs/index.html data/example.csv` prints nothing and exits 1.
- [x] AC6: The rendered folder's `README.md` states each of these: a render by name always runs that report's code; on the data machine, check the `.rds` fit files before a full render and stage only `_freeze/` and `docs/`; call `set.seed(` before random draws such as `pp_check`; publish from one machine; a page leaves site search with `search: false`; a build with the data deleted is never published. `index.qmd` tells the user to run `quarto render` once before the first commit.
- [x] AC7: On this Mac, with quarto on PATH, `Rscript -e 'devtools::test()'` reports 0 failures and 0 skips.

## Coverage

- AC1 → T1, T7
- AC2 → T2, T3, T4
- AC3 → T2, T4
- AC4 → T2, T4
- AC5 → T2, T3, T4
- AC6 → T6
- AC7 → T4, T5

## Tasks

- [x] T1: Package skeleton: DESCRIPTION (`supplement`, Authors@R with Jeffrey M. Girard and ORCID 0000-0002-7359-3746, `License: MIT + file LICENSE`, Suggests per D-005, `Config/testthat/edition: 3`), LICENSE, LICENSE.md, NAMESPACE, NEWS.md, and `.Rbuildignore` entries. No exported function yet.
- [x] T2: Template files in `inst/template/` from the pilot branch: `_quarto.yml` (render list, `freeze: true`, `output-dir: docs`, Analyses menu, `resources: data/*.csv`, the two scripts), `index.qmd` with placeholder text, `analyses/example.qmd` (an R chunk over `../data/example.csv`, with a seeded random draw), `data/example.csv`, `LICENSE.md`, `LICENSE-CC-BY.md`, `_gitignore`.
- [x] T3: `_scripts/setup.ts` (pre-render: rename `_gitignore` and `_README.md` when the target is missing, and remove the underscore copy when the target exists) and `_scripts/nojekyll.ts` (post-render: write `.nojekyll` into `QUARTO_PROJECT_OUTPUT_DIR`).
- [x] T4: `tests/testthat/test-template.R`: `skip_on_cran()`, skip when quarto is not on PATH, `withr::local_tempdir()`, and checks for AC2 to AC5.
- [x] T5: Planted-defect check in a scratch copy, one at a time: no rename of `_gitignore`; no rename of `_README.md`; an existing `.gitignore` overwritten; `analyses/*.qmd` dropped from `render:`; a nested `analyses/_quarto.yml`; a changed `output-dir`; freeze removed. Each makes at least one test fail. Record the results in the work log.
- [x] T6: Write `_README.md` with the AC6 facts, and the first-render note in `index.qmd`.
- [x] T7: Repository `README.md` with the `quarto use template jmgirard/supplement/inst/template` route, a NEWS.md entry, then `devtools::check()`.

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
- 2026-10-18: T1 done: DESCRIPTION (maintainer email jmgirard@ku.edu, the contact address on the published pilot sites), LICENSE and LICENSE.md (MIT, unchanged legal text), an empty NAMESPACE, NEWS.md, `tests/testthat.R`, and `.Rbuildignore` entries. No R code yet, so `R/` is absent.
- 2026-10-18: T2 done: `inst/template/` holds `_quarto.yml`, `index.qmd` (placeholders and the first-render callout), `analyses/example.qmd` (seeded bootstrap over `data/example.csv`), `data/example.csv`, `LICENSE.md`, `LICENSE-CC-BY.md`, and `_gitignore`. Footer and GitHub links use an `OWNER/REPO` placeholder, because relative links to repo files break on pages in `analyses/`.
- 2026-10-18: T3 done: `_scripts/setup.ts` and `_scripts/nojekyll.ts`, wired as `pre-render` and `post-render` in `_quarto.yml`. Hand run in a scratch folder: `quarto use template <local inst/template> --no-prompt` copied 9 files, and `quarto render` exited 0 and left `.gitignore`, `README.md`, `docs/.nojekyll`, and `_freeze/analyses/example/`, with no underscore copies.
- 2026-10-18: T4 done: `helper-template.R` builds one rendered site per run, and `test-template.R` has 6 tests (setup files, navbar header and freeze output, `quarto inspect`, a no-R render compared byte for byte, `git check-ignore`, an existing `.gitignore` kept). `devtools::test()`: 0 failures, 0 skips, 19 passes. `_README.md` was written now, ahead of T6, because AC2 needs `README.md`. Found: Quarto appends `/.quarto/` and `**/*.quarto_ipynb` to an existing `.gitignore`, so that test checks the first line and the absence of template entries. `quarto inspect` is read with regular expressions, because jsonlite is not a granted dependency.
- 2026-10-18: T5 done (scratchpad `plant.sh`, one defect per repo copy, each changing 1 file): no `_gitignore` rename → 4 fail; no `_README.md` rename → 2 fail; existing `.gitignore` overwritten → 2 fail; `analyses/*.qmd` dropped from `render:` → 2 fail; changed `output-dir` → 4 fail; freeze removed → 4 fail. A nested `analyses/_quarto.yml` → 0 fail, because Quarto ignores a `_quarto.yml` nested inside a project and the page still had its navbar, so that probe plants no defect. The pilot's navbar loss came from rendering outside the project, which the dropped-render probe covers.
- 2026-10-18: T6 done: `_README.md` (written during T4) states each AC6 fact, and `index.qmd` carries the first-render callout from T2.
- 2026-10-18: T7 done: repository README.md with the `quarto use template` route. NEWS.md heading changed to `# supplement 0.0.0.9000`, because R could not read "(development version)" as a version. `devtools::check()`: 0 errors, 0 warnings, 0 notes.
- 2026-10-18: minor amendment to T3: `setup.ts` now appends the template's missing `.gitignore` lines to an existing `.gitignore` instead of discarding them. The claim audit showed that Quarto writes its own `.gitignore` before pre-render in a git repository, so `git init` before the first render left `*.rds` unignored. New tests: rules added to an existing `.gitignore`, `git init` before the first render, an existing README.md kept. The `git init` test fails on the old script (checked in a scratch copy). Tests 27 passed, check 0/0/0.
- 2026-10-18: claim audit: 30 claims read, 5 corrected — README.md, DESCRIPTION, inst/template/index.qmd, inst/template/_README.md, inst/template/LICENSE-CC-BY.md, inst/template/_scripts/setup.ts. The re-read of the 7 corrected or unverifiable claims found 0 wrong.
- 2026-10-18: all tasks done; status set to review.

## Decisions

## Review

- Sync: origin/main is 5726f3d, an ancestor of the branch. Copilot round off.
- AC1 evidence (2026-10-18): fresh `git clone --branch m003-template-starter` at 958d968 into the scratchpad. `devtools::check()` there: 0 errors, 0 warnings, 0 notes, and "checking for hidden files and directories ... OK".
- AC2 evidence (2026-10-18, scratchpad `m003-evidence.sh` on the clean clone's `inst/template`): `quarto use template … --no-prompt` exit 0, `quarto render` exit 0. All 8 listed files present, and `_gitignore` and `_README.md` absent.
- AC3 evidence (2026-10-18): in `docs/analyses/example.html` the `<header id="quarto-header">` element was found and contains `href="../index.html"`. `_freeze/analyses/example/` holds 2 files.
- AC4 evidence (2026-10-18): `quarto inspect` parsed as JSON gives `config.execute.freeze` True and `config.project.output-dir` docs. A full render under `env -i HOME=… PATH=/usr/bin:/bin` exited 0, and `cmp` found `docs/analyses/example.html` byte-identical to its AC2 copy.
- AC5 evidence (2026-10-18): after `git init`, `git check-ignore analyses/fits/m.rds x.rds` printed both paths. The second `git check-ignore` printed nothing and exited 1.
- AC6 evidence (2026-10-18): `grep -F` on the rendered folder's `README.md` finds each fact once: "A render by name, such as … always runs that report's code"; "Before a full render, check the `.rds` fit files"; "Stage only `_freeze/` and `docs/`"; "`set.seed(`"; "Render and push the site from one machine"; "`search: false`"; "Never publish a build that ran with the data deleted". `index.qmd` has the callout "Before your first commit" with "Run `quarto render` once in this folder" (line 9).
- AC7 evidence (2026-10-18): `devtools::test()` on this Mac with quarto 1.10.19 on PATH: FAIL 0, WARN 0, SKIP 0, PASS 27.
- Consistency gate (2026-10-18): `cairn_validate.py` all checks passed. r-package slot: no roxygen, so `document()` has nothing to regenerate; NEWS.md has an entry; README.md is plain markdown (no README.Rmd); no pkgdown site; `.Rbuildignore` covers the new top-level files (check gave 0 notes); `devtools::check()` 0/0/0 (AC1).
- spawned: diff-bug, blame-history, prior-review.
- diff-bug #1: `nojekyll.ts` treats only `/`-paths as absolute, but Quarto passes an absolute `QUARTO_PROJECT_OUTPUT_DIR`, so on Windows the write goes to a broken path and every render fails — return floor (load-bearing defect: the user's data machine is Windows).
- diff-bug #2: the merge keeps an existing `docs/` rule, and GitHub's R `.gitignore` template has an active `docs/` rule (line 44, checked), so the site would never be committed — fix now: `_gitignore` ends with `!docs/` and `!_freeze/`.
- diff-bug #3: an existing README.md makes `setup.ts` delete `_README.md` silently, so the guidance is lost — fix now: keep it as `SUPPLEMENT.md`.
- diff-bug #4: `_gitignore` misses `*.rda`, `*.RData`, `*.qs`, `.Renviron`, `.DS_Store`, `.Rapp.history`, `rsconnect/`, `*.knit.md`, `*.utf8.md` — fix now.
- diff-bug #5: in a non-empty folder `quarto use template` offers a subdirectory, which GitHub Pages cannot serve — fix now: README says to answer no inside a clone.
- diff-bug #6: the remote form `jmgirard/supplement/inst/template` was never run, because main has no template yet — follow-up: run it after merge at hygiene, and pinning a tag goes to the new candidate row "template install from GitHub".
- diff-bug #7: the no-R test has no Windows skip, skips on `R` instead of `Rscript`, and a seeded re-run would also give identical bytes — fix now: `skip_on_os("windows")`, skip on `/usr/bin/Rscript` or `/bin/Rscript`, and require unchanged `_freeze/` modification times.
- diff-bug #8: renders need knitr and rmarkdown, which the tests do not skip on — fix now: `skip_if_not_installed()`.
- diff-bug #9: `git check-ignore` reads the global excludes file — fix now: `-c core.excludesFile=<empty file>`.
- diff-bug #10: the shared site uses `tempfile()`, caches a failed render, and is changed by later tests — fix now: each test gets its own copy of the rendered site, and the cache is removed at teardown.
- diff-bug #11: the `_quarto.yml` comment "See README.md" points at nothing — fix now: README section on the scripts.
- diff-bug #12: `resources: data/*.csv` covers CSV only — fix now: `data/**`.
- diff-bug #13: the CC BY scope includes `docs/site_libs`, which holds third-party MIT code — fix now: exclude it.
- diff-bug #14: the merge drops blank lines and can mix line endings — reject, style: git reads the result the same.
- diff-bug #15: `quarto preview` re-runs a report on save — fix now: one README line.
- diff-bug #16: DESIGN.md says nothing is built and the Pure R convention predates D-004; the Review section was uncommitted — fix now for DESIGN.md; the second part rejected, false: committed in f53dc0c.
- blame-history #1: the README never says fit files go in `analyses/fits/` (pilot P1) — fix now.
- blame-history #2: merging into an existing `.gitignore` changed D-004's behavior with no D-entry — fix now: D-006.
- blame-history #3: `.claude/`, `.luarc.json`, and `*.rmarkdown` rules from the pilot were dropped — fix now: added.
- blame-history #4: the pilot's `/src/` leftovers rule was dropped — reject, planned change: new sites have no old `src/` layout, and P7's disposition carries only the fit check and the narrow `git add`.
- blame-history #5: the README drops "needs its data, its fit files, and R" and says nothing about stale pages after a render by name — fix now.
- blame-history #6: the three absorbed candidate rows are still listed — reject, planned change: rows graduate at post-merge hygiene.
- prior-review #1: "freeze re-runs a report whose source changed" — reject, false: in the evidence site, after an edit to `example.qmd`, a full render with R unreachable exited 0 and the new chunk did not run. The README now says so outright (with blame-history #5).
- prior-review #2: "rebuilds without the data" overstates — reject, false: same test.
- prior-review #3: fit file location — fix now, same as blame-history #1.
- prior-review #4: stale `docs/` pages after a render by name — fix now, same as blame-history #5.
