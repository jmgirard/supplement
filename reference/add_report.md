# Add an analysis report to a supplement site

`add_report()` writes a new report file, `analyses/<name>.qmd`, and adds
a link to it as the last item of the Analyses menu in `_quarto.yml`. The
home page of a site made from the template lists every report in
`analyses/` with its title and description, so the new report shows
there too.

## Usage

``` r
add_report(name, title, description = "", path = ".")
```

## Arguments

- name:

  The file name of the report, without `.qmd`. It is ASCII letters,
  digits, `-`, and `_`, and starts with a letter or a digit. It cannot
  be a name that Windows reserves for a device, in any letter case:
  `CON`, `PRN`, `AUX`, `NUL`, `COM1` to `COM9`, or `LPT1` to `LPT9`.

- title:

  The title of the report. It shows in the Analyses menu and on the home
  page.

- description:

  A short description of the report for the home page. When it is `""`,
  the report has no `description`, and the home page shows the start of
  the report's text in its place.

- path:

  The folder of the site.

## Value

The path of the new report file, invisibly.

## Details

The first code chunk of the new report is the `site` chunk of the
template's example report, which sets `site` to the site folder. If
`QUARTO_PROJECT_DIR` is not empty, as in a render, `site` is its value.
Otherwise `site` is `"."` or `".."`, the first of the two that holds
`_quarto.yml`, and the chunk stops with an error if neither holds it.
The report's text says to read a data file as
`file.path(site, "data", "<file name>")`.

The new report ends with a "Computing environment" section, the same as
the template's example report. It prints the R and package versions of
the render, with
[`sessioninfo::session_info()`](https://sessioninfo.r-lib.org/reference/session_info.html)
when the sessioninfo package is installed and with
[`utils::sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html)
otherwise. It shows the home folder as `~`.

The function adds lines to `_quarto.yml` as text, so the other lines of
the file, its comments included, stay as they are. It finds the menu as
the item with `text: Analyses` under `website: navbar: left:` (or
`right:`), written in block style, with each item on its own line after
a `-`. The title and the description are written as YAML strings in
double quotes.

Quarto runs the new report the first time that the site renders, because
it has no stored output in `_freeze/` yet. To run it alone, render it by
name, for example `quarto render analyses/<name>.qmd`.

## Errors

The function writes nothing when it stops. Its own errors have the class
`supplement_error` and one of these classes:

- `supplement_error_argument`: `path` is not a single non-empty string,
  `title` is not a single string with a character other than white
  space, or `description` is not a single string.

- `supplement_error_report_name`: `name` is not a single string of ASCII
  letters, digits, `-`, and `_` that starts with a letter or a digit, or
  it is a name that Windows reserves for a device, in any letter case:
  `CON`, `PRN`, `AUX`, `NUL`, `COM1` to `COM9`, or `LPT1` to `LPT9`.

- `supplement_error_line_break`: `title` or `description` holds a line
  break.

- `supplement_error_no_config`: `path` holds no `_quarto.yml`.

- `supplement_error_parse`: the yaml package cannot read `_quarto.yml`.
  Examples are a `[` or a `{` that is not closed, a key line indented
  with a tab, and a key given twice in one map. The message names the
  file and gives the message of the yaml package.

- `supplement_error_file_exists`: the report file exists, or a file
  whose name differs from it only in letter case; `analyses` is not a
  folder or is a link; or `_freeze/analyses/<name>` exists, which holds
  the stored output of an earlier report of that name.

- `supplement_error_no_menu`: `_quarto.yml` has no Analyses menu in
  block style. The error shows the lines to add by hand.

- `supplement_error_yaml`: the yaml package does not read the changed
  `_quarto.yml` as the old menu with the new item added. The error shows
  the lines to add by hand.

- `supplement_error_encoding`: `title`, `description`, or `_quarto.yml`
  is not UTF-8 text.

- `supplement_error_write`: the `analyses` folder could not be made, or
  a write failed after its file was opened, for example on a full disk.
  A `_quarto.yml` whose write failed gets its old text back.

When a file cannot be opened for writing, for example a read-only
`_quarto.yml`, R's own error is shown. After any failed write, the
function removes the report file and any folder it made.

## See also

[`add_data()`](https://jmgirard.github.io/supplement/reference/add_data.md)
to add a data file, and
[`create_supplement()`](https://jmgirard.github.io/supplement/reference/create_supplement.md)
to make a site.

## Examples

``` r
site <- file.path(tempdir(), "report-example")
create_supplement(site)
#> ✔ Made a supplement site in /tmp/RtmpH7i6lB/report-example.
#> ℹ Replace `OWNER/REPO` in _quarto.yml, and `OWNER` and `REPO` in the site
#>   address in _README.md, with your GitHub repository.
#> ℹ Put the paper facts in _supplement.yml.
#> ℹ Run `quarto render` in /tmp/RtmpH7i6lB/report-example once before your first
#>   commit.
add_report("models", "Model Comparison", "Fits and compares the models.", path = site)
#> ✔ Wrote analyses/models.qmd and added it to the Analyses menu in _quarto.yml.
#> ℹ Run `quarto render analyses/models.qmd` in /tmp/RtmpH7i6lB/report-example to
#>   run the report.
cat(readLines(file.path(site, "analyses", "models.qmd")), sep = "\n")
#> ---
#> title: "Model Comparison"
#> description: "Fits and compares the models."
#> ---
#> 
#> Write the report here. The `site` chunk finds the site folder, so the
#> report reads a data file as `file.path(site, "data", "<file name>")`.
#> 
#> ```{r}
#> #| label: site
#> site <- Sys.getenv("QUARTO_PROJECT_DIR")
#> if (!nzchar(site)) {
#>   site <- Find(function(dir) file.exists(file.path(dir, "_quarto.yml")), c(".", ".."))
#> }
#> if (is.null(site)) {
#>   stop("Run this code from the site folder or from its analyses/ folder.")
#> }
#> ```
#> 
#> ```{r}
#> #| label: setup
#> set.seed(2026)
#> ```
#> 
#> ## Computing environment
#> 
#> This section shows the versions of R and of each package that the last
#> render of this report used. The site stores this output with the rest, so
#> the page keeps the versions that made its results. Your home folder shows
#> as `~`. Read the output before you publish it, because a folder outside
#> your home folder shows in full.
#> 
#> ::: {.callout-note collapse="true" title="R and package versions"}
#> ```{r}
#> #| label: session-info
#> #| cache: false
#> local({
#>   info <- if (requireNamespace("sessioninfo", quietly = TRUE)) {
#>     sessioninfo::session_info()
#>   } else {
#>     utils::sessionInfo()
#>   }
#>   # Each spelling of the home folder, longest first.
#>   windows <- .Platform$OS.type == "windows"
#>   homes <- Sys.getenv(c("USERPROFILE", "HOME"))
#>   homes <- c(homes, normalizePath(homes, winslash = "/", mustWork = FALSE))
#>   if (windows) homes <- c(homes, utils::shortPathName(homes))
#>   homes <- c(chartr("\\", "/", homes), chartr("/", "\\", homes))
#>   homes <- unique(sub("[/\\\\]+$", "", homes))
#>   homes <- homes[!grepl("^([A-Za-z]:)?$", homes)]
#>   homes <- homes[order(-nchar(homes))]
#>   # Show the home folder as ~ where a path starts with the whole folder.
#>   lines <- utils::capture.output(print(info))
#>   for (home in homes) {
#>     literal <- gsub("([][{}()|^$.*+?\\\\])", "\\\\\\1", home)
#>     pattern <- paste0("(?<!\\S)", literal, "(?=[/\\\\]|\\s|$)")
#>     lines <- gsub(pattern, "~", lines, perl = TRUE, ignore.case = windows)
#>   }
#>   writeLines(lines)
#> })
#> ```
#> :::
unlink(site, recursive = TRUE)
```
