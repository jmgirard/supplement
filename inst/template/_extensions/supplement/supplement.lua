-- Shortcodes that read the `supplement` map from _supplement.yml.

-- The text of the value at `supplement.<keys...>`, or "" when it is unset.
local function value(meta, ...)
  local node = meta["supplement"]
  for _, key in ipairs({ ... }) do
    if type(node) ~= "table" then
      return ""
    end
    node = node[key]
  end
  if node == nil then
    return ""
  end
  return pandoc.utils.stringify(node)
end

-- The DOI badge links to the version DOI. Before Zenodo mints one, it links
-- to the concept DOI, and with neither it shows nothing.
local function doi(args, kwargs, meta)
  local id = value(meta, "zenodo", "version-doi")
  if id == "" then
    id = value(meta, "zenodo", "concept-doi")
  end
  if id == "" then
    return pandoc.Inlines({})
  end
  local badge = pandoc.Image({ pandoc.Str("DOI") }, "https://zenodo.org/badge/DOI/" .. id .. ".svg")
  return pandoc.Link({ badge }, "https://doi.org/" .. id)
end

local function download(args, kwargs, meta)
  local url = value(meta, "zenodo", "archive-url")
  if url == "" then
    return pandoc.Inlines({})
  end
  return pandoc.Link(pandoc.Inlines("Download the archive from Zenodo"), url)
end

-- A file size in base 1000: whole bytes below 1000, else one decimal,
-- rounded half up. The unit is chosen after rounding, so 999950 bytes
-- reads "1.0 MB" and not "1000.0 KB". Integer arithmetic keeps the
-- rounding exact.
local function format_size(bytes)
  if bytes < 1000 then
    return string.format("%d B", bytes)
  end
  local units = { "KB", "MB", "GB" }
  local divisor = 1
  for i, unit in ipairs(units) do
    divisor = divisor * 1000
    local tenths = (bytes * 10 + divisor // 2) // divisor
    if tenths < 10000 or i == #units then
      return string.format("%d.%d %s", tenths // 10, tenths % 10, unit)
    end
  end
end

local function file_size(path)
  local handle = io.open(path, "rb")
  if handle == nil then
    return nil
  end
  local size = handle:seek("end")
  handle:close()
  return size
end

local function cell(content)
  return { pandoc.Plain(content) }
end

-- Quarto replaces the global `error` with a function that only prints a
-- message, so the render would go on. `assert` still raises an error,
-- which stops the render.
local function stop(message)
  assert(false, message)
end

local function is_folder(path)
  return (pcall(pandoc.system.list_directory, path))
end

-- Opening a file needs only read access, so this works in a read-only
-- folder too.
local function exists(path)
  local handle = io.open(path, "rb")
  if handle ~= nil then
    handle:close()
    return true
  end
  return is_folder(path)
end

-- A metadata value as inlines. A folded or block YAML string arrives as
-- blocks, and a number or `true` arrives as a plain Lua value.
local function as_inlines(value)
  local kind = pandoc.utils.type(value)
  if kind == "Inlines" then
    return value
  elseif kind == "Blocks" then
    return pandoc.utils.blocks_to_inlines(value)
  end
  return pandoc.Inlines(pandoc.utils.stringify(value))
end

-- Paths in _supplement.yml are relative to the project folder. Quarto
-- rewrites every metadata value that names an existing file or folder so
-- that it is relative to the page (`data/x.csv` reaches a page in
-- `analyses/` as `../data/x.csv`, and so does a description "data"), and
-- it leaves other values as written. This undoes that rewrite.
local function as_written(text, offset)
  local prefix = offset .. "/"
  if offset ~= "." and text:sub(1, #prefix) == prefix then
    local page_dir = pandoc.path.directory(quarto.doc.input_file)
    if exists(pandoc.path.join({ page_dir, text })) then
      return text:sub(#prefix + 1)
    end
  end
  return text
end

-- Readable names for common SPDX license ids, keyed by the id in lowercase,
-- because SPDX ids do not depend on letter case.
local license_names = {
  ["mit"] = "MIT",
  ["apache-2.0"] = "Apache 2.0",
  ["bsd-3-clause"] = "BSD 3-Clause",
  ["gpl-3.0-only"] = "GPL 3.0",
  ["gpl-3.0-or-later"] = "GPL 3.0 or later",
  ["cc-by-4.0"] = "CC BY 4.0",
  ["cc-by-sa-4.0"] = "CC BY-SA 4.0",
  ["cc0-1.0"] = "CC0 1.0",
}

-- `{{< supplement-license code >}}` or `{{< supplement-license content >}}`
-- shows the license in `supplement.license.code` or
-- `supplement.license.content`: the readable name of a listed id, any other
-- id as written, and nothing for an empty value.
local function license(args, kwargs, meta)
  local key = args[1] and pandoc.utils.stringify(args[1]) or ""
  local id = as_written(value(meta, "license", key), quarto.project.offset or ".")
  if id == "" then
    return pandoc.Inlines({})
  end
  return pandoc.Inlines(license_names[id:lower()] or id)
end

-- One row per entry under `supplement.data`, with each link written
-- relative to the page that holds the table. A missing file stops the
-- render, because a site without its data must not be published.
local function data_table(args, kwargs, meta)
  local entries = meta["supplement"] and meta["supplement"]["data"]
  if type(entries) ~= "table" or #entries == 0 then
    return pandoc.Blocks({})
  end

  local root = quarto.project.directory or pandoc.path.directory(quarto.doc.input_file)
  local offset = quarto.project.offset or "."

  local rows = {}
  for _, entry in ipairs(entries) do
    local file = as_written(pandoc.utils.stringify(entry["file"] or ""), offset)
    local path = pandoc.path.join({ root, file })
    if file ~= "" and is_folder(path) then
      stop("supplement-data-table: '" .. file .. "' is a folder, not a file (listed under supplement.data in _supplement.yml)")
    end
    local size = file ~= "" and file_size(path) or nil
    if size == nil then
      stop("supplement-data-table: data file not found: '" .. file .. "' (listed under supplement.data in _supplement.yml)."
        .. " Quarto reads the value as Markdown, so characters such as * _ ^ ' -- and ... can change a file name.")
    end
    local href = offset == "." and file or (offset .. "/" .. file)
    local link = pandoc.Link(
      { pandoc.Code(pandoc.path.filename(file)) },
      href, "", pandoc.Attr("", {}, { { "download", "" } })
    )
    local description = as_inlines(entry["description"] or "")
    local text = pandoc.utils.stringify(description)
    local written = as_written(text, offset)
    if written ~= text then
      description = pandoc.Inlines(written)
    end
    table.insert(rows, { cell({ link }), cell(description), cell(format_size(size)) })
  end

  local simple = pandoc.SimpleTable(
    {},
    { pandoc.AlignDefault, pandoc.AlignDefault, pandoc.AlignRight },
    { 0, 0, 0 },
    { cell("File"), cell("Description"), cell("Size") },
    rows
  )
  return pandoc.Blocks({ pandoc.utils.from_simple_table(simple) })
end

return {
  ["supplement-doi"] = doi,
  ["supplement-download"] = download,
  ["supplement-data-table"] = data_table,
  ["supplement-license"] = license,
}
