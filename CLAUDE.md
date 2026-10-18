## Project tracking (cairn)

This repo uses the cairn plugin. Before you act on a request, classify it and
route it. The tracking rulebook loads only after a cairn skill starts. Work
started in plain conversation skips the work tiers and the git model.

- **Trivial** (typo, comment, tracking edit): in owner mode, commit to the
  default branch. In guest mode, leave the edit on disk (`cairn/` files only).
- **Look into a GitHub issue**: invoke `/milestone` with the issue number
  or URL.
- **User-visible bug**: invoke `/hotfix`.
- **New work, a design decision, or more than one sitting**: invoke
  `/milestone-plan`. If a hotfix or trivial route fits, it offers that
  first. Otherwise one question set comes, and the run goes on to the merge
  question. Typed `/milestone-implement` or `/milestone-review` resumes it.
- **Status, "what's next", or unsure which tier**: invoke `/milestone`.
- **Never implement code on the default branch** outside a milestone or
  hotfix branch. Only the user's explicit approval at the merge question
  lets work reach it. For a trivial edit, the user's request or the tier
  chip is the approval.

If the request is not trivial, invoke the skill first. The skill loads the
full rulebook (the plugin's `skills/shared/tracking-rules.md`) and its
conduct. Do not rebuild the rules here from memory. All project state lives
under `cairn/`.
Architecture → DESIGN · Status → ROADMAP · Tasks → milestone files.
Decisions → DECISIONS · Lessons → LESSONS · History → archive + git.
Never record status or TODOs in this file. Claude's persistent memory never
holds project state. The `cairn/` files win any conflict.
