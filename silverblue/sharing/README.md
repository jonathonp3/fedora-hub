# Persistent Host-to-VM Sharing (The SSHFS Method)

This guide documents how to securely and persistently mount the **Fedora Silverblue** host home directory inside a **Fedora Silverblue VM**. 

## Why SSHFS over NFS/Samba?
- **Bypasses the "Symlink Trap":** Silverblue uses a symlink for `/home` -> `/var/home`, which causes NFS to fail with "No such directory." SSHFS operates at the user level and handles this perfectly.
- **Security:** Everything is encrypted via SSH (SFTP).
- **Simplicity:** No need to manage firewall ports or SELinux booleans for Samba/NFS.

## Method 1: The Lightweight Nautilus Way (GUI Only)

If you prefer a pure graphical interface and don't want to use the terminal or edit system files, you can use the built-in Nautilus "Connect to Server" feature.

    Open Nautilus (Files).
    Click + Other Locations (or Network) in the sidebar.
    In the Connect to Server address box, enter: 
   
```bash
sftp://192.0.2.10/var/home/jonathon
```
    
    Click Connect.
    Enter your Host username and password.
    Crucial Step: Select "Remember Forever" to ensure the connection stays password-less.
    Pro Tip: Once connected, press Ctrl + D to Add a Bookmark.

Why this works:
Nautilus saves your credentials in the secure GNOME Keyring. Even after a reboot, clicking the bookmark will instantly "remount" the host directory without asking for a password.

🔍 Technical Note: What happened to .ssh?

Even if you didn't create a key, Nautilus automatically creates the ~/.ssh/known_hosts file. As seen in my cat output, it has saved three types of "fingerprints" for the host:

    ssh-ed25519: The modern fast fingerprint.
    ssh-rsa: The classic fingerprint.
    ecdsa-sha2: The standard secure fingerprint.

Having these files means your VM and Host have officially "shaken hands" and trust each other! 🚀📁🛠️ 


## Method 2 (Mounting Host from VM):

The Fedora VM is the SSHFS client. The remote machine at `192.0.2.10` must be running an SSH server.

1. Install SSHFS

```bash
sudo dnf install sshfs
```

2. Enable global 'allow_other' permissions in FUSE

(Includes the space to match Fedora's default formatting)
```bash
sudo sed -i 's/# user_allow_other/user_allow_other/' /etc/fuse.conf
```

3. Create an SSH key

Only run this if the key does not already exist:
```bash
ls -l ~/.ssh/id\_ed25519
```

If it does not exist:
```bash
ssh-keygen -t ed25519 -N "" -f ~/.ssh/id\_ed25519
```

This creates:
```bash
~/.ssh/id\_ed25519       # private key
~/.ssh/id\_ed25519.pub   # public key
```

4. Copy the public key to Luhman-16
```bash
ssh-copy-id -i ~/.ssh/id\_ed25519.pub jonathon@192.0.2.10
```

Test passwordless SSH access:
```bash
ssh -i ~/.ssh/id\_ed25519 jonathon@192.0.2.10
```

5. Create the mountpoint
```bash
mkdir -p /var/home/jonathon/Luhman-16
```

6. Manually test the SSHFS mount
```bash
sshfs jonathon@192.0.2.10:/var/home/jonathon \\
  /var/home/jonathon/Luhman-16 \\
  -o IdentityFile="\$HOME/.ssh/id\_ed25519",reconnect,ServerAliveInterval=15,ServerAliveCountMax=3
```

Verify it:
```bash
findmnt /var/home/jonathon/Luhman-16
ls -la /var/home/jonathon/Luhman-16
```

Unmount the manual test:
```bash
fusermount3 -u /var/home/jonathon/Luhman-16
```

The allow_other option is not needed when only jonathon needs access. If other local users need access, add allow_other to the SSHFS options and enable it in /etc/fuse.conf:

```bash
sudo sed -i \\
  '/^[[:space:]]\*#[[:space:]]\*user\_allow\_other/s/^[[:space:]]\*#[[:space:]]\*//' \\
  /etc/fuse.conf
```

User systemd Service

7. Create the user-unit directory
```bash
mkdir -p ~/.config/systemd/user
```

8. Create the SSHFS service
```bash
vim ~/.config/systemd/user/Luhman-16-sshfs.service
```

Add:

```bash
[Unit]
Description=SSHFS mount for Luhman-16
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStartPre=/usr/bin/mkdir -p /var/home/jonathon/Luhman-16
ExecStart=/usr/bin/sshfs -f jonathon@192.0.2.10:/var/home/jonathon /var/home/jonathon/Luhman-16 -o IdentityFile=%h/.ssh/id\_ed25519,reconnect,ServerAliveInterval=15,ServerAliveCountMax=3
ExecStop=/usr/bin/fusermount3 -u /var/home/jonathon/Luhman-16
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

9. Enable and start the service

```bash
systemctl --user daemon-reload
systemctl --user enable --now Luhman-16-sshfs.service
```

Check the service:
```bash
systemctl --user status Luhman-16-sshfs.service --no-pager
```

View the service log:
```bash
journalctl --user -u Luhman-16-sshfs.service -b --no-pager
```

Check whether it is mounted:
```bash
findmnt /var/home/jonathon/Luhman-16
```

Service Management

Restart:
```bash
systemctl --user restart Luhman-16-sshfs.service
```

Stop:
```bash
systemctl --user stop Luhman-16-sshfs.service
```

Start:
```bash
systemctl --user start Luhman-16-sshfs.service
```

Unmount manually after stopping the service:
```bash
systemctl --user stop Luhman-16-sshfs.service
fusermount3 -u /var/home/jonathon/Luhman-16
```

If the service should start even when jonathon is not logged in:
```bash
sudo loginctl enable-linger jonathon
```

