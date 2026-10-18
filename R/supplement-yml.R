# Read and check the `supplement:` map in `_supplement.yml`.

check_args <- function(path, overwrite, call = parent.frame()) {
  if (!is.character(path) || length(path) != 1 || is.na(path)) {
    cli::cli_abort(
      "{.arg path} must be one folder path, not {.obj_type_friendly {path}}.",
      class = c("supplement_error_argument", "supplement_error"),
      call = call
    )
  }
  if (!isTRUE(overwrite) && !isFALSE(overwrite)) {
    cli::cli_abort(
      "{.arg overwrite} must be {.code TRUE} or {.code FALSE}.",
      class = c("supplement_error_argument", "supplement_error"),
      call = call
    )
  }
  invisible()
}

read_supplement <- function(path, call = parent.frame()) {
  file <- file.path(path, "_supplement.yml")
  if (!file.exists(file) || dir.exists(file)) {
    cli::cli_abort(
      c("No {.file _supplement.yml} in {.path {path}}.",
        "i" = "Run this function in the folder of a site made from the template."),
      class = c("supplement_error_no_metadata", "supplement_error"),
      call = call
    )
  }
  meta <- yaml::read_yaml(file)
  meta <- if (is_map(meta)) meta[["supplement"]]
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
  all(is.na(x) | !nzchar(trimws(as.character(x))))
}

field_type_error <- function(field, what, call) {
  cli::cli_abort(
    "{.field {field}} in {.file _supplement.yml} must be {what}.",
    class = c("supplement_error_field_type", "supplement_error"),
    call = call
  )
}

# A single text value with outer spaces and line breaks removed, or NULL
# when it is absent or empty. A list or several values is an error.
value <- function(x, field, call = parent.frame()) {
  if (is_empty(x)) {
    return(NULL)
  }
  if (is.list(x) || length(x) > 1) {
    field_type_error(field, "one text value", call)
  }
  trimws(as.character(x))
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
  if (!is.list(authors) || is_map(authors)) {
    cli::cli_abort(
      c("{.field supplement.authors} in {.file _supplement.yml} must be a list of authors.",
        "i" = "Start each author with {.code -}, and give each one {.field family:} and {.field given:}."),
      class = c("supplement_error_authors", "supplement_error"),
      call = call
    )
  }
  lapply(seq_along(authors), function(i) {
    author <- authors[[i]]
    if (!is_map(author)) {
      author <- list()
    }
    field <- function(name) sprintf("supplement.authors[%d].%s", i, name)
    family <- value(author[["family"]], field("family"), call)
    given <- value(author[["given"]], field("given"), call)
    if (is.null(family) || is.null(given)) {
      hint <- if (!is_empty(author[["name"]])) {
        c("i" = "Replace {.field name:} with {.field family:} (the family name) and {.field given:} (the given names).")
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
  id <- sub("^https://orcid\\.org/", "", orcid)
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

# Return the DOI without an http(s)://(dx.)doi.org/ prefix, or NULL.
bare_doi <- function(doi) {
  if (is.null(doi)) {
    return(NULL)
  }
  sub("^https?://(dx\\.)?doi\\.org/", "", doi)
}

check_overwrite <- function(file, overwrite, call = parent.frame()) {
  if (dir.exists(file)) {
    cli::cli_abort(
      "{.path {file}} is a folder, so the file cannot be written there.",
      class = c("supplement_error_file_exists", "supplement_error"),
      call = call
    )
  }
  if (file.exists(file) && !isTRUE(overwrite)) {
    cli::cli_abort(
      c("{.file {file}} already exists.",
        "i" = "Use {.code overwrite = TRUE} to replace it."),
      class = c("supplement_error_file_exists", "supplement_error"),
      call = call
    )
  }
  invisible(file)
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Drop NULL entries from a list.
compact <- function(x) {
  x[!vapply(x, is.null, logical(1))]
}

write_utf8 <- function(text, file) {
  con <- file(file, open = "wb")
  on.exit(close(con))
  writeLines(enc2utf8(text), con, useBytes = TRUE)
}

supplement_title <- function(meta, call = parent.frame()) {
  paste0(
    "Supplemental materials for: ",
    value(meta[["paper-title"]], "supplement.paper-title", call)
  )
}
