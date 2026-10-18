#' Add an analysis report to a supplement site
#'
#' `add_report()` writes a new report file, `analyses/<name>.qmd`, and adds
#' a link to it as the last item of the Analyses menu in `_quarto.yml`. The
#' home page of a site made from the template lists every report in
#' `analyses/` with its title and description, so the new report shows
#' there too.
#'
#' The function adds lines to `_quarto.yml` as text, so the other lines of
#' the file, its comments included, stay as they are. It finds the menu as
#' the item with `text: Analyses` under `website: navbar: left:` (or
#' `right:`), written in block style, with each item on its own line after
#' a `-`. The title and the description are written as YAML strings in
#' double quotes.
#'
#' Quarto runs the new report the first time that the site renders, because
#' it has no stored output in `_freeze/` yet. To run it alone, render it by
#' name, for example `quarto render analyses/<name>.qmd`.
#'
#' @param name The file name of the report, without `.qmd`. It is ASCII
#'   letters, digits, `-`, and `_`, and starts with a letter or a digit.
#' @param title The title of the report. It shows in the Analyses menu and
#'   on the home page.
#' @param description A short description of the report for the home
#'   page. When it is `""`, the report has no `description`, and the home
#'   page shows the start of the report's text in its place.
#' @param path The folder of the site.
#'
#' @return The path of the new report file, invisibly.
#'
#' @section Errors:
#' The function writes nothing when it stops. Its own errors have the class
#' `supplement_error` and one of these classes:
#'
#' * `supplement_error_argument`: `path` is not a single non-empty string,
#'   `title` is not a single string with a character other than white
#'   space, or `description` is not a single string.
#' * `supplement_error_report_name`: `name` is not a single string of ASCII
#'   letters, digits, `-`, and `_` that starts with a letter or a digit.
#' * `supplement_error_line_break`: `title` or `description` holds a line
#'   break.
#' * `supplement_error_no_config`: `path` holds no `_quarto.yml`.
#' * `supplement_error_file_exists`: the report file exists, or a file
#'   whose name differs from it only in letter case; `analyses` is not a
#'   folder or is a link; or `_freeze/analyses/<name>` exists, which holds
#'   the stored output of an earlier report of that name.
#' * `supplement_error_no_menu`: `_quarto.yml` has no Analyses menu in
#'   block style. The error shows the lines to add by hand.
#' * `supplement_error_yaml`: the yaml package does not read the changed
#'   `_quarto.yml` as the old menu with the new item added. The error shows
#'   the lines to add by hand.
#' * `supplement_error_encoding`: `title`, `description`, or
#'   `_quarto.yml` is not UTF-8 text.
#' * `supplement_error_write`: the `analyses` folder could not be made.
#'
#' When a file cannot be written, for example a read-only `_quarto.yml`,
#' R's own error is shown, and the function removes the report file and
#' any folder it made. If a
#' write of `_quarto.yml` fails partway, the file gets its old text back.
#'
#' @seealso [add_data()] to add a data file, and [create_supplement()] to
#'   make a site.
#' @export
#' @examples
#' site <- file.path(tempdir(), "report-example")
#' create_supplement(site)
#' add_report("models", "Model Comparison", "Fits and compares the models.", path = site)
#' cat(readLines(file.path(site, "analyses", "models.qmd")), sep = "\n")
#' unlink(site, recursive = TRUE)
add_report <- function(name, title, description = "", path = ".") {
  check_path(path)
  if (!is.character(name) || length(name) != 1 || is.na(name) ||
      !grepl("^[A-Za-z0-9][A-Za-z0-9_-]*$", name)) {
    cli::cli_abort(
      c("{.arg name} must be one file name made of ASCII letters, digits, {.code -}, and {.code _}.",
        "i" = "It must start with a letter or a digit, and it has no {.code .qmd} at the end."),
      class = c("supplement_error_report_name", "supplement_error")
    )
  }
  check_text(title, "title", required = TRUE)
  check_text(description, "description")

  config <- file.path(path, "_quarto.yml")
  if (!file.exists(config) || dir.exists(config)) {
    cli::cli_abort(
      c("No {.file _quarto.yml} in {.path {path}}.",
        "i" = "Run this function in the folder of a site made from the template."),
      class = c("supplement_error_no_config", "supplement_error")
    )
  }
  folder <- file.path(path, "analyses")
  # A link to a folder would make the write land outside the site.
  if (path_occupied(folder) && (!dir.exists(folder) || is_link(folder))) {
    cli::cli_abort(
      "{.path {folder}} is not a folder in the site, or is a link, so the report cannot be written there.",
      class = c("supplement_error_file_exists", "supplement_error")
    )
  }
  file <- paste0(name, ".qmd")
  report <- file.path(folder, file)
  # Names that differ only in letter case clash when the site is cloned on
  # macOS or Windows.
  taken <- if (dir.exists(folder)) list.files(folder, all.files = TRUE) else character()
  if (path_occupied(report) || tolower(file) %in% tolower(taken)) {
    cli::cli_abort(
      c("{.file analyses/{file}}, or a file whose name differs from it only in letter case, already exists.",
        "i" = "Choose another {.arg name}. Nothing was written."),
      class = c("supplement_error_file_exists", "supplement_error")
    )
  }
  # With `freeze: true`, Quarto would show the stored output of an earlier
  # report of this name in place of the new one.
  frozen <- file.path(path, "_freeze", "analyses", name)
  if (path_occupied(frozen)) {
    cli::cli_abort(
      c("{.path {frozen}} holds the stored output of an earlier report named {.val {name}}.",
        "i" = "Delete that folder, or choose another {.arg name}. Nothing was written."),
      class = c("supplement_error_file_exists", "supplement_error")
    )
  }

  href <- paste0("analyses/", file)
  item <- c(href = href, text = title)
  hand <- c(
    "website:",
    "  navbar:",
    "    left:",
    "      - text: Analyses",
    "        menu:",
    paste0("          - href: ", yaml_quote(href)),
    paste0("            text: ", yaml_quote(title))
  )
  menus <- lapply(c("left", "right"), function(side) {
    list("website", "navbar", side, yaml_item("text", "Analyses"), "menu")
  })
  edit <- append_item(
    config, menus, item,
    missing = "{.file _quarto.yml} has no Analyses menu in block style, so nothing was written.",
    missing_class = "supplement_error_no_menu",
    hand = hand
  )

  made <- character()
  done <- FALSE
  on.exit(if (!done) unlink(rev(made), recursive = TRUE))
  if (!dir.exists(folder)) {
    if (!dir.create(folder, showWarnings = FALSE)) {
      write_error("Could not make the folder {.path {folder}}.")
    }
    made <- c(made, folder)
  }
  made <- c(made, report)
  write_utf8(report_lines(title, description), report)
  write_text_lines(edit$read, edit$lines, config)
  done <- TRUE

  cli::cli_inform(c(
    "v" = "Wrote {.file {href}} and added it to the Analyses menu in {.file _quarto.yml}.",
    "i" = "Run {.code quarto render {href}} in {.path {path}} to run the report."
  ))
  invisible(report)
}

report_lines <- function(title, description) {
  c(
    "---",
    paste0("title: ", yaml_quote(title)),
    if (nzchar(description)) paste0("description: ", yaml_quote(description)),
    "---",
    "",
    "Write the report here. It runs from the `analyses/` folder, so it reads",
    "a data file as `file.path(\"..\", \"data\", \"<file name>\")`.",
    "",
    "```{r}",
    "#| label: setup",
    "set.seed(2026)",
    "```"
  )
}
