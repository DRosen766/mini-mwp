# mini-mwp — Project Instructions for Claude

This repo is a **context-storage repo**, not a product. It holds methodology, templates, and conventions I use across my personal development projects.

## What you should do here

- **Read before you write.** When I ask you to add to this repo, first check the relevant folder (`methodology/`, `conventions/`, `templates/`, `learnings/`, `skills/`, `scripts/`) for existing content so you don't duplicate or contradict it.
- **Distinguish the six kinds of content.**
  - `methodology/` = how I structure work *across* projects (process, file roles, workflow patterns).
  - `conventions/` = project-specific rules and gotchas, organized by project name.
  - `templates/` = reusable starter files I drop into new projects.
  - `learnings/` = cross-project meta-lessons distilled from incidents.
  - `skills/` = repo-agnostic Claude skills that operationalize methodology pieces. Consumed by product repos via submodule + symlink into `.claude/skills/`. Each skill must (a) cite the methodology file it encodes, (b) avoid project-specific names/paths/stacks, (c) be markdown instructions only — no executable scripts inside `skills/`.
  - `scripts/` = deterministic, non-AI shell utilities that operate on a *product* repo (where mini-mwp is mounted as a submodule). Each script must (a) run from the product repo root and refuse to run from inside mini-mwp itself, (b) be idempotent so re-running after a submodule update is the standard upgrade path, (c) fail loudly rather than guess when it would clobber user-owned files. Scripts here do not modify or assume things about mini-mwp itself.
- **Keep entries short.** Methodology, convention, and learning docs read like a cheat-sheet, not a textbook. One paragraph per principle, with the symptom or trigger that surfaces it.
- **Don't invent content.** If I haven't articulated a methodology decision, don't write one. Stub it with a `TBD` and ask.

## What you should NOT do

- Do not add product code, build configs, dependency manifests, or anything that implies this repo runs.
- Do not add status trackers, task logs, or other live-state files. Those belong inside the projects this repo informs, not here.
- Do not invent methodology I haven't said out loud. Ask.

## Tone and format

Match the existing files: prose-first, lists only when the content is genuinely list-shaped. Bold the rule, then explain. Quote the symptom or trigger that surfaces it.
