# M010: The footer, the DOI badge, and the citation files agree with _supplement.yml

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — the template pages and two exported writers change for site authors
- **Branch/PR:** m010-license-doi-agree

## Goal

The page footer, the DOI badge, and the two citation files agree with the license and DOI values in `_supplement.yml`.

## Scope

**In:** A new `supplement-license` shortcode in `inst/template/_extensions/supplement/supplement.lua`, which the footer in `inst/template/_quarto.yml` uses. `supplement-doi` removes a DOI link prefix before it builds the badge. `write_citation()` and `write_zenodo()` check the shape of each license id that they write. Template comments, `_README.md`, help pages, and NEWS.md describe the changes.

**Out:**
- A check of license ids against Zenodo's license list. The user chose the shape check at the plan gate (D-012).
- A check that a license id is in the CFF 1.2.0 license list. The shape check does not make `CITATION.cff` valid against the CFF schema (D-012).
- A footer with an empty license value. It shows an empty link, as now when a link text is empty.
- `supplement-license` with no argument or an argument other than `code` or `content`. This goes to the "shortcode edge cases" candidate row.
- A license check in `check_supplement()`. A bad id therefore stops `release_supplement()` only after it writes `_supplement.yml`, and the release then restores the file. This goes to the "release write order" candidate row.
- The footer link targets `LICENSE.md` and `LICENSE-CC-BY.md` stay as they are.

## Acceptance criteria

- [ ] AC1: The footer in `inst/template/_quarto.yml` takes its code license name from `{{< supplement-license code >}}` and its content license name from `{{< supplement-license content >}}`. It keeps its links to `LICENSE.md` and `LICENSE-CC-BY.md`. A render test sets `license.code` to `CC0-1.0` and `license.content` to `CC-BY-SA-4.0`. Inside `div.nav-footer-center` of `docs/index.html` and of `docs/analyses/example.html`, it finds `CC0 1.0` and `CC BY-SA 4.0`, and does not find `MIT` or `CC BY 4.0`. All four are fixed-string matches.
- [ ] AC2: `supplement-license` takes the argument `code` or `content` and maps the value of `supplement.license.<argument>` by this rule. A value equal to an id in the name table in `supplement.lua`, ignoring letter case, gives that id's readable name. An unlisted value made of letters, digits, `.`, `+`, and single `-` gives the value as written. An empty value, or an absent `license` map, gives nothing. The table holds at least `MIT` as `MIT`, `CC-BY-4.0` as `CC BY 4.0`, `CC-BY-SA-4.0` as `CC BY-SA 4.0`, and `CC0-1.0` as `CC0 1.0`. Render tests cover a listed id, a listed id in lower case, a listed id in mixed case, an unlisted id, an empty value, and an absent `license` map.
- [ ] AC3: Before it builds the badge image and link, `supplement-doi` removes a leading prefix of one of these forms, in any letter case. The forms are `doi:` followed by zero or more spaces, and `http://` or `https://` followed by an optional `dx.` or `www.` and then `doi.org/`. Render tests use six prefixes: `https://doi.org/`, `https://www.doi.org/`, `http://dx.doi.org/`, `doi:` with no space, `doi:` with one space, and `HTTPS://DOI.ORG/`. Each test finds the badge of the bare DOI. The existing bare-DOI tests in `tests/testthat/test-shortcodes.R` still pass.
- [ ] AC4: `write_citation()` checks `license.code` and `license.content`, and `write_zenodo()` checks `license.content`. When a non-empty value does not match the SPDX id shape, each stops with an error of classes `supplement_error_license` and `supplement_error`, and leaves its output file as it was. The shape is a letter or digit, then letters, digits, `.`, or `-`, and at most one final `+`. For each writer, tests use six failing shapes: a space between two words, a `/`, two ids joined by ` OR `, two final `+`, a `+` between two letters, and a leading `-`. Each test runs with an existing output file and `overwrite = TRUE`, and asserts the class and that the file's bytes did not change. Other tests show that `CC-BY-4.0` and `GPL-2.0+` write without error.
- [ ] AC5: The help pages of `write_citation()` and `write_zenodo()` name `supplement_error_license`. In `inst/template/_supplement.yml` and `inst/template/_README.md`, the sentences that say no page shows the license, and that `_quarto.yml` sets the footer license names, are gone. The DOI comment in `_supplement.yml` says that a `https://doi.org/` or `doi:` prefix is removed. The shortcode list in `_README.md` names `supplement-license`. NEWS.md has an entry for the footer, the badge prefix, and the license check.

## Coverage

- AC1 → T2
- AC2 → T1
- AC3 → T3
- AC4 → T4
- AC5 → T2, T3, T4, T5

## Tasks

- [x] T1: Add the `supplement-license` shortcode and its name table to `supplement.lua`. Add render tests for the six AC2 shapes in `tests/testthat/test-shortcodes.R`.
- [x] T2: Change the footer in `inst/template/_quarto.yml` (line 40) to use the shortcode. Update the license sentences in `_supplement.yml` (lines 3 to 4) and `_README.md` (lines 47 to 49), and add `supplement-license` to the `_README.md` shortcode list. Add the AC1 render test.
- [ ] T3: Remove the DOI prefix in `supplement-doi` (`supplement.lua` line 20). Update the DOI comment in `_supplement.yml`. Add the AC3 render tests.
- [ ] T4: Add the license shape check to `R/supplement-yml.R` and call it from `R/write-citation.R` and `R/write-zenodo.R` before any write. Document the new class in both help pages and add the AC4 tests.
- [ ] T5: Add the NEWS.md entries and update the shortcode list in the DESIGN.md Architecture section. Read the help pages and template text again against AC5.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: not run — work named at the question set.
- 2026-10-18: question set: next work — the "license footer", "badge DOI form", and "metadata value checks" candidate rows (user chose the recommended option).
- 2026-10-18: question set: footer text — readable names from a built-in table, other ids as written.
- 2026-10-18: question set: DOI link form — the badge removes the prefix, the render does not stop.
- 2026-10-18: question set: license check — shape only, no Zenodo list (recorded as D-012).
- 2026-10-18: inbox sweep: no open issues and no open PRs on jmgirard/supplement.
- 2026-10-18: collision check: the three absorbed rows only. No archived milestone or D-entry covers the footer, the badge prefix, or license ids.
- 2026-10-18: lessons applied: M009's criterion lesson (a stated rule plus a listed set of tests, input shapes over literal strings), M004's Lua lesson (`assert(false, msg)` stops a render, metadata is read as Markdown and paths are rewritten).
- 2026-10-18: question order: the work was chosen at the question set, so the criteria were drafted and audited after it.
- 2026-10-18: criteria audit (full mode, fresh Opus reader): 14 findings. Fixed: a fourth table id for AC1 and `div.nav-footer-center` as the element (1), mixed-case and absent-map probes (5), `www.` and no-space `doi:` probes (6), a space between words (8), three more failing shapes (9), both classes (10), unchanged bytes with `overwrite = TRUE` (11), the stale template passages added to AC5 (13), fixed-string matches (14). Narrowed: an empty footer value moved to Out (2), "as written" limited to plain id text (3), other arguments moved to Out (4), the `LicenseRef-` probe dropped and CFF validity moved to Out (7), the late release failure moved to Out (12). The claim that AC3 matches `bare_doi()` exactly was dropped (6).
- 2026-10-18: plan chose a shortcode in `page-footer.center` over a pre-render script that writes the footer into `_quarto.yml`, because a test render showed Quarto 1.10 runs shortcodes in the footer and the script would edit an author file on every render; falsified by a Quarto version where the footer shortcode renders as literal text.
- 2026-10-18: plan chose a shape check shared in `R/supplement-yml.R` over a check in each writer, because both writers read the same fields; falsified by a writer that needs a different id rule.
- 2026-10-18: test scope: render tests for AC1 to AC3 skip without Quarto, as the existing shortcode tests do. AC4 tests need no Quarto.
- 2026-10-18: changelog: three NEWS.md bullets under the development version.
- 2026-10-18: implement started on branch m010-license-doi-agree, cut from main at b8ba50c.
- 2026-10-18: T1 done. `supplement-license` looks up a lowercase-keyed table of eight ids and passes the value through `as_written()` first, so a value that names a path is not rewritten on subfolder pages. Three render tests cover the six AC2 shapes. `devtools::test()` clean.
- 2026-10-18: T2 done. The footer uses both shortcodes, and the `_supplement.yml` comments and `_README.md` say the footer shows the licenses. The footer render test failed four times with the old fixed footer planted, and passes with the new one. `devtools::test()` clean.

## Decisions

## Review
