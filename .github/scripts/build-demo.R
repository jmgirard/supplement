# Builds the demo for the package site: a filled-in site for a made-up
# diary study of sleep and next-day mood. The script starts from
# create_supplement() and then acts as an author. It adds the simulated data
# of .github/demo/simulate.R with add_data() and the reports in
# .github/demo/analyses/ with add_report(). It fills in _supplement.yml and
# the licenses, replaces the setup box with a note that the study is made up,
# removes the template's example report, data file, and figure, and writes
# CITATION.cff and .zenodo.json. It renders twice, because a figure saved
# under a new name reaches docs/ only on the next render. Then it runs
# check_supplement() and copies the rendered docs/ folder into the folder
# that its argument names, which must not exist yet.
#
# The script stops before it makes that folder when Quarto is missing, a
# render fails, the render writes no docs/index.html, check_supplement()
# finds a problem, or a template text that it edits is missing or occurs
# more than once. So a template change that breaks the demo fails the
# pkgdown build.
#
# Usage: Rscript .github/scripts/build-demo.R <output folder>
# It needs the supplement, knitr, and rmarkdown packages installed and
# Quarto on the PATH.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Name one output folder: Rscript build-demo.R <output folder>", call. = FALSE)
}
out <- args[[1]]
if (file.exists(out)) {
  stop(out, " already exists. Name a folder that does not exist yet.", call. = FALSE)
}
quarto <- Sys.which("quarto")
if (!nzchar(quarto)) {
  stop("quarto is not on the PATH.", call. = FALSE)
}

# The demo content is in .github/demo/, beside this script's folder.
script <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE))
demo <- file.path(dirname(dirname(normalizePath(script))), "demo")
source(file.path(demo, "simulate.R"), local = TRUE)

site <- tempfile("demo-")

# Replaces `old` in a site file with `new`. With `until`, the text replaced
# runs from `old` to the end of the first `until` after it. It stops unless
# `old` occurs exactly once, so the demo cannot drift from the template
# without notice.
replace_once <- function(file, old, new = "", until = NULL) {
  path <- file.path(site, file)
  text <- paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  starts <- gregexpr(old, text, fixed = TRUE)[[1]]
  count <- sum(starts > 0)
  if (count != 1) {
    stop(file, " holds ", count, " copies of this text, not 1:\n", old, call. = FALSE)
  }
  end <- starts + nchar(old) - 1
  if (!is.null(until)) {
    rest <- substring(text, end + 1)
    at <- regexpr(until, rest, fixed = TRUE)
    if (at < 0) {
      stop(file, " has no '", until, "' after this text:\n", old, call. = FALSE)
    }
    end <- end + at + nchar(until) - 1
  }
  text <- paste0(substring(text, 1, starts - 1), new, substring(text, end + 1))
  writeLines(enc2utf8(text), path, useBytes = TRUE)
}

remove_file <- function(file) {
  path <- file.path(site, file)
  if (!file.exists(path)) {
    stop(file, " is not in the new site.", call. = FALSE)
  }
  if (unlink(path) != 0 || file.exists(path)) {
    stop("Could not remove ", file, ".", call. = FALSE)
  }
}

render <- function() {
  old <- setwd(site)
  status <- system2(quarto, "render")
  setwd(old)
  if (!identical(status, 0L)) {
    stop("quarto render exited with status ", status, ".", call. = FALSE)
  }
}

supplement::create_supplement(site, repo = "jmgirard/supplement")

# Data files. The simulated files are written outside the site, and
# add_data() copies them in.
data_dir <- tempfile("demo-data-")
dir.create(data_dir)
data_files <- simulate_demo_data(data_dir)
supplement::add_data(data_files[[1]], "Age and chronotype of each participant (simulated)",
                     path = site)
supplement::add_data(data_files[[2]], "Nightly sleep and daily mood for each diary day (simulated)",
                     path = site)
unlink(data_dir, recursive = TRUE)

# Reports. Each body file holds an introduction and the analysis, split by
# an `<!-- analysis -->` line. They take the place of the stub's opening
# paragraph and its `setup` chunk, so the `site` chunk and the Computing
# environment section stay as add_report() wrote them.
reports <- list(
  sample = c("Sample Description",
             "Who took part, and how many diary days each person completed."),
  model = c("Main Analysis",
            "Within-person and between-person links of sleep with mood."),
  robustness = c("Robustness Checks",
                 "The within-person effect under other analysis choices.")
)
for (name in names(reports)) {
  supplement::add_report(name, reports[[name]][[1]], reports[[name]][[2]], path = site)
  body <- readLines(file.path(demo, "analyses", paste0(name, ".md")), encoding = "UTF-8")
  split <- which(body == "<!-- analysis -->")
  if (length(split) != 1) {
    stop(name, ".md needs one <!-- analysis --> line.", call. = FALSE)
  }
  report <- file.path("analyses", paste0(name, ".qmd"))
  replace_once(report, "Write the report here.", until = "\")`.",
               new = trimws(paste(body[seq_len(split - 1)], collapse = "\n")))
  replace_once(report, "```{r}\n#| label: setup\n", until = "```",
               new = trimws(paste(body[-seq_len(split)], collapse = "\n")))
}

# The template's example report, data file, and figure.
replace_once("_quarto.yml", "          - href: analyses/example.qmd\n            text: Example Analysis\n")
replace_once("_supplement.yml", "    - file: data/example.csv\n", until = "\n")
remove_file("analyses/example.qmd")
remove_file("data/example.csv")
remove_file("figures/bootstrap-means.png")

# Facts about the made-up paper. The DOI and the archive link are examples
# that lead to no Zenodo record.
replace_once("_supplement.yml", "  paper-title: ", until = "\n",
             '  paper-title: "Sleep Duration and Next-Day Mood: A 14-Day Diary Study"\n')
replace_once("_supplement.yml", "  citation: ", until = "\n", paste0(
  '  citation: "Rivera, M. L., & Chen, D. K. (2026). Sleep duration and next-day mood: ',
  'A 14-day diary study. *Journal of Example Studies*, *1*(1), 1-12."\n'
))
replace_once("_supplement.yml", '  version: ""', '  version: "1.0.0"')
replace_once("_supplement.yml", "  contact: ", until = "\n",
             '  contact: "M. L. Rivera, Department of Psychology, Example University. m.rivera@example.org"\n')
replace_once("_supplement.yml", "  authors:\n", until = "\n  # ", paste0(
  "  authors:\n",
  '    - family: "Rivera"\n',
  '      given: "M. L."\n',
  '      orcid: "0000-0002-1825-0097"\n',
  '      affiliation: "Example University"\n',
  '    - family: "Chen"\n',
  '      given: "D. K."\n',
  '      orcid: ""\n',
  '      affiliation: "Example University"\n',
  "  # "
))
replace_once("_supplement.yml", '    version-doi: ""', '    version-doi: "10.5281/zenodo.0000000"')
replace_once("_supplement.yml", '    archive-url: ""', '    archive-url: "https://zenodo.org/records/0000000"')
for (license in c("LICENSE.md", "LICENSE-CC-BY.md")) {
  replace_once(license, "Copyright (c) YEAR AUTHORS",
               "Copyright (c) 2026 M. L. Rivera and D. K. Chen")
}

# The home page: a note about the demo in place of the setup box, and no
# instruction under Archived Version.
replace_once("index.qmd", "::: {.callout-important}\n## Before your first commit\n", until = "\n:::", paste(
  "::: {.callout-note}",
  "## About this demo",
  "",
  "This site is a demo of the [supplement](https://jmgirard.github.io/supplement/)",
  "R package. The paper, its authors, its data, its DOI, and its archive link",
  "are made up for this demo. The data are simulated, and the DOI and the",
  "archive link lead to no Zenodo record. The package's",
  "[build script](https://github.com/jmgirard/supplement/blob/main/.github/scripts/build-demo.R)",
  "makes this site from the template.",
  ":::",
  sep = "\n"
))
replace_once("index.qmd", "archived on Zenodo. The DOI\nbadge", until = "`_supplement.yml`.",
             "archived on Zenodo.")

supplement::write_citation(site)
supplement::write_zenodo(site)

render()
render()
docs <- file.path(site, "docs")
if (!file.exists(file.path(docs, "index.html"))) {
  stop("quarto render wrote no docs/index.html.", call. = FALSE)
}

# The site is not a git repository, so the checks that read git skip.
problems <- supplement::check_supplement(site)
if (nrow(problems) > 0) {
  print(problems)
  stop("check_supplement() returned ", nrow(problems), " rows for the demo site.", call. = FALSE)
}
skipped <- attr(problems, "skipped")
if (!identical(sort(skipped), sort(c("large-file", "saved-object", "ignored-output")))) {
  stop("check_supplement() skipped other checks than expected: ",
       paste(skipped, collapse = ", "), ".", call. = FALSE)
}

if (!dir.create(out, recursive = TRUE)) {
  stop("Could not make ", out, ".", call. = FALSE)
}
entries <- list.files(docs, all.files = TRUE, no.. = TRUE, full.names = TRUE)
copied <- file.copy(entries, out, recursive = TRUE, copy.date = TRUE)
if (!all(copied)) {
  stop("Could not copy ", paste(basename(entries[!copied]), collapse = ", "), " into ", out, ".",
       call. = FALSE)
}
unlink(site, recursive = TRUE)
cat("Wrote the demo site to ", out, "\n", sep = "")
