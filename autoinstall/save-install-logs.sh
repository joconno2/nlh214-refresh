#!/usr/bin/env bash
# Runs in the live installer, on success or failure; never inside curtin in-target.
set -euo pipefail

# An early disk failure may leave no installed filesystem to save logs onto.
if ! mountpoint -q /target; then
  echo "[!] /target is not mounted; installer logs remain in the live session's /var/log" >&2
  exit 0
fi

DEST=/target/var/log/nlh214-install
umask 077
mkdir -p "$DEST/live"
chmod 0700 "$DEST"
# Keep the entire live log tree, including Subiquity/curtin, cloud-init and apt.
cp -a /var/log/. "$DEST/live/"
# The live journal may be in /run rather than /var/log, so export it explicitly.
journalctl -b --no-pager -o short-precise > "$DEST/installer-journal.log"
cat /proc/cmdline > "$DEST/kernel-command-line.txt"
printf '%s %s\n' "$(date -Is)" "${1:-snapshot}" >> "$DEST/snapshots.log"
sync
