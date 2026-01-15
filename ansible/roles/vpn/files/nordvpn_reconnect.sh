#!/bin/bash

# nordvpn_reconnect
# Reconnects to NordVPN and manages iptables rules for a specified LAN interface.
# iptables reject rules are enabled during the reconnect process to prevent leaks.

# Arguments:
# Usage: nordvpn_reconnect <lan_interface> <vpn_argument>
# Example: nordvpn_reconnect eth0 us

lan_iface="$1"
vpn_arg="$2"

function iptables_enable_reject_rules {
    # Enable iptables reject rules for the LAN interface
    iptables -A INPUT -i "${lan_iface}" -j REJECT
    iptables -A FORWARD -i "${lan_iface}" -j REJECT
}

function iptables_disable_reject_rules {
    # Disable iptables reject rules for the LAN interface
    iptables -D INPUT -i "${lan_iface}" -j REJECT
    iptables -D FORWARD -i "${lan_iface}" -j REJECT
}

echo "Starting VPN reconnect process..."

echo "Enabling iptables reject rules on interface ${lan_iface}..."
iptables_enable_reject_rules
sleep 1

echo "Disconnecting from VPN"
nordvpn disconnect

echo "Turning off kill switch"
nordvpn set killswitch off

sleep 1

# Connect to VPN
echo "Connecting to VPN with argument: ${vpn_arg}"
nordvpn connect "${vpn_arg}"

sleep 5

echo "Turning on kill switch..."
nordvpn set killswitch on

echo "Disabling iptables reject rules on interface ${lan_iface}..."
iptables_disable_reject_rules

echo "Reconnected to VPN successfully"