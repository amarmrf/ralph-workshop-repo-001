#!/bin/bash

set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
prompt_file=$(mktemp)
trap 'rm -f "$prompt_file"' EXIT

ralph_commits=$(git -C "$repo_root" log --grep="RALPH" -n 10 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || echo "No RALPH commits found")

cat "$repo_root/plans/prompt.md" > "$prompt_file"
printf "\n\nPrevious RALPH commits:\n%s\n" "$ralph_commits" >> "$prompt_file"

codex exec \
  --dangerously-bypass-approvals-and-sandbox \
  -C "$repo_root" \
  - < "$prompt_file"
