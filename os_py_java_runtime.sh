#!/bin/bash

# Function to update the OS, apt, and fetch the latest version of Python and Java
update_os_and_fetch_versions() {
    echo "[!] Updating the OS and package repositories..."
    
    sudo apt update
    sudo apt upgrade -y
    sudo apt dist-upgrade -y
    sudo apt autoremove -y
    sudo apt clean

    echo "[!] Updating Python..."
    
    # Fetch and install the latest Python version
    sudo apt install -y python3 python3-pip
    python3 -m pip install --upgrade pip
    
    # Install the latest Python version if needed (Python 3.x)
    sudo apt install -y python3-dev

    # Check Python version
    python3 --version
    pip --version

    echo "Updating Java..."
    
    # Fetch and install the latest Java version (OpenJDK)
    sudo apt install -y openjdk-17-jdk  # Install OpenJDK 17 (or the latest version available in apt)
    
    # Set JAVA_HOME environment variable
    sudo update-alternatives --config java
    
    # Verify Java installation
    java -version

    echo "[+] OS and package repositories have been updated. The latest versions of Python and Java are now installed."
}

echo "This script will perform the following tasks:"
echo "1. Update the package repositories and upgrade all installed packages."
echo "2. Perform a distribution upgrade and remove unnecessary packages."
echo "3. Fetch and install the latest version of Python 3 along with pip."
echo "4. Install the latest version of Java (OpenJDK 17)."
echo "5. Set the correct JAVA_HOME and update alternatives for Java."
echo "6. Clean up any old packages and dependencies to free up space."update_os_and_fetch_versions
