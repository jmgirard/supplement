# Report the tools that a supplement site needs

`check_tools()` looks for the programs and R packages that rendering and
publishing a supplement site need, and prints one line for each. Run it
before your first render, or when a render fails because a tool is
missing.
[`create_supplement()`](https://jmgirard.github.io/supplement/reference/create_supplement.md)
runs the same lookups after it makes a site and names the tools that are
missing, too old, or not on the system path.

## Usage

``` r
check_tools()
```

## Value

A data frame with one row per tool and the character columns `tool`,
`status`, and `detail`, invisibly. `detail` gives the path of a program
that was found (with the version, for Quarto), the version of an R
package that was found, or what a missing tool or an account is for and
where to get it.

## Details

The function looks for these tools, in this order:

- `Quarto`: the Quarto command-line interface, which renders the site.

- `knitr` and `rmarkdown`: the R packages that Quarto uses to run the R
  code in reports. They are looked for in the libraries of the R session
  that runs `check_tools()`. Quarto can run another R installation, with
  other libraries.

- `git`: to commit the site and push it to GitHub.

- `gh`: the GitHub command-line interface, for the `gh release create`
  command that
  [`release_supplement()`](https://jmgirard.github.io/supplement/reference/release_supplement.md)
  prints.

It then lists two accounts that it cannot check:

- `GitHub account`: hosts the site with GitHub Pages.

- `Zenodo account`: archives each GitHub release with a DOI.

The function only looks for the tools. It runs none of them, and it
reads the Quarto version from a file.

## Statuses

Each row has one of these statuses:

- `found`: the tool is installed. For Quarto, the copy is on the system
  path that R sees, and its version is 1.4.0 or later or unknown.

- `not on path`: a copy of Quarto was found only in `QUARTO_PATH` or in
  an editor's folder, and its version is 1.4.0 or later or unknown. An
  older copy there is `too old`. The copy is not on the system path that
  R sees, so `quarto render` in a terminal can miss it. Add its `bin`
  folder to the system path, or install Quarto.

- `too old`: the Quarto version is below 1.4.0, the minimum that the
  template's Quarto extension states.

- `missing`: the tool was not found.

- `reminder`: one of the two accounts.

## Where Quarto is looked for

The function takes the first of these places that holds a file:

1.  The system path, as
    [`Sys.which()`](https://rdrr.io/r/base/Sys.which.html) searches it.

2.  The file that the `QUARTO_PATH` environment variable names.

3.  The copy that RStudio or Positron installs, in this order:

    - macOS:
      `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto`,
      then
      `/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto`.

    - Windows: `RStudio\resources\app\bin\quarto\bin\quarto.exe` in the
      folder that `PROGRAMFILES` names, then
      `Programs\Positron\resources\app\quarto\bin\quarto.exe` in the
      folder that `LOCALAPPDATA` names, then
      `Positron\resources\app\quarto\bin\quarto.exe` in the folder that
      `PROGRAMFILES` names.

    - Linux: `/usr/lib/rstudio/resources/app/bin/quarto/bin/quarto`,
      then `/usr/share/positron/resources/app/quarto/bin/quarto`.

For the copy that it takes, the function follows a link to the file,
then reads the version from `share/version` beside the copy's `bin`
folder, where Quarto installs keep it. If that file is missing or holds
no version number, the version is unknown, and the status stays `found`
or `not on path`.

## See also

[`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md)
to check a site before a release.

## Examples

``` r
check_tools()
#> ✔ Quarto: found. /usr/local/bin/quarto, version 1.10.19
#> ✔ knitr: found. version 1.52
#> ✔ rmarkdown: found. version 2.32
#> ✔ git: found. /usr/bin/git
#> ✔ gh: found. /usr/bin/gh
#> ℹ GitHub account: reminder. A GitHub account hosts the site with GitHub Pages:
#>   https://github.com/signup
#> ℹ Zenodo account: reminder. A Zenodo account archives each GitHub release with
#>   a DOI. Link it to GitHub and turn on the repository before the first release:
#>   https://zenodo.org
```
