#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
for target in prerequisites cluster-create argocd-install argocd-projects bootstrap verify service-a-check lint validate verify-gitops-release ci destroy; do
  grep -E "^${target}:" "${ROOT_DIR}/Makefile" >/dev/null
done
echo "PASS: required Makefile targets are present."
