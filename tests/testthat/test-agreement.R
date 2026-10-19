# The site's shortcodes (Lua) and write_citation() (R) read the same
# license and DOI values. These tests run each value shape in each field
# through both and check that both accept it (for DOIs, with the same bare
# DOI), or both refuse it.

# A site that holds `meta` as `_supplement.yml`, the supplement extension,
# and one page with `body`.
agreement_site <- function(meta, body, text = NULL, env = parent.frame()) {
  dir <- local_site(meta, text = text, env = env)
  dir.create(file.path(dir, "_extensions"))
  file.copy(file.path(template_dir(), "_extensions", "supplement"), file.path(dir, "_extensions"),
            recursive = TRUE)
  writeLines(
    c("project:", "  type: website", "  output-dir: docs", "metadata-files:", "  - _supplement.yml"),
    file.path(dir, "_quarto.yml")
  )
  writeLines(c("---", "title: Fixture", "---", "", body), file.path(dir, "index.qmd"))
  dir
}

# Write each string in double quotes, as a site author would.
quoted <- function(x) {
  if (is.list(x)) lapply(x, quoted) else structure(x, quoted = TRUE)
}

citation_result <- function(dir) {
  tryCatch(write_citation(dir), error = function(e) e)
}

render_result <- function(dir) {
  rendered <- run_split(dir, "quarto", "render")
  html <- if (rendered$status == 0L) read_text(file.path(dir, "docs", "index.html")) else ""
  c(rendered, list(html = html))
}

# Each shape with the text that the shortcode shows for it, or NA when
# write_citation() and the render must both refuse it. The texts come from
# the readable-name list and the id rule, not from the code under test.
license_shapes <- list(
  "a plain id" = list("MIT", "MIT"),
  "an id with . and -" = list("CC-BY-4.0", "CC BY 4.0"),
  "a final +" = list("GPL-2.0+", "GPL-2.0+"),
  "mixed letter case" = list("Cc-By-Sa-4.0", "CC BY-SA 4.0"),
  "a space" = list("CC BY 4.0", NA),
  "--" = list("GPL--3.0", NA),
  ".." = list("GPL-3..0", NA),
  "..." = list("MIT...", NA),
  "a final -" = list("MIT-", NA),
  "a final ." = list("MIT.", NA),
  "a leading -" = list("-MIT", NA),
  "Markdown emphasis" = list("*MIT*", NA),
  "a code span" = list("`MIT`", NA)
)

test_that("write_citation() and the license shortcode accept and refuse the same ids", {
  skip_if_no_quarto(needs_r = FALSE)

  page <- "BEFORE {{< supplement-license code >}} MID {{< supplement-license content >}} AFTER"
  # full_supplement() has code MIT and content CC-BY-4.0.
  other_text <- c(code = "CC BY 4.0", content = "MIT")
  for (field in c("code", "content")) {
    for (shape in names(license_shapes)) {
      info <- paste(field, shape)
      id <- license_shapes[[shape]][[1]]
      shown <- license_shapes[[shape]][[2]]
      meta <- full_supplement()
      meta$license[[field]] <- id
      dir <- agreement_site(quoted(meta), page)

      cff <- citation_result(dir)
      rendered <- render_result(dir)
      if (is.na(shown)) {
        expect_true(inherits(cff, "supplement_error_license"), info = info)
        expect_match(conditionMessage(cff), paste0("supplement.license.", field), fixed = TRUE, info = info)
        expect_false(rendered$status == 0L, info = info)
        expect_match(rendered$stderr, paste0("supplement-license: supplement.license.", field, " "),
                     fixed = TRUE, info = info)
      } else {
        expect_false(inherits(cff, "error"), info = paste(info, if (inherits(cff, "error")) conditionMessage(cff)))
        expect_equal(rendered$status, 0L, info = paste(info, rendered$stderr))
        texts <- if (field == "code") c(shown, other_text[["code"]]) else c(other_text[["content"]], shown)
        expect_equal(strip_tags(between_markers(rendered$html)),
                     paste("BEFORE", texts[[1]], "MID", texts[[2]], "AFTER"), info = info)
      }
    }
  }
})

bare <- "10.5281/zenodo.333"

# Each shape with its bare DOI, or NA when both sides must refuse it, and
# the error class that write_citation() gives then.
doi_shapes <- list(
  "a bare DOI" = list(bare, bare),
  "https://doi.org/" = list(paste0("https://doi.org/", bare), bare),
  "https://www.doi.org/" = list(paste0("https://www.doi.org/", bare), bare),
  "http://dx.doi.org/" = list(paste0("http://dx.doi.org/", bare), bare),
  "doi:" = list(paste0("doi:", bare), bare),
  "doi: and a space" = list(paste0("doi: ", bare), bare),
  "HTTPS://DOI.ORG/" = list(paste0("HTTPS://DOI.ORG/", bare), bare),
  "doi: alone" = list("doi:", NA, "supplement_error_doi"),
  "https://doi.org/ alone" = list("https://doi.org/", NA, "supplement_error_doi"),
  "a three-digit registrant code" = list("10.528/zenodo.333", NA, "supplement_error_doi"),
  "a space in the suffix" = list("10.5281/zenodo 333", NA, "supplement_error_doi"),
  "a list" = list(list(bare), NA, "supplement_error_field_type")
)

test_that("write_citation() and the DOI badge accept and refuse the same DOIs", {
  skip_if_no_quarto(needs_r = FALSE)

  for (key in c("version-doi", "concept-doi")) {
    field <- paste0("supplement.zenodo.", key)
    for (shape in names(doi_shapes)) {
      info <- paste(key, shape)
      doi <- doi_shapes[[shape]][[1]]
      expected <- doi_shapes[[shape]][[2]]
      meta <- full_supplement()
      # The shape is the only DOI set.
      meta$zenodo <- list("version-doi" = "", "concept-doi" = "", "archive-url" = "")
      meta$zenodo[[key]] <- doi
      dir <- agreement_site(quoted(meta), "BEFORE {{< supplement-doi >}} AFTER")

      cff <- citation_result(dir)
      rendered <- render_result(dir)
      if (is.na(expected)) {
        expect_true(inherits(cff, doi_shapes[[shape]][[3]]), info = info)
        expect_match(conditionMessage(cff), field, fixed = TRUE, info = info)
        expect_false(rendered$status == 0L, info = info)
        expect_match(rendered$stderr, paste0("supplement-doi: ", field, " "), fixed = TRUE, info = info)
      } else {
        expect_false(inherits(cff, "error"), info = paste(info, if (inherits(cff, "error")) conditionMessage(cff)))
        expect_equal(read_cff(dir)$doi, expected, info = info)
        expect_equal(rendered$status, 0L, info = paste(info, rendered$stderr))
        expect_match(rendered$html, doi_badge_rx(expected), perl = TRUE, info = info)
      }
    }
  }
})

# The text of `_supplement.yml` with full_supplement()'s other values and
# `license` and `zenodo` maps written as the given YAML lines, indented
# under `supplement:`.
supplement_text <- function(license, zenodo) {
  meta <- full_supplement()
  meta$license <- NULL
  meta$zenodo <- NULL
  base <- strsplit(yaml::as.yaml(list(supplement = quoted(meta))), "\n")[[1]]
  c(base, paste0("  ", c("license:", license, "zenodo:", zenodo)))
}

test_that("write_citation() and the shortcodes read null and block values alike", {
  skip_if_no_quarto(needs_r = FALSE)

  page <- "BEFORE {{< supplement-license code >}} MID {{< supplement-license content >}} DOI {{< supplement-doi >}} AFTER"
  content <- '  content: "CC-BY-4.0"'
  no_doi <- c('  version-doi: ""', '  concept-doi: ""')
  bare <- "10.5281/zenodo.333"

  # A null license is empty on both sides.
  dir <- agreement_site(NULL, page, text = supplement_text(c("  code:", content), no_doi))
  cff <- citation_result(dir)
  rendered <- render_result(dir)
  expect_false(inherits(cff, "error"))
  expect_identical(read_cff(dir)$license, "CC-BY-4.0")
  expect_equal(rendered$status, 0L, info = rendered$stderr)
  expect_equal(strip_tags(between_markers(rendered$html)), "BEFORE MID CC BY 4.0 DOI AFTER")

  # A block license is its text on both sides.
  dir <- agreement_site(NULL, page, text = supplement_text(c("  code: |", "    MIT", content), no_doi))
  cff <- citation_result(dir)
  rendered <- render_result(dir)
  expect_false(inherits(cff, "error"))
  expect_identical(read_cff(dir)$license, c("MIT", "CC-BY-4.0"))
  expect_equal(rendered$status, 0L, info = rendered$stderr)
  expect_equal(strip_tags(between_markers(rendered$html)), "BEFORE MIT MID CC BY 4.0 DOI AFTER")

  # A license of two paragraphs is refused on both sides.
  dir <- agreement_site(NULL, page, text = supplement_text(c("  code: |", "    MIT", "", "    X", content), no_doi))
  cff <- citation_result(dir)
  rendered <- render_result(dir)
  expect_true(inherits(cff, "supplement_error_license"))
  expect_false(rendered$status == 0L)
  expect_match(rendered$stderr, "supplement-license: supplement.license.code ", fixed = TRUE)

  # A null DOI is empty, and a folded DOI is its text, on both sides.
  dir <- agreement_site(NULL, page, text = supplement_text(content, c("  version-doi:", "  concept-doi: >", paste0("    ", bare))))
  cff <- citation_result(dir)
  rendered <- render_result(dir)
  expect_false(inherits(cff, "error"))
  expect_identical(read_cff(dir)$doi, bare)
  expect_equal(rendered$status, 0L, info = rendered$stderr)
  expect_match(rendered$html, doi_badge_rx(bare), perl = TRUE)

  # A DOI of two paragraphs is refused on both sides.
  dir <- agreement_site(NULL, page, text = supplement_text(content, c("  version-doi: |", "    10.5281/zenodo.1", "", "    2")))
  cff <- citation_result(dir)
  rendered <- render_result(dir)
  expect_true(inherits(cff, "supplement_error_doi"))
  expect_false(rendered$status == 0L)
  expect_match(rendered$stderr, "supplement-doi: supplement.zenodo.version-doi ", fixed = TRUE)
})
