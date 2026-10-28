#!/usr/bin/env python3
import json
import os
import sys
import tempfile

CONFIG_PATH = os.environ.get("ARCHYWIDGETS_CONFIG_PATH", None)
if len(sys.argv) >= 3 and sys.argv[2]:
    CONFIG_PATH = sys.argv[2]
elif not CONFIG_PATH:
    CONFIG_PATH = os.path.expanduser("~/.config/omarchy/archywidgets.json")


if len(sys.argv) >= 2 and sys.argv[1] != "-":
    raw_json = sys.argv[1]
elif not sys.stdin.isatty():
    raw_json = sys.stdin.read()
else:
    sys.exit(1)

try:
    data = json.loads(raw_json)
    target_dir = os.path.dirname(os.path.abspath(CONFIG_PATH))
    os.makedirs(target_dir, exist_ok=True)

    # Atomic write via same-directory temporary file, flush, fsync, and os.replace
    prefix = f".{os.path.basename(CONFIG_PATH)}.tmp."
    with tempfile.NamedTemporaryFile("w", dir=target_dir, prefix=prefix, delete=False, encoding="utf-8") as tf:
        tmp_name = tf.name
        json.dump(data, tf, indent=2, ensure_ascii=False)
        tf.write("\n")
        tf.flush()
        os.fsync(tf.fileno())

    os.replace(tmp_name, CONFIG_PATH)
    print("SUCCESS")
except Exception as e:
    if 'tmp_name' in locals() and os.path.exists(tmp_name):
        try:
            os.remove(tmp_name)
        except OSError:
            pass
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
