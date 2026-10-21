test_that("a failed status check shows what the command printed", {
  skip_on_cran()
  script <- withr::local_tempfile(fileext = ".R")
  writeLines(c('cat("on-stdout\\n")', 'message("on-stderr")', "quit(status = 1)"), script)
  printed <- run_in(dirname(script), file.path(R.home("bin"), "Rscript"), shQuote(basename(script)))
  expect_equal(printed$status, 1L, info = paste(printed$output, collapse = "\n"))

  # Exit status 0 expected.
  expect_failure(expect_status(printed), "on-stdout")
  expect_failure(expect_status(printed), "on-stderr")
  # Exit status 1 and no output expected.
  expect_failure(expect_status(printed, 1L, output = character()), "on-stdout")
  expect_failure(expect_status(printed, 1L, output = character()), "on-stderr")
  # A status other than 0 expected, but the command exited 0.
  expect_failure(expect_command_fails(list(status = 0L, output = "on-stdout")), "on-stdout")
  # Each passes when the result matches.
  expect_success(expect_status(printed, 1L))
  expect_success(expect_command_fails(printed))
})

test_that("a check for no output shows the lines the command printed", {
  printed <- list(status = 1L, output = "docs/index.html")
  expect_failure(expect_status(printed, 1L, output = character()), "docs/index.html", fixed = TRUE)
  expect_success(expect_status(list(status = 1L, output = character()), 1L, output = character()))
})

test_that("a status check shows the expected output and refuses a missing status", {
  printed <- list(status = 0L, output = c("a.rds", "b.rds"))
  expect_failure(expect_status(printed, output = "a.rds"), "this output:\na.rds\n", fixed = TRUE)
  expect_failure(expect_status(printed, output = "a.rds"), "b.rds", fixed = TRUE)
  expect_success(expect_status(printed, output = c("a.rds", "b.rds")))

  # A result with no single whole-number status passes neither check, and
  # the message still shows the printed lines.
  for (status in list(NULL, NA_integer_, 0.5, "0", c(0L, 0L))) {
    result <- list(status = status, output = "printed-line")
    expect_failure(expect_status(result), "printed-line", fixed = TRUE)
    expect_failure(expect_command_fails(result), "printed-line", fixed = TRUE)
  }
})

test_that("a render whose setup script fails with no output shows the script's exit code", {
  skip_if_no_quarto(needs_r = FALSE)
  dir <- withr::local_tempdir("site-")
  expect_status(use_template(dir))
  # Quarto turns a failed project script into an error with no message, so
  # without debug logging the render prints only "Running script ...".
  writeLines("Deno.exit(3);", file.path(dir, "_scripts", "setup.ts"))

  rendered <- run_in(dir, "quarto", "render")
  expect_command_fails(rendered)
  expect_contains(rendered$output, "[execProcess] Success: false, code: 3")
})

test_that("a new site renders and holds its setup files", {
  skip_if_no_quarto()
  site <- site_copy()

  expect_status(site$used)
  expect_status(site$rendered)

  expected <- c(
    ".gitignore", "README.md", "index.qmd", "analyses/example.qmd",
    "data/example.csv", "LICENSE.md", "LICENSE-CC-BY.md", "docs/.nojekyll"
  )
  expect_true(all(file.exists(file.path(site$dir, expected))))
  expect_false(file.exists(file.path(site$dir, "_gitignore")))
  expect_false(file.exists(file.path(site$dir, "_README.md")))
})

test_that("report pages carry the site navbar and stored output", {
  skip_if_no_quarto()
  site <- site_copy()

  page <- read_text(file.path(site$dir, "docs", "analyses", "example.html"))
  header <- quarto_header(page)
  expect_match(header, 'href="../index.html"', fixed = TRUE)

  frozen <- list.files(file.path(site$dir, "_freeze", "analyses", "example"), recursive = TRUE)
  expect_gt(length(frozen), 0)
  # The report's figure reaches docs/ beside the page that shows it.
  expect_match(page, 'src="example_files/figure-html/bootstrap-1.png"', fixed = TRUE)
  expect_true(file.exists(file.path(site$dir, "docs", "analyses", "example_files", "figure-html", "bootstrap-1.png")))
})

test_that("the home page lists the reports through a Quarto listing", {
  index <- file.path(template_dir(), "index.qmd")
  listing <- front_matter(index)$listing
  expect_identical(listing$type, "table")
  expect_identical(listing$contents, "analyses/*.qmd")
  expect_identical(listing$fields, c("title", "description"))
  body <- readLines(index)
  expect_true(any(body == paste0("::: {#", listing$id, "}")))
  # The hand-written table is gone.
  expect_false(any(grepl("^\\s*\\|", body)))

  example <- front_matter(file.path(template_dir(), "analyses", "example.qmd"))
  expect_true(is.character(example$description) && nzchar(example$description))
})

test_that("the rendered home page lists the example report", {
  skip_if_no_quarto()
  site <- site_copy()

  html <- read_text(file.path(site$dir, "docs", "index.html"))
  rows <- listing_rows(html)
  expect_length(rows, 1)
  example <- front_matter(file.path(template_dir(), "analyses", "example.qmd"))
  expect_identical(rows[[1]]$cells, c(example$title, example$description))
  expect_true(any(grepl("(^|/)analyses/example\\.html$", rows[[1]]$links)))
})

test_that("the project freezes output and renders into docs", {
  skip_if_no_quarto()
  site <- site_copy()

  inspect <- run_in(site$dir, "quarto", "inspect")
  json <- paste(inspect$output, collapse = "\n")
  expect_match(json, '"freeze":\\s*true')
  expect_match(json, '"output-dir":\\s*"docs"')
})

test_that("a full render with R unreachable runs no report code", {
  skip_if_no_quarto()
  site <- site_copy()

  # Quarto looks for Rscript in QUARTO_R before R_HOME, PATH, and the Windows
  # registry. An empty folder there leaves Quarto no R to run, on every system.
  no_r_env <- c(QUARTO_R = withr::local_tempdir("no-r-"), R_HOME = NA)

  page <- file.path(site$dir, "docs", "analyses", "example.html")
  before <- readBin(page, "raw", file.info(page)$size)
  frozen <- list.files(file.path(site$dir, "_freeze"), recursive = TRUE, full.names = TRUE)
  frozen_times <- file.info(frozen)$mtime

  no_r <- withr::with_envvar(no_r_env, run_in(site$dir, "quarto", "render"))
  expect_status(no_r)

  after <- readBin(page, "raw", file.info(page)$size)
  expect_identical(after, before)
  expect_identical(file.info(frozen)$mtime, frozen_times)

  # In the same environment, a page with R code and no stored output cannot
  # render, because Quarto finds no R.
  writeLines(c("---", "title: Unfrozen", "---", "", "```{r}", "1 + 1", "```"),
             file.path(site$dir, "analyses", "unfrozen.qmd"))
  unfrozen <- withr::with_envvar(no_r_env, run_in(site$dir, "quarto", c("render", "analyses/unfrozen.qmd")))
  expect_command_fails(unfrozen)
  expect_match(paste(unfrozen$output, collapse = "\n"), "Unable to locate an installed version of R", fixed = TRUE)
})

test_that(".gitignore blocks fit files and keeps published output", {
  skip_if_no_quarto()
  skip_if_no_git()
  site <- site_copy()

  expect_status(git_in(site$dir, c("init", "-q")))
  ignored <- git_in(site$dir, c("check-ignore", "analyses/fits/m.rds", "x.rds"))
  expect_status(ignored)
  expect_setequal(ignored$output,c("analyses/fits/m.rds", "x.rds"))

  # The fits folder is ignored as a whole, saved R objects are ignored in any
  # letter case, and the negations for docs/ do not re-include them.
  objects <- c(
    "analyses/fits/m.json", "docs/data/x.rds", "_freeze/x/a.rds",
    "m.RDS", "m.Rda", "m.Rdata", "m.RData", "m.qs", "m.qs2"
  )
  ignored_objects <- git_in(site$dir, c("-c", "core.ignorecase=false", "check-ignore", objects))
  expect_status(ignored_objects)
  expect_setequal(ignored_objects$output, objects)

  kept <- git_in(
    site$dir,
    c("check-ignore", "_freeze/analyses/example/execute-results/html.json", "docs/index.html", "data/example.csv")
  )
  expect_status(kept, 1L, output = character())
})

test_that(".gitignore keeps figures/ and blocks figures saved in analyses/", {
  skip_if_no_quarto()
  skip_if_no_git()
  site <- site_copy()

  expect_status(git_in(site$dir, c("init", "-q")))
  expect_figure_rules(site$dir)
})

test_that("the example report saves a figure that the next full render publishes", {
  skip_if_no_quarto()
  dir <- withr::local_tempdir("site-")
  expect_status(use_template(dir))
  # Without the shipped figure, figures/bootstrap-means.png is new to this
  # render, so only the next render publishes it.
  expect_true(file.remove(file.path(dir, "figures", "bootstrap-means.png")))

  by_name <- run_in(dir, "quarto", c("render", "analyses/example.qmd"))
  expect_status(by_name)
  full <- run_in(dir, "quarto", "render")
  expect_status(full)

  png_signature <- as.raw(c(0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a))
  for (path in c("figures/bootstrap-means.png", "docs/figures/bootstrap-means.png")) {
    full_path <- file.path(dir, path)
    expect_true(file.exists(full_path), info = path)
    start <- if (file.exists(full_path)) readBin(full_path, "raw", 8L) else raw(0)
    expect_identical(start, png_signature, info = path)
  }
})

test_that("the first full render of a new site publishes the example figure", {
  skip_if_no_quarto()
  site <- new_site()

  expect_status(run_in(site, "quarto", "render"))
  figure <- file.path(site, "figures", "bootstrap-means.png")
  published <- file.path(site, "docs", "figures", "bootstrap-means.png")
  expect_true(file.exists(published))
  expect_identical(unname(tools::md5sum(published)), unname(tools::md5sum(figure)))
})

# A new site in its own parent folder, without the shipped figure, so that
# only the example report can write figures/bootstrap-means.png.
figure_site <- function(env = parent.frame()) {
  parent <- withr::local_tempdir("parent-", .local_envir = env)
  site <- file.path(parent, "site")
  suppressMessages(create_supplement(site))
  file.remove(file.path(site, "figures", "bootstrap-means.png"))
  list(parent = parent, site = site)
}

test_that("the example report saves its figure in the site with either execute-dir", {
  skip_if_no_quarto()
  for (execute_dir in c("file", "project")) {
    dirs <- figure_site()
    if (execute_dir == "project") {
      config <- file.path(dirs$site, "_quarto.yml")
      lines <- readLines(config)
      at <- which(lines == "  output-dir: docs")
      writeLines(append(lines, "  execute-dir: project", after = at), config)
    }

    expect_status(run_in(dirs$site, "quarto", "render"))
    expect_true(file.exists(file.path(dirs$site, "figures", "bootstrap-means.png")), info = execute_dir)
    expect_false(file.exists(file.path(dirs$parent, "figures")), info = execute_dir)
  }
})

test_that("the example code run by hand from analyses/ saves into the site's figures/", {
  skip_on_cran()
  skip_if_not(capabilities("png"), "R has no png device")
  dirs <- figure_site()
  qmd <- file.path(dirs$site, "analyses", "example.qmd")
  code <- unlist(lapply(c("data", "bootstrap", "save-figure"), chunk_code, path = qmd))

  # The bootstrap chunk draws on the current device.
  grDevices::pdf(NULL)
  device <- grDevices::dev.cur()
  on.exit(grDevices::dev.off(device), add = TRUE)
  withr::with_envvar(c(QUARTO_PROJECT_DIR = NA), withr::with_dir(
    file.path(dirs$site, "analyses"),
    eval(parse(text = code), envir = new.env())
  ))
  # save_png() makes the earlier device current again.
  expect_identical(grDevices::dev.cur(), device)
  expect_true(file.exists(file.path(dirs$site, "figures", "bootstrap-means.png")))
  expect_false(file.exists(file.path(dirs$parent, "figures")))
})

test_that("a failed plot in the example closes its device and leaves figures/ as it was", {
  skip_on_cran()
  skip_if_not(capabilities("png"), "R has no png device")
  site <- new_site()
  code <- chunk_code(file.path(site, "analyses", "example.qmd"), "save-figure")
  figures <- file.path(site, "figures")

  # The chunk runs alone, as an author who copies it runs it, so it finds
  # the site folder itself. folder_md5() also reads hidden files, so a
  # temporary file left in figures/ fails the test.
  expect_failed_plot_changes_nothing <- function() {
    env <- new.env()
    env$boot_means <- c(1, 2, 3)
    env$hist <- function(...) stop("the plot failed")
    devices <- grDevices::dev.list()
    before <- folder_md5(figures)
    expect_error(
      withr::with_envvar(c(QUARTO_PROJECT_DIR = NA), withr::with_dir(
        file.path(site, "analyses"),
        eval(parse(text = code), envir = env)
      )),
      "the plot failed"
    )
    after <- grDevices::dev.list()
    for (d in setdiff(after, devices)) grDevices::dev.off(d)
    expect_identical(after, devices)
    expect_identical(folder_md5(figures), before)
  }

  # With the shipped figure in place, and then with no figure.
  expect_failed_plot_changes_nothing()
  expect_true(file.remove(file.path(figures, "bootstrap-means.png")))
  expect_failed_plot_changes_nothing()
})

test_that("save_png() refuses a folder at its target and a plot that is not a function", {
  skip_on_cran()
  skip_if_not(capabilities("png"), "R has no png device")
  site <- new_site()
  code <- chunk_code(file.path(site, "analyses", "example.qmd"), "save-figure")
  figures <- file.path(site, "figures")
  env <- new.env()
  env$boot_means <- c(1, 2, 3)
  # Define save_png() and save the example figure once.
  withr::with_envvar(c(QUARTO_PROJECT_DIR = NA), withr::with_dir(
    file.path(site, "analyses"),
    eval(parse(text = code), envir = env)
  ))

  dir.create(file.path(figures, "taken.png"))
  before <- folder_md5(figures)
  withr::with_dir(file.path(site, "analyses"), {
    expect_error(env$save_png("taken.png", function() plot(1)), "taken.png is a folder.", fixed = TRUE)
    expect_error(env$save_png("p.png", 42), "Pass the plot as a function", fixed = TRUE)
  })
  expect_identical(folder_md5(figures), before)
  expect_true(dir.exists(file.path(figures, "taken.png")))
})

test_that("the figure rules hold in sites made by create_supplement()", {
  skip_if_no_quarto()
  skip_if_no_git()
  local_plain_git()

  # git init after the first render: setup renames _gitignore.
  after <- new_site()
  expect_status(run_in(after, "quarto", "render"))
  expect_status(git_in(after, c("init", "-q")))
  expect_figure_rules(after)

  # git init before it: Quarto writes a .gitignore, and setup merges into it.
  before <- new_site()
  expect_status(git_in(before, c("init", "-q")))
  expect_status(run_in(before, "quarto", "render"))
  expect_figure_rules(before)
})

test_that("a file named figures stops the example report with a message", {
  skip_if_no_quarto()
  site <- new_site()
  unlink(file.path(site, "figures"), recursive = TRUE)
  writeLines("not a folder", file.path(site, "figures"))

  rendered <- run_in(site, "quarto", c("render", "analyses/example.qmd"))
  expect_command_fails(rendered)
  expect_true(any(grepl("`figures` is a file, not a folder", rendered$output, fixed = TRUE)),
              info = command_failure(rendered, "the figures message"))
})

test_that("setup adds the template rules to an existing .gitignore", {
  skip_if_no_quarto()
  dir <- withr::local_tempdir("site-")
  expect_status(use_template(dir))
  writeLines("mine", file.path(dir, ".gitignore"))

  expect_status(run_in(dir, "quarto", "render"))
  kept <- readLines(file.path(dir, ".gitignore"))
  expect_equal(kept[1], "mine")
  expect_true(all(c("*.[Rr][Dd][Ss]", "analyses/fits/") %in% kept))
  expect_equal(sum(kept == "*.[Rr][Dd][Ss]"), 1L)
  expect_equal(utils::tail(kept, 2), c("!docs/", "!_freeze/"))
  expect_false(file.exists(file.path(dir, "_gitignore")))
})

expect_site_not_ignored <- function(existing_gitignore) {
  dir <- withr::local_tempdir("site-")
  expect_status(use_template(dir))
  writeBin(charToRaw(existing_gitignore), file.path(dir, ".gitignore"))

  expect_status(run_in(dir, "quarto", "render"))
  expect_status(git_in(dir, c("init", "-q")))
  kept <- git_in(dir, c("check-ignore", "docs/index.html", "_freeze/analyses/example/execute-results/html.json"))
  expect_status(kept, 1L, output = character())
}

test_that("a docs/ rule in an existing .gitignore does not hide the site", {
  skip_if_no_quarto()
  skip_if_no_git()
  # GitHub's R .gitignore template ignores docs/.
  expect_site_not_ignored(".Rhistory\ndocs/\n")
  # Windows line endings and no final newline.
  expect_site_not_ignored(".Rhistory\r\ndocs/")
  # A negation that comes before a later docs/ rule.
  expect_site_not_ignored("!docs/\n!_freeze/\ndocs/\n_freeze/\n")
})

test_that("fit files stay ignored when git init comes before the first render", {
  skip_if_no_quarto()
  skip_if_no_git()
  dir <- withr::local_tempdir("site-")
  expect_status(use_template(dir))
  expect_status(git_in(dir, c("init", "-q")))

  expect_status(run_in(dir, "quarto", "render"))
  ignored <- git_in(dir, c("check-ignore", "analyses/fits/m.rds", "x.rds"))
  expect_status(ignored)
  expect_setequal(ignored$output,c("analyses/fits/m.rds", "x.rds"))
  expect_figure_rules(dir)
})

test_that("setup keeps an existing README.md and writes the guide beside it", {
  skip_if_no_quarto()
  dir <- withr::local_tempdir("site-")
  expect_status(use_template(dir))
  writeLines("my readme", file.path(dir, "README.md"))

  expect_status(run_in(dir, "quarto", "render"))
  expect_equal(readLines(file.path(dir, "README.md")), "my readme")
  expect_equal(
    readLines(file.path(dir, "SUPPLEMENT.md")),
    readLines(file.path(template_dir(), "_README.md"))
  )
  expect_false(file.exists(file.path(dir, "_README.md")))
})

test_that("setup keeps both files when README.md and SUPPLEMENT.md exist", {
  skip_if_no_quarto()
  dir <- withr::local_tempdir("site-")
  expect_status(use_template(dir))
  writeLines("my readme", file.path(dir, "README.md"))
  writeLines("my supplement", file.path(dir, "SUPPLEMENT.md"))

  expect_status(run_in(dir, "quarto", "render"))
  expect_equal(readLines(file.path(dir, "README.md")), "my readme")
  expect_equal(readLines(file.path(dir, "SUPPLEMENT.md")), "my supplement")
  expect_false(file.exists(file.path(dir, "_README.md")))
})

# Lines that hide sessioninfo from code that asks requireNamespace() for it.
# On macOS, sessioninfo can sit in R's own library, so no library path
# setting hides it.
hide_sessioninfo <- c(
  "requireNamespace <- function(package, ...) {",
  "  if (identical(package, \"sessioninfo\")) FALSE else base::requireNamespace(package, ...)",
  "}"
)

test_that("the example page shows the R and knitr versions of its render", {
  skip_if_no_quarto()
  withr::local_envvar(QUARTO_R = NA)

  # The knitr version of the Rscript in R_HOME, which Quarto runs when
  # QUARTO_R is unset.
  dir <- withr::local_tempdir("knitr-")
  writeLines('cat(as.character(packageVersion("knitr")), "\\n")', file.path(dir, "v.R"))
  knitr <- run_in(dir, home_rscript(), "v.R")
  expect_status(knitr)
  version <- trimws(utils::tail(knitr$output, 1))
  expect_match(version, "^[0-9]+(\\.[0-9]+)+$")
  # sessionInfo() prints knitr_1.52, and session_info() prints knitr  1.52.
  # The end of the match keeps 1.5 from matching inside 1.52.
  knitr_rx <- paste0("knitr(_| +\\*? *)", rx_escape(version), "(\\s|$)")

  # Whether that R finds sessioninfo, which decides the branch of a render
  # that hides nothing.
  writeLines('cat(requireNamespace("sessioninfo", quietly = TRUE), "\\n")', file.path(dir, "s.R"))
  found <- run_in(dir, home_rscript(), "s.R")
  expect_status(found)
  has_sessioninfo <- identical(trimws(utils::tail(found$output, 1)), "TRUE")

  # The home folder in each spelling, which the page must not show.
  homes <- Sys.getenv(c("USERPROFILE", "HOME"))
  homes <- homes[nchar(homes) > 3]
  homes <- unique(c(homes, chartr("\\", "/", homes), chartr("/", "\\", homes)))

  # One render as the machine is, and one with sessioninfo hidden through
  # a profile that R reads at the start of the render.
  profile <- file.path(dir, "hide-sessioninfo.R")
  writeLines(hide_sessioninfo, profile)
  for (hidden in c(FALSE, TRUE)) {
    site <- new_site()
    if (hidden) {
      withr::with_envvar(c(R_PROFILE_USER = profile), expect_status(run_in(site, "quarto", "render")))
    } else {
      expect_status(run_in(site, "quarto", "render"))
    }

    page <- read_text(file.path(site, "docs", "analyses", "example.html"))
    section <- section_html(page, "computing-environment")
    expect_match(section, "<h2[^>]*>Computing environment</h2>", info = hidden)
    text <- html_text(section)
    expect_match(text, "R version [0-9]+\\.[0-9]+\\.[0-9]+", info = hidden)
    expect_match(text, knitr_rx, info = hidden)
    if (hidden || !has_sessioninfo) {
      expect_match(text, "attached base packages", fixed = TRUE, info = hidden)
      expect_no_match(text, "Session info", fixed = TRUE, info = hidden)
    } else {
      expect_match(text, "Session info", fixed = TRUE)
      expect_no_match(text, "attached base packages", fixed = TRUE)
    }
    for (home in homes) {
      expect_no_match(page, home, fixed = TRUE, info = paste(hidden, home))
    }
  }
})

# Run the code of the example report's session-info chunk with Rscript, after
# the lines in `before`, and return all it printed as one string.
run_session_code <- function(before = character(), env = parent.frame()) {
  code <- chunk_code(file.path(template_dir(), "analyses", "example.qmd"), "session-info")
  dir <- withr::local_tempdir("session-", .local_envir = env)
  writeLines(c(before, code), file.path(dir, "session.R"))
  out <- run_in(dir, home_rscript(), "session.R")
  expect_status(out)
  paste(out$output, collapse = "\n")
}

test_that("the environment section prints sessionInfo() when sessioninfo is not found", {
  skip_on_cran()
  text <- run_session_code(hide_sessioninfo)
  expect_match(text, "attached base packages", fixed = TRUE)
  expect_no_match(text, "Session info", fixed = TRUE)
})

test_that("the environment section prints session_info() when sessioninfo is installed", {
  skip_on_cran()
  skip_if_not_installed("sessioninfo")
  text <- run_session_code()
  expect_match(text, "Session info", fixed = TRUE)
  expect_no_match(text, "attached base packages", fixed = TRUE)
})

test_that("the environment section shows the home folder as ~", {
  skip_on_cran()
  skip_if_not_installed("sessioninfo")
  # With R's own folder as the home folder, the library folder that
  # session_info() lists, R_HOME/library, is inside the home folder.
  home <- normalizePath(R.home(), winslash = "/")
  text <- run_session_code(c(
    sprintf("Sys.setenv(HOME = %s)", deparse(home)),
    'Sys.unsetenv("USERPROFILE")'
  ))
  expect_match(text, "~/library", fixed = TRUE)
  expect_no_match(text, home, fixed = TRUE)
})
