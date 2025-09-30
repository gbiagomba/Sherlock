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
