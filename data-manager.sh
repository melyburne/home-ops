#!/usr/bin/env bash

# ==============================================================================
# Home-Ops Data Manager (Backup & Restore)
# ==============================================================================
# Description: Safely backs up and restores all dynamically found 'data'
#              directories across the modular Docker Compose stack.
# Note: Performs "Cold Backups" by stopping containers first. Restores perform
#       a "Clean Slate" wipe to prevent merging corrupted data with backups.
# Log Output: /var/log/home-ops-data-manager.log
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. STRICT MODE & GLOBAL VARIABLES
# ------------------------------------------------------------------------------
# set -e: Exit immediately if a command exits with a non-zero status.
# set -u: Treat unset variables as an error.
# set -o pipefail: Return pipeline status as the last non-zero command status.
set -euo pipefail

# Project and Backup Variables
PROJECT_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVE_NAME="home-ops-backup_${TIMESTAMP}.tar.gz"

# Standardized Administrative Log Location
LOG_FILE="/var/log/home-ops-data-manager.log"

# ------------------------------------------------------------------------------
# 2. HELPER FUNCTIONS (Clean Code / DRY)
# ------------------------------------------------------------------------------

# Centralized Logging Function
# Handles both colorized terminal output and plain-text file logging with timestamps.
_log() {
    local level="$1"
    local color="$2"
    local message="$3"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # 1. Print to console (Colorized)
    if [ "$level" = "ERROR" ]; then
        echo -e "${color}[${level}]\e[0m ${message}" >&2
    else
        echo -e "${color}[${level}]\e[0m ${message}"
    fi

    # 2. Print to log file (Plain text with timestamp)
    # Only attempt to write if running as root to avoid permission denied errors
    if [ "$EUID" -eq 0 ]; then
        echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
    fi
}

# Wrapper functions for specific log levels
log_info()    { _log "INFO"    "\e[34m" "$1"; }
log_success() { _log "SUCCESS" "\e[32m" "$1"; }
log_error()   { _log "ERROR"   "\e[31m" "$1"; }
log_warn()    { _log "WARN"    "\e[33m" "$1"; }

# Ensures the script is run with root privileges (required for file ownership/permissions)
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root to preserve file permissions."
        log_error "Please run with: sudo $0 $*"
        exit 1
    fi
}

# Displays how to use the script
show_usage() {
    cat << EOF
Usage: $0 <command> <target_path>

Commands:
  backup  <dest_dir>      Stops containers and backs up all data dirs to <dest_dir>
  restore <archive_file>  Stops containers, WIPES current data, and extracts <archive_file>

Examples:
  sudo $0 backup /mnt/external_drive/backups
  sudo $0 restore /mnt/external_drive/backups/home-ops-backup_2023-10-25_14-00-00.tar.gz
EOF
    exit 1
}

# Dynamically finds all directories named 'data' within the project, excluding .git
get_data_dirs() {
    find "${PROJECT_ROOT}" -type d -name "data" -not -path "*/\.git/*"
}

# Safely brings down the docker compose stack, teeing output to the log file
stop_stack() {
    log_info "Stopping Docker Compose stack to ensure data consistency..."
    cd "${PROJECT_ROOT}"
    # 2>&1 merges stderr into stdout, tee -a appends it to both screen and log file
    docker compose down 2>&1 | tee -a "$LOG_FILE"
}

# Brings the docker compose stack back up, teeing output to the log file
start_stack() {
    log_info "Starting Docker Compose stack..."
    cd "${PROJECT_ROOT}"
    docker compose up -d 2>&1 | tee -a "$LOG_FILE"
}

# ------------------------------------------------------------------------------
# 3. CORE LOGIC: BACKUP
# ------------------------------------------------------------------------------
do_backup() {
    local DEST_DIR="$1"

    if [ ! -d "$DEST_DIR" ]; then
        log_error "Destination directory '$DEST_DIR' does not exist."
        exit 1
    fi

    local DEST_FILE="${DEST_DIR}/${ARCHIVE_NAME}"

    # Initialize a new section in the log file
    echo -e "\n========================================" >> "$LOG_FILE"
    log_info "INITIATING BACKUP PROCESS"

    stop_stack

    log_info "Creating backup archive at: ${DEST_FILE}"

    # Switch to project root to keep relative paths clean in the tarball
    cd "${PROJECT_ROOT}"

    # Generate an array of target directories to back up
    local TARGETS=()
    while IFS= read -r dir; do
        TARGETS+=("${dir#${PROJECT_ROOT}/}")
    done < <(get_data_dirs)

    # Explicitly backup the .env file
    if [ -f ".env" ]; then
        TARGETS+=(".env")
    fi

    # Create the compressed tarball preserving permissions
    # Send verbose output (-v) to the log file using tee
    tar -czpvf "${DEST_FILE}" "${TARGETS[@]}" 2>&1 | tee -a "$LOG_FILE"

    start_stack

    log_success "Backup completed successfully: ${DEST_FILE}"
}

# ------------------------------------------------------------------------------
# 4. CORE LOGIC: RESTORE
# ------------------------------------------------------------------------------

# Safely wipes existing state so the restore doesn't merge with corrupted/new files
wipe_current_state() {
    log_info "Wiping existing data directories to ensure a clean slate..."
    cd "${PROJECT_ROOT}"

    # 1. Wipe all 'data' directories dynamically
    while IFS= read -r dir; do
        # Defensive check to ensure we only delete directories
        if [ -d "$dir" ]; then
            log_info "Deleting folder: ${dir#${PROJECT_ROOT}/}"
            rm -rf "$dir"
        fi
    done < <(get_data_dirs)

    # 2. Wipe the .env file (it will be recreated from the backup)
    if [ -f ".env" ]; then
        log_info "Deleting file: .env"
        rm -f ".env"
    fi

    log_success "Clean slate achieved. Ready for extraction."
}

do_restore() {
    local ARCHIVE_FILE="$1"

    if [ ! -f "$ARCHIVE_FILE" ]; then
        log_error "Archive file '$ARCHIVE_FILE' does not exist."
        exit 1
    fi

    # Safety confirmation to prevent accidental data loss
    echo -e "\e[31m[CRITICAL WARNING]\e[0m This will COMPLETELY DELETE all current data directories and replace them with the backup."
    read -p "Are you absolutely sure you want to proceed? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        # Use simple echo here because we don't need to log user aborts to the system log
        echo -e "\e[34m[INFO]\e[0m Restore aborted by user."
        exit 0
    fi

    # Initialize a new section in the log file
    echo -e "\n========================================" >> "$LOG_FILE"
    log_info "INITIATING RESTORE PROCESS"

    stop_stack

    # Wipe the existing state to prevent folder merging
    wipe_current_state

    log_info "Extracting backup from: ${ARCHIVE_FILE}"
    cd "${PROJECT_ROOT}"

    # Extract preserving permissions (-p)
    # Send verbose output (-v) to the log file using tee
    tar -xzpvf "${ARCHIVE_FILE}" 2>&1 | tee -a "$LOG_FILE"

    start_stack

    log_success "Restore completed successfully."
}

# ------------------------------------------------------------------------------
# 5. ENTRYPOINT (Main execution block)
# ------------------------------------------------------------------------------

# Require exactly 2 arguments
if [ "$#" -ne 2 ]; then
    show_usage
fi

COMMAND="$1"
TARGET_PATH="$2"

# Ensure root privileges are established BEFORE we attempt to write to /var/log/
check_root

case "$COMMAND" in
    backup)
        do_backup "$TARGET_PATH"
        ;;
    restore)
        do_restore "$TARGET_PATH"
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_usage
        ;;
esac