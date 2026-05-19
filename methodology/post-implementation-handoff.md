# Post-implementation handoff

After implementing a feature, the agent's response should hand the user explicit steps to verify the work in the running system — not just "I'm done."

## The rule

**End every implementation with verification steps the user can perform.** For an app, that means a walkthrough: which screen to open, what to tap, what to type, what to expect to see. For a backend change, the equivalent commands and expected output. The agent has just done the work and knows what it exercised; the user should not have to invent the test path from scratch.

## What good handoff steps look like

For an app feature, each step should be (a) something the user can do without referring back to the diff, and (b) tied to an observable outcome. Shape:

1. Open the app and navigate to `<screen>`.
2. `<concrete action>` — e.g. tap "Add task", type "Buy milk", set due date to tomorrow.
3. Expect `<observable result>` — e.g. task appears at the top of the list, due-date badge shows "Tomorrow", notification scheduled for 9am tomorrow.
4. Re-entry / edge case, if relevant — e.g. close and reopen the app; the task is still there.

If the agent can't name the observable outcome, the handoff isn't ready.

## Why it matters

The methodology already says human review sits between stages (`workflow-worktrees.md`). Explicit steps make that review tractable instead of "go figure out if it works." They also catch the integration gaps the agent can't see — code compiles and tests pass, but only the user can verify it feels right in the running app.

Symptom this prevents: the user opens the worktree, runs the app, and has to ask "wait, what was this supposed to do, and how do I see it?" That moment means the handoff was incomplete.

## What to leave out

- Tests the agent already ran (unit, lint, type-check). Those are part of the implementation, not the handoff.
- Generic "make sure it works" prompts.
- Steps that require the user to read code to know what to do.
