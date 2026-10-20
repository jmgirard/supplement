# M021: The link check reads links only from tags

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — `check_supplement()` is exported, and its `broken-link` rows decide whether a release goes ahead
- **Branch/PR:** m021-link-reader

## Goal

`check_supplement()` reads link values only from the start tags of a page, by stated rules for attribute names, values, and character references, so page text gives no `broken-link` row and an encoded link is checked as the file name it names.

## Scope

**In:** a tag reader in base R in `R/check-supplement.R` in place of the pattern in `page_links()` (around line 298). It skips comments and the text of `<script>`, `<style>`, `<textarea>`, and `<title>`, reads `href`, `src`, and `xlink:href` in any letter case, reads quoted and unquoted values, decodes five named character references and number references, and trims the value. The `broken-link` bullet of the help page, a NEWS.md entry, the `cairn/DESIGN.md` Architecture text, and tests.

**Out:** which pages are read (hidden folders), symbolic links in `docs/`, and link loops → M022. Requests to web addresses → the "Check web links on the rendered site" row. These cases, where the reader differs from a browser, are stated limits on the help page (AC6) and are not fixed here: the text of `<noscript>`, `<xmp>`, `<iframe>`, `<noembed>`, `<noframes>`, and `<plaintext>`, and `<![CDATA[…]]>` sections, are read as markup; the four skipped elements are skipped the same way inside `<svg>` and `<math>`; a comment ends only at the first `-->`; a second attribute of the same name is also read; named references other than the five, references with no `;`, and the number references that AC4 leaves as written are not decoded. An HTML parser package such as xml2 → not used (question set, 2026-10-19).

## Acceptance criteria

- [ ] AC1: Text in the places listed here gives no `broken-link` row. A test page puts `href="gone-a.csv"` and `src="gone-b.png"` in each place: an HTML comment on one line, an HTML comment over three lines, the text of a `<script>`, `<style>`, `<textarea>`, and `<title>` element (an end tag in any letter case, such as `</SCRIPT>`), and the text of a `<code>` and a `<p>` element. None of these gives a row. After each place, the page has a real link to a missing file, which gives a row, and `<script src="gone.js">` gives a row for its start tag.
- [ ] AC2: An attribute is read when its whole name, compared without letter case, is `href`, `src`, or `xlink:href`. A test page has one link to a missing file for each of these shapes, and each gives a row: `HREF="…"`, `Src="…"`, `XLINK:HREF="…"`, `href = "…"` (spaces around `=`), and an `href` after a quoted value that holds `>` (`title="a > b"`). A link to a missing file in an attribute named `data-href`, `data-src`, or `ng-src` gives no row.
- [ ] AC3: A value in double quotes, in single quotes, or with no quotes is read; an unquoted value runs to the next space, tab, line break, or `>`. Each value is handled in this order: character references are decoded (AC4); spaces, tabs, line breaks, and form feeds at the start and end are removed, and tabs and line breaks inside are dropped; the skip of values that start with a scheme, `/`, or `#` is applied; then percent decoding, as today. A row shows the value after the first two steps. Tested shapes: `href=" data/ok.csv "` and `href=data/ok.csv` reach the existing file `data/ok.csv` and give no row; `href=gone-c.csv` and `href='gone-d.csv'` give a row; `href=data/ok.csv/` gives a row with the link `data/ok.csv/`; `href="&#109;ailto&#58;a@example.org"` gives no row.
- [ ] AC4: In a value, `&amp;`, `&lt;`, `&gt;`, `&quot;`, and `&apos;` (lower case, with the `;`) are decoded, and so is a number reference written `&#N;`, `&#xH;`, or `&#XH;` that names a code point from 1 to 0x10FFFF, other than a surrogate (0xD800 to 0xDFFF) or 128 to 159. Tested shapes: `R&amp;D.csv`, `R&#38;D.csv`, and `R&#x26;D.csv` reach the existing file `R&D.csv` and give no row; `data/a&#37;20b.csv` reaches the existing file `data/a b.csv` and gives no row. These stay as written and give a row when no file has that name: `R&eacute;.csv`, `R&AMP;D.csv`, `R&ampD.csv`, `R&#38D.csv`, `R&#0;.csv`, `R&#xD800;.csv`, `R&#x110000;.csv`, and `R&#x80;.csv`.
- [ ] AC5: On the link shapes that the broken-link test of `tests/testthat/test-check-supplement.R` writes at commit `a01b723`, and on the site that the test "a rendered site in a git repository has no problems" renders from the template, `check_supplement()` gives the same `broken-link` rows as at commit `a01b723`.
- [ ] AC6: The `broken-link` bullet of the `check_supplement()` help page states the rules of AC1 to AC4 (the elements whose text is skipped, the attribute names, the value forms and the order of steps, the decoded references) and the limits listed in Out. NEWS.md has an entry for the change.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T2, T4
- AC6 → T3

## Tasks

- [x] T1: In `tests/testthat/test-check-supplement.R`, add one test per criterion AC1 to AC4 with the listed shapes, built with `write_page()` and `touch()`. Each test asserts the exact set of (file, link) pairs, as the existing broken-link test does at line 318. Run them before T2 and see each fail for the shape it targets (for example the comment link giving a row), not only fail.
- [x] T2: In `R/check-supplement.R`, replace the `regmatches()` pattern in `page_links()` with a reader that walks the page text: it skips `<!--` to the first `-->`, other `<!…>` and `<?…>` to `>`, and the text of the four elements to their end tag; it reads attributes from each start tag and keeps the values of the three names; it decodes and trims each value in the AC3 order (a helper beside `percent_decode()`). Keep `link_ok()` as it is. Run `devtools::test()`; the existing broken-link test and the rendered-site test must pass unchanged.
- [x] T3: Update the `broken-link` bullet in the roxygen block at the top of `R/check-supplement.R`, from a same-session read of the code; run `devtools::document()`. Add a NEWS.md bullet. Update the `R/check-supplement.R` text in the `cairn/DESIGN.md` Architecture section.
- [ ] T4: Run `devtools::check()` on the Mac (0 errors, 0 warnings).

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: not run — work named at the question set.
- 2026-10-19: question set: what to plan — the "Fix false positives in the link check" row; how to read pages — a tag reader in base R, after the user asked for the weight of xml2 (1.6.0, about 2.5 MB installed, compiled, needs libxml2 on Linux, adds xml2 and rlang to Imports) against the base R reader (about 80 to 120 lines); `xlink:href` — keep checking it; a symbolic link in `docs/` to a place outside `docs/` — counts as broken (M022).
- 2026-10-19: collision check: absorbs the "Fix false positives in the link check" row in full, across M021 and M022 (the reading defects here, the page-listing and link defects in M022); extends M008 (done), which chose a pattern over an HTML parser; "Check web links on the rendered site" and "Detect broken file links on Windows" are separate scopes; DECISIONS.md headings (D-001 to D-016) hold no match; GitHub inbox: 0 open issues, 0 open PRs.
- 2026-10-19: split: M021 covers how a page's links are read; the hidden-folder, symbolic-link, and loop defects become M022 (planned now, depends on M021, because both edit `check_links()` and `page_links()`). Not a feature series: each is a complete fix with its own NEWS entry.
- 2026-10-19: lessons applied: M009 (each criterion is a stated rule plus listed test shapes), M008 (read text as UTF-8, match without `useBytes`), M007 (`(*UCP)` and `\z` with `perl = TRUE`), M010 (see each new test fail before the fix).
- 2026-10-19: criteria audit (full, one fresh Opus reader over M021 and M022, run after the question set because the work was chosen there): 8 findings on M021, all taken. AC1 narrowed from all text outside tags to the listed places, with the browser-only elements, CDATA, SVG and MathML content, and comment ends moved to stated limits, and a `<script src>` shape added; AC3 now states the order of decoding, trimming, the scheme skip, and percent decoding, what a row shows, and the unquoted trailing `/` and encoded `mailto:` shapes; AC4 no longer claims browser behavior for references with no `;` or out-of-range numbers (now stated limits with listed shapes), and its `&#37;20` shape names a file; AC5 now names input shapes and the rendered template site rather than binding the test file; AC6 now also binds the limits. The title dropped "as a browser does".
- 2026-10-19: plan gate chose a tag reader in base R over xml2 in Imports, because it adds no compiled dependency and its rules can be stated and tested one by one; falsified by a Quarto page whose links the reader reads differently from a browser in a way the stated rules cannot fix.
- 2026-10-19: plan decided to read unquoted values, which the pattern skipped, because the reader must parse them to find the next attribute and a browser follows them.
- 2026-10-19: started on branch `m021-link-reader`, cut from `main` at `99abded`.
- 2026-10-19: T1: four tests added after the broken-link test; before T2 each failed on its target shape (comment and raw-text links gave rows; `HREF`, `Src`, `XLINK:HREF` gave none and `data-*`/`ng-src` gave rows; trimmed and unquoted values misread; references not decoded; `decode_refs()` missing).
- 2026-10-19: checkpoint (T2 and T3 written, not ticked): `tag_links()` and `decode_refs()` replace the pattern in `page_links()`; the check test file passes; a scratch comparison on a rendered template site gave the same link set on both pages under the a01b723 reader and the new one, and 0 broken-link rows; a 3.7 MB page reads in 0.4 s. Help page, NEWS, and DESIGN text written. Full suite and `devtools::check()` running.
- 2026-10-19: T2, T3 done: `devtools::test()` 256 tests, 0 failed, 0 errors, 5 skipped; `test-check-supplement.R` with `NOT_CRAN=true` ran all 20 tests with none skipped, the rendered-site test included.
- 2026-10-19: implement choice: `tag_links()` removes skipped text with one `gsub()` whose alternatives keep each start tag (raw-text start tags too), then reads tags from what is left, so a `<!--` inside a quoted attribute value does not start a comment.

## Decisions

## Review
