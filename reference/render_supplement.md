# Render the site from the R console

`render_supplement()` runs the Quarto commands that render a site, so
that you can render from the R console with no terminal. With no
`reports`, it renders the whole site, as `quarto render` does in a
terminal. With `reports`, it first renders each named report by name,
which runs its code again, and then renders the whole site. Use it after
you change a report: a full render alone reuses each report's stored
output in `_freeze/` and does not run the changed code.

## Usage

``` r
render_supplement(reports = NULL, path = ".")
```

## Arguments

- reports:

  `NULL` to render only the whole site, or the names of reports in
  `analyses/` to render by name first, without `.qmd`, as
  [`add_report()`](https://jmgirard.github.io/supplement/reference/add_report.md)
  takes them: `"models"` for `analyses/models.qmd`.

- path:

  The folder of the site.

## Value

The commands that the function ran, as a character vector, invisibly,
such as `c("quarto render analyses/models.qmd", "quarto render")`.

## Details

The function runs these commands in the site folder, in this order:

1.  `quarto render analyses/<name>.qmd` for each name in `reports`, in
    the order given. A name given twice is rendered once, at its first
    place.

2.  `quarto render`, which renders the whole site into `docs/`.

3.  `quarto render` once more, when a file in `figures/` is missing from
    `docs/figures/` after step 2. Quarto lists `figures/` when a render
    starts, so a figure that a report saves under a new name during the
    full render reaches `docs/` only with the next render. Files are
    compared by their path under each folder, hidden files included.
    When files are still missing after this render, the function prints
    their names and renders no more.

Quarto prints its output in the console as each command runs. The
function runs no git command. After it renders, commit the changed
reports with `_freeze/`, `docs/`, and `figures/`, and push.

## Which Quarto runs

The function runs the Quarto copy that
[`check_tools()`](https://jmgirard.github.io/supplement/reference/check_tools.md)
reports, by its full path: the copy on the system path, else the file
that the `QUARTO_PATH` environment variable names, else the copy that
RStudio or Positron installs. So it renders also when Quarto is not on
the system path that a terminal uses. A copy whose version cannot be
read is used. A copy older than 1.4.0 is refused. Quarto then runs the R
code of each report with its own R process.

## Errors

The function checks in this order and stops at the first problem. Before
step 1, no command has run. Each error has class `supplement_error` and
one of these classes:

- `supplement_error_argument`: `path` is not one non-empty string, or
  `reports` is not `NULL` or a character vector of length 1 or more with
  no `NA`.

- `supplement_error_report_name`: an entry of `reports` breaks the rule
  for the `name` of
  [`add_report()`](https://jmgirard.github.io/supplement/reference/add_report.md):
  ASCII letters, digits, `-`, and `_`, starting with a letter or a
  digit, and not a name that Windows reserves, such as `con`.

- `supplement_error_no_config`: `path` holds no `_quarto.yml` file.

- `supplement_error_no_report`: `analyses/<name>.qmd` is not a file for
  one or more entries of `reports`. The message names each one. A name
  must match its file's letter case, also on macOS and Windows, where
  the file system ignores case: `"Models"` does not match
  `analyses/models.qmd`.

- `supplement_error_no_quarto`: no Quarto copy was found.

- `supplement_error_quarto_version`: the Quarto copy is older than
  1.4.0.

- `supplement_error_render`: a command exited with a status other
  than 0. The message names the command. No later command runs, and the
  files that the earlier commands wrote stay.

The working folder of the R session is the same after the call as before
it, also after an error.

## See also

[`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md)
to check the rendered site, and
[`check_tools()`](https://jmgirard.github.io/supplement/reference/check_tools.md)
to see which Quarto copy is found.

## Examples

``` r
if (FALSE) { # \dontrun{
# In the folder of a site:
render_supplement()

# After you change analyses/models.qmd:
render_supplement("models")
} # }
```
