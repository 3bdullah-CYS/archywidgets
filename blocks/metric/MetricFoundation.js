.pragma library

// OmaDesk — MetricFoundation
// Reusable domain helpers, calculations, icons, and value formatters for MetricBlock variants.
// Pure functions only — no side effects, no timers, no processes.

function getMetricIcon(source, isCleaning) {
  if (source === "ram.percent") {
    if (isCleaning) return "󰑐";
    return "󰘚";
  }
  switch (source) {
    case "cpu.percent":
      return "󰍛";
    case "ram.percent":
      return "󰘚";
    case "disk.percent":
    case "disk.hdd":
      return "󰋊";
    case "temperature.cpu":
    case "temperature.gpu":
    case "temperature.nvme":
    case "temperature.hdd":
      return "󰔏";
    case "network.down":
    case "network.download":
      return "󰇚";
    case "network.up":
    case "network.upload":
      return "󰕒";
    case "fan.mode":
      return "󰈐";
    default:
      return "󰄪";
  }
}

function getMetricLabel(source, isCleaning, primaryDisk, dataHub) {
  if (source === "ram.percent") {
    if (isCleaning) return "Cleaning...";
    return "RAM";
  }
  switch (source) {
    case "cpu.percent":
      return "CPU";
    case "ram.percent":
      return "RAM";
    case "disk.percent":
      return primaryDisk ? primaryDisk.label : (dataHub && dataHub.diskLabel ? dataHub.diskLabel : "System");
    case "disk.hdd":
      return primaryDisk ? primaryDisk.label : "Data Disk";
    case "temperature.cpu":
      return "CPU Temp";
    case "temperature.gpu":
      return "GPU Temp";
    case "temperature.nvme":
      return "NVMe Temp";
    case "temperature.hdd":
      return "HDD Temp";
    case "network.down":
    case "network.download":
      return "Download";
    case "network.up":
    case "network.upload":
      return "Upload";
    case "fan.mode":
      return "Fan";
    default:
      return "Metric";
  }
}

function formatValue(source, rawValue, primaryDisk, dataHub, isWide) {
  if (rawValue === null || rawValue === undefined) {
    if (source === "disk.hdd") return "Unmounted";
    return "Unavailable";
  }

  switch (source) {
    case "cpu.percent":
    case "ram.percent": {
      var p = Math.round(Number(rawValue));
      return isNaN(p) ? "Unavailable" : (p + "%");
    }
    case "disk.percent": {
      var freeStr = "";
      if (primaryDisk && primaryDisk.available_str) {
        freeStr = primaryDisk.available_str;
      } else if (dataHub && dataHub.diskFreeStr && dataHub.diskFreeStr !== "0 GB") {
        freeStr = dataHub.diskFreeStr;
      }
      if (freeStr.length > 0) {
        return isWide ? (freeStr + " Free") : freeStr;
      }
      var dp = Math.round(Number(rawValue));
      return isNaN(dp) ? "Unavailable" : (dp + "%");
    }
    case "disk.hdd": {
      if (primaryDisk && primaryDisk.available_str) {
        var hddFree = primaryDisk.available_str;
        return isWide ? (hddFree + " Free") : hddFree;
      }
      return "Unmounted";
    }
    case "temperature.cpu":
    case "temperature.gpu":
    case "temperature.nvme":
    case "temperature.hdd": {
      var t = Math.round(Number(rawValue));
      return isNaN(t) ? "Unavailable" : (t + "°C");
    }
    case "network.down":
    case "network.download":
    case "network.up":
    case "network.upload":
      return String(rawValue);
    case "fan.mode": {
      var m = Math.floor(Number(rawValue));
      return (isNaN(m) || m < 0) ? "Unavailable" : ("Mode " + m);
    }
    default:
      return String(rawValue);
  }
}

function hasProgressBar(source) {
  switch (source) {
    case "cpu.percent":
    case "ram.percent":
    case "disk.percent":
    case "disk.hdd":
    case "temperature.cpu":
    case "temperature.gpu":
    case "temperature.nvme":
    case "temperature.hdd":
      return true;
    default:
      return false;
  }
}

function getProgressFraction(source, rawValue, primaryDisk) {
  if (rawValue === null || rawValue === undefined) {
    return 0.0;
  }
  if ((source === "disk.percent" || source === "disk.hdd") && primaryDisk && typeof primaryDisk.percent === "number") {
    return Math.max(0.0, Math.min(1.0, primaryDisk.percent * 0.01));
  }
  var val = Number(rawValue);
  if (isNaN(val) || !isFinite(val)) {
    return 0.0;
  }
  if (hasProgressBar(source)) {
    return Math.max(0.0, Math.min(1.0, val * 0.01));
  }
  return 0.0;
}

var MetricFoundation = {
  getMetricIcon: getMetricIcon,
  getMetricLabel: getMetricLabel,
  formatValue: formatValue,
  hasProgressBar: hasProgressBar,
  getProgressFraction: getProgressFraction
};

if (typeof globalThis !== "undefined") {
  globalThis.MetricFoundation = MetricFoundation;
}
