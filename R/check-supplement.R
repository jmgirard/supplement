#' Check a supplement site before a release
#'
#' `check_supplement()` looks for problems that can break a release of a
#' site or publish files that must stay private. It changes no file. It
#' prints each problem it finds and returns all of them as a data frame.
#'
#' The checks, by the value in the `check` column:
#'
#' * `"large-file"`: a file larger than 100 MiB (104,857,600 bytes), which
#'   GitHub refuses. A symbolic link, or on Windows a junction, is not
#'   counted, because git stores only the link.
#' * `"saved-object"`: a saved R object (`.rds`, `.rda`, `.rdata`, `.qs`,
#'   or `.qs2`, in any letter case). A fitted model saved this way can hold
#'   the data it was fitted to.
#' * `"no-stored-output"`: a `.qmd` report directly in `analyses/`, not in
#'   a folder inside it, with an R, Python, or Julia code chunk and no
#'   stored output in `_freeze/`. A full render then runs its code, which
#'   needs the data.
#' * `"not-rendered"`: the site has no `docs/` folder.
#' * `"broken-link"`: a quoted `href` or `src` link on a page in `docs/` to
#'   a file that is not in `docs/`, or to a folder there with no
#'   `index.html`, or a link that ends with `/` to a file. A page that
#'   cannot be read, such as a link to a missing file, also counts. Links
#'   that start with `/`, `#`, or a scheme such as
#'   `https:` are not checked, and no web address is requested. GitHub
#'   Pages matches letter case, so a link whose case differs from the file
#'   name counts as broken, also on a disk that ignores case. A link that
#'   also differs from the name in Unicode form (for example `é` written
#'   as `e` plus an accent) is not caught.
#' * `"doi-mismatch"`: the DOI in `CITATION.cff` differs from the one that
#'   [write_citation()] writes from `_supplement.yml`, or the DOI badge on
#'   `docs/index.html` differs from `zenodo.version-doi` (or
#'   `zenodo.concept-doi` when that is empty). A home page whose source uses
#'   `{{< supplement-doi >}}` but that shows no badge, while
#'   `_supplement.yml` has a DOI, also counts. So does a `CITATION.cff`
#'   that cannot be read or is not a YAML map (a link to a missing file
#'   included), and a DOI in `CITATION.cff` or on the badge that is not a
#'   DOI.
#'
#' The first two checks look at the files that git tracks or does not
#' ignore, which `git ls-files --cached --others --exclude-standard` lists,
#' so files that `.gitignore` blocks are left out. For these two checks the
#' function runs git only to read: `git --version`, `git rev-parse
#' --is-inside-work-tree`, and `git ls-files`. When git is not on the PATH,
#' one of these commands fails, or the folder is not in a git work tree,
#' it skips these two checks and says so.
#'
#' @param path The folder of the site.
#'
#' @return A data frame with one row per problem and the character columns
#'   `check`, `file` (the path in the site), and `problem`, invisibly. It has
#'   zero rows when the function finds no problem. Its `skipped` attribute
#'   names the git checks (`"large-file"` and `"saved-object"`) that did not
#'   run, and is empty when they ran.
#'
#' @section Errors:
#' The function stops with an error of class `supplement_error` and one of
#' these classes:
#'
#' * `supplement_error_argument`: `path` is not a single non-empty string.
#' * `supplement_error_no_metadata`: `path` holds no `_supplement.yml`.
#' * `supplement_error_parse`: the yaml package cannot read
#'   `_supplement.yml`, as for [write_citation()].
#' * `supplement_error_no_map`: `_supplement.yml` has no `supplement:` map.
#' * `supplement_error_field_type`: a DOI in `_supplement.yml` is not one
#'   text value, or `zenodo` is not a map.
#' * `supplement_error_doi`: a DOI in `_supplement.yml` is not a DOI.
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
  path <- drop_trailing_sep(path)
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
  out <- git_out_file()
  # expand = FALSE, so that `[`, `*`, or `?` in the temporary folder's path
  # does not match another file.
  on.exit(unlink(out, expand = FALSE))
  owd <- setwd(dir)
  on.exit(setwd(owd), add = TRUE)
  status <- suppressWarnings(system2("git", args, stdout = out, stderr = FALSE))
  bytes <- if (file.exists(out)) readBin(out, "raw", file.size(out)) else raw()
  list(status = status, stdout = bytes)
}

# The temporary file that holds git's standard output.
git_out_file <- function() tempfile("git-")

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
    return(list(reason = "`git rev-parse` failed, or the folder is not in a git work tree"))
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

# Strings marked as UTF-8, with each byte that is not valid UTF-8 shown as
# <xx>.
show_text <- function(x) {
  Encoding(x) <- "UTF-8"
  bad <- !validUTF8(x)
  x[bad] <- iconv(x[bad], "UTF-8", "UTF-8", sub = "byte")
  x
}

# The text of a file as UTF-8, with NUL bytes dropped and bytes that are
# not valid UTF-8 shown as <xx>, or NULL when it cannot be read.
read_page_text <- function(file) {
  bytes <- tryCatch(readBin(file, "raw", file.size(file)), error = function(e) NULL,
                    warning = function(w) NULL)
  if (is.null(bytes)) {
    return(NULL)
  }
  show_text(rawToChar(bytes[bytes != as.raw(0)]))
}

# GitHub blocks files larger than 100 MiB:
# https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-large-files-on-github
github_file_limit <- 104857600

check_git_files <- function(path, files) {
  full <- file.path(path, files)
  # git can list a name that is not valid UTF-8 from its index, and on
  # Windows file.info() stops on such a name.
  readable <- .Platform$OS.type != "windows" | validUTF8(full)
  size <- rep(NA_real_, length(full))
  size[readable] <- file.info(full[readable], extra_cols = FALSE)$size
  large <- !is.na(size) & size > github_file_limit
  large[large] <- !is_link(full[large])
  # useBytes keeps a name that is not valid UTF-8 in the match.
  saved <- grepl("\\.(rds|rda|rdata|qs|qs2)$", files, ignore.case = TRUE, useBytes = TRUE)
  shown <- show_text(files)
  rbind(
    problem_rows(
      "large-file", shown[large],
      sprintf("%s bytes is more than GitHub's limit of 104,857,600 bytes (100 MiB) for one file.",
              format(size[large], big.mark = ",", scientific = FALSE, trim = TRUE))
    ),
    problem_rows(
      "saved-object", shown[saved],
      rep_len("A saved R object can hold the data. Remove it from git or add it to .gitignore.", sum(saved))
    )
  )
}

# Stored output ---------------------------------------------------------------

check_stored_output <- function(path) {
  # The files that the glob analyses/*.qmd matches in the site. A glob over
  # the whole path would read `[`, `*`, or `?` in the site's own path as a
  # pattern, so list the folder instead. Like a glob, `*` skips names that
  # start with a dot.
  dir <- file.path(path, "analyses")
  names <- list.files(dir, pattern = "\\.qmd$")
  reports <- file.path(dir, names[!startsWith(names, ".")])
  reports <- reports[!dir.exists(reports)]
  missing <- vapply(reports, function(report) {
    # A report that cannot be read, such as a link whose target is missing,
    # has no code that a render could run.
    lines <- tryCatch(readLines(report, warn = FALSE, encoding = "UTF-8"),
                      error = function(e) character(), warning = function(w) character())
    has_code <- any(grepl("^\\s*`{3,}\\{(r|python|julia)[\\s,}]", lines, perl = TRUE, useBytes = TRUE))
    name <- sub("\\.qmd$", "", basename(report))
    # Hidden files such as .DS_Store are not stored output.
    stored <- list.files(file.path(path, "_freeze", "analyses", name, "execute-results"),
                         recursive = TRUE)
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
    if (is.null(links)) {
      return(problem_rows(
        "broken-link", file.path("docs", page),
        "The page cannot be read, or it is a link to a missing file."
      ))
    }
    broken <- links[!vapply(links, link_ok, logical(1), docs = docs, page = page)]
    problem_rows(
      "broken-link", rep_len(file.path("docs", page), length(broken)),
      sprintf("The page links to a file that is not in the site: `%s`", broken)
    )
  })
  do.call(rbind, c(list(problem_rows()), rows))
}

# The quoted href and src values on a page that point to a place inside
# the site, each once, or NULL when the page cannot be read, such as a
# link whose target is missing.
page_links <- function(file) {
  html <- read_page_text(file)
  if (is.null(html)) {
    return(NULL)
  }
  attrs <- regmatches(html, gregexpr("\\b(href|src)\\s*=\\s*(\"[^\"]*\"|'[^']*')", html, perl = TRUE))[[1]]
  # (?s) lets `.` match a line break inside the quotes. A browser drops
  # tabs and line breaks from a link (the URL standard's parser does), so
  # they are dropped here too.
  values <- sub("(?s)^[^=]*=\\s*.(.*).$", "\\1", attrs, perl = TRUE)
  values <- gsub("[\t\n\r]", "", values)
  skip <- !nzchar(values) | grepl("^([A-Za-z][A-Za-z0-9+.-]*:|/|#)", values)
  unique(values[!skip])
}

# TRUE when a relative link on `page` (a path inside `docs`) reaches a file
# in `docs`, or a folder there with an index.html.
link_ok <- function(link, docs, page) {
  target <- sub("[?#].*$", "", link)
  if (!nzchar(target)) {
    return(TRUE)
  }
  # Split at `/` before decoding, so that `%2F` is not taken as a folder
  # separator. No file name can hold `/`, so such a link counts as broken.
  decoded <- vapply(strsplit(target, "/", fixed = TRUE)[[1]], percent_decode, character(1))
  if (anyNA(decoded) || any(grepl("/", decoded, fixed = TRUE))) {
    return(FALSE)
  }
  # A link that ends with `/` must reach a folder.
  wants_folder <- endsWith(target, "/")
  parts <- c(strsplit(dirname(page), "/", fixed = TRUE)[[1]], decoded)
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
  if (dir.exists(file.path(docs, paste(kept, collapse = "/")))) {
    kept <- c(kept, "index.html")
  } else if (wants_folder) {
    return(FALSE)
  }
  # GitHub Pages matches letter case, so each part must match the name on
  # disk, also on a disk that ignores case.
  dir <- docs
  for (part in kept) {
    if (!exact_name(dir, part)) {
      return(FALSE)
    }
    dir <- file.path(dir, part)
  }
  TRUE
}

# TRUE when `dir` holds `name`. On a disk that ignores letter case,
# file.exists() also finds `Name`, so a name that differs only in case
# from every entry of `dir` counts as missing. A name that differs in
# another way, such as Unicode normalization, is taken as found.
exact_name <- function(dir, name) {
  path <- file.path(dir, name)
  if (!file.exists(path)) {
    return(FALSE)
  }
  entries <- list.files(dir, all.files = TRUE, no.. = TRUE)
  name %in% entries || !(tolower(name) %in% tolower(entries))
}

# Decode %XX escapes, or return NA when the result holds a NUL byte or is
# not valid UTF-8. No file name holds a NUL byte, and a name that is not
# valid UTF-8 cannot match a file on a disk that needs UTF-8 names, such
# as macOS. On Linux such a link counts as broken even when the file
# exists.
percent_decode <- function(x) {
  if (!grepl("%[0-9A-Fa-f]{2}", x, useBytes = TRUE)) {
    return(x)
  }
  bytes <- charToRaw(x)
  out <- raw()
  i <- 1L
  while (i <= length(bytes)) {
    hex <- if (i + 2L <= length(bytes)) rawToChar(bytes[(i + 1L):(i + 2L)]) else ""
    # useBytes, because `hex` can hold half of a UTF-8 character.
    if (bytes[i] == charToRaw("%") && grepl("^[0-9A-Fa-f]{2}$", hex, useBytes = TRUE)) {
      out <- c(out, as.raw(strtoi(hex, 16L)))
      i <- i + 3L
    } else {
      out <- c(out, bytes[i])
      i <- i + 1L
    }
  }
  if (any(out == as.raw(0))) {
    return(NA_character_)
  }
  x <- rawToChar(out)
  Encoding(x) <- "UTF-8"
  if (!validUTF8(x)) NA_character_ else x
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
  # path_occupied() also finds a link whose target is missing.
  if (path_occupied(cff) && !dir.exists(cff)) {
    rows <- c(rows, list(check_cff_doi(cff, cite_doi)))
  }
  index <- file.path(path, "docs", "index.html")
  if (file.exists(index) && !dir.exists(index)) {
    rows <- c(rows, list(check_badge_doi(path, index, badge_doi)))
  }
  do.call(rbind, rows)
}

check_cff_doi <- function(cff, expected) {
  # read_page_text() returns NULL for a file that cannot be read, such as a
  # link to a missing file. Read every sequence as a list, as
  # read_supplement() does, so that `doi: [x]` is not one text value. A
  # warning, such as for a large number, does not make the file unreadable.
  text <- read_page_text(cff)
  doc <- if (!is.null(text)) {
    tryCatch(
      suppressWarnings(yaml::yaml.load(text, handlers = list(seq = function(x) as.list(x)))),
      error = function(e) NULL
    )
  }
  if (!is_map(doc)) {
    return(problem_rows(
      "doi-mismatch", "CITATION.cff",
      "It cannot be read, or it is not a YAML map. Run write_citation(overwrite = TRUE)."
    ))
  }
  doi <- doc[["doi"]]
  if (!is.null(doi) && (!is.character(doi) || length(doi) != 1)) {
    return(problem_rows("doi-mismatch", "CITATION.cff", "Its doi is not one text value."))
  }
  # As value() does for _supplement.yml, so that a block-scalar doi loses
  # its final line break.
  if (!is.null(doi)) {
    doi <- clean_space(doi)
    if (is.na(doi) || !nzchar(doi)) doi <- NULL
  }
  if (!is.null(doi)) {
    bare <- doi_or_null(doi)
    if (is.null(bare)) {
      return(problem_rows(
        "doi-mismatch", "CITATION.cff",
        sprintf("Its doi is not a DOI: %s. Run write_citation(overwrite = TRUE).", doi)
      ))
    }
    doi <- bare
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

check_badge_doi <- function(path, index, expected) {
  html <- read_page_text(index)
  if (is.null(html)) {
    return(problem_rows())
  }
  ids <- regmatches(html, gregexpr("https://zenodo\\.org/badge/DOI/([^\"'<>[:space:]]+?)\\.svg", html, perl = TRUE))[[1]]
  ids <- unique(sub("^https://zenodo\\.org/badge/DOI/(.*)\\.svg$", "\\1", ids))
  bare <- lapply(ids, doi_or_null)
  if (length(ids) == 0) {
    if (!is.null(expected) && uses_doi_shortcode(file.path(path, "index.qmd"))) {
      return(problem_rows(
        "doi-mismatch", "docs/index.html",
        sprintf("The home page shows no DOI badge, and _supplement.yml gives %s. Render the site again.", expected)
      ))
    }
    return(problem_rows())
  }
  # The DOIs in _supplement.yml passed bare_doi() already, so a badge that
  # is not a DOI comes from an old render or from HTML written by hand.
  invalid <- vapply(bare, is.null, logical(1))
  valid <- unlist(bare[!invalid])
  wrong <- unique(valid[!vapply(valid, same_doi, logical(1), expected = expected)])
  rbind(
    problem_rows(
      "doi-mismatch", rep_len("docs/index.html", sum(invalid)),
      sprintf("The DOI badge shows %s, which is not a DOI. Render the site again.", ids[invalid])
    ),
    problem_rows(
      "doi-mismatch", rep_len("docs/index.html", length(wrong)),
      sprintf("The DOI badge shows %s, and _supplement.yml gives %s. Render the site again.",
              wrong, expected %||% "none")
    )
  )
}

# The DOI from bare_doi(), or NULL when it is not a DOI, so that a bad DOI
# outside _supplement.yml gives a row and not an error.
doi_or_null <- function(doi) {
  tryCatch(bare_doi(doi, "doi"), supplement_error_doi = function(e) NULL)
}

same_doi <- function(doi, expected) {
  identical(tolower(doi %||% ""), tolower(expected %||% ""))
}

uses_doi_shortcode <- function(file) {
  if (!file.exists(file) || dir.exists(file)) {
    return(FALSE)
  }
  lines <- tryCatch(readLines(file, warn = FALSE, encoding = "UTF-8"),
                    error = function(e) character(), warning = function(w) character())
  any(grepl("\\{\\{<\\s*supplement-doi(\\s|>)", lines, perl = TRUE, useBytes = TRUE))
}
