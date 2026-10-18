#' Write CITATION.cff from _supplement.yml
#'
#' `write_citation()` reads `_supplement.yml` in `path` and writes a
#' `CITATION.cff` file (Citation File Format 1.2.0) into the same folder.
#' GitHub reads this file to show a citation for the repository.
#'
#' The file holds:
#'
#' * `title`: "Supplemental materials for: " and `paper-title`.
#' * `authors`: each author's `family` and `given` names, ORCID iD, and
#'   affiliation, in the order of `_supplement.yml`.
#' * `doi`: `zenodo.concept-doi`, which names every release. When it is
#'   empty, `zenodo.version-doi`. A `https://doi.org/` in front is removed.
#' * `license`: the SPDX identifiers in `license.code` and
#'   `license.content`.
#'
#' Empty values are left out, and spaces and line breaks at the start and
#' end of a value are removed. Every value is written in double quotes.
#' Values are otherwise written as the YAML parser reads them, so Markdown such as `*Journal*` keeps its asterisks. Put values in
#' quotes in `_supplement.yml`, as the template does, so that YAML does not
#' read a value such as `No` or `1.10` as true/false or a number.
#'
#' @param path The folder that holds `_supplement.yml`.
#' @param overwrite If `TRUE`, replace an existing file.
#'
#' @return The path of the written file, invisibly.
#'
#' @section Errors:
#' A `_supplement.yml` that is not valid YAML gives the error of the YAML
#' parser. The errors that these functions raise themselves have the class
#' `supplement_error` and one of these classes:
#'
#' * `supplement_error_argument`: `path` is not one folder path, or
#'   `overwrite` is not `TRUE` or `FALSE`.
#' * `supplement_error_no_metadata`: `path` has no `_supplement.yml`.
#' * `supplement_error_no_map`: the file has no `supplement:` map.
#' * `supplement_error_missing_field`: `paper-title` is missing or empty.
#'   For [write_zenodo()], also `citation`.
#' * `supplement_error_field_type`: a value that the function reads is a
#'   list where one text value belongs, or `license` or `zenodo` is not a
#'   map.
#' * `supplement_error_authors`: `authors` is missing, empty, or not a list
#'   of authors.
#' * `supplement_error_author_name`: an author has no `family` or no
#'   `given` name.
#' * `supplement_error_orcid`: an ORCID iD does not have the form
#'   `0000-0000-0000-0000`, with or without `https://orcid.org/` in front,
#'   or its last character is not the iD's check digit. The last character
#'   can be `X`.
#' * `supplement_error_file_exists`: the output file exists and
#'   `overwrite` is `FALSE`, or a folder has the output file's name.
#'
#' @seealso [write_zenodo()] for `.zenodo.json`.
#' @export
#' @examples
#' site <- file.path(tempdir(), "my-supplement")
#' dir.create(site)
#' file.copy(
#'   system.file("template", "_supplement.yml", package = "supplement"),
#'   site
#' )
#' write_citation(site)
#' readLines(file.path(site, "CITATION.cff"))
#' unlink(site, recursive = TRUE)
write_citation <- function(path = ".", overwrite = FALSE) {
  check_args(path, overwrite)
  meta <- read_supplement(path)
  require_fields(meta, "paper-title")
  authors <- read_authors(meta)

  zenodo <- map_field(meta, "zenodo")
  doi <- bare_doi(
    value(zenodo[["concept-doi"]], "supplement.zenodo.concept-doi") %||%
      value(zenodo[["version-doi"]], "supplement.zenodo.version-doi")
  )

  license <- map_field(meta, "license")
  licenses <- unique(c(
    value(license[["code"]], "supplement.license.code"),
    value(license[["content"]], "supplement.license.content")
  ))

  cff <- compact(list(
    "cff-version" = "1.2.0",
    message = "If you use these materials, please cite them using the metadata from this file.",
    title = supplement_title(meta),
    authors = lapply(authors, function(author) {
      compact(list(
        "family-names" = author$family,
        "given-names" = author$given,
        orcid = if (!is.null(author$orcid)) paste0("https://orcid.org/", author$orcid),
        affiliation = author$affiliation
      ))
    }),
    doi = doi,
    license = licenses
  ))

  file <- file.path(path, "CITATION.cff")
  check_overwrite(file, overwrite)
  text <- c(
    "# Written by supplement::write_citation() from _supplement.yml.",
    "# Change _supplement.yml and write this file again.",
    yaml::as.yaml(quote_strings(cff), indent.mapping.sequence = TRUE)
  )
  write_utf8(sub("\n$", "", text), file)
  invisible(file)
}

# Mark every string to be written in double quotes, so that no YAML
# parser reads a value such as "1e3" as a number.
quote_strings <- function(x) {
  if (is.list(x)) {
    x[] <- lapply(x, quote_strings)
    x
  } else {
    structure(x, quoted = TRUE)
  }
}
