test_that("an error from a value check names the writer that the user called", {
  meta <- full_supplement()
  meta[["paper-title"]] <- ""
  dir <- local_site(meta)
  err <- expect_error(write_citation(dir), class = "supplement_error_missing_field")
  expect_identical(err$call[[1]], quote(write_citation))
  err <- expect_error(write_zenodo(dir), class = "supplement_error_missing_field")
  expect_identical(err$call[[1]], quote(write_zenodo))
})
