#!/bin/bash

# Safari Update Script

LOG_FILE="/var/log/safari_update.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "=== Safari Update Check Started ==="

# Root check
if [ "$(id -u)" -ne 0 ]; then
    log_message "ERROR: This script must be run as root"
    exit 1
fi

log_message "Checking for available Safari updates"

# Extract the Safari update label (without "Label: " prefix)
SAFARI_UPDATE_NAME=$(softwareupdate -l 2>&1 | grep -i 'Label:.*Safari' | sed 's/^\* Label: //' | head -n 1)

if [ -z "$SAFARI_UPDATE_NAME" ]; then
    log_message "No Safari updates available"
    exit 0
fi

log_message "Safari update found: $SAFARI_UPDATE_NAME"
log_message "Starting installation of: $SAFARI_UPDATE_NAME"

# Install only the specific Safari update
softwareupdate -i "$SAFARI_UPDATE_NAME" --agree-to-license >> "$LOG_FILE" 2>&1
result=$?

if [ $result -eq 0 ]; then
    log_message "Safari update completed successfully"
else
    log_message "ERROR: Safari update failed with exit code $result"
    exit 1
fi

log_message "=== Safari Update Check Completed ==="