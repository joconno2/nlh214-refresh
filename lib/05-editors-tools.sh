#!/usr/bin/env bash
# editors + course tools: VS Code, Sublime Text, Wireshark, Racket/DrRacket
source "$(dirname "$(readlink -f "$0")")/common.sh"
need_root

log "VS Code repo (Microsoft)"
install -d -m 0755 /usr/share/keyrings
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
cat > /etc/apt/sources.list.d/vscode.sources <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

log "Sublime Text repo"
curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg \
  -o /usr/share/keyrings/sublimehq-pub.asc
echo "deb [signed-by=/usr/share/keyrings/sublimehq-pub.asc] https://download.sublimetext.com/ apt/stable/" \
  > /etc/apt/sources.list.d/sublime-text.list

log "Wireshark: allow non-root capture"
echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections

apt-get update -y
log "install editors + tools"
DEBIAN_FRONTEND=noninteractive apt_install code sublime-text \
  wireshark racket

log "deploy wireshark-lab demo files"
if [ -d "$REPO/files/wireshark-lab" ]; then
  cp -a "$REPO/files/wireshark-lab" /opt/ && chmod -R a+rX /opt/wireshark-lab
fi
