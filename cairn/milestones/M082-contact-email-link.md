# M082: Link the contact email on new sites

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the Contact section of every new site's home page
- **Branch/PR:** m082-contact-email-link

## Goal

The template's contact value shows its email address as a mailto: link, and the site guide says how to write one.

## Scope

**In:** the `contact` placeholder in `inst/template/_supplement.yml` becomes `"Your Name, Your Institution. <you@example.edu>"`, with a comment line above it; the `## Paper facts in _supplement.yml` section of `inst/template/GUIDE.md`; `check_supplement()` keeps flagging the former placeholder as well as the new one, with `?check_supplement`; the test helper `fill_placeholders()`; the demo builder's contact line; a render test of the Contact section; a placeholder test; a NEWS.md entry.

**Out:** no shortcode or filter links a bare address (the user chose the template route; see the work log). Sites made before this change keep their contact line, and an author edits it by hand; no helper edits old sites (as with the parked row "Migrate old sites to the freeze layout").

## Acceptance criteria

- [ ] AC1: In a site that `quarto use template inst/template` makes (the `site_copy()` helper in `tests/testthat/helper-template.R`) and Quarto renders, `_supplement.yml`'s `contact` value is `Your Name, Your Institution. <you@example.edu>`, and the `<section id="contact">` of `docs/index.html` holds exactly one `<a>`, with `href="mailto:you@example.edu"` and the text `you@example.edu`, and its text with tags removed and runs of white space made one space is `Contact Your Name, Your Institution. you@example.edu`.
- [ ] AC2: A new comment line directly above `contact:` in `inst/template/_supplement.yml`, and the section `## Paper facts in _supplement.yml` of `inst/template/GUIDE.md`, say that an email address written between `<` and `>`, as in the template's value, shows as an email link.
- [ ] AC3: `check_supplement()` gives the `placeholder` row naming `contact` when the site's `contact` equals, after the existing white-space cleaning, either the installed template's value or the former template value `Your Name, Your Institution. Your email address.`, and `?check_supplement` states both. A test in `tests/testthat/test-check-supplement.R` sets the former value, once as written and once with extra spaces and a tab, and sees the row name `contact`; the test "template values in _supplement.yml give one placeholder row that names them" still passes.
- [ ] AC4: NEWS.md has one new entry that gives the new placeholder `Your Name, Your Institution. <you@example.edu>`, says the address shows as an email link, says that `check_supplement()` still flags the former placeholder, and says that a site made before this change keeps its contact line and its author can put the address between `<` and `>` in `_supplement.yml` by hand.
- [ ] AC5: `.github/scripts/build-demo.R` writes the line `  contact: "M. L. Rivera, Department of Psychology, Example University. <m.rivera@example.org>"`.
- [ ] AC6: With Quarto on PATH, `Rscript -e 'devtools::test()'` passes and runs the Contact-section test in `tests/testthat/test-shortcodes.R` (AC1) without a skip, and `Rscript -e 'devtools::check()'` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T1, T2
- AC2 → T2
- AC3 → T3
- AC4 → T4
- AC5 → T4
- AC6 → T5

## Tasks

- [x] T1: In `tests/testthat/test-shortcodes.R`, beside the footer test (line 427), add a test that reads the `<section id="contact">` of a `site_copy()` home page and checks AC1. Run it against the default branch's template and see it fail.
- [x] T2: Change `contact` in `inst/template/_supplement.yml` (line 17) to the new value and add the comment line above it; update `fill_placeholders()` in `tests/testthat/helper-files.R` (line 106), which replaces the old string by fixed match; add the link sentence to the paper-facts section of `inst/template/GUIDE.md` (around line 121). Run T1's test and the placeholder tests.
- [x] T3: In `R/check-supplement.R`, make `placeholder_values()` (line 2682) also count the former contact value, and update the roxygen text (line 452) and `man/` with `devtools::document()`. Add the AC3 test near line 2140 of `test-check-supplement.R`; plant a raw (uncleaned) comparison of the former value and see the white-space case fail.
- [x] T4: Change the demo contact line in `.github/scripts/build-demo.R` (line 157) and add the NEWS.md entry in the style of the footer-credit entry.
- [ ] T5: Run `devtools::test()` and `devtools::check()` with Quarto on PATH.

## Work log

- 2026-11-27: created by /milestone-plan.
- 2026-11-27: tier check: milestone — a change to the template every new site renders and to a check_supplement() rule, not a bug fix.
- 2026-11-27: idea vet: two gaps, no flaw. Gap — changing the template value would stop check_supplement() flagging sites that kept the old placeholder (reading taken: keep matching the former value). Gap — template route or automatic linking, and which link syntax (posed at the question set, as each changes what users see).
- 2026-11-27: lessons used: none.
- 2026-11-27: collision check: no D-entry or row covers the contact link; M004 built the contact value and M036 the placeholder check, both extended here. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-11-27: question set: approach — template and docs; link form — `<you@example.edu>`; the three uncommitted Docker-build candidate rows already in ROADMAP.md — commit them with the plan.
- 2026-11-27: plan gate chose the template route over a shortcode that links bare addresses because each site holds its own copy of supplement.lua and index.qmd, so the shortcode would reach no existing site without two hand edits, more than editing the value; falsified by a way to update installed sites' extension files, such as a package helper that refreshes `_extensions/`.
- 2026-11-27: plan gate chose `<you@example.edu>` over `[you@example.edu](mailto:you@example.edu)` because the address is typed once, so the shown text and link target cannot differ; falsified by a Quarto or Pandoc version that does not autolink `<addr>` in a metadata value.
- 2026-11-27: Quarto 1.11.9 render (scratch) showed `<addr>` and `[addr](mailto:addr)` in a metadata value both give a mailto: link and a bare address gives plain text; `git log -p` shows one contact placeholder ever, since M004.
- 2026-11-27: criteria audit (full mode, fresh Opus reader): 7 findings, all taken — T2 updates `fill_placeholders()`, whose fixed replace would silently miss; AC6 names the Contact-section test; AC3 names the existing test and adds a white-space case for the former value; AC2 says "a new comment line" and names the GUIDE.md section; AC4 also states the former-placeholder flag; AC5 pins the exact line. The reader confirmed the rendered section text matches AC1.
- 2026-11-27: implement started on branch m082-contact-email-link; status in-progress.
- 2026-11-27: T1 done — Contact-section test in test-shortcodes.R; on the unchanged template it failed 5 expectations (value, section text, link count, href, link text).
- 2026-11-27: T2 done — template value and comment line, fill_placeholders(), GUIDE.md sentence; test-shortcodes.R green.
- 2026-11-27: T3 done — `former_placeholders` list beside `placeholder_values()` (chosen over a hard-coded second compare so a later template change adds one entry), roxygen and man/ updated; a planted raw `identical()` compare failed only the white-space case; test-check-supplement.R green (skips are macOS file-system cases).
- 2026-11-27: T4 done — demo contact line in build-demo.R (its `replace_once("  contact: ")` still matches one line of the template) and the NEWS.md entry.

## Decisions

## Review
