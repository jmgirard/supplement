# M014: The footer and the DOI badge refuse the values that write_citation() refuses

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — template users see the footer and the badge, and `write_citation()` is exported
- **Branch/PR:** m014-footer-badge-agree

## Goal

For the license and DOI values that the tests list, the page footer and the DOI badge accept and refuse the same values as `write_citation()`, and each footer license name links to the SPDX page of its id.

## Scope

**In:** a narrower SPDX id rule in `license_id()`; one license entry in `CITATION.cff` for ids that differ only in letter case; license and DOI checks in the Lua shortcodes that stop the render; checks of the `supplement-license` argument; footer links to SPDX pages; tests that run the same value tables through `write_citation()` and a render; the docs for these changes.

**Out:**
- Values whose Markdown form leaves no trace in what Lua reads: backslash escapes and HTML entities in a license id, an unquoted number in a license value, and `--`, `'`, or a non-breaking space in a DOI suffix → the "shortcode edge cases" row.
- The other items of "shortcode edge cases" (file names, data maps, paths, the empty "Archived Version" paragraph) → that row.
- A check that SPDX or Zenodo knows an id → declined at the M010 gate (D-012).

## Acceptance criteria

- [x] AC1: `supplement-license` in `inst/template/_extensions/supplement/supplement.lua` stops the render, with a message that names the field (`supplement.license.code` or `supplement.license.content`), when the field's value is a list or a map with at least one item, or when it is not empty and is not one plain-text element whose text passes the id rule of AC2. An empty list or map shows nothing, as an empty string does. A test in `tests/testthat/test-shortcodes.R` renders each of these shapes in each field and checks for the stop and the field name: a list of two ids, a map, an id with a space, an id with `--`, an id with `...`, an id in Markdown emphasis, and an id in a code span.
- [x] AC2: `license_id()` in `R/supplement-yml.R` accepts an id that matches `\A[A-Za-z0-9]+([.-][A-Za-z0-9]+)*\+?\z`: letters or digits, then groups of one `.` or `-` and more letters or digits, then at most one `+`. `supplement-license` applies the same rule. One test table of quoted id shapes, listed in the test (a plain id, an id with `.` and `-`, a final `+`, mixed letter case, a space, `--`, `..`, `...`, a final `-`, `"MIT."`, a leading `-`, Markdown emphasis, and a code span), runs each shape in each license field through `write_citation()` on an otherwise valid `_supplement.yml` and through a render. For each shape, both accept it, or `write_citation()` refuses it with `supplement_error_license` naming the field and the render stops. For each accepted shape, the shortcode output is the readable name of a listed id, or the id as written.
- [x] AC3: `supplement-doi` removes the same prefixes as `bare_doi()` in `R/supplement-yml.R`. It stops the render, with a message that names the field, when `zenodo.version-doi` or `zenodo.concept-doi` is a list or a map with at least one item, or is not empty and is not then `10.`, four to nine digits, `/`, and a suffix with no spaces. It checks both fields, not only the one the badge shows. One test table of quoted DOI shapes, listed in the test (a bare DOI; the prefixes `https://doi.org/`, `https://www.doi.org/`, `http://dx.doi.org/`, `doi:`, `doi: `, and `HTTPS://DOI.ORG/`; `doi:` alone; `https://doi.org/` alone; a three-digit registrant code; a space in the suffix; and a list), runs each shape as the only DOI set, in each DOI field, through `write_citation()` and through a render. For each shape, both accept it and the badge and `CITATION.cff` hold the same bare DOI, or `write_citation()` refuses it with `supplement_error_doi` or `supplement_error_field_type` and the render stops.
- [x] AC4: When `license.code` and `license.content` differ only in letter case, `write_citation()` writes one `license` entry, spelled as in `license.code`. A test checks the written `CITATION.cff`.
- [x] AC5: The footer links each license name to `https://spdx.org/licenses/<id>.html`, with the id spelled as SPDX lists it for the eight ids that have readable names and as written for other ids, on the home page and on a page in `analyses/`. For an empty value, the label (`Code:` or `Content:`) stays and no name or link follows it. The footer in the template's `_quarto.yml` no longer links to `LICENSE.md` or `LICENSE-CC-BY.md`. A test renders sites with `CC0-1.0`, `cc-by-sa-4.0`, `EUPL-1.2`, and an empty value, and checks each link and the empty value on both pages.
- [x] AC6: `supplement-license` stops the render, with a message that names `code` and `content`, unless it has exactly one argument and that argument is `code` or `content`. A test renders no argument, `other`, and `code content`, and checks for the stop and the message.
- [x] AC7: The help page of `write_citation()` describes the new id rule and the single license entry for ids that differ only in letter case, and the help page of `write_zenodo()` describes the new id rule. The comments in the template's `_supplement.yml`, the field and shortcode text of the template's `_README.md`, and `NEWS.md` describe the new id rule, the render stops, and the footer links.

## Coverage

- AC1 → T2, T4, T8
- AC2 → T1, T2, T4
- AC3 → T3, T4, T8
- AC4 → T1
- AC5 → T5
- AC6 → T2
- AC7 → T6, T7

## Tasks

- [x] T1: In `R/supplement-yml.R` (`license_id()`, about line 255), narrow the regex to the AC2 rule and update its error hint. In `citation_text()` (`R/write-citation.R`, about lines 115-121), drop a content id that equals the code id ignoring letter case. Add R tests for the narrowed shapes and the single entry.
- [x] T2: In `supplement.lua`, make `supplement-license` check its arguments (AC6), refuse a non-empty list or map, accept only one plain-text element, and apply the AC2 rule, stopping with `stop()` and the field name. Add the AC1 and AC6 render tests.
- [x] T3: In `supplement.lua`, make `supplement-doi` check both DOI fields: refuse a non-empty list or map, and after `bare_doi()` refuse a non-empty value that is not `10.`, four to nine digits, `/`, and a suffix with no spaces. Add render tests for `doi:` alone and a bad value in the field the badge does not show.
- [x] T4: Add the two agreement tables of AC2 and AC3. Each runs every shape in each field through `write_citation()` on a full fixture and through a render, and checks that both sides accept or both refuse, with the error class and field named.
- [x] T5: Make `supplement-license` return the name as a link to the SPDX page, with the SPDX spelling for the eight listed ids. Change the footer in `inst/template/_quarto.yml` to `Code: {{< supplement-license code >}} · Content: {{< supplement-license content >}}`. Replace the footer test at `tests/testthat/test-shortcodes.R:294-314`, and confirm that the `OWNER/REPO` test in `test-create-supplement.R` still passes.
- [x] T6: Update the roxygen of `write_citation()` and `write_zenodo()` and run `devtools::document()`. Update the license and DOI comments in `inst/template/_supplement.yml`, `inst/template/_README.md` (about lines 71-75 and 112-115), `NEWS.md`, and the Lua lines in DESIGN.md's Architecture section.
- [x] T7: (review return 1) State the new id rule in the `supplement-license` text of `inst/template/_README.md` and in the license bullets of `NEWS.md`.
- [x] T8: (review return 2) In `supplement.lua`, read a null value as empty and a one-paragraph Blocks value as its inlines for licenses and DOIs; stop on a DOI of more than one block and on a named argument to `supplement-license`; give the `--`/`...` hint only when it applies. Add render tests for each. Add `info` to the two refusal assertions in test-agreement.R. Fix `_README.md:118-119`, the spdx.org link wording in `_README.md` and NEWS.md, and the "no SPDX id" comment in `R/supplement-yml.R`.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: milestone — it changes the Lua shortcodes and `write_citation()` and needs choices on render stops and footer links.
- 2026-10-18: collision sweep: absorbs the candidate "footer and badge edge cases" in full, and from "shortcode edge cases" the `supplement-license` argument item. Extends M010 (done), which shipped the footer shortcode. D-008 (a missing data file stops the render) is the precedent for the new stops. D-012 (shape check, not list check) stands, and only the shape changes.
- 2026-10-18: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-18: lessons used: M004 (`assert()` stops a render; Quarto reads metadata as Markdown), M009 (listed test shapes, not open domains), M010 (the footer runs on every page; the `git show main:<path>` check that a test can fail), M005 (YAML 1.1 in R).
- 2026-10-18: criteria audit (full mode, fresh Opus reader): 9 findings, all taken in narrower form. Lua accepts only one plain-text element, and the tables add a code span. A non-empty list or map stops the render, and an empty one shows nothing, as in R. Test values are quoted, `"MIT."` replaces `1.`, and the goal covers only listed shapes. The R side must refuse with the named class and field on a full fixture. The DOI prefixes are listed inline. AC5 adds an unlisted id and an empty value, and states the label rule. AC6 requires exactly one argument. AC7 now names the correct `_README.md` sections and the help page for each function. Known gaps went to the "shortcode edge cases" row.
- 2026-10-18: question set: bad values in the footer or badge — stop the render.
- 2026-10-18: question set: footer link targets — the SPDX page for each id.
- 2026-10-18: plan gate chose stopping the render over a warning that leaves the value out, because it matches D-008 and keeps the published footer and badge in line with `CITATION.cff`; falsified by template users who need to render a site while a value is still invalid.
- 2026-10-18: plan gate chose SPDX page links over renaming `LICENSE-CC-BY.md` to a neutral name, because the link then always matches the name shown; falsified by SPDX URLs that fail for the listed ids, or by users who need the repo's own license text linked.
- 2026-10-18: plan chose to narrow `license_id()` to the Lua rule over leaving R as it is, because otherwise an id such as `a--b` writes to `CITATION.cff` while the render stops; falsified by a real SPDX id with `--`, `..`, or a final `.` or `-`.
- 2026-10-18: plan chose accepting only one plain-text element in Lua over undoing Markdown in Lua, because escapes and entities leave no trace in the parsed value; falsified by a pandoc or Quarto API that gives Lua the raw metadata text.
- 2026-10-18: implement started; branch m014-footer-badge-agree cut from main at 51d575e.
- 2026-10-18: T1 done: `license_id()` uses the AC2 rule, `citation_text()` drops a later id equal ignoring case; six new refused shapes and three real SPDX ids in the tests; the new tests failed before the fix; `devtools::test()` clean.
- 2026-10-18: implementation choice: a probe render showed Lua gets one `Str` for a plain id, `Space`, `Emph`, or `Code` elements for spaces and Markdown, a `List` or plain table for a list or map, and a boolean for `true`; `plain_text()` accepts only an empty value or one `Str`, so `true` also stops, as `write_citation()` refuses it.
- 2026-10-18: T2 done: `supplement-license` checks its argument, the value's type, and the AC2 rule, and stops with `stop()`; `node_at()` now serves `value()`. The AC1 and AC6 tests failed against main's Lua (copied over the working file, then restored) and pass now; `devtools::test()` clean.
- 2026-10-18: implementation choice: `checked_doi()` reads a DOI as the stringified Inlines, not the one-`Str` rule of licenses, because `doi: 10.…` holds a space that arrives as a `Space` element.
- 2026-10-18: T3 done: `supplement-doi` checks both DOI fields before it picks one; three render tests (`doi:` alone, a bad concept DOI under a good version DOI, a list) failed 6 of 6 against main's Lua and pass now; `devtools::test()` clean.
- 2026-10-18: T4 done: new `tests/testthat/test-agreement.R` runs 13 license shapes and 12 DOI shapes in each field through `write_citation()` and a render of the same quoted `_supplement.yml` (192 expectations, about 58 s); each shape's expected text or bare DOI is stated in the table. `doi_badge_rx()` and `between_markers()` moved to `helper-template.R`. The tables fail against main's Lua; `devtools::test()` clean.
- 2026-10-18: T5 done: `listed_licenses` holds each listed id's SPDX spelling and name; `supplement-license` returns a link to `https://spdx.org/licenses/<id>.html`; the template footer has no repo links. The footer test now renders two cases (CC0-1.0 with cc-by-sa-4.0, and EUPL-1.2 with an empty value) and checks text and links on both pages; its link checks fail against main's Lua and `_quarto.yml`. The `OWNER/REPO` test in `test-create-supplement.R` passes (the navbar keeps one placeholder). `devtools::test()` clean.
- 2026-10-19: T6 done: roxygen of `write_citation()` (license entry, id rule; `write_zenodo()` inherits the Errors section), template `_supplement.yml` comments, `_README.md` shortcode bullets, NEWS.md (edited the unreleased entries in place), DESIGN.md Lua bullet; `devtools::document()` rewrote both Rd files; the simple-english lint is clean on NEWS.md and `_README.md`; `devtools::test()` clean.
- 2026-10-19: claim audit: 36 claims read, 7 corrected — supplement.lua, R/supplement-yml.R, NEWS.md, inst/template/_README.md, test-write-metadata-errors.R, test-agreement.R. The parity claims now name the refused examples, not "the same values": an unquoted number or `yes` in a license value renders while `write_citation()` refuses it (added to the "shortcode edge cases" row). The re-read found all 7 correct.
- 2026-10-19: all tasks done; `devtools::test()` clean and `devtools::document()` gives no diff; status set to review.
- 2026-10-19: review return 1: AC7 fails as written — the `_README.md` shortcode text and `NEWS.md` give refused examples but do not state the new id rule (letters or digits, groups joined by one `.` or `-`, at most one final `+`).
- 2026-10-19: implement resumed for review return 1; added T7 (minor amendment) and mapped AC7 → T6, T7.
- 2026-10-19: T7 done: `_README.md`'s `supplement-license` text and the `write_citation()` bullet of NEWS.md now state the id rule; the simple-english lint is clean; `devtools::test()` clean.
- 2026-10-19: claim audit: 10 claims read, 0 corrected — NEWS.md, inst/template/_README.md (the T7 lines).
- 2026-10-19: all tasks done; status set to review.
- 2026-10-19: review return 2: blame-history #1 — a blank YAML value (null) in `license.code`, `license.content`, `zenodo.version-doi`, or `zenodo.concept-doi` stops the render, so AC1 and AC3 fail for an empty value; the return also carries the review's fix-now items (Review section, pass 2).
- 2026-10-19: implementation choice: a probe render showed Quarto gives Lua a YAML null as the Lua string "", a block or folded string as Blocks with one Para, and named arguments in `kwargs`; new `simple_value()` reads null and empty forms as empty and one-paragraph Blocks as their inlines, and both `plain_text()` and `checked_doi()` use it.
- 2026-10-19: T8 done: null and block values, a two-paragraph DOI, a named argument, and the conditional `--`/`...` hint; new render tests in test-shortcodes.R and a null-and-block agreement test in test-agreement.R failed 25 of 58 expectations against the pre-T8 Lua and pass now; `info` on both refusal checks; `_README.md`, NEWS.md, and the `license_id()` comment fixed; `devtools::document()` no diff; `devtools::test()` clean.
- 2026-10-19: correction to the T8 line above: the pre-T8 Lua failed 25 of 66 expectations in the new and changed tests, not 25 of 58.
- 2026-10-19: claim audit: 19 claims read, 4 corrected — supplement.lua, inst/template/_README.md, NEWS.md (the T8 lines). Re-read: 4 correct; the hint comment now also names the em dash.
- 2026-10-19: all tasks done; status set to review.

## Decisions

## Review

Pass 1 (2026-10-19, branch head 4d6f030, main 51d575e unmoved). `devtools::test()`: 233 tests, 2483 expectations, 0 failed, 0 errors, 1 skip (the existing case-sensitive disk test).
- AC1 evidence: test-shortcodes "a license value that is not one SPDX id stops the render and names the field" renders the 7 listed shapes in each field and checks the stop and `supplement.license.<field>` (42 expectations, 0 failed); "shows nothing for an empty value" covers `[]` and `{}` (8, 0 failed).
- AC2 evidence: `R/supplement-yml.R:258` holds the regex as written; Lua `is_license_id()` applies the same rule. test-agreement "accept and refuse the same ids" runs the 13 listed shapes in each field through `write_citation()` on `full_supplement()` and a render, with the expected text or refusal stated per shape (96 expectations, 0 failed).
- AC3 evidence: test-agreement "accept and refuse the same DOIs" runs the 12 listed shapes in each DOI field as the only DOI set (96 expectations, 0 failed); test-shortcodes "a DOI value that is not a DOI stops the render" checks a bad concept DOI under a good version DOI (6, 0 failed). A probe render of `version-doi: {id: 10.5281/zenodo.1}` and `true` stopped naming `supplement.zenodo.version-doi`, and `[]` and `{}` rendered no badge.
- AC4 evidence: test-write-metadata "one license, or two equal ones, is written as one id" checks `CC-BY-4.0`/`cc-by-4.0` → `CC-BY-4.0` and `mit`/`MIT` → `mit` in `CITATION.cff` (11 expectations, 0 failed).
- AC5 evidence: test-shortcodes "the page footer shows the licenses" renders `CC0-1.0` with `cc-by-sa-4.0` and `EUPL-1.2` with an empty value, checking footer text, SPDX links, and no `LICENSE` link on `index.html` and `analyses/example.html` (15 expectations, 0 failed). `listed_licenses` holds the 8 SPDX spellings (confirmed by the claim audit). `grep LICENSE inst/template/_quarto.yml` finds nothing.
- AC6 evidence: test-shortcodes "the license shortcode stops unless its one argument is code or content" renders no argument, `other`, and `code content`, checking the stop and the message (9 expectations, 0 failed).
- AC7 FAILED: both help pages state the id rule (`write_citation.Rd:67`, `write_zenodo.Rd:67`) and `write_citation.Rd:33` the single entry; `_supplement.yml:21` states the rule, the stops, and the links. But the `_README.md` shortcode text and `NEWS.md` give only refused examples (`CC BY 4.0`, `GPL--3.0`, a list) and do not state the new id rule. Not ticked; review return 1.

Pass 2 (2026-10-19, branch head c05aeb0, main 51d575e unmoved). Since pass 1, only `NEWS.md` and `inst/template/_README.md` changed outside `cairn/` (T7), so the AC1-AC6 evidence stands; `devtools::check()` below re-ran the whole suite with 0 failures.
- AC7 evidence: `_README.md:77-81` states the id rule ("letters and digits, with one `.` or `-` between groups and at most one `+` at the end"), the render stops, and the spdx.org links. The `NEWS.md` footer bullet states the links and the stops, and its `write_citation()` bullet states the id rule and the single entry per id. Both help pages state the rule (`write_citation.Rd:67`, `write_zenodo.Rd:67`, inherited), and `write_citation.Rd:33` states the single entry. `_supplement.yml:18-23` states the rule, the stops, and the links. The claim audit of the T7 lines read 10 claims, 0 wrong.
- Gate: `cairn_validate.py` all checks passed. `devtools::document()` gives no diff. No README.Rmd and no `_pkgdown.yml`. NEWS.md has entries for the changes. No new top-level files. `devtools::check()`: 0 errors, 0 warnings, 0 notes.
- spawned: diff-bug, blame-history, prior-review, ripple
- blame-history #1: a blank YAML value (`code:` or `version-doi:` with nothing after the colon, null) now stops the render, while main rendered it blank and `write_citation()` treats it as empty — fix now; floor return (AC1 and AC3 promise a stop only for a non-empty value), fixed fa943bf.
- diff-bug #1: a block or folded license value (`code: |` then `MIT`) stops the render with a message about spaces or Markdown, while `write_citation()` writes `MIT` — fix now (one-paragraph Blocks read as its text), fixed fa943bf.
- diff-bug #2: a DOI with Markdown emphasis (`10.5281/*zenodo*.1`) gives a badge for `10.5281/zenodo.1` while `CITATION.cff` holds the raw text — follow-up, row "footer and badge remainder".
- diff-bug #3: a block DOI with two paragraphs renders a badge for the joined text (`10.5281/zenodo.12`) while `write_citation()` refuses it — fix now (a DOI of more than one block stops), fixed fa943bf.
- diff-bug #4: `license: "MIT"` or `zenodo: "x"` (text where a map belongs) renders an empty footer or no badge, while `write_citation()` raises `supplement_error_field_type`; not new in M014 — follow-up, row "footer and badge remainder".
- diff-bug #5: unquoted `code: 1.0` shows "1" linked to spdx.org/licenses/1.html — follow-up, row "footer and badge remainder" (the gap itself is already in "shortcode edge cases").
- diff-bug #6: a site that keeps the old footer and copies in the new extension gets a link inside a link — follow-up, row "footer and badge remainder".
- diff-bug #7: the narrowed rule refuses `GPL--3.0`, `MIT.`, `MIT-`, `GPL.-3`, which passed before — reject, planned change (the plan chose the narrowing; D-012's shape-only decision stands).
- diff-bug #8: `{{< supplement-license code foo=bar >}}` passes the argument check — fix now (a named argument also stops), fixed fa943bf.
- diff-bug #9: two refusal assertions in test-agreement.R carry no `info` — fix now, fixed fa943bf.
- diff-bug #10: the license id error adds the `--` and `...` hint for every bad id — fix now (only when the id holds a dash or ellipsis that Quarto made), fixed fa943bf and d86112e.
- ripple #1: the ROADMAP row "footer and badge edge cases" still describes the fixed defects — reject, planned change (post-merge hygiene graduates the row).
- ripple #2: `_README.md:118-119` says `CITATION.cff` takes both licenses — fix now (one id when they differ only in letter case), fixed fa943bf.
- ripple (in diff): `_README.md` and NEWS.md say each name links to "the id's page at spdx.org", but an id SPDX does not list has no page — fix now (docs name the URL and say the page exists only for listed ids), fixed fa943bf and d86112e.
- prior-review #1: the footer drops the repo license links that M010 shipped — reject, planned change (the user chose SPDX links at the plan gate; AC5).
- prior-review #2: unlisted ids link to a page that does not exist — reject the behavior as planned (AC5); the doc part is the ripple (in diff) fix.
- prior-review #3: block or folded license values stop the render — fix now, same as diff-bug #1, fixed fa943bf.
- prior-review #4: unquoted numbers and `yes` render while `write_citation()` refuses them — follow-up, already in "shortcode edge cases" (M014 plan).
- blame-history #2: the footer link removal has no D-entry — reject, planned change recorded at the plan gate in the work log; the choice binds only the template footer.
- blame-history #3: shape-valid non-SPDX ids, such as `yes`, link to a missing page — reject the behavior as planned (AC5); doc fix as in ripple (in diff).
- blame-history #4: SPDX's LicenseRef idstring allows `--` and `..`, so the comment "which no SPDX id has" is too broad — fix now (comment says "no id on the SPDX License List"); the narrowing stays (plan choice), fixed fa943bf.

Pass 3 (2026-10-19, branch head d86112e, main 51d575e unmoved). Since pass 2, T8 changed `supplement.lua`, the tests, and the docs.
- AC1 evidence (re-run): test-shortcodes "a license value that is not one SPDX id stops the render" (42 expectations), "shows nothing for an empty value" now with `[]`, `{}`, a null, `~`, and `null` (all render nothing), and "a block or folded license value reads as its text, and two paragraphs stop"; test-agreement "read null and block values alike" shows a null and a block license agree with `write_citation()`. All pass in the run below.
- AC3 evidence (re-run): test-agreement "accept and refuse the same DOIs" (96 expectations) and "read null and block values alike"; test-shortcodes "a null or block DOI value reads as empty or as its text, and two paragraphs stop" and "a DOI value that is not a DOI stops the render". All pass in the run below.
- AC2, AC4, AC5, AC6, AC7: pass 1 and pass 2 evidence stands; their tests pass in the run below; AC6's test now also covers a named argument.
- Run: `devtools::test()` 237 tests, 2532 expectations, 0 failed, 0 errors, 1 skip (test-agreement.R 210 expectations, test-shortcodes.R 266, 0 failed).
- Gate: `cairn_validate.py` all checks passed; `devtools::document()` gives no diff; `devtools::check()` 0 errors, 0 warnings, 0 notes.
- spawned: diff-bug, blame-history, prior-review, ripple (on `git diff 6aec878..HEAD`)
- diff-bug #1: `_supplement.yml:20-21` and DESIGN.md still say each name links to "its page at spdx.org" — fix now, fixed 7059ec7.
- diff-bug #2: a two-paragraph license value is quoted as `'MITX'` in the error — fix now (`shown_text()` joins blocks with a space, as R does), fixed 7059ec7.
- diff-bug #3: a one-block DOI that is not a paragraph (a heading) gets "more than one paragraph" in its error — fix now (message says "text that is not one paragraph" and quotes the value), fixed 7059ec7.
- diff-bug #4: the `checked_doi()` comment omits the paragraph stop — fix now, fixed 7059ec7.
- diff-bug #5: the string branch and the empty-Blocks branch of `simple_value()` never run in Quarto 1.10 — reject, no defect (defensive branches; the reviewer showed both would still be correct).
- diff-bug #6: the two-paragraph license cases and the `GPL--3.0` hint case also pass against the pre-T8 Lua — reject, not a defect: those cases were already right before T8 and stay as agreement guards; the paired null, block, named-argument, and no-hint cases fail against the pre-T8 Lua.
- diff-bug #7: an id that SPDX lists but is not one of the 8, written in another letter case, may link to a missing page if spdx.org paths depend on case (unverified) — follow-up, row "footer and badge remainder".
- diff-bug #8: NEWS does not name the named-argument stop — fix now, fixed 7059ec7.
- blame-history #1: a LicenseRef- id with `--` is valid SPDX, which may meet the plan's falsifier for the narrowing — reject: the falsifier names ids on the SPDX License List, and such a LicenseRef- id would show with an en dash in the footer, so accepting it in R would break the agreement the goal asks for.
- blame-history #2: same as diff-bug #7 — follow-up, row "footer and badge remainder".
- blame-history #3: the `simple_value()` string branch is untested — reject, same as diff-bug #5.
- blame-history #4: a one-paragraph Blocks with no content skips the empty check — reject: the diff-bug probe showed a whitespace-only block arrives as empty Inlines, which is empty.
- blame-history #5: the switch to `expect_true(inherits())` is needed and correct — reject, no defect (confirmation).
- blame-history #6: the hint also fires for a dash typed into the file — reject: the comment says so and the hint text is true in both cases.
- blame-history #7: `value()` joins a two-paragraph `zenodo.archive-url` — follow-up, row "footer and badge remainder" (outside the criteria).
- blame-history #8: the `simple_value()` comment has a doubled `"", ""` — fix now, fixed 7059ec7.
- blame-history #9: `_README.md` "takes one of them" omits that the `license.code` spelling wins — fix now, fixed 7059ec7.
- blame-history #10: `license: "MIT"` renders blank — follow-up, already in row "footer and badge remainder".
- prior-review #1: `_supplement.yml` and `_quarto.yml` comments still say "its page at spdx.org" — fix now (with diff-bug #1), fixed 7059ec7.
- prior-review #2: the new refusal assertions in test-agreement.R carry no `info` — fix now, fixed 7059ec7.
- prior-review #3: same as blame-history #6 — reject.
- prior-review #4: same as diff-bug #3 — fix now (license message too), fixed 7059ec7.
- prior-review #5: same as diff-bug #5 — reject.
- prior-review #6: same as blame-history #9 — fix now, fixed 7059ec7.
- ripple #1: ROADMAP row "footer and badge edge cases" is stale — reject, planned change (post-merge hygiene graduates the row).
- ripple #2: ROADMAP row "shortcode edge cases" says `supplement-license` with no argument has no defined result — reject, planned change (post-merge hygiene narrows the row).
- ripple #3: same as diff-bug #8 — fix now, fixed 7059ec7.
- ripple #4: `_supplement.yml`, `_quarto.yml`, DESIGN.md spdx.org wording — fix now (with diff-bug #1), fixed 7059ec7.
- ripple #5: test-write-metadata-errors.R comment "No SPDX id has these shapes" — fix now, fixed 7059ec7.
- ripple #6: same as blame-history #9 — fix now, fixed 7059ec7.
- ripple #7: the Lua comments listing refused values omit the paragraph stop — fix now, fixed 7059ec7.
- ripple #8: helper-template.R "The SPDX page of each license id" — fix now, fixed 7059ec7.
- blame-history #5: the "unquoted number or yes still renders" comment is true but conflicts with AC2's parity — reject, false conflict: AC2's domain is the listed quoted shapes; the gap is in "shortcode edge cases".
