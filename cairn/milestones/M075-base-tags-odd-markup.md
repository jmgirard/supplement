# M075: Read base tags and odd markup in pages

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** —
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing, because `check_supplement()` is exported and its `broken-link` rows stop `release_supplement()`
- **Branch/PR:** m075-base-tags-odd-markup

## Goal

`check_supplement()` reads the links of pages with a `<base>` tag, odd comment ends, `</` markup, or escaped script text by the stated HTML Standard rules.

## Scope

**In:**

- The `broken-link` check resolves a page's relative links against its first `<base href>`.
- The base value itself is not read as a link, so the `web-link` check does not request it.
- Comments also end at `<!-->`, `<!--->`, and `--!>`.
- `</` followed by a character that is not a letter starts a bogus comment.
- An end tag is read through its attributes to its `>`.
- Script text follows the escaped and double escaped states of the HTML Standard.
- The help page, the DESIGN.md "Link reader limits" entry, and NEWS.md state the new rules.
- A source note `cairn/references/whatwg-html.md` records the HTML Standard sections that the code follows.

**Out:**

- Bodies past the PCRE limits stay with the candidate row "Read huge script bodies past PCRE limits".
- The other differences that the help page lists stay in the DESIGN.md "Link reader limits" entry. Examples are noscript text, named references, and unclosed quotes.
- The `web-link` check does not request relative links resolved against an `http` or `https` base. The new low candidate row "Request relative links against a base" holds this work.
- Links and bases that start with `/` stay unchecked, because the check does not know the site's path on the server.
- An empty link under a base stays unchecked. The help page lists it as a difference.

## Acceptance criteria

- [ ] AC1: Only the first `<base>` start tag that has an `href` attribute counts, among the start tags that the link check reads. Its value is read after the decoding and trimming that link values get. A local base value is not empty and does not start with `#`, `?`, or `/`. It also has no scheme. With a local base, `check_supplement()` resolves each relative link on the page against the base, by these rules. The base folder is the base value up to its last `/`, with its `?` and `#` parts dropped. A base whose last part is `.` or `..` names a folder. A link that is only a `#` or `?` part resolves to the base address itself. A path that climbs above `docs/` counts as broken, as it does now. Tests use a page at `docs/a/page.html` with the bases `../`, `..`, `sub/`, `sub/.`, `sub/page.html`, and `sub/page.html#f`. For each base, a link whose target exists at the resolved path gives no `broken-link` row. A link whose target exists only in `docs/a/` gives a row. Two more tests use a `#x` link with the bases `sub/` and `sub/page.html`. The link resolves to `docs/a/sub/index.html` or `docs/a/sub/page.html`. If that file is missing, the link gives a row. If the file exists, the link gives no row.
- [ ] AC2: The `href` value of a `<base>` tag is not read as a link. A page whose only link-like value is `<base href="missing/">` gives no `broken-link` row. With `web_links = TRUE`, the address in `<base href="https://example.org/">` is not requested. If the first base value is empty, starts with `#` or `?`, or has the scheme `data:` or `javascript:`, the links resolve against the page's own folder. A later `<base href>` on the page is not used. Tests cover each of these values, and a `<base href="">` followed by `<base href="sub/">`. A base value with another scheme, such as `https:`, leaves the page's relative links unchecked, with no row. A base value that starts with `/` does the same. Tests cover both.
- [ ] AC3: A comment ends by the comment states of the HTML Standard (`whatwg-html`, Tokenization). `<!-->` and `<!--->` end at their own `>`. Every other comment ends at the first `-->` or `--!>` after its `<!--`. Tests show that a link after each of `<!-->`, `<!--->`, `<!-- x --!>`, and `<!----!>` gives its `broken-link` row. A link inside a comment that starts with `<!--!>` or `<!---!>` gives no row. A link inside a comment that holds `-!>` or `- ->` before its `-->` also gives no row.
- [ ] AC4: Outside comments and the text of script, style, textarea, and title, `</` can start a bogus comment or an end tag. The source is the end tag open state of the HTML Standard (`whatwg-html`, Tokenization). `</` followed by a character that is not an ASCII letter or `>` starts a bogus comment, which runs to the next `>`. `</` followed by an ASCII letter starts an end tag. It is read through its attributes and quoted values to its closing `>`, as a start tag is. Tests show no row for the link in `</ foo <a href="x.csv">`. They show no row for the link in `</p title="<a href='y.csv'>">`. A link after each of the two gives its row, and so does a link after `</>`.
- [ ] AC5: The text of a script follows the script data states of the HTML Standard (`whatwg-html`, Tokenization, the escaped and double escaped states). After `<!--`, a `<script` makes the next `</script>` not end the element. Here `script` is in any ASCII letter case and is followed by a space, tab, line break, form feed, `/`, or `>`. A `-->` returns to the plain state, and its dashes can be those of the `<!--`. Tests show that in `<script><!--<script></script><a href="in.csv"></script><a href="after.csv">` only `after.csv` gives a row. The same holds with `<SCRIPT/` and with `<script` and a tab in place of the inner `<script>`. Five more scripts end at their first `</script>`, so a link after each gives its row. They are `<script><!-- --></script>`, `<script><!--</script>`, `<script><!--<script>--></script>`, `<script><!--<scripts></script>`, and `<script><!--><script></script>`. A page whose script text repeats `<!--<script></script>-->` to 1 MB gives the row of a link after the script. It does not give the row for markup past the PCRE limits.
- [ ] AC6: The `check_supplement()` help page states the base rules of AC1 and AC2 and the ends of AC3 to AC5. Its sentence that links that start with `#` are not checked names the exception under a local base. Its list of cases that the check reads differently from a browser no longer names `<!-->`, `<!--->`, `--!>`, or a script that holds `<!--` and `<script>`. That list names these cases: a `\` in a base, an empty link under a base, a `<base>` inside `<svg>`, and the unchecked links under a base with a scheme or a leading `/`. It also names the end tags of script, style, textarea, and title, which still end at their first `>`. A NEWS.md entry names the new base, comment, end tag, and script rules. The DESIGN.md "Link reader limits" entry names the base cases of that list.
- [ ] AC7: `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage

- AC1 → T2
- AC2 → T2
- AC3 → T1, T3
- AC4 → T1, T3
- AC5 → T1, T4
- AC6 → T5
- AC7 → T6

## Tasks

- [x] T1: Write the source note `cairn/references/whatwg-html.md` and its `INDEX.md` line. Read the HTML Standard at html.spec.whatwg.org. Record the comment states, the end tag open state, the script data escaped and double escaped states, and the base element rules for the document base URL. Name each section, and give the provenance block.
- [x] T2: Write the AC1 and AC2 tests first in `tests/testthat/test-check-supplement.R`. Then make `tag_links()` (`R/check-supplement.R:1937`) give the `href` of the first `<base>` tag that has one, apart from the link values. `page_values()` (`:1766`) leaves that value out, so `web_addresses()` does not request it. `page_links()` (`:1755`) and `check_links()` (`:1639`) join the base folder to each relative link before `link_ok()` (`:1998`).
- [x] T3: Write the AC3 and AC4 tests first. Then change the comment part of `html_skipped` (`:1895`) and add parts for `</` and end tags. Keep every repeat possessive.
- [x] T4: Write the AC5 tests first, the 1 MB page included. Then add the escaped and double escaped states to the script part of `html_raw_text()` (`:1912`), with possessive repeats only. Run the existing large-page tests, such as the 6 MB script page.
- [ ] T5: Update the roxygen help of `check_supplement()` (`:316` to `:358`) and run `devtools::document()`. Add the NEWS.md entry under the development heading. Update the DESIGN.md "Link reader limits" entry.
- [ ] T6: Run `devtools::test()` and `devtools::check()`.

## Work log

- 2026-10-28: created by /milestone-plan.
- 2026-10-28: tier check: not run — work named at the question set.
- 2026-10-28: question set: what to work on — link reader fixes (candidate rows "Resolve page links against a base tag" and "Close the link reader's browser gaps"); run length — plan, build, and review in one run.
- 2026-10-28: idea vet: no concern. The rules follow the HTML Standard. Quarto 1.10 writes no `<base>` tag (no match in its `share/` templates), so these cases come from raw HTML that an author adds, and the user chose the work with the cases named.
- 2026-10-28: lessons used: 2026-10-20 (M021) for possessive repeats and ASCII letter classes, 2026-10-26 (M059) for no `.*` between names.
- 2026-10-28: collision check: absorbed the two candidate rows above. "Read huge script bodies past PCRE limits" stays a row (Out). D-017 (a base R reader, no parser package) stands, and no dependency changes. M021's milestone-local choice to keep `<!-->` and `<!--->` as stated limits is replaced by AC3.
- 2026-10-28: inbox sweep: 0 open issues and 0 open PRs.
- 2026-10-28: added the low candidate row "Request relative links against a base" for the Out item on the `web-link` check.
- 2026-10-28: criteria audit (full mode, fresh Opus reader): 12 findings, all taken. Fixes: the first base with an `href` counts even when its value is not usable; `data:` and `javascript:` bases fall back to the page folder; "as a browser does" dropped and the uncovered base cases moved to the help page's difference list; `sub/.` and `sub/page.html#f` bases and named `#x` targets added; the `<!--!>` test now says "starts with"; `<!---!>` and `<!----!>` tests added; AC4 scoped to text outside the four skipped elements; the script delimiter widened to all six characters in any case, with `<SCRIPT/`, tab, `<scripts>`, and `<!-->` tests; "at least 1 MB" narrowed to 1 MB; AC6 names the `#` sentence, the new difference cases, and what NEWS and DESIGN.md say; title renamed. Empty links under a base were narrowed to unchecked, listed as a difference.
- 2026-10-28: plan chose the script states as possessive PCRE parts inside the one `html_skipped` pass over an R loop that walks the page, because it keeps one linear pass and the existing large-page tests; falsified by the 1 MB escape page reaching the PCRE match limit.
- 2026-10-28: plan chose to join the base folder and the link into one path for `link_ok()` over a separate URL resolver, because `link_ok()` already decodes and normalizes parts and counts a path above `docs/` as broken; falsified by a base and link inside `docs/` whose joined path resolves to another file than the URL Standard gives.
- 2026-10-28: changelog: one NEWS.md entry for the whole milestone.
- 2026-10-28: implement started on branch m075-base-tags-odd-markup, cut from main at ed28d21.
- 2026-10-28: T1 done: wrote `cairn/references/whatwg-html.md` from the HTML Standard copy of 26 October 2026 (sections 2.4.3, 4.2.3, 13.2.5.4 to 13.2.5.52), with its INDEX line.
- 2026-10-28: T2 done: `tag_links()` gives the first `<base>` href as the attribute `base` and leaves base tags out of the links; `page_values()` cleans it with the new `link_text()`; `page_links()` sorts it with `base_kind()` and `base_address()` and gives each link a `targets` path for `link_ok()`. Four tests red before the change, green after; the whole `test-check-supplement.R` passes (131 tests, 0 failed, 7 skipped).
- 2026-10-28: implement choice: a `broken-link` row under a base names the link as written on the page, not the joined path, so the author can find it in the page.
- 2026-10-28: T3 done: `html_skipped` ends a comment at `<!-->`, `<!--->`, or the first `-->` or `--!>`, and removes `</` with a non-letter to the next `>` and end tags through their attributes. Two tests red before, green after; the old skipped-text and large-page tests still pass.
- 2026-10-28: T4 done: `html_script_body` (possessive parts only) gives the script text of `html_raw_text("script")` the escaped and double escaped states. The double-escape test was red before and green after; the 1 MB test passed before too, as a guard on the PCRE limit. Measured on macOS, R 4.6: `<!--<script></script>-->` repeated reads at 4 MB and reaches the match limit by 16 MB; a plain 6 MB script still reads; the old large-page and linear-time tests pass.

## Decisions

## Review
