# Supplemental Materials

Supplemental analysis reports, code, and data for: Author, A. A., &
Author, B. B. (Year). Title of the paper. *Journal Name*.

Website: https://OWNER.github.io/REPO/

## Contents

- `analyses/`: Quarto source files (`.qmd`), one per report
- `data/`: shared data files
- `_freeze/`: stored output of each report, so the site rebuilds without running report code
- `index.qmd`, `_quarto.yml`: website source
- `docs/`: rendered website, served by GitHub Pages

## How the site renders

The site uses Quarto's freeze option (`execute: freeze: true`). A full
render is `quarto render` with no file name. It uses the stored output in
`_freeze/`, so a report that already holds stored output runs no code. A
report with no stored output runs once, so it needs its data, its fit files,
and R.

A full render does not pick up changes to a report that already holds
stored output. A render by name, such as `quarto render
analyses/example.qmd`, always runs that report's code. Use it to re-run one
report after you change it. `quarto preview` also runs a report's code each
time you save its file.

After you delete or rename a report, run a full render. It clears `docs/`,
so the old page does not stay on the site.

Commit `_freeze/` and `docs/` with the source files.

## Setup scripts

Quarto runs two scripts in `_scripts/` on each render. They need no R.

- `setup.ts` runs before the render. On the first render it renames
  `_gitignore` to `.gitignore` and `_README.md` to `README.md`, because
  `quarto use template` does not copy those names. When `.gitignore` already
  exists, it adds the rules that it lacks. When `README.md` already exists,
  it writes this guide to `SUPPLEMENT.md` instead. If both files exist, it
  writes no guide.
- `nojekyll.ts` runs after the render and writes `docs/.nojekyll`, so that
  GitHub Pages serves the site as it is.

## Rendering on the machine with the private data

If a report needs private data or saved model fits, render it on the
machine that holds them. Keep fit files in `analyses/fits/`, which
`.gitignore` keeps out of git. A report runs from its own folder, so its
code reads them as `file.path("fits", ...)`.

1. Before a full render, check the `.rds` fit files of each report that
   has no stored output in `_freeze/` yet. Before a render by name, check
   that report's fit files. A missing fit file can make a report refit its
   model, which can take hours and give new estimates.
2. Run `quarto render`, or `quarto render analyses/<name>.qmd` to re-run
   one report.
3. Stage only `_freeze/` and `docs/`, commit, and push:

   ```
   git add _freeze docs
   git commit -m "Render reports"
   git push
   ```

Never publish a build that ran with the data deleted. It drops the data
files from `docs/`, so the download links break.

Share open data as CSV or another plain format in `data/`. `.gitignore`
blocks `.rds`, `.rda`, `.RData`, and `.qs` files everywhere, because saved
R objects such as fitted models can embed the data.

## Stable figures

Call `set.seed(` with a fixed number before each random draw, for example
before `pp_check()` or a bootstrap. Without a seed, every render that runs the
report's code redraws the figures. The numbers can stay the same while the
figures change.

## Publishing from one machine

Render and push the site from one machine. The theme file name in
`docs/site_libs/` is a hash of the compiled theme, which can differ between
machines, for example with another Quarto version. A render on a second
machine can then change every page.

## Site search

Every page is in the site search by default. To leave a page out of search,
add this to its front matter:

```yaml
search: false
```

## License

- Code (the `.qmd` files in `analyses/`, the scripts in `_scripts/`, and
  the website configuration): MIT, see `LICENSE.md`
- Content (rendered reports in `_freeze/` and `docs/`, website text, and
  data files): CC BY 4.0, see `LICENSE-CC-BY.md`. The third-party code that
  Quarto copies into `docs/site_libs/` keeps its own licenses.
