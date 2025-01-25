#!/bin/bash

# Update package repositories
sudo apt update

# Install tools
sudo apt install -y metasploit-framework
sudo apt install -y wireshark
sudo apt install -y nmap
sudo apt install -y aircrack-ng
sudo apt install -y john
sudo apt install -y hashcat

# Burp Suite installation (Download from official website)
# Note: The URL might change, so check the Burp Suite website for the latest version.
wget -O burp-suite.sh https://portswigger.net/burp/releases/download?product=community&version=2022.2.4&type=Linux
chmod +x burp-suite.sh
./burp-suite.sh

sudo apt install -y aircrack-ng
sudo apt install -y john
sudo apt install -y hashcat
sudo apt install -y zaproxy
sudo apt install -y sqlmap
sudo apt install -y hydra
sudo apt install -y proxychains
sudo apt install -y gobuster
sudo apt install -y dirb

# Maltego installation (Download from official website)
# Note: The URL might change, so check the Maltego website for the latest version.
wget -O maltego.tgz https://www.paterva.com/malv4/community/Maltego.v4.2.17.14253.Linux.deb
tar -xvf maltego.tgz
sudo dpkg -i Maltego.v4.2.17.14253.Linux.deb

# Social Engineering Toolkit (SET) installation
git clone https://github.com/trustedsec/social-engineer-toolkit.git
cd social-engineer-toolkit
sudo python setup.py install

# BeEF (Browser Exploitation Framework) installation
git clone https://github.com/beefproject/beef.git
cd beef
./install

# Checksec installation
sudo apt install -y checksec

echo "Installation complete!"
