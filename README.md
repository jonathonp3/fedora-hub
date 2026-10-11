# fedora-hub

A collection of guides, scripts, and configuration notes for Fedora Silverblue
and related Linux workstations. Everything here is written for the Atomic
desktop workflow: host-native where possible, Toolbox when building, and no
unnecessary layering.

## 📚 Guides

### 🖥️ [Persistent Host-to-VM Sharing (SSHFS)](silverblue/sharing/README.md)
Securely and persistently mount the Fedora Silverblue host home directory
inside a Fedora Silverblue VM. Covers both the lightweight Nautilus GUI
method and a full SSHFS + systemd user service setup, and explains why SSHFS
is preferred over NFS/Samba on Silverblue.

### 🔍 [DocSearch Pro](silverblue/search/README.md)
A high-performance, unified search utility that scans plain text, Markdown,
HTML, `.docx`, `.odt`, legacy `.doc`, and `.pdf` files in a single pass.
Includes terminal installation, GNOME desktop integration, and a system mode
for searching configs, logs, and Btrfs subvolumes.

### 🎨 [Full Vim Installation (Catppuccin Edition)](silverblue/vim/README.md)
Build and install a full-featured Vim from source inside a Toolbox container,
then deploy the binary and runtime to `/usr/local` on the host. Ships with
Catppuccin as the global default and documents the full set of included
colorschemes.

## 📂 Repository Layout

Other Links

- [sirius-os-pia-installer](https://github.com/jonathonp3/sirius-os-pia-installer)
- [sirius-os-virtualization](https://github.com/jonathonp3/sirius-os-virtualization)
- [sirius-provisioning-framework](https://github.com/jonathonp3/sirius-provisioning-framework)



