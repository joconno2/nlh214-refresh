#!/usr/bin/env bash
# base system: hostname, timezone, i386 multiarch, dev toolchain
source "$(dirname "$(readlink -f "$0")")/common.sh"
need_root

HOSTNAME_NEW="${1:-$(hostname)}"

log "hostname -> $HOSTNAME_NEW"
hostnamectl set-hostname "$HOSTNAME_NEW"
cat > /etc/hosts <<EOF
127.0.0.1	localhost
127.0.1.1	$HOSTNAME_NEW

::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

log "timezone -> $TIMEZONE"
timedatectl set-timezone "$TIMEZONE" || ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime

log "enable i386 multiarch (needed by the Scheme stack)"
dpkg --add-architecture i386

log "apt update"
apt-get update -y

log "dev toolchain + base tools"
apt_install build-essential gcc g++ make gdb git curl wget ca-certificates \
  vim emacs-nox openjdk-17-jdk python3 python3-pip openssh-server \
  gnupg apt-transport-https
