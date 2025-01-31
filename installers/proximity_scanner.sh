#!/bin/bash

###############################################################################
# COLOR DEFINITIONS
###############################################################################
CYAN='\033[1;36m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

###############################################################################
# FUNCTION: Find Surrounding Wi-Fi Devices & Signal Strength
###############################################################################
findSurroundingDevicesAndDistance() {
    # The first parameter ($1) should be the wireless interface
    local interface="$1"

    # Ensure 'iw' is available
    if ! command -v iw &>/dev/null; then
        echo -e "${MAGENTA}Error: 'iw' command not found. Please install it.${NC}"
        return
    fi

    # Capture and process the raw data
    local raw_data
    raw_data=$(
        sudo iw dev "$interface" scan 2>/dev/null \
        | grep -E "signal:|SSID:" \
        | sed -e "s/\tsignal: //" -e "s/\tSSID: //" \
        | awk '{ORS = (NR % 2 == 0)? "\n" : " "; print}' \
        | sort
    )

    # Check if raw_data is empty (e.g., invalid interface or scanning error)
    if [ -z "$raw_data" ]; then
        echo -e "${MAGENTA}No networks found or invalid interface: ${interface}${NC}"
        return
    fi

    # Print a colorized header for the table
    echo -e "\n${CYAN}Nearby Wi-Fi Networks${NC}"
    echo -e "${WHITE}------------------------------------${NC}"
    printf "%-30s %s\n" "SSID" "SIGNAL (dBm)"
    echo "------------------------------------"

    # Loop through each line of processed data
    while IFS= read -r line; do
        # Each line looks like: "-55 MySSID"
        # Where the first field is the signal and the rest is the SSID
        local signal
        local ssid

        signal=$(echo "$line" | awk '{print $1}')
        ssid=$(echo "$line"   | cut -d' ' -f2-)

        # Print using aligned columns:
        # SSID is left-aligned, signal is right-aligned
        printf "%-30s %s\n" "$ssid" "$signal"
    done <<< "$raw_data"
}

###############################################################################
# MAIN FUNCTION
###############################################################################
main() {
    echo -e "${GREEN}Hi!${NC}"
    
    # Prompt user for the wireless interface
    read -rp "Enter the wireless interface (e.g. wlan0): " user_interface

    # If user did not enter anything, exit or default to a known interface
    if [ -z "$user_interface" ]; then
        echo -e "${MAGENTA}No interface provided. Exiting...${NC}"
        exit 0
    fi

    findSurroundingDevicesAndDistance "$user_interface"

    echo -e "${GREEN}Bye!${NC}"
}

main

# Example of other useful Bluetooth commands left for reference:
#   hciconfig dev
#   hcitool scan
#   hcitool inquiry
#   hcitool name <MAC_ADDRESS>
#   hcitool info <MAC_ADDRESS>
