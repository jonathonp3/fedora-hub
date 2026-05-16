# Method 1: Persistent Host-to-VM Sharing (The SSHFS Method)

This guide documents how to securely and persistently mount the **Fedora Silverblue** host home directory inside a **Fedora Workstation VM**. 

## Why SSHFS over NFS/Samba?
- **Bypasses the "Symlink Trap":** Silverblue uses a symlink for `/home` -> `/var/home`, which causes NFS to fail with "No such directory." SSHFS operates at the user level and handles this perfectly.
- **Security:** Everything is encrypted via SSH (SFTP).
- **Simplicity:** No need to manage complex firewall ports or SELinux booleans for Samba/NFS.

---

## 🛠️ Setup Instructions

1. Host Preparation (Luhman-16)

##Enable Remote Login and open the SSH port:
```bash
# Enable SSH via Settings > Sharing > Remote Login OR:
sudo systemctl enable --now sshd

# Open Firewall
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload
```

2. VM Preparation (Workstation Client)

Install the mounting tools and enable global permissions:

Install the SSHFS driver
```bash
sudo dnf install sshfs
```

Enable global 'allow_other' permissions in FUSE

(Includes the space to match Fedora's default formatting)
```bash
sudo sed -i 's/# user_allow_other/user_allow_other/' /etc/fuse.conf
```

Verify the change (should show 'user_allow_other' without a #)
```bash
cat /etc/fuse.conf
```

Create the mount point
```bash
mkdir -p ~/Luhman-16
```

3. Password-less Authentication
Host (Luhman-16):
Creates a new keypair (both private and public)
```bash
ssh-keygen -t ed25519
```
or 

Generates a new SSH key pair in silent mode without prompts:
```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
```
Enable and start the sshd service:
```bash
sudo systemctl enable --now sshd
```
Allow SSH through firewall (firewalld) if it is not already allowed:
```bash
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --reload
```
VM (Fedora Workstation)
Generate a key in the VM and send it to the host:

Creates a new keypair (both private and public)
```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
```
Copy public key to the host (Luhman-16).
```bash
ssh-copy-id jonathon@[HOST_IP]
```
4. Persistent Mount (/etc/fstab)

Optional: Manual Connection Test
Run this to verify the connection and permissions before editing fstab.
If this works, your files will appear in the folder.
```bash
sshfs jonathon@[HOST_IP]:/var/home/jonathon/ /home/jonathon/Luhman-16 -o identityfile=/home/jonathon/.ssh/id_ed25519,allow_other,default_permissions
```
Check if files are visible
```bash
ls ~/Luhman-16
```
Unmount the test before proceeding to fstab setup
```bash
fusermount3 -u ~/Luhman-16
```

Edit fstab
```bash
sudo vim /etc/fstab
```
Add this line to the VM's /etc/fstab to enable Systemd Automount. This ensures the connection is only made when you click the folder, preventing boot delays.
```bash
jonathon@[HOST_IP]:/var/home/jonathon /home/jonathon/Luhman-16 fuse.sshfs noauto,x-systemd.automount,_netdev,reconnect,identityfile=/home/jonathon/.ssh/id_ed25519,allow_other,default_permissions 0 0
```

Tell systemd manager to stop, re-scan the entire system for changes, and "re-read" all configuration files.
```bash
sudo systemctl daemon-reload
```

In Fedora, systemd acts as the manager of the filesystem; running sudo systemctl daemon-reload activates a generator that scans your fstab and instantly creates background "virtual units" for your configuration. This applies your changes immediately, setting up a "listener" that waits to snap the connection into place the moment you access the folder.


Method 2: The Lightweight Nautilus Way (GUI Only)

If you only need to drag-and-drop files occasionally using your mouse and don't require terminal or background app access, you can use the built-in Nautilus "Connect to Server" feature.

Prerequisite: You must still complete the SSH Key Exchange (Step 2) for this to be persistent and password-less.

    Open Nautilus (Files).
    Click 'Network' in the sidebar.
    In 'Connect' to 'Server address' box, enter: sftp://192.168.1.132/var/home/jonathon
    Click Connect.
    Pro Tip: Once connected, press Ctrl + D or right-click the folder in the sidebar and select Add to Bookmark.

Why this works: 
Because your SSH keys are already installed, Nautilus will bypass the password prompt and automatically "remount" this connection every time you click the bookmark, even after a reboot.

