#!/usr/bin/env bash

# Example usage:
#   ./install.sh [output_directory]
# If no output_directory is provided, it defaults to \"cloned_repos\".

set -e

# Helper Function for error handling
error_exit() {
    echo "[ERROR]: $1" 1>&2
    exit 1
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
        "https://github.com/Ha3MrX/DDos-Attack.git"
     
    )

    # Create a directory for the cloned repositories
    local output_dir=\"${1:-cloned_repos}\"  # if 1st argument is not provided, defaults to cloned_repos
    mkdir -p \"$output_dir\"

    echo \"[INFO]: Starting the cloning process.\"
    for repo in \"${repos[@]}\"; do
        local repo_name=$(basename \"$repo\" .git)
        echo \"[INFO]: Cloning $repo into $output_dir/$repo_name...\"
        if [ ! -d \"$output_dir/$repo_name\" ]; then
            git clone \"$repo\" \"$output_dir/$repo_name\" || error_exit \"Failed to clone $repo.\"
            echo \"[INFO]: Successfully cloned $repo_name.\"
        else
            echo \"[INFO]: $repo_name already exists. Pulling latest changes...\"
            (cd \"$output_dir/$repo_name\" && git pull)
        fi

        # Check for install script
        if has_install_script \"$output_dir/$repo_name\"; then
            echo \"[INFO]: Found an installation script in $repo_name. Marking as executable and running it...\"
            chmod +x \"$output_dir/$repo_name\"/*install*.sh
            (cd \"$output_dir/$repo_name\" && bash ./*install*.sh) || echo \"[WARNING]: Could not run the installation script for $repo_name.\"
        else
            echo \"[INFO]: No installation script found for $repo_name.\"
            # Check if it is python-based, if so create venv and install
            if is_python_repo \"$output_dir/$repo_name\"; then
                echo \"[INFO]: $repo_name appears to be a Python repo. Creating virtual environment and installing.\"
                cd \"$output_dir/$repo_name\" || continue
                python3 -m venv venv
                source venv/bin/activate
                if [[ -f \"requirements.txt\" ]]; then
                    echo \"[INFO]: Installing from requirements.txt...\"
                    pip install --upgrade pip
                    pip install -r requirements.txt
                elif [[ -f \"setup.py\" ]]; then
                    echo \"[INFO]: Running setup.py install...\"
                    pip install --upgrade pip
                    python setup.py install
                fi
                deactivate
                cd -
            else
                echo \"[INFO]: Not python based, moving on\"

            #    echo \"[INFO]: $repo_name doesn't appear to be Python-based. Skipping venv setup.\"
            fi
        fi
    done

    echo \"[INFO]: All repositories have been processed.\"
    echo \"[INFO]: Please ensure to review and understand the purpose of each repository before running or installing its contents.\"
}

if [[ \"${BASH_SOURCE[0]}\" == \"${0}\" ]]; then
    install_ddos_tools \"$1\"
fi
