# M051: Keep the package README to the main steps

**Status:** done (2026-10-24, PR #52 https://github.com/jmgirard/supplement/pull/52)

**Goal:** The package `README.md` shows the main steps of each task, and the edge cases it held are on the help pages it names.

**Outcome:** README.md no longer holds the template's setup file names, the `.gitignore` merge, the text insertion of `add_report()` and `add_data()`, the link-check limits and git skip of `check_supplement()`, or the release value-error, changed-file, rollback, version-line, and `-- .` staging and subfolder details. Each part names `?create_supplement`, `?add_report`/`?add_data`, `?check_supplement`, or `?release_supplement`. The release part still says a problem or a failed git run stops the release and a differing `CITATION.cff` DOI does not. The `create_supplement()` roxygen gained the reason for the `_gitignore` and `_README.md` names (`quarto use template` does not copy `.gitignore` or `README.md`), that the first render adds only the rules an existing `.gitignore` lacks and ends it with `!docs/` and `!_freeze/`, and that those lines cannot undo a rule such as `docs/*`. No NEWS entry: no behavior changed.

**Decisions:** none.

**Review:** Claim audit 18 claims, 2 corrected. Four-lens review: 18 findings, 7 fixed (aae999f: the undefined "git checks" term, "recovery" wording, `_README.md` removal when `README.md` exists, the `docs/*` caveat, the edited files named, the DOI reason), 11 rejected (8 planned, 2 false, 1 style), 0 follow-up. CI green on six jobs; `devtools::check()` 0/0/0. Graduated the candidate "Split the template guide by reader". No LESSONS line.
