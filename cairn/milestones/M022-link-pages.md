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

- [x] AC1: Pages in hidden places are read. An `<a href>` to a missing file on `docs/.hidden/page.html`, on `docs/.page.html`, and on `docs/sub/.deep/page.html` gives a `broken-link` row for that page.
- [x] AC2: The page listing does not enter a linked folder. With `docs/loop` a symbolic link to `docs/` and `docs/inner` a symbolic link to `docs/sub`, each page's `broken-link` rows appear once, with `file` the page's own path (`docs/sub/page.html`, never `docs/inner/page.html` or `docs/loop/…`), and neither link gives a row of its own.
- [x] AC3: Each link in `docs/`, to a file or a folder, whose target exists and resolves to a place outside `docs/` gives one `broken-link` row, with `file` the link's path in the site and a `problem` that says the link points outside `docs/`, so the published site lacks its target. A target equal to `docs/` or under it is inside. Tested shapes: a file link to the site's `_supplement.yml`, a file link to a file outside the site folder, a file link `docs/out.html` to a page outside the site folder that holds a link to a missing file, and a folder link to a folder outside the site folder. The `.html` file link gives only its AC3 row: the page it points to is not read for links. A file link and a folder link whose targets are inside `docs/` give no such row.
- [x] AC4: A link on a page whose target path passes through or ends at a link of AC3 gives a `broken-link` row for that page link. Tested shapes: with `docs/private` a folder link to a folder outside the site that holds `x.csv`, `<a href="private/x.csv">` gives a row; with `docs/data.csv` a file link to a file outside the site, `<a href="data.csv">` gives a row. The same links through links whose targets are inside `docs/` give no row, as today.
- [ ] AC5: On Windows, a junction in `docs/` to a folder outside `docs/` gives the AC3 row, and a page link through it gives the AC4 row.
- [x] AC6: The `broken-link` bullet of the `check_supplement()` help page states the rules of AC1 to AC4, and NEWS.md has an entry for the change.

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
- [x] T4: Run `devtools::check()` on the Mac (0 errors, 0 warnings). The AC5 evidence is the AC5 test run (not skipped) in the Windows job of the `R-CMD-check` workflow on the milestone's pull request; at review, read that job's test output.

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
- 2026-10-20: claim audit: 48 claims read, 3 corrected — NEWS.md, R/check-supplement.R, man/check_supplement.Rd ("each page is read once" did not hold for a symbolic link to a page file, which is read as its own page; the NEWS outside-link sentence now says the target must exist).
- 2026-10-20: claim audit re-read (once, same reader): the NEWS bullet and the page-file sentence hold; the linked-folder sentence of the help bullet was narrowed to folders that a link inside `docs/` points to, and the outside-link sentence now also says a page in an outside linked folder is not read, as the reader proposed. No second pass.
- 2026-10-20: T4: `devtools::check()` on the Mac at 60458f6: 0 errors, 0 warnings, 0 notes. The AC5 test has not run yet: it skips on the Mac, and its evidence is the Windows job of `R-CMD-check` on the PR, read at review.
- 2026-10-20: status review; handed to /milestone-review.
- 2026-10-20: review return 1: AC4 fails for a page link to a folder (`sub/`, `sub`, `.`, `./`) whose `index.html` is a link to a place outside docs/: `link_ok()` tests the path's parts for outside links before it adds `index.html`, and skips the test when the path is empty, so no row comes (diff-bug #1, reproduced). Fix-now findings landed in 08aae7c.

## Decisions

## Review

- 2026-10-20 sync: branch contains origin/main (fe04e4d); main has not moved since the cut.
- AC1 evidence: `testthat::test_file()` at 67075ea, test "pages in hidden folders and hidden pages are read" passed (exact sorted rows for `docs/.hidden/page.html`, `docs/.page.html`, `docs/sub/.deep/page.html`); with main's `R/check-supplement.R` in a scratch copy, the same test failed (no rows).
- AC2 evidence: same run, test "the page listing does not enter a linked folder" passed (rows exactly once at `docs/index.html` and `docs/sub/page.html`, no `inner`/`loop` rows); with main's code it failed (rows repeated under `docs/loop/…` and `docs/inner/…`).
- AC3 evidence: same run, test "a link in docs to a place outside docs gives one row" passed (exactly the four outside rows for `meta.yml`, `secret.txt`, `out.html`, `ext`; no row from the page behind `out.html`; no row for the inside links `alias.csv`, `inner`); with main's code it failed.
- AC4 evidence: same run, test "a page link through a link to a place outside docs gives a row" passed (rows for `private/x.csv` and `data.csv` plus their two outside rows; none for `inner/y.csv` or `alias.csv`); with main's code it failed. The suite had 28 tests, 0 failed, 0 errors.
- AC5 evidence: pending. The test skipped on the Mac ("On Mac"). Its evidence is the Windows job of `R-CMD-check` on the PR, read after step 8 opens it and before the merge.
- AC6 evidence: `man/check_supplement.Rd` lines 41-53 at 67075ea state hidden files and folders are read (AC1), linked folders are not entered and pages are read at their own path (AC2), a link whose existing target is outside `docs/` gives its own row and its page is not read, while one inside gives none (AC3), and a page link through or ending at such a link counts (AC4); NEWS.md's last bullet describes the change.
- gate (pass 1): `cairn_validate.py` all checks passed; no principle changed (no `cairn_impact`); `devtools::document()` no diff; no README.Rmd and no pkgdown site; NEWS.md has the entry; no new top-level file; `devtools::check()` at 61b5ca5: 0 errors, 0 warnings, 0 notes.
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: a page link to a folder (`sub/`, `sub`, `.`, `./`) whose `index.html` is a link outside docs/ gives no row, because the outside-path test runs before `index.html` is added (reproduced) — floor return (AC4 fails: the target path ends at an outside link)
- diff-bug #2: the walk calls `is_link()` per entry, and on Windows `is_reparse_point()` lists the parent folder per path, so time grows with the square of a folder's size — fix now, fixed 08aae7c (`is_reparse_point()` takes a vector and lists and normalizes each parent once; same answers as main's on a mixed fixture; 3,000 files 0.047 s)
- diff-bug #3: `in_docs()` normalizes docs/ on every call — fix now, fixed 08aae7c (`docs_root()` once in `check_links()`, passed to `link_ok()` as `root`)
- diff-bug #4: a path that `normalizePath()` cannot resolve keeps its input, which need not start with the normalized root, so it reads as outside — fix now, fixed 08aae7c (paths are built from the normalized root, so an unresolved path stays under it); the matching Windows `is_reparse_point()` case is pre-existing (M018) — that part reject (pre-existing, not this diff)
- diff-bug #5: the row text assumes GitHub Pages lacks an outside target, which was not checked — reject (planned change: the question-set answer counts such a link as broken; the work log records the premise as unchecked)
- diff-bug #6: row order changed (outside rows first, folder files before subfolders) — fix now, fixed 08aae7c for pages (sorted by path in byte order); outside rows first kept (planned layout)
- diff-bug #7: `tolower()` in `in_docs()` stops on a name that is not valid UTF-8 on Windows — fix now, fixed 08aae7c (`utf8_lower()`)
- diff-bug #8: test gaps (folder link to an outside `index.html`, relative link targets, an outside link in a hidden folder, `has_links` equivalence, Windows file links) — fix now, fixed 08aae7c for relative targets and the hidden folder (new test); the folder-index gap goes with the floor return; `has_links` reject (the argument is now `root`, and the AC1 test runs the no-link path); Windows file links reject (the AC1 to AC4 tests run in the Windows CI job, read with AC5)
- diff-bug #9: NEWS line past the wrap width, a help sentence that reads as covering outside folders — fix now, fixed 08aae7c (NEWS rewrapped, sentence names folders in docs/); roxygen line breaks reject (style; Rd reflows)
- blame-history #1: same as diff-bug #7 — fix now, fixed 08aae7c (`utf8_lower()`)
- blame-history #2: same as diff-bug #2 and #3 — fix now, fixed 08aae7c
- blame-history #3: pages behind an outside folder link are no longer read — reject (planned change, AC3)
- blame-history #4: `useBytes = TRUE` makes a non-UTF-8 `.html` name match — reject (intended, stated in the comment)
- blame-history #5: no D-entry for the outside-link rule — reject (planned change: a milestone-local decision, recorded in this file's work log)
- prior-review #1: same as diff-bug #7 — fix now, fixed 08aae7c
- prior-review #2: on Windows a dangling file link passes `file.exists()`, so it would get the outside row — reject (false: per the M018 observation in "Detect broken file links on Windows", `normalizePath()` gives the link's own path, which is inside docs/, so no outside row, and the page still gives "cannot be read")
- prior-review #3: test gaps for past defect classes (non-ASCII, `[`, non-UTF-8, dangling) — reject (the older tests cover non-ASCII and the dangling page at test-check-supplement.R:311; macOS cannot make a non-UTF-8 name)
- prior-review #4: same as diff-bug #2 — fix now, fixed 08aae7c
- prior-review #5: NEWS "a junction does the same" is unclear — fix now, fixed 08aae7c (names the junction to a folder outside docs/)
- ripple #1: the "Fix false positives in the link check" row still lists the fixed defects — reject (planned: the row graduates at post-merge hygiene)
- ripple #2: README "It checks only relative links, which point inside the site" — reject (false: still true of page links; the new rows concern symbolic links in docs/)
- ripple #3: README.md and inst/template/_README.md list the broken-link cases without the outside link — fix now, fixed 08aae7c (bullet added to both)
- ripple #4: `page_links()` comment says links "point to a place inside the site" — reject (false: the diff did not change what `page_links()` returns)
- ripple #5: the "Check web links on the rendered site" row says the check tests only links inside docs/ — reject (false: still true)
- ripple #6: `docs_entries()` depends on `is_link()`, which misses a Windows file link to a missing file — reject (pre-existing, owned by "Detect broken file links on Windows")
