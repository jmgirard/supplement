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

return {
  ["supplement-doi"] = doi,
  ["supplement-download"] = download,
}
