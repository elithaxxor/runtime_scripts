#!/bin/bash

setup_network_tools() {
    echo "[!] Listing USB devices..."
    lsusb

    echo "[!] Checking airmon-ng..."
    sudo airmon-ng check

    echo "[!] Killing conflicting processes..."
    sudo airmon-ng check kill

    echo "[!] Starting airmon-ng on wlan1..."
    sudo airmon-ng start wlx049226882b21

    echo "[!] Starting airmon-ng on wlan2..."
    sudo airmon-ng start wlan2

    echo "[!] Displaying wireless configuration..."
    iwconfig

    echo "[!] Configuring Bluetooth..."
    sudo hciconfig -a
    sudo hciconfig hci0 up
    sudo hciconfig -a

    echo "Restarting NetworkManager..."
    sudo systemctl restart NetworkManager

    echo "Displaying wireless configuration again..."
    echo "Comment out the lines under 'Configuring Bluetooth' if your having issues"



    iwconfig
    echo "Connected to VPN"
}

echo "[!] [!]... This will put your cards into monitor mode. It's designed for wlan0, wlan1, wlan2. You may need to reconfigure the bash"
setup_network_tools
# sleep(3)
sudo expressvpn connect

echo "[!]
run bluetooth and broadcast mode || cd runstime_scripts && sudo bash broadcast_mode.sh
run attack-navigator ||
run netdiscover || netdiscover -i wlan0 -r 192.168.1.1/24 -L
run r4ven || python3 r4ven.py -p 2000
run caldera || python3 server.py --insecure --build
run expressvpn || expressvpn connect
docker run -p 8888:8888 caldera:latest
run starkiller || sudo starkiller
run kismet || sudo kismet
run openvas ||gvm-start
sudo docker run -d -p 443:443 --name openvas mikesplain/openvas
run proxy server ||
run vpn || sudo expressvpn connect
run webserver apache
run openvas || gvm-start
run Dradis ||sudo dradis
sudo docker run -d -p 443:443 --name openvas mikesplain/openvas
run spiderfoot || spiderfoot -l localhost:5009
run osintbudy || cd osintbudy/ ./launcher run
run osint framework || cd osif/ ./osif
run fruitywifi ||
run rustdesktop || git clone https://github.com/rustdesk/rustdesk && cd rustdesk &&docker build -t "rustdesk-builder" .
run nessus || cd '/home/frank/Nessus Professional 2024/Linux' && sudo bash nessus.sh
run dradis || sudo dradis
run mitmproxy || sudo mitmproxy --wizard
run socialphish || sudo bash socialphish.sh

"'
