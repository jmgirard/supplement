-- Post-render script, run by Quarto through Pandoc (no R needed).
--
-- GitHub Pages runs Jekyll on the published folder unless it holds a
-- `.nojekyll` file. A Quarto render does not write one, so this script does.
--
-- Quarto passes the output folder as an absolute path (on Windows, for
-- example `C:\...\docs`), so the path is used as given.

local output_dir = os.getenv("QUARTO_PROJECT_OUTPUT_DIR")

if output_dir and output_dir ~= "" then
  local file = assert(io.open(output_dir .. "/.nojekyll", "wb"))
  assert(file:close())
end
