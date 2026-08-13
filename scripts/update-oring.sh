#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]
then
  echo "Usage: $0 <version>" >&2
  exit 2
fi

version="${1#v}"
if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
then
  echo "Invalid stable semantic version: $1" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "${script_dir}/.." && pwd)"
formula="${ORING_FORMULA_PATH:-${repo_dir}/Formula/oring.rb}"
release_base_url="${ORING_RELEASE_BASE_URL:-https://github.com/KnowledgeKitAI/oring/releases/download/v${version}}"
release_dir="${ORING_RELEASE_DIR:-}"
download_dir="$(mktemp -d)"
formula_candidate="$(mktemp)"

cleanup() {
  rm -rf "${download_dir}"
  rm -f "${formula_candidate}"
}
trap cleanup EXIT

targets=(darwin-arm64 darwin-x64 linux-arm64 linux-x64)

verify_checksum() {
  local checksum="$1"
  if command -v shasum >/dev/null 2>&1
  then
    shasum -a 256 -c "${checksum}"
  else
    sha256sum --check "${checksum}"
  fi
}

for target in "${targets[@]}"
do
  archive="oring-v${version}-${target}.tar.gz"
  checksum="${archive}.sha256"
  if [[ -n "${release_dir}" ]]
  then
    cp "${release_dir}/${archive}" "${download_dir}/${archive}"
    cp "${release_dir}/${checksum}" "${download_dir}/${checksum}"
  else
    curl --fail --location --silent --show-error \
      "${release_base_url}/${archive}" \
      --output "${download_dir}/${archive}"
    curl --fail --location --silent --show-error \
      "${release_base_url}/${checksum}" \
      --output "${download_dir}/${checksum}"
  fi

  (
    cd "${download_dir}"
    verify_checksum "${checksum}"
  )
  tar -tzf "${download_dir}/${archive}" | grep -qx 'oring'
done

darwin_arm64="$(awk '{print $1}' "${download_dir}/oring-v${version}-darwin-arm64.tar.gz.sha256")"
darwin_x64="$(awk '{print $1}' "${download_dir}/oring-v${version}-darwin-x64.tar.gz.sha256")"
linux_arm64="$(awk '{print $1}' "${download_dir}/oring-v${version}-linux-arm64.tar.gz.sha256")"
linux_x64="$(awk '{print $1}' "${download_dir}/oring-v${version}-linux-x64.tar.gz.sha256")"

ruby "${script_dir}/render-oring-formula.rb" \
  "${formula_candidate}" \
  "${version}" \
  "${darwin_arm64}" \
  "${darwin_x64}" \
  "${linux_arm64}" \
  "${linux_x64}"

ruby -c "${formula_candidate}"
if command -v brew >/dev/null 2>&1
then
  brew style "${formula_candidate}"
fi

mkdir -p "$(dirname "${formula}")"
mv "${formula_candidate}" "${formula}"

echo "Updated ${formula} to standalone Oring ${version}."
echo "Review the diff and let pull-request CI audit all four host targets."
echo "This script does not commit, push, merge, tag, or publish anything."
