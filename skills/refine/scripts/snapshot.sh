#!/bin/sh
# Prints the id of a commit that holds the current working tree, untracked files included.
# It uses a temporary index, so the real index, the working tree and the branch stay untouched.
set -e
idx=$(mktemp)
trap 'rm -f "$idx"' EXIT
cp "$(git rev-parse --git-path index)" "$idx"
GIT_INDEX_FILE=$idx git add -A
tree=$(GIT_INDEX_FILE=$idx git write-tree)
git commit-tree "$tree" -p HEAD -m "refine snapshot"
