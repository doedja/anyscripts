#!/bin/bash
#curl -sSL https://raw.githubusercontent.com/doedja/anyscripts/refs/heads/main/nexus.sh | bash
#curl https://cli.nexus.xyz/ | sh

set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail  # Catch errors in piped commands

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing dependencies..."
sudo apt install -y build-essential pkg-config libssl-dev git-all curl unzip

echo "Installing Rust (required for Cargo)..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Detect which shell the user is using
SHELL_CONFIG=""

if [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
fi

# Reload shell configuration to apply Rust installation
if [ -n "$SHELL_CONFIG" ]; then
    echo "Reloading shell environment from $SHELL_CONFIG..."
    source "$SHELL_CONFIG"
else
    echo "Warning: Could not find a shell profile file to reload environment variables."
fi

# Verify Rust installation
if ! command -v cargo &> /dev/null; then
    echo "Error: Cargo (Rust) is not installed properly. Please restart your terminal and try again."
    exit 1
fi

echo "Rust and Cargo installed successfully."

echo "Removing any existing Protobuf (protoc) installation..."
sudo rm -rf /usr/local/bin/protoc /usr/local/include/google /usr/local/lib/libprotobuf* /usr/local/lib/pkgconfig/protobuf* ~/.protobuf*

echo "Ensuring Protobuf directory is clean..."
rm -rf protoc3 protoc-3.15.8-linux-x86_64.zip

echo "Downloading Protobuf (protoc) v3.15.8..."
curl -OL https://github.com/google/protobuf/releases/download/v3.15.8/protoc-3.15.8-linux-x86_64.zip

echo "Unzipping Protobuf (forcing overwrite)..."
unzip -o protoc-3.15.8-linux-x86_64.zip -d protoc3

echo "Moving Protobuf binaries to /usr/local/bin/..."
sudo mv protoc3/bin/* /usr/local/bin/

echo "Moving Protobuf includes to /usr/local/include/..."
sudo mv protoc3/include/* /usr/local/include/

echo "Cleaning up downloaded files..."
rm -rf protoc3 protoc-3.15.8-linux-x86_64.zip

echo "Installing Nexus CLI..."
curl https://cli.nexus.xyz/ | sh

echo "Verifying installations..."

echo -n "Rust version: "
rustc --version

echo -n "Cargo version: "
cargo --version

echo -n "Protobuf version: "
protoc --version

echo -n "Nexus CLI check: "
nexus --help || echo "Nexus CLI installation failed."

echo "All done!"
