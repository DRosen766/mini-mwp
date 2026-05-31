---
name: plan
description: Interactively draft a phase plan document under `docs/plans/000N_<phase>.md` by interviewing the user until you have enough detail to implement confidently. Use when the user says "/plan" or asks to "plan" / "draft a plan" / "spec out" a new feature, refactor, or body of work. The skill produces the plan doc only — it does not file issues or implement.
---

# plan

A conversational drafting assistant for phase plan docs. The user arrives with a brief explanation of what they want to do; the skill interviews them until the plan has the detail needed for a future session (human or agent) to pick it up and ship without re-litigating scope or design.

The single deliverable: a new `docs/plans/000N_<phase>.md` checked into the working tree (uncommitted is fine — the user decides when to land it). The skill **does not** file GitHub issues (that's `create-issue`), does not implement (that's `next` and the execution skills), and does not commit/PR unless the user asks.

The plan-doc shape this skill targets is the one described in `mini-mwp/methodology/workflow-stages.md` ("Per-feature plans") and `mini-mwp/skills/create-issue/SKILL.md` step 1. Read those first if you're unsure what fields belong.

---

## Operating principle

**Interview, don't autocomplete.** The user's opening message is a seed, not a spec. Your job is to ask the questions that surface the gaps — scope edges, design alternatives, sequencing, acceptance — and only write the doc once you can answer "would a fresh session know what to do?" with yes.

Ask in small batches (one `AskUserQuestion` call with 1–3 focused questions), not one huge wall. Each batch should reduce the largest current uncertainty. Stop interviewing as soon as the remaining unknowns are implementation details that belong in the doing, not the planning.

If the user's seed is already detailed enough (they handed you a near-spec), skip ahead — don't manufacture questions to look thorough.

---

## Steps

### 1. Read the seed and the surrounding context

The user's opening message is the seed. Before asking anything, also:

```bash
ls docs/plans/
```

Read the most recent 1–2 plan docs to match house style (heading levels, section names, sequencing format). If the project has `CLAUDE.md`, skim it for conventions that constrain scope (stack, deferred features, gotchas).

Pick the next sequence number: highest existing `000N_` + 1.

### 2. Decide the interview shape

From the seed, categorize the work — this determines what you need to learn:

- **Feature / new capability** → scope edges, user-visible behavior, data/state changes, acceptance.
- **Refactor / restructuring** → what changes shape, what stays compatible, migration path, how to verify nothing regressed.
- **Bug-fix phase / hardening** → symptoms in scope, what's explicitly out, repro coverage, acceptance.
- **Infra / tooling** → what it unblocks, who/what consumes it, rollback story.

Different shapes need different questions. Don't run a generic checklist.

### 3. Interview in batches

Drive the conversation with `AskUserQuestion`. Each batch targets the **largest current uncertainty**. Useful question families (pick the ones that apply — don't ask all of them):

- **Scope edges.** What's explicitly in? What's explicitly out, even if tempting? Where are the "we'll do this later" cuts?
- **Design decisions.** Are there non-obvious choices with real alternatives? If yes, which alternatives were considered and why was the chosen one preferred? (This becomes the "Design decisions" section — see `create-issue/SKILL.md`.)
- **Sequencing.** Is this one stage or several? If several, what's the order, and what does each stage hand off to the next?
- **Acceptance.** What does "done" look like — observable, not aspirational? How will the user verify in the running app / via tests / via inspection?
- **Constraints.** Hard constraints from existing code, prior decisions, external systems, deadlines, hardware, etc.
- **Owning team / specialist.** (Only if the project has `.claude/agents/` personas — see `mini-mwp/methodology/delegation.md`.) Which team owns this phase? Any specialist within it?
- **Risks and unknowns.** What might force a re-plan? What needs a spike before the rest can be sequenced?

Use plain back-and-forth (no `AskUserQuestion`) when the answer is open-ended ("walk me through how you imagine X"). Use `AskUserQuestion` when there are concrete option sets to pick between.

Between batches, **paraphrase what you've learned** in one short paragraph so the user can correct drift early. Don't ask for confirmation of every micro-fact — only summarize at meaningful checkpoints.

### 4. Know when to stop

Stop interviewing when:

- Scope edges are crisp (you can name something just outside scope).
- Every non-obvious design choice has a recorded reason.
- Sequencing exists (even if it's just "single stage").
- Acceptance is observable.
- Remaining unknowns are genuine implementation details, not planning gaps.

If the user gets impatient ("just write it"), stop and write the doc, but flag the remaining gaps inline as `**Open:** ...` bullets so they don't get lost.

### 5. Open a worktree if not already in one — HARD GATE

Before writing the doc, check whether the session is already in a worktree:

```bash
git rev-parse --show-toplevel
git worktree list
```

If the current toplevel is the main checkout (not a worktree), create a **sibling** worktree via `git worktree add` — this matches the worktree-first gate from `mini-mwp/methodology/workflow-worktrees.md`, and the sibling placement matches the rest of the methodology's tooling (see `skills/create-issue/SKILL.md` step 2).

```bash
REPO=$(basename "$(git rev-parse --show-toplevel)")
SLUG=<short-kebab-slug-of-plan>
git worktree add ../${REPO}-wt-plan-${SLUG} -b plan/${SLUG} main
```

Do **not** use the built-in `EnterWorktree` tool — it creates the worktree inside a Claude-managed subdir, not as a sibling of the main checkout, which breaks the rest of the methodology's path assumptions.

Because manual `cd` does not persist across tool calls, **use absolute paths for every subsequent file operation in this skill** rather than trying to switch the session's working directory. Capture the worktree path:

```bash
WORKTREE=$(cd .. && pwd)/${REPO}-wt-plan-${SLUG}
```

…and pass `$WORKTREE/docs/plans/000N_<slug>.md` to the Write tool. For git commands that need to run inside the worktree, chain them in a single Bash call with `cd "$WORKTREE" && ...`.

If the session is already in a worktree (e.g., the user is mid-task and wants to draft a follow-up plan from there), reuse it — don't nest worktrees. Note in the final report which worktree the doc landed in so the user knows where to commit it.

If `git worktree add` fails (branch already exists, path collision, etc.), stop and report the error. Do not fall back to writing in the main checkout.

### 6. Write the plan doc

Create `docs/plans/000N_<slug>.md` with the structure below. Use the slug form the existing plan docs use (kebab-case, descriptive, short).

```markdown
# Phase 000N — <Title>

## Scope
<1–3 sentences: what this phase covers and why now. Name what's explicitly out if the cut is non-obvious.>

## Design decisions
<Only include this section if there are non-obvious choices. For each: the decision, the alternatives considered, the reason for the pick. One short paragraph each — this is the "why" that future implementers shouldn't re-litigate. Omit the section entirely for straightforward work.>

## Issues in scope
- **#TBD — <title>.** <one-line summary + acceptance>
- **#TBD — <title>.** <one-line summary + acceptance>

(Or leave a single placeholder bullet if issues haven't been carved out yet:
`- _Issues to be filed via `/create-issue` once scope is locked._`)

## Sequencing
<Only if multi-stage. List stages in order, each with a one-line handoff to the next. Omit for single-issue plans.>

## Acceptance
<Observable success criteria for the phase as a whole. If acceptance is per-issue, point at the Issues in scope bullets instead.>

## Open questions
<Only if any remain. Bullet list. These are gaps the user knowingly left for later.>
```

Match the heading levels, prose density, and section order of the most recent plan doc in the repo if it diverges from the template above — house style wins over the template.

### 7. Report and hand off

Print a short summary:

```
Drafted: docs/plans/000N_<slug>.md
Worktree: <path>
Stages: <N, or "single stage">
Open questions: <count, or "none">
Next: file issues via `/create-issue` (per bullet under "Issues in scope"), then `/next` to pick one up.
```

Do **not** commit, push, or open a PR. The user decides when to land the doc — it's often bundled with the first `/create-issue` PR or with the first implementation worktree.

If the project has a `STATUS.md` and the user wants this to be the active phase, point that out — but don't edit `STATUS.md` yourself unless asked. Switching **Current phase** is a user decision (see `mini-mwp/methodology/task-pickup.md`).

---

## What this skill does NOT do

- File GitHub issues. Use `/create-issue` once the plan's "Issues in scope" bullets are ready to be tracked.
- Implement any of the planned work. Use `/next` to pick up the first issue.
- Update `STATUS.md` **Current phase** unless explicitly asked — phase activation is a user call.
- Edit an existing plan doc. Plans are append-only once they're shipping (see `workflow-stages.md`). If the user wants to add an issue to an existing plan, that's `/create-issue`, not this.
- Ask exhaustive checklist questions when the seed is already detailed. Interview to close gaps, not to look thorough.
