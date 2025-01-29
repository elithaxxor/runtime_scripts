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

install_dependencies() {
    echo "Attempting to install SNMP and UPnP packages..."
    sudo apt install -y snmp miniupnpc dig nslookup 

    # Check for a Debian/Ubuntu-based system
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update -y
        sudo apt-get install -y snmp miniupnpc
    # Check for a RedHat/CentOS-based system
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y net-snmp miniupnpc
    else
        echo "No compatible package manager found. Please install 'snmp' and 'miniupnpc' manually."
    fi
}


# Retrieve local IP address
get_local_ip() {
    local ip_address=$(ip route get 1 | awk '{print $7; exit}')
    echo "Local IP Address: $ip_address"
}

# Retrieve router IP address
get_router_ip() {
    # Pull the default gateway (assumed router IP)
    local router_ip
    router_ip=$(ip route | grep 'default' | awk '{print $3}' | head -n 1)

    if [ -z "$router_ip" ]; then
        echo "Could not detect router IP via 'ip route'."
        return 1
    fi

    echo "$router_ip"
    return 0
}

get_router_dns_table() {
    local router_ip
    router_ip=$(get_router_ip)

    if [ $? -ne 0 ] || [ -z "$router_ip" ]; then
        echo "Router IP not found. Aborting local DNS table retrieval."
        return 1
    fi

    echo "Using router IP: $router_ip"

    # Output files
    local txt_file="router_dns_table.txt"
    local json_file="router_dns_table.json"

    # Clear previous files
    > "$txt_file"
    > "$json_file"

    echo "Fetching local DNS data (SNMP, UPnP, and fallback)..." | tee -a "$txt_file"
    echo "Router IP: $router_ip" | tee -a "$txt_file"

    # JSON start
    echo "[" >> "$json_file"

    # We'll store all findings in an array of strings: "IP|HOSTNAME"
    local dns_results=()

    # 3.1) SNMP Attempt
    echo -e "\n--- SNMP Attempt ---" | tee -a "$txt_file"
    if command -v snmpwalk &>/dev/null; then
        # Attempt to walk some MIB branches that might reveal DNS or host mappings
        # NOTE: There's no universal MIB for DNS table. We'll just grep any possible 'dns' or 'host' patterns.
        snmp_data=$(snmpwalk -v2c -c public "$router_ip" 1.3.6.1.4.1 2>/dev/null | grep -iE "dns|host")

        if [ -n "$snmp_data" ]; then
            echo "SNMP data found (filtered by 'dns|host'):" | tee -a "$txt_file"
            echo "$snmp_data" | tee -a "$txt_file"

            # Attempt naive extraction of IP/host from SNMP lines
            # This part is highly router-specific and may need adjustments.
            while read -r line; do
                # Example line: SNMPv2-SMI::enterprises.xxx.yyy.zzz.0 = STRING: "hostname:somehost ip:192.168.1.20"
                possible_ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
                possible_host=$(echo "$line" | grep -oE '([A-Za-z0-9_-]+\.[A-Za-z0-9._-]+)')
                # If we have both, store them
                if [ -n "$possible_ip" ] && [ -n "$possible_host" ]; then
                    dns_results+=("$possible_ip|$possible_host")
                fi
            done <<< "$snmp_data"
        else
            echo "No matching SNMP DNS/host data found." | tee -a "$txt_file"
        fi
    else
        echo "snmpwalk not available. Skipping SNMP attempt." | tee -a "$txt_file"
    fi

    # 3.2) UPnP Attempt
    echo -e "\n--- UPnP Attempt ---" | tee -a "$txt_file"
    if command -v upnpc &>/dev/null; then
        # upnpc -l lists port mappings, might include some host info in certain routers
        upnp_data=$(upnpc -l 2>/dev/null)
        if [ -n "$upnp_data" ]; then
            echo "UPnP data found:" | tee -a "$txt_file"
            echo "$upnp_data" | tee -a "$txt_file"

            # Attempt naive extraction
            # In practice, upnpc typically won't show local DNS entries, just port mappings
            # But we might see host info in device descriptions. This is router-dependent.
            while read -r line; do
                possible_ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
                # Check if there's a possible domain in line
                possible_host=$(echo "$line" | grep -oE '([A-Za-z0-9_-]+\.[A-Za-z0-9._-]+)')
                if [ -n "$possible_ip" ] && [ -n "$possible_host" ]; then
                    dns_results+=("$possible_ip|$possible_host")
                fi
            done <<< "$upnp_data"
        else
            echo "No UPnP data found or router does not support it." | tee -a "$txt_file"
        fi
    else
        echo "upnpc not available. Skipping UPnP attempt." | tee -a "$txt_file"
    fi

    # 3.3) Fallback: DNS Brute Force via nslookup
    # For example, we'll assume a 192.168.1.x LAN. Adjust to your subnet if needed.
    echo -e "\n--- Fallback DNS Brute Force ---" | tee -a "$txt_file"
    if command -v nslookup &>/dev/null; then
        # Typically, you'd detect your subnet. We'll guess 192.168.1.0/24 for demo:
        local subnet_prefix="192.168.1"
        for ip_host in {1..254}; do
            local test_ip="${subnet_prefix}.${ip_host}"
            # Ask the router to resolve that IP's hostname
            hostname=$(nslookup "$test_ip" "$router_ip" 2>/dev/null | awk '/name =/ {print $4}' | sed 's/\.$//')
            if [ -n "$hostname" ]; then
                dns_results+=("$test_ip|$hostname")
            fi
        done
        echo "Brute force complete." | tee -a "$txt_file"
    else
        echo "nslookup not installed or not found." | tee -a "$txt_file"
    fi

    # 3.4) Remove duplicates & sort
    sorted_unique_dns=$(echo "${dns_results[@]}" | tr ' ' '\n' | sort -u)

    echo -e "\n--- Consolidated DNS Entries ---" | tee -a "$txt_file"
    if [ -z "$sorted_unique_dns" ]; then
        echo "No DNS entries found." | tee -a "$txt_file"
    else
        # Print to console and .txt
        while read -r entry; do
            ip="${entry%%|*}"
            host="${entry##*|}"
            echo "IP: $ip  Hostname: $host" | tee -a "$txt_file"
        done <<< "$sorted_unique_dns"
    fi

    # 3.5) Save JSON
    # Build an array of JSON objects
    echo "[" >> "$json_file"
    first_record=true
    while read -r entry; do
        ip="${entry%%|*}"
        host="${entry##*|}"

        # Skip empty lines
        if [ -z "$ip" ] || [ -z "$host" ]; then
            continue
        fi

        # Comma separate JSON objects
        if [ "$first_record" = true ]; then
            first_record=false
        else
            echo "," >> "$json_file"
        fi
        echo "  { \"ip\": \"$ip\", \"hostname\": \"$host\" }" >> "$json_file"
    done <<< "$sorted_unique_dns"
    echo "]" >> "$json_file"

    echo -e "\nDNS table saved to:"
    echo " - Text:  $txt_file"
    echo " - JSON:  $json_file"
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

    # 1_ Print all discovered IPs
    echo -e "\nDiscovered IP Addresses:"
    printf "%s\n" "${discovered_ips[@]}"
    
    # 2) Write to JSON
    echo "[" >> "$output_json"
    local first_record=true
    for ip in "${discovered_ips[@]}"; do
        # Separate JSON objects with a comma if not the first record
        if [ "$first_record" = true ]; then
            first_record=false
        else
            echo "," >> "$output_json"
        fi
        echo "  { \"ip\": \"$ip\" }" >> "$output_json"
    done
    echo "]" >> "$output_json"

    # Print console message
    echo -e "\nSaved discovered IPs to:"
    echo " - $output_txt"
    echo " - $output_json"
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
File Outputs

    router_dns_table.txt – Human-readable text with any discovered entries.
    router_dns_table.json – JSON array of { "ip": "...", "hostname": "..." } objects.
echo "hi"
main
echo "\nbye"
