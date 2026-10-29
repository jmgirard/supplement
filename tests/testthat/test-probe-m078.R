# Temporary probe: what Quarto does with a report name that is not valid
# UTF-8 on Linux. It fails on purpose so that R CMD check prints its text.
test_that("probe: Quarto render of a site with a report name that is not valid UTF-8", {
  skip_if_no_quarto()
  skip_on_os(c("mac", "windows"))
  site <- long_dir(new_site())
  bad <- file.path(site, "analyses", paste0(rawToChar(as.raw(c(0x63, 0x61, 0x66, 0xe9))), ".qmd"))
  writeBin(charToRaw("---\ntitle: Bad name\n---\n\nText.\n"), bad)
  result <- run_in(site, "quarto", "render")
  output <- iconv(result$output, "UTF-8", "UTF-8", sub = "byte")
  output <- output[!grepl("^\\s*\\[?DEBUG|^DEBUG", output)]
  pages <- iconv(list.files(file.path(site, "docs", "analyses")), "UTF-8", "UTF-8", sub = "byte")
  fail(paste(c(paste("status:", result$status), "docs/analyses:", pages, "output (last 40 lines):",
               utils::tail(output, 40)), collapse = "\n"))
})
