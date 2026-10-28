#!/bin/bash
set -e

# OmaDesk Memory Cleanup Helper
# Commits dirty file buffers to disk, then attempts to drop eligible kernel caches.

# Step 1: Commit user filesystem buffers
sync

HELPER="/usr/local/libexec/omadesk-memory-trim"

# Step 2: Attempt kernel cache reclamation if helper is installed
if [[ -x "$HELPER" ]]; then
    if sudo -n "$HELPER" 2>/dev/null; then
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a "OmaDesk" -i "dialog-information" "Memory Cleanup" "Pagecache and kernel slab caches cleared successfully." || true
        fi
        exit 0
    else
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a "OmaDesk" -u critical -i "dialog-error" "Memory Cleanup" "Failed to drop caches: sudo -n permission denied." || true
        fi
        exit 101
    fi
else
    # Helper is not yet installed in /usr/local/libexec/
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "OmaDesk" -u critical -i "dialog-warning" "Memory Cleanup" "Helper /usr/local/libexec/omadesk-memory-trim is not installed." || true
    fi
    exit 102
fi
