#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "${ROOT_DIR}/scripts/load-config.sh"

release_file="${ROOT_DIR}/releases/${GITOPS_TARGET_REVISION}-release-manifest.yaml"
if [[ ! -f "${release_file}" ]]; then
  echo "FAIL: release manifest does not exist: ${release_file}" >&2
  exit 1
fi

identity="$({ ruby -ryaml -e '
  release = YAML.load_file(ARGV.fetch(0)).fetch("release")
  gitops = release.fetch("gitops")
  puts [
    gitops.fetch("repository"),
    gitops.fetch("tag"),
    gitops.fetch("commit"),
    gitops.fetch("annotated_tag_object")
  ].join("\t")
' "${release_file}"; })"
IFS=$'\t' read -r repository tag expected_commit expected_tag_object <<<"${identity}"

if [[ "${repository}" != "${GITOPS_REPOSITORY_URL}" ]]; then
  echo "FAIL: release GitOps repository does not match platform configuration." >&2
  exit 1
fi
if [[ "${tag}" != "${GITOPS_TARGET_REVISION}" ]]; then
  echo "FAIL: release GitOps tag does not match platform target revision." >&2
  exit 1
fi
if [[ ! "${expected_commit}" =~ ^[0-9a-f]{40}$ || ! "${expected_tag_object}" =~ ^[0-9a-f]{40}$ ]]; then
  echo "FAIL: release GitOps commit or tag object is not a full SHA-1 identity." >&2
  exit 1
fi

tag_ref="refs/tags/${tag}"
remote_refs="$(git ls-remote --exit-code --tags "${repository}" "${tag_ref}" "${tag_ref}^{}")"
remote_tag_object="$(awk -v ref="${tag_ref}" '$2 == ref {print $1}' <<<"${remote_refs}")"
remote_commit="$(awk -v ref="${tag_ref}^{}" '$2 == ref {print $1}' <<<"${remote_refs}")"

if [[ -z "${remote_tag_object}" ]]; then
  echo "FAIL: remote GitOps tag ${tag} does not exist." >&2
  exit 1
fi
if [[ -z "${remote_commit}" ]]; then
  echo "FAIL: remote GitOps tag ${tag} is not annotated or has no peeled target." >&2
  exit 1
fi
if [[ "${remote_tag_object}" != "${expected_tag_object}" ]]; then
  echo "FAIL: remote GitOps annotated tag object does not match release metadata." >&2
  exit 1
fi
if [[ "${remote_commit}" != "${expected_commit}" ]]; then
  echo "FAIL: remote GitOps peeled commit does not match release metadata." >&2
  exit 1
fi

echo "PASS: GitOps ${tag} annotated tag object and peeled commit match release metadata."
