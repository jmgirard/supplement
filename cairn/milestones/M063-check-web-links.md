<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M063: Check web links on the rendered site

- **Status:** review   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — a new argument of the exported `check_supplement()`   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** m063-check-web-links   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

## Goal
<!-- owner: plan · create; a wrong goal returns to plan, never edited in place -->

`check_supplement(web_links = TRUE)` requests each `http` or `https` address that its tag reader finds on the rendered pages and gives a row for each one that fails, and `release_supplement()` does not run this check.

## Scope
<!-- owner: plan · create/amend-via-gate -->

**In:**
- An opt-in argument `web_links` of `check_supplement()`, default `FALSE` (D-030).
- `url_status()`, an internal helper that requests one address with base R's `curlGetHeaders()`. It sends a HEAD request, follows redirects, and stops after a fixed timeout.
- `web-link` rows for addresses that fail.
- The help page, NEWS.md, README.md, the template's GUIDE.md, and DESIGN.md's account of the checks.

**Out:**
- A retry with a GET request when a server refuses a HEAD request. This is the new candidate row "Retry refused web links with GET".
- Running the check from `release_supplement()`. The user chose a report-only check at the plan gate (D-030).
- Links in files other than `.html` pages, and markup that `tag_links()` reads differently from a browser. The existing rows "Close the link reader's browser gaps" and "Resolve page links against a base tag" hold that work.

## Acceptance criteria
<!-- owner: plan · create/amend-via-gate; review reads, never reinterprets. -->

- [x] AC1: `check_supplement()` takes a new argument `web_links`, default `FALSE`. It stops with an error of class `supplement_error_argument` when `web_links` is `NA`, `c(TRUE, TRUE)`, `"TRUE"`, `1`, or `NULL`, each tested. With the default it does not call `url_status()`: a test runs it on a fixture site whose `docs/` pages hold `https` links, with `url_status()` mocked to stop on any call, and gets no error and no `web-link` row.
- [x] AC2: With `web_links = TRUE`, the function calls `url_status()` once for each distinct address. The pages are those that `check_links()` lists and that `read_page_text()` and `tag_links()` read without NULL or a warning. The addresses are the values that `tag_links()` returns from those pages, after `decode_refs()` and the two `gsub()` steps of `page_links()` that trim the ends and drop tabs and line breaks inside. The function keeps the values whose scheme is `http` or `https` in any letter case and removes any `#` fragment. Two addresses are distinct when their strings differ after that. A test with `url_status()` mocked to record its calls uses a fixture with these values: one address on two pages, one of them in a subfolder; the same address with a fragment; a `src` value; an address with `&amp;` in its query; an `HTTPS` scheme; a relative link; a `mailto:` link; and an address only on a page that `read_page_text()` cannot read. The test asserts that the recorded addresses equal the expected set and that none is recorded twice.
- [x] AC3: Each address whose `url_status()` result is an error message, or a status of 400 or above, gives one row. The row has `check` `web-link`, the `file` `docs/<page>` of the first page in byte order that links it, and a `problem` that names the address and the status or the error message. A status below 400 gives no row. The rows come in byte order of address. Tests mock `url_status()` to give 200, 301, 399, 400, 404, 500, and an error, with one failing address on two pages. They assert each row's `check` and `file`, that its `problem` holds the address, the row order, and no row for 200, 301, and 399.
- [x] AC4: For status 401, 403, 405, or 429, the row's `problem` says that the server refused the request and that the link can still work in a browser. A row for any other status, or for an error message, does not say so. Tests cover 401, 403, 405, 429, 404, and an error message.
- [x] AC5: `url_status()` calls `curlGetHeaders()` with `redirect = TRUE` and a fixed positive `timeout`, returns the value of its `"status"` attribute, and returns the error's message when `curlGetHeaders()` stops. Tests mock a package-level `curlGetHeaders` binding to return a status and to stop, and assert the arguments it got.
- [x] AC6: `release_supplement()` calls `check_supplement()` with `web_links` left at `FALSE`. A test runs a release that succeeds with the real check on a `checked_site()` whose `docs/index.html` holds an `https` link, with `url_status()` mocked to count its calls, and asserts that the count is 0.
- [x] AC7: `?check_supplement` documents `web_links`: which addresses it requests, that it follows redirects, that it requests the addresses one after another with a fixed timeout each, which results give a row, the statuses of AC4, that pages the link check cannot read give no `web-link` row, and that `release_supplement()` does not run it. NEWS.md has one entry for it. README.md and `inst/template/GUIDE.md` each add a line next to the `check_supplement()` call that they show, which names `web_links = TRUE`.
- [x] AC8: No test or example makes a real web request: each test of the check mocks `url_status()` or `curlGetHeaders`. The profile's verify slot is clean (`devtools::document()`, `devtools::test()`), and `devtools::check()` gives 0 errors and 0 warnings.

## Coverage
<!-- owner: plan · create/amend-via-gate -->

- AC1 → T3
- AC2 → T1
- AC3 → T2
- AC4 → T2
- AC5 → T2
- AC6 → T3
- AC7 → T4
- AC8 → T1, T2, T3, T5

## Tasks
<!-- owner: plan (create) / implement (check-off, minor edits) -->

- [x] T1: Tests first, then an internal `web_addresses(path)` in `R/check-supplement.R`. It walks the pages as `check_links()` does (`docs_entries()`, `outside_links()`, `sort_bytes()`), reads each with `read_page_text()`, `tag_links()`, and `decode_refs()`, keeps the `http` and `https` values, drops fragments, and maps each address to its first page. Share the decode-and-trim step with `page_links()` rather than copying it.
- [x] T2: Tests first, then `url_status(url)` with a package-level `curlGetHeaders` binding for the mock, and `check_web_links(path)`, which builds the rows of AC3 and AC4.
- [x] T3: Tests first, then the `web_links` argument and its check in `check_supplement()`. Add the release test of AC6 to `tests/testthat/test-release-supplement.R`, with `skip_if_no_git()`.
- [x] T4: Roxygen `@param web_links` and a help section, then `devtools::document()`. Write the NEWS.md entry, the README.md and `inst/template/GUIDE.md` lines, and DESIGN.md's account of the checks.
- [x] T5: Run `devtools::check()` and fix any note that the change caused.

## Work log
<!-- owner: any skill · append-only; one line per entry; absolute dates. -->

- 2026-10-26: created by /milestone-plan.
- 2026-10-26: tier check: not run — work named at the question set.
- 2026-10-26: idea vet: one concern, that a down site or a server that refuses scripts gives a false alarm and every check_supplement() row stops release_supplement(). The question set answered it: the check is opt-in and report only.
- 2026-10-26: question set: what to work on — "Check web links on the rendered site". How a check whose findings can be wrong should act — opt-in argument, default off, report only, and release_supplement() does not run it.
- 2026-10-26: lessons used: 2026-10-20 (M021) PCRE limits in tag_links(), 2026-10-20 (M022) byte-order sort of names, 2026-10-26 (M061) paste0() on an empty vector in fixture helpers.
- 2026-10-26: collision check: absorbed the candidate row "Check web links on the rendered site" (from the M008 plan). D-009 and D-017 stand, since curlGetHeaders() is base R and tag_links() is reused. No archived milestone checks web links. Inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-26: criteria audit (full mode, fresh Opus reader): 16 findings, all fixed. AC1 now promises no url_status() call and names five bad values. AC2 names the trim steps, the readable-page domain, string distinctness, and the src, &amp;, subfolder, and unreadable-page cases. AC3 adds 301, 399, 400, 500, a two-page failure, and row order. AC4 covers all four statuses and an error. New AC5 covers url_status(). AC6 needs a release that succeeds. AC7 adds unreadable pages and the timeout, and picks an added line. AC8 adds no real web request. The goal now matches AC2.
- 2026-10-26: plan gate chose base R curlGetHeaders() (HEAD request) over a GET request through url() or a new HTTP package because it needs no dependency and reads no page body; falsified by evidence that most journal or DOI links refuse HEAD requests from scripts.
- 2026-10-26: plan gate chose a check_supplement() argument over a separate exported check_web_links() because the candidate row and the user's answer frame it as part of the release check; falsified by users asking to run the web check without the other checks.
- 2026-10-26: plan gate chose one row per failing address, on its first page, over one row per page and address because a navbar link is on every page; falsified by authors needing every page that holds a dead link.
- 2026-10-26: added candidate row "Retry refused web links with GET" for the HEAD-refused case.
- 2026-10-26: sizing: 8 criteria pass the 7-criterion tripwire, after the audit added the url_status() criterion. Kept as one milestone, since all eight cover one argument in one file and one PR, and no part ships alone.
- 2026-10-26: implement started on branch m063-check-web-links, cut from main at 19ca1e7.
- 2026-10-26: T1 done. page_values() now holds the read, decode, and trim steps that page_links() used, and site_pages() the page list of check_links(). web_addresses() returns a data frame of address and first page. The test site mocks read_page_text() and tag_links() for the unreadable-page and PCRE-warning cases. devtools::test(): 424 tests, 0 failed.
- 2026-10-26: T2 done. url_status() calls curlGetHeaders(redirect = TRUE, timeout = 10) through a NULL namespace binding that tests mock, and folds libcurl's line breaks in error messages into spaces. check_web_links() sorts addresses in byte order and prints one info line with their count. A real request to a missing r-project.org page gave libcurl error 92 (HTTP/2 stream not closed cleanly), not 404, so such a page gets a no-response row. Planted defects (429 dropped from the refused statuses, 400 read as working) turned both row tests red. devtools::test(): 427 tests, 0 failed.
- 2026-10-26: T3 done. check_supplement(path, web_links = FALSE) checks the flag with isTRUE()/isFALSE() after check_path() and runs check_web_links() after check_links(). Tests cover the five bad values, no url_status() call by default, the recorded addresses with web_links = TRUE, and a release with the real check that calls url_status() 0 times. devtools::test(): 431 tests, 0 failed.
- 2026-10-26: T4 done. Help page: @param web_links, a "web-link" bullet, and the argument error. NEWS.md entry, a line beside the call in README.md and inst/template/GUIDE.md, and DESIGN.md's link-check paragraph. Also added a line to vignettes/publishing.Rmd, which shows the same call (beyond AC7's list). devtools::test(): 431 tests, 0 failed.
- 2026-10-26: claim audit: 53 claims read, 2 corrected — R/check-supplement.R, man/check_supplement.Rd, NEWS.md, cairn/DESIGN.md. (1) The 10-second timeout holds only on R 4.1.0 or later, where curlGetHeaders() gained `timeout`, and DESCRIPTION sets no R floor. url_status() now passes `timeout` only when base::curlGetHeaders() has it, calling do.call("curlGetHeaders") so the NULL binding is skipped, and the help says "on R 4.1.0 or later". Chosen over adding `Depends: R (>= 4.1.0)`, a dependency change the plan did not grant. (2) "No response" was wrong for certificate errors and addresses curl rejects ("URL rejected: No host part"), so the row now says "could not be requested". Also added a row for a non-numeric or NA status in web_problem(). Checkpoint: the full check runs again before T5 is ticked.
- 2026-10-26: T5 done. devtools::check() on f6ac051: 0 errors, 0 warnings, 1 note (the local .claude folder, as at M062), with the tests run inside it. Status set to review.
- 2026-10-26: review checkpoint: evidence recorded for AC1–AC4 and AC6–AC8. AC5 is held, since its "fixed positive timeout" cannot hold on R before 4.1.0. Four reviewers are running.
- 2026-10-26: review pass 1: four lenses gave 30 findings. 12 were fixed now in 44341af, 3 went to follow-up rows ("Read each page once for web links", "Request web addresses with invalid bytes", and an addition to "Retry refused web links with GET"), and 15 were rejected (8 false, 5 planned change, 2 style).
- 2026-10-26: amendment routed: AC5 — "a fixed positive `timeout`" cannot hold on R before 4.1.0, where curlGetHeaders() has no `timeout` argument, and the test the criterion names runs only on the R in use. Status in-progress for the AC5 amendment alone.
- 2026-10-26: correction to the review pass 1 line: the 15 rejects were 9 false, 4 planned change, and 2 style, as the Review section lists them.
- 2026-10-26: re-audit: AC5 (full) — the first amended wording ("with a fixed positive `timeout` where `curlGetHeaders()` takes that argument") left out the trim of white space at the ends that the code and test do, and still claimed every R version while the test runs on one R and testthat 3.3 needs R 4.1.0, so the before-4.1.0 branch cannot run. Wording narrowed to R 4.1.0 and later, with the trim stated.
- 2026-10-26: re-audit: AC5 (full) — the second wording still claimed future R versions while the test runs on one R, "fixed" and the trim at the start were not probed, and "Tests mock … and assert the arguments" binds the test, not the package. Suggested wording: "On the R in use (4.1.0 or later), `url_status()` calls `curlGetHeaders()` with `redirect = TRUE` and the same positive numeric `timeout` on every call. It returns the `"status"` attribute of that call's result, or, when the call stops, the error's message with each run of white space replaced by one space and white space at either end removed." This is the second re-audit of AC5, so the wording goes to the user.
- 2026-10-27: stop: AC5 wording — the user chose "Require R 4.1.0" over the reader's narrowed wording. AC5 keeps its planned text, so no amendment is written and no `amendment return:` line counts. Dependency change recorded as D-031.
- 2026-10-27: DESCRIPTION has `Depends: R (>= 4.1.0)`. url_status() always passes `timeout = web_timeout` and calls curlGetHeaders() directly again (the formals() branch and do.call() are gone). The url_status() test asserts the timeout without a branch. The help says "waits up to 10 seconds", DESIGN.md cites D-031, and NEWS.md says the package now needs R 4.1.0. devtools::test(): 431 tests, 0 failed. CI runs R release only.
- 2026-10-27: claim audit: 64 claims read, 2 corrected — vignettes/publishing.Rmd (a web row does not stop a release because release_supplement() does not run the check, not because the site is out of the author's control), R/check-supplement.R (the refused-status comment: a browser may need a login too).
- 2026-10-27: devtools::check() on 08eb269 (with the R floor): 0 errors, 0 warnings, 1 note (local .claude folder). 1b1bcca changed only a comment and a vignette sentence. Status set to review.

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive -->

Evidence gathered 2026-10-26 on m063-check-web-links at ef8ffa5 (R 4.6.1, macOS). main had not moved (19ca1e7). test-check-supplement.R and test-release-supplement.R: 146 tests, 0 failed, 0 errors, 6 skipped (none of the web tests).

- AC1: "web_links must be TRUE or FALSE" passes, 5 expectations, one per value (NA, c(TRUE, TRUE), "TRUE", 1, NULL), each `supplement_error_argument`. "by default check_supplement() requests no web address" passes on web_site(), with url_status() mocked to stop: no error, 0 web-link rows.
- AC2: "web_links = TRUE requests each web address on the pages once" passes: the recorded calls equal the 6 expected addresses, none twice. web_site() holds an address on index.html and analyses/report.html, the same address with `#part`, an `<img src>`, `&amp;` in a query, an `HTTPS` scheme, a relative link, `mailto:`, `ftp:`, an address only on locked.html (read_page_text() mocked to NULL), and one only on bad.html (tag_links() mocked to warn). "web addresses are read once each, with the first page in byte order" passes, 3 expectations.
- AC3: "each address that fails gives one web-link row on its first page" passes, 8 expectations. Results 500, 200, 301, 399, 404, 400, and an error give exactly 4 rows, all `web-link`, in the order 400, 404, 500, error. The 404 address, also on analyses/report.html, names that page. Each problem holds its address, the 404 row holds "status 404", and the error row holds the libcurl message.
- AC4: "a row for a status that servers give scripts says the link can work in a browser" passes. One identical() compares the refused sentence's presence over 401, 403, 405, 429 (TRUE) and 404 and an error message (FALSE). A planted defect at T2 (429 left out of the list) turned it red.
- AC6: "the release runs the real check without the web link check" passes, 2 expectations, not skipped (git present). checked_site() with an `https` link in docs/index.html releases 1.0.0, and the url_status() mock that counts calls (and would return 404) counts 0. release_supplement() calls `check_supplement(path)` (R/release-supplement.R:205).
- AC7: man/check_supplement.Rd's "web-link" item names the addresses (http/https values of the broken-link pages, fragment removed), redirects, one-after-another requests with a 10-second wait on R 4.1.0 or later, the failure and 400-or-above rule, the 401/403/405/429 sentence, that unreadable pages give no row, and that release_supplement() does not run it. NEWS.md has one bullet. README.md:121 and inst/template/GUIDE.md:201 name `web_links = TRUE` in the paragraph after the call.
- AC8: grep of tests/testthat/*.R for `web_links = TRUE`, `check_web_links`, and `url_status(`: each call runs after a url_status() mock (mock_status(), the AC1 stop mock, the AC6 counter) or under a curlGetHeaders mock (the url_status() test). The help example calls `check_supplement(site)` with the default. `devtools::document()` gave no diff. devtools::check() on f6ac051: 0 errors, 0 warnings, 1 note (local .claude folder); ef8ffa5 differs from f6ac051 only in cairn/ files. `pkgdown::check_pkgdown()`: no problems.
- AC5: held, unticked. On R 4.6.1, "url_status() follows redirects with a timeout and gives the status or the error message" passes: redirect = TRUE, timeout 10, the status, and the folded error message. But since the claim-audit fix, url_status() passes no `timeout` on R before 4.1.0, where curlGetHeaders() has no such argument. The criterion's "a fixed positive `timeout`" cannot hold there for any implementation, and the test it names runs only on R 4.6.1. That is a wrong criterion, not a defect: amendment routed.

Gate: cairn_validate.py all checks passed (1 advisory, the 8-criterion sizing WARN). No principle changed, so cairn_impact.py was not run. `devtools::document()` gave no diff. No README.Rmd. `pkgdown::check_pkgdown()`: no problems. NEWS.md has the entry, with no milestone number. No new top-level file. devtools::check() on f6ac051: 0 errors, 0 warnings, 1 note (the local .claude folder, not in the built package from git). After the fix-now commit 44341af, devtools::test(): 431 tests, 0 failed. The first run of that suite failed "the license shortcode shows nothing for an empty value or no license map" (test-shortcodes.R), which passed alone with NOT_CRAN=true and in a second full run. That test does not touch the changed code.

spawned: diff-bug, blame-history, prior-review, ripple

- diff-bug #1: test-check-supplement.R:2105 asserts a numeric timeout, which fails on R before 4.1.0 — fix now, fixed 44341af (the assertion holds only where curlGetHeaders() takes `timeout`, else expects none). The AC5 wording goes to an amendment.
- diff-bug #2: an address with a space is sent raw. libcurl rejects it ("URL rejected: Malformed input to a URL function", run against 127.0.0.1:9), so the row is false. A byte that is not valid UTF-8 is requested as the text `<e9>` — the space part fixed now, fixed 44341af (url_status() sends a space as %20, with a test). The invalid-byte part is a follow-up: new row "Request web addresses with invalid bytes". Non-ASCII UTF-8 reached curl unchanged in the same run.
- diff-bug #3: a bare `http:` value is requested and gives an error row — reject, false: such a link is broken in a browser too, so the row is right.
- diff-bug #4: links that start with `//` are checked by neither check, and the help does not say so — fix now, fixed 44341af (help sentence).
- diff-bug #5: servers that answer HEAD with 400, 404, or 501 get rows with no browser note — follow-up, absorbed into "Retry refused web links with GET".
- diff-bug #6: the url_status() comment said that before R 4.1.0 it "waits as long as libcurl does", which was not read from any source — fix now, fixed 44341af (comment now says only that no timeout is passed).
- diff-bug #7: each page is read twice with web_links = TRUE — follow-up, new row "Read each page once for web links".
- diff-bug #8: a DESIGN.md line is 118 characters — reject, style.
- diff-bug #9: the AC3 test checked the status text only for 404 — fix now, fixed 44341af (400, 404, and 500 asserted).
- diff-bug #10: the five bad values, the four refused statuses, and the three statuses below 400 run one code path each — reject, planned change (AC1, AC3, and AC4 name each input).
- diff-bug #11: the AC2 test and the web_addresses() test assert the same address set — reject, false: the AC2 test records url_status() calls through check_supplement(), and the other reads web_addresses() and its pages.
- diff-bug #12: three test helper comments restate the code — reject, style.
- blame-history #1: the "broken-link" help item said "no web address is requested" — fix now, fixed 44341af.
- blame-history #2: the vignette put the web check under "Fix each problem", though some web rows cannot be fixed — fix now, fixed 44341af (the vignette now says such a row can come from a site the author does not control).
- blame-history #3: a reference such as `&eacute;` stays encoded, so the request differs from a browser's, and the "web-link" item did not say so — fix now, fixed 44341af (help sentence).
- blame-history #4: the help title line "problems that can break a release" overstates now that web rows do not stop one — reject, false: a dead web link is a problem in the released site, and the item says release does not run the check.
- blame-history #5: release_supplement()'s help did not say that it skips the web check — fix now, fixed 44341af.
- blame-history #6: check_web_links() repeated sort_bytes()'s byte-order code — fix now, fixed 44341af (order_bytes() shared).
- blame-history #7: grepl() and sub() in web_addresses() lack useBytes — reject, false: the values are valid UTF-8 after show_text(), and page_links() runs grepl() on the same values.
- blame-history #8: a comment says "page_links() then returns FALSE" — reject, false: it still does, through page_values().
- blame-history #9: DESIGN.md's "R 4.1.0" for the timeout is unverified — reject, false: the claim audit read `?curlGetHeaders` ("Added in R 4.1.0").
- prior-review #1: each page is read twice — follow-up, the same row as diff-bug #7.
- prior-review #2: addresses with spaces or non-ASCII text are sent unencoded — fix now for spaces, fixed 44341af; non-ASCII reached curl unchanged; invalid bytes are a follow-up, as for diff-bug #2.
- prior-review #3: the README line partly reverses M051's move of check limits to the help page — reject, planned change (AC7 asks for the line).
- prior-review #4: the new release test starts with skip_if_no_git() — reject, false: checked_site() is a git site that the release's real check needs, and the test ran unskipped.
- ripple #1: the "broken-link" help item contradicts the new check — fix now, fixed 44341af (as blame-history #1).
- ripple #2: DESIGN.md's list of check_supplement()'s outside calls omits the network — reject, false: the same paragraph describes the curlGetHeaders() request.
- ripple #3: the candidate row "Check web links on the rendered site" still asks for this work — reject, planned change: post-merge hygiene graduates it.
- ripple #4: test mocks of check_supplement() have no web_links formal — reject, false: they stand in for calls that pass only `path`.
- ripple #5: README.md and GUIDE.md put the web sentence before "It finds:" — reject, planned change (AC7 places the line next to the call).

Pass 2, 2026-10-27, on d98d5c3 (main still 19ca1e7), after the R floor (D-031) and the fix-now commit 44341af. test-check-supplement.R and test-release-supplement.R: 146 tests, 0 failed, 0 errors, 6 skipped (none of the web tests). The nine web tests pass with the expectation counts of pass 1, except "each address that fails…" (10, with the 400 and 500 status text added) and the url_status() test (6, with the %20 check added). AC1–AC4 and AC6–AC8 hold on this head as recorded above; AC8's grep finds the same mocked calls, and devtools::check() on 08eb269 gave 0 errors, 0 warnings, 1 note (local .claude folder). `devtools::document()` gave no diff, and cairn_validate.py passed.

- AC5: "url_status() follows redirects with a timeout and gives the status or the error message" passes, 6 expectations, with no R-version branch. The mocked curlGetHeaders binding gets the address, `redirect = TRUE`, and `timeout` 10 (numeric, length 1, positive). url_status() returns its `"status"` attribute (404L), and when the mock stops, the error's message folded to one line ("libcurl error code 6: no host"). DESCRIPTION's `Depends: R (>= 4.1.0)` (D-031) makes the `timeout` argument present on every R that installs the package.
