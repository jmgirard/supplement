#' Add an analysis report to a supplement site
#'
#' `add_report()` writes a new report file, `analyses/<name>.qmd`, and adds
#' a link to it as the last item of the Analyses menu in `_quarto.yml`. The
#' home page of a site made from the template lists every report in
#' `analyses/` with its title and description, so the new report shows
#' there too.
#'
#' The home page's table lists the reports that have an `order` field in
#' their front matter first, by that number, and the others after them by
#' title. The template's example report has `order: 1`. The function
#' gives the new report the next whole number after the largest `order` of
#' the other reports in `analyses/`. So when every report has an `order`
#' and the menu lists them in that order, the table lists reports in the
#' order of the Analyses menu. The new report gets `order: 1` when
#' `analyses/` holds no other report. It gets no `order` when no other
#' report has one, as in a site made before the template had `order`, so
#' that its table keeps listing reports by title. Here an `order` counts
#' only when the yaml package reads it as a number below one million (in
#' absolute value), and a report whose front matter cannot be read counts
#' as having none. To change the table's order, edit the `order` values,
#' render each changed report by name, then render the whole site.
#'
#' The first code chunk of the new report is the `site` chunk of the
#' template's example report, which sets `site` to the site folder. If
#' `QUARTO_PROJECT_DIR` is not empty, as in a render, `site` is its value.
#' Otherwise `site` is `"."` or `".."`, the first of the two that holds
#' `_quarto.yml`, and the chunk stops with an error if neither holds it.
#' The chunk then reads `_scripts/report.R` with
#' `source(file.path(site, "_scripts", "report.R"), local = TRUE)`. That
#' file defines `save_png()`, which saves a figure in `figures/`, and
#' `print_environment()`. The report's text says to read a data file as
#' `file.path(site, "data", "<file name>")`.
#'
#' A site made before the template had `_scripts/report.R` lacks the file.
#' When the site has no `_scripts/report.R`, the function copies the
#' template's file there, and it makes the `_scripts` folder when that is
#' missing. It never replaces a `_scripts/report.R` that the site has. A
#' report fails to render when that file lacks `print_environment()`.
#'
#' The new report ends with a "Computing environment" section, the same as
#' the template's example report. It calls `print_environment()`, which
#' prints the R and package versions of the render, with
#' `sessioninfo::session_info()` when the sessioninfo package is installed
#' and with `utils::sessionInfo()` otherwise. It shows the home folder as
#' `~`.
#'
#' `check_supplement()` compares the text of each report with the hash in
#' its stored output. If a report names `_scripts/report.R` and the file is
#' missing, it gives a row. `print_environment()` also prints the MD5 of
#' `_scripts/report.R`, and `check_supplement()` gives a row for each report
#' whose stored output gives another MD5 than the file has now. After a
#' change to the file, render each report by name to take the change.
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
#'   It cannot be a name that Windows reserves for a device, in any letter
#'   case: `CON`, `PRN`, `AUX`, `NUL`, `COM1` to `COM9`, or `LPT1` to
#'   `LPT9`.
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
#'   letters, digits, `-`, and `_` that starts with a letter or a digit, or
#'   it is a name that Windows reserves for a device, in any letter case:
#'   `CON`, `PRN`, `AUX`, `NUL`, `COM1` to `COM9`, or `LPT1` to `LPT9`.
#' * `supplement_error_line_break`: `title` or `description` holds a line
#'   break.
#' * `supplement_error_no_config`: `path` holds no `_quarto.yml`.
#' * `supplement_error_parse`: the yaml package cannot read `_quarto.yml`.
#'   Examples are a `[` or a `{` that is not closed, a key line indented
#'   with a tab, and a key given twice in one map. The message names the file and
#'   gives the message of the yaml package.
#' * `supplement_error_file_exists`: the report file exists, or a file
#'   whose name differs from it only in letter case; `analyses` is not a
#'   folder or is a link; `_scripts` is not a folder or is a link;
#'   `_scripts/report.R` is a folder or a link; or
#'   `_freeze/analyses/<name>` exists, which holds the stored output of an
#'   earlier report of that name.
#' * `supplement_error_no_menu`: `_quarto.yml` has no Analyses menu in
#'   block style. The error shows the lines to add by hand.
#' * `supplement_error_yaml`: the yaml package does not read the changed
#'   `_quarto.yml` as the old menu with the new item added. The error shows
#'   the lines to add by hand.
#' * `supplement_error_encoding`: `title`, `description`, or
#'   `_quarto.yml` is not UTF-8 text.
#' * `supplement_error_write`: the `analyses` or `_scripts` folder could
#'   not be made, or a write failed after its file was opened, for example
#'   on a full disk. A `_quarto.yml` whose write failed gets its old text
#'   back.
#'
#' When a file cannot be opened for writing, for example a read-only
#' `_quarto.yml`, R's own error is shown. After any failed write, the
#' function removes the report file, a `_scripts/report.R` that it copied,
#' and any folder it made.
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
  # A missing argument reaches the checks as NULL, so it gets their error.
  if (missing(name)) name <- NULL
  if (missing(title)) title <- NULL
  check_path(path)
  if (!is.character(name) || length(name) != 1 || is.na(name)) {
    cli::cli_abort(
      c("{.arg name} must be one file name made of ASCII letters, digits, {.code -}, and {.code _}.",
        "i" = "It must start with a letter or a digit, and it has no {.code .qmd} at the end."),
      class = c("supplement_error_report_name", "supplement_error")
    )
  }
  check_report_name(name, "name", "Choose another {.arg name}. Nothing was written.")
  title <- check_text(title, "title", required = TRUE)
  description <- check_text(description, "description")

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
  # The report reads _scripts/report.R. A link would make the copy land
  # outside the site, or make the report read a file outside it.
  scripts <- file.path(path, "_scripts")
  shared <- file.path(scripts, "report.R")
  if (path_occupied(scripts) && (!dir.exists(scripts) || is_link(scripts))) {
    cli::cli_abort(
      "{.path {scripts}} is not a folder in the site, or is a link, so {.file _scripts/report.R} cannot be read there.",
      class = c("supplement_error_file_exists", "supplement_error")
    )
  }
  if (is_link(shared) || dir.exists(shared)) {
    cli::cli_abort(
      c("{.path {shared}} is a link or a folder, so the report cannot read it.",
        "i" = "Replace it with the template's file, then run this function again. Nothing was written."),
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
  on.exit(if (!done) remove_made(made))
  if (!dir.exists(folder)) {
    if (!dir.create(folder, showWarnings = FALSE)) {
      write_error("Could not make the folder {.path {folder}}.")
    }
    made <- c(made, folder)
  }
  copied <- !file.exists(shared)
  if (copied) {
    if (!dir.exists(scripts)) {
      if (!dir.create(scripts, showWarnings = FALSE)) {
        write_error("Could not make the folder {.path {scripts}}.")
      }
      made <- c(made, scripts)
    }
    made <- c(made, shared)
    template <- system.file("template", "_scripts", "report.R", package = "supplement", mustWork = TRUE)
    write_checked(readBin(template, "raw", file.size(template)), shared)
  }
  made <- c(made, report)
  order <- next_report_order(path)
  text <- paste0(paste(report_lines(title, description, order), collapse = "\n"), "\n")
  write_checked(charToRaw(enc2utf8(text)), report)
  write_text_lines(edit$read, edit$lines, config)
  done <- TRUE

  cli::cli_inform(c(
    "v" = "Wrote {.file {href}} and added it to the Analyses menu in {.file _quarto.yml}.",
    "v" = if (copied) "Copied the template's {.file _scripts/report.R}, which the report reads. Commit it with the report.",
    "i" = "Run {.code quarto render {href}} in {.path {path}}, or {.code render_supplement(\"{name}\")} in R, to run the report."
  ))
  invisible(report)
}

# The `order` of a new report, as text, or NULL for none. The home page's
# listing puts reports with a numeric `order` first, by that value, and
# the others after them by title. The new report goes after every report
# that has an `order`: the next whole number after the largest. A site
# whose reports all lack an `order` lists them by title, and an `order`
# would put the new report first, so it gets none. An `order` that the
# yaml package reads as text, or of a million or more, counts as none. The
# cap keeps the written whole number well inside the range that the yaml
# package reads as an integer: it reads 3000000000 as NA.
next_report_order <- function(path) {
  reports <- analysis_reports(path)
  if (length(reports) == 0) {
    return("1")
  }
  orders <- unlist(lapply(reports, function(report) {
    # Quarto reads the front matter of a report that starts with a UTF-8
    # BOM, so drop it.
    lines <- read_report_lines(report)
    lines[1] <- sub("^\xef\xbb\xbf", "", lines[1], useBytes = TRUE)
    order <- report_front_matter(lines)[["order"]]
    if (is.numeric(order) && length(order) == 1 && is.finite(order) && abs(order) < 1e6) order
  }))
  if (length(orders) == 0) {
    return(NULL)
  }
  sprintf("%.0f", floor(max(orders)) + 1)
}

report_lines <- function(title, description, order = NULL) {
  c(
    "---",
    paste0("title: ", yaml_quote(title)),
    if (nzchar(description)) paste0("description: ", yaml_quote(description)),
    if (!is.null(order)) paste0("order: ", order),
    "---",
    "",
    "Write the report here. The `site` chunk finds the site folder, so the",
    "report reads a data file as `file.path(site, \"data\", \"<file name>\")`.",
    "",
    site_chunk(),
    "",
    "```{r}",
    "#| label: setup",
    "set.seed(2026)",
    "```",
    "",
    environment_section()
  )
}

# The "Computing environment" section that ends the template's example
# report, from its heading to the end of the file, so that every new report
# ends with the same lines.
environment_section <- function() {
  lines <- example_lines()
  start <- which(lines == "## Computing environment")
  stopifnot(length(start) == 1L)
  lines[start:length(lines)]
}

# The `site` chunk of the template's example report, from its opening fence
# to its closing fence, so that every new report finds the site folder the
# same way.
site_chunk <- function() {
  lines <- example_lines()
  label <- which(lines == "#| label: site")
  stopifnot(length(label) == 1L, label > 1L, lines[label - 1L] == "```{r}")
  ends <- which(lines == "```")
  lines[(label - 1L):min(ends[ends > label])]
}

example_lines <- function() {
  example <- system.file("template", "analyses", "example.qmd", package = "supplement", mustWork = TRUE)
  readLines(example, encoding = "UTF-8", warn = FALSE)
}
