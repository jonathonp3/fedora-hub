#!/bin/bash

# --- UNIVERSAL DISPOSABLE PIA DEPLOYMENT SCRIPT ---
# Supports: Distrobox (Bazzite) and Toolbox (Silverblue)
# Author: Jonathon (Fedora-Hub)
# --------------------------------------------------

# 1. Prompt for PIA Credentials
read -p "Enter PIA Username (p#######): " PIA_USER
read -s -p "Enter PIA Password: " PIA_PASS
echo -e "\n"

# 2. ENSURE NO PIA CONNECTION IS ACTIVE
if nmcli con show --active | grep -q '^pia'; then
    echo "⏸️ Bringing down active PIA VPN for fresh deployment..."
    nmcli con down pia
fi

# 3. AUTO-DETECT ENGINE
if command -v distrobox >/dev/null 2>&1; then
    ENGINE="distrobox"
    CREATE_CMD="distrobox create -n"
    RUN_CMD="distrobox-enter -n"
    RM_CMD="distrobox rm -f"
    # Distrobox needs an image specified for creation
    CREATE_SUFFIX="--image fedora:latest --yes"
    RUN_SUFFIX="--"
elif command -v toolbox >/dev/null 2>&1; then
    ENGINE="toolbox"
    CREATE_CMD="toolbox create -y -c"
    RUN_CMD="toolbox run -c"
    RM_CMD="toolbox rm -f"
    CREATE_SUFFIX=""
    RUN_SUFFIX=""
else
    echo "❌ Error: Neither Distrobox nor Toolbox found."
    exit 1
fi

TEMP_BOX="pia-temp-deploy"

# 4. CLEANUP PREVIOUS SESSIONS
echo "🧹 Cleaning up previous files and containers..."
rm -rf ~/manual-connections ~/pia.conf
$RM_CMD $TEMP_BOX 2>/dev/null

# 5. CREATE DISPOSABLE CONTAINER
echo "📦 Creating temporary $ENGINE container..."
$CREATE_CMD $TEMP_BOX $CREATE_SUFFIX

echo "🛠️ Installing dependencies in container..."
$RUN_CMD $TEMP_BOX $RUN_SUFFIX sudo dnf install -y git wireguard-tools jq curl -y

# 6. GENERATE KEYS VIA CONTAINER
echo "🌐 Generating fresh WireGuard keys via $ENGINE..."
$RUN_CMD $TEMP_BOX $RUN_SUFFIX bash -c "
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

# Run the script automatically
yes '' | sudo -E ./run_setup.sh
"

# 7. EXTRACT CONFIGURATION TO HOST
echo "📂 Extracting configuration..."
HOST_PIA_FILE="$HOME/pia.conf"
if $RUN_CMD $TEMP_BOX $RUN_SUFFIX sudo cat /tmp/pia.conf > "$HOST_PIA_FILE" 2>/dev/null; then
    echo "✅ Configuration extracted successfully!"
    chmod 600 "$HOST_PIA_FILE"
else
    echo "❌ Error: Could not find pia.conf. Check credentials."
    $RM_CMD $TEMP_BOX
    exit 1
fi

# 8. DELETE DISPOSABLE CONTAINER
echo "🗑️ Deleting temporary $ENGINE container..."
$RM_CMD $TEMP_BOX
rm -rf ~/manual-connections

# 9. INTEGRATE WITH NETWORKMANAGER
echo "⚙️ Integrating with NetworkManager..."
nmcli connection delete pia 2>/dev/null
nmcli connection import type wireguard file "$HOST_PIA_FILE"

# PERFORMANCE OPTIMIZATIONS
nmcli connection modify pia wireguard.mtu 1320
nmcli connection modify pia ipv4.dns "1.1.1.1 10.0.0.1"
nmcli connection modify pia ipv4.ignore-auto-dns yes

# 10. ACTIVATE AND VERIFY
echo "🚀 Activating VPN..."
nmcli connection up pia

echo "-------------------------------------"
sleep 2 
sudo wg show pia | grep -E "endpoint|handshake|transfer"
echo "-------------------------------------"
curl --connect-timeout 5 -s ipinfo.io | grep -E '"(ip|city|region|org)"' | tr -d '," '
echo "-------------------------------------"
echo "✅ Setup Complete. $ENGINE removed. VPN active."

