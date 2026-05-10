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

[🚀 Click here for the Automation & Clean Home Guide](#automation-guide)

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

## Manual Installation (Recommended for first time usage so you understand the process. After that use "Advanced: Automation (Auto-start & Desktop Integration)"):

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

3. Update the host connection (replace NEW_IP and PUB_KEY accordingly)
```bash
nmcli connection modify pia wireguard.peers "PUB_KEY endpoint=NEW_IP:1337 allowed-ips=0.0.0.0/0"
```

4. Re-activate
```bash
nmcli connection up pia
```
<a name="automation-guide"></a>
## 🤖 Advanced: Automation (Auto-start & Desktop Integration keeping your home directory clean)

To have your VPN automatically refresh keys and connect silently whenever you restart, and to have a "Renew" icon in your apps menu.
1. Create a Secure Credentials File

Store your PIA login info so the script can read it headlessly.
bash
```bash
vi ~/.pia-creds
```

Add your credentials (one per line):
```bash
p0939480
YourPasswordHere
```
Set permissions:
```bash
chmod 600 ~/.pia-creds
```

2. Configure Passwordless Sudo (Host)
Tell the host to allow the autostart script to manage the network without a password.
```bash
sudo visudo -f /etc/sudoers.d/pia-vpn
```
Add the following line (replace jonathon with your username):
```bash
jonathon ALL=(ALL) NOPASSWD: /usr/bin/nmcli, /usr/bin/wg, /var/home/jonathon/.opt/pia-manual/pia-autostart.sh
```
3. Create and Prepare the "Apps" Toolbox

We use a permanent hidden directory to keep your home folder clean.

a) Create the hidden directory & toolbox:
```bash
mkdir -p ~/.opt/pia-manual
toolbox create -c apps
```
b) Enter toolbox and install requirements:
```bash
toolbox enter apps
sudo dnf install git wireguard-tools jq curl -y
```
c) Clone the PIA scripts into the hidden folder:
```bash
cd ~/.opt/pia-manual
git clone https://github.com/pia-foss/manual-connections.git .
```

d) Set up Passwordless Sudo INSIDE the container:
bash
```bash
sudo visudo
```
Inside visudo, add to the bottom (replace jonathon with your username):
text
```bash
jonathon ALL=(ALL) NOPASSWD: ALL
```
Save and exit, then type exit to return to the host.

4. Deploy the Autostart Script

Copy the script from the repository to your hidden .opt folder:
```bash
cp ~/fedora-hub/vpn/pia-wireguard-silverblue/pia-autostart.sh /var/home/jonathon/.opt/pia-manual/
```
Make the script executable
```bash
chmod +x /var/home/jonathon/.opt/pia-manual/pia-autostart.sh
```

5. Create the Systemd User Service

This triggers the script automatically every time you log into your desktop.
```bash
mkdir -p ~/.config/systemd/user/
vi ~/.config/systemd/user/pia-vpn.service
```
Add the following configuration:
```bash
[Unit]
Description=Start PIA VPN on Login
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/var/home/jonathon/.opt/pia-manual/pia-autostart.sh
RemainAfterExit=yes

[Install]
WantedBy=default.target
```
6. Create the Desktop "Renew" Launcher

This adds a "Renew PIA VPN" icon to your GNOME applications menu.
```bash
mkdir -p ~/.local/share/applications/
vi ~/.local/share/applications/pia-renew.desktop
```
Add the following configuration (replace jonathon with your username):
```bash
[Desktop Entry]
Version=1.0
Type=Application
Name=Renew PIA VPN
Comment=Refresh WireGuard keys and reconnect
Exec=sh -c '/var/home/jonathon/.opt/pia-manual/pia-autostart.sh; sleep 10'
Icon=piavpn
Terminal=true
Categories=Network;VPN;
```

7. Install the Icon
Ensure the custom icon is in a location GNOME can find:
```bash
mkdir -p ~/.local/share/icons/hicolor/256x256/apps/
cp ~/fedora-hub/vpn/pia-wireguard-silverblue/piavpn.png ~/.local/share/icons/hicolor/256x256/apps/
gtk-update-icon-cache ~/.local/share/icons/hicolor
```
8. Enable and Test
a) Reload and enable the service
```bash
systemctl --user daemon-reload
systemctl --user enable --now pia-vpn.service
```
b) Test the script manually from the hidden path
```bash
~/.opt/pia-manual/pia-autostart.sh
```
9. Maintenance & Notes

IP Refresh: If the IP changes while using the computer, simply find the "Renew PIA VPN" app in your menu and click it. It will open a terminal, show the fresh handshake, and close after 10 seconds.

Total Tidiness: All engine files live in ~/.opt/pia-manual/ and your configuration is hidden at ~/.pia.conf. Your home directory remains pristine.
