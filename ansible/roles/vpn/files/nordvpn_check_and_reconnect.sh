#! /bin/bash

lan_face="$1"
vpn_arg="$2"

function log {
    if [[ -n "$1" ]]; then
        echo "$(date): $1" >> /var/log/nordvpn/reconnect.log
    else
        while IFS= read -r line; do
            echo "$(date): ${line}" >> /var/log/nordvpn/reconnect.log
        done
    fi
}

# if wan is down then reconnect vpn
if ! /usr/local/bin/test_wan; then
    log "Internet is down, reconnecting to VPN..."
    /usr/local/bin/nordvpn_reconnect "${lan_face}" "${vpn_arg}" 2>&1 | log || true
fi

# test again to confirm
if ! /usr/local/bin/test_wan; then
    log "Error: Internet is still down after VPN reconnect"
    exit 1
fi

log "Internet is up, no action needed"
exit 0