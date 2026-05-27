# Skills

Repo-agnostic skills that embody the mini-mwp methodology. Designed to be consumed by product repos that mount mini-mwp as a git submodule.

## Available skills

- **`create-issue/`** — file a GitHub issue, index it in the right `docs/plans/` phase doc, and land the doc edit via a worktree+PR.
- **`next/`** — pick the next task from the current phase and open a worktree for it. Enforces task-pickup discipline and the worktree-first gate.
- **`status-update/`** — the STATUS.md live-ticker update protocol (see `methodology/file-roles.md`).

## How a product repo wires these in

mini-mwp is added to a product repo as a submodule, then the installer wires per-skill symlinks into `.claude/skills/`:

```bash
# from the product repo root
git submodule add <mini-mwp-remote> mini-mwp
./mini-mwp/scripts/install.sh
```

The installer is idempotent — re-run it after `git submodule update --remote` to pick up new skills. See `scripts/README.md` for what it does.

### Why per-skill symlinks (not a whole-folder symlink)

Claude Code looks for one skill per direct child of `.claude/skills/`. Symlinking the whole `mini-mwp/skills/` folder under a namespace would put skills at `.claude/skills/mini-mwp/<name>/SKILL.md`, which isn't the discovered layout. Per-skill symlinks (`.claude/skills/<name> -> ../../mini-mwp/skills/<name>`) keep each skill at the depth Claude Code expects.

### Manual setup (if you can't run the script)

```bash
mkdir -p .claude/skills
ln -s ../../mini-mwp/skills/status-update .claude/skills/status-update
# … one symlink per skill
```

## Constraints these skills are written to

- **Repo-agnostic.** No project names, no hardcoded paths beyond the project root, no stack-specific assumptions. If a skill needs project-specific input, it asks.
- **Follow the methodology.** Skills are operationalizations of pieces already documented under `methodology/`. New skills should cite the methodology file they encode.
- **No runtime side effects in this repo.** Skills are markdown instructions for the agent, not executable scripts. If a skill needs to invoke shell commands, the agent does so in the consuming repo — never here.
