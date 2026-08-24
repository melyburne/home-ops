#!/bin/sh
# ==============================================================================
# Script: init-storage.sh
# Environment: Alpine (POSIX sh)
# Description: Declarative, idempotent provisioner for Home Assistant internal
#              storage (.storage) configurations. Ensures required settings
#              (HTTP server config, etc.) are present and correct on every boot
#              Uses atomic file transactions to prevent state corruption.
#              Modular design allows easy extension.
# ==============================================================================

# Exit on error (-e), treat unset variables as an error (-u), and fail pipes (-o pipefail)
set -euo pipefail

# ------------------------------------------------------------------------------
# 1. Global Configuration & Environment Initialization
# ------------------------------------------------------------------------------

DIR_STORAGE="/config/.storage"

# Storage Files
FILE_CONFIG_ENTRIES="${DIR_STORAGE}/core.config_entries"
FILE_HTTP_CONFIG="${DIR_STORAGE}/http"

# Environment Variables
HTTP_SERVER_PORT="${HOMEASSISTANT_HTTP_SERVER_PORT:-}"
HTTP_TRUSTED_PROXIES="${HOMEASSISTANT_HTTP_TRUSTED_PROXIES:-}"

# Ensure runtime dependencies are met
if ! command -v jq >/dev/null 2>&1; then
  echo "[SETUP] Installing required dependency: jq..." >&2
  apk add --no-cache -q jq
fi

# Setup automatic cleanup of temporary workspace directories on exit or failure
TEMP_WORKSPACE=$(mktemp -d)
trap 'rm -rf "$TEMP_WORKSPACE"' EXIT

# Ensure required directory structure exists
mkdir -p "$DIR_STORAGE"

# --- Baseline Initializations ---
# Validate or reset baseline configurations if missing or corrupted

# Baseline: http (Reverse Proxy, Port)
if [ ! -f "$FILE_HTTP_CONFIG" ] || ! jq . "$FILE_HTTP_CONFIG" >/dev/null 2>&1; then
  echo "[SETUP] 'http' configuration is missing or invalid. Initializing baseline..." >&2
  echo '{"version": 2, "minor_version": 2, "key": "http", "data": {"stable": null, "pending": null, "yaml_migration_done": true}}' > "$FILE_HTTP_CONFIG"
fi

# ------------------------------------------------------------------------------
# 2. Storage Provisioning Modules (DRY & Isolated)
# ------------------------------------------------------------------------------

generate_entry_id() {
  # Generates a 26-character Crockford Base32 compliant ULID string
  tr -dc '0-9A-GHJKMNP-TV-Z' < /dev/urandom | fold -w 26 | head -n 1
}

# --- Module: HTTP Configuration ---
provision_http_config() {
  local staging_file="${TEMP_WORKSPACE}/http.tmp"
  local existing_port
  local existing_proxies
  
  # Validation guard for HTTP server port
  if [ -z "$HTTP_SERVER_PORT" ]; then
    echo "[ERROR] HOMEASSISTANT_HTTP_SERVER_PORT is missing in the environment. Cannot provision HTTP." >&2
    exit 1
  fi

  # Validation guard for trusted proxies
  if [ -z "$HTTP_TRUSTED_PROXIES" ]; then
    echo "[ERROR] HOMEASSISTANT_HTTP_TRUSTED_PROXIES is missing in the environment. Cannot provision HTTP." >&2
    exit 1
  fi

  # Format the comma-separated environment variable into a valid JSON array
  local proxies_json
  proxies_json=$(echo "$HTTP_TRUSTED_PROXIES" | tr ',' '\n' | jq -R . | jq -s .)

  # Minify proxies for accurate string comparison
  local desired_proxies_min
  desired_proxies_min=$(echo "$proxies_json" | jq -c .)

  # Extract existing state (if any)
  existing_port=$(jq -r '.data.stable.server_port // empty' "$FILE_HTTP_CONFIG")
  existing_proxies=$(jq -c '.data.stable.trusted_proxies // []' "$FILE_HTTP_CONFIG")

  # State Reconciliation
  if [ "$existing_port" = "$HTTP_SERVER_PORT" ] && [ "$existing_proxies" = "$desired_proxies_min" ]; then
    echo "[SKIP] HTTP configuration is already up to date. No changes needed." >&2
    return 0
  else
    echo "[ACTION] Configuration mismatch detected. Injecting HTTP settings (Port: $HTTP_SERVER_PORT)..." >&2

    # Perform atomic injection for the exact HTTP configuration payload
    jq \
      --argjson port "$HTTP_SERVER_PORT" \
      --argjson proxies "$proxies_json" \
      '.data.stable = {
        "use_x_forwarded_for": true,
        "trusted_proxies": $proxies,
        "server_port": $port,
        "ip_ban_enabled": true,
        "cors_allowed_origins": [
          "https://cast.home-assistant.io"
        ],
        "use_x_frame_options": true,
        "ssl_profile": "modern",
        "login_attempts_threshold": -1,
        "created_at": (now | strftime("%Y-%m-%dT%H:%M:%S.000000+00:00")),
        "error": null,
        "error_message": null
      } | .data.pending = null | .data.yaml_migration_done = true' "$FILE_HTTP_CONFIG" > "$staging_file"
  fi

  # Commit transaction to production file atomically
  mv "$staging_file" "$FILE_HTTP_CONFIG"
  echo "[SUCCESS] HTTP configuration provisioned successfully." >&2
}

# ==============================================================================
# 3. Main Execution
# ==============================================================================

echo "[INFO] Starting Home Assistant storage provisioning sequence..." >&2

# Execute modular provisioners
provision_http_config

echo "[SETUP] Applying file ownership (PUID: 0 / PGID: 0) for Home Assistant..." >&2
chown -R 0:0 "$DIR_STORAGE"

echo "[INFO] Storage initialization sequence complete." >&2