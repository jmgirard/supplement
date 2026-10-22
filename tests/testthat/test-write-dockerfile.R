# write_dockerfile() writes a Dockerfile and a .dockerignore from renv.lock.

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

# Expect write_dockerfile(...) to stop with `class` and to leave `dir`
# as it was.
expect_refused <- function(dir, class, ..., info = NULL) {
  before <- folder_md5(dir)
  expect_error(write_dockerfile(...), class = class, info = info)
  expect_identical(folder_md5(dir), before, info = info)
}

dockerfile_461 <- paste0(paste(c(
  "# Written by supplement::write_dockerfile() from renv.lock. See",
  "# ?supplement::write_dockerfile for how to build the image and render in it.",
  "FROM rocker/r-ver:4.6.1",
  "",
  "# renv installs the packages into a library in this folder, with its",
  "# package cache off, and the site's renv/activate.R finds them there.",
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
  "    && export R_LIBS=/tmp/renv/library RENV_PATHS_ROOT=/tmp/renv/root \\",
  "    && mkdir -p \"$R_LIBS\" \\",
  "    && Rscript -e 'install.packages(\"https://p3m.dev/cran/latest/src/contrib/Archive/renv/renv_1.3.1.tar.gz\", repos = NULL, type = \"source\")' \\",
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
  expect_false(any(read_bytes(file.path(site, "Dockerfile")) == as.raw(13)))
})

test_that("the R, renv, and Quarto versions come from renv.lock and the quarto argument", {
  site <- lock_site(lock_json(r = '{"Version": "4.5.2"}', renv = '{"Version": "1.10.0"}'))
  write_dockerfile(site, quarto = "1.9.37")
  lines <- readLines(file.path(site, "Dockerfile"))
  expect_identical(lines[[3]], "FROM rocker/r-ver:4.5.2")
  expect_identical(grep("install_quarto", lines, value = TRUE), "RUN /rocker_scripts/install_quarto.sh 1.9.37")
  expect_match(lines, "/renv_1.10.0.tar.gz", fixed = TRUE, all = FALSE)
  expect_match(lines, "copy of renv 1.10.0 ", fixed = TRUE, all = FALSE)
  expect_false(any(grepl("4.6.1|1.3.1|1.10.19", lines)))
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
  for (path in list(c(site, site), 1, NA_character_, "", file.path(site, "no-such-folder"), file)) {
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

test_that("a lockfile renv older than 1.3.1 is refused", {
  for (version in c("1.3.0", "1.2.0")) {
    site <- lock_site(lock_json(renv = sprintf('{"Version": "%s"}', version)))
    expect_refused(site, "supplement_error_lockfile", site, quarto = "1.10.19", info = version)
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

test_that("the image renders a report offline as the user, with the lockfile's R", {
  skip_if_not(identical(Sys.getenv("SUPPLEMENT_TEST_DOCKER"), "true"), "SUPPLEMENT_TEST_DOCKER is not true")
  skip_on_os("windows")
  skip_if(Sys.which("docker") == "", "docker is not on PATH")
  site <- long_dir(renv_site())
  r_version <- jsonlite::read_json(file.path(site, "renv.lock"))[["R"]][["Version"]]
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
  # The library in the image, so the section is from the render in Docker.
  expect_match(section, "/opt/renv/library/", fixed = TRUE)

  unlink(site, recursive = TRUE)
  expect_false(dir.exists(site))
})

test_that("a link at either path is refused, with overwrite TRUE and FALSE", {
  skip_on_os("windows")
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
        skip_if_not(file.symlink(targets[[shape]], file.path(site, file)), "cannot make a symbolic link here")
        before <- folder_md5(outside)
        info <- paste(file, overwrite, shape)
        expect_refused(site, "supplement_error_file_exists", site, quarto = "1.10.19",
                       overwrite = overwrite, info = info)
        expect_identical(folder_md5(outside), before, info = info)
        expect_false(file.exists(file.path(outside, "missing")), info = info)
      }
    }
  }
})
