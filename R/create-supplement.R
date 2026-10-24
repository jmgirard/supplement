#' Make a new supplement site from the template
#'
#' `create_supplement()` copies the package's Quarto website template into
#' `path`. It is an R route in place of `quarto use template
#' jmgirard/supplement/inst/template`: it copies the template that is
#' installed with the package, and it needs no Quarto command-line
#' interface and no network.
#'
#' `path` can be a new folder or an existing one, such as a clone of a new
#' GitHub repository. The function never replaces a file and never follows
#' a link: if `path` already holds a file, a folder, or a link where the
#' template writes a file, or a file or a link where the template needs a
#' folder, it stops before it writes anything.
#'
#' The template ships `_gitignore` and `_README.md` under those names,
#' because `quarto use template` does not copy `.gitignore` or `README.md`.
#' The first `quarto render` gives them their real names, and that render adds
#' the template's rules to an existing `.gitignore`. `_README.md` is the
#' page for the site's readers. If `README.md` exists, the render keeps it
#' and removes `_README.md`. The guide for the site's authors is
#' `GUIDE.md`. Render the site once before your first commit.
#'
#' After it makes the site, the function runs the lookups of
#' [check_tools()]. Its closing message names each tool that is missing,
#' too old, or not on the system path. A tool never stops the function,
#' and the site is the same whether the tools are found or not.
#'
#' Hidden files and folders in the template folder are not copied, and
#' neither are `docs`, `_freeze`, or `_site` folders at its top level,
#' which hold render output.
#'
#' @param path The folder for the site. It is made if it does not exist.
#' @param repo The GitHub repository of the site, as `"owner/name"`, or
#'   `NULL`. When given, it replaces each `OWNER/REPO` placeholder in
#'   `_quarto.yml`, and the GitHub Pages address in `_README.md` and
#'   `GUIDE.md` becomes
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
#'   the form `owner/name`. The owner must be 1 to 39 ASCII letters and
#'   digits, with single `-` between them. The name must be 1 to 100 ASCII
#'   letters, digits, `-`, `_`, and `.`, and must not be `.` or `..`.
#' * `supplement_error_not_folder`: `path` is an existing file, or a link
#'   whose target is missing. A `/` at the end of `path` does not change
#'   this.
#' * `supplement_error_file_exists`: `path` holds a file, a folder, or a
#'   link where the template writes a file, or a file or a link where the
#'   template needs a folder.
#' * `supplement_error_write`: a folder could not be made, a file could not
#'   be copied, or the repository could not be written into a copied file,
#'   for example because a parent of `path` is a file. The function then
#'   removes the files and folders that it made.
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
  given <- path
  path <- drop_trailing_sep(path)
  if (path_occupied(path) && !dir.exists(path)) {
    cli::cli_abort(
      "{.path {path}} is a file or a broken link, so the site cannot be made there.",
      class = c("supplement_error_not_folder", "supplement_error")
    )
  }

  template <- template_path()
  files <- template_files(template)
  folders <- template_folders(files)
  check_conflicts(path, files, folders)

  # If a write fails, remove the files and folders that this call made,
  # the missing parents of `path` included.
  made <- character()
  done <- FALSE
  on.exit(if (!done) remove_made(made))
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
    # A failed file.copy() can leave an empty file, so record the target
    # first. The conflict check showed that nothing was there.
    made <- c(made, target)
    # copy.mode = FALSE, so that the copies are writable even when the
    # package is installed read-only.
    if (!file.copy(file.path(template, file), target, overwrite = FALSE, copy.mode = FALSE)) {
      write_error("Could not copy {.file {file}} to {.path {path}}.")
    }
  }
  if (!is.null(repo)) {
    here <- environment()
    tryCatch(fill_repo(path, repo), error = function(e) {
      reason <- conditionMessage(e)
      write_error("Could not write {.val {repo}} into the copied files: {reason}", call = here)
    })
  }
  done <- TRUE

  tools <- tool_problems()
  cli::cli_inform(c(
    "v" = "Made a supplement site in {.path {path}}.",
    if (is.null(repo)) {
      c("i" = "Replace {.code OWNER/REPO} in {.file _quarto.yml}, and {.code OWNER} and {.code REPO} in the site address in {.file _README.md}, with your GitHub repository.")
    },
    "i" = "Put the paper facts in {.file _supplement.yml}.",
    "i" = "Run {.code quarto render} in {.path {path}} once before your first commit.",
    # Each line refers to an element of `tools`, so that cli reads the
    # tool text as a value and not as markup.
    named_all(sprintf("{tools[%d]}", seq_along(tools)), "!"),
    if (length(tools) > 0L) {
      c("i" = "Run {.code check_tools()} to see every tool that the site needs.")
    }
  ))
  invisible(given)
}

# One line for each row of the check_tools() lookups whose status is
# missing, too old, or not on path. A tool row never stops site setup, so
# an error or a warning in the lookups gives no line.
tool_problems <- function() {
  rows <- tryCatch(tool_rows(), error = function(e) NULL, warning = function(w) NULL)
  if (is.null(rows)) {
    return(character())
  }
  tool_lines(rows[rows$status %in% c("missing", "too old", "not on path"), ])
}

# `x` with every element named `name`.
named_all <- function(x, name) {
  names(x) <- rep(name, length(x))
  x
}

template_path <- function() {
  system.file("template", package = "supplement", mustWork = TRUE)
}

# The template's files, as paths relative to `template`. Hidden files, and
# the output of a render of the template folder itself, are left out.
template_files <- function(template) {
  files <- list.files(template, recursive = TRUE)
  top <- sub("/.*$", "", files)
  files[!top %in% c("docs", "_freeze", "_site")]
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

# Remove the files and folders that a call made. unlink() reads `[`, `*`,
# and `?` in a path as a pattern unless `expand = FALSE`, and then it also
# skips `~`, so expand that first.
remove_made <- function(made) {
  unlink(path.expand(rev(made)), recursive = TRUE, expand = FALSE)
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
  # GitHub owners are letters and digits with single hyphens between them.
  # Repository names are letters, digits, "-", "_", and ".", but not "."
  # or "..".
  # GitHub allows at most 39 characters in an owner and 100 in a name.
  pattern <- "^(?=[^/]{1,39}/[^/]{1,100}$)[A-Za-z0-9]+(-[A-Za-z0-9]+)*/(?!\\.\\.?$)[A-Za-z0-9._-]+$"
  if (!is.character(repo) || length(repo) != 1 || is.na(repo) ||
      !grepl(pattern, repo, perl = TRUE)) {
    cli::cli_abort(
      c("{.arg repo} must be a GitHub repository written as {.val owner/name}.",
        "i" = "The owner is ASCII letters and digits, with single {.code -} between them.",
        "i" = "The name is ASCII letters, digits, {.code -}, {.code _}, and {.code .}, and is not {.code .} or {.code ..}."),
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
  file_targets <- file.path(path, files)
  folder_targets <- file.path(path, folders)
  conflicts <- c(
    files[path_occupied(file_targets)],
    # A link to a folder would make the copy write outside `path`.
    folders[path_occupied(folder_targets) &
              (!dir.exists(folder_targets) | is_link(folder_targets))]
  )
  if (length(conflicts) > 0) {
    cli::cli_abort(
      c("{.path {path}} already holds something where the template writes: {.file {conflicts}}.",
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
  for (file in c("_README.md", "GUIDE.md")) {
    replace_text(file.path(path, file), "https://OWNER.github.io/REPO/", pages)
  }
}

replace_text <- function(file, from, to) {
  text <- readChar(file, file.size(file), useBytes = TRUE)
  text <- gsub(from, to, text, fixed = TRUE, useBytes = TRUE)
  writeChar(text, file, eos = NULL, useBytes = TRUE)
}
