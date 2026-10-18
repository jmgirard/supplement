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
with the knitr and rmarkdown packages. In a new, empty folder, run:

```
quarto use template jmgirard/supplement/inst/template
```

Then render the site once, before your first commit:

```
quarto render
```

The first render creates `README.md` and writes the template's rules into
`.gitignore`. If `.gitignore` already exists, the missing rules are added to
it. The template ships these files as `_gitignore` and `_README.md`, because
`quarto use template` does not copy those file names. The new `README.md` explains how the site
renders, how to render on the machine that holds private data, and how to
publish.

## License

MIT. See `LICENSE.md`.
