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
#   5. Installing 'fnm' (Node manager), Node LTS, and AI CLIs (Gemini, Claude Code, OpenAI Codex).
#   6. Installing global Python tools (ruff, black, etc.) via uv.
#   7. Installing the Google Cloud SDK (gcloud CLI).
#   8. Installing WSL-side VS Code extensions.
#
# .NOTES
#   VERSION: 2.6 (Idempotent Node + AI CLIs + gcloud)
#   AUTHOR: Alexandre Oliveira
#   RUN: Run this script from INSIDE the Ubuntu 24.04 WSL terminal.
#        (e.g., using the 'curl ... | bash' one-liner)
#

# --- Step 0: Helper Functions and Setup ---

# Function to print pretty headers
print_header() {
    echo ""
    echo "-----------------------------------------------------"
    echo " $1"
    echo "-----------------------------------------------------"
}

# Helper: Install a global npm CLI only if its command is missing
#   $1 -> CLI binary name (gemini / claude / codex)
#   $2 -> npm package name (@google/gemini-cli, @anthropic-ai/claude-code, @openai/codex)
#   $3 -> human readable description (Google Gemini, Anthropic Claude Code, OpenAI Codex)
install_npm_cli_if_missing() {
    local cli_name="$1"
    local npm_package="$2"
    local description="$3"

    if command -v "$cli_name" &> /dev/null; then
        echo "$description CLI ('$cli_name') already installed. Skipping."
    else
        echo "$description CLI ('$cli_name') not found. Installing globally via npm package '$npm_package'..."
        npm install -g "$npm_package"
        echo "$description CLI ('$cli_name') installed."
    fi
}

# Exit immediately if any command fails
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
mkdir -p "$HOME/11-System-Tooling/11.10-Bin"
mkdir -p "$HOME/11-System-Tooling/11.20-Node"
mkdir -p "$HOME/11-System-Tooling/11.30-Configs"
mkdir -p "$HOME/21-Main-Projects"
mkdir -p "$HOME/31-Other-Projects"
echo "Directory structure created/verified."

# --- Step 3: Configure .bashrc ---
print_header "Step 3: Configuring ~/.bashrc for Data-Platform Structure and Tools"
BASHRC_SN_MARKER="# === Data-Platform Structure (Company) ==="

if ! grep -q "$BASHRC_SN_MARKER" ~/.bashrc; then
    echo "Adding Company configuration to ~/.bashrc..."
    cat >> ~/.bashrc <<'SH'

# === Data-Platform Structure (Company) ===
export TOOLING="$HOME/11-System-Tooling"

# uv (Python manager) and global tools (ruff, black, etc)
export PATH="$HOME/.local/bin:$PATH"

# Your personal scripts and downloaded binaries
export PATH="$TOOLING/11.10-Bin:$PATH"

# fnm/node (for AI CLIs)
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
if ! command -v uv &> /dev/null; then
    echo "uv not found. Installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "uv installed successfully."
else
    echo "uv is already installed. Skipping."
fi

export PATH="$HOME/.local/bin:$PATH"
uv --version

# --- Step 5: Install Node LTS + AI CLIs (Gemini, Claude Code, OpenAI Codex) ---
print_header "Step 5: Installing Node LTS + AI CLIs (Gemini, Claude Code, OpenAI Codex)"

# Centralized Node/fnm directory
export FNM_DIR="$HOME/11-System-Tooling/11.20-Node"
export PATH="$FNM_DIR:$PATH"
mkdir -p "$FNM_DIR"

# Install fnm only if missing
if ! command -v fnm &> /dev/null; then
    echo "fnm not found. Installing into $FNM_DIR..."
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "$FNM_DIR" --skip-shell
    echo "fnm installed."
else
    echo "fnm is already installed. Skipping installation."
fi

# Ensure fnm environment is loaded for this session
if command -v fnm &> /dev/null; then
    eval "$(fnm env)"
else
    echo "ERROR: fnm command not found even after install. Check FNM_DIR and PATH."
    exit 1
fi

# Install Node.js LTS only if no version is currently managed by fnm
if fnm ls | grep -Eq 'v[0-9]+\.[0-9]+\.[0-9]+'; then
    echo "At least one Node.js version is already installed via fnm. Skipping Node LTS installation."
else
    echo "No Node.js versions found in fnm. Installing Node.js LTS..."
    fnm install --lts
fi

# Determine the Node version to activate (latest listed by fnm)
NODE_VERSION=$(fnm ls | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1)

if [ -z "$NODE_VERSION" ]; then
    echo "No Node.js version detected after fnm ls. Installing Node.js LTS as fallback..."
    fnm install --lts
    NODE_VERSION=$(fnm ls | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1)
fi

# Set default Node version via fnm (idempotent even if called multiple times)
fnm default "$NODE_VERSION"

# Manually export the specific Node.js bin path for this session
NODE_BIN_PATH="$FNM_DIR/node-versions/$NODE_VERSION/installation/bin"
export PATH="$NODE_BIN_PATH:$PATH"

echo "Node $(node --version) and npm $(npm --version) available in current session."

# Install AI CLIs in hardcore idempotent mode (only if missing)
echo "Ensuring AI CLIs are installed (Gemini, Claude Code, OpenAI Codex)..."
install_npm_cli_if_missing "gemini" "@google/gemini-cli" "Google Gemini"
install_npm_cli_if_missing "claude" "@anthropic-ai/claude-code" "Anthropic Claude Code"
install_npm_cli_if_missing "codex" "@openai/codex" "OpenAI Codex"

# --- Step 6: Install Global Python Tools (with uv) ---
print_header "Step 6: Installing Global Python Tools"
echo "This step uses 'uv tool install' to make tools available system-wide (in ~/.local/bin)."

global_tools=(
    "ruff"
    "black"
    "sqlfluff"
    "jupyterlab"
    "pre-commit"
    "cookiecutter" # Added in v1.8
)

for tool in "${global_tools[@]}"; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Installing $tool via uv..."
        uv tool install "$tool"
    else
        echo "$tool is already installed. Skipping (hardcore idempotent)."
    fi
done

echo "Global Python tools installed/verified."
ls -l ~/.local/bin

# --- Step 7: Install Google Cloud SDK (gcloud CLI) ---
print_header "Step 7: Installing/Updating Google Cloud SDK (gcloud CLI)"

if ! command -v gcloud &> /dev/null; then
    echo "gcloud CLI not found. Installing..."
    sudo apt-get install -y apt-transport-https
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
    sudo apt-get update
    sudo apt-get install -y google-cloud-sdk
    echo "gcloud CLI installed successfully. Run 'gcloud init' to configure."
else
    echo "gcloud CLI is already installed. Skipping installation (hardcore idempotent)."
fi

# --- Step 8: Install WSL-side VS Code Extensions ---
print_header "Step 8: Installing WSL-side VS Code Extensions"
echo "This will install extensions inside the WSL environment (idempotent per extension)."

if command -v code &> /dev/null; then
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
        "pkief.material-icon-theme"
        "hashicorp.terraform"
        "ms-azuretools.vscode-docker"
        "Google.gemini-cli-vscode-ide-companion"
        "Google.geminicodeassist"
    )

    echo "Fetching list of installed WSL extensions..."
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
    echo "If you are running this script manually, connect with VS Code and rerun Step 8 to install extensions."
fi

# --- Conclusion ---
print_header "Bootstrap COMPLETE!"

echo "Your Ubuntu (WSL) environment is configured with hardcore idempotency for Node, AI CLIs, uv tools, and gcloud."
echo "Next steps:"

echo "1. Close and RE-OPEN this terminal for all .bashrc changes to take effect."

echo "2. Authenticate the CLIs when you first use them:"
echo "   gemini        # Google Gemini CLI"

echo "   claude        # Anthropic Claude Code CLI"

echo "   codex         # OpenAI Codex CLI"

echo "3. For GCP:"
echo "   gcloud init   # Configure account and default project"

echo "After that, you are ready to navigate to '~/21-Main-Projects' and start your work!"
