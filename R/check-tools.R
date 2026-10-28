#' Report the tools that a supplement site needs
#'
#' `check_tools()` looks for the programs and R packages that rendering and
#' publishing a supplement site need, and prints one line for each. Run it
#' before your first render, or when a render fails because a tool is
#' missing. [create_supplement()] runs the same lookups after it makes a
#' site and names the tools that are missing, too old, or not on the system
#' path.
#'
#' The function looks for these tools, in this order:
#'
#' * `Quarto`: the Quarto command-line interface, which renders the site.
#' * `knitr` and `rmarkdown`: the R packages that Quarto uses to run the R
#'   code in reports. They are looked for in the libraries of the R session
#'   that runs `check_tools()`. Quarto can run another R installation, with
#'   other libraries.
#' * `git`: to commit the site and push it to GitHub.
#' * `gh`: the GitHub command-line interface, for the
#'   `gh release create` command that [release_supplement()] prints.
#'
#' It then lists two accounts that it cannot check:
#'
#' * `GitHub account`: hosts the site with GitHub Pages.
#' * `Zenodo account`: archives each GitHub release with a DOI.
#'
#' The function only looks for the tools. It runs none of them, and it
#' reads the Quarto version from a file.
#'
#' @section Statuses:
#' Each row has one of these statuses:
#'
#' * `found`: the tool is installed. For Quarto, the copy is on the system
#'   path that R sees, and its version is 1.4.0 or later or unknown.
#' * `not on path`: a copy of Quarto was found only in `QUARTO_PATH` or in
#'   an editor's folder, and its version is 1.4.0 or later or unknown. An
#'   older copy there is `too old`. The copy is not on the system path that
#'   R sees, so `quarto render` in a terminal can miss it, while
#'   [render_supplement()] runs it. To render in a terminal, add its `bin`
#'   folder to the system path, or install Quarto.
#' * `too old`: the Quarto version is below 1.4.0, the minimum that the
#'   template's Quarto extension states.
#' * `missing`: the tool was not found.
#' * `reminder`: one of the two accounts.
#'
#' @section Where Quarto is looked for:
#' The function takes the first of these places that holds a file:
#'
#' 1. The system path, as [Sys.which()] searches it.
#' 2. The file that the `QUARTO_PATH` environment variable names.
#' 3. The copy that RStudio or Positron installs, in this order:
#'    * macOS: `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto`,
#'      then `/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto`.
#'    * Windows: `RStudio\resources\app\bin\quarto\bin\quarto.exe` in the
#'      folder that `PROGRAMFILES` names, then
#'      `Programs\Positron\resources\app\quarto\bin\quarto.exe` in the folder
#'      that `LOCALAPPDATA` names, then
#'      `Positron\resources\app\quarto\bin\quarto.exe` in the folder that
#'      `PROGRAMFILES` names.
#'    * Linux: `/usr/lib/rstudio/resources/app/bin/quarto/bin/quarto`, then
#'      `/usr/share/positron/resources/app/quarto/bin/quarto`.
#'
#' For the copy that it takes, the function follows a link to the file,
#' then reads the version from `share/version` beside the copy's `bin`
#' folder, where Quarto installs keep it. If that file is missing or holds
#' no version number, the version is unknown, and the status stays `found`
#' or `not on path`.
#'
#' @return A data frame with one row per tool and the character columns
#'   `tool`, `status`, and `detail`, invisibly. `detail` gives the path of
#'   a program that was found (with the version, for Quarto), the version
#'   of an R package that was found, or what a missing tool or an account
#'   is for and where to get it.
#'
#' @seealso [check_supplement()] to check a site before a release.
#' @export
#' @examples
#' check_tools()
check_tools <- function() {
  rows <- tool_rows()
  lines <- tool_lines(rows)
  for (i in seq_len(nrow(rows))) {
    line <- lines[i]
    mark <- switch(rows$status[i], found = "v", `not on path` = "!", reminder = "i", "x")
    bullet <- "{line}"
    names(bullet) <- mark
    cli::cli_bullets(bullet)
  }
  invisible(rows)
}

# One line of text per row, as check_tools() and create_supplement() print
# them.
tool_lines <- function(rows) {
  sprintf("%s: %s. %s", rows$tool, rows$status, rows$detail)
}

# The oldest Quarto that the template supports: the `quarto-required` value
# of inst/template/_extensions/supplement/_extension.yml.
quarto_minimum <- "1.4.0"

# The rows that check_tools() returns.
tool_rows <- function() {
  rows <- list(
    quarto_row(),
    package_row("knitr"),
    package_row("rmarkdown"),
    program_row("git", "Install git to commit the site and push it to GitHub: https://git-scm.com/downloads"),
    program_row("gh", "Install the GitHub CLI for the `gh release create` command that `release_supplement()` prints: https://cli.github.com"),
    c("GitHub account", "reminder", "A GitHub account hosts the site with GitHub Pages: https://github.com/signup"),
    c("Zenodo account", "reminder", "A Zenodo account archives each GitHub release with a DOI. Link it to GitHub and turn on the repository before the first release: https://zenodo.org")
  )
  data.frame(
    tool = vapply(rows, `[[`, "", 1L),
    status = vapply(rows, `[[`, "", 2L),
    detail = vapply(rows, `[[`, "", 3L),
    stringsAsFactors = FALSE
  )
}

program_row <- function(name, hint) {
  path <- tool_which(name)
  if (nzchar(path)) c(name, "found", path) else c(name, "missing", hint)
}

package_row <- function(pkg) {
  version <- package_version_text(pkg)
  if (nzchar(version)) {
    c(pkg, "found", paste("version", version))
  } else {
    c(pkg, "missing", sprintf('Run `install.packages("%s")` to render R reports.', pkg))
  }
}

quarto_row <- function() {
  copy <- find_quarto()
  if (is.null(copy)) {
    return(c("Quarto", "missing", "Install Quarto: https://quarto.org/docs/get-started/"))
  }
  version <- quarto_version(copy$path)
  status <- if (copy$place == "path") "found" else "not on path"
  detail <- paste0(copy$path, ", version ", if (is.null(version)) "unknown" else format(version))
  detail <- paste0(detail, switch(copy$place,
    QUARTO_PATH = ", from QUARTO_PATH",
    editor = ", in the RStudio or Positron install",
    ""
  ))
  if (!is.null(version) && version < quarto_minimum) {
    status <- "too old"
    detail <- paste0(detail, ". The template needs Quarto ", quarto_minimum, " or later")
  }
  if (copy$place != "path") {
    # render_supplement() refuses a copy that is too old.
    detail <- paste0(detail, ". `quarto render` in a terminal can miss this copy", if (status != "too old") ", but `render_supplement()` runs it")
  }
  c("Quarto", status, detail)
}

# The first Quarto copy, as a list of its path and its place ("path",
# "QUARTO_PATH", or "editor"), or NULL when there is none.
find_quarto <- function() {
  path <- tool_which("quarto")
  if (nzchar(path)) {
    return(list(path = path, place = "path"))
  }
  env <- tool_env("QUARTO_PATH")
  if (is_plain_file(env)) {
    return(list(path = env, place = "QUARTO_PATH"))
  }
  for (path in editor_quarto_paths()) {
    if (is_plain_file(path)) {
      return(list(path = path, place = "editor"))
    }
  }
  NULL
}

is_plain_file <- function(path) {
  nzchar(path) && file.exists(path) && !dir.exists(path)
}

# The Quarto copies that RStudio and Positron install on `os`, in the order
# that check_tools() tries them. A Windows path whose folder variable is
# unset is left out.
editor_quarto_paths <- function(os = tool_os()) {
  switch(os,
    mac = c(
      "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto",
      "/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto"
    ),
    linux = c(
      "/usr/lib/rstudio/resources/app/bin/quarto/bin/quarto",
      "/usr/share/positron/resources/app/quarto/bin/quarto"
    ),
    windows = {
      programs <- tool_env("PROGRAMFILES")
      local <- tool_env("LOCALAPPDATA")
      c(
        if (nzchar(programs)) file.path(programs, "RStudio", "resources", "app", "bin", "quarto", "bin", "quarto.exe"),
        if (nzchar(local)) file.path(local, "Programs", "Positron", "resources", "app", "quarto", "bin", "quarto.exe"),
        if (nzchar(programs)) file.path(programs, "Positron", "resources", "app", "quarto", "bin", "quarto.exe")
      )
    }
  )
}

# The version in `share/version` beside the `bin` folder of the Quarto
# program at `path`, after a link to the program is followed, or NULL when
# that file is missing or holds no version number.
quarto_version <- function(path) {
  program <- normalizePath(path, winslash = "/", mustWork = FALSE)
  file <- file.path(dirname(dirname(program)), "share", "version")
  if (!is_plain_file(file)) {
    return(NULL)
  }
  # readBin(), so that a file with no final line break gives no warning.
  bytes <- tryCatch(readBin(file, "raw", 64L), error = function(e) raw())
  end <- match(as.raw(10L), bytes, nomatch = length(bytes) + 1L)
  line <- bytes[seq_len(end - 1L)]
  # A version is ASCII digits and dots, so check the bytes before they
  # become text: other bytes can be invalid in the locale, and trimws()
  # then stops with an error and grepl() warns.
  if (!all(line %in% as.raw(c(9L, 13L, 32L, 46L, 48:57)))) {
    return(NULL)
  }
  text <- trimws(rawToChar(line))
  if (!grepl("^[0-9]+(\\.[0-9]+)+$", text)) {
    return(NULL)
  }
  # A part too big for an R integer makes numeric_version() warn and give
  # an NA part, so such a file holds no version either.
  tryCatch(numeric_version(text), warning = function(w) NULL)
}

# The lookups, kept apart so that tests can mock them.
tool_which <- function(name) unname(Sys.which(name))

tool_env <- function(name) Sys.getenv(name)

tool_os <- function() {
  if (.Platform$OS.type == "windows") {
    "windows"
  } else if (Sys.info()[["sysname"]] == "Darwin") {
    "mac"
  } else {
    "linux"
  }
}

# The version of the installed package `pkg`, or "" when it is not
# installed. It reads the DESCRIPTION file and does not load the package.
package_version_text <- function(pkg) {
  dir <- system.file(package = pkg)
  if (!nzchar(dir)) {
    return("")
  }
  version <- tryCatch(
    read.dcf(file.path(dir, "DESCRIPTION"), fields = "Version")[1, 1],
    error = function(e) NA_character_
  )
  if (is.na(version)) "" else version
}
