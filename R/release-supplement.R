#' Raise the site version and print the release commands
#'
#' `release_supplement()` prepares a release of a site. It runs
#' [check_supplement()] and stops when that finds a problem. It then raises
#' `version` in `_supplement.yml`, writes `CITATION.cff` and `.zenodo.json`
#' again with the new version, and prints the git and GitHub commands that
#' make the release. It runs none of these commands, so you can read them
#' first and run them yourself in the site folder.
#'
#' `bump` is one of:
#'
#' * `"patch"`, `"minor"`, or `"major"`: raise that part of the version by
#'   1 and set the parts after it to 0. `"minor"` makes `1.9.3` into
#'   `1.10.0`. An empty `version` counts as `0.0.0`, so `"major"` gives a
#'   first release `1.0.0`.
#' * A version such as `"1.0.0"`: three whole numbers joined by `.`, each
#'   `0` or without a leading zero. It must be greater than the current
#'   version, compared part by part as numbers, so `1.10.0` is greater than
#'   `1.9.0`.
#'
#' The function stops, and changes no file, when [check_supplement()]
#' finds a problem or skips its git checks. A `"doi-mismatch"` problem for
#' `CITATION.cff` does not stop it, because the release writes that file
#' again.
#'
#' Only the value on the `version:` line of `_supplement.yml` changes, so
#' its comments and the rest of its text stay as they are. The new value is
#' written in double quotes. The line must be a one-line `version:` value
#' directly under `supplement:`, as in the template. When it is missing,
#' add `version: ""` under `supplement:` by hand. The function reads
#' `_supplement.yml` before it runs [check_supplement()] and writes that
#' text back with the new version, so a change saved to the file while the
#' function runs is lost.
#'
#' Before it changes any file, the function stops when `CITATION.cff` or
#' `.zenodo.json` is a link, because a write would go through the link, or
#' is a file that it cannot read or write. It also stops when one of them
#' does not exist and its folder cannot be written.
#' If writing `_supplement.yml`, `CITATION.cff`, or `.zenodo.json`, or
#' printing the commands, stops, for example when [write_zenodo()] finds no
#' `citation`, the function puts back the old text of each of these files
#' that changed, removes each one that it made, and stops.
#'
#' The printed commands, for version `X.Y.Z`, are `git status`,
#' `git add -A`, `git commit -m "Release vX.Y.Z"`, `git tag vX.Y.Z`,
#' `git push`, `git push origin vX.Y.Z`, and
#' `gh release create vX.Y.Z --generate-notes`. `git add -A` adds every file
#' in the git repository that git does not ignore, also files outside the
#' site folder. When the site folder is the top of the repository, these are
#' the files that the git checks of [check_supplement()] read, so `docs/`
#' and `_freeze/` reach the release. The last command
#' needs the GitHub command-line tool (`gh`). When Zenodo's GitHub
#' integration is turned on for the repository, Zenodo archives the release
#' and gives it a version DOI. Add that DOI to `zenodo.version-doi` in
#' `_supplement.yml`, and render the site again, so that the home page shows
#' it.
#'
#' @param bump `"patch"`, `"minor"`, `"major"`, or a version such as
#'   `"1.0.0"`.
#' @param path The folder of the site.
#'
#' @return The release commands as a character vector, invisibly.
#'
#' @section Errors:
#' A `_supplement.yml` that is not valid YAML gives the error of the YAML
#' parser. Otherwise the function stops with an error of class
#' `supplement_error` and one of these classes. When it stops, no file is
#' changed, unless a file that changed cannot be put back. The
#' `supplement_error_release_write` message then names that file.
#'
#' * `supplement_error_argument`: `bump` is not one of the forms above, or
#'   `path` is not a single non-empty string.
#' * `supplement_error_no_metadata`, `supplement_error_no_map`: as for
#'   [write_citation()].
#' * `supplement_error_encoding`: `_supplement.yml` is not UTF-8 text.
#' * `supplement_error_field_type`: `version` is a list, or YAML reads it
#'   as a number or as true/false, such as an unquoted `1.10`. Write it as
#'   one value in quotes, such as `"1.10.0"`. [check_supplement()] also stops with this class, for a DOI
#'   that is not one text value or a `zenodo` that is not a map.
#' * `supplement_error_doi`: a DOI in `_supplement.yml` is not a DOI, as
#'   for [check_supplement()].
#' * `supplement_error_version`: `version` is not empty and is not a
#'   version, or the version in `bump` is not greater than it.
#' * `supplement_error_no_version`: `_supplement.yml` has no one-line
#'   `version:` value directly under `supplement:`.
#' * `supplement_error_yaml`: the yaml package does not read the changed
#'   `_supplement.yml` as the old file with the new version.
#' * `supplement_error_release_check`: [check_supplement()] found a problem
#'   other than a `"doi-mismatch"` problem for `CITATION.cff`, or it
#'   skipped its git checks.
#' * `supplement_error_file_exists`: `CITATION.cff` or `.zenodo.json` is a
#'   link.
#' * `supplement_error_write`: `CITATION.cff` or `.zenodo.json` cannot be
#'   read or written, or one of them does not exist and the site folder
#'   cannot be written.
#' * `supplement_error_release_write`: a write of `_supplement.yml`,
#'   `CITATION.cff`, or `.zenodo.json`, or the printing of the commands,
#'   stopped, and the files that changed got their old text back, and each
#'   file that the release made was removed. If a file
#'   cannot be put back, the message names it. The error of the step is the
#'   `parent` of this error.
#'
#' @seealso [check_supplement()] for the checks, and [write_citation()] and
#'   [write_zenodo()] for the files that the release writes again.
#' @export
#' @examples
#' \dontrun{
#' # In the folder of a rendered site in a git repository:
#' release_supplement("major")
#' }
release_supplement <- function(bump, path = ".") {
  if (missing(bump)) {
    bump <- NULL
  }
  check_bump(bump)
  # Drop names and a class (an S4 one included), so that the version
  # written is a plain string.
  bump <- as.character(bump)
  attributes(bump) <- NULL
  check_path(path)
  path <- drop_trailing_sep(path)
  meta <- read_supplement(path)
  current <- read_version(meta)
  new <- next_version(current, bump)

  file <- file.path(path, "_supplement.yml")
  read <- read_text_lines(file)
  version_path <- c("supplement", "version")
  lines <- yaml_replace_lines(read$lines, version_path, new)
  hand <- sprintf("version: %s", yaml_quote(current %||% ""))
  if (is.null(lines)) {
    abort_with_lines(
      c("{.file _supplement.yml} has no one-line {.field version:} value directly under {.field supplement:}, so nothing was changed.",
        "i" = "Add this line under {.field supplement:}, at the indent of {.field paper-title:}, or make the {.field version:} line look like it:"),
      hand,
      class = "supplement_error_no_version"
    )
  }
  if (!yaml_replaced(read$lines, lines, version_path, new)) {
    abort_with_lines(
      c("Could not change the version in {.file _supplement.yml} as text, so nothing was changed.",
        "i" = "Change the {.field version:} line under {.field supplement:} by hand to:"),
      sprintf("version: %s", yaml_quote(new)),
      class = "supplement_error_yaml"
    )
  }

  outputs <- file.path(path, c("CITATION.cff", ".zenodo.json"))
  old <- read_outputs(outputs)

  problems <- check_supplement(path)
  check_release_problems(problems)

  commands <- release_commands(new)
  write_release_files(read, lines, file, outputs, old, report = function() {
    report_release(path, new, commands)
  })
  invisible(commands)
}

# The bytes of each output file, or NULL for a file that does not exist
# or is a folder. A link, a file that cannot be read or written, or a
# missing file whose folder cannot be written stops before any write: the
# release would write through the link, maybe outside the site, could not
# put back a file that it cannot read, and would stop at a file that it
# cannot write only after it changed _supplement.yml.
read_outputs <- function(outputs, call = parent.frame()) {
  lapply(outputs, function(output) {
    if (is_link(output)) {
      cli::cli_abort(
        c("{.file {basename(output)}} is a link, so nothing was changed.",
          "i" = "Replace the link with the file itself, or remove it, and run this function again."),
        class = c("supplement_error_file_exists", "supplement_error"),
        call = call
      )
    }
    if (dir.exists(output)) {
      return(NULL)
    }
    if (!file.exists(output)) {
      # The release makes the file, so its folder must be writable.
      if (file.access(dirname(output), 2) != 0) {
        cli::cli_abort(
          c("Could not write {.file {basename(output)}} in {.path {dirname(output)}}, so nothing was changed.",
            "i" = "Make the folder writable, and run this function again."),
          class = c("supplement_error_write", "supplement_error"),
          call = call
        )
      }
      return(NULL)
    }
    bytes <- read_bytes_or_null(output)
    if (is.null(bytes)) {
      cli::cli_abort(
        "Could not read {.file {basename(output)}}, so nothing was changed.",
        class = c("supplement_error_write", "supplement_error"),
        call = call
      )
    }
    if (file.access(output, 2) != 0) {
      cli::cli_abort(
        c("Could not write {.file {basename(output)}}, so nothing was changed.",
          "i" = "Make the file writable, and run this function again."),
        class = c("supplement_error_write", "supplement_error"),
        call = call
      )
    }
    bytes
  })
}

read_bytes_or_null <- function(file) {
  tryCatch(
    suppressWarnings(readBin(file, "raw", file.size(file))),
    error = function(e) NULL
  )
}

# `bump` is not trimmed, unlike a value read from _supplement.yml: an
# argument with a space or a line break around it is refused.
check_bump <- function(bump, call = parent.frame()) {
  ok <- is.character(bump) && length(bump) == 1 && !is.na(bump) &&
    (bump %in% c("patch", "minor", "major") || is_version(bump))
  if (!ok) {
    cli::cli_abort(
      c("{.arg bump} must be {.val patch}, {.val minor}, {.val major}, or a version such as {.val 1.0.0}.",
        "i" = "A version is three whole numbers joined by {.code .}, with no leading zero."),
      class = c("supplement_error_argument", "supplement_error"),
      call = call
    )
  }
  invisible()
}

# The version after `current` for `bump`, a word or a version. A version
# that is not greater than `current` is an error.
next_version <- function(current, bump, call = parent.frame()) {
  shown <- if (is.null(current)) "empty, which counts as 0.0.0" else current
  current <- current %||% "0.0.0"
  parts <- strsplit(current, ".", fixed = TRUE)[[1]]
  if (bump %in% c("patch", "minor", "major")) {
    i <- match(bump, c("major", "minor", "patch"))
    parts[i] <- add_one(parts[i])
    parts[seq_len(3) > i] <- "0"
    return(paste(parts, collapse = "."))
  }
  if (compare_versions(bump, current) <= 0) {
    cli::cli_abort(
      c("The new version {.val {bump}} is not greater than the current version ({shown}), so nothing was changed.",
        "i" = "Give a greater version, or {.val patch}, {.val minor}, or {.val major}."),
      class = c("supplement_error_version", "supplement_error"),
      call = call
    )
  }
  bump
}

# 1 when version `a` is greater than `b`, -1 when it is smaller, and 0
# when they are equal, part by part as whole numbers. The parts have no
# leading zeros, so a longer part is the greater one, and in parts of equal
# length the first digit that differs decides. A part is not read as one
# number, so a part larger than R can hold as a whole number still
# compares exactly.
compare_versions <- function(a, b) {
  a <- strsplit(a, ".", fixed = TRUE)[[1]]
  b <- strsplit(b, ".", fixed = TRUE)[[1]]
  for (i in seq_along(a)) {
    if (nchar(a[i]) != nchar(b[i])) {
      return(sign(nchar(a[i]) - nchar(b[i])))
    }
    if (a[i] != b[i]) {
      # The first digit that differs decides, read as a number so that the
      # locale's text order plays no part.
      da <- as.integer(strsplit(a[i], "", fixed = TRUE)[[1]])
      db <- as.integer(strsplit(b[i], "", fixed = TRUE)[[1]])
      j <- which(da != db)[1]
      return(sign(da[j] - db[j]))
    }
  }
  0
}

# A whole number written in digits, plus 1, written in digits.
add_one <- function(x) {
  digits <- as.integer(strsplit(x, "", fixed = TRUE)[[1]])
  i <- length(digits)
  while (i > 0 && digits[i] == 9L) {
    digits[i] <- 0L
    i <- i - 1L
  }
  if (i == 0) {
    digits <- c(1L, digits)
  } else {
    digits[i] <- digits[i] + 1L
  }
  paste(digits, collapse = "")
}

# Stop when check_supplement() skipped its git checks or found a problem
# that the release does not fix. The release writes CITATION.cff again, so
# a DOI problem for that file does not count.
check_release_problems <- function(problems, call = parent.frame()) {
  skipped <- attr(problems, "skipped")
  fixed <- problems$check == "doi-mismatch" & problems$file == "CITATION.cff"
  n <- sum(!fixed)
  if (n == 0 && length(skipped) == 0) {
    return(invisible())
  }
  cli::cli_abort(
    c("{.fn check_supplement} found {n} problem{?s} that the release does not fix, so nothing was changed.",
      if (length(skipped) > 0) "It skipped the {.val {skipped}} check{?s}, and a release needs every check.",
      "i" = "Fix what {.fn check_supplement} printed, and run this function again."),
    class = c("supplement_error_release_check", "supplement_error"),
    call = call
  )
}

# Write `lines` to `_supplement.yml`, then CITATION.cff and .zenodo.json,
# then call `report()`. `old` holds the bytes of each output before the
# release, or NULL for an output that did not exist, from read_outputs().
# When any of these steps stops, or the function is interrupted, each file
# whose bytes changed gets its old bytes back, and each file that did not
# exist before is removed. A file that is as it was is not written again.
write_release_files <- function(read, lines, file, outputs, old, report, call = parent.frame()) {
  path <- dirname(file)
  files <- c(file, outputs)
  before <- c(list(read$bytes), old)
  # The names of the files that could not be put back, or an empty vector.
  restore <- function() {
    failed <- character()
    for (i in seq_along(files)) {
      target <- files[i]
      if (is.null(before[[i]])) {
        if (path_occupied(target) && !dir.exists(target)) {
          # unlink() reads `[`, `*`, and `?` in the path as a pattern, so it
          # could remove a file in another folder. file.remove() does not.
          suppressWarnings(file.remove(target))
          if (path_occupied(target)) failed <- c(failed, basename(target))
        }
        next
      }
      now <- if (file.exists(target) && !dir.exists(target)) read_bytes_or_null(target)
      if (identical(now, before[[i]])) {
        next
      }
      ok <- tryCatch({
        write_checked(before[[i]], target)
        TRUE
      }, error = function(e) FALSE)
      if (!ok) failed <- c(failed, basename(target))
    }
    failed
  }
  done <- FALSE
  on.exit(
    if (!done) {
      failed <- restore()
      if (length(failed) > 0) {
        cli::cli_warn(c(
          "The release was interrupted, and {.file {failed}} could not be put back.",
          "!" = "Check {.file {failed}} by hand, for example with {.code git diff}."
        ))
      }
    },
    add = TRUE
  )
  tryCatch(
    {
      write_text_lines(read, lines, file)
      write_citation(path, overwrite = TRUE)
      write_zenodo(path, overwrite = TRUE)
      report()
    },
    error = function(e) {
      failed <- restore()
      done <<- TRUE
      cli::cli_abort(
        if (length(failed) == 0) {
          c("The release stopped before it finished, so nothing was changed.",
            "i" = "{.file _supplement.yml}, {.file CITATION.cff}, and {.file .zenodo.json} are as they were before the release, even if a message above says that they were written.")
        } else {
          c("The release stopped before it finished, and {.file {failed}} could not be put back.",
            "!" = "Check {.file {failed}} by hand, for example with {.code git diff}.")
        },
        parent = e,
        class = c("supplement_error_release_write", "supplement_error"),
        call = call
      )
    }
  )
  done <- TRUE
  invisible()
}

release_commands <- function(version) {
  tag <- paste0("v", version)
  c(
    "git status",
    "git add -A",
    sprintf('git commit -m "Release %s"', tag),
    paste("git tag", tag),
    "git push",
    paste("git push origin", tag),
    sprintf("gh release create %s --generate-notes", tag)
  )
}

report_release <- function(path, version, commands) {
  cli::cli_alert_success(
    "Set {.field version} to {.val {version}} in {.file _supplement.yml}, and wrote {.file CITATION.cff} and {.file .zenodo.json}."
  )
  cli::cli_text("Run these commands in {.path {path}} to make the release. {.code git status} shows the files that {.code git add -A} adds.")
  cli::cli_code(commands)
  cli::cli_text(
    "After Zenodo archives the release, add its new version DOI to {.field zenodo.version-doi} in {.file _supplement.yml}, and render the site again."
  )
  invisible()
}
