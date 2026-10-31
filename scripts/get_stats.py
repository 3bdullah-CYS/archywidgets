#!/usr/bin/env python3
import glob
import json
import os
import platform
import shutil
import socket
import subprocess
import sys
import time
import psutil

# Read CPU model once
cpu_model = "CPU"
try:
    with open('/proc/cpuinfo') as f:
        for line in f:
            if 'model name' in line:
                cpu_model = line.split(':', 1)[1].strip()
                break
except Exception:
    pass
cpu_short = cpu_model.replace("Intel(R) Core(TM) ", "").replace(" CPU @ ", " @ ").replace("(R)", "").replace("(TM)", "")

kernel_ver = platform.release()
hostname = platform.node()
os_name = "Omarchy Linux"
try:
    if os.path.exists("/etc/os-release"):
        with open("/etc/os-release", "r", encoding="utf-8") as f:
            for line in f:
                if line.startswith("PRETTY_NAME="):
                    val = line.split("=", 1)[1].strip().strip('"').strip("'")
                    if val:
                        os_name = val
                    break
except Exception:
    pass
cpu_cores = psutil.cpu_count(logical=True) or 0
fan_path = "/sys/bus/platform/devices/VPC2004:00/fan_mode"

def format_speed(bps):
    kbps = bps / 1024.0
    if kbps >= 1024.0:
        return f"{kbps / 1024.0:.1f} MB/s"
    return f"{kbps:.0f} KB/s"

def format_bytes(num_bytes):
    val = max(0.0, float(num_bytes))
    mb = val / (1024.0 * 1024.0)
    if mb >= 1024.0:
        return f"{mb / 1024.0:.1f} GB"
    if mb >= 1.0:
        return f"{mb:.0f} MB"
    return f"{val / 1024.0:.0f} KB"

def get_local_ip(preferred_device=""):
    try:
        addrs = psutil.net_if_addrs()
        if preferred_device and preferred_device in addrs:
            for snic in addrs[preferred_device]:
                if snic.family == socket.AF_INET and snic.address and not snic.address.startswith("127."):
                    return snic.address
        for dev, snics in addrs.items():
            if dev == "lo":
                continue
            for snic in snics:
                if snic.family == socket.AF_INET and snic.address and not snic.address.startswith("127."):
                    return snic.address
    except Exception:
        pass
    return ""

def read_file_safe(path):
    try:
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            return f.read().strip()
    except Exception:
        return ""

def get_system_uptime():
    try:
        with open("/proc/uptime", "r", encoding="utf-8") as f:
            total_secs = float(f.read().split()[0])
            days = int(total_secs // 86400)
            hours = int((total_secs % 86400) // 3600)
            mins = int((total_secs % 3600) // 60)
            parts = []
            if days > 0:
                parts.append(f"{days} day{'s' if days > 1 else ''}")
            if hours > 0:
                parts.append(f"{hours} hour{'s' if hours > 1 else ''}")
            if mins > 0 or not parts:
                parts.append(f"{mins} minute{'s' if mins > 1 else ''}")
            return ", ".join(parts)
    except Exception:
        try:
            return subprocess.getoutput("uptime -p").replace("up ", "")
        except Exception:
            return ""

def get_battery_power_w():
    for path in glob.glob("/sys/class/power_supply/BAT*/power_now"):
        try:
            val = read_file_safe(path)
            if val:
                uw = int(val)
                if uw > 0:
                    return f"{uw / 1000000.0:.1f} W"
        except Exception:
            pass
    return ""

HAS_NVIDIA_SMI = shutil.which("nvidia-smi") is not None
last_gpu_check = 0.0
cached_gpu_temp = 0.0

def get_temps():
    global last_gpu_check, cached_gpu_temp
    temps = {"cpu": 0, "gpu": 0, "nvme": 0, "hdd": 0}
    for directory in glob.glob("/sys/class/hwmon/hwmon*"):
        try:
            name = read_file_safe(f"{directory}/name").lower()
            for path in glob.glob(f"{directory}/temp*_input"):
                label_path = path.replace("_input", "_label")
                label = read_file_safe(label_path).lower() if os.path.exists(label_path) else ""
                raw_val = read_file_safe(path)
                if not raw_val:
                    continue
                val = round(int(raw_val) / 1000.0, 1)
                if "package id" in label or name == "coretemp" or name in ("k10temp", "zenpower", "cpu_thermal"):
                    temps["cpu"] = val
                elif name == "drivetemp":
                    temps["hdd"] = max(temps["hdd"], val)
                elif name == "nvme" or "composite" in label:
                    temps["nvme"] = val
                elif "amdgpu" in name:
                    temps["gpu"] = val
        except Exception:
            pass
    if HAS_NVIDIA_SMI and temps["gpu"] == 0:
        now_ts = time.time()
        if now_ts - last_gpu_check > 5.0:
            last_gpu_check = now_ts
            try:
                nv = subprocess.run(
                    ["nvidia-smi", "--query-gpu=temperature.gpu", "--format=csv,noheader,nounits"],
                    capture_output=True, text=True, timeout=0.3
                )
                if nv.returncode == 0 and nv.stdout.strip():
                    cached_gpu_temp = float(nv.stdout.strip().splitlines()[0])
            except Exception:
                pass
        temps["gpu"] = cached_gpu_temp
    return temps

last_disk_check = 0.0
cached_storage_volumes = []
cached_disk_labels = {}
last_label_check = 0.0

def format_storage_bytes(num_bytes):
    val = max(0.0, float(num_bytes))
    tb = val / (1024.0 ** 4)
    if tb >= 1.0:
        return f"{tb:.1f} TB" if tb < 10.0 else f"{tb:.0f} TB"
    gb = val / (1024.0 ** 3)
    if gb >= 1.0:
        return f"{gb:.1f} GB" if gb < 10.0 else f"{gb:.0f} GB"
    mb = val / (1024.0 ** 2)
    if mb >= 1.0:
        return f"{mb:.0f} MB"
    return f"{val / 1024.0:.0f} KB"

def get_disk_labels(now_ts):
    global last_label_check, cached_disk_labels
    if now_ts - last_label_check < 10.0:
        return cached_disk_labels
    last_label_check = now_ts
    labels = {}
    for entry in glob.glob("/dev/disk/by-label/*"):
        try:
            target = os.path.realpath(entry)
            lbl = os.path.basename(entry).replace(r"\x20", " ")
            labels[target] = lbl
        except Exception:
            pass
    cached_disk_labels = labels
    return cached_disk_labels

def get_storage_volumes(now_ts):
    global last_disk_check, cached_storage_volumes
    if now_ts - last_disk_check < 3.0 and cached_storage_volumes:
        return cached_storage_volumes
    last_disk_check = now_ts

    labels = get_disk_labels(now_ts)
    seen_keys = set()
    volumes = []

    try:
        raw_parts = psutil.disk_partitions(all=False)
    except Exception:
        raw_parts = []

    parts = sorted(raw_parts, key=lambda p: (0 if p.mountpoint == '/' else 1, p.mountpoint))

    for p in parts:
        if p.device.startswith(('tmpfs', 'devtmpfs', 'overlay', 'none', 'squashfs')):
            continue
        if p.mountpoint in ('/boot', '/efi', '/boot/efi'):
            continue
        if p.mountpoint.startswith(('/proc', '/sys', '/dev', '/run/user')):
            continue

        try:
            real_dev = os.path.realpath(p.device) if p.device.startswith('/') else p.device
            st = os.statvfs(p.mountpoint)
        except (PermissionError, OSError):
            continue
        except Exception:
            continue

        total_bytes = st.f_blocks * st.f_frsize
        if total_bytes < 100 * 1024 * 1024:
            continue

        fs_key = (real_dev, st.f_blocks)
        if fs_key in seen_keys:
            continue
        seen_keys.add(fs_key)

        avail_bytes = st.f_bavail * st.f_frsize
        free_bytes = st.f_bfree * st.f_frsize
        used_bytes = max(0, (st.f_blocks - st.f_bfree) * st.f_frsize)

        usable_total = used_bytes + avail_bytes
        pct = round((used_bytes / usable_total * 100.0)) if usable_total > 0 else 0

        disk_lbl = labels.get(real_dev, "")
        if not disk_lbl and p.device != real_dev:
            disk_lbl = labels.get(p.device, "")

        if p.mountpoint == '/':
            name = "System"
        elif disk_lbl:
            name = disk_lbl[:10].strip()
        else:
            base_name = os.path.basename(p.mountpoint.rstrip('/')).capitalize()
            name = base_name[:10] if base_name else "Storage"

        volumes.append({
            "id": f"vol_{len(volumes)}",
            "label": name,
            "mount": p.mountpoint,
            "device": p.device,
            "fs_type": p.fstype,
            "total_bytes": total_bytes,
            "available_bytes": avail_bytes,
            "used_bytes": used_bytes,
            "total_str": format_storage_bytes(total_bytes),
            "available_str": format_storage_bytes(avail_bytes),
            "used_str": format_storage_bytes(used_bytes),
            "total_gb": f"{total_bytes / (1024**3):.0f}",
            "available_gb": f"{avail_bytes / (1024**3):.0f}",
            "used_gb": f"{used_bytes / (1024**3):.0f}",
            "percent": pct
        })

    if not volumes:
        try:
            st = os.statvfs('/')
            total_bytes = st.f_blocks * st.f_frsize
            avail_bytes = st.f_bavail * st.f_frsize
            used_bytes = max(0, (st.f_blocks - st.f_bfree) * st.f_frsize)
            usable_total = used_bytes + avail_bytes
            pct = round((used_bytes / usable_total * 100.0)) if usable_total > 0 else 0
            volumes.append({
                "id": "vol_0",
                "label": "System",
                "mount": "/",
                "device": "/",
                "fs_type": "btrfs",
                "total_bytes": total_bytes,
                "available_bytes": avail_bytes,
                "used_bytes": used_bytes,
                "total_str": format_storage_bytes(total_bytes),
                "available_str": format_storage_bytes(avail_bytes),
                "used_str": format_storage_bytes(used_bytes),
                "total_gb": f"{total_bytes / (1024**3):.0f}",
                "available_gb": f"{avail_bytes / (1024**3):.0f}",
                "used_gb": f"{used_bytes / (1024**3):.0f}",
                "percent": pct
            })
        except Exception:
            pass

    cached_storage_volumes = volumes
    return cached_storage_volumes

NOTIF_HISTORY_DIR = os.path.expanduser("~/.local/state/omarchy/notifications/history")
_notif_cache = []
_notif_mtime = 0.0

def get_recent_notifications(now):
    global _notif_cache, _notif_mtime
    if not os.path.isdir(NOTIF_HISTORY_DIR):
        return []
    try:
        dir_mtime = os.path.getmtime(NOTIF_HISTORY_DIR)
        if dir_mtime != _notif_mtime:
            _notif_mtime = dir_mtime
            files = sorted(glob.glob(os.path.join(NOTIF_HISTORY_DIR, "*.json")), key=os.path.getmtime, reverse=True)[:10]
            entries = []
            for path in files:
                try:
                    with open(path, "r", encoding="utf-8") as f:
                        entry = json.load(f)
                        if isinstance(entry, dict) and entry.get("summary"):
                            entries.append(entry)
                except Exception:
                    continue
            _notif_cache = entries
        return _notif_cache
    except Exception:
        return _notif_cache

# Initialize CPU and Net baseline
psutil.cpu_percent()
prev_net = psutil.net_io_counters()
prev_time = time.time()
ssid_cache = "Disconnected"
net_type_cache = "Offline"
net_device_cache = ""
net_ip_cache = ""
last_ssid_check = 0

while True:
    now = time.time()
    dt = max(0.2, now - prev_time)
    
    # 1. CPU
    cpu_pct = round(psutil.cpu_percent(interval=None))
    
    # 2. Net speeds
    curr_net = psutil.net_io_counters()
    down_speed = max(0.0, (curr_net.bytes_recv - prev_net.bytes_recv) / dt)
    up_speed = max(0.0, (curr_net.bytes_sent - prev_net.bytes_sent) / dt)
    prev_net = curr_net
    prev_time = now
    
    # 3. Memory, Swap & Disk
    mem = psutil.virtual_memory()
    swap = psutil.swap_memory()
    disk = psutil.disk_usage('/')
    batt = psutil.sensors_battery()
    load_avg_str = ""
    try:
        with open("/proc/loadavg", "r", encoding="utf-8") as lf:
            lparts = lf.read().strip().split()
            if len(lparts) >= 3:
                load_avg_str = f"{lparts[0]} · {lparts[1]} · {lparts[2]}"
    except Exception:
        pass
    
    # 4. SSID & Interface Info (checked every 6s to avoid nmcli overhead)
    if now - last_ssid_check > 6.0:
        last_ssid_check = now
        try:
            res = subprocess.run(
                ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "c", "show", "--active"],
                capture_output=True, text=True, timeout=0.4
            )
            if res.returncode == 0:
                active_ssid = "Disconnected"
                active_type = "Offline"
                active_dev = ""
                for line in res.stdout.splitlines():
                    parts = line.strip().split(":")
                    if len(parts) >= 2 and parts[1] in ("802-11-wireless", "802-3-ethernet", "wireguard", "vpn"):
                        active_ssid = parts[0]
                        if parts[1] == "802-11-wireless":
                            active_type = "Wi-Fi"
                        elif parts[1] == "802-3-ethernet":
                            active_type = "Ethernet"
                        else:
                            active_type = "VPN"
                        active_dev = parts[2] if len(parts) >= 3 else ""
                        break
                ssid_cache = active_ssid
                net_type_cache = active_type if active_ssid != "Disconnected" else "Offline"
                net_device_cache = active_dev if active_ssid != "Disconnected" else ""
                net_ip_cache = get_local_ip(net_device_cache) if active_ssid != "Disconnected" else ""
        except Exception:
            pass
    
    # 5. Temps
    temps = get_temps()
    
    # 6. Fan mode state
    fan_mode = -1
    runtime_dir = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}" if hasattr(os, "getuid") else "")
    archy_fan = os.path.join(runtime_dir, "archywidgets_fan_mode") if runtime_dir else ""
    if archy_fan and os.path.exists(archy_fan):
        try:
            if not hasattr(os, "getuid") or os.stat(archy_fan).st_uid == os.getuid():
                raw_fm = read_file_safe(archy_fan)
                if raw_fm.isdigit():
                    fan_mode = int(raw_fm)
        except Exception:
            pass
    if fan_mode not in (0, 1, 2, 4) and os.path.exists(fan_path):
        raw_val = read_file_safe(fan_path)
        if raw_val.isdigit():
            val = int(raw_val)
            fan_mode = val if val in (0, 1, 2, 4) else 1
        else:
            fan_mode = 1
            
    # 7. Uptime (pure /proc/uptime read with zero subprocess forks)
    uptime_str = get_system_uptime()

    batt_available = batt is not None
    batt_pct = round(batt.percent) if batt else 100
    batt_charging = bool(batt.power_plugged) if (batt and batt.power_plugged is not None) else True
    batt_time_str = ""
    if batt is not None:
        if batt_pct >= 100 and batt_charging:
            batt_time_str = "Full"
        elif isinstance(batt.secsleft, (int, float)) and 0 < batt.secsleft < 86400 * 5:
            hrs = int(batt.secsleft // 3600)
            mins = int((batt.secsleft % 3600) // 60)
            batt_time_str = f"{hrs}h {mins}m" if hrs > 0 else f"{mins}m"
        else:
            batt_time_str = "AC Power" if batt_charging else "On Battery"
    batt_power_w = get_battery_power_w() if batt_available else ""
    storage_vols = get_storage_volumes(now)
    primary_vol = storage_vols[0] if storage_vols else None
    sec_vol = storage_vols[1] if len(storage_vols) > 1 else None

    payload = {
        "cpu": cpu_pct,
        "cpu_model": cpu_short,
        "cpu_cores": cpu_cores,
        "kernel": kernel_ver,
        "hostname": hostname,
        "os_name": os_name,
        "load_avg": load_avg_str,
        "ram_used_gb": f"{mem.used / (1024**3):.1f}",
        "ram_total_gb": f"{mem.total / (1024**3):.1f}",
        "ram_percent": round(mem.percent),
        "swap_used_gb": f"{swap.used / (1024**3):.1f}" if swap else "0.0",
        "swap_total_gb": f"{swap.total / (1024**3):.1f}" if swap else "0.0",
        "swap_percent": round(swap.percent) if swap else 0,
        "disk_used_gb": primary_vol["used_gb"] if primary_vol else "0",
        "disk_total_gb": primary_vol["total_gb"] if primary_vol else "0",
        "disk_free_gb": primary_vol["available_gb"] if primary_vol else "0",
        "disk_free_str": primary_vol["available_str"] if primary_vol else "0 GB",
        "disk_total_str": primary_vol["total_str"] if primary_vol else "0 GB",
        "disk_used_str": primary_vol["used_str"] if primary_vol else "0 GB",
        "disk_percent": primary_vol["percent"] if primary_vol else 0,
        "disk_label": primary_vol["label"] if primary_vol else "System",
        "disks": storage_vols,
        "disk_hdd_available": sec_vol is not None,
        "disk_hdd_percent": sec_vol["percent"] if sec_vol else 0,
        "disk_hdd_used_gb": sec_vol["used_gb"] if sec_vol else "0",
        "disk_hdd_total_gb": sec_vol["total_gb"] if sec_vol else "0",
        "disk_hdd_free_gb": sec_vol["available_gb"] if sec_vol else "0",
        "disk_hdd_free_str": sec_vol["available_str"] if sec_vol else "0 GB",
        "disk_hdd_label": sec_vol["label"] if sec_vol else "Data Disk",
        "net_down_str": format_speed(down_speed),
        "net_up_str": format_speed(up_speed),
        "net_down_bps": round(down_speed),
        "net_up_bps": round(up_speed),
        "net_total_down_str": format_bytes(curr_net.bytes_recv),
        "net_total_up_str": format_bytes(curr_net.bytes_sent),
        "net_type": net_type_cache,
        "net_device": net_device_cache,
        "net_ip": net_ip_cache,
        "ssid": ssid_cache,
        "battery_available": batt_available,
        "battery_percent": batt_pct,
        "battery_charging": batt_charging,
        "battery_time_str": batt_time_str,
        "battery_power_w": batt_power_w,
        "temp_cpu": temps["cpu"],
        "temp_gpu": temps["gpu"],
        "temp_nvme": temps["nvme"],
        "temp_hdd": temps["hdd"],
        "fan_mode": fan_mode,
        "uptime": uptime_str,
        "recent_notifications": get_recent_notifications(now)
    }
    
    try:
        print(json.dumps(payload), flush=True)
    except BrokenPipeError:
        sys.exit(0)
    time.sleep(1.0)
