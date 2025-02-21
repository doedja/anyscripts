#!/bin/bash
#curl -sSL https://raw.githubusercontent.com/doedja/anyscripts/refs/heads/main/nexus.sh | bash
#curl https://cli.nexus.xyz/ | sh

set -e  # Exit immediately if a command fails
set -o pipefail  # Catch errors in piped commands

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing dependencies..."
sudo apt install -y build-essential pkg-config libssl-dev git-all curl unzip autoconf automake libtool make g++

echo "Installing Rust (required for Cargo)..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Detect the shell type
USER_SHELL=$(basename "$SHELL")

# Ensure Rust is available in the current session
if [[ -f "$HOME/.cargo/env" ]] && [[ "$USER_SHELL" != "fish" ]]; then
    echo "Applying Rust environment for Bash/Zsh..."
    . "$HOME/.cargo/env" || true
elif [[ -f "$HOME/.cargo/env.fish" ]] && [[ "$USER_SHELL" == "fish" ]]; then
    echo "Applying Rust environment for Fish..."
    source "$HOME/.cargo/env.fish" || true
else
    echo "Warning: Rust environment file not found. Please restart your shell if Cargo is not recognized."
fi

# Verify Rust installation
if ! command -v cargo &> /dev/null; then
    echo "Error: Cargo (Rust) is not installed properly. Please restart your terminal and try again."
    exit 1
fi

echo "Rust and Cargo installed successfully."

# Detect system architecture
ARCH=$(uname -m)

# Check if Protobuf is installed and meets the version requirement (3.15+)
PROTOC_VERSION=$(protoc --version 2>/dev/null | awk '{print $2}')
PROTOC_MIN_VERSION="3.15.0"

if [[ -n "$PROTOC_VERSION" && "$(printf '%s\n' "$PROTOC_MIN_VERSION" "$PROTOC_VERSION" | sort -V | tail -1)" == "$PROTOC_VERSION" ]]; then
    echo "Protobuf $PROTOC_VERSION is already installed (>= 3.15.0). Skipping reinstallation."
else
    echo "Removing any existing Protobuf (protoc) installation..."
    sudo rm -rf /usr/local/bin/protoc /usr/local/include/google /usr/local/lib/libprotobuf* /usr/local/lib/pkgconfig/protobuf* ~/.protobuf*

    if [[ "$ARCH" == "aarch64" ]]; then
        echo "Detected architecture: aarch64 (ARM64). Installing Protobuf 3.15.8 using precompiled binary..."

        cd /usr/local/src
        wget https://github.com/protocolbuffers/protobuf/releases/download/v3.15.8/protoc-3.15.8-linux-aarch_64.zip
        unzip -o protoc-3.15.8-linux-aarch_64.zip -d protoc3
        sudo mv protoc3/bin/* /usr/local/bin/
        sudo mv protoc3/include/* /usr/local/include/
        rm -rf protoc3 protoc-3.15.8-linux-aarch_64.zip

    else
        echo "Detected architecture: x86_64. Compiling Protobuf from source..."

        cd /usr/local/src
        sudo git clone --recurse-submodules -b v3.15.8 https://github.com/protocolbuffers/protobuf.git
        cd protobuf
        sudo ./autogen.sh
        sudo ./configure
        sudo make -j$(nproc)
        sudo make install
        sudo ldconfig
    fi
fi

echo "Verifying Protobuf installation..."
protoc --version

echo "Installing Nexus CLI..."
curl https://cli.nexus.xyz/ | sh

echo "All done!"
