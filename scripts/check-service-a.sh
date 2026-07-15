#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

tmp_response="$(mktemp)"
cleanup() {
  if [[ -n "${port_forward_pid:-}" ]]; then
    kill "${port_forward_pid}" 2>/dev/null || true
  fi
  rm -f "${tmp_response}"
}
trap cleanup EXIT

kubectl port-forward -n "${SERVICE_A_NAMESPACE}" "service/${SERVICE_A_NAME}" "${SERVICE_A_PORT}:${SERVICE_A_PORT}" >/dev/null 2>&1 &
port_forward_pid=$!
for _ in $(seq 1 20); do
  if curl --fail --silent "http://127.0.0.1:${SERVICE_A_PORT}/" >"${tmp_response}"; then
    break
  fi
  sleep 1
done

grep -F '"service": "service-a"' "${tmp_response}" >/dev/null
grep -F '"version": "0.1.0"' "${tmp_response}" >/dev/null
grep -F '"status": "running"' "${tmp_response}" >/dev/null
cat "${tmp_response}"
