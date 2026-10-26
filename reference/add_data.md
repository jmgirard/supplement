# Add a data file to a supplement site

`add_data()` copies a file into the site's `data/` folder and adds it as
the last item of the `data` list in `_supplement.yml`. The data table on
the home page of a site made from the template lists each file in that
list, with its description, its size, and a download link.

## Usage

``` r
add_data(file, description, path = ".")
```

## Arguments

- file:

  The path of the data file. Its base name must be ASCII letters,
  digits, `.`, `-`, and `_`, with no two of the symbols in a row, no `.`
  at the start, and not `_` at both the start and the end. Quarto reads
  each value in `_supplement.yml` as Markdown, and these names stay as
  they are. The base name also cannot end in `.`, which Windows drops.
  Its part before the first `.` cannot be a name that Windows reserves
  for a device, in any letter case and with any extension: `CON`, `PRN`,
  `AUX`, `NUL`, `COM1` to `COM9`, or `LPT1` to `LPT9`. For example,
  `con.csv` and `NUL.tar.gz` are refused.

- description:

  A short description of the file for the data table.

- path:

  The folder of the site.

## Value

The path of the file in the site's `data/` folder, invisibly.

## Details

If `file` is directly in the site's `data/` folder, and not in a folder
inside it, the function copies nothing and only adds it to the list,
under its name on disk. Every file in `data/` is published on the site,
so add only data that you can share.

The function adds lines to `_supplement.yml` as text, so the other lines
of the file, its comments included, stay as they are. It finds the
`data` list under `supplement:` in block style, with each item on its
own line after a `-`. The description is written as a YAML string in
double quotes.

## Errors

The function writes and copies nothing when it stops. Its own errors
have the class `supplement_error` and one of these classes:

- `supplement_error_argument`: `path` is not a single non-empty string,
  `file` is not a single string, or `description` is not a single
  string.

- `supplement_error_no_file`: `file` does not exist or is a folder.

- `supplement_error_line_break`: `description` holds a line break.

- `supplement_error_file_name`: the base name of `file` does not follow
  the file-name rule above. It holds a character or a run of symbols
  that the rule refuses, starts with `.`, starts and ends with `_`, ends
  in `.`, or its part before the first `.` is a name that Windows
  reserves for a device, in any letter case and with any extension:
  `CON`, `PRN`, `AUX`, `NUL`, `COM1` to `COM9`, or `LPT1` to `LPT9`.

- `supplement_error_no_metadata`: `path` holds no `_supplement.yml`.

- `supplement_error_parse`: the yaml package cannot read
  `_supplement.yml`, as for
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md).

- `supplement_error_ignored_file`: `file` is of a type that the
  template's `.gitignore` rules keep out of git: a saved R object
  (`.rds`, `.rda`, `.RData`, `.qs`, or `.qs2`), or a `.rmarkdown`,
  `.quarto_ipynb`, `.knit.md`, or `.utf8.md` file, in any letter case. A
  new site gets its `.gitignore` at the first render.

- `supplement_error_file_exists`: `data/<base name>`, or a file in
  `data/` whose name differs from it only in letter case, exists and is
  not `file`, or is a link; or `data` is not a folder or is a link.

- `supplement_error_already_listed`: `data/<base name>` is already in
  the `data` list, in any letter case.

- `supplement_error_no_data_list`: `_supplement.yml` has no `data` list
  in block style under `supplement:`. An empty list written as
  `data: []` is not in block style. The error shows the lines to add by
  hand.

- `supplement_error_yaml`: the yaml package does not read the changed
  `_supplement.yml` as the old list with the new item added. The error
  shows the lines to add by hand.

- `supplement_error_encoding`: `description` or `_supplement.yml` is not
  UTF-8 text.

- `supplement_error_write`: the `data` folder could not be made, `file`
  could not be copied, or the write of `_supplement.yml` failed after
  the file was opened, for example on a full disk. Then
  `_supplement.yml` gets its old text back.

When `_supplement.yml` cannot be opened for writing, for example when it
is read-only, R's own error is shown. After any failed write, the
function removes the copy and any folder it made.

## See also

[`add_report()`](https://jmgirard.github.io/supplement/reference/add_report.md)
to add a report, and
[`create_supplement()`](https://jmgirard.github.io/supplement/reference/create_supplement.md)
to make a site.

## Examples

``` r
site <- file.path(tempdir(), "data-example")
create_supplement(site)
#> ✔ Made a supplement site in /tmp/RtmpjuQfnq/data-example.
#> ℹ Replace `OWNER/REPO` in _quarto.yml, and `OWNER` and `REPO` in the site
#>   address in _README.md, with your GitHub repository.
#> ℹ Put the paper facts in _supplement.yml.
#> ℹ Run `quarto render` in /tmp/RtmpjuQfnq/data-example once before your first
#>   commit.
scores <- file.path(tempdir(), "scores.csv")
write.csv(data.frame(id = 1:3, score = c(4, 7, 5)), scores, row.names = FALSE)
add_data(scores, "Scores of each participant", path = site)
#> ✔ Copied /tmp/RtmpjuQfnq/scores.csv to data/scores.csv and added it to the data
#>   list in _supplement.yml.
#> ℹ Every file in data/ is published on the site.
list.files(file.path(site, "data"))
#> [1] "example.csv" "scores.csv" 
unlink(c(site, scores), recursive = TRUE)
```
