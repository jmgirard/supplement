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
#
# Quarto runs with QUARTO_LOG_LEVEL=DEBUG unless the variable is already
# set. Quarto 1.10 turns a failed project script into an error with no
# message, and only its debug lines show the script's exit code
# ("[execProcess] Success: false, code: 3"). The debug lines are part of
# `output`, so a failed status check shows them with the rest; a check
# that matches the output of a quarto command must allow for them.
# The variable is set with withr, because on Windows system2() passes `env`
# only to commands such as R that read it from their command line.
run_in <- function(dir, command, args, env = character()) {
  is_quarto <- is_quarto_command(command)
  log_level <- if (is_quarto && Sys.getenv("QUARTO_LOG_LEVEL") == "") {
    c(QUARTO_LOG_LEVEL = "DEBUG")
  } else {
    character()
  }
  run <- function() {
    withr::with_dir(long_dir(dir), withr::with_envvar(log_level, {
      suppressWarnings(system2(command, args, stdout = TRUE, stderr = TRUE, env = env))
    }))
  }
  out <- run()
  if (is_quarto && !is.null(attr(out, "status")) && sass_cache_locked(out)) out <- run()
  list(status = attr(out, "status") %||% 0L, output = out)
}

is_quarto_command <- function(command) {
  sub("\\.exe$", "", basename(command), ignore.case = TRUE) == "quarto"
}

# Quarto 1.10 keeps the Sass it compiles in a database in the user's
# cache. When test files run in parallel, two renders that write it at
# once can make one stop with "ERROR: database is locked", so run_in() and
# run_split() run such a render once more.
sass_cache_locked <- function(output) {
  any(grepl("database is locked", output, fixed = TRUE))
}

# Check the exit status of a result from run_in(), git_in(), run_split(),
# or git_run(), and with `output`, also the lines it printed. A failure
# shows everything the command printed, so the cause of a failed command
# reaches the test log.
expect_status <- function(result, status = 0L, output = NULL) {
  printed <- as.character(result$output)
  actual <- exit_status(result)
  ok <- !is.na(actual) && identical(actual, as.integer(status)) &&
    (is.null(output) || identical(printed, as.character(output)))
  expected <- paste("exit status", status)
  if (!is.null(output)) {
    expected <- paste(expected, if (length(output)) {
      paste0("and this output:\n", paste(output, collapse = "\n"), "\n")
    } else {
      "and no output"
    })
  }
  expect(ok, command_failure(result, expected))
  invisible(result)
}

# Check that a result from run_in() has an exit status other than 0.
expect_command_fails <- function(result) {
  actual <- exit_status(result)
  expect(!is.na(actual) && actual != 0L, command_failure(result, "an exit status other than 0"))
  invisible(result)
}

# The exit status as one integer, or NA when the result holds none.
exit_status <- function(result) {
  s <- result$status
  if (length(s) == 1L && is.numeric(s) && !is.na(s) && s == round(s) && abs(s) <= .Machine$integer.max) {
    as.integer(s)
  } else {
    NA_integer_
  }
}

command_failure <- function(result, expected) {
  printed <- as.character(result$output)
  # run_split() keeps standard output and standard error apart, and
  # git_run() keeps standard output as raw bytes.
  if (is.null(result$output)) {
    printed <- vapply(list(result$stdout, result$stderr), function(x) {
      if (is.raw(x)) rawToChar(x) else paste(x, collapse = "\n")
    }, character(1))
    printed <- printed[nzchar(printed)]
  }
  shown <- if (length(printed)) paste(printed, collapse = "\n") else "(nothing)"
  status <- paste(deparse(result$status), collapse = "")
  sprintf("The command exited with status %s; expected %s. It printed:\n%s", status, expected, shown)
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

# The template's rules for figures next to reports match any letter case,
# and figures/ stays in git. On macOS and Windows, `git init` sets
# core.ignorecase=true, because their file systems ignore letter case by
# default, so every check runs with core.ignorecase=false, as on Linux.
expect_figure_rules <- function(dir) {
  in_analyses <- c("analyses/a.PNG", "analyses/b.Pdf", "analyses/c.png", "analyses/d.pdf")
  ignored <- git_in(dir, c("-c", "core.ignorecase=false", "check-ignore", in_analyses))
  expect_status(ignored)
  expect_setequal(ignored$output, in_analyses)

  in_figures <- c("figures/e.PNG", "figures/f.PDF", "figures/plot.pdf", "figures/plot.png")
  kept <- git_in(dir, c("-c", "core.ignorecase=false", "check-ignore", in_figures))
  expect_status(kept, 1L, output = character())

  # A temporary file that save_png() leaves in figures/, and its copy in docs/.
  leftovers <- c("figures/.save-1a2b.png", "docs/figures/.save-1a2b.png")
  left <- git_in(dir, c("check-ignore", leftovers))
  expect_status(left)
  expect_setequal(left$output, leftovers)
}

# Turn off git's global and system configuration and the user's ignore
# file in $XDG_CONFIG_HOME/git/ignore, so that only a repository's own
# rules decide what git ignores.
local_plain_git <- function(env = parent.frame()) {
  empty <- withr::local_tempfile(.local_envir = env)
  file.create(empty)
  config <- withr::local_tempdir(.local_envir = env)
  withr::local_envvar(
    c(GIT_CONFIG_GLOBAL = empty, GIT_CONFIG_NOSYSTEM = "1", XDG_CONFIG_HOME = config),
    .local_envir = env
  )
}

# A site made by create_supplement() in a git repository, with the
# template's .gitignore, under local_plain_git().
git_site <- function(env = parent.frame()) {
  site <- new_site(env)
  file.copy(file.path(site, "_gitignore"), file.path(site, ".gitignore"))
  local_plain_git(env)
  inited <- git_in(site, c("init", "-q"))
  stopifnot(inited$status == 0L)
  site
}

# A git_site() that is rendered and committed, in which renv::init() then
# ran. renv runs in an Rscript process with its cache and sandbox in
# temporary folders, so a test never activates renv in its own session or
# writes to the user's renv folders. renv::init() needs a network only to
# install a package that the site uses and that Rscript does not have, so
# the test skips then.
renv_site <- function(env = parent.frame()) {
  skip_if_no_quarto()
  skip_if_no_git()
  scripts <- withr::local_tempdir("renv-scripts-", .local_envir = env)
  # renv itself and the packages that renv::dependencies() finds in the
  # template's reports. Each line names a missing one, so a message that
  # R prints on stderr is not read as a package.
  writeLines(
    c('pkgs <- c("renv", "knitr", "rmarkdown", "sessioninfo")',
      "for (p in pkgs) if (!requireNamespace(p, quietly = TRUE)) cat(\"missing:\", p, \"\\n\")"),
    file.path(scripts, "missing.R")
  )
  writeLines("renv::init()", file.path(scripts, "init.R"))
  missing <- run_in(scripts, home_rscript(), c("--no-init-file", "missing.R"))
  expect_status(missing)
  pkgs <- trimws(sub("^missing: ", "", grep("^missing: ", missing$output, value = TRUE)))
  skip_if("renv" %in% pkgs, "renv is not installed for Rscript")
  skip_if(length(pkgs) > 0,
          paste("renv::init() would download packages that Rscript does not have:",
                paste(pkgs, collapse = ", ")))

  site <- fill_placeholders(git_site(env))
  expect_status(run_in(site, "quarto", "render"))
  expect_status(git_in(site, c("add", "-A")))
  expect_status(git_in(site, c("-c", "user.name=Test", "-c", "user.email=test@example.com",
                               "-c", "commit.gpgsign=false", "commit", "-q", "-m", "Site")))

  renv_env <- c(
    RENV_PATHS_ROOT = long_dir(withr::local_tempdir("renv-root-", .local_envir = env)),
    RENV_PATHS_SANDBOX = long_dir(withr::local_tempdir("renv-sandbox-", .local_envir = env)),
    # renv makes its sandbox read-only, and withr then cannot delete it.
    RENV_SANDBOX_LOCKING_ENABLED = "FALSE",
    # Each of these would move renv's cache, library, or lockfile away from
    # the folders above and the site.
    RENV_PATHS_CACHE = NA, RENV_PATHS_LIBRARY = NA, RENV_PATHS_LIBRARY_ROOT = NA, RENV_PROFILE = NA,
    # Under testthat, renv prints little when it fails.
    RENV_VERBOSE = "TRUE"
  )
  init <- file.path(long_dir(scripts), "init.R")
  expect_status(withr::with_envvar(
    renv_env,
    run_in(site, home_rscript(), c("--no-init-file", shQuote(init)))
  ))
  site
}

# Make a new folder from the template without rendering it.
use_template <- function(dir) {
  run_in(dir, "quarto", c("use", "template", shQuote(template_dir()), "--no-prompt"))
}

# Render one site per test process, because a render runs R. Each test gets
# its own copy of it, so no test changes what another test sees.
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

# The code lines of the chunk with `#| label: <label>` in a .qmd file.
chunk_code <- function(path, label) {
  lines <- readLines(path, warn = FALSE)
  at <- which(lines == paste0("#| label: ", label))
  stopifnot(length(at) == 1L)
  start <- max(grep("^```\\{", lines[seq_len(at)]))
  ends <- which(lines == "```")
  end <- min(ends[ends > at])
  lines[(start + 1L):(end - 1L)]
}

# The MD5 of each file in a folder, named by its path in the folder.
folder_md5 <- function(dir) {
  files <- sort(list.files(dir, recursive = TRUE, all.files = TRUE))
  stats::setNames(unname(tools::md5sum(file.path(dir, files))), files)
}

# Run a command in `dir` and keep its standard output and standard error
# apart.
run_split <- function(dir, command, args) {
  out <- tempfile("stdout-")
  err <- tempfile("stderr-")
  on.exit(unlink(c(out, err)))
  is_quarto <- is_quarto_command(command)
  run <- function() {
    withr::with_dir(long_dir(dir), {
      suppressWarnings(system2(command, args, stdout = out, stderr = err))
    })
  }
  status <- run()
  if (is_quarto && status != 0L && sass_cache_locked(c(read_text(out), read_text(err)))) {
    status <- run()
  }
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

# The Rscript in the bin folder of R_HOME. With QUARTO_R unset, Quarto 1.10
# looks there before the PATH, and R sets R_HOME for the processes it
# starts. R CMD check puts a stub Rscript first on the PATH, which exits 1
# ("should not be used without a path").
home_rscript <- function() {
  file.path(Sys.getenv("R_HOME"), "bin", "Rscript")
}

# The HTML of the <section> with `id` on a rendered page, or "" when the
# page has none. The section ends at its first </section>, so it must hold
# no nested section.
section_html <- function(html, id) {
  start <- regexpr(sprintf('<section id="%s"', id), html, fixed = TRUE)
  if (start < 0) return("")
  rest <- substring(html, start)
  substring(rest, 1, regexpr("</section>", rest, fixed = TRUE) - 1L)
}

# The text of some HTML, with its tags removed and four named character
# references and `&#39;` decoded.
html_text <- function(html) {
  text <- gsub("<[^>]+>", "", html)
  refs <- c("&lt;" = "<", "&gt;" = ">", "&quot;" = "\"", "&#39;" = "'", "&amp;" = "&")
  for (ref in names(refs)) text <- gsub(ref, refs[[ref]], text, fixed = TRUE)
  text
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
