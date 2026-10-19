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
- [ ] AC7: The help page of `write_citation()` describes the new id rule and the single license entry for ids that differ only in letter case, and the help page of `write_zenodo()` describes the new id rule. The comments in the template's `_supplement.yml`, the field and shortcode text of the template's `_README.md`, and `NEWS.md` describe the new id rule, the render stops, and the footer links.

## Coverage

- AC1 → T2, T4
- AC2 → T1, T2, T4
- AC3 → T3, T4
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
