# Make a new supplement site from the template

`create_supplement()` copies the package's Quarto website template into
`path`. It is an R route in place of
`quarto use template jmgirard/supplement/inst/template`: it copies the
template that is installed with the package, and it needs no Quarto
command-line interface and no network.

## Usage

``` r
create_supplement(path, repo = NULL)
```

## Arguments

- path:

  The folder for the site. It is made if it does not exist.

- repo:

  The GitHub repository of the site, as `"owner/name"`, or `NULL`. When
  given, it replaces each `OWNER/REPO` placeholder in `_quarto.yml`, and
  the GitHub Pages address in `_README.md` and `GUIDE.md` becomes
  `https://<owner>.github.io/<name>/` with the owner in lowercase. For a
  repository named `<owner>.github.io`, the address is
  `https://<owner>.github.io/`. When `NULL`, the placeholders stay for
  you to edit.

## Value

`path`, invisibly.

## Details

`path` can be a new folder or an existing one, such as a clone of a new
GitHub repository. The function never replaces a file and never follows
a link: if `path` already holds a file, a folder, or a link where the
template writes a file, or a file or a link where the template needs a
folder, it stops before it writes anything.

The template ships `_gitignore` and `_README.md` under those names,
because `quarto use template` does not copy `.gitignore` or `README.md`.
The first `quarto render` gives them their real names, and that render
adds the template's rules that an existing `.gitignore` lacks and ends
it with `!docs/` and `!_freeze/`. These two lines cannot undo a rule
such as `docs/*` or `*.html`. `_README.md` is the page for the site's
readers. If `README.md` exists, the render keeps it and removes
`_README.md`. The guide for the site's authors is `GUIDE.md`. Render the
site once before your first commit.

After it makes the site, the function runs the lookups of
[`check_tools()`](https://jmgirard.github.io/supplement/reference/check_tools.md).
Its closing message names each tool that is missing, too old, or not on
the system path. A tool never stops the function, and the site is the
same whether the tools are found or not.

Hidden files and folders in the template folder are not copied, and
neither are `docs`, `_freeze`, or `_site` folders at its top level,
which hold render output.

## Errors

The errors that the function raises itself have the class
`supplement_error` and one of these classes:

- `supplement_error_argument`: `path` is not a single non-missing,
  non-empty character string.

- `supplement_error_repo`: `repo` is not `NULL` or a single string of
  the form `owner/name`. The owner must be 1 to 39 ASCII letters and
  digits, with single `-` between them. The name must be 1 to 100 ASCII
  letters, digits, `-`, `_`, and `.`, and must not be `.` or `..`.

- `supplement_error_not_folder`: `path` is an existing file, or a link
  whose target is missing. A `/` at the end of `path` does not change
  this.

- `supplement_error_file_exists`: `path` holds a file, a folder, or a
  link where the template writes a file, or a file or a link where the
  template needs a folder.

- `supplement_error_write`: a folder could not be made, a file could not
  be copied, or the repository could not be written into a copied file,
  for example because a parent of `path` is a file. The function then
  removes the files and folders that it made.

## See also

[`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md)
and
[`write_zenodo()`](https://jmgirard.github.io/supplement/reference/write_zenodo.md)
for the citation files.

## Examples

``` r
site <- file.path(tempdir(), "my-supplement")
create_supplement(site, repo = "jdoe/my-supplement")
#> ✔ Made a supplement site in /tmp/RtmpW1XhVZ/my-supplement.
#> ℹ Put the paper facts in _supplement.yml.
#> ℹ Run `quarto render` in /tmp/RtmpW1XhVZ/my-supplement once before your first
#>   commit.
list.files(site, recursive = TRUE)
#>  [1] "GUIDE.md"                             
#>  [2] "LICENSE-CC-BY.md"                     
#>  [3] "LICENSE.md"                           
#>  [4] "_README.md"                           
#>  [5] "_extensions/supplement/_extension.yml"
#>  [6] "_extensions/supplement/supplement.lua"
#>  [7] "_gitignore"                           
#>  [8] "_quarto.yml"                          
#>  [9] "_scripts/nojekyll.lua"                
#> [10] "_scripts/report.R"                    
#> [11] "_scripts/setup.lua"                   
#> [12] "_supplement.yml"                      
#> [13] "analyses/example.qmd"                 
#> [14] "data/example.csv"                     
#> [15] "figures/bootstrap-means.png"          
#> [16] "index.qmd"                            
unlink(site, recursive = TRUE)
```
