#!/usr/bin/env bash

################################################################################
# This script enumerates subdirectories (up to two levels deep) in the current
# working directory, then:
#   1) Checks if an install script (install.sh or setup.sh) is present.
#      - If found, marks it executable and runs it.
#   2) Otherwise, checks if the subdirectory appears to be Python-based (has
#      requirements.txt or setup.py). If so, creates a Python virtual environment
#      and installs dependencies.
################################################################################

# Remove or comment out 'set -e' to avoid exiting on any error
# set -e  # Exit on first error (DISABLED)

################################################################################
# Helper Functions
################################################################################

# A function that logs errors without exiting
log_error() {
    echo "[ERROR]: $1" 1>&2
    # Do NOT exit here; we want to keep going.
}

# Detect if the given directory is Python-based.
# Return 0 (true) if 'requirements.txt' or 'setup.py' is found at that path.
is_python_repo() {
    local repo_path="$1"
    if [[ -f "$repo_path/requirements.txt" || -f "$repo_path/setup.py" ]]; then
        return 0  # True
    else
        return 1  # False
    fi
}

# Check if there's an install script in the directory (install.sh or setup.sh)
has_install_script() {
    local repo_path="$1"
    if [[ -f "$repo_path/install.sh" || -f "$repo_path/setup.sh" ]]; then
        return 0  # True
    else
        return 1  # False
    fi
}

################################################################################
# Main logic: Enumerate directories in the current working directory
################################################################################

install_tools_in_cwd() {
    # Base directory is the current working directory.
    local base_dir
    base_dir="$(pwd)"

    echo "[INFO]: Searching subdirectories (2 levels deep) in: $base_dir"

    # We find all subdirectories from 1 to 2 levels below the current dir.
    # -mindepth 1 = ignore the base_dir itself
    # -maxdepth 2 = search only 2 levels deep
    mapfile -t folders < <(find "$base_dir" -mindepth 1 -maxdepth 2 -type d)

    if [[ ${#folders[@]} -eq 0 ]]; then
        echo "[INFO]: No subdirectories found within 2 levels of '$base_dir'."
        return 0
    fi

    for dir in "${folders[@]}"; do
        # Skip if it matches the base directory exactly
        if [[ "$dir" == "$base_dir" ]]; then
            continue
        fi

        local name
        name="$(basename "$dir")"

        echo "========================================================="
        echo "[INFO]: Checking directory: $dir (name: $name)"
        echo "========================================================="

        # 1) Check for install script
        if has_install_script "$dir"; then
            echo "[INFO]: Found an installation script in $dir."
            chmod +x "$dir"/*install*.sh "$dir"/*setup*.sh 2>/dev/null || true

            # Attempt to run each found script
            for script in "$dir"/install.sh "$dir"/setup.sh; do
                if [[ -f "$script" ]]; then
                    echo "[INFO]: Running script: $script"
                    if ! (cd "$dir" && bash "$script"); then
                        # We log an error instead of exiting
                        log_error "Could not run the installation script for $dir."
                        # If you want to skip the rest of this directory, you can do:
                        # continue 2
                    fi
                fi
            done

        # 2) Otherwise, check if Python-based
        elif is_python_repo "$dir"; then
            echo "[INFO]: Detected Python-based directory: $dir"

            # If we can't cd, log an error and skip
            if ! cd "$dir"; then
                log_error "Could not cd into $dir. Skipping..."
                continue
            fi

            # Create virtual environment
            if ! python3 -m venv venv; then
                log_error "Failed to create a virtual environment in $dir."
                cd - >/dev/null || true
                continue
            fi

            # Activate it
            if ! source venv/bin/activate; then
                log_error "Failed to activate the virtual environment in $dir."
                cd - >/dev/null || true
                continue
            fi

            # Install dependencies if they exist
            if [[ -f "requirements.txt" ]]; then
                echo "[INFO]: Installing from requirements.txt..."
                pip install --upgrade pip
                if ! pip install -r requirements.txt; then
                    log_error "Failed to install dependencies from requirements.txt in $dir."
                fi
            elif [[ -f "setup.py" ]]; then
                echo "[INFO]: Running setup.py install..."
                pip install --upgrade pip
                if ! python setup.py install; then
                    log_error "setup.py install failed for $dir."
                fi
            fi

            # Deactivate and go back
            deactivate
            cd - >/dev/null || true

        else
            echo "[INFO]: Not Python-based and no install script found. Skipping."
        fi
    done

    echo "[INFO]: Finished enumerating and processing subdirectories."
}

################################################################################
# Script Entry Point
################################################################################

# If this script is called directly, run the function to process CWD.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_tools_in_cwd
fi
