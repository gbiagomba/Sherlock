#!/usr/bin/env bash
set -euo pipefail

# Sherlock installer for Linux/macOS
# - Installs the sherlock binary to /usr/local/bin
# - Optional: installs common tools (nmap, amass, gobuster, httpx, nuclei)

WITH_TOOLS=0
PREFIX="/usr/local/bin"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-tools) WITH_TOOLS=1; shift ;;
    --prefix) PREFIX="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

echo "[+] Installing sherlock to $PREFIX"
if [[ -x "./target/release/sherlock" ]]; then
  BIN=./target/release/sherlock
elif command -v cargo >/dev/null 2>&1; then
  echo "[+] Building via cargo install --path ."
  cargo install --path .
  BIN=$(command -v sherlock)
else
  echo "[!] No built binary found and cargo is not available. Please download a release binary and place it in PATH."
  exit 1
fi

sudo install -m 0755 "$BIN" "$PREFIX/sherlock"
echo "[+] sherlock installed at $PREFIX/sherlock"

if [[ $WITH_TOOLS -eq 1 ]]; then
  echo "[+] Installing common tools (requires admin)"
  if command -v brew >/dev/null 2>&1; then
    brew update
    brew install nmap gobuster amass || true
    brew install projectdiscovery/tap/httpx projectdiscovery/tap/nuclei || true
    if ! command -v amass >/dev/null 2>&1; then
      echo "[i] amass not available via brew or not found; installing via go"
      export GOPATH=${GOPATH:-"$HOME/go"}; export PATH="$PATH:$GOPATH/bin"
      go install github.com/OWASP/Amass/v3/...@latest || true
      sudo install -m 0755 "$GOPATH/bin/amass" /usr/local/bin/amass || true
    fi
  elif command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y nmap gobuster golang-go
    export GOPATH=${GOPATH:-"$HOME/go"}; export PATH="$PATH:$GOPATH/bin"
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest || true
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest || true
    go install github.com/OWASP/Amass/v3/...@latest || true
    sudo install -m 0755 "$GOPATH/bin/httpx" /usr/local/bin/httpx || true
    sudo install -m 0755 "$GOPATH/bin/nuclei" /usr/local/bin/nuclei || true
    sudo install -m 0755 "$GOPATH/bin/amass" /usr/local/bin/amass || true
  elif command -v yum >/dev/null 2>&1 || command -v dnf >/dev/null 2>&1; then
    PM=$(command -v dnf || command -v yum)
    sudo $PM install -y nmap golang || true
    # gobuster/amass availability varies; prefer go install
    export GOPATH=${GOPATH:-"$HOME/go"}; export PATH="$PATH:$GOPATH/bin"
    go install github.com/OJ/gobuster/v3@latest || true
    go install github.com/OWASP/Amass/v3/...@latest || true
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest || true
    go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest || true
    for b in gobuster amass httpx nuclei; do sudo install -m 0755 "$GOPATH/bin/$b" /usr/local/bin/$b || true; done
  else
    echo "[!] Unsupported package manager. Please install tools manually.";
  fi
fi

echo "[+] Done. Run: sherlock doctor"
