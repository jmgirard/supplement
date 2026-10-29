# M076: Read large comments and element text in pages

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — `check_supplement()` gives fewer rows that stop `release_supplement()`
- **Branch/PR:** m076-read-large-page-text

## Goal

`check_supplement()` reads the links of a page whose comment, or whose script, style, textarea, or title text, is too large for one PCRE match, by the same rules as before.

## Scope

**In:** `tag_links()` in `R/check-supplement.R` scans the page once for the heads of its markup, with no attributes read, and then walks them in R: it finds where each comment and each script, style, textarea, and title element ends with separate short searches, and reads a tag's attributes only for a head that the walk reaches outside comments and element text. So no PCRE match spans a comment or an element's text. The rules stay those of M075 and `cairn/references/whatwg-html.md`: a comment ends at `<!-->`, `<!--->`, or its first `-->` or `--!>`; style, textarea, and title text ends at the first `</name` and a delimiter; script text follows the plain, escaped, and double escaped states. The help page, NEWS.md, code comments, and DESIGN.md state the new limits.

**Out:**
- A start or end tag with millions of attributes, outside comments and element text, can still give the PCRE-limit row: it stays in the candidate row "Read huge script bodies past PCRE limits", which post-merge hygiene narrows to that case.
- Time that grows with the count of comment ends and script state changes in a page is bounded only at the sizes AC2 tests.
- The other cases where the reader differs from a browser stay as listed in the DESIGN.md Known issues entry "Link reader limits".
- Reading each page once for both link checks stays in the candidate row "Read each page once for web links".
- An HTML parser package: D-017 stands, and no dependency changes.

## Acceptance criteria

- [ ] AC1: In a test that `devtools::test()` runs, `check_supplement()` gives for each of these pages one `broken-link` row, for a missing link placed after the comment or element ends, and no row for a missing link placed inside it after the large part: one page each whose script, style, textarea, or title text holds 7 million `<`; a page whose comment holds 7 million `-`; pages whose script text holds 7 million `</a`, 7 million `<!x`, and, after `<!--`, 7 million `<sx` and 7 million `-x`; and a page whose comment, and one page each whose script, style, textarea, or title text, holds `<b` followed by 3 million space-separated words.
- [ ] AC2: In a test that `devtools::test()` runs, a `check_supplement()` call takes under 10 seconds and gives one `broken-link` row for each missing link on a site whose one page holds 20,000 comments, 20,000 script elements, 20,000 style elements, and 20,000 style elements whose text holds `<?x` before `</style>`, each followed by a distinct missing link (80,000 rows); the same holds for a site whose one page holds script text with 200,000 `<!---->` followed by a missing link (one row).
- [ ] AC3: In a test that `devtools::test()` runs, `tag_links()` returns values and a `base` attribute `identical()` to those of main's reader at commit e7ba02a for each page of a fixed-seed generated set of at least 10,000 pages of 20 to 200 tokens, and for named pages where a head in script, style, or comment text runs past its end, such as `<script><?x</script><a href="x.csv">`. The tokens are `<`, `</`, `<!`, `<?`, `!`, the comment forms `<!--`, `<!-->`, `<!--->`, `-->`, and `--!>`, the names `script`, `style`, `textarea`, `title`, `base`, and `a` in mixed letter case, each of tab, LF, FF, CR, space, `/`, and `>`, the attributes `href`, `src`, and `xlink:href`, `=`, both quotes, `-`, ASCII letters, and `é`. The set includes pages in double escaped script text, pages with each comment end form, pages where a head runs past each of the four elements' ends, and pages that end inside a comment, an element's text, and a tag.
- [ ] AC4: In a test that `devtools::test()` runs, a page whose one start tag holds 3 million attributes gives its link rows or the row that says its markup goes past the limits of the PCRE pattern engine, and no error.
- [ ] AC5: The `check_supplement()` help page and DESIGN.md's "Link reader limits" entry name millions of attributes in one tag as the case that can give the PCRE-limit row; NEWS.md has an entry naming the comment and element text forms that AC1 tests as no longer giving that row; and among the hits of `grep -rnE "million|PCRE|limit" R/ man/ README.md inst/ NEWS.md`, no text names a comment or element text as reaching the limit.
- [ ] AC6: The `verify` slot is clean: `devtools::document()` leaves no diff, `devtools::test()` has 0 failures, and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T1, T3
- AC2 → T3, T4
- AC3 → T2, T3
- AC4 → T1
- AC5 → T5
- AC6 → T6

## Tasks

- [x] T1: Write the AC1 and AC4 pages in `tests/testthat/test-check-supplement.R`, beside "script text with millions of < or of - after <!-- is read" (line 1119), under `skip_on_cran()`. Run them on the current code: each 7 million page must give the PCRE-limit row (red, with that row's text asserted); the `<b` and 3 million words pages and AC4 must pass.
- [ ] T2: Copy main's reader (`html_skipped` and `tag_links()`, `R/check-supplement.R:2058-2107` at e7ba02a, with the parts they call) into a test helper as the frozen oracle `old_tag_links()`. Write the AC3 test with a fixed seed; it asserts at least 100 pages of each form AC3 lists (by markers the generator records). It passes on the current code.
- [ ] T3: Replace the `gsub()` in `tag_links()` (line 2086): one `gregexpr()` over a heads pattern that reads no attributes (comment starts, `<!` and `<?` markup, bogus `</` comments, and the `<name` and `</name` of tags); an R walk that takes the next head at or after its position; comment ends from fixed-string positions of `-->` and `--!>`; style, textarea, and title ends from positions of `</name` and a delimiter; script ends from a state walk over the positions of `<!--`, `-->`, `<script` and a delimiter, and `</script` and a delimiter (whatwg-html 13.2.5.15 to 13.2.5.31); a tag's attributes read only for a head the walk reaches, batched in a vector. Where a markup head runs past an element's end, scan again from that end in a window until the heads line up. Remove pattern parts no longer used. AC1, AC3, and the existing reader tests pass.
- [ ] T4: Write the AC2 test under `skip_on_cran()`. Time the AC1 pages and the AC2 pages on macOS and write the times in the work log.
- [ ] T5: Update the help text (`R/check-supplement.R:336-342`), the code comments at lines 1787-1795 and 1966-1978, NEWS.md, and DESIGN.md (the link check text near line 176 and the "Link reader limits" entry); run `devtools::document()`.
- [ ] T6: Run the `verify` slot: `devtools::document()`, `devtools::test()`, `devtools::check()`.

## Work log

- 2026-10-29: created by /milestone-plan.
- 2026-10-29: tier check: not run — work named at the question set.
- 2026-10-29: question set: what to work on — "Read huge script bodies past PCRE limits"; plan and go on to implement — yes.
- 2026-10-29: idea vet: no concern. The rules stay M075's stated HTML Standard rules; a large htmlwidget (plotly `<br>` tooltips, DT cells with HTML) can pass 5 million `<`, and the row stops `release_supplement()`; the row's approach fits D-017.
- 2026-10-29: lessons used: 2026-10-20 (M021), 2026-10-26 (M059), 2026-10-28 (M070), 2026-10-29 (M075).
- 2026-10-29: collision check: absorbs part of the candidate row "Read huge script bodies past PCRE limits" (the many-attributes case stays there); extends done M021 and M075; D-017 stands. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-29: measured on main (macOS, R 4.6, PCRE2 10.47): every AC1 7 million shape warns at 6 million; a tag with 3 million attributes warns and one with 1 million reads; `PCRE_use_JIT` TRUE or FALSE changes nothing, and R has no match-limit option.
- 2026-10-29: plan gate chose a head scan and an R walk over raising PCRE's match limit (R exposes no option), over cheaper body patterns (each `<` still costs at least one match step, so the limit stays near 10 million), and over xml2 (D-017); falsified by a page within main's limits that the two readers read differently with no rule to explain it, or walk time that grows faster than page size.
- 2026-10-29: criteria audit (full mode, Opus reader): 19 findings, all taken. T3's head scan reads no attributes, since `</a` runs are one end tag with millions of attributes (AC1 would fail) and tag-like text with 3 million words in a comment or element would regress (AC1 guard pages added); AC1 link placement and AC2 timing scope, count (80,000), state-walk page, and re-scan page fixed; AC3 tokens (`<`, `!`, comment forms, named delimiters, `é`, `xlink:href`), page length, required forms, named straddle pages, and `identical()` added, with the per-form counts moved to T2 as an instrument; AC4 accepts either row, since the limit belongs to the R build; AC5 grep widened and DESIGN.md added; tests under `skip_on_cran()` at 7 million, the smallest size red on main for every shape.
- 2026-10-29: implement started on branch m076-read-large-page-text, cut from main at 6dc4b1b.
- 2026-10-29: T1 done: tests "comments and element text past one PCRE match are read" and "a tag with millions of attributes gives its link row or the PCRE-limit row". On the current reader the first fails with the PCRE-limit row for each of the nine 7 million pages and no other difference; the five `<b` and 3 million words pages and the attributes test pass. The rows are compared as file and full problem text, since the PCRE-limit row has no backticked link.

## Decisions

## Review
