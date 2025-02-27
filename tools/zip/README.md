# Ziper Tool

<div align="center">

![Development Tools](https://img.shields.io/badge/Development-Tools-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-lightgrey)

[English](README.md) | [简体中文](README-zh.md)

</div>

A fast compression tool written in Rust.

## Features
- Fast compression of files and directories
- Support for ignore patterns with glob syntax
- Automatic output directory creation
- Cross-platform compatibility
- Flexible command line interface
- Quiet and verbose output modes

## Installation

### Quick Install

#### Unix-like Systems (macOS, Linux)
```bash
curl -sSL https://raw.githubusercontent.com/jwyGithub/development-tools/main/tools/zip/install/install.sh | bash
```

#### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/jwyGithub/development-tools/main/tools/zip/install/install.ps1 | iex
```

### Manual Installation from Source
```bash
# Clone the repository
git clone https://github.com/jwyGithub/development-tools.git
cd development-tools/tools/zip

# Build the project
cargo build --release

# Optional: Install globally
sudo cp target/release/ziper /usr/local/bin/  # Unix-like systems
# or copy to a directory in your PATH for Windows
```

## Usage

```bash
# Basic usage - compress a directory to [dirname].zip
ziper dist

# Specify output file name
ziper dist output.zip

# Specify output directory and filename
ziper dist path/to/output.zip

# Ignore specific patterns (supports glob syntax)
ziper dist --ignore "node_modules,.git,*.zip,*.tar"

# Quiet mode (suppress output)
ziper dist -q

# Verbose mode (show detailed output)
ziper dist -v

# Upgrade to latest version
ziper --upgrade

# Remove the program
ziper --remove
```

### Command Line Options

```
Usage: ziper [OPTIONS] <SOURCE> [OUTPUT]

Arguments:
  <SOURCE>  Source directory or file to compress
  [OUTPUT]  Output zip file path (optional, defaults to source name with .zip extension)

Options:
  -i, --ignore <PATTERNS>  Patterns to ignore (comma-separated)
  -q, --quiet             Suppress output
  -v, --verbose          Show detailed output
  -h, --help            Print help
  -V, --version         Print version
  --upgrade            Upgrade to latest version
  --remove            Remove the program
```

### Ignore Patterns
The `--ignore` option accepts comma-separated glob patterns:
- `node_modules` - Ignore node_modules directory
- `.git` - Ignore .git directory
- `*.zip` - Ignore all zip files
- `*.tar` - Ignore all tar files

Patterns are applied to both files and directories at any depth in the directory tree.

### Output Path
- If no output path is specified, creates `[source_name].zip` in the current directory
- If output path is specified, creates the file at that location
- Automatically creates any missing directories in the output path

## Development

### Prerequisites
- Rust 1.70 or higher
- Cargo (Rust's package manager)

### Building from source
```bash
cargo build        # Debug build
cargo build --release  # Release build
```

### Running tests
```bash
cargo test        # Run all tests
cargo test -- --nocapture  # Run tests with output
```

## License
This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details. 
