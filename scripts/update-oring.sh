#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]
then
  echo "Usage: $0 <version>" >&2
  exit 2
fi

version="${1#v}"
if [[ ! "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]
then
  echo "Invalid semantic version: $1" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "${script_dir}/.." && pwd)"
formula="${repo_dir}/Formula/oring.rb"
tarball_url="https://registry.npmjs.org/@knowledgekit/oring/-/oring-${version}.tgz"
download_dir="$(mktemp -d)"

cleanup() {
  rm -rf "${download_dir}"
}
trap cleanup EXIT

echo "Downloading @knowledgekit/oring@${version}..."
curl --fail --location --silent --show-error "${tarball_url}" \
  --output "${download_dir}/oring.tgz"
sha256="$(shasum -a 256 "${download_dir}/oring.tgz" | awk '{print $1}')"

ruby - "${formula}" "${tarball_url}" "${sha256}" <<'RUBY'
formula, url, sha256 = ARGV
content = File.read(formula)

unless content.sub!(%r{  url "https://registry\.npmjs\.org/@knowledgekit/oring/-/oring-[^"]+\.tgz"}, "  url \"#{url}\"")
  abort "Could not find the Oring npm tarball URL in #{formula}"
end

unless content.sub!(/  sha256 "[0-9a-f]{64}"/, "  sha256 \"#{sha256}\"")
  abort "Could not find the SHA-256 checksum in #{formula}"
end

File.write(formula, content)
RUBY

brew style "${formula}"

echo "Updated Formula/oring.rb to ${version} (${sha256})."
echo "Review the diff, then open a pull request; GitHub Actions will run the full audit."
