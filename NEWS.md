# supplement 0.0.0.9000

* Initial package with a Quarto website template for supplemental
  materials in `inst/template/`.
* The template's home page reads the paper title, citation, and contact
  from `_supplement.yml`. A Quarto extension in the template adds three
  shortcodes: `supplement-doi` shows a Zenodo DOI badge,
  `supplement-download` links to the Zenodo archive, and
  `supplement-data-table` lists the data files with their sizes and
  download links. A data file that does not exist stops the render.
* `create_supplement()` makes a new site folder from the template without
  the Quarto command-line interface. With `repo = "owner/name"`, it also
  writes the GitHub repository into the site's links. If the folder already
  holds a file that the template writes, it stops and writes nothing.
* The template's home page lists the reports in `analyses/` through a
  Quarto listing, with the title and the description from the front
  matter of each report, in place of a hand-written table.
* `add_report()` writes a new report file in `analyses/` and adds it to
  the Analyses menu in `_quarto.yml`. `add_data()` copies a data file into
  `data/` and adds it to the `data` list in `_supplement.yml`. Both
  functions add lines as text, so the comments in these files stay.
* `check_supplement()` lists the problems in a site before a release, and
  changes no file. It finds files larger than 100 MiB, and saved R
  objects that git tracks or does not ignore. It finds reports with code
  and no stored output, and a missing `docs/` folder. It also finds
  quoted relative links in `docs/` to files that are not in `docs/`, and
  DOIs that differ from
  `_supplement.yml`. It returns the problems as a data frame.
* `write_citation()` and `write_zenodo()` write `CITATION.cff` and
  `.zenodo.json` from `_supplement.yml`.
* Authors in the template's `_supplement.yml` now have `family:` and
  `given:` in place of `name:`. Both functions stop with an error for an
  author without them.
