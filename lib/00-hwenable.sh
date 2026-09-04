#!/usr/bin/env bash
# hardware enablement for the MSI Aegis ZS2 (AMD Ryzen 9 9900X / B650 / RTX 5080 /
# Realtek LAN + Wi-Fi 6E/7). Ubuntu 24.04 GA kernel 6.8 is too old for this silicon;
# we move to the OEM kernel (6.17) + latest firmware + NVIDIA 580-open (Blackwell) and
# carry Realtek dkms as a fallback for the NIC.
#
# Runs offline from the baked apt pool during autoinstall, or online if a NIC is up.
source "$(dirname "$(readlink -f "$0")")/common.sh"
need_root

POOL="${OFFLINE_POOL:-}"          # dir of .debs baked onto the USB; empty = use network

# Offline path: bulk-install the whole pool with dpkg. apt can't resolve deps with no
# network (no package indexes), but the pool already carries the full closure, so we
# let dpkg topo-sort it — two passes to settle dkms/header ordering.
if [ -n "$POOL" ] && ls "$POOL"/*.deb >/dev/null 2>&1; then
  log "offline: installing $(ls "$POOL"/*.deb | wc -l) pooled debs via dpkg"
  dpkg -i "$POOL"/*.deb >/dev/null 2>&1 || true
  dpkg -i "$POOL"/*.deb 2>&1 | grep -iE "error|depend" | head || true
  installed() { dpkg -l "$1" 2>/dev/null | grep -q "^ii"; }
  offline_install() { for p in "$@"; do installed "$p" && return 0; done; warn "not in pool: $*"; return 1; }
else
  offline_install() { apt_install "$@"; }
fi

log "OEM kernel 6.17 (newest-hardware enablement on the LTS base)"
offline_install linux-oem-24.04d || offline_install linux-oem-24.04c || \
  warn "OEM kernel not installed — falling back to whatever the ISO shipped"

log "latest linux-firmware (Wi-Fi 6E/7 + Realtek/AMD blobs)"
offline_install linux-firmware

log "NVIDIA open modules (RTX 5080 / Blackwell) — 580 current, 570 fallback"
offline_install nvidia-driver-580-open || offline_install nvidia-driver-570-open \
  || warn "nvidia driver not installed — check Secure Boot / pool"

log "Realtek NIC dkms fallback (covers RTL8125/8126 if the in-kernel driver misses)"
offline_install dkms build-essential || true
offline_install r8125-dkms || warn "r8125-dkms unavailable (fine if NIC is 8111H/8125 in-kernel)"
offline_install r8126-dkms || true

log "hardware enablement done — reboot into the OEM kernel before validating GPU/NIC"
