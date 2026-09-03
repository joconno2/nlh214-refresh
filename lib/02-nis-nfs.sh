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
