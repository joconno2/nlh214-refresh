# NLH214 lab refresh

Self-contained provisioner for the NLH214 teaching-lab machines (FY26 refresh).
Target OS: **Ubuntu 24.04 LTS**, dual-boot with Windows. Reference build pulled from the
FY22 fleet on 2026-09-03 — see [BUILD.md](BUILD.md) for the full inventory and provenance.

## Why 24.04
NIS/YP client, NFS, chezscheme, and racket are all in noble; new hardware needs the long
support window (2029/2036 vs 22.04's April 2027). The only casualties of the newer OS are the
32-bit libs the old Scheme stack links (Tcl/Tk 8.5, ncurses5) — those are **bundled in this
repo**, so `swl`/`pcs` work on 24.04 identically to 22.04. NIS itself is deprecated and on the
way out (whale AD migration planned); 24.04 is the last comfortable LTS for a NIS client.

## Provision a machine
Jim installs Ubuntu 24.04 + names the box, then:

```bash
# from a machine that can reach the new box:
rsync -a nlh214-refresh/ csadmin@<box>:/tmp/nlh214-refresh/
ssh csadmin@<box> 'cd /tmp/nlh214-refresh && sudo ./provision.sh <hostname>'
```

Run a single module by its number: `sudo ./provision.sh <hostname> 03`.

## What it installs
| Module | Contents |
|--------|----------|
| `01-base` | hostname, timezone, i386 multiarch, gcc/g++/make/gdb, git, jdk, python3, vim/emacs, sshd |
| `02-nis-nfs` | NIS client → whale (`waxlab`, ypserver 136.244.170.66), NFS `/home/CS_data`, nsswitch |
| `03-scheme` | `pcs` (Petite Chez Scheme 8.4) + `swl` (Scheme Widget Library 1.3) + bundled 32-bit libs |
| `04-xpilot-ai` | xpilot-ai game + C/Java/Python/Racket bot bindings, on PATH |
| `05-editors-tools` | VS Code, Sublime Text, Wireshark (+lab files), Racket/DrRacket |

## After provisioning — validate before cloning to the fleet
```bash
id <student>                 # NIS lookup works
ls /home/CS_data/students    # NFS home mounted
swl                          # SWL GUI window opens (needs a display)
xpilots --help               # xpilot-ai runs
racket --version ; drracket  # Racket/DrRacket
```

## Known follow-ups (not automated)
- **HTCondor worker join** — 17 of these run as Condor workers outside class. Pool config +
  IDTOKENS come from mega_knight; add a `06-condor.sh` once the new pool auth is settled.
- **AD migration** — when whale NIS is decommissioned, module 02 re-points to AD auth.
