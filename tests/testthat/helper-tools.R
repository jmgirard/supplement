# Mocks of the tool lookups in R/check-tools.R, shared by the check_tools()
# and render_supplement() tests.

# A Quarto install under `root`: `bin/<exe>` and, unless `version` is NULL,
# `share/version` with the bytes of `version` (text or raw). Returns the
# program's path.
fake_quarto <- function(root, version = "1.10.19\n", exe = "quarto") {
  dir.create(file.path(root, "bin"), recursive = TRUE)
  dir.create(file.path(root, "share"))
  program <- file.path(root, "bin", exe)
  file.create(program)
  if (!is.null(version)) {
    bytes <- if (is.raw(version)) version else charToRaw(version)
    writeBin(bytes, file.path(root, "share", "version"))
  }
  program
}

# Mock the lookups. `which` maps program names to paths, `env` maps
# environment variables to values, and `packages` maps package names to
# versions. Names that are absent are not found.
local_tools <- function(which = list(), env = list(), packages = list(),
                        editors = character(), env_frame = parent.frame()) {
  local_mocked_bindings(
    tool_which = function(name) if (is.null(which[[name]])) "" else which[[name]],
    tool_env = function(name) if (is.null(env[[name]])) "" else env[[name]],
    package_version_text = function(pkg) if (is.null(packages[[pkg]])) "" else packages[[pkg]],
    editor_quarto_paths = function(os = tool_os()) editors,
    .env = env_frame
  )
}
