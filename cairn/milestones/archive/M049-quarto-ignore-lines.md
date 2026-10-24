# M049: Keep a new site's .gitignore through later renders

**Status:** done (2026-10-24, PR #50 https://github.com/jmgirard/supplement/pull/50)

**Goal:** A new site's `.gitignore` stays as setup wrote it through later renders, because the template's `_gitignore` holds the lines that Quarto 1.10.19 requires.

**Outcome:** `inst/template/_gitignore` adds `/.quarto/` and `/_*.local` in a commented block after `.claude/`, keeping every earlier line in order (`.quarto/` stays for nested folders). Quarto 1.10.19's `ensureGitignore`, run from `renderProject` before pre-render scripts on full renders and renders by name, rewrites a `.gitignore` lacking the trimmed lines `/.quarto/` or `**/*.quarto_ipynb`, or `/_*.local` while a root file matches `^_.*?\.local$`, or `/env/` while `env/` holds `pyvenv.cfg` or `conda-meta`. `/env/` is left out, since a site may keep other files in `env/`. Test in `test-template.R`: "a second render leaves the .gitignore that setup renamed" checks the bytes after each of two renders of `script_site()`, with and without `_environment.local`; both cases failed on main, and removing `/_*.local` failed only the local-file case. NEWS entry. DESIGN.md Known issues gained "Quarto's .gitignore rewrites left" (an author's own `.gitignore` rewritten before setup, and the `env/` case).

**Decisions:** none. The plan chose adding `/.quarto/` beside `.quarto/` over replacing it, and leaving `/env/` out over adding it.

**Review:** Plan audit 10 findings (9 narrowed, 1 answered); claim audit 12 claims, 2 corrected (NEWS on when Quarto adds its lines, the `_gitignore` comment's conditions). Four-lens review: 13 findings, 2 fixed (one DESIGN.md wording issue, da031fb), 11 rejected (3 false, 4 planned, 2 style, 2 edge: a `TMPDIR` inside a git repository). CI green on all six jobs; `devtools::check()` 0/0/0. Graduated "Add Quarto's ignore lines to _gitignore". No LESSONS line: the Quarto behavior lives in the Known issues entry.
