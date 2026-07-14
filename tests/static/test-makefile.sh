#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
for target in prerequisites cluster-create argocd-install bootstrap verify service-a-check lint validate destroy; do
  grep -E "^${target}:" "${ROOT_DIR}/Makefile" >/dev/null
done
echo "PASS: required Makefile targets are present."
