Você está absolutamente correto. O script deve ser robusto e funcionar em todas as execuções.

Aqui está o script 02-prepare-linux-wsl.sh atualizado. A única alteração é a correção na linha que captura a NODE_VERSION, garantindo que ela funcione mesmo que o Node já esteja instalado.

Script Atualizado: 02-prepare-linux-wsl.sh
Eu substituí a linha problemática: NODE_VERSION=$(fnm ls | tail -1 | tr -d ' ' | sed 's/*//g')

Por esta versão mais robusta: NODE_VERSION=$(fnm ls | grep -Eo 'v[0-9\.]+' | tail -1)

Aqui está o conteúdo completo do arquivo corrigido:

Bash

#!/bin/bash
#
# .SYNOPSIS
#   Automation script to bootstrap the WSL (Ubuntu) environment.
#   Step 2 of the Data Analyst Setup Playbook.
#
# .DESCRIPTION
#   This script prepares the Ubuntu environment by:
#   1. Installing base dependencies (git, curl, build-essential, unzip).
#   2. Creating the Data-Platform Structure directory structure.
#   3. Configuring the .bashrc file with required PATHs and aliases.
#   4. Installing 'uv' (Python manager).
#   5. Installing 'fnm' (Node manager), Node LTS, and the Gemini CLI.
#   6. Installing global Python tools (ruff, black, etc.) via uv.
#   7. Installing the Google Cloud SDK (gcloud CLI).
#   8. Installing WSL-side VS Code extensions.
#
# .NOTES
#   VERSION: 2.5 (Added Step 7 for GCP SDK Installation)
#   AUTHOR: Alexandre Oliveira
#   RUN: Run this script from INSIDE the Ubuntu 24.04 WSL terminal.
#        (e.g., using the 'curl ... | bash' one-liner)
#

# --- Step 0: Helper Functions and Setup ---

# Function to print pretty headers, updated in v1.6
# Purpose: Provides clear visual separation for each step in the terminal output.
print_header() {
    echo ""
    echo "-----------------------------------------------------"
    echo " $1"
    echo "-----------------------------------------------------"
}

# Set script to exit immediately if any command fails
# Purpose: Ensures the script stops if a critical step fails, preventing partial/broken installs.
set -e

# --- Step 1: Base System Dependencies (apt) ---
print_header "Step 1: Installing Base System Dependencies"
echo "Updating package lists..."
# Purpose: Refresh the local cache of available packages and versions.
sudo apt-get update
echo "Installing git, curl, build-essential, ca-certificates, and unzip..."
# 'unzip' is required by the 'fnm' installer (Step 5)
# 'ca-certificates' ensures 'apt' can securely download packages over HTTPS.
sudo apt-get install -y git curl build-essential ca-certificates unzip

# --- Step 2: Create Data-Platform Structure Directory Structure ---
print_header "Step 2: Creating Data-Platform Structure"
echo "Creating Data-Platform folder structure in home directory (~/)..."
# The '-p' flag ensures mkdir doesn't error if directories already exist.
# Purpose: Establishes the standardized folder convention for the project.
mkdir -p "$HOME/11-System-Tooling/11.10-Bin"
mkdir -p "$HOME/11-System-Tooling/11.20-Node"
mkdir -p "$HOME/11-System-Tooling/11.30-Configs"
mkdir -p "$HOME/21-Main-Projects"
mkdir -p "$HOME/31-Other-Projects"
echo "Directory structure created/verified."

# --- Step 3: Configure .bashrc ---
print_header "Step 3: Configuring ~/.bashrc for Data-Platform Structure and Tools"
BASHRC_SN_MARKER="# === Data-Platform Structure (Company) ==="

# Purpose: Check if the configuration is already present to avoid duplication.
if ! grep -q "$BASHRC_SN_MARKER" ~/.bashrc; then
    echo "Adding Company configuration to ~/.bashrc..."
    # Purpose: Append the environment variables and paths to the shell configuration.
    # This block ensures all custom tools (uv, fnm, binaries) are in the PATH.
    cat >> ~/.bashrc <<'SH'

# === Data-Platform Structure (Company) ===
export TOOLING="$HOME/11-System-Tooling"

# uv (Python manager) and global tools (ruff, black, etc)
export PATH="$HOME/.local/bin:$PATH"

# Your personal scripts and downloaded binaries
export PATH="$TOOLING/11.10-Bin:$PATH"

# fnm/node (for Gemini CLI)
export FNM_DIR="$TOOLING/11.20-Node"
export PATH="$FNM_DIR:$PATH"
eval "$(fnm env)"
# === END Data-Platform Structure ===

SH
    echo "Configuration added."
else
    echo "Company configuration already found in ~/.bashrc. Skipping."
fi

# --- Step 4: Install uv (Python Manager) ---
print_header "Step 4: Installing uv (Python Manager)"
# Purpose: Check if 'uv' is already installed to avoid re-downloading.
if ! command -v uv &> /dev/null; then
    echo "uv not found. Installing..."
    # Purpose: Download and execute the official Astral installer for uv.
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "uv installed successfully."
else
    echo "uv is already installed. Skipping."
fi
# Purpose: Add uv to the *current* session's PATH so it can be used in Step 6.
export PATH="$HOME/.local/bin:$PATH"
uv --version

# --- Step 5: Install Node LTS + Gemini CLI (via fnm) ---
print_header "Step 5: Installing Node LTS + Gemini CLI"

# Purpose: Set FNM_DIR for the install script, pointing it to our custom directory.
export FNM_DIR="$HOME/11-System-Tooling/11.20-Node"
export PATH="$FNM_DIR:$PATH"

# Install fnm (Fast Node Manager)
# Purpose: Check if 'fnm' is already installed.
if ! command -v fnm &> /dev/null; then
    echo "fnm not found. Installing..."
    # Purpose: Install 'fnm' to the custom tooling directory and skip shell modification
    # (since we handle that manually in .bashrc).
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$FNM_DIR" --skip-shell
    echo "fnm installed."
else
    echo "fnm is already installed. Skipping."
fi

# Purpose: Add fnm to the *current* session's PATH and environment.
eval "$(fnm env)"

# Install Node.js LTS
echo "Installing Node.js LTS..."
# Purpose: Use 'fnm' to install the latest Long-Term Support version of Node.js.
fnm install --lts

# === INÍCIO DA CORREÇÃO ===
# Purpose: Get the specific version name (e.g., "v24.11.0") to set as default.
# This method is robust and works even if fnm ls output changes or has extra text.
NODE_VERSION=$(fnm ls | grep -Eo 'v[0-9\.]+' | tail -1)
# === FIM DA CORREÇÃO ===

fnm default $NODE_VERSION

# --- FIX (v2.4): Manually export the specific Node.js bin path ---
# The 'eval' and 'default' symlink methods are unreliable in curl|bash.
# Purpose: We will manually add the *specific version's* bin path to the session PATH
# to ensure 'node', 'npm', and 'npx' are available immediately.
echo "Activating Node.js $NODE_VERSION in the current session..."
NODE_BIN_PATH="$FNM_DIR/node-versions/$NODE_VERSION/installation/bin"
export PATH="$NODE_BIN_PATH:$PATH"
# --- END FIX ---

echo "Node $(node --version) and npm $(npm --version) installed."

# Install/Update Gemini CLI
echo "Installing/Updating @google/gemini-cli via npm..."
# Purpose: Use 'npm' (from the newly installed Node) to install the Gemini CLI globally.
npm install -g @google/gemini-cli
echo "Gemini CLI installed."

# --- Step 6: Install Global Python Tools (with uv) ---
print_header "Step 6: Installing Global Python Tools"
echo "This step uses 'uv tool install' to make tools available system-wide (in ~/.local/bin)."

# Purpose: Define a list of essential Python-based tools for data analysis and development.
global_tools=(
    "ruff"
    "black"
    "sqlfluff"
    "jupyterlab"
    "pre-commit"
    "cookiecutter" # Added in v1.8
)

# Purpose: Loop through the list and install/update each tool.
for tool in "${global_tools[@]}"; do
    # Purpose: Check if the tool is already installed.
    if ! command -v $tool &> /dev/null; then
        echo "Installing $tool..."
        uv tool install $tool
    else
        echo "$tool is already installed. Checking for updates..."
        # 'uv tool install' also acts as an "update" if the tool already exists.
        uv tool install $tool
    fi
done

echo "Global Python tools installed/verified."
ls -l ~/.local/bin

# --- Step 7: Install Google Cloud SDK (gcloud CLI) ---
# This is the new step you requested.
print_header "Step 7: Installing/Updating Google Cloud SDK (gcloud CLI)"

# Purpose: Check if gcloud is already installed to avoid redundant setup.
if ! command -v gcloud &> /dev/null; then
    echo "gcloud CLI not found. Installing..."
    
    # Purpose: Install 'apt-transport-https' to ensure 'apt' can handle HTTPS sources.
    # This is often needed for adding third-party repositories.
    sudo apt-get install -y apt-transport-https
    
    # Purpose: Download and add Google's public GPG key to the system's keyring.
    # This verifies that the packages we download are authentic and from Google.
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    
    # Purpose: Add the Google Cloud SDK package repository to 'apt's' source list.
    # This tells 'apt' where to find the 'google-cloud-sdk' package.
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
    
    # Purpose: Refresh the 'apt' package list again to include the new Google repository.
    sudo apt-get update
    
    # Purpose: Install the main Google Cloud SDK package.
    sudo apt-get install -y google-cloud-sdk
    
    echo "gcloud CLI installed successfully."
    echo "Run 'gcloud init' to configure."
else
    echo "gcloud CLI is already installed. Checking for updates..."
    # Purpose: Refresh the 'apt' package list to find the latest versions.
    sudo apt-get update
    # Purpose: The 'install' command will automatically upgrade the package if a new version is found.
    sudo apt-get install -y google-cloud-sdk
    echo "gcloud CLI is up-to-date."
fi


# --- Step 8: Install WSL-side VS Code Extensions ---
# (Previously Step 7)
print_header "Step 8: Installing WSL-side VS Code Extensions"
echo "This will install extensions inside the WSL environment."

# Purpose: Check if 'code' command (from VS Code Server) is available.
# This command only exists when the script is run from within the VS Code Remote-WSL terminal.
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
    # Purpose: Get a list of already-installed extensions to avoid re-installing.
    installedWslExtensions=$(code --list-extensions)

    # Purpose: Loop through the desired extensions and install any that are missing.
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
    # Purpose: Provide a helpful warning if the user is running the script outside of VS Code.
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
echo "2. Log in to the Gemini CLI by typing:"
echo "   gemini"
echo "3. Log in to the GCP CLI by typing:"
echo "   gcloud auth login && gcloud config set project [YOUR-PROJECT-ID]"
echo ""
echo "After that, you are ready to navigate to '~/21-Main-Projects' and start your work!"
echo ""
