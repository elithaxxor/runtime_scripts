manage_kvm_modules() {
    echo "[!]Checking for KVM and VirtualBox modules..."
    sudo lsmod | grep -E 'kvm|vbox'

    echo "[!]Removing the KVM module..."
    sudo modprobe -r kvm

    echo "[!]Removing KVM AMD-specific module (if loaded)..."
    sudo rmmod kvm_amd

    echo "[!]Removing the KVM core module..."
    sudo rmmod kvm

    echo "[!]Verifying that KVM and VirtualBox modules are removed..."
    sudo lsmod | grep -E 'kvm|vbox'
}

echo "[!][!]The manage_kvm_modules function checks for loaded KVM and VirtualBox modules, removes them, and verifies their removal."
manage_kvm_modules
