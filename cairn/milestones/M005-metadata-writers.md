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

- [ ] AC1: For a fixture `_supplement.yml` with every field filled, two authors, a non-ASCII family name, a `paper-title` holding `:`, `"`, `&`, and `*text*`, and a `citation` holding `*Journal*`, `write_citation()` writes `CITATION.cff` that `yaml::read_yaml()` reads back as: `cff-version` "1.2.0"; a non-empty `message`; `title` "Supplemental materials for: " followed by `paper-title` exactly as written (Markdown is not converted); `authors` in file order, each with `family-names`, `given-names`, `orcid` as `https://orcid.org/<id>`, and `affiliation`; `doi` equal to `concept-doi`; `license` equal to `c(<code>, <content>)`.
- [ ] AC2: For the same fixture, `write_zenodo()` writes `.zenodo.json` that `jsonlite::read_json()` reads back as: `title` as in AC1; `upload_type` "software"; `description` "Supplemental materials for: " followed by `citation` exactly as written; `creators` in file order, each with `name` "<family>, <given>", `orcid` as the bare id, and `affiliation`; `license` the content SPDX id in lowercase (Zenodo's license vocabulary form, such as `cc-by-4.0`).
- [ ] AC3: Two fixtures hold one author and only the required fields: one gives every optional field as `""`, the other leaves the optional keys out or null and has no `zenodo:` map. For both, a recursive walk over each read-back file finds no `""`, null, or zero-length value, and `.zenodo.json` read with `simplifyVector = FALSE` has `creators` as a list of length 1. With `concept-doi` empty and `version-doi` set, `CITATION.cff` has `doi` equal to `version-doi`. With only one license set, or both set to the same id, `CITATION.cff` has `license` as that one id. An ORCID given as `https://orcid.org/<id>` gives the same files as the bare id.
- [ ] AC4: Each function stops with a `cli::cli_abort()` error of a class named in its help page, and a test fires each case on each function that reads the field and asserts its class: `_supplement.yml` is missing; it has no `supplement:` map; `paper-title` is absent or empty; for `write_zenodo()`, `citation` is absent or empty; `authors` is absent or empty; an author's `family` or `given` is absent or empty (an author with only `name:` gets a message naming `family:` and `given:`); an ORCID, after an optional `https://orcid.org/` prefix is removed, does not match `^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$`; the output file exists and `overwrite = FALSE`. In each case the test shows that the output file is absent or unchanged afterwards.
- [ ] AC5: The template's `_supplement.yml` gives each author `family:` and `given:` in place of `name:`, and its comments and `_README.md` name the two functions. A test copies the template to a temporary folder, runs both functions there, and gets both files with no error.
- [ ] AC6: Both functions are exported and have help pages whose examples write into `tempdir()`. NEWS.md has an entry for them. On a clean checkout, `Rscript -e 'devtools::check()'` reports 0 errors and 0 warnings, and `Rscript -e 'devtools::test()'` reports 0 failures.

## Coverage

- AC1 → T2, T3
- AC2 → T2, T4
- AC3 → T3, T4
- AC4 → T2, T5
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

## Decisions

## Review
