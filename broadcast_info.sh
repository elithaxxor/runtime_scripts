#!/bin/bash

# Function to gather and display system information
function _broadcastInfo() {
    output_file="system_info.txt"

    # Clear the file before starting
    > "$output_file"
    
    # Add a header to the output file
    echo "==================== SYSTEM INFORMATION ====================" > "$output_file"
    echo "Generated on: $(date)" >> "$output_file"
    echo "------------------------------------------------------------" >> "$output_file"
    
    # Displaying and storing broadcast information
    echo -e "\n[*] Getting Broadcast Information..."
    _broadcast=$(ifconfig | grep broadcast)
    echo -e "Broadcast Info:\n$_broadcast"
    echo -e "\n[*] Broadcast Info:\n$_broadcast" >> "$output_file"

    # Displaying and storing IP information
    echo -e "\n[*] Getting IP (inet) Information..."
    _inet=$(ifconfig | grep inet)
    echo -e "IP Info:\n$_inet"
    echo -e "\n[*] IP Info:\n$_inet" >> "$output_file"

    # Displaying and storing MAC address information
    echo -e "\n[*] Getting MAC Address Information..."
    _mac=$(ifconfig | grep ether)
    echo -e "MAC Info:\n$_mac"
    echo -e "\n[*] MAC Info:\n$_mac" >> "$output_file"

    # Displaying and storing radio interface name
    echo -e "\n[*] Getting Radio Interface Name..."
    _radio_name=$(iw dev | awk '$1=="Interface"{print $2}')
    echo -e "Radio Interface: $_radio_name"
    echo -e "\n[*] Radio Interface:\n$_radio_name" >> "$output_file"

    # Displaying and storing USB devices
    echo -e "\n[*] Getting USB Devices..."
    _usb=$(lsusb)
    echo -e "USB Info:\n$_usb"
    echo -e "\n[*] USB Info:\n$_usb" >> "$output_file"

    # Displaying system files
    echo -e "\n[*] Listing .txt Files in Current Directory..."
    _DIRS=$(ls *.txt)
    echo -e "Text Files:\n$_DIRS"
    echo -e "\n[*] Text Files:\n$_DIRS" >> "$output_file"

    # Displaying device power metrics
    echo -e "\n[*] Getting Device Power Metrics..."
    _devInfo01=$(powermetrics)
    echo -e "Device Power Info:\n$_devInfo01"
    echo -e "\n[*] Device Power Info:\n$_devInfo01" >> "$output_file"

    # Displaying Infix command output (assuming 'Infix' is a valid command, otherwise this may need adjustment)
    echo -e "\n[*] Running Infix Command..."
    _devInfo02=$(Infix -Fxz)
    echo -e "Infix Info:\n$_devInfo02"
    echo -e "\n[*] Infix Info:\n$_devInfo02" >> "$output_file"

    # Displaying SSH logs
    echo -e "\n[*] Getting SSH Logs from Syslog..."
    _sshLogs=$(cat /var/log/syslog | grep ssh)
    echo -e "SSH Logs:\n$_sshLogs"
    echo -e "\n[*] SSH Logs:\n$_sshLogs" >> "$output_file"

    # Displaying user information (entries separated by commas)
    echo -e "\n[*] Getting User List from /etc/passwd..."
    _user_list=$(awk -F: '{ print $1}' /etc/passwd | tr '\n' ', ' | sed 's/, $//')
    echo -e "User List: $_user_list"
    echo -e "\n[*] User List: $_user_list" >> "$output_file"

    # Displaying /etc/passwd contents (entries separated by commas)
    echo -e "\n[*] Getting /etc/passwd Entries..."
    _passwd_entries=$(cat /etc/passwd | cut -d: -f1 | tr '\n' ', ' | sed 's/, $//')
    echo -e "/etc/passwd Entries: $_passwd_entries"
    echo -e "\n[*] /etc/passwd Entries: $_passwd_entries" >> "$output_file"

    # Displaying database user passwords (this might expose sensitive info, use with caution)
    echo -e "\n[*] Getting Database User Information..."
    _getDB_pass=$(getent passwd | awk -F: '{ print $1}')
    echo -e "Database User Info:\n$_getDB_pass"
    echo -e "\n[*] Database User Info:\n$_getDB_pass" >> "$output_file"

    # Inform user that the output has been saved
    echo -e "\nSystem information has been saved to '$output_file'."
}

# Calling the function to execute
_broadcastInfo
