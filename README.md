# supplement

supplement helps you share the supplemental materials of a research paper
as a website: analysis reports, code, and open data. Each report is a page
of one Quarto site, so every page has the site navigation. Quarto stores
each report's computed output in `_freeze/`, so the site rebuilds without
the data. GitHub Pages serves the site, and Zenodo archives each GitHub
release with a DOI.

The package is in early development.

## Start a new site

You need the [Quarto](https://quarto.org) command-line interface, and R
with the knitr and rmarkdown packages. In a new, empty folder, run:

```
quarto use template jmgirard/supplement/inst/template
```

Then render the site once, before your first commit:

```
quarto render
```

The first render creates `.gitignore` and `README.md`. The template ships
them as `_gitignore` and `_README.md`, because `quarto use template` does
not copy those file names. The new `README.md` explains how the site
renders, how to render on the machine that holds private data, and how to
publish.

## License

MIT. See `LICENSE.md`.
