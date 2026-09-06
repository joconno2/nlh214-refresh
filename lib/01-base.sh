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

# A fresh boot runs unattended-upgrades + apt-daily, which grab the dpkg lock and
# half-apply the pending point-release updates — racing this provisioner and leaving
# packages unconfigured. Quiesce them (this boot only; timers re-arm next boot) and wait
# for the lock before touching apt.
log "quiesce background apt (unattended-upgrades / apt-daily)"
systemctl stop unattended-upgrades.service apt-daily.service apt-daily-upgrade.service \
  apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true
for _ in $(seq 1 90); do fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 || break; sleep 2; done
dpkg --configure -a 2>/dev/null || true

# A fresh ISO pins base packages at the ISO's versions while the archive has newer
# point-release deps (e.g. keyboard-configuration 1.226ubuntu1 vs .1), so installs fail
# with "X depends Y (= old) but new is to be installed". full-upgrade moves the held base
# packages + their deps together and clears the skew (phased updates included).
log "apt update + full-upgrade"
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -f install || true
DEBIAN_FRONTEND=noninteractive apt-get -y -o APT::Get::Always-Include-Phased-Updates=true full-upgrade

log "dev toolchain + base tools"
apt_install build-essential gcc g++ make gdb git curl wget ca-certificates \
  vim emacs-nox openjdk-17-jdk python3 python3-pip openssh-server \
  gnupg apt-transport-https
