# Read and check the `supplement:` map in `_supplement.yml`.

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
  meta <- meta[["supplement"]]
  if (!is.list(meta) || is.null(names(meta))) {
    cli::cli_abort(
      c("{.file _supplement.yml} has no {.field supplement} map.",
        "i" = "Put the paper facts under a top-level {.field supplement:} key, as the template does."),
      class = c("supplement_error_no_map", "supplement_error"),
      call = call
    )
  }
  meta
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

# A single text value, or NULL when it is absent or empty.
value <- function(x) {
  if (is_empty(x) || is.list(x)) NULL else as.character(x)[[1]]
}

require_fields <- function(meta, fields, call = parent.frame()) {
  for (field in fields) {
    if (is.null(value(meta[[field]]))) {
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
  if (is_empty(authors) || !is.list(authors) || !is.null(names(authors))) {
    cli::cli_abort(
      c("{.field supplement.authors} in {.file _supplement.yml} is missing or empty.",
        "i" = "List each author with {.field family:} and {.field given:}."),
      class = c("supplement_error_authors", "supplement_error"),
      call = call
    )
  }
  lapply(seq_along(authors), function(i) {
    author <- authors[[i]]
    if (!is.list(author)) {
      author <- list()
    }
    family <- value(author[["family"]])
    given <- value(author[["given"]])
    if (is.null(family) || is.null(given)) {
      hint <- if (!is.null(value(author[["name"]]))) {
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
      orcid = orcid_id(value(author[["orcid"]]), i, call = call),
      affiliation = value(author[["affiliation"]])
    )
  })
}

# Return the bare ORCID iD, or NULL when there is none.
orcid_id <- function(orcid, i, call = parent.frame()) {
  if (is.null(orcid)) {
    return(NULL)
  }
  id <- sub("^https://orcid\\.org/", "", orcid)
  if (!grepl("^[0-9]{4}-[0-9]{4}-[0-9]{4}-[0-9]{3}[0-9X]$", id)) {
    cli::cli_abort(
      c("The ORCID iD of author {i} in {.file _supplement.yml} is not valid: {.val {orcid}}.",
        "i" = "Write it as {.val 0000-0002-1825-0097} or {.val https://orcid.org/0000-0002-1825-0097}."),
      class = c("supplement_error_orcid", "supplement_error"),
      call = call
    )
  }
  id
}

check_overwrite <- function(file, overwrite, call = parent.frame()) {
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

supplement_title <- function(meta) {
  paste0("Supplemental materials for: ", value(meta[["paper-title"]]))
}
