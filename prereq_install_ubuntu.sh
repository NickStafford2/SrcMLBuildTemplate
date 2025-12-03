#!/usr/bin/env bash
# prereqInstallUbuntu.sh
# Install all the packages needed to install srcML from source on Ubuntu 24.04.
# Always installs CMake from Kitware's apt repo.

set -euo pipefail

# ---------- Config ----------
UBUNTU_CODENAME="${UBUNTU_CODENAME:-noble}"

# ---------- Helpers ----------

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "✗ Missing required command: $1" >&2
    exit 1
  fi
}

# ---------- Begin ----------

echo ""
echo "=== [1/7] Checking prerequisites ==="
require_cmd sudo
echo "✓ sudo is available"

echo ""
echo "=== [2/7] Installing system dependencies ==="
sudo apt-get update -y
echo "✓ apt cache updated"

sudo apt-get install openjdk-11-jdk-headless -y
echo "✓ OpenJDK 11 installed"

sudo apt-get install --no-install-recommends -y \
  ca-certificates \
  ccache \
  cpio \
  curl \
  dpkg-dev \
  file \
  g++ \
  git \
  libarchive-dev \
  libcurl4-openssl-dev \
  libxml2-dev \
  libxml2-utils \
  libxslt1-dev \
  make \
  man \
  ninja-build \
  tree \
  valgrind \
  zip
echo "✓ Core build tools and libraries installed"

echo ""
echo "=== [3/7] Installing prerequisites for Kitware repo ==="
sudo apt-get update -y
sudo apt-get install gpg wget --no-install-recommends -y
echo "✓ gpg and wget installed"

echo ""
echo "=== [4/7] Adding Kitware signing key ==="
wget -O- https://apt.kitware.com/keys/kitware-archive-latest.asc |
  sudo gpg --dearmor |
  sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null
echo "✓ Kitware GPG key installed"

echo ""
echo "=== [5/7] Adding Kitware apt repository (${UBUNTU_CODENAME}) ==="
echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ ${UBUNTU_CODENAME} main" |
  sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null
echo "✓ Kitware repo added"

echo ""
echo "=== [6/7] Updating apt and installing repository key package ==="
sudo apt-get update -y
sudo apt-get install kitware-archive-keyring -y
echo "✓ kitware-archive-keyring installed"

echo ""
echo "=== [7/7] Installing latest CMake from Kitware ==="
sudo apt-get update -y
sudo apt-get install cmake --no-install-recommends -y
echo "✓ CMake installed from Kitware repo"

echo ""
echo "=== Installation Complete ==="
echo "Ubuntu dependencies + Kitware CMake successfully installed."
echo ""
