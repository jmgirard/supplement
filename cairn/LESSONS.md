# Lessons

Durable repo lessons — build quirks, testing tricks, gotchas worth
remembering next time — captured at milestone end and surfaced at plan time.
Not status, not decisions: a lesson is a reusable "how this repo actually
behaves" note. Cross-cutting *choices* still go to `DECISIONS.md`.

One line per lesson: `- YYYY-MM-DD (M<NNN>): <lesson>`. Two caps: 50 lines
and 20,000 bytes; over either, retire or prune before adding. Corrected in
place when proven false (never append a correction).

- 2026-10-18 (M001): `quarto render <file>` ignores `freeze: true` and runs that file's code. Only a full project render reuses `_freeze/`. gt writes random table ids, so each re-render shows a diff with no change in results.
- 2026-10-18 (M002): Matching printed numbers do not prove a re-render reproduces a report. Unseeded random draws, such as `pp_check(ndraws = 100)`, redraw figures each time, and the Bootstrap theme file name differs between machines. Compare figure hashes as well as numbers.
