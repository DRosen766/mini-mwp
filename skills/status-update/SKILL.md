---
name: status-update
description: Run the STATUS.md update protocol — read STATUS.md at session start, pick from Next up, move items between Now / Next up / Blocked / Done as work progresses, and append a dated one-liner to Activity log. Use whenever STATUS.md is touched — session start, picking work, declaring a stage done, or surfacing a new task discovered mid-session.
---

# status-update

`STATUS.md` is the project's **live ticker** — single source of truth for "where are we." This skill walks the standard update protocol so the file stays trustworthy across sessions.

If the project has no `STATUS.md` at the repo root, surface that to the user before doing other work. Don't invent one silently.

## Sections

`STATUS.md` carries five sections, in this order:

- **Now** — at most one item. If multiple things look in-flight, the others belong in Blocked or should be re-sequenced. Resist the urge to widen Now.
- **Next up** — priority-ordered. The top item is what the agent picks by default.
- **Blocked** — what's stuck, with a one-line "why blocked / what unblocks" note.
- **Done** — recent shipped work, ~10–15 items. Trim the oldest when this list grows past that.
- **Activity log** — append-only, dated, terse. The audit trail.

## Session start

1. Read `STATUS.md`.
2. Identify the top item in **Next up** unless the user has directed otherwise.
3. Surface what you intend to work on before starting — the user gets to redirect cheaply at this point.

## During work

- Move the chosen item from **Next up** to **Now**.
- If a blocker appears, move it to **Blocked** with the unblocker named.
- Work discovered mid-session that isn't trivially in-scope goes to **Next up** at the appropriate priority. Do not silently expand Now.

## At the end of work

- Move the completed item to **Done** with the ship date (`YYYY-MM-DD`).
- Append one line to **Activity log**: `- YYYY-MM-DD: <terse summary>`.
- If **Done** has grown past ~15 items, trim the oldest.

## Date discipline

All dates are absolute (`2026-05-18`), never relative ("today", "yesterday"). The point of the log is to remain interpretable months later — relative dates rot.

## Pointer mode

Once a project's open work has moved to a real issue tracker (Linear, GitHub Issues, etc.), `STATUS.md` shrinks to a pointer at that tracker plus any items that haven't been filed as issues. Don't double-track. If `STATUS.md` already looks like a pointer doc, follow the pointer rather than treating the (now-thin) file as authoritative.

## What this skill does NOT do

- It doesn't decide what work to do — only how to record where it stands.
- It doesn't write commit messages, changelogs, or release notes. Activity log is a one-line ledger, not a substitute for those.
- It doesn't touch `CLAUDE.md`, `ARCHITECTURE_PLAN.md`, or `RESUME.md`. Those have separate roles (see the methodology's `file-roles.md`).
