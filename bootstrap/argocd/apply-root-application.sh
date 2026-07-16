#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

sed \
  -e "s|__ARGOCD_NAMESPACE__|${ARGOCD_NAMESPACE}|g" \
  -e "s|__GITOPS_REPOSITORY_URL__|${GITOPS_REPOSITORY_URL}|g" \
  -e "s|__GITOPS_TARGET_REVISION__|${GITOPS_TARGET_REVISION}|g" \
  -e "s|__GITOPS_ROOT_PATH__|${GITOPS_ROOT_PATH}|g" \
  "${ROOT_DIR}/bootstrap/argocd/root-application.yaml" | kubectl apply -f -
echo "Root Application is applied."
