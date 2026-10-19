# M010: The footer, the DOI badge, and the citation files agree with _supplement.yml

- **Status:** review
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

- [x] AC1: The footer in `inst/template/_quarto.yml` takes its code license name from `{{< supplement-license code >}}` and its content license name from `{{< supplement-license content >}}`. It keeps its links to `LICENSE.md` and `LICENSE-CC-BY.md`. A render test sets `license.code` to `CC0-1.0` and `license.content` to `CC-BY-SA-4.0`. Inside `div.nav-footer-center` of `docs/index.html` and of `docs/analyses/example.html`, it finds `CC0 1.0` and `CC BY-SA 4.0`, and does not find `MIT` or `CC BY 4.0`. All four are fixed-string matches.
- [x] AC2: `supplement-license` takes the argument `code` or `content` and maps the value of `supplement.license.<argument>` by this rule. A value equal to an id in the name table in `supplement.lua`, ignoring letter case, gives that id's readable name. An unlisted value made of letters, digits, `.`, `+`, and single `-` gives the value as written. An empty value, or an absent `license` map, gives nothing. The table holds at least `MIT` as `MIT`, `CC-BY-4.0` as `CC BY 4.0`, `CC-BY-SA-4.0` as `CC BY-SA 4.0`, and `CC0-1.0` as `CC0 1.0`. Render tests cover a listed id, a listed id in lower case, a listed id in mixed case, an unlisted id, an empty value, and an absent `license` map.
- [x] AC3: Before it builds the badge image and link, `supplement-doi` removes a leading prefix of one of these forms, in any letter case. The forms are `doi:` followed by zero or more spaces, and `http://` or `https://` followed by an optional `dx.` or `www.` and then `doi.org/`. Render tests use six prefixes: `https://doi.org/`, `https://www.doi.org/`, `http://dx.doi.org/`, `doi:` with no space, `doi:` with one space, and `HTTPS://DOI.ORG/`. Each test finds the badge of the bare DOI. The existing bare-DOI tests in `tests/testthat/test-shortcodes.R` still pass.
- [x] AC4: `write_citation()` checks `license.code` and `license.content`, and `write_zenodo()` checks `license.content`. When a non-empty value does not match the SPDX id shape, each stops with an error of classes `supplement_error_license` and `supplement_error`, and leaves its output file as it was. The shape is a letter or digit, then letters, digits, `.`, or `-`, and at most one final `+`. For each writer, tests use six failing shapes: a space between two words, a `/`, two ids joined by ` OR `, two final `+`, a `+` between two letters, and a leading `-`. Each test runs with an existing output file and `overwrite = TRUE`, and asserts the class and that the file's bytes did not change. Other tests show that `CC-BY-4.0` and `GPL-2.0+` write without error.
- [x] AC5: The help pages of `write_citation()` and `write_zenodo()` name `supplement_error_license`. In `inst/template/_supplement.yml` and `inst/template/_README.md`, the sentences that say no page shows the license, and that `_quarto.yml` sets the footer license names, are gone. The DOI comment in `_supplement.yml` says that a `https://doi.org/` or `doi:` prefix is removed. The shortcode list in `_README.md` names `supplement-license`. NEWS.md has an entry for the footer, the badge prefix, and the license check.

## Coverage

- AC1 → T2
- AC2 → T1
- AC3 → T3
- AC4 → T4
- AC5 → T2, T3, T4, T5

## Tasks

- [x] T1: Add the `supplement-license` shortcode and its name table to `supplement.lua`. Add render tests for the six AC2 shapes in `tests/testthat/test-shortcodes.R`.
- [x] T2: Change the footer in `inst/template/_quarto.yml` (line 40) to use the shortcode. Update the license sentences in `_supplement.yml` (lines 3 to 4) and `_README.md` (lines 47 to 49), and add `supplement-license` to the `_README.md` shortcode list. Add the AC1 render test.
- [x] T3: Remove the DOI prefix in `supplement-doi` (`supplement.lua` line 20). Update the DOI comment in `_supplement.yml`. Add the AC3 render tests.
- [x] T4: Add the license shape check to `R/supplement-yml.R` and call it from `R/write-citation.R` and `R/write-zenodo.R` before any write. Document the new class in both help pages and add the AC4 tests.
- [x] T5: Add the NEWS.md entries and update the shortcode list in the DESIGN.md Architecture section. Read the help pages and template text again against AC5.

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
- 2026-10-18: T3 done. A Lua `bare_doi()` removes the prefixes from both DOI values before the badge is built, and the `_supplement.yml` DOI comment says so. The render test has the six AC3 prefixes plus a concept-DOI case. With main's Lua planted, all 7 cases failed. `devtools::test()` clean.
- 2026-10-18: T4 done. `license_id()` in `R/supplement-yml.R` matches `\A[A-Za-z0-9][A-Za-z0-9.-]*\+?\z` (perl) after `value()` trims spaces, and both writers call it before `check_overwrite()`. The tests run the six AC4 shapes per writer and field with an old file and `overwrite = TRUE`. With `license_id()` replaced by a no-op, the test failed. `devtools::document()` updated both Rd files. `devtools::test()` clean.
- 2026-10-18: T5 done. Three NEWS.md bullets, and DESIGN.md Architecture names the license shortcode, the badge prefix, and `license_id()`. The re-read found two more `_README.md` DOI passages that said to write a DOI without the prefix, and both now say it is removed (minor, inside AC5's intent). `devtools::document()` no diff, `devtools::test()` clean.
- 2026-10-18: claim audit: 50 claims read, 2 corrected — NEWS.md (the badge bullet now names every prefix removed, and the license bullet says `write_zenodo()` checks only `license.content`). The same reader re-read both and found them true.
- 2026-10-18: all tasks done, status set to review.
- 2026-10-18: step-7 approval: m010-license-doi-agree approved for merge

## Decisions

## Review

Pass 1, 2026-10-18, on branch head e11596b (main at b8ba50c, not moved).

- AC1: `_quarto.yml:42` footer holds `{{< supplement-license code >}}` and `{{< supplement-license content >}}` inside links to `.../LICENSE.md` and `.../LICENSE-CC-BY.md`. Test "the page footer shows the licenses set in _supplement.yml" (NOT_CRAN, Quarto 1.10.19): 14 expectations, 0 failed, 0 skipped. It sets `CC0-1.0` and `CC-BY-SA-4.0`, then reads `div.nav-footer-center` of `index.html` and `analyses/example.html` with fixed-string matches. Plant check in T2: 4 failures with main's fixed footer.
- AC2: `supplement.lua:146-153` table holds `mit`, `cc-by-4.0`, `cc-by-sa-4.0`, and `cc0-1.0` with the four required names, keyed in lowercase and looked up with `id:lower()`. Three render tests, 0 failed, 0 skipped: listed and lower-case and mixed-case ids (4 expectations), unlisted `EUPL-1.2` and `GPL-2.0+` as written (2), empty value and absent `license` map give nothing (4).
- AC3: test "the DOI badge removes a doi: or doi.org link prefix": 14 expectations, 0 failed, 0 skipped, over the six listed prefixes plus a concept-DOI case, each matched with `doi_badge_rx()` on the bare DOI. The existing tests "the DOI badge shows the version DOI, then the concept DOI" (5) and "empty DOI and archive values render nothing" (3) pass. Plant check in T3: 7 of 7 cases failed with main's Lua.
- AC4: `license_id()` (`R/supplement-yml.R`) matches `\A[A-Za-z0-9][A-Za-z0-9.-]*\+?\z` and raises classes `supplement_error_license` and `supplement_error`. `write_citation()` calls it on `license.code` and `license.content`, and `write_zenodo()` on `license.content`, before `check_overwrite()` and any write. Test "a license value that is not an SPDX id stops each writer and keeps the old file": 72 expectations (3 writer-field pairs × 6 shapes × class, `supplement_error` class, field name, unchanged bytes with `overwrite = TRUE`), 0 failed. Test "SPDX-shaped license ids are written" (`CC-BY-4.0`, `GPL-2.0+`, both writers): 4 expectations, 0 failed. Plant check in T4: the test failed with a no-op `license_id()`.
- AC5: `man/write_citation.Rd` and `man/write_zenodo.Rd` each name `supplement_error_license` once. A grep of `_supplement.yml` and `_README.md` for "license names in the page footer are" and "set in `_quarto.yml`" finds nothing, and both "No page shows" sentences now name only the preprint and authors. `_supplement.yml:38-40` says a `https://doi.org/` or `doi:` in front is removed. `_README.md:71` lists `supplement-license`. NEWS.md lines 41, 46, and 50 hold the footer, badge, and license entries.

Consistency gate: `cairn_validate.py` all checks passed. No principle changed, so `cairn_impact` was skipped. `devtools::document()` no diff. No README.Rmd and no `_pkgdown.yml`, so those checks do not apply. NEWS.md has the entries. No new top-level files. `devtools::check()`: 0 errors, 0 warnings, 0 notes (1m 58s, on 3d9d0af).

spawned: diff-bug, blame-history, prior-review

- diff-bug #1: the shape check accepts `--`, which the footer shows as an en dash — follow-up, row "footer and badge edge cases".
- diff-bug #2: the `release_supplement()` help page does not mention a bad license id — follow-up, row "footer and badge edge cases" (the late failure itself is in "release write order").
- diff-bug #3: footer link targets stay `LICENSE.md` and `LICENSE-CC-BY.md` while the label follows `_supplement.yml` — follow-up, row "footer and badge edge cases".
- diff-bug #4: the error hint says only "no spaces", which does not help for `/`, `++`, `A+B`, or `-MIT` — fix now, fixed c7f9596.
- diff-bug #5: the shortcode shows an id the writers refuse, with no stop — follow-up, row "footer and badge edge cases".
- diff-bug #6: a list value flattens to `MITApache-2.0` in the footer — follow-up, row "footer and badge edge cases".
- diff-bug #7: a prefix-only version DOI makes the badge fall back to the concept DOI — follow-up, row "footer and badge edge cases".
- diff-bug #8: `%s*` and `\s*` also match tabs, wider than AC3's "spaces" — reject, false: removing tabs too does not break AC3, and Lua matches R.
- diff-bug #9: `unique()` keeps `MIT` and `mit` as two CFF licenses — follow-up, row "footer and badge edge cases" (predates the branch).
- diff-bug #10: `write_zenodo()` does not check `license.code` — reject, planned change (AC4).
- diff-bug #11: `_README.md` DOI sentence named only `https://doi.org/` — fix now, fixed c7f9596.
- diff-bug #12: an unwrapped 110-character comment line in `_supplement.yml` and long R lines — fix now, fixed c7f9596.
- diff-bug #13: the DOI-prefix test does not pass stderr as `info` — fix now, fixed c7f9596.
- blame-history #1: the footer label and link target can disagree — follow-up, row "footer and badge edge cases" (same as diff-bug #3).
- blame-history #2: a render succeeds with an id the writers refuse — follow-up, row "footer and badge edge cases" (same as diff-bug #5).
- blame-history #3: SPDX expressions such as `MIT OR Apache-2.0` now stop the writers — reject, planned change (AC4, D-012).
- blame-history #4: two copies of the DOI prefix rule with no shared test — follow-up, row "footer and badge edge cases".
- blame-history #5: the `_supplement.yml` DOI comment reverses M004's "write a DOI without https://doi.org/" — reject, planned change (AC5, plan gate).
- blame-history #6: `gpl-3.0-only` read "GPL 3.0", dropping "only" — fix now, now "GPL 3.0 only", fixed c7f9596.
- prior-review #1: `--` in an id becomes an en dash in the footer (M004 lesson) — follow-up, row "footer and badge edge cases" (same as diff-bug #1).
- prior-review #2: an empty license value gives an empty footer link — reject, planned change (Scope Out).
- prior-review #3: a list value shows in the footer while the writers refuse it — follow-up, row "footer and badge edge cases" (same as diff-bug #6).

Return floor: no finding shows a criterion failing or a load-bearing defect, so status stays `review`. After the fixes, `devtools::document()` no diff and `devtools::test()` clean.
