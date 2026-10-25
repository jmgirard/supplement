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

### D-014 (2026-10-18): The testthat floor in Suggests is 3.3.0 (supersedes D-013)

**Context:** M013 planned a 3.2.0 floor (D-013) and a test run under that release. The source of testthat 3.2.0 to 3.2.3 does not compile under R 4.6.1, the only R installed on the machine that ran the tests, and 3.3.0, the next CRAN release, does. Running 3.2.0 in a Docker image with an older R was possible but not done. The 3.2 releases were not tried on an older R.
**Decision:** DESCRIPTION lists `testthat (>= 3.3.0)` under Suggests. The user chose this at the M013 implement stop, so that the floor is a release the tests are shown to pass under. The floor comes from what could be built and run, not from a function the tests need. It is not a claim that 3.3.0 is the oldest release that works.
**Consequences:** Someone with testthat 3.2.x on an older R is asked to update before running the tests. testthat 3.3.0 declares `Depends: R (>= 4.1.0)`, so running the tests needs R 4.1 or later, while the package itself declares no R version. A later test that calls a function newer than 3.3.0 needs the floor raised by hand.

### D-015 (2026-10-19): A site YAML file that does not parse gives supplement_error_parse

**Context:** A `_supplement.yml` or `_quarto.yml` that the yaml package cannot read gave the parser's unclassed error from four functions, and `supplement_error_yaml` from `add_data()` and `add_report()`. That class already means that the text a function changed does not read back as planned (D-010, D-011).
**Decision:** Every function that reads a site YAML file reads it through `yaml_read_file_text()`, which turns the yaml package's error into `supplement_error_parse` with the file name and the parser's message. `supplement_error_yaml` keeps its one meaning. The M016 plan chose a new class over the old one.
**Consequences:** Code that caught `supplement_error_yaml` from `add_data()` or `add_report()` for a file that does not parse now gets `supplement_error_parse`. A later function that reads a site YAML file uses the same helper.

### D-016 (2026-10-19): R CMD check runs in GitHub Actions on Windows, macOS, and Ubuntu

**Context:** The repo had no CI, and the machine that runs the tests is a Mac, so no test had run on Windows or Linux. The repo profile names the usethis check-standard workflow.
**Decision:** `.github/workflows/R-CMD-check.yaml` runs `R CMD check` on each push and pull request on windows-latest, macos-latest, and ubuntu-latest with the R release, Quarto 1.10, and `NOT_CRAN=true`, so the render tests run. A warning fails the check. A last step lists each skipped test and fails when a test skipped because Quarto, git, knitr, or rmarkdown is missing. The user chose three systems over Windows alone and over a run by hand at the M018 plan. The Codecov coverage job is not added (candidate row "coverage report").
**Consequences:** Merges wait on this workflow, and red CI blocks a merge. The tests run twice in each job. The workflow uses the r-lib and Quarto setup actions; they are not package dependencies.

### D-017 (2026-10-20): The link check reads pages with a tag reader in base R, not an HTML parser package

**Context:** `check_supplement()` found links with one pattern over quoted `href` and `src` values (M008), so it read link-shaped text in comments, scripts, and page text, and did not decode `&amp;`. The xml2 package parses HTML fully, but it is compiled, needs libxml2 on Linux, and would add xml2 and rlang to Imports. A reader in base R decodes only a stated set of character references and differs from a browser in some stated cases.
**Decision:** The link check reads start tags with `tag_links()`, PCRE patterns in base R, and decodes references with `decode_refs()`. No HTML parser package is added (D-009 stands). The user chose this at the M021 plan, after seeing the weight of each.
**Consequences:** The help page lists the cases where the check reads a page differently from a browser, such as named references other than five and some comment and script edge cases. A site whose links break in one of those ways is not caught, or gives a false row. Adding a parser later is a dependency change, which this entry's rationale would need to be weighed against.

### D-018 (2026-10-20): The template ships the example figure in figures/

**Context:** M017 shipped no `figures/` folder, so the example report made it. Quarto 1.10 lists `project.resources` files at the start of a render, so the first render of a new site wrote `figures/bootstrap-means.png` and left it out of `docs/`, though the setup message says to render once before the first commit.
**Decision:** The template ships `figures/bootstrap-means.png`. The first render then copies the bytes that the example writes in that render. The user chose this at the M028 plan over a setup message that says to render twice, and over a message change alone.
**Consequences:** `create_supplement()` refuses a folder that already holds `figures/bootstrap-means.png`, as for every template file. Each render that runs the example's code rewrites the tracked figure, so a render on another machine can change its bytes. A figure saved under a new name still reaches `docs/` only on the next render; M029 plans a `check_supplement()` row for it.

### D-019 (2026-10-21): sessioninfo is a suggested dependency (extends D-007)

**Context:** The template's Computing environment section prints `sessioninfo::session_info()` when sessioninfo is installed and `utils::sessionInfo()` otherwise. Two tests use sessioninfo and skip without it. D-007 says that packages the tests use belong in DESCRIPTION. CI runs `R CMD check --as-cran`, which hides packages outside Suggests, so without this entry the tests inside R CMD check run only the `sessionInfo()` form, and the later CI step that lists skips does not fail on a failed test.
**Decision:** DESCRIPTION lists sessioninfo under Suggests, and the CI skip list counts a skip for missing sessioninfo as a missing tool. The user granted this at an M030 implement stop.
**Consequences:** Installing supplement installs nothing new. CI renders and tests both forms of the section. The template's report code still runs without sessioninfo.

### D-020 (2026-10-21): CI runs the tests once, in parallel, and skips string-rule loops on Windows (amends D-016)

**Context:** D-016's last step ran the whole suite a second time to list skips, and the Windows job took about 30 minutes. R CMD check keeps the test output, skip reasons included, in `tests/testthat.Rout`.
**Decision:** The skip-list step reads that file with `.github/scripts/check-skips.R` and runs no test; the missing-tool list lives in that script. The two tests that read the package's R files sit in `test-source.R`, and a workflow step runs that file from the checkout. Test files run in parallel (`Config/testthat/parallel: true`), so a test must not rely on state another test file sets. Six loop tests of license and DOI string rules skip on Windows, and each shortcode keeps a Windows render. The user chose parallel tests and the Windows skips at the M033 plan.
**Consequences:** D-016's "The tests run twice in each job" no longer holds. The skip list depends on the format of testthat's check reporter, and the step fails when it cannot read that format. A Windows-only change to the string rules would not show in CI.

### D-021 (2026-10-22): renv is a suggested dependency (extends D-019)

**Context:** The template guide shows how to record and restore a site's R packages with renv. A test sets up renv in a temporary site, and D-007 says that packages the tests use belong in DESCRIPTION. The package's own functions never call renv.
**Decision:** DESCRIPTION lists renv under Suggests, and the CI skip list counts a skip for missing renv as a missing tool. The user granted this at the M031 plan, which chose a guide and tests over a `renv` argument to `create_supplement()`.
**Consequences:** Installing supplement installs nothing new. Authors install renv themselves to follow the guide. The test runs renv in a separate Rscript process, with renv's cache and sandbox in temporary folders, so a test never activates renv in its own session.

### D-022 (2026-10-23): fs is an imported dependency (extends D-009)

**Context:** On Windows, R's own file functions read a file symbolic link whose target is missing as an existing file, and `Sys.readlink()` gives `""` for every link, so `is_link()` misses such a link and the link refusals do not stop it. Base R can only infer the link, from a listed name that `file.info()` cannot read.
**Decision:** DESCRIPTION lists fs under Imports, and on Windows `is_link()` also counts each path that `fs::is_link()` reports as a link. The user chose fs over the base R inference at the M045 plan, on the condition that fs is light; the measurements are in the M045 milestone file.
**Consequences:** Installing supplement installs fs, which needs R 4.1 or later and compiled code; rmarkdown already brings it in through bslib and sass. D-017's choice of base R for the HTML link reader stands, since fs reads no HTML.

### D-023 (2026-10-23): The template's project scripts are Lua (supersedes D-004's TypeScript wording and D-006's script name)

**Context:** Quarto 1.10.19 runs a `.ts` project script with its bundled Deno, and on macOS that Deno process sometimes crashes with a segmentation fault (exit 139) soon after it starts, which fails the render. Quarto runs a `.lua` project script through Pandoc, with no Deno process.
**Decision:** The pre-render setup script and the post-render `.nojekyll` script are Lua files, `_scripts/setup.lua` and `_scripts/nojekyll.lua`, with the behavior D-004 and D-006 give them; D-006's rules for `setup.ts` apply to `setup.lua`. The user chose this at the M048 plan over a milestone that would only trace the crash and keep the TypeScript scripts.
**Consequences:** D-004's "A pre-render script in TypeScript" and "The template may carry Quarto TypeScript scripts" no longer hold; the template may carry Quarto Lua scripts. Sites made before the change keep their TypeScript scripts until their authors copy the new files. The scripts are checked on Quarto 1.10 only.

### D-024 (2026-10-24): A new site gets a reader README and the author guide in GUIDE.md (supersedes D-006's README clause)

**Context:** The first render made the template's author guide the site repository's `README.md`, so visitors on GitHub read author instructions under a placeholder citation.
**Decision:** The template ships `_README.md` as a short page for the site's readers and the author guide as `GUIDE.md`, which `quarto use template` and `create_supplement()` copy under that name. Setup renames `_README.md` to `README.md` when no `README.md` exists and otherwise removes it, so an existing README is kept and no `SUPPLEMENT.md` is written. The user chose the guide in its own file at the M050 plan over the guide in the package docs only and over keeping one guide file.
**Consequences:** D-006's "When `README.md` exists, the guide goes to `SUPPLEMENT.md`" no longer holds; its `.gitignore` rules stand. Sites made earlier keep their `README.md` or `SUPPLEMENT.md` guide, and `check_supplement()` keeps reading `SUPPLEMENT.md` for the placeholder site address.

### D-025 (2026-10-24): The package's own pkgdown site deploys to gh-pages from CI (D-001 stays scoped to template sites)

**Context:** The package had no site of its own. D-001 has template sites render into a committed `docs/` on the default branch, so that the Zenodo archive of a release holds readable pages, and rejected a `gh-pages` branch for them.
**Decision:** `.github/workflows/pkgdown.yaml` builds the package site and pushes `docs/` to a `gh-pages` branch on pushes to main, published releases, and manual runs; the repo ignores `/docs/`. The workflow deletes `CLAUDE.md` from its checkout before the build, because pkgdown makes a page from top-level `.md` files and has no setting to skip one, and the file holds notes for coding agents. It sets up Quarto so the `check_tools()` example on the site finds it. The user chose the workflow deploy over a configuration-only site at the M054 plan. D-001's reason does not apply: the package is not archived on Zenodo, and a committed `docs/` would add a built site to each package commit.
**Consequences:** GitHub Pages must name the `gh-pages` branch in the repo settings, which the user sets. A local `pkgdown::build_site()` still renders `CLAUDE.md`, so only the workflow's build is published.
