#' Render the site from the R console
#'
#' `render_supplement()` runs the Quarto commands that render a site, so
#' that you can render from the R console with no terminal. With no
#' `reports`, it renders the whole site, as `quarto render` does in a
#' terminal. With `reports`, it first renders each named report by name,
#' which runs its code again, and then renders the whole site. Use it after
#' you change a report: a full render alone reuses each report's stored
#' output in `_freeze/` and does not run the changed code.
#'
#' The function runs these commands in the site folder, in this order:
#'
#' 1. `quarto render analyses/<name>.qmd` for each name in `reports`, in
#'    the order given. A name given twice is rendered once, at its first
#'    place.
#' 2. `quarto render`, which renders the whole site into `docs/`.
#' 3. `quarto render` once more, when a file in `figures/` is missing from
#'    `docs/figures/` after step 2. Quarto lists `figures/` when a render
#'    starts, so a figure that a report saves under a new name during the
#'    full render reaches `docs/` only with the next render. Files are
#'    compared by their path under each folder, hidden files included. When
#'    files are still missing after this render, the function prints their
#'    names and renders no more.
#'
#' On Windows, when the path of the site folder holds a `~`, as an 8.3
#' short name such as `RUNNER~1` does, the function runs these commands
#' from the folder's long path. Quarto run from a short path leaves the
#' figures that knitr saves from code chunks out of `docs/`.
#'
#' Quarto prints its output in the console as each command runs. The
#' function runs no git command. After it renders, commit the changed
#' reports with `_freeze/`, `docs/`, and `figures/`, and push.
#'
#' @section Which Quarto runs:
#' The function runs the Quarto copy that [check_tools()] reports, by its
#' full path: the copy on the system path, else the file that the
#' `QUARTO_PATH` environment variable names, else the copy that RStudio or
#' Positron installs. So it renders also when Quarto is not on the system
#' path that a terminal uses. A copy whose version cannot be read is used.
#' A copy older than 1.4.0 is refused. Quarto then runs the R code of each
#' report with its own R process.
#'
#' @param reports `NULL` to render only the whole site, or the names of
#'   reports in `analyses/` to render by name first, without `.qmd`, as
#'   [add_report()] takes them: `"models"` for `analyses/models.qmd`.
#' @param path The folder of the site.
#'
#' @return The commands that the function ran, as a character vector,
#'   invisibly, such as `c("quarto render analyses/models.qmd",
#'   "quarto render")`.
#'
#' @section Errors:
#' The function checks in this order and stops at the first problem.
#' Before step 1, no command has run. Each error has class
#' `supplement_error` and one of these classes:
#'
#' * `supplement_error_argument`: `path` is not one non-empty string, or
#'   `reports` is not `NULL` or a character vector of length 1 or more with
#'   no `NA`.
#' * `supplement_error_report_name`: an entry of `reports` breaks the rule
#'   for the `name` of [add_report()]: ASCII letters, digits, `-`, and `_`,
#'   starting with a letter or a digit, and not a name that Windows
#'   reserves, such as `con`.
#' * `supplement_error_no_config`: `path` holds no `_quarto.yml` file.
#' * `supplement_error_no_report`: `analyses/<name>.qmd` is not a file for
#'   one or more entries of `reports`. The message names each one. A name
#'   must match its file's letter case, also on macOS and Windows, where
#'   the file system ignores case: `"Models"` does not match
#'   `analyses/models.qmd`.
#' * `supplement_error_no_quarto`: no Quarto copy was found.
#' * `supplement_error_quarto_version`: the Quarto copy is older than
#'   1.4.0.
#' * `supplement_error_render`: a command exited with a status other than
#'   0. The message names the command. No later command runs, and the
#'   files that the earlier commands wrote stay.
#'
#' The working folder of the R session is the same after the call as
#' before it, also after an error.
#'
#' @seealso [check_supplement()] to check the rendered site, and
#'   [check_tools()] to see which Quarto copy is found.
#' @export
#' @examples
#' \dontrun{
#' # In the folder of a site:
#' render_supplement()
#'
#' # After you change analyses/models.qmd:
#' render_supplement("models")
#' }
render_supplement <- function(reports = NULL, path = ".") {
  check_path(path)
  path <- drop_trailing_sep(path)
  reports <- check_reports(reports)

  config <- file.path(path, "_quarto.yml")
  if (!file.exists(config) || dir.exists(config)) {
    cli::cli_abort(
      c("No {.file _quarto.yml} in {.path {path}}.",
        "i" = "Run this function in the folder of a site made from the template."),
      class = c("supplement_error_no_config", "supplement_error")
    )
  }
  # paste0() of an empty vector gives ".qmd", so no reports give no files.
  names <- if (length(reports) > 0) paste0(reports, ".qmd") else character()
  # Names are matched to the listed files with their letter case, since
  # file.exists() ignores case on macOS and Windows, and a render under
  # another case writes its output under that case.
  present <- report_file_names(path)
  absent <- names[!names %in% present]
  if (length(absent) > 0) {
    missing <- file.path("analyses", absent)
    cased <- present[tolower(present) %in% tolower(absent)]
    cli::cli_abort(
      c("No report file {.file {missing}} in {.path {path}}, so nothing was rendered.",
        "i" = "Give the name of a report in {.path analyses/}, without {.code .qmd}.",
        "i" = if (length(cased) > 0) "{.file {file.path('analyses', cased)}} differ{?s/} only in letter case from a name given. Give each name as its file is written."),
      class = c("supplement_error_no_report", "supplement_error")
    )
  }
  files <- if (length(names) > 0) file.path("analyses", names) else character()
  quarto <- render_quarto()

  here <- environment()
  owd <- setwd(path)
  on.exit(setwd(owd), add = TRUE)
  # Quarto run from a Windows path with an 8.3 short name, such as
  # RUNNER~1, leaves the figures that knitr writes out of docs/. The long
  # path is used only for a path with ~, since normalizePath() also
  # resolves symbolic links and junctions.
  if (.Platform$OS.type == "windows" && grepl("~", getwd(), fixed = TRUE)) {
    setwd(normalizePath(".", winslash = "/", mustWork = TRUE))
  }
  ran <- character()
  render <- function(args) {
    command <- paste(c("quarto", args), collapse = " ")
    status <- quarto_run(quarto, args)
    if (!identical(as.integer(status), 0L)) {
      # On Unix, the shell that system2 starts gives 127 when it cannot
      # start the program.
      cause <- if (identical(as.integer(status), 127L)) {
        "Quarto at {.path {quarto}} could not be started. Run {.fn check_tools} to see which copy was found."
      } else {
        "Read Quarto's output above for the cause."
      }
      cli::cli_abort(
        c("{.code {command}} exited with status {status}, so the render stopped.",
          "i" = if (length(ran) > 0) "These commands ran before it: {.code {ran}}." else "No command ran before it.",
          "i" = cause),
        class = c("supplement_error_render", "supplement_error"),
        call = here
      )
    }
    ran <<- c(ran, command)
  }
  for (file in files) render(c("render", file))
  render("render")
  missing <- unpublished_figures(".")
  if (length(missing) > 0) {
    render("render")
    missing <- unpublished_figures(".")
  }

  cli::cli_alert_success("Rendered the site into {.path docs/}.")
  if (length(missing) > 0) {
    cli::cli_inform(c(
      "!" = "{.file {missing}} {?is/are} still missing from {.path docs/figures/} after two full renders.",
      "i" = "Check that {.path docs/figures/} is a folder and that {.file _quarto.yml} renders into {.path docs/} and lists {.code figures/**} under {.field resources}, as the template does."
    ))
  }
  cli::cli_text("Commit the changed reports with {.path _freeze/}, {.path docs/}, and {.path figures/}, and push.")
  invisible(ran)
}

# `reports` as unique names, or character() for NULL, after the checks
# that come before the site's files are read.
check_reports <- function(reports, call = parent.frame()) {
  if (is.null(reports)) {
    return(character())
  }
  if (!is.character(reports) || length(reports) == 0 || anyNA(reports)) {
    cli::cli_abort(
      "{.arg reports} must be {.code NULL} or a character vector of report names with no {.code NA}.",
      class = c("supplement_error_argument", "supplement_error"),
      call = call
    )
  }
  reports <- unique(as.vector(reports))
  for (name in reports) {
    check_report_name(name, "reports", "Give the name of a report in {.path analyses/}. Nothing was rendered.",
                      each = TRUE, call = call)
  }
  reports
}

# The names of the `.qmd` files in analyses/ under `path`, as written on
# disk, folders left out.
report_file_names <- function(path) {
  dir <- file.path(path, "analyses")
  names <- list.files(dir, pattern = "\\.qmd$")
  names[vapply(file.path(dir, names), is_plain_file, logical(1))]
}

# The path of the Quarto copy that check_tools() reports, after the checks
# that it exists and is not too old.
render_quarto <- function(call = parent.frame()) {
  copy <- find_quarto()
  if (is.null(copy)) {
    cli::cli_abort(
      c("Could not find Quarto, so nothing was rendered.",
        "i" = "Install Quarto from {.url https://quarto.org/docs/get-started/}, or run {.fn check_tools} to see where it was looked for."),
      class = c("supplement_error_no_quarto", "supplement_error"),
      call = call
    )
  }
  version <- quarto_version(copy$path)
  if (!is.null(version) && version < quarto_minimum) {
    cli::cli_abort(
      c("Quarto {format(version)} at {.path {copy$path}} is older than {quarto_minimum}, the oldest that the template supports, so nothing was rendered.",
        "i" = "Install a newer Quarto from {.url https://quarto.org/docs/get-started/}."),
      class = c("supplement_error_quarto_version", "supplement_error"),
      call = call
    )
  }
  copy$path
}

# Run the Quarto program `quarto` with `args` in the working folder, its
# output shown in the console, and return its exit status. Kept apart so
# that tests can mock it. system2 quotes the program's path itself with
# shQuote, so a path with a space runs, and a path quoted here first would
# be quoted twice and not found (status 127).
quarto_run <- function(quarto, args) {
  suppressWarnings(system2(quarto, args))
}

# The files in figures/ under `path` that docs/figures/ lacks, as paths
# such as "figures/plot.png", hidden files included.
unpublished_figures <- function(path) {
  listed <- function(dir) {
    if (!dir.exists(dir)) {
      return(character())
    }
    files <- list.files(dir, recursive = TRUE, all.files = TRUE, no.. = TRUE)
    files[!dir.exists(file.path(dir, files))]
  }
  missing <- setdiff(listed(file.path(path, "figures")), listed(file.path(path, "docs", "figures")))
  if (length(missing) == 0) character() else paste0("figures/", sort(missing))
}
