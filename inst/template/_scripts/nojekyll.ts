// Post-render script, run by Quarto itself (no R needed).
//
// GitHub Pages runs Jekyll on the published folder unless it holds a
// `.nojekyll` file. A Quarto render does not write one, so this script does.

const projectDir = Deno.env.get("QUARTO_PROJECT_DIR") ?? ".";
const outputDir = Deno.env.get("QUARTO_PROJECT_OUTPUT_DIR");

if (outputDir) {
  const dir = outputDir.startsWith("/") ? outputDir : `${projectDir}/${outputDir}`;
  Deno.writeTextFileSync(`${dir}/.nojekyll`, "");
}
