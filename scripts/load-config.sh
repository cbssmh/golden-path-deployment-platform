#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${ROOT_DIR}/config/platform.env.example"
if [[ -f "${ROOT_DIR}/config/platform.env.local" ]]; then
  CONFIG_FILE="${ROOT_DIR}/config/platform.env.local"
fi
# shellcheck source=/dev/null
source "${CONFIG_FILE}"
