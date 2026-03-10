#!/bin/bash

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <iterations>"
  exit 1
fi

repo_root=$(cd "$(dirname "$0")/.." && pwd)

for ((i=1; i<=$1; i++)); do
  prompt_file=$(mktemp)
  result_file=$(mktemp)
  trap 'rm -f "$prompt_file" "$result_file"' EXIT

  echo "------- ITERATION $i --------"

  ralph_commits=$(git -C "$repo_root" log --grep="RALPH" -n 10 --format="%H%n%ad%n%B---" --date=short 2>/dev/null || echo "No RALPH commits found")

  cat "$repo_root/plans/prompt.md" > "$prompt_file"
  printf "\n\nPrevious RALPH commits:\n%s\n" "$ralph_commits" >> "$prompt_file"

  codex exec \
    --dangerously-bypass-approvals-and-sandbox \
    -C "$repo_root" \
    -o "$result_file" \
    - < "$prompt_file"

  result=$(cat "$result_file")

  if [[ "$result" == *"<promise>NO MORE TASKS</promise>"* ]]; then
    echo "Ralph complete after $i iterations."
    exit 0
  fi

  if [[ "$result" == *"<promise>ABORT</promise>"* ]]; then
    echo "Ralph aborted after $i iterations."
    exit 1
  fi

  rm -f "$prompt_file" "$result_file"
  trap - EXIT
done
