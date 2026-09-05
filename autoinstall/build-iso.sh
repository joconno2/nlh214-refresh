#!/usr/bin/env bash
# Remaster an Ubuntu 24.04.3 Desktop ISO into an unattended NLH214 autoinstall image.
# Injects: nocloud autoinstall (user-data/meta-data), a grub cmdline to trigger it,
# the whole provisioner repo, and the offline driver pool.
#
#   ./build-iso.sh <base-ubuntu-desktop.iso> <hostname> [out.iso]
set -euo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

# One image is cloned to the whole lab, so the baked hostname is just a base —
# each machine self-names uniquely on first boot (see firstboot/run-provision.sh).
BASE="${1:?path to ubuntu-24.04.x-desktop-amd64.iso}"
HOSTNAME_NEW="${2:-nlh214-box}"
OUT="${3:-$HERE/iso/nlh214-autoinstall.iso}"
PW_PLAIN="${CSADMIN_PW:-password}"

command -v xorriso >/dev/null || { echo "need xorriso"; exit 1; }
ls "$HERE/pool/"*.deb >/dev/null 2>&1 || echo "[!] pool/ is empty — run fetch-offline-debs.sh first"

# SHA-512 crypt hash (python's crypt module is gone in 3.13; openssl is always here)
PWHASH="$(openssl passwd -6 "$PW_PLAIN")"

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
echo "[+] extracting $BASE"
xorriso -osirrox on -indev "$BASE" -extract / "$WORK/iso" >/dev/null 2>&1
chmod -R u+w "$WORK/iso"

echo "[+] injecting nocloud autoinstall (host=$HOSTNAME_NEW)"
mkdir -p "$WORK/iso/nocloud"
sed -e "s/{{HOSTNAME}}/$HOSTNAME_NEW/" -e "s|{{PWHASH}}|$PWHASH|" \
  "$HERE/user-data" > "$WORK/iso/nocloud/user-data"
cp "$HERE/meta-data" "$WORK/iso/nocloud/meta-data"

echo "[+] baking repo + driver pool onto the ISO"
mkdir -p "$WORK/iso/nlh214-refresh"
rsync -a --exclude iso/ --exclude .git/ "$REPO/." "$WORK/iso/nlh214-refresh/"

echo "[+] adding autoinstall to the grub cmdline"
GRUB="$WORK/iso/boot/grub/grub.cfg"
sed -i 's|---|autoinstall ds=nocloud\\;s=/cdrom/nocloud/ ---|g' "$GRUB"
# make the automated entry the default and drop the timeout
sed -i '0,/^set timeout=.*/s//set timeout=5/' "$GRUB" || true

echo "[+] repacking -> $OUT"
mkdir -p "$(dirname "$OUT")"
rm -f "$OUT"                       # xorriso -outdev won't clobber an existing file
xorriso -indev "$BASE" -outdev "$OUT" \
  -boot_image any replay \
  -map "$WORK/iso/nocloud" /nocloud \
  -map "$WORK/iso/nlh214-refresh" /nlh214-refresh \
  -map "$GRUB" /boot/grub/grub.cfg

echo "[+] done: $OUT ($(du -h "$OUT" | cut -f1))"
echo "    write to USB:  sudo dd if=$OUT of=/dev/sdX bs=4M status=progress oflag=sync"
