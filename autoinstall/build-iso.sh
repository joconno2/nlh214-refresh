#!/usr/bin/env bash
# Remaster an Ubuntu 24.04.3 Desktop ISO into an unattended NLH214 autoinstall image.
# Injects: nocloud autoinstall (user-data/meta-data), a grub cmdline to trigger it,
# the whole provisioner repo, and the offline driver pool.
#
#   ./build-iso.sh <base-ubuntu-desktop.iso> <hostname> [out.iso]
set -euo pipefail
HERE="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
REPO="$(cd "$HERE/.." && pwd)"

BASE="${1:?path to ubuntu-24.04.x-desktop-amd64.iso}"
HOSTNAME_NEW="${2:?hostname for this image, e.g. NL214-Lin01}"
OUT="${3:-$HERE/iso/nlh214-autoinstall.iso}"
PW_PLAIN="${CSADMIN_PW:-c\$@dm1n}"

command -v xorriso >/dev/null || { echo "need xorriso"; exit 1; }
[ -f "$HERE/pool/"*.deb ] 2>/dev/null || echo "[!] pool/ is empty — run fetch-offline-debs.sh first"

PWHASH="$(python3 -c "import crypt;print(crypt.crypt('$PW_PLAIN', crypt.mksalt(crypt.METHOD_SHA512)))")"

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
xorriso -indev "$BASE" -outdev "$OUT" \
  -boot_image any replay \
  -map "$WORK/iso/nocloud" /nocloud \
  -map "$WORK/iso/nlh214-refresh" /nlh214-refresh \
  -map "$GRUB" /boot/grub/grub.cfg \
  >/dev/null 2>&1

echo "[+] done: $OUT ($(du -h "$OUT" | cut -f1))"
echo "    write to USB:  sudo dd if=$OUT of=/dev/sdX bs=4M status=progress oflag=sync"
