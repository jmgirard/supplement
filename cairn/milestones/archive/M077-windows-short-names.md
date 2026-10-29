# M077: Render from short folder names on Windows

**Status:** done (2026-10-29, PR #78 https://github.com/jmgirard/supplement/pull/78)

**Goal:** On Windows, `render_supplement()` publishes the figures that knitr writes when the path of the site folder holds an 8.3 short name, such as `RUNNER~1`.

**Outcome:** `render_supplement()` in `R/render-supplement.R`, after `setwd(path)`, sets the working folder to `normalizePath(".", mustWork = FALSE)` on Windows when `getwd()` holds `~`, so Quarto runs from the long path; macOS, Linux, and paths with no `~` are unchanged, and `on.exit()` still restores the folder. Before the fix, windows-latest showed Quarto warn that `...\RUNNER~1\...\example_files\figure-html\bootstrap-1.png` was not found, the figure missing from `docs/`, and a `broken-link` row. Tests in `test-render-supplement.R`: a real render through `utils::shortPathName()` (red on main, green with the fix) and a mocked test of the working folder for `path = short`, `"."` from a short folder, and a failed command; the `short_path()` helper stops rather than skips under `CI=true`. The help page, NEWS.md, DESIGN.md, and the template's GUIDE.md ("How the site renders", a note for terminal renders) describe it. The test helper `long_dir()` stays for `run_in()`.

**Decisions:** none. Idea vet: the long path is used only for a `~` path on Windows, since `normalizePath()` can also resolve links.

**Review:** fan-out of four lenses (diff-bug, blame-history, prior-review, ripple): 22 findings, 10 fixed (example name `JANEDO~1`, `mustWork = FALSE`, a no-`~` assertion, GUIDE, DESIGN, and NEWS wording, a NEWS rewrap), 11 rejected (2 edge: a short name on a UNC share, another CI with no 8.3 names), 1 to the new row "Note short Windows paths in the vignette". Claim audit 28 claims, 3 corrected; criteria audit 5 findings, all taken. 0 amendments. CI green on all checks. Graduated "Handle short folder names on Windows". Lessons: one captured (M077), three marked used, the 2026-10-19 (M016) lesson evicted by rank.
