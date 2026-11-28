# RB01: Why M009's reviews keep returning (M009)

- **Date:** 2026-10-18
- **Output required:** write findings to `cairn/reviews/RR01-m009-review-returns.md`
- **Binding criteria:** not requested

You are performing an independent expert review. This brief is fully
self-contained — do not assume any conversation context. Read only what this
brief directs you to read, answer the numbered questions, and write your
findings to the output path above using the same numbering.

## Background

The repository at `/Users/jmgirard/github/supplement` is an R package,
`supplement`. It ships a Quarto website template for the supplemental
materials of a research paper, and R helpers for the site. The site's facts
live in `_supplement.yml` under a `supplement:` map. `write_citation()` and
`write_zenodo()` write `CITATION.cff` and `.zenodo.json` from that file.
`check_supplement()` lists problems before a release and changes no file.

Milestone M009 adds a `version` field to `_supplement.yml` and exports
`release_supplement(bump, path = ".")`. The function checks `bump` and the
current version, runs `check_supplement()`, changes only the value on the
`version:` line of `_supplement.yml`, writes `CITATION.cff` and
`.zenodo.json` again, and prints (never runs) the git and `gh` release
commands. If a step after the first write stops, it puts the files back.

The work is on branch `m009-release-supplement`. Its review has returned
the milestone for defects four times, and one re-plan came between the third
and fourth returns:

1. AC3: the release-check error gave no number of problems when only git
   checks were skipped.
2. AC5: a dangling-link `CITATION.cff` let the release create a file outside
   the site that a failed release did not remove, and a failure while
   printing was not rolled back.
3. AC2: `bump = "1.2.3\n"` was accepted, because the version pattern ended
   with `$` under `perl = TRUE`.
4. AC2 (after the re-plan): the code refuses the five values that AC2 names,
   but the test probes the `1.2.4` forms of those values instead of the
   `1.2.3` forms that AC2 lists.

Each review pass also found several smaller defects, which were fixed or
filed as candidate rows. The project's rules stop the work after the third
return, so the maintainer asked for this independent review before more work
is done. The question is why the returns keep coming, and what plan or
approach would let the milestone pass review without more rounds.

## Materials

Read these files on the branch (the working tree is on it):

- `cairn/milestones/M009-release-supplement.md`: Goal, Scope, the
  acceptance criteria AC1 to AC7, Coverage, the tasks T1 to T9, the work log
  (its `review return <n>:`, `question set:`, `criteria audit`, and
  `claim audit` lines), and the `## Review` section, which records four
  review passes with every finding and its disposition.
- `R/release-supplement.R`: the whole file (`release_supplement()`,
  `read_outputs()`, `check_bump()`, `next_version()`,
  `check_release_problems()`, `write_release_files()`, `report_release()`).
- `R/supplement-yml.R`: `value()`, `clean_space()`, `read_version()`,
  `is_version()`, `write_utf8()`, `path_occupied()`, `is_link()`.
- `R/yaml-insert.R`: `read_text_lines()`, `write_text_lines()`,
  `write_checked()`, `yaml_replace_lines()`, `yaml_replaced()`.
- `tests/testthat/test-release-supplement.R`: the whole file.
- `cairn/DECISIONS.md`: D-010 and D-011.
- `cairn/DESIGN.md`: Purpose & Scope and Architecture.
- `git log --oneline main..HEAD` and `git diff main..HEAD --stat` for the
  history of the branch.

To run the release tests:
`Rscript -e 'devtools::test("/Users/jmgirard/github/supplement", filter = "release-supplement")'`.
Use ref-based git only (`git diff`, `git log`, `git show`); do not check out,
reset, stash, or commit, and do not edit any file other than the output file.

## Questions

1. Classify each of the four defect returns by cause: (a) a criterion
   promise that is wider than any procedure in the plan can check, (b) a
   defect in the implementation's approach or design, (c) a test that does
   not test what its criterion says, or (d) something else. Give the
   evidence for each from the files above.
2. Read AC2, AC3, and AC5 exactly as written. For each, say whether its
   promise is bounded by a procedure that the plan names (a test list, a
   search, a stated rule), or whether it quantifies over an open domain (for
   example "any other `bump`" or "for any reason"). Where it is open, give
   concrete narrower wording that keeps what the user gets and that a test
   can settle.
3. Judge the restore design in `write_release_files()` and
   `read_outputs()`: snapshot the old bytes, write `_supplement.yml`, call
   `write_citation()` and `write_zenodo()`, print, and put back on any stop.
   Is it sound? Would another design remove whole classes of the findings,
   for example building all the new bytes in memory and checking every
   target before the first write, or writing to temporary files and then
   renaming them? Weigh the gain against the size of the change.
4. For the work still owed (AC2's five literal values in the test, and the
   pass-4 findings diff-bug #2 and #3 in the Review section), what is the
   smallest path to a review that passes? Choose among: fix and review
   again, narrow one or more criteria first, split the milestone, or another
   path. Say what the next review should check, so that it does not keep
   finding new edge cases outside the criteria.
5. List any defect in the current branch that you find and that the four
   review passes did not record, with a file:line and a failing input.

## Constraints

- D-010 and D-011 hold: a function that changes a site's YAML file edits its
  text and leaves the other lines as they are, and it reads the result with
  the yaml package before it writes.
- Calls to the GitHub or Zenodo API are out of scope (DESIGN Purpose &
  Scope). The function prints release commands and runs none of them; it
  starts no process itself (AC6).
- The maintainer decided at the question sets: keep printing `git add -A`
  (the subfolder fix stays in the "release from a subfolder" candidate row),
  and take none of the "release edge cases" row into M009.
- A dependency change, such as a higher testthat floor, needs the
  maintainer's approval.
- Flag any disagreement with a constraint explicitly, rather than working
  around it.

## Output format

In `RR01-m009-review-returns.md`: answer each question by number with your
reasoning and evidence; list any additional findings separately under
"Beyond the brief"; end with concrete recommendations, each marked apply /
consider / reject-with-reason. Your report is advisory: emit a
`## Binding criteria` section ONLY if this brief's header slot says
`requested`.
