# M032: write_dockerfile() writes a container recipe from renv.lock

- **Status:** planned
- **Priority:** normal
- **Depends on:** M031
- **Driving RR:** —
- **Principles touched:** —
- **Resolves:** —
- **Surface tier:** user-facing — a new exported function and a guide part
- **Branch/PR:** —

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

- [ ] T1: Probe with Docker on the Mac. Build a first draft Dockerfile for a site with renv. Find how `/rocker_scripts/install_quarto.sh` takes a Quarto version, how renv gets into the `RENV_PATHS_LIBRARY` library so that `activate.R` finds it with no download, and which setting turns off cache links. Find whether the render runs with `--network none` and `--user`. Record each result in the work log, and write the help text from what the probes show (the derived-claims rule).
- [ ] T2: Write the AC1 to AC4 tests in a new `tests/testthat/test-write-dockerfile.R`. Write the full expected Dockerfile into the test from the T1 probe. Write fixtures with `writeBin()` (LESSONS M011). Use `folder_md5()` (`helper-template.R:208`) before and after each refusal.
- [ ] T3: Write `write_dockerfile()` with roxygen help. Read `renv.lock` with jsonlite. Check versions with a `\z` anchor (LESSONS M007). Refuse links and folders with `is_link()` and `path_occupied()` (`R/supplement-yml.R`). Write with `writeBin()` so that line endings are LF. Add the export to NAMESPACE with `devtools::document()`.
- [ ] T4: Write the AC5 test in `tests/testthat/test-write-dockerfile.R`, and run it on the Mac with `SUPPLEMENT_TEST_DOCKER=true`. Record the run in the work log. The R-CMD-check workflow does not set the variable.
- [ ] T5: Write the container part of `inst/template/_README.md` after the renv part from M031, and a pointer in `README.md`. Add a NEWS.md bullet.
- [ ] T6: Run `devtools::test()` and `devtools::check()`. The R-CMD-check workflow runs at the PR.

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

## Decisions

## Review
