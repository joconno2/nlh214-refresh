#!/usr/bin/env bash
# First on-campus boot: run the full lab provisioner online, then disarm.
set -euo pipefail
REPO=/opt/nlh214-refresh
LOG=/var/log/nlh214-firstboot.log
exec > >(tee -a "$LOG") 2>&1
echo "=== nlh214 first-boot provision $(date -Is) ==="
# hardware enablement already ran in the installer; here we do the lab stack online.
bash "$REPO/provision.sh" "$(hostname)" || { echo "provision failed — see $LOG"; exit 1; }
touch /var/lib/nlh214-provisioned
systemctl disable nlh214-firstboot.service || true
echo "=== done ==="
