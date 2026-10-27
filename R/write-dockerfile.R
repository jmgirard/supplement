#' Write a Dockerfile from renv.lock
#'
#' `write_dockerfile()` reads `renv.lock` in a site set up with renv and
#' writes a `Dockerfile` and a `.dockerignore` into the same folder. The
#' image that Docker builds from them holds the R version and the R
#' packages that `renv.lock` records, and the Quarto version that you give.
#' You can then render a report in the image with the site folder mounted,
#' so that its code runs with those versions on another machine that runs
#' Docker with Linux containers on an amd64 processor, or on arm64 for R
#' 4.1.0 or later, the platforms of the Rocker images. `renv.lock` must
#' record R 4.0.0 or later, because older `rocker/r-ver` images lack the
#' Rocker scripts that the build runs. The Dockerfile was built and run with
#' `rocker/r-ver:4.6.1` on arm64 (Docker 29.9.1, 2026-10-22); older images
#' and amd64 were not built. supplement never runs Docker itself.
#'
#' The `Dockerfile` starts from the Rocker image `rocker/r-ver` with the R
#' version in `renv.lock`, and installs Quarto with Rocker's
#' `install_quarto.sh`. It copies `renv.lock` into the image. It downloads
#' the renv version that `renv.lock` records from the CRAN archive of Posit
#' Package Manager (`p3m.dev`), installs it into a temporary library, uses
#' it to install the Ubuntu packages that `renv::sysreqs()` lists for the
#' packages in `renv.lock`, and runs `renv::restore()`. renv reads those
#' packages from `renv.lock` from version 1.3.1 on, so `renv.lock` must
#' record renv 1.3.1 or later. The packages, renv included, go
#' into a library in the image under `/opt/renv/library`, which
#' `RENV_PATHS_LIBRARY` names. renv's package cache is off, so the library
#' holds the packages and not links into a cache. When the site folder is
#' mounted at `/site`, the site's `renv/activate.R` loads renv from that
#' library, with no download.
#'
#' The `.dockerignore` holds the two lines `*` and `!renv.lock`, so of the
#' site's files only `renv.lock` can be copied into the image. The image
#' holds no other site file and no data. Both files are written with LF
#' line endings on every system.
#'
#' @section Build and render:
#' In a terminal, in the site folder, build the image and give it a name:
#'
#' ```
#' docker build -t my-supplement .
#' ```
#'
#' Then render one report in it with the site folder mounted at `/site`.
#' On macOS and Linux:
#'
#' ```
#' docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/tmp \
#'   -v "$PWD":/site my-supplement quarto render analyses/example.qmd
#' ```
#'
#' `--network none` shows that the render needs nothing from the network.
#' `--user` runs the render as you. On Linux it makes you the owner of the
#' files that the render writes into the site folder; Docker Desktop on
#' macOS does that without it. `HOME=/tmp` gives that user a home folder in
#' the container.
#'
#' @section Versions that can change:
#' An image tag such as `rocker/r-ver:4.6.1` can be moved to a newer image,
#' so without `digest`, a later build can get newer system libraries. To
#' pin the base image, read the digest of its multi-platform index:
#'
#' ```
#' docker buildx imagetools inspect rocker/r-ver:4.6.1
#' ```
#'
#' and pass the `Digest:` value, such as `"sha256:bafb..."`, as `digest`.
#' The build also installs Ubuntu packages for the R packages. These come
#' from Ubuntu's package archive at build time, so they can be newer in a
#' later build even with `digest`.
#'
#' To keep the built image itself, write it to a file that you can archive:
#'
#' ```
#' docker save -o my-supplement.tar my-supplement
#' ```
#'
#' `docker load -i my-supplement.tar` reads it back. Commit the
#' `Dockerfile` and the `.dockerignore`: the Zenodo archive of a GitHub
#' release then holds them, but not the image.
#'
#' @param path The site folder that holds `renv.lock`.
#' @param quarto The Quarto version to install, as three whole numbers
#'   joined by `.`, such as `"1.10.19"`. `quarto --version` in a terminal
#'   prints the version that you render with.
#' @param digest `NULL`, or the digest of the base image, `"sha256:"` and
#'   64 lowercase hex digits. With a digest, the `FROM` line names the image
#'   by its tag and the digest, so the build uses that image even after the
#'   tag moves.
#' @param overwrite If `TRUE`, replace an existing `Dockerfile` and
#'   `.dockerignore`.
#'
#' @return The paths of the written `Dockerfile` and `.dockerignore`,
#'   invisibly.
#'
#' @section Errors:
#' The function checks the arguments, `renv.lock`, and both target paths
#' before it writes a file, so after any error but a failed write the site
#' folder is as it was. It writes `.dockerignore` first, then the
#' `Dockerfile`. A failed write, an open that fails included, can leave
#' `.dockerignore` written, and either file empty or cut short. A file that
#' cannot be opened for writing gives R's own error. The other errors have
#' the class `supplement_error` and one of these classes:
#'
#' * `supplement_error_argument`: `path` is not a single non-missing,
#'   non-empty string, or it is not a folder. `quarto` is missing or is not
#'   one string of three whole numbers joined by `.`, each `0` or without
#'   a leading zero. `digest` is not `NULL` or one string of `sha256:` and
#'   64 lowercase hex digits. `overwrite` is not `TRUE` or `FALSE`.
#' * `supplement_error_no_file`: the folder has no `renv.lock`, or
#'   `renv.lock` is a folder.
#' * `supplement_error_lockfile`: `renv.lock` is not a JSON object, has no
#'   `R` object with a `Version`, or has no `renv` entry with a `Version`
#'   under `Packages`, or one of the two versions is not one string of three
#'   whole numbers joined by `.`. A development version such as
#'   `1.1.5.9000` is such an error, because the build installs released
#'   versions. An R version older than 4.0.0 or a renv version older than
#'   1.3.1 is also this error. So is a key that the function reads, given
#'   twice in the same object: `R` or `Packages` at the top level,
#'   `Version` in `R`, `renv` in `Packages`, or `Version` in that `renv`
#'   entry. This check comes before the version checks.
#' * `supplement_error_file_exists`: `Dockerfile` or `.dockerignore`
#'   exists and `overwrite` is `FALSE`. A folder at either path is this
#'   error even when `overwrite` is `TRUE`. So is a link, also a link to a
#'   missing file, because a write would follow it.
#' * `supplement_error_write`: a file was opened, but writing it gave an
#'   error or a warning, or the file then has another size than the text.
#'
#' @seealso The parts "Recording R packages with renv" and "Running
#'   reports in a container" of the template guide, `GUIDE.md`.
#' @export
#' @examples
#' site <- file.path(tempdir(), "my-supplement")
#' dir.create(site)
#' writeLines(
#'   '{"R": {"Version": "4.6.1"}, "Packages": {"renv": {"Version": "1.3.1"}}}',
#'   file.path(site, "renv.lock")
#' )
#' write_dockerfile(site, quarto = "1.10.19")
#' readLines(file.path(site, "Dockerfile"))
#' unlink(site, recursive = TRUE)
write_dockerfile <- function(path = ".", quarto, digest = NULL, overwrite = FALSE) {
  check_args(path, overwrite)
  if (!dir.exists(path)) {
    argument_error("{.arg path} must be a folder: {.path {path}}.")
  }
  if (missing(quarto) || !is_version_string(quarto)) {
    argument_error(c(
      "{.arg quarto} must be a Quarto version, such as {.val 1.10.19}.",
      "i" = "Run {.code quarto --version} in a terminal to see the version that you render with."
    ))
  }
  if (!is.null(digest) &&
      !(is.character(digest) && length(digest) == 1 && !is.na(digest) &&
        grepl("\\Asha256:[0-9a-f]{64}\\z", digest, perl = TRUE))) {
    argument_error(c(
      "{.arg digest} must be {.code NULL} or {.code sha256:} and 64 lowercase hex digits.",
      "i" = "{.code docker buildx imagetools inspect rocker/r-ver:<version>} prints it after {.code Digest:}."
    ))
  }
  source <- dockerfile_lock_source(path)
  versions <- read_lockfile_versions(path, source)

  dockerfile <- file.path(path, "Dockerfile")
  dockerignore <- file.path(path, ".dockerignore")
  check_overwrite(c(dockerfile, dockerignore), overwrite, "write_dockerfile")
  inform_lock_source(source)

  # .dockerignore first, so a Dockerfile never stands without it.
  write_utf8(c("*", paste0("!", source$file)), dockerignore)
  write_utf8(dockerfile_text(versions$r, versions$renv, quarto, digest, source), dockerfile)
  invisible(c(dockerfile, dockerignore))
}

# The lockfile of the site's renv profile, from lock_source(), with the
# profile name refused unless the Dockerfile and .dockerignore can hold it
# as written. The name check comes before any file check, so that no file
# function sees a name that is not valid UTF-8.
dockerfile_lock_source <- function(path, call = parent.frame()) {
  profile_error <- function(message) {
    cli::cli_abort(
      message,
      class = c("supplement_error_profile", "supplement_error"),
      call = call,
      .envir = parent.frame()
    )
  }
  source <- lock_source(path)
  if (isFALSE(source)) {
    profile_error(c(
      "{.file renv/profile} in {.path {path}} is a folder or a file that cannot be opened.",
      "i" = "renv reads the name of the site's renv profile from its first line. Make it such a file, or delete it to use {.file renv.lock}."
    ))
  }
  if (is.null(source$profile)) {
    return(source)
  }
  if (!grepl("\\A[A-Za-z0-9_-][A-Za-z0-9._-]*\\z", source$profile, perl = TRUE, useBytes = TRUE)) {
    name <- show_text(source$profile)
    profile_error(c(
      "The renv profile name {.val {name}}, which {.field {source$from}} gives, cannot be written into a Dockerfile.",
      "i" = "Use a name of ASCII letters, digits, {.code .}, {.code _}, and {.code -} that does not start with {.code .}."
    ))
  }
  source
}

argument_error <- function(message, call = parent.frame(), .envir = parent.frame()) {
  cli::cli_abort(
    message,
    class = c("supplement_error_argument", "supplement_error"),
    call = call,
    .envir = .envir
  )
}

is_version_string <- function(x) {
  is.character(x) && length(x) == 1 && !is.na(x) && is_version(x)
}

# The R version and the renv version in the lockfile that `source`, from
# dockerfile_lock_source(), names in the site `path`.
read_lockfile_versions <- function(path, source, call = parent.frame()) {
  file <- file.path(path, source$file)
  # Docker matches names with letter case, so the profile's folder must
  # be listed under the exact name, also where the file system ignores
  # case. On Windows file.exists() is TRUE for a file link to a missing
  # file.
  found <- (is.null(source$profile) ||
              source$profile %in% list.files(file.path(path, "renv", "profiles"), all.files = TRUE)) &&
    file.exists(file) && !dir.exists(file) && (!is_link(file) || link_ends_on_file(file))
  if (!found) {
    hint <- if (is.null(source$profile)) {
      "Set up renv in the site first, as the part {.emph Recording R packages with renv} of {.file GUIDE.md} shows."
    } else {
      "Run {.code renv::snapshot()} in the site with the renv profile {.val {source$profile}} active."
    }
    cli::cli_abort(
      c("No {.file {source$file}} in {.path {path}}.", "i" = hint),
      class = c("supplement_error_no_file", "supplement_error"),
      call = call
    )
  }
  # `problem` and `hint` are part of the cli template, so their markup is
  # read.
  lockfile_error <- function(problem,
                             hint = "Run {.code renv::snapshot()} in the site to write it again.") {
    cli::cli_abort(
      c(paste("{.path {file}}", problem), "i" = hint),
      class = c("supplement_error_lockfile", "supplement_error"),
      call = call,
      .envir = parent.frame()
    )
  }
  bytes <- readBin(file, "raw", file.size(file))
  lock <- tryCatch(
    jsonlite::parse_json(rawToChar(bytes), simplifyVector = FALSE),
    error = function(e) NULL
  )
  if (!is_map(lock)) {
    lockfile_error("is not a JSON object.")
  }
  # jsonlite keeps both copies of a repeated key, and `[[` takes the
  # first, while renv may read another. So each key read here must appear
  # once in its object, checked before any value.
  repeated <- function(map, key) is_map(map) && sum(names(map) == key) > 1
  packages <- lock[["Packages"]]
  keys <- list(
    "R" = repeated(lock, "R"),
    "Packages" = repeated(lock, "Packages"),
    "R.Version" = repeated(lock[["R"]], "Version"),
    "Packages.renv" = repeated(packages, "renv"),
    "Packages.renv.Version" = is_map(packages) && repeated(packages[["renv"]], "Version")
  )
  for (key in names(keys)) {
    if (keys[[key]]) {
      lockfile_error("has the key {.field {key}} more than once.")
    }
  }
  r <- if (is_map(lock[["R"]])) lock[["R"]][["Version"]]
  if (!is_version_string(r)) {
    lockfile_error("has no R version of three whole numbers in {.field R.Version}.")
  }
  # rocker/r-ver images before R 4.0.0 have no /rocker_scripts.
  if (numeric_version(r) < "4.0.0") {
    lockfile_error(
      "records R {r}, and the Dockerfile needs R 4.0.0 or later.",
      "Rocker images for older R lack the scripts that the build runs."
    )
  }
  renv <- if (is_map(packages) && is_map(packages[["renv"]])) packages[["renv"]][["Version"]]
  if (!is_version_string(renv)) {
    lockfile_error(
      "has no renv version of three whole numbers in {.field Packages.renv.Version}.",
      "Install a released renv from CRAN, then run {.code renv::snapshot()} in the site."
    )
  }
  # Before 1.3.1, renv::sysreqs() reads the packages from the project's
  # code, which the build does not have, and before 1.1.2 it does not exist.
  if (numeric_version(renv) < "1.3.1") {
    lockfile_error(
      "records renv {renv}, and the Dockerfile needs renv 1.3.1 or later.",
      "Update renv, then run {.code renv::snapshot()} in the site."
    )
  }
  list(r = r, renv = renv)
}

# The lines of the Dockerfile, which reads the lockfile that `source`, from
# dockerfile_lock_source(), names.
dockerfile_text <- function(r, renv, quarto, digest, source) {
  from <- paste0("rocker/r-ver:", r, if (!is.null(digest)) paste0("@", digest))
  tarball <- sprintf("https://p3m.dev/cran/latest/src/contrib/Archive/renv/renv_%s.tar.gz", renv)
  lockfile <- source$file
  env <- c(
    "# renv installs the packages into a library under /opt/renv/library, with",
    "# its package cache off, and the site's renv/activate.R finds them there.",
    "ENV RENV_PATHS_LIBRARY=/opt/renv/library \\",
    "    RENV_CONFIG_CACHE_ENABLED=FALSE"
  )
  if (!is.null(source$profile)) {
    # renv keeps the library of a profile in a folder of its own, so the
    # restore and every render in the image need the profile active.
    env <- c(
      env[1:2],
      paste0("# RENV_PROFILE makes renv use the profile ", source$profile, " in the build and in"),
      "# each render, whatever the site's renv/profile names.",
      env[3],
      paste0(env[4], " \\"),
      paste0("    RENV_PROFILE=", source$profile)
    )
  }
  c(
    paste0("# Written by supplement::write_dockerfile() from ", lockfile, ". See"),
    "# ?supplement::write_dockerfile for how to build the image and render in it.",
    paste0("FROM ", from),
    "",
    env,
    "",
    paste0("RUN /rocker_scripts/install_quarto.sh ", quarto),
    "",
    paste0("# A temporary copy of renv ", renv, " installs the system packages that the R"),
    paste0("# packages need, then restores ", lockfile, ", renv itself included."),
    "WORKDIR /opt/renv",
    paste("COPY", lockfile, lockfile),
    "RUN apt-get update \\",
    "    && export DEBIAN_FRONTEND=noninteractive R_LIBS=/tmp/renv/library RENV_PATHS_ROOT=/tmp/renv/root \\",
    "    && mkdir -p \"$R_LIBS\" \\",
    paste0("    && Rscript -e 'install.packages(\"", tarball, "\", repos = NULL, type = \"source\"); library(renv)' \\"),
    "    && Rscript -e 'writeLines(as.character(unique(unlist(lapply(renv::sysreqs(report = FALSE, check = FALSE), `[[`, \"packages\")))), \"/tmp/renv/sysreqs.txt\")' \\",
    "    && xargs -r apt-get install -y --no-install-recommends < /tmp/renv/sysreqs.txt \\",
    "    && Rscript -e 'renv::restore(library = renv::paths$library(), prompt = FALSE)' \\",
    "    && rm -rf /tmp/renv /var/lib/apt/lists/*",
    "",
    "WORKDIR /site"
  )
}
