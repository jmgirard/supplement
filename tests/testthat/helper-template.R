# Helpers for tests that build a site from the template with the Quarto CLI.

skip_if_no_quarto <- function() {
  skip_on_cran()
  skip_if(Sys.which("quarto") == "", "quarto is not on PATH")
}

template_dir <- function() {
  system.file("template", package = "supplement", mustWork = TRUE)
}

# Run a command in `dir` and return its exit status and output.
run_in <- function(dir, command, args, env = character()) {
  withr::with_dir(dir, {
    out <- suppressWarnings(
      system2(command, args, stdout = TRUE, stderr = TRUE, env = env)
    )
  })
  list(status = attr(out, "status") %||% 0L, output = out)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Make a new folder from the template without rendering it.
use_template <- function(dir) {
  run_in(dir, "quarto", c("use", "template", shQuote(template_dir()), "--no-prompt"))
}

# Build one rendered site per test run and reuse it, because a render runs R.
rendered_site <- local({
  site <- NULL
  function() {
    if (is.null(site)) {
      dir <- tempfile("site-")
      dir.create(dir)
      used <- use_template(dir)
      rendered <- run_in(dir, "quarto", "render")
      site <<- list(dir = dir, used = used, rendered = rendered)
    }
    site
  }
})

read_text <- function(path) paste(readLines(path, warn = FALSE), collapse = "\n")

# The page header that holds the site navbar, or "" when the page has none.
quarto_header <- function(html) {
  m <- regmatches(html, regexpr('<header id="quarto-header"[\\s\\S]*?</header>', html, perl = TRUE))
  if (length(m) == 0) "" else m
}
