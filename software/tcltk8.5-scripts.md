# Tcl/Tk 8.5.19 script data

`tcltk8.5-scripts.tgz` supplies the complete `tcl8.5/` and `tk8.5/` script
directories needed by the existing 32-bit libraries in `scheme-i386-libs.tgz`.
Shared libraries alone are insufficient: Tcl needs `init.tcl`, and Tk needs
`tk.tcl`, widget bindings, and the remaining runtime data.

Source packages from the Debian archive (only script data is deployed; these
packages are not installed into Ubuntu):

- [libtcl8.5_8.5.19-2+b1_i386.deb](https://archive.debian.org/debian/pool/main/t/tcl8.5/libtcl8.5_8.5.19-2+b1_i386.deb)
  SHA-256: `3d0a985ccfbfcb8e8450dee976d87bba8383a15187b18a8866a170939fb4d7a6`
- [libtk8.5_8.5.19-1+b1_i386.deb](https://archive.debian.org/debian/pool/main/t/tk8.5/libtk8.5_8.5.19-1+b1_i386.deb)
  SHA-256: `ea06cfe8a9700e22c8ea0d7822e6daf34016d78c2432c8d0ceeb12c05b0f6f54`

The archive contains each package's `usr/share/tcltk/` contents, with the package's
`usr/share/doc/libtcl8.5/copyright` or `usr/share/doc/libtk8.5/copyright` preserved
as `tcl8.5/license.terms` or `tk8.5/license.terms`. Files retain their original
contents. Paths are sorted; tar ownership is root:root, timestamps are zero,
directories are mode 0755, and files are mode 0644. The gzip timestamp is zero.

Archive SHA-256:
`f714289870c68354726287c067e5aabb84f9fbe6b3971236cd22e48939b0f003`

Module 03 extracts this data into `/usr/local/share/nlh214-scheme` and installs
`files/swl`, which selects these 8.5 directories instead of the reference
launcher's incorrect 8.6 paths. Provisioning checks the startup files and SWL's
shared-library dependencies, then runs Petite. Launch `swl` from a graphical
session to validate Tcl/Tk initialization and the SWL window as well.
