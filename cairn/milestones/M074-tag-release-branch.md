# M074: Tag the release on the branch that holds it

- **Status:** planned
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — changes the text and the address that `release_supplement()` prints to authors
- **Branch/PR:** —

## Goal

The release address that `release_supplement()` prints tags the author's current branch, for more forms of a GitHub `origin` url.

## Scope

**In:** These parts change:

- The address gains `&target=<branch>`, and the text names the branch.
- If the current branch is not the default branch that `refs/remotes/origin/HEAD` names, the text adds a line.
- The `origin` read takes the push url, and more GitHub url forms give the address.
- Code: `release_address()` and `report_release()` in `R/release-supplement.R`, and `origin_url()` with a new branch read beside it in `R/check-supplement.R`. Both reads go through `git_run()` (D-035).
- Tests in `tests/testthat/test-release-supplement.R`.
- Docs: the help page, `README.md`, `inst/template/GUIDE.md`, `vignettes/publishing.Rmd`, `NEWS.md`, and `cairn/DESIGN.md`.

**Out:**

- An `origin` that names an ssh host alias, such as `git@github-work:o/r`. It needs the user's ssh configuration, so it goes to the candidate row "Read ssh host aliases for GitHub".
- A release published after later commits reach the named branch. GitHub still tags the later commit. The user chose at the plan to keep the text that says to publish right after the push, so no row holds it.
- The default branch of a push url that differs from the fetch url. `refs/remotes/origin/HEAD` comes from the fetch url, so the other-branch line compares with that repository (D-038).
- A printed `git tag` command, which the plan rejected (D-038).

## Acceptance criteria

- [ ] AC1: If the site's git checkout is on a branch whose name is valid UTF-8, the printed address is `https://github.com/<owner>/<name>/releases/new?tag=vX.Y.Z&target=<branch>`. Here `<branch>` is the full branch name, with each byte outside `A-Za-z0-9-._~` written as `%XX` of its UTF-8 bytes. A branch `rel/v1#b&c+é` gives `target=rel%2Fv1%23b%26c%2B%C3%A9`, also when a tag has the same name. The text after the commands says that GitHub makes the tag on that branch. If the checkout is not on such a branch (detached HEAD), the address has no `target`. The text then says that GitHub makes the tag on the default branch. If `origin` gives the Releases-page steps, the steps tell the author to pick the current branch as the target, or the default branch when the checkout is not on such a branch.
- [ ] AC2: If `refs/remotes/origin/HEAD` names a branch other than the current branch, the release text names both branches. It says that the tag goes on the current branch. The text holds no such line in three cases: `refs/remotes/origin/HEAD` names the current branch, it is not set, or the checkout is not on a branch. A local branch named `origin/main` does not change which branch is read as the default.
- [ ] AC3: Each `origin` push url in this list gives the address of `jdoe/my-site`, or of `my_org/my-site` for the last url: `https://github.com/jdoe/my-site/`, `https://github.com/jdoe/my-site.git/`, `http://github.com/jdoe/my-site`, `https://www.github.com/jdoe/my-site`, `https://GitHub.COM/jdoe/my-site`, `git@GitHub.com:jdoe/my-site`, `https://jdoe@github.com/jdoe/my-site`, `https://jdoe:x@github.com/jdoe/my-site`, `https://github.com:443/jdoe/my-site`, `ssh://git@github.com:22/jdoe/my-site.git`, `ssh://github.com/jdoe/my-site`, `org-1@github.com:jdoe/my-site.git`, `https://github.com/my_org/my-site`. Each url in this list gives the Releases-page steps: `https://github.com.evil.org/jdoe/my-site`, `https://evil.org/github.com/jdoe/my-site`, `https://github.com@evil.org/jdoe/my-site`, `https://github.example.com/jdoe/my-site`, `https://github.com/jdoe/my-site/tree/main`, `https://github.com/jdoe/my-site?x`, `https://github.com/jdoe/my-site//`, `git://github.com/jdoe/my-site`, `git@github-work:jdoe/my-site`. The seven url forms that gave the address before M074 still give it, and the two cases that gave the steps still give them.
- [ ] AC4: The address comes from the push url of `origin`. With fetch url `https://gitlab.com/jdoe/my-site` and push url `https://github.com/jdoe/my-site`, the release prints the address of `jdoe/my-site`. With the two urls swapped, it prints the Releases-page steps.
- [ ] AC5: Join the wrapped lines of `R/release-supplement.R`, `man/release_supplement.Rd`, `README.md`, `inst/template/GUIDE.md`, `vignettes/publishing.Rmd`, `NEWS.md`, and `cairn/DESIGN.md`, and read each sentence that holds `default branch` in any case. Each such sentence that is about the release tag is about a checkout not on a branch, the Releases-page steps for such a checkout, or the other-branch line. `man/release_supplement.Rd`, `inst/template/GUIDE.md`, and `vignettes/publishing.Rmd` each say that the address names the current branch.
- [ ] AC6: In the built-in browser, signed in as the user, `https://github.com/jmgirard/supplement/releases/new?tag=v9.9.9&target=%67h-pages` opens GitHub's new-release form. The form shows `v9.9.9` in the tag field and `gh-pages` as the target, so GitHub decodes `%XX` in the target. Afterwards, `gh release view v9.9.9 --repo jmgirard/supplement` finds no release.
- [ ] AC7: `devtools::test()` gives 0 failures, and `devtools::document()` gives no diff. `devtools::check()` gives 0 errors and 0 warnings, and CI passes on every job of the PR.

## Coverage

- AC1 → T3, T4
- AC2 → T3, T4
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T5
- AC6 → T6
- AC7 → T7

## Tasks

- [ ] T1: Write tests first in the release-address block of `tests/testthat/test-release-supplement.R` (from line 1168). Add one test for each AC3 url and one for each AC4 case. A helper sets a separate push url with `git remote set-url --push origin`. See the new tests fail.
- [ ] T2: Make `origin_url()` (`R/check-supplement.R:625`) run `git remote get-url --push origin`. Widen `release_address()` (`R/release-supplement.R:515`) to these forms, and nothing after the name:
  - `https://` or `http://`, with optional user info and port, host `github.com` or `www.github.com` in any case.
  - `ssh://`, with optional user and port, host `github.com` in any case.
  - The scp-like form `<user>@github.com:`, host in any case.
  - Owner `[A-Za-z0-9_-]+`, name `[A-Za-z0-9._-]+`, an optional `.git`, and at most one trailing `/`.
- [ ] T3: Write tests first for AC1 and AC2. The cases are: branch `main`, branch `rel/v1#b&c+é` with a tag of that name, a detached HEAD, a non-GitHub origin on a branch, and `refs/remotes/origin/HEAD` set by `git symbolic-ref` to the same branch, to another branch, and unset. Add a local branch `origin/main` to one case. Update `expect_push_first()` for the branch wording. See the new tests fail.
- [ ] T4: Add a branch read beside `origin_url()` through `git_run()`. It runs `git symbolic-ref --quiet HEAD` and strips `refs/heads/`. It runs `git symbolic-ref --quiet refs/remotes/origin/HEAD` and strips `refs/remotes/origin/`. Each read gives NULL on a failure, on another prefix, or on bytes that are not UTF-8. Pass the branch to `release_address()`, which adds `&target=` with `utils::URLencode(reserved = TRUE)`. Pass it to `report_release()`, which names the branch in the push-first text and in the Releases-page steps, and prints the other-branch line. `test-source.R` stays as it is. T3 passes.
- [ ] T5: Update the roxygen of `release_supplement()`, `README.md`, `inst/template/GUIDE.md` "Make a release", `vignettes/publishing.Rmd`, the `NEWS.md` entry, and `cairn/DESIGN.md` (Conventions and Architecture). Run `devtools::document()`, then read each `default branch` sentence that AC5 names.
- [ ] T6: Open the AC6 address in the built-in browser and read the tag and target fields. Leave without publishing, then run `gh release view v9.9.9 --repo jmgirard/supplement`.
- [ ] T7: Run `devtools::test()` and `devtools::check()`, then push and read CI.

## Work log

- 2026-10-28: created by /milestone-plan.
- 2026-10-28: tier check: not run — work named at the question set.
- 2026-10-28: idea vet: two concerns. A branch target does not pin the release commit, since a later commit on the branch moves it; the set offered a printed `git tag` and no build, and the user chose the branch target. An ssh host alias cannot be read as GitHub without the user's ssh configuration; the agent moved it to the candidate row "Read ssh host aliases for GitHub".
- 2026-10-28: question set: work to plan — "Tag releases made from other branches", with "Read more GitHub remote address forms" folded in.
- 2026-10-28: question set: approach — name the branch in the address and warn when it is not the default branch.
- 2026-10-28: question set: may the review open GitHub's new-release form on jmgirard/supplement in the built-in browser with the user's sign-in, publishing nothing — yes.
- 2026-10-28: plan gate chose `&target=<branch>` in the address over printing `git tag vX.Y.Z` and `git push origin vX.Y.Z`, because the user keeps the release in the R console, a browser, and the Git pane (D-036); falsified by evidence that GitHub's form ignores `target`, or that authors publish after later commits reach the branch.
- 2026-10-28: plan chose a local read of `refs/remotes/origin/HEAD` over asking GitHub for the default branch, because the package calls no web API for a release (DESIGN Conventions); falsified by evidence that new repositories made by `usethis::use_github()` leave it unset.
- 2026-10-28: collision: absorbed candidate rows "Tag releases made from other branches" and "Read more GitHub remote address forms"; extends M073 (archived); D-036 narrowed by D-038 in this plan commit; D-035 holds, as the new read goes through `git_run()`. Inbox: 0 open issues, 0 open PRs.
- 2026-10-28: lessons used: 2026-10-28 (M068) on pushing tracking commits before the CI wait; 2026-10-28 (M073) on GitHub's default-branch lag after a push.
- 2026-10-28: criteria audit (full mode, fresh Opus reader): 9 findings, all fixed. Branch reads use full refs, since `--short` gives `heads/<b>` beside a same-named tag and `remotes/origin/main` beside a local `origin/main` (AC1, AC2, T4). Non-UTF-8 branch names fall to the no-branch case (AC1). The Releases-page steps now name the branch (AC1). The M073 count corrected to 7 address and 2 steps cases (AC3). Steps cases added for a query, a double `/`, and `git://`, and an scp case with an upper-case host (AC3). Test counts moved from the criteria to T1 and T3. D-038 narrows D-036, and the fetch-versus-push default branch went to Out. AC5 reads joined sentences, not grep lines. AC6 encodes `g` as `%67` so the look shows GitHub decodes the target. AC7 passed.
