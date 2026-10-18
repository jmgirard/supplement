# M005: Metadata writers for CITATION.cff and .zenodo.json

- **Status:** review
- **Priority:** high
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — exported R functions that write files Zenodo and GitHub read
- **Branch/PR:** m005-metadata-writers

## Goal

Export `write_citation()` and `write_zenodo()`, which write `CITATION.cff` and `.zenodo.json` from the template's `_supplement.yml`.

## Scope

**In:** The package's first R code: `write_citation(path = ".", overwrite = FALSE)` and `write_zenodo(path = ".", overwrite = FALSE)`, each reading `<path>/_supplement.yml` and writing its file into `<path>`. yaml, jsonlite, and cli in Imports. The template's authors change from `name:` to `family:` and `given:`. Roxygen help, NEWS.md entry, and a `_README.md` note on the two functions.

**Out:**
- A structured `preferred-citation` for the paper in `CITATION.cff`: not planned, because `supplement.citation` is free text with no fields to map.
- Version and release date in either file → the "release checks" candidate row, whose `release_supplement()` sets the version.
- Related identifiers (preprint link, paper DOI) in `.zenodo.json` → not planned; a new candidate row only if an author asks.
- Showing authors or licenses on a page → the "license footer" candidate row.

## Acceptance criteria

- [x] AC1: For a fixture `_supplement.yml` with every field filled, two authors, a non-ASCII family name, a `paper-title` holding `:`, `"`, `&`, and `*text*`, and a `citation` holding `*Journal*`, `write_citation()` writes `CITATION.cff` that `yaml::read_yaml()` reads back as: `cff-version` "1.2.0"; a non-empty `message`; `title` "Supplemental materials for: " followed by `paper-title` exactly as written (Markdown is not converted); `authors` in file order, each with `family-names`, `given-names`, `orcid` as `https://orcid.org/<id>`, and `affiliation`; `doi` equal to `concept-doi`; `license` equal to `c(<code>, <content>)`.
- [x] AC2: For the same fixture, `write_zenodo()` writes `.zenodo.json` that `jsonlite::read_json()` reads back as: `title` as in AC1; `upload_type` "software"; `description` "Supplemental materials for: " followed by `citation` exactly as written; `creators` in file order, each with `name` "<family>, <given>", `orcid` as the bare id, and `affiliation`; `license` the content SPDX id in lowercase (Zenodo's license vocabulary form, such as `cc-by-4.0`).
- [x] AC3: Two fixtures hold one author and only the required fields: one gives every optional field as `""`, the other leaves the optional keys out or null and has no `zenodo:` map. For both, a recursive walk over each read-back file finds no `""`, null, or zero-length value, and `.zenodo.json` read with `simplifyVector = FALSE` has `creators` as a list of length 1. With `concept-doi` empty and `version-doi` set, `CITATION.cff` has `doi` equal to `version-doi`. With only one license set, or both set to the same id, `CITATION.cff` has `license` as that one id. An ORCID given as `https://orcid.org/<id>` gives the same files as the bare id.
- [x] AC4: Each function stops with a `cli::cli_abort()` error of a class named in its help page, and a test fires each case on each function that reads the field and asserts its class: `_supplement.yml` is missing; it has no `supplement:` map; `paper-title` is absent or empty; for `write_zenodo()`, `citation` is absent or empty; `authors` is absent or empty; an author's `family` or `given` is absent or empty (an author with only `name:` gets a message naming `family:` and `given:`); an ORCID, after an optional `https://orcid.org/` prefix is removed, does not match `^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$`; the output file exists and `overwrite = FALSE`. In each case the test shows that the output file is absent or unchanged afterwards.
- [x] AC5: The template's `_supplement.yml` gives each author `family:` and `given:` in place of `name:`, and its comments and `_README.md` name the two functions. A test copies the template to a temporary folder, runs both functions there, and gets both files with no error.
- [x] AC6: Both functions are exported and have help pages whose examples write into `tempdir()`. NEWS.md has an entry for them. On a clean checkout, `Rscript -e 'devtools::check()'` reports 0 errors and 0 warnings, and `Rscript -e 'devtools::test()'` reports 0 failures.

## Coverage

- AC1 → T2, T3
- AC2 → T2, T4
- AC3 → T3, T4
- AC4 → T2, T5, T8
- AC5 → T1, T6
- AC6 → T1, T6, T7

## Tasks

- [x] T1: DESCRIPTION Imports yaml, jsonlite, cli. Template `_supplement.yml`: authors as `family:` and `given:`, header comment updated (authors are now read by the two functions).
- [x] T2: Internal reader in `R/supplement-yml.R`: read `<path>/_supplement.yml`, check the AC4 error cases, return the `supplement` map with empty strings and nulls treated alike. ORCID normalizer to the bare id.
- [x] T3: `write_citation()` in `R/write-citation.R`: build the list, drop empty values, write with `yaml::write_yaml()` in UTF-8. Tests with the AC1 and AC3 fixtures; write the expected values from the CFF 1.2.0 schema guide, not from the function's output.
- [x] T4: `write_zenodo()` in `R/write-zenodo.R`: build the list, write with `jsonlite::write_json(auto_unbox = TRUE, pretty = TRUE)`, keeping `creators` an array. A code comment cites Zenodo's license vocabulary (`https://zenodo.org/api/vocabularies/licenses/cc-by-4.0` gives id `cc-by-4.0`). Tests with the AC2 and AC3 fixtures.
- [x] T5: Error tests for every AC4 case on both functions, each with `expect_error(class =)` and a check that the output file is absent or unchanged.
- [x] T6: Template test (AC5) and planted-defect check in a scratch copy, one at a time, each in each function it applies to: `doi` from `version-doi` first; empty values kept (per file); `orcid` without the URL prefix in CFF and with it in Zenodo; authors reversed; Zenodo `name` as "Given Family"; Zenodo license from `code`; `creators` unboxed to an object for one author; `overwrite` ignored; one AC4 error without its class. Each must make a test fail; record the results in the work log.
- [x] T7: `_README.md` paragraph on the two functions. Roxygen help with examples that copy the template from `system.file()` into `tempdir()`; the `write_zenodo()` page says Zenodo shows only the content license and uses `.zenodo.json` over `CITATION.cff`. `devtools::document()`, NEWS.md entry (with the `name:` to `family:`/`given:` change), DESIGN.md Function Families and Architecture updated, then `devtools::check()`.
- [x] T8: Review return 1: a `_supplement.yml` whose top level is a scalar or a list of scalars gives `supplement_error_no_map`; add both inputs to the no-map test.
- [x] T9: Review pass 1 fix-now findings: classed error for a non-map `license`/`zenodo` and for a list where one text value is expected; ORCID check digit; strip a `https://doi.org/` prefix from DOIs; quote every string in CITATION.cff; check `path` and `overwrite`, and refuse a folder named like the output file; message for `authors` as a list of strings; trim values (folded YAML); hand-written full fixture, `.na`, and missing-path tests; DESIGN.md sentence fix. Update help pages and the guide.

## Work log

- 2026-10-18: created by /milestone-plan.
- 2026-10-18: tier check: not run — work named at the question set.
- 2026-10-18: question set: next work — the "metadata writers" candidate row.
- 2026-10-18: question set: dependencies — yaml, jsonlite, and cli granted for Imports (D-009).
- 2026-10-18: question set: author names — separate `family:` and `given:` keys in `_supplement.yml`.
- 2026-10-18: question set: Zenodo license — the content license.
- 2026-10-18: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-18: collision check: absorbs the "metadata writers" candidate row; no planned or archived milestone and no D-entry covers it. The "license footer" row also reads `license`, but it changes a page, so it stays a separate row.
- 2026-10-18: plan gate chose `doi` from `concept-doi` first in `CITATION.cff` over `version-doi` first (the badge's order) because the file in the repository cannot know the DOI of its own future release; falsified by Zenodo or GitHub reading `CITATION.cff` per release and expecting that release's DOI.
- 2026-10-18: plan gate chose `upload_type` "software" over "dataset" because it is the type Zenodo's GitHub integration gives a release by default; falsified by authors whose archive Zenodo lists under the wrong type.
- 2026-10-18: plan gate chose `overwrite = FALSE` with a classed error over always overwriting because an author may have edited the file by hand; falsified by authors who regenerate both files on every DOI change and find the argument a burden.
- 2026-10-18: plan gate chose a hand-written expected list from the CFF 1.2.0 schema guide over a schema validator because no validator is installed and adding one is a dependency the question set did not cover; falsified by a written file that GitHub's citation widget or Zenodo rejects.
- 2026-10-18: plan gate chose passing Markdown in `paper-title` and `citation` through unchanged over stripping or converting it because both need a Markdown parser the package does not have; falsified by authors who find literal asterisks on their Zenodo record a problem.
- 2026-10-18: criteria audit (full mode, Opus): 11 findings, all fixed in the wording above. AC1 no longer names how the test oracle was made (moved to T3); `license` form, Markdown pass-through, and `&`/`*` fixture values stated; Zenodo's lowercase license id confirmed against its license vocabulary before the criterion was kept; AC3 split into `""` and absent/null fixtures, a recursive walk replaces the listed keys, and `creators` stays an array; ORCID pattern named; required fields per function stated; absent and empty authors' names both error; T6 probes widened per function; T7 examples copy the template.
- 2026-10-18: implement started on branch m005-metadata-writers.
- 2026-10-18: T1 done: Imports cli, jsonlite, yaml; template authors as `family:`/`given:` with an ORCID form comment. Minor amendment: the `_README.md` paragraph moved from T1 to T7, so it is written against the finished functions. devtools::test() 0 failures.
- 2026-10-18: T2-T5 done: reader and checks in `R/supplement-yml.R`, `write_citation()`, `write_zenodo()`; NAMESPACE removed and regenerated by roxygen. Error classes chosen: `supplement_error` plus one of `_no_metadata`, `_no_map`, `_missing_field`, `_authors`, `_author_name`, `_orcid`, `_file_exists`. `CITATION.cff` opens with two comment lines naming its source. Tests in `test-write-metadata.R` and `test-write-metadata-errors.R`, 0 failures.
- 2026-10-18: T6 done: template-copy test added. Planted defects, one at a time in a scratch copy, failing tests per defect: doi version-first (cff) 2; empty values kept cff 9, zenodo 10; orcid unprefixed in cff 1; orcid prefixed in zenodo 1; authors reversed cff 1, zenodo 2; zenodo name "Given Family" 5; zenodo license from code 3; creators unboxed 4; overwrite forced FALSE cff 1, zenodo 1; overwrite never checked cff 2, zenodo 2; orcid error unclassed 1; author-name error unclassed 2. Every defect failed at least one test.
- 2026-10-18: T7 done: `_README.md` "Citation files" section, NEWS.md entries (functions and the `name:` change), DESIGN.md Function Families and Architecture. devtools::document() no diff; devtools::check() 0 errors, 0 warnings, 0 notes; devtools::test() 0 failures.
- 2026-10-18: claim audit: 52 claims read, 6 corrected — R/write-citation.R, R/write-zenodo.R, inst/template/_README.md, tests/testthat/test-write-metadata-errors.R. Fixes: YAML parse errors are not classed; values pass through the YAML parser (quote them); `.zenodo.json`'s `license` field, not a Zenodo record, holds one license; the authors error also covers a map; the guide names which file takes which values; one test name narrowed. The same reader re-read the six and found them correct.
- 2026-10-18: implement complete; status set to review (commit 6c557a9 landed without this line and the claim-audit line; both added here).
- 2026-10-18: review return 1: AC4 fails for a `_supplement.yml` whose top level is a scalar or a list of scalars (base `subscriptOutOfBoundsError`, not `supplement_error_no_map`; diff-bug #1). The fix-now findings of pass 1 (diff-bug #2-5, #7-9, #11, #14; prior-review #2) are fixed in the same return; see the Review section.
- 2026-10-18: implement resumed for return 1; minor amendment: T8 (the return) and T9 (pass 1 fix-now findings) added, Coverage AC4 → T8.
- 2026-10-18: T8-T9 done: top level checked as a map before indexing; new classes `supplement_error_argument` and `supplement_error_field_type`; ORCID check digit (ISO 7064 MOD 11-2; fixture ORCID changed to 0000-0002-1694-233X, a valid X iD); DOI prefix stripped; every CITATION.cff value double-quoted; values trimmed; folder with the output name refused; authors list-form message; DESIGN sentence fixed. An ORCID with outer spaces is now accepted after trimming, so that error-test input became "0000-0002-1825-0097 x". Planted defects, one each in a scratch copy, failing tests: map check removed 1; check digit skipped 8; DOI prefix kept 2; CFF unquoted 6; no trim 1; list keeps first item 13; non-map license accepted 1; argument check skipped 1; output-named folder accepted 1; list-form message lost 2. devtools::test() 0 failures.
- 2026-10-18: claim audit: 25 claims read, 4 corrected — R/write-citation.R, R/supplement-yml.R (return 1 lines, diff 781c7d1..HEAD). Fixes: the DOI bullet names both stripped prefixes; `supplement_error_argument` says "a single non-missing character string"; `supplement_error_field_type` says only `write_citation()` reads `zenodo`; the `bare_doi()` comment names both prefixes. The `value()` and `map_field()` comments now name their errors. The same reader re-read them and found them correct. devtools::document() regenerated; devtools::check() 0/0/0.
- 2026-10-18: implement complete after return 1; status set to review.
- 2026-10-18: step-7 approval: m005-metadata-writers approved for merge

## Decisions

## Review

Pass 1, 2026-10-18, branch m005-metadata-writers at 781c7d1, level with origin/main 67b0fe1. Full suite: 42 tests, 346 expectations, 0 failed, 0 errors, 0 skipped.

- AC1: test-write-metadata.R "write_citation() writes every field of a full _supplement.yml" passes (4 expectations): the fixture in helper-metadata.R has two authors, family name "Müller" (`ü`), a paper-title with `:`, `"`, `&`, `*text*`, and a citation with `*Journal*`; read-back equals cff-version 1.2.0, the title, both authors with URL ORCIDs and affiliations, doi = concept-doi, license c("MIT", "CC-BY-4.0"); message non-empty.
- AC2: test-write-metadata.R "write_zenodo() writes every field of a full _supplement.yml" passes (2 expectations): `read_json()` of the same fixture equals title, upload_type "software", description "Supplemental materials for: " plus the citation verbatim, creators "Doe, Jane Q." and "Müller, Änne" with bare ORCIDs and affiliations, license "cc-by-4.0".
- AC3: test-write-metadata.R passes "empty and absent optional values are left out of both files" (18; three fixtures: all optional `""`, keys absent with no `zenodo:` map, keys null via `:`/`~`/`null` with no `zenodo:` map; `empty_paths()` recursive walk empty for both files), "one author is written as a list of one" (4; `creators` length 1 under `simplifyVector = FALSE`, raw text `"creators": [`), "the DOI falls back to version-doi" (1), "one license, or two equal ones, is written as one id" (7), "an ORCID iD as a URL gives the same files as the bare iD" (2, byte-equal lines).
- AC4: all 10 tests in test-write-metadata-errors.R pass (114 expectations), each `expect_error(class =)` plus a file-absent check, on both functions for every case they read: no file; no map (3 forms); paper-title absent, `""`, blank; citation absent or `""` (zenodo refuses, citation writes); authors absent, empty list, `""`, a map; family or given absent or `""`, author as a bare string; `name:`-only author's message names `family:` and `given:`; 8 malformed ORCIDs; existing file kept byte-equal with `overwrite = FALSE`. grep: each of the 7 class names appears in man/write_citation.Rd and man/write_zenodo.Rd.
- AC5: test "both files are written in a copy of the template" passes (8): every template author has `family` and `given` and no `name`; both functions run with no error in a copy of `inst/template`. grep: `inst/template/_supplement.yml:6` and `inst/template/_README.md:76-81` name both functions.
- AC6: NAMESPACE exports `write_citation` and `write_zenodo`; both Rd files carry examples writing to `file.path(tempdir(), "my-supplement")`; NEWS.md:11 has the entry. A fresh `git clone` of the branch: `devtools::check()` 0 errors, 0 warnings, 0 notes (examples and tests run). `devtools::test()` in the checkout: 0 failures.
- Consistency gate: `cairn_validate.py` all checks passed; no principle changed (cairn_impact skipped); `devtools::document()` no diff; no README.Rmd or `_pkgdown.yml`; NEWS.md entry present; no new top-level file needs `.Rbuildignore`; `devtools::check()` on a clean clone 0/0/0.
- spawned: diff-bug, blame-history, prior-review
- diff-bug #1: a top-level scalar or list of scalars in `_supplement.yml` gives base `subscriptOutOfBoundsError`, not `supplement_error_no_map` (supplement-yml.R:14) — fix now; demonstrates AC4 failing, so review return 1
- diff-bug #2: a non-map `license` or `zenodo` value is dropped with no message — fix now (classed error)
- diff-bug #3: a sequence where one text value is expected keeps its first item (`value()`) — fix now (classed error)
- diff-bug #4: ORCID check digit (ISO 7064 MOD 11-2) not checked — fix now
- diff-bug #5: a DOI with a `https://doi.org/` prefix is written as-is, invalid CFF `doi` — fix now (strip the prefix, as for ORCID); same as prior-review #1
- diff-bug #6: license ids not checked against SPDX shape or Zenodo's vocabulary — follow-up, new row "metadata value checks"
- diff-bug #7: strings such as `1e3` written unquoted read as numbers under YAML 1.2 parsers — fix now (quote every string in CITATION.cff)
- diff-bug #8: `path` and `overwrite` not checked; a folder named CITATION.cff gives a base error — fix now
- diff-bug #9: `authors` as a list of strings says "missing or empty" — fix now (message names the list form)
- diff-bug #10: no `_pkgdown.yml` reference rows — follow-up, absorbed into the "docs site and walkthrough" row (no pkgdown site exists yet)
- diff-bug #11: fixtures pass only through R's yaml writer; no `.na` or nonexistent-path case — fix now (hand-written full fixture, `.na`, missing path)
- diff-bug #12: Markdown `&`/`<` in `citation` reach Zenodo's HTML description — reject, planned change (plan gate chose pass-through, falsifier recorded)
- diff-bug #13: long CITATION.cff values fold across lines — reject, style (valid YAML)
- diff-bug #14: DESIGN.md Architecture sentence has non-agreeing verbs — fix now
- diff-bug #15: `%||%` defined in the package and a test helper — reject, style (harmless)
- blame-history #1: template authors `name:` → `family:`/`given:` breaks M004-seeded sites — reject, planned change (AC5; NEWS line and error hint)
- blame-history #2: D-005/D-007 text says no Imports — reject, false: history is not edited (IP4) and D-009's heading names the extension
- blame-history #3: Markdown pass-through is not a D-entry — reject, planned change (milestone-local choice in the work log)
- blame-history #4: CFF `license` as a list may be invalid — reject, false: CFF 1.2.0 allows a list of SPDX ids (criteria audit, high confidence)
- prior-review #1: DOI URL prefix written into CITATION.cff (M004 diff-bug #16 shape) — fix now, with diff-bug #5
- prior-review #2: a folded YAML value keeps its trailing newline in `.zenodo.json` (M004 diff-bug #1 shape) — fix now (trim values)
- prior-review #3: Markdown kept as literal asterisks — reject, planned change
- fix-now items above: fixed 9c9a581 (diff-bug #2, #3, #4, #5, #7, #8, #9, #11, #14; prior-review #1, #2), claim wording 8d2fcc5.

Pass 2, 2026-10-18, branch at 8d2fcc5, level with origin/main 67b0fe1. Full suite: 51 tests, 452 expectations, 0 failed, 0 errors, 0 skipped.

- AC1 (pass 2): "write_citation() writes every field of a full _supplement.yml" passes (4), now with ORCID 0000-0002-1694-233X; "a hand-written _supplement.yml gives the same files as the R-written one" passes (2).
- AC2 (pass 2): "write_zenodo() writes every field of a full _supplement.yml" passes (2); the hand-written fixture test covers `.zenodo.json` too.
- AC3 (pass 2): the five AC3 tests named in pass 1 pass (18, 4, 1, 7, 2), plus "folded values and outer spaces are trimmed, and .na counts as empty" (5) and "a DOI written as a URL is written bare" (2).
- AC4 (pass 2): all 15 tests in test-write-metadata-errors.R pass (211 expectations). "_supplement.yml without a supplement map is refused" (24) now includes a top-level scalar, a top-level list, and an empty file, each giving `supplement_error_no_map` from both functions with no output file. The other AC4 cases pass as in pass 1; 10 malformed ORCIDs including two bad check digits. grep: all 9 class names appear in both Rd files.
- AC5 (pass 2): "both files are written in a copy of the template" passes (8); template files unchanged since pass 1.
- AC6 (pass 2): fresh `git clone` at 8d2fcc5: `devtools::check()` 0 errors, 0 warnings, 0 notes; `devtools::test()` 0 failures; exports and NEWS entry unchanged.
- Consistency gate (pass 2): `cairn_validate.py` all checks passed; `devtools::document()` no diff; no README.Rmd or `_pkgdown.yml`; no principle changed.
- spawned: diff-bug, blame-history, prior-review
- diff-bug #1: a DOI such as `doi:10.5281/zenodo.1` or `HTTPS://DOI.ORG/...` is written in an invalid CFF form — fix now (strip `doi:` and any-case `http(s)://(dx.|www.)doi.org/`, then a classed error unless it starts `10.`)
- diff-bug #2: plain YAML numbers and booleans (`No`, `1.10`, `0755`) are written as converted text — fix now (a value YAML reads as a number or true/false is a classed error asking for quotes); same as prior-review #1
- diff-bug #3: a huge number reads as NA and gives a misleading "no given name" — fix now, with #2
- diff-bug #4: a one-item sequence `[A paper]` passes as one value — fix now (sequences read as lists)
- diff-bug #5: a literal block keeps inner line breaks — fix now (inner runs of spaces and line breaks become one space)
- diff-bug #6: Unicode spaces such as U+00A0 are not trimmed, so a blank affiliation is written — fix now
- diff-bug #7: `http://orcid.org/` refused while `http://dx.doi.org/` is accepted — fix now (accept http and https for ORCID)
- diff-bug #8: `{.obj_type_friendly}` needs cli 3.4.0 with no version floor — fix now by dropping that markup (a version floor is a dependency re-pin the question set did not grant)
- diff-bug #9: `path = ""` passes the argument check — fix now
- diff-bug #10: `supplement: {}` gives `supplement_error_missing_field`, not `_no_map` — reject, false: the map is present and `paper-title` is missing, which that class names
- diff-bug #11: no `_pkgdown.yml` rows — follow-up, already in the "docs site and walkthrough" row (pass 1)
- diff-bug #12: the template's ORCID example `0000-0000-0000-0000` fails the new check digit — fix now (use 0000-0002-1825-0097); same as blame-history #3
- diff-bug #13: a dangling symlink named CITATION.cff skips the overwrite check — fix now
- diff-bug #14: the quoting test does not check list items — fix now
- blame-history #1: CITATION.cff takes `concept-doi` first while the badge takes `version-doi` first — reject, planned change (plan gate recorded why); fix now the guide sentence so it names which DOI
- blame-history #2: plan-gate choices are not D-entries — reject, false: they are milestone-local choices, recorded in the work log as plan step 4 asks
- blame-history #3: stale ORCID example — fix now, with diff-bug #12
- blame-history #4: the badge does not strip a DOI URL prefix while CITATION.cff does — follow-up, new row "badge DOI form"
- prior-review #1: plain booleans and numbers converted silently — fix now, with diff-bug #2
- prior-review #2: the "license footer" row says no page reads `license`, and the citation writers now read it — follow-up, row text updated
- prior-review #3: a bare-string author in a mixed list gets no list-form hint — fix now (the author-name message gives the list form)
- pass 2 fix-now items: fixed 0dd7550 (diff-bug #1-9, #12-14; blame-history #1 guide sentence, #3; prior-review #1, #3). Writing them showed `Sys.readlink()` returns NA for a missing file, so the first link check refused every new file; the tests caught it and the check reads `!is.na(link) && nzchar(link)`. Planted defects, one each in a scratch copy, failing tests: sequences simplified 4; numbers/booleans accepted 9; inner spaces kept 6; ASCII-only spaces 2; DOI not validated 24; `doi:` kept 1; DOI prefix case-sensitive 1; http ORCID refused 1; empty path accepted 1; dangling link missed 3; bare-string hint lost 2; list items unquoted 1. After the fixes: 57 tests, 536 expectations, 0 failed; `devtools::check()` 0/0/0; `devtools::document()` no diff; `cairn_validate.py` passed.
