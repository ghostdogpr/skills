#!/bin/sh
# Restores the working tree to a commit printed by snapshot.sh, untracked files included.
# Files created since the snapshot are deleted. The index and the branch stay untouched.
# Usage: restore.sh <snapshot commit>. Run it from the repository root.
set -e
base=$1
[ -n "$base" ] || { echo "usage: restore.sh <snapshot commit>" >&2; exit 1; }
now=$("$(dirname "$0")/snapshot.sh")
git diff --name-only --diff-filter=A -z "$base" "$now" | xargs -0 rm -f --
git restore --source="$base" --worktree -- .
