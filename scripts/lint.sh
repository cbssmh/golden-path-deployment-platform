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
  find . \
    \( -path './.git' -o -path './ci/node_modules' \) -prune -o \
    -type f \( -name '*.yaml' -o -name '*.yml' \) -print0 |
    xargs -0 yamllint
else
  echo "SKIP: yamllint is not installed."
fi
if command -v markdownlint >/dev/null 2>&1; then
  markdownlint --ignore 'ci/node_modules/**' '**/*.md'
else
  echo "SKIP: markdownlint is not installed."
fi
echo "PASS: lint checks completed."
