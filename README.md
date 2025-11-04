# Data Science & Engineering Bootstrap

This repository contains automation scripts to set up a complete data science and engineering environment on either Windows (using WSL2) or macOS.

## Table of Contents

* [Overview](#-overview)
* [For Windows Users](#-for-windows-users)
  * [Windows Process Overview](#windows-process-overview)
  * [Windows Prerequisites](#windows-prerequisites)
  * [Windows Installation Steps](#windows-installation-steps)
  * [What the Windows Scripts Do](#-what-the-windows-scripts-do)
* [For macOS Users](#-for-macos-users)
  * [macOS Process Overview](#macos-process-overview)
  * [macOS Prerequisites](#macos-prerequisites)
  * [macOS Installation Steps](#macos-installation-steps)
  * [What the macOS Script Does](#-what-the-macos-script-does)

---

## 🚀 Overview

The goal of this project is to provide a one-click setup for a robust development environment.

* **Windows users** will have a two-script process that installs and configures WSL2 (Windows Subsystem for Linux) with an Ubuntu environment.
* **macOS users** will have a single-script process that configures their native UNIX environment.

Both setups will install:
* Core tools like Git and VS Code.
* Python environment management (`uv`).
* Node.js environment management (`fnm`) for tools like the Gemini CLI.
* Essential global Python tools (`ruff`, `black`, `sqlfluff`, `jupyterlab`, etc.).
* A comprehensive set of VS Code extensions for data science.

---

## 🖥️ For Windows Users

This section describes the two-script process to set up a Windows machine for analytics, engineering, and data science projects by leveraging WSL2 (Windows Subsystem for Linux).

### Windows Process Overview

The setup is a two-part process. The first script prepares Windows, and the second configures the Linux (WSL) environment.

[ 🖥️ **Script 1: Windows Prep** ] ➔ [ 🔄 **Reboot** ] ➔ [ 🐧 **Script 2: Linux (WSL) Setup** ]

### Windows Prerequisites

* A Windows 10 or 11 machine.
* Administrator privileges.

### Windows Installation Steps

1.  **Run the Windows Prep Script (Script 1):**
    * Open **PowerShell as an Administrator**.
    * Execute the following command to download and run the first script:
        ```powershell
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process; iex (irm -Uri "[https://raw.githubusercontent.com/alexandreheringer/bootstrap-data-science/main/01-prepare-windows.ps1](https://raw.githubusercontent.com/alexandreheringer/bootstrap-data-science/main/01-prepare-windows.ps1)")
        ```

2.  **Reboot:** After the script finishes, **restart your computer**. This is required to finalize the WSL2 installation.

3.  **Set up Ubuntu:**
    * From the Start Menu, open **"Ubuntu 24.04"**.
    * Follow the prompts to complete the one-time setup (creating your Linux username and password).

4.  **Configure VS Code:**
    * Open **VS Code**.
    * Press `Ctrl + Shift + P` to open the Command Palette.
    * Type `Terminal: Select Default Profile` and press Enter.
    * Choose **WSL (Ubuntu-24.04)** from the list. This makes WSL your default terminal in VS Code.

5.  **Run the Linux Setup Script (Script 2):**
    * In the VS Code terminal (which is now a WSL/Ubuntu terminal), execute the following command:
        ```bash
        curl -LsSf "[https://raw.githubusercontent.com/alexandreheringer/bootstrap-data-science/main/02-prepare-linux-wsl.sh](https://raw.githubusercontent.com/alexandreheringer/bootstrap-data-science/main/02-prepare-linux-wsl.sh)" | bash
        ```

6.  **All Done!** Relaunch VS Code. Your environment is now fully configured.

### 🔍 What the Windows Scripts Do

#### Script 1: `01-prepare-windows.ps1` (Windows Setup)

This script sets up the Windows side of the environment.

* **🔒 Admin Check:** Verifies it's running with Administrator privileges.
* **🛠️ Install/Update Core Tools:** Uses `winget` to install or upgrade:
  * Git
  * Visual Studio Code
  * The `winget` package manager itself.
* **🔌 Install VS Code Extensions (Windows):** Installs UI-level extensions:
  * `ms-vscode-remote.remote-wsl` (for connecting to WSL)
  * `ms-vscode-remote.remote-containers`
  * Dracula Theme, Rainbow CSV, Material Icon Theme, and a PDF viewer.
* **🔧 Enable WSL2:** Enables `Microsoft-Windows-Subsystem-Linux` and `VirtualMachinePlatform`.
* **🐧 Install Ubuntu:** Checks for and installs Ubuntu 24.04 if not present.
* **💻 Create Shortcut:** Creates a "VS Code (WSL)" shortcut on the Desktop that auto-launches VS Code connected to the Ubuntu 24.04 environment.

#### Script 2: `02-prepare-linux-wsl.sh` (Linux Setup)

This script runs inside Ubuntu (WSL) to configure the Linux development environment.

* **📦 Base Dependencies:** Updates `apt` and installs `git`, `curl`, `build-essential`, `unzip`, and `ca-certificates`.
* **📂 Custom Directory Structure:** Builds a specific folder system in your `~/` (home) directory.
* **⚙️ Environment Configuration:** Modifies `~/.bashrc` to add the new tooling directories to your system's `PATH`.
* **🐍 Python Tooling:**
  * Installs `uv` (a fast Python package manager).
  * Uses `uv` to globally install: `ruff`, `black`, `sqlfluff`, `jupyterlab`, `pre-commit`, and `cookiecutter`.
* **🚀 Node.js & Gemini CLI:**
  * Installs `fnm` (Fast Node Manager).
  * Uses `fnm` to install the latest LTS version of Node.js.
  * Uses `npm` to globally install `@google/gemini-cli`.
* **🔌 VS Code Extensions (WSL):** Installs a comprehensive list of extensions directly into the WSL environment for development, including:
  * `eamodio.gitlens` (GitLens)
  * `ms-toolsai.jupyter` (Jupyter)
  * `msrvida.vscode-sanddance` (SandDance)
  * `ms-toolsai.datawrangler` (Data Wrangler)
  * `dorzey.vscode-sqlfluff` (sqlfluff)
  * `ms-python.python` (Python)
  * `kevinrose.vsc-python-indent` (Python Indent)
  * `ms-python.debugpy` (Python Debugger)
  * `ms-python.vscode-python-envs` (Python Environment Manager)
  * `redhat.vscode-yaml` (YAML)
  * `yzhang.markdown-all-in-one` (Markdown All in One)
  * `pkief.material-icon-theme` (Material Icon Theme)
  * `hashicorp.terraform` (HashiCorp Terraform)
  * `ms-azuretools.vscode-docker` (Docker)
  * `Google.gemini-cli-vscode-ide-companion` (Gemini CLI)
  * `Google.geminicodeassist` (Gemini Code Assist)

---

## 🍎 For macOS Users

This section describes the single-script process to set up a macOS machine. The macOS environment is already UNIX-based, so no virtual machine or WSL is required.

### macOS Process Overview

The setup is a single-script process. You run the script, and it configures your native macOS terminal environment.

[ 🍎 **Terminal** ] ➔ [ ⚙️ **Run Setup Script** ] ➔ [ ✅ **All Done!** ]

### macOS Prerequisites

* A macOS machine (Intel or Apple Silicon).
* Administrator privileges (the script will prompt for your password to install Homebrew and other software).

### macOS Installation Steps

1.  **Open the Terminal**
    * You can find it in `Applications/Utilities/Terminal.app` or by searching for "Terminal" with Spotlight (Cmd + Space).

2.  **Run the macOS Setup Script:**
    * Copy and paste the following command into your terminal and press Enter. This will download and execute the `prepare-macos.sh` script.
        ```bash
        curl -LsSf "[https://raw.githubusercontent.com/alexandreheringer/bootstrap-data-science/main/prepare-macos.sh](https://raw.githubusercontent.com/alexandreheringer/bootstrap-data-science/main/prepare-macos.sh)" | bash
        ```

3.  **Handle VS Code Extensions (If Necessary):**
    * The script will try to install VS Code extensions automatically. If this is the *first time* you have installed VS Code, the script might show a warning: `WARNING: 'code' command not found.`
    * If you see this, simply:
        1.  Open **Visual Studio Code**.
        2.  Open the Command Palette (`Cmd + Shift + P`).
        3.  Type and select `Shell Command: Install 'code' command in PATH`.
        4.  Close VS Code.
        5.  Run the `curl` command from Step 2 again. The script is idempotent and will safely skip all previous steps, installing only the extensions.

4.  **All Done!**
    * **Close and RE-OPEN your terminal.** This is a crucial step to load the new environment variables and paths from your `.zshrc` file.
    * Your environment is now fully configured.

### 🔍 What the macOS Script Does

The `prepare-macos.sh` script configures your native macOS environment.

* **🍺 Install Homebrew:** Checks for, installs, or updates Homebrew, the standard macOS package manager.
* **🛠️ Install/Update Core Tools:** Uses `brew` to install or upgrade:
  * Git
  * Visual Studio Code
  * `unzip` (a dependency for `fnm`).
* **📂 Custom Directory Structure:** Builds the same specific folder system in your `~/` (home) directory as the Linux setup.
* **⚙️ Environment Configuration:** Modifies `~/.zshrc` (the default macOS shell config file) to add the new tooling directories to your system's `PATH`.
* **🐍 Python Tooling:**
  * Installs `uv` (a fast Python package manager).
  * Uses `uv` to globally install: `ruff`, `black`, `sqlfluff`, `jupyterlab`, `pre-commit`, and `cookiecutter`.
* **🚀 Node.js & Gemini CLI:**
  * Installs `fnm` (Fast Node Manager).
  * Uses `fnm` to install the latest LTS version of Node.js.
  * Uses `npm` to globally install `@google/gemini-cli`.
* **🔌 Install VS Code Extensions:** Installs a combined list of UI and development extensions, including:
  * `ms-vscode-remote.remote-containers`
  * `dracula-theme.theme-dracula` (Dracula Theme)
  * `mechatroner.rainbow-csv` (Rainbow CSV)
  * `pkief.material-icon-theme` (Material Icon Theme)
  * `mathematic.vscode-pdf` (PDF Viewer)
  * `eamodio.gitlens` (GitLens)
  * `ms-toolsai.jupyter` (Jupyter)
  * `msrvida.vscode-sanddance` (SandDance)
  * `ms-toolsai.datawrangler` (Data Wrangler)
  * `dorzey.vscode-sqlfluff` (sqlfluff)
  * `ms-python.python` (Python)
  * `kevinrose.vsc-python-indent` (Python Indent)
  * `ms-python.debugpy` (Python Debugger)
  * `ms-python.vscode-python-envs` (Python Environment Manager)
  * `redhat.vscode-yaml` (YAML)
  * `yzhang.markdown-all-in-one` (Markdown All in One)
  * `hashicorp.terraform` (HashiCorp Terraform)
  * `ms-azuretools.vscode-docker` (Docker)
  * `Google.gemini-cli-vscode-ide-companion` (Gemini CLI)
  * `Google.geminicodeassist` (Gemini Code Assist)
