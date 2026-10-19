# M010: The footer, the DOI badge, and the citation files agree with _supplement.yml

**Status:** done (2026-10-18, PR #11 https://github.com/jmgirard/supplement/pull/11)

**Goal:** The page footer, the DOI badge, and the two citation files agree with the license and DOI values in `_supplement.yml`.

**Outcome:** `inst/template/_extensions/supplement/supplement.lua` adds the `supplement-license` shortcode. It reads `license.code` or `license.content`, undoes Quarto's path rewrite with `as_written()`, and maps eight SPDX ids to readable names, matched in lowercase. Other ids show as written, and an empty value shows nothing. The footer in `_quarto.yml` uses `{{< supplement-license code >}}` and `{{< supplement-license content >}}`, and still links to `LICENSE.md` and `LICENSE-CC-BY.md`. A Lua `bare_doi()` in `supplement-doi` removes `doi:` plus spaces and `http(s)://` plus `doi.org/`, `dx.doi.org/`, or `www.doi.org/`, in any letter case, from both DOI values. `license_id()` in `R/supplement-yml.R` matches `\A[A-Za-z0-9][A-Za-z0-9.-]*\+?\z`. `write_citation()` (code and content) and `write_zenodo()` (content) call it before any write and stop with `supplement_error_license`. The template comments, `_README.md`, both help pages, NEWS.md, and DESIGN.md describe the changes.

**Decisions:** D-012 (license ids get a shape check, not a list check). Milestone-local: none.

**Review:** one pass with three fresh reviewers (diff-bug, blame-history, prior-review), 22 findings. Five were fixed on the branch: the error hint, "GPL 3.0 only", a `_README.md` DOI sentence, line wraps, and test info. Twelve went to the new row "footer and badge edge cases", and five were rejected as planned or not a defect. No returns, no amendments. `R CMD check` 0/0/0. The rows "license footer", "badge DOI form", and "metadata value checks" graduated. The vocabulary part of "metadata value checks" was declined at the plan gate (D-012).
