# Lessons

Durable repo lessons — build quirks, testing tricks, gotchas worth
remembering next time — captured at milestone end and surfaced at plan time.
Not status, not decisions: a lesson is a reusable "how this repo actually
behaves" note. Cross-cutting *choices* still go to `DECISIONS.md`.

One line per lesson: `- YYYY-MM-DD (M<NNN>): <lesson>`. Two caps: 50 lines
and 20,000 bytes; over either, retire or prune before adding. Corrected in
place when proven false (never append a correction).

- 2026-10-18 (M001): `quarto render <file>` ignores `freeze: true` and runs that file's code, and it writes that file's stored output to `_freeze/` (checked M008). Only a full project render reuses `_freeze/`. gt writes random table ids, so each re-render shows a diff with no change in results.
- 2026-10-18 (M002): Matching printed numbers do not prove a re-render reproduces a report. Unseeded random draws, such as `pp_check(ndraws = 100)`, redraw figures each time, and the Bootstrap theme file name differs between machines. Compare figure hashes as well as numbers.
- 2026-10-18 (M003): `quarto use template` skips dotfiles, README.md, and LICENSE, and in a git repository Quarto writes its own `.gitignore` before pre-render scripts run. Template setup must merge into an existing `.gitignore`, not replace or skip it.
- 2026-10-18 (M003): git ignore rules are case-sensitive on Linux, so match file extensions with bracket patterns such as `*.[Rr][Dd][Ss]`. A trailing `!docs/` undoes an earlier `docs/` rule but not `docs/*`.
- 2026-10-18 (M004): In Quarto 1.10 Lua filters and shortcodes, the global `error()` only prints a message and returns, so stop a render with `assert(false, msg)`. Quarto also rewrites any metadata string that names an existing path to be relative to the page, and parses metadata strings as Markdown, so file names with `--` or `_x_` change before Lua sees them.
- 2026-10-18 (M005): R's yaml package reads YAML 1.1: unquoted `No` is FALSE, `1.10` is 1.1, `0755` is 493, `.na` is a logical NA, and a sequence of scalars, `[x]` included, becomes a plain vector. Pass `handlers = list(seq = function(x) as.list(x))` to keep sequences as lists, and check `is.character()` before using a value as text. `yaml::as.yaml()` double-quotes a string that carries the attribute `quoted = TRUE`.
- 2026-10-18 (M006): `file.copy()` from an unreadable source creates an empty target and returns FALSE, so cleanup code must record the target before the copy. On macOS `file.exists("file/")` is FALSE for an existing file, so drop trailing separators before checks. `list.files(recursive = TRUE)` without `all.files` skips hidden files and the contents of hidden folders.
- 2026-10-18 (M005): `Sys.readlink()` returns NA for a path that does not exist, and `nzchar(NA)` is TRUE, so test `!is.na(link) && nzchar(link)` to find a link.
- 2026-10-18 (M007): cli drops the spaces at the start of each message line, so an error that shows YAML to add by hand needs a base R condition with a `cli::format_message()` header. R only warns when a write fills the disk ("Problem closing connection"), so a write check must catch warnings or compare the file size.
- 2026-10-18 (M008): `regmatches()` and `sub()` with `useBytes = TRUE` return strings marked "bytes", and `file.path()` and `sprintf()` then stop with an unclassed error, so read text as UTF-8 (repair bad bytes with `iconv(x, "UTF-8", "UTF-8", sub = "byte")`) and match without `useBytes`. `Sys.glob()` over a full path reads `[`, `*`, and `?` in folder names as patterns, so list the folder instead. On macOS `file.exists()` ignores letter case, while GitHub Pages does not.
- 2026-10-18 (M008): `yaml::read_yaml()` warns on a valid file with no final line break, so a `tryCatch()` that treats warnings as failure rejects good files; parse the text with `yaml.load()` inside `suppressWarnings()`. A block-scalar value keeps its final line break only when a key follows it.
- 2026-10-18 (M007): With `perl = TRUE`, `$` also matches before a final `\n`, so anchor names with `\z`. PCRE needs `(*UCP)` for `\S` to skip Unicode spaces, and `\x{2028}` in a pattern fails on an ASCII-only string. A valid UTF-8 string marked "bytes" is not `identical()` to the same text read by the yaml package.
