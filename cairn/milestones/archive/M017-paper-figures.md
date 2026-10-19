# M017: The template publishes paper figures from a figures folder

**Status:** done (2026-10-19, PR #18 https://github.com/jmgirard/supplement/pull/18)

**Goal:** A site made from the template has a `figures/` folder that git tracks and the site publishes, and the example report shows how a report saves a figure there.

**Outcome:** `inst/template/_quarto.yml` lists `"figures/**"` in `project.resources`, with a comment to render again after a new figure name. `analyses/example.qmd` has a "Paper Figures" section whose `save-figure` chunk runs `dir.create()` and writes `../figures/bootstrap-means.png` with `png()`. The template ships no `figures/` folder, and the `analyses/*.png` and `analyses/*.pdf` ignore rules stay. The site README has a "Paper figures" section (save in `figures/` with `file.path("..", "figures", ...)` and `dir.create()`, render again after a new name, every file there is published, delete and run a full render to take one off, commit it, its web address, and the lower-case-only rules on Linux), a Contents line, and `figures` in both commit steps. `LICENSE-CC-BY.md`, the README License section, and the `release_supplement()` help name `figures/`. Two tests in `tests/testthat/test-template.R` check the ignore rules and that a render by name then a full render give a PNG in `figures/` and `docs/figures/`. NEWS.md and DESIGN.md describe it.

**Decisions:** none. AC3 was amended at a user stop: Quarto 1.10.19 lists `figures/` at the start of a render and copies after the report code runs, so a changed figure is copied in the same render and a new name on the next render of either kind.

**Review:** claim audit 19 claims, 0 corrected. One review pass, four lenses: 21 findings, 10 fixed (README example, publish and removal notes, private-data step, Linux case note, license lists, release help, DESIGN timing), 7 to the new row "figures folder edge cases", 4 rejected (planned change or false). One amendment (AC3). `R CMD check` 0/0/0; the repo has no CI. Graduated "paper figure files".
