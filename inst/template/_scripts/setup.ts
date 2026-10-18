// Pre-render script, run by Quarto itself (no R needed).
//
// `quarto use template` does not copy dotfiles or README.md, so the template
// ships them under other names. This script gives them their real names.
// When the real file already exists, it is kept and the template copy is
// removed.

const projectDir = Deno.env.get("QUARTO_PROJECT_DIR") ?? ".";

const renames: [string, string][] = [
  ["_gitignore", ".gitignore"],
  ["_README.md", "README.md"],
];

function exists(path: string): boolean {
  try {
    Deno.statSync(path);
    return true;
  } catch {
    return false;
  }
}

for (const [from, to] of renames) {
  const src = `${projectDir}/${from}`;
  const dest = `${projectDir}/${to}`;
  if (!exists(src)) continue;
  if (exists(dest)) {
    Deno.removeSync(src);
  } else {
    Deno.renameSync(src, dest);
  }
}
