#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

kubectl config current-context | grep -Fx "kind-${CLUSTER_NAME}" >/dev/null
kubectl wait --for=condition=Ready nodes --all --timeout=180s
expected_kind_image_digest="${KIND_NODE_IMAGE##*@}"
actual_kind_image_digest="$(docker inspect "${CLUSTER_NAME}-control-plane" --format '{{.Image}}')"
if [[ "${actual_kind_image_digest}" != "${expected_kind_image_digest}" ]]; then
  echo "kind control-plane image does not match ${expected_kind_image_digest}: ${actual_kind_image_digest}" >&2
  exit 1
fi
echo "kind control-plane image is pinned at ${actual_kind_image_digest}."
kubectl wait -n "${ARGOCD_NAMESPACE}" --for=condition=Available deployment/argocd-server --timeout=300s
argocd_server_image="$(kubectl get deployment argocd-server -n "${ARGOCD_NAMESPACE}" -o jsonpath='{.spec.template.spec.containers[0].image}')"
if [[ "${argocd_server_image}" != "quay.io/argoproj/argocd:${ARGOCD_VERSION}" ]]; then
  echo "Argo CD server image does not match ${ARGOCD_VERSION}: ${argocd_server_image}" >&2
  exit 1
fi
echo "Argo CD server image is ${argocd_server_image}."
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
for application in root-applications service-a; do
  revision="$(kubectl get application "${application}" -n "${ARGOCD_NAMESPACE}" -o jsonpath='{.spec.source.targetRevision}')"
  if [[ "${revision}" != "${GITOPS_TARGET_REVISION}" ]]; then
    echo "Application '${application}' does not use ${GITOPS_TARGET_REVISION}: ${revision}" >&2
    exit 1
  fi
  echo "Application '${application}' targets immutable GitOps revision ${revision}."
done
kubectl rollout status deployment/"${SERVICE_A_NAME}" -n "${SERVICE_A_NAMESPACE}" --timeout=180s
kubectl wait -n "${SERVICE_A_NAMESPACE}" --for=condition=Ready pod -l "app.kubernetes.io/name=${SERVICE_A_NAME}" --timeout=180s
service_a_image_id="$(kubectl get pods -n "${SERVICE_A_NAMESPACE}" -l "app.kubernetes.io/name=${SERVICE_A_NAME}" -o jsonpath='{.items[0].status.containerStatuses[0].imageID}')"
if [[ "${service_a_image_id}" != *"${SERVICE_A_IMAGE_DIGEST}" ]]; then
  echo "Service A imageID does not include ${SERVICE_A_IMAGE_DIGEST}: ${service_a_image_id}" >&2
  exit 1
fi
echo "Service A imageID is ${service_a_image_id}."
endpoint_ready="$(kubectl get endpointslice -n "${SERVICE_A_NAMESPACE}" -l "kubernetes.io/service-name=${SERVICE_A_NAME}" -o jsonpath='{range .items[*].endpoints[*]}{.conditions.ready}{"\n"}{end}')"
if ! grep -Fxq true <<<"${endpoint_ready}"; then
  echo "Service A has no ready EndpointSlice endpoint." >&2
  exit 1
fi
echo "Service A EndpointSlice has a ready endpoint."
"${ROOT_DIR}/scripts/check-service-a.sh"
