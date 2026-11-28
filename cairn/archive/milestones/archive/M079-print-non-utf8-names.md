# M079: Print names that are not UTF-8 in messages

**Status:** done (2026-10-29, PR #80 https://github.com/jmgirard/supplement/pull/80)

**Goal:** On Linux, a name that is not valid UTF-8 no longer stops the `"leftover-output"` row of `check_supplement()` or the no-report message of `render_supplement()`.

**Outcome:** `check_leftover_output()` in `R/check-supplement.R` passes each row's `file` through `show_text()`, so a folder of `_freeze/analyses/` whose name is not valid UTF-8 shows as `_freeze/analyses/caf<e9>`. Before, `report_problems()` stopped in `cli::cli_bullets()` with "input string 1 is invalid UTF-8", as a Linux CI run of the new test on the old code showed. `render_supplement()` is unchanged: its new Linux test passed on the old code in `C.UTF-8` and `C`, because `check_reports()` admits only ASCII names, `list.files(pattern =)` leaves such a name out in a UTF-8 locale, and `tolower()` works byte by byte in the C locale. The row's premise did not hold, and the test stays. Both tests run on Linux only and assert the locale they set. The help page and NEWS.md describe the leftover row.

**Decisions:** none promoted. At the question set the user chose `<xx>` in the `file` column, as other rows show, over keeping the raw bytes.

**Review:** Criteria audit at plan (full): 7 findings, 6 taken, 1 answered. Claim audit 8 claims, 1 corrected. One four-lens pass, 15 findings: 2 fixed (9a778fd: locale assertion in the tests, NEWS wording), 4 to the new rows "Show Latin-1 names in rows as text" and "Sort leftover rows in byte order", 9 rejected (none edge). One windows-latest timing failure of an M076 test (10.19 s against 10 s) passed on a rerun; the row "Time the large-page tests on Windows" now records it. Local and CI R CMD check clean on three systems. Graduated "Print leftover folders with odd bytes" and "Render by name beside non-UTF-8 reports". Lessons: one captured (M079), four marked used, the 2026-10-27 (M064) lesson evicted by rank.
