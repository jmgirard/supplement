// Post-render script, run by Quarto itself (no R needed).
//
// GitHub Pages runs Jekyll on the published folder unless it holds a
// `.nojekyll` file. A Quarto render does not write one, so this script does.
//
// Quarto passes the output folder as an absolute path (on Windows, for
// example `C:\...\docs`), so the path is used as given.

const outputDir = Deno.env.get("QUARTO_PROJECT_OUTPUT_DIR");

if (outputDir) {
  Deno.writeTextFileSync(`${outputDir}/.nojekyll`, "");
}
