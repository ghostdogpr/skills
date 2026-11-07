#!/bin/sh
# Counts non-blank, non-comment lines per file and in total.
# Usage: count-lines.sh [--at <commit>] [-f <list file>] [<file or directory>...]
# A list file holds one path per line. With --at, it counts the files as they are in that commit.
# Only files git tracks or would track are counted, so build output never is. Run it inside the repository.
# Files of an unknown type are skipped, and stderr names their extensions.
# Comment detection is approximate: a line that starts with the language's comment marker is a comment.
at=
list_file=
while :; do
  case "$1" in
    --at) at=$2; shift 2 ;;
    -f) list_file=$2; shift 2 ;;
    *) break ;;
  esac
done
[ -z "$list_file" ] || [ -r "$list_file" ] || { echo "cannot read $list_file" >&2; exit 1; }
top=$(git rev-parse --show-toplevel 2>/dev/null)
prefix=$(git rev-parse --show-prefix 2>/dev/null)

# Prints the comment pattern for a source file, or fails for any other file.
pattern() {
  case "$1" in
    *.scala|*.sc|*.sbt|*.java|*.kt|*.kts|*.groovy|*.ts|*.tsx|*.mts|*.cts|*.js|*.jsx|*.mjs|*.cjs|*.go|*.rs|*.c|*.h|*.cc|*.cpp|*.cxx|*.hpp|*.hh|*.cs|*.fs|*.swift|*.dart|*.php|*.zig|*.proto)
      echo '^[[:space:]]*($|//|/\*|\*)' ;;
    *.py|*.pyi|*.rb|*.sh|*.bash|*.ex|*.exs|*.jl|*.pl|*.cr|*.nim|*.yml|*.yaml|*.toml)
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
    git -C "$top" -c core.quotePath=false ls-tree -r --name-only "$at" -- "$rel"
  else
    git -c core.quotePath=false ls-files -co --exclude-standard -- "$1"
  fi
}

content() {
  if [ -n "$at" ]; then git -C "$top" show "$at:$1"; else cat "$1"; fi
}

count() {
  list "$1" | sort -u | while IFS= read -r f; do
    [ -n "$at" ] || [ -f "$f" ] || continue
    if p=$(pattern "$f"); then
      echo "$(content "$f" | grep -cvE "$p") $f"
    else
      echo "$f" >> "$skipped"
    fi
  done
}

tmp=$(mktemp)
skipped=$(mktemp)
trap 'rm -f "$tmp" "$skipped"' EXIT
{
  if [ -n "$list_file" ]; then
    while IFS= read -r path; do
      [ -z "$path" ] || count "$path"
    done < "$list_file"
  fi
  for path in "$@"; do
    count "$path"
  done
} > "$tmp"
cat "$tmp"
awk '{ s += $1 } END { print s + 0, "total" }' "$tmp"
awk -F/ '{ n = split($NF, part, "."); e = n > 1 ? "." part[n] : $NF; c[e]++ } END { for (e in c) print "skipped:", c[e], e }' "$skipped" | sort >&2
