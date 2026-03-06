#!/bin/bash
set -e

# -----------------------------------------------------------------------------
# Home-Ops Security Hardening Script
# -----------------------------------------------------------------------------

# 1. Safety Check: Prevent running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "❌ Error: This script should NOT be run as root."
    echo "   Run it as your standard user to secure your own files."
    exit 1
fi

echo "🔒 Locking down file permissions..."

# 2. Secure Secrets (.env files)
# Find all .env files recursively and set to 600 (RW Owner Only)
find . -name ".env" -type f -print0 | xargs -0 chmod 600
echo "   ✅ .env files secured (600)"

# 3. Secure Sensitive Data Files
# Note: While Docker Init containers fix these at runtime, we lock them down
# here to ensure they are secure "at rest" on the host filesystem.
SENSITIVE_FILES=(
    "core/traefik/data/acme.json"
    "core/traefik/traefik_dynamic.yml"
    "apps/roundcube/config/config.inc.php"
    "apps/roundcube/config/nonroot-custom-php-config.iniconfig.inc.php"
)

for file in "${SENSITIVE_FILES[@]}"; do
    if [ -f "$file" ]; then
        chmod 600 "$file"
        echo "   ✅ $file secured (600)"
    fi
done

echo "🎉 Security hardening complete."