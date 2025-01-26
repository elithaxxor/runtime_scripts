#!/bin/bash

setup_network_tools() {
    echo "[!] Listing USB devices..."
    lsusb

    echo "[!] Checking airmon-ng..."
    sudo airmon-ng check

    echo "[!] Killing conflicting processes..."
    sudo airmon-ng check kill

    echo "[!] Starting airmon-ng on wlan1..."
    sudo airmon-ng start wlan1

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
}

echo "[!] [!]... This will put your cards into monitor mode. It's designed for wlan0, wlan1, wlan2. You may need to reconfigure the bash"
setup_network_tools
