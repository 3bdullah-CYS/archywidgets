/**
 * ArchyWidgets Block Registry
 * Defines all available composable block kinds, supported variants, footprints,
 * singleton constraints, allowed metric sources, presentation modes, and growth capabilities.
 */
.pragma library

var ALLOWED_METRIC_SOURCES = [
  "cpu.percent",
  "ram.percent",
  "disk.percent",
  "disk.hdd",
  "temperature.cpu",
  "temperature.gpu",
  "temperature.nvme",
  "temperature.hdd",
  "network.download",
  "network.upload",
  "fan.mode"
];

var ALLOWED_FAN_MODES = [0, 1, 2, 4];

var PRESENTATION_MODES = ["auto", "icon", "compact", "detailed", "dashboard"];

var REGISTRY = {
  "time": {
    kind: "time",
    supportedVariants: ["compact", "wide", "minimal", "analog", "cards"],
    variants: {
      "compact": {
        label: "Compact · 1×1",
        icon: "󰥔",
        description: "Digital clock with hours and minutes",
        colSpan: 1,
        rowSpan: 1,
        minPixelWidth: 60,
        minPixelHeight: 30,
        aspectRatio: null,
        resizable: true,
        defaultSettings: { showSeconds: false }
      },
      "wide": {
        label: "Wide · 2×1",
        icon: "󱑎",
        description: "Digital clock banner with seconds and date",
        colSpan: 2,
        rowSpan: 1,
        minPixelWidth: 120,
        minPixelHeight: 30,
        aspectRatio: null,
        resizable: true,
        defaultSettings: { showSeconds: true }
      },
      "minimal": {
        label: "Minimal · 1×1",
        icon: "󰥔",
        description: "Minimalist typography clock",
        colSpan: 1,
        rowSpan: 1,
        minPixelWidth: 60,
        minPixelHeight: 30,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      },
      "analog": {
        label: "Analog · 1×1",
        icon: "󰥔",
        description: "Classic analog dial with hour, minute and second hands",
        colSpan: 1,
        rowSpan: 1,
        minPixelWidth: 70,
        minPixelHeight: 70,
        aspectRatio: "1:1",
        resizable: false,
        allowedSpans: [{ colSpan: 1, rowSpan: 1 }, { colSpan: 2, rowSpan: 2 }],
        defaultSettings: {}
      },
      "cards": {
        label: "Flip Cards · 2×1",
        icon: "󱑎",
        description: "Segmented flip cards clock with distinct hour and minute tiles",
        colSpan: 2,
        rowSpan: 1,
        minPixelWidth: 120,
        minPixelHeight: 36,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      }
    },
    footprints: {
      "compact": { colSpan: 1, rowSpan: 1, label: "Compact · 1×1", minPixelWidth: 60, minPixelHeight: 30 },
      "wide": { colSpan: 2, rowSpan: 1, label: "Wide · 2×1", minPixelWidth: 120, minPixelHeight: 30 },
      "minimal": { colSpan: 1, rowSpan: 1, label: "Minimal · 1×1", minPixelWidth: 60, minPixelHeight: 30 },
      "analog": { colSpan: 1, rowSpan: 1, label: "Analog · 1×1", minPixelWidth: 70, minPixelHeight: 70 },
      "cards": { colSpan: 2, rowSpan: 1, label: "Flip Cards · 2×1", minPixelWidth: 120, minPixelHeight: 36 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 48, minPixelHeight: 28 },
      "compact": { minPixelWidth: 60, minPixelHeight: 30 },
      "detailed": { minPixelWidth: 120, minPixelHeight: 30 },
      "dashboard": { minPixelWidth: 200, minPixelHeight: 120 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 150, minPixelHeight: 54 },
      "dashboard": { minPixelWidth: 220, minPixelHeight: 135 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: true
  },
  "date": {
    kind: "date",
    supportedVariants: ["compact", "desk-card", "wide"],
    variants: {
      "compact": {
        label: "Compact · 1×1",
        icon: "󰃭",
        description: "Compact calendar card with date and day",
        colSpan: 1,
        rowSpan: 1,
        minPixelWidth: 60,
        minPixelHeight: 30,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      },
      "desk-card": {
        label: "Desk Card · 1×1",
        icon: "󰸗",
        description: "Classic tear-off desk calendar card with month banner and prominent day number",
        colSpan: 1,
        rowSpan: 1,
        minPixelWidth: 60,
        minPixelHeight: 30,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      },
      "wide": {
        label: "Wide · 2×1",
        icon: "󰃭",
        description: "Date badge with 7-day week strip",
        colSpan: 2,
        rowSpan: 1,
        minPixelWidth: 120,
        minPixelHeight: 30,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      }
    },
    footprints: {
      "compact": { colSpan: 1, rowSpan: 1, label: "Compact · 1×1", minPixelWidth: 60, minPixelHeight: 30 },
      "desk-card": { colSpan: 1, rowSpan: 1, label: "Desk Card · 1×1", minPixelWidth: 60, minPixelHeight: 30 },
      "wide": { colSpan: 2, rowSpan: 1, label: "Wide · 2×1", minPixelWidth: 120, minPixelHeight: 30 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 48, minPixelHeight: 28 },
      "compact": { minPixelWidth: 60, minPixelHeight: 30 },
      "detailed": { minPixelWidth: 120, minPixelHeight: 36 },
      "dashboard": { minPixelWidth: 200, minPixelHeight: 120 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 150, minPixelHeight: 54 },
      "dashboard": { minPixelWidth: 220, minPixelHeight: 135 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: true
  },
  "metric": {
    kind: "metric",
    supportedVariants: ["compact", "bar"],
    variants: {
      "compact": {
        label: "Compact · 1×1",
        icon: "󰘚",
        description: "Compact metric glance tile with progress indicator",
        colSpan: 1,
        rowSpan: 1,
        minPixelWidth: 60,
        minPixelHeight: 30,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      },
      "bar": {
        label: "Bar · 2×1",
        icon: "󱕍",
        description: "Horizontal gauge bar with live readout and peak indicator",
        colSpan: 2,
        rowSpan: 1,
        minPixelWidth: 120,
        minPixelHeight: 30,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      }
    },
    footprints: {
      "compact": { colSpan: 1, rowSpan: 1, label: "Compact · 1×1", minPixelWidth: 60, minPixelHeight: 30 },
      "bar": { colSpan: 2, rowSpan: 1, label: "Bar · 2×1", minPixelWidth: 120, minPixelHeight: 30 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 48, minPixelHeight: 28 },
      "compact": { minPixelWidth: 60, minPixelHeight: 30 },
      "detailed": { minPixelWidth: 120, minPixelHeight: 30 },
      "dashboard": { minPixelWidth: 200, minPixelHeight: 120 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 150, minPixelHeight: 54 },
      "dashboard": { minPixelWidth: 220, minPixelHeight: 135 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: true,
    singleton: false
  },
  "network": {
    kind: "network",
    supportedVariants: ["compact", "wide"],
    variants: {
      "compact": {
        label: "Compact · 1×1",
        icon: "󰤨",
        description: "Compact network glance tile with live throughput rates",
        colSpan: 1,
        rowSpan: 1,
        minPixelWidth: 60,
        minPixelHeight: 30,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      },
      "wide": {
        label: "Wide · 2×1",
        icon: "󰈀",
        description: "Wide network banner with IP and dual traffic meters",
        colSpan: 2,
        rowSpan: 1,
        minPixelWidth: 120,
        minPixelHeight: 36,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      }
    },
    footprints: {
      "compact": { colSpan: 1, rowSpan: 1, label: "Compact · 1×1", minPixelWidth: 60, minPixelHeight: 30 },
      "wide": { colSpan: 2, rowSpan: 1, label: "Wide · 2×1", minPixelWidth: 120, minPixelHeight: 36 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 48, minPixelHeight: 28 },
      "compact": { minPixelWidth: 60, minPixelHeight: 30 },
      "detailed": { minPixelWidth: 120, minPixelHeight: 36 },
      "dashboard": { minPixelWidth: 200, minPixelHeight: 120 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 180, minPixelHeight: 54 },
      "dashboard": { minPixelWidth: 220, minPixelHeight: 135 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: true
  },
  "battery": {
    kind: "battery",
    supportedVariants: ["compact", "wide"],
    variants: {
      "compact": {
        label: "Compact · 1×1",
        icon: "󰁹",
        description: "Compact battery level tile with charge state",
        colSpan: 1,
        rowSpan: 1,
        minPixelWidth: 60,
        minPixelHeight: 30,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      },
      "wide": {
        label: "Wide · 2×1",
        icon: "󰂄",
        description: "Wide battery banner with linear charge meter and power rate",
        colSpan: 2,
        rowSpan: 1,
        minPixelWidth: 120,
        minPixelHeight: 36,
        aspectRatio: null,
        resizable: true,
        defaultSettings: {}
      }
    },
    footprints: {
      "compact": { colSpan: 1, rowSpan: 1, label: "Compact · 1×1", minPixelWidth: 60, minPixelHeight: 30 },
      "wide": { colSpan: 2, rowSpan: 1, label: "Wide · 2×1", minPixelWidth: 120, minPixelHeight: 36 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 48, minPixelHeight: 28 },
      "compact": { minPixelWidth: 60, minPixelHeight: 30 },
      "detailed": { minPixelWidth: 120, minPixelHeight: 36 },
      "dashboard": { minPixelWidth: 200, minPixelHeight: 120 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 180, minPixelHeight: 54 },
      "dashboard": { minPixelWidth: 220, minPixelHeight: 135 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: true
  },
  "workspace": {
    kind: "workspace",
    supportedVariants: ["compact", "wide"],
    footprints: {
      "compact": { colSpan: 1, rowSpan: 1, label: "Compact · 1×1", minPixelWidth: 60, minPixelHeight: 30 },
      "wide": { colSpan: 2, rowSpan: 1, label: "Wide · 2×1", minPixelWidth: 120, minPixelHeight: 36 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 48, minPixelHeight: 28 },
      "compact": { minPixelWidth: 60, minPixelHeight: 30 },
      "detailed": { minPixelWidth: 120, minPixelHeight: 36 },
      "dashboard": { minPixelWidth: 200, minPixelHeight: 120 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 180, minPixelHeight: 54 },
      "dashboard": { minPixelWidth: 220, minPixelHeight: 135 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: true
  },
  "app-grid": {
    kind: "app-grid",
    supportedVariants: ["compact", "wide"],
    footprints: {
      "compact": { colSpan: 2, rowSpan: 2, label: "Grid · 2×2", minPixelWidth: 120, minPixelHeight: 60 },
      "wide": { colSpan: 4, rowSpan: 2, label: "Wide · 4×2", minPixelWidth: 240, minPixelHeight: 70 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 100, minPixelHeight: 60 },
      "compact": { minPixelWidth: 120, minPixelHeight: 60 },
      "detailed": { minPixelWidth: 240, minPixelHeight: 70 },
      "dashboard": { minPixelWidth: 240, minPixelHeight: 120 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 260, minPixelHeight: 84 },
      "dashboard": { minPixelWidth: 260, minPixelHeight: 150 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: false
  },
  "folder-grid": {
    kind: "folder-grid",
    supportedVariants: ["compact", "wide"],
    footprints: {
      "compact": { colSpan: 2, rowSpan: 2, label: "Grid · 2×2", minPixelWidth: 120, minPixelHeight: 60 },
      "wide": { colSpan: 4, rowSpan: 2, label: "Wide · 4×2", minPixelWidth: 240, minPixelHeight: 70 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 100, minPixelHeight: 60 },
      "compact": { minPixelWidth: 120, minPixelHeight: 60 },
      "detailed": { minPixelWidth: 240, minPixelHeight: 70 },
      "dashboard": { minPixelWidth: 240, minPixelHeight: 120 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 260, minPixelHeight: 84 },
      "dashboard": { minPixelWidth: 260, minPixelHeight: 150 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: false
  },
  "fan-control": {
    kind: "fan-control",
    supportedVariants: ["controls"],
    footprints: {
      "controls": { colSpan: 4, rowSpan: 1, label: "Controls · 4×1", minPixelWidth: 152, minPixelHeight: 36 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 152, minPixelHeight: 36 },
      "compact": { minPixelWidth: 152, minPixelHeight: 42 },
      "detailed": { minPixelWidth: 152, minPixelHeight: 64 },
      "dashboard": { minPixelWidth: 200, minPixelHeight: 110 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 220, minPixelHeight: 64 },
      "dashboard": { minPixelWidth: 220, minPixelHeight: 135 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: true,
    defaultSettings: {
      modes: [0, 1, 2, 4]
    }
  },
  "sys-info": {
    kind: "sys-info",
    label: "System Info",
    category: "system",
    supportedVariants: ["compact", "wide"],
    footprints: {
      "compact": { colSpan: 1, rowSpan: 1, label: "1x1 Compact", minPixelWidth: 68, minPixelHeight: 40 },
      "wide": { colSpan: 2, rowSpan: 1, label: "2x1 Wide", minPixelWidth: 144, minPixelHeight: 40 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 52, minPixelHeight: 32 },
      "compact": { minPixelWidth: 68, minPixelHeight: 40 },
      "detailed": { minPixelWidth: 144, minPixelHeight: 40 },
      "dashboard": { minPixelWidth: 200, minPixelHeight: 110 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 168, minPixelHeight: 40 },
      "dashboard": { minPixelWidth: 220, minPixelHeight: 120 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: true,
    defaultSettings: {}
  },
  "todo": {
    kind: "todo",
    supportedVariants: ["compact", "list"],
    footprints: {
      "compact": { colSpan: 2, rowSpan: 1, label: "Summary · 2×1", minPixelWidth: 120, minPixelHeight: 36 },
      "list": { colSpan: 2, rowSpan: 2, label: "Task List · 2×2", minPixelWidth: 140, minPixelHeight: 80 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 48, minPixelHeight: 28 },
      "compact": { minPixelWidth: 120, minPixelHeight: 36 },
      "detailed": { minPixelWidth: 140, minPixelHeight: 70 },
      "dashboard": { minPixelWidth: 200, minPixelHeight: 120 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 160, minPixelHeight: 60 },
      "dashboard": { minPixelWidth: 220, minPixelHeight: 135 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: true
  },
  "notifications": {
    kind: "notifications",
    supportedVariants: ["compact", "recent"],
    footprints: {
      "compact": { colSpan: 2, rowSpan: 1, label: "Badge · 2×1", minPixelWidth: 120, minPixelHeight: 36 },
      "recent": { colSpan: 2, rowSpan: 2, label: "History · 2×2", minPixelWidth: 140, minPixelHeight: 80 }
    },
    supportedPresentations: ["auto", "icon", "compact", "detailed", "dashboard"],
    presentationMinimums: {
      "icon": { minPixelWidth: 48, minPixelHeight: 28 },
      "compact": { minPixelWidth: 120, minPixelHeight: 36 },
      "detailed": { minPixelWidth: 140, minPixelHeight: 70 },
      "dashboard": { minPixelWidth: 200, minPixelHeight: 120 }
    },
    autoPresentationMinimums: {
      "detailed": { minPixelWidth: 160, minPixelHeight: 60 },
      "dashboard": { minPixelWidth: 220, minPixelHeight: 135 }
    },
    allowGrowWidth: true,
    allowGrowHeight: true,
    requiresSource: false,
    singleton: true
  }
};

function _clone(val) {
  if (val === null || typeof val !== "object") {
    return val;
  }
  return JSON.parse(JSON.stringify(val));
}

function all() {
  var keys = Object.keys(REGISTRY);
  var list = [];
  for (var i = 0; i < keys.length; i++) {
    list.push(_clone(REGISTRY[keys[i]]));
  }
  return list;
}

function get(kind) {
  if (REGISTRY.hasOwnProperty(kind)) {
    return _clone(REGISTRY[kind]);
  }
  return null;
}

function has(kind) {
  return REGISTRY.hasOwnProperty(kind);
}

function supportsVariant(kind, variant) {
  if (!REGISTRY.hasOwnProperty(kind)) {
    return false;
  }
  var variantsList = REGISTRY[kind].supportedVariants;
  return variantsList.indexOf(variant) !== -1;
}

function footprint(kind, variant) {
  if (!REGISTRY.hasOwnProperty(kind)) {
    return null;
  }
  var fps = REGISTRY[kind].footprints;
  if (fps && fps.hasOwnProperty(variant)) {
    return _clone(fps[variant]);
  }
  return null;
}

function minimumFootprint(kind, variant) {
  return footprint(kind, variant);
}

function supportedPresentations(kind, variant) {
  if (!REGISTRY.hasOwnProperty(kind)) {
    return [];
  }
  return _clone(REGISTRY[kind].supportedPresentations || ["auto", "compact", "detailed"]);
}

function presentationMinimum(kind, variant, presentationMode) {
  if (!REGISTRY.hasOwnProperty(kind)) {
    return null;
  }
  var entry = REGISTRY[kind];
  var mode = (presentationMode === "auto" || !presentationMode) ? "compact" : presentationMode;
  if (entry.presentationMinimums && entry.presentationMinimums[mode]) {
    return _clone(entry.presentationMinimums[mode]);
  }
  var fp = footprint(kind, variant || entry.supportedVariants[0]);
  if (fp) {
    return { minPixelWidth: fp.minPixelWidth, minPixelHeight: fp.minPixelHeight };
  }
  return null;
}

function autoPresentationMinimum(kind, variant, presentationMode) {
  if (!REGISTRY.hasOwnProperty(kind)) {
    return null;
  }
  var entry = REGISTRY[kind];
  if (entry.autoPresentationMinimums && entry.autoPresentationMinimums[presentationMode]) {
    return _clone(entry.autoPresentationMinimums[presentationMode]);
  }
  return presentationMinimum(kind, variant, presentationMode);
}

function canAllocate(kind, variant, colSpan, rowSpan) {
  if (!REGISTRY.hasOwnProperty(kind)) {
    return false;
  }
  var fp = footprint(kind, variant);
  if (!fp) {
    return false;
  }
  if (typeof colSpan !== "number" || colSpan < fp.colSpan || Math.floor(colSpan) !== colSpan) {
    return false;
  }
  if (typeof rowSpan !== "number" || rowSpan < fp.rowSpan || Math.floor(rowSpan) !== rowSpan) {
    return false;
  }
  var entry = REGISTRY[kind];
  if (entry.variants && entry.variants[variant]) {
    var vDef = entry.variants[variant];
    if (vDef.allowedSpans && Array.isArray(vDef.allowedSpans)) {
      var matched = false;
      for (var s = 0; s < vDef.allowedSpans.length; s++) {
        if (vDef.allowedSpans[s].colSpan === colSpan && vDef.allowedSpans[s].rowSpan === rowSpan) {
          matched = true;
          break;
        }
      }
      if (!matched) {
        return false;
      }
    } else if (vDef.resizable === false) {
      if (colSpan !== fp.colSpan || rowSpan !== fp.rowSpan) {
        return false;
      }
    }
  }
  if (colSpan > fp.colSpan && !entry.allowGrowWidth) {
    return false;
  }
  if (rowSpan > fp.rowSpan && !entry.allowGrowHeight) {
    return false;
  }
  return true;
}

function validateSettings(kind, settings, variant) {
  if (!REGISTRY.hasOwnProperty(kind)) {
    return { valid: false, error: "UNKNOWN_BLOCK_KIND" };
  }
  if (settings === undefined || settings === null) {
    settings = {};
  }
  if (typeof settings !== "object" || Array.isArray(settings)) {
    return { valid: false, error: "INVALID_SETTINGS_OBJECT" };
  }

  if (kind === "fan-control") {
    var rawModes = settings.modes;
    if (rawModes === undefined) {
      return { valid: true, settings: { modes: [0, 1, 2, 4] } };
    }
    if (!Array.isArray(rawModes) || rawModes.length === 0) {
      return { valid: false, error: "FAN_MODE_UNSUPPORTED" };
    }
    var seen = Object.create(null);
    var cleanModes = [];
    for (var i = 0; i < rawModes.length; i++) {
      var m = rawModes[i];
      if (typeof m !== "number" || ALLOWED_FAN_MODES.indexOf(m) === -1 || Math.floor(m) !== m) {
        return { valid: false, error: "FAN_MODE_UNSUPPORTED" };
      }
      if (seen[m]) {
        return { valid: false, error: "FAN_MODE_DUPLICATE" };
      }
      seen[m] = true;
      cleanModes.push(m);
    }
    return { valid: true, settings: { modes: cleanModes } };
  }

  if (kind === "app-grid" || kind === "folder-grid") {
    var items = Array.isArray(settings.items) ? settings.items : [];
    // Dynamic capacity ceiling: allow up to 64 configured items in settings.
    // Display scaling and responsive geometry are handled dynamically by presentation layer.
    var capacity = 64;
    if (items.length > capacity) {
      return { valid: false, error: "GRID_CAPACITY_EXCEEDED" };
    }
    var cleanItems = [];
    for (var j = 0; j < items.length; j++) {
      var item = items[j];
      if (!item || typeof item !== "object" || Array.isArray(item) ||
          typeof item.name !== "string" || !item.name.trim()) {
        return { valid: false, error: "INVALID_GRID_ITEM" };
      }
      if (item.icon !== undefined && typeof item.icon !== "string") {
        return { valid: false, error: "INVALID_GRID_ITEM" };
      }
      var cleanItem = {
        name: item.name.trim(),
        icon: typeof item.icon === "string" ? item.icon.trim() : ""
      };
      if (typeof item.id === "string" && item.id.trim()) {
        cleanItem.id = item.id.trim();
      } else {
        cleanItem.id = "item_" + (j + 1) + "_" + Math.random().toString(36).substr(2, 7);
      }
      if (kind === "app-grid") {
        var cmd = (typeof item.command === "string") ? item.command.trim() : (typeof item.desktopId === "string" ? item.desktopId.trim() : "");
        if (!cmd) {
          return { valid: false, error: "INVALID_GRID_ITEM" };
        }
        cleanItem.command = cmd;
        if (item.sub !== undefined && typeof item.sub === "string") {
          cleanItem.sub = item.sub.trim();
        }
        if (item.desktopId !== undefined && typeof item.desktopId === "string") {
          cleanItem.desktopId = item.desktopId.trim();
        }
      } else {
        if (typeof item.path !== "string" || !item.path.trim()) {
          return { valid: false, error: "INVALID_GRID_ITEM" };
        }
        cleanItem.path = item.path.trim();
        if (item.isFile !== undefined) {
          cleanItem.isFile = Boolean(item.isFile);
        }
      }
      cleanItems.push(cleanItem);
    }
    return { valid: true, settings: { items: cleanItems } };
  }

  return { valid: true, settings: _clone(settings) };
}

function variants(kind) {
  if (!REGISTRY.hasOwnProperty(kind)) {
    return [];
  }
  var entry = REGISTRY[kind];
  var list = [];
  for (var i = 0; i < entry.supportedVariants.length; i++) {
    var vName = entry.supportedVariants[i];
    var fp = entry.footprints ? entry.footprints[vName] : null;
    var vDef = (entry.variants && entry.variants[vName]) ? entry.variants[vName] : null;
    if (fp || vDef) {
      var item = {
        variant: vName,
        label: (vDef && vDef.label) || (fp && fp.label) || vName,
        colSpan: (vDef && typeof vDef.colSpan === "number") ? vDef.colSpan : (fp ? fp.colSpan : 1),
        rowSpan: (vDef && typeof vDef.rowSpan === "number") ? vDef.rowSpan : (fp ? fp.rowSpan : 1),
        minPixelWidth: (vDef && typeof vDef.minPixelWidth === "number") ? vDef.minPixelWidth : (fp ? fp.minPixelWidth : 60),
        minPixelHeight: (vDef && typeof vDef.minPixelHeight === "number") ? vDef.minPixelHeight : (fp ? fp.minPixelHeight : 30)
      };
      if (vDef) {
        if (vDef.icon) item.icon = vDef.icon;
        if (vDef.description) item.description = vDef.description;
        if (vDef.aspectRatio !== undefined) item.aspectRatio = vDef.aspectRatio;
        if (vDef.resizable !== undefined) item.resizable = vDef.resizable;
        if (vDef.allowedSpans) item.allowedSpans = _clone(vDef.allowedSpans);
        if (vDef.defaultSettings) item.defaultSettings = _clone(vDef.defaultSettings);
      }
      list.push(item);
    }
  }
  return list;
}

function getVariant(kind, variant) {
  if (!REGISTRY.hasOwnProperty(kind)) {
    return null;
  }
  var entry = REGISTRY[kind];
  if (entry.variants && entry.variants.hasOwnProperty(variant)) {
    var vDef = entry.variants[variant];
    var fp = entry.footprints ? entry.footprints[variant] : null;
    var res = _clone(vDef);
    res.variant = variant;
    if (typeof res.colSpan !== "number" && fp) res.colSpan = fp.colSpan;
    if (typeof res.rowSpan !== "number" && fp) res.rowSpan = fp.rowSpan;
    if (typeof res.minPixelWidth !== "number" && fp) res.minPixelWidth = fp.minPixelWidth;
    if (typeof res.minPixelHeight !== "number" && fp) res.minPixelHeight = fp.minPixelHeight;
    return res;
  }
  var fpDefault = footprint(kind, variant);
  if (fpDefault) {
    return {
      variant: variant,
      label: fpDefault.label,
      colSpan: fpDefault.colSpan,
      rowSpan: fpDefault.rowSpan,
      minPixelWidth: fpDefault.minPixelWidth,
      minPixelHeight: fpDefault.minPixelHeight
    };
  }
  return null;
}

function isSingleton(kind) {
  if (!REGISTRY.hasOwnProperty(kind)) {
    return false;
  }
  return Boolean(REGISTRY[kind].singleton);
}

function supportsSource(kind, source) {
  if (kind !== "metric") {
    return false;
  }
  return ALLOWED_METRIC_SOURCES.indexOf(source) !== -1;
}

function normalizeBlock(block) {
  if (!block || typeof block !== "object") {
    return null;
  }
  var kind = block.kind;
  if (!has(kind)) {
    return null;
  }
  var variant = block.variant;
  if (!supportsVariant(kind, variant)) {
    variant = REGISTRY[kind].supportedVariants[0];
  }
  var fp = footprint(kind, variant);
  if (!fp) {
    return null;
  }

  // Normalized allocated spans (never below registry footprint)
  var requestedColSpan = fp.colSpan;
  var requestedRowSpan = fp.rowSpan;
  var hasManualAnchor = false;
  var colAnchor = 0;
  var rowAnchor = 0;

  if (block.layout && typeof block.layout === "object" && !Array.isArray(block.layout)) {
    var lCol = (typeof block.layout.colSpan === "number") ? Math.floor(block.layout.colSpan) : fp.colSpan;
    var lRow = (typeof block.layout.rowSpan === "number") ? Math.floor(block.layout.rowSpan) : fp.rowSpan;
    if (canAllocate(kind, variant, lCol, lRow)) {
      requestedColSpan = lCol;
      requestedRowSpan = lRow;
    }
    if (typeof block.layout.col === "number" && block.layout.col >= 0 && Math.floor(block.layout.col) === block.layout.col &&
        typeof block.layout.row === "number" && block.layout.row >= 0 && Math.floor(block.layout.row) === block.layout.row) {
      hasManualAnchor = true;
      colAnchor = block.layout.col;
      rowAnchor = block.layout.row;
    }
  }

  var presentationMode = "auto";
  if (typeof block.presentationMode === "string" && PRESENTATION_MODES.indexOf(block.presentationMode) !== -1) {
    presentationMode = block.presentationMode;
  }

  var sRes = validateSettings(kind, block.settings, variant);
  var validSettings = sRes.valid ? sRes.settings : (REGISTRY[kind].defaultSettings ? _clone(REGISTRY[kind].defaultSettings) : {});

  var normalized = {
    id: typeof block.id === "string" ? block.id.trim() : "",
    kind: kind,
    variant: variant,
    order: (typeof block.order === "number" && block.order >= 0) ? Math.floor(block.order) : 0,
    colSpan: requestedColSpan,
    rowSpan: requestedRowSpan,
    presentationMode: presentationMode,
    layout: {
      colSpan: requestedColSpan,
      rowSpan: requestedRowSpan
    },
    settings: validSettings
  };

  if (hasManualAnchor) {
    normalized.layout.col = colAnchor;
    normalized.layout.row = rowAnchor;
  }

  if (REGISTRY[kind].requiresSource) {
    normalized.source = typeof block.source === "string" ? block.source.trim() : "";
  }

  return normalized;
}

var CONTAINER_DOMAINS = [
  {
    id: "clock",
    title: "Time & Calendar",
    shortLabel: "Clock",
    icon: "󰥔",
    description: "Dedicated timekeeping, monthly calendar & workspace status",
    defaultFootprint: { colSpan: 2, rowSpan: 1 },
    allowedShapes: [
      { colSpan: 1, rowSpan: 1, label: "1×1 Compact", subtitle: "Desk clock & date card" },
      { colSpan: 2, rowSpan: 1, label: "2×1 Wide Banner", subtitle: "Clock + 7-day week strip" },
      { colSpan: 2, rowSpan: 2, label: "2×2 Full Calendar", subtitle: "Clock + full monthly grid" }
    ],
    blocks: [
      { kind: "time", variant: "wide", source: "", label: "System Clock", subtitle: "Digital clock, uptime & host badge", icon: "󰥔" },
      { kind: "date", variant: "wide", source: "", label: "Calendar & Date", subtitle: "Day, 7-day week strip & monthly grid", icon: "󰃭" },
      { kind: "workspace", variant: "compact", source: "", label: "Active Workspace", subtitle: "Current Hyprland workspace indicator", icon: "󰖲" }
    ]
  },
  {
    id: "system",
    title: "System Performance",
    shortLabel: "System",
    icon: "󰍛",
    description: "Core processor, memory, storage & system identity",
    defaultFootprint: { colSpan: 2, rowSpan: 1 },
    allowedShapes: [
      { colSpan: 1, rowSpan: 1, label: "1×1 Compact", subtitle: "Compact 2×2 metric tiles" },
      { colSpan: 2, rowSpan: 1, label: "2×1 Wide Bar", subtitle: "Horizontal performance strip" },
      { colSpan: 2, rowSpan: 2, label: "2×2 Full Dashboard", subtitle: "Detailed gauges & system overview" }
    ],
    blocks: [
      { kind: "metric", variant: "compact", source: "cpu.percent", label: "CPU Usage", subtitle: "Processor load & hardware model", icon: "󰍛" },
      { kind: "metric", variant: "compact", source: "ram.percent", label: "Memory Usage", subtitle: "RAM utilization & used/total GB", icon: "󰘚" },
      { kind: "metric", variant: "compact", source: "disk.percent", label: "Storage Usage", subtitle: "Filesystem capacity & disk usage", icon: "󰋊" },
      { kind: "metric", variant: "compact", source: "disk.hdd", label: "HDD Storage", subtitle: "Secondary drive capacity & usage", icon: "󰋊" },
      { kind: "sys-info", variant: "wide", source: "", label: "System Identity", subtitle: "OS, hostname, kernel, CPU, load avg & swap", icon: "󰌽" }
    ]
  },
  {
    id: "fan",
    title: "Thermal & Fan",
    shortLabel: "Thermal",
    icon: "󰈐",
    description: "Hardware cooling profiles & thermal sensor telemetry",
    defaultFootprint: { colSpan: 2, rowSpan: 2 },
    allowedShapes: [
      { colSpan: 2, rowSpan: 1, label: "2×1 Controls Strip", subtitle: "Compact fan profile bar" },
      { colSpan: 2, rowSpan: 2, label: "2×2 Thermal Dashboard", subtitle: "Fan modes + 4 thermal sensors" }
    ],
    blocks: [
      { kind: "fan-control", variant: "controls", source: "", label: "Fan Profile Controls", subtitle: "Quiet, Standard, Clean & Boost modes", icon: "󰈐" },
      { kind: "metric", variant: "compact", source: "temperature.cpu", label: "CPU Temperature", subtitle: "Processor package thermal sensor", icon: "󰔏" },
      { kind: "metric", variant: "compact", source: "temperature.gpu", label: "GPU Temperature", subtitle: "Graphics core thermal sensor", icon: "󰔏" },
      { kind: "metric", variant: "compact", source: "temperature.nvme", label: "NVMe Temperature", subtitle: "Solid-state drive thermal sensor", icon: "󰔏" },
      { kind: "metric", variant: "compact", source: "temperature.hdd", label: "HDD Temperature", subtitle: "Secondary storage thermal sensor", icon: "󰔏" }
    ]
  },
  {
    id: "network",
    title: "Network & Power",
    shortLabel: "Network",
    icon: "󰤨",
    description: "Connectivity dashboard, IP/SSID, throughput & battery state",
    defaultFootprint: { colSpan: 2, rowSpan: 1 },
    allowedShapes: [
      { colSpan: 1, rowSpan: 1, label: "1×1 Compact", subtitle: "Compact Wi-Fi & battery card" },
      { colSpan: 2, rowSpan: 1, label: "2×1 Wide Strip", subtitle: "Live traffic speeds & power bar" },
      { colSpan: 2, rowSpan: 2, label: "2×2 Full Dashboard", subtitle: "SSID, IPv4, totals & power dashboard" }
    ],
    blocks: [
      { kind: "network", variant: "wide", source: "", label: "Network Dashboard", subtitle: "SSID, IPv4, interface & traffic totals", icon: "󰤨" },
      { kind: "battery", variant: "wide", source: "", label: "Battery & Power", subtitle: "Charge level, wattage & remaining time", icon: "󰁹" },
      { kind: "metric", variant: "compact", source: "network.download", label: "Download Gauge", subtitle: "Dedicated live download speed card", icon: "󰇚" },
      { kind: "metric", variant: "compact", source: "network.upload", label: "Upload Gauge", subtitle: "Dedicated live upload speed card", icon: "󰕒" }
    ]
  },
  {
    id: "apps",
    title: "Applications",
    shortLabel: "Apps",
    icon: "󰅩",
    description: "Pinned desktop application launchers grid",
    defaultFootprint: { colSpan: 1, rowSpan: 1 },
    allowedShapes: [
      { colSpan: 1, rowSpan: 1, label: "1×1 Square (2×2)", subtitle: "2 columns × 2 rows compact grid" },
      { colSpan: 1, rowSpan: 2, label: "1×2 Tall List (1 Col)", subtitle: "1 vertical column of stacked rows" },
      { colSpan: 2, rowSpan: 1, label: "2×1 Wide Grid (4 Cols)", subtitle: "Multi-column horizontal app bar" },
      { colSpan: 2, rowSpan: 2, label: "2×2 Large Grid", subtitle: "Spacious multi-column & row grid" }
    ],
    blocks: [
      { kind: "app-grid", variant: "compact", source: "", label: "Applications Grid", subtitle: "Pinned desktop application shortcuts", icon: "󰅩" },
      { kind: "folder-grid", variant: "compact", source: "", label: "Folders Grid", subtitle: "Quick access to pinned directories & files", icon: "󰉋" }
    ]
  },
  {
    id: "folders",
    title: "Folders",
    shortLabel: "Folders",
    icon: "󰉋",
    description: "Quick directory & project folder shortcuts grid",
    defaultFootprint: { colSpan: 1, rowSpan: 1 },
    allowedShapes: [
      { colSpan: 1, rowSpan: 1, label: "1×1 Square (2×2)", subtitle: "2 columns × 2 rows folder grid" },
      { colSpan: 1, rowSpan: 2, label: "1×2 Tall List (1 Col)", subtitle: "1 vertical column of stacked rows" },
      { colSpan: 2, rowSpan: 1, label: "2×1 Wide Grid (4 Cols)", subtitle: "Multi-column horizontal folder bar" },
      { colSpan: 2, rowSpan: 2, label: "2×2 Large Grid", subtitle: "Spacious multi-column & row grid" }
    ],
    blocks: [
      { kind: "folder-grid", variant: "compact", source: "", label: "Folders Grid", subtitle: "Quick access to pinned directories & files", icon: "󰉋" },
      { kind: "app-grid", variant: "compact", source: "", label: "Applications Grid", subtitle: "Pinned desktop application shortcuts", icon: "󰅩" }
    ]
  },
  {
    id: "todo",
    title: "To-Do List",
    shortLabel: "Tasks",
    icon: "󰄱",
    description: "Persistent tasks & checklist from Omarchy To-Do List plugin",
    defaultFootprint: { colSpan: 2, rowSpan: 2 },
    allowedShapes: [
      { colSpan: 2, rowSpan: 1, label: "2×1 Compact", subtitle: "Open task count & quick strip" },
      { colSpan: 2, rowSpan: 2, label: "2×2 Full List", subtitle: "Scrollable interactive task checklist" }
    ],
    blocks: [
      { kind: "todo", variant: "list", source: "", label: "To-Do Tasks", subtitle: "Interactive task checklist", icon: "󰄱" }
    ]
  },
  {
    id: "notifications",
    title: "Notifications & Alerts",
    shortLabel: "Alerts",
    icon: "󰂚",
    description: "Recent system notification history & Do Not Disturb toggle",
    defaultFootprint: { colSpan: 2, rowSpan: 2 },
    allowedShapes: [
      { colSpan: 2, rowSpan: 1, label: "2×1 Compact", subtitle: "DND status & latest toast badge" },
      { colSpan: 2, rowSpan: 2, label: "2×2 Full History", subtitle: "Notification history cards stack" }
    ],
    blocks: [
      { kind: "notifications", variant: "recent", source: "", label: "Notifications Feed", subtitle: "System alerts & DND controller", icon: "󰂚" }
    ]
  }
];

function containerDomains() {
  return _clone(CONTAINER_DOMAINS);
}

function containerDomain(domainId) {
  if (typeof domainId !== "string") {
    return _clone(CONTAINER_DOMAINS[1]);
  }
  for (var i = 0; i < CONTAINER_DOMAINS.length; i++) {
    if (CONTAINER_DOMAINS[i].id === domainId) {
      return _clone(CONTAINER_DOMAINS[i]);
    }
  }
  return _clone(CONTAINER_DOMAINS[1]);
}

function domainShapes(domainId) {
  var dom = containerDomain(domainId);
  if (dom && Array.isArray(dom.allowedShapes) && dom.allowedShapes.length > 0) {
    return _clone(dom.allowedShapes);
  }
  return [
    { colSpan: 1, rowSpan: 1, label: "1×1 Compact", subtitle: "Compact card" },
    { colSpan: 2, rowSpan: 1, label: "2×1 Wide", subtitle: "Wide horizontal card" },
    { colSpan: 2, rowSpan: 2, label: "2×2 Large", subtitle: "Full dashboard card" }
  ];
}

function inferContainerDomain(container) {
  if (!container || typeof container !== "object") {
    return "system";
  }
  if (typeof container.domain === "string") {
    for (var d = 0; d < CONTAINER_DOMAINS.length; d++) {
      if (CONTAINER_DOMAINS[d].id === container.domain) {
        return container.domain;
      }
    }
  }

  var blocks = Array.isArray(container.blocks) ? container.blocks : [];
  for (var i = 0; i < blocks.length; i++) {
    var b = blocks[i];
    if (!b || typeof b !== "object") continue;
    var k = String(b.kind || "");
    var src = String(b.source || "");
    if (k === "time" || k === "date" || k === "workspace") return "clock";
    if (k === "fan-control" || src.indexOf("temperature.") === 0 || src === "fan.mode") return "fan";
    if (k === "network" || k === "battery" || src.indexOf("network.") === 0) return "network";
    if (k === "app-grid") return "apps";
    if (k === "folder-grid") return "folders";
    if (k === "todo") return "todo";
    if (k === "notifications") return "notifications";
    if (k === "sys-info" || src === "cpu.percent" || src === "ram.percent" || src === "disk.percent" || src === "disk.hdd") return "system";
  }

  var hint = (String(container.id || "") + " " + String(container.title || "")).toLowerCase();
  if (hint.indexOf("clock") !== -1 || hint.indexOf("time") !== -1 || hint.indexOf("date") !== -1 || hint.indexOf("calendar") !== -1) {
    return "clock";
  }
  if (hint.indexOf("fan") !== -1 || hint.indexOf("thermal") !== -1 || hint.indexOf("temp") !== -1) {
    return "fan";
  }
  if (hint.indexOf("net") !== -1 || hint.indexOf("battery") !== -1 || hint.indexOf("power") !== -1 || hint.indexOf("wifi") !== -1) {
    return "network";
  }
  if (hint.indexOf("app") !== -1 || hint.indexOf("dev") !== -1) {
    return "apps";
  }
  if (hint.indexOf("folder") !== -1 || hint.indexOf("file") !== -1 || hint.indexOf("project") !== -1) {
    return "folders";
  }
  if (hint.indexOf("todo") !== -1 || hint.indexOf("task") !== -1) {
    return "todo";
  }
  if (hint.indexOf("notif") !== -1 || hint.indexOf("alert") !== -1 || hint.indexOf("bell") !== -1) {
    return "notifications";
  }
  return "system";
}

function domainBlocks(domainId) {
  var dom = containerDomain(domainId);
  return dom && Array.isArray(dom.blocks) ? _clone(dom.blocks) : [];
}

function isBlockAllowedInDomain(domainId, kind, source) {
  var blocks = domainBlocks(domainId);
  var normSource = typeof source === "string" ? source.trim() : "";
  for (var i = 0; i < blocks.length; i++) {
    var entry = blocks[i];
    if (entry.kind === kind) {
      if (kind === "metric") {
        if (entry.source === normSource) return true;
      } else {
        return true;
      }
    }
  }
  return false;
}

var BlockRegistry = {
  all: all,
  get: get,
  getVariant: getVariant,
  has: has,
  supportsVariant: supportsVariant,
  footprint: footprint,
  minimumFootprint: minimumFootprint,
  supportedPresentations: supportedPresentations,
  presentationMinimum: presentationMinimum,
  autoPresentationMinimum: autoPresentationMinimum,
  canAllocate: canAllocate,
  validateSettings: validateSettings,
  variants: variants,
  normalizeBlock: normalizeBlock,
  isSingleton: isSingleton,
  supportsSource: supportsSource,
  containerDomains: containerDomains,
  containerDomain: containerDomain,
  domainShapes: domainShapes,
  inferContainerDomain: inferContainerDomain,
  domainBlocks: domainBlocks,
  isBlockAllowedInDomain: isBlockAllowedInDomain
};

if (typeof globalThis !== "undefined") {
  globalThis.BlockRegistry = BlockRegistry;
}
