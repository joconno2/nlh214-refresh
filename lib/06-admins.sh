#!/usr/bin/env bash
# Lab admins — grant sudo to CS staff/student admins (NIS accounts) on every machine.
# Password-required sudo (they authenticate with their NIS password).
source "$(dirname "$(readlink -f "$0")")/common.sh"
need_root

# NIS usernames that get sudo on all NLH214 machines
ADMINS=(dgezgin)

F=/etc/sudoers.d/nlh214-admins
tmp="$(mktemp)"
echo "# NLH214 lab admins — managed by nlh214-refresh, do not edit by hand" > "$tmp"
for u in "${ADMINS[@]}"; do
  echo "$u ALL=(ALL) ALL" >> "$tmp"
done

# validate before installing so a typo can't lock sudo
if visudo -cf "$tmp" >/dev/null 2>&1; then
  install -m 0440 "$tmp" "$F"
  log "sudo granted to: ${ADMINS[*]}"
else
  warn "sudoers syntax check failed — not installing $F"
fi
rm -f "$tmp"
