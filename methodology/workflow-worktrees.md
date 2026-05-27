# Workflow: Worktree-per-task, PR into main

The handoff mechanism between agent stages. Each PR is one stage's output; review happens before the next stage begins.

## The rule

**Never commit directly to `main`.** For any change — code, migrations, docs, config — open a PR targeting `main`. The only exception is when I explicitly say so in the request (e.g. "commit straight to main", "skip the PR", "push directly"). If a request is ambiguous, default to PR and ask only if blocked.

## The rule: worktree first, then work

**Open a worktree before writing any code, docs, or config.** The worktree is the first action after picking a task — before reading source files, before planning the change, before touching anything. No changes of any kind land in the main checkout; all work happens inside a worktree. This is not a suggestion or a default — it is a hard gate.

**Default to git worktrees, not in-place branches.** Multiple Claude instances may be working in the repo concurrently, so an in-place `git checkout -b` can stomp on another session's working tree. Use:

```bash
git worktree add ../<repo>-wt-<short-slug> -b <branch-name> main
```

**Worktrees go in a sibling directory of the main checkout — never nested inside it.** The `../` prefix above is load-bearing, not cosmetic. A worktree placed inside the main repo (e.g. `./worktrees/<slug>/` or `./<slug>/`) confuses every tool that walks the working tree: `git status` from the main checkout sees the nested worktree as an untracked directory, file watchers double-index, and IDE indexers fight over the same files. Symptom this prevents: the main checkout shows phantom "untracked" entries for an unrelated worktree, or a build tool picks up two copies of the same source file.

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

## Reviewer assignment

**Add `DRosen766` as a reviewer on every PR.** Use `gh pr create --reviewer DRosen766 …` (or the `reviewers` field if creating via API). This is what surfaces the PR in the GitHub "Review requested" inbox and on the mobile app; without it, PRs sit silently until someone happens to browse the repo. Symptom this prevents: a stage finishes, the agent reports "PR opened," and nothing pings the reviewer — the work stalls until the next time the repo is opened manually.

## Handoff hygiene

When a worktree's work is ready for the user to test (especially iOS), the agent prints the absolute path to whatever IDE command opens it — e.g. `xed /Users/.../tasks-wt-<slug>/ios`. The user shouldn't have to figure out which worktree to `cd` into.

## Local pre-flight before pushing

For changes that have a fast local validator (compile check, lint, smoke test), run it before declaring the work ready. CI is for catching mistakes that slipped through, not for running the first compile. Symptom this prevents: a 25-minute CI cycle to surface a missing import.

## Docs ship with the change

**Before opening the PR, update every doc the change makes stale — in the same PR.** If a stage changes behavior, config, or a known gotcha, the docs that describe it move with it: `CLAUDE.md` gotchas, `ARCHITECTURE_PLAN.md`, the relevant `docs/plans/000N_*.md`, an ADR if a decision changed. The doc edit is part of the stage, not a follow-up — a stage isn't ready to push until its code compiles *and* its docs match what it now does.

**Why:** In mini-MWP the markdown *is* the context substrate the next agent session reads (`file-roles.md`). A PR that ships code but leaves the docs describing the old behavior hands the next session wrong context, and a separate "update the docs later" PR rarely gets written. Symptom this prevents: an agent reads a `CLAUDE.md` gotcha that the last merge already invalidated and re-introduces the bug the gotcha warned about.

## Sweep `STATUS.md` before the PR

**Before opening the PR, run the [status-update](../skills/status-update/SKILL.md) protocol on `STATUS.md` end-to-end — not just the line for this stage.** Move this stage's item from Now → Done with the ship date, trim Done past ~15 entries, re-check Next up priorities, demote anything silently completed elsewhere, and confirm Blocked entries are still blocked. Append the dated Activity log line. The status doc is a live ticker (see `file-roles.md`), so it rots faster than any other doc in the repo: stale Now items, items in Done with no date, Blocked items that have been unblocked for weeks.

**Why:** A stale `STATUS.md` makes the *next* session pick the wrong work, or worse, redo work that's already shipped. The sweep-before model is much cheaper than cleanup-after — by the time someone notices the staleness, multiple sessions have already been mis-primed by it. Symptom this prevents: a new session reads "Now: implement X" and starts working on X, not realizing the previous session shipped X two PRs ago but never updated the ticker.
