#!/usr/bin/env python3
"""
OmaDesk — Native Notification Helper
Integrates with Omarchy's notifications service and reads history state.
"""
import glob
import json
import os
import subprocess
import sys

STATE_DIR = os.environ.get("OMARCHY_NOTIF_STATE", os.path.expanduser("~/.local/state/omarchy/notifications"))
HISTORY_DIR = os.path.join(STATE_DIR, "history")

def list_history():
    if not os.path.exists(HISTORY_DIR):
        print("[]")
        return 0
    try:
        files = sorted(glob.glob(os.path.join(HISTORY_DIR, "*.json")), key=os.path.getmtime, reverse=True)[:10]
        results = []
        for path in files:
            try:
                with open(path, "r", encoding="utf-8") as f:
                    entry = json.load(f)
                    if isinstance(entry, dict) and entry.get("summary"):
                        results.append(entry)
            except Exception:
                continue
        print(json.dumps(results, ensure_ascii=False))
        return 0
    except Exception as e:
        print("[]")
        return 0

def call_ipc(func_name, arg=""):
    cmd = ["/usr/bin/quickshell", "ipc", "-p", "/usr/share/omarchy/shell", "call", "notifications", func_name]
    if arg:
        cmd.append(arg)
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=3.0)
        output = (res.stdout or "").strip()
        print(output if output else "ok")
        return 0 if res.returncode == 0 else 1
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

def main():
    if len(sys.argv) < 2:
        list_history()
        return

    action = sys.argv[1]
    if action == "list":
        list_history()
    elif action == "toggle_dnd":
        call_ipc("toggleDnd")
    elif action == "dnd_state":
        call_ipc("dndState")
    elif action == "clear":
        call_ipc("clear")
    else:
        print(f"Unknown action: {action}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
