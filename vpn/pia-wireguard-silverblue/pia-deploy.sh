#!/bin/bash

# --- DISPOSABLE PIA DEPLOYMENT SCRIPT ---
# Author: Jonathon (Fedora-Hub)
# ----------------------------------------

# 1. Prompt for PIA Credentials (not stored)
read -p "Enter PIA Username (p#######): " PIA_USER
read -s -p "Enter PIA Password: " PIA_PASS
echo -e "\n"

# 2. ENSURE NO PIA CONNECTION IS ACTIVE
# Latency tests and handshakes can fail if an old tunnel is still up.
if nmcli con show --active | grep -q '^pia'; then
    echo "⏸️ Bringing down active PIA VPN for fresh deployment..."
    nmcli con down pia
fi

TEMP_BOX="pia-temp-setup"

# 3. CLEANUP PREVIOUS SESSIONS
echo "🧹 Cleaning up previous files and containers..."
rm -rf ~/manual-connections ~/pia.conf
toolbox rm -f $TEMP_BOX 2>/dev/null

# 4. CREATE DISPOSABLE CONTAINER
echo "📦 Creating temporary toolbox..."
toolbox create -y -c $TEMP_BOX
toolbox run -c $TEMP_BOX sudo dnf install -y git wireguard-tools jq curl -y

# 5. GENERATE KEYS VIA CONTAINER
echo "🌐 Generating fresh WireGuard keys (Automatic Mode)..."
toolbox run -c $TEMP_BOX bash -c "
git clone https://github.com/pia-foss/manual-connections.git ~/manual-connections
cd ~/manual-connections

export PIA_USER='$PIA_USER'
export PIA_PASS='$PIA_PASS'
export VPN_PROTOCOL=wireguard
export PIA_CONNECT=false
export AUTOCONNECT=true
export PIA_PF=false
export DISABLE_IPV6=yes
export PIA_CONF_PATH='/tmp/pia.conf'

# Run the script with piped empty strings to handle remaining prompts
yes '' | sudo -E ./run_setup.sh
"

# 6. EXTRACT CONFIGURATION TO HOST
echo "📂 Extracting configuration..."
HOST_PIA_FILE="$HOME/pia.conf"
if toolbox run -c $TEMP_BOX sudo cat /tmp/pia.conf > "$HOST_PIA_FILE" 2>/dev/null; then
    echo "✅ Configuration extracted successfully!"
    chmod 600 "$HOST_PIA_FILE"
else
    echo "❌ Error: Could not find pia.conf. Please check credentials."
    toolbox rm -f $TEMP_BOX
    exit 1
fi

# 7. DELETE DISPOSABLE CONTAINER
echo "🗑️ Deleting temporary toolbox..."
toolbox rm -f $TEMP_BOX
rm -rf ~/manual-connections

# 8. INTEGRATE WITH NETWORKMANAGER
echo "⚙️ Integrating with NetworkManager..."
nmcli connection delete pia 2>/dev/null
nmcli connection import type wireguard file "$HOST_PIA_FILE"

# 9. PERFORMANCE OPTIMIZATIONS
# MTU 1320 is the sweet spot for High-Speed Fiber VPNs
nmcli connection modify pia wireguard.mtu 1320
# Force Cloudflare + PIA DNS to ensure no leaks and high stability
nmcli connection modify pia ipv4.dns "1.1.1.1 10.0.0.1"
nmcli connection modify pia ipv4.ignore-auto-dns yes

# 10. ACTIVATE AND VERIFY
echo "🚀 Activating VPN..."
nmcli connection up pia

echo "-------------------------------------"
sleep 2 # Wait for handshake
sudo wg show pia | grep -E "endpoint|handshake|transfer"
echo "-------------------------------------"
curl --connect-timeout 5 ipinfo.io
echo "-------------------------------------"
echo "✅ Setup Complete. Toolbox removed. Connection active."

