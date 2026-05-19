#!/usr/bin/env bash
#
# install.sh — wire mini-mwp skills into a product repo.
#
# Usage (from the product repo root, after adding mini-mwp as a submodule):
#
#   ./mini-mwp/scripts/install.sh
#
# What it does:
# - Ensures .claude/skills/ exists in the product repo.
# - For each skill at mini-mwp/skills/<name>/, creates a relative symlink at
#   .claude/skills/<name> -> ../../mini-mwp/skills/<name>.
# - Idempotent: leaves up-to-date symlinks alone, replaces stale ones, refuses
#   to clobber non-symlink entries.
#

set -euo pipefail

# Resolve the mini-mwp dir from this script's location, regardless of cwd.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MWP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$MWP_DIR/skills"
PRODUCT_ROOT="$PWD"

# Reject the case where someone runs this from inside mini-mwp itself.
case "$PRODUCT_ROOT/" in
  "$MWP_DIR"/*)
    echo "ERROR: run install.sh from the product repo root, not from inside mini-mwp." >&2
    echo "  cd <product repo root>" >&2
    echo "  ./mini-mwp/scripts/install.sh" >&2
    exit 1
    ;;
esac

if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "ERROR: no skills/ directory found at $SKILLS_SRC" >&2
  exit 1
fi

# Sanity check: mini-mwp should sit as a direct child of the product root, so
# the relative target path .claude/skills/<name> -> ../../mini-mwp/skills/<name>
# actually resolves.
if [[ ! -d "$PRODUCT_ROOT/mini-mwp" ]] || [[ "$(cd "$PRODUCT_ROOT/mini-mwp" && pwd)" != "$MWP_DIR" ]]; then
  echo "ERROR: expected '$PRODUCT_ROOT/mini-mwp' to be the mini-mwp submodule." >&2
  echo "  Add it first:  git submodule add <mini-mwp-remote> mini-mwp" >&2
  exit 1
fi

SKILLS_DEST="$PRODUCT_ROOT/.claude/skills"
mkdir -p "$SKILLS_DEST"

linked=0
skipped=0
replaced=0
for skill_dir in "$SKILLS_SRC"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  link_path="$SKILLS_DEST/$skill_name"
  target="../../mini-mwp/skills/$skill_name"

  if [[ -L "$link_path" ]]; then
    if [[ "$(readlink "$link_path")" == "$target" ]]; then
      skipped=$((skipped + 1))
      continue
    fi
    echo "Replacing stale symlink: .claude/skills/$skill_name"
    rm "$link_path"
    ln -s "$target" "$link_path"
    replaced=$((replaced + 1))
    continue
  fi

  if [[ -e "$link_path" ]]; then
    echo "ERROR: .claude/skills/$skill_name exists and is not a symlink." >&2
    echo "  Move it aside and re-run, or delete it if it's stale." >&2
    exit 1
  fi

  ln -s "$target" "$link_path"
  echo "Linked: .claude/skills/$skill_name -> $target"
  linked=$((linked + 1))
done

echo ""
echo "Done. $linked newly linked, $replaced replaced, $skipped already up-to-date."
echo "Restart your Claude session if one is open, so the new skills are picked up."
