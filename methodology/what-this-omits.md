# What mini-MWP deliberately omits

Full MWP includes machinery that doesn't pay off for single-author projects. This file lists what gets dropped and why, so future-me doesn't reflexively add it back.

## One folder per stage

Full MWP: each stage lives in its own folder with a dedicated prompt file, context bundle, and output spec.

mini-MWP: numbered files in shared folders (`migrations/`, `docs/plans/`, `docs/adr/`). Stage context lives in the file itself or in cross-cutting docs (`CLAUDE.md`, `ARCHITECTURE_PLAN.md`).

**Why:** Per-stage folders are valuable when stages are reused, when prompts are versioned, or when multiple authors need to coordinate on a single stage. None of that is true for a solo project.

## One prompt file per stage

Full MWP: each stage has a dedicated prompt the agent reads to know what to do.

mini-MWP: the agent reads `STATUS.md` ("Next up") and the relevant `docs/plans/000N_*.md` if one exists. The instruction is "do the next thing in the queue" — no per-stage prompt scaffolding.

**Why:** The overhead of writing a stage prompt for each task exceeds the benefit when the agent already knows the project and reads the standing context.

## Multi-agent orchestration

Full MWP: multiple specialized agents pass work to each other (planner, executor, reviewer).

mini-MWP: single agent, single conversation, human review between stages. If a task needs review of a different kind (security, design), I do it myself or spawn a one-off subagent — no permanent orchestration.

**Why:** Multi-agent setups add coordination cost. For solo work the human is the orchestrator and the reviewer.

## Formal stage gates

Full MWP: stages have explicit entry/exit criteria documented in machine-readable form.

mini-MWP: a stage is done when its PR merges. That's the gate.

**Why:** A merged PR already encodes that the change is reviewed and tested. A separate gate spec would just be redundant ceremony.

## What stays

- **Markdown as the prompt + context substrate.**
- **Numbered stages on disk** for migrations / plans / ADRs.
- **Single agent, sequential stages, human review between** as the work model.
- **Scripts/ for mechanical work** so the agent loop isn't burning tokens on deterministic tasks.
- **PR-per-worktree** as the handoff mechanism.

## Decision rationale

Where applicable, the call to adopt or skip a piece of full-MWP machinery should be captured in an ADR (`docs/adr/000N-*.md`) in the project applying it, with a link back here. Future-me can revisit those calls without re-deriving them.
