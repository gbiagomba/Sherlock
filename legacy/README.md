# Legacy

This folder contains the original Bash-based implementation of Sherlock and supporting scripts. It is kept for historical reference, comparison, and potential migration of niche behaviors not yet ported to the Rust orchestrator.

What’s here
- `sherlock.sh`: Original recon orchestrator (Bash) calling many external tools.
- `install.sh`, `uninstall.sh`: Legacy installers for Linux-based environments.
- `gift_wrapper.sh`: Helper sourced by `sherlock.sh` for banners/formatting.
- `sherlock.zip`: Archived artifact of older assets/tools.

Status
- Deprecated: These scripts are not actively maintained and may reference outdated tool names, flags, or package managers.
- Not used by the new CLI: The Rust-based binary in `src/` replaces these scripts.
- Kept read-only: Please avoid modifying legacy scripts unless you are extracting logic to port.

Security and portability notes
- Running the legacy scripts can install or invoke numerous third-party tools. Use in a disposable environment or container.
- Expect OS-specific assumptions (e.g., Debian/Kali services, `apt`, `service` commands).
- Prefer the Rust CLI and its adapters for safer, structured execution.

If you must run them
- Use a Linux VM/container, review the scripts first, then:
  - `chmod +x legacy/*.sh`
  - `sudo ./legacy/install.sh` (installs a large set of tools)
  - `sudo ./legacy/sherlock.sh <targets-file> <project-name>`

Migration guidance
- When porting functionality, prefer structured outputs (JSON/CSV) and avoid `sh -c`.
- Add new adapters under `src/tools/`, normalize to the `Finding` model, and extend reporting as needed.

