# A frozen copy of the link reader before it walked heads in R (tag_links()
# and the patterns it used, R/check-supplement.R at commit e7ba02a). It is
# the oracle that the reader must agree with on pages within PCRE's match
# limit. Edit nothing here: a change to the reader's rules belongs in the
# package and in the test that compares the two.

old_html <- local({
  space <- "[\t\n\f\r ]"
  attr <- paste0(
    "[^\t\n\f\r />][^\t\n\f\r />=]*+",
    "(?:", space, "*+=", space, "*+(?:\"[^\"]*+\"|'[^']*+'|[^\t\n\f\r >]*+))?+"
  )
  tag_rest <- paste0("(?:[\t\n\f\r /]++|", attr, ")*+(?:>|\\z)")
  start_tag <- paste0("<[A-Za-z][^\t\n\f\r />]*+", tag_rest)
  any_case <- function(word) {
    chars <- strsplit(word, "", fixed = TRUE)[[1]]
    upper <- chartr("abcdefghijklmnopqrstuvwxyz", "ABCDEFGHIJKLMNOPQRSTUVWXYZ", chars)
    paste0("[", upper, chars, "]", collapse = "")
  }
  script_body <- local({
    name <- any_case("script")
    start <- paste0("<", name, "[\t\n\f\r />]")
    end <- paste0("</", name, "[\t\n\f\r />]")
    no_end <- paste0("</(?!", name, "[\t\n\f\r />])")
    plain_run <- "[^<]*+(?:<(?![/!])[^<]*+)*+"
    plain <- paste0(plain_run, "(?:(?:", no_end, "|<!(?!--))", plain_run, ")*+")
    dashes <- "-++(?!>)|->"
    double_run <- "[^<-]*+(?:<(?!/)[^<-]*+)*+"
    double_text <- paste0(double_run, "(?:(?:", dashes, "|", no_end, ")", double_run, ")*+")
    escaped_run <- "[^<-]*+(?:<(?![/Ss])[^<-]*+)*+"
    escaped <- paste0(
      "<!", escaped_run,
      "(?:(?:", dashes, "|", no_end, "|<(?=[Ss])(?!", name, "[\t\n\f\r />])|", start, double_text, end, ")",
      escaped_run, ")*+",
      "(?:--++>|", start, double_text, "(?:--++>)?+)?+"
    )
    paste0(plain, "(?:", escaped, plain, ")*+")
  })
  raw_text <- function(name) {
    body <- if (name == "script") script_body
    name <- any_case(name)
    end <- paste0("/", name, "(?=[\t\n\f\r />])")
    paste0(
      "(<", name, "(?=[\t\n\f\r />])", tag_rest, ")",
      if (is.null(body)) paste0("[^<]*+(?:<(?!", end, ")[^<]*+)*+") else body,
      "(?:<", end, "[^>]*+(?:>|\\z))?+"
    )
  }
  skipped <- paste0(
    "<!--(?:-?+>|[^-]*+(?:-(?!-!?+>)[^-]*+)*+(?:--!?+>|\\z))|<[!?][^>]*+(?:>|\\z)|",
    paste(vapply(c("script", "style", "textarea", "title"), raw_text, character(1)), collapse = "|"),
    "|</(?![A-Za-z])[^>]*+(?:>|\\z)|</[A-Za-z][^\t\n\f\r />]*+", tag_rest,
    "|(", start_tag, ")"
  )
  list(space = space, attr = attr, start_tag = start_tag, skipped = skipped)
})

old_tag_links <- function(html) {
  lower <- function(x) chartr("ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz", x)
  value <- function(attrs) {
    values <- sub(paste0("(?s)^[^=]*=", old_html$space, "*"), "", attrs, perl = TRUE)
    values[!grepl("=", attrs, fixed = TRUE)] <- ""
    sub("(?s)^([\"'])(.*)\\1$", "\\2", values, perl = TRUE)
  }
  html <- gsub(old_html$skipped, "\\1\\2\\3\\4\\5 ", html, perl = TRUE, useBytes = TRUE)
  Encoding(html) <- "UTF-8"
  tags <- regmatches(html, gregexpr(old_html$start_tag, html, perl = TRUE, useBytes = TRUE))[[1]]
  Encoding(tags) <- "UTF-8"
  tags <- tags[endsWith(tags, ">") & grepl("[Hh][Rr][Ee][Ff]|[Ss][Rr][Cc]", tags)]
  rests <- sub("^<[^\t\n\f\r />]*", "", tags)
  per_tag <- regmatches(rests, gregexpr(old_html$attr, rests, perl = TRUE))
  attrs <- unlist(per_tag)
  attr_names <- lower(sub("(?s)^([^=\t\n\f\r ]*).*", "\\1", attrs, perl = TRUE))
  tag_names <- lower(sub("(?s)^<([^\t\n\f\r />]*).*", "\\1", tags, perl = TRUE))
  in_base <- (tag_names == "base")[rep(seq_along(per_tag), lengths(per_tag))]
  base <- attrs[in_base & attr_names == "href"]
  links <- attrs[!in_base & attr_names %in% c("href", "src", "xlink:href")]
  links <- links[grepl("=", links, fixed = TRUE)]
  structure(value(links), base = if (length(base) > 0) value(base[1]))
}
