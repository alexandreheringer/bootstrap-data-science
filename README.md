Data Science & Engineering Bootstrap

This README describes the two-script process to set up a Windows machine for analytics, engineering, and data science projects by leveraging WSL2 (Windows Subsystem for Linux).

🚀 Process Overview

The setup is a two-part process. The first script prepares Windows, and the second configures the Linux (WSL) environment.

[ 🖥️ Script 1: Windows Prep ] ➔ [ 🔄 Reboot ] ➔ [ 🐧 Script 2: Linux (WSL) Setup ]

📋 Prerequisites

A Windows 10 or 11 machine.

Administrator privileges.

⚙️ Installation Steps

Run the Windows Prep Script (Script 1):

Open PowerShell as an Administrator.

Execute the following command to download and run the first script:

Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; iex (irm -Uri "[https://raw.githubusercontent.com/alexandreheringer/bootstrap-data-science/refs/heads/main/01-prepare-windows.ps1](https://raw.githubusercontent.com/alexandreheringer/bootstrap-data-science/refs/heads/main/01-prepare-windows.ps1)")


Reboot: After the script finishes, restart your computer. This is required to finalize the WSL2 installation.

Set up Ubuntu:

From the Start Menu, open "Ubuntu 24.04".

Follow the prompts to complete the one-time setup (creating your Linux username and password).

Configure VS Code:

Open VS Code.

Press Ctrl + Shift + P to open the Command Palette.

Type Terminal: Select Default Profile and press Enter.

Choose WSL (Ubuntu-24.04) from the list. This makes WSL your default terminal in VS Code.

Run the Linux Setup Script (Script 2):

In the VS Code terminal (which is now a WSL/Ubuntu terminal), execute the following command:

curl -LsSf [https://raw.githubusercontent.com/alexandreheringer/bootstrap-data-science/refs/heads/main/02-prepare-linux-wsl.sh](https://raw.githubusercontent.com/alexandreheringer/bootstrap-data-science/refs/heads/main/02-prepare-linux-wsl.sh) | bash


All Done! Relaunch VS Code. Your environment is now fully configured.

🔍 What the Scripts Do

🖥️ Script 1: 01-prepare-windows.ps1 (Windows Setup)

This script sets up the Windows side of the environment.

🔒 Admin Check: Verifies it's running with Administrator privileges.

🛠️ Install/Update Core Tools: Uses winget to install or upgrade:

Git

Visual Studio Code

The winget package manager itself.

🔌 Install VS Code Extensions (Windows): Installs UI-level extensions:

ms-vscode-remote.remote-wsl (for connecting to WSL)

ms-vscode-remote.remote-containers

Dracula Theme, Rainbow CSV, Material Icon Theme, and a PDF viewer.

🔧 Enable WSL2: Enables Microsoft-Windows-Subsystem-Linux and VirtualMachinePlatform.

🐧 Install Ubuntu: Checks for and installs Ubuntu 24.04 if not present.

💻 Create Shortcut: Creates a "VS Code (WSL)" shortcut on the Desktop that auto-launches VS Code connected to the Ubuntu 24.04 environment.

🐧 Script 2: 02-prepare-linux-wsl.sh (Linux Setup)

This script runs inside Ubuntu (WSL) to configure the Linux development environment.

📦 Base Dependencies: Updates apt and installs git, curl, build-essential, unzip, and ca-certificates.

📂 Custom Directory Structure: Builds a specific folder system in your ~/ (home) directory:

/home/user/
├── 11-System-Tooling/
│   ├── 11.10-Bin/      (For custom scripts/binaries)
│   ├── 11.20-Node/     (For Node.js versions)
│   └── 11.30-Configs/
├── 21-Main-Projects/
└── 31-Other-Projects/


⚙️ Environment Configuration: Modifies ~/.bashrc to add the new tooling directories (~/.local/bin, ~/11-System-Tooling/11.10-Bin/, etc.) to your system's PATH.

🐍 Python Tooling:

Installs uv (a fast Python package manager).

Uses uv to globally install: ruff, black, sqlfluff, jupyterlab, pre-commit, and cookiecutter.

🚀 Node.js & Gemini CLI:

Installs fnm (Fast Node Manager).

Uses fnm to install the latest LTS version of Node.js.

Uses npm to globally install @google/gemini-cli.

🔌 VS Code Extensions (WSL): Installs a comprehensive list of extensions directly into the WSL environment, including:

eamodio.gitlens (GitLens)

ms-toolsai.jupyter (Jupyter)

msrvida.vscode-sanddance (SandDance for VS Code)

ms-toolsai.datawrangler (Data Wrangler)

dorzey.vscode-sqlfluff (sqlfluff)

ms-python.python (Python)

kevinrose.vsc-python-indent (Python Indent)

ms-python.debugpy (Python Debugger)

ms-python.vscode-python-envs (Python Environment Manager)

redhat.vscode-yaml (YAML)

yzhang.markdown-all-in-one (Markdown All in One)

pkief.material-icon-theme (Material Icon Theme)

hashicorp.terraform (HashiCorp Terraform)

ms-azuretools.vscode-docker (Docker)

Google.gemini-cli-vscode-ide-companion (Gemini CLI)
