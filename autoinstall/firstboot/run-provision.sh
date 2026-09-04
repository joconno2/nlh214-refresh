#!/usr/bin/env bash
# First on-campus boot: run the full lab provisioner online, then disarm.
set -euo pipefail
REPO=/opt/nlh214-refresh
LOG=/var/log/nlh214-firstboot.log
exec > >(tee -a "$LOG") 2>&1
echo "=== nlh214 first-boot provision $(date -Is) ==="

# One USB images the whole lab, so every clone boots with the same baked hostname.
# Self-name uniquely from the machine serial (fallback: MAC) before touching NIS/NFS.
current="$(hostname)"
if [ "$current" = "nlh214-box" ] || [ -z "$current" ]; then
  serial="$(dmidecode -s system-serial-number 2>/dev/null | tr -cd '[:alnum:]')"
  [ -z "$serial" ] && serial="$(ip link | awk '/ether/{gsub(/:/,"");print $2;exit}')"
  uniq="nlh214-$(echo "$serial" | tail -c 7)"
  echo "renaming $current -> $uniq"
  hostnamectl set-hostname "$uniq"
fi

# hardware enablement already ran in the installer; here we do the lab stack online.
bash "$REPO/provision.sh" "$(hostname)" || { echo "provision failed — see $LOG"; exit 1; }
touch /var/lib/nlh214-provisioned
systemctl disable nlh214-firstboot.service || true
echo "=== done ==="
