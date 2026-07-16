#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

manifest_file="$(mktemp)"
cleanup() {
  rm -f "${manifest_file}"
}
trap cleanup EXIT

curl --fail --silent --show-error --location "${ARGOCD_INSTALL_MANIFEST_URL}" -o "${manifest_file}"
printf '%s  %s\n' "${ARGOCD_INSTALL_MANIFEST_SHA256}" "${manifest_file}" | shasum -a 256 -c -
echo "Argo CD ${ARGOCD_VERSION} manifest checksum verified."

kubectl create namespace "${ARGOCD_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side -n "${ARGOCD_NAMESPACE}" \
  -f "${manifest_file}"
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
echo "Argo CD ${ARGOCD_VERSION} is installed."
