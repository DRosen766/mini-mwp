# Delegation: the main agent routes, owning personas execute

The main Claude Code agent is a **router and integrator**, not the default executor. Stage work is delegated to the persona whose domain owns it. The main agent only does work directly when no persona fits — cross-cutting glue, repo hygiene, skill plumbing, PR mechanics.

This file is the methodology layer. The skills (`churn`, `next`, `create-issue`) operationalize it. Projects that use the pattern provide the team→persona routing config locally; mini-mwp stays repo-agnostic.

## The rule

**Delegation is mandatory, not optional.** When a stage / task has an owning persona, the main agent must hand execution to that persona's lead sub-agent (via the `Agent` tool with `subagent_type: <lead>`) before doing implementation work. Direct execution of team-owned stage work by the main agent is a workflow violation — call it out and correct.

The main agent **retains**:

- Stage selection and pickup discipline (per `task-pickup.md`).
- Worktree setup and the worktree-first gate (per `workflow-worktrees.md`).
- PR mechanics: branch, push, open PR, set reviewer.
- `STATUS.md` updates (the live ticker is repo-wide state, not a team's deliverable).
- Merge wait, cleanup.
- The forward-looking pass — landscape scans range across all teams' plans, so the router is the right layer to do them.
- Any stage with no clear team owner.

## Where ownership comes from

Allocation has **two layers** — team and specialist — both optional, both signals to the routing layer.

**Team allocation** (which lead owns the stage) is derivable from, in order:

1. **The plan doc** — front-matter (`team: <name>`) or an explicit owner field in the plan header.
2. **The GitHub issue** — a `team:*` label.
3. **The skill's own judgment** — based on stage title and content, falling back to the project's designated triage persona (often the personal-assistant role) when the signal is ambiguous or cross-cutting.

**Specialist allocation** (which sub-agent within the team should do the work) is optional and derivable from:

1. **The GitHub issue** — an `assignee:<persona>` or `specialist:<persona>` label, or the issue body's `## Allocation` section naming a specialist.
2. **The plan doc** — a per-stage allocation hint (e.g., a `Specialist:` field on the stage entry).

Specialist allocation does **not** bypass the lead. The main agent still routes to the lead; the brief tells the lead to delegate to the named specialist rather than choosing one. This preserves the audit trail (the lead saw the work and signed off on the delegation) while honoring the explicit assignment. If no specialist is named, the lead chooses or does the work themselves.

If the project has no routing config and no team signals, the skill falls back to direct main-agent execution. Delegation is a layer projects opt into by providing `.claude/agents/` + a routing convention; it's not a hard prerequisite for the methodology to work.

## How delegation runs

Once the owning team is determined:

1. **Open the worktree first** (worktree gate from `workflow-worktrees.md` still runs before anything else, including delegation).
2. **Invoke the lead** via the `Agent` tool with `subagent_type: <lead-persona-name>` and a self-contained brief (see "Brief template" below). The lead works inside the worktree the main agent opened.
3. **The lead executes** — implementing the stage, possibly further delegating one level to its sub-agents. Sub-agents do **not** re-delegate; the chain depth is at most lead → sub-agent.
4. **The lead returns** a summary of what shipped: files touched, decisions made, follow-ups noticed.
5. **The main agent picks back up** for the wrap: forward-looking landscape scan, docs sweep, PR open, status updates, merge, cleanup.

## Brief template

The failure mode this pattern is designed to defeat: **a lead sub-agent without enough context produces shallow work, and the main agent silently redoes it.** The mitigation is the brief — it must be self-contained enough that the lead doesn't need to ask follow-up questions.

A brief includes:

- **Stage goal** — one sentence, what success looks like.
- **Plan-doc path** — `docs/plans/000N_<slug>.md` or wherever plans live in this project.
- **Prior stage outputs** — what previous stages of this phase shipped, and where they live. Without this the lead can't tell which decisions are settled.
- **Acceptance criteria** — crisp, ideally checkboxed.
- **Branch name** — so the lead knows where its commits land.
- **Expected artifacts** — files to create, files to edit, decisions to document.
- **Specialist allocation, if any** — "delegate this to `<specialist>`" if the issue named one. Lead honors the assignment rather than choosing.
- **Constraints** — project conventions, gotchas (`CLAUDE.md` references), things explicitly out of scope.

If the lead returns something unusable, the diagnosis is "the brief was thin," not "bypass delegation." Fix the brief template in the calling skill.

## What good looks like

After this pattern lands in a project:

- Commit logs attribute stages to the lead that executed them — via a PR-body trailer (`Executed-By: <lead>`) or a persona-prefixed commit subject. The audit trail tells you who owned what.
- A team-owned stage's `/churn` run shows a sub-agent invocation in the transcript. The main agent's direct file edits during that stage are limited to STATUS.md, branch/PR plumbing, and final merge.
- Domains that were previously invisible because nothing routed to them (business, legal, ops, design) start producing artifacts authored through their respective leads, surfacing gaps the main agent would have papered over.

## What stays out of scope

- **No new persona files invented by the methodology.** Persona definitions live in the project's `.claude/agents/`. This methodology only describes how the skills route to them.
- **No automatic re-delegation chains beyond one level.** Lead → sub-agent is the maximum; sub-agents do not re-delegate.
- **No persona invocation for ops glue.** Worktree creation, PR opening, status updates, merge mechanics — those are main-agent work by design. Delegating these would just add a hop without adding signal.
- **No hard requirement.** If a project doesn't define personas or a routing config, the skills fall back to direct execution. The pattern is opt-in.

## Relation to other docs

- `file-roles.md` — STATUS.md, plan docs, and architecture docs are repo-wide state the main agent owns. Persona-specific deliverables live in the project's domain directories.
- `task-pickup.md` — pickup discipline runs before delegation. The main agent picks the stage; only then does it route to the owner.
- `workflow-worktrees.md` — the worktree-first gate runs before delegation. The lead works inside an already-opened worktree.
- `skills/churn/SKILL.md`, `skills/next/SKILL.md`, `skills/create-issue/SKILL.md` — the operational entry points that implement the routing.
