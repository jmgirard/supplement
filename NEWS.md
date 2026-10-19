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
  pages there that cannot be read. It finds DOIs that differ from
  `_supplement.yml`, and a `CITATION.cff` that cannot be read. It returns
  the problems as a data frame.
* `release_supplement()` prepares a release. An empty `citation` is one
  value that stops `write_citation()` or `write_zenodo()`. If
  `_supplement.yml` holds such a value, the release stops before
  `check_supplement()` runs, with an error of the same class and message. If
  `CITATION.cff` or `.zenodo.json` is a folder or a link, it also stops
  before `check_supplement()` runs. It then runs
  `check_supplement()`. When that finds a problem or skips its git checks,
  the function stops. If `_supplement.yml`, `CITATION.cff`, or
  `.zenodo.json` changes while the check runs, the function stops and
  writes none of these files. A file made or removed counts as a
  change. The
  change that you saved then stays in the file. A change saved after the
  function reads the files again can still be lost. A DOI in
  `CITATION.cff` that differs from `_supplement.yml` does not stop it. It then raises the version in
  `_supplement.yml` by `"patch"`, `"minor"`, or `"major"`, or sets a given
  greater version. It writes `CITATION.cff` and `.zenodo.json` again with
  the new version. It prints the git and GitHub commands that make the
  release, and runs none of them. If a write stops, the files get
  their old text back. The commands are printed after the files are
  written, so an error while printing keeps the files.
* `write_citation()` and `write_zenodo()` write `CITATION.cff` and
  `.zenodo.json` from `_supplement.yml`.
* The template's page footer shows the licenses in `license.code` and
  `license.content` of `_supplement.yml`, in place of a fixed MIT and
  CC BY 4.0. A new `supplement-license` shortcode shows a readable name
  for common ids, such as CC BY 4.0 for `CC-BY-4.0`, and any other id as
  written. Each name links to `https://spdx.org/licenses/<id>.html` in
  place of links to `LICENSE.md` and `LICENSE-CC-BY.md`. SPDX keeps that
  page only for ids on its license and exception lists. A license value that is
  not one SPDX id stops the render. Examples are `CC BY 4.0`, `GPL--3.0`,
  and a list. A call also stops the render unless it has one argument,
  `code` or `content`, and no named argument.
* The `supplement-doi` badge removes the prefixes in front of a DOI that
  `write_citation()` removes: `doi:`, and `http://` or `https://` with
  `doi.org/`, `dx.doi.org/`, or `www.doi.org/`. A DOI written as such a
  doi.org address no longer breaks the badge. A `zenodo.version-doi` or
  `zenodo.concept-doi` value that `write_citation()` refuses, such as
  `doi:` alone, stops the render.
* `write_citation()` stops with `supplement_error_license` for a
  `license.code` or `license.content` value that does not have the shape
  of an SPDX id. An id is letters and digits, with one `.` or `-` between
  groups and at most one `+` at the end. Examples of other values are
  `CC BY 4.0` with spaces and `GPL--3.0` with two hyphens in a row.
  `write_zenodo()` does the same for `license.content`, and the footer's
  `supplement-license` shortcode uses the same rule. When the two ids
  differ only in letter case, `CITATION.cff` holds one of them.
* The template's `_supplement.yml` has a `version` field for the site
  version, such as `"1.0.0"`. When it is not empty, `write_citation()`
  and `write_zenodo()` write it. They stop for a value that is not three
  whole numbers joined by `.`, or that has a leading zero.
* Authors in the template's `_supplement.yml` now have `family:` and
  `given:` in place of `name:`. Both functions stop with an error for an
  author without them.
* When a write fails, `create_supplement()`, `add_report()`, and
  `add_data()` remove only the files and folders that they made. Before,
  these functions read `[`, `*`, and `?` in a site path as a pattern. For
  a site path such as `site[ab]`, the cleanup then removed files in
  another folder, such as `sitea`, and kept its own.
