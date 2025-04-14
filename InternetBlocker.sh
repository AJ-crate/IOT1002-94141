#!/bin/bash

# InternetBlocker.sh - A script to manage internet access via iptables
# Author:Agbebi Jeremiah 
# Date: 30/03/2025

# Retrieve list of IT group users
IT_USERS=$(getent group it | cut -d: -f4 | tr ',' ' ')

# Initialize user count
USER_COUNT=0

# Ensure script runs with root privileges
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Exiting."
    exit 1
fi

# Allow IT users to access the internet
for USER in $IT_USERS; do
    if id "$USER" &>/dev/null; then
        sudo iptables -A OUTPUT -p tcp --dport 443 -m owner --uid-owner "$USER" -j ACCEPT
        ((USER_COUNT++))
    fi
done

# Allow access to local web server
sudo iptables -A OUTPUT -p tcp --dport 443 -d 192.168.2.3 -j ACCEPT

# Block all other outgoing web traffic
sudo iptables -t filter -A OUTPUT -p tcp --dport 8003 -j DROP
sudo iptables -t filter -A OUTPUT -p tcp --dport 1979 -j DROP

# Display final message
echo "Internet access granted to $USER_COUNT IT users."

exit 0

