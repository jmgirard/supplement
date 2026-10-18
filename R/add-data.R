#' Add a data file to a supplement site
#'
#' `add_data()` copies a file into the site's `data/` folder and adds it as
#' the last item of the `data` list in `_supplement.yml`. The data table on
#' the home page of a site made from the template lists each file in that
#' list, with its description, its size, and a download link.
#'
#' If `file` is already in the site's `data/` folder, the function copies
#' nothing and only adds it to the list. Every file in `data/` is published
#' on the site, so add only data that you can share.
#'
#' The function adds lines to `_supplement.yml` as text, so the other lines
#' of the file, its comments included, stay as they are. It finds the
#' `data` list under `supplement:` in block style, with each item on its own
#' line after a `-`. The description is written as a YAML string in double
#' quotes.
#'
#' @param file The path of the data file. Its base name must be ASCII
#'   letters, digits, `.`, `-`, and `_`, with no two of the symbols in a
#'   row and no `.` at the start. Quarto reads each value in
#'   `_supplement.yml` as Markdown, and these names stay as they are.
#' @param description A short description of the file for the data table.
#' @param path The folder of the site.
#'
#' @return The path of the file in the site's `data/` folder, invisibly.
#'
#' @section Errors:
#' The function writes and copies nothing when it stops. Its errors have the
#' class `supplement_error` and one of these classes:
#'
#' * `supplement_error_argument`: `path` is not a single non-empty string,
#'   `file` is not a single string, or `description` is not a single
#'   string.
#' * `supplement_error_no_file`: `file` does not exist or is a folder.
#' * `supplement_error_line_break`: `description` holds a line break.
#' * `supplement_error_file_name`: the base name of `file` does not follow
#'   the file-name rule above.
#' * `supplement_error_no_metadata`: `path` holds no `_supplement.yml`.
#' * `supplement_error_file_exists`: `data/<base name>` exists and is not
#'   `file`, or `data` is not a folder.
#' * `supplement_error_already_listed`: `data/<base name>` is already in
#'   the `data` list.
#' * `supplement_error_no_data_list`: `_supplement.yml` has no `data` list
#'   in block style under `supplement:`. An empty list written as
#'   `data: []` is not in block style. The error shows the lines to add by
#'   hand.
#' * `supplement_error_yaml`: the yaml package does not read the changed
#'   `_supplement.yml` as the old list with the new item added. The error
#'   shows the lines to add by hand.
#' * `supplement_error_encoding`: `_supplement.yml` is not UTF-8 text.
#'
#' @seealso [add_report()] to add a report, and [create_supplement()] to
#'   make a site.
#' @export
#' @examples
#' site <- file.path(tempdir(), "data-example")
#' create_supplement(site)
#' scores <- file.path(tempdir(), "scores.csv")
#' write.csv(data.frame(id = 1:3, score = c(4, 7, 5)), scores, row.names = FALSE)
#' add_data(scores, "Scores of each participant", path = site)
#' list.files(file.path(site, "data"))
#' unlink(c(site, scores), recursive = TRUE)
add_data <- function(file, description, path = ".") {
  check_path(path)
  if (!is.character(file) || length(file) != 1 || is.na(file)) {
    cli::cli_abort(
      "{.arg file} must be one file path, given as a single string.",
      class = c("supplement_error_argument", "supplement_error")
    )
  }
  if (!file.exists(file) || dir.exists(file)) {
    cli::cli_abort(
      "{.path {file}} does not exist or is a folder.",
      class = c("supplement_error_no_file", "supplement_error")
    )
  }
  check_text(description, "description")
  base <- basename(file)
  if (!grepl("^(?!\\.)(?!.*[._-]{2})[A-Za-z0-9._-]+$", base, perl = TRUE)) {
    cli::cli_abort(
      c("The file name {.file {base}} cannot be listed in {.file _supplement.yml}.",
        "i" = "Use ASCII letters, digits, {.code .}, {.code -}, and {.code _}, with no two of those symbols in a row and no {.code .} at the start, because Quarto reads the name as Markdown.",
        "i" = "Rename the file, then add it."),
      class = c("supplement_error_file_name", "supplement_error")
    )
  }

  meta <- file.path(path, "_supplement.yml")
  if (!file.exists(meta) || dir.exists(meta)) {
    cli::cli_abort(
      c("No {.file _supplement.yml} in {.path {path}}.",
        "i" = "Run this function in the folder of a site made from the template."),
      class = c("supplement_error_no_metadata", "supplement_error")
    )
  }
  folder <- file.path(path, "data")
  if (path_occupied(folder) && !dir.exists(folder)) {
    cli::cli_abort(
      "{.path {folder}} is not a folder, so the file cannot be copied there.",
      class = c("supplement_error_file_exists", "supplement_error")
    )
  }
  target <- file.path(folder, base)
  same <- file.exists(target) && normalizePath(target) == normalizePath(file)
  if (path_occupied(target) && !same) {
    cli::cli_abort(
      c("{.file data/{base}} already exists in {.path {path}} and is not {.path {file}}.",
        "i" = "Rename the file, or remove the one in {.file data/}. Nothing was written."),
      class = c("supplement_error_file_exists", "supplement_error")
    )
  }

  listed <- paste0("data/", base)
  item <- c(file = listed, description = description)
  hand <- c(
    "supplement:",
    "  data:",
    paste0("    - file: ", yaml_quote(listed)),
    paste0("      description: ", yaml_quote(description))
  )
  data_path <- list("supplement", "data")
  edit <- append_item(
    meta, list(data_path), item,
    missing = "{.file _supplement.yml} has no {.field data} list in block style under {.field supplement:}, so nothing was written.",
    missing_class = "supplement_error_no_data_list",
    hand = hand
  )
  doc <- yaml::yaml.load(paste(edit$read$lines, collapse = "\n"), handlers = list(seq = function(x) as.list(x)))
  files <- vapply(yaml_get(doc, data_path), function(x) {
    f <- if (is_map(x)) x[["file"]]
    if (is.character(f) && length(f) == 1) sub("^(\\./)+", "", f) else NA_character_
  }, "")
  if (listed %in% files) {
    cli::cli_abort(
      c("{.file {listed}} is already in the {.field data} list in {.file _supplement.yml}.",
        "i" = "Nothing was written."),
      class = c("supplement_error_already_listed", "supplement_error")
    )
  }

  made <- character()
  done <- FALSE
  on.exit(if (!done) unlink(rev(made), recursive = TRUE))
  if (!same) {
    if (!dir.exists(folder)) {
      if (!dir.create(folder, showWarnings = FALSE)) {
        write_error("Could not make the folder {.path {folder}}.")
      }
      made <- c(made, folder)
    }
    made <- c(made, target)
    if (!file.copy(file, target, overwrite = FALSE, copy.mode = FALSE)) {
      write_error("Could not copy {.path {file}} to {.path {target}}.")
    }
  }
  write_text_lines(edit$read, edit$lines, meta)
  done <- TRUE

  cli::cli_inform(c(
    "v" = if (same) {
      "Added {.file {listed}} to the {.field data} list in {.file _supplement.yml}."
    } else {
      "Copied {.path {file}} to {.file {listed}} and added it to the {.field data} list in {.file _supplement.yml}."
    },
    "i" = "Every file in {.file data/} is published on the site."
  ))
  invisible(target)
}
