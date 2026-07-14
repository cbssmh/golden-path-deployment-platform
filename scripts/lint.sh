#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

git diff --check
while IFS= read -r shell_file; do
  bash -n "${shell_file}"
done < <(find bootstrap scripts -type f -name '*.sh' -print)
if command -v shellcheck >/dev/null 2>&1; then
  find bootstrap scripts -type f -name '*.sh' -exec shellcheck {} +
else
  echo "SKIP: shellcheck is not installed."
fi
if command -v yamllint >/dev/null 2>&1; then
  yamllint .
else
  echo "SKIP: yamllint is not installed."
fi
if command -v markdownlint >/dev/null 2>&1; then
  markdownlint '**/*.md'
else
  echo "SKIP: markdownlint is not installed."
fi
echo "PASS: lint checks completed."
