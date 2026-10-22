# M032: write_dockerfile() writes a container recipe from renv.lock

- **Status:** in-progress
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

- [ ] AC1: A fixture `renv.lock` names R 4.6.1 and renv 1.3.1. The test runs `write_dockerfile(path, quarto = "1.10.19")`. The written `Dockerfile` has the FROM line `FROM rocker/r-ver:4.6.1`. It sets `RENV_PATHS_LIBRARY` to a folder in the image and turns off renv's cache links. It installs Quarto 1.10.19, and it installs renv 1.3.1 into the `RENV_PATHS_LIBRARY` library. It copies `renv.lock` into the image and runs `renv::restore()` on it. The file has LF line endings on every system, and the test compares its bytes with the expected bytes in T2.
- [ ] AC2: With `digest = "sha256:"` followed by 64 lowercase hex digits, the FROM line is `FROM rocker/r-ver:4.6.1@` followed by that digest. The test compares the line.
- [ ] AC3: The function also writes `.dockerignore` with the two lines `*` and `!renv.lock`, with LF line endings. The test compares its bytes.
- [ ] AC4: Each refusal gives the class named here. After each refusal, `folder_md5()` of the site folder is the same as before the call. A test asserts the class for each shape listed here. On Windows the link shapes skip, as the existing link tests do.
  - `path` that is not one string, a missing folder, or a file: `supplement_error_argument`.
  - No `renv.lock` in the site: `supplement_error_no_file`.
  - A `renv.lock` that is empty, truncated JSON, a JSON array, or a JSON scalar: `supplement_error_lockfile`. The same class for no `R`, an `R` that is a string, no `R.Version`, and an `R.Version` that is a number, an array, or `""`. The same class for no renv entry under `Packages`, and for a renv entry with no `Version`.
  - The R version of the lockfile, the renv version of the lockfile, or `quarto`, when it is `"4.6"`, `"4.6.1.1"`, `" 4.6.1"`, `"4.6.1\n"`, `"1.1.5.9000"`, NA, length 2, or a number: `supplement_error_lockfile` for the two lockfile versions, and `supplement_error_argument` for `quarto`.
  - A `digest` with 63 hex digits, uppercase digits, no `sha256:`, a final `"\n"`, NA, length 2, or a number: `supplement_error_argument`.
  - An `overwrite` that is NA, `"TRUE"`, or length 2: `supplement_error_argument`.
  - A `Dockerfile` or `.dockerignore` that exists while `overwrite` is FALSE: `supplement_error_file_exists`. The same class for a link to a file, a link to a folder, a broken link, or a folder at either path, with `overwrite` TRUE and FALSE.
- [ ] AC5: On a machine with Docker and with `SUPPLEMENT_TEST_DOCKER=true` set, a test runs. It sets up renv in a site as the M031 tests do, writes the Dockerfile, and builds the image. If `docker manifest inspect rocker/r-ver:<lockfile R version>` fails, it skips. It runs `docker run --network none --user <uid>:<gid> -e HOME=/tmp` with the site folder mounted, and that run renders `analyses/example.qmd` and exits 0. The Computing environment section of the rendered page holds the R version that the site's `renv.lock` names. The test then deletes the site with no error.
- [ ] AC6: The help page and the template guide state these facts. They say how to build the image and how to render one report in it with the site folder mounted. The image that the written Dockerfile builds holds no site file other than `renv.lock`, and no data, because `.dockerignore` keeps the rest out of the build. Without `digest`, a later build can get newer system libraries. The guide shows how to read the multi-platform digest of `rocker/r-ver:<version>` with `docker buildx imagetools inspect`. `docker save` writes a built image to a file that an author can archive. Once the author commits the Dockerfile, the Zenodo archive of a GitHub release holds it, but not the image.
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

## Decisions

## Review
