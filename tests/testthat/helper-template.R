# Helpers for tests that build a site from the template with the Quarto CLI.

skip_if_no_quarto <- function() {
  skip_on_cran()
  skip_if(Sys.which("quarto") == "", "quarto is not on PATH")
  skip_if_not_installed("knitr")
  skip_if_not_installed("rmarkdown")
}

skip_if_no_git <- function() {
  skip_if(Sys.which("git") == "", "git is not on PATH")
}

template_dir <- function() {
  system.file("template", package = "supplement", mustWork = TRUE)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Run a command in `dir` and return its exit status and output.
run_in <- function(dir, command, args, env = character()) {
  withr::with_dir(dir, {
    out <- suppressWarnings(
      system2(command, args, stdout = TRUE, stderr = TRUE, env = env)
    )
  })
  list(status = attr(out, "status") %||% 0L, output = out)
}

# Run git without the user's global excludes file, so that only the
# repository's own .gitignore decides what is ignored.
git_in <- function(dir, args) {
  empty <- tempfile("excludes-")
  file.create(empty)
  on.exit(unlink(empty))
  run_in(dir, "git", c("-c", paste0("core.excludesFile=", shQuote(empty)), args))
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
  dest <- withr::local_tempdir("site-copy-", .local_envir = env)
  file.copy(list.files(site$dir, all.files = TRUE, no.. = TRUE, full.names = TRUE),
            dest, recursive = TRUE)
  utils::modifyList(site, list(dir = dest))
}

read_text <- function(path) paste(readLines(path, warn = FALSE), collapse = "\n")

# The page header that holds the site navbar, or "" when the page has none.
quarto_header <- function(html) {
  m <- regmatches(html, regexpr('<header id="quarto-header"[\\s\\S]*?</header>', html, perl = TRUE))
  if (length(m) == 0) "" else m
}
