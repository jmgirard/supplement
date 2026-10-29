# M075: Read base tags and odd markup in pages

- **Status:** review
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

- [x] AC1: Only the first `<base>` start tag that has an `href` attribute counts, among the start tags that the link check reads. Its value is read after the decoding and trimming that link values get. A local base value is not empty and does not start with `#`, `?`, or `/`. It also has no scheme. With a local base, `check_supplement()` resolves each relative link on the page against the base, by these rules. The base folder is the base value up to its last `/`, with its `?` and `#` parts dropped. A base whose last part is `.` or `..` names a folder. A link that is only a `#` or `?` part resolves to the base address itself. A path that climbs above `docs/` counts as broken, as it does now. Tests use a page at `docs/a/page.html` with the bases `../`, `..`, `sub/`, `sub/.`, `sub/page.html`, and `sub/page.html#f`. For each base, a link whose target exists at the resolved path gives no `broken-link` row. A link whose target exists only in `docs/a/` gives a row. Two more tests use a `#x` link with the bases `sub/` and `sub/page.html`. The link resolves to `docs/a/sub/index.html` or `docs/a/sub/page.html`. If that file is missing, the link gives a row. If the file exists, the link gives no row.
- [x] AC2: The `href` value of a `<base>` tag is not read as a link. A page whose only link-like value is `<base href="missing/">` gives no `broken-link` row. With `web_links = TRUE`, the address in `<base href="https://example.org/">` is not requested. If the first base value is empty, starts with `#` or `?`, or has the scheme `data:` or `javascript:`, the links resolve against the page's own folder. A later `<base href>` on the page is not used. Tests cover each of these values, and a `<base href="">` followed by `<base href="sub/">`. A base value with another scheme, such as `https:`, leaves the page's relative links unchecked, with no row. A base value that starts with `/` does the same. Tests cover both.
- [x] AC3: A comment ends by the comment states of the HTML Standard (`whatwg-html`, Tokenization). `<!-->` and `<!--->` end at their own `>`. Every other comment ends at the first `-->` or `--!>` after its `<!--`. Tests show that a link after each of `<!-->`, `<!--->`, `<!-- x --!>`, and `<!----!>` gives its `broken-link` row. A link inside a comment that starts with `<!--!>` or `<!---!>` gives no row. A link inside a comment that holds `-!>` or `- ->` before its `-->` also gives no row.
- [x] AC4: Outside comments and the text of script, style, textarea, and title, `</` can start a bogus comment or an end tag. The source is the end tag open state of the HTML Standard (`whatwg-html`, Tokenization). `</` followed by a character that is not an ASCII letter or `>` starts a bogus comment, which runs to the next `>`. `</` followed by an ASCII letter starts an end tag. It is read through its attributes and quoted values to its closing `>`, as a start tag is. Tests show no row for the link in `</ foo <a href="x.csv">`. They show no row for the link in `</p title="<a href='y.csv'>">`. A link after each of the two gives its row, and so does a link after `</>`.
- [x] AC5: The text of a script follows the script data states of the HTML Standard (`whatwg-html`, Tokenization, the escaped and double escaped states). After `<!--`, a `<script` makes the next `</script>` not end the element. Here `script` is in any ASCII letter case and is followed by a space, tab, line break, form feed, `/`, or `>`. A `-->` returns to the plain state, and its dashes can be those of the `<!--`. Tests show that in `<script><!--<script></script><a href="in.csv"></script><a href="after.csv">` only `after.csv` gives a row. The same holds with `<SCRIPT/` and with `<script` and a tab in place of the inner `<script>`. Five more scripts end at their first `</script>`, so a link after each gives its row. They are `<script><!-- --></script>`, `<script><!--</script>`, `<script><!--<script>--></script>`, `<script><!--<scripts></script>`, and `<script><!--><script></script>`. A page whose script text repeats `<!--<script></script>-->` to 1 MB gives the row of a link after the script. It does not give the row for markup past the PCRE limits.
- [x] AC6: The `check_supplement()` help page states the base rules of AC1 and AC2 and the ends of AC3 to AC5. Its sentence that links that start with `#` are not checked names the exception under a local base. Its list of cases that the check reads differently from a browser no longer names `<!-->`, `<!--->`, `--!>`, or a script that holds `<!--` and `<script>`. That list names these cases: a `\` in a base, an empty link under a base, a `<base>` inside `<svg>`, and the unchecked links under a base with a scheme or a leading `/`. It also names the end tags of script, style, textarea, and title, which still end at their first `>`. A NEWS.md entry names the new base, comment, end tag, and script rules. The DESIGN.md "Link reader limits" entry names the base cases of that list.
- [x] AC7: `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings.

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
- [x] T5: Update the roxygen help of `check_supplement()` (`:316` to `:358`) and run `devtools::document()`. Add the NEWS.md entry under the development heading. Update the DESIGN.md "Link reader limits" entry.
- [x] T6: Run `devtools::test()` and `devtools::check()`.
- [x] T7: Review return 1. Unroll `html_script_body` so each `<` run and dash run costs one loop pass, add a test past the old PCRE margin, re-measure the PCRE figure, and fix the other fix-now items of review pass 1.

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
- 2026-10-28: T1 done: wrote `cairn/references/whatwg-html.md` from the HTML Standard copy last updated 2026-10-26 (sections 2.4.3, 4.2.3, 13.2.5.4 to 13.2.5.52), with its INDEX line.
- 2026-10-28: T2 done: `tag_links()` gives the first `<base>` href as the attribute `base` and leaves base tags out of the links; `page_values()` cleans it with the new `link_text()`; `page_links()` sorts it with `base_kind()` and `base_address()` and gives each link a `targets` path for `link_ok()`. Four tests red before the change, green after; the whole `test-check-supplement.R` passes (131 tests, 0 failed, 7 skipped).
- 2026-10-28: implement choice: a `broken-link` row under a base names the link as written on the page, not the joined path, so the author can find it in the page.
- 2026-10-28: T3 done: `html_skipped` ends a comment at `<!-->`, `<!--->`, or the first `-->` or `--!>`, and removes `</` with a non-letter to the next `>` and end tags through their attributes. Two tests red before, green after; the old skipped-text and large-page tests still pass.
- 2026-10-28: T4 done: `html_script_body` (possessive parts only) gives the script text of `html_raw_text("script")` the escaped and double escaped states. The double-escape test was red before and green after; the 1 MB test passed before too, as a guard on the PCRE limit. Measured on macOS, R 4.6: `<!--<script></script>-->` repeated reads at 4 MB and reaches the match limit by 16 MB; a plain 6 MB script still reads; the old large-page and linear-time tests pass.
- 2026-10-28: T5 done: the `check_supplement()` help page states the end rules, the base paragraph, and the new differences (end tags of the four skipped elements, `<base>` in `<svg>`, `\` in a base, empty links, links under a scheme or `/` base); `devtools::document()` rewrote `man/check_supplement.Rd`. NEWS.md has one entry; the DESIGN.md "Link reader limits" entry names the base cases and is marked narrowed M075. README, GUIDE.md, `_README.md`, and the vignettes state no link reading rules (grep), so they are unchanged.
- 2026-10-28: claim audit: 74 claims read, 8 corrected — R/check-supplement.R (help script sentences, the row-text sentence, the scheme-base difference, the `page_links()` and `html_skipped` comments, "except as listed below"), NEWS.md (scheme base, ASCII letter, script sentence), man/check_supplement.Rd. The re-read passed all 8 and found one gap in the help script sentence (the `<!--` dashes and the six delimiters), fixed with no further pass.
- 2026-10-28: T6 done: `devtools::test()` 525 tests, 0 failed, 0 errors, 12 skipped (at 0e43ffd, before the comment-only claim fixes); `devtools::check()` on 15f3b23 gave 0 errors, 0 warnings, 1 NOTE. The NOTE names `.claude/`, which holds only `scheduled_tasks.lock` that this session's wakeup timer wrote; git ignores it, so a clone and CI do not have it.
- 2026-10-28: implement done; status review.
- 2026-10-28: format fix: the T1 line's date, written with the month as a word, is rewritten as 2026-10-26 for the `iso date format` check; the fact is unchanged.
- 2026-10-28: review return 1: `html_script_body` reaches the PCRE match limit at about half the size main reads (2.5M `<` in one script body, and `<!--` with 3M dashes, where main reads 3M and 6M); unroll the plain, escaped, and double escaped parts so each `<` run and each dash run costs one loop pass, add a test past the old margin, and re-measure the "about 5 million" figure. Also fix the review's other fix-now items listed in the Review section (help, NEWS, DESIGN.md, the `tag_links()` comment, possessive `?`, and the repeated `//` base test).
- 2026-10-28: T7 checkpoint, half done: dash runs and the escaped `<!--<script></script>-->` repeat now read past main's sizes (6M dashes, 8 MB repeat), and the comment pattern's `?` are possessive. The committed `html_script_body` still reaches the PCRE limit before main on runs of `<` (any second check per `<` in the loop costs steps); a measurement of candidate shapes is running.
- 2026-10-28: T7: the user asked why the work was slow and chose the recommended route: stop the binary-search sweep (it made about 180 multi-MB probes), test one shape at fixed sizes, and choose the pattern per page if that shape fell short. The shape held, so no per-page switch was needed.
- 2026-10-28: T7 implement choice: each part of `html_script_body` loops over ordinary `<` with one class lookahead and takes `</`, `<!`, dash runs, and `<script` in an outer loop. Measured against main on macOS, R 4.6, both read 4.8M `<`, 3.5M `x<`, 20 MB of `<a href='x'>y</a> `, 4.8M `<` after `<!--`, and 6M dashes after `<!--`. Below main: 1.5M `</` in a row reads (main 2M), 2M single dashes in escaped text read (main 3M), and the escaped repeat reads 6 MB but not 8 MB. New test "script text with millions of < or of - after <!-- is read" (3M `<`, 5M dashes) reaches the limit at ffbb8ba and passes now.
- 2026-10-28: T7: fixed the other pass-1 fix-now items. The help notes the sooner limit for escaped script text, the `#` exception in the handling-order sentence, `data:` and `javascript:` in any letter case, and two new differences (a `<base>` in `<template>`, a scheme base a browser cannot parse). The `tag_links()` and PCRE-limit comments are updated. NEWS.md drops "as a browser does" and says `#` and `?` links under a base can give rows. DESIGN.md's link check text names end tags and the base folder, and its known issues entry adds the two cases. The `//example.org/` base test case is removed.
- 2026-10-28: claim audit (T7 lines): 21 claims read, 3 corrected — R/check-supplement.R (the escaped-script limit sentence in the help and the comment now name millions of `</` or separate `-` runs, and the `<svg>` base case is narrowed to outside `<foreignObject>`), cairn/DESIGN.md, man/check_supplement.Rd; the `html_script_body` comment drops its unmeasured "about half" figure. Re-read pending.
- 2026-10-28: claim audit re-read: the limit sentences and the `html_script_body` comment match (its reason rests on the T7 lookahead comparison, where every form with a second check per `<` reached the limit at 4.4M `<` and the one-check forms read 4.8M); the `<svg>` base case also excludes `<desc>`, fixed with no further pass, and the help paragraph is rewrapped.
- 2026-10-28: T7 done: `devtools::test()` on efe3c10 gives 526 tests, 0 failed, 0 errors, 12 skipped; `devtools::check()` from the same run gives 0 errors, 0 warnings, 1 NOTE (the session's git-ignored `.claude/` lock file). Later commits change comments and help text only. Status review.
- 2026-10-29: step-7 approval: m075-base-tags-odd-markup approved for merge

## Decisions

## Review

Pass 1 (2026-10-28), on branch head ffbb8ba, main at ed28d21 (not moved since the cut). Copilot round off (no `# Copilot review:` line). No PR yet.

- AC1: "relative links resolve against the folder of a local base" and "a link of only a # or ? part resolves to the base address" pass in a fresh `devtools::test()` (525 tests, 0 failed, 0 errors, 12 skipped); both were red on main before T2.
- AC2: "a base href is not a link, and only the first base with an href counts" and "web_links = TRUE does not request the address of a base" pass in the same run; both were red before T2.
- AC3: "comments end at <!-->, <!--->, --!>, and -->, and nowhere else" passes in the same run; red before T3.
- AC4: "</ and a non-letter is a bogus comment, and an end tag is read to its >" passes in the same run; red before T3.
- AC5: "a script that holds <!-- and <script> runs past its first </script>" (red before T4) and "1 MB of escaped script text is read" pass in the same run.
- AC6: help text read at ffbb8ba: the `#` sentence names the local-base exception (R/check-supplement.R:309); the base paragraph and the comment, end tag, and script rules are stated (:317 to :361); the difference list no longer names `<!-->`, `<!--->`, `--!>`, or the script case and names the `<svg>`, `\`, empty-link, scheme and `/` base cases and the four elements' end tags (:369 to :380); NEWS.md has the entry; the DESIGN.md "Link reader limits" entry names the base cases.
- AC7: `devtools::test()` as above; `devtools::check()` on 15f3b23 (package tree identical to ffbb8ba, later commits touch `cairn/` only, which `.Rbuildignore` drops): 0 errors, 0 warnings, 1 NOTE for the session's git-ignored `.claude/scheduled_tasks.lock`.
- Gate: `cairn_validate.py` all checks passed; `devtools::document()` no diff; `pkgdown::check_pkgdown()` no problems; README.Rmd unchanged; no new top-level files; NEWS.md entry present; no principle changed, so no `cairn_impact` run.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: script text reaches the PCRE match limit at about half the old size (2.5M `<` in one script body warns, main reads it) — fix now; load-bearing, return floor (review return 1)
- prior-review #1: `<script><!--` and 3M dashes warns where main reads 6M, as `-(?!->)` costs one loop pass per dash — fix now; same return
- blame-history #1: same limit drop for `<` in script bodies, with no test on the margin — fix now; same return
- diff-bug #2: the "about 5 million" PCRE figure in the comment and help overstates the headroom — fix now; re-measure after the return fix
- diff-bug #3: a scheme base whose address does not parse (`http://`) falls back to the page folder in a browser, but the check leaves the links unchecked — fix now; name it in the help's difference list and the DESIGN.md entry (not edge: a missed row is a wrong result with no warning)
- diff-bug #4: NEWS.md says "as a browser does" for the base rule though the help lists differences — fix now
- diff-bug #5: NEWS.md does not say that `#` and `?` links under a local base can now give rows — fix now
- diff-bug #6: the `//example.org/` base test takes the same code path as `/site/` — fix now; remove it
- diff-bug #7: the `tag_links()` header comment omits the `base` attribute, left-out base hrefs, and skipped end tags — fix now
- diff-bug #8: a `<base>` inside `<template>` counts as a base, though a browser ignores it — fix now; name it in the help's difference list and the DESIGN.md entry
- diff-bug #9: the help does not say `data:` and `javascript:` match in any letter case — fix now
- blame-history #2: `?` in the new comment pattern is not possessive, while the comment says every repeat is — fix now; make each `?` possessive
- blame-history #3: `#` links under a local base are now checked — reject (planned change, AC1)
- blame-history #4: M021's stated `<!-->` limit is retired — reject (planned change, AC3; recorded in the plan's collision line)
- ripple #1: help line "links with a scheme, `/`, or `#` at the start are skipped" (R/check-supplement.R:344) is false under a local base — fix now
- ripple #2: ROADMAP row "Close the link reader's browser gaps" still lists the three closed gaps — reject (planned change: the row ends with `started M075` and graduates at step 9 hygiene)
- ripple #3: ROADMAP row "Resolve page links against a base tag" describes fixed behavior — reject (planned change: graduates at step 9 hygiene)
- ripple #4: DESIGN.md architecture text (about line 175) omits base hrefs and skipped end tags — fix now
- ripple #5: DESIGN.md says each link resolves by path segments, with no word on a local base — fix now
- ripple #6: same as diff-bug #7 — fix now
- Pass-1 fix-now items: fixed in 643c997, efe3c10, 0a1e205, and f7fba85 (return 1, task T7); pass 2's prior-review lens found each one in the code.

Pass 2 (2026-10-28), on branch head 919cb2c, main at ed28d21 (not moved). One defect return so far (return 1).

- AC1 to AC5: the eight M075 tests named in pass 1, plus "script text with millions of < or of - after <!-- is read", pass in a fresh `devtools::test()` on 919cb2c: 526 tests, 0 failed, 0 errors, 12 skipped.
- AC6: help text at 919cb2c states the base rules (R/check-supplement.R:352 to :367), the comment, end tag, and script rules (:317 to :331), the `#` exception (:309, :344), and the difference list (:369 to :392) without the four closed cases and with the base cases; NEWS.md and the DESIGN.md entry match.
- AC7: `devtools::test()` as above; `devtools::check()` on 919cb2c: 0 errors, 0 warnings, 1 NOTE (the session's git-ignored `.claude/` lock file).
- Gate: `cairn_validate.py` all checks passed; `devtools::document()` no diff at 919cb2c; `pkgdown::check_pkgdown()` no problems (pass 1, `_pkgdown.yml` and exports unchanged since).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: plain script text with 2M `</a` (or 2M `<!x`) reaches the PCRE limit, where main reads 4M — reject (edge: needs millions of `</` or `<!` in one script; htmlwidgets writes `</` as `<\/`, and 20 MB of HTML-like text holding 1.2M `</` reads; effect is the PCRE-limit row). A one-lookahead variant was fuzzed (109,445 inputs, 0 mismatches) and gained nothing on `</`, so the pattern stays.
- diff-bug #2: the help and comment named only the escaped cases of the sooner limit — fix now; they now name `</` and `<!` in any script text, and `<s` and separate `-` runs after `<!--` (measured at 3M each)
- diff-bug #3: three pattern branches had no test (`->` in double escaped text, `<s` that starts no `<script`, `<!` that starts no `<!--`) — fix now; test "->, <s, and <! that start nothing stay script text", which fails on each of the three planted mutants
- diff-bug #4: the margin test discriminates — noted
- diff-bug #5: the comment said a `-`-run rule makes `--->` work, though the `-->` tail alone does — fix now; comment reworded
- diff-bug #6 to #8: the `//` test removal, the help figure, and the NEWS and help script text all match — noted
- blame-history #1: a base starting with `/` (such as `/supplement/`) or naming the site's own `https:` address leaves relative links unchecked, where main checked them against the page folder — reject (planned change: AC2 and the Scope Out item); follow-up row "Check links under a site-root base" for reading the site's path
- blame-history #2: a scheme base that does not parse (`http://`) leaves links unchecked, where main matched the browser by chance — follow-up, same row
- blame-history #3: sooner PCRE limits in escaped script text — reject (edge: millions of `</`, `<s`, or `-` runs after `<!--`; effect is the PCRE-limit row; documented)
- blame-history #4, #5: `<!-->` endings and `#` links under a base — reject (planned change, AC3 and AC1)
- blame-history #6: `..` above `docs/` under a base counts as broken — reject (false: such a path leaves the published site, the M022 rule)
- prior-review: no prior-review evidence; every pass-1 fix present. Its note on the "about 5 million" figure — noted: 5M `<` reaches the limit on main and HEAD, 4.8M reads on both (T7).
- ripple #1: ROADMAP row "Read huge script bodies past PCRE limits" cross-references "Close the link reader's browser gaps", which hygiene removes — fix now at step 9 hygiene
- ripple #2: the same row does not name the sooner escaped-script limits — fix now at step 9 hygiene
- Pass 2 fix-now work: diff-bug #2, #3, and #5, fixed 1073076. On 1073076: `devtools::test()` 527 tests, 0 failed, 0 errors, 12 skipped; `devtools::check()` 0 errors, 0 warnings, 1 NOTE (`.claude/` lock file). No changed snapshot files (no `_snaps` path in the diff). Copilot round off.
