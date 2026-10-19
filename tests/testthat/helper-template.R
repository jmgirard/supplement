# Helpers for tests that build a site from the template with the Quarto CLI.

skip_if_no_quarto <- function(needs_r = TRUE) {
  skip_on_cran()
  skip_if(Sys.which("quarto") == "", "quarto is not on PATH")
  if (needs_r) {
    skip_if_not_installed("knitr")
    skip_if_not_installed("rmarkdown")
  }
}

skip_if_no_git <- function() {
  skip_if(Sys.which("git") == "", "git is not on PATH")
  # A git that cannot run, such as the macOS git before the Xcode license
  # is accepted, counts as no git.
  status <- suppressWarnings(system2("git", "--version", stdout = FALSE, stderr = FALSE))
  skip_if(status != 0L, "git --version fails")
}

template_dir <- function() {
  system.file("template", package = "supplement", mustWork = TRUE)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# The folder in its long form. On Windows the temporary folder can hold an
# 8.3 short name such as RUNNER~1, and Quarto run from such a folder does
# not find the figures that knitr writes, so they never reach docs/.
long_dir <- function(dir) normalizePath(dir, winslash = "/", mustWork = TRUE)

# Run a command in `dir` and return its exit status and output.
run_in <- function(dir, command, args, env = character()) {
  withr::with_dir(long_dir(dir), {
    out <- suppressWarnings(
      system2(command, args, stdout = TRUE, stderr = TRUE, env = env)
    )
  })
  list(status = attr(out, "status") %||% 0L, output = out)
}

# Check the exit status of a result from run_in() or git_in(), and with
# `output`, also the lines it printed. A failure shows everything the
# command printed, so the cause of a failed command reaches the test log.
expect_status <- function(result, status = 0L, output = NULL) {
  printed <- as.character(result$output)
  ok <- identical(as.integer(result$status), as.integer(status)) &&
    (is.null(output) || identical(printed, as.character(output)))
  expected <- paste("exit status", status)
  if (!is.null(output)) {
    expected <- paste(expected, if (length(output)) "and the expected output" else "and no output")
  }
  expect(ok, command_failure(result, expected))
  invisible(result)
}

# Check that a result from run_in() has an exit status other than 0.
expect_command_fails <- function(result) {
  expect(!identical(as.integer(result$status), 0L), command_failure(result, "an exit status other than 0"))
  invisible(result)
}

command_failure <- function(result, expected) {
  printed <- as.character(result$output)
  shown <- if (length(printed)) paste(printed, collapse = "\n") else "(nothing)"
  sprintf("The command exited with status %s; expected %s. It printed:\n%s", result$status, expected, shown)
}

# Run git without the user's global or system configuration and without a
# global excludes file, so that only the repository's own .gitignore
# decides what is ignored. GIT_DIR, GIT_WORK_TREE, and GIT_INDEX_FILE are
# unset, so that a run inside a git hook does not act on another
# repository.
git_in <- function(dir, args) {
  empty <- tempfile("gitconfig-")
  file.create(empty)
  on.exit(unlink(empty))
  withr::with_envvar(
    c(GIT_CONFIG_GLOBAL = empty, GIT_CONFIG_NOSYSTEM = "1",
      GIT_DIR = NA, GIT_WORK_TREE = NA, GIT_INDEX_FILE = NA),
    run_in(dir, "git", c("-c", paste0("core.excludesFile=", shQuote(empty)), args))
  )
}

# Make a new folder from the template without rendering it.
use_template <- function(dir) {
  run_in(dir, "quarto", c("use", "template", shQuote(template_dir()), "--no-prompt"))
}

# Render one site per test run, because a render runs R. Each test gets its
# own copy of it, so no test changes what another test sees.
rendered_site <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) {
      dir <- tempfile("site-")
      dir.create(dir)
      withr::defer(unlink(dir, recursive = TRUE), envir = testthat::teardown_env())
      used <- use_template(dir)
      rendered <- run_in(dir, "quarto", "render")
      cache <<- list(dir = dir, used = used, rendered = rendered)
    }
    cache
  }
})

site_copy <- function(env = parent.frame()) {
  site <- rendered_site()
  if (site$used$status != 0L || site$rendered$status != 0L) {
    fail(paste(c("Building the site from the template failed:", site$rendered$output), collapse = "\n"))
  }
  dest <- withr::local_tempdir("site-copy-", .local_envir = env)
  file.copy(list.files(site$dir, all.files = TRUE, no.. = TRUE, full.names = TRUE),
            dest, recursive = TRUE)
  utils::modifyList(site, list(dir = dest))
}

read_text <- function(path) paste(readLines(path, warn = FALSE), collapse = "\n")

# Run a command in `dir` and keep its standard output and standard error
# apart.
run_split <- function(dir, command, args) {
  out <- tempfile("stdout-")
  err <- tempfile("stderr-")
  on.exit(unlink(c(out, err)))
  status <- withr::with_dir(long_dir(dir), suppressWarnings(system2(command, args, stdout = out, stderr = err)))
  list(status = status, stdout = read_text(out), stderr = read_text(err))
}

# A small website with the template's supplement extension and no R code.
# `supplement` holds the lines that go under the `supplement:` key, without
# their two-space indent, which this function adds. `pages` maps file names
# to page bodies.
shortcode_site <- function(supplement, pages, env = parent.frame()) {
  dir <- withr::local_tempdir("shortcodes-", .local_envir = env)
  dir.create(file.path(dir, "_extensions"))
  file.copy(file.path(template_dir(), "_extensions", "supplement"), file.path(dir, "_extensions"),
            recursive = TRUE)
  writeLines(
    c("project:", "  type: website", "  output-dir: docs", "metadata-files:", "  - _supplement.yml"),
    file.path(dir, "_quarto.yml")
  )
  writeLines(c("supplement:", paste0("  ", supplement)), file.path(dir, "_supplement.yml"))
  for (name in names(pages)) {
    path <- file.path(dir, name)
    dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
    writeLines(c("---", "title: Fixture", "---", "", pages[[name]]), path)
  }
  dir
}

zenodo_yaml <- function(version = "", concept = "", archive = "") {
  c("zenodo:",
    sprintf('  version-doi: "%s"', version),
    sprintf('  concept-doi: "%s"', concept),
    sprintf('  archive-url: "%s"', archive))
}

data_yaml <- function(files) {
  c("data:", unlist(lapply(files, function(f) {
    c(sprintf('  - file: "%s"', f), sprintf('    description: "About %s"', basename(f)))
  })))
}

rx_escape <- function(x) gsub("([.?*+^$(){}|\\[\\]\\\\/])", "\\\\\\1", x, perl = TRUE)

# The rows of the data table on a page, one character vector of cell
# contents per row, header row left out.
data_table_rows <- function(html) {
  rows <- regmatches(html, gregexpr("<tr[^>]*>[\\s\\S]*?</tr>", html, perl = TRUE))[[1]]
  rows <- rows[grepl("<td", rows, fixed = TRUE)]
  lapply(rows, function(row) {
    cells <- regmatches(row, gregexpr("<td[^>]*>[\\s\\S]*?</td>", row, perl = TRUE))[[1]]
    sub("^<td[^>]*>([\\s\\S]*?)</td>$", "\\1", cells, perl = TRUE)
  })
}

# Set one key of _supplement.yml to a new quoted value.
set_supplement_value <- function(path, key, value) {
  lines <- readLines(path)
  i <- grep(paste0("^\\s*", rx_escape(key), ":"), lines)
  stopifnot(length(i) == 1L)
  lines[i] <- sub(":.*$", paste0(': "', value, '"'), lines[i])
  writeLines(lines, path)
}

supplement_value <- function(path, key) {
  lines <- readLines(path)
  i <- grep(paste0("^\\s*", rx_escape(key), ":"), lines)
  stopifnot(length(i) == 1L)
  sub('^[^:]*:\\s*"(.*)"\\s*$', "\\1", lines[i])
}

# The YAML front matter of a .qmd file, read with the yaml package.
front_matter <- function(path) {
  lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
  ends <- which(lines == "---")
  stopifnot(length(ends) >= 2, ends[1] == 1)
  yaml::yaml.load(paste(lines[2:(ends[2] - 1)], collapse = "\n"))
}

strip_tags <- function(x) {
  x <- gsub("<[^>]+>", "", x)
  trimws(gsub("\\s+", " ", x))
}

# The rows of the report listing on the home page. Each row is a list with
# `cells`, the text of each cell with its HTML tags removed, and `links`,
# the link targets in the row.
listing_rows <- function(html) {
  listing <- regmatches(html, regexpr('<div id="listing-reports"[\\s\\S]*?</table>', html, perl = TRUE))
  if (length(listing) == 0) {
    return(list())
  }
  rows <- regmatches(listing, gregexpr("<tr[^>]*>[\\s\\S]*?</tr>", listing, perl = TRUE))[[1]]
  rows <- rows[grepl("<td", rows, fixed = TRUE)]
  lapply(rows, function(row) {
    cells <- regmatches(row, gregexpr("<td[^>]*>[\\s\\S]*?</td>", row, perl = TRUE))[[1]]
    links <- regmatches(row, gregexpr('href="[^"]*"', row))[[1]]
    list(cells = strip_tags(cells), links = sub('^href="([^"]*)"$', "\\1", links))
  })
}

# The page header that holds the site navbar, or "" when the page has none.
quarto_header <- function(html) {
  m <- regmatches(html, regexpr('<header id="quarto-header"[\\s\\S]*?</header>', html, perl = TRUE))
  if (length(m) == 0) "" else m
}

# A pattern for the DOI badge: a link to doi.org around Zenodo's badge
# image, both for `doi`.
doi_badge_rx <- function(doi) {
  paste0(
    '<a [^>]*href="https://doi\\.org/', rx_escape(doi), '"[^>]*>\\s*',
    '<img [^>]*src="https://zenodo\\.org/badge/DOI/', rx_escape(doi), '\\.svg"'
  )
}

# The footer's link target for each license id (SPDX has a page there only
# for the ids it lists).
spdx_url <- function(ids) paste0("https://spdx.org/licenses/", ids, ".html")

# The link targets in `html` that start with https://spdx.org/, in order.
spdx_links <- function(html) {
  links <- regmatches(html, gregexpr('href="https://spdx\\.org/[^"]*"', html))[[1]]
  sub('^href="([^"]*)"$', "\\1", links)
}

# The page text between BEFORE and AFTER, with runs of white space made one
# space.
between_markers <- function(html) {
  m <- regmatches(html, regexpr("BEFORE[\\s\\S]*?AFTER", html, perl = TRUE))
  gsub("\\s+", " ", m)
}
