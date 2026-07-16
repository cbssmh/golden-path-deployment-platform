#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side -n "${ARGOCD_NAMESPACE}" \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
for deployment in \
  argocd-applicationset-controller \
  argocd-dex-server \
  argocd-notifications-controller \
  argocd-redis \
  argocd-repo-server \
  argocd-server; do
  kubectl rollout status --namespace "${ARGOCD_NAMESPACE}" "deployment/${deployment}" --timeout=300s
done
kubectl rollout status --namespace "${ARGOCD_NAMESPACE}" statefulset/argocd-application-controller --timeout=300s
echo "Argo CD is installed."
