#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail  # Catch errors in piped commands

echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

echo "Installing dependencies..."
sudo apt install -y build-essential pkg-config libssl-dev git-all

sudo appt install zip

echo "Downloading Protobuf (protoc) v3.15.8..."
curl -OL https://github.com/google/protobuf/releases/download/v3.15.8/protoc-3.15.8-linux-x86_64.zip

echo "Unzipping Protobuf..."
unzip protoc-3.15.8-linux-x86_64.zip -d protoc3

echo "Moving Protobuf binaries to /usr/local/bin/..."
sudo mv protoc3/bin/* /usr/local/bin/

echo "Moving Protobuf includes to /usr/local/include/..."
sudo mv protoc3/include/* /usr/local/include/

echo "Cleaning up downloaded files..."
rm -rf protoc3 protoc-3.15.8-linux-x86_64.zip

echo "Installing Nexus CLI..."
curl https://cli.nexus.xyz/ | sh

echo "Installation complete! Verifying installations..."

echo -n "Protobuf version: "
protoc --version

echo -n "Nexus CLI check: "
nexus --help || echo "Nexus CLI installation failed."

echo "All done!"
