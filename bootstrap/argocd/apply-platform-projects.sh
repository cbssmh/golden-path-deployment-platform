#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

render_project() {
  local manifest="$1"
  sed \
    -e "s|__ARGOCD_NAMESPACE__|${ARGOCD_NAMESPACE}|g" \
    -e "s|__GITOPS_REPOSITORY_URL__|${GITOPS_REPOSITORY_URL}|g" \
    "${manifest}"
}

# The replacement project must exist before the permissive fallback is locked.
render_project "${ROOT_DIR}/bootstrap/argocd/platform-project.yaml" | kubectl apply -f -

default_applications="$(
  kubectl get applications.argoproj.io -n "${ARGOCD_NAMESPACE}" \
    -o jsonpath='{range .items[?(@.spec.project=="default")]}{.metadata.name}{"\n"}{end}'
)"
if [[ -n "${default_applications}" ]]; then
  echo "Refusing to restrict the default AppProject while Applications still use it:" >&2
  printf '%s\n' "${default_applications}" >&2
  echo "GP-2A supports a clean v0.2.0 bootstrap, not an in-place v0.1.1 migration." >&2
  exit 1
fi

render_project "${ROOT_DIR}/bootstrap/argocd/default-project.yaml" | kubectl apply -f -
echo "Platform AppProject is applied and the default AppProject is restricted."
