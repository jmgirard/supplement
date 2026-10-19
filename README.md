# supplement

supplement helps you share the supplemental materials of a research paper
as a website: analysis reports, code, and open data. Each report is a page
of one Quarto site, so every page has the site navigation. Quarto stores
each report's computed output in `_freeze/`, so the site rebuilds without
the data. GitHub Pages serves the site, and Zenodo's GitHub integration
can archive each GitHub release with a DOI.

The package is in early development.

## Start a new site

You need the [Quarto](https://quarto.org) command-line interface, and R
with the knitr and rmarkdown packages, to render the site. You can make
the site folder from R or from Quarto.

From R, install the package from GitHub with `pak::pak("jmgirard/supplement")`.
Then run:

```r
supplement::create_supplement("my-supplement", repo = "owner/name")
```

The first argument is the folder for the site. It can be a new folder or a
clone of a new GitHub repository. `repo` is the GitHub repository, which
the function writes into the site's GitHub links. You can leave it out and
edit the `OWNER` and `REPO` placeholders in `_quarto.yml` and `_README.md`
yourself. If the folder already holds a file that the template writes, the
function stops and writes nothing.

From Quarto, in a new, empty folder or in a clone of a new GitHub
repository, run:

```
quarto use template jmgirard/supplement/inst/template
```

Quarto asks whether to put the site in a new subdirectory. In a folder that
is not empty, such as a clone, the default answer is yes, so type `n`.
GitHub Pages serves `docs/` only at the top of the repository.

With either route, render the site once in its folder before your first
commit:

```
quarto render
```

The first render writes the template's rules into `.gitignore`. If
`.gitignore` already exists, the render adds the rules that it lacks. The
first render also writes the template's guide to `README.md`. If the folder
already has a `README.md`, the guide goes to `SUPPLEMENT.md` instead. If
both files exist, no guide is written. The template ships these files as `_gitignore` and `_README.md`, because
`quarto use template` does not copy those file names. The guide explains how
the site renders, how to render on the machine that holds private data, and
how to publish.

Put the paper title, citation, Zenodo DOIs, and data files in
`_supplement.yml`. The home page reads them from that file. The guide
lists the values and describes the shortcodes that show them.

## Add reports and data

In R, run these functions in the site folder:

```r
supplement::add_report("models", "Model Comparison", "Fits and compares the models.")
supplement::add_data("path/to/scores.csv", "Scores of each participant")
```

`add_report()` writes `analyses/models.qmd`, with the title and the
description in its front matter. It also adds a link to the report to the
Analyses menu in `_quarto.yml`. The home page lists each report in
`analyses/` with its title and description.

`add_data()` copies the file into `data/` and adds it to the `data` list
in `_supplement.yml`. If the file is directly in `data/`, the function does
not copy it. The data table on the home page lists each file in that list.
Every file in `data/` is published on the site.

Both functions add lines to these files as text, so the other lines and
the comments stay as they are. If a function cannot find the menu or the
list, it stops, writes nothing, and shows the lines to add by hand.

## Check a site before a release

In R, run this function in the site folder:

```r
supplement::check_supplement()
```

`check_supplement()` changes no file. It prints each problem that it finds
and returns the problems as a data frame, with one row per problem. It
finds:

- files larger than GitHub's limit of 100 MiB
- saved R objects, such as `.rds` files, that git tracks or does not ignore
- reports directly in `analyses/` with code and no stored output in
  `_freeze/`
- a site with no `docs/` folder
- quoted relative links in `docs/` to files that are not in `docs/`, or to
  folders there with no `index.html`
- pages in `docs/` that cannot be read
- DOIs in `CITATION.cff` or on the home page that differ from
  `_supplement.yml`, and a `CITATION.cff` that cannot be read

It checks only relative links, which point inside the site. It does not
check links that start with `/` and requests no web address. For the
file size and saved object checks, it reads the file list from git. When
git cannot run or the folder is not in a git work tree, it skips those two
checks and says so.

## Make a release

`_supplement.yml` holds the site version under `supplement:`, for example
`version: "1.0.0"`. A new site has `version: ""` until its first release.
`write_citation()` and `write_zenodo()` write the version to
`CITATION.cff` and `.zenodo.json`.

In R, run this function in the site folder:

```r
supplement::release_supplement("major")
```

`release_supplement()` takes `"patch"`, `"minor"`, `"major"`, or a version
such as `"1.0.0"`. A word raises that part of the version and sets the
parts after it to 0. An empty version counts as `0.0.0`, so `"major"`
gives `1.0.0`. A version must be greater than the current version.

If a value in `_supplement.yml` stops `write_citation()` or
`write_zenodo()`, the function also stops and changes no file. Its error
has the same class and message. Before it changes any file, the function runs `check_supplement()`. If
that finds a problem, or skips its git checks, the function stops and
changes no file. If `_supplement.yml`, `CITATION.cff`, or `.zenodo.json`
changes while the check runs, the function also stops and writes none of
these files. A DOI in
`CITATION.cff` that differs from `_supplement.yml` does not stop it,
because the release writes that file again. The function then changes the
version in `_supplement.yml` and writes `CITATION.cff` and `.zenodo.json`
again. Only the version line of `_supplement.yml` changes, so its comments
stay. If a write stops, the three files get their old text back.

Last, the function prints the commands that make the release, for example:

```sh
git status -- .
git add -A -- .
git commit -m "Release v1.0.0" -- .
git tag v1.0.0
git push
git push origin v1.0.0
gh release create v1.0.0 --generate-notes
```

It runs none of them. Read them, then run them yourself in the site
folder. The `-- .` makes the first three commands stage and commit only
files under the site folder, the files that `check_supplement()` checked.
If the site is in a subfolder of its repository, changes outside the site
stay out of the release commit. The last command needs the [GitHub command-line
tool](https://cli.github.com), `gh`. After Zenodo archives the release, add the
new version DOI to `_supplement.yml` and render the site again.

## License

MIT. See `LICENSE.md`.
