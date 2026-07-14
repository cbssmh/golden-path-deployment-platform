#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

if kind get clusters | grep -Fxq "${CLUSTER_NAME}"; then
  echo "kind cluster '${CLUSTER_NAME}' already exists; reusing it."
else
  kind create cluster --name "${CLUSTER_NAME}" --config "${ROOT_DIR}/bootstrap/kind/cluster-config.yaml"
fi

CONTEXT="kind-${CLUSTER_NAME}"
kubectl config use-context "${CONTEXT}" >/dev/null
kubectl wait --for=condition=Ready nodes --all --timeout=180s
echo "Cluster '${CLUSTER_NAME}' is ready with context '${CONTEXT}'."
