#!/usr/bin/env bash
# First on-campus boot: run the full lab provisioner online, then disarm.
set -euo pipefail
REPO=/opt/nlh214-refresh
LOG=/var/log/nlh214-firstboot.log
exec > >(tee -a "$LOG") 2>&1
echo "=== nlh214 first-boot provision $(date -Is) ==="

# network-online.target can fire before campus DHCP/DNS is usable. Wait until apt can
# actually reach the archive (up to ~5 min) so provisioning doesn't fail on empty lists.
echo "waiting for network + apt reachability..."
for i in $(seq 1 30); do
  if apt-get update -y >/dev/null 2>&1; then echo "apt reachable after ${i} tries"; break; fi
  sleep 10
done

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
