#!/usr/bin/env bash

###############################################################################
#                            NetVision Bash Script                            #
#         Gathers network info, runs stealthy scans, sets up netcat & ngrok 
#                                @Copyleft#
###############################################################################

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
# 1) NAME & INFO
########################
whatDoIdO() {
    echo -e "\n${CYAN}========================================="
    echo -e "         NETWORK INFORMATION APP        "
    echo -e "=========================================${NC}"
    echo "This script retrieves and displays network info, scans the LAN, and:"
    echo "- Installs netcat & ngrok"
    echo "- Starts netcat listening on port 6666"
    echo "- Creates ngrok tunnels: TCP 6667 & HTTP 80"
    echo "- Performs a quick stealthy port scan + OS detection"
}

########################
# 2) SUMMARY AFTER EXEC
########################
whatDidIdo() {
    echo -e "\n${CYAN}========================================="
    echo -e "           SUMMARY OF RESULTS           "
    echo -e "=========================================${NC}"
}

########################
# 3) INSTALL DEPENDENCIES
########################
install_dependencies() {
    echo -e "\n${WHITE}Attempting to install SNMP, UPnP, nmap, netcat (nc)...${NC}"
    sudo apt install -y snmp miniupnpc dnsutils nmap netcat 2>/dev/null || true

    # Debian/Ubuntu
    if [ -x "$(command -v apt-get)" ]; then
        sudo apt-get update -y
        sudo apt-get install -y snmp miniupnpc nmap netcat
    # RedHat/CentOS
    elif [ -x "$(command -v yum)" ]; then
        sudo yum install -y net-snmp miniupnpc nmap nc
    else
        echo -e "${YELLOW}No compatible package manager found. Please install 'snmp', 'miniupnpc', 'nmap', and 'netcat' manually.${NC}"
    fi
}

########################
# 4) INSTALL & START NGROK, NETCAT
########################
install_and_start_netcat_ngrok() {
    echo -e "\n${WHITE}Installing & configuring ngrok...${NC}"

    # 4.1) Check if ngrok is already installed
    if ! command -v ngrok &>/dev/null; then
        echo -e "${YELLOW}ngrok not found; attempting download...${NC}"
        
        # Download ngrok (Linux 64-bit). Adjust for other OS/arch if needed.
        curl -sLO "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip"
        if [ -f "ngrok-stable-linux-amd64.zip" ]; then
            unzip -o ngrok-stable-linux-amd64.zip
            chmod +x ngrok
            sudo mv ngrok /usr/local/bin/
            rm -f ngrok-stable-linux-amd64.zip
            echo -e "${GREEN}ngrok installed to /usr/local/bin/ngrok${NC}"
        else
            echo -e "${RED}Failed to download ngrok. Please install manually.${NC}"
        fi
    else
        echo -e "${GREEN}ngrok is already installed.${NC}"
    fi

    # 4.2) Optional: set your ngrok auth token if you want persistent tunnels
    # If you have an authtoken, uncomment and replace YOUR_TOKEN_HERE:
    # ngrok config add-authtoken "YOUR_TOKEN_HERE"

    # 4.3) Start netcat listener on port 6666 in background
    echo -e "\n${CYAN}Starting netcat listener on port 6666...${NC}"
    # -l = listen mode, -p 6666 = port, -v = verbose
    # run in background (&)
    nc -lvp 6666 > /dev/null 2>&1 &
    echo -e "${GREEN}Netcat listening on port 6666 (PID $!).${NC}"

    # 4.4) Start ngrok TCP on port 6667 in background
    echo -e "${CYAN}Starting ngrok TCP tunnel on port 6667...${NC}"
    ngrok tcp 6667 --log=stdout > /dev/null 2>&1 &
    echo -e "${GREEN}ngrok TCP tunnel started for port 6667 (PID $!).${NC}"

    # 4.5) Also start ngrok HTTP on port 80 in background
    echo -e "${CYAN}Starting ngrok HTTP tunnel on port 80...${NC}"
    ngrok http 80 --log=stdout > /dev/null 2>&1 &
    echo -e "${GREEN}ngrok HTTP tunnel started for port 80 (PID $!).${NC}"
}

########################
# 5) DNS SERVERS
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
# 7) ROUTER MAC
########################
get_router_mac() {
    local router_mac
    router_mac=$(arp -n | grep -m1 "$(get_router_ip)" | awk '{print $3}')
    echo -e "${MAGENTA}Router MAC Address:${NC} $router_mac"
}

########################
# 8) ARP TABLE + HOSTNAMES
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

    # 2) Save discovered IPs to JSON + TXT
    local output_txt="discovered_ips.txt"
    local output_json="discovered_ips.json"
    > "$output_txt"
    > "$output_json"

    echo "[" >> "$output_json"
    local first_record=true
    for ip in "${discovered_ips[@]}"; do
        if [ "$first_record" = true ]; then
            first_record=false
        else
            echo "," >> "$output_json"
        fi
        echo "  { \"ip\": \"$ip\" }" >> "$output_json"
        # Also append to the discovered_ips.txt file
        echo "$ip" >> "$output_txt"
    done
    echo "]" >> "$output_json"

    # Print console message
    echo -e "\n${GREEN}Saved discovered IPs to:"
    echo " - $output_txt"
    echo -e " - $output_json${NC}"
}

########################
# 9) LOCAL IP
########################
get_local_ip() {
    local ip_address
    ip_address=$(ip route get 1 | awk '{print $7; exit}')
    echo -e "${MAGENTA}Local IP Address:${NC} $ip_address"
}

########################
# 10) ROUTER IP
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
# 11) SUBNET MASK
########################
get_subnet_mask() {
    local subnet_mask
    subnet_mask=$(ifconfig 2>/dev/null | grep -w 'netmask' | awk '{print $4}' | head -n 1)
    echo -e "${MAGENTA}Subnet Mask:${NC} $subnet_mask"
}

########################
# 12) ROUTER DNS TABLE
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

    # DNS Brute Force
    echo -e "\n--- Fallback DNS Brute Force ---" | tee -a "$txt_file"
    if command -v nslookup &>/dev/null; then
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
# 13) ROUTER MAKE & MODEL
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
# 14) ROUTER FIRMWARE
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
# 15) QUICK PING & PORT SCAN (with OS Detection)
########################
quick_ping_and_port_scan() {
    local target_ip="$1"
    local output_file="quick_scan.txt"  # Full Nmap output (including OS guess)
    local ports_txt="open_ports.txt"    # Parsed open ports in TXT
    local ports_json="open_ports.json"  # Parsed open ports in JSON

    echo -e "\n${CYAN}Performing quick ping & stealthy port scan on ${WHITE}$target_ip${NC}..."
    
    # 1) Initialize or clear the files
    echo "Target: $target_ip" > "$output_file"
    > "$ports_txt"
    > "$ports_json"

    # 2) Check if host is up via ping (-c 1, -W 1)
    local ping_result
    ping_result=$(ping -c 1 -W 1 "$target_ip" 2>/dev/null)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Host is up (ping successful).${NC}"
        echo "Host is up (ping successful)." >> "$output_file"

        # 3) SYN stealth scan on top 10 ports, plus OS detection (-O).
        #    --osscan-limit tries OS detection only if at least one open port is found.
        #    --osscan-guess attempts a guess if OS detection isn't definitive.
        echo -e "\n${YELLOW}Scanning top 10 TCP ports with OS detection...${NC}"
        echo "Scanning top 10 TCP ports with OS detection..." >> "$output_file"

        local scan_result
        scan_result=$(sudo nmap -sS -n --top-ports 10 -O --osscan-limit --osscan-guess "$target_ip" 2>/dev/null)

        # 4) Write the raw scan output to the main log file
        echo "$scan_result" >> "$output_file"

        # 5) Parse open ports from the nmap output
        local open_ports=()
        while read -r line; do
            port=$(echo "$line" | grep -Eo '^[0-9]+/tcp' | cut -d'/' -f1)
            if [ -n "$port" ]; then
                open_ports+=("$port")
            fi
        done < <(echo "$scan_result" | grep -i "open")

        # 6) Attempt to extract OS details
        local os_detect
        # Common lines are "Running:", "OS details:", "Aggressive OS guesses:"
        os_detect=$(echo "$scan_result" | grep -E "Running:|OS details:|Aggressive OS guesses:")

        if [ ${#open_ports[@]} -eq 0 ]; then
            echo -e "${RED}No open ports found in the top 10.${NC}"
            echo "No open ports found in the top 10." >> "$output_file"
        else
            # Save open ports to a TXT file
            echo "Open Ports:" >> "$ports_txt"
            for p in "${open_ports[@]}"; do
                echo "$p" >> "$ports_txt"
            done

            # Save open ports to a JSON file
            echo "[" >> "$ports_json"
            local first_port=true
            for p in "${open_ports[@]}"; do
                if [ "$first_port" = true ]; then
                    first_port=false
                else
                    echo "," >> "$ports_json"
                fi
                echo "  { \"port\": \"$p\" }" >> "$ports_json"
            done
            echo "]" >> "$ports_json"

            echo -e "${GREEN}Found open ports: ${open_ports[*]}${NC}"
            echo "Open ports saved to: $ports_txt, $ports_json" >> "$output_file"
        fi

        # 7) OS detection results
        if [ -n "$os_detect" ]; then
            echo -e "\n${GREEN}Possible OS detection results:${NC}"
            echo "$os_detect"
            echo -e "\nOS detection output:\n$os_detect" >> "$output_file"
        else
            echo -e "\n${RED}OS detection failed or was inconclusive.${NC}"
            echo -e "\nOS detection failed or was inconclusive." >> "$output_file"
        fi

    else
        echo -e "${RED}Host $target_ip seems down (ping timed out).${NC}"
        echo "Host $target_ip seems down (ping timed out)." >> "$output_file"
    fi

    echo -e "\n${GREEN}Scan results saved to $output_file${NC}"
    echo -e "${GREEN}Parsed open ports saved to $ports_txt, $ports_json${NC}"
}

########################
# 16) MAIN
########################
main() {
    whatDoIdO
    install_dependencies

    echo -e "\n${CYAN}-----------------------------------------"
    echo "             NETWORK DETAILS             "
    echo -e "-----------------------------------------${NC}"

    get_local_ip
    local router_ip
    router_ip=$(get_router_ip)
    if [ $? -eq 0 ] && [ -n "$router_ip" ]; then
        echo -e "${MAGENTA}Router IP Address:${NC} $router_ip"
    fi

    get_subnet_mask
    get_dns_servers
    get_wan_ip
    get_router_mac
    get_router_make_model
    get_router_firmware
    get_arp_table_with_hostnames
    get_router_dns_table

    # OPTIONAL: Quick port scan of the router, includes OS detection
    if [ -n "$router_ip" ]; then
        quick_ping_and_port_scan "$router_ip"
    fi

    # Finally, install & start netcat + two ngrok processes:
    #  - TCP on 6667
    #  - HTTP on 80
    install_and_start_netcat_ngrok

    whatDidIdo
}

########################
# 17) RUN THE SCRIPT
########################
echo -e "${GREEN}hi${NC}"
main
echo -e "\n${GREEN}bye${NC}"