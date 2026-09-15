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

## Build it (any Linux box with docker + xorriso)
Easiest: `../build.sh` from the repo root does all of this. Piecemeal:
```bash
./fetch-iso.sh                 # download + SHA256-verify the base ISO into iso/
./fetch-offline-debs.sh        # harvest the driver pool via docker (~1.3 GB)
./build-iso.sh iso/ubuntu-24.04.4-desktop-amd64.iso nlh214-box
sudo dd if=iso/nlh214-autoinstall.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## On the machine
1. Boot the USB (disable **Secure Boot** in BIOS — nvidia-open + dkms modules are unsigned).
2. Install runs unattended, reboots into the OEM kernel with GPU + NIC live.
3. On campus, first boot runs `provision.sh` (see `/var/log/nlh214-firstboot.log`).
4. Validate: `id <student>`, `ls /home/CS_data/students`, `swl`, `xpilots --help`, `nvidia-smi`.

## Saved installation logs

Each newly built USB saves logs on the installed computer, including on success:

- `/var/log/nlh214-install/live/`: a copy of the live installer's entire `/var/log`,
  including `installer/` (Subiquity/curtin), cloud-init and package logs.
- `/var/log/nlh214-install/installer-journal.log`: the live installer's system journal.
- `/var/log/nlh214-install/hardware.log`: both offline driver-install passes, including errors.
- `/var/log/nlh214-install/kernel-command-line.txt` and `snapshots.log`: boot options,
  capture time and whether the lab's late commands completed or an installer error occurred.
- `/var/log/nlh214-firstboot.log`: lab setup output, apt reachability attempts and each
  attempt's exit status. Retries append to this file, and success does not delete it.

Use `sudo` to read these logs. The installer snapshot is taken at the end of the late
commands, before reboot; it does not include later shutdown messages. On an installer
error, logs are also copied if `/target` is still mounted. If installation fails before
the target disk is mounted, logs remain only in the live session. These hooks require
the custom autoinstall configuration to run. Rebuild the ISO and rewrite the USB to
include this change; existing USB images and installed computers are not updated.

## Decisions still open
- **Storage**: defaults to whole-disk Ubuntu (WIPES the preloaded Windows 11). The old lab was
  dual-boot — if that's wanted, switch `storage:` in `user-data` to a manual layout that keeps
  the Windows ESP + partition.
- **Exact NIC**: `lspci -nn | grep -i net` from the box lets us trim the dkms set; until then we
  carry the superset.
