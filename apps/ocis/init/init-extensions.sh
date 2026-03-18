#!/bin/sh
set -e # Exit immediately if a command exits with a non-zero status

apk add --no-cache curl tar unzip
mkdir -p /apps

# Define the reusable installation function
install_extension() {
  local REPO="$1"
  local VERSION="$2"
  
  echo "Processing $REPO..."
  
  if [ "$VERSION" = "latest" ] || [ -z "$VERSION" ]; then
    VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
  fi
  echo "Target version: $VERSION"
  
  local ASSET_URL=$(curl -s "https://api.github.com/repos/$REPO/releases/tags/$VERSION" | grep '"browser_download_url":' | grep -E '\.(tar\.gz|tgz|zip)"' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
  
  if [ -z "$ASSET_URL" ]; then
    echo "Error: Could not find a suitable release asset for $REPO."
    exit 1
  fi
  
  local FILE_NAME="${ASSET_URL##*/}"
  echo "Downloading $FILE_NAME..."
  curl -sL "$ASSET_URL" -o "/tmp/$FILE_NAME"
  
  echo "Extracting $FILE_NAME to /apps..."
  if echo "$FILE_NAME" | grep -q '\.zip$'; then
    unzip -q -o "/tmp/$FILE_NAME" -d /apps/
  else
    tar -xz --warning=no-unknown-keyword -f "/tmp/$FILE_NAME" -C /apps/
  fi
  
  rm "/tmp/$FILE_NAME"
  echo "Successfully installed $REPO."
  echo "----------------------------------------"
}

# --- Process Arguments ---

# Check if any arguments were passed
if [ "$#" -eq 0 ]; then
  echo "No extensions specified to install."
  exit 0
fi

# Loop through all arguments passed to the script
for arg in "$@"; do
  # Extract repo and version using parameter expansion (splits by ':')
  REPO="${arg%%:*}"
  VERSION="${arg##*:}"
  
  # If no version was provided (e.g., just "author/repo"), default it to latest
  if [ "$REPO" = "$VERSION" ]; then
    VERSION="latest"
  fi

  # Call the install function
  install_extension "$REPO" "$VERSION"
done

echo "Extension initialization complete."