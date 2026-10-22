# Read and check the `supplement:` map in `_supplement.yml`.

check_args <- function(path, overwrite, call = parent.frame()) {
  check_path(path, call = call)
  if (!isTRUE(overwrite) && !isFALSE(overwrite)) {
    cli::cli_abort(
      "{.arg overwrite} must be {.code TRUE} or {.code FALSE}.",
      class = c("supplement_error_argument", "supplement_error"),
      call = call
    )
  }
  invisible()
}

check_path <- function(path, call = parent.frame()) {
  if (!is.character(path) || length(path) != 1 || is.na(path) || !nzchar(path)) {
    cli::cli_abort(
      "{.arg path} must be one folder path, given as a single string.",
      class = c("supplement_error_argument", "supplement_error"),
      call = call
    )
  }
  invisible()
}

# file.exists("file/") is FALSE on some systems, so drop the separators at
# the end. A root such as "/" or "C:/" keeps its separator.
drop_trailing_sep <- function(path) {
  sub("^(.*[^/\\\\:])[/\\\\]+$", "\\1", path)
}

read_supplement <- function(path, call = parent.frame()) {
  file <- supplement_file(path, call = call)
  # Read the text as yaml::read_yaml() does, which warns when the last line
  # has no line break. yaml_read_file_text() reads every sequence as a
  # list, so that a one-item sequence such as [A paper] is not taken for a
  # single value.
  con <- file(file, "rt", encoding = "UTF-8")
  text <- tryCatch(paste(readLines(con), collapse = "\n"), finally = close(con))
  supplement_map(yaml_read_file_text(text, file, call = call), call = call)
}

# The path of `_supplement.yml` in `path`, which must be a file.
supplement_file <- function(path, call = parent.frame()) {
  file <- file.path(path, "_supplement.yml")
  if (!file.exists(file) || dir.exists(file)) {
    cli::cli_abort(
      c("No {.file _supplement.yml} in {.path {path}}.",
        "i" = "Run this function in the folder of a site made from the template."),
      class = c("supplement_error_no_metadata", "supplement_error"),
      call = call
    )
  }
  file
}

# The `supplement` map of a parsed `_supplement.yml`.
supplement_map <- function(doc, call = parent.frame()) {
  meta <- if (is_map(doc)) doc[["supplement"]]
  if (!is_map(meta)) {
    cli::cli_abort(
      c("{.file _supplement.yml} has no {.field supplement} map.",
        "i" = "Put the paper facts under a top-level {.field supplement:} key, as the template does."),
      class = c("supplement_error_no_map", "supplement_error"),
      call = call
    )
  }
  meta
}

is_map <- function(x) {
  is.list(x) && !is.null(names(x))
}

is_empty <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return(TRUE)
  }
  if (is.list(x)) {
    return(FALSE)
  }
  all(is.na(x) | !nzchar(clean_space(as.character(x))))
}

# Make each run of spaces and line breaks (Unicode ones included) one
# space, and remove them at the start and end.
clean_space <- function(x) {
  x <- gsub("[\\h\\v]+", " ", x, perl = TRUE)
  gsub("^ | $", "", x, perl = TRUE)
}

field_type_error <- function(field, what, call) {
  cli::cli_abort(
    "{.field {field}} in {.file _supplement.yml} must be {what}.",
    class = c("supplement_error_field_type", "supplement_error"),
    call = call
  )
}

# A single text value with its spaces cleaned (clean_space()), or NULL
# when it is absent or empty. A list, several values, or a value that YAML
# read as a number or true/false is an error.
value <- function(x, field, call = parent.frame()) {
  if (is.null(x) || length(x) == 0) {
    return(NULL)
  }
  if (is.list(x) || length(x) > 1) {
    field_type_error(field, "one text value", call)
  }
  if (is.logical(x) && is.na(x)) {
    return(NULL)
  }
  if (!is.character(x)) {
    field_type_error(field, "text. YAML read it as a number or as true/false, so put it in quotes", call)
  }
  x <- clean_space(x)
  if (is.na(x) || !nzchar(x)) NULL else x
}

# A map such as `license` or `zenodo`, or an empty list when it is absent
# or empty. A value that is not a map is an error.
map_field <- function(meta, name, call = parent.frame()) {
  x <- meta[[name]]
  if (is_empty(x)) {
    return(list())
  }
  if (!is_map(x)) {
    field_type_error(paste0("supplement.", name), "a map of keys and values", call)
  }
  x
}

require_fields <- function(meta, fields, call = parent.frame()) {
  for (field in fields) {
    if (is.null(value(meta[[field]], paste0("supplement.", field), call))) {
      cli::cli_abort(
        "{.field supplement.{field}} in {.file _supplement.yml} is missing or empty.",
        class = c("supplement_error_missing_field", "supplement_error"),
        call = call
      )
    }
  }
  invisible(meta)
}

# The authors as a list of lists with `family`, `given`, `orcid` (bare iD
# or NULL), and `affiliation` (or NULL).
read_authors <- function(meta, call = parent.frame()) {
  authors <- meta[["authors"]]
  if (is_empty(authors)) {
    cli::cli_abort(
      c("{.field supplement.authors} in {.file _supplement.yml} is missing or empty.",
        "i" = "List each author with {.field family:} and {.field given:}."),
      class = c("supplement_error_authors", "supplement_error"),
      call = call
    )
  }
  if (!is.list(authors) || is_map(authors) ||
      !any(vapply(authors, is_map, logical(1)))) {
    cli::cli_abort(
      c("{.field supplement.authors} in {.file _supplement.yml} must be a list of authors.",
        "i" = "Start each author with {.code -}, and give each one {.field family:} and {.field given:}."),
      class = c("supplement_error_authors", "supplement_error"),
      call = call
    )
  }
  lapply(seq_along(authors), function(i) {
    author <- authors[[i]]
    hint <- NULL
    if (!is_map(author)) {
      author <- list()
      hint <- c("i" = "Write each author as {.field family:} and {.field given:} under one {.code -}, not as a single name.")
    }
    field <- function(name) sprintf("supplement.authors[%d].%s", i, name)
    family <- value(author[["family"]], field("family"), call)
    given <- value(author[["given"]], field("given"), call)
    if (is.null(family) || is.null(given)) {
      if (!is_empty(author[["name"]])) {
        hint <- c("i" = "Replace {.field name:} with {.field family:} (the family name) and {.field given:} (the given names).")
      }
      cli::cli_abort(
        c("Author {i} in {.file _supplement.yml} needs a {.field family} and a {.field given} name.",
          hint),
        class = c("supplement_error_author_name", "supplement_error"),
        call = call
      )
    }
    list(
      family = family,
      given = given,
      orcid = orcid_id(value(author[["orcid"]], field("orcid"), call), i, call = call),
      affiliation = value(author[["affiliation"]], field("affiliation"), call)
    )
  })
}

# Return the bare ORCID iD, or NULL when there is none.
orcid_id <- function(orcid, i, call = parent.frame()) {
  if (is.null(orcid)) {
    return(NULL)
  }
  id <- sub("^https?://orcid\\.org/", "", orcid)
  if (!grepl("^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$", id) ||
      orcid_check_digit(id) != substr(id, 19, 19)) {
    cli::cli_abort(
      c("The ORCID iD of author {i} in {.file _supplement.yml} is not valid: {.val {orcid}}.",
        "i" = "Write it as {.val 0000-0002-1825-0097} or {.val https://orcid.org/0000-0002-1825-0097}, and check each digit."),
      class = c("supplement_error_orcid", "supplement_error"),
      call = call
    )
  }
  id
}

# The last character of an ORCID iD is an ISO 7064 MOD 11-2 check digit
# over the first 15 digits:
# https://support.orcid.org/hc/en-us/articles/360006897674
orcid_check_digit <- function(id) {
  digits <- as.integer(strsplit(gsub("-", "", substr(id, 1, 18)), "")[[1]])
  total <- 0
  for (digit in digits) {
    total <- (total + digit) * 2
  }
  result <- (12 - total %% 11) %% 11
  if (result == 10) "X" else as.character(result)
}

# Return the DOI without a "doi:" or http(s)://(dx. or www.)doi.org/
# prefix, in any letter case, or NULL. A DOI that does not then start
# with "10." and a registrant code is an error.
bare_doi <- function(doi, field, call = parent.frame()) {
  if (is.null(doi)) {
    return(NULL)
  }
  bare <- sub("^(doi:\\s*|https?://((dx|www)\\.)?doi\\.org/)", "", doi,
              ignore.case = TRUE, perl = TRUE)
  if (!grepl("^10\\.[0-9]{4,9}/\\S+$", bare, perl = TRUE)) {
    cli::cli_abort(
      c("{.field {field}} in {.file _supplement.yml} is not a DOI: {.val {doi}}.",
        "i" = "Write it as {.val 10.5281/zenodo.1234567}."),
      class = c("supplement_error_doi", "supplement_error"),
      call = call
    )
  }
  bare
}

# Return the license id, or NULL. An id must have the shape of an SPDX
# short identifier (https://spdx.org/licenses/): letters or digits, then
# groups of one "." or "-" and more letters or digits, and at most one "+"
# at the end. A license name with spaces, such as "CC BY 4.0", or an
# expression of two ids is an error. So are "--", "..", and a "." or "-"
# at the end, which no id on the SPDX License List has. A LicenseRef- id
# can have them, and this rule refuses it. Quarto would also show "--" as
# a dash and "..." as an ellipsis in the page footer. The template's
# supplement-license shortcode applies the same rule. The shape check
# does not test that SPDX or Zenodo knows the id (D-012).
license_id <- function(id, field, call = parent.frame()) {
  if (is.null(id)) {
    return(NULL)
  }
  if (!grepl("\\A[A-Za-z0-9]+([.-][A-Za-z0-9]+)*\\+?\\z", id, perl = TRUE)) {
    cli::cli_abort(
      c("{.field {field}} in {.file _supplement.yml} is not an SPDX license id: {.val {id}}.",
        "i" = "Write one id of letters and digits, with one {.code .} or {.code -} between groups and at most one {.code +} at the end, such as {.val CC-BY-4.0} or {.val MIT}. See {.url https://spdx.org/licenses/}."),
      class = c("supplement_error_license", "supplement_error"),
      call = call
    )
  }
  id
}

# Refuses, in this order, a link at any of `files`, a folder at any of
# them, and, unless `overwrite` is TRUE, a file at any of them. A write
# would follow a link, even one whose target is missing, maybe out of the
# site, so a link is refused whatever `overwrite` is. On Windows,
# is_link() misses a file link to a missing file, which then reads as an
# existing file.
check_overwrite <- function(files, overwrite, call = parent.frame()) {
  link <- files[is_link(files)]
  if (length(link) > 0) {
    cli::cli_abort(
      c("{.path {link[[1]]}} is a link, so the file is not written there.",
        "i" = "Remove the link, then run this function again."),
      class = c("supplement_error_file_exists", "supplement_error"),
      call = call
    )
  }
  folder <- files[dir.exists(files)]
  if (length(folder) > 0) {
    cli::cli_abort(
      "{.path {folder[[1]]}} is a folder, so the file cannot be written there.",
      class = c("supplement_error_file_exists", "supplement_error"),
      call = call
    )
  }
  existing <- files[file.exists(files)]
  if (length(existing) > 0 && !isTRUE(overwrite)) {
    cli::cli_abort(
      c("{.file {existing[[1]]}} already exists.",
        "i" = "Use {.code overwrite = TRUE} to replace it."),
      class = c("supplement_error_file_exists", "supplement_error"),
      call = call
    )
  }
  invisible(files)
}

# TRUE for each path that holds a file, a folder, or a link.
# file.exists() is FALSE for a link whose target is missing (on Windows,
# for a junction or a folder link), and Sys.readlink() is NA for a path
# that does not exist.
path_occupied <- function(paths) {
  file.exists(paths) | is_link(paths)
}

is_link <- function(paths) {
  link <- Sys.readlink(paths)
  found <- !is.na(link) & nzchar(link)
  if (.Platform$OS.type == "windows") {
    found <- found | is_reparse_point(paths)
  }
  found
}

# On Windows, Sys.readlink() gives "" for a junction and for a symbolic
# link. So a path that its parent folder lists counts as a link when it
# does not exist, or when it resolves to a place other than its parent
# folder plus its own name, letter case ignored. A file link to a missing
# file passes both tests there (candidate row "Windows file links").
# Each parent folder is listed and normalized once, so that the paths of
# one folder take time that grows with their count, not its square.
is_reparse_point <- function(paths) {
  paths <- drop_trailing_sep(paths)
  parents <- dirname(paths)
  names <- basename(paths)
  found <- logical(length(paths))
  for (parent in unique(parents)) {
    i <- which(parents == parent)
    siblings <- list.files(parent, all.files = TRUE, no.. = TRUE)
    # tolower() stops on a name that is not valid UTF-8.
    siblings <- siblings[validUTF8(siblings)]
    name <- names[i]
    valid <- validUTF8(name)
    listed <- name %in% siblings
    listed[valid] <- listed[valid] | tolower(name[valid]) %in% tolower(siblings)
    # A listed name is valid UTF-8, since every sibling is.
    i <- i[listed]
    if (length(i) == 0) {
      next
    }
    missing <- !file.exists(paths[i])
    resolved <- normalizePath(paths[i], winslash = "/", mustWork = FALSE)
    # A drive root keeps its separator ("D:/"), so drop it before the join.
    folder <- sub("/+$", "", normalizePath(parent, winslash = "/", mustWork = FALSE))
    expected <- paste0(folder, "/", names[i])
    # A resolved path or a parent can still be invalid UTF-8.
    found[i] <- missing | utf8_lower(resolved) != utf8_lower(expected)
  }
  found
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Drop NULL entries from a list.
compact <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

# Write each line of `text` with "\n" after it. write_checked() stops with
# `supplement_error_write` on a warning (R only warns when the disk is
# full) or a file of another size.
write_utf8 <- function(text, file, call = parent.frame()) {
  bytes <- charToRaw(paste0(paste(enc2utf8(text), collapse = "\n"), "\n"))
  write_checked(bytes, file, call = call)
}

# The site version in `supplement.version`, or NULL when it is empty. A
# version is three whole numbers joined by ".", as in "1.0.0", each "0"
# or without a leading zero. Any other value is an error.
read_version <- function(meta, call = parent.frame()) {
  version <- value(meta[["version"]], "supplement.version", call)
  if (!is.null(version) && !is_version(version)) {
    version_error(
      "{.field supplement.version} in {.file _supplement.yml} is not a version: {.val {version}}.",
      version = version,
      call = call
    )
  }
  version
}

# The whole text must match. With perl = TRUE, `$` also matches before a
# final "\n", so the pattern ends with `\z`.
is_version <- function(x) {
  grepl("\\A(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\.(0|[1-9][0-9]*)\\z", x, perl = TRUE)
}

version_error <- function(message, version, call) {
  cli::cli_abort(
    c(message,
      "i" = "Write a version as three whole numbers joined by {.code .}, such as {.val 1.0.0}, with no leading zero."),
    class = c("supplement_error_version", "supplement_error"),
    call = call,
    .envir = environment()
  )
}

supplement_title <- function(meta, call = parent.frame()) {
  paste0(
    "Supplemental materials for: ",
    value(meta[["paper-title"]], "supplement.paper-title", call)
  )
}
