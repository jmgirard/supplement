test_that("a site with an added report and data file renders and lists both", {
  skip_if_no_quarto()
  site <- new_site()
  title <- "Model Comparison"
  description <- "Fits and compares the models."
  data_description <- "Scores of each participant"
  scores <- withr::local_tempfile(fileext = ".csv")
  utils::write.csv(data.frame(id = 1:3, score = c(4, 7, 5)), scores, row.names = FALSE)
  suppressMessages({
    add_report("models", title, description, path = site)
    add_data(scores, data_description, path = site)
  })

  rendered <- run_in(site, "quarto", "render")
  expect_equal(rendered$status, 0L, info = paste(rendered$output, collapse = "\n"))

  html <- read_text(file.path(site, "docs", "index.html"))
  reports <- listing_rows(html)
  hit <- Filter(function(row) identical(row$cells, c(title, description)), reports)
  expect_length(hit, 1)
  expect_true(any(grepl("(^|/)analyses/models\\.html$", hit[[1]]$links)))

  data_rows <- lapply(data_table_rows(html), strip_tags)
  expect_true(any(vapply(data_rows, function(cells) {
    identical(cells[1:2], c(basename(scores), data_description))
  }, logical(1))))
  expect_true(file.exists(file.path(site, "docs", "data", basename(scores))))

  # The links in the Analyses dropdown, in order.
  menu <- regmatches(html, regexpr('<ul class="dropdown-menu" aria-labelledby="nav-menu-analyses">[\\s\\S]*?</ul>', html, perl = TRUE))
  expect_length(menu, 1)
  links <- regmatches(menu, gregexpr('href="[^"]*"', menu))[[1]]
  expect_identical(links, c('href="./analyses/example.html"', 'href="./analyses/models.html"'))
  expect_true(file.exists(file.path(site, "docs", "analyses", "models.html")))
})
