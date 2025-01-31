#!/usr/bin/env bash

# This script clones specific GitHub repositories that may be Python-based or have their own install script.
# If a repository has a Python requirements.txt, the script creates a virtual environment and installs it.
# If a repository contains an install.sh file, we run that script.
# Repositories are cloned into a user-defined output_dir (defaults to "cloned_repos" if not provided).

# ------------------------------------------------------------------------------
# Safety: Removed 'set -e' so the script does not exit on first error.
#         We will handle errors manually and proceed with the next repo.
# ------------------------------------------------------------------------------

# set -e  # <-- Commented out to avoid exiting on any error.

# Helper Function for error handling - only logs, does not exit
log_error() {
    echo "[ERROR]: $1" 1>&2
}

# Helper function to detect if repository likely is Python-based
# We consider it Python-based if it has a requirements.txt or a setup.py in the root.
is_python_repo() {
    local repo_path="$1"
    if [[ -f "$repo_path/requirements.txt" || -f "$repo_path/setup.py" ]]; then
        return 0  # True
    else
        return 1  # False
    fi
}

# Helper function to see if there's an install script
has_install_script() {
    local repo_path="$1"
    if [[ -f "$repo_path/install.sh" || -f "$repo_path/setup.sh" ]]; then
        return 0  # True
    else
        return 1  # False
    fi
}

# Main install function
install_tools() {
    # List of GitHub repositories to clone
    local repos=(
        "https://github.com/aircrack-ng/aircrack-ng.git"
        "https://github.com/FluxionNetwork/fluxion.git"
        "https://github.com/chrisk44/Hijacker.git"
        "https://github.com/entropy1337/infernal-twin.git"
        "https://github.com/kismetwireless/kismet.git"
        "https://github.com/wi-fi-analyzer/mdk3-master.git"
        "https://github.com/aircrack-ng/mdk4.git"
        "https://github.com/Synacktiv-contrib/Modmobjam.git"
        "https://github.com/Synacktiv-contrib/Modmobmap.git"
        "https://github.com/P1sec/QCSuper.git"
        "https://github.com/calebmadrigal/trackerjacker.git"
        "https://github.com/IxAmxZer0/Wifi-Biter.git"
        "https://github.com/DanMcInerney/wifijammer.git"
        "https://github.com/kimocoder/wifite2.git"
        "https://github.com/virtualabs/btlejack.git"
        "https://github.com/Ledger-Donjon/intel-wifi-research-tools.git"
        "https://github.com/entropy1337/infernal-twin.git"
        "https://github.com/kismetwireless/kismet.git"
        "https://github.com/chrisk44/Hijacker.git"
        "https://github.com/penthertz/rf-swift.git"
        "https://github.com/DanMcInerney/wifijammer.git"
    )

    # We sanitize the argument in case the user surrounds it with quotes.
    # If the user typed something like ""booty"" (with double quotes), this will remove them.
    local raw_dir="$1"
    local sanitized_dir
    sanitized_dir="$(sed -E 's/^\"+|\"+$//g' <<< "$raw_dir")"

    # If no argument or sanitized argument is empty, default to cloned_repos.
    local output_dir="${sanitized_dir:-cloned_repos}"

    mkdir -p "$output_dir"

    echo "[INFO]: Starting the cloning process."
    for repo in "${repos[@]}"; do
        local repo_name
        repo_name="$(basename "$repo" .git)"

        echo "[INFO]: Processing repository: $repo_name"

        # -----------------------------
        # CLONE OR PULL THE REPOSITORY
        # -----------------------------
        if [ ! -d "$output_dir/$repo_name" ]; then
            echo "[INFO]: Cloning $repo into $output_dir/$repo_name..."
            if ! git clone "$repo" "$output_dir/$repo_name"; then
                log_error "Failed to clone $repo. Skipping this repository..."
                continue
            fi
            echo "[INFO]: Successfully cloned $repo_name."
        else
            echo "[INFO]: $repo_name already exists. Pulling latest changes..."
            if ! (cd "$output_dir/$repo_name" && git pull); then
                log_error "Failed to pull changes for $repo_name. Skipping further steps for this repo..."
                continue
            fi
            echo "[INFO]: Successfully pulled latest changes for $repo_name."
        fi

        # ------------------------------------
        # CHECK FOR INSTALL SCRIPT & EXECUTE
        # ------------------------------------
        if has_install_script "$output_dir/$repo_name"; then
            echo "[INFO]: Found an installation script in $repo_name. Marking as executable and running..."
            chmod +x "$output_dir/$repo_name"/*install*.sh
            if ! (cd "$output_dir/$repo_name" && bash ./*install*.sh); then
                echo "[WARNING]: Could not run the installation script for $repo_name."
                # continue  # If you want to skip to the next repo on error, uncomment this.
            fi
        else
            echo "[INFO]: No installation script found for $repo_name."
            # ----------------------------------------------------------
            # CHECK IF IT IS PYTHON-BASED; IF SO, CREATE VENV AND INSTALL
            # ----------------------------------------------------------
            if is_python_repo "$output_dir/$repo_name"; then
                echo "[INFO]: $repo_name appears to be a Python repo. Creating virtual environment and installing."
                if ! cd "$output_dir/$repo_name"; then
                    log_error "Could not enter directory $output_dir/$repo_name. Skipping..."
                    continue
                fi

                python3 -m venv venv
                source venv/bin/activate

                if [[ -f "requirements.txt" ]]; then
                    echo "[INFO]: Installing from requirements.txt..."
                    pip install --upgrade pip
                    if ! pip install -r requirements.txt; then
                        log_error "Failed to install Python dependencies for $repo_name."
                        # continue  # Uncomment if you want to skip next steps for this repo.
                    fi
                elif [[ -f "setup.py" ]]; then
                    echo "[INFO]: Running setup.py install..."
                    pip install --upgrade pip
                    if ! python setup.py install; then
                        log_error "Failed to run setup.py install for $repo_name."
                        # continue
                    fi
                fi

                deactivate
                cd - >/dev/null || true

            else
                echo "[INFO]: $repo_name doesn't appear to be Python-based. Skipping venv setup."
            fi
        fi

        echo "[INFO]: Finished processing $repo_name."
        echo "--------------------------------------------------"
    done

    echo "[INFO]: All repositories have been processed."
    echo "[INFO]: Please review and understand the purpose of each repository before running or installing its contents."
}

# Example usage:
#   ./install.sh [output_directory]
# If no output_directory is provided, it defaults to "cloned_repos".

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_tools "$1"
fi

Install_security_and_network_tools() {
    echo "[+] Installing essential tools for network administration and security..."
    local tools=(
        net-tools tcpdump traceroute mtr iperf3 dnsutils whois tshark arp-scan ettercap-common dsniff
        metasploit-framework wireshark nmap aircrack-ng john hashcat zaproxy sqlmap hydra proxychains
        gobuster dirb checksec nikto wpscan macchanger responder bloodhound impacket-scripts
        crackmapexec seclists nishang powersploit enum4linux recon-ng tor xplico apache2 openvas
        netcat
    )

    # Example: apt-get install logic here, with error checks if you wish.
    # ...
}
