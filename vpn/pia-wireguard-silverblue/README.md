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
bash fedora-hub/vpn/pia-wireguard-silverblue/pia-deploy.sh
```

### Manual Installation (Recommended for first time usage so you understand the process):

## Phase 1: Container Setup (Toolbox)   

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

5. Export the generated config to your home directory
(Since Toolbox shares your home folder, this is easy)
```bash
sudo cp /etc/wireguard/pia.conf ~/pia.conf
exit
```

## Phase 2: Host Integration & Optimization

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

## Phase 3: Maintenance (Updating the IP)
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



