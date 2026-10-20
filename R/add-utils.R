# Checks and errors that add_report() and add_data() share.

# Stop unless `x` is one string. With `required = TRUE`, it must also
# hold a character that is not white space. A line break is always an error,
# because the value goes on one line of YAML.
check_text <- function(x, arg, required = FALSE, call = parent.frame()) {
  if (is.character(x) && length(x) == 1 && !is.na(x) && !validUTF8(enc2utf8(x))) {
    cli::cli_abort(
      "{.arg {arg}} must be UTF-8 text. Mark its encoding or convert it with {.fn enc2utf8} or {.fn iconv}.",
      class = c("supplement_error_encoding", "supplement_error"),
      call = call
    )
  }
  # (*UCP) makes \S skip Unicode spaces such as U+00A0 and U+3000 too.
  if (!is.character(x) || length(x) != 1 || is.na(x) ||
      (required && !grepl("(*UCP)\\S", enc2utf8(x), perl = TRUE))) {
    what <- if (required) "one string with a character other than white space" else "one string"
    cli::cli_abort(
      "{.arg {arg}} must be {what}.",
      class = c("supplement_error_argument", "supplement_error"),
      call = call
    )
  }
  breaks <- c(0x0a, 0x0b, 0x0c, 0x0d, 0x85, 0x2028, 0x2029)
  if (any(utf8ToInt(enc2utf8(x)) %in% breaks)) {
    cli::cli_abort(
      "{.arg {arg}} must be one line of text, with no line break.",
      class = c("supplement_error_line_break", "supplement_error"),
      call = call
    )
  }
  utf8_text(x)
}

# TRUE for each element of `x` that is a name Windows reserves for a
# device, in any letter case. Windows cannot make a file of that name, and
# reads `con.csv` as `con` too, so callers pass the part before the first
# `.`. The list is the ASCII part of the one on Microsoft's page "Naming
# Files, Paths, and Namespaces"
# (https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file).
# The page also lists COM and LPT with the superscript digits ¹, ², and ³.
# Both name rules allow only ASCII, so those names never reach this check;
# a rule that allows other characters must add them here.
windows_reserved <- function(x) {
  devices <- c("con", "prn", "aux", "nul", paste0("com", 1:9), paste0("lpt", 1:9))
  tolower(x) %in% devices
}

# `x` as a string marked as UTF-8. A string marked "bytes" that holds valid
# UTF-8 is marked as UTF-8, so that it compares equal to the same text read
# from a file.
utf8_text <- function(x) {
  if (identical(Encoding(x), "bytes")) {
    x <- rawToChar(charToRaw(x))
    Encoding(x) <- "UTF-8"
  }
  enc2utf8(x)
}

# Stop with `message`, formatted by cli, followed by `lines` of YAML as
# they are. A cli message drops the spaces at the start of a line, so this
# error is made without cli.
abort_with_lines <- function(message, lines, class, call = parent.frame(), .envir = parent.frame()) {
  header <- cli::format_message(message, .envir = .envir)
  cond <- structure(
    class = c(class, "supplement_error", "error", "condition"),
    list(
      message = paste(c(header, paste0("    ", lines)), collapse = "\n"),
      call = frame_call(call)
    )
  )
  stop(cond)
}

# The call of the function whose frame is `env`, or NULL.
frame_call <- function(env) {
  i <- which(vapply(sys.frames(), identical, logical(1), env))
  if (length(i) > 0) sys.call(i[length(i)])
}

# A list with `read`, what read_text_lines() returned for `file`, and
# `lines`, its lines with `item` added as the last item of the first list
# in `paths` that is in block style. Stops before any write when the yaml
# package cannot read the file, when no path names a block-style list, or
# when the yaml package does not read the result as the old list with the
# item added. `missing` is the message for the second case. `hand` holds
# the lines to add by hand, which the last two errors show.
append_item <- function(file, paths, item, missing, missing_class, hand, call = parent.frame(),
                        .envir = parent.frame()) {
  read <- read_text_lines(file, call = call)
  yaml_read_file_text(yaml_lines_text(read$lines), file, call = call)
  for (path in paths) {
    new <- yaml_append_lines(read$lines, path, item)
    if (!is.null(new)) {
      break
    }
  }
  if (is.null(new)) {
    abort_with_lines(
      c(missing, "i" = "Add these lines by hand:"),
      hand,
      class = missing_class,
      call = call,
      .envir = .envir
    )
  }
  if (!yaml_appended(read$lines, new, path, item)) {
    abort_with_lines(
      c("Could not add the item to {.file {basename(file)}} as text, so nothing was written.",
        "i" = "Add these lines by hand:"),
      hand,
      class = "supplement_error_yaml",
      call = call
    )
  }
  list(read = read, lines = new)
}
