# supplement

supplement helps you share the supplemental materials of a research paper
as a website: analysis reports, code, and open data. Each report is a page
of one Quarto site, so every page has the site navigation. Quarto stores
each report's computed output in `_freeze/`. So once each report holds
stored output, the site rebuilds without the data. GitHub Pages serves the site, and Zenodo's GitHub integration
can archive each GitHub release with a DOI.

The package is in early development.

## Start a new site

The guide
[Publish a supplement site](https://github.com/jmgirard/supplement/blob/main/vignettes/publishing.Rmd)
is for your first site. It goes step by step from an empty folder to a site on GitHub Pages with a
Zenodo DOI. In R, `vignette("publishing", package = "supplement")` opens
it when the package was installed with its vignettes.

You need the [Quarto](https://quarto.org) command-line interface, and R
with the knitr and rmarkdown packages, to render the site. You can make
the site folder from R or from Quarto. In R, `supplement::check_tools()`
reports which of these tools are missing, too old, or not on the system
path. It also checks for git and the GitHub CLI (`gh`).

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
first render also writes `README.md`, a short page for the people who read
the site's repository. It keeps a `README.md` that the folder already has. The
template ships these files as `_gitignore` and `_README.md`, because
`quarto use template` does not copy those file names. The guide for the
site's authors is `GUIDE.md`. It explains how the site renders, how to
render on the machine that holds private data, and how to publish. It also
shows how to record R packages with renv and how to render reports in a
Docker container.

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
description in its front matter. The report ends with a "Computing
environment" section that shows the R and package versions of its last
render. The function also adds a link to the report to the Analyses menu
in `_quarto.yml`. The home page lists each report in
`analyses/` with its title and description.

`add_data()` copies the file into `data/` and adds it to the `data` list
in `_supplement.yml`. If the file is directly in `data/`, the function does
not copy it. The data table on the home page lists each file in that list.
Every file in `data/` is published on the site.

Both functions add lines to these files as text, so the other lines and
the comments stay as they are. If a function cannot find the menu or the
list, it stops, writes nothing, and shows the lines to add by hand.

## Record the R setup

To record the version of each R package that the reports use, so that
another machine can install the same versions, use the renv package. The
guide's "Recording R packages with renv" part shows the three commands.
supplement does not call renv.

In R, `supplement::write_dockerfile(quarto = "1.10.19")` in the site
folder reads `renv.lock` and writes a `Dockerfile` and a `.dockerignore`.
Docker builds an image from them. The image holds the R version and the R
packages in `renv.lock`, and Quarto. A report can render in it where Docker
runs Linux containers on amd64, or on arm64 for R 4.1.0 or later. The
guide's "Running reports in a container" part shows how to build the image
and render a report in it.

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
- files in `figures/`, `docs/`, and `_freeze/` that git ignores, which a
  release leaves out
- reports directly in `analyses/` with code and no stored output in
  `_freeze/`
- reports directly in `analyses/` whose stored output in `_freeze/` came
  from other text than the report holds now, or whose source hash cannot
  be read
- folders in `_freeze/analyses/` that no file or folder in `analyses/`
  names, as after a report is deleted or renamed
- a site with no `docs/` folder
- relative `href`, `src`, and `xlink:href` links in `docs/` to files that
  are not in `docs/`, or to folders there with no `index.html`
- symbolic links in `docs/` to existing files or folders outside `docs/`,
  and on Windows junctions to folders outside `docs/`
- pages in `docs/` that cannot be read
- figures in `figures/` whose copy in `docs/figures/` is missing or
  differs
- DOIs in `CITATION.cff` or on the home page that differ from
  `_supplement.yml`, and a `CITATION.cff` that cannot be read
- template placeholders left in place, such as the paper title in
  `_supplement.yml` or the unchanged example report
  (`?check_supplement` lists them all)

On pages, it checks only relative links, which point inside the site. It
does not check links that start with `/` and requests no web address. For the
file size, saved object, and ignored file checks, it reads the file list
from git. When git cannot run or the folder is not in a git work tree, it
skips those three checks and says so.

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
folder. With the `-- .`, `git status` shows only files under the site
folder, and `git add` and `git commit` stage and commit only these files.
These are the files that the file size and saved object checks of
`check_supplement()` read.
If the site is in a subfolder of its repository, changes outside the site
stay out of the release commit. A file outside the site that was staged
before the release stays staged, so a later `git commit` adds it. The last command needs the [GitHub command-line
tool](https://cli.github.com), `gh`. After Zenodo archives the release, add the
new version DOI to `_supplement.yml` and render the site again.

## License

MIT. See `LICENSE.md`.
