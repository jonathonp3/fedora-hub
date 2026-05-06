#!/bin/bash

# --- PIA AUTOSTART (STABLE PORTABLE VERSION) ---
# Automatically detects user home for Silverblue compatibility
# -----------------------------------------------

# 1. Detect the absolute home path safely
# This works even if systemd hasn't set the $HOME variable yet
USER_HOME=$(getent passwd $USER | cut -d: -f6)

CREDS_FILE="$USER_HOME/.pia-creds"
PIA_CONF="$USER_HOME/pia.conf"
SCRIPT_DIR="$USER_HOME/manual-connections"
AUTO_SCRIPT="$USER_HOME/fedora-hub/vpn/pia-wireguard-silverblue/pia-autostart.sh"

# 2. Read credentials
if [ ! -f "$CREDS_FILE" ]; then
    echo "❌ Error: $CREDS_FILE not found."
    exit 1
fi
PIA_USER=$(sed -n '1p' "$CREDS_FILE")
PIA_PASS=$(sed -n '2p' "$CREDS_FILE")

# 3. Kill old connection (Host Sudo)
# We use sudo -n (non-interactive)
sudo -n nmcli con down pia 2>/dev/null

# 4. Generate keys inside 'apps' container
# We pass the absolute paths into the container
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

# Run the setup script silently using the NOPASSWD rule inside the box
yes '' | sudo -n -E ./run_setup.sh
"

# 5. Import and Activate
if [ -s "$PIA_CONF" ]; then
    sudo -n nmcli connection delete pia 2>/dev/null
    sudo -n nmcli connection import type wireguard file "$PIA_CONF"
    
    # Optimization & DNS
    sudo -n nmcli connection modify pia wireguard.mtu 1320 ipv4.dns "1.1.1.1 10.0.0.1" ipv4.ignore-auto-dns yes
    
    # Start it up
    sudo -n nmcli connection up pia
else
    # Fallback to existing if generation failed
    echo "⚠️ Fresh key generation failed, attempting to bring up last known profile..."
    sudo -n nmcli connection up pia
fi

# 6. Final Verification (Silent)
sleep 5
sudo -n wg show pia | grep -E "endpoint|handshake|transfer"
curl --connect-timeout 10 -s ipinfo.io | grep -E "ip|city|org"

