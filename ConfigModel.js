/**
 * ArchyWidgets Config Model
 * Version 2 configuration migration, normalization, validation, and cloning.
 */
.pragma library
.import "BlockRegistry.js" as BlockRegistry

function _getRegistry() {
  if (typeof BlockRegistry !== "undefined" && BlockRegistry && typeof BlockRegistry.has === "function") {
    return BlockRegistry;
  }
  if (typeof globalThis !== "undefined" && globalThis.BlockRegistry) {
    return globalThis.BlockRegistry;
  }
  throw new Error("BlockRegistry library not found");
}

function _isArray(val) {
  if (Array.isArray(val)) return true;
  if (val !== null && typeof val === "object" && typeof val.length === "number" && !isNaN(val.length) && val.length >= 0) {
    if (typeof val.splice === "function" || typeof val.slice === "function" || (val.constructor && val.constructor.name === "QJSValue")) {
      return true;
    }
  }
  return false;
}

function clone(value) {
  if (value === null || typeof value !== "object") {
    return value;
  }
  try {
    return JSON.parse(JSON.stringify(value));
  } catch (e) {
    if (_isArray(value)) {
      var arr = [];
      for (var i = 0; i < value.length; i++) {
        arr.push(clone(value[i]));
      }
      return arr;
    }
    var obj = {};
    var keys = Object.keys(value);
    for (var k = 0; k < keys.length; k++) {
      obj[keys[k]] = clone(value[keys[k]]);
    }
    return obj;
  }
}

function normalizeV2(config) {
  if (!config || typeof config !== "object") {
    return null;
  }
  var reg = _getRegistry();
  var c = clone(config);

  var normalized = {
    schemaVersion: 2,
    targetWorkspace: (typeof c.targetWorkspace === "number" && !isNaN(c.targetWorkspace)) ? Math.floor(c.targetWorkspace) : 1,
    deskClosed: Boolean(c.deskClosed),
    autoHideOnWindows: c.autoHideOnWindows !== false,
    cardOpacity: (typeof c.cardOpacity === "number" && !isNaN(c.cardOpacity)) ? c.cardOpacity : 0.45,
    layoutMode: (typeof c.layoutMode === "string" && c.layoutMode === "manual") ? "manual" : "auto"
  };

  if (c.occupiedOpacity !== undefined && typeof c.occupiedOpacity === "number") {
    normalized.occupiedOpacity = c.occupiedOpacity;
  }

  var rawContainers = Array.isArray(c.containers) ? c.containers : [];
  var sortedContainers = rawContainers.slice().sort(function(a, b) {
    var oa = (a && typeof a.order === "number") ? a.order : 0;
    var ob = (b && typeof b.order === "number") ? b.order : 0;
    return oa - ob;
  });

  var containers = [];
  for (var i = 0; i < sortedContainers.length; i++) {
    var rawC = sortedContainers[i];
    if (!rawC || typeof rawC !== "object") continue;

    var containerId = (typeof rawC.id === "string" && rawC.id.trim()) ? rawC.id.trim() : ("container_" + i);
    var colSpan = (typeof rawC.colSpan === "number") ? Math.max(1, Math.min(4, Math.floor(rawC.colSpan))) : 1;
    var rowSpan = (typeof rawC.rowSpan === "number") ? Math.max(1, Math.min(3, Math.floor(rawC.rowSpan))) : 1;
    var headerMode = (typeof rawC.headerMode === "string" && ["none", "compact", "normal"].indexOf(rawC.headerMode) !== -1)
      ? rawC.headerMode
      : "none";
    var layoutMode = (typeof rawC.layoutMode === "string" && rawC.layoutMode === "manual") ? "manual" : "auto";

    var rawBlocks = Array.isArray(rawC.blocks) ? rawC.blocks : [];
    var sortedBlocks = rawBlocks.slice().sort(function(a, b) {
      var oa = (a && typeof a.order === "number") ? a.order : 0;
      var ob = (b && typeof b.order === "number") ? b.order : 0;
      return oa - ob;
    });

    var blocks = [];
    for (var j = 0; j < sortedBlocks.length; j++) {
      var rawB = sortedBlocks[j];
      var nb = reg.normalizeBlock(rawB);
      if (nb) {
        nb.order = j;
        if (layoutMode === "auto" && nb.layout) {
          delete nb.layout.col;
          delete nb.layout.row;
        }
        blocks.push(nb);
      }
    }

    var containerObj = {
      id: containerId,
      title: typeof rawC.title === "string" ? rawC.title : "",
      enabled: rawC.enabled !== false,
      order: i,
      colSpan: colSpan,
      rowSpan: rowSpan,
      headerMode: headerMode,
      layoutMode: layoutMode,
      blocks: blocks
    };

    if (rawC.legacy && typeof rawC.legacy === "object" && !Array.isArray(rawC.legacy)) {
      containerObj.legacy = clone(rawC.legacy);
    }

    if (typeof rawC.col === "number" && isFinite(rawC.col) && rawC.col >= 0) {
      containerObj.col = Math.floor(rawC.col);
    }
    if (typeof rawC.row === "number" && isFinite(rawC.row) && rawC.row >= 0) {
      containerObj.row = Math.floor(rawC.row);
    }

    containers.push(containerObj);
  }

  normalized.containers = containers;
  return normalized;
}

function validateV2(rawConfig) {
  var errors = [];
  var warnings = [];

  if (!rawConfig || typeof rawConfig !== "object" || Array.isArray(rawConfig)) {
    return {
      ok: false,
      value: null,
      errors: [{ code: "INVALID_ROOT", path: "" }],
      warnings: warnings
    };
  }

  var config = clone(rawConfig);

  if (config.schemaVersion !== 2) {
    errors.push({ code: "INVALID_SCHEMA_VERSION", path: "schemaVersion" });
  }

  if (config.layoutMode !== undefined && config.layoutMode !== null) {
    if (typeof config.layoutMode !== "string" || (config.layoutMode !== "auto" && config.layoutMode !== "manual")) {
      errors.push({ code: "INVALID_LAYOUT_MODE", path: "layoutMode" });
    }
  }

  if (!Array.isArray(config.containers)) {
    errors.push({ code: "INVALID_CONTAINERS", path: "containers" });
    return {
      ok: false,
      value: null,
      errors: errors,
      warnings: warnings
    };
  }

  var reg = _getRegistry();
  var seenContainerIds = Object.create(null);

  for (var i = 0; i < config.containers.length; i++) {
    var cPath = "containers[" + i + "]";
    var c = config.containers[i];

    if (!c || typeof c !== "object" || Array.isArray(c)) {
      errors.push({ code: "INVALID_CONTAINER", path: cPath });
      continue;
    }

    if (typeof c.id !== "string" || !c.id.trim()) {
      errors.push({ code: "INVALID_CONTAINER_ID", path: cPath + ".id" });
    } else {
      var cIdCanonical = c.id.trim();
      if (seenContainerIds[cIdCanonical]) {
        errors.push({ code: "DUPLICATE_CONTAINER_ID", path: cPath + ".id" });
      } else {
        seenContainerIds[cIdCanonical] = true;
      }
    }

    if (typeof c.title !== "string") {
      errors.push({ code: "INVALID_CONTAINER_TITLE", path: cPath + ".title" });
    }

    if (typeof c.enabled !== "boolean") {
      errors.push({ code: "INVALID_CONTAINER_ENABLED", path: cPath + ".enabled" });
    }

    if (typeof c.order !== "number" || c.order < 0 || Math.floor(c.order) !== c.order || isNaN(c.order)) {
      errors.push({ code: "INVALID_CONTAINER_ORDER", path: cPath + ".order" });
    }

    if (typeof c.colSpan !== "number" || c.colSpan < 1 || c.colSpan > 4 || Math.floor(c.colSpan) !== c.colSpan) {
      errors.push({ code: "INVALID_CONTAINER_SPAN", path: cPath + ".colSpan" });
    }

    if (typeof c.rowSpan !== "number" || c.rowSpan < 1 || c.rowSpan > 3 || Math.floor(c.rowSpan) !== c.rowSpan) {
      errors.push({ code: "INVALID_CONTAINER_SPAN", path: cPath + ".rowSpan" });
    }

    if (typeof c.headerMode !== "string" || ["none", "compact", "normal"].indexOf(c.headerMode) === -1) {
      errors.push({ code: "INVALID_HEADER_MODE", path: cPath + ".headerMode" });
    }

    if (c.col !== undefined && c.col !== null) {
      if (typeof c.col !== "number" || c.col < 0 || Math.floor(c.col) !== c.col || isNaN(c.col)) {
        errors.push({ code: "INVALID_CONTAINER_POSITION", path: cPath + ".col" });
      }
    }

    if (c.row !== undefined && c.row !== null) {
      if (typeof c.row !== "number" || c.row < 0 || Math.floor(c.row) !== c.row || isNaN(c.row)) {
        errors.push({ code: "INVALID_CONTAINER_POSITION", path: cPath + ".row" });
      }
    }

    if (c.layoutMode !== undefined) {
      if (typeof c.layoutMode !== "string" || (c.layoutMode !== "auto" && c.layoutMode !== "manual")) {
        errors.push({ code: "INVALID_LAYOUT_MODE", path: cPath + ".layoutMode" });
      }
    }

    if (c.legacy !== undefined) {
      if (typeof c.legacy !== "object" || c.legacy === null || Array.isArray(c.legacy)) {
        errors.push({ code: "INVALID_CONTAINER_LEGACY", path: cPath + ".legacy" });
      } else {
        warnings.push({
          code: "UNSUPPORTED_LEGACY_PORTAL",
          path: cPath + ".legacy",
          legacyType: String(c.legacy.type || "unknown")
        });
      }
    }

    if (!Array.isArray(c.blocks)) {
      errors.push({ code: "INVALID_BLOCKS", path: cPath + ".blocks" });
    } else {
      var seenBlockIds = Object.create(null);
      var seenSingletons = Object.create(null);

      for (var j = 0; j < c.blocks.length; j++) {
        var bPath = cPath + ".blocks[" + j + "]";
        var b = c.blocks[j];

        if (!b || typeof b !== "object" || Array.isArray(b)) {
          errors.push({ code: "INVALID_BLOCK", path: bPath });
          continue;
        }

        if (typeof b.id !== "string" || !b.id.trim()) {
          errors.push({ code: "INVALID_BLOCK_ID", path: bPath + ".id" });
        } else {
          var bIdCanonical = b.id.trim();
          if (seenBlockIds[bIdCanonical]) {
            errors.push({ code: "DUPLICATE_BLOCK_ID", path: bPath + ".id" });
          } else {
            seenBlockIds[bIdCanonical] = true;
          }
        }

        if (typeof b.order !== "number" || b.order < 0 || Math.floor(b.order) !== b.order || isNaN(b.order)) {
          errors.push({ code: "INVALID_BLOCK_ORDER", path: bPath + ".order" });
        }

        if (!b.settings || typeof b.settings !== "object" || Array.isArray(b.settings)) {
          errors.push({ code: "INVALID_BLOCK_SETTINGS", path: bPath + ".settings" });
        }

        if (b.presentationMode !== undefined) {
          if (typeof b.presentationMode !== "string" || ["auto", "icon", "compact", "detailed", "dashboard"].indexOf(b.presentationMode) === -1) {
            errors.push({ code: "PRESENTATION_UNSUPPORTED", path: bPath + ".presentationMode", blockId: b.id });
          } else if (reg.has(b.kind) && reg.supportsVariant(b.kind, b.variant)) {
            var supp = reg.supportedPresentations(b.kind, b.variant);
            if (supp.indexOf(b.presentationMode) === -1) {
              errors.push({ code: "PRESENTATION_UNSUPPORTED", path: bPath + ".presentationMode", blockId: b.id });
            }
          }
        }

        if (b.layout !== undefined) {
          if (typeof b.layout !== "object" || b.layout === null || Array.isArray(b.layout)) {
            errors.push({ code: "INVALID_BLOCK_LAYOUT", path: bPath + ".layout", blockId: b.id });
          } else {
            if (b.layout.colSpan !== undefined && (typeof b.layout.colSpan !== "number" || b.layout.colSpan < 1 || Math.floor(b.layout.colSpan) !== b.layout.colSpan)) {
              errors.push({ code: "INVALID_BLOCK_LAYOUT", path: bPath + ".layout.colSpan", blockId: b.id });
            }
            if (b.layout.rowSpan !== undefined && (typeof b.layout.rowSpan !== "number" || b.layout.rowSpan < 1 || Math.floor(b.layout.rowSpan) !== b.layout.rowSpan)) {
              errors.push({ code: "INVALID_BLOCK_LAYOUT", path: bPath + ".layout.rowSpan", blockId: b.id });
            }
          }
        }

        if (c.layoutMode === "manual") {
          if (!b.layout || typeof b.layout !== "object" || Array.isArray(b.layout) ||
              typeof b.layout.col !== "number" || b.layout.col < 0 || Math.floor(b.layout.col) !== b.layout.col ||
              typeof b.layout.row !== "number" || b.layout.row < 0 || Math.floor(b.layout.row) !== b.layout.row) {
            errors.push({ code: "INVALID_BLOCK_LAYOUT", path: bPath + ".layout", blockId: b.id });
          }
        }

        if (!reg.has(b.kind)) {
          errors.push({ code: "UNKNOWN_BLOCK_KIND", path: bPath + ".kind" });
        } else {
          if (reg.isSingleton(b.kind)) {
            if (seenSingletons[b.kind]) {
              errors.push({ code: "DUPLICATE_SINGLETON", path: bPath + ".kind" });
            } else {
              seenSingletons[b.kind] = true;
            }
          }

          if (!reg.supportsVariant(b.kind, b.variant)) {
            errors.push({ code: "UNSUPPORTED_BLOCK_VARIANT", path: bPath + ".variant" });
          } else {
            var fp = reg.footprint(b.kind, b.variant);
            var effColSpan = (b.layout && typeof b.layout.colSpan === "number") ? b.layout.colSpan : fp.colSpan;
            var effRowSpan = (b.layout && typeof b.layout.rowSpan === "number") ? b.layout.rowSpan : fp.rowSpan;
            if (effColSpan < fp.colSpan || effRowSpan < fp.rowSpan) {
              errors.push({ code: "BLOCK_BELOW_MINIMUM", path: bPath + ".layout", blockId: b.id });
            } else if (!reg.canAllocate(b.kind, b.variant, effColSpan, effRowSpan)) {
              errors.push({ code: "BLOCK_GROWTH_UNSUPPORTED", path: bPath + ".layout", blockId: b.id });
            }

            var intCols = (typeof c.colSpan === "number") ? c.colSpan * 2 : 2;
            var intRows = (typeof c.rowSpan === "number") ? c.rowSpan * 2 : 2;
            if (c.layoutMode === "manual" && b.layout && typeof b.layout.col === "number" && typeof b.layout.row === "number") {
              if (b.layout.col + effColSpan > intCols || b.layout.row + effRowSpan > intRows) {
                errors.push({ code: "BLOCK_OUT_OF_BOUNDS", path: bPath + ".layout", blockId: b.id });
              }
            }
          }

          var entry = reg.get(b.kind);
          if (entry && entry.requiresSource) {
            if (typeof b.source !== "string" || !b.source.trim()) {
              errors.push({ code: "MISSING_BLOCK_SOURCE", path: bPath + ".source" });
            } else if (!reg.supportsSource(b.kind, b.source)) {
              errors.push({ code: "UNSUPPORTED_BLOCK_SOURCE", path: bPath + ".source" });
            }
          }

          if (b.settings && typeof b.settings === "object" && !Array.isArray(b.settings)) {
            var sRes = reg.validateSettings(b.kind, b.settings, b.variant);
            if (!sRes.valid) {
              errors.push({ code: sRes.error || "INVALID_BLOCK_SETTINGS", path: bPath + ".settings", blockId: b.id });
            }
          }
        }
      }

      if (c.layoutMode === "manual") {
        var gridOccupied = Object.create(null);
        for (var k = 0; k < c.blocks.length; k++) {
          var blk = c.blocks[k];
          if (blk && blk.layout && typeof blk.layout.col === "number" && typeof blk.layout.row === "number") {
            var bFp = (reg.has(blk.kind) && reg.supportsVariant(blk.kind, blk.variant)) ? reg.footprint(blk.kind, blk.variant) : { colSpan: 1, rowSpan: 1 };
            var bCS = (typeof blk.layout.colSpan === "number") ? blk.layout.colSpan : bFp.colSpan;
            var bRS = (typeof blk.layout.rowSpan === "number") ? blk.layout.rowSpan : bFp.rowSpan;
            var hasCol = false;
            for (var dr = 0; dr < bRS; dr++) {
              for (var dc = 0; dc < bCS; dc++) {
                var cellKey = (blk.layout.col + dc) + "," + (blk.layout.row + dr);
                if (gridOccupied[cellKey]) {
                  hasCol = true;
                  break;
                }
                gridOccupied[cellKey] = blk.id || true;
              }
              if (hasCol) break;
            }
            if (hasCol) {
              errors.push({ code: "BLOCK_COLLISION", path: cPath + ".blocks[" + k + "]", blockId: blk.id });
              break;
            }
          }
        }
      }
    }
  }

  if (errors.length > 0) {
    return {
      ok: false,
      value: null,
      errors: errors,
      warnings: warnings
    };
  }

  return {
    ok: true,
    value: normalizeV2(config),
    errors: [],
    warnings: warnings
  };
}

function migrate(rawConfig) {
  if (!rawConfig || typeof rawConfig !== "object" || Array.isArray(rawConfig)) {
    return null;
  }

  // Any config that already uses the containers model is not a legacy portals config.
  // Return a deep clone without normalization so validateV2() validates the exact input.
  if (rawConfig.schemaVersion === 2 || Array.isArray(rawConfig.containers)) {
    return clone(rawConfig);
  }

  var c = clone(rawConfig);
  var containers = [];
  var containerOrder = 0;

  // Clock container migration
  if (c.showClock !== false) {
    containers.push({
      id: "container_clock",
      title: "",
      enabled: true,
      order: containerOrder++,
      colSpan: 2,
      rowSpan: 1,
      headerMode: "none",
      layoutMode: "auto",
      blocks: [
        {
          id: "block_clock_time",
          kind: "time",
          variant: "wide",
          order: 0,
          presentationMode: "auto",
          settings: {}
        },
        {
          id: "block_clock_date",
          kind: "date",
          variant: "wide",
          order: 1,
          presentationMode: "auto",
          settings: {}
        }
      ]
    });
  }

  // Legacy portals migration
  if (Array.isArray(c.portals)) {
    var portalsWithIndex = [];
    for (var idx = 0; idx < c.portals.length; idx++) {
      portalsWithIndex.push({
        portal: c.portals[idx],
        originalIndex: idx
      });
    }

    var sortedPortals = portalsWithIndex.slice().sort(function(a, b) {
      var pa = a.portal;
      var pb = b.portal;
      var oa = (pa && typeof pa.order === "number") ? pa.order : a.originalIndex;
      var ob = (pb && typeof pb.order === "number") ? pb.order : b.originalIndex;
      return oa - ob;
    });

    for (var i = 0; i < sortedPortals.length; i++) {
      var item = sortedPortals[i];
      var p = item.portal;
      if (!p || typeof p !== "object") continue;

      var baseId = (typeof p.id === "string" && p.id.trim())
        ? p.id.trim()
        : ("portal_" + item.originalIndex);
      var cId = baseId.indexOf("container_") === 0 ? baseId : ("container_" + baseId);

      var pColSpan = (typeof p.colSpan === "number") ? Math.max(1, Math.min(4, Math.floor(p.colSpan))) : 1;
      var pRowSpan = (typeof p.rowSpan === "number") ? Math.max(1, Math.min(3, Math.floor(p.rowSpan))) : 1;
      var pTitle = typeof p.title === "string" ? p.title : "";
      var pEnabled = p.enabled !== false;

      var blocks = [];
      var containerData = {
        id: cId,
        title: pTitle,
        enabled: pEnabled,
        order: containerOrder++,
        colSpan: pColSpan,
        rowSpan: pRowSpan,
        headerMode: (pColSpan === 1 && pRowSpan === 1) ? "compact" : "normal",
        layoutMode: "auto"
      };

      switch (p.type) {
        case "folders":
          blocks.push({
            id: "block_" + baseId + "_grid",
            kind: "folder-grid",
            variant: "compact",
            order: 0,
            colSpan: 2,
            rowSpan: 2,
            settings: {
              items: Array.isArray(p.items) ? clone(p.items) : []
            }
          });
          break;

        case "apps":
          blocks.push({
            id: "block_" + baseId + "_grid",
            kind: "app-grid",
            variant: "compact",
            order: 0,
            colSpan: 2,
            rowSpan: 2,
            settings: {
              items: Array.isArray(p.items) ? clone(p.items) : []
            }
          });
          break;

        case "system":
          containerData.title = "";
          containerData.headerMode = "none";
          blocks.push(
            {
              id: "block_" + baseId + "_cpu",
              kind: "metric",
              source: "cpu.percent",
              variant: "compact",
              order: 0,
              colSpan: 1,
              rowSpan: 1,
              settings: {}
            },
            {
              id: "block_" + baseId + "_ram",
              kind: "metric",
              source: "ram.percent",
              variant: "compact",
              order: 1,
              colSpan: 1,
              rowSpan: 1,
              settings: {}
            },
            {
              id: "block_" + baseId + "_disk",
              kind: "metric",
              source: "disk.percent",
              variant: "compact",
              order: 2,
              colSpan: 1,
              rowSpan: 1,
              settings: {}
            }
          );
          break;

        case "fan":
          containerData.colSpan = 2;
          containerData.rowSpan = 2;
          containerData.layoutMode = "manual";
          containerData.headerMode = "compact";
          blocks.push(
            {
              id: "block_" + baseId + "_temp_cpu",
              kind: "metric",
              source: "temperature.cpu",
              variant: "compact",
              order: 0,
              presentationMode: "compact",
              layout: { col: 0, row: 0, colSpan: 2, rowSpan: 1 },
              settings: {}
            },
            {
              id: "block_" + baseId + "_temp_gpu",
              kind: "metric",
              source: "temperature.gpu",
              variant: "compact",
              order: 1,
              presentationMode: "compact",
              layout: { col: 2, row: 0, colSpan: 2, rowSpan: 1 },
              settings: {}
            },
            {
              id: "block_" + baseId + "_temp_nvme",
              kind: "metric",
              source: "temperature.nvme",
              variant: "compact",
              order: 2,
              presentationMode: "compact",
              layout: { col: 0, row: 1, colSpan: 2, rowSpan: 1 },
              settings: {}
            },
            {
              id: "block_" + baseId + "_temp_hdd",
              kind: "metric",
              source: "temperature.hdd",
              variant: "compact",
              order: 3,
              presentationMode: "compact",
              layout: { col: 2, row: 1, colSpan: 2, rowSpan: 1 },
              settings: {}
            },
            {
              id: "block_" + baseId + "_fan_controls",
              kind: "fan-control",
              variant: "controls",
              order: 4,
              presentationMode: "auto",
              layout: { col: 0, row: 2, colSpan: 4, rowSpan: 2 },
              settings: {
                modes: [0, 1, 2, 4]
              }
            }
          );
          break;

        case "network":
          containerData.title = "Network";
          blocks.push({
            id: "block_" + baseId + "_net",
            kind: "network",
            variant: "wide",
            order: 0,
            colSpan: 2,
            rowSpan: 1,
            presentationMode: "auto",
            settings: {}
          });
          containerData.blocks = blocks;
          containers.push(containerData);
          containers.push({
            id: cId + "_battery",
            title: "Battery",
            enabled: pEnabled,
            order: containerOrder++,
            colSpan: 1,
            rowSpan: 1,
            headerMode: "compact",
            layoutMode: "auto",
            blocks: [{
              id: "block_" + baseId + "_battery",
              kind: "battery",
              variant: "wide",
              order: 0,
              colSpan: 2,
              rowSpan: 1,
              presentationMode: "auto",
              settings: {}
            }]
          });
          continue;

        default:
          containerData.enabled = false;
          containerData.legacy = {
            type: String(p.type || "unknown"),
            portal: clone(p)
          };
          break;
      }

      containerData.blocks = blocks;
      containers.push(containerData);
    }
  }

  var v2 = {
    schemaVersion: 2,
    targetWorkspace: (typeof c.targetWorkspace === "number") ? c.targetWorkspace : 1,
    deskClosed: Boolean(c.deskClosed),
    autoHideOnWindows: c.autoHideOnWindows !== undefined ? Boolean(c.autoHideOnWindows) : true,
    cardOpacity: (typeof c.cardOpacity === "number") ? c.cardOpacity : 0.45,
    containers: containers
  };

  if (c.occupiedOpacity !== undefined && typeof c.occupiedOpacity === "number") {
    v2.occupiedOpacity = c.occupiedOpacity;
  }

  return normalizeV2(v2);
}

function defaultConfig() {
  return migrate({
    targetWorkspace: 1,
    deskClosed: false,
    autoHideOnWindows: true,
    cardOpacity: 0.45,
    showClock: true,
    portals: [
      {
        id: "folders_portal",
        type: "folders",
        title: "Folders",
        colSpan: 1,
        rowSpan: 1,
        order: 0,
        enabled: true,
        items: [
          { name: "Home", icon: "folder-home", path: "~" },
          { name: "Downloads", icon: "folder-download", path: "~/Downloads" },
          { name: "Projects", icon: "folder-development", path: "~/Projects" },
          { name: "Documents", icon: "folder-documents", path: "~/Documents" }
        ]
      },
      {
        id: "apps_portal",
        type: "apps",
        title: "Applications",
        colSpan: 1,
        rowSpan: 1,
        order: 1,
        enabled: true,
        items: [
          { name: "Terminal", icon: "utilities-terminal", command: "alacritty" },
          { name: "Browser", icon: "web-browser", command: "firefox" },
          { name: "Editor", icon: "text-editor", command: "code" },
          { name: "Files", icon: "system-file-manager", command: "nautilus" }
        ]
      },
      { id: "system_portal", type: "system", title: "System Analytics", colSpan: 1, rowSpan: 1, order: 2, enabled: true },
      { id: "fan_portal", type: "fan", title: "Fan & Thermals", colSpan: 1, rowSpan: 1, order: 3, enabled: true },
      { id: "net_battery_portal", type: "network", title: "Network & Power", colSpan: 1, rowSpan: 1, order: 4, enabled: true }
    ]
  });
}

function normalize(config) {
  if (!config || typeof config !== "object") {
    return null;
  }
  if (config.schemaVersion === 2) {
    return normalizeV2(config);
  }
  return migrate(config);
}

var ConfigModel = {
  defaultConfig: defaultConfig,
  migrate: migrate,
  normalize: normalize,
  normalizeV2: normalizeV2,
  validateV2: validateV2,
  clone: clone
};

if (typeof globalThis !== "undefined") {
  globalThis.ConfigModel = ConfigModel;
}

