#!/bin/sh
# Counts non-blank, non-comment lines per file and in total.
# Usage: count-lines.sh [--at <commit>] <file or directory>...
# With --at, it counts the files as they are in that commit. Run it inside the repository.
# Comment detection is approximate: a line that starts with the language's comment marker is a comment.
at=
if [ "$1" = "--at" ]; then
  at=$2
  shift 2
fi
top=$(git rev-parse --show-toplevel 2>/dev/null)
prefix=$(git rev-parse --show-prefix 2>/dev/null)

# Prints the comment pattern for a source file, or fails for any other file.
pattern() {
  case "$1" in
    *.scala|*.sc|*.java|*.kt|*.kts|*.groovy|*.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.go|*.rs|*.c|*.h|*.cc|*.cpp|*.cxx|*.hpp|*.cs|*.fs|*.swift|*.dart|*.php|*.zig)
      echo '^[[:space:]]*($|//|/\*|\*)' ;;
    *.py|*.rb|*.sh|*.bash|*.ex|*.exs|*.jl|*.pl|*.cr|*.nim)
      echo '^[[:space:]]*($|#)' ;;
    *.hs|*.lua|*.elm|*.purs)
      echo '^[[:space:]]*($|--|\{-|-\})' ;;
    *.clj|*.cljs|*.cljc|*.el|*.lisp|*.scm|*.rkt)
      echo '^[[:space:]]*($|;)' ;;
    *.ml|*.mli)
      echo '^[[:space:]]*($|\(\*|\*)' ;;
    *) return 1 ;;
  esac
}

list() {
  if [ -n "$at" ]; then
    case "$1" in
      "$top"/*) rel=${1#"$top"/} ;;
      *) rel=$prefix${1#./} ;;
    esac
    git -C "$top" ls-tree -r --name-only "$at" -- "$rel"
  else
    find "$1" -type f 2>/dev/null
  fi
}

content() {
  if [ -n "$at" ]; then git -C "$top" show "$at:$1"; else cat "$1"; fi
}

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
for path in "$@"; do
  list "$path" | sort | while read -r f; do
    p=$(pattern "$f") || continue
    echo "$(content "$f" | grep -cvE "$p") $f"
  done
done > "$tmp"
cat "$tmp"
awk '{ s += $1 } END { print s + 0, "total" }' "$tmp"
