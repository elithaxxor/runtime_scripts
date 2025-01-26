#!/bin/bash

whatdoido(){
    echo "[!] [!] The install_security_and_network_tools function installs the following tools, organized by their utilization:"
    echo "[1] Network Administration Tools: net-tools, tcpdump, traceroute, mtr, iperf3, dnsutils, whois, tshark, arp-scan, ettercap-common, dsniff"
    echo "[2] Penetration Testing Tools: metasploit-framework, wireshark, nmap, aircrack-ng, john, hashcat, zaproxy (ZAP Proxy), sqlmap, hydra, proxychains, gobuster, dirb, checksec, nikto, wpscan"
    echo "[3] Red Teaming & Post-Exploitation Tools: responder, bloodhound, impacket-scripts, crackmapexec, seclists, nishang, powersploit, enum4linux, recon-ng"
    echo "[4] Web Application & Network Forensics Tools: RouterSploit, Xplico, Apache2, Burp Suite, Maltego, Social Engineering Toolkit (SET), BeEF, zaproxy (ZAP Proxy)"
    echo "[5] Vulnerability Scanners & Security Tools: OpenVAS, SpiderFoot, Tor, Ngrok, libglib2.0-dev, bluepy"
    echo "[6] Network Utility Tools: Netcat"
    echo "[7] Python Tools: pipx"
    echo "[+] All tools have been installed successfully. You can now use them for network administration, penetration testing, vulnerability scanning, red teaming, OSINT, and more."
}



# Function to update the OS, apt, and fetch the latest version of Python and Java
update_os_and_fetch_versions() {
    echo "[+] Updating the OS and package repositories..."
    sudo apt update
    
    sudo apt upgrade -y
    sudo apt dist-upgrade -y
    sudo apt autoremove -y
    sudo apt clean
    echo "Updating Python..."
    
    # Fetch and install the latest Python version
    sudo apt install -y python3 python3-pip
    python3 -m pip install --upgrade pip
    
    # Install the latest Python version if needed (Python 3.x)
    sudo apt install -y python3-dev

    python3 --version
    pip --version
    echo "[!] Updating Java..."
    
    # Fetch and install the latest Java version (OpenJDK)
    sudo apt install -y openjdk-17-jdk  # Install OpenJDK 17 (or the latest version available in apt)
    sudo update-alternatives --config java
    java -version

    echo "[+] OS and package repositories have been updated. The latest versions of Python and Java are now installed."
}


install_tools() {
    echo "[!] Updating package repositories..."
    sudo apt update -y

    # Install common dependencies for all tools
    echo "[!] Installing common dependencies for all tools..."
    sudo apt install -y git build-essential python3-pip python3-dev libssl-dev libffi-dev


    # Category: Brute Force Tool
    echo -e "\n### Installing Brute Force Tool: Ncrack ###"
    echo "[+] Ncrack is a network authentication cracking tool used to perform brute-force attacks on various network services."
    echo "Installing Ncrack..."
    sudo apt install -y ncrack

    # Category: WiFi Cracking Tool
    echo -e "\n### Installing WiFi Cracking Tool: Airgeddon ###"
    echo "[-] Airgeddon is a multi-use bash script for Wi-Fi penetration testing, particularly focused on cracking WEP/WPA2 encryption."
    echo "[!] Cloning Airgeddon repository from GitHub..."
    git clone https://github.com/airgeddon/airgeddon.git
    cd airgeddon
    echo "Airgeddon cloned. Now you can run it from this directory: ./airgeddon.sh"
    cd ..

    # Category: OSINT Tool for Web Enumeration
    echo -e "\n### Installing OSINT Tool for Web Enumeration: Eyewitness ###"
    echo "Eyewitness is a tool used for taking screenshots and gathering information about web servers (HTTP/HTTPS). It’s typically used for web enumeration in pentesting."
    echo "[!] Cloning Eyewitness repository from GitHub..."
    git clone https://github.com/FortyNorthSecurity/EyeWitness.git
    cd EyeWitness
    echo "[!] Installing Eyewitness dependencies..."
    sudo pip3 install -r requirements.txt
    echo "[+] Eyewitness installation complete."
    cd ..

        echo "Updating package repositories..."
    sudo apt update -y

    # Install dependencies
    echo "Installing dependencies..."
    sudo apt install -y git curl python3-pip python3-dev build-essential
    echo "Cloning Lazy Script repository from GitHub..."
    git clone https://github.com/psypanda/lazyscript.git
    cd lazyscript
    echo "Installing Lazy Script..."
    chmod +x lazyscript.py
    sudo python3 lazyscript.py

    echo "Updating package repositories..."
    sudo apt update -y

    # Install required dependencies
    echo "Installing dependencies..."
    sudo apt install -y git curl python3-pip python3-dev build-essential

    # Clone the Sn1per repository from GitHub
    echo "Cloning Sn1per Framework repository from GitHub..."
    git clone https://github.com/1N3/Sn1per.git

    # Navigate to the Sn1per directory
    cd Sn1per

    echo "Running installation script for Sn1per..."
    chmod +x install.sh
    sudo ./install.sh
    echo "Sn1per installation complete!"
    echo "You can now run Sn1per with the following command: sudo sn1per"

    
    # Finishing up
    echo "Lazy Script installation complete!"
    echo "You can run Lazy Script by navigating to the directory and running: python3 lazyscript.py"
    
    echo -e "\n### All tools have been installed! ###"
    echo "Summary of the tools installed:"
    echo "1. Ncrack - Brute Force Tool for cracking network authentication."
    echo "2. Airgeddon - Wi-Fi penetration testing tool for cracking WEP/WPA2."
    echo "3. Eyewitness - OSINT tool for web enumeration and server screenshots."
    
    echo -e "\n### How to run the tools ###"
    echo "1. Ncrack: ncrack"
    echo "2. Airgeddon: cd airgeddon && ./airgeddon.sh"
    echo "3. Eyewitness: cd EyeWitness && python3 eyewitness.py"
}


# This installs the security tools 
install_security_and_network_tools() {
    echo "[+] This script will install a comprehensive suite of tools for network administration, penetration testing, red teaming, vulnerability scanning, OSINT, and anonymity. The tools include network scanners, exploitation frameworks, web servers, and more."

    # Update package repositories
    echo "[!] Updating package repositories..."
    sudo apt update
    echo "[+] Repos updated" 

    # Install core tools for network administration
    echo "[!] Installing essential network administration tools..."
    sudo apt install -y net-tools          # Network interface configuration tools
    sudo apt install -y tcpdump            # Network packet analyzer
    sudo apt install -y traceroute         # Network diagnostics
    sudo apt install -y mtr                # Network diagnostic tool
    sudo apt install -y iperf3             # Network performance measurement tool
    sudo apt install -y dnsutils           # DNS query tools
    sudo apt install -y whois              # Whois client
    sudo apt install -y tshark             # CLI version of Wireshark
    sudo apt install -y arp-scan           # ARP network scanner
    sudo apt install -y ettercap-common    # Network sniffer/interceptor
    sudo apt install -y dsniff             # Collection of network traffic analysis tools

    # Install penetration testing tools
    echo "Installing penetration testing tools..."
    sudo apt install -y metasploit-framework
    sudo apt install -y wireshark
    sudo apt install -y nmap               # Network scanning tool
    sudo apt install -y aircrack-ng
    sudo apt install -y john
    sudo apt install -y hashcat
    sudo apt install -y zaproxy            # Install ZAP (OWASP Zed Attack Proxy)
    sudo apt install -y sqlmap
    sudo apt install -y hydra
    sudo apt install -y proxychains
    sudo apt install -y gobuster
    sudo apt install -y dirb
    sudo apt install -y checksec
    sudo apt install -y nikto              # Web server vulnerability scanner
    sudo apt install -y wpscan             # WordPress vulnerability scanner

    # Install advanced tools
    echo "Installing advanced tools for red teaming..."
    sudo apt install -y macchanger
    sudo apt install -y responder          # LLMNR, NBT-NS, and MDNS poisoner
    sudo apt install -y bloodhound         # Active Directory mapping tool
    sudo apt install -y impacket-scripts   # SMB/MSRPC utilities
    sudo apt install -y crackmapexec       # Post-exploitation tool for Active Directory
    sudo apt install -y seclists           # Security wordlists for discovery
    sudo apt install -y nishang            # PowerShell offensive toolkit
    sudo apt install -y powersploit        # PowerShell post-exploitation scripts
    sudo apt install -y enum4linux         # SMB enumeration tool
    sudo apt install -y recon-ng           # Web reconnaissance framework

    # Install RouterSploit
    echo "[!] Installing RouterSploit framework..."
    git clone https://github.com/threat9/routersploit.git
    cd routersploit
    python3 -m pip install -r requirements.txt
    cd ..

    # Install Xplico
    echo "[!] Installing Xplico (Network Forensic Analysis Tool)..."
    sudo apt install -y xplico

    # Install Apache2
    echo "[!] Installing Apache2 web server..."
    sudo apt install -y apache2
    sudo systemctl enable apache2
    sudo systemctl start apache2

    # Install OpenVAS (Greenbone Vulnerability Management)
    echo "[!] Installing OpenVAS (Greenbone Vulnerability Management)..."
    sudo apt install -y openvas
    sudo gvm-setup  # Setup OpenVAS
    sudo gvm-check-setup  # Check if OpenVAS is set up properly

    # Install SpiderFoot
    echo "Installing SpiderFoot (OSINT Automation)..."
    git clone https://github.com/smicallef/spiderfoot.git
    cd spiderfoot
    sudo python3 setup.py install
    cd ..

    # Install theHarvestor // toooling 
    sudo apt install -y netcat dnsutils dnsrecon curl wget httrack python3-pip
    echo "[!] Installing The Harvester..."
    sudo apt install -y theharvester
    pip3 install -r https://raw.githubusercontent.com/larose/theHarvester/master/requirements.txt
    echo "[+] Installation complete!"

    echo "[!] Updating package repositories..."
    sudo apt update -y
    echo "[!] Installing dependencies for Kismet..."
    sudo apt install -y build-essential libpcap-dev libusb-1.0-0-dev libpthread-stubs0-dev libsqlite3-dev \
        libncurses5-dev libz-dev libtool pkg-config git cmake

    echo "[!] Cloning the Kismet repository from GitHub..."
    git clone https://github.com/kismetwireless/kismet.git
    echo "[+] Kismet clone done ..."

    echo "[!] Navigating to Kismet directory..."
    cd kismet
    echo "Building Kismet..."
    ./configure
    make
    sudo make install
    echo "[+] Kismet installation complete!"
    echo "[+] To start Kismet, run the command: kismet"

    

    # Install Tor
    echo "[!] Installing Tor..."
    sudo apt install -y tor
    sudo systemctl enable tor
    sudo systemctl start tor

    # Install Ngrok (Tunneling tool)
    echo "[!] Installing Ngrok..."
    wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip
    unzip ngrok-stable-linux-amd64.zip
    sudo mv ngrok /usr/local/bin/

    # Install Burp Suite
    echo "[!] Installing Burp Suite (Community Edition)..."
    wget -O burp-suite.sh https://portswigger.net/burp/releases/download?product=community&version=2022.2.4&type=Linux
    chmod +x burp-suite.sh
    ./burp-suite.sh

    # Install Maltego
    echo "Installing Maltego..."
    wget -O maltego.tgz https://www.paterva.com/malv4/community/Maltego.v4.2.17.14253.Linux.deb
    tar -xvf maltego.tgz
    sudo dpkg -i Maltego.v4.2.17.14253.Linux.deb

    # Install Social Engineering Toolkit (SET)
    echo "Installing Social Engineering Toolkit (SET)..."
    git clone https://github.com/trustedsec/social-engineer-toolkit.git
    cd social-engineer-toolkit
    sudo python setup.py install
    cd ..

    # Install BeEF (Browser Exploitation Framework)
    echo "Installing BeEF (Browser Exploitation Framework)..."
    git clone https://github.com/beefproject/beef.git
    cd beef
    ./install
    cd ..

    # Install libglib2.0-dev
    echo "Installing libglib2.0-dev..."
    sudo apt-get install -y libglib2.0-dev

    # Install bluepy (Python library for Bluetooth LE)
    echo "Installing bluepy..."
    python3 -m pip install bluepy

    # Run rsf.py (RouterSploit Framework Script)
    echo "Running rsf.py..."
    python3 rsf.py

    # Install Netcat (Network Utility Tool)
    echo "Installing Netcat..."
    sudo apt install -y netcat

    # Install pipx (Python package installer)
    echo "Installing pipx..."
    sudo apt install -y python3-pip
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath

    echo "Installation of all tools, including OpenVAS, SpiderFoot, Tor, Ngrok, ZAP, and additional libraries, is complete!"
}

whatdoido
update_os_and_fetch_versions
install_security_and_network_tools
install_tools

