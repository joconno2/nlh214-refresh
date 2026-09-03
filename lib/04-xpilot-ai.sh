#!/usr/bin/env bash
# xpilot-ai — AI course game + bot libraries (C/Java/Python/Racket bindings).
# 64-bit native. Pinned tarball is the reference (gitlab.com/xpilot-ai/xpilot-ai @ 243c9dd);
# set XPILOT_FROM_GIT=1 to clone upstream instead.
source "$(dirname "$(readlink -f "$0")")/common.sh"
need_root

log "xpilot-ai runtime deps (X11 client + language bindings)"
apt_install libxcb1 libx11-6 default-jre python3 racket

if [ "${XPILOT_FROM_GIT:-0}" = "1" ]; then
  log "clone xpilot-ai from upstream"
  rm -rf /lib/xpilot-ai
  git clone https://gitlab.com/xpilot-ai/xpilot-ai.git /lib/xpilot-ai
else
  log "deploy pinned xpilot-ai tree -> /lib/xpilot-ai"
  rm -rf /lib/xpilot-ai
  tar xzf "$SOFTWARE/nlh214-xpilot-ai.tgz" -C /lib
fi

chmod -R a+rX /lib/xpilot-ai
chmod +x /lib/xpilot-ai/binaries/* 2>/dev/null || true

log "put xpilot-ai binaries on PATH for all users"
cat > /etc/profile.d/xpilot-ai.sh <<'EOF'
export PATH="$PATH:/lib/xpilot-ai/binaries"
EOF

/lib/xpilot-ai/binaries/xpilots --help >/dev/null 2>&1 && log "xpilots runs" \
  || warn "xpilots smoke test inconclusive (may need a display)"
