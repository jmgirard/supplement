writers <- list(
  "CITATION.cff" = write_citation,
  ".zenodo.json" = write_zenodo
)

# Run `writer` in `dir`, expect an error of `class`, and check that the
# output file is absent afterwards.
expect_refused <- function(dir, file, class) {
  writer <- writers[[file]]
  expect_error(writer(dir), class = class)
  expect_false(file.exists(file.path(dir, file)))
}

with_change <- function(change) {
  meta <- full_supplement()
  change(meta)
}

test_that("a folder without _supplement.yml is refused", {
  dir <- local_site()
  for (file in names(writers)) {
    expect_refused(dir, file, "supplement_error_no_metadata")
  }
})

test_that("a path that does not exist is refused", {
  dir <- file.path(local_site(), "no-such-folder")
  for (writer in writers) {
    expect_error(writer(dir), class = "supplement_error_no_metadata")
  }
  expect_false(dir.exists(dir))
})

test_that("path and overwrite must have the right form", {
  dir <- local_site(full_supplement())
  bad <- list(
    list(path = c(dir, dir)),
    list(path = 1),
    list(path = NA_character_),
    list(path = ""),
    list(path = factor(dir)),
    list(path = dir, overwrite = NA),
    list(path = dir, overwrite = "yes"),
    list(path = dir, overwrite = c(TRUE, TRUE))
  )
  for (args in bad) {
    for (file in names(writers)) {
      expect_error(do.call(writers[[file]], args), class = "supplement_error_argument")
      expect_false(file.exists(file.path(dir, file)))
    }
  }
})

test_that("_supplement.yml without a supplement map is refused", {
  texts <- list(
    c("title: A paper"),
    c("supplement: A paper"),
    c("supplement:", "  - A paper"),
    c("just a string"),
    c("- a", "- b"),
    c("")
  )
  for (text in texts) {
    dir <- local_site(text = text)
    for (file in names(writers)) {
      expect_refused(dir, file, "supplement_error_no_map")
    }
  }
})

test_that("a missing or empty paper-title is refused", {
  changes <- list(
    function(m) { m[["paper-title"]] <- NULL; m },
    function(m) { m[["paper-title"]] <- ""; m },
    function(m) { m[["paper-title"]] <- "  "; m }
  )
  for (change in changes) {
    dir <- local_site(with_change(change))
    for (file in names(writers)) {
      expect_refused(dir, file, "supplement_error_missing_field")
    }
  }
})

test_that("write_zenodo() refuses a missing or empty citation", {
  changes <- list(
    function(m) { m$citation <- NULL; m },
    function(m) { m$citation <- ""; m }
  )
  for (change in changes) {
    dir <- local_site(with_change(change))
    expect_refused(dir, ".zenodo.json", "supplement_error_missing_field")
    expect_error(write_citation(dir), NA)
  }
})

test_that("missing or empty authors are refused", {
  changes <- list(
    function(m) { m$authors <- NULL; m },
    function(m) { m$authors <- list(); m },
    function(m) { m$authors <- ""; m },
    function(m) { m$authors <- list(family = "Doe", given = "Jane"); m }
  )
  for (change in changes) {
    dir <- local_site(with_change(change))
    for (file in names(writers)) {
      expect_refused(dir, file, "supplement_error_authors")
    }
  }
})

test_that("authors as a list of names gets a message about the list form", {
  dir <- local_site(text = c(
    "supplement:",
    "  paper-title: A paper",
    "  citation: A citation",
    "  authors: [Jane Doe, John Roe]"
  ))
  for (file in names(writers)) {
    err <- expect_error(writers[[file]](dir), class = "supplement_error_authors")
    expect_match(conditionMessage(err), "must be a list of authors", fixed = TRUE)
    expect_false(file.exists(file.path(dir, file)))
  }
})

test_that("a list where one value belongs, or a license or zenodo that is not a map, is refused", {
  both <- list(
    function(m) { m[["paper-title"]] <- c("A", "B"); m },
    function(m) { m$authors[[1]]$given <- c("Jane", "Q."); m },
    function(m) { m$authors[[1]]$family <- list(a = "Doe"); m },
    function(m) { m$authors[[2]]$orcid <- c("0000-0002-1825-0097", "x"); m },
    function(m) { m$authors[[2]]$affiliation <- c("A", "B"); m },
    function(m) { m$license <- "MIT"; m },
    function(m) { m$license$content <- c("MIT", "CC-BY-4.0"); m }
  )
  for (change in both) {
    dir <- local_site(with_change(change))
    for (file in names(writers)) {
      expect_refused(dir, file, "supplement_error_field_type")
    }
  }

  citation_only <- list(
    function(m) { m$zenodo <- "10.5281/zenodo.1"; m },
    function(m) { m$zenodo[["concept-doi"]] <- c("10.5281/zenodo.1", "x"); m },
    function(m) { m$license$code <- c("MIT", "BSD-3-Clause"); m }
  )
  for (change in citation_only) {
    dir <- local_site(with_change(change))
    expect_refused(dir, "CITATION.cff", "supplement_error_field_type")
  }

  dir <- local_site(with_change(function(m) { m$citation <- c("A", "B"); m }))
  expect_refused(dir, ".zenodo.json", "supplement_error_field_type")
})

test_that("a one-item list, a number, or true/false where text belongs is refused", {
  base <- c(
    "supplement:",
    "  citation: A citation"
  )
  author <- c("  authors:", "    - family: Doe")
  cases <- list(
    c(base, "  paper-title: [A paper]", author, "      given: Jane"),
    c(base, "  paper-title: A paper", author, "      given: No"),
    c(base, "  paper-title: A paper", author, "      given: Jane", "      affiliation: 1.10"),
    c(base, "  paper-title: A paper", author, "      given: 12345678901234567890"),
    c(base, "  paper-title: true", author, "      given: Jane")
  )
  for (text in cases) {
    dir <- local_site(text = text)
    for (file in names(writers)) {
      suppressWarnings(expect_refused(dir, file, "supplement_error_field_type"))
    }
  }
  dir <- local_site(text = c(base, "  paper-title: A paper", author, "      given: No"))
  err <- expect_error(write_citation(dir), class = "supplement_error_field_type")
  expect_match(conditionMessage(err), "quotes", fixed = TRUE)
})

test_that("a version that is not three whole numbers is refused", {
  bad <- c("1.0", "v1.0.0", "01.0.0", "1.0.0-rc1", "1. 0.0", "1.00.0", "1.0.0.0", "-1.0.0")
  for (version in bad) {
    dir <- local_site(with_change(function(m) {
      m$version <- version
      m
    }))
    for (file in names(writers)) {
      expect_refused(dir, file, "supplement_error_version")
    }
    err <- expect_error(write_zenodo(dir), class = "supplement_error_version")
    expect_match(conditionMessage(err), version, fixed = TRUE)
  }
})

test_that("an unquoted version that YAML reads as a number is refused", {
  dir <- local_site(text = c(
    "supplement:",
    "  paper-title: A paper",
    "  citation: A citation",
    "  version: 1.10",
    "  authors:",
    "    - family: Doe",
    "      given: Jane"
  ))
  for (file in names(writers)) {
    expect_refused(dir, file, "supplement_error_field_type")
  }
})

test_that("write_citation() refuses a DOI that is not a DOI", {
  bad <- c(
    "zenodo.1234567",
    "10.5281",
    "10.52/zenodo.1",
    "https://zenodo.org/records/1",
    "doi.org/10.5281/zenodo.1",
    "10.5281/zenodo 1"
  )
  for (key in c("concept-doi", "version-doi")) {
    for (doi in bad) {
      dir <- local_site(with_change(function(m) {
        m$zenodo[[key]] <- doi
        m
      }))
      expect_refused(dir, "CITATION.cff", "supplement_error_doi")
      expect_no_error(write_zenodo(dir))
    }
  }
})

test_that("a bare-string author in a list gets a message about the author form", {
  dir <- local_site(with_change(function(m) {
    m$authors[[1]] <- "Jane Doe"
    m
  }))
  for (file in names(writers)) {
    err <- expect_error(writers[[file]](dir), class = "supplement_error_author_name")
    expect_match(conditionMessage(err), "not as a single name", fixed = TRUE)
  }
})

test_that("an author without a family or given name is refused", {
  changes <- list(
    function(m) { m$authors[[2]]$family <- NULL; m },
    function(m) { m$authors[[2]]$family <- ""; m },
    function(m) { m$authors[[1]]$given <- NULL; m },
    function(m) { m$authors[[1]]$given <- ""; m },
    function(m) { m$authors[[1]] <- "Jane Doe"; m }
  )
  for (change in changes) {
    dir <- local_site(with_change(change))
    for (file in names(writers)) {
      expect_refused(dir, file, "supplement_error_author_name")
    }
  }
})

test_that("an author with only a name gets a hint about family and given", {
  dir <- local_site(with_change(function(m) {
    m$authors[[1]] <- list(name = "Jane Doe", orcid = "")
    m
  }))
  for (writer in writers) {
    err <- expect_error(writer(dir), class = "supplement_error_author_name")
    expect_match(conditionMessage(err), "family:", fixed = TRUE)
    expect_match(conditionMessage(err), "given:", fixed = TRUE)
  }
})

test_that("a malformed ORCID iD is refused", {
  bad <- c(
    "0000-0002-1825-009",
    "0000-0002-1825-00977",
    "0000-0002-1694-233x",
    "0000-0002-1825-0098",
    "0000-0002-1694-2330",
    "0000000218250097",
    "https://orcid.org/0000-0002-1825-0097/",
    "https://www.orcid.org/0000-0002-1825-0097",
    "orcid.org/0000-0002-1825-0097",
    "0000-0002-1825-0097 x"
  )
  for (orcid in bad) {
    dir <- local_site(with_change(function(m) {
      m$authors[[2]]$orcid <- orcid
      m
    }))
    for (file in names(writers)) {
      expect_refused(dir, file, "supplement_error_orcid")
    }
  }
})

# Values that do not have the shape of an SPDX license id.
bad_license_ids <- c(
  "space between words" = "MIT License",
  "slash" = "CC/BY",
  "OR expression" = "MIT OR Apache-2.0",
  "two final plus signs" = "GPL-2.0++",
  "plus between letters" = "A+B",
  "leading hyphen" = "-MIT",
  # Quarto reads `--` as an en dash and `...` as an ellipsis, so the footer
  # could not show these ids as written.
  "two hyphens" = "GPL--3.0",
  "two dots" = "GPL-3..0",
  "three dots" = "MIT...",
  "final hyphen" = "MIT-",
  "final dot" = "MIT.",
  "dot then hyphen" = "GPL.-3"
)

test_that("a license value that is not an SPDX id stops each writer and keeps the old file", {
  fields <- list("CITATION.cff" = c("code", "content"), ".zenodo.json" = "content")
  for (file in names(writers)) {
    for (field in fields[[file]]) {
      for (shape in names(bad_license_ids)) {
        meta <- full_supplement()
        meta$license[[field]] <- bad_license_ids[[shape]]
        dir <- local_site(meta)
        path <- file.path(dir, file)
        writeLines("old text", path)
        old <- readBin(path, "raw", file.size(path))
        info <- paste(file, field, shape)
        err <- expect_error(writers[[file]](dir, overwrite = TRUE),
                            class = "supplement_error_license", info = info)
        expect_s3_class(err, "supplement_error")
        expect_match(conditionMessage(err), paste0("supplement.license.", field), fixed = TRUE, info = info)
        expect_identical(readBin(path, "raw", file.size(path) + 1), old, info = info)
      }
    }
  }
})

test_that("SPDX-shaped license ids are written", {
  for (id in c("CC-BY-4.0", "GPL-2.0+", "0BSD", "LGPL-2.1-or-later", "BSD-2-Clause-Patent")) {
    meta <- full_supplement()
    meta$license <- list(code = id, content = id)
    dir <- local_site(meta)
    for (file in names(writers)) {
      path <- writers[[file]](dir)
      # .zenodo.json takes Zenodo's lowercase ids.
      written <- if (file == ".zenodo.json") tolower(id) else id
      expect_match(read_text(path), paste0('"', written, '"'), fixed = TRUE, info = paste(file, id))
    }
  }
})

test_that("an existing file is kept when overwrite is FALSE", {
  dir <- local_site(full_supplement())
  for (file in names(writers)) {
    path <- file.path(dir, file)
    writeLines("hand-written", path)
    expect_error(writers[[file]](dir), class = "supplement_error_file_exists")
    expect_equal(readLines(path), "hand-written")
  }
})

test_that("a folder with the output file's name is refused", {
  dir <- local_site(full_supplement())
  for (file in names(writers)) {
    dir.create(file.path(dir, file))
    expect_error(
      writers[[file]](dir, overwrite = TRUE),
      class = "supplement_error_file_exists"
    )
    expect_true(dir.exists(file.path(dir, file)))
  }
})

test_that("a dangling link with the output file's name is kept", {
  skip_on_os("windows")
  dir <- local_site(full_supplement())
  target <- file.path(dir, "missing-target")
  for (file in names(writers)) {
    link <- file.path(dir, file)
    file.symlink(target, link)
    expect_error(writers[[file]](dir), class = "supplement_error_file_exists")
    expect_false(file.exists(target))
  }
})

test_that("a missing _supplement.yml error also has the class supplement_error", {
  dir <- local_site()
  expect_error(write_citation(dir), class = "supplement_error")
  expect_error(write_zenodo(dir), class = "supplement_error")
})
