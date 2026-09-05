#!/usr/bin/env bash
# One-command NLH214 USB build. Runs on ANY Linux box with docker + xorriso — not tied
# to a specific machine. Fetches the base ISO, harvests the offline driver pool, and
# remasters the autoinstall image.
#
#   ./build.sh [hostname-base] [ubuntu-version]
#   defaults: nlh214-box  24.04.4
set -euo pipefail
REPO="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
AI="$REPO/autoinstall"
HOST="${1:-nlh214-box}"
VER="${2:-24.04.4}"

echo "== preflight: required tooling =="
miss=0
need() { command -v "$1" >/dev/null 2>&1 && echo "  ok  $1" || { echo "  MISSING  $1  ($2)"; miss=1; }; }
need docker   "Docker Engine — harvests the noble-matched driver pool"
need xorriso  "package: xorriso — remasters the ISO"
need curl     "package: curl"
need openssl  "package: openssl — hashes the install password"
need rsync    "package: rsync"
need sha256sum "package: coreutils"
if [ "$miss" = 1 ]; then
  cat <<'EOF'

Install the missing tools, then re-run. Examples:
  Debian/Ubuntu:  sudo apt install -y docker.io xorriso curl openssl rsync coreutils
  Fedora/RHEL:    sudo dnf install -y moby-engine xorriso curl openssl rsync coreutils
  Arch:           sudo pacman -S --needed docker libisoburn curl openssl rsync coreutils
(Docker also needs your user in the 'docker' group, or run this with sudo.)
EOF
  exit 1
fi
docker info >/dev/null 2>&1 || { echo "[x] docker daemon not reachable (start it, or add your user to the docker group)"; exit 1; }

echo "== 1/3 base ISO =="
BASE="$("$AI/fetch-iso.sh" "$VER" | tail -1)"

echo "== 2/3 offline driver pool =="
if ls "$AI/pool/"*.deb >/dev/null 2>&1; then
  echo "  pool present ($(ls "$AI/pool/"*.deb | wc -l) debs) — skipping harvest (delete pool/ to refresh)"
else
  "$AI/fetch-offline-debs.sh"
fi

echo "== 3/3 remaster =="
"$AI/build-iso.sh" "$BASE" "$HOST"

echo
echo "USB image ready. Write it (≥16GB stick):"
echo "  lsblk"
echo "  sudo dd if=$AI/iso/nlh214-autoinstall.iso of=/dev/sdX bs=4M status=progress oflag=sync"
