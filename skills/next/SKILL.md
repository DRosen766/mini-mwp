---
name: next
description: Pick the next task from the current phase and open a worktree for it. Use when the user says "/next" or "next task" or "what's next" — the skill enforces the task-pickup discipline and the worktree-first gate from the methodology.
---

# next

Pick the next task, open a worktree, and report what you're about to do. This skill is the operational entry point for starting work — it enforces the sequencing defined in `mini-mwp/methodology/task-pickup.md` and the worktree-first gate from `mini-mwp/methodology/workflow-worktrees.md`.

The deliverables every run produces:

1. A chosen task (from the current phase's plan).
2. A worktree, created and `cd`-ed into, ready for work.
3. A short message to the user: what was picked, why, and the worktree path.

---

## Steps

### 1. Read the methodology

Read these two files (relative to the repo root) before doing anything else:

- `mini-mwp/methodology/task-pickup.md` — the rules for choosing what to work on.
- `mini-mwp/methodology/workflow-worktrees.md` — the worktree-first gate and PR workflow.

If the repo doesn't have a `mini-mwp/` submodule, look for equivalent guidance in `CLAUDE.md`. If neither exists, tell the user and stop.

### 2. Read STATUS.md

```bash
cat STATUS.md
```

Find the **Current phase** field. It points at the active plan doc (e.g. `docs/plans/0009_completion_ux.md`).

- If the current phase has no open stages left, this is a **phase handoff** — follow the two-step process in `task-pickup.md` ("Phase handoff is a two-step pickup"). Ask the user which phase to start next if the priority isn't obvious.
- If there is no `STATUS.md`, tell the user and stop.

### 3. Read the plan doc

```bash
cat docs/plans/000N_<phase>.md
```

Find the next open stage or issue using the plan's own sequencing rules. Apply the pickup discipline:

- Pick from the current phase. Don't jump to a different plan.
- Drain before switching. If stages remain, pick one — don't switch phases.
- If all remaining stages are blocked, report the blockers and ask the user.

### 4. Update STATUS.md

Move the chosen task into **Now** in STATUS.md if it isn't already there. This happens in the main checkout (it's a status update, not a code change).

### 5. Open a worktree

**This is a hard gate — no work happens without it.**

```bash
SLUG=<short-kebab-slug>
git worktree add ../<repo-wt-prefix>-$SLUG -b <branch-name> main
cd ../<repo-wt-prefix>-$SLUG
```

Follow the project's worktree naming convention if one exists (check `CLAUDE.md`). Default to `<repo-name>-wt-<slug>` as a sibling of the main checkout.

Do not read source files, do not plan the implementation, do not touch anything until the worktree exists and you have `cd`-ed into it.

### 6. Report to the user

Print a short summary:

```
Picked: <task title> (#<issue> if applicable)
Phase: docs/plans/000N_<phase>.md
Worktree: /absolute/path/to/<repo-wt-prefix>-<slug>
Branch: <branch-name>
```

Then begin working on the task inside the worktree.

---

## What this skill does NOT do

- Implement the task beyond opening the worktree — implementation follows immediately but is not part of the skill's contract.
- Switch phases without asking (unless there's only one candidate).
- Skip the worktree for "small" changes — the gate applies to everything, including one-line fixes.
- Create the worktree inside the main checkout — worktrees are always siblings.
