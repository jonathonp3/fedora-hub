#!/bin/bash

# --- PIA AUTOSTART (STABLE PORTABLE VERSION) ---
# -----------------------------------------------

# 1. Detect the absolute home path safely
USER_HOME=$(getent passwd $USER | cut -d: -f6)

# --- PATH CONFIGURATION ---
CREDS_FILE="$USER_HOME/.pia-creds"
PIA_CONF="$USER_HOME/.pia.conf"
SCRIPT_DIR="$USER_HOME/.opt/pia-manual"
# --------------------------

# 2. Read credentials
if [ ! -f "$CREDS_FILE" ]; then
    echo "❌ Error: $CREDS_FILE not found."
    exit 1
fi
PIA_USER=$(sed -n '1p' "$CREDS_FILE")
PIA_PASS=$(sed -n '2p' "$CREDS_FILE")

# 3. ENSURE NO PIA CONNECTION IS ACTIVE
sudo -n nmcli con down pia 2>/dev/null
sudo -n nmcli con down .pia 2>/dev/null

# 4. Generate keys inside container
toolbox run -c apps bash -c "
cd $SCRIPT_DIR || exit 1
export PIA_USER='$PIA_USER'
export PIA_PASS='$PIA_PASS'
export VPN_PROTOCOL=wireguard
export PIA_CONNECT=false
export AUTOCONNECT=true
export PIA_PF=false
export DISABLE_IPV6=yes
export PIA_CONF_PATH='$PIA_CONF'
yes '' | sudo -n -E ./run_setup.sh
"

# 5. Import with the "Temporary Copy" trick
if [ -s "$PIA_CONF" ]; then
    echo "✅ Fresh config generated. Integrating..."
    
    # Remove old profiles (both named versions) to prevent duplicates
    sudo -n nmcli connection delete pia 2>/dev/null
    sudo -n nmcli connection delete .pia 2>/dev/null
    
    # THE TRICK: Copy the hidden file to a temporary non-hidden file
    # This forces NetworkManager to name the connection 'pia' and the device 'pia'
    cp "$PIA_CONF" /tmp/pia.conf
    sudo -n nmcli connection import type wireguard file /tmp/pia.conf
    rm -f /tmp/pia.conf
    
    # Apply optimizations to the clean name 'pia'
    sudo -n nmcli connection modify pia wireguard.mtu 1320 ipv4.dns "1.1.1.1 10.0.0.1" ipv4.ignore-auto-dns yes
    
    # Start it up
    sudo -n nmcli connection up pia
else
    echo "⚠️ Fresh key generation failed, attempting to bring up last known profile..."
    sudo -n nmcli connection up pia 2>/dev/null
fi

# 6. Final Verification
sleep 5
sudo -n wg show pia | grep -E "endpoint|handshake|transfer"
curl --connect-timeout 10 -s ipinfo.io | grep -E "ip|city|org"

