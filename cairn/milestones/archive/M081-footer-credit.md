# M081: Credit the package in the site footer

**Status:** done (2026-11-26, PR #82 https://github.com/jmgirard/supplement/pull/82)

**Goal:** The page footer of every new site says "Created with supplement", with "supplement" linked to the package repository.

**Outcome:** `inst/template/_quarto.yml` adds `right: "Created with [supplement](https://github.com/jmgirard/supplement)"` under `page-footer`, with a comment that says to delete it and the comment to remove the credit. The license line stays in `center`. Quarto writes the credit as `<p>` text inside `<div class="nav-footer-right">` on every page. `tests/testthat/test-shortcodes.R` adds `footer_right()` and the test "the right part of the page footer credits the package", which checks the text and the one link on `index.html` and `analyses/example.html` of a rendered template copy. `inst/template/GUIDE.md`, the `_supplement.yml` header comment, `cairn/DESIGN.md`, and NEWS.md describe the credit and how to remove it. Sites made before the change keep their footer. With `web_links = TRUE`, `check_supplement()` now requests the credit address once per site (it answered 200 on 2026-11-26).

**Decisions:** none. At the plan gate the user chose the footer's right part over the end of the license line, and only the word "supplement" as the link.

**Review:** Full criteria audit at plan (8 findings, all taken). One substantive amendment at implement: AC1 and AC5 name Quarto 1.10.19 (pinned in CI) and 1.11.9 (local), and AC1 trims the footer text at both ends, the user's choice at the second-re-audit stop. Claim audit: 10 claims, 0 corrected, 2 stale comments fixed. One four-lens pass, 18 findings: 6 fix-now lines (4 distinct: test helper, page info on count checks, a NEWS note for older sites, a comment wrap), 8 rejected, 4 noted, 0 follow-ups. Local suite 0 failures; `devtools::check()` 0/0/0; R-CMD-check green on three systems with Quarto 1.10.19. No rows graduated or unparked; no lessons captured or marked; M078 row pruned.
