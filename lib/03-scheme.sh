#!/usr/bin/env bash
# Scheme teaching stack: pcs (Petite Chez Scheme 8.4) + swl (Scheme Widget Library 1.3)
# Both are 32-bit and packaged nowhere. swl.so links Tcl/Tk 8.5 and petite links
# ncurses5/tinfo5 — all dropped from 24.04 — so we bundle those .so files here.
source "$(dirname "$(readlink -f "$0")")/common.sh"
need_root

log "32-bit base libs from the distro (libc/libm/librt/libdl + X11)"
apt-get update -y
apt_install libc6-i386 libc6:i386 libx11-6:i386 libxext6:i386

# The deb was repacked to drop the obsolete libncurses5/libtinfo5 package deps (noble
# has neither; we ship those .so files ourselves below). Do NOT run apt-get -f install
# on failure — it would remove petite to "resolve" a phantom dep.
log "install pcs (Petite Chez Scheme 8.4)"
dpkg -i "$SOFTWARE/petitechezscheme_8.4-2_all.deb" || warn "petite dpkg failed — check libc6-i386"

log "deploy swl (Scheme Widget Library 1.3) tree + wrapper"
tar xzf "$SOFTWARE/nlh214-scheme.tgz" -C /

log "bundle the 32-bit libs 24.04 no longer ships (Tcl/Tk 8.5, ncurses5, tinfo5)"
LIBDIR=/usr/local/lib/nlh214-scheme
mkdir -p "$LIBDIR"
tmp="$(mktemp -d)"
tar xzf "$SOFTWARE/scheme-i386-libs.tgz" -C "$tmp"
find "$tmp" -name '*.so*' -exec cp -a {} "$LIBDIR/" \;
rm -rf "$tmp"
echo "$LIBDIR" > /etc/ld.so.conf.d/nlh214-scheme.conf
ldconfig

log "smoke test petite"
echo '(display "pcs ok")(newline)' | petite -q && log "petite runs" \
  || warn "petite failed — check 32-bit libs"
command -v swl >/dev/null && log "swl wrapper installed at $(command -v swl) (GUI test on the pilot box)" \
  || warn "swl wrapper missing"
