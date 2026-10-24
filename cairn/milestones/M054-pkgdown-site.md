<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M054: Build a package site with pkgdown

- **Status:** in-progress   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — the package's users read its help pages, guide, and news on the site   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m054-pkgdown-site   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

Publish the package's help pages, guide, and news as a pkgdown site that a
GitHub Actions workflow deploys to the `gh-pages` branch.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:** `_pkgdown.yml` with the site address, Bootstrap 5, and a reference
index in titled groups that lists all nine exported functions, among them
`write_citation()`, `write_zenodo()`, `write_dockerfile()`, and
`check_tools()` (the candidate row). `.github/workflows/pkgdown.yaml`,
which builds the site on pull requests and deploys it to `gh-pages` on
other events. The site address in DESCRIPTION's `URL:` field. Ignore
entries for `_pkgdown.yml`, `docs/`, and `pkgdown/`. One NEWS.md bullet
naming the site address. One DESIGN.md Architecture sentence on the new
workflow.

**Out:** Turning on GitHub Pages for the `gh-pages` branch, and the repo's
website field: the user does both in the repo settings after the merge,
since repo settings are the user's. The template guide `GUIDE.md` as a site
article: it ships inside the template, and no request asks for it on the
package site. A coverage report in CI: the candidate row "Add a test
coverage report to CI".

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: `_pkgdown.yml` at the repo root sets
      `url: https://jmgirard.github.io/supplement/` and Bootstrap 5
      (`template: bootstrap: 5`), and its `reference:` index has titled
      groups that name, by topic name, each topic of the `man/*.Rd` files
      that `list.files("man", "\\.Rd$")` returns.
      `Rscript -e 'pkgdown::check_pkgdown()'` exits 0 and prints
      "No problems found."
- [ ] AC2: `Rscript -e 'pkgdown::build_site(preview = FALSE)'` finishes
      with no error and writes `docs/index.html`,
      `docs/reference/index.html`, `docs/articles/publishing.html`,
      `docs/news/index.html`, and one `docs/reference/<name>.html` for each
      `man/<name>.Rd` file that `list.files("man", "\\.Rd$")` returns.
- [ ] AC3: `.github/workflows/pkgdown.yaml` parses as YAML and runs on
      pull requests, on pushes to `main`, on published releases, and on a
      manual run. It has one job. A step of that job builds the site with
      pkgdown, and its deploy step pushes `docs/` to the `gh-pages` branch
      and carries `if: github.event_name != 'pull_request'`. The workflow's
      default permission is `read-all`, and the job gets `contents: write`.
- [ ] AC4: DESCRIPTION's `URL:` field lists
      `https://jmgirard.github.io/supplement/` before
      `https://github.com/jmgirard/supplement`. `.Rbuildignore` holds the
      lines `^_pkgdown\.yml$`, `^docs$`, and `^pkgdown$`, and `.gitignore`
      holds `/docs/`, so `git status --porcelain` lists no path under
      `docs/` after AC2's build. NEWS.md has one bullet that names
      `https://jmgirard.github.io/supplement/`.
- [ ] AC5: `Rscript -e 'devtools::test()'` passes, and
      `Rscript -e 'devtools::check()'` gives 0 errors and 0 warnings, and
      none of its NOTEs names a file or folder this milestone adds.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T1
- AC3 → T2
- AC4 → T1, T3
- AC5 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive
     change is amend-via-gate. -->

- [x] T1: Write `_pkgdown.yml`: `url:`, `template: bootstrap: 5`, and a
      `reference:` index with four titled groups: making a site
      (`create_supplement`, `add_report`, `add_data`), checking tools and
      sites (`check_tools`, `check_supplement`), releasing
      (`release_supplement`, `write_citation`, `write_zenodo`), and running
      reports in a container (`write_dockerfile`). Set no `development:`
      mode, so the build writes to `docs/`. Put the site address
      first in DESCRIPTION's `URL:`. Add the three `.Rbuildignore` lines
      and `/docs/` to `.gitignore`. Run `pkgdown::check_pkgdown()` and
      `pkgdown::build_site(preview = FALSE)`, then `git status --porcelain`.
- [x] T2: Add `.github/workflows/pkgdown.yaml` from the r-lib/actions v2
      pkgdown example: `actions/checkout@v7` as in `R-CMD-check.yaml`,
      `permissions: read-all` at the top, `contents: write` on the job, a
      concurrency group, `extra-packages: any::pkgdown, local::.`,
      `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)`,
      and `JamesIves/github-pages-deploy-action` to `gh-pages` with
      `clean: false`, skipped on pull requests. No Quarto setup step: the
      vignette's code blocks are not evaluated and no help example renders.
      Check that it parses with `yaml::read_yaml()`, which reads the `on:`
      key as `"TRUE"` (YAML 1.1).
- [x] T3: Add a NEWS.md bullet: DESCRIPTION's `URL:` field now names the
      package site, which holds the help pages, the publishing guide, and
      the news (written against T1's build). Add one sentence on the
      pkgdown workflow to DESIGN.md Architecture, beside the
      `R-CMD-check.yaml` paragraph.
- [ ] T4: Run `devtools::document()` (no diff expected), `devtools::test()`,
      and `devtools::check()`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-24: created by /milestone-plan.
- 2026-10-24: tier check: not run — work named at the question set
- 2026-10-24: question set: which candidate to build — the pkgdown package site
- 2026-10-24: question set: how to publish the site — a workflow that pushes a `gh-pages` branch after merge; the user turns on Pages in the repo settings
- 2026-10-24: checkpoint: plan written; the criteria audit (fresh Opus reader, full mode) is running and its findings are not yet applied
- 2026-10-24: idea vet: found no concern; pkgdown is the R-package convention for a documentation site, and the vignette's code blocks and the help examples run without Quarto, so the build needs no Quarto setup
- 2026-10-24: collision check: absorbs candidate row "Build a package site with pkgdown"; no archived milestone or D-entry covers a package site; D-016 and D-020 cover only `R-CMD-check.yaml`, which this workflow leaves as it is
- 2026-10-24: inbox sweep: 0 open issues and 0 open PRs on jmgirard/supplement
- 2026-10-24: lessons used: none
- 2026-10-24: plan gate chose a workflow deploy to `gh-pages` over a config-only site because the user chose publishing at the question set; falsified by the deploy failing on GitHub or the user not wanting a public site
- 2026-10-24: plan chose to install pkgdown in the workflow (`extra-packages: any::pkgdown`) over a `Config/Needs/website` field or a Suggests entry, so DESCRIPTION's dependencies do not change; falsified by the workflow failing to find pkgdown
- 2026-10-24: criteria audit (full mode, fresh Opus reader): AC1 named the checker's meaning rather than the config, and a broad selector could pass the check, so AC1 now requires each `man/*.Rd` topic by name and the "No problems found." line; AC3 described the run-time push, which only shows after merge, so it now states the `if:` condition, and "build job" became the workflow's one job; AC3's suggested CI-build clause was not added, because the PR opens only after the merge approval and the merge wait already blocks a red run; AC5 found the gate's changelog rule in conflict with the declined NEWS entry, so a NEWS bullet moved into Scope, AC4, and T3; AC2's development-mode caveat went into T1 and the `on:` key note into T2; AC2, AC4, AC5 otherwise no finding
- 2026-10-24: changelog: one NEWS.md bullet naming the site address, decided after the criteria audit
- 2026-10-24: implement: set in-progress, branch m054-pkgdown-site cut from main at 85da5c9
- 2026-10-24: T1 done: `_pkgdown.yml` with four reference groups, site address first in `URL:`, ignore entries; `check_pkgdown()` printed "No problems found.", `build_site(preview = FALSE)` exited 0 and wrote all nine reference pages, and `git status --porcelain` listed nothing under `docs/`; pandoc printed deprecation warnings for `--mathml` and `--mathjax`, which pkgdown passes and which change no output
- 2026-10-24: T2 done: `.github/workflows/pkgdown.yaml` from the r-lib/actions v2 example (fetched 2026-10-24), with `actions/checkout@v7` and `use-public-rspm: true` as in `R-CMD-check.yaml`, push trigger on `main` only, and the deploy action kept at its pinned v4.8.0 commit; `yaml::read_yaml()` parses it (triggers under `TRUE`: push, pull_request, release, workflow_dispatch), with `read-all` default, one job with `contents: write`, and the deploy step's `if:`; actionlint is not installed, so the first CI run is the workflow's first execution
- 2026-10-24: T3 done: NEWS.md bullet naming the site and what T1's build put on it (`reference/`, `articles/publishing.html`, `news/index.html`); DESIGN.md Architecture sentence on the pkgdown workflow after the CI paragraph
- 2026-10-24: claim audit: 10 claims read, 2 corrected (workflow header said Pages serves gh-pages, NEWS said the package has a website; both now name the address without saying it is live) — .github/workflows/pkgdown.yaml, NEWS.md; the re-read held both, and the agent then narrowed the new step's comment, which listed too few of pkgdown's skipped names, to a pointer
- 2026-10-24: implement: the claim auditor found that pkgdown's `package_mds()` turns the tracked `CLAUDE.md` into `docs/CLAUDE.html` and has no setting to skip a file, so the workflow runs `rm -f CLAUDE.md` before the build; chosen over moving `CLAUDE.md`, which the repo's cairn setup keeps at the root; DESIGN.md Architecture names the step

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. -->
