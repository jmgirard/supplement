# On Windows CI, R-CMD-check.yaml names a folder in SUPPLEMENT_TEST_LOG.
# Each test process then writes "<file>:<line> <test name>" to <pid>.log
# there before each test starts, so the step that reads crash dumps can
# name the test that a crashed process started last
# (.github/scripts/read-dumps.py).

# The test that calls the state inspector: the name and the file and line
# of the innermost test_that() call on the stack, or NULL outside a test.
running_test <- function() {
  calls <- sys.calls()
  for (i in rev(seq_along(calls))) {
    if (identical(sys.function(i), testthat::test_that)) {
      ref <- attr(calls[[i]], "srcref")
      where <- if (is.null(ref)) "?" else {
        paste0(basename(utils::getSrcFilename(ref)), ":", utils::getSrcLocation(ref, "line"))
      }
      return(paste(where, get("desc", envir = sys.frame(i))))
    }
  }
  NULL
}

local({
  dir <- Sys.getenv("SUPPLEMENT_TEST_LOG")
  if (.Platform$OS.type == "windows" && identical(Sys.getenv("CI"), "true") && nzchar(dir)) {
    log <- file.path(dir, paste0(Sys.getpid(), ".log"))
    last <- NULL
    # testthat calls the inspector before and after each test, so a line
    # is written only when the test differs from the last one written.
    testthat::set_state_inspector(function() {
      test <- running_test()
      if (!is.null(test) && !identical(test, last)) {
        cat(test, "\n", file = log, sep = "", append = TRUE)
        last <<- test
      }
      NULL
    })
  }
})
