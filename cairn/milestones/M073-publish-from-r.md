# M073: Publish a site from the R console and a browser

- **Status:** planned
- **Priority:** normal
- **Depends on:** M072
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes what `release_supplement()` prints and returns, the rows of `check_tools()`, and the publishing guide
- **Branch/PR:** —

## Goal

Let an author follow the publishing guide from an empty folder to a release with the R console, a web browser, and the Git pane of RStudio or Positron, with no GitHub command-line tool.

## Scope

**In:** `release_supplement()` prints and returns the git commands that commit and push the release, and prints the address of GitHub's new-release form for the tag, read from the `origin` remote. `check_tools()` drops its `gh` row. `vignettes/publishing.Rmd` is rewritten around `render_supplement()` (M072), usethis and gitcreds for git, sign-in, the repository, and Pages, the Git pane for commits and pushes, and GitHub's page for the release; its last section gives the terminal commands for the same steps. usethis joins Suggests. `tests/testthat/test-publishing.R` follows the new local steps. Docs: the help pages of both functions, `README.md`'s setup and release sections, `GUIDE.md`'s "Make a release", `NEWS.md`, `cairn/DESIGN.md`'s Conventions, and two D-entries.

**Out:** a package function that commits, tags, or pushes: the package never does (`cairn/DESIGN.md` Conventions). Zenodo stays a step on Zenodo's site (its API is out of scope for version 1). Deleting the test repository of T6: the user deletes it.

## Acceptance criteria

- [ ] AC1: `release_supplement()` prints, and returns invisibly, exactly `git status -- .`, `git add -A -- .`, `git commit -m "Release vX.Y.Z" -- .`, and `git push`, in that order, shown by the command tests in `tests/testthat/test-release-supplement.R`.
- [ ] AC2: After the commands, `release_supplement()` prints `https://github.com/<owner>/<name>/releases/new?tag=vX.Y.Z` when `git remote get-url origin`, run in the site folder, gives `https://github.com/<owner>/<name>`, `git@github.com:<owner>/<name>`, or `ssh://git@github.com/<owner>/<name>`, each with or without `.git` at the end. With no `origin` remote, or an address in another form, it prints the steps to make the release from the repository's Releases page, with no address. Either way the text says to push first and that GitHub makes the tag on the default branch when the release is published. The six forms, a repository name that holds a dot (`my.site`), the no-remote case, and one other address are each shown by their own test.
- [ ] AC3: `check_tools()` returns rows for Quarto, knitr, rmarkdown, git, GitHub account, and Zenodo account, in that order, and no `gh` row, shown by the row tests in `tests/testthat/test-check-tools.R`.
- [ ] AC4: In `vignettes/publishing.Rmd`, the steps above its last `## ` heading use only R code, web pages, and the Git pane: every fenced block above that heading is an `r` block, and no prose above it tells the reader to run a shell command, checked by reading the file. These steps render with `render_supplement()`; set up git and the GitHub sign-in with `usethis::use_git_config()`, `usethis::create_github_token()`, and `gitcreds::gitcreds_set()`, and check them with `usethis::git_sitrep()`; make the repository with `usethis::use_git()` and `usethis::use_github()`; turn on Pages with `usethis::use_github_pages(branch = usethis::git_default_branch(), path = "/docs")`; and publish the release on GitHub's page from the address that `release_supplement()` prints. The last section gives the terminal commands for the same steps.
- [ ] AC5: The steps of AC4, walked once in order in a new site folder made with `create_supplement(repo = ...)` and a new public repository on the user's GitHub account, starting from the sign-in that `usethis::git_sitrep()` confirms in place of the token steps and leaving out Zenodo, give a site that GitHub Pages serves at the address that `create_supplement()` writes. The address that `release_supplement()` prints opens GitHub's new-release form with the tag field set to the new tag. The Review section records the repository, the Pages address, and the release page.
- [ ] AC6: `grep -rniE 'gh release|gh auth|github cli|cli\.github\.com|command-line tool|command-line interface|\bgh\b' R man README.md vignettes inst/template NEWS.md` finds no line that tells the author to install or run the GitHub command-line tool. The help pages of `release_supplement()` and `check_tools()`, `README.md`'s release section, and `GUIDE.md`'s section "Make a release" say that the author pushes the release commit and then publishes the release on GitHub's page. `NEWS.md` has an entry for the change. `cairn/DESIGN.md`'s Conventions say that the package prints the git commands and the release address, runs none of the printed commands, and opens no page. `DESCRIPTION` lists usethis under Suggests, and `cairn/DECISIONS.md` has a D-entry for publishing the release on GitHub's page and one for usethis in Suggests.
- [ ] AC7: `devtools::test()` gives 0 failures and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T3
- AC4 → T4
- AC5 → T6
- AC6 → T2, T3, T5
- AC7 → T7

## Tasks

- [ ] T1: Tests first. Update `expected_commands()` and the command tests in `test-release-supplement.R`. Switch the tests that read the printed text for `git tag` to tell whether the commands were printed (near lines 907, 989, and 1009) to `git push`. Add the AC2 cases, each in a temporary repository from `git init` with `git remote add origin <address>`. Update the row tests in `test-check-tools.R` (lines 35, 53-54, and 66) and the mocked `gh` row in `test-create-supplement.R` (lines 383-418). In `test-publishing.R`, replace the terminal renders with `render_supplement()`. See them fail.
- [ ] T2: In `R/release-supplement.R`, cut `release_commands()` to the four commands, read the `origin` address through `git_run()` (`R/check-supplement.R:567`), and print the address or the Releases-page steps in `report_release()`; update the roxygen.
- [ ] T3: In `R/check-tools.R`, remove the `gh` row (line 107) and its roxygen item.
- [ ] T4: Rewrite `vignettes/publishing.Rmd` per AC4, keeping its step order and its rule for rendering again after a report changes, with the last section "Use a terminal instead".
- [ ] T5: Add usethis to Suggests. Update `README.md`'s setup and release sections, `GUIDE.md`'s "Make a release", `NEWS.md` (the `check_tools()` entry and a new entry), and `cairn/DESIGN.md`'s Conventions; append the two D-entries. Run AC6's grep and record its lines in the Review section.
- [ ] T6: Walk AC4's steps in a new folder outside the repo with a new public repository on the user's account, as the question set allowed, and record AC5's evidence. Tell the user the repository's name so that they can delete it.
- [ ] T7: Run `devtools::document()`, `devtools::test()`, and `devtools::check()`.

## Work log

- 2026-10-28: created by /milestone-plan.
- 2026-10-28: tier check: milestone — changes exported behavior and needs a design decision on the release step.
- 2026-10-28: idea vet: one concern, posed at the question set: GitHub's form makes the tag on the default branch at publish time, so a release published before the push tags an older commit; answered by printing "push first" (AC2) and accepted with the web-page option.
- 2026-10-28: lessons used: 2026-10-28 (M068), CI takes over 10 minutes per push, for the review's CI wait; 2026-10-27 (M065), read check states, not `gh pr checks` exit codes.
- 2026-10-28: collision check: `cairn/DESIGN.md` Conventions say the package never runs `git tag`, `git push`, or a GitHub release and prints those commands; this plan keeps the first half and changes what is printed. M015 (archived) set the `-- .` commit commands, which stay. No candidate row or D-entry covers the gh tool. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-28: question set: how to publish a release — GitHub's web page from a printed address, gh dropped (over printing both, and no change); the shorter return value takes no deprecation period, since the package has no release.
- 2026-10-28: question set: a live test on the user's GitHub account — yes: one public test repository under jmgirard, Pages on, one test release, from the existing sign-in; the user deletes the repository.
- 2026-10-28: question set: usethis in DESCRIPTION — add to Suggests (over docs only). gitcreds is not listed, since usethis imports it.
- 2026-10-28: plan gate chose GitHub's new-release form over `gh release create` because it needs no extra install or sign-in; falsified by GitHub dropping the form's `tag` query parameter.
- 2026-10-28: plan gate chose one terminal section at the end of the vignette over a terminal line inside each step because the R path stays short to read; falsified by readers who mostly use the terminal.
- 2026-10-28: criteria audit (full mode, fresh Opus reader), shared with M072, all accepted; for M073: tests that used `git tag` as a marker, six address forms and a dotted name, the stale `gh` row in a create test, every fence and the prose checked (AC4), the token steps left to the user (AC5), the package's own wording in the grep, "runs none of the printed commands" in place of "runs neither", the D-entry bound by a criterion, and "Make a release" named. The usethis sentence of AC6 came from the question set and passed the same questions; it joined AC6 to keep the milestone at 7 criteria.
- 2026-10-28: note from M072 implement: `tests/testthat/test-source.R` ("release_supplement() starts no process of its own") refuses `git_run` and `system2` in `R/release-supplement.R`, so T2's read of the `origin` address needs a helper outside that file (for example beside `git_files()` in `R/check-supplement.R`) or a change to that test, decided at implement with a work-log line.

## Decisions
