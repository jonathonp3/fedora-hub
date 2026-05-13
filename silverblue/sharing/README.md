# Persistent Host-to-VM Sharing (The SSHFS Method)

This guide documents how to securely and persistently mount the **Fedora Silverblue** host home directory inside a **Fedora Workstation VM**. 

## Why SSHFS over NFS/Samba?
- **Bypasses the "Symlink Trap":** Silverblue uses a symlink for `/home` -> `/var/home`, which causes NFS to fail with "No such directory." SSHFS operates at the user level and handles this perfectly.
- **Security:** Everything is encrypted via SSH (SFTP).
- **Simplicity:** No need to manage complex firewall ports or SELinux booleans for Samba/NFS.

---

## 🛠️ Setup Instructions

### 1. Host Preparation (Luhman-16)
Enable Remote Login and open the SSH port:
```bash
# Enable SSH via Settings > Sharing > Remote Login OR:
sudo systemctl enable --now sshd

# Open Firewall
sudo firewall-cmd --add-service=ssh --permanent
sudo firewall-cmd --reload
```

2. VM Preparation (Workstation Client)

Install the mounting tools and enable global permissions:
```bash
sudo dnf install sshfs
# Uncomment 'user_allow_other' in /etc/fuse.conf
sudo sed -i 's/#user_allow_other/user_allow_other/' /etc/fuse.conf
# Create the mount point
mkdir -p ~/Luhman-16
```

3. Password-less Authentication

Generate a key in the VM and send it to the host:
bash
```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519
ssh-copy-id jonathon@[HOST_IP]
```
4. Persistent Mount (/etc/fstab)

Edit fstab
```bash
sudo vim /etc/fstab
```
Add this line to the VM's /etc/fstab to enable Systemd Automount. This ensures the connection is only made when you click the folder, preventing boot delays.
```bash
jonathon@[HOST_IP]:/var/home/jonathon  /home/jonathon/Luhman-16  fuse.sshfs  noauto,x-systemd.automount,_netdev,reconnect,identityfile=/home/jonathon/.ssh/id_ed25519,allow_other,default_permissions 0 0
```
