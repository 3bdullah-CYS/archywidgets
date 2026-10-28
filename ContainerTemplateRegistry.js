/**
 * OmaDesk Container Template Registry
 * Defines all preconfigured container presets, including their initial blocks,
 * dimensions, header modes, and layout modes.
 * Single source of truth for container templates.
 */
.pragma library

var TEMPLATES = [
  {
    id: "clock",
    title: "Time & Calendar",
    category: "general",
    icon: "󰥔",
    span: "2×2",
    colSpan: 2,
    rowSpan: 2,
    headerMode: "none",
    layoutMode: "auto",
    desc: "Clock & monthly calendar",
    blocks: [
      { kind: "time", variant: "compact", order: 0, settings: { showSeconds: false } },
      { kind: "date", variant: "compact", order: 1, settings: {} }
    ]
  },
  {
    id: "system",
    title: "System Metrics",
    category: "system",
    icon: "󰍛",
    span: "1×1",
    colSpan: 1,
    rowSpan: 1,
    headerMode: "compact",
    layoutMode: "auto",
    desc: "CPU, RAM & Disk load",
    blocks: [
      { kind: "metric", source: "cpu.percent", variant: "compact", order: 0 },
      { kind: "metric", source: "ram.percent", variant: "compact", order: 1 },
      { kind: "metric", source: "disk.percent", variant: "compact", order: 2 }
    ]
  },
  {
    id: "battery",
    title: "Battery & Power",
    category: "hardware",
    icon: "󰁹",
    span: "1×1",
    colSpan: 1,
    rowSpan: 1,
    headerMode: "compact",
    layoutMode: "auto",
    desc: "Battery charge & power status",
    capability: "battery",
    blocks: [
      { kind: "battery", variant: "compact", order: 0, settings: {} }
    ]
  },
  {
    id: "network",
    title: "Network Monitor",
    category: "system",
    icon: "󰤨",
    span: "1×1",
    colSpan: 1,
    rowSpan: 1,
    headerMode: "compact",
    layoutMode: "auto",
    desc: "Connection status & telemetry",
    blocks: [
      { kind: "network", variant: "compact", order: 0, settings: {} }
    ]
  },
  {
    id: "folders",
    title: "Folders & Media",
    category: "files",
    icon: "󰉋",
    span: "2×1",
    colSpan: 2,
    rowSpan: 1,
    headerMode: "compact",
    layoutMode: "auto",
    desc: "Quick links to common folders",
    blocks: [
      {
        kind: "folder-grid",
        variant: "compact",
        order: 0,
        settings: {
          items: [
            { name: "Home", icon: "user-home", path: "~" },
            { name: "Documents", icon: "folder-documents", path: "~/Documents" },
            { name: "Downloads", icon: "folder-download", path: "~/Downloads" },
            { name: "Pictures", icon: "folder-pictures", path: "~/Pictures" }
          ]
        }
      }
    ]
  },
  {
    id: "apps",
    title: "Applications Hub",
    category: "apps",
    icon: "󰀻",
    span: "2×2",
    colSpan: 2,
    rowSpan: 2,
    headerMode: "compact",
    layoutMode: "auto",
    desc: "Quick-launch app shortcuts",
    blocks: [
      {
        kind: "app-grid",
        variant: "compact",
        order: 0,
        settings: {
          items: [
            { name: "Terminal", icon: "utilities-terminal", command: "foot" },
            { name: "Browser", icon: "internet-web-browser", command: "xdg-open https://" },
            { name: "Files", icon: "system-file-manager", command: "thunar" },
            { name: "Editor", icon: "accessories-text-editor", command: "gedit" }
          ]
        }
      }
    ]
  },
  {
    id: "fan",
    title: "Fan & Thermals",
    category: "hardware",
    icon: "󰈐",
    span: "2×2",
    colSpan: 2,
    rowSpan: 2,
    headerMode: "compact",
    layoutMode: "auto",
    desc: "Cooling & temperature sensors",
    capability: "fan-control",
    blocks: [
      { kind: "fan-control", variant: "controls", order: 0, settings: { modes: [0, 1, 2, 4] } },
      { kind: "metric", source: "temperature.cpu", variant: "compact", order: 1 },
      { kind: "metric", source: "temperature.gpu", variant: "compact", order: 2 },
      { kind: "metric", source: "temperature.nvme", variant: "compact", order: 3 },
      { kind: "metric", source: "temperature.hdd", variant: "compact", order: 4 }
    ]
  },
  {
    id: "todo",
    title: "To-Do List",
    category: "productivity",
    icon: "󰄱",
    span: "2×2",
    colSpan: 2,
    rowSpan: 2,
    headerMode: "compact",
    layoutMode: "auto",
    desc: "Omarchy checklist & tasks",
    blocks: [
      { kind: "todo", variant: "list", order: 0, settings: {} }
    ]
  },
  {
    id: "notifications",
    title: "Notifications",
    category: "system",
    icon: "󰂚",
    span: "2×2",
    colSpan: 2,
    rowSpan: 2,
    headerMode: "compact",
    layoutMode: "auto",
    desc: "Recent alerts & DND toggle",
    blocks: [
      { kind: "notifications", variant: "recent", order: 0, settings: {} }
    ]
  },
  {
    id: "workspaces",
    title: "Workspaces",
    category: "system",
    icon: "󰍹",
    span: "1×1",
    colSpan: 1,
    rowSpan: 1,
    headerMode: "compact",
    layoutMode: "auto",
    desc: "Active virtual desktops",
    blocks: [
      { kind: "workspace", variant: "compact", order: 0, settings: {} }
    ]
  }
];

function _cloneTemplate(obj) {
  return JSON.parse(JSON.stringify(obj));
}

function getAllTemplates() {
  return _cloneTemplate(TEMPLATES);
}

function all() {
  return getAllTemplates();
}

function getTemplate(templateId) {
  if (typeof templateId !== "string") return null;
  var target = templateId.trim().toLowerCase();
  for (var i = 0; i < TEMPLATES.length; i++) {
    if (TEMPLATES[i].id.toLowerCase() === target) {
      return _cloneTemplate(TEMPLATES[i]);
    }
  }
  return null;
}

function get(templateId) {
  return getTemplate(templateId);
}

function hasTemplate(templateId) {
  return getTemplate(templateId) !== null;
}

function has(templateId) {
  return hasTemplate(templateId);
}

function createContainerFromTemplate(templateId, newContainerId, reg) {
  var tId = (typeof templateId === "string" && templateId.trim()) ? templateId.trim().toLowerCase() : "custom";
  var tpl = getTemplate(tId);

  if (!tpl || tId === "custom") {
    return {
      id: newContainerId,
      title: "Custom",
      enabled: true,
      colSpan: 1,
      rowSpan: 1,
      headerMode: "none",
      layoutMode: "auto",
      blocks: []
    };
  }

  var container = {
    id: newContainerId,
    title: tpl.title || "",
    enabled: true,
    colSpan: tpl.colSpan || 1,
    rowSpan: tpl.rowSpan || 1,
    headerMode: tpl.headerMode || "none",
    layoutMode: tpl.layoutMode || "auto",
    blocks: []
  };

  var rawBlocks = Array.isArray(tpl.blocks) ? tpl.blocks : [];
  for (var i = 0; i < rawBlocks.length; i++) {
    var raw = rawBlocks[i];
    var safeKind = (raw.kind || "block").replace(/[^a-zA-Z0-9_]/g, "_");
    var safeSrc = raw.source ? ("_" + raw.source.replace(/[^a-zA-Z0-9_]/g, "_")) : "";
    var blockSpec = {
      id: "block_" + newContainerId + "_" + safeKind + safeSrc + "_" + i,
      kind: raw.kind,
      variant: raw.variant,
      order: i,
      settings: raw.settings ? _cloneTemplate(raw.settings) : {}
    };
    if (raw.source) {
      blockSpec.source = raw.source;
    }

    var norm = (reg && typeof reg.normalizeBlock === "function") ? reg.normalizeBlock(blockSpec) : blockSpec;
    if (norm) {
      container.blocks.push(norm);
    }
  }

  return container;
}

var ContainerTemplateRegistry = {
  all: getAllTemplates,
  get: getTemplate,
  has: hasTemplate,
  getAllTemplates: getAllTemplates,
  getTemplate: getTemplate,
  hasTemplate: hasTemplate,
  createContainerFromTemplate: createContainerFromTemplate
};

if (typeof globalThis !== "undefined") {
  globalThis.ContainerTemplateRegistry = ContainerTemplateRegistry;
}
