.pragma library

// OmaDesk — NetworkFoundation
// Reusable domain logic and helper calculations for NetworkBlock variants.
// Pure functions only — zero timers, zero background processes, zero nmcli calls.

function isConnected(networkName) {
  var name = typeof networkName === "string" ? networkName.trim() : "";
  return name.length > 0 && name !== "Disconnected";
}

function getConnectionIcon(connected, networkType) {
  if (!connected) return "󰤭";
  var type = typeof networkType === "string" ? networkType : "";
  if (type === "Ethernet") return "󰈀";
  if (type === "VPN") return "󰦝";
  return "󰤨";
}

function getInterfaceSummary(connected, networkDevice, networkIp, networkType) {
  if (!connected) return "No network connection";
  var dev = typeof networkDevice === "string" ? networkDevice.trim() : "";
  var ip = typeof networkIp === "string" ? networkIp.trim() : "";
  var type = typeof networkType === "string" ? networkType.trim() : "Wi-Fi";
  if (dev.length > 0 && ip.length > 0) {
    return dev + " • " + ip;
  }
  if (dev.length > 0) return dev;
  if (ip.length > 0) return ip;
  return type;
}

var NetworkFoundation = {
  isConnected: isConnected,
  getConnectionIcon: getConnectionIcon,
  getInterfaceSummary: getInterfaceSummary
};

if (typeof globalThis !== "undefined") {
  globalThis.NetworkFoundation = NetworkFoundation;
}
