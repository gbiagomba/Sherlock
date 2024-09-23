![alt tag](img/Firefly%20Create%20a%20sleek%20and%20professional%20logo%20inspired%20by%20the%20art%20style%20of%20the%20Sherlock%20Holmes%20detect%20(3).jpg)

# Sherlock - Web Inspector

![GitHub](https://img.shields.io/github/license/Achiefs/fim) [![Tip Me via PayPal](https://img.shields.io/badge/PayPal-tip_me-green?logo=paypal)](paypal.me/gbiagomba)

## Background/Lore
Sherlock is a powerful recon automation tool designed to streamline the early phases of web application security assessments. Named after the legendary detective, it automates tasks like target scanning, excluding specific hosts, and more. With Sherlock, security professionals can perform their investigations efficiently while focusing on critical vulnerabilities.

## Features
- Single target scanning (`--target` or `-t`).
- Multi-target scanning from file (`--target-file` or `-f`).
- Ability to exclude specific targets from scans (`--exclude` or `-e`).
- Cross-platform support (Linux, macOS, Windows).
- Efficient automation of recon tasks like port scanning (using nmap).
- Open-source and extendable.

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

## Usage

### Examples
- **Scan a single target**:
  ```bash
  ./sherlock --target 192.168.1.1
  ```
- **Scan multiple targets from a file**:
  ```bash
  ./sherlock --target-file targets.txt
  ```
- **Scan multiple targets while excluding specific ones**:
  ```bash
  ./sherlock --target-file targets.txt --exclude exclude.txt
  ```

### Using the `Makefile`
- **Build the project**:
  ```bash
  make build
  ```
- **Run the project**:
  ```bash
  make run
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
- [ ] Add multi-thread parallel processing
- [ ] Limit amount of data stored to disk, use more variables
- [ ] Add Tenable API scanning/support [Queued]
- [ ] Add joomscan & droopescan scan [Queued]
- [ ] Add function to check if the script is running on latest version [inprogress]
- [ ] Add exclusion list config file
- [ ] Add flag support
- [x] Convert sherlock to rust lang

## Contributing
We welcome contributions! Please follow the standard GitHub workflow:
1. Fork the repository.
2. Create a new feature branch.
3. Submit a pull request after testing your changes.

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
