#' Write .zenodo.json from _supplement.yml
#'
#' `write_zenodo()` reads `_supplement.yml` in `path` and writes a
#' `.zenodo.json` file into the same folder. When Zenodo's GitHub
#' integration archives a release, it reads this file for the record's
#' metadata. When a repository has both `.zenodo.json` and `CITATION.cff`,
#' Zenodo uses `.zenodo.json`.
#'
#' The file holds:
#'
#' * `title`: "Supplemental materials for: " and `paper-title`.
#' * `version`: `version`, the version of the site, such as `"1.0.0"`.
#' * `upload_type`: `"software"`.
#' * `description`: "Supplemental materials for: " and `citation`.
#' * `creators`: each author as "Family, Given", with the ORCID iD and the
#'   affiliation, in the order of `_supplement.yml`.
#' * `license`: the SPDX identifier in `license.content`, in lowercase.
#'   The `license` field of `.zenodo.json` takes one license id, so the
#'   code license is not written.
#'
#' Empty values are left out. In each value, every run of spaces and line
#' breaks becomes one space, and spaces at the start and end are removed.
#' Values are otherwise written as they are, so Markdown such as
#' `*Journal*` keeps its asterisks. YAML reads some values without quotes
#' as numbers or as true/false, for example `No` or `1.10`. Such a value is
#' an error, so put it in quotes in `_supplement.yml`, as the template
#' does.
#'
#' @inheritParams write_citation
#' @inherit write_citation return
#' @inheritSection write_citation Errors
#'
#' @seealso [write_citation()] for `CITATION.cff`.
#' @export
#' @examples
#' site <- file.path(tempdir(), "my-supplement")
#' dir.create(site)
#' file.copy(
#'   system.file("template", "_supplement.yml", package = "supplement"),
#'   site
#' )
#' write_zenodo(site)
#' readLines(file.path(site, ".zenodo.json"))
#' unlink(site, recursive = TRUE)
write_zenodo <- function(path = ".", overwrite = FALSE) {
  check_args(path, overwrite)
  meta <- read_supplement(path)
  require_fields(meta, c("paper-title", "citation"))
  authors <- read_authors(meta)

  license <- map_field(meta, "license")
  # Zenodo's license ids are lowercase SPDX ids:
  # https://zenodo.org/api/vocabularies/licenses/cc-by-4.0 has the id
  # "cc-by-4.0".
  content <- license_id(value(license[["content"]], "supplement.license.content"),
                        "supplement.license.content")
  # `version` is a string in Zenodo's deposit metadata, which suggests a
  # semantic version such as "2.1.5":
  # https://developers.zenodo.org/#representation
  version <- read_version(meta)

  zenodo <- compact(list(
    title = supplement_title(meta),
    version = version,
    upload_type = "software",
    description = paste0(
      "Supplemental materials for: ",
      value(meta[["citation"]], "supplement.citation")
    ),
    creators = lapply(authors, function(author) {
      compact(list(
        name = paste0(author$family, ", ", author$given),
        orcid = author$orcid,
        affiliation = author$affiliation
      ))
    }),
    license = if (!is.null(content)) tolower(content)
  ))

  file <- file.path(path, ".zenodo.json")
  check_overwrite(file, overwrite)
  text <- jsonlite::toJSON(zenodo, auto_unbox = TRUE, pretty = TRUE)
  write_utf8(as.character(text), file)
  invisible(file)
}
