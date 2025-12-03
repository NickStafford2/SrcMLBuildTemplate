#!/usr/bin/env bash
# ubuntuInstall.sh
# Install srcML from source on Ubuntu 24.04, using an EXISTING local repo.
# Always installs CMake from Kitware's apt repo (satisfies presets v10).

set -euo pipefail

# ---------- Config ----------
UBUNTU_CODENAME="${UBUNTU_CODENAME:-noble}"

# ---------- Helpers ----------

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

# ---------- Begin ----------

echo "[1/7] Installing system dependencies (sudo required)…"
require_cmd sudo

sudo apt-get update
sudo apt-get install openjdk-11-jdk-headless
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

# 1) prerequisites
sudo apt-get update
sudo apt-get install gpg wget --no-install-recommends -y

# 2) add Kitware signing key (to /usr/share/keyrings)
wget -O- https://apt.kitware.com/keys/kitware-archive-latest.asc |
  sudo gpg --dearmor |
  sudo tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null

# 3) add the Kitware repo for your Ubuntu codename (jammy/noble, etc.)
echo "deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ ${UBUNTU_CODENAME} main" |
  sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null

# 4) update and install cmake
sudo apt-get update
sudo apt-get install kitware-archive-keyring
sudo apt-get update
sudo apt-get install cmake --no-install-recommends -y
