---
name: next
description: Pick the next task from the current phase and open a worktree for it. Use when the user says "/next" or "next task" or "what's next" — the skill enforces the task-pickup discipline and the worktree-first gate from the methodology.
---

# next

Pick the next task, open a worktree, and report what you're about to do. This skill is the operational entry point for starting work — it enforces the sequencing defined in `mini-mwp/methodology/task-pickup.md` and the worktree-first gate from `mini-mwp/methodology/workflow-worktrees.md`.

The deliverables every run produces:

1. A chosen task (from the current phase's plan).
2. A worktree, created via `EnterWorktree` and switched into, ready for work.
3. A short message to the user: what was picked, why, and the worktree path.

---

## Steps

### 1. Read the methodology

Read these two files (relative to the mini-mwp submodule root) before doing anything else:

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

### 5. Open a worktree — HARD GATE

**This is a hard gate. No reading source, no planning, no implementation, no file edits until the worktree exists and the session is inside it.**

Use the `EnterWorktree` tool to create and switch into a worktree:

```
EnterWorktree({ name: "<short-kebab-slug-of-task>" })
```

This is **not optional**. Do not use `git worktree add` manually — the `EnterWorktree` tool is what actually switches the session's working directory. Manual `cd` after `git worktree add` does not persist across tool calls and is the reason worktrees get skipped in practice.

**Verify you are in the worktree** after calling `EnterWorktree` — run `pwd` and confirm the path contains the worktree slug. If `EnterWorktree` fails, stop and report the error. Do not proceed with work in the main checkout as a fallback.

### 6. Hand off to the owning persona (if the project has personas)

Per `mini-mwp/methodology/delegation.md`, the main agent is a router, not the default executor. If the project has `.claude/agents/` and a routing config, hand stage execution to the team's lead before doing implementation work yourself.

Determine the owning team from the plan doc / issue label / stage title (see delegation.md for the full rule), then invoke the lead:

```
Agent({
  subagent_type: "<lead-persona-name>",
  description: "<short — picked-up task>",
  prompt: <self-contained brief — stage goal, plan-doc path, prior outputs, acceptance criteria, branch name, expected artifacts, specialist allocation if any, constraints>
})
```

The lead executes inside the worktree the main agent just opened. Sub-agents may further delegate one level (lead → sub-agent); no chains beyond that. See `delegation.md` for the brief template.

**Fallback:** if the project has no `.claude/agents/` or no team signal can be derived, the main agent does the work directly. Delegation is opt-in per project.

### 7. Report to the user

Print a short summary:

```
Picked: <task title> (#<issue> if applicable)
Phase: docs/plans/000N_<phase>.md
Worktree: <pwd output from step 5>
Branch: <branch name>
Owning team: <team or "n/a — direct execution">
Lead invoked: <lead persona or "n/a">
```

Then continue — either as the orchestrating main agent (delegated path) or with direct implementation (fallback path).

---

## What this skill does NOT do

- Implement the task beyond opening the worktree — implementation follows immediately but is not part of the skill's contract.
- Switch phases without asking (unless there's only one candidate).
- Skip the worktree for "small" changes — the gate applies to everything, including one-line fixes.
- Fall back to the main checkout if worktree creation fails — it stops and reports instead.
