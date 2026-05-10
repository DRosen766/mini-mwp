# Cross-project learnings

A running, project-agnostic ledger of meta-lessons. Each entry is an abstracted principle plus the kind of symptom that surfaces it.

> Add to this folder at the end of any project (or any especially gnarly debugging session). Keep entries short and generalized — link out to project-specific gotchas in the originating repo's `CLAUDE.md` (or this repo's `conventions/<project>.md`).

## How to use this in a new project

1. At project kickoff, skim the entries here and surface anything obviously relevant to the stack you're choosing.
2. The new project's `CLAUDE.md` should link here: *"Cross-project lessons live at `~/mini-mwp/learnings/`."*
3. As the new project surfaces lessons, decide each time: project-specific (→ `CLAUDE.md` for the project) or generalizable (→ this folder).
4. Periodically prune: lessons that have been internalized into your default workflow can be retired.

## Pending migration

The Task Tracker App project carries its own `CLAUDE_PROJECT_LEARNINGS.md` at `~/Documents/Claude/Projects/TastTrackerApp_parent/CLAUDE_PROJECT_LEARNINGS.md` (path unchanged — that's the project's own location) with sections on process discipline, naming and namespacing, hosted/managed platform realities, spawn environments and PATH, CI/CD signing & distribution, database/auth/RLS, verification and smoke-testing, and architecture choices that paid off. Plan is to migrate that content here once it stops being actively edited from inside the project.
