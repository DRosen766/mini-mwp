---
name: create-issue
description: File a new GitHub issue, anchor it in the right phase doc under `docs/plans/`, and land the doc change via a worktree+PR that gets merged. Use when the user says "/create-issue" or asks to "create an issue" for a bug, follow-up, or scoped feature that should be tracked in the phase queue.
---

# create-issue

A short, scripted workflow for filing a tracked issue. The deliverables every run produces:

1. A new GitHub issue, with body that points at the phase doc.
2. A bullet for it in the correct `docs/plans/000N_*.md` phase, under "Issues in scope".
3. A merged PR that lands the phase-doc edit.

Don't expand scope inside the loop — this skill **only** files and indexes the issue. The implementation of the issue itself is a separate task.

---

## Inputs the user usually gives

- A short description of the bug or feature.
- (Optional) The phase doc to file it under. If omitted, pick the best fit from `docs/plans/` and confirm in one line before editing.
- (Optional) An existing worktree to bundle the doc edit into. If omitted, spawn a fresh worktree.

If the user's request is ambiguous about which phase the issue belongs to, ask once with `AskUserQuestion` before editing.

---

## Steps

### 1. Pick the phase doc

```bash
ls docs/plans/
```

Read the candidate doc(s) and choose the one whose **Scope** matches the new issue. Heuristics:

- `bug`-shaped items → the active bug sweep phase (e.g. `0005_bug_sweep.md`) unless a later phase already lists a closely related issue.
- Feature work → the phase whose "Issues in scope" already groups its siblings.
- If nothing fits, surface that and ask the user before creating a new phase.

Announce the pick in one line: `Filing under docs/plans/000N_<phase>.md (reason).`

### 2. Spawn (or reuse) a worktree

If the user named an existing worktree, `cd` into it and use its branch. Otherwise:

```bash
SLUG=<short-kebab-slug-of-the-issue>
git worktree add ../<repo-wt-prefix>-create-issue-$SLUG -b chore/issue-$SLUG main
cd ../<repo-wt-prefix>-create-issue-$SLUG
```

Follow the project's worktree naming convention if one exists (check `CLAUDE.md`). Default to `<repo-name>-wt-create-issue-<slug>` as a sibling of the main checkout.

### 3. Edit the phase doc

Append a bullet under "Issues in scope" in the chosen phase doc, using the format the doc already uses. While the GH issue number is unknown, use `#TBD` as a placeholder. Required content:

- One-line summary of the bug/feature.
- Repro (for bugs) or scope (for features).
- Likely culprits / pointers (for bugs) — link to relevant `CLAUDE.md` gotchas where they apply.
- Acceptance criteria.

If the phase has a **Sequencing** section, only add a stage entry if the new issue is large enough to be its own stage. Bug-sweep items typically don't get a sequencing entry.

### 4. File the GitHub issue

```bash
gh issue create \
  --title "<concise title>" \
  --label <bug|enhancement|future-work> \
  --body "$(cat <<'EOF'
## Summary
<1-2 sentences>

## Repro          # (bugs only)
1. ...
2. ...
3. Observe: ...

## Likely culprits   # (bugs only — best-guess pointers)
- ...

## Scope
- iOS-only / backend-only / docs-only / mixed.
- Likely-touched files: ...

## Acceptance
<crisp success criterion>

## Plan
Tracked under `docs/plans/000N_<phase>.md`.
EOF
)"
```

Capture the URL it prints; the trailing path segment is the issue number.

### 5. Replace `#TBD` with the real issue number

```bash
# in the phase doc
- **#TBD — <title>.**  →  - **#<N> — <title>.**
```

Use the Edit tool, not sed, so the change is reviewable.

### 6. Commit, push, PR, merge

```bash
git add docs/plans/000N_<phase>.md
git commit -m "$(cat <<'EOF'
docs(<phase>): file #<N> — <short title>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
EOF
)"
git push -u origin <branch>
gh pr create --title "docs(<phase>): file #<N> — <short title>" --body "$(cat <<'EOF'
Indexes #<N> into `docs/plans/000N_<phase>.md` under "Issues in scope".
No code change.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

If the worktree was reused and already carries unrelated work-in-progress on that branch, **do not** bundle the issue index into that PR — instead commit on a fresh branch and merge separately. The user only opted in to "reuse the worktree"; they did not necessarily opt in to mixing scope.

Wait for CI on the PR. When green:

```bash
gh pr merge <PR#> --squash --delete-branch
```

If a check is red on a pure docs change, investigate before merging — never bypass with `--admin` unless the user explicitly asks.

### 7. Clean up

```bash
git worktree remove ../<worktree-dir>   # only if it was spawned by this skill
```

Reused worktrees stay put.

### 8. Update STATUS.md

If the project has a `STATUS.md` and the issue is going on the active queue, append a one-liner to the Activity log (see the `status-update` skill). Otherwise skip — back-burner phases don't need an activity log entry just for filing.

---

## What this skill does NOT do

- Implement the issue. That's a separate worktree+PR.
- Triage existing issues — see `churn` for that.
- File issues that belong in another repo's tracker.
- Mix doc-index commits with feature code (see step 6 caveat).
