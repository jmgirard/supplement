# Most tests replace quarto_run() and the Quarto lookups, so they run
# without Quarto. The render tests at the end run the real Quarto.

# Mock a Quarto copy and quarto_run(). `on_run` gets the arguments of each
# call and returns its exit status. The returned function gives the calls,
# each as the quarto path followed by the arguments.
local_runner <- function(on_run = function(args) 0L, env = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = env)
  local_tools(which = list(quarto = fake_quarto(file.path(dir, "q"))), env_frame = env)
  calls <- list()
  local_mocked_bindings(
    quarto_run = function(quarto, args) {
      calls[[length(calls) + 1L]] <<- c(quarto, args)
      on_run(args)
    },
    .env = env
  )
  function() calls
}

# A site with the reports `names` in analyses/, with no Quarto output.
plain_site <- function(names = character(), env = parent.frame()) {
  site <- withr::local_tempdir("site-", .local_envir = env)
  writeLines("project:\n  type: website", file.path(site, "_quarto.yml"))
  dir.create(file.path(site, "analyses"))
  for (name in names) writeLines("---\ntitle: R\n---", file.path(site, "analyses", paste0(name, ".qmd")))
  site
}

args_of <- function(calls) lapply(calls, `[`, -1L)

test_that("render_supplement() with no reports runs one full render", {
  calls <- local_runner()
  site <- plain_site()
  expect_invisible(out <- suppressMessages(render_supplement(path = site)))
  expect_identical(out, "quarto render")
  expect_identical(args_of(calls()), list("render"))
})

test_that("named reports render by name, in order and once each, before the full render", {
  calls <- local_runner()
  site <- plain_site(c("a", "b"))
  out <- suppressMessages(render_supplement(c("a", "b"), path = site))
  expect_identical(out, c("quarto render analyses/a.qmd", "quarto render analyses/b.qmd", "quarto render"))
  expect_identical(args_of(calls()), list(c("render", "analyses/a.qmd"), c("render", "analyses/b.qmd"), "render"))

  # A character vector with a class, as from fs::path(), is taken as names.
  calls <- local_runner()
  out <- suppressMessages(render_supplement(structure("a", class = c("fs_path", "character")), path = site))
  expect_identical(out, c("quarto render analyses/a.qmd", "quarto render"))

  calls <- local_runner()
  out <- suppressMessages(render_supplement(c("b", "a", "b"), path = site))
  expect_identical(out, c("quarto render analyses/b.qmd", "quarto render analyses/a.qmd", "quarto render"))
  expect_identical(args_of(calls()), list(c("render", "analyses/b.qmd"), c("render", "analyses/a.qmd"), "render"))
})

# A runner that, on each full render, saves figures/new.png as a report
# with no stored output would, and copies figures/ into docs/figures/ only
# on the full renders listed in `copies`.
figure_runner <- function(site, copies) {
  full <- 0L
  function(args) {
    if (identical(args, "render")) {
      full <<- full + 1L
      if (full %in% copies) {
        dir.create(file.path(site, "docs", "figures"), recursive = TRUE, showWarnings = FALSE)
        file.copy(list.files(file.path(site, "figures"), full.names = TRUE, all.files = TRUE, no.. = TRUE),
                  file.path(site, "docs", "figures"))
      }
      writeBin(as.raw(1:4), file.path(site, "figures", "new.png"))
    }
    0L
  }
}

test_that("a full render that leaves a figure out of docs/figures/ runs once more, and never a third time", {
  site <- plain_site()
  dir.create(file.path(site, "figures"))
  dir.create(file.path(site, "docs", "figures"), recursive = TRUE)

  # No figure is missing: one full render.
  calls <- local_runner()
  expect_identical(suppressMessages(render_supplement(path = site)), "quarto render")
  expect_length(calls(), 1L)

  # The first full render saves a figure after Quarto listed figures/, the
  # second copies it.
  unlink(file.path(site, c("figures/new.png", "docs/figures/new.png")))
  calls <- local_runner(figure_runner(site, copies = 2L))
  messages <- capture_messages(out <- render_supplement(path = site))
  expect_identical(out, c("quarto render", "quarto render"))
  expect_length(calls(), 2L)
  expect_true(file.exists(file.path(site, "docs", "figures", "new.png")))
  expect_false(any(grepl("new.png", messages, fixed = TRUE)))

  # Neither full render copies it: two renders, then the missing name.
  unlink(file.path(site, c("figures/new.png", "docs/figures/new.png")))
  calls <- local_runner(figure_runner(site, copies = integer()))
  messages <- capture_messages(out <- render_supplement(path = site))
  expect_identical(out, c("quarto render", "quarto render"))
  expect_length(calls(), 2L)
  expect_true(any(grepl("figures/new.png", messages, fixed = TRUE)))
  expect_true(any(grepl("figures/**", messages, fixed = TRUE)))
})

test_that("a hidden figure missing from docs/figures/ also starts the second render", {
  site <- plain_site()
  dir.create(file.path(site, "figures", "sub"), recursive = TRUE)
  dir.create(file.path(site, "docs", "figures", "sub"), recursive = TRUE)
  writeBin(as.raw(1:4), file.path(site, "figures", "sub", ".hidden.png"))
  calls <- local_runner()
  out <- suppressMessages(render_supplement(path = site))
  expect_identical(out, c("quarto render", "quarto render"))
})

test_that("render_supplement() runs the Quarto copy that check_tools() reports", {
  site <- plain_site()
  run <- function() {
    calls <- list()
    local_mocked_bindings(quarto_run = function(quarto, args) {
      calls[[length(calls) + 1L]] <<- quarto
      0L
    })
    suppressMessages(render_supplement(path = site))
    calls[[1]]
  }
  dir <- withr::local_tempdir()
  on_path <- fake_quarto(file.path(dir, "path"))
  in_env <- fake_quarto(file.path(dir, "env"))
  in_editor <- fake_quarto(file.path(dir, "editor"))

  local_tools(which = list(quarto = on_path), env = list(QUARTO_PATH = in_env), editors = in_editor)
  expect_identical(run(), on_path)
  local_tools(env = list(QUARTO_PATH = in_env), editors = in_editor)
  expect_identical(run(), in_env)
  local_tools(editors = in_editor)
  expect_identical(run(), in_editor)

  # A copy whose version cannot be read is used.
  unknown <- fake_quarto(file.path(dir, "unknown"), version = NULL)
  local_tools(which = list(quarto = unknown))
  expect_identical(run(), unknown)
})

test_that("render_supplement() stops before any render when Quarto is missing or too old", {
  site <- plain_site()
  ran <- FALSE
  local_mocked_bindings(quarto_run = function(quarto, args) {
    ran <<- TRUE
    0L
  })
  local_tools()
  expect_error(render_supplement(path = site), class = "supplement_error_no_quarto")
  old <- fake_quarto(file.path(withr::local_tempdir(), "q"), version = "1.3.450\n")
  local_tools(which = list(quarto = old))
  expect_error(render_supplement(path = site), "1.3.450", class = "supplement_error_quarto_version")
  expect_false(ran)
})

test_that("render_supplement() checks its arguments and the site in order, before any render", {
  calls <- local_runner()
  site <- plain_site("a")
  bad_reports <- list(character(), NA_character_, c("a", NA), 1, factor("a"), list("a"))
  for (reports in bad_reports) {
    expect_error(render_supplement(reports, path = site), class = "supplement_error_argument")
  }
  # A bad path comes before a bad report name.
  expect_error(render_supplement("a b", path = ""), class = "supplement_error_argument")

  for (name in c("a.qmd", "CON")) {
    expect_error(render_supplement(name, path = site), class = "supplement_error_report_name")
  }
  # A bad name comes before a missing _quarto.yml.
  empty <- withr::local_tempdir()
  expect_error(render_supplement("a b", path = empty), class = "supplement_error_report_name")
  expect_error(render_supplement(path = empty), class = "supplement_error_no_config")
  dir.create(file.path(empty, "_quarto.yml"))
  expect_error(render_supplement(path = empty), class = "supplement_error_no_config")
  # A missing _quarto.yml comes before a missing report.
  expect_error(render_supplement("zz", path = empty), class = "supplement_error_no_config")

  dir.create(file.path(site, "analyses", "d.qmd"))
  err <- expect_error(render_supplement(c("a", "zz", "d", "yy"), path = site), class = "supplement_error_no_report")
  shown <- conditionMessage(err)
  expect_match(shown, "zz", fixed = TRUE)
  expect_match(shown, "yy", fixed = TRUE)
  expect_match(shown, "analyses/d.qmd", fixed = TRUE)
  expect_false(grepl("analyses/a.qmd", shown, fixed = TRUE))

  # The letter case must match the file's, also where the file system
  # ignores case.
  writeLines("---\ntitle: M\n---", file.path(site, "analyses", "models.qmd"))
  err <- expect_error(render_supplement("Models", path = site), class = "supplement_error_no_report")
  expect_match(conditionMessage(err), "analyses/Models.qmd", fixed = TRUE)
  expect_match(conditionMessage(err), "analyses/models.qmd", fixed = TRUE)
  expect_length(calls(), 0L)
})

test_that("a render that fails stops the function and runs no later command", {
  site <- plain_site(c("a", "b"))
  calls <- local_runner(function(args) if (identical(args, c("render", "analyses/a.qmd"))) 1L else 0L)
  before <- getwd()
  err <- expect_error(render_supplement(c("a", "b"), path = site), class = "supplement_error_render")
  expect_match(conditionMessage(err), "quarto render analyses/a.qmd", fixed = TRUE)
  expect_length(calls(), 1L)
  expect_identical(getwd(), before)
})

test_that("a Quarto that cannot be started gets its own message", {
  site <- plain_site()
  local_runner(function(args) 127L)
  err <- expect_error(render_supplement(path = site), class = "supplement_error_render")
  expect_match(conditionMessage(err), "could not be started", fixed = TRUE)
})

test_that("render_supplement() runs each render in the site folder and gives back the working folder", {
  site <- normalizePath(plain_site("a"), winslash = "/")
  seen <- character()
  local_runner(function(args) {
    seen <<- c(seen, normalizePath(getwd(), winslash = "/"))
    0L
  })
  before <- getwd()
  suppressMessages(render_supplement("a", path = site))
  expect_identical(seen, c(site, site))
  expect_identical(getwd(), before)
})

# Render tests with the real Quarto.

# Quarto 1.10 can stop a render with "database is locked" when test files
# render at once (see sass_cache_locked() in helper-template.R). Quarto
# prints to the console, not to R, so the lock text cannot be read here: a
# call that fails runs once more, and a real failure fails twice.
render_quiet <- function(...) {
  suppressMessages(tryCatch(
    render_supplement(...),
    supplement_error_render = function(e) {
      # Written to standard error, so the test log shows each rerun.
      cat("render_supplement() failed once, running it again:", conditionMessage(e), "\n", file = stderr())
      render_supplement(...)
    }
  ))
}

test_that("render_supplement() renders a new site", {
  skip_if_no_quarto()
  site <- long_dir(new_site())
  expect_identical(render_quiet(path = site), "quarto render")
  expect_true(file.exists(file.path(site, "docs", "index.html")))
})

test_that("a named report runs its code again, which a full render alone does not", {
  skip_if_no_quarto()
  site <- long_dir(new_site())
  render_quiet(path = site)
  report <- file.path(site, "analyses", "example.qmd")
  page <- file.path(site, "docs", "analyses", "example.html")
  # The value is built at run time, so the page holds it only in the
  # chunk's output.
  cat("\n```{r}\n#| label: render-marker\ncat(paste0(\"marker-\", \"new\"))\n```\n", file = report, append = TRUE)
  render_quiet(path = site)
  expect_false(grepl("marker-new", read_text(page), fixed = TRUE))
  out <- render_quiet("example", path = site)
  expect_identical(out, c("quarto render analyses/example.qmd", "quarto render"))
  expect_true(grepl("marker-new", read_text(page), fixed = TRUE))
})

test_that("a figure that a full render saves under a new name reaches docs/ in one call", {
  skip_if_no_quarto()
  site <- long_dir(new_site())
  render_quiet(path = site)
  suppressMessages(add_report("figs", "Figures", path = site))
  report <- file.path(site, "analyses", "figs.qmd")
  cat("\n```{r}\n#| label: new-figure\nsave_png(\"fig-new.png\", function() plot(1:3))\n```\n", file = report, append = TRUE)
  # One full render does not copy the figure (the mocked tests count the
  # renders), so its copy shows the second render ran.
  render_quiet(path = site)
  expect_true(file.exists(file.path(site, "docs", "figures", "fig-new.png")))
})

test_that("render_supplement() renders with the copy in QUARTO_PATH when none is on the path", {
  skip_if_no_quarto()
  real <- unname(Sys.which("quarto"))
  site <- long_dir(new_site())
  local_tools(env = list(QUARTO_PATH = real))
  expect_identical(render_quiet(path = site), "quarto render")
  expect_true(file.exists(file.path(site, "docs", "index.html")))
})
