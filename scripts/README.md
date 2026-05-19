# Scripts

Deterministic, non-AI utilities that operate on a product repo that has mini-mwp mounted as a submodule. Each script does one job and is safe to re-run.

## Available scripts

- **`install.sh`** — wire mini-mwp skills into the product repo's `.claude/skills/` directory (per-skill symlinks). Idempotent.

## Conventions

- **Run from the product repo root.** Scripts assume `mini-mwp/` is a direct child of `$PWD` and refuse to run from inside mini-mwp itself.
- **Idempotent by default.** Re-running a script after pulling submodule updates should be the standard way to pick up new content (new skills, etc.), not a special-case operation.
- **Fail loudly on ambiguity.** If a script would clobber a file the user didn't put there (e.g. a non-symlink at the destination), it errors out rather than guessing.
- **No product-repo-specific assumptions.** Same constraint as skills: no project names, no stack-specific paths, no hardcoded remotes.
