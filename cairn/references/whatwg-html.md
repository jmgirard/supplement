# whatwg-html — HTML Standard rules that the link reader follows

**Provenance.** Ingested 2026-10-28 by M075 from https://html.spec.whatwg.org/multipage/ (`parsing.html`, `semantics.html`, `urls-and-fetching.html`), fetched with curl by the M075 implement session. The Living Standard copy read was "Last Updated 26 October 2026".
Pagination: section numbers of the multipage edition.
Extraction: verified 2026-10-28 against the source — observed 2026-10-28.

**Citation.** WHATWG. HTML Living Standard. https://html.spec.whatwg.org/. Last Updated 26 October 2026.

**Role.** It states where comments, end tags, and script text end, and how a `<base>` element sets the address that relative links resolve against. `tag_links()` and the base handling of `check_links()` in `R/check-supplement.R` follow these rules. The cases where the reader differs on purpose are listed on the `check_supplement()` help page.

## Extracted values

- End tag open state (13.2.5.7). After `</`: an ASCII letter starts an end tag. `>` is "a missing-end-tag-name parse error. Switch to the data state." Anything else "Create a comment token" and reconsume in the bogus comment state, which runs to the next `>` (13.2.5.41). End tags then go through the same tag name and attribute states as start tags (13.2.5.8 and on).
- Comment start state (13.2.5.43) and comment start dash state (13.2.5.44). A `>` right after `<!--` or `<!---` is "an abrupt-closing-of-empty-comment parse error" that emits the comment, so `<!-->` and `<!--->` end there.
- Comment end dash, comment end, and comment end bang states (13.2.5.50 to 13.2.5.52). Two dashes in the comment reach the comment end state. Then `>` ends the comment, and `!` then `>` ends it as "an incorrectly-closed-comment parse error". So a comment ends at its first `-->` or `--!>` after `<!--`. In the comment start state a `!` is plain text, so `<!--!>` and `<!---!>` do not end a comment.
- Script data states (13.2.5.4, 13.2.5.15 to 13.2.5.31). In script text, `<!--` reaches the script data escaped dash dash state. From the escaped states, `-->` returns to the script data state. There `</script` followed by tab, LF, FF, space, `/`, or `>` ends the element. In the escaped states, `<script` followed by one of those six characters reaches the script data double escaped state. Letters count in either case (13.2.5.26: "Append the lowercase version"). In the double escaped states, `</script` and one of the six characters returns to the escaped state (13.2.5.31). There `-->` returns to the script data state (13.2.5.29).
- Document base URLs (2.4.3). "If document has a descendant base element that has an href attribute, then return the frozen base URL of the first such base element in tree order." Otherwise the fallback base URL, the page's own address, is used.
- The base element (4.2.3), "set the frozen base URL". The `href` value is parsed against the fallback base URL ("Thus, the base element isn't affected by itself"). If parsing fails, or the scheme is "data" or "javascript", the frozen base URL is the fallback base URL.

## Traces to

- `R/check-supplement.R`: `html_skipped`, `html_raw_text()`, and `tag_links()` (comment, end tag, and script states), and the base handling in `page_links()`.
- `tests/testthat/test-check-supplement.R`: the M075 tests for base tags, comment ends, end tags, and script text.
