#!/usr/bin/env python3
"""
OmaDesk — Native Todo List Helper
Performs safe, atomic mutations on ~/.config/omarchy/todo-list/items.json
compatible with io.zet.todo-list.
"""
import json
import os
import secrets
import sys
import time

STORE_DIR = os.environ.get("OMARCHY_TODO_DIR", os.path.expanduser("~/.config/omarchy/todo-list"))
ITEMS_PATH = os.path.join(STORE_DIR, "items.json")

def load_items():
    if not os.path.exists(ITEMS_PATH):
        return {"version": 1, "items": [], "history": []}
    try:
        with open(ITEMS_PATH, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {"version": 1, "items": [], "history": []}

def save_items(data):
    os.makedirs(STORE_DIR, mode=0o700, exist_ok=True)
    tmp_path = os.path.join(STORE_DIR, f".items.{secrets.token_hex(8)}.tmp")
    try:
        with open(tmp_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
            f.write("\n")
            f.flush()
            os.fsync(f.fileno())
        os.chmod(tmp_path, 0o600)
        os.replace(tmp_path, ITEMS_PATH)
        return True
    except Exception as e:
        if os.path.exists(tmp_path):
            try:
                os.unlink(tmp_path)
            except OSError:
                pass
        print(f"ERROR: {e}", file=sys.stderr)
        return False

def toggle_item(item_id):
    data = load_items()
    items = data.get("items", [])
    history = data.get("history", [])
    now_ms = int(time.time() * 1000)

    # Check if in open items
    target = None
    for i, it in enumerate(items):
        if it.get("id") == item_id:
            target = items.pop(i)
            break

    if target:
        target["done"] = True
        target["completedAt"] = now_ms
        target["reason"] = "completed"
        history.insert(0, target)
        if len(history) > 100:
            history = history[:100]
        data["items"] = items
        data["history"] = history
        if save_items(data):
            print("TOGGLED_TO_DONE")
            return 0
        return 1

    # Check if in history (restore)
    for i, it in enumerate(history):
        if it.get("id") == item_id:
            target = history.pop(i)
            break

    if target:
        target["done"] = False
        target["completedAt"] = 0
        target["reason"] = "completed"
        items.insert(0, target)
        data["items"] = items
        data["history"] = history
        if save_items(data):
            print("TOGGLED_TO_OPEN")
            return 0
        return 1

    print("ITEM_NOT_FOUND", file=sys.stderr)
    return 1

def add_item(text):
    text = (text or "").strip()
    if not text:
        return 1
    data = load_items()
    items = data.get("items", [])
    new_id = f"{int(time.time()*1000):x}-{secrets.token_hex(4)}"
    item = {
        "id": new_id,
        "text": text[:500],
        "done": False,
        "createdAt": int(time.time() * 1000),
        "completedAt": 0,
        "reason": "completed"
    }
    items.insert(0, item)
    if len(items) > 200:
        items = items[:200]
    data["items"] = items
    if save_items(data):
        print(new_id)
        return 0
    return 1

def delete_item(item_id):
    item_id = (item_id or "").strip()
    if not item_id:
        return 1
    data = load_items()
    items = data.get("items", [])
    history = data.get("history", [])

    found = False
    for i, it in enumerate(items):
        if it.get("id") == item_id:
            items.pop(i)
            found = True
            break

    if not found:
        for i, it in enumerate(history):
            if it.get("id") == item_id:
                history.pop(i)
                found = True
                break

    if found:
        data["items"] = items
        data["history"] = history
        if save_items(data):
            print("DELETED")
            return 0
        return 1

    print("ITEM_NOT_FOUND", file=sys.stderr)
    return 1

def main():
    if len(sys.argv) < 2:
        print("Usage: todo_helper.py toggle <id> | add <text> | delete <id>", file=sys.stderr)
        sys.exit(1)

    action = sys.argv[1]
    if action == "toggle" and len(sys.argv) >= 3:
        sys.exit(toggle_item(sys.argv[2]))
    elif action == "add" and len(sys.argv) >= 3:
        sys.exit(add_item(" ".join(sys.argv[2:])))
    elif action == "delete" and len(sys.argv) >= 3:
        sys.exit(delete_item(sys.argv[2]))
    else:
        print(f"Unknown action: {action}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
