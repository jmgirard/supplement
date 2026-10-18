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

## License

MIT. See `LICENSE.md`.
