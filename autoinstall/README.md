# NLH214 autoinstall USB

Unattended Ubuntu 24.04.3 Desktop image for the **MSI Aegis ZS2 C9NVV-1277US** fleet
(AMD Ryzen 9 9900X / B650 / RTX 5080 / Realtek LAN + Wi-Fi 6E-7).

## Why this is not a stock ISO
24.04's GA kernel (6.8) predates this silicon — the NIC doesn't come up and the Blackwell
5080 needs NVIDIA 570. So the image:
- installs the **OEM 6.14 kernel** + latest `linux-firmware` (Wi-Fi + NIC + amdgpu),
- installs **nvidia-driver-570-open** (RTX 5080),
- carries **Realtek dkms** as a NIC fallback,
- does all of that from an **on-disk pool** (`pool/`) so a dark NIC can't stall the install,
- then runs the full lab provisioner (NIS/NFS/swl/pcs/xpilot/editors) on **first boot** once
  the machine is on the campus network.

## Build it (on cachy)
```bash
# 1. harvest the driver pool (needs network + docker; ~1-1.5 GB)
./fetch-offline-debs.sh

# 2. download an Ubuntu 24.04.3 Desktop ISO into iso/  (base image)

# 3. remaster
./build-iso.sh iso/ubuntu-24.04.3-desktop-amd64.iso NL214-Lin01

# 4. write to USB
sudo dd if=iso/nlh214-autoinstall.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## On the machine
1. Boot the USB (disable **Secure Boot** in BIOS — nvidia-open + dkms modules are unsigned).
2. Install runs unattended, reboots into the OEM kernel with GPU + NIC live.
3. On campus, first boot runs `provision.sh` (see `/var/log/nlh214-firstboot.log`).
4. Validate: `id <student>`, `ls /home/CS_data/students`, `swl`, `xpilots --help`, `nvidia-smi`.

## Decisions still open
- **Storage**: defaults to whole-disk Ubuntu (WIPES the preloaded Windows 11). The old lab was
  dual-boot — if that's wanted, switch `storage:` in `user-data` to a manual layout that keeps
  the Windows ESP + partition.
- **Exact NIC**: `lspci -nn | grep -i net` from the box lets us trim the dkms set; until then we
  carry the superset.
