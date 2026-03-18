#!/bin/sh
set -e

# ==============================================================================
# Script: init-extensions.sh
# Environment: BusyBox / Alpine (POSIX sh)
# Description: Automatically downloads and installs oCIS web extensions from
#              GitHub releases. Extracts archives and places valid extensions
#              (identified by manifest.json) into the /apps directory.
#
# Usage: ./init-extensions.sh [author/repo:version] ...
# Example: ./init-extensions.sh LukasHirt/web-app-excalidraw:latest mschlachter/ocis-app-tokens:1.0.0
# ==============================================================================

# Ensure the target installation directory exists
mkdir -p /apps

# ------------------------------------------------------------------------------
# Function: install_extension
# Description: Fetches, downloads, extracts, and installs a single extension.
# Arguments:
#   $1 - GitHub Repository (e.g., "author/repo")
#   $2 - Target Version (e.g., "1.0.0" or "latest")
# ------------------------------------------------------------------------------
install_extension() {
  local REPO="$1"
  local VERSION="$2"
  local APP_NAME="${REPO##*/}" # Extract only the repository name

  echo "Processing ${REPO}..."

  # 1. Determine Target Version
  # If version is "latest" or empty, query the GitHub API to find the newest release tag.
  if [ "$VERSION" = "latest" ] || [ -z "$VERSION" ]; then
    VERSION=$(wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" | \
              grep '"tag_name":' | \
              sed -E 's/.*"([^"]+)".*/\1/')
  fi
  echo "Target version: ${VERSION}"

  # 2. Locate Download URL
  # Query the specific release and extract the URL for the first valid archive file.
  local ASSET_URL=$(wget -qO- "https://api.github.com/repos/${REPO}/releases/tags/${VERSION}" | \
                    grep '"browser_download_url":' | \
                    grep -E '\.(tar\.gz|tgz|zip)"' | \
                    head -n 1 | \
                    sed -E 's/.*"([^"]+)".*/\1/')

  if [ -z "$ASSET_URL" ]; then
    echo "Error: Could not find a suitable .zip or .tar.gz release asset for ${REPO}."
    exit 1
  fi

  # 3. Download the Asset
  local FILE_NAME="${ASSET_URL##*/}"
  echo "Downloading ${FILE_NAME}..."
  wget -qO "/tmp/${FILE_NAME}" "$ASSET_URL"

  # 4. Extract the Asset
  # Extract into an isolated temporary directory to prevent file conflicts
  echo "Extracting ${FILE_NAME}..."
  mkdir -p "/tmp/ext_${APP_NAME}"

  if echo "$FILE_NAME" | grep -q '\.zip$'; then
    unzip -q -o "/tmp/${FILE_NAME}" -d "/tmp/ext_${APP_NAME}/"
  else
    tar -xzf "/tmp/${FILE_NAME}" -C "/tmp/ext_${APP_NAME}/"
  fi

  # 5. Install the Application
  # Archives often contain nested root folders. We dynamically find the correct
  # root by locating the app's 'manifest.json' file.
  local MANIFEST_DIR=$(find "/tmp/ext_${APP_NAME}" -name "manifest.json" -exec dirname {} \; | head -n 1)

  if [ -n "$MANIFEST_DIR" ]; then
    # Clear any existing installation and move the newly extracted app into place
    rm -rf "/apps/${APP_NAME}"
    mv "$MANIFEST_DIR" "/apps/${APP_NAME}"
    echo "Successfully installed ${APP_NAME} into /apps/${APP_NAME}"
  else
    echo "Error: manifest.json not found inside ${REPO} release archive!"
    exit 1
  fi

  # 6. Cleanup
  rm -rf "/tmp/ext_${APP_NAME}" "/tmp/${FILE_NAME}"
  echo "----------------------------------------"
}


# ==============================================================================
# Main Execution
# ==============================================================================

# Abort cleanly if no arguments are provided
if [ "$#" -eq 0 ]; then
  echo "No extensions specified to install."
  exit 0
fi

# Iterate over all provided arguments
for arg in "$@"; do
  # Split argument into REPO and VERSION based on the colon ':' delimiter
  REPO="${arg%%:*}"
  VERSION="${arg##*:}"

  # Fallback to 'latest' if the user omitted the version tag (e.g., just "author/repo")
  if [ "$REPO" = "$VERSION" ]; then
    VERSION="latest"
  fi

  # Execute installation
  install_extension "$REPO" "$VERSION"
done

echo "Extension initialization complete."