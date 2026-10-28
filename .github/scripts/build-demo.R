# Builds the demo for the package site: the site that create_supplement()
# makes, rendered once by Quarto with no edit between the two steps. The
# script copies the rendered docs/ folder into the folder that its argument
# names, which must not exist yet. It stops before any copy when Quarto is
# missing, the render fails, or the render writes no docs/index.html, so a
# broken demo fails the pkgdown build.
#
# Usage: Rscript build-demo.R <output folder>
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

site <- tempfile("demo-")
supplement::create_supplement(site, repo = "jmgirard/supplement")

old <- setwd(site)
status <- system2(quarto, "render")
setwd(old)
if (!identical(status, 0L)) {
  stop("quarto render exited with status ", status, ".", call. = FALSE)
}

docs <- file.path(site, "docs")
if (!file.exists(file.path(docs, "index.html"))) {
  stop("quarto render wrote no docs/index.html.", call. = FALSE)
}
dir.create(out, recursive = TRUE)
entries <- list.files(docs, all.files = TRUE, no.. = TRUE, full.names = TRUE)
copied <- file.copy(entries, out, recursive = TRUE, copy.date = TRUE)
if (!all(copied)) {
  stop("Could not copy ", paste(basename(entries[!copied]), collapse = ", "), " into ", out, ".",
       call. = FALSE)
}
cat("Wrote the demo site to ", out, "\n", sep = "")
