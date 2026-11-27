# M082: Link the contact email on new sites

**Status:** done (2026-11-27, PR #83 https://github.com/jmgirard/supplement/pull/83)

**Goal:** The template's contact value shows its email address as a mailto: link, and the site guide says how to write one.

**Outcome:** `inst/template/_supplement.yml` sets `contact: "Your Name, Your Institution. <you@example.edu>"` with a comment line above it; Pandoc's autolink turns `<addr>` in a `{{< meta >}}` value into `<a href="mailto:addr" class="email">`, while a bare address stays plain text (Quarto 1.11.9). `inst/template/GUIDE.md` (paper-facts section) says so. `R/check-supplement.R` adds `former_placeholders` (keyed by field; `contact` holds `Your Name, Your Institution. Your email address.`), which `placeholder_values()` also compares through `same_text()`, so sites that kept the old placeholder still get the `placeholder` row; `?check_supplement` and `cairn/DESIGN.md` name the exception. `fill_placeholders()` in `helper-files.R` matches the new value. `.github/scripts/build-demo.R` writes the demo address as `<m.rivera@example.org>`. Tests: "the home page shows the template's contact address as an email link" (test-shortcodes.R, pins the template's literal value, so a later change to it fails a test) and "the template's earlier contact value still counts" (test-check-supplement.R, exact and spaced values). NEWS.md tells older sites to put the address between `<` and `>` by hand.

**Decisions:** none. At the plan gate the user chose the template route over a shortcode that links bare addresses (each site holds its own `supplement.lua` and `index.qmd`, so a shortcode reaches no existing site without hand edits) and the `<addr>` form over `[addr](mailto:addr)`.

**Review:** Full criteria audit at plan (7 findings, all taken). Claim audit: 16 claims, 2 code comments corrected. One four-lens pass, 20 findings: 6 fix-now lines (help page and DESIGN.md now name the earlier contact value, a roxygen wrap), 13 rejected, 1 noted, 0 follow-ups. Local suite 0 failures; `devtools::check()` 0/0/0; R-CMD-check green on three systems. No rows graduated or unparked; no lessons captured or marked; M079 row pruned.
