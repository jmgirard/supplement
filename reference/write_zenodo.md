# Write .zenodo.json from \_supplement.yml

`write_zenodo()` reads `_supplement.yml` in `path` and writes a
`.zenodo.json` file into the same folder. When Zenodo's GitHub
integration archives a release, it reads this file for the record's
metadata. When a repository has both `.zenodo.json` and `CITATION.cff`,
Zenodo uses `.zenodo.json`.

## Usage

``` r
write_zenodo(path = ".", overwrite = FALSE)
```

## Arguments

- path:

  The folder that holds `_supplement.yml`.

- overwrite:

  If `TRUE`, replace an existing file.

## Value

The path of the written file, invisibly.

## Details

The file holds:

- `title`: "Supplemental materials for: " and `paper-title`.

- `version`: `version`, the version of the site, such as `"1.0.0"`.

- `upload_type`: `"software"`.

- `description`: "Supplemental materials for: " and `citation`.

- `creators`: each author as "Family, Given", with the ORCID iD and the
  affiliation, in the order of `_supplement.yml`.

- `license`: the SPDX identifier in `license.content`, in lowercase. The
  `license` field of `.zenodo.json` takes one license id, so the code
  license is not written.

Empty values are left out. In each value, every run of spaces and line
breaks becomes one space, and spaces at the start and end are removed.
Values are otherwise written as they are, so Markdown such as
`*Journal*` keeps its asterisks. YAML reads some values without quotes
as numbers or as true/false, for example `No` or `1.10`. Such a value is
an error, so put it in quotes in `_supplement.yml`, as the template
does.

## Errors

The errors that these functions raise themselves have the class
`supplement_error` and one of these classes:

- `supplement_error_argument`: `path` is not a single non-missing,
  non-empty character string, or `overwrite` is not `TRUE` or `FALSE`.

- `supplement_error_no_metadata`: `path` has no `_supplement.yml`.

- `supplement_error_parse`: the yaml package cannot read
  `_supplement.yml`. Examples are a `[` or a `{` that is not closed, a
  key line indented with a tab, and a key given twice in one map. The
  message names the file and gives the message of the yaml package.

- `supplement_error_no_map`: the file has no `supplement:` map.

- `supplement_error_missing_field`: `paper-title` is missing or empty.
  For `write_zenodo()`, also `citation`.

- `supplement_error_field_type`: a value that the function reads is a
  list (a one-item list included), a number, or true/false where one
  text value belongs, or `license` (and, for
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md),
  `zenodo`) is not a map.

- `supplement_error_doi`: for
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md),
  `zenodo.concept-doi` or `zenodo.version-doi`, with its prefix removed,
  is not `10.`, four to nine digits, `/`, and a suffix with no spaces.

- `supplement_error_license`: `license.content` (and, for
  [`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md),
  `license.code`) is not empty and does not have the shape of an SPDX
  license id: letters or digits, then groups of one `.` or `-` and more
  letters or digits, and at most one `+` at the end. For example,
  `CC BY 4.0` has spaces and `GPL--3.0` has two hyphens in a row, so
  both are errors, and `CC-BY-4.0` is not. The check does not test that
  SPDX or Zenodo knows the id. The template's page footer applies the
  same check, so such a value also stops the site render.

- `supplement_error_version`: `version` is not empty and is not three
  whole numbers joined by `.`, each `0` or without a leading zero, such
  as `1.0.0` or `0.10.2`.

- `supplement_error_authors`: `authors` is missing, empty, or not a list
  of authors.

- `supplement_error_author_name`: an author has no `family` or no
  `given` name.

- `supplement_error_orcid`: an ORCID iD does not have the form
  `0000-0000-0000-0000`, with or without `https://orcid.org/` or
  `http://orcid.org/` in front, or its last character is not the iD's
  check digit. The last character can be `X`.

- `supplement_error_file_exists`: the output file exists and `overwrite`
  is `FALSE`. A folder at the output path is this error even when
  `overwrite` is `TRUE`. So is a link, also a link to a missing file,
  because a write would follow it.

- `supplement_error_write`: the output file was opened, but writing it
  gave an error or a warning (R warns when the disk is full), or the
  file then has another size than the text.

## See also

[`write_citation()`](https://jmgirard.github.io/supplement/reference/write_citation.md)
for `CITATION.cff`.

## Examples

``` r
site <- file.path(tempdir(), "my-supplement")
dir.create(site)
file.copy(
  system.file("template", "_supplement.yml", package = "supplement"),
  site
)
#> [1] TRUE
write_zenodo(site)
readLines(file.path(site, ".zenodo.json"))
#>  [1] "{"                                                                                                                             
#>  [2] "  \"title\": \"Supplemental materials for: Title of the paper\","                                                              
#>  [3] "  \"upload_type\": \"software\","                                                                                              
#>  [4] "  \"description\": \"Supplemental materials for: Author, A. A., & Author, B. B. (Year). Title of the paper. *Journal Name*.\","
#>  [5] "  \"creators\": ["                                                                                                             
#>  [6] "    {"                                                                                                                         
#>  [7] "      \"name\": \"Author, A. A.\""                                                                                             
#>  [8] "    },"                                                                                                                        
#>  [9] "    {"                                                                                                                         
#> [10] "      \"name\": \"Author, B. B.\""                                                                                             
#> [11] "    }"                                                                                                                         
#> [12] "  ],"                                                                                                                          
#> [13] "  \"license\": \"cc-by-4.0\""                                                                                                  
#> [14] "}"                                                                                                                             
unlink(site, recursive = TRUE)
```
