# mini-MWP — Methodology Overview

A lightweight personal adaptation of the **Model Workspace Protocol** (Van Clief & McDermott, [arXiv:2603.16021](https://arxiv.org/abs/2603.16021)) — also called *Interpretable Context*.

## The core idea

> Replace framework-level multi-agent orchestration with **filesystem structure + plain markdown**, drive a **single agent** stage-by-stage with **human review between stages**, and keep mechanical (non-AI) work in `scripts/`.

Concretely:

- **Numbered stages on disk.** Order is encoded in filenames (`migrations/000N_*.sql`, `docs/plans/000N_*.md`, `docs/adr/000N-*.md`), not in framework code.
- **Markdown carries the prompt + context.** Specific files take specific roles (see `file-roles.md`). The agent reads these to know what role to play.
- **Single agent, sequential stages, human review between.** The PR-per-worktree workflow is the handoff mechanism — each PR is one stage's output, reviewed before the next stage begins (see `workflow-worktrees.md`).
- **Scripts handle non-AI work.** Anything mechanical (smoke tests, codegen, deploys) lives in `scripts/`, fastlane, `xcodegen`, etc. — not the agent loop.

## What this deliberately omits

Full MWP formalization includes one folder per stage and one prompt file per stage. For a single-author project that costs more than it saves. mini-MWP keeps the *spirit* — staged work, markdown context, human review — and drops the per-stage scaffolding. See `what-this-omits.md` for the list and rationale.

## Where to read next

- `file-roles.md` — what `CLAUDE.md`, `STATUS.md`, `ARCHITECTURE_PLAN.md`, and `RESUME.md` each do, and why they're separate.
- `workflow-worktrees.md` — the worktree-per-task PR pattern that handles concurrent agent sessions.
- `workflow-stages.md` — numbered-on-disk stages for migrations, plans, and ADRs.
- `what-this-omits.md` — full-MWP machinery I deliberately don't use, with reasons.
