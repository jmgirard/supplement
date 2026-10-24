# M049: Keep a new site's .gitignore through later renders

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the template's `_gitignore` becomes each new site's `.gitignore`
- **Branch/PR:** m049-quarto-ignore-lines

## Goal

A new site's `.gitignore` stays as setup wrote it through later renders, because the template's `_gitignore` holds the lines that Quarto 1.10.19 requires.

## Scope

**In:** Add `/.quarto/` and `/_*.local` to `inst/template/_gitignore`, keeping `.quarto/` and every other rule, with a comment that Quarto rewrites a `.gitignore` that lacks its lines. A test of the second render of a `.gitignore` that setup renamed. A NEWS entry. A DESIGN.md Known issues line for the rewrites left.

**Out:**
- `/env/`: Quarto adds it only when a root `env/` folder holds a Python environment, and a site may keep other files in `env/`, so the template leaves it out. The case lives in the DESIGN.md Known issues line (T3).
- Quarto's rewrite of an author's own `.gitignore` before setup appends to it: Quarto's behavior, which the template cannot change. It lives in the same Known issues line (T3).
- The other follow-ups of the Lua move, such as "Drop the Windows Quarto cache in tests", stay candidate rows (question set: separate milestones).

## Acceptance criteria

- [ ] AC1: With Quarto 1.10.19, in a project that is not inside a git repository and holds the template's `_gitignore` and setup script, no `.gitignore`, and no root `env/` folder, a second full render leaves `.gitignore` byte for byte as the first full render left it. This holds both with no root file matching `_*.local` and with a root `_environment.local`.
- [ ] AC2: `inst/template/_gitignore` holds every line it held at the milestone's base commit, in the same order, and adds `/.quarto/` and `/_*.local` as whole lines. The only ignore rules it adds are those two; comment lines may be added.
- [ ] AC3: `NEWS.md`'s development section has one entry for the change that says a new site's `.gitignore` no longer changes on its second render unless a root `env/` folder holds a Python environment, and that the template now ignores Quarto's `_*.local` files at the project root.
- [ ] AC4: `devtools::test()` passes on Quarto 1.10.19 with AC1's test run and not skipped. At review, `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T1, T2, T3

## Tasks

- [x] T1: Test first. In `tests/testthat/test-template.R`, after "a second render leaves the files that setup wrote" (about line 694), add a test that makes `script_site()` with no `.gitignore` and no `env/`, renders twice, and compares `.gitignore` bytes after each render, in two cases: no `_*.local` file, and an `_environment.local` file holding one variable line. Run it on the unchanged template. Both cases must fail, and the diff must show Quarto's lines added by the second render (`/.quarto/`, plus `/_*.local` in the second case), not another difference.
- [x] T2: In `inst/template/_gitignore`, add `/.quarto/` and `/_*.local` beside `.quarto/`, with a comment that Quarto rewrites a `.gitignore` that lacks its lines. Run T1's test green. Plant the defect: remove `/_*.local` alone, see the `_environment.local` case fail and the other case pass, then restore the line. Run `devtools::test()` and confirm the new test ran, not skipped; the setup-merge tests derive their expected lines from `_gitignore` through `template_ignore_lines()`, so they stay green unedited.
- [x] T3: Write the NEWS entry (AC3) against the T1 and T2 runs. Add a DESIGN.md Known issues line naming the rewrites left: an author's own `.gitignore` that lacks Quarto's lines is rewritten before setup runs, and a root `env/` folder with `pyvenv.cfg` or `conda-meta` makes Quarto add `/env/`, which the template leaves out. Update the `quarto_ignore` comment in `test-template.R` (about line 622) if its wording no longer fits.

## Work log

- 2026-10-24: created by /milestone-plan.
- 2026-10-24: tier check: not run — work named at the question set.
- 2026-10-24: question set: which work — "Fix the template ignore list"; ship with the test-helper tidy — separate; pkgdown publishing — build only (unused, since the pkgdown site was not picked).
- 2026-10-24: idea vet: found none. The vet read `ensureGitignore` in Quarto 1.10.19's `quarto.js`, which also requires `/_*.local` when a root `_*.local` file exists and `/env/` when a root `env/` holds a Python environment, so the scope adds `/_*.local` and leaves `/env/` out.
- 2026-10-24: collision check: absorbed the candidate row "Add Quarto's ignore lines to _gitignore" in full; its Quarto-side remainder (an author's own `.gitignore` rewritten before setup) goes to DESIGN.md Known issues at T3. D-006 (setup appends only) and D-023 (Lua scripts) stay unaffected. M048 created the row; no other overlap.
- 2026-10-24: inbox sweep: 0 open issues and 0 open PRs on jmgirard/supplement.
- 2026-10-24: lessons harvest: M009 (criteria as a stated rule plus listed tests), M010 (prove a template test can fail against the unchanged file), and M019 (Lua script failures print Pandoc's error) shape T1 and T2.
- 2026-10-24: plan chose adding `/.quarto/` beside `.quarto/` over replacing `.quarto/` because the addition keeps every folder the old rule ignored; falsified by evidence that Quarto 1.10.19 rewrites a `.gitignore` holding both lines.
- 2026-10-24: plan chose leaving `/env/` out over adding it because Quarto adds it only for a Python environment folder and a site may keep other files in `env/`; falsified by evidence that sites made from the template keep Python environments at the root.
- 2026-10-24: test scope: one new test with two cases (T1) and one planted-defect run (T2); no existing test should need edits. Changelog: one NEWS entry (AC3).
- 2026-10-24: criteria audit (full mode, fresh Opus reader): 10 findings, 9 fixed by narrowing and 1 answered. AC1 named Quarto 1.10.19, excluded git repositories (Quarto writes `.gitignore` before setup there) and a root `env/`, and stated its two cases itself rather than through the test. AC2 states file contents against the base commit, not a `git diff`, and forbids other new rules. AC3 carries the `env/` caveat. AC4 requires AC1's test to run, not skip. The finding that no criterion covers the DESIGN.md line was answered: that line is a project record, not the deliverable, so it stays task T3.
- 2026-10-24: checkpoint (T1–T3 written, full suite still running, boxes unticked): the new test failed on the unchanged template in both cases, the second render appending `\n/.quarto/\n` (plus `/_*.local\n` with `_environment.local`), and passed after the `_gitignore` edit; with `/_*.local` planted out, only the local-file case failed. The new lines sit in their own commented block, so the old lines keep their order (AC2). NEWS entry and DESIGN.md Known issues line written; the `quarto_ignore` comment still fits.
- 2026-10-24: T1–T3 done: `devtools::test()` on the T2 code gave 391 tests, 0 failed, 0 errors, 10 skipped, and the new test ran its 8 expectations unskipped (Quarto 1.10.19, macOS). NEWS and DESIGN.md edits came after that run and touch no test input.

## Decisions

## Review
