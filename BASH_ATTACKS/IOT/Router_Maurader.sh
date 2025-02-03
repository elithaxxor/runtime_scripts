#!/usr/bin/env bash

########################
# COLOR DEFINITIONS
########################
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
MAGENTA='\033[1;35m'
RED='\033[0;31m'
NC='\033[0m' # No Color

########################
# 1) Display Script Info
########################
whatDoIdO() {
    echo -e "\n${CYAN}========================================="
    echo -e "      NETWORK INFORMATION SCRIPT        "
    echo -e "=========================================${NC}"
    echo "This script retrieves and displays:"
    echo "- Local IP Address"
    echo "- Router IP Address"
    echo "- Router MAC Address"
    echo "- Router Make & Model"
    echo "- Router Firmware Version"
    echo "- DNS Servers"
    echo "- WAN IP Address"
    echo "- ARP Table Scan"
}

########################
# 2) Summary After Execution
########################
whatDidIdo() {
    echo -e "\n${CYAN}========================================="
    echo -e "           SUMMARY OF RESULTS           "
    echo -e "=========================================${NC}"
}

########################
# 3) Install Dependencies
########################
install_dependencies() {
    echo -e "\n${WHITE}Attempting to install SNMP and UPnP packages...${NC}"
    # Minimal attempt for Debian/Ubuntu
    sudo apt install -y snmp miniupnpc dnsutils 2>/dev/null || true

    # Check for a Debian/Ubuntu-based system
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update -y
        sudo apt-get install -y snmp miniupnpc
    # Check for a RedHat/CentOS-based system
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y net-snmp miniupnpc
    else
        echo -e "${YELLOW}No compatible package manager found. Please install 'snmp' and 'miniupnpc' manually.${NC}"
    fi
}

########################
# 4) Save Discovered Data
########################
# This function references an array named `discovered_data`.
# Make sure you have `discovered_data` populated before calling it.
save_discovered_data() {
    local txt_file="discovered_data.txt"
    local json_file="discovered_data.json"

    # Clear (or create) both files
    > "$txt_file"
    > "$json_file"

    # 1) Write a header to the TXT file
    printf "%-20s %-20s %-20s\n" "IP Address" "MAC Address" "Hostname" >> "$txt_file"
    printf "%-20s %-20s %-20s\n" "----------" "-----------" "---------" >> "$txt_file"

    # 2) Start the JSON array
    echo "[" >> "$json_file"
    local first_record=true

    # 3) Loop through the discovered data
    for entry in "${discovered_data[@]}"; do
        ip="${entry%%|*}"
        remainder="${entry#*|}"
        mac="${remainder%%|*}"
        hostname="${remainder#*|}"

        # Print nicely to the TXT file
        printf "%-20s %-20s %-20s\n" "$ip" "$mac" "$hostname" >> "$txt_file"

        # Write each item as a JSON object
        if [ "$first_record" = true ]; then
            first_record=false
        else
            echo "," >> "$json_file"
        fi
        echo "  { \"ip\": \"$ip\", \"mac\": \"$mac\", \"hostname\": \"$hostname\" }" >> "$json_file"
    done

    # Close the JSON array
    echo "]" >> "$json_file"

    echo -e "\n${GREEN}Data saved to:"
    echo " - $txt_file"
    echo " - $json_file${NC}"
}

########################
# 5) DNS Servers
########################
get_dns_servers() {
    echo -e "\n${MAGENTA}DNS Servers:${NC}"
    awk '/^nameserver/ {print " - "$2}' /etc/resolv.conf
}

########################
# 6) WAN IP
########################
get_wan_ip() {
    local wan_ip
    wan_ip=$(curl -s https://api64.ipify.org)
    echo -e "${MAGENTA}WAN IP Address:${NC} $wan_ip"
}

########################
# 7) Router MAC
########################
get_router_mac() {
    local router_mac
    router_mac=$(arp -n | grep -m1 "$(get_router_ip)" | awk '{print $3}')
    echo -e "${MAGENTA}Router MAC Address:${NC} $router_mac"
}

########################
# 8) ARP Table + Hostnames
########################
get_arp_table_with_hostnames() {
    echo -e "\n${CYAN}Fetching ARP table and resolving hostnames...${NC}"
    
    # Copy the ARP table
    arp_table=$(arp -a)

    # Initialize an array to store discovered IPs
    discovered_ips=()

    # Print table header
    echo -e "${WHITE}%-20s %-20s %-20s${NC}" | xargs printf "   %s %s %s\n" "IP Address" "MAC Address" "Hostname"
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

    # 1) Print all discovered IPs
    echo -e "\n${MAGENTA}Discovered IP Addresses:${NC}"
    printf "%s\n" "${discovered_ips[@]}"

    # 2) Save discovered IPs to JSON
    local output_txt="discovered_ips.txt"
    local output_json="discovered_ips.json"
    > "$output_txt"
    > "$output_json"

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
        # Also append to a discovered_ips.txt file
        echo "$ip" >> "$output_txt"
    done
    echo "]" >> "$output_json"

    # Print console message
    echo -e "\n${GREEN}Saved discovered IPs to:"
    echo " - $output_txt"
    echo -e " - $output_json${NC}"
}

########################
# 9) Local IP
########################
get_local_ip() {
    local ip_address
    ip_address=$(ip route get 1 | awk '{print $7; exit}')
    echo -e "${MAGENTA}Local IP Address:${NC} $ip_address"
}

########################
# 10) Router IP
########################
get_router_ip() {
    local router_ip
    router_ip=$(ip route | grep 'default' | awk '{print $3}' | head -n 1)
    if [ -z "$router_ip" ]; then
        echo -e "${RED}Could not detect router IP via 'ip route'.${NC}"
        return 1
    fi
    echo "$router_ip"
    return 0
}

########################
# 11) Subnet Mask
########################
get_subnet_mask() {
    local subnet_mask
    subnet_mask=$(ifconfig 2>/dev/null | grep -w 'netmask' | awk '{print $4}' | head -n 1)
    # Some distros may use 'Mask:' or different syntax. Adjust as needed.
    echo -e "${MAGENTA}Subnet Mask:${NC} $subnet_mask"
}

########################
# 12) Router DNS Table
########################
get_router_dns_table() {
    local router_ip
    router_ip=$(get_router_ip)
    if [ $? -ne 0 ] || [ -z "$router_ip" ]; then
        echo -e "${RED}Router IP not found. Aborting local DNS table retrieval.${NC}"
        return 1
    fi

    echo -e "\n${CYAN}Using router IP: $router_ip${NC}"
    local txt_file="router_dns_table.txt"
    local json_file="router_dns_table.json"

    > "$txt_file"
    > "$json_file"

    echo -e "${MAGENTA}Fetching local DNS data (SNMP, UPnP, and fallback)...${NC}" | tee -a "$txt_file"
    echo "Router IP: $router_ip" | tee -a "$txt_file"

    # Start JSON
    echo "[" >> "$json_file"

    local dns_results=()

    # SNMP Attempt
    echo -e "\n--- SNMP Attempt ---" | tee -a "$txt_file"
    if command -v snmpwalk &>/dev/null; then
        snmp_data=$(snmpwalk -v2c -c public "$router_ip" 1.3.6.1.4.1 2>/dev/null | grep -iE "dns|host")
        if [ -n "$snmp_data" ]; then
            echo "SNMP data found (filtered by 'dns|host'):" | tee -a "$txt_file"
            echo "$snmp_data" | tee -a "$txt_file"
            while read -r line; do
                possible_ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
                possible_host=$(echo "$line" | grep -oE '([A-Za-z0-9_-]+\.[A-Za-z0-9._-]+)')
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

    # UPnP Attempt
    echo -e "\n--- UPnP Attempt ---" | tee -a "$txt_file"
    if command -v upnpc &>/dev/null; then
        upnp_data=$(upnpc -l 2>/dev/null)
        if [ -n "$upnp_data" ]; then
            echo "UPnP data found:" | tee -a "$txt_file"
            echo "$upnp_data" | tee -a "$txt_file"
            while read -r line; do
                possible_ip=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
                possible_host=$(echo "$line" | grep -oE '([A-Za-z0-9_-]+\.[A-Za-z0-9._-]+)')
                if [ -n "$possible_ip" ] && [ -n "$possible_host" ]; then
                    dns_results+=("$possible_ip|$possible_host")
                fi
            done <<< "$upnp_data"
        else
            echo "No UPnP data found or router does not expose DNS in UPnP." | tee -a "$txt_file"
        fi
    else
        echo "upnpc not available. Skipping UPnP attempt." | tee -a "$txt_file"
    fi

    # Fallback DNS Brute Force
    echo -e "\n--- Fallback DNS Brute Force ---" | tee -a "$txt_file"
    if command -v nslookup &>/dev/null; then
        # Adjust this subnet as needed
        local subnet_prefix="192.168.1"
        for i in {1..254}; do
            local test_ip="${subnet_prefix}.${i}"
            hostname=$(nslookup "$test_ip" "$router_ip" 2>/dev/null | awk '/name =/ {print $4}' | sed 's/\.$//')
            if [ -n "$hostname" ]; then
                dns_results+=("$test_ip|$hostname")
            fi
        done
        echo "Brute force complete." | tee -a "$txt_file"
    else
        echo "nslookup not available. Install dnsutils or bind-utils for fallback." | tee -a "$txt_file"
    fi

    # Remove duplicates & sort
    local sorted_unique_dns
    sorted_unique_dns=$(echo "${dns_results[@]}" | tr ' ' '\n' | sort -u)

    echo -e "\n--- Consolidated DNS Entries ---" | tee -a "$txt_file"
    if [ -z "$sorted_unique_dns" ]; then
        echo "No DNS entries found." | tee -a "$txt_file"
    else
        while read -r entry; do
            ip="${entry%%|*}"
            host="${entry##*|}"
            [ -z "$ip" ] && continue
            [ -z "$host" ] && continue
            echo "IP: $ip   Hostname: $host" | tee -a "$txt_file"
        done <<< "$sorted_unique_dns"
    fi

    # Write JSON
    local first_record=true
    while read -r entry; do
        ip="${entry%%|*}"
        host="${entry##*|}"
        [ -z "$ip" ] && continue
        [ -z "$host" ] && continue

        if [ "$first_record" = true ]; then
            first_record=false
        else
            echo "," >> "$json_file"
        fi
        echo "  { \"ip\": \"$ip\", \"hostname\": \"$host\" }" >> "$json_file"
    done <<< "$sorted_unique_dns"

    echo "]" >> "$json_file"

    echo -e "\n${GREEN}DNS table saved to:"
    echo " - Text:  $txt_file"
    echo -e " - JSON:  $json_file${NC}"
}

########################
# 13) Router Make & Model
########################
get_router_make_model() {
    local router_ip
    router_ip=$(get_router_ip)
    local make_model
    make_model=$(curl -s "http://$router_ip" | grep -i -o -E "Netgear|TP-Link|Asus|Linksys|D-Link|Cisco|Arris|Motorola|Ubiquiti|MikroTik" | head -n 1)
    make_model=${make_model:-"Unknown (Check router web interface manually)"}
    echo -e "${MAGENTA}Router Make & Model:${NC} $make_model"
}

########################
# 14) Router Firmware
########################
get_router_firmware() {
    local router_ip
    router_ip=$(get_router_ip)
    echo -e "\n${CYAN}Checking Router Firmware Version...${NC}"

    # SNMP
    if command -v snmpwalk &>/dev/null; then
        firmware_snmp=$(snmpwalk -v2c -c public "$router_ip" 1.3.6.1.2.1.1.1.0 2>/dev/null | awk -F ': ' '{print $2}')
        if [ -n "$firmware_snmp" ]; then
            echo -e "${MAGENTA}Router Firmware (SNMP):${NC} $firmware_snmp"
            return
        fi
    fi

    # HTTP
    firmware_http=$(curl -s "http://$router_ip" | grep -i -oE "Firmware Version[: ]?[0-9A-Za-z.\-]+" | head -n 1)
    if [ -n "$firmware_http" ]; then
        echo -e "${MAGENTA}Router Firmware (HTTP):${NC} $firmware_http"
        return
    fi

    # UPnP
    if command -v upnpc &>/dev/null; then
        firmware_upnp=$(upnpc -l 2>/dev/null | grep -i "firmware" | awk -F ': ' '{print $2}')
        if [ -n "$firmware_upnp" ]; then
            echo -e "${MAGENTA}Router Firmware (UPnP):${NC} $firmware_upnp"
            return
        fi
    fi

    echo -e "${YELLOW}Router Firmware: Unknown (Check router web interface manually)${NC}"
}

########################
# 15) MAIN
########################
main() {
    # 1) Intro
    whatDoIdO

    # 2) Install Dependencies
    install_dependencies

    # 3) Show Network Details
    echo -e "\n${CYAN}-----------------------------------------"
    echo "             NETWORK DETAILS             "
    echo -e "-----------------------------------------${NC}"

    get_local_ip
    local router_ip
    router_ip=$(get_router_ip)
    if [ $? -eq 0 ]; then
        echo -e "${MAGENTA}Router IP Address:${NC} $router_ip"
    fi

    get_subnet_mask
    get_dns_servers
    get_wan_ip
    get_router_mac
    get_router_make_model
    get_router_firmware

    # 4) ARP Table
    get_arp_table_with_hostnames

    # 5) Router DNS Table
    get_router_dns_table

    # 6) Summary
    whatDidIdo
}

########################
# 16) Run It All
########################
echo -e "${GREEN}hi${NC}"
main
echo -e "\n${GREEN}bye${NC}"
