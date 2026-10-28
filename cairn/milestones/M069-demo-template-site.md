# M069: Publish a demo of the template site

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — readers of the package site see the demo pages and links
- **Branch/PR:** m069-demo-template-site

## Goal

Publish the site that `create_supplement()` and one `quarto render` make under `demo/` of the package site, linked from the site's navbar and the README.

## Scope

**In:**

- A script, `.github/scripts/build-demo.R`. It makes a site with `supplement::create_supplement(<temp folder>, repo = "jmgirard/supplement")`, runs `quarto render` in it with no edit between the two steps, and copies the site's `docs/` into the folder that its first argument names.
- A step in the `build` job of `.github/workflows/pkgdown.yaml` that runs the script into `docs/demo` after the pkgdown build. The existing artifact upload and deploy job then publish it.
- A `Demo` navbar entry in `_pkgdown.yml`.
- A README sentence and link, and one NEWS.md bullet.
- DESIGN.md's pkgdown paragraph, which names the demo step and states that a failing demo build stops the deploy of the whole package site.

**Out:**

- Example values in `_supplement.yml`, or edits to the demo's pages. The demo shows the template as the two steps make it, with its placeholders and setup box. Filled-in values are new work for a new candidate row.
- Turning on GitHub Pages. The user does it in the repo settings.
- Other site changes, such as a logo or home-page sidebar links. The user did not pick them.

## Acceptance criteria

- [x] AC1: With the package installed and Quarto 1.10 on the path, `Rscript .github/scripts/build-demo.R <out>`, run from the repo root for an `<out>` that did not exist, exits 0. `<out>` then lists (`list.files(recursive = TRUE, all.files = TRUE)`) the same relative paths as the `docs/` of a separate `create_supplement(<dir>, repo = "jmgirard/supplement")` and `quarto render` run on the same machine.
- [x] AC2: When `quarto` is not on the PATH, or `quarto render` exits non-zero after it writes `docs/index.html`, the script exits non-zero and `<out>` (not existing before) holds no `index.html`. Shown by one run with Quarto off the PATH, and one run with a stub `quarto` first on the PATH that writes `docs/index.html` and exits 1.
- [x] AC3: A run of the pkgdown workflow on the milestone branch (`gh workflow run pkgdown.yaml --ref <branch>`) passes, and its `site` artifact holds `demo/index.html`, `demo/analyses/example.html`, and `demo/data/example.csv`.
- [x] AC4: In the site that the AC3 run builds, the navbar of `index.html` and of `reference/create_supplement.html` holds a `Demo` link with a relative `href`. Joined to that page's folder, the `href` names `demo/` or `demo/index.html` at the artifact root.
- [x] AC5: README.md links `https://jmgirard.github.io/supplement/demo/` and says that the demo is the site that `create_supplement()` and one `quarto render` make, with no edits. NEWS.md has one bullet naming the demo.

## Coverage

- AC1 → T1
- AC2 → T1
- AC3 → T2, T4
- AC4 → T2, T4
- AC5 → T3

## Tasks

- [x] T1: Write `.github/scripts/build-demo.R` with a usage comment in the shape of `check-skips.R`. It makes the site in a temporary folder, runs `quarto render` through `system2()`, stops on a non-zero status before any copy, then copies `docs/` (hidden files included) into the folder that the first argument names. Run it locally and compare its listing with a separate render (AC1). Run it once with Quarto off the PATH, calling `Rscript` by its full path where the two share a folder, and once with a stub `quarto` that writes `docs/index.html` and exits 1 (AC2).
- [x] T2: Add a `Build demo site` step after `Build site` in the `build` job of `.github/workflows/pkgdown.yaml`, with a comment, that runs the script into `docs/demo`. Add a `demo` navbar component to `_pkgdown.yml` with a relative `href`, and place it in the navbar structure. Build the pkgdown site locally, run the script into `docs/demo`, and read the `Demo` hrefs on the home page and on a reference page.
- [x] T3: Add the README sentence and link, the NEWS.md bullet, and the demo step to DESIGN.md's pkgdown paragraph, with the deploy trade-off. Write each against the local render.
- [x] T4: Push the branch and start the workflow on it with `gh workflow run pkgdown.yaml --ref <branch>`. Wait for the run, then list its `site` artifact within the day it is kept (AC3) and read the navbar hrefs in it (AC4).

## Work log

- 2026-10-28: created by /milestone-plan.
- 2026-10-28: tier check: not run — work named at the question set.
- 2026-10-28: question set: the user answered "pkgdown website" to the first round, which named an area, so a second round asked about GitHub Pages and the site work. The user picked the demo template site only.
- 2026-10-28: question set: turning on GitHub Pages — the user turns it on in the repo settings. No milestone change to GitHub settings.
- 2026-10-28: idea vet: no concern. A demo made by running `create_supplement()` in CI cannot drift from the template. A demo helps people judge the package before they install it. The placeholder-versus-filled choice is an approach choice, decided below.
- 2026-10-28: plan gate chose the unchanged render (placeholders and setup box shown) over a demo with example values in `_supplement.yml` because it needs no text edits in the build and shows no made-up citation; falsified by readers or the user finding that the placeholder demo does not show what a finished site looks like.
- 2026-10-28: plan gate chose a `demo/` folder inside the package site's build over a separate demo repository or a committed render because it reuses the existing artifact and deploy jobs and adds no built files to commits; falsified by the demo build making the package site's build fail or run past its time limit.
- 2026-10-28: collision check: D-001 covers author sites only, and the demo is rendered in CI and not committed. D-025, D-026, and D-027 stand, since the deploy job does not change. No ROADMAP row or archived milestone covers a demo (M054 to M057 built and hardened the package site).
- 2026-10-28: inbox sweep: 0 open issues and 0 open PRs on jmgirard/supplement.
- 2026-10-28: criteria audit (full mode, fresh Opus reader): 5 findings, all accepted. AC1 compares with a separate render into a new `<out>`. AC2 adds a stub-quarto probe that writes `index.html` and exits 1, since the missing-Quarto probe alone passes a script that ignores the exit status. AC4 accepts a relative `demo/` or `demo/index.html`. AC5 names the render step. The trade-off that a failing demo stops site deploys goes to DESIGN.md (T3), not to a criterion.
- 2026-10-28: test scope: no R code changes, so no testthat tests. Evidence comes from the script runs and the workflow run that the criteria name.
- 2026-10-28: changelog: one NEWS.md bullet, as M054 gave one for the site itself.
- 2026-10-28: lessons used: 2026-10-28 (M068) on pushing tracking commits before the CI wait, 2026-10-27 (M065) on reading check states rather than the exit code of `gh pr checks --watch`.
- 2026-10-28: implement started on branch m069-demo-template-site, cut from main at aada685.
- 2026-10-28: T1 done. The script also stops when `<out>` already exists, so stale files never mix with a new demo. Local runs with the package installed in a scratch library: the output and a separate render list the same 27 paths. Quarto off the PATH exits 1 with "quarto is not on the PATH." A stub `quarto` that writes `docs/index.html` and exits 1 gives exit 1 with "quarto render exited with status 1.", and no `<out>` folder.
- 2026-10-28: T2 done. `_pkgdown.yml` keeps pkgdown's default left navbar items and adds `demo` before `news`, with `href: demo/index.html`. A local `pkgdown::build_site()` plus the script: the home page links `demo/index.html` and `reference/create_supplement.html` links `../demo/index.html`. `pkgdown::check_pkgdown()` found no problems. The build's Pandoc `--mathml` warnings come from pkgdown, not from this change.
- 2026-10-28: T3 done. The README paragraph after the opening one links the demo and names what its home page shows, read from the local render's `demo/index.html` (the setup box, the placeholder title, the example report, and `example.csv`). One NEWS.md bullet. DESIGN.md's pkgdown paragraph names the demo step and the deploy trade-off.
- 2026-10-28: T4 done. Pushed the branch at f39dd89 and ran `gh workflow run pkgdown.yaml --ref m069-demo-template-site` (run 40614339385): build success, deploy skipped. Its `site` artifact holds `demo/index.html`, `demo/analyses/example.html`, and `demo/data/example.csv`. Its `index.html` links `demo/index.html` and `reference/create_supplement.html` links `../demo/index.html`.
- 2026-10-28: claim audit: 16 claims read, 1 corrected — README.md, NEWS.md (the demo sentence now says that `repo` is set, so the GitHub link has no placeholder). The reader also found that a render that exits 0 with no `docs/` gave an empty demo, so the script now stops when `docs/index.html` is missing (a stub `quarto` that exits 0 gives exit 1 and no `<out>`). The usage line now names knitr and rmarkdown. The same reader re-read the corrections once and found them accurate.
- 2026-10-28: verify: `devtools::test()` 475 tests, 0 failed, 0 errors, 12 skipped (macOS). All tasks done, status review.

## Decisions

## Review

- AC1: at 3ffe1d9, with the package installed in a scratch library, `Rscript .github/scripts/build-demo.R <out>` for a new `<out>` exited 0. Its listing and the `docs/` listing of a separate `create_supplement(repo = "jmgirard/supplement")` plus `quarto render` both hold 27 paths, `identical()` TRUE.
- AC2: at 3ffe1d9, with PATH `/usr/bin:/bin` and `Rscript` called by its full path, the script exited 1 with "quarto is not on the PATH." and made no `<out>/index.html`. With a stub `quarto` first on the PATH that writes `docs/index.html` and exits 1, the script exited 1 with "quarto render exited with status 1." and made no `<out>/index.html`.
- AC3: `gh workflow run pkgdown.yaml --ref m069-demo-template-site` at 3ffe1d9, run 40615177027: conclusion success (build success, deploy skipped). Its downloaded `site` artifact holds `demo/index.html`, `demo/analyses/example.html`, and `demo/data/example.csv`.
- AC4: in that artifact, `index.html` has `<a class="nav-link" href="demo/index.html">Demo` and `reference/create_supplement.html` has `<a class="nav-link" href="../demo/index.html">Demo`. Both resolve to `demo/index.html` at the artifact root.
- AC5: README.md:10 links `https://jmgirard.github.io/supplement/demo/`, and README.md:10-11 say the demo is the site that `create_supplement()` and one `quarto render` make, with no edits. NEWS.md has one bullet in the 0.0.0.9000 section naming the demo (NEWS.md:3-6).
- gate: `cairn_validate.py` all checks passed. `devtools::document()` gave no diff. `pkgdown::check_pkgdown()` found no problems. No README.Rmd, so no knit. NEWS.md has the entry. No new top-level file, and `.github` is already in `.Rbuildignore`. No principle changed, so no impact report.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: README.md and NEWS.md link `/demo/`, which 404s until a merge to main deploys it — reject (planned change: the link names the post-merge page, and Pages served the site with 200 on 2026-10-28).
- diff-bug #2: DESIGN.md names only two of the script's stops and leaves out the missing `docs/index.html` and the existing output folder — fix now, fixed 308507a.
- diff-bug #3: a second local run into the same `docs/demo` fails until the folder is deleted — reject (planned change: the script header states that the folder must not exist yet, so stale files never mix with a new demo).
- diff-bug #4: no timeout on the render, so a hung render holds the job up to GitHub's 6-hour limit — fix now (step `timeout-minutes: 15`), fixed 308507a.
- diff-bug #5: `setwd(old)` is not in `on.exit()` — reject (style: the script runs as a top-level Rscript, and an error ends the process).
- diff-bug #6: the temporary site is never deleted — fix now, fixed 308507a.
- diff-bug #7: the `dir.create()` result is not checked — fix now, fixed 308507a.
- diff-bug #8: the demo pages are not in pkgdown's search index or sitemap — reject (planned change: the demo is a separate Quarto site with its own search).
- diff-bug #9: the demo's example report prints the CI runner's R and package versions and R home path — reject (planned change: the demo shows the template's output unchanged, and the template documents what `print_environment()` prints).
- blame-history #1: a failing demo now stops the whole site deploy, against M055's aim that gh-pages match the latest main build, and no D-entry records it — fix now (D-033), fixed 308507a.
- blame-history #2: D-001 rejects gh-pages for template sites, and no D-entry says the demo falls under D-025's package-site exception — fix now (D-033), fixed 308507a.
- blame-history #3: the README paragraph adds detail of the kind M051 moved out of the README — reject (planned change: AC5 asks for the sentence, and the claim audit asked for the `repo` note).
- prior-review #1: the demo step gates the whole site deploy and no D-entry records it — fix now (D-033, same as blame-history #1), fixed 308507a.
- after the fixes, at 308507a: the AC1 run again gave the same 27 paths as the separate render, both AC2 probes again exited 1 with no output folder, and `cairn_validate.py` passed. The changed workflow step has not run on GitHub yet. The PR's pkgdown check runs it before the merge.
- gate: `devtools::check()` at 3ffe1d9, 0 errors, 0 warnings, 1 NOTE (the local `.claude` folder, not in git, as in M054). The later fixes touch only `.github/` and `cairn/`, which `.Rbuildignore` leaves out of the build.
- prior-review #2: the step runs the PR's own script in the build job, whose env holds `GITHUB_PAT` — reject (false as a new risk: that job already installs and runs the PR's package code with the same read-only token, M056).
- prior-review #3: knitr and rmarkdown may not be installed for the script — reject (false: setup-r-dependencies installs Suggests, and run 40615177027 rendered the R report).
- ripple: no ripple evidence.
