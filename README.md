# NLH214 lab refresh

Unattended install USB + provisioner for the NLH214 teaching lab (FY26 refresh).
Target hardware: **MSI Aegis ZS2 C9NVV-1277US** (Ryzen 9 9900X / B650 / RTX 5080 / Realtek
LAN + Wi-Fi). Target OS: **Ubuntu 24.04.4 LTS**, whole-disk (wipes the preloaded Windows 11).

> 24.04's stock installer fails on this box — the GA 6.8 kernel is too old for the NIC and the
> Blackwell GPU. This USB carries an OEM 6.17 kernel + NVIDIA 580 + NIC drivers **baked in as an
> offline pool**, so it installs with no working network, then runs the lab provisioner on first
> boot once the machine is on campus.

## Install a machine (the USB workflow)

**1. Build the USB image** — one command, on **any Linux box** with `docker` + `xorriso`
(not tied to any particular machine):
```bash
git clone https://github.com/joconno2/nlh214-refresh && cd nlh214-refresh
./build.sh                          # fetches ISO, harvests driver pool, remasters image
# -> autoinstall/iso/nlh214-autoinstall.iso  (~7.5G)
```
`build.sh` runs a preflight that names any missing tools and the install command for your
distro. Prereqs: `docker xorriso curl openssl rsync coreutils`. The steps also run standalone
(`autoinstall/fetch-iso.sh`, `fetch-offline-debs.sh`, `build-iso.sh`) if you want them piecemeal.

**2. Write it to a USB** (≥16GB stick):
```bash
lsblk                                                     # identify the stick, e.g. /dev/sdb
sudo dd if=autoinstall/iso/nlh214-autoinstall.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

**3. Boot the ZS2 from the USB:**
- In BIOS, **disable Secure Boot** (the NVIDIA-open + dkms modules are unsigned).
- Boot the USB. The install is **unattended**: it wipes the disk, installs Ubuntu + the OEM
  kernel/NVIDIA/NIC drivers from the on-USB pool, and reboots into kernel 6.17 with GPU + NIC live.
- Login `csadmin` / `password`. The box **self-names** `nlh214-<serial>`.

**4. First boot on campus** runs the lab provisioner automatically (NIS/NFS/swl/pcs/xpilot/editors).
Watch `/var/log/nlh214-firstboot.log`, then validate:
```bash
id <student>                 # NIS lookup works
ls /home/CS_data/students    # NFS home mounted
swl                          # SWL GUI window opens
xpilots --help               # xpilot-ai runs
nvidia-smi                   # RTX 5080 up
```

Details of the USB build internals: [autoinstall/README.md](autoinstall/README.md).

## What the provisioner installs
Runs on first boot (or manually: `sudo ./provision.sh <hostname>`). Reference build pulled from
the FY22 fleet 2026-09-03 — see [BUILD.md](BUILD.md).

| Module | Contents |
|--------|----------|
| `00-hwenable` | OEM 6.17 kernel, NVIDIA 580-open, linux-firmware, Realtek dkms (offline-pool aware) |
| `01-base` | hostname, timezone, i386 multiarch, gcc/g++/make/gdb, git, jdk, python3, vim/emacs, sshd |
| `02-nis-nfs` | NIS client → whale (`waxlab`, ypserver 136.244.170.66), NFS `/home/CS_data`, nsswitch |
| `03-scheme` | `pcs` (Petite Chez Scheme 8.4) + `swl` (Scheme Widget Library 1.3) + bundled 32-bit libs |
| `04-xpilot-ai` | xpilot-ai game + C/Java/Python/Racket bot bindings, on PATH |
| `05-editors-tools` | VS Code, Sublime Text, Wireshark (+lab files), Racket/DrRacket |

## Why 24.04
NIS/YP client, NFS, chezscheme, and racket are all in noble; new hardware needs the long support
window (to 2029/2036 vs 22.04's April 2027). The 32-bit libs the old Scheme stack links (Tcl/Tk
8.5, ncurses5) are dropped from noble, so they're **bundled here** — `swl`/`pcs` work on 24.04
identically to 22.04. NIS is deprecated (whale AD migration planned); 24.04 is the last comfortable
LTS for a NIS client.

## Known follow-ups (not automated)
- **HTCondor worker join** — 17 of these run as Condor workers outside class. Pool config +
  IDTOKENS come from mega_knight; add a `06-condor.sh` once the new pool auth is settled.
- **AD migration** — when whale NIS is decommissioned, module 02 re-points to AD auth.
