-- Shortcodes that read the `supplement` map from _supplement.yml.

-- The node at `supplement.<keys...>`, or nil when it is unset.
local function node_at(meta, ...)
  local node = meta["supplement"]
  for _, key in ipairs({ ... }) do
    if type(node) ~= "table" then
      return nil
    end
    node = node[key]
  end
  return node
end

-- The text of the value at `supplement.<keys...>`, or "" when it is unset.
local function value(meta, ...)
  local node = node_at(meta, ...)
  if node == nil then
    return ""
  end
  return pandoc.utils.stringify(node)
end

-- The DOI without a leading "doi:" (and the spaces after it) or
-- "http(s)://" plus "doi.org/", "dx.doi.org/", or "www.doi.org/", in any
-- letter case.
local function bare_doi(id)
  local lower = id:lower()
  local rest = lower:match("^doi:%s*()")
  if rest ~= nil then
    return id:sub(rest)
  end
  for _, scheme in ipairs({ "http://", "https://" }) do
    for _, host in ipairs({ "doi.org/", "dx.doi.org/", "www.doi.org/" }) do
      local prefix = scheme .. host
      if lower:sub(1, #prefix) == prefix then
        return id:sub(#prefix + 1)
      end
    end
  end
  return id
end

-- Quarto replaces the global `error` with a function that only prints a
-- message, so the render would go on. `assert` still raises an error,
-- which stops the render.
local function stop(message)
  assert(false, message)
end

-- The DOI in `supplement.zenodo.<key>` without its prefix, or "" when the
-- value is empty. A value that supplement::write_citation() refuses stops
-- the render: a list, a map, or true or false, or a value that is not
-- then "10.", four to nine digits, "/", and a suffix with no spaces. This
-- is the rule of bare_doi() in R/supplement-yml.R.
local function checked_doi(meta, key)
  local field = "supplement.zenodo." .. key
  local node = node_at(meta, "zenodo", key)
  local kind = pandoc.utils.type(node)
  local text
  if node == nil then
    text = ""
  elseif kind == "Inlines" or kind == "Blocks" then
    text = pandoc.utils.stringify(node)
  elseif (kind == "List" or kind == "table") and next(node) == nil then
    text = ""
  else
    stop("supplement-doi: " .. field .. " in _supplement.yml must be one DOI in quotes, not a list, a map, or true or false")
  end
  if text == "" then
    return ""
  end
  local id = bare_doi(text)
  local registrant, suffix = id:match("^10%.(%d+)/(.+)$")
  if registrant == nil or #registrant < 4 or #registrant > 9 or suffix:find("%s") then
    stop("supplement-doi: " .. field .. " in _supplement.yml is not a DOI: '" .. text .. "'."
      .. " Write it as 10.5281/zenodo.1234567.")
  end
  return id
end

-- The DOI badge links to the version DOI. Before Zenodo mints one, it links
-- to the concept DOI, and with neither it shows nothing. Both values are
-- checked, so a bad concept DOI stops the render even while the badge shows
-- the version DOI.
local function doi(args, kwargs, meta)
  local version_id = checked_doi(meta, "version-doi")
  local concept_id = checked_doi(meta, "concept-doi")
  local id = version_id ~= "" and version_id or concept_id
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

-- Common SPDX license ids as SPDX spells them, with a readable name, keyed
-- by the id in lowercase, because SPDX ids do not depend on letter case.
local listed_licenses = {
  ["mit"] = { id = "MIT", name = "MIT" },
  ["apache-2.0"] = { id = "Apache-2.0", name = "Apache 2.0" },
  ["bsd-3-clause"] = { id = "BSD-3-Clause", name = "BSD 3-Clause" },
  ["gpl-3.0-only"] = { id = "GPL-3.0-only", name = "GPL 3.0 only" },
  ["gpl-3.0-or-later"] = { id = "GPL-3.0-or-later", name = "GPL 3.0 or later" },
  ["cc-by-4.0"] = { id = "CC-BY-4.0", name = "CC BY 4.0" },
  ["cc-by-sa-4.0"] = { id = "CC-BY-SA-4.0", name = "CC BY-SA 4.0" },
  ["cc0-1.0"] = { id = "CC0-1.0", name = "CC0 1.0" },
}

-- TRUE for the shape of an SPDX short identifier: letters or digits, then
-- groups of one "." or "-" and more letters or digits, and at most one "+"
-- at the end. This is the rule of license_id() in R/supplement-yml.R.
local function is_license_id(id)
  local body = id:match("^(.*)%+$") or id
  return body:match("^[A-Za-z0-9.-]+$") ~= nil
    and body:match("^[.-]") == nil
    and body:match("[.-]$") == nil
    and body:find("[.-][.-]") == nil
end

-- The text of a metadata value that must be one plain word, such as a
-- license id: "" for an unset or empty value or an empty list or map, and
-- nil for any other value that is not a single run of text. Quarto reads
-- metadata as Markdown, so `CC BY 4.0`, `*MIT*`, and `` `MIT` `` arrive
-- as several elements or as a format, and a list, a map, or `true` arrives
-- as a Lua table or value.
local function plain_text(node)
  if node == nil then
    return ""
  end
  local kind = pandoc.utils.type(node)
  if kind == "Inlines" then
    if #node == 0 then
      return ""
    elseif #node == 1 and node[1].t == "Str" then
      return node[1].text
    end
    return nil
  elseif (kind == "List" or kind == "table") and next(node) == nil then
    return ""
  end
  return nil
end

-- `{{< supplement-license code >}}` or `{{< supplement-license content >}}`
-- shows the license in `supplement.license.code` or
-- `supplement.license.content`: the readable name of a listed id, any other
-- id as written, and nothing for an empty value. The name links to the
-- id's page at spdx.org, with the SPDX spelling of a listed id. The page
-- of an id that SPDX does not list does not exist. A value that
-- supplement::write_citation() refuses stops the render, so the footer
-- never shows a license that CITATION.cff does not hold.
local function license(args, kwargs, meta)
  local key = #args == 1 and pandoc.utils.stringify(args[1]) or ""
  if key ~= "code" and key ~= "content" then
    stop("supplement-license: give one argument, code or content, as in {{< supplement-license code >}}")
  end
  local field = "supplement.license." .. key
  local text = plain_text(node_at(meta, "license", key))
  if text == nil then
    stop("supplement-license: " .. field .. " in _supplement.yml must be one SPDX license id, such as \"CC-BY-4.0\","
      .. " in quotes. It is a list, a map, true or false, or text with spaces or Markdown: '"
      .. pandoc.utils.stringify(node_at(meta, "license", key)) .. "'")
  end
  local id = as_written(text, quarto.project.offset or ".")
  if id == "" then
    return pandoc.Inlines({})
  end
  if not is_license_id(id) then
    stop("supplement-license: " .. field .. " in _supplement.yml is not an SPDX license id: '" .. id .. "'."
      .. " Write letters and digits, with one . or - between groups and at most one + at the end, such as CC-BY-4.0."
      .. " Quarto reads -- as a dash and ... as one character.")
  end
  local listed = listed_licenses[id:lower()] or { id = id, name = id }
  return pandoc.Link(pandoc.Inlines(listed.name), "https://spdx.org/licenses/" .. listed.id .. ".html")
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
