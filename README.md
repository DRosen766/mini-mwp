# mini-mwp

A lightweight, personal adaptation of the **Model Workspace Protocol** (Van Clief & McDermott, [arXiv:2603.16021](https://arxiv.org/abs/2603.16021)) — also called *Interpretable Context*. Holds the methodology, templates, and conventions I use across Claude-assisted personal development projects.

## What this repo is

A context-storage repo, not a product. It captures:

- **`methodology/`** — how I structure work across all projects (file roles, workflow patterns, deliberate omissions).
- **`conventions/`** — per-project conventions distilled from real repos.
- **`templates/`** — reusable starter files I drop into new projects.
- **`learnings/`** — cross-project meta-lessons accumulated over time.
- **`skills/`** — repo-agnostic Claude skills that operationalize the methodology. Designed to be consumed by product repos that mount this repo as a submodule and symlink the skills into `.claude/skills/`.

The goal is for this repo to eventually become a portable seed I can clone (or mount as a submodule) at the start of any new project.

## Origin

The methodology here was reverse-engineered from the Task Tracker App project, which had organically converged on a set of file roles, workflow patterns, and conventions worth preserving. See `methodology/overview.md` for the framing and `conventions/task-tracker-app.md` for the first concrete project example.

## Status

Bootstrap. Initial extraction from Task Tracker App complete. Will be iterated on as new methodologies surface.
