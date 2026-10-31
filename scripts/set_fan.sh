#!/bin/bash
set -e

mode="$1"

if [[ -z "$mode" ]]; then
    exit 1
fi

case "$mode" in
    0) mode_name="Quiet" ;;
    1) mode_name="Standard" ;;
    2) mode_name="Dust Clean" ;;
    4) mode_name="Fan Boost" ;;
    *)
        if command -v notify-send >/dev/null 2>&1; then
            notify-send -a "ArchyWidgets" -u critical -i "dialog-error" "Fan Control" "Unsupported fan mode: $mode" || true
        fi
        exit 1
        ;;
esac

# Apply fan mode using passwordless sudo directly (never prompt for passwords)
if sudo -n /usr/local/libexec/lenovo-fan-control-apply "$mode" 2>/dev/null; then
    state_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    if [[ -d "$state_dir" && -w "$state_dir" ]]; then
        echo "$mode" > "$state_dir/archywidgets_fan_mode"
    fi
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "ArchyWidgets" -i "dialog-information" "Fan Control" "Fan mode set: $mode_name" || true
    fi
    exit 0
else
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a "ArchyWidgets" -u critical -i "dialog-error" "Fan Control" "Failed to set fan mode to: $mode_name" || true
    fi
    exit 1
fi
