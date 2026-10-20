# M021: The link check reads links only from tags

- **Status:** review
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

- [x] AC1: Text in the places listed here gives no `broken-link` row. A test page puts `href="gone-a.csv"` and `src="gone-b.png"` in each place: an HTML comment on one line, an HTML comment over three lines, the text of a `<script>`, `<style>`, `<textarea>`, and `<title>` element (an end tag in any letter case, such as `</SCRIPT>`), and the text of a `<code>` and a `<p>` element. None of these gives a row. After each place, the page has a real link to a missing file, which gives a row, and `<script src="gone.js">` gives a row for its start tag.
- [x] AC2: An attribute is read when its whole name, compared without letter case, is `href`, `src`, or `xlink:href`. A test page has one link to a missing file for each of these shapes, and each gives a row: `HREF="…"`, `Src="…"`, `XLINK:HREF="…"`, `href = "…"` (spaces around `=`), and an `href` after a quoted value that holds `>` (`title="a > b"`). A link to a missing file in an attribute named `data-href`, `data-src`, or `ng-src` gives no row.
- [x] AC3: A value in double quotes, in single quotes, or with no quotes is read; an unquoted value runs to the next space, tab, line break, or `>`. Each value is handled in this order: character references are decoded (AC4); spaces, tabs, line breaks, and form feeds at the start and end are removed, and tabs and line breaks inside are dropped; the skip of values that start with a scheme, `/`, or `#` is applied; then percent decoding, as today. A row shows the value after the first two steps. Tested shapes: `href=" data/ok.csv "` and `href=data/ok.csv` reach the existing file `data/ok.csv` and give no row; `href=gone-c.csv` and `href='gone-d.csv'` give a row; `href=data/ok.csv/` gives a row with the link `data/ok.csv/`; `href="&#109;ailto&#58;a@example.org"` gives no row.
- [x] AC4: In a value, `&amp;`, `&lt;`, `&gt;`, `&quot;`, and `&apos;` (lower case, with the `;`) are decoded, and so is a number reference written `&#N;`, `&#xH;`, or `&#XH;` that names a code point from 1 to 0x10FFFF, other than a surrogate (0xD800 to 0xDFFF) or 128 to 159. Tested shapes: `R&amp;D.csv`, `R&#38;D.csv`, and `R&#x26;D.csv` reach the existing file `R&D.csv` and give no row; `data/a&#37;20b.csv` reaches the existing file `data/a b.csv` and gives no row. These stay as written and give a row when no file has that name: `R&eacute;.csv`, `R&AMP;D.csv`, `R&ampD.csv`, `R&#38D.csv`, `R&#0;.csv`, `R&#xD800;.csv`, `R&#x110000;.csv`, and `R&#x80;.csv`.
- [x] AC5: On the link shapes that the broken-link test of `tests/testthat/test-check-supplement.R` writes at commit `a01b723`, and on the site that the test "a rendered site in a git repository has no problems" renders from the template, `check_supplement()` gives the same `broken-link` rows as at commit `a01b723`.
- [x] AC6: The `broken-link` bullet of the `check_supplement()` help page states the rules of AC1 to AC4 (the elements whose text is skipped, the attribute names, the value forms and the order of steps, the decoded references) and the limits listed in Out. NEWS.md has an entry for the change.

## Coverage

- AC1 → T1, T2, T5
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T2, T4
- AC6 → T3, T5

## Tasks

- [x] T1: In `tests/testthat/test-check-supplement.R`, add one test per criterion AC1 to AC4 with the listed shapes, built with `write_page()` and `touch()`. Each test asserts the exact set of (file, link) pairs, as the existing broken-link test does at line 318. Run them before T2 and see each fail for the shape it targets (for example the comment link giving a row), not only fail.
- [x] T2: In `R/check-supplement.R`, replace the `regmatches()` pattern in `page_links()` with a reader that walks the page text: it skips `<!--` to the first `-->`, other `<!…>` and `<?…>` to `>`, and the text of the four elements to their end tag; it reads attributes from each start tag and keeps the values of the three names; it decodes and trims each value in the AC3 order (a helper beside `percent_decode()`). Keep `link_ok()` as it is. Run `devtools::test()`; the existing broken-link test and the rendered-site test must pass unchanged.
- [x] T3: Update the `broken-link` bullet in the roxygen block at the top of `R/check-supplement.R`, from a same-session read of the code; run `devtools::document()`. Add a NEWS.md bullet. Update the `R/check-supplement.R` text in the `cairn/DESIGN.md` Architecture section.
- [x] T4: Run `devtools::check()` on the Mac (0 errors, 0 warnings).
- [x] T5: Review return 1. In `tag_links()`, use possessive unrolled loops for comment and raw-text bodies so a body over 5 MB does not hit PCRE's match limit; let a start tag end at the end of the page and drop it there, so time stays linear and an unclosed tag gives no link; run `unique()` before `decode_refs()`; in `page_links()`, treat a warning from `tag_links()` as a page that cannot be read. Add tests: a 6 MB script body with link text, unclosed comment and raw-text elements at the end of a page, an unclosed tag at the end of a page, many `<a ` with no `>`, a warning from the reader, and `decode_refs()` on a vector. State `<!-->`, script double-escaped text, and an invalid byte in an unquoted value as limits on the help page.

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
- 2026-10-19: T4 done: `devtools::check()` on the Mac, 0 errors, 0 warnings, 0 notes.
- 2026-10-19: checkpoint: the claim audit corrected 5 of 41 claims (NEWS said `xlink:href` reading was new; the help page's limit list read as complete and its CDATA and row-shape wording was off; a code comment said control characters are trimmed). The re-read of the corrections is pending.
- 2026-10-19: claim audit: 41 claims read, 5 corrected — NEWS.md, R/check-supplement.R, man/check_supplement.Rd (the same reader re-read the 5 corrections once and found them true).
- 2026-10-19: implement complete; status set to review.
- 2026-10-20: review fix-now: an `href`, `src`, or `xlink:href` with no `=` (`<a href>`) gave the link "href"; it now has an empty value and gives no row (shape added to the AC3 test, which fails without the fix; help sentence added). README.md, the template `_README.md`, and the first NEWS bullet no longer say "quoted" links. Full suite: 256 tests, 0 failed, 5 skipped.
- 2026-10-20: review return 1: AC1 fails for script text: a `<script>`, `<style>`, or comment body over about 5 MB makes the skip `gsub()` in `tag_links()` hit PCRE's match limit, so the text is read as links and gives false rows (diff-bug #1); with it, diff-bug #3, #4, #5, #6, #7, #8, #10, and the #11 test gaps (see the Review section).
- 2026-10-20: minor amendment: T5 added for review return 1, mapped from AC1 and AC6; status in-progress.
- 2026-10-20: implement choice: `<!-->` and `<!--->` stay a stated limit (help page) rather than ending the comment at once, because the Scope Out list states "a comment ends only at the first `-->`" and a code change there would need a scope amendment.
- 2026-10-20: checkpoint (T5 written, not ticked): the new tests failed before the fix (PCRE warning and a `\"gone-big.csv\"` row on the 6 MB script page, a `gone-4.csv` row from the unclosed tag, no unreadable row for a reader warning; the 20,000 unclosed `<a ` page took 11.2 s) and pass after it (0.17 s); probes: a 16 MB script reads in 0.05 s, an 8 MB data URI in 0.09 s, and 6 million `-` in a comment or 3 million attributes give a PCRE warning, now a page that cannot be read. Full suite, `devtools::check()`, and a claim audit of the new prose are running.
- 2026-10-20: T5 addition from a late diff-bug finding (its addendum to pass 1): on a page with a non-ASCII character, `gregexpr()` and `regmatches()` over the whole page took time that grew with the square of the tag count (20,000 tags: 26 s in the reviewer's run, 31.6 s in the new test before the fix). The whole-page `gsub()` and `gregexpr()` now use `useBytes = TRUE` and mark the results UTF-8 again (a code comment says why, against the M008 lesson); the test "a long page with non-ASCII text is read in linear time" now passes, and `tag_links()` reads that page in 0.125 s with `gé.csv` intact.
- 2026-10-20: checkpoint: the claim audit of the T5 prose corrected 4 of 29 claims (the possessive and match-limit comment; a quote that never closes is read, not dropped; an invalid byte's `>` ends the whole tag; the tag_links() header). The re-read of the corrections is pending.
- 2026-10-20: claim audit: 29 claims read, 4 corrected — R/check-supplement.R, man/check_supplement.Rd (the same reader re-read the 4 corrections and the new useBytes comment once and found them true). The first suite run after T5 (before the useBytes fix) gave 258 tests, 0 failed, 5 skipped; the stale `devtools::check()` run was stopped, and both rerun on `3f6389d`.
- 2026-10-20: T5 done on `cd36256`: `devtools::test()` 259 tests, 0 failed, 0 errors, 5 skipped; `devtools::check()` 0 errors, 0 warnings, 0 notes. Implement complete; status set to review.

## Decisions

## Review

Evidence gathered 2026-10-19 at branch head `c2d924a`; `main` had not moved since the cut (`99abded`). `NOT_CRAN=true testthat::test_file("tests/testthat/test-check-supplement.R")`: 20 tests, 0 failed, 0 errors, 0 skipped.

- AC1: test "link-shaped text outside start tags gives no broken-link row" passed: rows are exactly the 8 `after-*` links and `gone.js`; no row for the bait tags or attribute text in the two comments, the four raw-text elements (`</SCRIPT>`, `</Style>`, `</TITLE>` end tags), or `<code>`/`<p>` text. It failed before T2 with `gone-a.csv` and `gone-b.png` rows (T1 work-log line).
- AC2: test "only href, src, and xlink:href attributes are read, in any letter case" passed: rows are exactly `gone-upper.csv` (`HREF`), `gone-mixed.png` (`Src`), `gone-xlink.svg` (`XLINK:HREF`), `gone-spaced.csv`, and `gone-after-gt.csv`; none for `data-href`, `data-src`, `ng-src`.
- AC3: test "quoted and unquoted values are read and trimmed" passed: rows are exactly `gone-c.csv` (unquoted), `gone-d.csv` (single quotes), and `data/ok.csv/`; no row for `" data/ok.csv "`, `"\f\tdata/ok.csv\n"`, unquoted `data/ok.csv`, or `&#109;ailto&#58;a@example.org` (decoded before the scheme skip). The order of steps is the code order in `page_links()`: `decode_refs()`, trim, drop, skip, then `percent_decode()` in `link_ok()`.
- AC4: test "character references in a link are decoded by the stated rules" passed: no row for `R&amp;D.csv`, `R&#38;D.csv`, `R&#x26;D.csv`, `R&#X26;D.csv`, `it&apos;s.csv`, `data/a&#37;20b.csv`; rows exactly for the 8 kept shapes (`R&eacute;.csv`, `R&AMP;D.csv`, `R&ampD.csv`, `R&#38D.csv`, `R&#0;.csv`, `R&#xD800;.csv`, `R&#x110000;.csv`, `R&#x80;.csv`), shown as written; `decode_refs()` gives `<>"'&é😀` for the five names plus `&#233;` and `&#x1F600;`.
- AC5: `git diff a01b723 HEAD -- tests/testthat/test-check-supplement.R` removes no line, so the broken-link test's shapes and expected set are those of `a01b723`, and it passed (14 rows expected, plus the `dangling.html` row). The test "a rendered site in a git repository has no problems" ran (not skipped) and passed: 0 rows, then exactly the 5 planted rows. A scratch run (`scratchpad/compare_links.R`) rendered a fresh template site and compared the `a01b723` `page_links()` with the branch's: `analyses/example.html` 19 links and `index.html` 21 links, same sets, 0 `broken-link` rows.
- AC6: `man/check_supplement.Rd` (from the roxygen bullet) states the skipped elements (`<script>`, `<style>`, `<textarea>`, `<title>`, comments, `<!...>`/`<?...>`), the three attribute names and the whole-name rule (`data-href`), the three value forms, the order of steps, the five named and the number references with their range, and the Out limits (other references, other control characters, the six elements, CDATA after its first `>`, `<svg>`/`<math>`, comment end at the first `-->`, a second attribute of the same name). NEWS.md line 113 has the entry. The claim audit (41 claims, 5 corrected, corrections re-read true) read these texts against the code.

Consistency gate, pass 1 (2026-10-19, `c2d924a`/`d397acf`): `cairn_validate` all checks passed; `devtools::document()` no diff; NEWS.md entry present, no milestone numbers; no new top-level files; no pkgdown site, no README.Rmd; no principle changed (impact check skipped); `devtools::check()` 0 errors, 0 warnings, 0 notes.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: a comment, script, or style body over about 5 MB makes the skip `gsub()` hit PCRE's match limit (warning, page returned unchanged), so script text is read as links and gives false rows (a 7 MB JSON script) — fix now via review return 1 (fails AC1 for script text)
- diff-bug #2: an attribute with no `=` (`<a href>`) is read as the link "href" — fix now, fixed d7d5b5b
- diff-bug #3: time grows with the square of the count of `<` + letter with no later `>` (1e5 `<a ` took 229 s) — fix now via review return 1
- diff-bug #4: a `gregexpr()` PCRE limit warning drops a page's links in silence (one tag with 3e6 attributes) — fix now via review return 1 (a limit warning gives the page-cannot-be-read row)
- diff-bug #5: `<!-->` and `<!--->` run to the next `-->`, while a browser ends them at once — fix now via review return 1
- diff-bug #6: an unclosed tag at the end of a page can still give a link from its quoted text — fix now via review return 1 (stated as a limit on the help page)
- diff-bug #7: script "double-escaped" text (`<!--` then `<script>` inside a script) is not handled and not listed — fix now via review return 1 (stated as a limit)
- diff-bug #8: an invalid UTF-8 byte, shown as `<e9>` by `read_page_text()`, ends an unquoted value — fix now via review return 1 (stated as a limit)
- diff-bug #9: `<base href>` is read as a link and other links are not resolved against it; the `a01b723` pattern did the same — follow-up, new candidate row "Resolve page links against a base tag"
- diff-bug #10: `decode_refs()` runs before `unique()` — fix now via review return 1
- diff-bug #11: test gaps (value-less attribute, unclosed comment or raw-text element at the end of a page, a large page, `<!-->`, `decode_refs()` on a vector); `broken_pairs()` misparses a link with a backtick — fix now via review return 1 for the gaps; the backtick item rejected (style: a test helper, and no test link holds a backtick)
- diff-bug #12: no Windows or locale defect seen; PCRE JIT on Windows may move the limit of #1 — noted; the return's large-page test runs in the Windows CI job
- diff-bug #13: the help page did not state the value-less attribute rule — fix now, fixed d7d5b5b
- blame-history #1: same as diff-bug #2 — fix now, fixed d7d5b5b
- blame-history #2: a start tag cut off by the end of the page is no longer read; a browser emits no tag there — reject (false as a defect: matches the HTML tokenizer)
- blame-history #3: unquoted values, `xlink:href` case, and skipped text widen M008's "quoted href/src" — reject (planned change, AC1 to AC3)
- prior-review #1: named references other than the five (`&eacute;`, `&AMP;`) still give rows for files that exist — follow-up, a `cairn/DESIGN.md` Known issues entry at post-merge hygiene (the user chose the base R reader knowing this, question set 2026-10-19)
- prior-review #2: same as blame-history #3 — reject (planned change)
- ripple #1: the "Fix false positives in the link check" row still lists the defects M021 fixes — reject (planned: post-merge hygiene narrows the row to the M022 part)
- ripple #2: `inst/template/_README.md:146` said "quoted relative links" — fix now, fixed d7d5b5b
- ripple #3: `README.md:103`, the same — fix now, fixed d7d5b5b
- ripple #4: `NEWS.md:26` said "quoted relative links" — fix now, fixed d7d5b5b
- diff-bug #14 (addendum to pass 1): on a page with a non-ASCII character, whole-page `gregexpr()` time grew with the square of the tag count (20,000 tags: 26 s) — fix now via review return 1, fixed d6e3480

Pass 2 evidence, 2026-10-20 at `7709925` (`main` still `99abded`). `NOT_CRAN=true testthat::test_file("tests/testthat/test-check-supplement.R")`: 23 tests, 0 failed, 0 errors, 0 skipped.

- AC1 (pass 2): the AC1 test passed again; the new test "large skipped text and unclosed markup give the stated rows" passed: a 6 MB JSON script body with link text gives no row and no warning, the link after it gives a row, and comment, script, and title bodies that run to the end of the page give no row.
- AC2 (pass 2): the AC2 test passed again.
- AC3 (pass 2): the AC3 test passed again, its bare-attribute shapes (`<a href>`, `<script src>`, `<a HREF >`) giving no row.
- AC4 (pass 2): the AC4 test passed again, with `decode_refs()` on a vector (`é&amp;`, `""`, `&amp;amp;` decoded once).
- AC5 (pass 2): `git diff a01b723 HEAD -- tests/testthat/test-check-supplement.R` removes 0 lines and the broken-link test passed; the rendered-site test ran and passed; `scratchpad/compare_links.R` again gave the same link sets (19 and 21) on both template pages and 0 rows.
- AC6 (pass 2): the help page now also states the bare-attribute rule, the cut-off tag rule, the PCRE-limit rule, and the `<!-->`, script double-escape, unclosed-quote, and invalid-byte limits; the T5 claim audit (29 claims, 4 corrected, re-read true) read them against the code. NEWS.md line 113 has the entry.

Consistency gate, pass 2: `devtools::test()` 259 tests, 0 failed, 5 skipped and `devtools::check()` 0 errors, 0 warnings, 0 notes, both on `cd36256` (later commits change only `cairn/`). `cairn_validate` all checks passed; `devtools::document()` no diff; no new top-level files; NEWS.md entry present with no milestone numbers.

spawned: diff-bug, blame-history, prior-review, ripple

- ripple #1 (pass 2): `cairn/LESSONS.md:21` (M008) said to match without `useBytes`, which `tag_links()` now does on purpose for whole-page matches — fix now, fixed facb1dd (lesson corrected in place, marked "corrected M021")
- prior-review #1 (pass 2): `useBytes = TRUE` departs from the M008 lesson and rests on the two `Encoding()` lines — fix now, fixed facb1dd (the same lesson correction); the non-ASCII test builds its row text with `sprintf()`, which stops on a string marked "bytes", so the `Encoding()` lines are tested
- prior-review #2 (pass 2): the link contract widened from M008's "quoted href/src" — reject (planned change, AC1 to AC3)
- prior-review #3 (pass 2): `--!>` is not in the help page's limits — fix now, fixed facb1dd (help sentence added; a probe gives `y` only for `<!-- a --!><a href=x> --><a href=y>`)
- prior-review #4 (pass 2): the `expect_lt(time, 30)` and `expect_lt(time, 10)` assertions could flake on a slow runner — reject (false as a risk: the tests take 0.17 s and 0.13 s on the Mac, about 60 times under the bound; the Windows job on the PR shows its own time)
- prior-review #5 (pass 2): `&#37;2F` decodes to `%2F` and then to `/` inside one path part — reject (false as a defect: the same row as a raw `%2F`, which the a01b723 test already expects as broken)
- blame-history #1 (pass 2): the M008 lesson conflicts with the `useBytes` code — fix now, fixed facb1dd (same as ripple #1)
- blame-history #2 (pass 2): a comment does not end at `--!>`, so a link after it that main read is now missed — follow-up, new candidate row "Close the link reader's browser gaps" (the Scope Out list and the help page state the `-->` rule)
- blame-history #3 (pass 2): `<<!-- c -->a href="gone.csv">` joins into a tag after the comment is removed; main did the same — follow-up, the same new row
- blame-history #4 (pass 2): `</ foo <a href="gone.csv">` is not read as a bogus comment; main did the same — follow-up, the same new row
- blame-history #5 (pass 2): the choice of a base R reader over an HTML parser package has no D-entry — fix now (D-017 added)
- diff-bug #1 (pass 2): a raw-text body with about 5 million `<` (20 MB) reaches PCRE's match limit, so the page gets the unreadable row where main read it — follow-up, new candidate row "Read huge script bodies past PCRE limits"; the limit is stated in the help page and the code comment
- diff-bug #2 (pass 2): a PCRE-limit page got the "cannot be read, or it is a link to a missing file" text — fix now (its own row text; `page_links()` returns FALSE)
- diff-bug #3 (pass 2): removing a comment or `<?…?>` joined a text `<` to the text after it into a false tag — fix now (each removed or kept part is followed by a space; AC1 test shape `<p>a <<!-- c -->a href="gone-joined.csv">`, which a probe shows is read without the space); blame-history #3 is fixed with it and dropped from the "Close the link reader's browser gaps" row
- diff-bug #4 (pass 2): the 30 s bound with 20,000 unclosed `<a ` did not catch the old pattern (11.2 s) — fix now (60,000 tags, 10 s bound)
- diff-bug #5 (pass 2): tags with no link were parsed further, 2.05 s for 1.2M tags — fix now (prefilter on `href`/`src` text; 200,000 table rows read in 0.26 s)
- diff-bug #6 (pass 2): `(?i)` on bytes and `tolower()` follow the locale's case tables (Turkish `i`) — fix now (explicit ASCII letter classes from `ascii_any_case()`, and `ascii_lower()` with `chartr()`)
