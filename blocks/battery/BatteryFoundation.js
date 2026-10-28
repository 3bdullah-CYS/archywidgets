.pragma library

// OmaDesk — BatteryFoundation
// Reusable domain logic and presentation helpers for BatteryBlock variants.
// Pure functions only — zero timers, zero background processes, zero side effects.

function getBatteryIcon(batteryAvailable, charging, percent) {
  if (!batteryAvailable) return "󱉝";
  if (charging) return "󰂄";
  if (percent >= 90) return "󰁹";
  if (percent >= 60) return "󰁿";
  if (percent >= 40) return "󰁽";
  if (percent >= 20) return "󰁻";
  return "󰁺";
}

function getStateText(batteryAvailable, charging, percent) {
  if (!batteryAvailable) return "No battery";
  if (charging) return "Charging";
  if (percent === 100) return "Full";
  return "Discharging";
}

function getPowerSubtitle(batteryAvailable, charging, timeRemainingText, powerWattsText) {
  if (!batteryAvailable) return "AC Desktop Power";
  var timeStr = typeof timeRemainingText === "string" ? timeRemainingText.trim() : "";
  var wattStr = typeof powerWattsText === "string" ? powerWattsText.trim() : "";
  if (timeStr.length > 0 && wattStr.length > 0) {
    return timeStr + " • " + wattStr;
  }
  if (timeStr.length > 0) return timeStr;
  if (wattStr.length > 0) return wattStr;
  return charging ? "AC Connected" : "On Battery";
}

var BatteryFoundation = {
  getBatteryIcon: getBatteryIcon,
  getStateText: getStateText,
  getPowerSubtitle: getPowerSubtitle
};

if (typeof globalThis !== "undefined") {
  globalThis.BatteryFoundation = BatteryFoundation;
}
