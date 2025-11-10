![alt tag](img/Firefly%20Create%20a%20sleek%20and%20professional%20logo%20inspired%20by%20the%20art%20style%20of%20the%20Sherlock%20Holmes%20detect%20(3).jpg)

# Sherlock - Web Inspector

![GitHub](https://img.shields.io/github/license/Achiefs/fim) [![Tip Me via PayPal](https://img.shields.io/badge/PayPal-tip_me-green?logo=paypal)](paypal.me/gbiagomba)

## Background/Lore
Sherlock is a powerful recon automation tool designed to streamline the early phases of web application security assessments. Named after the legendary detective, it automates tasks like target scanning, excluding specific hosts, and more. With Sherlock, security professionals can perform their investigations efficiently while focusing on critical vulnerabilities.

## Features
- System-agnostic single binary (Rust) with subcommands.
- Passive and active recon via external tools (amass, gobuster, nmap).
- Optional HTTP probing via httpx; aggressive checks via nuclei.
- Concurrency and timeouts per tool; no shell eval; structured outputs.
- Consolidated reporting in JSON, CSV, HTML, and TXT.
- Optional “Mindpalace” visual map (HTML + JSON) of targets and findings.

## Installation

### Using Cargo
If you have Rust and Cargo installed, you can easily install Sherlock by running:
```bash
cargo install --path .
```

### Compiling from source
To compile Sherlock from the source code, first ensure that Rust is installed. Then, run the following commands:
```bash
git clone https://github.com/gbiagomba/sherlock
cd sherlock
cargo build --release
```
This will generate an optimized binary located in the `target/release` directory.

### Installer scripts
- Linux/macOS: `scripts/install.sh`
  - Install Sherlock to `/usr/local/bin` and optionally tools.
  - Examples:
    - `scripts/install.sh` (just install sherlock)
    - `scripts/install.sh --with-tools` (also install nmap, amass, gobuster, httpx, nuclei)

- Windows: `scripts/install.ps1`
  - Install `sherlock.exe` to `C:\\Program Files\\Sherlock` and add to PATH.
  - Example (PowerShell): `./scripts/install.ps1 -WithTools`
  - Note: Tools are suggested; use winget/choco/scoop to install as available.

### Docker
The provided Dockerfile builds a ready-to-go image with nmap, amass, gobuster, httpx, and nuclei preinstalled.

Build and run:
```bash
docker build -t sherlock:latest .
docker run --rm -it -v $(pwd):/data sherlock:latest recon -t example.com -p demo -o /data/work/demo
```
Data written to `/data/work/...` inside your current directory.

### CI/CD
- Binaries: Publishing on tags `v*.*.*` builds multi-arch binaries and attaches them to the release.
  - Linux (glibc+musl): x86_64 and aarch64
  - macOS: macos-13 (x64) and macos-14 (Apple Silicon)
  - Windows: x64 and arm64 (MSVC)
  - Workflow: `.github/workflows/release-binaries.yml` (uses `taiki-e/upload-rust-binary`).
- Docker: Multi-arch images (linux/amd64, linux/arm64) built and pushed on `main` and tags.
  - Workflow: `.github/workflows/release-docker.yml` (Buildx with QEMU).
  - Pushes to GHCR `ghcr.io/<owner>/<repo>`; optionally also to Docker Hub if secrets present.

Configure secrets for Docker Hub (optional):
- `DOCKERHUB_USERNAME`: your Docker Hub username
- `DOCKERHUB_TOKEN`: a Docker Hub access token
- `DOCKERHUB_REPO` (optional): override repository name (default: `docker.io/<owner>/<repo>`)

Tag a release to trigger both pipelines:
```bash
git tag v2.0.0
git push origin v2.0.0
```

## Usage

### Subcommands

- `sherlock recon`: Passive recon only (subdomain enumeration without brute force).
- `sherlock investigate`: Full pipeline (subdomain enum with brute + host discovery + basic service scan).
- `sherlock hound`: Aggressive hunting leveraging service fingerprints (nmap) and web probes (httpx) to run nuclei; extensible to metasploit.
- `sherlock report`: Generate JSON, CSV, HTML, and TXT reports from `findings.jsonl` in `--out`.
- `sherlock mindpalace`: Build `graph.json` and `mindpalace.html` visualization.
- `sherlock doctor`: Check environment for tools and print versions.

### Common flags

- `-t, --target <TARGET>`: Single target (repeatable). Accepts hostname, IP, or CIDR.
- `-f, --target-file <FILE>`: File with list of targets.
- `-e, --exclude <FILE>`: File with targets to exclude.
- `-p, --project <NAME>`: Project label for output grouping.
- `-o, --out <DIR>`: Output directory (default: `work/<timestamp>_<project>`).
- `--timeout <SECS>`: Per-tool timeout (default: 600).
- `--concurrency <N>`: Max concurrent tasks (default: 8).
- `-w, --wordlist <FILE>`: Wordlist for DNS brute force (defaults to `rsc/subdomains.list` if present).
- `--dry-run`: Print the execution plan without running tools.
- `--use-httpx`: Enable httpx probing; feeds discovered URLs into nuclei.
- `--nuclei-templates <PATH>`: Path to nuclei templates (directory or file) used in `hound`.
- `--nuclei-severity <LIST>`: CSV of severities to include, e.g. `critical,high,medium`.

### Examples

- Passive recon for a domain list:
  - `sherlock recon -f domains.txt -p acme -o work/acme-recon`

- Full investigation for one domain with wordlist:
  - `sherlock investigate -t example.com -w rsc/subdomains.list -p acme`

- Full investigation including httpx probing:
  - `sherlock investigate -t example.com --use-httpx -w rsc/subdomains.list -p acme`

- Generate reports from prior run:
  - `sherlock report -s work/2025.03.07-12.00.00_acme`

- Create visual map:
  - `sherlock mindpalace -s work/2025.03.07-12.00.00_acme`

### Outputs
- During runs, findings stream to `findings.jsonl` under the chosen `--out`.
- `report` produces:
  - `report.json`, `report.csv`, `report.html`, `report.txt`, and `services.csv` (service inventory: target, host, port, proto, state, service).

### Using the `Makefile`
- **Build the project**:
  ```bash
  make build
  ```
- **Run a passive recon**:
  ```bash
  make build && make recon ARGS="-t example.com -p demo"
  ```
- **Run a full investigation**:
  ```bash
  make build && make investigate ARGS="-t example.com -w rsc/subdomains.list"
  ```
- **Generate reports**:
  ```bash
  make report ARGS="-s work/..."
  ```
- **Clean the project**:
  ```bash
  make clean
  ```
- **Run tests**:
  ```bash
  make test
  ```

## TODO

### Infrastructure & Integrations
- [ ] Add scan result ingestion from vulnerability scanners
  - Support for Tenable Nessus `.nessus` files (XML format)
  - Support for Greenbone OpenVAS XML exports
  - Support for Nmap XML results (already partially supported; extend with direct import command)
  - Parse and normalize findings into sherlock's unified finding format
  - Enable automated follow-up validation checks based on ingested findings

### Service-Specific Exploitation & Validation
- [ ] Add service-specific exploit hooks and validation modules
  - Implement Metasploit integration for `sherlock hound` mode
  - When SMTP is detected (via nmap or ingested scans), run targeted nmap scripts (smtp-*)
  - When RDP is detected, run rdp-specific validation checks
  - When SSH is detected, run ssh-specific checks (ssh-auth-methods, weak ciphers)
  - Create extensible framework for service-to-validation mapping
  - Add optional Metasploit module suggestions based on identified services/CVEs

### Visualization & Reporting
- [ ] Enhance mindpalace visualization
  - Add node grouping by category (subdomains, services, vulnerabilities)
  - Implement filtering by severity, service type, or tool
  - Add search functionality for nodes
  - Consider implementation options:
    - Web app with backend API (more interactive, requires deployment)
    - Enhanced static HTML with client-side filtering (portable, no backend needed)
    - CLI-based visualization using terminal graphics libraries
    - Database backend (SQLite for portability, PostgreSQL for larger deployments)
  - Add export capabilities (PNG/SVG for reports)
  - Implement severity-based color coding for nodes

### Completed Items
- [x] Add HTTP-aware runners (httpx, nuclei) and parser adapters
  - httpx integration complete (src/tools/tool_httpx.rs)
  - nuclei integration complete (src/tools/tool_nuclei.rs)
  - Available via `--use-httpx` flag and `hound` mode

## Contributing
We welcome contributions! Please follow the standard GitHub workflow:
1. Fork the repository.
2. Create a new feature branch.
3. Submit a pull request after testing your changes.

Notes for contributors
- Commit `Cargo.lock` for this application. Our CI enforces that a tracked lockfile exists to ensure reproducible builds and working Docker layers.
- Prefer adding new external tooling via adapters that consume structured outputs (JSON/CSV) and never via `sh -c`.
- For any new tools, update `VERSIONS.md` with proposed version pins and add smoke tests.

Feel free to open issues or suggest improvements.

## License
Sherlock is licensed under the GPL-3.0 License. For more information, see the [LICENSE](LICENSE) file.

## Outtro

```
           ."""-.
          /      \
          |  _..--'-.
          >.`__.-"";"`
         / /(     ^\    (
         '-`)     =|-.   )s
          /`--.'--'   \ .-.
        .'`-._ `.\    | J /
  jgs  /      `--.|   \__/ 
```
