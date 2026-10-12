#!/usr/bin/env bash
# Container-side Debian 13 acceptance checks. The driver runs both modes with
# Docker networking disabled so startup and removal cannot reach package registries.

set -euo pipefail

APP_BIN=/usr/bin/deepseek-harness
APP_ROOT='/opt/DeepSeek Harness'
MODE=${1:-session}

assert_debian_13() {
  . /etc/os-release
  [ "${ID:-}" = debian ] && [ "${VERSION_ID:-}" = 13 ]
}

assert_offline() {
  if awk '$2 == "00000000" && $3 != "00000000" { found = 1 } END { exit !found }' /proc/net/route; then
    echo "FAIL: container unexpectedly has a default IPv4 route" >&2
    exit 1
  fi
  echo "PASS: container has no default IPv4 route"
}

session_check() {
  assert_debian_13
  assert_offline
  dpkg-query -W -f='${Status} ${Version}\n' deepseek-harness | grep -q '^install ok installed '
  test -x "$APP_BIN"

  ELECTRON_RUN_AS_NODE=1 "$APP_BIN" --expose-internals -e '
    const { existsSync } = require("node:fs")
    const skill = process.argv[1]
    if (!existsSync(skill)) {
      console.error(`missing packaged SCNet Skill: ${skill}`)
      process.exit(1)
    }
  ' "$APP_ROOT/resources/app.asar/dsh/node_modules/dsh-scnet/skills/scnet-hpc/SKILL.md"
  echo "PASS: packaged dsh-scnet contains the scnet-hpc Skill"

  export DSH_HOME=/tmp/dsh-home
  export SHOT_DIR=/tmp/dsh-session
  mkdir -p "$DSH_HOME" "$SHOT_DIR"
  timeout 180 dbus-run-session -- xvfb-run -a -s '-screen 0 1280x900x24' \
    /usr/local/bin/desktop-session.sh
  echo "PASS: Debian 13 installed session starts offline with dsh-scnet active"
}

uninstall_check() {
  assert_debian_13
  assert_offline
  dpkg --purge deepseek-harness
  if dpkg-query -W -f='${db:Status-Status}\n' deepseek-harness 2>/dev/null | grep -q installed; then
    echo "FAIL: deepseek-harness remains installed after purge" >&2
    exit 1
  fi
  test ! -e "$APP_BIN"
  test ! -e "$APP_ROOT"
  echo "PASS: Debian 13 purge removed the launcher and application directory"
}

case "$MODE" in
  session) session_check ;;
  uninstall) uninstall_check ;;
  *)
    echo "usage: $0 session|uninstall" >&2
    exit 2
    ;;
esac
