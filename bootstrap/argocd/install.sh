#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n "${ARGOCD_NAMESPACE}" \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --namespace "${ARGOCD_NAMESPACE}" --for=condition=Available deployment/argocd-server --timeout=300s

sed \
  -e "s|__ARGOCD_NAMESPACE__|${ARGOCD_NAMESPACE}|g" \
  -e "s|__GITOPS_REPOSITORY_URL__|${GITOPS_REPOSITORY_URL}|g" \
  -e "s|__GITOPS_TARGET_REVISION__|${GITOPS_TARGET_REVISION}|g" \
  -e "s|__GITOPS_ROOT_PATH__|${GITOPS_ROOT_PATH}|g" \
  "${ROOT_DIR}/bootstrap/argocd/root-application.yaml" | kubectl apply -f -
echo "Argo CD and Root Application are installed."
