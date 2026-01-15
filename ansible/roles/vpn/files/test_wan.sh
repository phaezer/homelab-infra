#!/bin/bash

# List of public IP addresses to check (using reliable public DNS servers)
IP_ADDRESSES=(
    "8.8.8.8"        # Google DNS
    "1.1.1.1"        # Cloudflare DNS
    "9.9.9.9"        # Quad9 DNS
    "208.67.222.222" # OpenDNS
)

# Number of ping attempts per IP
PING_COUNT=1
# Timeout in seconds
TIMEOUT=2

for ip in "${IP_ADDRESSES[@]}"; do
    if ping -c "${PING_COUNT}" -W "${TIMEOUT}" "${ip}" &>/dev/null; then
        echo "Success: ${ip} is reachable"
        exit 0
    fi
done

echo "Failure: None of the IP addresses are reachable"
exit 1
