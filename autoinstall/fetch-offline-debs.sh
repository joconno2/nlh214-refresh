#!/usr/bin/env bash
# Harvest the hardware-enablement .debs (+ all deps) into autoinstall/pool/ so the
# USB can bring up GPU + NIC with no network. Runs a clean noble container so the
# dependency closure matches the target, not cachy.
set -euo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
POOL="$HERE/pool"
mkdir -p "$POOL"

# Everything the GA kernel can't provide for the Aegis ZS2. Extras (r8126-dkms) are
# best-effort — the container skips any not in noble.
PKGS="linux-oem-24.04d linux-firmware dkms build-essential \
nvidia-driver-570-open r8125-dkms r8126-dkms"

echo "[+] harvesting into $POOL via ubuntu:24.04 container"
docker run --rm -v "$POOL:/pool" ubuntu:24.04 bash -c '
set -e
sed -i "s/^Components: main$/Components: main restricted universe multiverse/" \
  /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || true
apt-get update -y
mkdir -p /var/cache/apt/archives/partial
for p in '"$PKGS"'; do
  echo "== $p =="
  apt-get install -y --download-only --no-install-recommends "$p" \
    || echo "!! skip $p (not available in noble)"
done
cp -n /var/cache/apt/archives/*.deb /pool/ 2>/dev/null || true
'
echo "[+] pool now has $(ls "$POOL"/*.deb 2>/dev/null | wc -l) debs, $(du -sh "$POOL" | cut -f1)"
