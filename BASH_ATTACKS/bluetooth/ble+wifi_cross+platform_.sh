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
# FUNCTION: Secure Temp File Creation
###############################################################################
create_tempfile() {
    mktemp 2>/dev/null || mktemp -t 'wifidiag'
}

###############################################################################
# FUNCTION: Robust Spinner Animation
###############################################################################
spinner() {
    local pid=$1
    local delay=0.1
    local spin='-\|/'
    local i=0

    trap "kill $pid 2>/dev/null; exit 1" SIGINT SIGTERM

    while ps -p "$pid" &>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${CYAN}Processing... ${spin:$i:1} ${NC}"
        sleep "$delay"
    done
    printf "\r${GREEN}✔ Done!${NC}\n"
}

###############################################################################
# FUNCTION: gather_wdutil_info (Fixed output capture + CSV)
###############################################################################
gather_wdutil_info() {
    if ! command -v wdutil &>/dev/null; then
        echo -e "${MAGENTA}${BOLD}⚠️  Error: 'wdutil' not found. Skipping wdutil logs.${NC}"
        return 1
    fi

    local datetime
    datetime="$(date +%F_%H-%M-%S)"

    # Capture wdutil log
    echo -e "${CYAN}${BOLD}\n🔍 Gathering 'wdutil log' output...${NC}"
    local log_file
    log_file=$(create_tempfile)
    wdutil log 2>&1 > "$log_file" &
    spinner $!
    local log_data
    log_data=$(<"$log_file")
    rm -f "$log_file"

    # Capture wdutil info
    echo -e "${CYAN}${BOLD}\n🔍 Gathering 'wdutil info' output...${NC}"
    local info_file
    info_file=$(create_tempfile)
    wdutil info 2>&1 > "$info_file" &
    spinner $!
    local info_data
    info_data=$(<"$info_file")
    rm -f "$info_file"

    # Display Results
    echo -e "${WHITE}\n📜 === WDUTIL LOG ===${NC}"
    echo "$log_data"
    echo -e "${WHITE}\n📜 === WDUTIL INFO ===${NC}"
    echo "$info_data"

    # Save to TXT
    local log_txt_file="wdutil_log_${datetime}.txt"
    local info_txt_file="wdutil_info_${datetime}.txt"
    echo "$log_data"  > "$log_txt_file"
    echo "$info_data" > "$info_txt_file"

    # Save to CSV with proper escaping
    local log_csv_file="wdutil_log_${datetime}.csv"
    local info_csv_file="wdutil_info_${datetime}.csv"
    echo '"Log Data"' > "$log_csv_file"
    echo "$log_data" | awk '{gsub(/"/, "\"\""); print "\""$0"\""}' >> "$log_csv_file"
    echo '"Info Data"' > "$info_csv_file"
    echo "$info_data" | awk '{gsub(/"/, "\"\""); print "\""$0"\""}' >> "$info_csv_file"

    echo -e "${GREEN}\n✅ Logs saved to: ${BOLD}${log_txt_file} | ${log_csv_file}${NC}"
    echo -e "${GREEN}✅ Info saved to: ${BOLD}${info_txt_file} | ${info_csv_file}${NC}"
}

###############################################################################
# FUNCTION: Linux Wi-Fi Scan (Improved parsing + validation)
###############################################################################
findSurroundingDevicesAndDistance() {
    local interface="$1"

    # Validate interface
    if ! ip link show "$interface" &>/dev/null; then
        echo -e "${MAGENTA}${BOLD}⚠️  Invalid interface: ${interface}${NC}" >&2
        return 1
    fi

    # Sudo validation
    echo -e "${CYAN}${BOLD}📡 Scanning Wi-Fi networks...${NC}"
    if ! sudo -n true 2>/dev/null; then
        echo -e "${MAGENTA}${BOLD}🔒 This operation requires sudo privileges:${NC}"
        if ! sudo true; then
            echo -e "${MAGENTA}${BOLD}✖️  Authentication failed${NC}" >&2
            return 1
        fi
    fi

    # Scan with timeout
    local scan_data
    scan_data=$(sudo timeout 10s iw dev "$interface" scan 2>/dev/null | awk '
        BEGIN {FS=":"; OFS=","; ssid=""; signal=""}
        /SSID:/ {ssid=substr($0, 7); gsub(/^[ \t]+|[ \t]+$/, "", ssid)}
        /signal:/ {signal=$2; gsub(/ dBm$/, "", signal); print ssid, signal}
    ' | sort -t',' -k2n)

    if [ -z "$scan_data" ]; then
        echo -e "${MAGENTA}${BOLD}⚠️  No networks found${NC}" >&2
        return 1
    fi

    # Display table
    echo -e "\n${CYAN}${BOLD}🌍 Nearby Wi-Fi Networks (Linux)${NC}"
    echo -e "${WHITE}------------------------------------${NC}"
    printf "%-30s %s\n" "SSID" "SIGNAL (dBm)"
    echo "------------------------------------"
    echo "$scan_data" | awk -F',' '{printf "%-30s %s\n", $1, $2}'
    echo -e "${GREEN}\n✅ Scan complete!${NC}"
}

###############################################################################
# FUNCTION: macOS Wi-Fi Scan (Timeout + better parsing)
###############################################################################
findSurroundingWiFi_macOS() {
    echo -e "${CYAN}${BOLD}📡 Scanning Wi-Fi networks on macOS...${NC}"

    # Scan with timeout
    local scan_data
    scan_data=$(timeout 10s system_profiler SPAirPortDataType -xml 2>/dev/null | plutil -extract '0._items' json -o - - | jq -r '.[].spairport_network_info[] | [.spairport_network_ssid, .spairport_network_rssi] | @csv' 2>/dev/null)

    if [ -z "$scan_data" ]; then
        echo -e "${MAGENTA}${BOLD}⚠️  Scan failed or no networks found${NC}" >&2
        return 1
    fi

    # Display table
    echo -e "\n${CYAN}${BOLD}🌍 Nearby Wi-Fi Networks (macOS)${NC}"
    echo -e "${WHITE}------------------------------------${NC}"
    printf "%-30s %s\n" "SSID" "SIGNAL (dBm)"
    echo "------------------------------------"
    echo "$scan_data" | awk -F',' '{gsub(/"/, ""); printf "%-30s %s\n", $1, $2}'
    echo -e "${GREEN}\n✅ Scan complete!${NC}"
}

###############################################################################
# MAIN FUNCTION
###############################################################################
main() {
    trap "echo -e '\n${MAGENTA}${BOLD}🛑 Script interrupted${NC}'; exit 1" SIGINT SIGTERM

    echo -e "${GREEN}${BOLD}👋 Welcome! Let's get started.${NC}"
    case "$(uname)" in
        Darwin)
            echo -e "${CYAN}${BOLD}🖥️  Detected macOS...${NC}"
            gather_wdutil_info
            findSurroundingWiFi_macOS
            ;;
        Linux)
            echo -e "${CYAN}${BOLD}🐧 Detected Linux...${NC}"
            read -rp "💻 Enter wireless interface (e.g., wlan0): " user_interface
            findSurroundingDevicesAndDistance "${user_interface:-wlan0}"
            ;;
        *)
            echo -e "${MAGENTA}${BOLD}❌ Unsupported OS${NC}" >&2
            exit 1
            ;;
    esac

    echo -e "${GREEN}${BOLD}🎉 All tasks completed successfully!${NC}"
}

main