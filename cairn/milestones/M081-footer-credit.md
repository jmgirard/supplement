# M081: Credit the package in the site footer

- **Status:** review
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the page footer of every new site
- **Branch/PR:** m081-footer-credit

## Goal

The page footer of every new site says "Created with supplement", with "supplement" linked to the package repository.

## Scope

**In:** a `right:` entry under `page-footer` in `inst/template/_quarto.yml` that shows `Created with [supplement](https://github.com/jmgirard/supplement)`; a render test of both template pages; the footer sentences of `inst/template/GUIDE.md`; the template part of `cairn/DESIGN.md`; a NEWS.md entry.

**Out:** sites made before this change keep their footer; an author adds the line by hand, and no helper edits old sites (as with the parked row "Migrate old sites to the freeze layout"). No `_supplement.yml` value turns the credit off; an author deletes the line, as GUIDE.md will say. The license line in the center does not change.

## Acceptance criteria

- [ ] AC1: In a site that `quarto use template inst/template` makes (the `use_template()` helper in `tests/testthat/helper-template.R`) and that Quarto 1.10.19 (the version `.github/workflows/R-CMD-check.yaml` pins) and Quarto 1.11.9 each render, `docs/index.html` and `docs/analyses/example.html` each hold exactly one `<div class="nav-footer-right">` whose text, with tags removed, runs of white space made one space, and white space at both ends removed, is `Created with supplement`, and whose only link is an `<a>` with the text `supplement` and `href="https://github.com/jmgirard/supplement"`.
- [x] AC2: On both pages, for both license cases of the test "the page footer shows the licenses set in _supplement.yml" in `tests/testthat/test-shortcodes.R`, the `nav-footer-center` text and SPDX links equal the values that test expects on the default branch at the branch cut.
- [x] AC3: `inst/template/GUIDE.md` says that the right part of the page footer shows `Created with supplement`, with `supplement` linked to https://github.com/jmgirard/supplement, and that an author removes it by deleting the `right:` entry under `page-footer` in `_quarto.yml`.
- [x] AC4: NEWS.md has an entry that gives the text `Created with supplement` and the address https://github.com/jmgirard/supplement.
- [ ] AC5: With Quarto 1.11.9 on PATH, `Rscript -e 'devtools::test()'` passes and runs the tests "the right part of the page footer credits the package" and "the page footer shows the licenses set in _supplement.yml" without a skip, and `Rscript -e 'devtools::check()'` gives 0 errors and 0 warnings; the R-CMD-check workflow, which pins Quarto 1.10.19, passes on the PR's head commit on all three systems.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T3
- AC5 → T4

## Tasks

- [x] T1: In `tests/testthat/test-shortcodes.R`, beside `footer_center()` (line 422), add a `footer_right()` helper and a test that renders a fresh template site and checks AC1 on both pages. Run it on the default branch's template and see it fail.
- [x] T2: Add `right: "Created with [supplement](https://github.com/jmgirard/supplement)"` under `page-footer` in `inst/template/_quarto.yml` (line 46), with a comment that authors can delete it. Run the new test and the license footer test.
- [x] T3: Update the footer sentences of `inst/template/GUIDE.md` (lines 128 and 155), the template paragraph of `cairn/DESIGN.md` (line 339), and add the NEWS.md entry.
- [x] T4: Run `devtools::test()` and `devtools::check()` with Quarto on PATH.

## Work log

- 2026-11-26: created by /milestone-plan.
- 2026-11-26: tier check: milestone — a change to the template that every new site renders, not a bug fix.
- 2026-11-26: idea vet: one gap — which words carry the link (reading taken: only "supplement"; posed at the question set as another reading changes what users see); no flaw.
- 2026-11-26: lessons used: none.
- 2026-11-26: collision check: no D-entry, archive, or row covers a footer credit; M010 and M014 built the license line, which stays. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-11-26: question set: placement — the footer's right part; link text — only "supplement".
- 2026-11-26: plan gate chose the footer's right part over the end of the license line because the license line keeps its test and an author removes the credit by deleting one line; falsified by a Quarto theme that hides or wraps `nav-footer-right` on narrow screens.
- 2026-11-26: criteria audit (full mode, fresh Opus reader): 8 findings, all taken — AC1 names the helper and says "exactly one"; AC1's and AC2's test-harness clauses moved to tasks, AC2 narrowed to the center footer values; AC3 and AC4 give the text and address; AC5 requires the footer tests to run unskipped; DESIGN.md went to T3 as a task, not a criterion, since the consistency gate reads it. The reader confirmed Quarto writes all three footer divs, an empty one holding `&nbsp;`.
- 2026-11-26: with `web_links = TRUE`, `check_supplement()` now requests the credit address once per site (it drops repeats); D-030 keeps that check opt-in.

- 2026-11-26: status in-progress; branch m081-footer-credit cut from main at 0263095.
- 2026-11-26: re-audit: AC1 (full) — "Quarto 1.10 or later" is an unbounded version range; my premise was wrong, since R-CMD-check.yaml pins Quarto 1.10.19 and only the local Quarto is 1.11.9; fix: name 1.10.19 and 1.11.9.
- 2026-11-26: re-audit: AC5 (full) — same version-range finding; name both footer tests; add the pinned-Quarto CI run on the PR head.
- 2026-11-26: T1: new test "the right part of the page footer credits the package" uses site_copy(); on the old template it failed on both pages (right part held only `&nbsp;`).
- 2026-11-26: T2: `right:` entry added to `inst/template/_quarto.yml`; the new test and the license footer test pass locally (Quarto 1.11.9).
- 2026-11-26: checkpoint: T3 edits to GUIDE.md, DESIGN.md, and NEWS.md written, not yet checked off; the fixed AC1 and AC5 wording waits on its one re-entry reader.
- 2026-11-26: re-audit: AC1 (full) — second reader on the fixed wording: the text rule does not trim the ends, and a 1.11.9 render puts the credit on its own line, so the text reads " Created with supplement "; fix: also remove white space at both ends. A second line on AC1, so the fix goes to the user.
- 2026-11-26: re-audit: AC5 (full) — second reader: "the PR's head commit" can be a records commit after the CI run, and "passes" does not say how a rerun counts; held as written, since every push to the branch runs the workflow (no path filter), and a rerun counts by its last attempt as GitHub reports it.
- 2026-11-26: substantive amendment: AC1 names Quarto 1.10.19 (pinned in CI) and 1.11.9 (local) in place of "Quarto 1.10", and trims white space at both ends of the footer text; AC5 names 1.11.9 for the local run, names both footer tests, and adds the pinned-Quarto CI run on the PR head. The end trim was the user's choice at the second-re-audit stop. The deliverable is unchanged.
- 2026-11-26: T3: GUIDE.md (paper facts section), DESIGN.md template paragraph, and a NEWS.md entry describe the credit and how to remove it; a render of the old template showed the right part empty (`&nbsp;`), the basis for the removal sentence.
- 2026-11-26: claim audit: 10 claims read, 0 corrected — NEWS.md, inst/template/GUIDE.md, inst/template/_quarto.yml, tests/testthat/test-shortcodes.R; the reader rendered the template with and without the `right:` line. It found the `_supplement.yml` header comment stale ("The page footer shows the two licenses") and the `_quarto.yml` comment left behind after a delete; both fixed.
- 2026-11-26: T4: with Quarto 1.11.9, `devtools::test()` passed (0 failed; 18 platform or opt-in skips, neither footer test among them) and `devtools::check()` gave 0 errors, 0 warnings, 0 notes. The two comment fixes came after the check started; test-shortcodes.R, test-template.R, and test-create-supplement.R passed again after them.
- 2026-11-26: status review.
- 2026-11-26: review: `devtools::test()` on 5e91aa2 gave 0 failures and 18 skips, neither footer test among them. Feature cap read: 0 open PRs against a cap of 2. No snapshot files changed.
- 2026-11-26: step-7 approval: m081-footer-credit approved for merge

## Decisions

## Review

- 2026-11-26: sync: main has not moved since the branch cut (0 commits behind origin/main). No Copilot round (no `# Copilot review:` line).
- AC3 evidence: `inst/template/GUIDE.md` lines 128-133 at HEAD say the right part of the footer shows "Created with supplement", with `supplement` linked to https://github.com/jmgirard/supplement, and that deleting the `right:` entry under `page-footer` in `_quarto.yml` removes it. Read 2026-11-26.
- AC4 evidence: NEWS.md lines 3-7 at HEAD, in the unreleased `# supplement 0.0.0.9000` section, give "Created with supplement" and https://github.com/jmgirard/supplement. Read 2026-11-26.
- AC2 evidence: the diff adds 20 lines to `tests/testthat/test-shortcodes.R` and changes no line of the license footer test, so its cases and expected values are those of main at the cut (0263095). That test passed in the fresh `devtools::test()` run with Quarto 1.11.9 (0 failures). A manual render on 1.11.9 showed `Code: MIT · Content: CC BY 4.0` with the two SPDX links in `nav-footer-center` on both pages.
- AC1 evidence (Quarto 1.11.9 part): a fresh `quarto use template` render showed exactly one `nav-footer-right` on `index.html` and on `analyses/example.html`, holding `<p>Created with <a href="https://github.com/jmgirard/supplement">supplement</a></p>`. The test "the right part of the page footer credits the package" passed, and with the `right:` line removed it failed 4 expectations on each page. The Quarto 1.10.19 part waits on the R-CMD-check run on the PR head; box not ticked.
- AC5 evidence (local part): with Quarto 1.11.9, `devtools::test()` gave 0 failures with 18 platform or opt-in skips, neither footer test among them; `devtools::check()` gave 0 errors, 0 warnings, 0 notes (before the fix-now commit 5e91aa2, which changes a test helper, NEWS.md, and a template comment; `devtools::test()` reruns on it). The CI part waits on the R-CMD-check run on the PR head; box not ticked.
- consistency gate: `cairn_validate.py` all checks passed; `devtools::document()` gave no diff; no README.Rmd; `pkgdown::check_pkgdown()` no problems; NEWS.md has the entry; no new top-level files. No principle changed, so no `cairn_impact` run.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: with `web_links = TRUE` every site requests github.com/jmgirard/supplement, and a refusal would give a row for a link the author did not write — reject (false): a HEAD request through `curlGetHeaders()` returned 200 on 2026-11-26; refusals in general are the parked row "Retry refused web links with GET".
- diff-bug #2: below 768 px Quarto orders the center part last, so on phones the credit sits above the license line — reject (planned change): both parts still show; the plan placed the credit in the right part.
- diff-bug #3: NEWS.md says nothing about sites made before the change — fix now, fixed 5e91aa2.
- diff-bug #4: the two count checks give no page in their failure message — fix now, fixed 5e91aa2.
- diff-bug #5: T1 named a `footer_right()` helper, and the regex sat inside the test — fix now, fixed 5e91aa2.
- diff-bug #6: the lazy match stops at the first `</div>`, so a later Quarto that nests a div there would fail the test — reject (false): such a change shows as a failure, never a false pass, and the planted run failed as expected.
- diff-bug #7: the edited `_supplement.yml` header line runs past the block's wrap — fix now, fixed 5e91aa2.
- diff-bug #8: no "What gets a test" exclusion applies; the second page shares a code path but AC1 names both pages — noted, no change.
- blame-history #1: the work log says `check_supplement()` now requests the credit address, but no R/ file changed — reject (false): `web_addresses()` reads every http(s) link in the rendered pages, so the new link is requested with no code change.
- blame-history #2: the `_supplement.yml` line length — fix now, fixed 5e91aa2 (same as diff-bug #7).
- blame-history #3: the test and the comment match the guide and NEWS — noted, no finding.
- prior-review #1: the `_supplement.yml` line length repeats a wrap point M010's review fixed — fix now, fixed 5e91aa2 (same as diff-bug #7).
- prior-review #2: `test-agreement.R` does not cover the credit — reject (planned change): that file compares `_supplement.yml` values with `write_citation()`, and the credit is no such value.
- prior-review #3: no stale text in `_README.md`, NEWS, or DESIGN.md — noted, no finding.
- prior-review #4: the `_quarto.yml` comment fits M040 and M041's short-comment practice — noted, no finding.
- ripple #1: `cairn/references/scope-draft.md:70` lists "the license footer" with no credit — reject (false as stale text): the page is the dated 2026-10-18 scope draft, a record of an earlier setup.
- ripple #2: `inst/template/_supplement.yml:19-20` says the page footer shows a readable name for common ids — reject (false): the footer does show those names, in its center, and the sentence makes no claim about the right part.
- ripple #3: the template comment says to delete the comment and the next line, while GUIDE.md and NEWS.md say to delete the `right:` entry — reject (style): both remove the credit, and following the guide leaves only a comment.
