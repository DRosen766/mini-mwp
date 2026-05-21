# Task pickup discipline

How the agent chooses what to work on at the start of a session. The rule set keeps work concentrated inside one plan at a time so each phase drains before the next one starts.

## The rules

**STATUS.md names the current phase.** A `## Current phase` field near the top of `STATUS.md` points at the active plan doc — e.g. `docs/plans/0009_completion_ux.md` — or carries an explicit "no active phase" marker. The picker reads this field before anything else. The field is defined in `file-roles.md`; the pickup rules below key off it.

**Pick from the current phase's plan.** Once the current phase is known, the next stage comes from that plan's open stages, picked by the plan's own sequencing rules (numbered stages, "PR-A blocks PR-B" notes, or risk-first ordering for bug sweeps). Items in STATUS.md's "Next up" or in the GitHub issue tracker that aren't in the current plan are deprioritized — even if they look smaller or more urgent in isolation.

**Drain before switching.** A phase is complete only when every stage in its plan is shipped (or explicitly cut from scope and noted in the plan). While the current phase still has open stages, the picker does not jump to a different plan and does not pick freestanding "Next up" items.

**Switch plans only on a hard blocker or explicit user override.** Two exceptions to "drain before switching":

1. **Hard blocker.** A stage in the current phase is blocked on something the agent can't resolve in-session — waiting on a user decision, an external dependency, an unanswered design question. The blocked stage moves to **Blocked** in STATUS.md with the reason recorded, and the picker prefers another open stage *in the same plan* before considering a switch. Switching plans is the last resort, not the first move.
2. **Explicit user override.** The user says "work on X" or "switch phases." Follow it. Don't relitigate.

**Phase handoff is a two-step pickup.** When the last stage of the current phase ships, the next session's pickup is a two-step decision: (1) choose the next plan and update **Current phase** to point at it, then (2) pick the first stage from that plan. Step 1 is a planning call, not an execution one — if multiple candidate plans exist and the priority isn't obvious, stop and ask rather than guess. After the choice is made, work proceeds inside the new plan under the same drain-before-switching rule.

## Why this exists

A plan exists because a set of stages belongs together — they share design context, test paths, and review attention. Hopping between plans mid-drain forces the human reviewer to re-load context per PR, and stages from a half-drained plan tend to bit-rot as later stages reshape the same area of the code.

Symptom this prevents: three plans each 60% shipped, none mergeable as a complete unit, and the user can't remember which one was the priority.

## What "cleaned out" means in practice

When a plan ships its last stage, the plan doc itself is closed out — every stage carries a "shipped" marker per `workflow-stages.md`, and STATUS.md's **Activity log** records each merge. Open issues that were referenced by the plan but didn't get done are either rolled forward into the next plan or explicitly cut. The plan doc isn't deleted; it stays as the historical record of what that phase shipped.

## Relation to other docs

- `file-roles.md` — defines the `Current phase` field on STATUS.md.
- `workflow-stages.md` — plans (`docs/plans/000N_*.md`) are the unit a phase is built from.
- The `cowork-churn` skill is the autonomous counterpart to these rules — it already operates plan-scoped and drains one plan's stages before stopping. This doc is the manual-session equivalent and the authoritative rule set both follow.
