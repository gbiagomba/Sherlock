# Installation Scripts

This directory contains installation scripts for deploying Sherlock across different platforms.

## Files

### install.sh

Shell script for installing Sherlock on Linux and macOS systems.

**Usage:**
```bash
./scripts/install.sh [OPTIONS]
```

**Options:**
- `--with-tools`: Install common security tools (nmap, amass, gobuster, httpx, nuclei)
- `--prefix <PATH>`: Installation directory (default: `/usr/local/bin`)

**Examples:**
```bash
# Basic installation
./scripts/install.sh

# Install with tools
./scripts/install.sh --with-tools

# Custom installation path
./scripts/install.sh --prefix ~/.local/bin
```

**Requirements:**
- Existing built binary in `target/release/sherlock` OR
- Cargo installed for building from source
- Sudo access for installation

### install.ps1

PowerShell script for installing Sherlock on Windows systems.

**Usage:**
```powershell
.\scripts\install.ps1 [-WithTools] [-Prefix <PATH>]
```

**Parameters:**
- `-WithTools`: Install common security tools via winget/chocolatey
- `-Prefix <PATH>`: Installation directory (default: `C:\Program Files\Sherlock`)

**Examples:**
```powershell
# Basic installation
.\scripts\install.ps1

# Install with tools
.\scripts\install.ps1 -WithTools

# Custom installation path
.\scripts\install.ps1 -Prefix "C:\Tools\Sherlock"
```

**Requirements:**
- Existing built binary in `target\release\sherlock.exe` OR
- Cargo installed for building from source
- Administrator privileges for system-wide installation

## Post-Installation

After installation, verify the setup by running:
```bash
sherlock doctor
```

This command checks for the presence of required and optional tools.
