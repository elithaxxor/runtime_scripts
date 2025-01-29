#!/bin/bash

"""     [HOW TO GET ROUTERS MAKE AND MODEL] 
    1. get_router_ip: Extracts the default gateway IP.
    2. get_router_mac: Uses the arp command to get the router’s MAC address.
    3. get_router_make_model: Attempts to detect the router's make and model by fetching its web interface and checking for common brand names.
"""

explain_program() {
    echo "This script retrieves and displays network-related information"
    echo "- Router MAC Address: The MAC address of the router."
    echo "- Router Make & Model: The detected brand/model of the router."
    echo "Use this script for network diagnostics and monitoring."
}

install_dependencies(){
    sudo apt install snmp
    sudo apt install miniupnpc
}


get_local_ip() {
    local ip_address
    ip_address=$(ip route get 1 | awk '{print $7; exit}')
    echo "Local IP Address: $ip_address"
}

get_router_ip() {
    local router_ip
    router_ip=$(ip route | grep default | awk '{print $3}')
    echo "Router IP Address: $router_ip"
}

get_subnet_mask() {
    local subnet_mask
    subnet_mask=$(ifconfig | grep -w 'netmask' | awk '{print $4}' | head -n 1)
    echo "Subnet Mask: $subnet_mask"
}

get_dns_servers() {
    local dns_servers
    dns_servers=$(awk '/^nameserver/ {print $2}' /etc/resolv.conf)
    echo "DNS Servers:"
    echo "$dns_servers"
}

get_wan_ip() {
    local wan_ip
    wan_ip=$(curl -s https://api64.ipify.org)
    echo "WAN IP Address: $wan_ip"
}

get_free_ip_grabber() {
    local grabber_url
    grabber_url=$(curl -s "https://pastebin.com/raw/ip_grabber_link" || echo "Failed to fetch IP grabber.")
    echo "Free IP Grabber URL: $grabber_url"
}

get_router_mac() {
    local router_mac
    router_mac=$(arp -n | grep -m1 "$(get_router_ip)" | awk '{print $3}')
    echo "Router MAC Address: $router_mac"
}

get_router_make_model() {
    local router_ip
    router_ip=$(get_router_ip)
    local make_model
    make_model=$(curl -s "http://$router_ip" | grep -i -o -E "Netgear|TP-Link|Asus|Linksys|D-Link|Cisco|Arris|Motorola|Ubiquiti|MikroTik" | head -n 1)
    if [ -z "$make_model" ]; then
        make_model="Unknown (Try accessing router's web interface manually)"
    fi
    echo "Router Make & Model: $make_model"
}


get_router_firmware() {
    local router_ip
    router_ip=$(get_router_ip)
    
    echo "Attempting to retrieve router firmware version..."

    # Try SNMP (if enabled)
    if command -v snmpwalk &>/dev/null; then
        firmware_snmp=$(snmpwalk -v2c -c public "$router_ip" 1.3.6.1.2.1.1.1.0 2>/dev/null | awk -F ': ' '{print $2}')
        if [ ! -z "$firmware_snmp" ]; then
            echo "Router Firmware (SNMP): $firmware_snmp"
            return
        fi
    fi

    # Try HTTP request to the router's login page
    firmware_http=$(curl -s "http://$router_ip" | grep -i -oE "Firmware Version[: ]?[0-9A-Za-z.\-]+" | head -n 1)
    if [ ! -z "$firmware_http" ]; then
        echo "Router Firmware (HTTP): $firmware_http"
        return
    fi

    # Try UPnP (if enabled)
    if command -v upnpc &>/dev/null; then
        firmware_upnp=$(upnpc -l 2>/dev/null | grep -i "firmware" | awk -F ': ' '{print $2}')
        if [ ! -z "$firmware_upnp" ]; then
            echo "Router Firmware (UPnP): $firmware_upnp"
            return
        fi
    fi

    echo "Router Firmware: Unknown (Try accessing the router's web interface manually)"
}


main(){
    explain_program

    echo "installing dependecies" 
    install_dependencies
    
    echo "- WAN IP Address: The public IP address assigned by your ISP."
    get_wan_ip
    
    get_subnet_mask
    
    echo "- Router IP Address: The default gateway address of the network."
    get_router_ip
    
    echo "- DNS Servers: The DNS resolvers your system is using."
    get_dns_servers
    
    echo "get_router_mac: Uses the arp command to get the router’s MAC address."
    get_router_mac
    
    echo "- Local IP Address: The private IP assigned to your device on the network."
    get_local_ip

    echo "get_router_make_model: Attempts to detect the router's make and model by fetching its web interface and checking for common brand names."
    get_router_make_model
}

echo "hi"
main 
echo "bye" 
