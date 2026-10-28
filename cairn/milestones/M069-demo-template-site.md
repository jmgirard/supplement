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

- [ ] AC1: With the package installed and Quarto 1.10 on the path, `Rscript .github/scripts/build-demo.R <out>`, run from the repo root for an `<out>` that did not exist, exits 0. `<out>` then lists (`list.files(recursive = TRUE, all.files = TRUE)`) the same relative paths as the `docs/` of a separate `create_supplement(<dir>, repo = "jmgirard/supplement")` and `quarto render` run on the same machine.
- [ ] AC2: When `quarto` is not on the PATH, or `quarto render` exits non-zero after it writes `docs/index.html`, the script exits non-zero and `<out>` (not existing before) holds no `index.html`. Shown by one run with Quarto off the PATH, and one run with a stub `quarto` first on the PATH that writes `docs/index.html` and exits 1.
- [ ] AC3: A run of the pkgdown workflow on the milestone branch (`gh workflow run pkgdown.yaml --ref <branch>`) passes, and its `site` artifact holds `demo/index.html`, `demo/analyses/example.html`, and `demo/data/example.csv`.
- [ ] AC4: In the site that the AC3 run builds, the navbar of `index.html` and of `reference/create_supplement.html` holds a `Demo` link with a relative `href`. Joined to that page's folder, the `href` names `demo/` or `demo/index.html` at the artifact root.
- [ ] AC5: README.md links `https://jmgirard.github.io/supplement/demo/` and says that the demo is the site that `create_supplement()` and one `quarto render` make, with no edits. NEWS.md has one bullet naming the demo.

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
