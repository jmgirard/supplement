# M044: Advise deleting unreadable format files

**Status:** done (2026-10-23, PR #45 https://github.com/jmgirard/supplement/pull/45)

**Goal:** The problem text of a `"stale-output"` row shows which stored output files it names, and how to clear a row whose unreadable file no render rewrites.

**Outcome:** `quote_path()` in `R/check-supplement.R` puts each `_freeze/analyses/<name>/execute-results/<file>` path that `check_stale_output()` names between double quotes, with `\` before each `\` and `"`, after `show_text()` and `sort_bytes()`, in both the "differs" and the "cannot be read" texts. The "cannot be read" text now ends with `rerender_steps` and then a delete step: if the row stays after those steps, the files can be from a format that the report no longer renders, or damaged, so delete them, render the whole site, and commit the report with `_freeze/`, `docs/`, and `figures/`. The help item and the NEWS.md `check_supplement()` bullet state both. Tests: the unreadable-hash test asserts the whole text for four report shapes; a quoting test covers `a, b.json`, `x, y.json`, and (skipped on Windows) `d"e.json`, `f\g.json`, and a report named `q"r`; a Quarto render test shows the render steps clear a damaged `html.json` while a dropped format's damaged `docx.json` stays until it is deleted.

**Decisions:** Plan gate: the delete step in every "cannot be read" text (not only beside a matching file), and the `, ` join fixed here; double quotes with `\` escapes over `encodeString()` (locale-dependent) and one path per line (a name can hold a line break).

**Review:** Criteria audit at plan (full mode): 8 findings, all fixed. Claim audit: 18 claims, 1 corrected (help "If so"). Four-lens review: 18 findings, no correctness bug; 2 fix-now (one NEWS sentence on which rows give a delete step, fixed 2c68438), 16 rejected (planned change, false, style). `devtools::check()` 0/0/0 on macOS; CI passed on all six jobs. Graduated "Advise deleting unreadable format files". One lesson extended (M017 line: a render by name rewrites a `.json` that does not parse).
