# A site set up with renv, as the template guide shows, still renders and
# checks as before, and git keeps its package library out.

# The [execProcess] lines of a Quarto debug log that name R, Rscript, or
# Rterm, other than a line that looks R up. Quarto logs a command and its
# arguments joined by spaces, with no quotes. On Windows, `where` can find
# R as a .bat or .cmd file, such as a shim that runs the real R.
r_process_lines <- function(log) {
  lines <- grep("^\\[execProcess\\] ", trimws(log), value = TRUE)
  lookup <- "^\\[execProcess\\] (which|CMD /C where) (R|Rscript)$"
  lines <- lines[!grepl(lookup, lines)]
  names_r <- vapply(strsplit(sub("^\\[execProcess\\] ", "", lines), " ", fixed = TRUE), function(words) {
    base <- sub(".*[/\\\\]", "", gsub("[\"']", "", words))
    any(tolower(sub("\\.(exe|bat|cmd)$", "", base, ignore.case = TRUE)) %in% c("r", "rscript", "rterm"))
  }, logical(1))
  lines[names_r]
}

test_that("the R process check finds each form of an R call and no other process", {
  r_calls <- c(
    "[execProcess] Rscript -e 1",
    "[execProcess] /usr/bin/R --vanilla",
    '[execProcess] "C:\\Program Files\\R\\bin\\Rscript.exe" -e 1',
    "[execProcess] C:\\Program Files\\R\\bin\\Rscript.exe -e 1",
    "[execProcess] C:/R/R-4.6.1/bin/x64/Rterm.exe --vanilla",
    "[execProcess] Rterm.exe",
    "[execProcess] C:\\R\\bin\\R.exe CMD BATCH x.R",
    "[execProcess] C:\\R\\bin\\rscript.EXE x.R",
    "[execProcess] /opt/R/4.4/bin/x64/Rscript run.R",
    "[execProcess] CMD /C Rscript x.R",
    "[execProcess] C:\\PROGRA~1\\R\\R-46~1.1\\bin\\x64\\RSCRIPT.EXE x.R",
    "[execProcess] C:\\Users\\me\\AppData\\Local\\Programs\\R\\Rscript.bat x.R",
    "[execProcess] C:\\rig\\R.cmd --vanilla"
  )
  expect_identical(r_process_lines(r_calls), r_calls)

  others <- c(
    "[execProcess] /Applications/quarto/bin/tools/aarch64/deno run --allow-all _scripts/build.ts",
    "[execProcess] /Applications/quarto/bin/tools/aarch64/dart-sass/sass in.scss out.css --style compressed",
    "[execProcess] /Applications/quarto/bin/tools/aarch64/pandoc +RTS -K512m -RTS --defaults d.yml",
    "[execProcess] Success: true, code: 0",
    "[execProcess] which Rscript",
    "[execProcess] CMD /C where Rscript",
    "[execProcess] which R",
    "[execProcess] /opt/R/4.4/bin/pandoc --version",
    "[execProcess] pandoc --lua-filter Rscript.lua",
    "[execProcess] cmd /c C:\\Users\\me\\AppData\\Local\\Temp\\quarto-safe-exec1a2b.bat",
    "Looking for 'Rscript' in PATH."
  )
  expect_identical(r_process_lines(others), character())
})

test_that("a site set up with renv renders with no R, checks clean, and keeps its library out of git", {
  site <- renv_site()

  rendered <- withr::with_envvar(c(QUARTO_LOG_LEVEL = "DEBUG"), run_in(site, "quarto", "render"))
  expect_status(rendered)
  # The output holds the debug lines of Quarto's own processes, so the
  # check below reads a log of the processes that the render started.
  expect_true(any(grepl("^\\[execProcess\\] .*pandoc", rendered$output)))
  expect_identical(r_process_lines(rendered$output), character())

  rows <- suppressMessages(check_supplement(site))
  expect_identical(nrow(rows), 0L, info = paste(utils::capture.output(print(rows)), collapse = "\n"))

  untracked <- git_in(site, c("ls-files", "--others", "--exclude-standard"))
  expect_status(untracked)
  expect_contains(untracked$output, c("renv.lock", ".Rprofile", "renv/activate.R", "renv/settings.json"))
  library <- list.files(file.path(site, "renv", "library"), recursive = TRUE, include.dirs = TRUE)
  expect_true(length(library) > 0)
  expect_false(any(startsWith(untracked$output, "renv/library/")), info = paste(untracked$output, collapse = "\n"))
})
