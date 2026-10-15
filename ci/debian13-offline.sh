#!/usr/bin/env bash
# Build Debian 13 images containing the candidate deb, then exercise startup,
# removal and (when a base deb is provided) offline upgrade with networking disabled.

set -euo pipefail

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
DEB_FILE=${1:-}
BASE_DEB_FILE=${2:-}

if [ -z "$DEB_FILE" ] || [ ! -f "$DEB_FILE" ]; then
  echo "usage: $0 /path/to/candidate.deb [/path/to/base.deb]" >&2
  exit 2
fi
if [ -n "$BASE_DEB_FILE" ] && [ ! -f "$BASE_DEB_FILE" ]; then
  echo "base deb not found: $BASE_DEB_FILE" >&2
  exit 2
fi

DEB_FILE=$(realpath "$DEB_FILE")
if [ -n "$BASE_DEB_FILE" ]; then
  BASE_DEB_FILE=$(realpath "$BASE_DEB_FILE")
fi
CONTEXT=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/dsh-debian13.XXXXXX")
CANDIDATE_CONTEXT_NAME=deepseek-harness-candidate.deb
BASE_CONTEXT_NAME=deepseek-harness-base.deb
IMAGE="dsh-debian13-offline:$(sha256sum "$DEB_FILE" | cut -c1-12)"
UPGRADE_IMAGE=

cleanup() {
  rm -rf -- "$CONTEXT"
  docker image rm -f "$IMAGE" >/dev/null 2>&1 || true
  if [ -n "$UPGRADE_IMAGE" ]; then
    docker image rm -f "$UPGRADE_IMAGE" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

cp "$REPO_ROOT/ci/debian13-offline.Dockerfile" "$CONTEXT/Dockerfile"
cp "$REPO_ROOT/ci/debian13-package-check.sh" "$CONTEXT/debian13-package-check.sh"
cp "$REPO_ROOT/ci/desktop-session.sh" "$CONTEXT/desktop-session.sh"
cp "$DEB_FILE" "$CONTEXT/$CANDIDATE_CONTEXT_NAME"

docker build --pull \
  --build-arg "DEB_FILE=$CANDIDATE_CONTEXT_NAME" \
  --build-arg "CANDIDATE_FILE=$CANDIDATE_CONTEXT_NAME" \
  --tag "$IMAGE" "$CONTEXT"
# Xvfb does not reliably model the plain second-launch restore path. That assertion is covered by
# the real desktop-session jobs; keep the Debian container focused on offline install, first launch,
# Bundle activation, dsh:// registration/activation, and removal.
docker run --rm --network none --shm-size 512m \
  -e SKIP_HEADLESS_RELAUNCH_CHECK=1 \
  "$IMAGE" session
docker run --rm --network none "$IMAGE" uninstall

if [ -n "$BASE_DEB_FILE" ]; then
  cp "$BASE_DEB_FILE" "$CONTEXT/$BASE_CONTEXT_NAME"
  UPGRADE_IMAGE="dsh-debian13-upgrade:$(sha256sum "$BASE_DEB_FILE" "$DEB_FILE" | sha256sum | cut -c1-12)"
  docker build \
    --build-arg "DEB_FILE=$BASE_CONTEXT_NAME" \
    --build-arg "CANDIDATE_FILE=$CANDIDATE_CONTEXT_NAME" \
    --tag "$UPGRADE_IMAGE" "$CONTEXT"
  for profile_mode in legacy-default disabled custom; do
    docker run --rm --network none --shm-size 512m \
      -e SKIP_HEADLESS_RELAUNCH_CHECK=1 \
      -e PROFILE_EXPECTATION="$profile_mode" \
      "$UPGRADE_IMAGE" upgrade
  done
fi
