# supplement 0.0.0.9000

* Initial package with a Quarto website template for supplemental
  materials in `inst/template/`.
* The template's home page reads the paper title, citation, and contact
  from `_supplement.yml`. A Quarto extension in the template adds three
  shortcodes: `supplement-doi` shows a Zenodo DOI badge,
  `supplement-download` links to the Zenodo archive, and
  `supplement-data-table` lists the data files with their sizes and
  download links. A data file that does not exist stops the render.
* `write_citation()` and `write_zenodo()` write `CITATION.cff` and
  `.zenodo.json` from `_supplement.yml`.
* Authors in the template's `_supplement.yml` now have `family:` and
  `given:` in place of `name:`. Both functions stop with an error for an
  author without them.
