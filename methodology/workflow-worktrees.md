# Workflow: Worktree-per-task, PR into main

The handoff mechanism between agent stages. Each PR is one stage's output; review happens before the next stage begins.

## The rule

**Never commit directly to `main`.** For any change — code, migrations, docs, config — open a PR targeting `main`. The only exception is when I explicitly say so in the request (e.g. "commit straight to main", "skip the PR", "push directly"). If a request is ambiguous, default to PR and ask only if blocked.

## The pattern

**Default to git worktrees, not in-place branches.** Multiple Claude instances may be working in the repo concurrently, so an in-place `git checkout -b` can stomp on another session's working tree. Use:

```bash
git worktree add ../<repo>-wt-<short-slug> -b <branch-name> main
```

Then `cd` into the worktree, make the change, commit, push, open the PR from there. After merge, clean up:

```bash
git worktree remove ../<repo>-wt-<short-slug>
git branch -d <branch-name>
```

This applies even to one-line fixes and to changes asked for in the same turn. Don't shortcut it.

## Why it works

- **Concurrency safe.** Two agent sessions can each have their own worktree without colliding on staged files or branch state.
- **Reviewable units.** Each PR is one stage of one task — small enough to review, big enough to ship.
- **History stays linear.** PRs squash-merge into main in the order they pass review, so `main` reads as a sequence of completed stages.
- **Easy rollback.** A bad stage is one revert; the worktree directory is the audit trail.

## Parent-folder convention

Worktrees live as siblings to the main checkout, inside a parent folder. Layout:

```
~/Documents/.../<App>_parent/
├── <App>/                          ← main checkout (always on `main`)
├── <repo>-wt-<slug-1>/             ← active worktree
├── <repo>-wt-<slug-2>/             ← active worktree
└── CLAUDE_PROJECT_LEARNINGS.md     ← cross-project ledger
```

The parent folder is what gets opened in Cowork, so the agent can see all worktrees at once and the cross-project learnings ledger is sibling to all of them.

## Handoff hygiene

When a worktree's work is ready for the user to test (especially iOS), the agent prints the absolute path to whatever IDE command opens it — e.g. `xed /Users/.../tasks-wt-<slug>/ios`. The user shouldn't have to figure out which worktree to `cd` into.

## Local pre-flight before pushing

For changes that have a fast local validator (compile check, lint, smoke test), run it before declaring the work ready. CI is for catching mistakes that slipped through, not for running the first compile. Symptom this prevents: a 25-minute CI cycle to surface a missing import.
