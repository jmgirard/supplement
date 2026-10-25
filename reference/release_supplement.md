# Raise the site version and print the release commands

`release_supplement()` prepares a release of a site. It runs
[`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md)
and stops when that finds a problem, or when one of the files that it
writes changes while the check runs. It then raises `version` in
`_supplement.yml`, writes `CITATION.cff` and `.zenodo.json` again with
the new version, and prints the git and GitHub commands that make the
release. It runs none of these commands, so you can read them first and
run them yourself in the site folder.

## Usage

``` r
release_supplement(bump, path = ".")
```

## Arguments

- bump:

  `"patch"`, `"minor"`, `"major"`, or a version such as `"1.0.0"`.

- path:

  The folder of the site.

## Value

The release commands as a character vector, invisibly.

## Details

`bump` is one of:

- `"patch"`, `"minor"`, or `"major"`: raise that part of the version by
  1 and set the parts after it to 0. `"minor"` makes `1.9.3` into
  `1.10.0`. An empty `version` counts as `0.0.0`, so `"major"` gives a
  first release `1.0.0`.

- A version such as `"1.0.0"`: three whole numbers joined by `.`, each
  `0` or without a leading zero. It must be greater than the current
  version, compared part by part as numbers, so `1.10.0` is greater than
  `1.9.0`.

The function stops, and changes no file, when
[`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md)
finds a problem or skips its git checks. A `"doi-mismatch"` problem for
`CITATION.cff` does not stop it, because the release writes that file
again. A change to `_supplement.yml`, `CITATION.cff`, or `.zenodo.json`
during the check also stops it, as described below.

Only the value on the `version:` line of `_supplement.yml` changes, so
its comments and the rest of its text stay as they are. The new value is
written in double quotes. The line must be a one-line `version:` value
directly under `supplement:`, as in the template. When it is missing,
add `version: ""` under `supplement:` by hand.

The function reads `_supplement.yml`, `CITATION.cff`, and `.zenodo.json`
before it runs
[`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md),
and reads them again after the check. When the bytes of one of these
files changed while the check ran, or one of them was made or removed as
a file, for example because you saved `_supplement.yml`, the function
stops and writes none of the three files, so you can run it again. A
change saved after the function reads the files again, until it
finishes, can still be lost.

Before it runs
[`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md),
the function makes the new text of `CITATION.cff` and `.zenodo.json`
from `_supplement.yml` with the new version. So a value that
[`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md)
or
[`write_zenodo()`](https://jmgirard.github.io/supplement/reference/write_zenodo.md)
refuses, such as an empty `citation`, stops the function with the class
and message of that function's error, before the check runs and before
any file is changed.

Before it changes any file, the function stops when `CITATION.cff` or
`.zenodo.json` is a link, because a write would go through the link, or
is a folder, or is a file that it cannot read or write. It also stops
when one of them does not exist and its folder cannot be written. It
looks for these when it reads the two files, before and after the check.
If writing `_supplement.yml`, `CITATION.cff`, or `.zenodo.json` stops,
for example when the disk is full, or is interrupted, the function puts
back the old text of each of these files that changed, removes each one
that it made, and stops. It prints the commands only after the three
files are written, so an error or an interrupt while it prints keeps the
files of the release.

The printed commands, for version `X.Y.Z`, are `git status -- .`,
`git add -A -- .`, `git commit -m "Release vX.Y.Z" -- .`,
`git tag vX.Y.Z`, `git push`, `git push origin vX.Y.Z`, and
`gh release create vX.Y.Z --generate-notes`. The `-- .` limits the first
three commands to the site folder: `git status` shows, and `git add` and
`git commit` stage and commit, only files under the site folder. These
are the files that the `"large-file"` and `"saved-object"` checks of
[`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md)
read, so `docs/`, `_freeze/`, and `figures/` reach the release when git
does not ignore them, as in the template. When the site is a subfolder
of its repository, a change outside the site folder, also one that was
staged before, stays out of the release commit. A file outside the site
folder that was staged before the release stays staged, so a later
`git commit` adds it. The last command needs the GitHub command-line
tool (`gh`). When Zenodo's GitHub integration is turned on for the
repository, Zenodo archives the release and gives it a version DOI. Add
that DOI to `zenodo.version-doi` in `_supplement.yml`, and render the
site again, so that the home page shows it.

## Errors

An error while the function prints the commands, after it wrote the
files, reaches you as it is. Otherwise the function stops with an error
of class `supplement_error` and one of these classes. When it stops with
one of these classes, no file is changed, unless a file that changed
cannot be put back. The `supplement_error_release_write` message then
names that file.

The function checks in this order, and stops at the first problem:
`bump` and `path`; `_supplement.yml` (no file, not UTF-8, not valid
YAML, no `supplement` map); the current version and `bump`; the
`version:` line; the values that the new `CITATION.cff` and
`.zenodo.json` hold; the two output files;
[`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md);
an output file that is now a link, a folder, or a file that cannot be
read or written, also when another file changed; a file that changed
during the check; the problems that
[`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md)
found; the writes.

- `supplement_error_argument`: `bump` is not one of the forms above, or
  `path` is not a single non-empty string.

- `supplement_error_no_metadata`, `supplement_error_no_map`: as for
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md).

- `supplement_error_encoding`: `_supplement.yml` is not UTF-8 text.

- `supplement_error_parse`: the yaml package cannot read
  `_supplement.yml`, as for
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md).

- The classes that
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md)
  lists for a value in `_supplement.yml`, such as
  `supplement_error_missing_field`, `supplement_error_license`,
  `supplement_error_orcid`, and `supplement_error_author_name`: a value
  that
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md)
  or
  [`write_zenodo()`](https://jmgirard.github.io/supplement/reference/write_zenodo.md)
  refuses. The error has the same class and message as theirs, names
  `release_supplement()`, and comes before
  [`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md)
  runs.

- `supplement_error_field_type`: `version` is a list, or YAML reads it
  as a number or as true/false, such as an unquoted `1.10`. Write it as
  one value in quotes, such as `"1.10.0"`. Another value of the kinds
  that
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md)
  names also gives this class.

- `supplement_error_doi`: a DOI in `_supplement.yml` is not a DOI, as
  for
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md).

- `supplement_error_version`: `version` is not empty and is not a
  version, or the version in `bump` is not greater than it.

- `supplement_error_no_version`: `_supplement.yml` has no one-line
  `version:` value directly under `supplement:`.

- `supplement_error_yaml`: the yaml package does not read the changed
  `_supplement.yml` as the old file with the new version.

- `supplement_error_changed`: `_supplement.yml`, `CITATION.cff`, or
  `.zenodo.json` changed while
  [`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md)
  ran. This error comes before a `supplement_error_release_check` error.
  When `CITATION.cff` or `.zenodo.json` is now a link, a folder, or a
  file that cannot be read or written, the
  `supplement_error_file_exists` or `supplement_error_write` error comes
  instead, also when another file changed.

- `supplement_error_release_check`:
  [`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md)
  found a problem other than a `"doi-mismatch"` problem for
  `CITATION.cff`, or it skipped its git checks.

- `supplement_error_file_exists`: `CITATION.cff` or `.zenodo.json` is a
  link or a folder.

- `supplement_error_write`: `CITATION.cff` or `.zenodo.json` cannot be
  read or written, or one of them does not exist and the site folder
  cannot be written.

- `supplement_error_release_write`: a write of `_supplement.yml`,
  `CITATION.cff`, or `.zenodo.json` stopped, and the files that changed
  got their old text back, and each file that the release made was
  removed. If a file cannot be put back, the message names it. The error
  of the step is the `parent` of this error.

## See also

[`check_supplement()`](https://jmgirard.github.io/supplement/reference/check_supplement.md)
for the checks, and
[`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md)
and
[`write_zenodo()`](https://jmgirard.github.io/supplement/reference/write_zenodo.md)
for the files that the release writes again.

## Examples

``` r
if (FALSE) { # \dontrun{
# In the folder of a rendered site in a git repository:
release_supplement("major")
} # }
```
