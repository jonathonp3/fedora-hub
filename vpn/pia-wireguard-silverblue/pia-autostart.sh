#!/bin/bash

# --- PIA AUTOSTART (UNIVERSAL: DISTROBOX / TOOLBOX) ---
# Compatible with Fedora Silverblue, Bazzite, and Kinoite
# ------------------------------------------------------

# 1. Detect home path safely
USER_HOME=$(getent passwd $USER | cut -d: -f6)

# --- CONFIGURATION ---
CREDS_FILE="$USER_HOME/.pia-creds"
PIA_CONF="$USER_HOME/.pia.conf"
SCRIPT_DIR="$USER_HOME/.opt/pia-manual"
CONTAINER_NAME="apps"

# 2. AUTO-DETECT CONTAINER ENGINE
if command -v distrobox-enter >/dev/null 2>&1; then
    # Engine: Distrobox (Found on Bazzite)
    RUN_CMD="distrobox-enter -n $CONTAINER_NAME --"
    ENGINE="Distrobox"
elif command -v toolbox >/dev/null 2>&1; then
    # Engine: Toolbox (Found on Silverblue)
    RUN_CMD="toolbox run -c $CONTAINER_NAME"
    ENGINE="Toolbox"
else
    echo "❌ Error: Neither Distrobox nor Toolbox found."
    exit 1
fi
# ---------------------

# 3. Read credentials
if [ ! -f "$CREDS_FILE" ]; then
    echo "❌ Error: $CREDS_FILE not found."
    exit 1
fi
PIA_USER=$(sed -n '1p' "$CREDS_FILE")
PIA_PASS=$(sed -n '2p' "$CREDS_FILE")

# 4. ENSURE NO PIA CONNECTION IS ACTIVE
echo "🧹 Cleaning up connections..."
sudo -n nmcli con down pia 2>/dev/null
sudo -n nmcli con down .pia 2>/dev/null

# 5. Generate keys inside the detected container
echo "🌐 Negotiating fresh keys via $ENGINE..."
$RUN_CMD bash -c "
cd $SCRIPT_DIR || exit 1
export PIA_USER='$PIA_USER'
export PIA_PASS='$PIA_PASS'
export VPN_PROTOCOL=wireguard
export PIA_CONNECT=false
export AUTOCONNECT=true
export PIA_PF=false
export DISABLE_IPV6=yes
export PIA_CONF_PATH='$PIA_CONF'

# Run the setup script silently
yes '' | sudo -n -E ./run_setup.sh
"

# 6. Import and Integrate (The /tmp/ trick to force clean name 'pia')
if [ -s "$PIA_CONF" ]; then
    echo "✅ Fresh config generated. Integrating..."
    sudo -n nmcli connection delete pia 2>/dev/null
    sudo -n nmcli connection delete .pia 2>/dev/null
    
    # Use the temporary copy trick to force 'pia' name (not .pia)
    cp "$PIA_CONF" /tmp/pia.conf
    sudo -n nmcli connection import type wireguard file /tmp/pia.conf
    rm -f /tmp/pia.conf
    
    # Apply Speed & DNS Optimizations
    sudo -n nmcli connection modify pia wireguard.mtu 1320 ipv4.dns "1.1.1.1 10.0.0.1" ipv4.ignore-auto-dns yes
    
    echo "🚀 Activating VPN..."
    sudo -n nmcli connection up pia
else
    echo "⚠️ Fresh key failed. Falling back to existing..."
    sudo -n nmcli connection up pia 2>/dev/null
fi

# 7. Verification
echo "⏳ Verifying connection..."
sleep 5
RECEIVED=$(sudo -n wg show pia | grep "transfer" | awk '{print $2}')

echo "=========================================="
if [[ "$RECEIVED" != "0" && -n "$RECEIVED" ]]; then
    echo "🎉 SUCCESS: PIA VPN IS ACTIVE ($ENGINE)"
    sudo -n wg show pia | grep -E "endpoint|handshake|transfer"
    echo "------------------------------------------"
    # Show IP info (uses grep fallback if jq is missing)
    if command -v jq >/dev/null 2>&1; then
        curl --connect-timeout 10 -s ipinfo.io | jq -r '"📍 Location: \(.city), \(.region)\n🌐 Public IP: \(.ip)\n🏢 Provider: \(.org)"'
    else
        curl --connect-timeout 10 -s ipinfo.io | grep -E '"(ip|city|region|org)"' | tr -d '," '
    fi
else
    echo "❌ ERROR: Handshake failed (0 B received)."
fi
echo "=========================================="

