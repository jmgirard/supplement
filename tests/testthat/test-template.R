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
  writeLines("os.exit(3)", file.path(dir, "_scripts", "setup.lua"))

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

test_that("a full render runs the project scripts through Pandoc and starts no Deno", {
  skip_if_no_quarto()
  site <- new_site()

  rendered <- withr::with_envvar(c(QUARTO_LOG_LEVEL = "DEBUG"), run_in(site, "quarto", "render"))
  expect_status(rendered)
  expect_true(file.exists(file.path(site, "docs", ".nojekyll")))

  log <- paste(rendered$output, collapse = "\n")
  expect_match(rendered$output, "--lua-filter _scripts/setup.lua", fixed = TRUE, all = FALSE, info = log)
  expect_match(rendered$output, "--lua-filter _scripts/nojekyll.lua", fixed = TRUE, all = FALSE, info = log)
  expect_no_match(rendered$output, 'deno(\\.exe)?"? run', info = log)
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

test_that("a full render with R unreachable runs no code of a report with stored output", {
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

test_that("the example's site chunk finds the site folder from analyses/ or the site folder", {
  code <- chunk_code(file.path(template_dir(), "analyses", "example.qmd"), "site")
  site_from <- function(dir, project_dir) {
    env <- new.env()
    withr::with_envvar(c(QUARTO_PROJECT_DIR = project_dir), withr::with_dir(
      dir,
      eval(parse(text = code), envir = env)
    ))
    env$site
  }
  site <- new_site()
  analyses <- file.path(site, "analyses")
  for (unset in list(NA, "")) {
    expect_identical(site_from(analyses, unset), "..", info = format(unset))
    expect_identical(site_from(site, unset), ".", info = format(unset))
  }

  # When both folders hold _quarto.yml, the current folder wins.
  parent <- withr::local_tempdir("parent-")
  file.create(file.path(parent, "_quarto.yml"))
  nested <- file.path(parent, "site")
  suppressMessages(create_supplement(nested))
  expect_identical(site_from(nested, NA), ".")

  other <- withr::local_tempdir("other-")
  expect_identical(site_from(analyses, other), other)

  lost <- file.path(withr::local_tempdir("lost-"), "a", "b")
  dir.create(lost, recursive = TRUE)
  for (unset in list(NA, "")) {
    expect_error(
      site_from(lost, unset),
      "Run this code from the site folder or from its analyses/ folder.",
      fixed = TRUE
    )
  }
})

test_that("the guide's figure code starts with the example's site chunk", {
  readme <- readLines(file.path(template_dir(), "GUIDE.md"), encoding = "UTF-8")
  section <- readme[which(readme == "## Paper figures"):length(readme)]
  start <- which(section == "```r")[1]
  end <- which(section == "```")
  block <- section[(start + 1L):(min(end[end > start]) - 1L)]

  chunk <- chunk_code(file.path(template_dir(), "analyses", "example.qmd"), "site")
  chunk <- chunk[!startsWith(chunk, "#|")]
  expect_identical(block[seq_along(chunk)], chunk)
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

test_that("a report from add_report() reads data through its site chunk with either execute-dir", {
  skip_if_no_quarto()
  rows <- nrow(read.csv(file.path(template_dir(), "data", "example.csv")))
  # One site for each setup, because a second render of one site would
  # reuse the stored output and run no code.
  for (execute_dir in c("file", "project")) {
    site <- new_site()
    if (execute_dir == "project") {
      config <- file.path(site, "_quarto.yml")
      lines <- readLines(config)
      at <- which(lines == "  output-dir: docs")
      writeLines(append(lines, "  execute-dir: project", after = at), config)
    }
    report <- suppressMessages(add_report("counts", "Counts", path = site))
    cat(
      "", "```{r}", "#| label: count",
      'nrow(read.csv(file.path(site, "data", "example.csv")))', "```",
      file = report, sep = "\n", append = TRUE
    )

    expect_status(run_in(site, "quarto", "render"))
    page <- paste(readLines(file.path(site, "docs", "analyses", "counts.html"), warn = FALSE), collapse = "\n")
    # The output block that follows the count chunk's code.
    after <- substring(page, regexpr('"example.csv"', page, fixed = TRUE))
    output <- regmatches(after, regexpr('(?s)cell-output-stdout">\\s*<pre><code>.*?</code>', after, perl = TRUE))
    expect_identical(
      sub("(?s).*<code>(.*)</code>", "\\1", output, perl = TRUE),
      paste("[1]", rows),
      info = execute_dir
    )
  }
})

test_that("the example code run by hand from analyses/ saves into the site's figures/", {
  skip_on_cran()
  skip_if_not(capabilities("png"), "R has no png device")
  dirs <- figure_site()
  qmd <- file.path(dirs$site, "analyses", "example.qmd")
  code <- unlist(lapply(c("site", "data", "bootstrap", "save-figure"), chunk_code, path = qmd))

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
  qmd <- file.path(site, "analyses", "example.qmd")
  code <- unlist(lapply(c("site", "save-figure"), chunk_code, path = qmd))
  figures <- file.path(site, "figures")

  # The chunk runs after the site chunk only, as an author who copies the
  # two runs them. folder_md5() also reads hidden files, so a temporary file
  # left in figures/ fails the test.
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
  qmd <- file.path(site, "analyses", "example.qmd")
  code <- unlist(lapply(c("site", "save-figure"), chunk_code, path = qmd))
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

test_that("save_png() keeps its target as it was when the PNG file lacks its end chunk", {
  skip_on_cran()
  skip_if_not(capabilities("png"), "R has no png device")
  site <- new_site()
  qmd <- file.path(site, "analyses", "example.qmd")
  code <- unlist(lapply(c("site", "save-figure"), chunk_code, path = qmd))
  figures <- file.path(site, "figures")
  env <- new.env()
  env$boot_means <- c(1, 2, 3)
  withr::with_envvar(c(QUARTO_PROJECT_DIR = NA), withr::with_dir(
    file.path(site, "analyses"),
    eval(parse(text = code), envir = env)
  ))
  earlier <- read_bytes(file.path(figures, "bootstrap-means.png"))

  # Each probe changes the device's file after the device closes it.
  probes <- list(
    "no file" = function(path) file.remove(path),
    "0 bytes" = function(path) writeBin(raw(0), path),
    "11 bytes" = function(path) writeBin(read_bytes(path)[1:11], path),
    "the last byte cut" = function(path) writeBin(utils::head(read_bytes(path), -1L), path)
  )
  for (probe in names(probes)) {
    env$dev.off <- function(which) {
      grDevices::dev.off(which)
      probes[[probe]](list.files(figures, "^\\.save-.*\\.png$", all.files = TRUE, full.names = TRUE))
    }
    for (file in c("new.png", "bootstrap-means.png")) {
      info <- paste(probe, "with", file)
      withr::with_dir(file.path(site, "analyses"), expect_error(
        env$save_png(file, function() plot(1)),
        paste0("Could not write a whole PNG file for \\S*", gsub(".", "\\.", file, fixed = TRUE)),
        info = info
      ))
      expect_length(list.files(figures, "^\\.save-", all.files = TRUE), 0L)
    }
    expect_false(file.exists(file.path(figures, "new.png")), info = probe)
    expect_identical(read_bytes(file.path(figures, "bootstrap-means.png")), earlier, info = probe)
  }
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

test_that("the example report makes a missing figures folder and saves its figure there", {
  skip_if_no_quarto()
  site <- new_site()
  unlink(file.path(site, "figures"), recursive = TRUE)

  expect_status(run_in(site, "quarto", c("render", "analyses/example.qmd")))
  expect_true(file.exists(file.path(site, "figures", "bootstrap-means.png")))
})

# Replace the site's figures/ with a link to `target`, render the example
# report by name, and return the render.
render_with_linked_figures <- function(site, target) {
  figures <- file.path(site, "figures")
  unlink(figures, recursive = TRUE)
  symlink_or_skip(target, figures)
  run_in(site, "quarto", c("render", "analyses/example.qmd"))
}


test_that("a figures link to a folder outside the site stops the example report", {
  skip_if_no_quarto()
  site <- new_site()
  # On Windows symlink_or_skip() makes a junction to the folder.
  outside <- withr::local_tempdir("outside-")
  writeLines("kept", file.path(outside, "other.txt"))
  before <- folder_state(outside)

  rendered <- render_with_linked_figures(site, outside)
  expect_command_fails(rendered)
  expect_match(rendered$output, "`figures` is a link", fixed = TRUE, all = FALSE,
               info = command_failure(rendered, "the link message"))
  expect_identical(folder_state(outside), before)
})

test_that("a figures link to a missing path stops the example report", {
  skip_if_no_quarto()
  site <- new_site()

  rendered <- render_with_linked_figures(site, file.path(site, "gone"))
  expect_command_fails(rendered)
  # On Windows a file link to a missing path reads as a file in base R.
  message <- if (.Platform$OS.type == "windows") "`figures` is a (link|file, not a folder)" else "`figures` is a link"
  expect_match(rendered$output, message, all = FALSE,
               info = command_failure(rendered, "the link message"))
})

test_that("a figures link to a file stops the example report", {
  skip_on_os("windows")
  skip_if_no_quarto()
  site <- new_site()
  outside <- withr::local_tempdir("outside-")
  writeLines("kept", file.path(outside, "figures.txt"))
  before <- folder_state(outside)

  rendered <- render_with_linked_figures(site, file.path(outside, "figures.txt"))
  expect_command_fails(rendered)
  expect_match(rendered$output, "`figures` is a link", fixed = TRUE, all = FALSE,
               info = command_failure(rendered, "the link message"))
  expect_identical(folder_state(outside), before)
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

# A project with the template's two scripts, _gitignore, _README.md, and
# GUIDE.md, and one page with no code, so a render runs no R. `files` maps
# file names to the bytes they start with.
script_site <- function(files = list(), dir = withr::local_tempdir("scripts-", .local_envir = env),
                        env = parent.frame()) {
  dir.create(file.path(dir, "_scripts"), recursive = TRUE)
  file.copy(file.path(template_dir(), c("_gitignore", "_README.md", "GUIDE.md")), dir)
  file.copy(file.path(template_dir(), "_scripts", c("setup.lua", "nojekyll.lua")), file.path(dir, "_scripts"))
  writeLines(
    c("project:", "  type: website", "  output-dir: docs",
      "  pre-render: _scripts/setup.lua", "  post-render: _scripts/nojekyll.lua"),
    file.path(dir, "_quarto.yml")
  )
  writeLines(c("---", "title: Home", "---", "", "Hi"), file.path(dir, "index.qmd"))
  for (name in names(files)) writeBin(charToRaw(files[[name]]), file.path(dir, name))
  dir
}

# The non-blank lines of the template's _gitignore other than the two that
# setup keeps last.
template_ignore_lines <- function() {
  lines <- readLines(file.path(template_dir(), "_gitignore"))
  lines[grepl("\\S", lines) & !lines %in% c("!docs/", "!_freeze/")]
}

lf_lines <- function(lines) paste0(lines, "\n", collapse = "")

# Before the setup script runs, Quarto adds these lines to an existing
# .gitignore that lacks one and rewrites the whole file, so each .gitignore
# that a test writes holds them and reaches the script as written.
quarto_ignore <- c("/.quarto/", "**/*.quarto_ipynb")

# The lines that setup appends to a .gitignore holding the lines `have`,
# which do not end with `!docs/` and `!_freeze/`.
appended <- function(have) {
  lines <- template_ignore_lines()
  lf_lines(c(lines[!lines %in% have], "!docs/", "!_freeze/"))
}

test_that("setup appends the template's missing lines after the existing bytes", {
  skip_if_no_quarto(needs_r = FALSE)
  lines <- template_ignore_lines()
  some <- c("mine", quarto_ignore, lines[2])
  all <- c(quarto_ignore, lines)
  cases <- list(
    "LF" = list(before = lf_lines(some), added = appended(some)),
    "CRLF" = list(before = paste0(some, "\r\n", collapse = ""), added = appended(some)),
    "no final line break" = list(before = paste(some, collapse = "\r\n"), added = paste0("\n", appended(some))),
    "the two lines last and a template line missing" = list(
      before = lf_lines(c(quarto_ignore, lines[-1], "!docs/", "!_freeze/")),
      added = lf_lines(c(lines[1], "!docs/", "!_freeze/"))
    ),
    "the two lines before a later rule" = list(
      before = lf_lines(c(all, "!docs/", "!_freeze/", "docs/")),
      added = lf_lines(c("!docs/", "!_freeze/"))
    ),
    "complete" = list(before = paste0(c(all, "!docs/", "!_freeze/", ""), "\r\n", collapse = ""), added = "")
  )

  for (case in names(cases)) {
    dir <- script_site(list(.gitignore = cases[[case]]$before))
    expect_status(run_in(dir, "quarto", "render"))
    expect_identical(
      read_bytes(file.path(dir, ".gitignore")),
      charToRaw(paste0(cases[[case]]$before, cases[[case]]$added)),
      info = case
    )
    expect_false(file.exists(file.path(dir, "_gitignore")), info = case)
  }
})

test_that("setup renames _gitignore and _README.md with their bytes", {
  skip_if_no_quarto(needs_r = FALSE)
  dir <- script_site()

  expect_status(run_in(dir, "quarto", "render"))
  expect_identical(read_bytes(file.path(dir, ".gitignore")), read_bytes(file.path(template_dir(), "_gitignore")))
  expect_identical(read_bytes(file.path(dir, "README.md")), read_bytes(file.path(template_dir(), "_README.md")))
  expect_false(file.exists(file.path(dir, "_gitignore")))
  expect_false(file.exists(file.path(dir, "_README.md")))
})

test_that("setup keeps an existing README.md and writes no SUPPLEMENT.md", {
  skip_if_no_quarto(needs_r = FALSE)
  guide <- read_bytes(file.path(template_dir(), "GUIDE.md"))
  cases <- list(
    "no README.md" = list(),
    "a README.md" = list(.gitignore = lf_lines(c("mine", quarto_ignore)), README.md = "my readme\r\n"),
    "a README.md and a SUPPLEMENT.md" = list(README.md = "my readme", SUPPLEMENT.md = "my supplement\r\n")
  )

  for (case in names(cases)) {
    files <- cases[[case]]
    dir <- script_site(files)
    expect_status(run_in(dir, "quarto", "render"))
    for (file in intersect(names(files), c("README.md", "SUPPLEMENT.md"))) {
      expect_identical(read_bytes(file.path(dir, file)), charToRaw(files[[file]]), info = paste(case, file))
    }
    if (!"SUPPLEMENT.md" %in% names(files)) {
      expect_false(file.exists(file.path(dir, "SUPPLEMENT.md")), info = case)
    }
    expect_identical(read_bytes(file.path(dir, "GUIDE.md")), guide, info = case)
    expect_false(file.exists(file.path(dir, "_README.md")), info = case)

    kept <- intersect(c(".gitignore", "README.md", "GUIDE.md", "SUPPLEMENT.md"), list.files(dir, all.files = TRUE))
    first <- lapply(file.path(dir, kept), read_bytes)
    expect_status(run_in(dir, "quarto", "render"))
    expect_identical(lapply(file.path(dir, kept), read_bytes), first, info = case)
  }
})

test_that("a second render leaves the .gitignore that setup renamed", {
  skip_if_no_quarto(needs_r = FALSE)
  # Quarto also requires /_*.local when a file such as _environment.local
  # sits in the project folder.
  cases <- list("no local file" = list(), "a local file" = list(`_environment.local` = "SUPPLEMENT_X=1\n"))
  for (case in names(cases)) {
    dir <- script_site(cases[[case]])
    expect_status(run_in(dir, "quarto", "render"))
    expect_identical(read_bytes(file.path(dir, ".gitignore")), read_bytes(file.path(template_dir(), "_gitignore")),
                     info = case)

    expect_status(run_in(dir, "quarto", "render"))
    expect_identical(read_bytes(file.path(dir, ".gitignore")), read_bytes(file.path(template_dir(), "_gitignore")),
                     info = case)
  }
})

test_that("a setup step that fails stops the render and names the script", {
  skip_if_no_quarto(needs_r = FALSE)
  ignore <- lf_lines(c("mine", quarto_ignore))
  expect_setup_error <- function(dir, case, message) {
    rendered <- withr::with_envvar(c(QUARTO_LOG_LEVEL = "INFO"), run_in(dir, "quarto", "render"))
    log <- paste(c(case, rendered$output), collapse = "\n")
    expect_command_fails(rendered)
    expect_match(rendered$output, "Error running filter '_scripts/setup.lua'", fixed = TRUE, all = FALSE, info = log)
    expect_match(rendered$output, message, all = FALSE, info = log)
    expect_identical(read_bytes(file.path(dir, ".gitignore")), charToRaw(ignore), info = case)
  }

  # The script cannot read a folder in place of the template's _gitignore.
  # On Windows the open fails; elsewhere the read does.
  folder <- script_site(list(.gitignore = ignore))
  file.remove(file.path(folder, "_gitignore"))
  dir.create(file.path(folder, "_gitignore"))
  expect_setup_error(folder, "a _gitignore folder", "_gitignore: Permission denied|Is a directory")

  # Nor append to a .gitignore that is read-only.
  skip_if(Sys.info()[["user"]] == "root", "root can read and write any file")
  locked <- script_site(list(.gitignore = ignore))
  Sys.chmod(file.path(locked, ".gitignore"), "444")
  withr::defer(Sys.chmod(file.path(locked, ".gitignore"), "644"))
  expect_setup_error(locked, "a read-only .gitignore", "\\.gitignore: Permission denied")
})

test_that("the scripts run in a site folder whose path holds a non-ASCII letter", {
  skip_if_no_quarto(needs_r = FALSE)
  dir <- file.path(withr::local_tempdir(), paste0("site-", intToUtf8(233)))
  have <- c("mine", quarto_ignore)
  script_site(list(.gitignore = lf_lines(have), README.md = "my readme\n"), dir = dir)

  expect_status(run_in(dir, "quarto", "render"))
  expect_identical(read_bytes(file.path(dir, ".gitignore")), charToRaw(paste0(lf_lines(have), appended(have))))
  expect_identical(read_bytes(file.path(dir, "README.md")), charToRaw("my readme\n"))
  expect_false(file.exists(file.path(dir, "_gitignore")))
  expect_false(file.exists(file.path(dir, "_README.md")))
  expect_true(file.exists(file.path(dir, "docs", ".nojekyll")))
})

test_that("the post-render script writes .nojekyll under a letter outside the Windows code page", {
  skip_if_no_quarto(needs_r = FALSE)
  # U+4E2D is outside Windows-1252. Quarto 1.10.19's own filters cannot
  # render in such a folder on a Windows-1252 system ("cannot encode
  # character"), so Quarto's Pandoc runs the script the way a render does.
  dir <- file.path(withr::local_tempdir(), paste0("site-", intToUtf8(0x4E2D)))
  dir.create(file.path(dir, "docs"), recursive = TRUE)
  dir.create(file.path(dir, "_scripts"))
  file.copy(file.path(template_dir(), "_scripts", "nojekyll.lua"), file.path(dir, "_scripts"))
  file.create(file.path(dir, "empty.md"))

  output <- normalizePath(file.path(dir, "docs"), mustWork = TRUE)
  ran <- withr::with_envvar(c(QUARTO_PROJECT_OUTPUT_DIR = output), run_in(
    dir, "quarto",
    c("pandoc", "--from", "markdown", "--to", "plain", "--lua-filter", "_scripts/nojekyll.lua", "empty.md")
  ))
  expect_status(ran)
  expect_true(file.exists(file.path(dir, "docs", ".nojekyll")))
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

  # The home folder in each spelling, which the page must not show in any
  # letter case.
  homes <- Sys.getenv(c("USERPROFILE", "HOME"))
  homes <- homes[nzchar(homes)]
  homes <- c(homes, normalizePath(homes, winslash = "/", mustWork = FALSE))
  homes <- c(chartr("\\", "/", homes), chartr("/", "\\", homes))
  homes <- unique(sub("[/\\\\]+$", "", homes))
  homes <- homes[!grepl("^([A-Za-z]:)?$", homes)]

  # One render as the machine is, and one with sessioninfo hidden by a
  # chunk that the test puts in its copy of the report, before the section.
  # The chunk runs in the R that Quarto starts, on every system.
  for (hidden in c(FALSE, TRUE)) {
    site <- new_site()
    if (hidden) {
      report <- file.path(site, "analyses", "example.qmd")
      text <- rawToChar(read_bytes(report))
      at <- regexpr("\n## Computing environment\n", text, fixed = TRUE)
      stopifnot("the example report has a Computing environment heading" = at > 0)
      chunk <- paste(c("", "```{r}", "#| include: false", hide_sessioninfo, "```", "", ""), collapse = "\n")
      text <- paste0(substring(text, 1, at), chunk, substring(text, at + 1))
      writeBin(charToRaw(text), report)
    }
    expect_status(run_in(site, "quarto", "render"))

    page <- read_text(file.path(site, "docs", "analyses", "example.html"))
    section <- section_html(page, "computing-environment")
    # testthat needs `info` as text.
    info <- sprintf("hidden: %s, sessioninfo found: %s", hidden, has_sessioninfo)
    expect_match(section, "<h2[^>]*>Computing environment</h2>", info = info)
    text <- html_text(section)
    expect_match(text, "R version [0-9]+\\.[0-9]+\\.[0-9]+", info = info)
    expect_match(text, knitr_rx, info = info)
    if (hidden || !has_sessioninfo) {
      expect_match(text, "attached base packages", fixed = TRUE, info = info)
      expect_no_match(text, "Session info", fixed = TRUE, info = info)
    } else {
      expect_match(text, "Session info", fixed = TRUE, info = info)
      expect_no_match(text, "attached base packages", fixed = TRUE, info = info)
    }
    for (home in homes) {
      expect_false(grepl(tolower(home), tolower(page), fixed = TRUE), info = paste(info, home, sep = ", home: "))
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

# Lines that set the home folder to `home`, and put `lib` first among the
# library folders that session_info() lists.
home_lines <- function(home, lib = NULL) {
  c(
    sprintf("Sys.setenv(HOME = %s)", deparse(home)),
    'Sys.unsetenv("USERPROFILE")',
    if (!is.null(lib)) sprintf(".libPaths(c(%s, .libPaths()))", deparse(lib))
  )
}

test_that("the environment section shows the home folder as ~", {
  skip_on_cran()
  skip_if_not_installed("sessioninfo")
  # A writable home folder with a library folder inside it. Quarto, which
  # session_info() runs for its version, writes a cache under the home
  # folder and prints an error that names it when it cannot.
  home <- normalizePath(withr::local_tempdir("home-"), winslash = "/")
  lib <- file.path(home, "lib")
  dir.create(lib)
  text <- run_session_code(home_lines(home, lib))
  expect_match(text, "[1] ~/lib", fixed = TRUE)
  expect_no_match(text, home, fixed = TRUE)
})

test_that("the environment section leaves a folder that only starts like the home folder", {
  skip_on_cran()
  skip_if_not_installed("sessioninfo")
  base <- normalizePath(withr::local_tempdir("homes-"), winslash = "/")
  dir.create(file.path(base, "al"))
  lib <- file.path(base, "alice", "lib")
  dir.create(lib, recursive = TRUE)
  text <- run_session_code(home_lines(file.path(base, "al"), lib))
  expect_match(text, lib, fixed = TRUE)
  expect_no_match(text, "~ice", fixed = TRUE)
})

test_that("the environment section shows a linked home folder as ~ by its real path", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_not_installed("sessioninfo")
  # The home folder is reached through a link, and its real path ends with
  # the linked path, as /tmp/h and /private/tmp/h do on macOS. A match of
  # the shorter spelling inside the real path would print /private~/lib.
  root <- normalizePath(withr::local_tempdir("homes-"), winslash = "/")
  real <- file.path(root, "real")
  lib <- file.path(real, root, "h", "lib")
  dir.create(lib, recursive = TRUE)
  skip_if_not(file.symlink(file.path(real, root, "h"), file.path(root, "h")), "cannot make a symbolic link here")
  text <- run_session_code(home_lines(file.path(root, "h"), lib))
  expect_match(text, "[1] ~/lib", fixed = TRUE)
  expect_no_match(text, real, fixed = TRUE)
  expect_no_match(text, "real~", fixed = TRUE)
})

test_that("the sessionInfo() output shows the home folder as ~", {
  skip_on_cran()
  # sessionInfo() prints the path of the LAPACK library, so a home folder
  # two levels above it shows there.
  lapack <- La_library()
  skip_if(!nzchar(lapack), "R gives no LAPACK path here")
  home <- dirname(dirname(normalizePath(lapack, winslash = "/")))
  text <- run_session_code(c(hide_sessioninfo, home_lines(home)))
  expect_match(text, "attached base packages", fixed = TRUE)
  expect_match(text, "LAPACK: ~/", fixed = TRUE)
  expect_no_match(text, home, fixed = TRUE)
})
