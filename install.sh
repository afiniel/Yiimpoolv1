#!/usr/bin/env bash

#########################################################
#
# This script performs the following tasks:
# 1. Sets the version tag for the Yiimpoolv1 installation.
# 2. Checks and installs git if it's not already installed.
# 3. Clones the Yiimpoolv1 installer repository from GitHub.
# 4. Updates the repository to the specified version tag if necessary.
# 5. Starts the Yiimpoolv1 installation process.
#
# Author: Afiniel
# Date: 2024-07-13
#
#########################################################

# Default version tag if not provided as environment variable
TAG=${TAG:-v2.5.9}

# File paths
YIIMPOOL_VERSION_FILE="/etc/yiimpoolversion.conf"
YIIMPOOL_INSTALL_DIR="$HOME/Yiimpoolv1"

log_error() {
  echo "[ERROR] $1" >&2
}

install_git() {
  if ! command -v git &>/dev/null; then
    log_error "Git is not installed. Installing git..."
    sudo apt-get -q update
    DEBIAN_FRONTEND=noninteractive sudo apt-get -q install -y git < /dev/null
    echo "Git installed."
  else
    echo "Git is already installed."
  fi
}

clone_or_update_repo() {
  if [ ! -d "$YIIMPOOL_INSTALL_DIR" ]; then
    echo "Cloning Yiimpool Installer ${TAG}..."
    git clone -b "${TAG}" --depth 1 https://github.com/afiniel/Yiimpoolv1 "$YIIMPOOL_INSTALL_DIR" < /dev/null
    echo "Repository cloned."
  else
    echo "Updating Yiimpool Installer to ${TAG}..."
    cd "$YIIMPOOL_INSTALL_DIR"
    sudo chown -R "$USER" "$YIIMPOOL_INSTALL_DIR/.git/"
    git fetch --depth 1 --force --prune origin tag "${TAG}"
    if ! git checkout -q "${TAG}"; then
      log_error "Failed to update repository to ${TAG}."
      exit 1
    fi
    echo "Repository updated."
  fi
}


set_yiimpool_version() {
  echo "VERSION=${TAG}" | sudo tee "$YIIMPOOL_VERSION_FILE" >/dev/null
}


start_installation() {
  bash "$YIIMPOOL_INSTALL_DIR/install/start.sh"
}

install_git
clone_or_update_repo
set_yiimpool_version
start_installation
