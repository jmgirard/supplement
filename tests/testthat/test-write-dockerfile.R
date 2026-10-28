# write_dockerfile() writes a Dockerfile and a .dockerignore from renv.lock or the lockfile of an renv profile.

# A RENV_PROFILE of the session that runs the tests picks another lockfile.
withr::local_envvar(RENV_PROFILE = NA)

# The text of a renv.lock with `r` as the value of `R` and `renv` as the
# renv entry under `Packages`, each given as JSON text.
lock_json <- function(r = '{"Version": "4.6.1"}',
                      renv = '{"Package": "renv", "Version": "1.3.1"}') {
  sprintf('{\n  "R": %s,\n  "Packages": {\n    "knitr": {"Package": "knitr", "Version": "1.52"},\n    "renv": %s\n  }\n}\n', r, renv)
}

# A site folder that holds `text` as renv.lock, or no renv.lock when
# `text` is NULL.
lock_site <- function(text = lock_json(), env = parent.frame()) {
  dir <- withr::local_tempdir("docker-site-", .local_envir = env)
  if (!is.null(text)) writeBin(charToRaw(text), file.path(dir, "renv.lock"))
  dir
}

read_bytes <- function(path) readBin(path, "raw", file.size(path))

# Expect write_dockerfile(...) to stop with `class`, to print no message,
# and to leave `dir` as it was. Returns the error.
expect_refused <- function(dir, class, ..., info = NULL) {
  before <- folder_md5(dir)
  messages <- character()
  err <- withCallingHandlers(
    expect_error(write_dockerfile(...), class = class, info = info),
    message = function(m) {
      messages <<- c(messages, conditionMessage(m))
      invokeRestart("muffleMessage")
    }
  )
  expect_identical(messages, character(), info = info)
  expect_identical(folder_md5(dir), before, info = info)
  invisible(err)
}

dockerfile_461 <- paste0(paste(c(
  "# Written by supplement::write_dockerfile() from renv.lock. See",
  "# ?supplement::write_dockerfile for how to build the image and render in it.",
  "FROM rocker/r-ver:4.6.1",
  "",
  "# renv installs the packages into a library under /opt/renv/library, with",
  "# its package cache off, and the site's renv/activate.R finds them there.",
  "ENV RENV_PATHS_LIBRARY=/opt/renv/library \\",
  "    RENV_CONFIG_CACHE_ENABLED=FALSE",
  "",
  "RUN /rocker_scripts/install_quarto.sh 1.10.19",
  "",
  "# A temporary copy of renv 1.3.1 installs the system packages that the R",
  "# packages need, then restores renv.lock, renv itself included.",
  "WORKDIR /opt/renv",
  "COPY renv.lock renv.lock",
  "RUN apt-get update \\",
  "    && export DEBIAN_FRONTEND=noninteractive R_LIBS=/tmp/renv/library RENV_PATHS_ROOT=/tmp/renv/root \\",
  "    && mkdir -p \"$R_LIBS\" \\",
  "    && Rscript -e 'install.packages(\"https://p3m.dev/cran/latest/src/contrib/Archive/renv/renv_1.3.1.tar.gz\", repos = NULL, type = \"source\"); library(renv)' \\",
  "    && Rscript -e 'writeLines(as.character(unique(unlist(lapply(renv::sysreqs(report = FALSE, check = FALSE), `[[`, \"packages\")))), \"/tmp/renv/sysreqs.txt\")' \\",
  "    && xargs -r apt-get install -y --no-install-recommends < /tmp/renv/sysreqs.txt \\",
  "    && Rscript -e 'renv::restore(library = renv::paths$library(), prompt = FALSE)' \\",
  "    && rm -rf /tmp/renv /var/lib/apt/lists/*",
  "",
  "WORKDIR /site"
), collapse = "\n"), "\n")

test_that("the Dockerfile and .dockerignore have the expected bytes", {
  site <- lock_site()
  written <- write_dockerfile(site, quarto = "1.10.19")
  expect_identical(written, file.path(site, c("Dockerfile", ".dockerignore")))
  expect_identical(read_bytes(file.path(site, "Dockerfile")), charToRaw(dockerfile_461))
  expect_identical(read_bytes(file.path(site, ".dockerignore")), charToRaw("*\n!renv.lock\n"))
})

test_that("the R, renv, and Quarto versions come from renv.lock and the quarto argument", {
  site <- lock_site(lock_json(r = '{"Version": "4.5.2"}', renv = '{"Version": "1.10.0"}'))
  write_dockerfile(site, quarto = "1.9.37")
  lines <- readLines(file.path(site, "Dockerfile"))
  expect_identical(lines[[3]], "FROM rocker/r-ver:4.5.2")
  expect_identical(grep("install_quarto", lines, value = TRUE), "RUN /rocker_scripts/install_quarto.sh 1.9.37")
  expect_match(lines, "/renv_1.10.0.tar.gz", fixed = TRUE, all = FALSE)
  expect_match(lines, "copy of renv 1.10.0 ", fixed = TRUE, all = FALSE)
  for (version in c("4.6.1", "1.3.1", "1.10.19")) {
    expect_false(any(grepl(version, lines, fixed = TRUE)), info = version)
  }
})

test_that("a digest pins the base image", {
  site <- lock_site()
  digest <- paste0("sha256:", strrep("0123456789abcdef", 4))
  write_dockerfile(site, quarto = "1.10.19", digest = digest)
  lines <- readLines(file.path(site, "Dockerfile"))
  expect_identical(lines[[3]], paste0("FROM rocker/r-ver:4.6.1@", digest))
  expect_identical(lines[-3], strsplit(dockerfile_461, "\n")[[1]][-3])
})

test_that("overwrite = TRUE replaces both files", {
  site <- lock_site()
  for (file in c("Dockerfile", ".dockerignore")) writeBin(charToRaw("old\n"), file.path(site, file))
  write_dockerfile(site, quarto = "1.10.19", overwrite = TRUE)
  expect_identical(read_bytes(file.path(site, "Dockerfile")), charToRaw(dockerfile_461))
  expect_identical(read_bytes(file.path(site, ".dockerignore")), charToRaw("*\n!renv.lock\n"))
})

test_that("a path that is not one folder is refused", {
  site <- lock_site()
  file <- file.path(site, "renv.lock")
  for (path in list(c(site, site), file.path(site, "no-such-folder"), file)) {
    expect_refused(site, "supplement_error_argument", path, quarto = "1.10.19", info = format(path))
  }
})

test_that("a missing quarto argument is refused", {
  site <- lock_site()
  expect_refused(site, "supplement_error_argument", site)
})

test_that("a site with no renv.lock is refused", {
  site <- lock_site(NULL)
  expect_refused(site, "supplement_error_no_file", site, quarto = "1.10.19")
  dir.create(file.path(site, "renv.lock"))
  expect_refused(site, "supplement_error_no_file", site, quarto = "1.10.19")
})

test_that("a renv.lock under another letter case is refused", {
  for (name in c("Renv.lock", "RENV.LOCK")) {
    site <- lock_site(NULL)
    writeBin(charToRaw(lock_json()), file.path(site, name))
    err <- expect_refused(site, "supplement_error_no_file", site, quarto = "1.10.19", info = name)
    expect_match(conditionMessage(err), "No 'renv.lock' in", fixed = TRUE, info = name)
    # Where the file system ignores letter case, renv.lock is found under
    # the other case, and the hint says so.
    hint <- if (ignores_case(site)) "is listed under another spelling" else "Set up renv in the site first"
    expect_match(conditionMessage(err), hint, fixed = TRUE, info = name)
  }
})

test_that("a renv.lock that does not have the lockfile form is refused", {
  texts <- list(
    empty = "",
    truncated = substr(lock_json(), 1, 40),
    array = "[1, 2]\n",
    scalar = "\"4.6.1\"\n",
    "no R" = '{"Packages": {"renv": {"Version": "1.3.1"}}}\n',
    "R a string" = lock_json(r = '"4.6.1"'),
    "no R.Version" = lock_json(r = '{"Repositories": []}'),
    "R.Version a number" = lock_json(r = '{"Version": 4.6}'),
    "R.Version an array" = lock_json(r = '{"Version": ["4.6.1"]}'),
    "R.Version empty" = lock_json(r = '{"Version": ""}'),
    "no renv" = '{"R": {"Version": "4.6.1"}, "Packages": {"knitr": {"Version": "1.52"}}}\n',
    "renv with no Version" = lock_json(renv = '{"Package": "renv"}')
  )
  for (name in names(texts)) {
    site <- lock_site(texts[[name]])
    expect_refused(site, "supplement_error_lockfile", site, quarto = "1.10.19", info = name)
  }
})

bad_versions <- list("4.6", "4.6.1.1", " 4.6.1", "4.6.1\n", "1.1.5.9000", NA, c("4.6.1", "4.6.1"), 4.6)

test_that("a lockfile R or renv version that is not three whole numbers is refused", {
  for (version in bad_versions) {
    json <- if (length(version) == 1 && is.na(version)) "null" else jsonlite::toJSON(version, auto_unbox = TRUE)
    info <- format(json)
    site <- lock_site(lock_json(r = sprintf('{"Version": %s}', json)))
    expect_refused(site, "supplement_error_lockfile", site, quarto = "1.10.19", info = info)
    site <- lock_site(lock_json(renv = sprintf('{"Version": %s}', json)))
    expect_refused(site, "supplement_error_lockfile", site, quarto = "1.10.19", info = info)
  }
})

test_that("a lockfile R older than 4.0.0 or renv older than 1.3.1 is refused", {
  site <- lock_site(lock_json(r = '{"Version": "3.6.3"}'))
  expect_refused(site, "supplement_error_lockfile", site, quarto = "1.10.19")
  site <- lock_site(lock_json(renv = '{"Version": "1.3.0"}'))
  expect_refused(site, "supplement_error_lockfile", site, quarto = "1.10.19")
})

test_that("a lockfile that repeats a key it reads is refused before its values, and one it does not read is not", {
  packages <- function(renv_version) {
    sprintf('{"knitr": {"Package": "knitr", "Version": "1.52"}, "renv": {"Package": "renv", "Version": "%s"}}',
            renv_version)
  }
  renv_twice <- '{"Package": "renv", "Version": "1.3.1"},\n    "renv": {"Package": "renv", "Version": "1.3.2"}'
  version_twice <- '{"Package": "renv", "Version": "1.3.1", "Version": "1.3.2"}'
  texts <- list(
    "R" = sprintf('{"R": {"Version": "4.6.1"}, "R": {"Version": "4.5.0"}, "Packages": %s}', packages("1.3.1")),
    "R, the same value twice" = sprintf('{"R": {"Version": "4.6.1"}, "R": {"Version": "4.6.1"}, "Packages": %s}',
                                        packages("1.3.1")),
    "Packages" = sprintf('{"R": {"Version": "4.6.1"}, "Packages": %s, "Packages": %s}',
                         packages("1.3.1"), packages("1.3.2")),
    "R.Version" = lock_json(r = '{"Version": "4.6.1", "Version": "4.5.0"}'),
    "Packages.renv" = lock_json(renv = renv_twice),
    "Packages.renv.Version" = lock_json(renv = version_twice),
    "Packages.renv.Version, with R 3.6.0" = lock_json(r = '{"Version": "3.6.0"}', renv = version_twice)
  )
  for (name in names(texts)) {
    key <- sub(",.*", "", name)
    site <- lock_site(texts[[name]])
    err <- expect_refused(site, "supplement_error_lockfile", site, quarto = "1.10.19", info = name)
    expect_match(conditionMessage(err), paste0(key, "\\W+more\\s+than\\s+once"), info = name)
  }

  cli_twice <- paste0('{"Package": "renv", "Version": "1.3.1"},\n',
                      '    "cli": {"Package": "cli", "Version": "3.6.4"},\n',
                      '    "cli": {"Package": "cli", "Version": "3.6.5"}')
  site <- lock_site(lock_json(renv = cli_twice))
  write_dockerfile(site, quarto = "1.10.19")
  expect_match(read_text(file.path(site, "Dockerfile")), "FROM rocker/r-ver:4.6.1\n", fixed = TRUE)
})

test_that("errors name write_dockerfile() as the call", {
  site <- lock_site()
  calls <- list(
    argument = function() write_dockerfile(site, quarto = "1.10"),
    lockfile = function() write_dockerfile(lock_site("[]"), quarto = "1.10.19"),
    renv = function() write_dockerfile(lock_site(lock_json(renv = '{"Version": "1.3.0"}')), quarto = "1.10.19"),
    no_file = function() write_dockerfile(lock_site(NULL), quarto = "1.10.19"),
    folder = function() {
      dir.create(file.path(site, "Dockerfile"))
      on.exit(unlink(file.path(site, "Dockerfile"), recursive = TRUE, expand = FALSE))
      write_dockerfile(site, quarto = "1.10.19")
    }
  )
  for (name in names(calls)) {
    err <- tryCatch(calls[[name]](), supplement_error = identity)
    expect_s3_class(err, "supplement_error")
    expect_identical(conditionCall(err)[[1]], quote(write_dockerfile), info = name)
  }
})

test_that("a quarto version that is not three whole numbers is refused", {
  site <- lock_site()
  for (version in bad_versions) {
    expect_refused(site, "supplement_error_argument", site, quarto = version, info = format(version))
  }
})

test_that("a digest that is not sha256: and 64 lowercase hex digits is refused", {
  site <- lock_site()
  hex <- strrep("0123456789abcdef", 4)
  digests <- list(
    paste0("sha256:", substr(hex, 1, 63)),
    paste0("sha256:", toupper(hex)),
    hex,
    paste0("sha256:", hex, "\n"),
    NA, c(paste0("sha256:", hex), paste0("sha256:", hex)), 1
  )
  for (digest in digests) {
    expect_refused(site, "supplement_error_argument", site, quarto = "1.10.19", digest = digest,
                   info = format(digest))
  }
})

test_that("an overwrite that is not TRUE or FALSE is refused", {
  site <- lock_site()
  for (overwrite in list(NA, "TRUE", c(TRUE, TRUE))) {
    expect_refused(site, "supplement_error_argument", site, quarto = "1.10.19", overwrite = overwrite,
                   info = format(overwrite))
  }
})

test_that("an existing Dockerfile or .dockerignore is kept unless overwrite = TRUE", {
  for (file in c("Dockerfile", ".dockerignore")) {
    site <- lock_site()
    writeBin(charToRaw("old\n"), file.path(site, file))
    expect_refused(site, "supplement_error_file_exists", site, quarto = "1.10.19", info = file)
  }
})

test_that("a folder at either path is refused, with overwrite TRUE and FALSE", {
  for (file in c("Dockerfile", ".dockerignore")) {
    for (overwrite in c(FALSE, TRUE)) {
      site <- lock_site()
      dir.create(file.path(site, file))
      writeBin(charToRaw("inside\n"), file.path(site, file, "kept.txt"))
      expect_refused(site, "supplement_error_file_exists", site, quarto = "1.10.19",
                     overwrite = overwrite, info = paste(file, overwrite))
    }
  }
})

# Build an image from the renv site `site`, whose lockfile is at `lockfile`,
# render the example report in it offline as the user, and check the
# Computing environment section of the page. Returns the section's text.
expect_docker_render <- function(site, lockfile = "renv.lock") {
  r_version <- jsonlite::read_json(file.path(site, lockfile))[["R"]][["Version"]]
  manifest <- run_in(site, "docker", c("manifest", "inspect", paste0("rocker/r-ver:", r_version)))
  skip_if(manifest$status != 0L, paste0("no rocker/r-ver:", r_version, " image"))

  quarto <- run_in(site, "quarto", "--version")
  expect_status(quarto)
  write_dockerfile(site, quarto = trimws(utils::tail(quarto$output, 1)))
  image <- paste0("supplement-test-", tolower(gsub("[^A-Za-z0-9]", "", basename(site))))
  withr::defer(run_in(tempdir(), "docker", c("image", "rm", "-f", image)))
  expect_status(run_in(site, "docker", c("build", "-t", image, ".")))

  user <- paste0(run_in(site, "id", "-u")$output, ":", run_in(site, "id", "-g")$output)
  rendered <- run_in(site, "docker", c(
    "run", "--rm", "--network", "none", "--user", user, "-e", "HOME=/tmp",
    "-v", paste0(site, ":/site"), image, "quarto", "render", "analyses/example.qmd"
  ))
  expect_status(rendered)
  page <- paste(readLines(file.path(site, "docs", "analyses", "example.html"), warn = FALSE), collapse = "\n")
  section <- html_text(section_html(page, "computing-environment"))
  expect_match(section, paste0("R version ", r_version, " "), fixed = TRUE)

  unlink(site, recursive = TRUE, expand = FALSE)
  expect_false(dir.exists(site))
  section
}

skip_if_no_docker <- function() {
  skip_if_not(identical(Sys.getenv("SUPPLEMENT_TEST_DOCKER"), "true"), "SUPPLEMENT_TEST_DOCKER is not true")
  skip_on_os("windows")
  skip_if(Sys.which("docker") == "", "docker is not on PATH")
}

test_that("the image renders a report offline as the user, with the lockfile's R", {
  skip_if_no_docker()
  section <- expect_docker_render(long_dir(renv_site()))
  # The library in the image, so the section is from the render in Docker.
  expect_match(section, "/opt/renv/library/", fixed = TRUE)
})

test_that("the image of a renv profile restores and renders with the profile's lockfile", {
  skip_if_no_docker()
  site <- long_dir(renv_site())
  lockfile <- "renv/profiles/docker/renv.lock"
  dir.create(file.path(site, dirname(lockfile)), recursive = TRUE)
  expect_true(file.rename(file.path(site, "renv.lock"), file.path(site, lockfile)))
  writeLines("docker", file.path(site, "renv", "profile"))
  section <- expect_docker_render(site, lockfile)
  expect_match(section, "/opt/renv/library/profiles/docker/", fixed = TRUE)
})

test_that("a link at either path is refused, with overwrite TRUE and FALSE", {
  outside <- withr::local_tempdir("docker-outside-")
  writeBin(charToRaw("target\n"), file.path(outside, "target.txt"))
  targets <- c(
    "a link to a file" = file.path(outside, "target.txt"),
    "a link to a folder" = outside,
    "a broken link" = file.path(outside, "missing")
  )
  for (file in c("Dockerfile", ".dockerignore")) {
    for (overwrite in c(FALSE, TRUE)) {
      for (shape in names(targets)) {
        site <- lock_site()
        symlink_or_skip(targets[[shape]], file.path(site, file))
        info <- paste(file, overwrite, shape)
        err <- expect_refused(site, "supplement_error_file_exists", site, quarto = "1.10.19",
                              overwrite = overwrite, info = info)
        expect_link_message(err, "write_dockerfile", info = info)
      }
    }
  }
  # Links at both targets are checked before any existing file.
  site <- lock_site()
  writeBin(charToRaw("old\n"), file.path(site, "Dockerfile"))
  symlink_or_skip(targets[["a link to a file"]], file.path(site, ".dockerignore"))
  err <- expect_refused(site, "supplement_error_file_exists", site, quarto = "1.10.19")
  expect_link_message(err, "write_dockerfile")
  expect_match(conditionMessage(err), ".dockerignore", fixed = TRUE)
})

# renv profiles ---------------------------------------------------------------

# Write `name`, given as text or raw bytes, as the first line of
# renv/profile in `site`.
write_profile_name <- function(site, name) {
  bytes <- if (is.raw(name)) name else charToRaw(name)
  dir.create(file.path(site, "renv"), showWarnings = FALSE)
  writeBin(c(bytes, as.raw(0x0a)), file.path(site, "renv", "profile"))
}

# Write `text` as the lockfile of the renv profile `name` in `site`.
write_profile_lock <- function(site, name, text = lock_json(r = '{"Version": "4.5.2"}')) {
  dir.create(file.path(site, "renv", "profiles", name), recursive = TRUE, showWarnings = FALSE)
  writeBin(charToRaw(text), file.path(site, "renv", "profiles", name, "renv.lock"))
}

# TRUE when RENV_PROFILE can hold `text` on this system.
can_set_profile <- function(text) {
  isTRUE(tryCatch(withr::with_envvar(c(RENV_PROFILE = text), Sys.getenv("RENV_PROFILE") == text),
                  error = function(e) FALSE, warning = function(w) FALSE))
}

# The messages that write_dockerfile(...) prints, without ANSI codes or
# Unicode.
dockerfile_messages <- function(...) {
  withr::local_options(cli.unicode = FALSE, cli.num_colors = 1, cli.hyperlink = FALSE)
  messages <- character()
  withCallingHandlers(write_dockerfile(...), message = function(m) {
    messages <<- c(messages, conditionMessage(m))
    invokeRestart("muffleMessage")
  })
  messages
}

dockerfile_dev <- paste0(paste(c(
  "# Written by supplement::write_dockerfile() from renv/profiles/dev/renv.lock. See",
  "# ?supplement::write_dockerfile for how to build the image and render in it.",
  "FROM rocker/r-ver:4.5.2",
  "",
  "# renv installs the packages into a library under /opt/renv/library, with",
  "# its package cache off, and the site's renv/activate.R finds them there.",
  "# RENV_PROFILE makes renv use the profile dev in the build and in",
  "# each render, whatever the site's renv/profile names.",
  "ENV RENV_PATHS_LIBRARY=/opt/renv/library \\",
  "    RENV_CONFIG_CACHE_ENABLED=FALSE \\",
  "    RENV_PROFILE=dev",
  "",
  "RUN /rocker_scripts/install_quarto.sh 1.10.19",
  "",
  "# A temporary copy of renv 1.3.1 installs the system packages that the R",
  "# packages need, then restores renv/profiles/dev/renv.lock, renv itself included.",
  "WORKDIR /opt/renv",
  "COPY renv/profiles/dev/renv.lock renv/profiles/dev/renv.lock",
  "RUN apt-get update \\",
  "    && export DEBIAN_FRONTEND=noninteractive R_LIBS=/tmp/renv/library RENV_PATHS_ROOT=/tmp/renv/root \\",
  "    && mkdir -p \"$R_LIBS\" \\",
  "    && Rscript -e 'install.packages(\"https://p3m.dev/cran/latest/src/contrib/Archive/renv/renv_1.3.1.tar.gz\", repos = NULL, type = \"source\"); library(renv)' \\",
  "    && Rscript -e 'writeLines(as.character(unique(unlist(lapply(renv::sysreqs(report = FALSE, check = FALSE), `[[`, \"packages\")))), \"/tmp/renv/sysreqs.txt\")' \\",
  "    && xargs -r apt-get install -y --no-install-recommends < /tmp/renv/sysreqs.txt \\",
  "    && Rscript -e 'renv::restore(library = renv::paths$library(), prompt = FALSE)' \\",
  "    && rm -rf /tmp/renv /var/lib/apt/lists/*",
  "",
  "WORKDIR /site"
), collapse = "\n"), "\n")

test_that("with no renv profile, renv.lock is read and no message is printed", {
  # Each case: the RENV_PROFILE value (NA to unset it) and the bytes of
  # renv/profile (NULL for no file). Each site also has a profile lockfile
  # for dev, which none of them picks.
  cases <- list(
    "no profile" = list(NA, NULL),
    "RENV_PROFILE default" = list("default", charToRaw("dev\n")),
    "default in renv/profile" = list(NA, charToRaw("default\n")),
    "empty renv/profile" = list(NA, raw()),
    "empty first line" = list(NA, charToRaw("\ndev\n"))
  )
  for (case in names(cases)) {
    site <- lock_site()
    write_profile_lock(site, "dev")
    if (!is.null(cases[[case]][[2]])) writeBin(cases[[case]][[2]], file.path(site, "renv", "profile"))
    messages <- withr::with_envvar(c(RENV_PROFILE = cases[[case]][[1]]),
                                   dockerfile_messages(site, quarto = "1.10.19"))
    expect_identical(messages, character(), info = case)
    expect_identical(read_bytes(file.path(site, "Dockerfile")), charToRaw(dockerfile_461), info = case)
    expect_identical(read_bytes(file.path(site, ".dockerignore")), charToRaw("*\n!renv.lock\n"), info = case)
  }
})

test_that("with a renv profile, its lockfile is read, copied, and named in a message", {
  for (from in c("RENV_PROFILE", "renv/profile")) {
    site <- lock_site()
    write_profile_lock(site, "dev")
    if (from == "RENV_PROFILE") {
      withr::local_envvar(RENV_PROFILE = "dev")
      source <- "`RENV_PROFILE`"
    } else {
      withr::local_envvar(RENV_PROFILE = NA)
      write_profile_name(site, "dev")
      source <- "'renv/profile'"
    }
    messages <- dockerfile_messages(site, quarto = "1.10.19")
    expect_identical(messages, paste0(
      "i Picked 'renv/profiles/dev/renv.lock', the lockfile of the renv profile \"dev\", which ",
      source, " names.\n"
    ), info = from)
    # renv.lock records R 4.6.1 and the profile lockfile R 4.5.2.
    expect_identical(read_bytes(file.path(site, "Dockerfile")), charToRaw(dockerfile_dev), info = from)
    expect_identical(read_bytes(file.path(site, ".dockerignore")),
                     charToRaw("*\n!renv/profiles/dev/renv.lock\n"), info = from)
  }
})

test_that("the message and the name error name both sources when they give the same name", {
  # Each shape of renv/profile beside RENV_PROFILE "dev", and the sources
  # that the message then names.
  alone <- "`RENV_PROFILE` names"
  shapes <- list(
    "the same name" = list(function(site) write_profile_name(site, "dev"), "`RENV_PROFILE` and 'renv/profile' both name"),
    "no renv/profile" = list(function(site) NULL, alone),
    "an empty renv/profile" = list(function(site) write_profile_name(site, raw()), alone),
    "another name" = list(function(site) write_profile_name(site, "other"), alone),
    "a folder" = list(function(site) dir.create(file.path(site, "renv", "profile"), recursive = TRUE), alone)
  )
  withr::local_envvar(RENV_PROFILE = "dev")
  for (shape in names(shapes)) {
    site <- lock_site()
    write_profile_lock(site, "dev")
    shapes[[shape]][[1]](site)
    messages <- dockerfile_messages(site, quarto = "1.10.19")
    expect_identical(messages, paste0(
      "i Picked 'renv/profiles/dev/renv.lock', the lockfile of the renv profile \"dev\", which ",
      shapes[[shape]][[2]], ".\n"
    ), info = shape)
    expect_identical(read_bytes(file.path(site, "Dockerfile")), charToRaw(dockerfile_dev), info = shape)
  }

  withr::local_options(cli.unicode = FALSE, cli.num_colors = 1)
  site <- lock_site()
  write_profile_name(site, "a b")
  err <- withr::with_envvar(c(RENV_PROFILE = "a b"),
                            expect_refused(site, "supplement_error_profile", site, quarto = "1.10.19"))
  expect_match(conditionMessage(err), "which `RENV_PROFILE` and 'renv/profile' both give", fixed = TRUE)
})

test_that("a lockfile that starts with a UTF-8 byte order mark is read with no warning", {
  bom <- as.raw(c(0xef, 0xbb, 0xbf))
  for (profile in c(FALSE, TRUE)) {
    site <- lock_site()
    if (profile) {
      write_profile_name(site, "dev")
      lock <- file.path(site, "renv", "profiles", "dev", "renv.lock")
      dir.create(dirname(lock), recursive = TRUE)
      writeBin(c(bom, charToRaw(lock_json(r = '{"Version": "4.5.2"}'))), lock)
    } else {
      writeBin(c(bom, charToRaw(lock_json())), file.path(site, "renv.lock"))
    }
    expect_no_warning(dockerfile_messages(site, quarto = "1.10.19"))
    expect_identical(read_bytes(file.path(site, "Dockerfile")),
                     charToRaw(if (profile) dockerfile_dev else dockerfile_461), info = profile)
    expect_identical(read_bytes(file.path(site, ".dockerignore")),
                     charToRaw(if (profile) "*\n!renv/profiles/dev/renv.lock\n" else "*\n!renv.lock\n"), info = profile)
  }
})

test_that("the lockfile checks apply to the lockfile of the renv profile", {
  site <- lock_site()
  write_profile_name(site, "dev")
  write_profile_lock(site, "dev", lock_json(r = '{"Version": "3.6.3"}'))
  err <- expect_refused(site, "supplement_error_lockfile", site, quarto = "1.10.19")
  expect_match(conditionMessage(err), "renv/profiles/dev/renv.lock", fixed = TRUE)
  expect_match(conditionMessage(err), "records R 3.6.3", fixed = TRUE)
  writeBin(charToRaw("[]"), file.path(site, "renv", "profiles", "dev", "renv.lock"))
  err <- expect_refused(site, "supplement_error_lockfile", site, quarto = "1.10.19")
  expect_match(conditionMessage(err), 'with the renv profile "dev" active', fixed = TRUE)
})

test_that("a renv profile name that a Dockerfile cannot hold is refused", {
  names <- list(
    ".dev", "..", "a/b", "a\\b", "a b", "a\tb", "dev ", "a\"b", "a$b", "a*b", "\u00e9",
    as.raw(c(0x63, 0x61, 0x66, 0xe9))
  )
  unstored <- character()
  for (name in names) {
    info <- paste(format(name), collapse = " ")
    site <- lock_site()
    write_profile_name(site, name)
    expect_refused(site, "supplement_error_profile", site, quarto = "1.10.19", info = info)
    unlink(file.path(site, "renv"), recursive = TRUE)
    text <- if (is.raw(name)) rawToChar(name) else name
    if (can_set_profile(text)) {
      withr::with_envvar(c(RENV_PROFILE = text), {
        expect_refused(site, "supplement_error_profile", site, quarto = "1.10.19", info = info)
      })
    } else {
      unstored <- c(unstored, info)
    }
  }
  # renv/profile ends a name at a line break, and in a UTF-8 locale
  # readLines() drops a byte order mark from it, as for renv, so
  # RENV_PROFILE alone can hold either.
  site <- lock_site()
  write_profile_lock(site, "dev")
  for (name in c("dev\n", "dev\r", "a\nb", "\ufeffdev")) {
    withr::with_envvar(c(RENV_PROFILE = name), {
      err <- expect_refused(site, "supplement_error_profile", site, quarto = "1.10.19", info = name)
    })
    expect_match(conditionMessage(err), "RENV_PROFILE", fixed = TRUE, info = name)
  }
  skip_if(length(unstored) > 0,
          paste("RENV_PROFILE cannot hold these names here:", paste(unstored, collapse = ", ")))
})

test_that("a renv profile name of each allowed character passes", {
  for (name in c("Dev-2.a_b", "-a", "_x")) {
    site <- lock_site()
    write_profile_lock(site, name)
    write_profile_name(site, name)
    dockerfile_messages(site, quarto = "1.10.19")
    expect_identical(read_bytes(file.path(site, ".dockerignore")),
                     charToRaw(paste0("*\n!renv/profiles/", name, "/renv.lock\n")), info = name)
  }
})

test_that("a renv/profile that is a folder or cannot be opened is refused", {
  site <- lock_site()
  write_profile_lock(site, "dev")
  dir.create(file.path(site, "renv", "profile"))
  expect_refused(site, "supplement_error_profile", site, quarto = "1.10.19")

  unlink(file.path(site, "renv", "profile"), recursive = TRUE)
  skip_on_os("windows")
  write_profile_name(site, "dev")
  Sys.chmod(file.path(site, "renv", "profile"), "000")
  withr::defer(Sys.chmod(file.path(site, "renv", "profile"), "644"))
  skip_if(file.access(file.path(site, "renv", "profile"), 4) == 0, "the file can still be read, for example as root")
  expect_refused(site, "supplement_error_profile", site, quarto = "1.10.19")
})

test_that("a missing lockfile of the renv profile is refused, also under another letter case", {
  shapes <- list(
    "no profile folder" = function(site) NULL,
    "another letter case" = function(site) write_profile_lock(site, "Dev"),
    "a lockfile name in another letter case" = function(site) {
      write_profile_lock(site, "dev")
      file.rename(file.path(site, "renv", "profiles", "dev", "renv.lock"),
                  file.path(site, "renv", "profiles", "dev", "RENV.LOCK"))
    },
    "a profiles folder in another letter case" = function(site) {
      write_profile_lock(site, "dev")
      file.rename(file.path(site, "renv", "profiles"), file.path(site, "renv", "Profiles"))
    },
    "no lockfile in the folder" = function(site) dir.create(file.path(site, "renv", "profiles", "dev"), recursive = TRUE),
    "a folder at the lockfile" = function(site) {
      dir.create(file.path(site, "renv", "profiles", "dev", "renv.lock"), recursive = TRUE)
    },
    "a link to a missing file" = function(site) {
      dir.create(file.path(site, "renv", "profiles", "dev"), recursive = TRUE)
      symlink_or_skip(file.path(site, "missing.lock"), file.path(site, "renv", "profiles", "dev", "renv.lock"))
    }
  )
  for (shape in names(shapes)) {
    site <- lock_site()
    write_profile_name(site, "dev")
    shapes[[shape]](site)
    err <- expect_refused(site, "supplement_error_no_file", site, quarto = "1.10.19", info = shape)
    expect_match(conditionMessage(err), "No 'renv/profiles/dev/renv.lock' in", fixed = TRUE, info = shape)
    # Where the file system ignores letter case, the path of a case shape is
    # found under another case, and the hint says so.
    if (grepl("letter case", shape, fixed = TRUE) && ignores_case(site)) {
      expect_match(conditionMessage(err), "is listed under another spelling", fixed = TRUE, info = shape)
    } else {
      expect_match(conditionMessage(err), "renv::snapshot()", fixed = TRUE, info = shape)
    }
  }
})
