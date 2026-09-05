#!/usr/bin/env bash
# NLH214 lab provisioner — run on a fresh Ubuntu 24.04 install as root.
#   sudo ./provision.sh <hostname>        # full build
#   sudo ./provision.sh <hostname> 03     # run one module (by number prefix)
#
# Reference build pulled from the FY22 fleet 2026-09-03. See BUILD.md.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"
source lib/common.sh
need_root

HOST="${1:-$(hostname)}"
ONLY="${2:-}"

. /etc/os-release
[ "${VERSION_ID:-}" = "24.04" ] || warn "expected Ubuntu 24.04, found ${VERSION_ID:-unknown} — continuing"

run() {
  local m="$1"
  [ -n "$ONLY" ] && [[ "$m" != *"$ONLY"* ]] && return 0
  log "=== $m ==="
  bash "lib/$m" "$HOST"
}

run 01-base.sh
run 02-nis-nfs.sh
run 03-scheme.sh
run 04-xpilot-ai.sh
run 05-editors-tools.sh
run 06-admins.sh

log "done. verify: id <student> ; ls $NFS_MOUNT/students ; swl ; xpilots --help ; sudo -lU dgezgin"
