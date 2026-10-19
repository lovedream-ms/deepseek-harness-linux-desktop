#!/usr/bin/env bash
# Download and reinstall the latest public Linux deb for DeepSeek Harness.
#
# Usage:
#   ./ci/install-latest-linux.sh
#   ./ci/install-latest-linux.sh --tag v0.2.0-rc.2-linux.6
#
# The package is deliberately installed with --reinstall because multiple Linux
# release iterations can share the same Debian product version.
set -Eeuo pipefail

REPOSITORY=${DSH_LINUX_RELEASE_REPOSITORY:-lql341/deepseek-harness-linux-desktop}
REQUESTED_TAG=''
KEEP_DOWNLOADS=0

usage() {
  cat <<'EOF'
Usage: ci/install-latest-linux.sh [options]

Options:
  --tag TAG       Install an exact public release tag instead of latest.
  --keep          Keep the downloaded deb and checksum files.
  -h, --help      Show this help.

Environment:
  DSH_LINUX_RELEASE_REPOSITORY
                  GitHub repository in OWNER/REPO form.
                  Default: lql341/deepseek-harness-linux-desktop
EOF
}

while (($# > 0)); do
  case "$1" in
    --tag)
      (($# >= 2)) || { echo "error: --tag requires a value" >&2; exit 2; }
      REQUESTED_TAG=$2
      shift 2
      ;;
    --keep)
      KEEP_DOWNLOADS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

require_command() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

for command in curl node sha256sum dpkg-deb dpkg-query sudo apt-get; do
  require_command "$command"
done

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/deepseek-harness-update.XXXXXX")
cleanup() {
  if ((KEEP_DOWNLOADS)); then
    echo "Downloaded files kept in: $tmpdir"
  else
    rm -rf -- "$tmpdir"
  fi
}
trap cleanup EXIT

api_url="https://api.github.com/repos/${REPOSITORY}/releases"
if [[ -n "$REQUESTED_TAG" ]]; then
  release_json=$(curl --fail --silent --show-error --location \
    -H 'Accept: application/vnd.github+json' \
    "${api_url}/tags/${REQUESTED_TAG}")
else
  release_json=$(curl --fail --silent --show-error --location \
    -H 'Accept: application/vnd.github+json' \
    "${api_url}/latest")
fi

mapfile -t release_data < <(
  printf '%s' "$release_json" | node -e '
    const fs = require("node:fs")
    const release = JSON.parse(fs.readFileSync(0, "utf8"))
    const deb = release.assets?.find(asset =>
      asset.name.endsWith(".deb") && asset.name.includes("linux-amd64"))
    const sums = release.assets?.find(asset => asset.name === "SHA256SUMS")
    if (!deb || !sums) {
      console.error("release does not contain a Linux amd64 deb and SHA256SUMS")
      process.exit(2)
    }
    console.log(release.tag_name)
    console.log(deb.name)
    console.log(deb.browser_download_url)
    console.log(sums.browser_download_url)
  '
)

(( ${#release_data[@]} == 4 )) || {
  echo "error: could not resolve a Linux release asset" >&2
  exit 1
}

release_tag=${release_data[0]}
deb_name=${release_data[1]}
deb_url=${release_data[2]}
sums_url=${release_data[3]}
deb_path="${tmpdir}/${deb_name}"
sums_path="${tmpdir}/SHA256SUMS"

echo "Release: ${release_tag}"
echo "Asset:   ${deb_name}"
curl --fail --silent --show-error --location --output "$deb_path" "$deb_url"
curl --fail --silent --show-error --location --output "$sums_path" "$sums_url"

expected_sha=$(awk -v name="$deb_name" '$2 == name { print $1; exit }' "$sums_path")
[[ "$expected_sha" =~ ^[0-9a-fA-F]{64}$ ]] || {
  echo "error: SHA256SUMS has no valid entry for ${deb_name}" >&2
  exit 1
}
printf '%s  %s\n' "$expected_sha" "$deb_path" | sha256sum --check --status -

package_arch=$(dpkg-deb --field "$deb_path" Architecture)
[[ "$package_arch" == "amd64" ]] || {
  echo "error: downloaded package architecture is ${package_arch}, expected amd64" >&2
  exit 1
}

echo "Checksum: verified"
echo "Installing with apt (the existing profile and credentials are preserved)..."
sudo apt-get install --reinstall "$deb_path"

echo
echo "Installed package:"
dpkg-query -W -f='${binary:Package}\t${Version}\n' deepseek-harness
echo "Installed release asset: ${release_tag}"
