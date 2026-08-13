#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
test_root="$(mktemp -d)"
release_dir="${test_root}/release"
formula="${test_root}/oring.rb"
version="9.8.7"

cleanup() {
  rm -rf "${test_root}"
}
trap cleanup EXIT

run_ruby() {
  if command -v ruby >/dev/null 2>&1
  then
    ruby "$@"
  else
    brew ruby -- "$@"
  fi
}

write_checksum() {
  local archive="$1"
  if command -v shasum >/dev/null 2>&1
  then
    shasum -a 256 "${archive}" >"${archive}.sha256"
  else
    sha256sum "${archive}" >"${archive}.sha256"
  fi
}

mkdir -p "${release_dir}"
for target in darwin-arm64 darwin-x64 linux-arm64 linux-x64
do
  stage="${test_root}/${target}"
  mkdir -p "${stage}"
  printf '#!/bin/sh\necho %s\n' "${version}" >"${stage}/oring"
  chmod +x "${stage}/oring"
  archive="oring-v${version}-${target}.tar.gz"
  tar -czf "${release_dir}/${archive}" -C "${stage}" oring
  (
    cd "${release_dir}"
    write_checksum "${archive}"
  )
done

ORING_FORMULA_PATH="${formula}" \
  ORING_RELEASE_DIR="${release_dir}" \
  "${script_dir}/update-oring.sh" "v${version}"

run_ruby -c "${formula}"
grep -q 'version "9.8.7"' "${formula}"
grep -q 'on_macos do' "${formula}"
grep -q 'on_linux do' "${formula}"
grep -q 'oring-v9.8.7-darwin-arm64.tar.gz' "${formula}"
grep -q 'oring-v9.8.7-linux-x64.tar.gz' "${formula}"
grep -q 'bin.install "oring"' "${formula}"
if grep -q 'depends_on "node"' "${formula}"
then
  echo "Generated binary formula unexpectedly depends on Node." >&2
  exit 1
fi

echo "Atomic four-platform Oring formula update passed."
