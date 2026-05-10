# Task Tracker App — Conventions and Gotchas

Distilled from the Task Tracker App's `CLAUDE.md`. The first concrete example of a project-conventions doc in this repo. As that project's conventions evolve, sync them here too — it's the public-facing version.

## Workflow rules

**Always PR into `main`, via a worktree.** Never commit directly to `main`. Use `git worktree add ../tasks-wt-<slug> -b <branch> main`, work there, push, open PR. Cleanup with `git worktree remove` after merge. Even one-line fixes go through a PR. (See methodology/workflow-worktrees.md.)

**Validate iOS changes locally before pushing.** Run `./scripts/validate-ios.sh` (xcodegen + no-link xcodebuild compile against Simulator) and confirm `BUILD SUCCEEDED` before declaring iOS work ready. CI is not the canonical pre-PR gate.

**Print `xed` command when iOS feature is ready to test.** End the response with the absolute path: `xed /Users/dannyrosen/.../tasks-wt-<slug>/ios`. If `ios/project.yml` was touched, regenerate first: `(cd <worktree>/ios && xcodegen generate) && xed <worktree>/ios`.

## CI / distribution

**TestFlight triggers on push to `main`, not on tags.** `testflight.yml` migrated from `on: push: tags: [v*]` to `on: push: branches: [main]`. Marketing version comes from `ios/project.yml` `MARKETING_VERSION` (bump manually); build number auto-bumps from latest TestFlight. `paths-ignore` skips docs/backend/MCP merges; `concurrency: cancel-in-progress` keeps only the tip of `main` on TestFlight. `workflow_dispatch` is the manual escape hatch.

**Don't run TestFlight twice per merge.** If `auto-tag.yml` and `validate.yml` exist alongside the `push: main` trigger, every merge can dispatch TestFlight twice. Pick one path: direct trigger (current, simplest) or the validate→auto-tag→dispatch chain. Don't enable both.

## Backend / Supabase

**Dashboard Edge Function editor is single-file.** The Supabase dashboard's editor doesn't resolve relative imports (e.g. `../_shared/cors.ts`). CLI deploys (`supabase functions deploy`) bundle `_shared/` automatically; dashboard pastes need helpers inlined. Prefer the CLI.

**`supabase db push` is forward-only.** Hosted Supabase has no `db revert`. Recovery from a bad migration means writing a fixup migration (e.g. `0006_revert_thing.sql`). Never push a migration to `main` that hasn't been tested locally against `supabase start` + `supabase db reset`.

**Migrations are append-only.** Never edit `0001_initial.sql` after it's been applied. Add `0003_*.sql`, `0004_*.sql`, etc.

## Code conventions

**Type naming: `TaskItem`, NOT `Task`.** The Swift model is named `TaskItem` deliberately to avoid colliding with `_Concurrency.Task`. Symptom of the collision: every `Task { try? await ... }` async-spawn site fails to compile. If a stray `Task` appears as a type (return type, field, parameter), rename to `TaskItem`.

**No business logic in the iOS/client app.** iOS, MCP server, and any future client (web, watchOS) all hit the same Postgres-shaped reality through RLS. Push logic into Edge Functions or SQL functions so every client gets it for free.

## Agent tooling

**Cowork sandbox boundaries.** Cowork sandbox sessions don't have `git`, `gh`, `supabase` CLI, or outbound network to GitHub/Supabase APIs. They're good for code edits and MCP tool calls in the workspace mount; bad for deploys, git ops, or any CLI requiring auth. Route deploys + git work through Claude Code on the Mac.

---

Many more project-specific gotchas live in the project's `CLAUDE.md` itself (Apple Sign-In bundle-ID-as-Client-ID, hosted Supabase `ALTER DATABASE` block, GH Actions empty-secret truthiness, audit log JWT-claim reading, RLS + `security definer` triggers, soft-delete model, `UICollectionViewList` section-identity traps, Xcode 26 SDK floor, etc.). Sync them here as they stabilize.
