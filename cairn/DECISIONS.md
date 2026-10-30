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

### D-026 (2026-10-25): The package site deploys only from main, with clean deploys (supersedes D-025's list of deploy events)

**Context:** D-025 has the workflow push the site on pushes to main, published releases, and manual runs, with `clean: false`. A manual run on an unmerged branch, or a release made from an older tag, then pushed that ref's site, and pages the build no longer made stayed on `gh-pages` (M054 review).
**Decision:** The deploy step runs only when `github.ref` is `refs/heads/main`, that is, for a push to main or a manual run on main. The `release` trigger is removed, because a release is cut from main, whose push already deploys. The deploy uses `clean: true`, so files on `gh-pages` that the build did not make are deleted. The rest of D-025 stands. The user chose deploys from main only at the M055 plan.
**Consequences:** A manual run on another branch builds the site and skips the deploy. A release from a ref other than main does not change the site.

### D-027 (2026-10-25): The site's deploy job pins every action by commit hash, and other jobs use version tags

**Context:** The `deploy` job of `.github/workflows/pkgdown.yaml` is the one job with `contents: write` (M056). It ran `actions/checkout` and `actions/download-artifact` by major-version tag, which the action's owner can move to other code, while the third-party deploy action was pinned by hash (M056 review).
**Decision:** Every action in the deploy job is pinned to a full commit hash read from the action's own repository, with the matching release tag in a comment. The build job and `.github/workflows/R-CMD-check.yaml` keep major-version tags, and no Dependabot file updates the pins. The user chose the deploy job only, with hand-updated pins, at the M057 plan.
**Consequences:** A moved tag cannot change what runs with the write token. Pins are updated by hand. An action in the build job still runs by tag and could change the site artifact that the deploy job publishes, so the pins protect the write token, not the site's content.

### D-028 (2026-10-25): Reports share setup code through a site file, not package functions

**Context:** Each report that `add_report()` writes carries the Computing environment code, and the example report also defines `save_png()`. The ease-of-use review asked for shorter reports. M046 chose base R link checks in the example because a site renders without supplement.
**Decision:** The template ships `_scripts/report.R`, which defines the shared report functions, and each report sources it from its `site` chunk. Reports call no supplement function, so a render needs no supplement install. `add_report()` copies the file into a site that lacks it and never overwrites it. The user chose the site file over package functions and over shorter inline code at the M058 plan.
**Consequences:** A reader who reruns a report needs only the site repository and the report's packages. A fix to the file reaches a site only when its author copies the new file. The stored output of a report does not track the file, so a change to it needs a render of each report by name.

### D-029 (2026-10-26): Each report prints the hash of _scripts/report.R, and the release check compares it (narrows D-028's consequences)

**Context:** D-028 states that the stored output of a report does not track `_scripts/report.R`, so `check_supplement()` cannot tell when a report was rendered with older shared code. Quarto's stored hash covers the report file alone.
**Decision:** `print_environment()` in the template's `_scripts/report.R` prints the file's MD5, with each CR LF read as LF, as the last line of the Computing environment section. `check_supplement()` compares that line in each report's stored output with the site's file now. The user chose this at the M061 plan over a comparison of git commit times.
**Consequences:** Readers see which version of the shared file made each report. A report whose stored output holds no such line, such as one without the Computing environment section or one rendered before its site copied the new file, gets no row. D-028's other consequences stand.

### D-030 (2026-10-26): Checks that request web addresses are opt-in and do not stop the release

**Context:** Every row that `check_supplement()` gives stops `release_supplement()`. A check of web links on the rendered site needs a network, and a site that is down or a server that refuses scripts gives a row that the author cannot fix.
**Decision:** The web link check runs only when the author calls `check_supplement(web_links = TRUE)`. Its default is `FALSE`, and `release_supplement()` does not turn it on, so its rows never stop a release. The user chose this at the M063 plan over an opt-in check that can stop the release and over a check that always runs.
**Consequences:** A release can go ahead with dead web links on the site, and authors who want the check run it themselves. `check_supplement()` with its defaults makes no web request, which keeps its tests and examples off the network.

### D-031 (2026-10-27): The package needs R 4.1.0 or later

**Context:** The web link check of `check_supplement()` (D-030) requests each address with base R's `curlGetHeaders()`, whose `timeout` argument came in R 4.1.0. DESCRIPTION set no R floor, so on older R the call either fails or needs a branch that no test can run, since testthat 3.3, the Suggests floor, itself needs R 4.1.0.
**Decision:** DESCRIPTION has `Depends: R (>= 4.1.0)`, and `url_status()` always passes the timeout. The user chose this at the M063 review over a criterion limited to the R in use and a version branch in the code.
**Consequences:** The package no longer installs on R before 4.1.0. Sites still build Docker images for R 4.0.x with `write_dockerfile()`, since the reports call no supplement function (D-028).

### D-032 (2026-10-27): The renv.lock comparison is opt-in and does not stop the release (extends D-030)

**Context:** Every row that `check_supplement()` gives stops `release_supplement()`, except the opt-in web link check (D-030). Freeze is on for the whole project (D-002), so an older report keeps the R and package versions of its own render. After a package update and `renv::snapshot()`, `renv.lock` and those reports differ. GUIDE.md says that this is expected.
**Decision:** The comparison of `renv.lock` with the versions in stored output runs only when the author calls `check_supplement(renv_lock = TRUE)`. The default is `FALSE`, and `release_supplement()` does not turn it on, so its rows never stop a release. The user chose this at the M064 plan over a check that always runs and stops the release, and over a check that always runs and that the release passes over.
**Consequences:** A release can go ahead while the stored output of a report and `renv.lock` record other versions. Authors who want the comparison run it themselves. `check_supplement()` with its defaults does not read `renv.lock`.

### D-033 (2026-10-28): The package site publishes a CI render of the unchanged template as its demo (extends D-025; D-001 stays scoped to author sites)

**Context:** The package site had no example of the site that `create_supplement()` makes. D-001 has author sites render into a committed `docs/` and rejects a `gh-pages` branch for them. D-025 has the package's own site built in CI and pushed to `gh-pages`.
**Decision:** The `build` job of `.github/workflows/pkgdown.yaml` runs `.github/scripts/build-demo.R` after the pkgdown build. The script makes a site with `create_supplement(repo = "jmgirard/supplement")`, renders it once with no edit, and copies its `docs/` into `docs/demo`, so the demo is part of the package site and follows D-025 and D-026. A failing demo build fails the job, so the whole package site is not deployed until the demo builds again. The user chose a demo template site at the M069 plan. The plan chose the unchanged render over example values in `_supplement.yml`, and a folder of the package site over a separate repository or a committed render.
**Consequences:** The demo cannot drift from the template, because each build from main makes it again. A template change that breaks the render also stops updates to the package's help pages on the site until it is fixed. D-001 still governs author sites, because the demo is a package-site page and is not committed.

### D-034 (2026-10-28): The demo is a filled-in site for a made-up study, built from create_supplement() and the package's functions (supersedes D-033's unchanged-render choice)

**Context:** D-033 has the demo show the template as `create_supplement()` and one render make it, with its placeholder title, setup box, and example report. The user asked for a demo that looks like a finished supplement and shows the main features.
**Decision:** `.github/scripts/build-demo.R` still starts from `create_supplement(repo = "jmgirard/supplement")` in CI. It then acts as an author: it adds simulated data files with `add_data()` and reports with `add_report()`, fills `_supplement.yml` and the LICENSE files with made-up values and an example DOI that resolves to no record, and replaces the setup box with a note that the content is made up. It renders, and it stops when `check_supplement()` returns a row or when a template text it edits is not found exactly once. The user chose this at the M070 plan over keeping the placeholder render, over showing both, and over linking a real supplement of theirs. The plan chose build-time edits over a committed demo source.
**Consequences:** The demo no longer shows what a new site looks like. A template change to a text that the script edits fails the build, and so stops the package-site deploy as D-033 states, until the script is updated. The DOI badge and the download link lead to no record. D-033's other parts stand.

### D-035 (2026-10-28): The package starts git only through git_run() and Quarto only through quarto_run()

**Context:** Since M008, `git_run()` in `R/check-supplement.R` held the package's one `system2()` call, and `tests/testthat/test-source.R` allowed only that call. M072's `render_supplement()` must run Quarto.
**Decision:** `R/` holds two process calls: `git_run()` runs git, and `quarto_run()` in `R/render-supplement.R` runs the Quarto copy that `find_quarto()` picks, by its full path. `test-source.R` allows exactly these two. `release_supplement()` still starts no process of its own, and no function runs `git tag`, `git push`, or a GitHub release (DESIGN.md Conventions). The M072 plan chose `system2()` over the quarto R package, which would add a dependency and would not find the copy inside RStudio or Positron.
**Consequences:** A new process call anywhere else in `R/` fails `test-source.R` until a decision admits it. Quarto's output goes to the console and is not captured, so a caller or test cannot read it.

### D-036 (2026-10-28): Authors publish each release on GitHub's new-release page, and the package prints its address (narrows DESIGN.md's printed release commands)

**Context:** `release_supplement()` printed `git tag`, two pushes, and `gh release create`, so a release needed the GitHub command-line tool and its own sign-in. The user wants a site published with the R console, a browser, and the Git pane of RStudio or Positron.
**Decision:** `release_supplement()` prints and returns four git commands that commit and push the release: `git status -- .`, `git add -A -- .`, `git commit -m "Release vX.Y.Z" -- .`, and `git push`. After them it prints `https://github.com/<owner>/<name>/releases/new?tag=vX.Y.Z`, read from `git remote get-url origin` in the https, scp-like, or `ssh://` GitHub form, or the steps on the Releases page for any other `origin`. The text says to push first, because GitHub makes the tag on the default branch when the release is published. `check_tools()` drops its `gh` row. The package runs none of the printed commands and opens no page. The `origin` read goes through `origin_url()` beside `git_files()`, so `release_supplement()` itself calls no process helper (D-035). The user chose the web page over printing both routes and over no change at the M073 plan.
**Consequences:** No GitHub command-line tool is needed. A release published before the push tags an older commit, which only the printed text guards against. The shorter return value takes no deprecation period, since the package has no release. If GitHub drops the form's `tag` query parameter, the address opens a form with an empty tag field.

### D-037 (2026-10-28): usethis is a suggested dependency (extends D-021)

**Context:** The publishing guide sets up git, the GitHub sign-in, the repository, and GitHub Pages from R with usethis, and stores the token with gitcreds, which usethis brings through gh. No package code calls usethis.
**Decision:** DESCRIPTION lists usethis under Suggests with no version floor, and gitcreds is not listed. The user chose Suggests over naming usethis only in the docs at the M073 plan.
**Consequences:** Installing supplement does not install usethis. The guide's first step installs it. A usethis release that renames a function the guide calls breaks the guide, not the package.

### D-038 (2026-10-28): The release address names the current branch and reads the push url of origin (narrows D-036)

**Context:** GitHub's new-release form makes the tag on the default branch when the author publishes, so a release committed and pushed on another branch is tagged on another commit, and Zenodo archives that commit (M073 review). D-036 read the address from the fetch url of `origin` in three GitHub forms only.
**Decision:** When the site's checkout is on a branch, `release_supplement()` adds `&target=<branch>` to the new-release address, with the name percent-encoded, and its text says that GitHub makes the tag on that branch. When `refs/remotes/origin/HEAD` names another branch, the text names both. The address comes from `git remote get-url --push origin`, and more GitHub url forms give it (M074). The package still runs no `git tag` and opens no page. The user chose the branch in the address over printing `git tag vX.Y.Z` and `git push origin vX.Y.Z`, which pins the exact commit but needs a terminal, and over no change, at the M074 plan.
**Consequences:** A release published after later commits reach that branch still tags the later commit, and only the printed text guards against it. A checkout not on a branch gets no target, so GitHub tags the default branch. The other-branch line reads the default branch of the fetch url, which can differ from the push url's repository. An ssh host alias of GitHub still gets the Releases-page steps.

### D-039 (2026-10-30): The 2026-10-30 triage drops eight candidate rows as not worth keeping

**Context:** A `/cairn-triage` pass weighed every ROADMAP candidate row and every DESIGN.md Known issues entry. It dropped each row that cites no issue or user report and whose effect is an error, a false row, or slow running that only an input outside common use reaches, or that changes no output.
**Decision:** Dropped, each with the effect its row named: "Settle the env argument of run_in" (no caller passes `env` to `run_in()` in `helper-template.R`, an unused argument); "Read huge script bodies past PCRE limits" (one tag with millions of attributes gives the row saying the page cannot be read, which DESIGN.md's "Link reader limits" entry still records); "Speed up the path test of page links" (`link_ok()` runs slower once `docs/` holds any link); "Request web addresses with invalid bytes" (a page byte that is not UTF-8 gives a false `web-link` row in the opt-in check); "Skip FIFOs and other special files" (a FIFO at a report path makes `check_supplement()` wait); "Remove a partly copied demo folder" (a rerun of `.github/scripts/build-demo.R` refuses a folder that a failed `file.copy()` left); "Read ssh host aliases for GitHub" (an ssh host alias gets the Releases-page steps in place of the new-release address, as D-038 states); "Print many check rows in less time" (`report_problems()` takes minutes to print tens of thousands of rows). The user accepted the drops at the triage gate.
**Consequences:** A user report of any of these effects re-opens its row by superseding this entry. No prior decision entry is superseded.

### D-040 (2026-10-30): Windows CI keeps crash dumps and logs each test a process starts (extends D-020)

**Context:** Two windows-latest R CMD check runs ended when a testthat worker process crashed with an access violation, and the check output named only the test file and the exit code (`cairn/references/windows-test-crash.md`). The crash came in two different files on commits that changed no code, so its cause can be read only from a crash that leaves more trace.
**Decision:** The Windows job of `R-CMD-check.yaml` builds a crash catcher DLL with `R CMD SHLIB`, and each test process on Windows CI loads it. Its vectored exception handler writes a minidump of its own process on an access violation or another fatal exception code, at most 3 per process, and lets the exception go on. Windows Error Reporting `LocalDumps` wrote no dump for a planted crash of a test process (M080), so the job does not use it. Each test process also writes each test it starts to a log named by its process id, through a testthat state inspector. A step after the check reads each dump with a standard-library Python script and prints the fault module and offset and the last test of that process, and the job uploads the dumps and logs when a dump exists. A manual run's `plant_crash` input crashes one test process on purpose. No tool is installed for this. The user chose catching the next crash over a loop that tries to cause it now, and over a record with no CI change, at the M080 plan.
**Consequences:** Each Windows job runs three more steps and writes a log line per test. `tests/testthat/test-plant-crash.R` skips in every normal run. A crash in a program that is not a test process, such as Quarto, gives no dump. An access violation that other code in the process handles still gives a dump, and a dump written from a process with a corrupt heap can fail. The cause of the crash stays unknown until a crash comes after this change.
