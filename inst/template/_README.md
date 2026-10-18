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
report with no stored output runs once.

A render by name, such as `quarto render analyses/example.qmd`, always runs
that report's code. Use it to re-run one report after you change it.

Commit `_freeze/` and `docs/` with the source files.

## Rendering on the machine with the private data

If a report needs private data or saved model fits, render it on the
machine that holds them.

1. Before a full render, check the `.rds` fit files. A missing fit file
   makes the report refit that model, which can take hours and gives new
   estimates.
2. Run `quarto render`.
3. Stage only `_freeze/` and `docs/`, commit, and push:

   ```
   git add _freeze docs
   git commit -m "Render reports"
   git push
   ```

Never publish a build that ran with the data deleted. It drops the data
files from `docs/`, so the download links break.

## Stable figures

Call `set.seed(` with a fixed number before each random draw, for example
before `pp_check()` or a bootstrap. Without a seed, every render redraws the
figures. The numbers can stay the same while the figures change.

## Publishing from one machine

Render and push the site from one machine. Quarto names the theme file in
`docs/site_libs/` differently on different machines, so a render on a
second machine changes every page.

## Site search

Every page is in the site search by default. To leave a page out of search,
add this to its front matter:

```yaml
search: false
```

## License

- Code (the `.qmd` files in `analyses/` and the website configuration):
  MIT, see `LICENSE.md`
- Content (rendered reports in `_freeze/` and `docs/`, website text, and
  data files): CC BY 4.0, see `LICENSE-CC-BY.md`
