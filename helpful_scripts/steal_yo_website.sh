#!/bin/bash

# Function to get IP from DNS
getIPfromDNS() {
    echo "Getting IP addresses and DNS info for $website..."
    # Use netcat, host, dig, and dnsrecon to get IP and DNS info
    netcat $website
    host $website
    dig $website
    dnsrecon -d $website
}

# Function to steal the website's content using various tools
stealDarrensSite() {
    echo "Downloading content from $website using various tools..."

    # Using curl to download the website
    mkdir /home/CURLED_WEBSITE && cd /home/CURLED_WEBSITE
    curl -o $(basename $website) $website
    
    # Using wget to download the website
    mkdir /home/WGET_WEBSITE && cd /home/WGET_WEBSITE
    wget $website
    
    # Using httrack to download the website
    mkdir /home/HTTPRACK_WEBSITE && cd /home/HTTPRACK_WEBSITE
    httrack $website -O $(basename $website)
}

read -p "Enter the website URL (e.g., https://darren.kitchen/): " website
# Validate user input (ensure it's not empty and starts with http/https)
if [[ -z "$website" ]] || ! [[ "$website" =~ ^https?:// ]]; then
    echo "Invalid input. Please enter a valid website URL starting with http:// or https://"
    exit 1
fi

# Call the functions with the provided website
getIPfromDNS
stealDarrensSite
