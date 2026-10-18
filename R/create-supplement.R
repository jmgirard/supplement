#' Make a new supplement site from the template
#'
#' `create_supplement()` copies the package's Quarto website template into
#' `path`. It copies the same files as `quarto use template
#' jmgirard/supplement/inst/template`, but it needs no Quarto command-line
#' interface and no network.
#'
#' `path` can be a new folder or an existing one, such as a clone of a new
#' GitHub repository. The function never replaces a file: if `path` already
#' holds a file or a folder where the template writes a file, or a file
#' where the template needs a folder, it stops before it writes anything.
#'
#' The template ships `_gitignore` and `_README.md` under those names. The
#' first `quarto render` gives them their real names. It adds the
#' template's rules to an existing `.gitignore`. If `README.md` exists, the
#' guide goes to `SUPPLEMENT.md` instead. Render the site once before your
#' first commit.
#'
#' @param path The folder for the site. It is made if it does not exist.
#' @param repo The GitHub repository of the site, as `"owner/name"`, or
#'   `NULL`. When given, it replaces each `OWNER/REPO` placeholder in
#'   `_quarto.yml`, and the GitHub Pages address in `_README.md` becomes
#'   `https://<owner>.github.io/<name>/` with the owner in lowercase. For a
#'   repository named `<owner>.github.io`, the address is
#'   `https://<owner>.github.io/`. When `NULL`, the placeholders stay for
#'   you to edit.
#'
#' @return `path`, invisibly.
#'
#' @section Errors:
#' The errors that the function raises itself have the class
#' `supplement_error` and one of these classes:
#'
#' * `supplement_error_argument`: `path` is not a single non-missing,
#'   non-empty character string.
#' * `supplement_error_repo`: `repo` is not `NULL` or a single string of
#'   the form `owner/name`, made of ASCII letters, digits, `-`, `_`, and
#'   `.`.
#' * `supplement_error_not_folder`: `path` is an existing file.
#' * `supplement_error_file_exists`: `path` holds a file, a folder, or a
#'   link where the template writes a file, or a file where the template
#'   needs a folder.
#' * `supplement_error_write`: a folder could not be made or a file could
#'   not be copied, for example because a parent of `path` is a file. The
#'   function then removes the files and folders that it made.
#'
#' @seealso [write_citation()] and [write_zenodo()] for the citation files.
#' @export
#' @examples
#' site <- file.path(tempdir(), "my-supplement")
#' create_supplement(site, repo = "jdoe/my-supplement")
#' list.files(site, recursive = TRUE)
#' unlink(site, recursive = TRUE)
create_supplement <- function(path, repo = NULL) {
  check_path(path)
  check_repo(repo)
  if (file.exists(path) && !dir.exists(path)) {
    cli::cli_abort(
      "{.path {path}} is a file, so the site cannot be made there.",
      class = c("supplement_error_not_folder", "supplement_error")
    )
  }

  template <- system.file("template", package = "supplement", mustWork = TRUE)
  files <- list.files(template, recursive = TRUE, all.files = TRUE, no.. = TRUE)
  folders <- template_folders(files)
  check_conflicts(path, files, folders)

  # If a write fails, remove the files and folders that this call made,
  # the missing parents of `path` included.
  made <- character()
  done <- FALSE
  on.exit(if (!done) unlink(rev(made), recursive = TRUE))
  for (folder in c(missing_parents(path), file.path(path, folders))) {
    if (!dir.exists(folder)) {
      if (!dir.create(folder, showWarnings = FALSE)) {
        write_error("Could not make the folder {.path {folder}}.")
      }
      made <- c(made, folder)
    }
  }
  for (file in files) {
    target <- file.path(path, file)
    if (!file.copy(file.path(template, file), target, overwrite = FALSE)) {
      write_error("Could not copy {.file {file}} to {.path {path}}.")
    }
    made <- c(made, target)
  }
  if (!is.null(repo)) {
    fill_repo(path, repo)
  }
  done <- TRUE

  cli::cli_inform(c(
    "v" = "Made a supplement site in {.path {path}}.",
    if (is.null(repo)) {
      c("i" = "Replace {.code OWNER/REPO} in {.file _quarto.yml}, and {.code OWNER} and {.code REPO} in the site address in {.file _README.md}, with your GitHub repository.")
    },
    "i" = "Put the paper facts in {.file _supplement.yml}.",
    "i" = "Run {.code quarto render} in {.path {path}} once before your first commit."
  ))
  invisible(path)
}

# `path` and each of its parents that does not exist, outermost first.
missing_parents <- function(path) {
  out <- character()
  while (!dir.exists(path) && !file.exists(path)) {
    out <- c(path, out)
    parent <- dirname(path)
    if (parent == path) {
      break
    }
    path <- parent
  }
  out
}

write_error <- function(message, call = parent.frame(), .envir = parent.frame()) {
  cli::cli_abort(
    c(message, "i" = "The files and folders that this call made were removed."),
    class = c("supplement_error_write", "supplement_error"),
    call = call,
    .envir = .envir
  )
}

check_repo <- function(repo, call = parent.frame()) {
  if (is.null(repo)) {
    return(invisible())
  }
  if (!is.character(repo) || length(repo) != 1 || is.na(repo) ||
      !grepl("^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$", repo, perl = TRUE)) {
    cli::cli_abort(
      c("{.arg repo} must be a GitHub repository written as {.val owner/name}.",
        "i" = "Use only ASCII letters, digits, {.code -}, {.code _}, and {.code .} on each side of the {.code /}."),
      class = c("supplement_error_repo", "supplement_error"),
      call = call
    )
  }
  invisible()
}

# Every folder that holds a template file, parents before children.
template_folders <- function(files) {
  folders <- character()
  for (folder in unique(dirname(files))) {
    while (folder != ".") {
      folders <- c(folders, folder)
      folder <- dirname(folder)
    }
  }
  folders <- unique(folders)
  folders[order(nchar(folders))]
}

check_conflicts <- function(path, files, folders, call = parent.frame()) {
  if (!dir.exists(path)) {
    return(invisible())
  }
  # file.exists() is FALSE for a link whose target is missing.
  occupied <- function(target) {
    link <- Sys.readlink(target)
    file.exists(target) | (!is.na(link) & nzchar(link))
  }
  file_targets <- file.path(path, files)
  folder_targets <- file.path(path, folders)
  conflicts <- c(
    files[occupied(file_targets)],
    folders[occupied(folder_targets) & !dir.exists(folder_targets)]
  )
  if (length(conflicts) > 0) {
    cli::cli_abort(
      c("{.path {path}} already holds {cli::qty(length(conflicts))}{?a file/files} that the template writes: {.file {conflicts}}.",
        "i" = "Move {cli::qty(length(conflicts))}{?it/them} away or choose another folder. Nothing was written."),
      class = c("supplement_error_file_exists", "supplement_error"),
      call = call
    )
  }
  invisible()
}

fill_repo <- function(path, repo) {
  parts <- strsplit(repo, "/", fixed = TRUE)[[1]]
  owner <- tolower(parts[[1]])
  name <- parts[[2]]
  pages <- if (tolower(name) == paste0(owner, ".github.io")) {
    paste0("https://", owner, ".github.io/")
  } else {
    paste0("https://", owner, ".github.io/", name, "/")
  }
  replace_text(file.path(path, "_quarto.yml"), "OWNER/REPO", repo)
  replace_text(file.path(path, "_README.md"), "https://OWNER.github.io/REPO/", pages)
}

replace_text <- function(file, from, to) {
  text <- readChar(file, file.size(file), useBytes = TRUE)
  text <- gsub(from, to, text, fixed = TRUE, useBytes = TRUE)
  writeChar(text, file, eos = NULL, useBytes = TRUE)
}
