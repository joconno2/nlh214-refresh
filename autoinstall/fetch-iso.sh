#!/usr/bin/env bash
# Download + SHA256-verify the base Ubuntu Desktop ISO. Portable: runs anywhere with
# curl. Skips if a verified copy already exists.
#   ./fetch-iso.sh [version]     (default 24.04.4)
set -euo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
VER="${1:-24.04.4}"
ISO="ubuntu-${VER}-desktop-amd64.iso"
DEST="$HERE/iso/$ISO"
mkdir -p "$HERE/iso"

# mirrors tried in order; releases.ubuntu.com 403s direct GETs from some networks
MIRRORS=(
  "https://mirrors.kernel.org/ubuntu-releases/${VER}/${ISO}"
  "https://mirror.math.princeton.edu/pub/ubuntu-iso/${VER}/${ISO}"
  "https://ubuntu.osuosl.org/releases/${VER}/${ISO}"
)
UA="Mozilla/5.0"

exp_sha() {
  for base in "https://releases.ubuntu.com/${VER}" "https://mirrors.kernel.org/ubuntu-releases/${VER}"; do
    local s; s="$(curl -s -A "$UA" "$base/SHA256SUMS" 2>/dev/null | awk -v f="$ISO" '$2 ~ f {print $1}' | head -1)"
    [ -n "$s" ] && { echo "$s"; return; }
  done
}
EXP="$(exp_sha)"; [ -n "$EXP" ] || { echo "[x] could not fetch SHA256 for $ISO"; exit 1; }

verify() { [ -f "$DEST" ] && [ "$(sha256sum "$DEST" | awk '{print $1}')" = "$EXP" ]; }

if verify; then echo "[+] $ISO already present and verified"; echo "$DEST"; exit 0; fi

for m in "${MIRRORS[@]}"; do
  echo "[+] downloading $ISO from $m"
  rm -f "$DEST"
  if curl -fSL -A "$UA" --retry 8 --retry-delay 5 -o "$DEST" "$m"; then
    verify && { echo "[+] verified ✓  $DEST"; echo "$DEST"; exit 0; }
    echo "[!] checksum mismatch from this mirror, trying next"
  fi
done
echo "[x] all mirrors failed for $ISO"; exit 1
