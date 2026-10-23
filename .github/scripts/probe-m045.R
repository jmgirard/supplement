# Temporary probe: how fs and base R read links on Windows.
dir <- file.path(normalizePath(tempdir(), winslash = "/"), "probe")
dir.create(dir)
outside <- file.path(dir, "outside")
dir.create(outside)
writeLines("x", file.path(outside, "target.txt"))
writeLines("x", file.path(dir, "plain.txt"))
dir.create(file.path(dir, "folder"))

made <- c(
  file_link = file.symlink(file.path(outside, "target.txt"), file.path(dir, "file-link")),
  dangling = file.symlink(file.path(outside, "missing.txt"), file.path(dir, "dangling")),
  junction = Sys.junction(outside, file.path(dir, "junction")),
  folder_link = file.symlink(outside, file.path(dir, "folder-link"))
)
print(made)

# A path over 260 characters.
long <- dir
while (nchar(long) < 270) long <- file.path(long, strrep("d", 40))
long_made <- tryCatch(dir.create(long, recursive = TRUE), error = function(e) conditionMessage(e))
long_file <- file.path(long, "long.txt")
long_written <- tryCatch({ writeLines("x", long_file); TRUE }, error = function(e) conditionMessage(e))
cat("long path made:", format(long_made), " file written:", format(long_written), " nchar:", nchar(long_file), "\n")

paths <- c(
  file.path(dir, c("plain.txt", "folder", "file-link", "dangling", "junction", "folder-link", "not-there")),
  long_file,
  path.expand("~")
)
try_or <- function(expr) tryCatch(format(expr), error = function(e) paste("ERROR:", conditionMessage(e)),
                                  warning = function(w) paste("WARNING:", conditionMessage(w)))
for (p in paths) {
  cat("\n==", if (nchar(p) > 80) paste0("...", substring(p, nchar(p) - 40)) else p, "\n")
  cat("  fs::is_link:          ", try_or(fs::is_link(p)), "\n")
  cat("  fs::file_info type:   ", try_or(as.character(fs::file_info(p, follow = FALSE)$type)), "\n")
  cat("  fs::link_exists:      ", try_or(fs::link_exists(p)), "\n")
  cat("  file.exists:          ", try_or(file.exists(p)), "\n")
  cat("  dir.exists:           ", try_or(dir.exists(p)), "\n")
  cat("  Sys.readlink:         ", try_or(Sys.readlink(p)), "\n")
  cat("  file.info size:       ", try_or(file.info(p)$size), "\n")
  cat("  is_reparse_point:     ", try_or(supplement:::is_reparse_point(p)), "\n")
  cat("  is_link:              ", try_or(supplement:::is_link(p)), "\n")
}
cat("\nfs::path_expand('~'):", fs::path_expand("~"), " path.expand('~'):", path.expand("~"), "\n")
cat("fs version:", as.character(packageVersion("fs")), " R:", R.version.string, "\n")
