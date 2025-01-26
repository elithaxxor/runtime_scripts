#!/bin/bash




echo "This script will:"
echo "1. Bring the specified network interface down."
echo "2. Change the MAC address to a random one."
echo "3. Change the MAC address to a specific one (86:E3:20:19:18:CA)."
echo "4. Bring the network interface back up."
echo ""
echo "Note: You will need to edit the script if you want to use a different network interface."
echo "Currently, the script is set to change the MAC address of wlan0."
echo ""


install_macchanger() {
    echo "Checking if macchanger is installed..."
    if ! command -v macchanger &> /dev/null; then
        echo "macchanger not found. Installing macchanger..."
        sudo apt update
        sudo apt install -y macchanger
    else
        echo "macchanger is already installed."
    fi
}

change_mac() {
# Function to change MAC address
    # Specify the network interface
    NETWORK_INTERFACE="wlan0"

    # Bring the network interface down
    echo "Bringing $NETWORK_INTERFACE interface down..."
    sudo ifconfig $NETWORK_INTERFACE down

    # Change to a specific MAC address
    echo "Changing MAC address of $NETWORK_INTERFACE to a specific one (86:E3:20:19:18:CA)..."
    sudo macchanger -m 86:E3:20:19:18:CA $NETWORK_INTERFACE
    
    # Change to a random MAC address
    echo "Changing MAC address of $NETWORK_INTERFACE to a random one..."
    sudo macchanger -r $NETWORK_INTERFACE


    # Bring the network interface up
    echo "Bringing $NETWORK_INTERFACE interface up..."
    sudo ifconfig $NETWORK_INTERFACE up

    echo "MAC address has been changed successfully!"
}

install_macchanger
change_mac 
