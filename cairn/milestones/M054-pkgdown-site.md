<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M054: Build a package site with pkgdown

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
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

- [x] AC1: `_pkgdown.yml` at the repo root sets
      `url: https://jmgirard.github.io/supplement/` and Bootstrap 5
      (`template: bootstrap: 5`), and its `reference:` index has titled
      groups that name, by topic name, each topic of the `man/*.Rd` files
      that `list.files("man", "\\.Rd$")` returns.
      `Rscript -e 'pkgdown::check_pkgdown()'` exits 0 and prints
      "No problems found."
- [x] AC2: `Rscript -e 'pkgdown::build_site(preview = FALSE)'` finishes
      with no error and writes `docs/index.html`,
      `docs/reference/index.html`, `docs/articles/publishing.html`,
      `docs/news/index.html`, and one `docs/reference/<name>.html` for each
      `man/<name>.Rd` file that `list.files("man", "\\.Rd$")` returns.
- [x] AC3: `.github/workflows/pkgdown.yaml` parses as YAML and runs on
      pull requests, on pushes to `main`, on published releases, and on a
      manual run. It has one job. A step of that job builds the site with
      pkgdown, and its deploy step pushes `docs/` to the `gh-pages` branch
      and carries `if: github.event_name != 'pull_request'`. The workflow's
      default permission is `read-all`, and the job gets `contents: write`.
- [x] AC4: DESCRIPTION's `URL:` field lists
      `https://jmgirard.github.io/supplement/` before
      `https://github.com/jmgirard/supplement`. `.Rbuildignore` holds the
      lines `^_pkgdown\.yml$`, `^docs$`, and `^pkgdown$`, and `.gitignore`
      holds `/docs/`, so `git status --porcelain` lists no path under
      `docs/` after AC2's build. NEWS.md has one bullet that names
      `https://jmgirard.github.io/supplement/`.
- [x] AC5: `Rscript -e 'devtools::test()'` passes, and
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
      `clean: false`, skipped on pull requests. A Quarto 1.10.19 setup step
      so the `check_tools()` example on the site finds Quarto (added at
      review; no help example or vignette block renders with Quarto).
      Check that it parses with `yaml::read_yaml()`, which reads the `on:`
      key as `"TRUE"` (YAML 1.1).
- [x] T3: Add a NEWS.md bullet: DESCRIPTION's `URL:` field now names the
      package site, which holds the help pages, the publishing guide, and
      the news (written against T1's build). Add one sentence on the
      pkgdown workflow to DESIGN.md Architecture, beside the
      `R-CMD-check.yaml` paragraph.
- [x] T4: Run `devtools::document()` (no diff expected), `devtools::test()`,
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
- 2026-10-24: T4 done: `devtools::document()` left no diff; `devtools::test()` 391 results, 0 failed, 0 errors, 10 skipped; `devtools::check()` 0 errors, 0 warnings, 1 NOTE for the hidden folder `.claude`, which is untracked, holds no file git lists, and is not added by this milestone; the check started before the NEWS rewording in 739314d, which changed only bullet text
- 2026-10-24: implement complete: status set to review
- 2026-10-24: review checkpoint: AC1 to AC4 verified; AC5's test and check run and the four-lens review are in progress
- 2026-10-24: review: AC5 and the gate verified; 21 findings settled (7 fix now, 5 follow-up into one new row, 9 reject); T2 text updated for the Quarto setup step added at review

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. -->

Review pass 1, 2026-10-24, at e892ae8 (branch contains origin/main 85da5c9; no PR yet; Copilot round off).

- AC1: `_pkgdown.yml` line 1 sets the `url:`, line 4 `bootstrap: 5`; a yaml read gives 4 reference groups, all titled, naming 9 topics, with none missing and none extra against the 9 names from `list.files("man", "\\.Rd$")`; `pkgdown::check_pkgdown()` exited 0 and printed "No problems found."
- AC2: after `rm -rf docs`, `pkgdown::build_site(preview = FALSE)` exited 0 with no "error" in its log and wrote `docs/index.html`, `docs/reference/index.html`, `docs/articles/publishing.html`, `docs/news/index.html`, and 9 of 9 `docs/reference/<name>.html` pages for the `man/*.Rd` files.
- AC3: `yaml::read_yaml()` parses `.github/workflows/pkgdown.yaml`; triggers (under `TRUE`) are push (branches: main), pull_request, release (types: published), and workflow_dispatch; default permissions `read-all`; one job, `pkgdown`, with `contents: write`; step "Build site" runs `pkgdown::build_site_github_pages(...)`; step "Deploy to GitHub Pages" uses the JamesIves deploy action with branch `gh-pages`, folder `docs`, and `if: github.event_name != 'pull_request'`.
- AC4: DESCRIPTION `URL:` lists `https://jmgirard.github.io/supplement/` then `https://github.com/jmgirard/supplement`; `.Rbuildignore` lines 12 to 14 hold the three lines exactly (`grep -xF`); `.gitignore` line 7 is `/docs/`; after AC2's build `git status --porcelain -- docs` printed 0 lines; NEWS.md holds the address once, in the bullet at lines 3 to 6.
- AC5: at fdf1a27's tree, `devtools::test()` gave 391 results, 0 failed, 0 errors, 10 skipped; `devtools::check()` gave 0 errors, 0 warnings, 1 NOTE naming the hidden folder `.claude`, which `git diff --name-only main...HEAD` does not list, so no NOTE names a file or folder this milestone adds.
- Gate: `cairn_validate.py` exit 0, all checks passed; no principle changed, so `cairn_impact` skipped; `devtools::document()` left 0 changed paths in `man/` and `NAMESPACE`; no README.Rmd; `pkgdown::check_pkgdown()` passed (AC1); NEWS.md has the bullet (AC4); the two added top-level files are `.Rbuildignore`d (`.github` already was); `devtools::check()` 0/0/1, the NOTE justified in AC5.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: a local `build_site()` puts `CLAUDE.md` in `docs/` pages, `search.json`, and `sitemap.xml`, while DESIGN.md named only `CLAUDE.html` — fix now (DESIGN.md names all three and says only the workflow's build is for publishing)
- diff-bug #2: `rm -f CLAUDE.md` names one file, so a later agent-notes `.md` would be published — reject, false: no such file is tracked, and pkgdown renders no other extra page today (the reviewer listed the tracked top-level `.md` files)
- diff-bug #3: a manual run started on any branch deploys that branch's site — follow-up, row "Tighten the package site and its deploy"
- diff-bug #4: a release run builds from the tag, so a release from an older tag publishes older pages — follow-up, same row
- diff-bug #5: `clean: false` keeps pages the build no longer makes — follow-up, same row
- diff-bug #6: the first `URL:` entry is dead until Pages is on — reject, planned change: the Scope leaves turning on Pages to the user after merge
- diff-bug #7: the `check_tools()` example on the site would show Quarto missing, since the runner had none — fix now (Quarto 1.10.19 setup step in the workflow)
- diff-bug #8: DESIGN.md's "no help example ... renders" reads as if no example runs — fix now (sentence removed; D-025 holds the Quarto reason)
- diff-bug #9: the README's guide link points to the Rmd on GitHub, which the site's home page shows — follow-up, row "Tighten the package site and its deploy"
- diff-bug #10: NEWS wording "built into a pkgdown website for <url>" reads oddly and lists only three parts — reject, style: wording only, and the bullet claims no full list
- diff-bug #11: the deploy action's handling of a deleted tracked file is untested until the first push to main — reject, false: no defect shown, and the action deploys through its own worktree; the first deploy run is read after the merge
- blame-history #1: no D-entry records the package site's `gh-pages` route, which D-001 rejected for template sites — fix now (D-025)
- blame-history #2: the DESIGN.md addition held decision reasons, ran past one sentence, and joined the R-CMD-check paragraph — fix now (reasons moved to D-025, own paragraph, facts only)
- blame-history #3: the first `URL:` entry is not live at merge — reject, planned change (as diff-bug #6)
- blame-history #4: the NEWS bullet names an address not yet live and an internal detail — reject, planned change: the claim audit reworded it to say the site is built for the address, and the `URL` field is public package metadata
- blame-history #5: `^pkgdown$` ignores a folder that does not exist — reject, planned change: AC4 asks for it, and it covers a `pkgdown/` folder of site assets if one is added
- prior-review: no prior-review evidence, 0 findings
- ripple #1: DESIGN.md's "never runs `git push`" convention now sits beside a workflow that pushes — fix now (the convention says it covers package code and names D-025)
- ripple #2: as diff-bug #8 — fix now (same edit)
- ripple #3: DESIGN.md "the CI workflow does not set it" is ambiguous with two workflows — fix now (names `R-CMD-check.yaml`)
- ripple #4: PROFILE.md says the maintainers' CI never holds `cairn/` — reject, false: that sentence is the guest-mode clause, and this repo runs in owner mode
- ripple #5: README and NEWS give two addresses for the guide — follow-up, row "Tighten the package site and its deploy" (as diff-bug #9)
