# M004: Home page from _supplement.yml with shortcodes

**Status:** done (2026-10-18, PR #4 https://github.com/jmgirard/supplement/pull/4)

**Goal:** Drive the template's home page from one `_supplement.yml` file through a Quarto extension whose shortcodes render the DOI badge, the Zenodo download link, and the data table.

**Outcome:** `inst/template/_supplement.yml` holds a `supplement:` map (title, citation, preprint, contact, SPDX licenses, authors, Zenodo DOIs and archive URL, data files), loaded by `metadata-files` in `_quarto.yml`. `index.qmd` reads the title, citation, and contact with `{{< meta >}}`. `_extensions/supplement/supplement.lua` adds `supplement-doi` (version DOI, then concept DOI, else nothing), `supplement-download`, and `supplement-data-table` (base-1000 sizes by integer rounding, links from `quarto.project.offset`, a stop when a file is missing or is a folder). Quarto rewrites metadata values that name an existing path to be page-relative, so the table undoes that for files and descriptions. Quarto redefines `error()` in filters to print only, so the shortcode stops with `assert(false, …)`. 22 shortcode and template tests, 180 expectations; five planted defects each fail a test.

**Decisions:** D-008 (a missing data file stops the render). DESIGN's convention now allows a Lua extension in the template.

**Review:** three reviewers plus a claim audit before review. The claim audit corrected 5 claims and found descriptions rewritten on subfolder pages (fixed). Of 27 reviewer findings, 11 were fixed on the branch: folded YAML descriptions crashing, Markdown-mangled file names (naming rule and error hint), a `rename`-based existence check failing in read-only folders, folder entries rendering a row, and the DOI format. Fixing them showed the old `error()` call did not stop the render. 11 went to rows: new "license footer" and "shortcode edge cases", and "Windows check" (2 GiB files, 1 GB fixture). 5 were rejected, among them the data-free rebuild objection (planned, D-008). The "template extraction" row graduated.
