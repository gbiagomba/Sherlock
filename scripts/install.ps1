param(
  [switch]$WithTools,
  [string]$Prefix = "$env:ProgramFiles\Sherlock"
)

$ErrorActionPreference = "Stop"

Write-Host "[+] Installing sherlock to $Prefix"
New-Item -ItemType Directory -Force -Path $Prefix | Out-Null

$localBinary = Join-Path (Get-Location) "target\release\sherlock.exe"
if (Test-Path $localBinary) {
  Copy-Item $localBinary (Join-Path $Prefix "sherlock.exe") -Force
}
elseif (Get-Command cargo -ErrorAction SilentlyContinue) {
  Write-Host "[+] Building via cargo install --path ."
  cargo install --path .
  $installed = (Get-Command sherlock.exe).Source
  Copy-Item $installed (Join-Path $Prefix "sherlock.exe") -Force
}
else {
  throw "No built binary found and cargo unavailable. Please download a release artifact for Windows."
}

# Add to PATH for current user
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*${Prefix}*") {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$Prefix", "User")
  Write-Host "[+] Appended $Prefix to user PATH. Restart terminal to take effect."
}

if ($WithTools) {
  Write-Host "[+] Installing common tools"
  if (Get-Command winget -ErrorAction SilentlyContinue) {
    try { winget install -e --id Nmap.Nmap } catch {}
    # The following may not exist in winget repos; print guidance if absent.
    Write-Host "[*] For amass/gobuster/httpx/nuclei, prefer Scoop or vendor releases."
  }
  elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    try { choco install -y nmap } catch {}
  }
  else {
    Write-Host "[!] No package manager detected (winget/choco). Install tools manually."
  }
}

Write-Host "[+] Done. Run: sherlock doctor"

