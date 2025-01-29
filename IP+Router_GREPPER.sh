#!/bin/bash

get_local_ip() {
    local ip_address
    ip_address=$(ifconfig | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | head -n 1)
    echo "Local IP Address: $ip_address"
}

get_subnet_mask() {
    local subnet_mask
    subnet_mask=$(ifconfig | grep -w 'netmask' | awk '{print $4}' | head -n 1)
    echo "Subnet Mask: $subnet_mask"
}

get_dns_servers() {
    local dns_servers
    dns_servers=$(cat /etc/resolv.conf | grep 'nameserver' | awk '{print $2}')
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

explain_program() {
    echo "This script retrieves and displays network-related information, including:"
    echo "- Local IP Address: The private IP assigned to your device on the network."
    echo "- Router IP Address: The default gateway address of the network."
    echo "- Router MAC Address: The MAC address of the router."
    echo "- Router Make & Model: The detected brand/model of the router."
    echo "- DNS Servers: The DNS resolvers your system is using."
    echo "- WAN IP Address: The public IP address assigned by your ISP."
    echo "Use this script for network diagnostics and monitoring."
}

main(){
    explain_program
    get_wan_ip
    get_router_ip
    get_dns_servers
    get_router_mac
    get_local_ip
    get_router_make_model
}
main 
