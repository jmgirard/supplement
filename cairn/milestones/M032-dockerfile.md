# M032: write_dockerfile() writes a container recipe from renv.lock

- **Status:** review
- **Priority:** normal
- **Depends on:** M031
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a new exported function and a guide part
- **Branch/PR:** m032-dockerfile

## Goal

`write_dockerfile()` writes a Dockerfile and a `.dockerignore` from a site's `renv.lock`, so that an author can build an image with the site's R, packages, and Quarto, and render a report in it with the site folder mounted.

## Scope

**In:** an exported `write_dockerfile(path = ".", quarto, digest = NULL, overwrite = FALSE)` in a new `R/write-dockerfile.R`, its help page, a container part in `inst/template/_README.md`, a pointer in `README.md`, tests, and a NEWS.md bullet.

**Out:** supplement never runs `docker`. Binder and other hosted services are not covered. Python packages get no recipe (candidate row "Record the Python setup of reports"). supplement does not look up a digest over the network, so the author passes it.

## Acceptance criteria

- [x] AC1: A fixture `renv.lock` names R 4.6.1 and renv 1.3.1. The test runs `write_dockerfile(path, quarto = "1.10.19")`. The written `Dockerfile` has the FROM line `FROM rocker/r-ver:4.6.1`. It sets `RENV_PATHS_LIBRARY` to a folder in the image and turns off renv's cache links. It installs Quarto 1.10.19, and it installs renv 1.3.1 into the `RENV_PATHS_LIBRARY` library. It copies `renv.lock` into the image and runs `renv::restore()` on it. The file has LF line endings on every system, and the test compares its bytes with the expected bytes in T2.
- [x] AC2: With `digest = "sha256:"` followed by 64 lowercase hex digits, the FROM line is `FROM rocker/r-ver:4.6.1@` followed by that digest. The test compares the line.
- [x] AC3: The function also writes `.dockerignore` with the two lines `*` and `!renv.lock`, with LF line endings. The test compares its bytes.
- [x] AC4: Each refusal gives the class named here. After each refusal, `folder_md5()` of the site folder is the same as before the call. A test asserts the class for each shape listed here. On Windows the link shapes skip, as the existing link tests do.
  - `path` that is not one string, a missing folder, or a file: `supplement_error_argument`.
  - No `renv.lock` in the site: `supplement_error_no_file`.
  - A `renv.lock` that is empty, truncated JSON, a JSON array, or a JSON scalar: `supplement_error_lockfile`. The same class for no `R`, an `R` that is a string, no `R.Version`, and an `R.Version` that is a number, an array, or `""`. The same class for no renv entry under `Packages`, and for a renv entry with no `Version`.
  - The R version of the lockfile, the renv version of the lockfile, or `quarto`, when it is `"4.6"`, `"4.6.1.1"`, `" 4.6.1"`, `"4.6.1\n"`, `"1.1.5.9000"`, NA, length 2, or a number: `supplement_error_lockfile` for the two lockfile versions, and `supplement_error_argument` for `quarto`.
  - A `digest` with 63 hex digits, uppercase digits, no `sha256:`, a final `"\n"`, NA, length 2, or a number: `supplement_error_argument`.
  - An `overwrite` that is NA, `"TRUE"`, or length 2: `supplement_error_argument`.
  - A `Dockerfile` or `.dockerignore` that exists while `overwrite` is FALSE: `supplement_error_file_exists`. The same class for a link to a file, a link to a folder, a broken link, or a folder at either path, with `overwrite` TRUE and FALSE.
- [x] AC5: On a machine with Docker and with `SUPPLEMENT_TEST_DOCKER=true` set, a test runs. It sets up renv in a site as the M031 tests do, writes the Dockerfile, and builds the image. If `docker manifest inspect rocker/r-ver:<lockfile R version>` fails, it skips. It runs `docker run --network none --user <uid>:<gid> -e HOME=/tmp` with the site folder mounted, and that run renders `analyses/example.qmd` and exits 0. The Computing environment section of the rendered page holds the R version that the site's `renv.lock` names. The test then deletes the site with no error.
- [x] AC6: The help page and the template guide state these facts. They say how to build the image and how to render one report in it with the site folder mounted. The image that the written Dockerfile builds holds no site file other than `renv.lock`, and no data, because `.dockerignore` keeps the rest out of the build. Without `digest`, a later build can get newer system libraries. The guide shows how to read the multi-platform digest of `rocker/r-ver:<version>` with `docker buildx imagetools inspect`. `docker save` writes a built image to a file that an author can archive. Once the author commits the Dockerfile, the Zenodo archive of a GitHub release holds it, but not the image.
- [ ] AC7: NEWS.md has one bullet for `write_dockerfile()`. `devtools::test()` passes with no failures, and `devtools::check()` gives 0 errors and 0 warnings. The R-CMD-check workflow passes on Windows, macOS, and Ubuntu.

## Coverage

- AC1 → T1, T2, T3
- AC2 → T2, T3
- AC3 → T2, T3
- AC4 → T2, T3
- AC5 → T1, T4
- AC6 → T1, T5
- AC7 → T5, T6

## Tasks

- [x] T1: Probe with Docker on the Mac. Build a first draft Dockerfile for a site with renv. Find how `/rocker_scripts/install_quarto.sh` takes a Quarto version, how renv gets into the `RENV_PATHS_LIBRARY` library so that `activate.R` finds it with no download, and which setting turns off cache links. Find whether the render runs with `--network none` and `--user`. Record each result in the work log, and write the help text from what the probes show (the derived-claims rule).
- [x] T2: Write the AC1 to AC4 tests in a new `tests/testthat/test-write-dockerfile.R`. Write the full expected Dockerfile into the test from the T1 probe. Write fixtures with `writeBin()` (LESSONS M011). Use `folder_md5()` (`helper-template.R:208`) before and after each refusal.
- [x] T3: Write `write_dockerfile()` with roxygen help. Read `renv.lock` with jsonlite. Check versions with a `\z` anchor (LESSONS M007). Refuse links and folders with `is_link()` and `path_occupied()` (`R/supplement-yml.R`). Write with `writeBin()` so that line endings are LF. Add the export to NAMESPACE with `devtools::document()`.
- [x] T4: Write the AC5 test in `tests/testthat/test-write-dockerfile.R`, and run it on the Mac with `SUPPLEMENT_TEST_DOCKER=true`. Record the run in the work log. The R-CMD-check workflow does not set the variable.
- [x] T5: Write the container part of `inst/template/_README.md` after the renv part from M031, and a pointer in `README.md`. Add a NEWS.md bullet.
- [x] T6: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

## Work log

- 2026-10-21: created by /milestone-plan.
- 2026-10-21: tier check: milestone — a new exported function with design choices.
- 2026-10-21: idea vet: see M030's idea-vet line. For this milestone, the user asked whether every version can be pinned and whether the image can stay apart from private data. The answer is the `digest` argument, the `.dockerignore`, and the `docker save` part of the guide.
- 2026-10-21: question set: container form — `write_dockerfile()`, with an optional digest pin and a `.dockerignore` that admits only `renv.lock`.
- 2026-10-21: question set: permission to pull Rocker images and build images on the Mac for the AC5 test at implement and review — granted with the container answer.
- 2026-10-21: plan gate chose a function over an example Dockerfile in the guide, because the function reads the R and renv versions from `renv.lock` so that the recipe matches the lockfile; falsified by authors who edit the written Dockerfile in most sites.
- 2026-10-21: depends on M031, because the recipe restores the `renv.lock` that M031's guide makes, and the AC5 test uses M031's renv helper.
- 2026-10-21: collision check: no ROADMAP row, archived milestone, or D-entry covers containers. D-014's context mentions a Docker image only as an option it did not take.
- 2026-10-21: inbox sweep: 0 open issues, 0 open PRs.
- 2026-10-21: lessons surfaced: M007 (`\z` anchors), M011 (`writeBin()` fixtures), M018 and M022 (links and junctions on Windows), M006 (record a target before a write that can fail).
- 2026-10-21: criteria audit (full mode, fresh Opus reader): 6 findings for the draft and 10 for the revision after the question set, all taken. Main changes: renv goes into the `RENV_PATHS_LIBRARY` library, cache links are off, and the file is LF and compared as bytes. Each refusal names its class, and the shapes now vary path, lockfile form, each version source, digest, and `overwrite`. The Docker test runs offline and as the user, skips without a Rocker tag for the R version, and compares with the lockfile's R version. The guide reads the base image's multi-platform digest, and the Zenodo claim needs a committed Dockerfile. AC2 and AC7 had no finding.
- 2026-10-21: changelog: one new bullet in NEWS.md under 0.0.0.9000.
- 2026-10-22: implement started on branch m032-dockerfile, cut from main at b32dc42.
- 2026-10-22: T1 probe (Docker 29.0.1 on the Mac, aarch64, rocker/r-ver:4.6.1, a template site after renv::init() with renv 1.3.1): `/rocker_scripts/install_quarto.sh 1.10.19` takes the version as its first argument and installs the GitHub release .deb for the machine's architecture.
- 2026-10-22: T1 probe: renv's library path under `RENV_PATHS_LIBRARY` is `<root>/linux-ubuntu-noble/R-4.6/<platform>` (`renv::paths$library()`), so the Dockerfile asks renv for it rather than building it. `restore(library = renv::paths$library())` installs renv 1.3.1 from the lockfile into that library, and `activate.R` loads it there in a `--network none` run. Without `library =`, restore wrote into `/usr/local/lib/R/site-library`.
- 2026-10-22: T1 probe: the first build failed because binary `fs` needs libuv (`libuv.so.1: cannot open shared object file`). `renv::sysreqs(report = FALSE, check = FALSE)` lists the apt packages (cmake, libuv1-dev, make, pandoc for the template), and the build installs them before restore. Minor amendment: this step is part of the recipe; AC1 wording unchanged.
- 2026-10-22: T1 probe: with `RENV_CONFIG_CACHE_SYMLINKS=FALSE` the library held real folders but renv's cache added 72 MB under `/root/.cache/R/renv`; `RENV_CONFIG_CACHE_ENABLED=FALSE` installs straight into the library with no cache and no links. Decision: use `RENV_CONFIG_CACHE_ENABLED=FALSE`, which turns off cache links by turning off the cache. renv's downloads go to a temporary `RENV_PATHS_ROOT` that the same RUN deletes, with the bootstrap renv copy in a temporary `R_LIBS`.
- 2026-10-22: T1 probe: renv 1.3.1's source tarball downloads from `https://p3m.dev/cran/latest/src/contrib/Archive/renv/renv_1.3.1.tar.gz` (also 1.0.0, and the current version), independent of the image's dated CRAN snapshot. Decision: the bootstrap install uses that URL with the lockfile's renv version.
- 2026-10-22: T1 probe: `docker run --rm --network none --user $(id -u):$(id -g) -e HOME=/tmp -v "$PWD":/site <image> quarto render analyses/example.qmd` exits 0; the session info shows R 4.6.1, Ubuntu 24.04.5, and library `/opt/renv/library/linux-ubuntu-noble/R-4.6/aarch64-unknown-linux-gnu`. The image's `/site` is empty and `/opt/renv` holds only `renv.lock` and the library.
- 2026-10-22: T1 probe: `docker buildx imagetools inspect rocker/r-ver:4.6.1` prints the multi-platform `Digest:` line (sha256:bafb3b9a…), and a FROM line with `@` and that digest builds. `docker manifest inspect` exits 0 for 4.6.1 and 1 for a missing tag. `docker save -o image.tar` wrote 586 MB for a 2.32 GB image, and `docker load -i` reloaded it.
- 2026-10-22: correction to the first T1 probe line: the Docker server version is 29.9.1, not 29.0.1.
- 2026-10-22: T2 and T3: `tests/testthat/test-write-dockerfile.R` (15 tests) and `R/write-dockerfile.R`; the tests failed with no function and pass with it. Planted defects went red: no link refusal (19 failures in the link test), and a version rule of `^[0-9.]+$` (12 lockfile and 2 quarto failures).
- 2026-10-22: T3 decisions: the function checks `path`, `overwrite`, `quarto`, and `digest`, then reads the lockfile, then refuses a folder or a link at either target before any write. A missing `quarto` is `supplement_error_argument`; a `renv.lock` that is a folder is `supplement_error_no_file`. It returns both paths invisibly. Versions use the existing `is_version()` rule (three whole numbers, no leading zero).
- 2026-10-22: T3: `test-source.R` refuses `system2(` anywhere in `R/`, so the system-package step writes the list to `/tmp/renv/sysreqs.txt` and runs `xargs -r apt-get install`. With no package needing one, `unlist()` gave NULL and `writeLines()` stopped, so the list goes through `as.character()`. Both forms built on the Mac: the template site (libuv1-dev, cmake, pandoc set up; offline render exit 0) and a lockfile with renv alone.
- 2026-10-22: verify: `devtools::test()` 329 tests, 0 failed, 7 skipped (before the `as.character()` change; the new file's 15 tests pass after it).
- 2026-10-22: T4: the AC5 test ran on the Mac with `SUPPLEMENT_TEST_DOCKER=true` (Docker 29.9.1, R 4.6.1, Quarto 1.10.19): 11 expectations, 0 failed, 11.6 s with Docker's layer cache from the T3 builds; its image is removed after. Without the variable it skips with "SUPPLEMENT_TEST_DOCKER is not true", which is not on the CI missing-tool list. It also skips on Windows (`id -u`). Beyond AC5 it checks that the section names `/opt/renv/library/`: with the render replaced by `true`, the R version check passed on the host-rendered page and that check failed.
- 2026-10-22: T5: guide part "Running reports in a container" after the renv part, two README edits (the guide summary and a `write_dockerfile()` paragraph after the renv one), and one NEWS bullet after the renv bullet. The guide adds one fact beyond AC6, from the Dockerfile text: after `renv::snapshot()`, build again, and write the recipe again when the R or renv version changed. `devtools::test()`: 330 tests, 0 failed, 8 skipped (the Docker test is the new skip).
- 2026-10-22: T6: `devtools::check()` 0 errors, 0 warnings, 0 notes on the Mac. The R-CMD-check workflow runs at the PR.
- 2026-10-22: claim audit: 64 claims read, 14 corrected — R/write-dockerfile.R, man/write_dockerfile.Rd, inst/template/_README.md, README.md, NEWS.md. Corrections: platforms (amd64, arm64 only for R 4.1.0 or later), renv 1.3.1 floor, `.dockerignore` limits what can be copied into the image, `--user` ownership on Linux only, failed writes and R's own open error, and a new digest after the R version changes. The re-read found the platform and failed-write wording still short; both fixed with the reader's wording, no further pass.
- 2026-10-22: minor amendment from the claim audit: `write_dockerfile()` refuses a lockfile renv older than 1.3.1 (`supplement_error_lockfile`), with a test for 1.3.0 and 1.2.0; the version-source test moved to renv 1.10.0. No AC wording changed (AC4 lists the refusal shapes its tests must cover; this adds one). See Decisions.
- 2026-10-22: verify after the audit: `devtools::test()` 331 tests, 0 failed, 8 skipped; the last edits were help and guide wording, and the new file's 17 tests pass after them.
- 2026-10-22: status review; handed to /milestone-review.

## Decisions

- 2026-10-22: `write_dockerfile()` refuses a `renv.lock` that records renv older than 1.3.1. Before 1.3.1, `renv::sysreqs()` reads the packages from the project's code, which the build does not have: with renv 1.3.0 it listed no system packages for the template site, and renv 1.1.1 has no `sysreqs()`, so the build fails at restore. A fixed renv for the build was not taken, because its library path could differ from the one that an older renv's `activate.R` looks in.

## Review

- 2026-10-22: sync: `git fetch origin`; main has not moved since the branch was cut (b32dc42 is an ancestor of HEAD). Copilot round off (no `# Copilot review:` line in PROFILE.md).
- AC1 evidence (2026-10-22): `test_file("tests/testthat/test-write-dockerfile.R")` with `SUPPLEMENT_TEST_DOCKER=true`: 17 tests, 0 failed, 0 skipped. "the Dockerfile and .dockerignore have the expected bytes" (4 expectations) compares the Dockerfile's bytes with the literal expected text for R 4.6.1, renv 1.3.1, Quarto 1.10.19: FROM `rocker/r-ver:4.6.1`, `RENV_PATHS_LIBRARY=/opt/renv/library`, `RENV_CONFIG_CACHE_ENABLED=FALSE` (cache and so its links off), `install_quarto.sh 1.10.19`, renv 1.3.1 restored into `renv::paths$library()`, `COPY renv.lock` and `renv::restore()`; it also checks for no CR byte. "the R, renv, and Quarto versions come from renv.lock and the quarto argument" passes with R 4.5.2, renv 1.10.0, Quarto 1.9.37.
- AC2 evidence (2026-10-22): same run, "a digest pins the base image" passes: line 3 is `FROM rocker/r-ver:4.6.1@sha256:` plus the 64-digit test digest, and the other lines equal the expected text.
- AC3 evidence (2026-10-22): same run, the bytes test compares `.dockerignore` with `charToRaw("*\n!renv.lock\n")` and passes; "overwrite = TRUE replaces both files" checks the same bytes after a replace.
- AC4 evidence (2026-10-22): same run, each refusal test asserts the class with `expect_error(class =)` and `folder_md5()` equal before and after, all 0 failed: path not one folder (`c(dir, dir)`, `1`, NA, `""`, missing folder, a file: argument, 12 expectations); no renv.lock and a renv.lock folder (no_file); 12 lockfile shapes (empty, truncated, array, scalar, no R, R a string, no R.Version, R.Version number/array/`""`, no renv, renv with no Version: lockfile, 24); the 8 version shapes for the lockfile R and renv (lockfile, 32) and for `quarto` (argument, 16); 7 digest shapes (argument, 14); 3 overwrite shapes (argument, 6); an existing Dockerfile or .dockerignore with overwrite FALSE (file_exists, 4); a folder at either path with overwrite TRUE and FALSE (file_exists, 8); a link to a file, to a folder, and a broken link at either path with overwrite TRUE and FALSE (file_exists, 48; `skip_on_os("windows")`). Also a missing `quarto` (argument) and renv 1.3.0 and 1.2.0 (lockfile).
- AC5 evidence (2026-10-22): same run on the Mac (Docker 29.9.1, aarch64), "the image renders a report offline as the user, with the lockfile's R": 11 expectations, 0 failed. It sets up renv with `renv_site()`, skips only if `docker manifest inspect rocker/r-ver:<R>` fails (it did not), builds, runs `docker run --rm --network none --user <uid>:<gid> -e HOME=/tmp -v <site>:/site <image> quarto render analyses/example.qmd` with exit 0, finds `R version 4.6.1 ` (the lockfile's R) and `/opt/renv/library/` in the Computing environment section, then `unlink()`s the site and finds it gone. Docker's layer cache served that build; a separate `docker build --no-cache` of the probe site's freshly written Dockerfile also exited 0, its offline render as the user exited 0 with R 4.6.1 and the image library on the page, and the image's `/site` was empty and `/opt/renv` held only `library` and `renv.lock`.
- AC6 evidence (2026-10-22): read `man/write_dockerfile.Rd` and the guide part "Running reports in a container" in `inst/template/_README.md`. Both state: how to build (`docker build -t my-supplement .`) and render one report with the site mounted (`docker run --rm --network none --user ... -v "$PWD":/site my-supplement quarto render analyses/example.qmd`); that `.dockerignore` lets only `renv.lock` of the site's files into the image, so it holds no other site file and no data; that without a digest a later build can get newer system libraries; how to read the multi-platform index digest with `docker buildx imagetools inspect rocker/r-ver:4.6.1`; that `docker save` writes the image to a file to archive; and that the Zenodo archive of a GitHub release holds the committed Dockerfile but not the image. The claim audit (64 claims, 14 corrected, re-read once) checked these against Docker and the code.
- AC7 evidence, local part (2026-10-22): NEWS.md has one `write_dockerfile()` bullet (line 30). `devtools::test()`: 331 tests, 0 failed, 0 errors, 8 skipped. `devtools::check()`: 0 errors, 0 warnings, 0 notes. The R-CMD-check workflow on Windows, macOS, and Ubuntu runs when step 8 opens the PR; AC7 is ticked only after it passes.
- gate (2026-10-22): `cairn_validate.py` all checks passed (exit 0). No DESIGN.md principle changed, so no `cairn_impact`. `devtools::document()` gives no diff. No README.Rmd and no `_pkgdown.yml`, so no knit or pkgdown check. NEWS.md has the bullet with no milestone number. New files are under `R/`, `man/`, and `tests/`, no new top-level file. `devtools::check()` 0/0/0 (AC7 line).
- spawned: diff-bug, blame-history, prior-review, ripple
- diff-bug #1: a lockfile with R before 4.0.0 gets a Dockerfile that cannot build (`rocker/r-ver:3.6.3` has no `/rocker_scripts`), with no error — fix now (refused with `supplement_error_lockfile`), fixed 00f4768
- diff-bug #2: the Dockerfile is written before `.dockerignore`, so a failure between them leaves a Dockerfile without its context filter — fix now (`.dockerignore` first), fixed 00f4768
- diff-bug #3: `apt-get install` runs without `DEBIAN_FRONTEND=noninteractive` — fix now, fixed 00f4768 (rebuilt: Docker test passed)
- diff-bug #4: older Rocker images and amd64 were not built — follow-up: row "Build the Dockerfile on older R images"; the help now states what was built and when, fixed 00f4768
- diff-bug #5: the bootstrap renv URL is fixed to p3m.dev and ignores the lockfile's repositories — reject (edge: only a build that cannot reach p3m.dev, such as a private-mirror-only network, outside documented use; effect is a build error)
- diff-bug #6: the "run renv::snapshot()" hint does not help for a development renv or an old renv — fix now (own hints), fixed 00f4768
- diff-bug #7: the failed-write help wording reads as if an open failure is not a failed write — fix now, fixed 00f4768
- diff-bug #8: DESIGN.md has no family or Architecture paragraph for `write_dockerfile()` — fix now, fixed 00f4768
- diff-bug #9: a failed `install.packages()` exits 0 and the build stops one step later — fix now (`library(renv)` after it), fixed 00f4768
- diff-bug #10: the required `quarto` comes after the defaulted `path` — reject (planned change: Scope fixes the signature)
- diff-bug #11: the link refusal has no hint — fix now, fixed 00f4768
- diff-bug #12: `argument_error()` and `is_version_string()` sit in the feature file — reject (style)
- diff-bug #13: `quarto` or `digest` with invalid UTF-8 adds a base `grepl()` warning — follow-up: DESIGN.md Known issues "Release edge cases", extended in this review
- diff-bug #14: a BOM is accepted with jsonlite's warning, and with duplicate keys the first wins silently — follow-up: row "Refuse duplicate keys in renv.lock" (the BOM part: reject, edge: renv writes no BOM; effect a warning)
- diff-bug #15: a roxygen line past 100 characters — reject (style); the paragraph was rewrapped with #7
- diff-bug #16: the Dockerfile comment "a library in this folder" does not name the folder — fix now, fixed 00f4768
- diff-bug (c)1: the no-CR check repeats the exact bytes check — fix now (removed), fixed 00f4768
- diff-bug (c)2: four `path` values run the untouched `check_path()` — fix now (kept `c(site, site)`, a missing folder, a file), fixed 00f4768
- diff-bug (c)3: three `overwrite` values run the untouched `check_args()` — reject (planned change: AC4 lists NA, "TRUE", and length 2)
- diff-bug (c)4: eight version values at three sources run one regex — reject (planned change: AC4 lists each value at each source)
- diff-bug (c)5: renv 1.3.0 and 1.2.0 take one branch — fix now (1.3.0 kept), fixed 00f4768
- diff-bug (c)6: `overwrite` FALSE and TRUE run one path for folders and links — reject (planned change: AC4 asks for both)
- diff-bug (c)7: the outside-folder checks guard a write the refusal already prevents — fix now (removed; `folder_md5()` of the site reads through the link), fixed 00f4768
- diff-bug (c)8: unescaped dots in the negative version match — fix now (fixed matches), fixed 00f4768
- diff-bug (c)9: the FALSE link cases pass through `check_overwrite()` without the new refusal — reject (false as a defect: AC4 lists them, and the TRUE file-link and broken-link cases cover the new refusal)
- diff-bug (c)10: no test checks that errors name `write_dockerfile()` as the call — fix now (new test, five branches), fixed 00f4768
- blame-history #1: a failed overwrite has no restore, unlike the release writer — follow-up: DESIGN.md Known issues "Release edge cases" (the accepted no-restore limit of the sibling writers), extended in this review
- blame-history #2: the link refusal differs from `write_citation()` and `write_zenodo()`, which write through a link with `overwrite = TRUE` — follow-up: row "Refuse links in the citation writers"
- blame-history #3: the link refusal has no Windows test — reject (planned change: AC4 skips the link shapes on Windows as the existing link tests do)
- blame-history #4: the CI missing-tool list lacks the Docker skip texts — reject (false: CI never sets `SUPPLEMENT_TEST_DOCKER`, so those skips cannot occur there)
- blame-history #5: the build's download of renv from p3m.dev is not documented — fix now (help names it), fixed 00f4768
- blame-history #6: a trailing separator gives `site//Dockerfile` — reject (false as a defect: the path names the same file; the sibling writers share it)
- blame-history #7: "supplement does not call renv" next to the new paragraph — reject (false: the sentence still holds; the README part was regrouped with ripple #3)
- prior-review #1: a failed overwrite leaves the old file truncated (M006, M009 restore findings) — follow-up: same Known issues extension as blame-history #1
- prior-review #2: the link refusal has no Windows test (M018, M022) — reject (planned change, as blame-history #3)
- prior-review #3: invalid UTF-8 `quarto` or `digest` warns (RR01 5.2) — follow-up: same Known issues extension as diff-bug #13
- prior-review #4: a `renv.lock` with invalid UTF-8 or a nul gets "is not a JSON object" rather than `supplement_error_encoding` — reject (edge: renv writes UTF-8 JSON; effect a lockfile error with a vague message)
- prior-review #5: only an aarch64 Mac ran the image test, while the help names amd64 — follow-up: row "Build the Dockerfile on older R images"; help states what was built, fixed 00f4768
- prior-review #6: the Docker skip texts are not on the CI missing-tool list — reject (false, as blame-history #4)
- prior-review #7: the guide says the Computing environment section shows the image's packages, but the fallback `utils::sessionInfo()` prints no library paths — reject (false: the fallback still prints the R and package versions; the test's library check rests on sessioninfo, which `renv_site()` requires)
- prior-review #8: link handling differs between writers — follow-up: row "Refuse links in the citation writers"
- prior-review #9: `unlink(site, recursive = TRUE)` expands globs (LESSONS M009) — fix now (`expand = FALSE`), fixed 00f4768
- prior-review #10: `expect_match(all = FALSE)` passes for a version on the wrong line — reject (false: the bytes test pins every line's place for the same template code; this test shows only that the values come from the inputs)
- prior-review #11: the link refusal's `cli_abort()` has no `call` — reject (false: its default call is `write_dockerfile()`, as the printed error and the new call test show)
- ripple #1: DESIGN.md Function Families lacks `write_dockerfile()` — fix now, fixed 00f4768
- ripple #2: DESIGN.md Architecture has no paragraph for `R/write-dockerfile.R` — fix now, fixed 00f4768
- ripple #3: the README paragraph sits under "Add reports and data" — fix now (new "Record the R setup" part holding the renv and Docker paragraphs), fixed 00f4768
- ripple #4: PROFILE.md's `_pkgdown.yml` rule is unmet — reject (false: no `_pkgdown.yml` exists; the pkgdown row carries it, ripple #5)
- ripple #5: the pkgdown row's reference index names only two writers — follow-up: row "Build a package site with pkgdown" now names `write_dockerfile()`
- ripple #6: the guide's renv part gives no renv version floor — reject (false: the container part states the floors in its first paragraph, before step 1)
- ripple #7: the guide's Contents list does not name `Dockerfile` — reject (false: Contents lists what the template ships, and these files are optional, as renv's are)
- ripple #8: DESIGN.md Conventions does not say supplement never runs Docker — fix now, fixed 00f4768
- ripple #9: DESIGN.md's test paragraph does not say the Docker test runs only locally — fix now, fixed 00f4768
- return floor: no finding shows an acceptance criterion failing; diff-bug #1 is fixed on the branch with no status change. Totals: 53 findings, 22 fix now, 10 follow-up, 21 reject (2 on the edge ground, plus the BOM part of diff-bug #14).
- re-verify after fixes (2026-10-22): `test-write-dockerfile.R` with `SUPPLEMENT_TEST_DOCKER=true`: 18 tests, 0 failed (Docker test 11 expectations, rebuilt RUN layer, 36 s). `devtools::test()` 332 tests, 0 failed, 8 skipped. `devtools::check()` 0/0/0. `devtools::document()` no diff.
