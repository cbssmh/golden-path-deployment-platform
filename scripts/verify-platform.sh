#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

kubectl config current-context | grep -Fx "kind-${CLUSTER_NAME}" >/dev/null
kubectl wait --for=condition=Ready nodes --all --timeout=180s
kubectl wait -n "${ARGOCD_NAMESPACE}" --for=condition=Available deployment/argocd-server --timeout=300s
kubectl get application root-applications -n "${ARGOCD_NAMESPACE}" >/dev/null

wait_for_application() {
  local name="$1"
  local phase
  for _ in $(seq 1 60); do
    phase="$(kubectl get application "${name}" -n "${ARGOCD_NAMESPACE}" -o jsonpath='{.status.sync.status}:{.status.health.status}' 2>/dev/null || true)"
    if [[ "${phase}" == "Synced:Healthy" ]]; then
      echo "Application '${name}' is Synced and Healthy."
      return 0
    fi
    sleep 5
  done
  echo "Application '${name}' did not become Synced:Healthy (last state: ${phase:-unknown})." >&2
  return 1
}

wait_for_application root-applications
wait_for_application service-a
kubectl rollout status deployment/"${SERVICE_A_NAME}" -n "${SERVICE_A_NAMESPACE}" --timeout=180s
kubectl wait -n "${SERVICE_A_NAMESPACE}" --for=condition=Ready pod -l "app.kubernetes.io/name=${SERVICE_A_NAME}" --timeout=180s
"${ROOT_DIR}/scripts/check-service-a.sh"
