#' Check a supplement site before a release
#'
#' `check_supplement()` looks for problems that can break a release of a
#' site or publish files that must stay private. It changes no file. It
#' prints each problem it finds and returns all of them as a data frame.
#'
#' The checks, by the value in the `check` column:
#'
#' * `"large-file"`: a file larger than 100 MiB (104,857,600 bytes), which
#'   GitHub refuses.
#' * `"saved-object"`: a saved R object (`.rds`, `.rda`, `.rdata`, `.qs`,
#'   or `.qs2`, in any letter case). A fitted model saved this way can hold
#'   the data it was fitted to.
#' * `"no-stored-output"`: a report in `analyses/` with an R, Python, or
#'   Julia code chunk and no stored output in `_freeze/`. A full render
#'   then runs its code, which needs the data.
#' * `"not-rendered"`: the site has no `docs/` folder.
#' * `"broken-link"`: a link on a page in `docs/` to a file or folder that
#'   is not in `docs/`. Only links inside the site are checked, and no web
#'   address is requested.
#' * `"doi-mismatch"`: the DOI in `CITATION.cff` differs from the one that
#'   [write_citation()] writes from `_supplement.yml`, or the DOI badge on
#'   `docs/index.html` differs from `zenodo.version-doi` (or
#'   `zenodo.concept-doi` when that is empty). A home page whose source uses
#'   `{{< supplement-doi >}}` but that shows no badge, while
#'   `_supplement.yml` has a DOI, also counts.
#'
#' The first two checks look at the files that git tracks or does not
#' ignore, which `git ls-files --cached --others --exclude-standard` lists, so files
#' that `.gitignore` blocks are left out. For these two checks the function
#' runs git, but only to read the file list. When git is not on the PATH,
#' cannot run, or the folder is not in a git repository, it skips these two
#' checks and says so.
#'
#' @param path The folder of the site.
#'
#' @return A data frame with one row per problem and the character columns
#'   `check`, `file` (the path in the site), and `problem`, invisibly. It has
#'   zero rows when the function finds no problem. Its `skipped` attribute
#'   names the checks that did not run.
#'
#' @section Errors:
#' The function stops with an error of class `supplement_error` and one of
#' these classes:
#'
#' * `supplement_error_argument`: `path` is not a single non-empty string.
#' * `supplement_error_no_metadata`: `path` holds no `_supplement.yml`.
#' * `supplement_error_doi`: a DOI in `_supplement.yml`, `CITATION.cff`, or
#'   the badge on `docs/index.html` is not a DOI.
#'
#' @seealso [write_citation()] to write `CITATION.cff` again.
#' @export
#' @examples
#' site <- file.path(tempdir(), "check-example")
#' create_supplement(site)
#' # A new site has not been rendered, and its example report has no
#' # stored output yet.
#' problems <- check_supplement(site)
#' problems$check
#' unlink(site, recursive = TRUE)
check_supplement <- function(path = ".") {
  check_path(path)
  path <- sub("(.)[/\\\\]+$", "\\1", path)
  meta <- read_supplement(path)

  git <- git_files(path)
  rows <- list(
    if (!is.null(git$files)) check_git_files(path, git$files),
    check_stored_output(path),
    check_links(path),
    check_dois(path, meta, call = environment())
  )
  rows <- Filter(Negate(is.null), rows)
  result <- if (length(rows) > 0) do.call(rbind, rows) else problem_rows()
  rownames(result) <- NULL
  attr(result, "skipped") <- if (is.null(git$files)) c("large-file", "saved-object") else character()

  report_problems(result, path, git$reason)
  invisible(result)
}

problem_rows <- function(check = character(), file = character(), problem = character()) {
  data.frame(
    check = rep_len(as.character(check), length(file)),
    file = as.character(file),
    problem = as.character(problem),
    stringsAsFactors = FALSE
  )
}

report_problems <- function(result, path, skip_reason) {
  if (!is.null(skip_reason)) {
    cli::cli_alert_info(
      "Skipped the {.val large-file} and {.val saved-object} checks: {skip_reason}."
    )
  }
  if (nrow(result) == 0) {
    cli::cli_alert_success("No problems found in {.path {path}}.")
    return(invisible())
  }
  cli::cli_alert_danger("{nrow(result)} problem{?s} found in {.path {path}}:")
  for (i in seq_len(nrow(result))) {
    check <- result$check[i]
    file <- result$file[i]
    problem <- result$problem[i]
    cli::cli_bullets(c("x" = "{.strong {check}} {.path {file}}: {problem}"))
  }
  invisible()
}

# Git -----------------------------------------------------------------------

# Run git in `dir` and return its exit status and its standard output as
# raw bytes, or NULL when git is not on the PATH. This is the one place
# where the package starts a process.
git_run <- function(args, dir) {
  if (!nzchar(Sys.which("git"))) {
    return(NULL)
  }
  out <- tempfile("git-")
  on.exit(unlink(out))
  owd <- setwd(dir)
  on.exit(setwd(owd), add = TRUE)
  status <- suppressWarnings(system2("git", args, stdout = out, stderr = FALSE))
  bytes <- if (file.exists(out)) readBin(out, "raw", file.size(out)) else raw()
  list(status = status, stdout = bytes)
}

# The files in `path` that git tracks or does not ignore, as paths relative to
# `path`, or NULL with the reason when git cannot list them.
git_files <- function(path) {
  version <- git_run("--version", path)
  if (is.null(version)) {
    return(list(reason = "git is not on the PATH"))
  }
  if (!identical(version$status, 0L)) {
    return(list(reason = "`git --version` failed"))
  }
  tree <- git_run(c("rev-parse", "--is-inside-work-tree"), path)
  if (!identical(tree$status, 0L) || !identical(trimws(rawToChar(tree$stdout)), "true")) {
    return(list(reason = "the folder is not in a git work tree"))
  }
  # -z prints each name as it is, ended by a NUL byte. Without it, git
  # quotes names with non-ASCII characters.
  listed <- git_run(c("ls-files", "-z", "--cached", "--others", "--exclude-standard"), path)
  if (!identical(listed$status, 0L)) {
    return(list(reason = "`git ls-files` failed"))
  }
  list(files = unique(split_nul(listed$stdout)))
}

# Split raw bytes at each NUL byte into UTF-8 strings.
split_nul <- function(bytes) {
  ends <- which(bytes == as.raw(0))
  if (length(ends) == 0) {
    return(character())
  }
  starts <- c(1L, ends[-length(ends)] + 1L)
  names <- vapply(seq_along(ends), function(i) {
    x <- rawToChar(bytes[seq.int(starts[i], length.out = ends[i] - starts[i])])
    Encoding(x) <- "UTF-8"
    x
  }, character(1))
  names[nzchar(names)]
}

# GitHub blocks files larger than 100 MiB:
# https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github
github_file_limit <- 104857600

check_git_files <- function(path, files) {
  full <- file.path(path, files)
  size <- file.info(full, extra_cols = FALSE)$size
  large <- !is.na(size) & size > github_file_limit & !is_link(full)
  saved <- grepl("\\.(rds|rda|rdata|qs|qs2)$", files, ignore.case = TRUE)
  rbind(
    problem_rows(
      "large-file", files[large],
      sprintf("%.0f MiB is more than GitHub's limit of 100 MiB for one file.", size[large] / 2^20)
    ),
    problem_rows(
      "saved-object", files[saved],
      rep_len("A saved R object can hold the data. Remove it from git or add it to .gitignore.", sum(saved))
    )
  )
}

# Stored output ---------------------------------------------------------------

check_stored_output <- function(path) {
  reports <- Sys.glob(file.path(path, "analyses", "*.qmd"))
  missing <- vapply(reports, function(report) {
    lines <- readLines(report, warn = FALSE, encoding = "UTF-8")
    has_code <- any(grepl("^\\s*`{3,}\\{(r|python|julia)[\\s,}]", lines, perl = TRUE, useBytes = TRUE))
    name <- sub("\\.qmd$", "", basename(report))
    stored <- list.files(file.path(path, "_freeze", "analyses", name, "execute-results"),
                         recursive = TRUE, all.files = TRUE)
    has_code && length(stored) == 0
  }, logical(1))
  files <- file.path("analyses", basename(reports[missing]))
  problem_rows(
    "no-stored-output", files,
    rep_len("The report has code and no stored output in _freeze/. Render it by name, then commit _freeze/.",
            length(files))
  )
}

# Links -----------------------------------------------------------------------

check_links <- function(path) {
  docs <- file.path(path, "docs")
  if (!dir.exists(docs)) {
    return(problem_rows("not-rendered", "docs", "The site has no docs/ folder. Render the site."))
  }
  pages <- list.files(docs, pattern = "\\.html$", recursive = TRUE)
  rows <- lapply(pages, function(page) {
    links <- page_links(file.path(docs, page))
    broken <- links[!vapply(links, link_ok, logical(1), docs = docs, page = page)]
    problem_rows(
      "broken-link", rep_len(file.path("docs", page), length(broken)),
      sprintf("The page links to a file that is not in the site: `%s`", broken)
    )
  })
  do.call(rbind, c(list(problem_rows()), rows))
}

# The quoted href and src values on a page that point to a place inside
# the site, each once.
page_links <- function(file) {
  html <- rawToChar(readBin(file, "raw", file.size(file)))
  attrs <- regmatches(html, gregexpr("\\b(href|src)\\s*=\\s*(\"[^\"]*\"|'[^']*')", html, perl = TRUE, useBytes = TRUE))[[1]]
  values <- sub("^[^=]*=\\s*.(.*).$", "\\1", attrs, perl = TRUE, useBytes = TRUE)
  skip <- !nzchar(values) | grepl("^([A-Za-z][A-Za-z0-9+.-]*:|/|#)", values, useBytes = TRUE)
  unique(values[!skip])
}

# TRUE when a relative link on `page` (a path inside `docs`) reaches a file
# in `docs`, or a folder there with an index.html.
link_ok <- function(link, docs, page) {
  target <- sub("[?#].*$", "", link)
  if (!nzchar(target)) {
    return(TRUE)
  }
  parts <- c(strsplit(dirname(page), "/", fixed = TRUE)[[1]],
             strsplit(percent_decode(target), "/", fixed = TRUE)[[1]])
  kept <- character()
  for (part in parts) {
    if (part %in% c("", ".")) next
    if (part == "..") {
      if (length(kept) == 0) {
        return(FALSE)
      }
      kept <- kept[-length(kept)]
    } else {
      kept <- c(kept, part)
    }
  }
  full <- do.call(file.path, as.list(c(docs, kept)))
  if (dir.exists(full)) file.exists(file.path(full, "index.html")) else file.exists(full)
}

percent_decode <- function(x) {
  if (!grepl("%[0-9A-Fa-f]{2}", x)) {
    return(x)
  }
  bytes <- charToRaw(x)
  out <- raw()
  i <- 1L
  while (i <= length(bytes)) {
    hex <- if (i + 2L <= length(bytes)) rawToChar(bytes[(i + 1L):(i + 2L)]) else ""
    if (bytes[i] == charToRaw("%") && grepl("^[0-9A-Fa-f]{2}$", hex)) {
      out <- c(out, as.raw(strtoi(hex, 16L)))
      i <- i + 3L
    } else {
      out <- c(out, bytes[i])
      i <- i + 1L
    }
  }
  x <- rawToChar(out)
  Encoding(x) <- "UTF-8"
  x
}

# DOIs ------------------------------------------------------------------------

check_dois <- function(path, meta, call = parent.frame()) {
  zenodo <- map_field(meta, "zenodo", call = call)
  yml <- lapply(c(version = "version-doi", concept = "concept-doi"), function(key) {
    field <- paste0("supplement.zenodo.", key)
    bare_doi(value(zenodo[[key]], field, call = call), field, call = call)
  })
  cite_doi <- yml$concept %||% yml$version
  badge_doi <- yml$version %||% yml$concept

  rows <- list(problem_rows())
  cff <- file.path(path, "CITATION.cff")
  if (file.exists(cff) && !dir.exists(cff)) {
    rows <- c(rows, list(check_cff_doi(cff, cite_doi, call)))
  }
  index <- file.path(path, "docs", "index.html")
  if (file.exists(index) && !dir.exists(index)) {
    rows <- c(rows, list(check_badge_doi(path, index, badge_doi, call)))
  }
  do.call(rbind, rows)
}

check_cff_doi <- function(cff, expected, call) {
  doi <- yaml::read_yaml(cff)[["doi"]]
  if (!is.null(doi) && (!is.character(doi) || length(doi) != 1)) {
    return(problem_rows("doi-mismatch", "CITATION.cff", "Its doi is not one text value."))
  }
  if (!is.null(doi)) {
    doi <- bare_doi(doi, "doi", file = "CITATION.cff", call = call)
  }
  if (same_doi(doi, expected)) {
    return(problem_rows())
  }
  problem_rows(
    "doi-mismatch", "CITATION.cff",
    sprintf("Its DOI is %s, and _supplement.yml gives %s. Run write_citation(overwrite = TRUE).",
            doi %||% "missing", expected %||% "none")
  )
}

check_badge_doi <- function(path, index, expected, call) {
  html <- rawToChar(readBin(index, "raw", file.size(index)))
  ids <- regmatches(html, gregexpr("https://zenodo\\.org/badge/DOI/([^\"'<>[:space:]]+?)\\.svg", html, perl = TRUE))[[1]]
  ids <- sub("^https://zenodo\\.org/badge/DOI/(.*)\\.svg$", "\\1", ids)
  ids <- vapply(ids, bare_doi, character(1), field = "DOI badge", file = "docs/index.html",
                call = call, USE.NAMES = FALSE)
  if (length(ids) == 0) {
    if (!is.null(expected) && uses_doi_shortcode(file.path(path, "index.qmd"))) {
      return(problem_rows(
        "doi-mismatch", "docs/index.html",
        sprintf("The home page shows no DOI badge, and _supplement.yml gives %s. Render the site again.", expected)
      ))
    }
    return(problem_rows())
  }
  wrong <- unique(ids[!vapply(ids, same_doi, logical(1), expected = expected)])
  problem_rows(
    "doi-mismatch", rep_len("docs/index.html", length(wrong)),
    sprintf("The DOI badge shows %s, and _supplement.yml gives %s. Render the site again.",
            wrong, expected %||% "none")
  )
}

same_doi <- function(doi, expected) {
  identical(tolower(doi %||% ""), tolower(expected %||% ""))
}

uses_doi_shortcode <- function(file) {
  if (!file.exists(file) || dir.exists(file)) {
    return(FALSE)
  }
  lines <- readLines(file, warn = FALSE, encoding = "UTF-8")
  any(grepl("\\{\\{<\\s*supplement-doi(\\s|>)", lines, perl = TRUE, useBytes = TRUE))
}
