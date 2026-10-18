# Expected values follow the Citation File Format 1.2.0 schema guide
# (https://github.com/citation-file-format/citation-file-format/blob/main/schema-guide.md)
# and Zenodo's .zenodo.json fields (creators as "Family, Given", bare ORCID
# iD, lowercase license id). They are written here by hand, not copied
# from the functions' output.

title <- "Supplemental materials for: Effects: a \"close\" look at *text* & more"

test_that("write_citation() writes every field of a full _supplement.yml", {
  dir <- local_site(full_supplement())
  out <- write_citation(dir)

  expect_equal(out, file.path(dir, "CITATION.cff"))
  cff <- read_cff(dir)
  expect_type(cff$message, "character")
  expect_true(nzchar(cff$message))
  cff$message <- NULL
  expect_equal(cff, list(
    "cff-version" = "1.2.0",
    title = title,
    authors = list(
      list(
        "family-names" = "Doe",
        "given-names" = "Jane Q.",
        orcid = "https://orcid.org/0000-0002-1825-0097",
        affiliation = "University A"
      ),
      list(
        "family-names" = "Müller",
        "given-names" = "Änne",
        orcid = "https://orcid.org/0000-0001-5109-370X",
        affiliation = "Institut B"
      )
    ),
    doi = "10.5281/zenodo.1",
    license = c("MIT", "CC-BY-4.0")
  ))
})

test_that("write_zenodo() writes every field of a full _supplement.yml", {
  dir <- local_site(full_supplement())
  out <- write_zenodo(dir)

  expect_equal(out, file.path(dir, ".zenodo.json"))
  expect_equal(read_zenodo(dir), list(
    title = title,
    upload_type = "software",
    description = "Supplemental materials for: Doe, J., & Müller, Ä. (2026). Effects. *Journal*.",
    creators = list(
      list(
        name = "Doe, Jane Q.",
        orcid = "0000-0002-1825-0097",
        affiliation = "University A"
      ),
      list(
        name = "Müller, Änne",
        orcid = "0000-0001-5109-370X",
        affiliation = "Institut B"
      )
    ),
    license = "cc-by-4.0"
  ))
})

test_that("the files are UTF-8", {
  dir <- local_site(full_supplement())
  write_citation(dir)
  write_zenodo(dir)

  for (file in c("CITATION.cff", ".zenodo.json")) {
    bytes <- readBin(file.path(dir, file), "raw", 10000)
    text <- rawToChar(bytes)
    Encoding(text) <- "UTF-8"
    expect_true(validUTF8(text))
    expect_match(text, "Müller", fixed = TRUE)
  }
})

minimal_supplement <- function(optional) {
  meta <- list(
    "paper-title" = "A paper",
    citation = "Doe, J. (2026). A paper.",
    authors = list(list(family = "Doe", given = "Jane"))
  )
  if (optional == "empty") {
    meta$authors[[1]]$orcid <- ""
    meta$authors[[1]]$affiliation <- ""
    meta$license <- list(code = "", content = "")
    meta$zenodo <- list("version-doi" = "", "concept-doi" = "", "archive-url" = "")
    meta$preprint <- ""
  }
  meta
}

test_that("empty and absent optional values are left out of both files", {
  null_text <- c(
    "supplement:",
    "  paper-title: A paper",
    "  citation: Doe, J. (2026). A paper.",
    "  preprint:",
    "  license:",
    "    code:",
    "    content: ~",
    "  authors:",
    "    - family: Doe",
    "      given: Jane",
    "      orcid:",
    "      affiliation: null"
  )
  sites <- list(
    empty = local_site(minimal_supplement("empty")),
    absent = local_site(minimal_supplement("absent")),
    null = local_site(text = null_text)
  )

  for (dir in sites) {
    write_citation(dir)
    write_zenodo(dir)
    cff <- read_cff(dir)
    zenodo <- read_zenodo(dir)

    expect_equal(empty_paths(cff), character())
    expect_equal(empty_paths(zenodo), character())
    expect_named(cff, c("cff-version", "message", "title", "authors"))
    expect_equal(cff$authors, list(list("family-names" = "Doe", "given-names" = "Jane")))
    expect_named(zenodo, c("title", "upload_type", "description", "creators"))
    expect_equal(zenodo$creators, list(list(name = "Doe, Jane")))
  }
})

test_that("one author is written as a list of one", {
  dir <- local_site(minimal_supplement("absent"))
  write_zenodo(dir)
  write_citation(dir)

  expect_length(read_zenodo(dir)$creators, 1)
  expect_match(
    paste(readLines(file.path(dir, ".zenodo.json")), collapse = "\n"),
    '"creators": \\[\\s*\\{'
  )
  expect_length(read_cff(dir)$authors, 1)
  expect_null(names(read_cff(dir)$authors))
})

test_that("the DOI falls back to version-doi", {
  meta <- full_supplement()
  meta$zenodo[["concept-doi"]] <- ""
  dir <- local_site(meta)
  write_citation(dir)

  expect_equal(read_cff(dir)$doi, "10.5281/zenodo.2")
})

test_that("one license, or two equal ones, is written as one id", {
  cases <- list(
    list(code = "MIT", content = ""),
    list(code = "", content = "CC-BY-4.0"),
    list(code = "CC-BY-4.0", content = "CC-BY-4.0")
  )
  expected <- c("MIT", "CC-BY-4.0", "CC-BY-4.0")
  for (i in seq_along(cases)) {
    meta <- full_supplement()
    meta$license <- cases[[i]]
    dir <- local_site(meta)
    write_citation(dir)
    expect_identical(read_cff(dir)$license, expected[[i]])
    expect_match(
      paste(readLines(file.path(dir, "CITATION.cff")), collapse = "\n"),
      paste0("\nlicense: ", expected[[i]], "$")
    )
  }

  meta <- full_supplement()
  meta$license <- list(code = "MIT", content = "")
  dir <- local_site(meta)
  write_zenodo(dir)
  expect_null(read_zenodo(dir)$license)
})

test_that("an ORCID iD as a URL gives the same files as the bare iD", {
  bare <- full_supplement()
  bare$authors[[2]]$orcid <- "0000-0001-5109-370X"
  url <- full_supplement()
  url$authors[[1]]$orcid <- "https://orcid.org/0000-0002-1825-0097"
  dirs <- list(local_site(bare), local_site(url))

  for (dir in dirs) {
    write_citation(dir)
    write_zenodo(dir)
  }
  for (file in c("CITATION.cff", ".zenodo.json")) {
    expect_identical(
      readLines(file.path(dirs[[1]], file)),
      readLines(file.path(dirs[[2]], file))
    )
  }
})

test_that("both files are written in a copy of the template", {
  dir <- withr::local_tempdir("template-")
  file.copy(list.files(template_dir(), full.names = TRUE, all.files = TRUE, no.. = TRUE),
            dir, recursive = TRUE)

  authors <- yaml::read_yaml(file.path(dir, "_supplement.yml"))$supplement$authors
  for (author in authors) {
    expect_true(all(c("family", "given") %in% names(author)))
    expect_false("name" %in% names(author))
  }

  expect_no_error(write_citation(dir))
  expect_no_error(write_zenodo(dir))
  expect_equal(read_cff(dir)$title, "Supplemental materials for: Title of the paper")
  expect_equal(read_zenodo(dir)$creators[[1]]$name, "Author, A. A.")
})

test_that("overwrite = TRUE replaces the file", {
  dir <- local_site(full_supplement())
  for (name in c("CITATION.cff", ".zenodo.json")) {
    writeLines("old", file.path(dir, name))
  }
  write_citation(dir, overwrite = TRUE)
  write_zenodo(dir, overwrite = TRUE)

  expect_equal(read_cff(dir)$doi, "10.5281/zenodo.1")
  expect_equal(read_zenodo(dir)$license, "cc-by-4.0")
})
