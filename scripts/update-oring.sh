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
    shasum -a 256 -c "${checksum}"
  )
  tar -tzf "${download_dir}/${archive}" | grep -qx 'oring'
done

checksum_for() {
  local target="$1"
  awk '{print $1}' "${download_dir}/oring-v${version}-${target}.tar.gz.sha256"
}

ruby - "${formula_candidate}" "${version}" \
  "$(checksum_for darwin-arm64)" \
  "$(checksum_for darwin-x64)" \
  "$(checksum_for linux-arm64)" \
  "$(checksum_for linux-x64)" <<'RUBY'
path, version, darwin_arm64, darwin_x64, linux_arm64, linux_x64 = ARGV
release = "https://github.com/KnowledgeKitAI/oring/releases/download/v#{version}"

content = <<~FORMULA
  class Oring < Formula
    desc "Agentic development toolkit for specs, sessions, and Git workflows"
    homepage "https://github.com/KnowledgeKitAI/oring"
    version "#{version}"
    license "MIT"

    on_macos do
      if Hardware::CPU.arm?
        url "#{release}/oring-v#{version}-darwin-arm64.tar.gz"
        sha256 "#{darwin_arm64}"
      else
        url "#{release}/oring-v#{version}-darwin-x64.tar.gz"
        sha256 "#{darwin_x64}"
      end
    end

    on_linux do
      if Hardware::CPU.arm?
        url "#{release}/oring-v#{version}-linux-arm64.tar.gz"
        sha256 "#{linux_arm64}"
      else
        url "#{release}/oring-v#{version}-linux-x64.tar.gz"
        sha256 "#{linux_x64}"
      end
    end

    def install
      bin.install "oring"
    end

    test do
      assert_match version.to_s, shell_output("\#{bin}/oring --version")
      assert_match "Agentic development toolkit", shell_output("\#{bin}/oring --help")
      assert_match '"sessions"', shell_output("\#{bin}/oring tui --demo --json")
    end
  end
FORMULA

File.write(path, content)
RUBY

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
