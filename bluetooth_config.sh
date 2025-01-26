# Define the function
setup_bluetooth_tools() {
    echo "[!] Displaying Bluetooth configuration..."
    hciconfig

    echo "[!] Bringing up hci0 interface..."
    hciconfig hci0 up

    echo "[!] Displaying updated Bluetooth configuration..."
    hciconfig

    echo "[!] Setting hci0 class to 0x50024..."
    hciconfig hci0 class 0x50024

    echo "[!] Verifying hci0 class..."
    hciconfig hci0 class

    echo "[+] Scanning for nearby Bluetooth devices..."
    hcitool scan
}

echo "[!].. This turns your bluetooth card into a psuedo monitor mode; and sets the hci class to '0x50024' to mimic a cell phone rather than cpu"
setup_bluetooth_tools
