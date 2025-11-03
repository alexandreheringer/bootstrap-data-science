#!/bin/bash
#
# .SYNOPSIS
#    Automation script to bootstrap the WSL (Ubuntu) environment.
#    Step 2 of the Data Analyst Setup Playbook.
#
# .DESCRIPTION
#    This script prepares the Ubuntu environment by:
#    1. Installing base dependencies (git, curl, build-essential, unzip).
#    2. Creating the Data-Platform Structure directory structure.
#    3. Configuring the .bashrc file with required PATHs.
#    4. Installing 'uv' (Python manager).
#    5. Installing Node.js LTS (via fnm) into the Data-Platform Structure and installing Gemini CLI.
#    6. Installing global Python tools (ruff, black, etc.) via uv.
#    7. Installing WSL-side VS Code extensions.
#
# .NOTES
#    VERSION: 2.8 (Restored fnm and Data-Platform Structure for Node.js)
#    AUTHOR: Alexandre Oliveira
#    RUN: Run this script from INSIDE the Ubuntu 24.04 WSL terminal.
#         (e.g., using the 'curl ... | bash' one-liner)
#

# --- Step 0: Helper Functions and Setup ---

# Function to print pretty headers, updated in v1.6
print_header() {
    echo ""
    echo "-----------------------------------------------------"
    echo " $1"
    echo "-----------------------------------------------------"
}

# Set script to exit immediately if any command fails
set -e

# --- Step 1: Base System Dependencies (apt) ---
print_header "Step 1: Installing Base System Dependencies"
echo "Updating package lists..."
sudo apt-get update
echo "Installing git, curl, build-essential, ca-certificates, and unzip..."
sudo apt-get install -y git curl build-essential ca-certificates unzip

# --- Step 2: Create Data-Platform Structure Directory Structure ---
print_header "Step 2: Creating Data-Platform Structure"
echo "Creating Data-Platform folder structure in home directory (~/)..."
# The '-p' flag ensures mkdir doesn't error if directories already exist
mkdir -p "$HOME/11-System-Tooling/11.10-Bin"
mkdir -p "$HOME/11-System-Tooling/11.20-Node" # Restored in v2.8
mkdir -p "$HOME/11-System-Tooling/11.30-Configs" # Restored in v2.8
mkdir -p "$HOME/21-Main-Projects"
mkdir -p "$HOME/31-Other-Projects"
echo "Directory structure created/verified."

# --- Step 3: Configure .bashrc ---
print_header "Step 3: Configuring ~/.bashrc for Data-Platform Structure and Tools"
BASHRC_SN_MARKER="# === Data-Platform Structure (Company) ==="

# Check if the configuration block already exists
if ! grep -q "$BASHRC_SN_MARKER" ~/.bashrc; then
    echo "Adding Company configuration to ~/.bashrc..."
    cat >> ~/.bashrc <<'SH'

# === Data-Platform Structure (Company) ===
export TOOLING="$HOME/11-System-Tooling"

# uv (Python manager) and global tools (ruff, black, etc)
export PATH="$HOME/.local/bin:$PATH"

# Your personal scripts and downloaded binaries
export PATH="$TOOLING/11.10-Bin:$PATH"

# fnm (Node.js Version Manager)
# This directory is specified for fnm to install Node.js versions
export FNM_DIR="$TOOLING/11.20-Node"
export PATH="$FNM_DIR/bin:$PATH"
# This line ensures fnm's environment (shims, etc.) is loaded in interactive shells
eval "$(fnm env)"
# === END Data-Platform Structure ===

SH
    echo "Configuration added."
else
    echo "Company configuration already found in ~/.bashrc. Skipping."
fi

# --- Step 4: Install uv (Python Manager) ---
print_header "Step 4: Installing uv (Python Manager)"
if ! command -v uv &> /dev/null; then
    echo "uv not found. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "uv installed successfully."
else
    echo "uv is already installed. Skipping."
fi
# Add uv to the current session's PATH
export PATH="$HOME/.local/bin:$PATH"
uv --version

# --- Step 5: Install Node.js LTS + Gemini CLI (via fnm) ---
print_header "Step 5: Installing Node.js LTS + Gemini CLI (via fnm)"

# Set the directory (must match Step 3)
export FNM_DIR="$HOME/11-System-Tooling/11.20-Node"
export PATH="$FNM_DIR/bin:$PATH"

if ! command -v fnm &> /dev/null; then
    echo "fnm not found. Installing..."
    # Install fnm, telling it where to install itself (bin) and NOT to modify the shell (skip-shell)
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$FNM_DIR/bin" --skip-shell
    echo "fnm installed."
else
    echo "fnm is already installed. Skipping."
fi

echo "Installing Node.js LTS..."
fnm install --lts
fnm default lts-latest # Set as default

# --- FIX FOR 'curl | bash' ---
# The 'eval $(fnm env)' command fails in the non-interactive 'curl | bash' shell.
# We must manually find the 'default' path and add it to the CURRENT session's PATH.
NODE_DEFAULT_PATH="$FNM_DIR/default/bin"

if [ -d "$NODE_DEFAULT_PATH" ]; then
    export PATH="$NODE_DEFAULT_PATH:$PATH"
    echo "Node.js $(node --version) activated in current session."
else
    echo "ERROR: Could not find Node.js 'default' path. npm will fail."
    echo "Attempting to find fnm executable path: $FNM_DIR/bin/fnm"
    ls -l "$FNM_DIR/bin"
    exit 1
fi
# --- END FIX ---

echo "Node $(node --version) and npm $(npm --version) installed."

# Install Gemini CLI (NO SUDO, as we are in a user-owned directory)
echo "Installing/Updating @google/gemini-cli via npm (no sudo)..."
npm install -g @google/gemini-cli
echo "Gemini CLI installed."


# --- Step 6: Install Global Python Tools (with uv) ---
print_header "Step 6: Installing Global Python Tools"
echo "This step uses 'uv tool install' to make tools available system-wide (in ~/.local/bin)."

# List of tools to install
global_tools=(
    "ruff"
    "black"
    "sqlfluff"
    "jupyterlab"
    "pre-commit"
    "cookiecutter" # Added in v1.8
)

for tool in "${global_tools[@]}"; do
    if ! command -v $tool &> /dev/null; then
        echo "Installing $tool..."
        uv tool install $tool
    else
        echo "$tool is already installed. Checking for updates..."
        uv tool install $tool # 'uv tool install' also acts as an "update"
    fi
done

echo "Global Python tools installed/verified."
ls -l ~/.local/bin

# --- Step 7: Install WSL-side VS Code Extensions ---
print_header "Step 7: Installing WSL-side VS Code Extensions"
echo "This will install extensions inside the WSL environment."

# Check if 'code' command (from VS Code Server) is available
if command -v code &> /dev/null; then
    # List of extensions to install INSIDE WSL
    wslExtensions=(
        "eamodio.gitlens"
        "ms-toolsai.jupyter"
        "msrvida.vscode-sanddance"
        "ms-toolsai.datawrangler"
        "dorzey.vscode-sqlfluff"
        "ms-python.python"
        "kevinrose.vsc-python-indent"
        "ms-python.debugpy"
        "ms-python.vscode-python-envs"
        "redhat.vscode-yaml"
        "yzhang.markdown-all-in-one"
        "pkief.material-icon-theme" # Also install on WSL side for remote consistency
        "hashicorp.terraform"
        "ms-azuretools.vscode-docker"
        "Google.gemini-cli-vscode-ide-companion"
        "Google.geminicodeassist"
    )

    echo "Fetching list of installed WSL extensions..."
    # Get list of extensions already installed in WSL
    installedWslExtensions=$(code --list-extensions)

    for ext in "${wslExtensions[@]}"; do
        if echo "$installedWslExtensions" | grep -qi "$ext"; then
            echo "WSL Extension '$ext' is already installed. Skipping."
        else
            echo "Installing WSL extension: $ext..."
            code --install-extension "$ext"
        fi
    done
    echo "WSL extensions check complete."
else
    echo "WARNING: 'code' command not found."
    echo "This command is only available when you are connected via 'Remote - WSL' in VS Code."
    echo "If you are running this script manually, please connect with VSCode"
    echo "and run this command in the VS Code terminal to install extensions:"
    echo ""
    echo "code --install-extension eamodio.gitlens; code --install-extension ms-toolsai.jupyter; # ...and so on"
fi

# --- Conclusion ---
print_header "Bootstrap COMPLETE!"
echo ""
echo "Your Ubuntu (WSL) environment is 100% configured."
echo "Next steps:"
echo "1. Close and RE-OPEN this terminal for all changes (especially to .bashrc) to take effect."
echo "2. (Optional) Log in to the Gemini CLI by typing:"
echo "   gemini"
echo ""
echo "After that, you are ready to navigate to '~/21-Main-Projects' and start your work!"
echo ""

