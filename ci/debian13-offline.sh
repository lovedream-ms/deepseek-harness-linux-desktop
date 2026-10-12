#!/usr/bin/env bash
# Build a Debian 13 image containing one deb, then exercise startup and removal
# with Docker networking disabled.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
DEB_FILE=${1:-}

if [ -z "$DEB_FILE" ] || [ ! -f "$DEB_FILE" ]; then
  echo "usage: $0 /path/to/deepseek-harness.deb" >&2
  exit 2
fi

DEB_FILE=$(realpath "$DEB_FILE")
CONTEXT=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/dsh-debian13.XXXXXX")
DEB_NAME=$(basename "$DEB_FILE")
IMAGE="dsh-debian13-offline:$(sha256sum "$DEB_FILE" | cut -c1-12)"

cleanup() {
  rm -rf -- "$CONTEXT"
  docker image rm -f "$IMAGE" >/dev/null 2>&1 || true
}
trap cleanup EXIT

cp "$REPO_ROOT/ci/debian13-offline.Dockerfile" "$CONTEXT/Dockerfile"
cp "$REPO_ROOT/ci/debian13-package-check.sh" "$CONTEXT/debian13-package-check.sh"
cp "$REPO_ROOT/ci/desktop-session.sh" "$CONTEXT/desktop-session.sh"
cp "$DEB_FILE" "$CONTEXT/$DEB_NAME"

docker build --pull --build-arg "DEB_FILE=$DEB_NAME" --tag "$IMAGE" "$CONTEXT"
docker run --rm --network none --shm-size 512m "$IMAGE" session
docker run --rm --network none "$IMAGE" uninstall
