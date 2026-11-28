# M013: DESCRIPTION asks for testthat 3.3.0, and the tests pass under it

**Status:** done (2026-10-19, PR #14 https://github.com/jmgirard/supplement/pull/14)

**Goal:** DESCRIPTION's testthat floor is 3.3.0, the first CRAN release after 3.2.3; testthat 3.2.0 through 3.2.3 do not compile under R 4.6.1 (D-014). The tests are shown to pass under testthat 3.3.0.

**Outcome:** DESCRIPTION Suggests changed from `testthat (>= 3.0.0)` to `testthat (>= 3.3.0)`. The tests call `expect_no_error()` and `expect_no_warning()` (testthat 3.1.5) and `local_mocked_bindings()` (3.1.7), so 3.0.0 was false. The plan chose 3.2.0 (D-013), but the source of 3.2.0 to 3.2.3 does not compile under R 4.6.1 (`reassign.c` calls `SET_FORMALS`, `BODY`, `CLOENV`, and three more), so at that stop the user chose 3.3.0 (D-014). testthat 3.3.0, built from the CRAN archive into a scratch library, ran `test_local()` with no failures and the same one skip as 3.3.2. A parse sweep found 30 testthat functions the tests call, all exported by 3.3.0. testthat 3.3.0 needs R 4.1, so the tests do too. No NEWS.md entry.

**Decisions:** D-013 (3.2.0 floor, superseded) and D-014 (3.3.0 floor). Rewriting `expect_no_error()` as `expect_error(x, NA)` was rejected, because `local_mocked_bindings()` needs 3.1.7 anyway.

**Review:** full criteria audit at plan (6 findings, taken) and re-audits after both floor answers; one substantive amendment (3.2.0 to 3.3.0, the Goal re-cut in place at the user's choice); claim audit 2 claims, 0 corrected. One review pass with four lenses (diff-bug, blame-history, prior-review, ripple), 12 findings: 4 fixed on the branch (D-014 wording, the R 4.1 need, a function miscount), 8 rejected, 0 follow-up. `R CMD check` 0/0/0. Graduated "testthat floor"; new row "Suggests floor guard" (added at plan).
