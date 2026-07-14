#!/usr/bin/env bash
set -euo pipefail

required=(docker kind kubectl make git curl)
optional=(shellcheck yamllint kubeconform)
missing=0

for tool in "${required[@]}"; do
  if command -v "${tool}" >/dev/null 2>&1; then
    echo "PASS: ${tool} found at $(command -v "${tool}")"
  else
    echo "FAIL: ${tool} is required but was not found."
    missing=1
  fi
done

if kubectl kustomize --help >/dev/null 2>&1; then
  echo "PASS: Kustomize is available through kubectl kustomize."
else
  echo "FAIL: kubectl kustomize is unavailable."
  missing=1
fi

if docker info >/dev/null 2>&1; then
  echo "PASS: Docker daemon is reachable."
else
  echo "FAIL: Docker daemon is not reachable."
  missing=1
fi

for tool in "${optional[@]}"; do
  if command -v "${tool}" >/dev/null 2>&1; then
    echo "PASS: optional ${tool} found."
  else
    echo "SKIP: optional ${tool} is not installed."
  fi
done

exit "${missing}"
