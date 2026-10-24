<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M054: Build a package site with pkgdown

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — the package's users read its help pages, guide, and news on the site   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

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
entries for `_pkgdown.yml`, `docs/`, and `pkgdown/`. One DESIGN.md
Architecture sentence on the new workflow.

**Out:** Turning on GitHub Pages for the `gh-pages` branch, and the repo's
website field: the user does both in the repo settings after the merge,
since repo settings are the user's. The template guide `GUIDE.md` as a site
article: it ships inside the template, and no request asks for it on the
package site. A NEWS.md entry: none, because the installed package does not
change apart from its `URL:` field. A coverage report in CI: the candidate
row "Add a test coverage report to CI".

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [ ] AC1: `_pkgdown.yml` at the repo root sets
      `url: https://jmgirard.github.io/supplement/` and Bootstrap 5
      (`template: bootstrap: 5`), and its `reference:` index lists the help
      topics in titled groups. `Rscript -e 'pkgdown::check_pkgdown()'` exits
      0 with no problem reported, which means pkgdown found every help topic
      in `man/` in the reference index.
- [ ] AC2: `Rscript -e 'pkgdown::build_site(preview = FALSE)'` finishes
      with no error and writes `docs/index.html`,
      `docs/reference/index.html`, `docs/articles/publishing.html`,
      `docs/news/index.html`, and one `docs/reference/<name>.html` for each
      `man/<name>.Rd` file that `list.files("man", "\\.Rd$")` returns.
- [ ] AC3: `.github/workflows/pkgdown.yaml` parses as YAML and runs on
      pull requests, on pushes to `main`, on published releases, and on a
      manual run. Its build step runs pkgdown, and its deploy step pushes
      `docs/` to the `gh-pages` branch only when the event is not a pull
      request. The workflow's default permission is `read-all`, and only
      the build job gets `contents: write`.
- [ ] AC4: DESCRIPTION's `URL:` field lists
      `https://jmgirard.github.io/supplement/` before
      `https://github.com/jmgirard/supplement`. `.Rbuildignore` holds the
      lines `^_pkgdown\.yml$`, `^docs$`, and `^pkgdown$`, and `.gitignore`
      holds `/docs/`, so `git status --porcelain` lists no path under
      `docs/` after AC2's build.
- [ ] AC5: `Rscript -e 'devtools::test()'` passes, and
      `Rscript -e 'devtools::check()'` gives 0 errors and 0 warnings, and
      none of its NOTEs names a file or folder this milestone adds.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T1
- AC2 → T1
- AC3 → T2
- AC4 → T1
- AC5 → T4

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits); substantive
     change is amend-via-gate. -->

- [ ] T1: Write `_pkgdown.yml`: `url:`, `template: bootstrap: 5`, and a
      `reference:` index with four titled groups: making a site
      (`create_supplement`, `add_report`, `add_data`), checking tools and
      sites (`check_tools`, `check_supplement`), releasing
      (`release_supplement`, `write_citation`, `write_zenodo`), and running
      reports in a container (`write_dockerfile`). Put the site address
      first in DESCRIPTION's `URL:`. Add the three `.Rbuildignore` lines
      and `/docs/` to `.gitignore`. Run `pkgdown::check_pkgdown()` and
      `pkgdown::build_site(preview = FALSE)`, then `git status --porcelain`.
- [ ] T2: Add `.github/workflows/pkgdown.yaml` from the r-lib/actions v2
      pkgdown example: `actions/checkout@v7` as in `R-CMD-check.yaml`,
      `permissions: read-all` at the top, `contents: write` on the job, a
      concurrency group, `extra-packages: any::pkgdown, local::.`,
      `pkgdown::build_site_github_pages(new_process = FALSE, install = FALSE)`,
      and `JamesIves/github-pages-deploy-action` to `gh-pages` with
      `clean: false`, skipped on pull requests. No Quarto setup step: the
      vignette's code blocks are not evaluated and no help example renders.
      Check that it parses with `yaml::read_yaml()`.
- [ ] T3: Add one sentence on the pkgdown workflow to DESIGN.md
      Architecture, beside the `R-CMD-check.yaml` paragraph.
- [ ] T4: Run `devtools::document()` (no diff expected), `devtools::test()`,
      and `devtools::check()`.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-24: created by /milestone-plan.
- 2026-10-24: tier check: not run — work named at the question set
- 2026-10-24: question set: which candidate to build — the pkgdown package site
- 2026-10-24: question set: how to publish the site — a workflow that pushes a `gh-pages` branch after merge; the user turns on Pages in the repo settings
- 2026-10-24: checkpoint: plan written; the criteria audit (fresh Opus reader, full mode) is running and its findings are not yet applied

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive; evidence per criterion, consistency-gate
     results, review findings + triage. -->
