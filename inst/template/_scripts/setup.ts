// Pre-render script, run by Quarto itself (no R needed).
//
// `quarto use template` does not copy dotfiles or README.md, so the template
// ships them under other names. This script gives them their real names.
//
// When `.gitignore` already exists (Quarto writes one in a git repository
// before this script runs), the template's lines that it lacks are appended,
// so the ignore rules for fitted models are never lost. The file then ends
// with `!docs/` and `!_freeze/`, because in git the last matching rule wins,
// so an earlier `docs/` rule cannot keep the site out of git. An existing
// README.md is kept as it is, and the template's README becomes
// SUPPLEMENT.md instead. If SUPPLEMENT.md also exists, the template's
// README is removed and no guide is written.

const projectDir = Deno.env.get("QUARTO_PROJECT_DIR") ?? ".";

function exists(path: string): boolean {
  try {
    Deno.statSync(path);
    return true;
  } catch {
    return false;
  }
}

const keepLast = ["!docs/", "!_freeze/"];

function mergeLines(src: string, dest: string) {
  const current = Deno.readTextFileSync(dest);
  const have = new Set(current.split(/\r?\n/));
  const add = Deno.readTextFileSync(src)
    .split(/\r?\n/)
    .filter((line) => line.trim() !== "" && !have.has(line) && !keepLast.includes(line));

  const lines = current.split(/\r?\n/).concat(add).filter((line) => line.trim() !== "");
  const tail = lines.slice(-keepLast.length);
  if (tail.join("\n") !== keepLast.join("\n")) add.push(...keepLast);

  if (add.length > 0) {
    const sep = current.endsWith("\n") || current === "" ? "" : "\n";
    Deno.writeTextFileSync(dest, current + sep + add.join("\n") + "\n");
  }
}

const gitignoreSrc = `${projectDir}/_gitignore`;
const gitignore = `${projectDir}/.gitignore`;
if (exists(gitignoreSrc)) {
  if (exists(gitignore)) {
    mergeLines(gitignoreSrc, gitignore);
    Deno.removeSync(gitignoreSrc);
  } else {
    Deno.renameSync(gitignoreSrc, gitignore);
  }
}

const readmeSrc = `${projectDir}/_README.md`;
if (exists(readmeSrc)) {
  const readme = `${projectDir}/README.md`;
  const fallback = `${projectDir}/SUPPLEMENT.md`;
  if (!exists(readme)) {
    Deno.renameSync(readmeSrc, readme);
  } else if (!exists(fallback)) {
    Deno.renameSync(readmeSrc, fallback);
  } else {
    Deno.removeSync(readmeSrc);
  }
}
