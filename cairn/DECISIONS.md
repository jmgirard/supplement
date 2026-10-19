# Decisions

Append-only. Never renumber; supersede with a new entry. D-entries record
choices with rationale — never deferrals ("not now" is a ROADMAP fact).

### D-001 (2026-10-18): New sites render into docs/ on the default branch

**Context:** A site can publish from a committed `docs/` folder or from a `gh-pages` branch built by GitHub Actions.
**Decision:** The template renders into `docs/`, which the author commits and GitHub Pages serves. The user chose this at the M003 plan gate.
**Consequences:** Each Zenodo release archives readable rendered pages. Authors publish from one machine, because the theme file name differs by machine (pilot-port P10).

### D-002 (2026-10-18): Freeze is on for the whole project

**Context:** `freeze: auto` re-runs a report when its source changes, and that re-run fails where the data is absent. The M002 pilot showed that `freeze: true` rebuilds the site with no data and no code runs.
**Decision:** The template sets `execute: freeze: true` at the project level.
**Consequences:** An author re-runs a report by rendering it by name. The template README says so.

### D-003 (2026-10-18): The template lives in inst/template of the package repository

**Context:** Quarto 1.10.19 installs a template or extension from `org/repo/subdir@tag`, so the template need not sit at the repository root.
**Decision:** One repository. The template, with its `_extensions/`, lives in `inst/template/`, where the R package also reads it. There is no build-time copy.
**Consequences:** The install command is `quarto use template jmgirard/supplement/inst/template`. This replaces the scope draft's root-`_extensions/` recommendation.

### D-004 (2026-10-18): Template setup files are renamed on the first render

**Context:** `quarto use template` skips dotfiles, `README.md`, and `LICENSE`, and R CMD check gives a NOTE for hidden files under `inst/`.
**Decision:** The template ships `_gitignore` and `_README.md`. A pre-render script in TypeScript, run by Quarto with no R, renames them when the targets do not exist. A post-render script writes `.nojekyll` into the output folder. The user chose this at the M003 plan gate over two copies of each file and over an R-only setup.
**Consequences:** The "Pure R" convention covers package code only. The template may carry Quarto TypeScript scripts. Users render once before the first commit.

### D-005 (2026-10-18): testthat and withr are suggested dependencies

**Context:** The template needs tests that render it in a temporary folder.
**Decision:** DESCRIPTION lists `testthat (>= 3.0.0)` and `withr` under Suggests, with no Imports. The user granted this at the M003 plan gate.
**Consequences:** Tests skip on CRAN and when quarto is not on PATH.

### D-006 (2026-10-18): Setup merges into existing files and never discards the template's rules (narrows D-004)

**Context:** In a git repository, Quarto writes its own `.gitignore` before pre-render scripts run, and GitHub's R `.gitignore` template ignores `docs/`. D-004's rename alone then left fit files unignored or the site uncommitted.
**Decision:** When `.gitignore` exists, `setup.ts` appends the template's missing lines, and the template's `.gitignore` ends with `!docs/` and `!_freeze/`. When `README.md` exists, the guide goes to `SUPPLEMENT.md`.
**Consequences:** Setup edits an author's existing `.gitignore` by appending only. Existing lines are never removed or reordered.

### D-007 (2026-10-18): knitr and rmarkdown are suggested dependencies (extends D-005)

**Context:** The template tests render the example report, which needs knitr and rmarkdown, and skip without them. Packages that tests use belong in DESCRIPTION.
**Decision:** DESCRIPTION lists knitr and rmarkdown under Suggests. The user granted this at the M003 merge gate.
**Consequences:** No package is added to Imports. Users of the template still need knitr and rmarkdown to render R reports.

### D-008 (2026-10-18): A missing data file stops the render

**Context:** The pilot showed that a build without `data/` drops the download files from `docs/` (pilot-port P8), and P8's disposition left the guard to a later release check. The template's data table now lists each data file from `_supplement.yml`.
**Decision:** The `supplement-data-table` shortcode stops the render when a listed file is missing or is a folder, and names it. The user chose this at the M004 plan gate over a table row marked as missing.
**Consequences:** A clone without its listed data files no longer renders, so a data-free rebuild is no longer a test of the full site. A site whose data files are fetched after the render would need another approach. The release check can still look for the same problem.

### D-009 (2026-10-18): yaml, jsonlite, and cli are imported dependencies (extends D-005, D-007)

**Context:** The first exported functions read `_supplement.yml`, write `.zenodo.json`, and need user-facing errors, which the r-package profile asks to come from cli.
**Decision:** DESCRIPTION lists yaml, jsonlite, and cli under Imports. The user granted this at the M005 plan gate.
**Consequences:** Installing the package now installs these three. The template itself still needs no R package beyond those D-007 names for rendering R reports.

### D-010 (2026-10-18): Package functions edit site YAML files by inserting lines of text

**Context:** `add_report()` and `add_data()` add an item to `_quarto.yml` and `_supplement.yml`. A rewrite with the yaml package drops every comment in the template's files and can change how values are quoted.
**Decision:** A function that changes a site's YAML file inserts lines of text and leaves the other lines as they are. Before it writes, it reads the result with the yaml package and stops if the result is not the old file with the change. The user chose text insertion at the M007 plan gate.
**Consequences:** Such a function handles block-style YAML and refuses other forms, such as a flow-style list, with the lines to add by hand. Later writers of these files follow the same rule.

### D-011 (2026-10-18): A one-line value change follows the same text-edit rule (extends D-010)

**Context:** `release_supplement()` changes the value of `supplement.version` in `_supplement.yml`. D-010 covers only inserted lines.
**Decision:** A function that changes one value in a site's YAML file replaces only the value's text on its key's line, writes the new value in double quotes, and keeps the spaces and comment after it. Before it writes, it reads the result with the yaml package and stops unless the result is the old map with only that value changed.
**Consequences:** Such a function handles a one-line scalar in a block-style map and refuses other forms, such as a block scalar, a flow map, or a value on the next line, with the line to add by hand.

### D-012 (2026-10-18): License ids get a shape check, not a list check

**Context:** `write_citation()` and `write_zenodo()` write license ids from `_supplement.yml` as given. A check could test the SPDX id shape, or also test each id against a copy of Zenodo's license list shipped with the package.
**Decision:** The writers check only the shape of each id. The user chose this at the M010 plan gate, because a shipped copy of the list can fall out of date as Zenodo adds ids.
**Consequences:** A well-formed id that Zenodo or the CFF 1.2.0 license list does not know still writes, so the output can fail their own checks. Ids with spaces, such as `CC BY 4.0`, stop the writers.

### D-013 (2026-10-18): The testthat floor in Suggests is 3.2.0 (supersedes D-005's floor)

**Context:** D-005 set `testthat (>= 3.0.0)`. The tests call `expect_no_error()` and `expect_no_warning()`, new in testthat 3.1.5, and `local_mocked_bindings()`, new in 3.1.7. The floor could be the lowest release that the tests pass under, or 3.2.0, the release whose NEWS calls these functions stable.
**Decision:** DESCRIPTION lists `testthat (>= 3.2.0)` under Suggests. The user chose 3.2.0 at the M013 plan gate. The floor is not a claim that 3.2.0 is the oldest release that works. The rest of D-005 stands.
**Consequences:** Someone who runs the tests with testthat 3.1.7 to 3.1.10 is asked for a newer release. A later test that calls a function newer than 3.2.0 needs the floor raised by hand.
