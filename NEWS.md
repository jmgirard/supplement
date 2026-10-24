# supplement 0.0.0.9000

* The template's two project scripts are now Lua files, `_scripts/setup.lua`
  and `_scripts/nojekyll.lua`, that Quarto runs through Pandoc, so a render
  starts no Deno process for them. On macOS, Quarto's Deno sometimes
  crashed while it ran the old TypeScript scripts, and the render then
  failed. To switch a site made earlier, copy `setup.lua` and
  `nojekyll.lua` from
  `system.file("template", "_scripts", package = "supplement")` into its
  `_scripts/` folder. Change the `pre-render` and `post-render` lines of
  `_quarto.yml` to name them, and delete `setup.ts` and `nojekyll.ts`.
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
* `check_tools()` reports whether Quarto, knitr, rmarkdown, git, and gh
  are installed, and lists the GitHub and Zenodo accounts that a site
  needs. It finds Quarto on the system path, in `QUARTO_PATH`, or in the
  copy that RStudio or Positron installs. It reports a copy that is not
  on the system path or is older than Quarto 1.4.0. It runs none of
  the tools. `create_supplement()` names each tool that is missing, too
  old, or not on the system path in its closing message.
* The template's home page lists the reports in `analyses/` through a
  Quarto listing, with the title and the description from the front
  matter of each report, in place of a hand-written table.
* `add_report()` writes a new report file in `analyses/` and adds it to
  the Analyses menu in `_quarto.yml`. `add_data()` copies a data file into
  `data/` and adds it to the `data` list in `_supplement.yml`. Both
  functions add lines as text, so the comments in these files stay.
  Both refuse names that Windows reserves for a device, such as `con`, in
  any letter case. `add_data()` also refuses such a name with an
  extension, such as `con.csv`, and a file name that ends in `.`.
* The template guide has a part on recording a site's R packages with
  renv: `renv::init()`, `renv::snapshot()` after a render, and
  `renv::restore()` on another machine. In a site set up with renv, a full
  render from stored output still runs no R. `check_supplement()` finds
  no problem in the files that renv adds, and git keeps `renv/library/`
  out.
* `write_dockerfile()` reads the R and renv versions in `renv.lock` and
  writes a `Dockerfile` that builds an image with that R, the packages in
  `renv.lock`, and a given Quarto version. `renv.lock` must record R 4.0.0
  or later and renv 1.3.1 or later. It must not give `R`, `Packages`,
  `R.Version`, `Packages.renv`, or `Packages.renv.Version` twice in one
  object. It also writes a `.dockerignore` that lets only `renv.lock` of
  the site's files into the image. `digest` pins the base image.
  The template guide shows how to build the image and render a report in
  it.
* `check_supplement()` lists the problems in a site before a release, and
  changes no file. It finds files larger than 100 MiB, and saved R
  objects that git tracks or does not ignore. It finds reports with code
  and no stored output, and a missing `docs/` folder. A code chunk of any
  engine counts, such as `{bash}` or `{sql}`, but not `{ojs}`,
  `{mermaid}`, or `{dot}`. It counts in any letter case, with a space or
  tab before `{`, and inside a `>` block quote. If the report's front
  matter sets `engine: knitr`, inline R code also counts: `r` and a space,
  `r#`, or `{r}` and a space after the first backtick. From the source
  hash that Quarto stores, it finds reports whose stored output was made
  from other text than the report holds now. A change in a file that the
  report includes does not count. It also finds stored output whose hash
  cannot be read. If a hash cannot be read, the row names each such file.
  Otherwise it names each file whose hash differs. If another file's hash
  then matches the report, the row adds a hint. The hint says that the
  files that differ can be from a dropped format, such as `docx`. If so,
  the author deletes them, renders the whole site, and commits the report
  with `_freeze/`, `docs/`, and `figures/`. The row for a hash that cannot
  be read adds a delete step. If the row stays after the render steps,
  the author deletes the named files and renders the whole site. Then the
  author commits the report with `_freeze/`, `docs/`, and `figures/`. Each
  named file stands between double quotes, so a name that holds `, `
  reads as one file. It finds folders in
  `_freeze/analyses/` that no file or folder in `analyses/` names, as
  after a report is deleted or renamed.
  It also finds relative links in `docs/` to files that are not in
  `docs/`, and pages there that cannot be read. It finds files in `figures/`, `docs/`,
  and `_freeze/` that git ignores, which a release leaves out. It finds
  figures in `figures/` whose copy in `docs/figures/` is missing or
  differs. The rows for missing, old, or unreadable stored output and for
  such figures give the steps to render and commit the fix. The hint above
  and the row for unreadable stored output also give a delete step. The
  row for a report with no stored output
  also says: if you added the report to the Analyses menu, as
  `add_report()` does, commit `_quarto.yml` too. It
  finds DOIs that differ from `_supplement.yml`, and a `CITATION.cff`
  that cannot be read. It finds
  the template's placeholder values that the author did not replace. These
  are the paper title, citation, contact, and authors in
  `_supplement.yml`, `OWNER/REPO` in the GitHub link, and `OWNER` and
  `REPO` in the site address. They are also the "Before your first
  commit" box, the `YEAR AUTHORS` copyright lines, and the example report
  and data while they are unchanged. Each such row stops `release_supplement()`. It
  returns the problems as a data frame.
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
  release, and runs none of them. The printed `git status`, `git add`, and
  `git commit` commands end in `-- .`. So `git add` and `git commit` stage
  and commit only files under the site folder. This is also true for a site in a subfolder
  of its repository. If a write stops, the files get
  their old text back. The commands are printed after the files are
  written, so an error while printing keeps the files.
* `write_citation()` and `write_zenodo()` write `CITATION.cff` and
  `.zenodo.json` from `_supplement.yml`. Like `write_dockerfile()`, they
  refuse a link at the output path even with `overwrite = TRUE`, because
  a write follows the link. On Windows they also refuse a file link to a
  missing file, and so does `release_supplement()`. supplement now
  imports the fs package to find such a link there.
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
* A `_supplement.yml` or `_quarto.yml` that the yaml package cannot read
  now gives an error of class `supplement_error_parse`. Examples are a `[`
  or a `{` that is not closed and a key given twice. The message names the
  file and gives the message of the yaml package, and no file changes.
  `write_citation()`, `write_zenodo()`, `check_supplement()`,
  `release_supplement()`, and `add_data()` give it for `_supplement.yml`,
  and `add_report()` gives it for `_quarto.yml`. Before, the first four
  gave the yaml package's own error. `add_data()` and `add_report()` gave
  `supplement_error_yaml`, the class for a changed file that does not read
  back as planned. For a key line indented with a tab, `add_data()` gave
  `supplement_error_no_data_list`.
* The template publishes paper figures from a `figures/` folder, which git
  tracks. The template ships `figures/bootstrap-means.png`, so the first
  render of a new site publishes it. The example report saves it again on
  each render that runs its code. The example finds the site folder in a
  `site` chunk. If `QUARTO_PROJECT_DIR` is not empty, as in a render, the
  chunk uses it. Otherwise the chunk looks for `_quarto.yml` in the
  current folder first, then in the folder above it, and uses the first
  folder that holds it. If neither holds it, the chunk stops with a
  message. So the example also works with `execute-dir: project` and with
  its code run by hand from the site folder or from `analyses/`. A failed
  plot leaves no partial file in `figures/`. A PNG file that does not end
  with the PNG end chunk, such as one that a full disk cut short, also
  leaves none. When its code runs, the report stops with a message if a
  file named `figures` is in place of the folder. If `figures` is a link,
  or on Windows a junction, the report also stops. The site's README says
  how a report writes a figure to `figures/`. In new sites, git
  ignores `.png` and `.pdf` files saved directly in `analyses/` in any
  letter case.
* The template's example report and each report that `add_report()` writes
  end with a "Computing environment" section. It prints the R and package
  versions of the render. If the sessioninfo package is installed, it uses
  `sessioninfo::session_info()`. Otherwise it uses `utils::sessionInfo()`.
  It shows the home folder as `~`, and folders outside it in full. The
  stored output keeps the versions of each report's last render.
* In each report that `add_report()` writes, the first code chunk is the
  example report's `site` chunk, so the report finds the site folder by
  the same rule. Its text says to read a data file as
  `file.path(site, "data", "<file name>")`. Before, its text said to read
  data from `..`. That path is wrong for code run from the site folder.
  The site's README tells reports to read fit files as
  `file.path(site, "analyses", "fits", ...)`. In a site made before this
  change, copy the `site` chunk from a new site's `analyses/example.qmd`
  into each report.
* Fixes on Windows. `create_supplement()`, `add_report()`, and `add_data()`
  now stop with `supplement_error_file_exists` for a junction where the
  site needs a folder, as they already did on other systems for a link.
  Before, they wrote through the junction into the folder it points to. The data table shortcode
  shows the size of a data file of 2 GiB or more. Before, it showed
  "-1 B". When git lists a file name that is not valid UTF-8,
  `check_supplement()` no longer stops with an error.
* `check_supplement()` now reads links from start tags only. Before, it
  also read link-shaped text in comments, in `<script>` and `<style>`
  text, and in page text such as `<code>`. It also read attributes such
  as `data-href`, and it reported those as broken links. It now decodes
  character references such as `&amp;`, so a link to `R&D.csv` written as
  `R&amp;D.csv` is no longer reported. It reads `HREF` and other letter
  cases (also in `xlink:href`) and unquoted values, and it removes the
  spaces at the ends of a link. The help page lists the main cases that
  it still reads differently from a browser.
* `check_supplement()` now reads pages in hidden folders of `docs/` and
  hidden pages, such as `docs/.page.html`. It does not enter a linked
  folder. Before, a symbolic link in `docs/` to a folder there repeated
  the rows of each page in that folder. A link to `docs/` itself repeated
  them many times. A symbolic link in `docs/` to an existing file or
  folder outside `docs/` now gives a `broken-link` row. The published
  site does not have its target. On Windows, a junction in `docs/` to a
  folder outside `docs/` also gives that row. A link on a page that goes
  through such a link also gives a row.
* Package functions read YAML files without running `!expr` code, also
  when `options(yaml.eval.expr = TRUE)` is set. Such a value is read as
  the text of its R code.
* New guide, `vignette("publishing")`: the steps from an empty folder to a
  site on GitHub Pages with a Zenodo DOI. It also gives the rule for
  rendering again after a report changes: render the report by name,
  render the whole site, then commit the report with `_freeze/`, `docs/`,
  and `figures/`.
