#!/usr/bin/env bash
# Scheme teaching stack: pcs (Petite Chez Scheme 8.4) + swl (Scheme Widget Library 1.3)
# Both are 32-bit and packaged nowhere. swl.so links Tcl/Tk 8.5 and petite links
# ncurses5/tinfo5 — all dropped from 24.04 — so we bundle those .so files and
# the matching Tcl/Tk 8.5.19 startup scripts here.
source "$(dirname "$(readlink -f "$0")")/common.sh"
need_root

log "32-bit base libs from the distro (libc/libm/librt/libdl + X11)"
apt-get update -y
# Bundled Tk 8.5 also needs 32-bit Xft and Xss to load SWL's GUI.
apt_install libc6-i386 libc6:i386 libx11-6:i386 libxext6:i386 \
  libxft2:i386 libxss1:i386

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

log "install matching Tcl/Tk startup scripts + SWL launcher"
DATADIR=/usr/local/share/nlh214-scheme
install -d -m 0755 "$DATADIR"
tar xzf "$SOFTWARE/tcltk8.5-scripts.tgz" -C "$DATADIR"
test -r "$DATADIR/tcl8.5/init.tcl"
test -r "$DATADIR/tk8.5/tk.tcl"
# The reference tarball's launcher points to 8.6; the bundled binaries require 8.5.
install -m 0755 "$REPO/files/swl" /usr/bin/swl

log "check SWL shared-library dependencies"
deps="$(ldd /usr/lib/swl1.3/i3le/swl.so)" || die "could not inspect SWL dependencies"
if grep -q 'not found' <<< "$deps"; then
  printf '%s\n' "$deps" >&2
  die "SWL shared libraries are missing"
fi

log "smoke test Petite"
echo '(display "pcs ok")(newline)' | petite -q || die "Petite smoke test failed"
log "SWL installed; validate the GUI with swl on the pilot box"
