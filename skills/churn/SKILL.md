---
name: churn
description: Autonomously drive ONE drain-the-phase iteration — pick the next stage, implement it in a worktree, ship docs + status updates as if already merged, run a forward-looking planning pass, open a PR with DRosen766 as reviewer, wait for green checks, merge, and clean up. Pair with `/loop` for continuous operation (`/loop /churn`). Use when the user says "/churn" or asks to autonomously work through the current phase.
---

# churn

One disciplined iteration of draining the **current phase**: pick the next stage, ship it, plan ahead, merge, clean up. Designed to be re-fired by `/loop` for continuous operation — each invocation handles exactly one stage end-to-end, then exits cleanly so the harness can decide whether to fire again.

This skill is the autonomous counterpart to the `next` skill — same rules from `mini-mwp/methodology/task-pickup.md` and `mini-mwp/methodology/workflow-worktrees.md`, but designed to run unattended. The discipline that matters most: **drain before switching phases**. Churn never jumps to a different plan on its own — phase handoff is a planning decision that requires the user.

## How to run continuously

The skill body below is **one iteration**. To run it continuously, pair it with `/loop` in **dynamic mode** (no interval):

```
/loop /churn
```

`/loop` has two modes — dynamic and scheduled — and churn requires dynamic:

- **Dynamic (use this):** `/loop /churn` with no interval. The model calls `ScheduleWakeup` at the end of each iteration to pick when to re-fire. Right for churn because iterations vary in length (a 2-minute docs PR vs. a 25-minute CI-bound change) — a fixed interval would either re-enter mid-iteration or sit idle.
- **Scheduled:** `/loop 5m /churn` and similar. Re-fires on a fixed cron-like cadence regardless of whether the prior iteration finished. **Don't use for churn** — it's for pollers like "check PR status every 5 min," not for workload-bound loops.

In dynamic mode, continuation is explicit: at the end of every iteration, if no stop condition tripped, **call `ScheduleWakeup`** with `prompt: "/churn"` (or the sentinel `<<autonomous-loop-dynamic>>` if the loop was started autonomously) and a small `delaySeconds` (60 is fine — the harness clamps to [60, 3600]). If a stop condition tripped, **do not call `ScheduleWakeup`** — the loop ends.

Context is bounded per iteration (auto-compaction runs between firings), the boundary is clean (worktree gone, PR merged, plans updated), and stop conditions surface as the model declining to schedule the next wake-up.

**What "continuous" means here.** Continuous means "the loop re-fires automatically until a stop condition trips," not "the model runs forever without supervision." Realistic stop points:

- **Phase drained** — every stage in the current plan is shipped. Phase handoff requires the user.
- **All remaining stages blocked on the user** — every open stage in the current phase needs a user decision (see "Routing around user-dependent blockers" in step 1). A *single* blocked stage does **not** stop the loop — churn marks it `Blocked` and switches to another unblocked stage in the same phase.
- **Red CI** — a check fails on a PR. The iteration reports and exits without scheduling.
- **Forward-looking floor violated** — the planning pass couldn't surface a single new issue *anywhere* (current phase, neighbors, or a new phase). The floor is landscape-wide; only a truly empty forward surface stops the loop.
- **Sensitive surface** — every remaining stage touches auth/billing/migrations/secrets without prior authorization.
- **Permission prompt** — a tool call requires user approval that wasn't pre-granted (see "Pre-approving permissions" below).
- **Sync failure** — step 0's `git pull --ff-only` or submodule update failed (network error, local `main` diverged, not on `main`). Don't proceed on stale state.
- **User interrupts.**

So a realistic overnight run is "N iterations until one of the above fires," not "infinite." That's the design — the stops are features, not bugs.

**Running without `/loop`** (single iteration on demand) is fine too — just type `/churn` and it'll do one stage and stop.

## Pre-approving permissions

Churn runs a fixed set of tool calls. To avoid every iteration stalling on a permission prompt, pre-approve them once via the `fewer-permission-prompts` skill or by editing `.claude/settings.local.json` in the product repo. The set:

- `Bash(gh issue list:*)`, `Bash(gh issue create:*)`, `Bash(gh issue view:*)`
- `Bash(gh pr create:*)`, `Bash(gh pr checks:*)`, `Bash(gh pr merge:*)`, `Bash(gh pr view:*)`
- `Bash(git worktree add:*)`, `Bash(git worktree list:*)`, `Bash(git worktree remove:*)`, `Bash(git branch -d:*)`, `Bash(git push:*)`, `Bash(git add:*)`, `Bash(git commit:*)`
- `Bash(git pull --ff-only:*)`, `Bash(git submodule update:*)`, `Bash(git rev-parse:*)` — for step 0's sync.
- `Bash(cat:*)`, `Bash(ls:*)`
- `EnterWorktree`, `ExitWorktree`

Do **not** pre-approve `gh pr merge --admin`, `git push --force`, or `--no-verify` variants — those should still prompt.

If a churn iteration stops on a permission prompt the user didn't pre-grant, that's the harness working correctly. Add it to the allowlist if it's safe, then re-fire `/loop /churn`.

## Iteration overview

Each invocation:

0. **Sync the main checkout** — pull latest `main`, refresh `mini-mwp`, classify any lingering worktrees (reclaim merged, leave unmerged-with-commits alone, **resume in-progress WIP**).
1. **Pick** the next open stage from the current phase's plan — *only if* step 0 didn't resume an in-progress worktree.
2. **Open a worktree** via `EnterWorktree` (hard gate) — *only if* step 0 didn't resume one.
3. **Implement** the stage (or finish what was already started, on a resumed worktree).
4. **Update docs + STATUS.md** as if the PR is already merged.
5. **Forward-looking planning pass** — read the plan landscape, update/create plans, file **≥1 new issue per stage shipped** (hard lower bound).
6. **Open a PR** linking the issue, with `DRosen766` as reviewer.
7. **Wait** for CI checks.
8. **Merge if green; stop and preserve the worktree if not.** Verify `state: MERGED` before proceeding.
9. **Exit the worktree** and clean up — **only after a confirmed merge**.
10. **End the iteration cleanly** — print the one-line status, do not start a new pick. `/loop` handles re-firing.

If you discover work that doesn't belong in the current stage (out-of-scope bug, follow-up, missing feature), **invoke the `create-issue` skill** to file and index it — do not expand the current stage.

---

## 0. Sync the main checkout

**Before reading anything else, refresh local state.** A long `/loop /churn` run can otherwise drift behind merges that landed on `main` (your own from a previous iteration, or any concurrent work) and behind `mini-mwp` updates that ship new skill versions or methodology refinements. Every iteration must start from current ground truth — otherwise the planning pass reads stale plan docs and the worktree branches off a stale base.

Run from the main checkout (you should be there at the start of every iteration — `EnterWorktree` happens in step 2):

```bash
git -C "$(git rev-parse --show-toplevel)" rev-parse --abbrev-ref HEAD   # must print: main
git pull --ff-only origin main
git submodule update --init --remote mini-mwp
```

### 0a. Reclaim stranded worktrees from prior stopped iterations

After the pull, check whether any worktrees from a previous stopped iteration are still around — typically because the prior iteration's merge was blocked (red CI, permission denial, missing review) and the user has since resolved it manually.

```bash
git worktree list
gh pr list --state merged --search "head:<churn-branch-prefix>" --limit 5
```

Classify each lingering worktree into one of three states and act accordingly:

**State A — Branch merged into `main`** (`git branch --merged main` lists it, or the PR list shows it merged). Reclaim:

```bash
git worktree remove ../<lingering-worktree-path>
git branch -d <lingering-branch>
```

**State B — Branch has commits but is not yet merged** (open PR awaiting CI, review, or manual merge). Leave it alone — the user is finishing it. Note it in the iteration summary so the user sees it.

**State C — Worktree has uncommitted in-progress writes** (i.e. `git -C <worktree> status --porcelain` is non-empty, OR the branch has zero commits beyond `main` but the working tree has staged/unstaged changes). This is an iteration that was **interrupted mid-implementation** — typically by a permission denial, a tool failure, or the user. The work-in-progress is real and recoverable, but it lives only in the worktree's working tree (not on any remote, possibly not even in a commit).

**Do not pick a new stage.** Resume the interrupted iteration in the existing worktree:

1. `EnterWorktree({ path: "<absolute path from git worktree list>" })` to switch the session into the existing worktree. Use `path`, not `name` — `name` would try to create a new worktree.
2. Inspect what was already done: `git status`, `git diff`, `git log main..HEAD`. Read the stage's plan entry to know what's still owed.
3. Resume from where the interruption hit — finish writing the remaining files / running the remaining commands, then proceed through steps 4–9 normally (docs sweep → forward-looking pass → PR → CI → merge → cleanup).
4. **Skip step 1** (don't re-pick a stage) and **skip step 2** (the worktree already exists; don't try to create a new one). Pick up at step 3 (implement) or wherever the interruption hit.

If you can't tell what was done vs. what's owed (the work is unfamiliar, the stage entry is ambiguous, or the WIP looks inconsistent with the stage), **stop and ask the user** rather than guess and ship something half-baked. Emit `Stopping: found WIP in <worktree> from interrupted iteration; need user direction on how to resume.`

If multiple worktrees are in State C, that's a sign of repeated interruptions. Resume one and surface the others in the iteration summary so the user can triage.

---

These three states are the counterpart to step 8's "preserve worktree on merge failure" rule and the broader "never leave the user holding orphaned work" guarantee. Together they make `/loop /churn` self-recovering across interruptions: the loop fires, looks at what's lying around, finishes what's resumable, reclaims what's done, and only picks a new stage when nothing prior is owed.

**Rules:**

- **Fast-forward only.** `--ff-only` refuses to auto-merge if local `main` has diverged. Divergence on the main checkout is a sign something is wrong — stop the loop and surface it; do not auto-resolve.
- **You must be on `main`** before this step. If `HEAD` is not `main`, something has gone wrong with prior worktree cleanup — stop and report.
- **Submodule sync is non-committing.** `git submodule update --remote` may move the `mini-mwp` pointer in the working tree (showing as a dirty submodule in `git status`). That's expected. If the bump is meaningful (new methodology rule that affects how you'd implement the next stage, new version of an invoked skill), commit the submodule pin update as part of step 5b's plan-landscape edits or as its own tiny issue. If it's a no-op for the work ahead, leave it dirty — the next iteration's pull will see the same state and you can decide again.
- **Network failure stops the loop.** If `git pull` or `git submodule update` fails, do not proceed with stale state — emit a `Stopping: failed to sync main / mini-mwp (<error>)` line and exit without `ScheduleWakeup`.

After the sync succeeds, proceed to step 1.

## 1. Read the methodology and pick the next stage

**Skip this step entirely if step 0a put you into a resumed worktree (State C).** In that case, jump to step 3 — the stage is already picked, the worktree is already open, and re-picking would forget what's already done.

Before the first iteration, read:

- `mini-mwp/methodology/task-pickup.md` — pickup discipline.
- `mini-mwp/methodology/workflow-worktrees.md` — worktree-first gate, PR workflow, "docs ship with the change."
- `mini-mwp/methodology/file-roles.md` — what each markdown doc is for.

Then, every fresh-pick iteration:

```bash
cat STATUS.md
```

Find the **Current phase** field. It names the active plan doc (e.g. `docs/plans/0009_completion_ux.md`).

```bash
cat docs/plans/000N_<phase>.md
```

Pick the next open stage using the plan's own sequencing rules (numbered stages, "PR-A blocks PR-B" notes, risk-first ordering for bug sweeps). Apply the pickup discipline:

- **Pick from the current phase only.** Don't jump plans.
- **Drain before switching.** If stages remain, pick one.
- **Skip and surface** stages that are ambiguous enough to need a user decision, blocked on something you can't resolve, or labeled `blocked` / `needs-design` in the plan.
- **Skip** stages that touch auth/billing/migrations/secrets without explicit user authorization for autonomous work in that area.

If the plan has an associated GitHub issue for the stage, capture the issue number.

### Routing around user-dependent blockers

If you pick a stage and discover (here or mid-implementation in step 3) that it's blocked on a decision only the user can make — an unanswered design question, a missing credential, an external dependency, a "which behavior do we want here?" — **do not stop the loop**. Instead:

1. **Mark the stage `Blocked`** in `STATUS.md` and in the plan doc, with a one-line note describing exactly what the user needs to resolve. Cite the file/decision point.
2. **If you started implementing, exit the worktree** cleanly via `ExitWorktree` and leave no half-finished commits on the branch (or commit a WIP and leave it for the user to inspect — choose based on whether the WIP adds context the user needs).
3. **Pick another unblocked stage from the same phase** and continue the iteration with it. Drain-before-switching still applies: stay in the current plan.
4. **Only stop the loop if every remaining stage in the current phase is blocked.** That's the genuine "I need the user" condition; a single blocked stage isn't.

When you do continue with a different stage, announce the swap in one line: `Blocked: <original stage> (reason). Switched to: <new stage>.`

The user-dependent blocker becomes a forward-looking artifact: the `Blocked` note in STATUS.md + the plan doc tells the user exactly what's waiting on them when they come back. Do **not** invent an answer to keep moving — the whole point of marking blocked is to surface the decision, not to paper over it.

If the original blocker is one the forward-looking pass (step 5) would naturally file as an issue (e.g. "Decide policy for X"), file it as a regular issue instead of just a STATUS.md note — issues are more durable.

**If no stages remain in the current phase**, this is a phase handoff. Per `task-pickup.md`, phase handoff is a two-step planning decision — **stop the loop and ask the user** which phase to start next. Do not pick the next plan yourself.

Announce the pick in one line: `Picked: <stage title> (#N if applicable) from docs/plans/000N_<phase>.md.`

## 2. Open a worktree — HARD GATE

**Skip if step 0a put you into a resumed worktree (State C)** — the session is already inside it; verify with `pwd` and proceed to step 3.

For a fresh-pick iteration: **no source reading, no implementation, no edits until the worktree exists.**

The methodology (`mini-mwp/methodology/workflow-worktrees.md`) requires worktrees to live as **siblings of the main checkout**, never nested inside it. `EnterWorktree({ name })` creates worktrees in `.claude/worktrees/` (nested) — that violates the convention. The correct pattern is two steps: create the worktree at the sibling path with `git worktree add`, then `EnterWorktree({ path })` to switch the session into it.

```bash
# Compute paths
REPO_ROOT="$(git rev-parse --show-toplevel)"
REPO_NAME="$(basename "$REPO_ROOT")"
SLUG="churn-<short-kebab-slug>"
WT_PATH="$(dirname "$REPO_ROOT")/${REPO_NAME}-wt-${SLUG}"
BRANCH="worktree-${SLUG}"

# Create the worktree as a sibling, branching off freshly-pulled main
git worktree add "$WT_PATH" -b "$BRANCH" main
```

Then switch the session in:

```
EnterWorktree({ path: "<absolute path printed by `git worktree list | tail -1`>" })
```

Pass the **path exactly as `git worktree list` reports it** — `EnterWorktree` validates the path against that list and rejects unregistered paths.

Verify with `pwd` after the call; the path must be the sibling (`../<repo>-wt-churn-<slug>` from the main checkout's perspective, never `.claude/worktrees/...`). If either `git worktree add` or `EnterWorktree` fails, stop the loop and report — do not fall back to the main checkout, and do not fall back to `EnterWorktree({ name })` (that would nest the worktree under `.claude/worktrees/`, violating the methodology).

**Why this matters:** a worktree under `.claude/worktrees/` is inside the main checkout's working tree. From the main checkout, `git status` reports the nested worktree's contents as untracked; file watchers and IDE indexers see two copies of the same files; build tools that walk the tree pick up both. The sibling layout is what the rest of the methodology (the `<App>_parent/` folder convention, Cowork's parent-folder mount, the cross-project learnings ledger) is built around.

## 3. Implement the stage

Inside the worktree:

- Read the stage's plan entry and any linked issue body in full.
- Read the relevant `CLAUDE.md` gotchas and project conventions before touching code.
- Make the change. Stay within the stage's scope.
- Run the project's local validators (compile / lint / type-check / smoke tests) before declaring the work ready — CI is for catching escapes, not the first compile.

**Out-of-scope discoveries:** if you find a bug, follow-up, or missing feature that doesn't belong in this stage, invoke the `create-issue` skill to file it (or note it for filing at the end of the iteration). Do **not** expand the current stage to absorb it.

## 4. Ship docs + STATUS.md as if already merged

Per `workflow-worktrees.md` ("Docs ship with the change — written as if already merged"):

- Update every doc the change makes stale **in this same PR**: `CLAUDE.md` gotchas, the plan doc's stage marker, architecture docs, ADRs if a decision changed.
- Write in present tense. Mark the stage as shipped in the plan doc.
- Run the [`status-update`](../status-update/SKILL.md) protocol on `STATUS.md` end-to-end — move this stage Now → Done with today's date, trim Done, re-check Next up, demote silently-completed items, append the Activity log line.

The goal: the moment the PR merges, every doc in the repo is already correct.

## 5. Forward-looking planning pass

Closing out the stage's docs is backward-looking — it reconciles the markdown with what just shipped. This step is the **forward-looking** counterpart: before opening the PR, take a deliberate look at the road ahead and leave the plan landscape in better shape than you found it.

**This step is not optional. It runs every iteration. It has a hard lower bound on output.**

### 5a. Read the plan landscape

Read, in this order:

```bash
ls docs/plans/
cat docs/plans/000N_<current-phase>.md
```

Then read enough of the other plan docs (or their headers) to know what phases exist, which are active vs. back-burner, and what depends on what. Also re-read:

- `STATUS.md` — Next up, Blocked, Activity log.
- The architecture / design doc (`ARCHITECTURE_PLAN.md`, `DESIGN.md`, or equivalent — see `file-roles.md`).
- Any `CLAUDE.md` gotchas you touched or that touched what you just shipped.
- The GitHub issue tracker (`gh issue list --state open --limit 50`) to avoid filing duplicates.

The shipped stage almost always surfaces three categories of forward-looking work — actively look for them:

1. **Follow-ups the stage exposed.** Out-of-scope bugs you noticed, half-finished edges, "TODO: revisit after X ships" items that X has now shipped.
2. **Next-step work the stage unlocks.** Stages that were blocked on this one, or new capabilities the change makes possible.
3. **Plan-structure drift.** Phases that should be split, merged, re-prioritized, retired, or created. A phase that's grown to 15 stages probably wants to be two. A back-burner phase that the recent direction has elevated probably wants to move up.

### 5b. Update, create, and re-shape plans — across the whole landscape

The forward-looking pass is **not scoped to the current phase**. The current phase governs *execution* (drain-before-switching applies to which stage you pick next), but planning ranges over the entire `docs/plans/` directory. As the current phase drains, the place where new forward-looking work lives is increasingly *outside* the current phase — that's the point.

Edit the markdown to reflect what you just learned, anywhere it applies:

- **Update the current plan doc** — newly-discovered stages, re-sequencing notes, scope cuts.
- **Update other existing plan docs** — dependencies the shipped change just satisfied, gotchas, cross-phase links, re-prioritizations.
- **Create new plan docs aggressively when a new phase emerges.** Use the next sequence number (`ls docs/plans/ | tail -1`) and the structure from the `create-issue` skill's step 1. Mark active or back-burner per `file-roles.md`. **Creating new phases is encouraged, not exceptional** — it's the primary mechanism by which churn keeps the forward surface area expanding faster than the current phase contracts. If the shipped change implies a body of work that doesn't fit any existing phase, spin up a new plan doc rather than cramming it into the current one.
- **Re-shape the plan structure** — split a phase that's grown unwieldy, retire one that's bit-rotted, merge two that overlap, promote a back-burner phase whose dependencies just landed.
- **Re-prioritize** by updating STATUS.md's Next up. Don't *execute* a phase switch in this step — drain-before-switching still holds for the running loop — but record the prioritization signal so the next phase handoff is informed.

If nothing in the plan landscape needs to change, write down *why* in the PR body's "Forward-looking notes" section. "Nothing changed" should be a justified conclusion after looking, not a default from not looking.

### 5c. File new issues — hard lower bound: ≥1 per stage shipped, anywhere in the plan landscape

**You must file at least one new GitHub issue per stage you ship.** Hard floor, not a target.

The floor counts **any new issue filed anywhere in the plan landscape** — current phase, another existing phase, or a brand-new phase you just created in step 5b. The point of the floor is to guarantee forward surface area grows, not to keep the current phase fed. Filing into a new phase is exactly as valid as filing into the current one — often more valuable, because new phases open avenues that hadn't existed before this iteration.

In practice, expect the distribution of filed issues to shift over a churn run:

- **Early iterations on a phase:** most new issues land in the current phase (refinements, edges, follow-ups the stage exposed).
- **Mid-run:** issues start landing in other existing phases (the shipped change satisfied a dependency, or revealed work in a neighboring area).
- **Late-run / saturating phase:** issues increasingly land in *new* phases the iteration just created. This is healthy — it means the forward landscape is expanding while the current phase drains.

For each new issue, invoke the `create-issue` skill (or follow its protocol inline if invoking it would derail the churn loop):

- Title, body with summary / scope / acceptance, label (`bug` / `enhancement` / `future-work`).
- Index it under whatever plan doc fits — current, neighbor, or new.
- Include the issue number in the current PR body under `## Forward-looking notes` with the plan doc it landed in.

Don't pad with junk to hit the floor. Each filed issue should be real work you'd be willing to pick up in a future churn iteration. **If you genuinely cannot find a single forward-looking issue anywhere — not in the current phase, not in neighbors, and no new phase suggests itself — stop the loop and report.** That's a strong signal the user needs to re-prioritize, not a license to ship without filing.

The lower bound is one. The expected number is often more. Don't pad with junk issues to hit the floor — pad with junk, and the issue tracker becomes useless. Issues filed here should each be something you'd be willing to pick up in a future churn iteration.

## 6. Open the PR

From the worktree branch:

```bash
gh pr create --reviewer DRosen766 --title "<concise title>" --body "$(cat <<'EOF'
Closes #<issue-number>   # omit if the stage has no GH issue

## Summary
<1-3 bullets on what changed and why>

## Docs updated
- <plan doc>: marked stage shipped
- STATUS.md: moved to Done, Activity log appended
- <other docs touched, if any>

## Test plan
- [ ] <how this was verified locally>

## Forward-looking notes
- Plan changes: <plans created / updated / re-prioritized, or "no changes — <why>">
- New phases created: <000N_<slug>.md, …, or "none">
- New issues filed: #<N> (→ <plan doc>), #<N+1> (→ <plan doc>), … (≥1 required per step 5c, anywhere in the landscape)

## Follow-ups
- #<N> — <new issue from out-of-scope discovery mid-implementation, if separate from the forward-looking batch>
EOF
)"
```

`--reviewer DRosen766` is **mandatory** per `workflow-worktrees.md` ("Reviewer assignment") — without it the PR sits silently.

Use `Closes #N` (not `Refs`) so merge auto-closes the issue. Omit the `Closes` line if the stage has no GH issue.

## 7. Wait for checks

```bash
gh pr checks <pr-number> --watch
```

Run with `run_in_background: true` if it'll take more than a couple minutes. Do **not** poll in a sleep loop.

Default to **sequential** — one PR at a time — to keep merge conflicts and review load sane. Only start the next stage in parallel if the user explicitly asked for maximum throughput.

## 8. Merge or stop

**Green:** merge with the repo's standard style. Default to squash unless `CLAUDE.md` or recent merges say otherwise.

```bash
gh pr merge <pr-number> --squash --delete-branch
```

Never use `--admin`, never bypass branch protection, never `--no-verify`.

**Verify the merge actually happened** before proceeding to step 9. Check:

```bash
gh pr view <pr-number> --json state,mergedAt
```

`state` must be `MERGED` and `mergedAt` must be non-null. Only then is step 9 (worktree cleanup) safe.

If the merge **did not happen** — for any reason — **do NOT proceed to step 9**. Skip directly to step 10 with a `Stopping:` line. The reasons this branch triggers:

- **Red CI** — stop. Report which check failed, link the failing run. Do not auto-retry — a flaky test and a real regression look identical from the outside.
- **Conflicted** — try `gh pr merge` after a rebase. Rebase onto `main`, push, re-watch checks. If the rebase is non-mechanical, stop and ask.
- **Permission denial on `gh pr merge`** — the user hasn't pre-approved `Bash(gh pr merge:*)`. Stop, report the PR URL, and remind them to add it to the allowlist (or merge manually) before re-running `/loop /churn`.
- **Any other `gh pr merge` failure** — branch protection, required reviews not met, repo settings — stop and report.

**Critical rule when the merge fails:** the worktree and its branch (local + remote) **must be preserved**. The user's only handle on the in-flight work is that worktree and that branch. Cleanup (step 9) would orphan the PR — the local worktree gone, the local branch deleted, and the user holding a remote PR they have to merge by hand against a branch they can no longer easily inspect locally. **Leave it alone.** Do not call `ExitWorktree`, do not `git worktree remove`, do not `git branch -d`. The push has already happened, so the work is durable on the remote — but the user expects the worktree to still be there when they come back.

Cross-reference: step 0 of the *next* iteration will detect and clean up any stranded worktree whose branch has since been merged by the user.

## 9. Exit the worktree and clean up — only after a confirmed merge

**Precondition: step 8 confirmed `state: MERGED`.** If you got here without confirming the merge, go back. Do not run any of the cleanup commands below on an unmerged worktree.

The worktree was entered via `EnterWorktree({ path })`, which means `ExitWorktree` will **not** auto-remove it (per the tool's own rules — only worktrees created via `name` are auto-managed). Use `action: "keep"` to return to the main checkout, then remove the worktree and branch explicitly:

```
ExitWorktree({ action: "keep" })
```

Then from the main checkout:

```bash
git worktree remove "$WT_PATH"                  # the sibling path created in step 2
git branch -d "$BRANCH"                          # safe -d, not -D — refuses to delete unmerged work as defense in depth
git worktree list                                # confirm the worktree is gone
```

If `git branch -d` refuses (claims the branch is unmerged), **stop and investigate** — that means git doesn't see the merge yet (likely a stale local main; step 0 of the next iteration should have caught this, but didn't). Do not escalate to `-D`. Report and let the user resolve.

If `git branch -d` refuses (claims the branch is unmerged), **stop and investigate** — that means git doesn't see the merge yet (likely a stale local main; step 0 of the next iteration should have caught this, but didn't). Do not escalate to `-D`. Report and let the user resolve.

## 10. End the iteration cleanly

This skill body is **one iteration**. Do not start picking the next stage in the same invocation — `/loop` handles re-firing, and auto-compaction runs between firings so the next iteration starts lean.

Before returning, decide whether to signal continuation or stop. Print exactly one line:

- **Continue:** `Shipped <stage> (PR #M). Filed: #X, #Y. Next candidate: <stage from same phase>.`
- **Stop:** `Stopping: <reason>.` — used when one of the conditions below is true.

**Continue** (emit the `Shipped:` line, then call `ScheduleWakeup({ delaySeconds: 60, prompt: "/churn", reason: "next churn iteration" })`) when none of the stop conditions below apply.

**Stop the loop** (emit the `Stopping:` line and end the turn — do **not** call `ScheduleWakeup`) when:

- The current phase's plan has no open stages left → phase handoff requires the user.
- **Every remaining stage in the current phase is blocked on the user** — route around single blockers (step 1, "Routing around user-dependent blockers"); only stop when there's nothing unblocked left to pick.
- A PR check failed in step 8.
- The forward-looking pass (step 5) couldn't surface a single new issue — the ≥1/stage floor was violated.
- Every remaining candidate stage touches auth/billing/migrations/secrets without prior authorization.
- A required tool call hit a permission prompt the harness can't auto-grant.
- The user interrupted.

A single blocked stage is **not** a stop condition. Mark it `Blocked`, pick another unblocked stage from the same phase, continue.

Do not call `/compact` (the model can't self-invoke it; auto-compaction between turns handles context).

Note: filing more issues than you ship is **expected** — the ≥1/stage floor guarantees it. A growing backlog during a churn run is healthy as long as each filed issue is real work, not padding.

---

## Guardrails

- **Sync first, every iteration.** Step 0 is non-optional. Pull `main` fast-forward-only and refresh the `mini-mwp` submodule before reading anything else. Stale ground truth corrupts the planning pass and branches the next worktree off a stale base.
- **Never clean up an unmerged worktree.** Step 9 runs **only** after step 8 confirms `state: MERGED`. A merge that failed (red CI, permission denial, conflict) leaves the worktree and branch intact — local + remote — so the user can finish the merge. The next iteration's step 0a reclaims it once the user has merged it manually.
- **Resume before pick.** If step 0a finds a worktree with uncommitted in-progress writes (State C — interrupted mid-implementation), the iteration resumes *that* work in *that* worktree rather than picking a new stage. The loop only picks a new stage when nothing prior is owed.
- **Worktrees are siblings, not nested.** Step 2 creates worktrees at `../<repo>-wt-churn-<slug>/` via `git worktree add` then enters via `EnterWorktree({ path })`. Never `EnterWorktree({ name })` — that nests under `.claude/worktrees/` and violates `methodology/workflow-worktrees.md`.
- **Phase-scoped.** Never switch plans without the user — phase handoff is a planning decision.
- **Route around user-dependent blockers.** A stage blocked on a user decision gets marked `Blocked` in STATUS.md + the plan doc with a one-line note; the iteration picks another unblocked stage in the same phase and continues. Only stop the loop when *every* remaining stage in the phase is blocked. Don't invent answers to user-only decisions.
- **Worktree-first.** Step 2's hard gate applies to every iteration, including one-line fixes.
- **Docs ship with the change.** Step 4 is not optional — the methodology's "assume merged" rule is what keeps the markdown substrate trustworthy for the next session.
- **Forward-looking pass runs every iteration.** Step 5 is not optional. **Hard floor: ≥1 new issue filed per stage shipped — anywhere in the plan landscape, not just the current phase.** Creating new phases is encouraged and is the primary mechanism by which churn keeps forward surface area growing faster than the current phase drains.
- **One iteration per invocation.** Don't try to loop inside the skill. Pair with `/loop /churn` for continuous operation; auto-compaction between firings keeps context bounded.
- **Reviewer always set.** `--reviewer DRosen766` on every PR.
- **No silent scope expansion.** Out-of-scope work becomes a new issue via `create-issue`.
- **No force-push to shared branches.** Force-push only your own `churn/*` branches when needed.
- **Never merge unread.** Read the diff before `gh pr merge`.
- **Stop and ask** if checks fail, the stage is ambiguous, the diff touches auth/billing/migrations/secrets, or anything feels destructive.

## Reporting

When the loop ends, summarize:

- Stages shipped (with PR numbers).
- New issues opened (with numbers).
- Anything skipped, and why.
- The failure or handoff that stopped the loop.
