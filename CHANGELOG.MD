# v2.0.1 (2025-11-10)

## Documentation & Infrastructure
- Added comprehensive `scripts/README.md` documenting installation scripts for all platforms
- Enhanced main README TODO section with detailed roadmap:
  - Infrastructure & Integrations: Vulnerability scanner ingestion (Nessus, OpenVAS, Nmap XML)
  - Service-Specific Exploitation: Metasploit integration and service-specific validation hooks
  - Visualization & Reporting: Enhanced mindpalace with grouping, filtering, and multiple output options
  - Marked httpx/nuclei integration as completed
- Created `.version-tracking.md` for semantic versioning compliance and change tracking
- Enhanced `.gitignore` to exclude test artifacts, logs, working directories, and sensitive files
- Added `.github/workflows/` to version control for CI/CD transparency

## Analysis & Findings
- Confirmed httpx and nuclei are fully integrated (tool_httpx.rs, tool_nuclei.rs)
- Identified Metasploit mentioned but not yet implemented in `sherlock hound` mode
- Documented current mindpalace visualization capabilities and enhancement roadmap
- Verified multi-platform CI/CD workflows are properly configured for releases

## Resource Cleanup
- Analyzed `rsc/` directory usage:
  - `rsc/subdomains.list`: Actively used as default wordlist (src/main.rs:154)
  - `rsc/resolvers.txt`: Only used by legacy bash script
  - `rsc/arch_sherlock.zip`: Unused artifact (candidate for removal)

# v2.0.0 (2025-09-30)
- Full rewrite in Rust with modular CLI subcommands: `recon`, `investigate`, `hound`, `report`, `mindpalace`, `doctor`.
- Safe tool orchestration with timeouts, bounded concurrency, and argv-only execution.
- New adapters: Amass, Gobuster DNS, Nmap (XML: host discovery + service scan), httpx, nuclei.
- Feed-forward pipeline: subdomains → targets; services → inferred URLs → nuclei.
- Reporting: consolidated `findings.jsonl` and generated `report.json`, `report.csv`, `report.html`, `report.txt`, plus `services.csv` inventory.
- Mindpalace visualization and `graph.json` export.
- Installers: `scripts/install.sh` (Linux/macOS) and `scripts/install.ps1` (Windows).
- Docker: ready-to-run image with nmap, amass, gobuster, httpx, nuclei.
- CI/CD: multi-arch Docker release; multi-platform binaries (Linux glibc+musl x64/aarch64, macOS x64/arm64, Windows x64/arm64) with asset naming `sherlock-{target}`.
- Docs updated (README) with usage, flags, installers, Docker, CI/CD.

# v2.0.0-dev
- Started conversion to Rust
- Moved `sherlock.sh` and `gift_wrapper.sh` to legacy

# v1.19.6
- Added "defaet rst/icmp" flag to nmap commands
- Added max retries on nmap and set it to 2-3 
- Added nmap Script timeout of 10mins
- Upped the nmap pingsweep min rate to 500
- Moved temp directory from /tmp/ to [cwd](https://www.rapidtables.com/code/linux/linux-current-directory.html)

# v1.19.5
- Added brew and yum support to install script

# v1.19.4
- Removed halberd
- Updated readme
- Added page-fetch and placed it alongside goverview

# v1.19.3
- Added more banners in install script

# v1.19.2
- Changed gospider and dirbpy to load in the target file (its more efficient this way)
- Fixed dirbpy execution, it was a typo which explains why it never ran
- Moved path enum to execute after wappalyzerm this is helpful for feeding the next round fo tools
- Updated install script to reflect the new tools added

# v1.19.1
- added additional tools to install script (e.g., sqlmap, dalfox, uro)
- added sqlmap, goverview and dalfox to sherlock
- fixed some logic errors as well

# v1.18.0
- Added nuclei
- Streamlined code by generating URL tags into a file as opposed to going through nmap results and checking to see if each target had a web server
- Updated install script
- Removed some legacy code

# v1.18.1
- Made changes to the SSH securitty checks
