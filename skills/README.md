# Skills

Repo-agnostic skills that embody the mini-mwp methodology. Designed to be consumed by product repos that mount mini-mwp as a git submodule.

## Available skills

- **`status-update/`** — the STATUS.md live-ticker update protocol (see `methodology/file-roles.md`).

More will land as methodology pieces stabilize.

## How a product repo wires these in

mini-mwp is intended to be added to a product repo as a submodule:

```bash
# from the product repo root
git submodule add <mini-mwp-remote> mini-mwp
```

Then symlink the skills into the product repo's Claude skills directory. Two patterns work:

### Whole-folder symlink (simpler)

```bash
mkdir -p .claude/skills
ln -s ../../mini-mwp/skills .claude/skills/mini-mwp
```

Every skill under `mini-mwp/skills/` becomes available, and pulling submodule updates surfaces new skills automatically. Slight cost: the product repo opts in to all skills, including ones it may not use.

### Per-skill symlinks (more selective)

```bash
mkdir -p .claude/skills
ln -s ../../mini-mwp/skills/status-update .claude/skills/status-update
```

The product repo explicitly opts in to each skill. New skills in the submodule won't appear until linked.

## Constraints these skills are written to

- **Repo-agnostic.** No project names, no hardcoded paths beyond the project root, no stack-specific assumptions. If a skill needs project-specific input, it asks.
- **Follow the methodology.** Skills are operationalizations of pieces already documented under `methodology/`. New skills should cite the methodology file they encode.
- **No runtime side effects in this repo.** Skills are markdown instructions for the agent, not executable scripts. If a skill needs to invoke shell commands, the agent does so in the consuming repo — never here.
