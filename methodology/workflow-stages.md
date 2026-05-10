# Workflow: Numbered stages on disk

Order is encoded in filenames, not in framework code. The filesystem is the orchestration layer.

## Where this shows up

- **Database migrations.** `supabase/migrations/0001_initial.sql`, `0002_cron.sql`, `0003_user_id_defaults.sql`, … Order of application is filename order.
- **Plans.** `docs/plans/0001_<feature>.md`, `0002_<feature>.md`, … One plan per feature, numbered as they're started.
- **ADRs.** `docs/adr/0001-<decision>.md`, … One per architectural decision.

## Rules

**Append-only.** Once a numbered file has been applied (migration run, plan executed, ADR signed off), don't edit it. Add a new numbered file with the fix or follow-up. Editing breaks every other environment that's already at that version.

**Numbers are sequential, not semantic.** `0007` doesn't mean anything except "the seventh thing." Don't try to encode meaning in the number.

**Filename describes the contents.** `0006_revert_priority_column.sql` is good; `0006_fix.sql` is not.

## Why this beats a framework

- **Greppable.** `ls migrations/` shows you the entire history at a glance.
- **No tooling needed.** A new contributor (or a new agent session) understands the order by looking at the directory.
- **Composable with git.** Each file is its own diff in the PR, and the PR title says what the new stage does.

## Per-feature plans

A `docs/plans/000N_<feature>.md` document carries the stage-by-stage acceptance criteria for a multi-stage feature. The agent reads it to know what role to play in each stage. The plan itself is append-only once stages are shipped — completed stages get a "shipped" marker; later sections can be edited until they ship.
