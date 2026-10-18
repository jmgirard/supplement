# Helpers for the tests of write_citation() and write_zenodo().

# A `supplement:` map with every field filled. The second author has a
# non-ASCII family name and gives the ORCID iD as a URL.
full_supplement <- function() {
  list(
    "paper-title" = "Effects: a \"close\" look at *text* & more",
    citation = "Doe, J., & Müller, Ä. (2026). Effects. *Journal*.",
    preprint = "https://osf.io/abcde",
    contact = "Jane Doe, University A.",
    license = list(code = "MIT", content = "CC-BY-4.0"),
    authors = list(
      list(
        family = "Doe", given = "Jane Q.",
        orcid = "0000-0002-1825-0097", affiliation = "University A"
      ),
      list(
        family = "Müller", given = "Änne",
        orcid = "https://orcid.org/0000-0001-5109-370X",
        affiliation = "Institut B"
      )
    ),
    zenodo = list(
      "version-doi" = "10.5281/zenodo.2",
      "concept-doi" = "10.5281/zenodo.1",
      "archive-url" = "https://zenodo.org/records/2"
    ),
    data = list(list(file = "data/example.csv", description = "Example"))
  )
}

# A temporary folder that holds `_supplement.yml`. `meta` is the
# `supplement:` map, or `text` is the whole file.
local_site <- function(meta = NULL, text = NULL, env = parent.frame()) {
  dir <- withr::local_tempdir("site-", .local_envir = env)
  file <- file.path(dir, "_supplement.yml")
  if (!is.null(text)) {
    writeLines(enc2utf8(text), file, useBytes = TRUE)
  } else if (!is.null(meta)) {
    yaml::write_yaml(list(supplement = meta), file)
  }
  dir
}

read_cff <- function(dir) {
  yaml::read_yaml(file.path(dir, "CITATION.cff"))
}

read_zenodo <- function(dir) {
  jsonlite::read_json(file.path(dir, ".zenodo.json"), simplifyVector = FALSE)
}

# The paths to every NULL, NA, "", or zero-length value in a parsed file.
empty_paths <- function(x, path = "") {
  if (is.list(x)) {
    if (length(x) == 0) {
      return(path)
    }
    keys <- names(x) %||% as.character(seq_along(x))
    unlist(lapply(seq_along(x), function(i) {
      empty_paths(x[[i]], paste0(path, "/", keys[[i]]))
    }))
  } else if (is.null(x) || length(x) == 0 || any(is.na(x) | x == "")) {
    path
  } else {
    character()
  }
}
