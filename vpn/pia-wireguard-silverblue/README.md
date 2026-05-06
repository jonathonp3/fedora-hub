# PIA WireGuard for Fedora Silverblue

### ⚠️ The Problem
Official VPN apps often struggle with Fedora Silverblue's immutable filesystem. Manual WireGuard configurations for PIA frequently expire, require complex "handshake" scripts, or default to slow MTU settings that throttle high-speed connections.

### ✅ The Solution
A **"Stateless"** deployment script that creates a temporary **Toolbox** container to negotiate fresh WireGuard keys and then integrates the configuration directly into the host's **NetworkManager**.

### 🚀 Key Features
*   **Disposable:** Creates and deletes its own container; leaves the host OS pristine.
*   **High Performance:** Automatically applies the **1320 MTU fix**, optimized for high-speed fiber (250Mbps+).
*   **DNS Secure:** Configures a combination of Cloudflare and PIA DNS to ensure stability and prevent leaks.
*   **Fully Automated:** Handles the complex PIA API handshake automatically—just enter your credentials and the script does the rest.
*   **LAN Aware:** Built to work alongside local network bridges (e.g., `br0`) without interrupting local services like Nextcloud.

### 📥 Quick Start Install 
1. **Clone the repository:**
```bash
git clone https://github.com/jonathonp3/fedora-hub.git
```
   
Run the automatic deploy script:

```bash
cd fedora-hub
bash vpn/pia-wireguard-silverblue/pia-deploy.sh
```

## Manual Installation (Recommended for first time usage so you understand the process):

### Phase 1: Container Setup (Toolbox)   

1. Create the 'apps' toolbox
```bash
toolbox create -c apps
```

2. Enter the toolbox
```bash
toolbox enter apps
```

3. Install dependencies inside the container
```bash
sudo dnf install git wireguard-tools jq curl expect -y
```

4. Clone and run the official PIA scripts
```bash
git clone https://github.com/pia-foss/manual-connections.git
cd manual-connections
sudo ./run_setup.sh
```

**Answers to the interactive prompts:**
*   **Dedicated IP token?** → `n` (No)
*   **Forwarding port?** → `n` (No)
*   **Disable IPv6?** → `y` (Yes)
*   **Manually select server?** → `y` (Yes)
*   **Select Region:** → Choose **Melbourne** (usually `1`)
*   **Custom Latency?** → Press **Enter** (default 50ms)
*   **Force PIA DNS?** → `y` (Yes)


5. Export the generated config to your home directory
(Since Toolbox shares your home folder, this is easy)
```bash
sudo cp /etc/wireguard/pia.conf ~/pia.conf
exit
```

### Phase 2: Host Integration & Optimization

1. Take ownership of the file so your user can read it
```bash
sudo chown $USER:$USER ~/pia.conf
```

2. Clean up old profiles and import the new one
```bash
nmcli connection delete pia 2>/dev/null
nmcli connection import type wireguard file ~/pia.conf
```

3. PERFORMANCE FIX: Set MTU to 1320 (Optimized for 250Mbps+ Fiber)
```bash
nmcli connection modify pia wireguard.mtu 1320
```

4. DNS FIX: Set PIA's internal DNS and Cloudflare as backup
```bash
nmcli connection modify pia ipv4.dns "10.0.0.1 1.1.1.1"
nmcli connection modify pia ipv4.ignore-auto-dns yes
```

5. Activate the VPN
```bash
nmcli connection up pia
```

### Phase 3: Maintenance (Updating the IP)
If the connection stops working, use the toolbox to find the latest active server.

1. Get the newest server IP from the toolbox
```bash
toolbox run -c apps bash -c "cd ~/manual-connections && ./get_region.sh"
```

2. Note the IP address and Public Key from the output.

3. Update the host connection (Replace NEW_IP and PUB_KEY accordingly)
```bash
nmcli connection modify pia wireguard.peers "PUB_KEY endpoint=NEW_IP:1337 allowed-ips=0.0.0.0/0"
```

4. Re-activate
```bash
nmcli connection up pia
```

## 🤖 Advanced: Automation (Auto-start on Login)
To have your VPN automatically refresh keys and connect silently whenever you restart:

1. Create a Secure Credentials File
Store your PIA login info so the script can read it headlessly.
```bash
nano ~/.pia-creds
```
add:
```bash
# Line 1: p0939480
# Line 2: YourPassword
```
Set permissions
```bash
chmod 600 ~/.pia-creds
```
2. Configure Passwordless Sudo (Host)
```bash
sudo visudo -f /etc/sudoers.d/pia-vpn
```
Add the following line (Replace jonathon with your username):
```bash
jonathon ALL=(ALL) NOPASSWD: /usr/bin/nmcli, /usr/bin/wg, /var/home/jonathon/fedora-hub/vpn/pia-wireguard-silverblue/pia-autostart.sh
```

3.  Create and Prepare the "Apps" Toolbox:

Create the toolbox container
```bash
toolbox create -c apps
```

Enter the toolbox
```bash
toolbox enter apps
```

Install the required tools inside the container
```bash
sudo dnf install git wireguard-tools jq curl -y
```

Clone the PIA manual connections repository into your home folder
```bash
git clone https://github.com/pia-foss/manual-connections.git
```

Set up Passwordless Sudo INSIDE the container (Critical for automation)
This allows the autostart script to run 'sudo ./run_setup.sh' without a prompt
```bash
sudo visudo
```

When visudo opens, scroll to the bottom and add this line:
```bash
jonathon ALL=(ALL) NOPASSWD: ALL
```
Save and exit (Ctrl+O, Enter, Ctrl+X), then to exit the toolbox type:
```bash
exit
```

4. Create the Systemd User Service
```bash
mkdir -p ~/.config/systemd/user/
vim ~/.config/systemd/user/pia-vpn.service
```
Add the following (Change jonathon to your username):

```bash
[Unit]
Description=Start PIA VPN on Login
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/var/home/jonathon/fedora-hub/vpn/pia-wireguard-silverblue/pia-autostart.sh
RemainAfterExit=yes

[Install]
WantedBy=default.target
```

5. Test the script:
```bash
~/fedora-hub/vpn/pia-wireguard-silverblue/pia-autostart.sh
```

6. Enable the Service. Connection should appear in gnome desktop
```bash
systemctl --user daemon-reload
systemctl --user enable --now pia-vpn.service
```

7. Test vpn in the browser:
```bash
https://www.privateinternetaccess.com/what-is-my-ip
```

8. Reboot. It takes about 7 seconds to create a new connection with the latest ip address after a restart.

Note if the PIA ip changes while you are using it or you left the computer on overnight in sleep mode, just execute the script manually to renew it:
```bash
~/fedora-hub/vpn/pia-wireguard-silverblue/pia-autostart.sh
```

9. If you want to remove pia from network-manager:
```bash
nmcli connection delete pia
```


