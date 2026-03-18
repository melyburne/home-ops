#!/bin/sh
set -e

# Install required tools and ensure target directory exists
apk add --no-cache curl tar unzip
mkdir -p /apps

install_extension() {
  local REPO="$1"
  local VERSION="$2"
  local APP_NAME="${REPO##*/}" # Extract just the repository name

  echo "Processing $REPO..."

  # Fetch the latest version tag from GitHub API if not explicitly provided
  if [ "$VERSION" = "latest" ] || [ -z "$VERSION" ]; then
    VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  fi
  echo "Target version: $VERSION"

  # Find the download URL for the first valid release asset (.tar.gz or .zip)
  local ASSET_URL=$(curl -s "https://api.github.com/repos/$REPO/releases/tags/$VERSION" | grep '"browser_download_url":' | grep -E '\.(tar\.gz|tgz|zip)"' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')

  if [ -z "$ASSET_URL" ]; then
    echo "Error: Could not find a suitable release asset for $REPO."
    exit 1
  fi

  local FILE_NAME="${ASSET_URL##*/}"
  echo "Downloading $FILE_NAME..."
  curl -sL "$ASSET_URL" -o "/tmp/$FILE_NAME"

  # Extract into a temporary sandbox directory to prevent file spillage
  echo "Extracting $FILE_NAME safely..."
  mkdir -p "/tmp/ext_$APP_NAME"

  if echo "$FILE_NAME" | grep -q '\.zip$'; then
    unzip -q -o "/tmp/$FILE_NAME" -d "/tmp/ext_$APP_NAME/"
  else
    tar -xz --warning=no-unknown-keyword -f "/tmp/$FILE_NAME" -C "/tmp/ext_$APP_NAME/"
  fi

  # Locate the actual root directory of the app by finding its manifest.json
  local MANIFEST_DIR=$(find "/tmp/ext_$APP_NAME" -name "manifest.json" -exec dirname {} \; | head -n 1)

  if [ -n "$MANIFEST_DIR" ]; then
    # Move the cleanly extracted app to its final destination
    rm -rf "/apps/$APP_NAME"
    mv "$MANIFEST_DIR" "/apps/$APP_NAME"
    echo "Successfully installed $APP_NAME into /apps/$APP_NAME"
  else
    echo "Error: manifest.json not found inside $REPO release!"
    exit 1
  fi

  # Clean up temporary artifacts
  rm -rf "/tmp/ext_$APP_NAME" "/tmp/$FILE_NAME"
  echo "----------------------------------------"
}

# --- Main Execution ---

if [ "$#" -eq 0 ]; then
  echo "No extensions specified to install."
  exit 0
fi

# Process each extension passed as an argument (Expected format: "author/repo:version")
for arg in "$@"; do
  REPO="${arg%%:*}"
  VERSION="${arg##*:}"

  # Fallback to 'latest' if no version tag was provided
  if [ "$REPO" = "$VERSION" ]; then
    VERSION="latest"
  fi

  install_extension "$REPO" "$VERSION"
done

echo "Extension initialization complete."