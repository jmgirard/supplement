<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M038: Write a first-time publishing guide

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a guide that authors read to publish their sites
- **Branch/PR:** m038-publishing-guide

## Goal

A first-time author can follow one guide from an empty folder to a site
served by GitHub Pages and archived on Zenodo with a DOI.

## Scope

**In:** a new vignette `vignettes/publishing.Rmd` ("Publish a supplement
site") with numbered steps and no code that runs at build time;
`VignetteBuilder: knitr` in DESCRIPTION (knitr and rmarkdown are already
in Suggests, D-007), with the ignore entries a built vignette needs; a
link to the vignette from the "Start a new site" part of README.md; one
NEWS.md bullet; one test file, `tests/testthat/test-publishing.R`, that
runs the guide's local steps.

**Out:**
- Shortening README.md or the template guide, or moving their edge cases:
  candidate row "Split the template guide by reader".
- An article page for the vignette on a package site: candidate row
  "Build a package site with pkgdown".
- A pinned tag in the install command: candidate row "Recommend a pinned
  tag in the README" (parked until a release exists).
- Changes to the template guide's own publishing parts ("Make a release",
  "Rendering on the machine with the private data"): they stay as they are.

## Acceptance criteria

- [ ] AC1: `vignettes/publishing.Rmd` walks a first-time author, in
      numbered steps in this order, through: checking the tools with
      `check_tools()`; making a public GitHub repository with no README,
      `.gitignore`, or license, and cloning it; making the site in the
      clone with `create_supplement()` and its `repo` argument; the first
      `quarto render`; the first commit and push; serving the `/docs`
      folder of the pushed branch with GitHub Pages; linking Zenodo to
      GitHub and turning on the repository's switch; replacing the
      template placeholders (the values in `_supplement.yml`, the box in
      `index.qmd`, the year and authors in `LICENSE.md` and
      `LICENSE-CC-BY.md`, and the example report and data) until
      `check_supplement()` finds no problem; the first release with
      `release_supplement()` and the commands it prints; and adding the
      Zenodo DOIs to `_supplement.yml`, rendering again, and pushing.
- [ ] AC2: Every fenced block in `vignettes/publishing.Rmd` opens with
      ```` ```r ```` or ```` ```sh ````, at any indent; the vignette has no
      tilde fence, no code block indented by four spaces, no line that
      matches `^\s*```\s*\{`, and no inline `` `r `` code, so a build runs
      no code. Before its first block the vignette says that `r` blocks run
      in the R console and `sh` blocks in a terminal, and each step names
      the folder its commands run in. `grep -nE '^\s*(```|~~~)'
      vignettes/publishing.Rmd` lists the fences.
- [ ] AC3: The vignette states this rule for rendering again after a report
      changes: render that report by name, then render the whole site, then
      commit the changed report with `_freeze/`, `docs/`, and `figures/`,
      and push.
- [ ] AC4: The vignette's steps for the GitHub Pages source (branch and
      folder), for linking Zenodo to GitHub, and for the repository's
      switch on Zenodo each name the setting and link the GitHub Docs or
      Zenodo help page that describes it.
- [ ] AC5: The guide's local steps, run by `tests/testthat/test-publishing.R`
      in a temporary git repository, give: after `create_supplement()` with
      `repo`, `quarto render`, and a commit, a commit whose tree holds
      `docs/index.html` and `docs/.nojekyll`; after a chunk that prints a
      marker value is added to `analyses/example.qmd` and the value is then
      changed, a full render alone leaves the old value in
      `docs/analyses/example.html`, and a render of that report by name
      followed by a full render shows the new value; and after a version
      DOI is set in `_supplement.yml` and a full render, a
      `docs/index.html` that holds the DOI badge for that DOI.
- [ ] AC6: README.md's "Start a new site" part links
      `vignettes/publishing.Rmd` on GitHub and names
      `vignette("publishing", package = "supplement")`, and NEWS.md has one
      bullet for the guide.
- [ ] AC7: `devtools::check()` builds the vignette and gives 0 errors, 0
      warnings, and 0 notes on the local machine, and the R-CMD-check
      workflow passes on Windows, macOS, and Ubuntu (D-016).

## Coverage

- AC1 → T1, T3
- AC2 → T3
- AC3 → T3
- AC4 → T1, T3
- AC5 → T2
- AC6 → T4
- AC7 → T3, T5

## Tasks

- [x] T1: Read, in the session, the GitHub Docs page on the Pages
      publishing source and the Zenodo help pages on linking accounts and
      enabling a repository; record each setting's label and page URL in
      one work-log line. Where a page states a limit for private
      repositories or for releases made before the switch, the guide
      states it with the link; where none does, the guide claims none.
- [x] T2: Test first. Write `tests/testthat/test-publishing.R`: skip on
      CRAN or without Quarto or git (`skip_if_no_quarto()`,
      `skip_if_no_git()`); `local_plain_git()`, `git init`, then
      `create_supplement(site, repo = "owner/name")` in that folder (as in
      a clone; no `_gitignore` copy, since the first render writes
      `.gitignore`); run each step with the same commands, in the same
      order, as the guide's local steps, through `run_in()` and `git_in()`
      from `long_dir()` folders (LESSONS M018). Read the marker value back
      from the page as LESSONS M028 shows and the badge with
      `doi_badge_rx()`. Show the test red with the render by name left out
      (expect the old value), then green. The test must not skip in CI.
- [ ] T3: Write `vignettes/publishing.Rmd` to AC1 to AC4, with plain
      fenced blocks only; add `VignetteBuilder: knitr` to DESCRIPTION and
      the ignore entries for built vignette output; every claim about the
      package or the template is checked against a same-session read or
      run (derived-claims rule). Build it with `devtools::build_vignettes()`.
- [ ] T4: Link the vignette from README.md's "Start a new site" part (the
      GitHub URL and the `vignette()` call) and add one NEWS.md bullet that
      names only what the guide and its test show.
- [ ] T5: Run `devtools::document()`, `devtools::test()`, and
      `devtools::check()`; push the branch and read the R-CMD-check result
      on all three systems, with the skip list showing the new test ran.

## Work log

- 2026-10-22: created by /milestone-plan.
- 2026-10-22: tier check: not run — work named at the question set.
- 2026-10-22: question set: which candidate to build — "Write a first-time publishing guide".
- 2026-10-22: idea vet: none found; the steps match D-001 (`docs/` on the pushed branch) and the release's placeholder stop (M036), and the guide claims no GitHub or Zenodo limit that their pages do not state.
- 2026-10-22: collision check: absorbs candidate "Write a first-time publishing guide"; "Split the template guide by reader", "Build a package site with pkgdown", and "Recommend a pinned tag in the README" stay as rows, named in Out; archive M031 (renv guide part) and M037 (`check_tools()` account reminders) are done and distinct; D-001, D-002, D-004, D-007 read, none blocks.
- 2026-10-22: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-22: lessons harvested: M009 (bounded criteria, listed tests), M017 (a figure under a new name reaches `docs/` on the next render), M018 (`long_dir()` on Windows), M028 (read a printed value back from `docs/`), M015 (commit settings in a test repository).
- 2026-10-22: plan chose a vignette over a new README.md part or a template-guide part because README.md (198 lines) and the template guide (519 lines) are the length the ease-of-use review flagged, and the template guide becomes the site repository's public README; falsified by evidence that first-time authors who start from README.md do not reach the vignette. Decided by the agent after the question set.
- 2026-10-22: plan chose plain fenced blocks over knitr chunks with `eval = FALSE` because a setup chunk would itself run; falsified by a check NOTE or warning for a vignette with no chunk.
- 2026-10-22: no dependency change: `VignetteBuilder: knitr` names a package already in Suggests (D-007); CI already sets up pandoc.
- 2026-10-22: criteria audit (full mode, fresh Opus reader): 14 findings, all fixed. AC1 gained the placeholder step (the release stops on placeholder rows), "no README, .gitignore, or license", and the pushed branch in place of `main`. AC2 lists fences at any indent and bans tilde fences, indented code, and inline `r` code, and each step names its folder. AC3 commits the changed report and says "this rule". AC4 names its three steps; its private-repository clause was dropped because the GitHub Pages and Zenodo pages read on 2026-10-22 state no plan or private-repository limit, so it moved to T1. AC5 uses an added marker chunk, adds the full-render-alone control, and its test-to-guide match and no-skip rule moved to T2 as instrument properties. AC6 names both link forms. AC7 names local and three-OS CI and drops the repeated test clause.
- 2026-10-22: release tripwire: not hit.
- 2026-10-22: T1: read GitHub Docs "Configuring a publishing source" (Settings > Pages > Build and deployment > Source "Deploy from a branch", branch and folder menus, Save), Zenodo "Linking accounts" (profile menu > Linked accounts > Connect next to GitHub) and "Enable a repository" (profile menu > GitHub > Sync now > repository toggle); none states a private-repository limit or what happens to releases made before the toggle, so the guide claims neither.
- 2026-10-22: T2: `test-publishing.R` passes (18 expectations, about 35 s on the Mac); a planted copy without the second render by name failed on "walk-new" missing and "walk-old" present, and was deleted. The marker is built with `paste0()` so the page holds it only in the chunk's output.

## Decisions

## Review
