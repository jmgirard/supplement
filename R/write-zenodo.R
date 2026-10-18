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
#' * `upload_type`: `"software"`.
#' * `description`: "Supplemental materials for: " and `citation`.
#' * `creators`: each author as "Family, Given", with the ORCID iD and the
#'   affiliation, in the order of `_supplement.yml`.
#' * `license`: the SPDX identifier in `license.content`, in lowercase.
#'   A Zenodo record takes one license, so the code license is not
#'   written.
#'
#' Empty values are left out. Values are written as they are, so Markdown
#' such as `*Journal*` keeps its asterisks.
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
  meta <- read_supplement(path)
  require_fields(meta, c("paper-title", "citation"))
  authors <- read_authors(meta)

  license <- meta[["license"]]
  if (!is.list(license)) {
    license <- list()
  }
  # Zenodo's license ids are lowercase SPDX ids:
  # https://zenodo.org/api/vocabularies/licenses/cc-by-4.0 has the id
  # "cc-by-4.0".
  content <- value(license[["content"]])

  zenodo <- compact(list(
    title = supplement_title(meta),
    upload_type = "software",
    description = paste0("Supplemental materials for: ", value(meta[["citation"]])),
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
