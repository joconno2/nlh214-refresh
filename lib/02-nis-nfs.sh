#!/usr/bin/env bash
# NIS client + NFS home mount, pointed at whale (waxlab domain)
source "$(dirname "$(readlink -f "$0")")/common.sh"
need_root

log "preseed NIS domain so the nis package installs non-interactively"
echo "nis nis/domain string $NIS_DOMAIN" | debconf-set-selections

log "install NIS + NFS client packages"
apt_install nis ypbind-mt yp-tools libnss-nis libnss-nis:i386 nfs-common rpcbind

log "NIS domain -> $NIS_DOMAIN, ypserver -> $YP_SERVER"
echo "$NIS_DOMAIN" > /etc/defaultdomain
nisdomainname "$NIS_DOMAIN"
cat > /etc/yp.conf <<EOF
# NLH214 lab -> whale NIS master
ypserver $YP_SERVER
EOF

log "nsswitch.conf (files + nis) from reference build"
install -m 0644 "$CONFIGS/etc/nsswitch.conf" /etc/nsswitch.conf

log "NFS home: $NFS_SERVER:$NFS_EXPORT -> $NFS_MOUNT"
mkdir -p "$NFS_MOUNT"
if ! grep -q "$NFS_MOUNT" /etc/fstab; then
  echo "$NFS_SERVER:$NFS_EXPORT $NFS_MOUNT nfs defaults 0 0" >> /etc/fstab
fi

log "enable services"
systemctl enable --now rpcbind
systemctl enable --now ypbind || warn "ypbind did not start — check reachability to $YP_SERVER"
systemctl enable --now nfs-client.target || true

log "mount NFS home"
mount -a || warn "mount -a failed — verify whale is reachable and exporting $NFS_EXPORT"

log "verify NIS"
ypwhich 2>/dev/null && ypcat passwd 2>/dev/null | head -1 >/dev/null \
  && log "NIS bound to $(ypwhich)" || warn "NIS not bound yet"

# Snaps + non-standard NFS homes: strict snaps (Firefox is shipped by default) are
# AppArmor-confined to /home/<user> and BREAK when homes live under /home/CS_data/...
# — this is the classic "snap won't launch for NIS students" failure. Tell snapd where
# the real home roots are so it regenerates AppArmor with those paths in @{HOMEDIRS}.
if command -v snap >/dev/null; then
  log "snap homedirs -> NFS home roots (so strict snaps work for NIS logins)"
  snap set system homedirs=/home/CS_data/students,/home/CS_data/collaborator \
    || warn "snap homedirs not set — strict snaps (Firefox) may fail for NIS users"
fi
