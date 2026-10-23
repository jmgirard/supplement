<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M038: Write a first-time publishing guide

- **Status:** review
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

- [x] AC1: `vignettes/publishing.Rmd` walks a first-time author, in
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
- [x] AC2: Every fenced block in `vignettes/publishing.Rmd` opens with
      ```` ```r ```` or ```` ```sh ````, at any indent; the vignette has no
      tilde fence, no code block indented by four spaces, no line that
      matches `^\s*```\s*\{`, and no inline `` `r `` code, so a build runs
      no code. Before its first block the vignette says that `r` blocks run
      in the R console and `sh` blocks in a terminal, and each step names
      the folder its commands run in. `grep -nE '^\s*(```|~~~)'
      vignettes/publishing.Rmd` lists the fences.
- [x] AC3: The vignette states this rule for rendering again after a report
      changes: render that report by name, then render the whole site, then
      commit the changed report with `_freeze/`, `docs/`, and `figures/`,
      and push.
- [x] AC4: The vignette's steps for the GitHub Pages source (branch and
      folder), for linking Zenodo to GitHub, and for the repository's
      switch on Zenodo each name the setting and link the GitHub Docs or
      Zenodo help page that describes it.
- [x] AC5: The guide's local steps, run by `tests/testthat/test-publishing.R`
      in a temporary git repository, give: after `create_supplement()` with
      `repo`, `quarto render`, and a commit, a commit whose tree holds
      `docs/index.html` and `docs/.nojekyll`; after a chunk that prints a
      marker value is added to `analyses/example.qmd` and the value is then
      changed, a full render alone leaves the old value in
      `docs/analyses/example.html`, and a render of that report by name
      followed by a full render shows the new value; and after a version
      DOI is set in `_supplement.yml` and a full render, a
      `docs/index.html` that holds the DOI badge for that DOI.
- [x] AC6: README.md's "Start a new site" part links
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

- [x] T1: Read the GitHub Docs page on the Pages publishing source and the
      Zenodo pages on linking accounts and enabling a repository; log each
      setting's label and URL. The guide states a private-repository or
      before-the-switch limit only where a page states one.
- [x] T2: Test first: `tests/testthat/test-publishing.R` skips on CRAN or
      without Quarto or git; `local_plain_git()`, `git init`, then
      `create_supplement(site, repo =)` there (no `_gitignore` copy); the
      guide's local commands in its order through `run_in()`/`git_in()` in
      `long_dir()` folders (LESSONS M018, M028; `doi_badge_rx()`). Red with
      the render by name left out, then green; it must not skip in CI.
- [x] T3: Write `vignettes/publishing.Rmd` to AC1 to AC4 with plain fences;
      `VignetteBuilder: knitr` and built-output ignores; each package or
      template claim checked by a same-session read or run; build it.
- [x] T4: README.md link (GitHub URL and `vignette()` call) and one NEWS.md
      bullet naming only what the guide and its test show.
- [x] T5: `devtools::document()`, `test()`, and `check()`; the three-system
      CI result and skip list are read at review's merge step.

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
- 2026-10-22: T3: vignette written (10 numbered steps plus the render rule, 11 plain fences, no chunk); `VignetteBuilder: knitr` added, `/doc/` and `/Meta/` in `.gitignore`, `vignettes/.gitignore` for `*.html` and `*.R`, and `build_vignettes()` added `^doc$` and `^Meta$` to `.Rbuildignore`. Chose to have step 8 delete the example figure too and to name no place on Zenodo's record page for the concept DOI, since no page read states one. The empty-clone warning was observed with git 2.54.
- 2026-10-22: T4: README.md "Start a new site" opens with the GitHub link and the `vignette()` call (the call works only when vignettes were built at install, which the text says); one NEWS bullet naming the guide and its render rule, both covered by `test-publishing.R`.
- 2026-10-22: claim audit: 50 claims read, 3 corrected — vignettes/publishing.Rmd (step 1 adds Quarto's not-on-path status; step 3 names where the repository and Pages address are written; step 8 separates the four items a release stops on from the example figure and a new README citation item). The re-read found the figure still under item 4, now its own item. Its scratch run of steps 3 to 9 rendered and checked clean.
- 2026-10-22: T5: `devtools::document()` no diff; `devtools::test()` with NOT_CRAN=true: 19 files, 368 expectations, 0 failed, 0 errors, 8 skipped; `devtools::check()` 0 errors, 0 warnings, 0 notes (vignette built and re-built); the vignette rebuilt clean after the claim fixes. Minor amendment: T5's CI read moved to review's merge step, since the git model pushes the branch there.
- 2026-10-22: Tasks section compressed in one rewrite (plan-owned body was 156 lines, cap 150); each task's content kept.

## Decisions

## Review

Evidence (2026-10-22, branch head 6cd9971 for the guide and test; main had not moved).

- AC1: `vignettes/publishing.Rmd` steps 1 to 10 in order: find missing tools (`check_tools()`); make a public repository with no README, `.gitignore`, or license, and clone it; `create_supplement("my-supplement", repo = "owner/name")`; `quarto render`; commit and `git push -u origin HEAD`; Pages from the pushed branch and `/docs`; Zenodo linked accounts and repository switch; replace placeholders until `check_supplement()` finds none; `release_supplement("major")` and its printed commands; DOIs into `_supplement.yml`, render, push. Read by heading and text.
- AC2: `grep -nE '^\s*(```|~~~)'` lists 14 fences (5 ```` ```r ````, 9 ```` ```sh ````, 14 closing), none tilde; 0 lines match `^\s*```\s*\{`, 0 inline `` `r `` code; no 4-space indented code (only 3-space list text). Lines 15-19 say where `r` and `sh` blocks run; every step with commands names its folder (steps 6 and 7 are web settings with no commands). A scratch render by the diff-bug lens ran no code.
- AC3: "Render again after a report changes": render that report by name, render the whole site, commit the changed report with `_freeze/`, `docs/`, and `figures/`, and push, with the commands.
- AC4: step 6 names Settings > Pages > Build and deployment > Source "Deploy from a branch", branch, `/docs`, Save, and links GitHub Docs "Configuring a publishing source"; step 7 item 1 names Linked accounts > Connect and links Zenodo "Linking accounts"; item 2 names GitHub > Sync now > switch and links "Enable a repository".
- AC5: `test-publishing.R` run fresh with NOT_CRAN=true: 18 expectations, 0 failed, 0 skipped, no error (before and after the review fixes). Implement's planted run without the render by name failed on the new value.
- AC6: README.md "Start a new site" links `vignettes/publishing.Rmd` on GitHub and names `vignette("publishing", package = "supplement")`; NEWS.md has one bullet for the guide.
- AC7 (local half): `devtools::check()` 0 errors, 0 warnings, 0 notes, vignette created and re-built; the vignette rebuilt clean after the review fixes. The three-system CI half is read at step 8.

Consistency gate: `cairn_validate.py` all checks passed; `devtools::document()` no diff; no README.Rmd, no pkgdown site; NEWS.md bullet present with no milestone number; new top-level paths `doc`/`Meta` are in `.Rbuildignore` and check gave no NOTE; no principle changed (`cairn_impact` skipped).

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: after step 10, `CITATION.cff` has no DOI and `check_supplement()` gives a doi-mismatch row — fix now (step 10 runs `write_citation(overwrite = TRUE)`; a scratch run then gave 0 doi rows), fixed 6cd9971
- diff-bug #2: `pak::pak()` builds no vignettes, so `vignette("publishing")` can be missing — reject, planned change: AC6 names both forms and the README states the condition beside the GitHub link
- diff-bug #3: a first HTTPS push asks for a password that GitHub refuses — fix now (step 5 gives `gh auth login` and `gh auth setup-git`), fixed 6cd9971
- diff-bug #4: `git commit` stops when `user.name`/`user.email` are unset — fix now (step 5 gives the two `git config --global` lines), fixed 6cd9971
- diff-bug #5: `git add ... figures` stops with "pathspec 'figures' did not match" on a clone with no `figures/` after the example figure is deleted — fix now (step 8 keeps the figure until a report saves its own), fixed 6cd9971
- diff-bug #6: step 1 assumes pak is installed — fix now (`install.packages("pak")`), fixed 6cd9971
- diff-bug #7: deleting the example report leaves `_freeze/analyses/example/` committed — fix now (step 8 deletes it), fixed 6cd9971
- diff-bug #8: the site address is wrong for a repository named `owner.github.io` — fix now (step 6 gives `https://owner.github.io/`), fixed 6cd9971
- diff-bug #9: the badge check repeats `test-shortcodes.R` — reject, planned change: AC5 names it as part of the walk
- diff-bug #10: the test does not run steps 8 and 9 — reject, planned change: AC5's scope
- diff-bug #11: two lines past the wrap width — reject, style
- diff-bug #12: the CI half of AC7 is not yet verified — reject, planned change: T5 reads it at the merge step
- blame-history #1: same as diff-bug #5 — fix now, fixed 6cd9971
- blame-history #2: the guide serves the pushed branch where D-001 and the row said `main` — reject, planned change: AC1 wording from the criteria audit; a fresh clone is on the default branch
- blame-history #3: seven renders add CI time, unlike D-020's Windows cuts — reject, planned change: AC5 and T2 require the test to run in CI (about 35 s on the Mac)
- blame-history #4: same as diff-bug #1 — fix now, fixed 6cd9971
- blame-history #5: same as diff-bug #2 — reject, planned change
- prior-review #1: same as diff-bug #5 — fix now, fixed 6cd9971
- prior-review #2: same as diff-bug #7 — fix now, fixed 6cd9971
- prior-review #3: the test commit sets no `core.hooksPath` (LESSONS M015) — fix now, fixed 6cd9971
- prior-review #4: `writeLines()` writes CRLF on Windows (LESSONS M011) — reject, false: the test reads rendered output values, which line ends do not change
- ripple #1: `check_supplement()` stale-output and no-stored-output rows say "render by name, then commit `_freeze/`" — follow-up, row "Align render advice with the new guide"
- ripple #2: the template guide's private-data recipe stages `_freeze docs figures` without the changed report — follow-up, same row
- ripple #3: that recipe offers either render, not both in order — follow-up, same row
- ripple #4: the unpublished-figure row says to commit `docs/` only — follow-up, same row
- ripple #5: the `_quarto.yml` and README "Website:" placeholders are not in step 8 — reject, false: step 3's `repo` fills both lines, and the claim reader's scratch walk gave only the six rows step 8 covers
- ripple #6: the guide uses `git add -A`, not `git add -A -- .` — reject, planned change: the clone is the site folder
