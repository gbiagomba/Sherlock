Sherlock Compatibility Set (Initial)

This document tracks pinned versions for reproducible builds and predictable outputs. Adjust as upstream projects evolve.

Rust toolchain
- rustc/cargo: 1.77.2 (rust-toolchain.toml)
- Components: rustfmt, clippy

External tools (proposed pins)
- nmap: 7.94
- amass: v3.25.0
- gobuster: v3.6.0
- httpx: v1.6.5
- nuclei: v3.2.6
- Go: 1.22.x (for building httpx/nuclei if not installed via package manager)

Rationale
- Chosen based on widely adopted stable tags with active maintenance and compatibility with Sherlock’s parsers. These can be revised after CI validation against your environments.

Maintenance policy
- Quarterly review or on critical CVEs.
- CI jobs:
  - security-and-smoke: runs cargo audit weekly and builds/tests on ubuntu/macos/windows.
  - release workflows produce SHA256SUMS and signed artifacts.

Notes
- Cargo dependencies are pinned via Cargo.lock and audited via cargo-audit.
- Docker image currently installs latest httpx/nuclei via Go; version pinning there is deferred until explicit approval (scope C).
