#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

grep -F '__GITOPS_REPOSITORY_URL__' "${ROOT_DIR}/bootstrap/argocd/root-application.yaml" >/dev/null
if [[ -d "${ROOT_DIR}/${GITOPS_LOCAL_PATH}" ]]; then
  kubectl kustomize "${ROOT_DIR}/${GITOPS_LOCAL_PATH}/applications/root" >/dev/null
  kubectl kustomize "${ROOT_DIR}/${GITOPS_LOCAL_PATH}/environments/dev" >/dev/null
  kubectl kustomize "${ROOT_DIR}/${GITOPS_LOCAL_PATH}/services/service-a/overlays/dev" >/dev/null
else
  echo "SKIP: local GitOps repository not found at ${GITOPS_LOCAL_PATH}."
fi
grep -F 'kind: Application' "${ROOT_DIR}/bootstrap/argocd/root-application.yaml" >/dev/null
grep -F 'repoURL: __GITOPS_REPOSITORY_URL__' "${ROOT_DIR}/bootstrap/argocd/root-application.yaml" >/dev/null
grep -F 'path: __GITOPS_ROOT_PATH__' "${ROOT_DIR}/bootstrap/argocd/root-application.yaml" >/dev/null
echo "PASS: Root Application manifest contains the required GitOps source fields."
echo "PASS: platform validation completed."
