# Add one item to the end of a block-style YAML list by inserting lines of
# text, or change the value on one line of a block-style map, so that every
# other line of the file, its comments included, stays as it was. The
# scanner reads only the indentation and the keys of lines, so it knows the
# block style that the template uses and not every YAML form.
# yaml_appended() and yaml_replaced() read the result with the yaml
# package, so that a form the scanner reads wrongly stops the caller before
# it writes.

# The lines of a UTF-8 text file, split at each "\n". A line keeps its
# "\r" when the file has CRLF line endings, and a file that ends with a
# line break has "" as its last line, so pasting the lines with "\n" gives
# the text back. `bytes` holds the whole file, to restore it when a write
# fails.
read_text_lines <- function(file, call = parent.frame()) {
  bytes <- readBin(file, "raw", file.size(file))
  not_utf8 <- function() {
    cli::cli_abort(
      "{.file {file}} is not UTF-8 text, so nothing was written.",
      class = c("supplement_error_encoding", "supplement_error"),
      call = call
    )
  }
  # A NUL byte, as in UTF-16 text, cannot be in an R string.
  if (any(bytes == as.raw(0))) {
    not_utf8()
  }
  bom <- length(bytes) >= 3 && identical(bytes[1:3], as.raw(c(0xef, 0xbb, 0xbf)))
  text <- rawToChar(if (bom) bytes[-(1:3)] else bytes)
  Encoding(text) <- "UTF-8"
  if (!validUTF8(text)) {
    not_utf8()
  }
  lines <- if (nzchar(text)) strsplit(text, "\n", fixed = TRUE)[[1]] else ""
  if (endsWith(text, "\n")) {
    lines <- c(lines, "")
  }
  list(lines = lines, bom = bom, bytes = bytes)
}

# Write `lines` to `file` as read_text_lines() would read them. If the
# write fails after the file is opened, the file gets its old bytes back.
write_text_lines <- function(read, lines, file, call = parent.frame()) {
  bytes <- charToRaw(enc2utf8(paste(lines, collapse = "\n")))
  if (read$bom) {
    bytes <- c(as.raw(c(0xef, 0xbb, 0xbf)), bytes)
  }
  write_checked(bytes, file, restore = read$bytes, call = call)
}

# Write `bytes` to `file`. A file that cannot be opened gives R's own
# error. After the file is opened, an error, a warning (R only warns when
# the disk is full), or a file of another size stops with
# `supplement_error_write`, after `restore`, when given, is written back.
write_checked <- function(bytes, file, restore = NULL, call = parent.frame()) {
  con <- file(file, open = "wb")
  failed <- function(reason) {
    if (!is.null(con)) {
      try(suppressWarnings(close(con)), silent = TRUE)
    }
    if (!is.null(restore)) {
      try(suppressWarnings(writeBin(restore, file)), silent = TRUE)
    }
    cli::cli_abort(
      c("Could not write {.path {file}}: {reason}",
        "i" = if (!is.null(restore)) "The file got its old text back."),
      class = c("supplement_error_write", "supplement_error"),
      call = call
    )
  }
  tryCatch(
    {
      write_bytes(bytes, con)
      close(con)
      con <- NULL
    },
    error = function(e) failed(conditionMessage(e)),
    warning = function(w) failed(conditionMessage(w))
  )
  if (!identical(file.size(file), as.numeric(length(bytes)))) {
    failed("the file has another size than the text written.")
  }
  invisible(file)
}

# A separate function, so that tests can make a write fail.
write_bytes <- function(bytes, con) {
  writeBin(bytes, con)
}

# A YAML double-quoted string for each value. `\` and `"` are escaped, and
# so are control characters, the characters that YAML 1.1 reads as line
# breaks or as a byte order mark, and the noncharacters U+FFFE and U+FFFF.
yaml_quote <- function(x) {
  vapply(enc2utf8(x), function(s) {
    cp <- utf8ToInt(s)
    out <- intToUtf8(cp, multiple = TRUE)
    escape <- cp < 0x20 | (cp >= 0x7f & cp <= 0x9f) |
      cp %in% c(0x2028, 0x2029, 0xfeff, 0xfffe, 0xffff)
    out[escape] <- sprintf("\\u%04X", cp[escape])
    out[cp == 0x5c] <- "\\\\"
    out[cp == 0x22] <- "\\\""
    paste0("\"", paste(out, collapse = ""), "\"")
  }, "", USE.NAMES = FALSE)
}

# One step of a path to a list: a key of a map, or yaml_item(key, value)
# for the item of a list whose map has `key: value`.
yaml_item <- function(key, value) {
  list(key = key, value = value)
}

# `lines` with `item`, a named character vector, added as the last item of
# the block-style list that `path` names. NULL when there is no such list.
# The lines of a file read by read_text_lines() may end with "\r". The new
# lines get the line ending that most lines of the file have.
yaml_append_lines <- function(lines, path, item) {
  found <- yaml_find_list(sub("\r$", "", lines), path)
  if (is.null(found)) {
    return(NULL)
  }
  values <- yaml_quote(unname(item))
  new <- paste0(strrep(" ", found$indent), "-", strrep(" ", found$offset - 1), names(item)[1], ": ", values[1])
  if (length(item) > 1) {
    new <- c(new, paste0(strrep(" ", found$indent + found$offset), names(item)[-1], ": ", values[-1]))
  }
  n <- length(lines)
  ended <- lines[-n]
  cr <- if (length(ended) > 0 && mean(endsWith(ended, "\r")) > 0.5) "\r" else ""
  new <- paste0(new, cr)
  if (found$after == n) {
    # The list ends the file and no line break follows it, so the old last
    # line gets one and the new last line does not.
    lines[n] <- paste0(lines[n], cr)
    new[length(new)] <- sub("\r$", "", new[length(new)])
  }
  append(lines, new, after = found$after)
}

# TRUE when the yaml package reads `new` as `old` with `item` added as the
# last item of the list that `path` names, and with nothing else changed.
yaml_appended <- function(old, new, path, item) {
  old_doc <- yaml_read_lines(old)
  new_doc <- yaml_read_lines(new)
  before <- yaml_get(old_doc, path)
  after <- yaml_get(new_doc, path)
  n <- length(after)
  is.list(before) && is.list(after) && n == length(before) + 1 &&
    identical(after[-n], before) && identical(after[[n]], as.list(item)) &&
    identical(yaml_set(new_doc, path, after[-n]), old_doc)
}

# The lines read with the yaml package, or NULL when they are not valid
# YAML.
yaml_read_lines <- function(lines) {
  tryCatch(yaml_parse_lines(lines), error = function(e) NULL)
}

# The lines read with the yaml package. Text that is not valid YAML gives
# the parser's error. Every sequence is read as a list, as
# read_supplement() does.
yaml_parse_lines <- function(lines) {
  yaml_load_list(yaml_lines_text(lines))
}

# The lines as one text, with the "\r" at the end of each line removed.
# The text ends with a line break either way, so that a block scalar at the
# end of the file reads the same before and after an insert.
yaml_lines_text <- function(lines) {
  paste0(paste(sub("\r$", "", lines), collapse = "\n"), "\n")
}

yaml_load_list <- function(text) {
  yaml::yaml.load(text, handlers = list(seq = function(x) as.list(x)))
}

# `text`, the text of `file`, read as yaml_load_list() reads it. Text that
# the yaml package cannot read stops with `supplement_error_parse`, which
# names `file` and gives the parser's message.
yaml_read_file_text <- function(text, file, call = parent.frame()) {
  tryCatch(yaml_load_list(text), error = function(e) {
    parser <- trimws(conditionMessage(e))
    # The parser's message is data: a "{" in it is not a cli template.
    cli::cli_abort(
      c("The yaml package cannot read {.file {file}}, so nothing was written.",
        "x" = "{parser}",
        "i" = "Fix the YAML at the place that the message names."),
      class = c("supplement_error_parse", "supplement_error"),
      call = call
    )
  })
}

# `lines` with the value of the key that `path`, a vector of map keys,
# names replaced by `value` in double quotes. Only the value's text on the
# key's line changes, so the spaces and a comment after it stay. NULL when
# a step of the path is missing or not in block form, or when the value is
# not a one-line scalar on the key's line: a block, a block scalar (`|` or
# `>`), a flow list or map, an anchor, an alias, or a tag. An empty value,
# as in `version:`, is replaced too.
yaml_replace_lines <- function(lines, path, value) {
  plain <- sub("\r$", "", lines)
  from <- 1L
  to <- length(plain)
  for (step in path[-length(path)]) {
    k <- yaml_find_key(plain, from, to, step)
    if (is.null(k) || !grepl("^\\s*(#.*)?$", k$rest)) {
      return(NULL)
    }
    block <- yaml_child(plain, k$line)
    if (is.null(block)) {
      return(NULL)
    }
    from <- block[1]
    to <- block[2]
  }
  k <- yaml_find_key(plain, from, to, path[length(path)])
  # A more indented line below the key would continue its value.
  if (is.null(k) || !is.null(yaml_child(plain, k$line))) {
    return(NULL)
  }
  # The spaces before the value, the value (double-quoted, single-quoted,
  # plain, or empty), and the spaces and comment after it.
  rx <- paste0(
    "^(\\s*)",
    "(\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^']|'')*'|[^\\s#|>\\[\\]{}&*!%@`'\",][^#]*?|)",
    "(\\s*(?:\\s#.*)?)$"
  )
  m <- regmatches(k$rest, regexec(rx, k$rest, perl = TRUE))[[1]]
  if (length(m) == 0) {
    return(NULL)
  }
  line <- plain[k$line]
  key <- substr(line, 1, nchar(line) - nchar(k$rest))
  # An empty value goes one space after the colon, before the old spaces
  # and comment.
  new <- if (nzchar(m[3])) {
    paste0(key, m[2], yaml_quote(value), m[4])
  } else {
    paste0(key, " ", yaml_quote(value), k$rest)
  }
  cr <- if (endsWith(lines[k$line], "\r")) "\r" else ""
  lines[k$line] <- paste0(new, cr)
  lines
}

# TRUE when the yaml package reads `new` as `old` with the value at `path`
# set to `value`, and with nothing else changed.
yaml_replaced <- function(old, new, path, value) {
  old_doc <- yaml_read_lines(old)
  new_doc <- yaml_read_lines(new)
  parent <- yaml_get(old_doc, path[-length(path)])
  is_map(parent) && path[length(path)] %in% names(parent) &&
    identical(yaml_get(new_doc, path), value) &&
    identical(yaml_set(old_doc, path, value), new_doc)
}

# `doc` with the value at `path` replaced by `value`.
yaml_set <- function(doc, path, value) {
  if (length(path) == 0) {
    return(value)
  }
  step <- path[[1]]
  i <- if (is.character(step)) {
    step
  } else {
    which(vapply(doc, function(x) is_map(x) && identical(x[[step$key]], step$value), logical(1)))[1]
  }
  doc[[i]] <- yaml_set(doc[[i]], path[-1], value)
  doc
}

yaml_get <- function(doc, path) {
  for (step in path) {
    if (!is.list(doc)) {
      return(NULL)
    }
    if (is.character(step)) {
      doc <- if (!is.null(names(doc))) doc[[step]]
    } else {
      hits <- Filter(function(x) is_map(x) && identical(x[[step$key]], step$value), doc)
      doc <- if (length(hits) > 0) hits[[1]]
    }
  }
  doc
}

yaml_indent <- function(lines) {
  nchar(sub("^( *).*$", "\\1", lines))
}

# TRUE for lines that are not blank and not only a comment.
yaml_content <- function(lines) {
  !grepl("^\\s*(#.*)?$", lines)
}

yaml_dash <- function(lines) {
  grepl("^ *-( |$)", lines)
}

# Find the list that `path` names. Returns the line after which a new item
# goes, the indent of the list's `-`, and the offset from the `-` to the
# item's keys. NULL when a step of the path is missing or is not in block
# form.
yaml_find_list <- function(lines, path) {
  from <- 1L
  to <- length(lines)
  for (step in path) {
    if (is.character(step)) {
      k <- yaml_find_key(lines, from, to, step)
      if (is.null(k) || !grepl("^\\s*(#.*)?$", k$rest)) {
        return(NULL)
      }
      block <- yaml_child(lines, k$line)
    } else {
      block <- NULL
      for (item in yaml_items(lines, from, to)) {
        # Read the item as a map by putting a space where its "-" is.
        as_map <- lines
        as_map[item[1]] <- sub("-", " ", as_map[item[1]], fixed = TRUE)
        k <- yaml_find_key(as_map, item[1], item[2], step$key)
        if (!is.null(k) && identical(yaml_scalar(k$rest), step$value)) {
          lines <- as_map
          block <- item
          break
        }
      }
    }
    if (is.null(block)) {
      return(NULL)
    }
    from <- block[1]
    to <- block[2]
  }
  items <- yaml_items(lines, from, to)
  if (length(items) == 0) {
    return(NULL)
  }
  last <- items[[length(items)]]
  indent <- yaml_indent(lines[last[1]])
  head <- sub("^ *(- *).*$", "\\1", lines[last[1]])
  offset <- nchar(head)
  if (!yaml_content(sub("^ *- *", "", lines[last[1]])) && last[2] > last[1]) {
    # The item's keys start on its next content line.
    rest <- seq.int(last[1] + 1L, last[2])
    offset <- yaml_indent(lines[rest[yaml_content(lines[rest])][1]]) - indent
  }
  list(after = last[2], indent = indent, offset = max(offset, 2L))
}

# The first key `key` of the map in lines `from` to `to`, with the text
# after its colon. NULL when the map has no such key.
yaml_find_key <- function(lines, from, to, key) {
  if (from > to) {
    return(NULL)
  }
  idx <- seq.int(from, to)
  idx <- idx[yaml_content(lines[idx])]
  if (length(idx) == 0) {
    return(NULL)
  }
  indent <- yaml_indent(lines[idx[1]])
  k <- gsub("([.?*+^$(){}|\\[\\]\\\\])", "\\\\\\1", key, perl = TRUE)
  rx <- paste0("^ {", indent, "}(", k, "|\"", k, "\"|'", k, "') *:((\\s.*)?)$")
  for (i in idx[yaml_indent(lines[idx]) == indent]) {
    m <- regmatches(lines[i], regexec(rx, lines[i], perl = TRUE))[[1]]
    if (length(m) > 0) {
      return(list(line = i, rest = m[3]))
    }
  }
  NULL
}

# The first and last content lines of the value of the key on line `k`,
# when that value is a block on the lines below it. A list may start at
# the indent of its key. NULL when no block follows.
yaml_child <- function(lines, k) {
  n <- length(lines)
  if (k >= n) {
    return(NULL)
  }
  idx <- seq.int(k + 1L, n)
  idx <- idx[yaml_content(lines[idx])]
  if (length(idx) == 0) {
    return(NULL)
  }
  key_indent <- yaml_indent(lines[k])
  indent <- yaml_indent(lines[idx])
  if (indent[1] > key_indent) {
    inside <- indent > key_indent
  } else if (indent[1] == key_indent && yaml_dash(lines[idx[1]])) {
    inside <- indent > key_indent | (indent == key_indent & yaml_dash(lines[idx]))
  } else {
    return(NULL)
  }
  stop_at <- which(!inside)
  last <- if (length(stop_at) > 0) stop_at[1] - 1L else length(idx)
  c(idx[1], idx[last])
}

# The items of the block-style list in lines `from` to `to`, each as the
# numbers of its first and last content lines. An empty list when the
# lines are not a block-style list.
yaml_items <- function(lines, from, to) {
  idx <- seq.int(from, to)
  idx <- idx[yaml_content(lines[idx])]
  if (length(idx) == 0) {
    return(list())
  }
  indent <- yaml_indent(lines[idx])
  top <- idx[indent == indent[1]]
  if (!all(yaml_dash(lines[top]))) {
    return(list())
  }
  ends <- vapply(seq_along(top), function(i) {
    next_top <- if (i < length(top)) top[i + 1] else to + 1L
    max(idx[idx < next_top])
  }, integer(1))
  Map(c, top, ends)
}

# The value of a one-line YAML scalar when it is a string, or NULL
# otherwise.
yaml_scalar <- function(text) {
  value <- tryCatch(yaml::yaml.load(text), error = function(e) NULL)
  if (is.character(value) && length(value) == 1) value
}
