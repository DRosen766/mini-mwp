---
name: create-issue
description: File a new GitHub issue, create or update a plan doc under `docs/plans/` (with decision documentation when applicable), and land the doc changes via a worktree+PR that is created AND merged. Use when the user says "/create-issue" or asks to "create an issue" for a bug, follow-up, or scoped feature.
---

# create-issue

A short, scripted workflow for filing a tracked issue. The deliverables every run produces:

1. A new GitHub issue on the repo.
2. A plan doc under `docs/plans/` — either a **new** plan created for this issue, or an **existing** plan updated with the new issue added. Includes decision documentation when the issue involves non-obvious design choices.
3. A PR that lands the plan-doc changes, **created and merged** before the skill exits.

Don't expand scope inside the loop — this skill **only** files and indexes the issue. The implementation of the issue itself is a separate task.

---

## Inputs the user usually gives

- A short description of the bug or feature.
- (Optional) The plan doc to file it under. If omitted, decide whether an existing plan fits or a new one is needed (see step 1).
- (Optional) An existing worktree to bundle the doc edit into. If omitted, spawn a fresh worktree.
- (Optional) Design context, trade-offs, or decisions that should be documented alongside the issue.

If the user's request is ambiguous about which plan the issue belongs to, ask once with `AskUserQuestion` before editing.

---

## Steps

### 1. Pick or create the plan doc

```bash
ls docs/plans/
```

Read the candidate doc(s) and decide:

**Add to an existing plan** when the new issue clearly belongs to a phase that already has a plan doc — its scope covers this work, and the "Issues in scope" section already groups siblings.

**Create a new plan** when:
- No existing plan covers this area of work.
- The issue represents a new initiative, phase, or body of work that deserves its own plan.
- The user explicitly asks for a new plan.

To create a new plan, pick the next sequence number (`ls docs/plans/ | tail -1` to find the highest) and create `docs/plans/000N_<slug>.md` with at least:

```markdown
# Phase 000N — <Title>

## Scope
<1-3 sentences: what this phase covers and why>

## Design decisions
<document any non-obvious choices, trade-offs, alternatives considered — omit this section if the issue is straightforward>

## Issues in scope
- **#TBD — <title>.** <one-line summary + acceptance criteria>

## Sequencing
<only if the phase has multiple stages; omit for single-issue plans>
```

If adding to an existing plan, announce the pick: `Filing under docs/plans/000N_<phase>.md (reason).`

### 2. Spawn (or reuse) a worktree

If the user named an existing worktree, `cd` into it and use its branch. Otherwise:

```bash
SLUG=<short-kebab-slug-of-the-issue>
git worktree add ../<repo-wt-prefix>-create-issue-$SLUG -b chore/issue-$SLUG main
cd ../<repo-wt-prefix>-create-issue-$SLUG
```

Follow the project's worktree naming convention if one exists (check `CLAUDE.md`). Default to `<repo-name>-wt-create-issue-<slug>` as a sibling of the main checkout.

### 3. Write the plan doc changes

**If creating a new plan:** write the full plan doc as described in step 1.

**If updating an existing plan:** append a bullet under "Issues in scope" using the format the doc already uses. Use `#TBD` as a placeholder for the GH issue number. Required content:

- One-line summary of the bug/feature.
- Repro (for bugs) or scope (for features).
- Likely culprits / pointers (for bugs) — link to relevant `CLAUDE.md` gotchas where they apply.
- Acceptance criteria.

**Decision documentation:** if the issue involves non-obvious design choices, trade-offs, or alternatives that were considered, add or update a "Design decisions" section in the plan doc. This captures the *why* so future implementers don't re-litigate settled questions. Skip this section for straightforward bugs or small enhancements where the approach is obvious.

If the phase has a **Sequencing** section, only add a stage entry if the new issue is large enough to be its own stage.

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

In the plan doc:
```
- **#TBD — <title>.**  →  - **#<N> — <title>.**
```

Use the Edit tool, not sed, so the change is reviewable.

### 6. Commit, push, create PR, and merge

```bash
git add docs/plans/
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

If the worktree was reused and already carries unrelated work-in-progress on that branch, **do not** bundle the issue index into that PR — instead commit on a fresh branch and merge separately.

**Wait for CI, then merge the PR before exiting.** This is a hard requirement — the skill is not done until the PR is merged:

```bash
# Wait for checks (poll briefly — docs PRs are usually fast)
gh pr checks <PR#> --watch

gh pr merge <PR#> --squash --delete-branch
```

If a check is red on a pure docs change, investigate before merging — never bypass with `--admin` unless the user explicitly asks. If checks hang or fail for infrastructure reasons, report the status and ask the user how to proceed.

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
- Exit without merging the PR (unless blocked by a failing check that needs user input).
