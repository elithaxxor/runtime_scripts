#!/usr/bin/env bash

###############################################################################
# CONSTANTS & CONFIGURATION
###############################################################################
# Colors using individual variables instead of associative array
COLORS_CYAN='\033[1;36m'
COLORS_GREEN='\033[0;32m'
COLORS_WHITE='\033[1;37m'
COLORS_MAGENTA='\033[1;35m'
COLORS_BOLD='\033[1m'
COLORS_NC='\033[0m'

# Dependencies as indexed arrays
LINUX_DEPS="iw timeout"
MACOS_DEPS="system_profiler plutil jq"

# OS information
CURRENT_OS=$(uname -s)
OS_NAME="Unknown"
case "$CURRENT_OS" in
    Darwin) OS_NAME="macOS" ;;
    Linux) OS_NAME="Linux" ;;
esac

TEMP_PREFIX="wifidiag"
CSV_HEADER="SSID,SIGNAL(dBm)"

###############################################################################
# FUNCTIONS: OUTPUT FORMATTING
###############################################################################
color_echo() {
    local color_var="$1"
    local msg="$2"
    local color=${!color_var}
    echo -e "${color}${msg}${COLORS_NC}"
}

bold_echo() {
    local color_var="$1"
    local msg="$2"
    echo -e "${COLORS_BOLD}${!color_var}${msg}${COLORS_NC}"
}

###############################################################################
# FUNCTIONS: UTILITIES
###############################################################################
create_tempfile() {
    mktemp 2>/dev/null || mktemp -t "$TEMP_PREFIX"
}

cleanup() {
    rm -f "${TMP_FILES[@]}" 2>/dev/null
}

spinner() {
    local pid=$1
    local delay=0.1
    local spin='-\|/'
    local i=0

    trap "kill $pid 2>/dev/null; exit 1" SIGINT SIGTERM

    while ps -p "$pid" &>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${COLORS_CYAN}Processing... ${spin:$i:1} ${COLORS_NC}"
        sleep "$delay"
    done
    printf "\r${COLORS_GREEN}✔ Done!${COLORS_NC}\n"
}

###############################################################################
# FUNCTIONS: CORE OPERATIONS
###############################################################################
check_dependencies() {
    local missing=()
    local deps

    case "$CURRENT_OS" in
        Linux) deps=($LINUX_DEPS) ;;
        Darwin) deps=($MACOS_DEPS) ;;
        *) return 1 ;;
    esac

    for cmd in "${deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        bold_echo "COLORS_MAGENTA" "Missing dependencies: ${missing[*]}"
        return 1
    fi
}

get_wdutil_data() {
    local type=$1
    local file=$(create_tempfile)
    TMP_FILES+=("$file")
    
    wdutil "$type" 2>&1 > "$file" &
    spinner $!
    <"$file" awk '{gsub(/"/, "\"\""); print "\""$0"\""}'
}

handle_wdutil() {
    if ! command -v wdutil &>/dev/null; then
        bold_echo "COLORS_MAGENTA" "⚠️  'wdutil' not found. Skipping logs."
        return 1
    fi

    local datetime=$(date +%F_%H-%M-%S)
    local outputs=("log" "info")

    for type in "${outputs[@]}"; do
        bold_echo "COLORS_CYAN" "\n🔍 Gathering 'wdutil $type' output..."
        data=$(get_wdutil_data "$type")
        
        # Terminal output - FIXED LINE 121
        color_echo "COLORS_WHITE" "\n📜 === WDUTIL $(echo "$type" | tr '[:lower:]' '[:upper:]') ==="
        echo "$data"
        
        # File saving
        save_outputs "$type" "$datetime" "$data"
    done
}

save_outputs() {
    local type=$1
    local datetime=$2
    local data=$3

    # Capitalize first letter for Bash 3 compatibility
    local capitalized_type=$(echo "$type" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')

    # Text file
    echo "$data" > "${type}_${datetime}.txt"

    # CSV file
    {
        echo "\"${capitalized_type} Data\""
        echo "$data"
    } > "${type}_${datetime}.csv"

    bold_echo "COLORS_GREEN" "✅ ${capitalized_type} saved to: ${type}_${datetime}.txt | ${type}_${datetime}.csv"
}

scan_network() {
    local interface=${1:-}

    bold_echo "COLORS_CYAN" "\n📡 Scanning Wi-Fi networks..."
    
    if [[ "$CURRENT_OS" == "Linux" ]]; then
        validate_linux_interface "$interface" || return 1
        sudo -v || { bold_echo "COLORS_MAGENTA" "✖️  Authentication failed"; return 1; }
    fi

    local scan_data
    scan_data=$(scan_command "$interface") || return 1

    display_results "$scan_data"
}

validate_linux_interface() {
    local interface=$1
    ip link show "$interface" &>/dev/null || {
        bold_echo "COLORS_MAGENTA" "⚠️  Invalid interface: $interface"
        return 1
    }
}

scan_command() {
    case "$CURRENT_OS" in
        Linux)
            local interface=$1
            sudo timeout 10s iw dev "$interface" scan 2>/dev/null | awk '
                BEGIN {FS=":"; OFS=","; ssid=""; signal=""}
                /SSID:/ {ssid=substr($0, 7); gsub(/^[ \t]+|[ \t]+$/, "", ssid)}
                /signal:/ {signal=$2; gsub(/ dBm$/, "", signal); print ssid, signal}
            ' | sort -t',' -k2n
            ;;
        Darwin)
            timeout 10s system_profiler SPAirPortDataType -xml 2>/dev/null | \
            plutil -extract '0._items' json -o - - | \
            jq -r '.[].spairport_network_info[] | [.spairport_network_ssid, .spairport_network_rssi] | @csv' 2>/dev/null
            ;;
    esac
}

display_results() {
    local data=$1

    [[ -z "$data" ]] && {
        bold_echo "COLORS_MAGENTA" "⚠️  No networks found"
        return 1
    }

    bold_echo "COLORS_CYAN" "\n🌍 Nearby Wi-Fi Networks ($OS_NAME)"
    echo -e "${COLORS_WHITE}------------------------------------"
    printf "%-30s %s\n" "SSID" "SIGNAL (dBm)"
    echo "------------------------------------"
    awk -F',' '{gsub(/"/, ""); printf "%-30s %s\n", $1, $2}' <<< "$data"
    bold_echo "COLORS_GREEN" "\n✅ Scan complete!"
}

###############################################################################
# MAIN EXECUTION
###############################################################################
main() {
    trap "cleanup; echo -e '\n${COLORS_MAGENTA}🛑 Script interrupted${COLORS_NC}'; exit 1" SIGINT SIGTERM
    trap "cleanup" EXIT

    check_dependencies || exit 1

    bold_echo "COLORS_GREEN" "👋 Welcome! Detected ${OS_NAME}..."

    handle_wdutil

    if [[ "$CURRENT_OS" == "Linux" ]]; then
        read -rp "💻 Enter wireless interface [wlan0]: " interface
        interface=${interface:-wlan0}
        while true; do
            scan_network "$interface"
            sleep 20
        done
    else
        while true; do
            scan_network
            sleep 20
        done
    fi
}

main "$@"