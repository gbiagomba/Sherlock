
# Sherlock

## Background/Lore
Sherlock is a tool designed to automate the reconnaissance phases of a web application assessment. It simplifies the process by automating target scanning and filtering out unnecessary steps, making it easier for security professionals to focus on the critical aspects of their assessments.

## Features
- Supports single or multiple targets.
- Exclusion of specified targets from scans.
- Built-in concurrency and efficient use of system resources.

## Installation

### Using Cargo
You can install Sherlock directly using Cargo with the following command:
```bash
cargo install --path .
```

### Compiling from source
To compile Sherlock from source, ensure you have Rust installed and run:
```bash
cargo build --release
```

## Usage

### Examples
- Scan a single target:
  ```bash
  ./sherlock --target 192.168.1.1
  ```
- Scan multiple targets from a file:
  ```bash
  ./sherlock --target-file targets.txt
  ```
- Exclude targets from a scan using an exclusion list:
  ```bash
  ./sherlock --target-file targets.txt --exclude exclude.txt
  ```

### Using the `Makefile`
- To build the project:
  ```bash
  make build
  ```
- To run the project:
  ```bash
  make run
  ```
- To clean the project:
  ```bash
  make clean
  ```

## Contributing
Contributions are welcome! Please follow the [Code of Conduct](CODE_OF_CONDUCT.md) and submit pull requests or issues on GitHub.

## License
Sherlock is licensed under the GPL-3.0 License. See the [LICENSE](LICENSE) file for details.
