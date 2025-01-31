#!/bin/bash

###############################################################################
# COLOR DEFINITIONS
###############################################################################
CYAN='\033[1;36m'
GREEN='\033[0;32m'
WHITE='\033[1;37m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

###############################################################################
# FUNCTION: Fancy Spinner Animation
# Used while running commands for better UI feedback
###############################################################################
spinner() {
    local pid=$!
    local delay=0.1
    local spin='-\|/'

    while ps -p $pid &>/dev/null; do
        local i=$(( (i+1) %4 ))
        printf "\r${CYAN}Processing... ${spin:$i:1} ${NC}"
        sleep "$delay"
    done
    printf "\r${GREEN}✔ Done!${NC}\n"
}

###############################################################################
# FUNCTION: gather_wdutil_info
# Runs "wdutil log" and "wdutil info", prints them to terminal, and saves
# them in both .txt and .csv files.
###############################################################################
gather_wdutil_info() {
    if ! command -v wdutil &>/dev/null; then
        echo -e "${MAGENTA}${BOLD}⚠️  Error: 'wdutil' not found. Skipping wdutil logs.${NC}"
        return 1
    fi

    local datetime
    datetime="$(date +%F_%H-%M-%S)"

    echo -e "${CYAN}${BOLD}\n🔍 Gathering 'wdutil log' output...${NC}"
    local log_data
    wdutil log 2>&1 & log_data=$(cat)
    spinner

    echo -e "${CYAN}${BOLD}\n🔍 Gathering 'wdutil info' output...${NC}"
    local info_data
    wdutil info 2>&1 & info_data=$(cat)
    spinner

    # Display Results
    echo -e "${WHITE}\n📜 === WDUTIL LOG ===${NC}"
    echo "$log_data"

    echo -e "${WHITE}\n📜 === WDUTIL INFO ===${NC}"
    echo "$info_data"

    # Save to files
    local log_txt_file="wdutil_log_${datetime}.txt"
    local info_txt_file="wdutil_info_${datetime}.txt"
    echo "$log_data"  > "$log_txt_file"
    echo "$info_data" > "$info_txt_file"

    echo -e "${GREEN}\n✅ Saved wdutil log to: ${BOLD}$log_txt_file${NC}"
    echo -e "${GREEN}✅ Saved wdutil info to: ${BOLD}$info_txt_file${NC}"

    # Save to CSV
    local log_csv_file="wdutil_log_${datetime}.csv"
    local info_csv_file="wdutil_info_${datetime}.csv"
    echo "$log_data"  | tr '\n' ',' | sed 's/,$/\n/' > "$log_csv_file"
    echo "$info_data" | tr '\n' ',' | sed 's/,$/\n/' > "$info_csv_file"

    echo -e "${GREEN}✅ Saved wdutil log (CSV) to: ${BOLD}$log_csv_file${NC}"
    echo -e "${GREEN}✅ Saved wdutil info (CSV) to: ${BOLD}$info_csv_file${NC}"
}

###############################################################################
# FUNCTION: findSurroundingDevicesAndDistance (Linux only)
###############################################################################
findSurroundingDevicesAndDistance() {
    local interface="$1"

    echo -e "${CYAN}${BOLD}📡 Scanning Wi-Fi networks...${NC}"
    sleep 1  # Simulate scanning delay

    # Ensure 'iw' is available
    if ! command -v iw &>/dev/null; then
        echo -e "${MAGENTA}${BOLD}⚠️  Error: 'iw' command not found. Please install it.${NC}"
        return 1
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

    if [ -z "$raw_data" ]; then
        echo -e "${MAGENTA}${BOLD}⚠️  No networks found or invalid interface: ${interface}${NC}"
        return 1
    fi

    # Print Table
    echo -e "\n${CYAN}${BOLD}🌍 Nearby Wi-Fi Networks (Linux)${NC}"
    echo -e "${WHITE}------------------------------------${NC}"
    printf "%-30s %s\n" "SSID" "SIGNAL (dBm)"
    echo "------------------------------------"

    while IFS= read -r line; do
        local signal
        local ssid

        signal=$(echo "$line" | awk '{print $1}')
        ssid=$(echo "$line" | cut -d' ' -f2-)
        printf "%-30s %s\n" "$ssid" "$signal"
    done <<< "$raw_data"

    echo -e "${GREEN}\n✅ Wi-Fi scan complete!${NC}"
}

###############################################################################
# FUNCTION: findSurroundingWiFi_macOS (Uses system_profiler)
###############################################################################
findSurroundingWiFi_macOS() {
    echo -e "${CYAN}${BOLD}📡 Scanning Wi-Fi networks on macOS...${NC}"
    sleep 1  # Simulate scanning delay

    local raw_data
    raw_data=$(system_profiler SPAirPortDataType 2>/dev/null | grep -E " SSID| RSSI")

    if [[ -z "$raw_data" ]]; then
        echo -e "${MAGENTA}${BOLD}⚠️  No networks found or unable to scan on macOS.${NC}"
        return
    fi

    echo -e "\n${CYAN}${BOLD}🌍 Nearby Wi-Fi Networks (macOS)${NC}"
    echo -e "${WHITE}------------------------------------${NC}"
    printf "%-30s %s\n" "SSID" "SIGNAL (dBm)"
    echo "------------------------------------"

    local ssid=""
    local rssi=""

    while IFS= read -r line; do
        line="$(echo "$line" | sed 's/^ *//;s/ *$//')"

        if [[ "$line" == "SSID:"* ]]; then
            ssid="$(echo "$line" | cut -d':' -f2 | sed 's/^ *//')"
        elif [[ "$line" == "RSSI:"* ]]; then
            rssi="$(echo "$line" | cut -d':' -f2 | sed 's/^ *//')"
            printf "%-30s %s\n" "$ssid" "$rssi"
        fi
    done <<< "$raw_data"

    echo -e "${GREEN}\n✅ Wi-Fi scan complete!${NC}"
}

###############################################################################
# MAIN FUNCTION
###############################################################################
main() {
    echo -e "${GREEN}${BOLD}👋 Welcome! Let's get started.${NC}"

    local os_type
    os_type="$(uname)"

    if [[ "$os_type" == "Darwin" ]]; then
        echo -e "${CYAN}${BOLD}🖥️  Detected macOS...${NC}"
        
        gather_wdutil_info
        findSurroundingWiFi_macOS

    else
        echo -e "${CYAN}${BOLD}🐧 Detected Linux...${NC}"
        
        read -rp "💻 Enter the wireless interface (e.g., wlan0): " user_interface
        if [ -z "$user_interface" ]; then
            echo -e "${MAGENTA}${BOLD}⚠️  No interface provided. Exiting...${NC}"
            exit 0
        fi

        findSurroundingDevicesAndDistance "$user_interface"
    fi

    echo -e "${GREEN}${BOLD}🎉 All tasks completed successfully! Exiting now.${NC}"
}

main
