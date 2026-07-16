#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

[[ "${GITOPS_TARGET_REVISION}" == "v0.1.1" ]]
[[ "${SERVICE_A_IMAGE_DIGEST}" == sha256:* ]]
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
grep -F "image: ${KIND_NODE_IMAGE}" "${ROOT_DIR}/bootstrap/kind/cluster-config.yaml" >/dev/null
grep -F "${ARGOCD_INSTALL_MANIFEST_URL}" "${ROOT_DIR}/config/platform.env.example" >/dev/null
grep -F "${ARGOCD_INSTALL_MANIFEST_SHA256}" "${ROOT_DIR}/config/platform.env.example" >/dev/null
echo "PASS: Root Application manifest contains the required GitOps source fields."
echo "PASS: platform validation completed."
