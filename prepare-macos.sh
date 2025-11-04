#!/bin/bash
#
# .SYNOPSIS
#    Automation script to bootstrap a Data Science environment on macOS.
#
# .DESCRIPTION
#    This script prepares the macOS environment by:
#    1. Installing Homebrew (the macOS package manager), if not present.
#    2. Installing base dependencies (Git, VS Code, unzip) via Homebrew.
#    3. Creating the 'Data-Platform Structure' directory structure.
#    4. Configuring the .zshrc file (macOS default shell) with the required PATHs.
#    5. Installing 'uv' (Python manager).
#    6. Installing 'fnm' (Node manager), Node LTS, and the Gemini CLI.
#    7. Installing the Google Cloud SDK (gcloud CLI).
#    8. Installing global Python tools (ruff, black, etc.) via uv.
#    9. Installing all required VS Code extensions.
#
# .NOTES
#    VERSION: 1.1 (Added GCP SDK Installation)
#    AUTHOR: Alexandre Oliveira (Adapted for macOS by Gemini)
#    RUN: Run this script from the macOS terminal.
#         Ex: curl -LsSf [URL_TO_THIS_FILE] | bash
#

# --- Step 0: Helper Functions and Setup ---

# Function to print formatted headers
print_header() {
    echo ""
    echo "-----------------------------------------------------"
    echo " $1"
    echo "-----------------------------------------------------"
}

# Set script to exit immediately if any command fails
set -e

# --- Step 1: Install Homebrew (macOS Package Manager) ---
print_header "Step 1: Checking for and Installing Homebrew"

if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing..."
    # Non-interactive Homebrew installation
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to the CURRENT session's PATH (Critical for Apple Silicon)
    if [ -x "/opt/homebrew/bin/brew" ]; then
        echo "Adding Homebrew (Apple Silicon) to this session's PATH..."
        export PATH="/opt/homebrew/bin:$PATH"
    fi
    # Add Homebrew to the CURRENT session's PATH (Critical for Intel Macs)
    if [ -x "/usr/local/bin/brew" ]; then
        echo "Adding Homebrew (Intel) to this session's PATH..."
        export PATH="/usr/local/bin:$PATH"
    fi
else
    echo "Homebrew is already installed. Updating..."
    brew update
fi
brew --version

# --- Step 2: Install Base Dependencies (Git, VS Code) ---
print_header "Step 2: Installing Base Dependencies (Homebrew)"

echo "Installing/Updating Git..."
# Homebrew handles the 'Xcode Command Line Tools' dependency here
brew install git

echo "Installing/Updating Visual Studio Code..."
# '--cask' is used for macOS GUI applications
brew install --cask visual-studio-code

echo "Installing 'unzip' (required by fnm)..."
brew install unzip

# --- Step 3: Create 'Data-Platform Structure' Directory Structure ---
print_header "Step 3: Creating Directory Structure"
echo "Creating Data-Platform folder structure in home directory (~/)..."
# The '-p' flag ensures mkdir doesn't error if directories already exist
mkdir -p "$HOME/11-System-Tooling/11.10-Bin"
mkdir -p "$HOME/11-System-Tooling/11.20-Node"
mkdir -p "$HOME/11-System-Tooling/11.30-Configs"
mkdir -p "$HOME/21-Main-Projects"
mkdir -p "$HOME/31-Other-Projects"
echo "Directory structure created/verified."

# --- Step 4: Configure .zshrc ---
print_header "Step 4: Configuring ~/.zshrc for Tools"
# The default macOS shell is Zsh
CONFIG_FILE="$HOME/.zshrc"
BASHRC_SN_MARKER="# === Data-Platform Structure (Company) ==="

# Check if the configuration block already exists (Idempotency)
if ! grep -q "$BASHRC_SN_MARKER" $CONFIG_FILE; then
    echo "Adding Company configuration to $CONFIG_FILE..."
    # Use 'SH' as the delimiter
    cat >> $CONFIG_FILE <<'SH'

# === Data-Platform Structure (Company) ===
export TOOLING="$HOME/11-System-Tooling"

# uv (Python manager) and global tools (ruff, black, etc)
export PATH="$HOME/.local/bin:$PATH"

# Your personal scripts and downloaded binaries
export PATH="$TOOLING/11.10-Bin:$PATH"

# fnm/node (for the Gemini CLI)
export FNM_DIR="$TOOLING/11.20-Node"
export PATH="$FNM_DIR:$PATH"
# 'eval' recommended for zsh
eval "$(fnm env --use-on-cd)"
# === END Data-Platform Structure ===

SH
    echo "Configuration added."
else
    echo "Company configuration already found in $CONFIG_FILE. Skipping."
fi

# --- Step 5: Install uv (Python Manager) ---
print_header "Step 5: Installing uv (Python Manager)"
if ! command -v uv &> /dev/null; then
    echo "uv not found. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "uv installed successfully."
else
    echo "uv is already installed. Skipping."
fi
# Add uv to the CURRENT session's PATH
export PATH="$HOME/.local/bin:$PATH"
uv --version

# --- Step 6: Install Node LTS + Gemini CLI (via fnm) ---
print_header "Step 6: Installing Node LTS + Gemini CLI"

# Set FNM_DIR for the install script and current session
export FNM_DIR="$HOME/11-System-Tooling/11.20-Node"
export PATH="$FNM_DIR:$PATH"

# Install fnm (Fast Node Manager)
if ! command -v fnm &> /dev/null; then
    echo "fnm not found. Installing..."
    # The 'unzip' dependency was handled in Step 2 (brew)
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$FNM_DIR" --skip-shell
    echo "fnm installed."
else
    echo "fnm is already installed. Skipping."
fi

# Add fnm to the CURRENT session's env
eval "$(fnm env)"

# Install Node.js LTS
echo "Installing Node.js LTS..."
fnm install --lts

# === START FIX ===
# Get the name of the latest installed version
# This method is robust and works even if fnm ls output changes.
NODE_VERSION=$(fnm ls | grep -Eo 'v[0-9\.]+' | tail -1)
# === END FIX ===

fnm default $NODE_VERSION

# --- FIX (v2.4 from original script): Manually activate the Node bin ---
# This is crucial for 'npm' to work in the next step
echo "Activating Node.js $NODE_VERSION in the current session..."
NODE_BIN_PATH="$FNM_DIR/node-versions/$NODE_VERSION/installation/bin"
export PATH="$NODE_BIN_PATH:$PATH"
# --- END FIX ---

echo "Node $(node --version) and npm $(npm --version) installed."

# Install/Update the Gemini CLI
echo "Installing/Updating @google/gemini-cli via npm..."
npm install -g @google/gemini-cli
echo "Gemini CLI installed."

# --- Step 7: Install Google Cloud SDK (gcloud CLI) ---
print_header "Step 7: Installing/Updating Google Cloud SDK (gcloud CLI)"

# Purpose: Check if gcloud is already installed by checking the command.
if ! command -v gcloud &> /dev/null; then
    echo "gcloud CLI not found. Installing..."
    # Purpose: Use Homebrew to install the cask. This is the standard way on macOS.
    brew install --cask google-cloud-sdk
    echo "gcloud CLI installed successfully."
else
    echo "gcloud CLI is already installed. Checking for updates..."
    # Purpose: Use 'brew upgrade' to update the cask if a new version is available.
    # 'brew update' was already run in Step 1.
    brew upgrade --cask google-cloud-sdk
    echo "gcloud CLI is up-to-date."
fi
echo "Run 'gcloud init' to configure after the script finishes."


# --- Step 8: Install Global Python Tools (with uv) ---
print_header "Step 8: Installing Global Python Tools (with uv)"
echo "Using 'uv tool install' to make tools available globally (in ~/.local/bin)."

# List of tools to install
global_tools=(
    "ruff"
    "black"
    "sqlfluff"
    "jupyterlab"
    "pre-commit"
    "cookiecutter"
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

# --- Step 9: Install VS Code Extensions ---
print_header "Step 9: Installing VS Code Extensions"
echo "This will install all required extensions (combined from scripts 01 and 02)."

# Check if the 'code' command (from VS Code) is available
if command -v code &> /dev/null; then
    # Combined list of extensions
    allExtensions=(
        # From 01-prepare-windows.ps1 (UI Extensions)
        "ms-vscode-remote.remote-containers"
        "dracula-theme.theme-dracula"
        "mechatroner.rainbow-csv"
        "pkief.material-icon-theme"
        "mathematic.vscode-pdf"
        
        # From 02-prepare-linux-wsl.sh (Dev Extensions)
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
        "hashicorp.terraform"
        "ms-azuretools.vscode-docker"
        "Google.gemini-cli-vscode-ide-companion"
        "Google.geminicodeassist"
    )

    echo "Getting list of installed extensions..."
    # Get the list of already installed extensions
    installedExtensions=$(code --list-extensions)

    for ext in "${allExtensions[@]}"; do
        if echo "$installedExtensions" | grep -qi "$ext"; then
            echo "Extension '$ext' is already installed. Skipping."
        else
            echo "Installing extension: $ext..."
            code --install-extension "$ext"
        fi
    done
    echo "VS Code extensions check complete."
else
    echo "WARNING: 'code' command not found."
    echo "Could not install VS Code extensions."
    echo "Please open VS Code, press (Cmd + Shift + P), run 'Shell Command: Install 'code' command in PATH',"
    echo "and then run this script again."
fi

# --- Step 10: Conclusion ---
print_header "Bootstrap COMPLETE!"
echo ""
echo "Your macOS environment is 100% configured."
echo "Next steps:"
echo "1. Close and RE-OPEN this terminal for all changes (especially to .zshrc) to take effect."
echo "2. Log in to the Gemini CLI by typing:"
echo "   gemini"
echo "3. Log in to the GCP CLI by typing:"
echo "   gcloud auth login && gcloud config set project [YOUR-PROJECT-ID]"
echo ""
echo "After that, you are ready to navigate to '~/21-Main-Projects' and start your work!"
echo ""
