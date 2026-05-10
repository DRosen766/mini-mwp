# File Roles

A small set of markdown files carry distinct roles. Keeping the roles separate is what lets the methodology stay lightweight — each file has one job, and updates to one don't churn the others.

## `CLAUDE.md` — stable operating manual

Project-specific conventions, gotchas, "how this thing works." Read at session start. Updated only when something **durable** changes — a new convention adopted, a new gotcha discovered, a workflow rule established. Never touched for routine state changes.

Typical contents: stack overview, repo layout, naming conventions, gotchas with symptom strings, common workflows, what's deliberately deferred.

## `STATUS.md` — live ticker

Where work-in-progress lives. Sections: **Now** / **Next up** / **Blocked** / **Done** / **Activity log**. Read at the start of every session; updated as work progresses; appended to when something ships. Single source of truth for "where are we." Done is kept to ~10–15 most recent items; older entries get trimmed.

Update protocol every session:

1. Read it.
2. Pick the top item from **Next up** unless told otherwise.
3. As work progresses, move items between sections.
4. Append a one-line entry to **Activity log** with date + terse summary.
5. New work discovered mid-session goes to **Next up** in priority order, not silently into Now.

> Once a project's open work moves to a real issue tracker, `STATUS.md` shrinks to a pointer at that tracker plus any items that haven't been filed as issues. Don't double-track.

## `ARCHITECTURE_PLAN.md` — design rationale

The "why" doc. Stack choices, data model intent, locked-in decisions, reminder/auth/distribution architecture. Read once at project kickoff and on major design questions. Doesn't churn. Annotated with notes when reality diverges from intent (e.g. "v1 design intent — canonical schema is in `migrations/`, which has since added X, dropped Y").

## `RESUME.md` — phone-readable handoff

A "what to do when you're back at your Mac" checklist. Useful when work crosses device boundaries (e.g. you're on your phone, the next step needs your laptop). Lists current state by component, what's verifiable from the phone, and what to do when you're back at the keyboard. Disposable — overwritten or retired once the handoff is done.

## How they relate

- **Stable manual** (CLAUDE.md) ⟂ **live ticker** (STATUS.md). The manual holds conventions and durable rules; the ticker holds state. Cross-reference between them, never duplicate.
- **Design rationale** (ARCHITECTURE_PLAN.md) is upstream of both — it's why decisions in the manual exist.
- **Handoff** (RESUME.md) is ephemeral and points at the other three.

## What goes where (quick test)

- "We learned that X breaks Y under Z" → `CLAUDE.md` (gotcha).
- "I just merged the X feature" → `STATUS.md` Activity log, possibly Done.
- "We decided to use Postgres instead of Firestore because…" → `ARCHITECTURE_PLAN.md` (locked-in decision).
- "When you're back at your Mac, run X then Y then Z" → `RESUME.md` (or just say it in chat).
