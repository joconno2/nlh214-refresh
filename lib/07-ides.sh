#!/usr/bin/env bash
# Heavy IDEs via snap (classic confinement) — Eclipse (Java) + PyCharm Community (Python).
# Snap is the only well-maintained path for these on 24.04; the apt eclipse package is gone.
source "$(dirname "$(readlink -f "$0")")/common.sh"
need_root

command -v snap >/dev/null || apt_install snapd
systemctl enable --now snapd.socket 2>/dev/null || true
snap wait system seed.loaded 2>/dev/null || true

log "PyCharm Community (JetBrains, Python IDE)"
snap install pycharm-community --classic || warn "pycharm-community snap failed"

log "Eclipse (Java IDE)"
snap install eclipse --classic || warn "eclipse snap failed"

log "IDEs done: $(snap list 2>/dev/null | grep -iE 'pycharm|eclipse' | awk '{print $1}' | tr '\n' ' ')"
