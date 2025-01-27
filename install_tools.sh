#!/bin/bash

# Helper Function to display installed tools
whatdoido() {
    cat <<EOF
[!] The install_security_and_network_tools function installs the following tools, organized by their utilization:
[1] Network Administration Tools: net-tools, tcpdump, traceroute, mtr, iperf3, dnsutils, whois, tshark, arp-scan, ettercap-common, dsniff
[2] Penetration Testing Tools: metasploit-framework, wireshark, nmap, aircrack-ng, john, hashcat, zaproxy, sqlmap, hydra, proxychains, gobuster, dirb, checksec, nikto, wpscan
[3] Red Teaming & Post-Exploitation Tools: responder, bloodhound, impacket-scripts, crackmapexec, seclists, nishang, powersploit, enum4linux, recon-ng
[4] Web Application & Network Forensics Tools: RouterSploit, Xplico, Apache2, Burp Suite, Maltego, Social Engineering Toolkit (SET), BeEF, zaproxy
[5] Vulnerability Scanners & Security Tools: OpenVAS, SpiderFoot, Tor, Ngrok, libglib2.0-dev, bluepy
[6] Network Utility Tools: Netcat
[7] Python Tools: pipx
[+] All tools have been installed successfully. You can now use them for network administration, penetration testing, vulnerability scanning, OSINT, and more.
EOF
}

# Function to update the OS, apt, and install Python/Java
update_os_and_fetch_versions() {
    echo "[+] Updating the OS and package repositories..."
    sudo apt update -y && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y && sudo apt clean
    echo "[+] Installing Python..."
    sudo apt install -y python3 python3-pip python3-dev && python3 -m pip install --upgrade pip
    echo "[+] Installing Java..."
    sudo apt install -y openjdk-17-jdk && sudo update-alternatives --config java
    java -version
    echo "[+] System updated with the latest Python and Java versions."
}


OSINTII_TOOLS() {
    repos=(
      "https://github.com/techgaun/github-dorks.git"
      "https://github.com/soxoj/maigret.git"
      "https://github.com/megadose/holehe.git"
      "https://github.com/p1ngul1n0/blackbird.git"
      "https://github.com/0xfff0800/Brute-force-Instagram-2025"
      "https://github.com/Datalux/Osintgram.git"
      "https://github.com/megadose/nqntnqnqmb.git"
    )
    
    # Log file for tracking the process
    LOG_FILE="clone_install.log"
    > "$LOG_FILE"
    
    # Function to clone and install a repository
    clone_and_install() {
      local repo_url=$1
      local repo_name=$(basename "$repo_url" .git)
    
      echo "Processing: $repo_name" | tee -a "$LOG_FILE"
    
      # Clone the repository
      if git clone "$repo_url" "$repo_name"; then
        echo "Cloned $repo_name successfully." | tee -a "$LOG_FILE"
        cd "$repo_name" || exit
    
        # Install dependencies if possible
        if [ -f "requirements.txt" ]; then
          echo "Installing dependencies from requirements.txt..." | tee -a "../$LOG_FILE"
          if ! pip install -r requirements.txt; then
            echo "Failed to install dependencies for $repo_name." | tee -a "../$LOG_FILE"
          fi
        elif [ -f "setup.py" ]; then
          echo "Installing via setup.py..." | tee -a "../$LOG_FILE"
          if ! python setup.py install; then
            echo "Failed to install $repo_name via setup.py." | tee -a "../$LOG_FILE"
          fi
        else
          echo "No installation file found for $repo_name." | tee -a "../$LOG_FILE"
        fi
    
        # Go back to the parent directory
        cd ..
      else
        echo "Failed to clone $repo_name." | tee -a "$LOG_FILE"
      fi
    
      echo "----------------------------------------" | tee -a "$LOG_FILE"
    }
    
    # Iterate over each repository
    for repo in "${repos[@]}"; do
      clone_and_install "$repo"
    done
    
    echo "All repositories processed. Check $LOG_FILE for details."

}



# Function to clone and install the specified applications
install_dork_tools() {
  echo "Starting installation of dork tools..."

  # Define repositories in an associative array
  declare -A repositories=(
    ["Fast-Google-Dorks-Scan"]="https://github.com/IvanGlinkin/Fast-Google-Dorks-Scan"
    ["PyDork"]="https://github.com/blacknon/pydork"
    ["0xDork"]="https://github.com/rlyonheart/0xdork"
    ["SDorker"]="https://github.com/TheSpeedX/SDorker"
    ["ASHOK"]="https://github.com/ankitdobhal/Ashok"
    ["Pagodo"]="https://github.com/opsdisk/pagodo"
    ["Katana"]="https://github.com/TebbaaX/Katana"
    ["GO-Dork"]="https://github.com/dwisiswant0/go-dork"
    ["Snitch"]="https://github.com/Smaash/snitch"
    ["Dorks-Eye"]="https://github.com/BullsEye0/dorks-eye"
    ["SQLI-Dorks-Generator"]="https://github.com/Zold1/sqli-dorks-generator"
    ["DSH"]="https://github.com/falkensmz/dsh"
    ["Dork-Hunter"]="https://github.com/six2dez/dorks_hunter"
  )

  # Iterate through repositories and process each
  for tool in "${!repositories[@]}"; do
    echo "Cloning $tool from ${repositories[$tool]}..."
    git clone "${repositories[$tool]}"

    # Move into the cloned directory and install if necessary
    dir_name=$(basename "${repositories[$tool]}" .git)
    if [ -d "$dir_name" ]; then
      cd "$dir_name"

      # Run installation steps if a setup file exists
      if [ -f "requirements.txt" ]; then
        echo "Installing dependencies for $tool..."
        pip install -r requirements.txt
      fi
      if [ -f "setup.py" ]; then
        echo "Running setup.py for $tool..."
        python setup.py install
      fi

      # Return to the parent directory
      cd ..
    else
      echo "Error: Failed to find directory $dir_name after cloning."
    fi
  done

  echo "All tools have been processed."
}


install_osint_tools() {
  declare -A tools=(
    ["https://github.com/iojw/socialscan"]="socialscan"
    ["https://github.com/torerobo/maigret"]="maigret"
    ["https://github.com/megadose/holehe"]="holehe"
    ["https://github.com/p1ngul1n0/blackbird"]="blackbird"
    ["https://github.com/sherlock-project/sherlock"]="sherlock"
    ["https://github.com/martinvigo/email2phonenumber"]="email2phonenumber"
  )

  # Directory to store the cloned tools
  TOOL_DIR="$HOME/osint-tools"

  echo "Creating OSINT tools directory at $TOOL_DIR..."
  mkdir -p "$TOOL_DIR"

  for repo in "${!tools[@]}"; do
    tool_name="${tools[$repo]}"
    tool_path="$TOOL_DIR/$tool_name"

    echo "Cloning $repo..."
    if [ -d "$tool_path" ]; then
      echo "$tool_name is already cloned. Skipping..."
    else
      git clone "$repo" "$tool_path"
    fi

    echo "Installing dependencies for $tool_name..."
    if [ -f "$tool_path/requirements.txt" ]; then
      python3 -m pip install -r "$tool_path/requirements.txt"
    fi

    # Add alias to ~/.bashrc
    echo "Adding alias for $tool_name to ~/.bashrc..."
    if ! grep -q "alias $tool_name=" "$HOME/.bashrc"; then
      echo "alias $tool_name='python3 $tool_path/${tool_name}.py'" >> "$HOME/.bashrc"
    else
      echo "Alias for $tool_name already exists in ~/.bashrc. Skipping..."
    fi
  done

  echo "Reloading ~/.bashrc..."
  source "$HOME/.bashrc"

  echo "All tools installed and configured!"
}

# Install common dependencies and tools
install_security_and_network_tools() {
    echo "[+] Installing essential tools for network administration and security..."
    local tools=(
        net-tools tcpdump traceroute mtr iperf3 dnsutils whois tshark arp-scan ettercap-common dsniff
        metasploit-framework wireshark nmap aircrack-ng john hashcat zaproxy sqlmap hydra proxychains
        gobuster dirb checksec nikto wpscan macchanger responder bloodhound impacket-scripts
        crackmapexec seclists nishang powersploit enum4linux recon-ng tor xplico apache2 openvas
        netcat
    )
    sudo apt update -y
    sudo apt install -y "${tools[@]}"
    echo "[+] Core tools installed."
}

# Install specific tools from GitHub
install_github_tools() {
    local repos=(
        "https://github.com/airgeddon/airgeddon.git"
        "https://github.com/FortyNorthSecurity/EyeWitness.git"
        "https://github.com/threat9/routersploit.git"
        "https://github.com/smicallef/spiderfoot.git"
        "https://github.com/trustedsec/social-engineer-toolkit.git"
        "https://github.com/beefproject/beef.git"
    )
    local tool_dir="$HOME/tools"

    echo "[+] Creating tools directory at $tool_dir..."
    mkdir -p "$tool_dir"
    cd "$tool_dir" || return

    for repo in "${repos[@]}"; do
        local name=$(basename "$repo" .git)
        echo "[+] Cloning $name from $repo..."
        if [ ! -d "$name" ]; then
            git clone "$repo"
        else
            echo "[!] $name is already cloned. Skipping..."
        fi

        cd "$name" || continue
        if [ -f "requirements.txt" ]; then
            echo "[+] Installing dependencies for $name..."
            python3 -m pip install -r requirements.txt
        fi
        cd ..
    done
    echo "[+] GitHub tools cloned and dependencies installed."
}

# Final installation wrapper
install_tools() {
    echo "[+] Starting tool installation..."
    install_osint_tools
    update_os_and_fetch_versions
    install_security_and_network_tools
    install_github_tools
    OSINTII_TOOLS
    install_dork_tools

    echo "[+] All tools have been successfully installed. Happy hacking!"
}

# Add commands to your shell profile for ease of use
alias install_tools="install_tools"
alias whatdoido="whatdoido"

# Ensure ~/.bashrc changes are loaded
echo "[+] Aliases added. Run 'source ~/.bashrc' or restart your terminal to apply changes."
