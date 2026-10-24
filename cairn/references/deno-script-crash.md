# The Deno crash in Quarto project scripts on macOS (M048)

**Provenance.** Ingested 2026-10-24 by M048. The first source is the macOS crash reports on the maintainer's Mac (`~/Library/Logs/DiagnosticReports/deno-*.ips`). The second is the log of GitHub Actions run 39891081546 (attempt 1, `macos-latest` job). The rest are stress loops run on 2026-10-23 and a read of Quarto 1.10.19's `quarto.js` and its bundled `deno` binary with `lldb`.
Pagination: —.
Extraction: first-hand record, nothing to re-verify against — observed 2026-10-24.

**Scope.** This page records what is known about the crash that M048 avoids by running the template's project scripts in Lua (D-023). It is the evidence for an upstream report, not a fix. It is a reference, not an authority. Status lives in `ROADMAP.md`, decisions in `DECISIONS.md`, and architecture in `DESIGN.md`.

**Evidence snapshot.**

- 18 crash reports, `deno-2026-10-18-184652.ips` to `deno-2026-10-22-224917.ips`, all from runs of this repo's tests — observed 2026-10-23.
- CI run 39891081546, attempt 1, `macos-latest` job on image `macos-26-arm64` — observed 2026-10-23.
- Quarto 1.10.19 at `/Applications/quarto` with Deno 2.7.14 (v8 14.7.173.20-rusty), macOS 27.0.1 on arm64 — observed 2026-10-23.
- The Deno v2.7.14 GitHub release lists no symbol file for any system — observed 2026-10-24.

## What happens

Quarto runs a `.ts` or `.js` project script as a child process. The command is `tools/aarch64/deno run --import-map <cache>/deno_std/run_import_map.json --allow-all --unstable-kv --unstable-ffi <script>`. `DENO_DIR` names the shared `deno_std/cache` folder in the user's Quarto cache (`denoRunHandler` and `initDenoCache` in `quarto.js`). Sometimes that child dies with a segmentation fault. Quarto then logs `[execProcess] Success: false, code: 139` at debug level and prints only `Error:`, and the render exits 1.

In CI run 39891081546, the child that crashed ran `_scripts/nojekyll.ts`. That script does one `Deno.writeTextFileSync()` call and nothing else. The test at `test-template.R:449` failed, and the same commit passed on a re-run.

## The crash reports

All 18 reports share these facts:

- The exception is `EXC_BAD_ACCESS` with `SIGSEGV` at address 0, and the program counter is 0.
- The faulting thread is a `tokio-runtime-worker` thread. The process has 20 threads.
- The first frame is the null call, in no image. The next five are at the same offsets in `deno` in every report: 29888468, 29886848, 29888192, 23717972, and 2798292.
- Each process was 0.039 to 0.100 seconds old at the crash (`captureTime` minus `procLaunch`). So each was a short project-script run and not Quarto's own process, which runs for seconds.
- The main thread was at a different place in each report.

## The crashing call

The binary is stripped. `nm` lists 666 symbols, all of them exported library symbols, and `atos` names none of the frames. At the default load address, the return address at offset 29888468 is 0x101c80fd4. The three instructions before it are `adrp x8, 16757`, `ldr x8, [x8, #0x5f8]`, and `blr x8`. So the call goes through a function pointer at 0x105df55f8, in `deno.__DATA.__data` (+ 103928). The stored value of that word in the binary is 0. A worker thread therefore called a function pointer that the process had not set yet, or had already cleared. The caller follows the call with a `dmb ish` barrier, as atomic code does.

## What did not reproduce it

These runs used the same `deno run` command line and `DENO_DIR` on the Mac on 2026-10-23:

- 400 runs of `nojekyll.ts`, one at a time, gave no failure and no crash report.
- 2,000 runs, 10 at a time, gave no failure and no crash report.
- 300 full renders of a small site with both `.ts` scripts ran 8 at a time. Those 600 script runs gave no failure and no crash report.

The crashes came during parallel test runs, which also run R, knitr, and Pandoc.

## Upstream status

quarto-dev/quarto-cli#10426 tracks this crash, and it is open. A Quarto maintainer reopened it on 2026-10-20 and wrote that macOS crash reports from Quarto's nightly CI show the cause. At start, Deno opens its cache databases on parallel threads, and SQLite's start-up code inside Deno can then race. It happens only on arm64. denoland/deno#37045 reports it for Deno 2.7.14 with the same faulting stack: address 0 on a `tokio-runtime-worker` thread, about 20 ms after start. That issue is open, and no linked fix was found — observed 2026-10-24.

That cause fits the facts above. The null call is in a worker thread soon after start. Quarto points each script's Deno at one shared `DENO_DIR`, which holds SQLite cache files (`dep_analysis_cache_v2`, `v8_code_cache_v2`, and others).

## Draft issue for quarto-dev/quarto-cli

The draft below predates the find of #10426 and duplicates it, so it was not posted.

Title: TypeScript project scripts crash with exit 139 on macOS arm64.

> **Bug description.** With Quarto 1.10.19 on macOS arm64, a `.ts` pre-render or post-render script sometimes fails. The `deno` child process that runs it dies with a segmentation fault. The render prints only `Error:` and exits 1. With `QUARTO_LOG_LEVEL=DEBUG`, the log shows `[execProcess] Success: false, code: 139` after the `deno run` line for the script. A re-run passes.
>
> We saw it on a GitHub Actions `macos-26-arm64` runner and on a Mac with macOS 27.0.1. Both times a test suite rendered many small projects in parallel. The script that crashed in CI writes one empty file with `Deno.writeTextFileSync()` and does nothing else. It did not happen on demand: 2,400 direct runs of the script and 300 parallel renders gave no crash.
>
> **Crash reports.** macOS wrote 18 crash reports (`~/Library/Logs/DiagnosticReports/deno-*.ips`) from 2026-10-18 to 2026-10-22, and all 18 match. Each is `EXC_BAD_ACCESS (SIGSEGV)` at address 0 in a `tokio-runtime-worker` thread, 40 to 100 ms after the process started. The frames are at the same offsets in the bundled Deno 2.7.14 binary: 29888468, 29886848, 29888192, 23717972, and 2798292. The instructions before the first offset are `ldr x8, [x8, #0x5f8]` and `blr x8`. That is a call through a function pointer at `__DATA.__data + 103928`, and the binary stores 0 there. We can attach a report.
>
> **Steps to reproduce.** We have no steps that work every time. On macOS arm64, give a website project `pre-render` and `post-render` TypeScript scripts. Then render it many times in parallel, for example from an R test suite with parallel test files.
>
> **Expected.** The script runs and the render succeeds.
>
> **Workaround.** Write the scripts in Lua. Quarto runs a `.lua` project script through Pandoc and starts no Deno process for it.
>
> **Versions.** Quarto 1.10.19 with Deno 2.7.14, on macOS 27.0.1 (arm64) and on the `macos-26-arm64` runner image.
