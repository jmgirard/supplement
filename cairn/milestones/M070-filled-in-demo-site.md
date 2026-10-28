# M070: Fill in the demo site

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — readers of the package site see the demo pages, the README, and NEWS
- **Branch/PR:** m070-filled-in-demo-site

## Goal

Make the package site's demo a finished-looking supplement for a made-up study, built in CI from `create_supplement()` and the package's own functions.

## Scope

**In:**

- Demo content in `.github/demo/`: a seeded base R script that simulates the two data files of a made-up diary study of sleep and next-day mood, the body text of three reports (sample description, main model, robustness check), and the values the build writes. The values are made-up authors, ORCID's example iD, an example Zenodo DOI that leads to no record, and its archive link.
- `.github/scripts/build-demo.R`, which still starts from `create_supplement(<temporary folder>, repo = "jmgirard/supplement")` and then acts as an author. It adds the data files with `add_data()` and the reports with `add_report()`, and puts each report's body into its stub. It fills `_supplement.yml` and the two LICENSE files, and puts a note in place of the setup box that says the paper, authors, data, DOI, and archive link are made up. It also rewrites the Archived Version text and removes the template's example report, data file, and figure with their list entries. Then it renders, runs `check_supplement()`, and copies `docs/`. Every replace and remove goes through one helper, which stops unless its text occurs exactly once.
- The README paragraph, the NEWS.md demo bullet (edited, not added), the DESIGN.md demo paragraph, the script's header comment, and the comment on the demo step of `pkgdown.yaml`.

**Out:**

- A fresh-template render beside the demo. The user chose the filled-in demo only.
- A link to a real supplement made with the package. That is a parked candidate row, "Link a real supplement from the README", for when such a site exists.
- New package dependencies. The demo reports use base R only.

## Acceptance criteria

- [ ] AC1: `.github/scripts/build-demo.R` starts the demo from `create_supplement(<temporary folder>, repo = "jmgirard/supplement")`, adds the demo's 3 reports with `add_report()` and its 2 data files with `add_data()`, and renders with `quarto render`. Outside `add_report()`, `add_data()`, and `quarto render`, no call in the script creates a path under `analyses/` or `data/` that did not exist before it, and the simulated data files are written outside the site.
- [ ] AC2: In the output folder of a build, a fixed-string `grep -rl` over every `.html` file finds none of these template texts: `Title of the paper`, `Author, A. A.`, `Your Name, Your Institution`, `Before your first commit`, `show here after you add the values`, `Example Analysis`, `example.csv`, `bootstrap-means`, `Write the report here`, `OWNER/REPO`.
- [ ] AC3: The output folder's `index.html` holds the demo's paper title, citation, and contact, and a note that says the paper, its authors, its data, its DOI, and its archive link are made up for this demo. It also holds an `<img>` whose `src` is `https://zenodo.org/badge/DOI/<demo DOI>.svg` inside a link to `https://doi.org/<demo DOI>`, and a link with the text `Download the archive from Zenodo`. Its report listing table has 3 body rows, and its data table has 2 body rows.
- [ ] AC4: Each of the 3 report pages in the output folder holds at least one code cell with output and a `Computing environment` heading. For each file name that the demo's report text passes to `save_png()`, at least one, the output folder holds `figures/<name>`, and a report page has an `<img>` whose `src` resolves to it. The output folder's `figures/` holds no other file.
- [ ] AC5: The script stops with an error before it makes the output folder in two new cases. One is when `check_supplement()` on the rendered demo site returns a row, or when its `skipped` attribute is not `large-file`, `saved-object`, `ignored-output`. The other is when a template text that the script replaces or removes occurs zero times or more than once. Probes cover zero matches, two matches, and a planted `check_supplement()` row. A build from a clean checkout completes.
- [ ] AC6: A `workflow_dispatch` run of `.github/workflows/pkgdown.yaml` on the milestone branch passes its build job, and the `site` artifact it uploads holds `demo/index.html` with the demo's paper title.
- [ ] AC7: Five texts describe the filled-in demo and name the made-up study: the README paragraph and the NEWS.md bullet that link the demo, the DESIGN.md paragraph on the demo step, the header comment of `build-demo.R`, and the comment on the demo step in `pkgdown.yaml`. The README, NEWS, and DESIGN.md texts name `create_supplement()`, `add_report()`, `add_data()`, and `check_supplement()`. None of the five says that the demo has no edits or shows the template's placeholders.

## Coverage

- AC1 → T2
- AC2 → T1, T2, T3
- AC3 → T1, T2, T3
- AC4 → T1, T2, T3
- AC5 → T2, T3
- AC6 → T5
- AC7 → T2, T4

## Tasks

- [x] T1: Write `.github/demo/`: `simulate.R` (seeded base R, writes `participants.csv` and `diary.csv` into a folder it is given), the three report body files, and the demo values. Each report body reads its data through `file.path(site, "data", ...)`, and at least one saves a paper figure with `save_png()`. The example DOI is well-formed and resolves to no Zenodo record.
- [x] T2: Extend `.github/scripts/build-demo.R`. Add a `replace_once()` helper that stops, naming the file and the text, unless the text occurs exactly once, and route every replace and remove through it. Order the steps as follows. Run `create_supplement()`, then simulate the data into a temporary folder outside the site. Run `add_data()` and `add_report()` before the example entries are removed, because a list left empty may refuse a new item. Put each report body into its stub in place of the "Write the report here" paragraph and the `setup` chunk. Remove the example report, data file, and figure, and their menu and data entries. Fill `_supplement.yml`, the LICENSE files, the setup box, and the Archived Version text. Render twice, since a figure saved under a new name reaches `docs/` only on the next render (D-018). Then stop on any `check_supplement()` row or an unexpected `skipped` value, and copy. Rewrite the header comment.
- [x] T3: Run the build locally into a new folder and read the output for AC2 to AC4 (grep, `index.html`, report pages, `figures/`). Probe AC5 against a temporary install of the package whose template has one edited text, once with the text gone and once with it doubled, and once with a planted `check_supplement()` row. Each probe exits non-zero, and the output folder is absent afterward.
- [x] T4: Edit the README paragraph, the NEWS.md demo bullet, the DESIGN.md demo paragraph, and the demo step comment in `pkgdown.yaml`, written against the T3 build. Run `devtools::test()` and `devtools::check()`.
- [x] T5: Push the branch, run `gh workflow run pkgdown.yaml --ref m070-filled-in-demo-site`, wait for the run, and read the `site` artifact within the day it is kept (AC6).

## Work log

- 2026-10-28: created by /milestone-plan.
- 2026-10-28: tier check: milestone — a change to the CI-built demo, the README, and NEWS that supersedes D-033's choice, so it needs a design decision.
- 2026-10-28: idea vet: three concerns, each answered at the question set. A filled-in demo no longer shows a new site, so it can drift from the template: the user chose the filled-in demo only, and the build still starts from `create_supplement()` and stops when an edited text changes. A made-up DOI leads nowhere: the user chose an example DOI with a note on the home page. Made-up content could be read as real: the home page note says it is made up.
- 2026-10-28: question set: the user asked whether a made-up demo or a link to a real supplement of theirs is better. The answer recommended the built demo, because it stays current with the template, and a real-site link later. The user chose the built demo.
- 2026-10-28: question set: content — a made-up diary study of sleep and mood with simulated data. DOI — an example Zenodo DOI that resolves to no record.
- 2026-10-28: question set: permission for one `gh workflow run pkgdown.yaml` on the milestone branch — granted.
- 2026-10-28: collision check: D-033 chose the unchanged render. D-034 supersedes that choice at the user's request at this plan. M069 (done) shipped the demo step that this extends. No candidate row overlaps.
- 2026-10-28: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-28: criteria audit (full mode, fresh Opus reader): 6 findings, all accepted. D-033 needed superseding, and AC7 now covers the script header and the workflow comment and lists the functions. AC1 now covers paths the script creates. AC3 names the badge markup and body rows. AC4 is bounded to the names passed to `save_png()`, with no other file in `figures/`. AC5 names the `skipped` value and probes zero and two matches for text that is replaced or removed.
- 2026-10-28: plan chose build-time edits of a `create_supplement()` site over a committed demo site source, because the edits track template changes and fail loudly when one breaks them; falsified by template changes that break the demo build often enough to block package-site deploys.
- 2026-10-28: plan chose inserting report bodies into the `add_report()` stubs over copying whole report files, so the `site` chunk and Computing environment section come from the installed template; falsified by `report_lines()` changes that break the insertion on most template edits.
- 2026-10-28: lessons used: 2026-10-28 (M069), 2026-10-28 (M068), 2026-10-21 (M028).
- 2026-10-28: changelog: edit the unreleased NEWS.md demo bullet rather than add a bullet.
- 2026-10-28: T1: wrote `.github/demo/simulate.R` (60 people, 14 days, about 1 in 12 days missed) and three report bodies, each an intro and an analysis part split by an `<!-- analysis -->` line. The demo values live beside their replacements in `build-demo.R`, not in a separate file (minor task edit). The model report saves `figure-1.png` and shows it with a Markdown image, not a second inline plot.
- 2026-10-28: T2: `replace_once()` takes an optional `until`, so a block (the setup box, a YAML value line, the authors list, a stub paragraph) is matched by its start text and the first end text after it, not by its whole wording. The build also runs `write_citation()` and `write_zenodo()` for a site an author would release. It sets `version: "1.0.0"`, the ORCID example iD for the first author, DOI `10.5281/zenodo.0000000`, and archive link `https://zenodo.org/records/0000000`. It leaves `concept-doi` empty because a low record number may be a real record.
- 2026-10-28: T3: local build into a new folder exited 0, and `check_supplement()` returned no rows and skipped the three git checks. All 10 AC2 texts were in 0 `.html` files. `index.html` has the badge `<img>` and the download link. Each report page has `Computing environment`, and `figures/` holds only `figure-1.png`, which `model.html` shows. Probes: a changed setup-box heading (0 copies) and a doubled LICENSE line (2 copies), each in a temporary install, and a planted broken link in a copy of `.github/`. Each exited 1 with its own error, and no output folder was left. A screen check in the preview pane looked right. The report listing sorts by title, so it reads Main, Robustness, Sample.
- 2026-10-28: T4 checkpoint: edited the README paragraph, the NEWS.md demo bullet, the DESIGN.md demo paragraph, and the demo step comment in `pkgdown.yaml`. `devtools::test()`, `devtools::check()`, and `pkgdown::check_pkgdown()` are running. T4 stays open until they pass.
- 2026-10-28: T4: `devtools::test()` 475 tests, 0 failed, 12 skipped. `devtools::check()` 0 errors, 0 warnings, 1 note (local `.claude`). `pkgdown::check_pkgdown()` found no problems.
- 2026-10-28: T5: `workflow_dispatch` run 40620592498 on the branch: build success, deploy skipped. Its `site` artifact holds `demo/index.html` with the paper title "Sleep Duration and Next-Day Mood: A 14-Day Diary Study", the 3 report pages, and `demo/figures/figure-1.png`.
- 2026-10-28: claim audit: 44 claims read, 4 corrected — cairn/DESIGN.md (2), .github/workflows/pkgdown.yaml, .github/demo/analyses/sample.md. The reader also noted that the ORCID example iD, which ORCID keeps for a fictional researcher, reaches `CITATION.cff` and `.zenodo.json` but no demo page. It was kept. The re-read of the corrected claims is pending.
