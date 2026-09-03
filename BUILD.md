# NLH214 lab refresh — reference build

Pulled from a live FY22 machine (`NL214-Lin11163` / beholder, 136.244.224.242, csadmin) on 2026-09-03.
This is the golden reference for imaging the new NLH214 machines.

## Reference OS (old fleet)
- Ubuntu 22.04.5 LTS (jammy), kernel 6.8, dual-boot with Windows (GRUB → Windows Boot Manager)
- i386 multiarch enabled (needed by the 32-bit Scheme stack, below)
- Default local login: `csadmin` / `c$@dm1n`; student Ubuntu pw `springcamel2026`; logins come from NIS

## Identity + storage (must match whale)
- NIS: domain `waxlab`, ypserver `136.244.170.66` (whale.conncoll.edu), `ypbind` enabled
- `/etc/yp.conf` → `ypserver 136.244.170.66`
- `/etc/defaultdomain` → `waxlab`
- `nsswitch.conf`: `passwd/group: files nis systemd`, `hosts: files nis mdns4_minimal [NOTFOUND=return] dns`, `netgroup: nis`
- NFS home: `whale.conncoll.edu:/home  /home/CS_data  nfs  defaults 0 0` (rpcbind + rpc-statd enabled)
- NIS UIDs 1000–1847, homes under `/home/CS_data/students/`
- Copies of all these files: `configs/etc/`

Packages: `nis ypbind-mt yp-tools libnss-nis rpcbind nfs-common` (+ `:i386` variants of libnss-nis/libnsl2).
All present in Ubuntu 24.04 noble (verified).

## Course software
| Tool | What | Source on refresh box |
|------|------|-----------------------|
| xpilot-ai | AI course (bots in C/Java/Python/Racket) | git clone https://gitlab.com/xpilot-ai/xpilot-ai.git → `/lib/xpilot-ai` (ref commit 243c9dd). Local copy: `software/nlh214-xpilot-ai.tgz` |
| pcs | Petite Chez Scheme 8.4 (32-bit, 2011) | NOT in apt — alien "Converted tgz". `/usr/bin/petite`. In `software/nlh214-scheme.tgz` |
| swl | Scheme Widget Library 1.3 (32-bit) | NOT in apt — manual. Wrapper `/usr/bin/swl` → petite + `/usr/lib/swl1.3` + `/usr/lib/csv8.4`. In `software/nlh214-scheme.tgz` |
| racket / drracket | 8.2 | apt: `racket racket-common racket-doc` (in noble as 8.x) |
| chezscheme | 9.5 | apt (in noble) — note current box actually runs on petite 8.4, not this |
| editors | emacs, vim, VS Code (`code`), sublime-text 4200 | apt / MS repo / sublime repo |
| net tools | wireshark 3.6 (+ `/opt/wireshark-lab` demo files) | apt |
| build | gcc g++ make, openjdk (javac), python3 | apt |
| Tcl/Tk | 8.6 + blt (SWL GUI); 32-bit tcl/tk 8.5 for old SWL | apt (+ :i386) |

## The one fragile piece
`swl` and `pcs` are 32-bit (i3le, Chez 8.4). They are NOT packaged in any Ubuntu release. Two options on a
modern OS:
- **(A) Redeploy as-is:** enable i386 multiarch, install 32-bit `libtcl8.5:i386 libtk8.5:i386 libnsl2:i386`,
  drop the `swl1.3`/`csv8.4` trees back into `/usr/lib`, install petite. Same mechanism the FY22 box uses. Low effort, keeps the i386 baggage.
- **(B) Modernize:** rebuild SWL against noble's 64-bit chezscheme, drop i386 entirely. More work, cleaner long-term.

## Reproduction manifests
- `pkg/dpkg-selections.txt` — full package set (apt reproduction)
- `pkg/apt-manual.txt` — explicitly-installed packages only
- `pkg/relevant-pkgs.txt` — the course/identity subset with versions

## Artifacts pulled (in software/)
- `nlh214-configs.tgz` — /etc files + manifests + systemd unit states
- `nlh214-scheme.tgz` — swl1.3 + csv8.4 + swl wrapper (the pcs/swl stack)
- `nlh214-xpilot-ai.tgz` — full xpilot-ai git tree (6.3M)
