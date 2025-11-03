<#
.SYNOPSIS
    Automation script to prepare the Host (Windows 11) environment.
    Step 1 of the Data Analyst Setup Playbook.

.DESCRIPTION
    This script prepares the Windows 11 environment by installing tools (Git, VS Code),
    VS Code Windows extensions (like the WSL remote connector),
    activates WSL2, installs the Ubuntu 24.04 distribution,
    and adds a helper configuration (Desktop Shortcut).
    It is idempotent, meaning it can be run multiple times.

.NOTES
    VERSION: 2.7 (Removed automatic VS Code profile setting per user request)
    AUTHOR: Alexandre Oliveira
    REQUIRES: Administrator privileges.
#>

# --- Administrator Privilege Check ---
Write-Host "Checking Administrator privileges..." -ForegroundColor Yellow
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator."
    Write-Warning "Please, right-click the script and select 'Run as Administrator'."
    Write-Host ""
    Write-Host "The script cannot continue without Administrator privileges." -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"
    Exit 1
}
Write-Host "Administrator privileges confirmed." -ForegroundColor Green

# --- 1. Install/Update Tools (Winget, Git, VS Code) ---
Write-Host "Starting Step 1: Installing base Windows tools via Winget..."

Write-Host "Attempting to update 'winget' (Microsoft.AppInstaller)..."
winget install -e --id Microsoft.AppInstaller --accept-source-agreements --accept-package-agreements
$wingetUpdateCode = $LASTEXITCODE
if ($wingetUpdateCode -ne 0 -and $wingetUpdateCode -ne -1978335189) { # -1978335189 = No update found / Already installed
    Write-Warning "Could not update AppInstaller (winget). Code: $wingetUpdateCode. Continuing..."
} Else {
    Write-Host "Winget updated or already current." -ForegroundColor Green
}

# Check, Install, or Upgrade Git
Write-Host "Checking for Git..."
winget list --id Git.Git -n 1 | Out-Null
$gitCheckCode = $LASTEXITCODE

if ($gitCheckCode -ne 0) {
    Write-Host "Git not found. Installing Git (Git.Git)..."
    winget install -e --id Git.Git --accept-source-agreements --accept-package-agreements
    If ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to install Git via winget. Code: $LASTEXITCODE"
    } Else {
        Write-Host "Git installed." -ForegroundColor Green
    }
} Else {
    Write-Host "Git is already installed. Checking for updates..."
    winget upgrade --id Git.Git --accept-source-agreements --accept-package-agreements
    $gitUpgradeCode = $LASTEXITCODE
    if ($gitUpgradeCode -eq 0) {
        Write-Host "Git successfully upgraded." -ForegroundColor Green
    } ElseIf ($gitUpgradeCode -eq -1978335189) { # No update found
        Write-Host "Git is already up to date." -ForegroundColor Green
    } Else {
        Write-Warning "Could not check for Git updates or upgrade failed. Code: $gitUpgradeCode. Continuing..."
    }
}

# Check, Install, or Upgrade VS Code
Write-Host "Checking for VS Code..."
winget list --id Microsoft.VisualStudioCode -n 1 | Out-Null
$vsCodeCheckCode = $LASTEXITCODE

if ($vsCodeCheckCode -ne 0) {
    Write-Host "VS Code not found. Installing VS Code (Microsoft.VisualStudioCode)..."
    winget install -e --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements
    If ($LASTEXITCODE -ne 0) {
        Write-Warning "Failed to install VS Code via winget. Code: $LASTEXITCODE"
    } Else {
        Write-Host "VS Code installed." -ForegroundColor Green
    }
} Else {
    Write-Host "VS Code is already installed. Checking for updates..."
    winget upgrade --id Microsoft.VisualStudioCode --accept-source-agreements --accept-package-agreements
    $vsCodeUpgradeCode = $LASTEXITCODE
    if ($vsCodeUpgradeCode -eq 0) {
        Write-Host "VS Code successfully upgraded." -ForegroundColor Green
    } ElseIf ($vsCodeUpgradeCode -eq -1978335189) { # No update found
        Write-Host "VS Code is already up to date." -ForegroundColor Green
    } Else {
        Write-Warning "Could not check for VS Code updates or upgrade failed. Code: $vsCodeUpgradeCode. Continuing..."
    }
}
Write-Host "Step 1 (Base Tools) Complete."
Write-Host "-----------------------------------------------------"


# --- 1b. Install VS Code Windows Extensions ---
Write-Host "Starting Step 1b: Refreshing PATH and installing VS Code UI/Remote extensions..."

# Force refresh of $env:Path in the current session
Write-Host "Refreshing environment PATH..."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

if (Get-Command code -ErrorAction SilentlyContinue) {
    Write-Host "VS Code 'code' command found. Checking Windows (UI) extensions..."
    
    $windowsExtensions = @(
        "ms-vscode-remote.remote-wsl",
        "ms-vscode-remote.remote-containers",
        "dracula-theme.theme-dracula",
        "mechatroner.rainbow-csv",
        "pkief.material-icon-theme",
        "mathematic.vscode-pdf"
    )

    Write-Host "Fetching list of installed extensions..."
    $installedExtensions = $(code --list-extensions)
    
    foreach ($ext in $windowsExtensions) {
        if ($installedExtensions -match $ext) {
            Write-Host "Extension '$ext' is already installed. Skipping." -ForegroundColor Gray
        } else {
            Write-Host "Installing Windows extension: $ext..." -ForegroundColor Yellow
            code --install-extension $ext
            If ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to install Windows extension: $ext"
            }
        }
    }
    Write-Host "VS Code Windows extensions check complete."
} else {
    Write-Warning "Could not find the 'code' command in the PATH."
    Write-Warning "VS Code Windows extensions will NOT be installed by this script."
    Write-Warning "Please install them manually or restart your session and run the script again."
}
Write-Host "Step 1b (VS Code Extensions) Complete."
Write-Host "-----------------------------------------------------"


# --- 2. Enable WSL Features ---
Write-Host "Starting Step 2: Enabling WSL2 features..."
$wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
if ($wslFeature.State -ne "Enabled") {
    Write-Host "Enabling feature 'Microsoft-Windows-Subsystem-Linux'..."
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
} else {
    Write-Host "Feature 'Microsoft-Windows-Subsystem-Linux' is already enabled."
}

$vmPlatformFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
if ($vmPlatformFeature.State -ne "Enabled") {
    Write-Host "Enabling feature 'VirtualMachinePlatform'..."
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
} else {
    Write-Host "Feature 'VirtualMachinePlatform' is already enabled."
}
Write-Host "Step 2 (WSL Features) Complete."
Write-Host "-----------------------------------------------------"


# --- 3. Install WSL Distribution (Ubuntu) ---
Write-Host "Starting Step 3: Checking WSL Distributions..."
$distroName = "Ubuntu-24.04"
$wingetId = "Canonical.Ubuntu.2404"

# Check 1: Check 'wsl --list'
$wslList = wsl --list --quiet
# Check 2: Check 'winget list'
winget list --id $wingetId -n 1 | Out-Null
$wingetCheckCode = $LASTEXITCODE

if ($wslList -match $distroName -or $wingetCheckCode -eq 0) {
    Write-Host "An existing '$distroName' distribution was found." -ForegroundColor Green
    Write-Host "Skipping installation."
} else {
    Write-Host "No existing '$distroName' distribution found."
    Write-Host "Installing Ubuntu 24.04 via winget..."
    
    winget install -e --id $wingetId --accept-source-agreements --accept-package-agreements
    $installCode = $LASTEXITCODE
    
    # Check if installation succeeded OR if it failed because it was already installed
    if ($installCode -eq 0) {
        Write-Host "Successfully installed '$wingetId'." -ForegroundColor Green
    } ElseIf ($installCode -eq -1978335189) { # -1978335189 = Already installed
        Write-Host "'$wingetId' is already installed (pending first-time setup)." -ForegroundColor Green
    } Else {
        Write-Error "Failed to install '$wingetId' via winget. Code: $installCode"
        Write-Host "The script cannot continue." -ForegroundColor Red
        Write-Warning "Please try installing 'Ubuntu 24.04 LTS' from the Microsoft Store manually."
        Read-Host -Prompt "Press Enter to exit"
        Exit 1
    }
}
Write-Host "Step 3 (WSL Install) Complete."
Write-Host "-----------------------------------------------------"


# --- 4. NEW: Create VS Code (WSL) Desktop Shortcut ---
Write-Host "Starting Step 4: Creating 'VS Code (WSL)' shortcut on Desktop..."
try {
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "VS Code (WSL).lnk"

    if (-not (Test-Path $shortcutPath)) {
        # Find the path to code.exe
        $codePath = (Get-Command code.exe).Source
        if ($codePath) {
            $shell = New-Object -ComObject WScript.Shell
            $shortcut = $shell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $codePath
            $shortcut.Arguments = "--remote wsl+$distroName"
            $shortcut.Description = "Opens VScode connected to $distroName (WSL)"
            $shortcut.Save()
            Write-Host "Successfully created 'VS Code (WSL)' shortcut on your Desktop." -ForegroundColor Green
        } else {
            Write-Warning "Could not find 'code.exe' path. Shortcut not created."
        }
    } else {
        Write-Host "A 'VS Code (WSL)' shortcut already exists on your Desktop. Skipping."
    }
} catch {
    Write-Warning "Failed to create Desktop shortcut."
    Write-Warning "Error: $_"
}
Write-Host "Step 4 (Desktop Shortcut) Complete."
Write-Host "-----------------------------------------------------"


# --- Conclusion ---
Write-Host ""
Write-Host "*****************************************************"
Write-Host " STEP 1 (WINDOWS HOST) COMPLETE!"
Write-Host "*****************************************************"
Write-Host ""
Write-Host "The script has finished."
Write-Host "BEFORE you can run Step 2, you MUST DO THE FOLLOWING:"
Write-Host ""
Write-Host "1. (If you haven't) RESTART THE COMPUTER to ensure WSL2 is fully active."
Write-Host "2. Open '$distroName' from the Start Menu."
Write-Host "3. Create your Linux user and password (this is the first-time setup)."
Write-Host ""
Write-Host "After that, you are ready for Step 2:"
Write-Host "Run the '02-prepare-linux-wsl.sh' script inside your new Ubuntu terminal."
Write-Host ""

Read-Host -Prompt "Press Enter to exit"
