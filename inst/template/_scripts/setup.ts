// Pre-render script, run by Quarto itself (no R needed).
//
// `quarto use template` does not copy dotfiles or README.md, so the template
// ships them under other names. This script gives them their real names.
//
// When `.gitignore` already exists (Quarto writes one in a git repository
// before this script runs), the template's lines that it lacks are appended,
// so the ignore rules for fitted models are never lost. An existing
// README.md is kept as it is. Either way the template copy is removed.

const projectDir = Deno.env.get("QUARTO_PROJECT_DIR") ?? ".";

function exists(path: string): boolean {
  try {
    Deno.statSync(path);
    return true;
  } catch {
    return false;
  }
}

function mergeLines(src: string, dest: string) {
  const current = Deno.readTextFileSync(dest);
  const have = new Set(current.split(/\r?\n/));
  const missing = Deno.readTextFileSync(src)
    .split(/\r?\n/)
    .filter((line) => line.trim() !== "" && !have.has(line));
  if (missing.length > 0) {
    const sep = current.endsWith("\n") || current === "" ? "" : "\n";
    Deno.writeTextFileSync(dest, current + sep + missing.join("\n") + "\n");
  }
}

const files: [string, string, boolean][] = [
  ["_gitignore", ".gitignore", true],
  ["_README.md", "README.md", false],
];

for (const [from, to, merge] of files) {
  const src = `${projectDir}/${from}`;
  const dest = `${projectDir}/${to}`;
  if (!exists(src)) continue;
  if (!exists(dest)) {
    Deno.renameSync(src, dest);
    continue;
  }
  if (merge) mergeLines(src, dest);
  Deno.removeSync(src);
}
