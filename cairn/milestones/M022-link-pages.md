# M022: The link check reads every page once and refuses links out of docs

- **Status:** in-progress
- **Priority:** normal
- **Depends on:** M021
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — `check_supplement()` is exported, and its `broken-link` rows decide whether a release goes ahead
- **Branch/PR:** m022-link-pages

## Goal

`check_supplement()` reads each page in `docs/` once, pages in hidden folders included, and gives a `broken-link` row for a symbolic link in `docs/` whose target is outside `docs/`.

## Scope

**In:** a page listing in `check_links()` (`R/check-supplement.R`, around line 277) that includes hidden files and folders and does not enter a linked folder; a row for each link in `docs/` (a symbolic link, or on Windows a junction, as `is_link()` finds them) whose existing target is outside `docs/`; a page link whose target path passes through such a link counts as broken. The `broken-link` bullet of the help page, a NEWS.md entry, the `cairn/DESIGN.md` Architecture text, and tests.

**Out:** how links are read from a page → M021. A link whose target does not exist → reported as today (a page that cannot be read, or a link to a missing file). A `docs/` folder that is itself a link → read through, as today; T3 adds this to the "Release check edge cases" entry of the `cairn/DESIGN.md` Known issues. A file link to a missing file on Windows, which `is_link()` misses → the "Detect broken file links on Windows" row.

## Acceptance criteria

- [ ] AC1: Pages in hidden places are read. An `<a href>` to a missing file on `docs/.hidden/page.html`, on `docs/.page.html`, and on `docs/sub/.deep/page.html` gives a `broken-link` row for that page.
- [ ] AC2: The page listing does not enter a linked folder. With `docs/loop` a symbolic link to `docs/` and `docs/inner` a symbolic link to `docs/sub`, each page's `broken-link` rows appear once, with `file` the page's own path (`docs/sub/page.html`, never `docs/inner/page.html` or `docs/loop/…`), and neither link gives a row of its own.
- [ ] AC3: Each link in `docs/`, to a file or a folder, whose target exists and resolves to a place outside `docs/` gives one `broken-link` row, with `file` the link's path in the site and a `problem` that says the link points outside `docs/`, so the published site lacks its target. A target equal to `docs/` or under it is inside. Tested shapes: a file link to the site's `_supplement.yml`, a file link to a file outside the site folder, a file link `docs/out.html` to a page outside the site folder that holds a link to a missing file, and a folder link to a folder outside the site folder. The `.html` file link gives only its AC3 row: the page it points to is not read for links. A file link and a folder link whose targets are inside `docs/` give no such row.
- [ ] AC4: A link on a page whose target path passes through or ends at a link of AC3 gives a `broken-link` row for that page link. Tested shapes: with `docs/private` a folder link to a folder outside the site that holds `x.csv`, `<a href="private/x.csv">` gives a row; with `docs/data.csv` a file link to a file outside the site, `<a href="data.csv">` gives a row. The same links through links whose targets are inside `docs/` give no row, as today.
- [ ] AC5: On Windows, a junction in `docs/` to a folder outside `docs/` gives the AC3 row, and a page link through it gives the AC4 row.
- [ ] AC6: The `broken-link` bullet of the `check_supplement()` help page states the rules of AC1 to AC4, and NEWS.md has an entry for the change.

## Coverage

- AC1 → T1, T2
- AC2 → T1, T2
- AC3 → T1, T2
- AC4 → T1, T2
- AC5 → T1, T4
- AC6 → T3

## Tasks

- [x] T1: In `tests/testthat/test-check-supplement.R`, add one test per criterion AC1 to AC5 with the listed shapes. Symbolic-link tests skip with a stated reason where `file.symlink()` returns FALSE (Windows without developer mode); the AC5 test makes junctions with `Sys.junction()` and skips off Windows. Each test asserts the exact set of (file, problem) rows. Run them before T2 and see each fail for the shape it targets.
- [x] T2: In `R/check-supplement.R`, list pages with a walk over `list.files(all.files = TRUE, no.. = TRUE)` that enters a folder only when `is_link()` is FALSE for it; collect each link it meets; compare each link's normalized target with `normalizePath(docs)` (a path equal to it, or one that starts with it plus `/`, is inside); give one row per link outside, and do not read an outside `.html` link as a page. In `link_ok()`, check each path part against those links, so a target that passes through or ends at an outside link is broken. Run `devtools::test()`.
- [x] T3: Update the `broken-link` bullet in the roxygen block of `R/check-supplement.R`, from a same-session read of the code; run `devtools::document()`. Add a NEWS.md bullet. Update the `cairn/DESIGN.md` Architecture text, and add the linked-`docs/` case to the "Release check edge cases" Known issues entry.
- [ ] T4: Run `devtools::check()` on the Mac (0 errors, 0 warnings). The AC5 evidence is the AC5 test run (not skipped) in the Windows job of the `R-CMD-check` workflow on the milestone's pull request; at review, read that job's test output.

## Work log

- 2026-10-19: created by /milestone-plan.
- 2026-10-19: tier check: not run — work named at the question set.
- 2026-10-19: question set: a symbolic link in `docs/` whose target is outside `docs/` — counts as a broken link, and a link loop gives one row, not one per loop level (the other answers are in M021's work log).
- 2026-10-19: collision check: takes the hidden-folder, symbolic-link, and loop defects of the "Fix false positives in the link check" row (M021 takes the rest); "Detect broken file links on Windows" is a separate scope; DECISIONS.md headings hold no match; GitHub inbox: 0 open issues, 0 open PRs.
- 2026-10-19: lessons applied: M018 (on Windows `Sys.readlink()` gives `""` for links, `Sys.junction()` needs no admin rights, compare normalized paths after dropping a drive root's `/`), M006 (`list.files()` without `all.files` skips hidden files), M009 (`unlink(expand = FALSE)` in test cleanup), M008 (`Sys.glob()` reads `[` in folder names).
- 2026-10-19: criteria audit (full, the same fresh Opus reader as M021): 5 findings on M022, all taken. AC1 says `<a href>`, since "link" also means a symbolic link here; AC2's `docs/loop` to `docs/` counted as outside under T2's "starts with it plus `/`" test, so a target equal to `docs/` is now inside (AC3, T2); AC3 adds an `.html` file link to an outside page and states that the page is not read; AC4 now covers a page link that ends at an outside file link; AC5's CI run moved from the criterion to T4.
- 2026-10-19: plan decided that a link whose target is inside `docs/` gives no row, because the user's question-set answer named only targets outside `docs/`; whether GitHub Pages serves a linked file inside the site was not checked.
- 2026-10-19: plan decided not to enter linked folders when listing pages, over following them with a visited set, because a linked folder inside `docs/` holds pages already read at their real path and one outside gets its own row; falsified by a site whose published pages exist only behind a linked folder inside `docs/`.
- 2026-10-20: implement started; branch m022-link-pages cut from origin/main at fe04e4d.
- 2026-10-20: T1: five tests added to test-check-supplement.R; run before T2 on the Mac, the AC1 to AC4 tests failed for their shapes (hidden pages unread, the loop repeated pages to many levels, out.html read as a page with no outside rows, no rows through outside links); the AC5 test skips off Windows, so its first run is the Windows CI job.
- 2026-10-20: chose the AC3 row text "It is a link to a place outside docs/, so the published site does not have its target." and kept the existing page-link row text for AC4 rows.
- 2026-10-20: T2: `docs_entries()` walks docs/ with a queue (hidden names included, linked folders listed and not entered), `outside_links()` and `in_docs()` compare normalized paths with `normalizePath(docs)` (case ignored on Windows, as in `is_reparse_point()`); `link_ok()` fails a link when any existing part of its path resolves outside docs/, which also covers a linked folder inside docs/ that leads to an outside link (checked in a scratch run), and skips that check when docs/ holds no link; outside rows come first in the result. `devtools::test()` clean on the Mac.
- 2026-10-20: T3: `broken-link` help bullet extended from a same-session read of `check_links()`, `docs_entries()`, `outside_links()`, and `link_ok()`; `devtools::document()` run; NEWS.md bullet added (sentences split to pass the simple-english hook); DESIGN.md Architecture text names the walk and `in_docs()`, and the "Release check edge cases" entry names the linked-`docs/` case.

## Decisions

## Review
