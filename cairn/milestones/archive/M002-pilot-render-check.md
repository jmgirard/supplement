# M002: Pilot render on the data machine and data-free rebuild

**Status:** done (2026-10-18, PR #2 https://github.com/jmgirard/supplement/pull/2)

**Goal:** Show that the pilot site, after one full render on the machine that holds the fits and private data, rebuilds from a fresh clone with no data and keeps the navbar on every report page.

**Outcome:** The user ran one full `quarto render` on the Windows data machine (pilot dddad4a on `freeze-layout`, not merged; origin `main` still 54684dc). `_freeze/analyses/` holds stored output for all 5 reports. A fresh clone on this Mac with `data/*.csv` deleted rendered with exit 0, left `_freeze/` unchanged, and gave every report page the navbar and links to the other 4, with one theme file. Every printed number matches v1.1.0. The 27 posterior predictive check figures changed, because `pp_check` draws have no seed. The user reported no data-machine problems. `cairn/references/pilot-port.md` lists 259 changed paths and problems P1 to P11.

**Decisions:** none.

**Review:** one Opus diff-bug reviewer, 7 findings. Fixed 4 in the note and work log: unseeded figures (P9), machine-dependent theme file name (P10), a wrong backslash claim, and an incomplete number check. Follow-up 1: site search now indexes the demographics page (P11, to the "template extraction" row). Noted 1: the data-free build drops `docs/data/` (already P8). Rejected 1: the uncommitted review records (false). The "freeze-layout pilot port" candidate row graduated.
