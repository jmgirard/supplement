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

test_that("_supplement.yml without a supplement map is refused", {
  texts <- list(
    c("title: A paper"),
    c("supplement: A paper"),
    c("supplement:", "  - A paper")
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
    "0000-0001-5109-370x",
    "0000000218250097",
    "http://orcid.org/0000-0002-1825-0097",
    "https://orcid.org/0000-0002-1825-0097/",
    "orcid.org/0000-0002-1825-0097",
    " 0000-0002-1825-0097"
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

test_that("an existing file is kept when overwrite is FALSE", {
  dir <- local_site(full_supplement())
  for (file in names(writers)) {
    path <- file.path(dir, file)
    writeLines("hand-written", path)
    expect_error(writers[[file]](dir), class = "supplement_error_file_exists")
    expect_equal(readLines(path), "hand-written")
  }
})

test_that("every error also has the class supplement_error", {
  dir <- local_site()
  expect_error(write_citation(dir), class = "supplement_error")
  expect_error(write_zenodo(dir), class = "supplement_error")
})
