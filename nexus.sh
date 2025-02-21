#!/bin/bash
#curl -sSL https://raw.githubusercontent.com/doedja/anyscripts/refs/heads/main/nexus.sh | bash
#curl https://cli.nexus.xyz/ | sh

set -e  # Exit if a command fails
set -o pipefail  # Catch errors in piped commands

echo "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive  # Prevent interactive prompts
sudo apt update && sudo apt upgrade -y || true  # Allow script to continue even if nothing upgrades

echo "Installing dependencies..."
sudo apt install -y build-essential pkg-config libssl-dev git-all curl unzip autoconf automake libtool make g++ || true

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
protoc --version || { echo "Protobuf installation failed!"; exit 1; }

echo "Installing Nexus CLI..."
curl https://cli.nexus.xyz/ | sh || { echo "Nexus CLI installation failed!"; exit 1; }

echo "All done!"
