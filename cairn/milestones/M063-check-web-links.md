<!-- Section ownership + write-modes: see tracking-rules.md "Milestone-file
     section ownership". A phase skill never rewrites another phase's section.
     Per-section owners are tagged below. The one size check that can fail is
     cairn_validate's <150 over the plan-owned body. -->
# M063: Check web links on the rendered site

- **Status:** planned   <!-- owner: transitioning skill · mirror-update; cairn/ROADMAP.md is the authority -->
- **Priority:** normal   <!-- owner: plan · create/amend-via-gate; high | normal | low -->
- **Depends on:** —   <!-- owner: plan · create/amend-via-gate; M<xx>, M<yy> or — -->
- **Driving RR:** —   <!-- owner: plan · create/amend-via-gate; RR<NN> whose Binding criteria bind this milestone's ACs (binding-criteria check), or — -->
- **Principles touched:** —   <!-- owner: plan · create/amend-via-gate; comma-separated IPn/GPn ids this milestone touches, or — -->
- **Resolves:** —   <!-- owner: plan · create/amend-via-gate; comma-separated GitHub issues the scope absorbs, each `#N closes` (the PR closes it at merge) or `#N partial` (the remainder gets a candidate row), or — ; skill conduct only — no validate check parses it -->
- **Surface tier:** user-facing — a new argument of the exported `check_supplement()`   <!-- owner: plan · create/amend-via-gate; user-facing | internal — <one-clause reason>; skill conduct only — no validate check parses it -->
- **Branch/PR:** —   <!-- owner: implement (branch) / review (PR URL) · create; a companion checkout the milestone also works in is one further entry per checkout, `companion: <abs-path> <branch>` (implement), its PR URL appended by review — /milestone-review merges companions first, in listed order -->

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

- [ ] AC1: `check_supplement()` takes a new argument `web_links`, default `FALSE`. It stops with an error of class `supplement_error_argument` when `web_links` is `NA`, `c(TRUE, TRUE)`, `"TRUE"`, `1`, or `NULL`, each tested. With the default it does not call `url_status()`: a test runs it on a fixture site whose `docs/` pages hold `https` links, with `url_status()` mocked to stop on any call, and gets no error and no `web-link` row.
- [ ] AC2: With `web_links = TRUE`, the function calls `url_status()` once for each distinct address. The pages are those that `check_links()` lists and that `read_page_text()` and `tag_links()` read without NULL or a warning. The addresses are the values that `tag_links()` returns from those pages, after `decode_refs()` and the two `gsub()` steps of `page_links()` that trim the ends and drop tabs and line breaks inside. The function keeps the values whose scheme is `http` or `https` in any letter case and removes any `#` fragment. Two addresses are distinct when their strings differ after that. A test with `url_status()` mocked to record its calls uses a fixture with these values: one address on two pages, one of them in a subfolder; the same address with a fragment; a `src` value; an address with `&amp;` in its query; an `HTTPS` scheme; a relative link; a `mailto:` link; and an address only on a page that `read_page_text()` cannot read. The test asserts that the recorded addresses equal the expected set and that none is recorded twice.
- [ ] AC3: Each address whose `url_status()` result is an error message, or a status of 400 or above, gives one row. The row has `check` `web-link`, the `file` `docs/<page>` of the first page in byte order that links it, and a `problem` that names the address and the status or the error message. A status below 400 gives no row. The rows come in byte order of address. Tests mock `url_status()` to give 200, 301, 399, 400, 404, 500, and an error, with one failing address on two pages. They assert each row's `check` and `file`, that its `problem` holds the address, the row order, and no row for 200, 301, and 399.
- [ ] AC4: For status 401, 403, 405, or 429, the row's `problem` says that the server refused the request and that the link can still work in a browser. A row for any other status, or for an error message, does not say so. Tests cover 401, 403, 405, 429, 404, and an error message.
- [ ] AC5: `url_status()` calls `curlGetHeaders()` with `redirect = TRUE` and a fixed positive `timeout`, returns the value of its `"status"` attribute, and returns the error's message when `curlGetHeaders()` stops. Tests mock a package-level `curlGetHeaders` binding to return a status and to stop, and assert the arguments it got.
- [ ] AC6: `release_supplement()` calls `check_supplement()` with `web_links` left at `FALSE`. A test runs a release that succeeds with the real check on a `checked_site()` whose `docs/index.html` holds an `https` link, with `url_status()` mocked to count its calls, and asserts that the count is 0.
- [ ] AC7: `?check_supplement` documents `web_links`: which addresses it requests, that it follows redirects, that it requests the addresses one after another with a fixed timeout each, which results give a row, the statuses of AC4, that pages the link check cannot read give no `web-link` row, and that `release_supplement()` does not run it. NEWS.md has one entry for it. README.md and `inst/template/GUIDE.md` each add a line next to the `check_supplement()` call that they show, which names `web_links = TRUE`.
- [ ] AC8: No test or example makes a real web request: each test of the check mocks `url_status()` or `curlGetHeaders`. The profile's verify slot is clean (`devtools::document()`, `devtools::test()`), and `devtools::check()` gives 0 errors and 0 warnings.

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

- [ ] T1: Tests first, then an internal `web_addresses(path)` in `R/check-supplement.R`. It walks the pages as `check_links()` does (`docs_entries()`, `outside_links()`, `sort_bytes()`), reads each with `read_page_text()`, `tag_links()`, and `decode_refs()`, keeps the `http` and `https` values, drops fragments, and maps each address to its first page. Share the decode-and-trim step with `page_links()` rather than copying it.
- [ ] T2: Tests first, then `url_status(url)` with a package-level `curlGetHeaders` binding for the mock, and `check_web_links(path)`, which builds the rows of AC3 and AC4.
- [ ] T3: Tests first, then the `web_links` argument and its check in `check_supplement()`. Add the release test of AC6 to `tests/testthat/test-release-supplement.R`, with `skip_if_no_git()`.
- [ ] T4: Roxygen `@param web_links` and a help section, then `devtools::document()`. Write the NEWS.md entry, the README.md and `inst/template/GUIDE.md` lines, and DESIGN.md's account of the checks.
- [ ] T5: Run `devtools::check()` and fix any note that the change caused.

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

## Decisions
<!-- owner: implement / review · append-only; milestone-local. -->

## Review
<!-- owner: review · exclusive -->
