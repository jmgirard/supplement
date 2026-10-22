#' Write CITATION.cff from _supplement.yml
#'
#' `write_citation()` reads `_supplement.yml` in `path` and writes a
#' `CITATION.cff` file (Citation File Format 1.2.0) into the same folder.
#' GitHub reads this file to show a citation for the repository.
#'
#' The file holds:
#'
#' * `title`: "Supplemental materials for: " and `paper-title`.
#' * `version`: `version`, the version of the site, such as `"1.0.0"`.
#' * `authors`: each author's `family` and `given` names, ORCID iD, and
#'   affiliation, in the order of `_supplement.yml`.
#' * `doi`: `zenodo.concept-doi`, which names every release. When it is
#'   empty, `zenodo.version-doi`. A `doi:`, `https://doi.org/`, or
#'   `http://dx.doi.org/` in front is removed.
#' * `license`: the SPDX identifiers in `license.code` and
#'   `license.content`. SPDX ids do not depend on letter case, so when the
#'   two differ only in letter case, such as `MIT` and `mit`, the file
#'   holds one id, spelled as in `license.code`.
#'
#' Empty values are left out. In each value, every run of spaces and line
#' breaks becomes one space, and spaces at the start and end are removed.
#' Every value is written in double quotes. Values are otherwise written as
#' they are, so Markdown such as `*Journal*` keeps its asterisks. YAML reads
#' some values without quotes as numbers or as true/false, for example `No`
#' or `1.10`. Such a value is an error, so put it in quotes in
#' `_supplement.yml`, as the template does.
#'
#' @param path The folder that holds `_supplement.yml`.
#' @param overwrite If `TRUE`, replace an existing file.
#'
#' @return The path of the written file, invisibly.
#'
#' @section Errors:
#' The errors that these functions raise themselves have the class
#' `supplement_error` and one of these classes:
#'
#' * `supplement_error_argument`: `path` is not a single non-missing,
#'   non-empty character string, or `overwrite` is not `TRUE` or `FALSE`.
#' * `supplement_error_no_metadata`: `path` has no `_supplement.yml`.
#' * `supplement_error_parse`: the yaml package cannot read
#'   `_supplement.yml`. Examples are a `[` or a `{` that is not closed, a key
#'   line indented with a tab, and a key given twice in one map. The
#'   message names the file and gives the message of the yaml package.
#' * `supplement_error_no_map`: the file has no `supplement:` map.
#' * `supplement_error_missing_field`: `paper-title` is missing or empty.
#'   For [write_zenodo()], also `citation`.
#' * `supplement_error_field_type`: a value that the function reads is a
#'   list (a one-item list included), a number, or true/false where one
#'   text value belongs, or `license` (and, for [write_citation()],
#'   `zenodo`) is not a map.
#' * `supplement_error_doi`: for [write_citation()], `zenodo.concept-doi`
#'   or `zenodo.version-doi`, with its prefix removed, is not `10.`, four
#'   to nine digits, `/`, and a suffix with no spaces.
#' * `supplement_error_license`: `license.content` (and, for
#'   [write_citation()], `license.code`) is not empty and does not have the
#'   shape of an SPDX license id: letters or digits, then groups of one `.`
#'   or `-` and more letters or digits, and at most one `+` at the end. For
#'   example, `CC BY 4.0` has spaces and `GPL--3.0` has two hyphens in a
#'   row, so both are errors, and `CC-BY-4.0` is not. The check does not
#'   test that SPDX or Zenodo knows the id. The template's page footer
#'   applies the same check, so such a value also stops the site render.
#' * `supplement_error_version`: `version` is not empty and is not three
#'   whole numbers joined by `.`, each `0` or without a leading zero, such
#'   as `1.0.0` or `0.10.2`.
#' * `supplement_error_authors`: `authors` is missing, empty, or not a list
#'   of authors.
#' * `supplement_error_author_name`: an author has no `family` or no
#'   `given` name.
#' * `supplement_error_orcid`: an ORCID iD does not have the form
#'   `0000-0000-0000-0000`, with or without `https://orcid.org/` or
#'   `http://orcid.org/` in front,
#'   or its last character is not the iD's check digit. The last character
#'   can be `X`.
#' * `supplement_error_file_exists`: the output file exists and
#'   `overwrite` is `FALSE`. A folder or a link at the output path is this
#'   error even when `overwrite` is `TRUE`, because a write would follow
#'   the link. On Windows a file link to a missing file is not seen as a
#'   link, so with `overwrite = TRUE` it is written through.
#' * `supplement_error_write`: the output file was opened, but writing it
#'   gave an error or a warning (R warns when the disk is full), or the
#'   file then has another size than the text.
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
  text <- citation_text(meta)
  file <- file.path(path, "CITATION.cff")
  check_overwrite(file, overwrite)
  write_utf8(text, file)
  invisible(file)
}

# The text of CITATION.cff for the `supplement` map `meta`, as strings
# that write_utf8() joins with line breaks. An error names `call`, the
# function that the user called.
citation_text <- function(meta, call = parent.frame()) {
  require_fields(meta, "paper-title", call = call)
  authors <- read_authors(meta, call = call)

  zenodo <- map_field(meta, "zenodo", call = call)
  dois <- lapply(c("concept-doi", "version-doi"), function(key) {
    field <- paste0("supplement.zenodo.", key)
    bare_doi(value(zenodo[[key]], field, call = call), field, call = call)
  })
  doi <- dois[[1]] %||% dois[[2]]
  # `version` is "the version of the software or dataset" in the CFF 1.2.0
  # schema guide:
  # https://github.com/citation-file-format/citation-file-format/blob/main/schema-guide.md#version
  version <- read_version(meta, call = call)

  license <- map_field(meta, "license", call = call)
  code <- "supplement.license.code"
  content <- "supplement.license.content"
  licenses <- c(
    license_id(value(license[["code"]], code, call = call), code, call = call),
    license_id(value(license[["content"]], content, call = call), content, call = call)
  )
  # SPDX ids do not depend on letter case, so `mit` and `MIT` are one id,
  # written as in `license.code`.
  licenses <- licenses[!duplicated(tolower(licenses))]

  cff <- compact(list(
    "cff-version" = "1.2.0",
    message = "If you use these materials, please cite them using the metadata from this file.",
    title = supplement_title(meta, call = call),
    version = version,
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

  text <- c(
    "# Written by supplement::write_citation() from _supplement.yml.",
    "# Change _supplement.yml and write this file again.",
    yaml::as.yaml(quote_strings(cff), indent.mapping.sequence = TRUE)
  )
  sub("\n$", "", text)
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
