#' Write a Dockerfile from renv.lock
#'
#' `write_dockerfile()` reads `renv.lock` in a site set up with renv and
#' writes a `Dockerfile` and a `.dockerignore` into the same folder. The
#' image that Docker builds from them holds the R version and the R
#' packages that `renv.lock` records, and the Quarto version that you give.
#' You can then render a report in the image with the site folder mounted,
#' so that its code runs with those versions on another machine that runs
#' Docker with Linux containers on an amd64 processor, or on arm64 for R
#' 4.1.0 or later, the platforms of the Rocker images. supplement never
#' runs Docker itself.
#'
#' The `Dockerfile` starts from the Rocker image `rocker/r-ver` with the R
#' version in `renv.lock`, and installs Quarto with Rocker's
#' `install_quarto.sh`. It copies `renv.lock` into the image. It installs
#' the renv version that `renv.lock` records into a temporary library, uses
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
#' folder is as it was. A failed write can leave the `Dockerfile` written,
#' and either file empty or cut short. A file that cannot be opened for writing gives R's own error. The
#' other errors have the class `supplement_error` and one of these classes:
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
#'   versions. A renv version older than 1.3.1 is also this error.
#' * `supplement_error_file_exists`: `Dockerfile` or `.dockerignore`
#'   exists and `overwrite` is `FALSE`. A folder or a link at either path is
#'   this error even when `overwrite` is `TRUE`, because a write would
#'   follow the link.
#' * `supplement_error_write`: a file was opened, but writing it gave an
#'   error or a warning, or the file then has another size than the text.
#'
#' @seealso The template guide's parts "Recording R packages with renv"
#'   and "Running reports in a container".
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
  versions <- read_lockfile_versions(path)

  dockerfile <- file.path(path, "Dockerfile")
  dockerignore <- file.path(path, ".dockerignore")
  for (file in c(dockerfile, dockerignore)) {
    if (is_link(file)) {
      cli::cli_abort(
        "{.path {file}} is a link, so the file is not written there.",
        class = c("supplement_error_file_exists", "supplement_error")
      )
    }
    check_overwrite(file, overwrite)
  }

  write_utf8(dockerfile_text(versions$r, versions$renv, quarto, digest), dockerfile)
  write_utf8(c("*", "!renv.lock"), dockerignore)
  invisible(c(dockerfile, dockerignore))
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

# The R version and the renv version in `renv.lock` of `path`.
read_lockfile_versions <- function(path, call = parent.frame()) {
  file <- file.path(path, "renv.lock")
  if (!file.exists(file) || dir.exists(file)) {
    cli::cli_abort(
      c("No {.file renv.lock} in {.path {path}}.",
        "i" = "Set up renv in the site first, as the template guide's part {.emph Recording R packages with renv} shows."),
      class = c("supplement_error_no_file", "supplement_error"),
      call = call
    )
  }
  # `problem` is part of the cli template, so its markup is read.
  lockfile_error <- function(problem) {
    cli::cli_abort(
      c(paste("{.path {file}}", problem),
        "i" = "Run {.code renv::snapshot()} in the site to write it again."),
      class = c("supplement_error_lockfile", "supplement_error"),
      call = call
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
  r <- if (is_map(lock[["R"]])) lock[["R"]][["Version"]]
  if (!is_version_string(r)) {
    lockfile_error("has no R version of three whole numbers in {.field R.Version}.")
  }
  packages <- lock[["Packages"]]
  renv <- if (is_map(packages) && is_map(packages[["renv"]])) packages[["renv"]][["Version"]]
  if (!is_version_string(renv)) {
    lockfile_error("has no renv version of three whole numbers in {.field Packages.renv.Version}.")
  }
  # Before 1.3.1, renv::sysreqs() reads the packages from the project's
  # code, which the build does not have, and before 1.1.2 it does not exist.
  if (numeric_version(renv) < "1.3.1") {
    cli::cli_abort(
      c("{.path {file}} records renv {renv}, and the Dockerfile needs renv 1.3.1 or later.",
        "i" = "Update renv, then run {.code renv::snapshot()} in the site."),
      class = c("supplement_error_lockfile", "supplement_error"),
      call = call
    )
  }
  list(r = r, renv = renv)
}

# The lines of the Dockerfile.
dockerfile_text <- function(r, renv, quarto, digest) {
  from <- paste0("rocker/r-ver:", r, if (!is.null(digest)) paste0("@", digest))
  tarball <- sprintf("https://p3m.dev/cran/latest/src/contrib/Archive/renv/renv_%s.tar.gz", renv)
  c(
    "# Written by supplement::write_dockerfile() from renv.lock. See",
    "# ?supplement::write_dockerfile for how to build the image and render in it.",
    paste0("FROM ", from),
    "",
    "# renv installs the packages into a library in this folder, with its",
    "# package cache off, and the site's renv/activate.R finds them there.",
    "ENV RENV_PATHS_LIBRARY=/opt/renv/library \\",
    "    RENV_CONFIG_CACHE_ENABLED=FALSE",
    "",
    paste0("RUN /rocker_scripts/install_quarto.sh ", quarto),
    "",
    paste0("# A temporary copy of renv ", renv, " installs the system packages that the R"),
    "# packages need, then restores renv.lock, renv itself included.",
    "WORKDIR /opt/renv",
    "COPY renv.lock renv.lock",
    "RUN apt-get update \\",
    "    && export R_LIBS=/tmp/renv/library RENV_PATHS_ROOT=/tmp/renv/root \\",
    "    && mkdir -p \"$R_LIBS\" \\",
    paste0("    && Rscript -e 'install.packages(\"", tarball, "\", repos = NULL, type = \"source\")' \\"),
    "    && Rscript -e 'writeLines(as.character(unique(unlist(lapply(renv::sysreqs(report = FALSE, check = FALSE), `[[`, \"packages\")))), \"/tmp/renv/sysreqs.txt\")' \\",
    "    && xargs -r apt-get install -y --no-install-recommends < /tmp/renv/sysreqs.txt \\",
    "    && Rscript -e 'renv::restore(library = renv::paths$library(), prompt = FALSE)' \\",
    "    && rm -rf /tmp/renv /var/lib/apt/lists/*",
    "",
    "WORKDIR /site"
  )
}
