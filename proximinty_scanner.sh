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

echo " [!][!] CHANGE WIRELESS CARD DIRECTLY IN CODE [!] [!] --- ASSUMED 'wlan1' """

findSurroundingDevicesAndDistance() {
    # Capture and process the raw data
    local raw_data
    raw_data=$(
        sudo iw dev wlan1 scan \
        | egrep "signal:|SSID:" \
        | sed -e "s/\tsignal: //" -e "s/\tSSID: //" \
        | awk '{ORS = (NR % 2 == 0)? "\n" : " "; print}' \
        | sort
    )

    # Print a colorized header for the table
    echo -e "\n${CYAN}Nearby Wi-Fi Networks${NC}"
    echo -e "${WHITE}------------------------------------${NC}"
    printf "%-30s %s\n" "SSID" "SIGNAL (dBm)"
    echo "------------------------------------"

    # Loop through each line of processed data
    while IFS= read -r line; do
        # Each line looks like: "-55 MySSID"
        # Where the first field is the signal and the rest is the SSID
        signal=$(echo "$line" | awk '{print $1}')
        ssid=$(echo "$line" | cut -d' ' -f2-)

        # Print using aligned columns
        # SSID is left-aligned, signal is right-aligned
        printf "%-30s %s\n" "$ssid" "$signal"
    done <<< "$raw_data"
}

###############################################################################
# MAIN SCRIPT
###############################################################################
echo -e "${GREEN}hi${NC}"
findSurroundingDevicesAndDistance
echo -e "${GREEN}bye${NC}"
