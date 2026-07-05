#!/bin/bash
set -e

echo "=== Updating system and installing build tools ==="
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq linux-headers-$(uname -r) build-essential dkms

echo "=== Installing NVIDIA drivers and CUDA ==="
# Install NVIDIA driver and CUDA toolkit from Ubuntu repos
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nvidia-driver-550 nvidia-utils-550 nvidia-cuda-toolkit

echo "=== Setup complete. Rebooting may be needed for drivers ==="
nvidia-smi 2>/dev/null || echo "Driver installed but nvidia-smi not found yet (may need reboot or module load)"

echo "=== Installing Python packages ==="
pip3 install --upgrade pip
pip3 install torch torchaudio --index-url https://download.pytorch.org/whl/cu118
pip3 install uv

echo "=== Done ==="