#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"${ROOT_DIR}/scripts/check-prerequisites.sh"
"${ROOT_DIR}/bootstrap/kind/create-cluster.sh"
"${ROOT_DIR}/bootstrap/argocd/install.sh"
"${ROOT_DIR}/bootstrap/argocd/apply-root-application.sh"
"${ROOT_DIR}/scripts/verify-platform.sh"
