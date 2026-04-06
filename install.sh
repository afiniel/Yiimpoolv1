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
TAG=${TAG:-v2.7.5}

# File paths
YIIMPOOL_VERSION_FILE="/etc/yiimpoolversion.conf"
YIIMPOOL_INSTALL_DIR="$HOME/Yiimpoolv1"

log_error() {
  echo "[ERROR] $1" >&2
}

install_git() {
  if ! command -v git &>/dev/null; then
    echo "[YiimPool] Git not found; installing git..."
    sudo apt-get -q update
    DEBIAN_FRONTEND=noninteractive sudo apt-get -q install -y git < /dev/null
    echo "[YiimPool] Git installed."
  else
    echo "[YiimPool] Git is already installed."
  fi
}

clone_or_update_repo() {
  if [ ! -d "$YIIMPOOL_INSTALL_DIR" ]; then
    echo "[YiimPool] Cloning installer repository (tag ${TAG})..."
    git clone -b "${TAG}" --depth 1 https://github.com/afiniel/Yiimpoolv1 "$YIIMPOOL_INSTALL_DIR" < /dev/null
    echo "[YiimPool] Repository cloned to $YIIMPOOL_INSTALL_DIR"
  else
    echo "[YiimPool] Updating installer checkout to tag ${TAG}..."
    # Ensure repository directory is owned by the invoking user to avoid
    # Git's "dubious ownership" protection when the repo was created as root
    # (for example, from an earlier sudo-based install run).
    if command -v stat >/dev/null 2>&1; then
      repo_owner="$(stat -c '%U' "$YIIMPOOL_INSTALL_DIR" 2>/dev/null || echo "")"
      if [ -n "$repo_owner" ] && [ "$repo_owner" != "$USER" ]; then
        sudo chown -R "$USER":"$USER" "$YIIMPOOL_INSTALL_DIR"
      fi
    else
      # Fallback: attempt to fix ownership recursively without inspection.
      sudo chown -R "$USER":"$USER" "$YIIMPOOL_INSTALL_DIR"
    fi

    cd "$YIIMPOOL_INSTALL_DIR"
    git fetch --depth 1 --force --prune origin tag "${TAG}"
    if ! git checkout -q "${TAG}"; then
      log_error "Failed to update repository to ${TAG}."
      exit 1
    fi
    echo "[YiimPool] Repository updated to ${TAG}."
  fi
}


set_yiimpool_version() {
  echo "VERSION=${TAG}" | sudo tee "$YIIMPOOL_VERSION_FILE" >/dev/null
}


start_installation() {
  echo "[YiimPool] Starting install/start.sh (first-time wizard or main menu)"
  bash "$YIIMPOOL_INSTALL_DIR/install/start.sh"
}

install_git
clone_or_update_repo
set_yiimpool_version
start_installation
