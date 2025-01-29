#!/bin/bash

# Display script information
whatDoIdO() {
    echo "\n========================================="
    echo "      NETWORK INFORMATION SCRIPT       "
    echo "========================================="
    echo "This script retrieves and displays:"
    echo "- Local IP Address"
    echo "- Router IP Address"
    echo "- Router MAC Address"
    echo "- Router Make & Model"
    echo "- Router Firmware Version"
    echo "- DNS Servers"
    echo "- WAN IP Address"
    echo "- ARP Table Scan"
    echo "========================================="
}

# Summary after execution
whatDidIdo() {
    echo "\n========================================="
    echo "           SUMMARY OF RESULTS           "
    echo "========================================="
}

# Install required dependencies
install_dependencies() {
    echo "\nInstalling dependencies..."
    sudo apt install -y snmp miniupnpc dig nslookup 
}

# Retrieve local IP address
get_local_ip() {
    local ip_address=$(ip route get 1 | awk '{print $7; exit}')
    echo "Local IP Address: $ip_address"
}

# Retrieve router IP address
get_router_ip() {
    local router_ip=$(ip route | grep default | awk '{print $3}')
    echo "Router IP Address: $router_ip"
}

# Retrieve subnet mask
get_subnet_mask() {
    local subnet_mask=$(ifconfig | grep -w 'netmask' | awk '{print $4}' | head -n 1)
    echo "Subnet Mask: $subnet_mask"
}

# Retrieve DNS servers
get_dns_servers() {
    echo "DNS Servers:"
    awk '/^nameserver/ {print " - "$2}' /etc/resolv.conf
}

# Retrieve WAN IP address
get_wan_ip() {
    local wan_ip=$(curl -s https://api64.ipify.org)
    echo "WAN IP Address: $wan_ip"
}

# Retrieve router MAC address
get_router_mac() {
    local router_mac=$(arp -n | grep -m1 "$(get_router_ip)" | awk '{print $3}')
    echo "Router MAC Address: $router_mac"
}
get_arp_table_with_hostnames() {
    echo "Fetching ARP table and resolving hostnames..."
    
    # Copy the ARP table
    arp_table=$(arp -a)

    # Initialize an array to store discovered IPs
    discovered_ips=()

    # Print table header
    printf "%-20s %-20s %-20s\n" "IP Address" "MAC Address" "Hostname"
    echo "------------------------------------------------------------"

    # Process each line of the ARP table
    echo "$arp_table" | while read -r line; do
        ip=$(echo "$line" | awk '{print $2}' | tr -d '()')
        mac=$(echo "$line" | awk '{print $4}')
        hostname=$(nslookup "$ip" 2>/dev/null | awk '/name =/ {print $4}' | sed 's/\.$//')

        # If no hostname is found, use "Unknown"
        if [ -z "$hostname" ]; then
            hostname="Unknown"
        fi

        # Store discovered IP
        if [ -n "$ip" ]; then
            discovered_ips+=("$ip")
        fi

        # Print formatted output
        printf "%-20s %-20s %-20s\n" "$ip" "$mac" "$hostname"
    done

    # Print all discovered IPs
    echo -e "\nDiscovered IP Addresses:"
    printf "%s\n" "${discovered_ips[@]}"
}

# Retrieve router make and model
get_router_make_model() {
    local router_ip=$(get_router_ip)
    local make_model=$(curl -s "http://$router_ip" | grep -i -o -E "Netgear|TP-Link|Asus|Linksys|D-Link|Cisco|Arris|Motorola|Ubiquiti|MikroTik" | head -n 1)
    make_model=${make_model:-"Unknown (Check router web interface manually)"}
    echo "Router Make & Model: $make_model"
}

# Retrieve router firmware version
get_router_firmware() {
    local router_ip=$(get_router_ip)
    echo "\nChecking Router Firmware Version..."

    # Try SNMP
    if command -v snmpwalk &>/dev/null; then
        firmware_snmp=$(snmpwalk -v2c -c public "$router_ip" 1.3.6.1.2.1.1.1.0 2>/dev/null | awk -F ': ' '{print $2}')
        if [ ! -z "$firmware_snmp" ]; then
            echo "Router Firmware (SNMP): $firmware_snmp"
            return
        fi
    fi

    # Try HTTP
    firmware_http=$(curl -s "http://$router_ip" | grep -i -oE "Firmware Version[: ]?[0-9A-Za-z.\-]+" | head -n 1)
    if [ ! -z "$firmware_http" ]; then
        echo "Router Firmware (HTTP): $firmware_http"
        return
    fi

    # Try UPnP
    if command -v upnpc &>/dev/null; then
        firmware_upnp=$(upnpc -l 2>/dev/null | grep -i "firmware" | awk -F ': ' '{print $2}')
        if [ ! -z "$firmware_upnp" ]; then
            echo "Router Firmware (UPnP): $firmware_upnp"
            return
        fi
    fi

    echo "Router Firmware: Unknown (Check router web interface manually)"
}

get_router_dns_table() {
    output_file="router_dns_table.txt"

    echo "Fetching local DNS table from the router..."
    echo "Local DNS Table:" > "$output_file"

    # Get router IP address (assumes default gateway is the router)
    router_ip=$(ip route | grep default | awk '{print $3}')
    echo "Router IP: $router_ip" | tee -a "$output_file"

    echo -e "\nLocal DNS Entries:" | tee -a "$output_file"

    # Attempt to retrieve DNS records via nslookup
    for ip in $(seq 1 254); do
        hostname=$(nslookup 192.168.1.$ip "$router_ip" 2>/dev/null | awk '/name =/ {print $4}' | sed 's/\.$//')
        if [ -n "$hostname" ]; then
            echo "192.168.1.$ip - $hostname" | tee -a "$output_file"
        fi
    done

    echo -e "\nDNS table saved to $output_file"
}



main() {
    whatDoIdO

    install_dependencies

    echo "\n-----------------------------------------"
    echo "             NETWORK DETAILS             "
    echo "-----------------------------------------"
    get_local_ip
    get_router_ip
    get_subnet_mask
    get_dns_servers
    get_wan_ip
    get_router_mac
    get_router_make_model
    get_router_firmware
    get_arp_table_with_hostnames
    get_router_dns_table
    whatDidIdo
}

echo "hi"
main
echo "\nbye"
