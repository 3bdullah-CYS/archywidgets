/**
 * ArchyWidgets Composer Model
 * Pure transactional layer for Container Composer mutations.
 * Atomic validation against schema, internal capacity, and desktop capacity.
 * Stateless, deterministic, immutable, non-throwing.
 */
.pragma library
.import "ConfigModel.js" as ConfigModel
.import "BlockRegistry.js" as BlockRegistry
.import "InternalLayoutEngine.js" as InternalLayoutEngine
.import "AdaptiveLayoutEngine.js" as AdaptiveLayoutEngine
.import "ContainerTemplateRegistry.js" as ContainerTemplateRegistry

function _getTemplateRegistry() {
  if (typeof ContainerTemplateRegistry !== "undefined" && ContainerTemplateRegistry && typeof ContainerTemplateRegistry.createContainerFromTemplate === "function") {
    return ContainerTemplateRegistry;
  }
  if (typeof globalThis !== "undefined" && globalThis.ContainerTemplateRegistry) {
    return globalThis.ContainerTemplateRegistry;
  }
  throw new Error("ContainerTemplateRegistry library not found");
}

function _getConfigModel() {
  if (typeof ConfigModel !== "undefined" && ConfigModel && typeof ConfigModel.validateV2 === "function") {
    return ConfigModel;
  }
  if (typeof globalThis !== "undefined" && globalThis.ConfigModel) {
    return globalThis.ConfigModel;
  }
  throw new Error("ConfigModel library not found");
}

function _getRegistry() {
  if (typeof BlockRegistry !== "undefined" && BlockRegistry && typeof BlockRegistry.has === "function") {
    return BlockRegistry;
  }
  if (typeof globalThis !== "undefined" && globalThis.BlockRegistry) {
    return globalThis.BlockRegistry;
  }
  throw new Error("BlockRegistry library not found");
}

function _getInternalLayout() {
  if (typeof InternalLayoutEngine !== "undefined" && InternalLayoutEngine && typeof InternalLayoutEngine.tryPackBlocks === "function") {
    return InternalLayoutEngine;
  }
  if (typeof globalThis !== "undefined" && globalThis.InternalLayoutEngine) {
    return globalThis.InternalLayoutEngine;
  }
  throw new Error("InternalLayoutEngine library not found");
}

function _getAdaptiveLayout() {
  if (typeof AdaptiveLayoutEngine !== "undefined" && AdaptiveLayoutEngine && typeof AdaptiveLayoutEngine.tryPackWidgets === "function") {
    return AdaptiveLayoutEngine;
  }
  if (typeof globalThis !== "undefined" && globalThis.AdaptiveLayoutEngine) {
    return globalThis.AdaptiveLayoutEngine;
  }
  throw new Error("AdaptiveLayoutEngine library not found");
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

function _clone(val) {
  if (val === null || typeof val !== "object") {
    return val;
  }
  try {
    return JSON.parse(JSON.stringify(val));
  } catch (e) {
    if (_isArray(val)) {
      var arr = [];
      for (var i = 0; i < val.length; i++) {
        arr.push(_clone(val[i]));
      }
      return arr;
    }
    var obj = {};
    var keys = Object.keys(val);
    for (var k = 0; k < keys.length; k++) {
      obj[keys[k]] = _clone(val[keys[k]]);
    }
    return obj;
  }
}

function _isObject(val) {
  return val !== null && typeof val === "object" && !Array.isArray(val);
}

function _rendererAvailable(kind) {
  return kind === "time" || kind === "metric" || kind === "date" || kind === "workspace" || kind === "network" || kind === "battery" ||
         kind === "app-grid" || kind === "folder-grid" || kind === "fan-control" || kind === "sys-info" ||
         kind === "todo" || kind === "notifications";
}

function _validateDesktopMetrics(metrics) {
  if (!metrics || typeof metrics !== "object" || Array.isArray(metrics)) {
    return false;
  }
  if (metrics.valid !== true) {
    return false;
  }
  var adaptive = _getAdaptiveLayout();
  var check = adaptive.tryPackWidgets([], metrics);
  if (!check || check.fits !== true) {
    return false;
  }
  return true;
}

function _validateCandidate(candidate, desktopMetrics, originalDraft) {
  if (!_validateDesktopMetrics(desktopMetrics)) {
    return {
      ok: false,
      value: _clone(originalDraft),
      error: { code: "INVALID_DESKTOP_METRICS" }
    };
  }

  var configModel = _getConfigModel();
  var valRes = configModel.validateV2(candidate);
  if (!valRes.ok) {
    return {
      ok: false,
      value: _clone(originalDraft),
      error: {
        code: "INVALID_CONFIG",
        details: valRes.errors
      }
    };
  }

  var normalized = valRes.value;
  var internalLayout = _getInternalLayout();

  for (var i = 0; i < normalized.containers.length; i++) {
    var c = normalized.containers[i];
    var cols = c.colSpan * 2;
    var rows = c.rowSpan * 2;

    if (c.layoutMode === "manual") {
      var manCheck = internalLayout.validateManualPlacements(c.blocks, cols, rows);
      if (!manCheck.valid) {
        return {
          ok: false,
          value: _clone(originalDraft),
          error: manCheck.error || { code: "INVALID_BLOCK_LAYOUT", containerId: c.id }
        };
      }
    } else if (c.blocks.length > 1) {
      var packRes = internalLayout.tryPackBlocks(c.blocks, cols, rows);
      if (!packRes || !packRes.fits || !Array.isArray(packRes.placements) || packRes.placements.length !== c.blocks.length) {
        return {
          ok: false,
          value: _clone(originalDraft),
          error: {
            code: "CONTAINER_NO_SPACE",
            containerId: c.id,
            unplacedIds: (packRes && packRes.unplacedIds) ? packRes.unplacedIds : []
          }
        };
      }
    }

    if (desktopMetrics && desktopMetrics.valid) {
      var dCellW = desktopMetrics.cellWidth || 176;
      var dCellH = desktopMetrics.cellHeight || 124;
      var dColGap = typeof desktopMetrics.colGap === "number" ? desktopMetrics.colGap : 14;
      var dRowGap = typeof desktopMetrics.rowGap === "number" ? desktopMetrics.rowGap : 12;
      var containerWidth = c.colSpan * dCellW + (c.colSpan - 1) * dColGap;
      var containerHeight = c.rowSpan * dCellH + (c.rowSpan - 1) * dRowGap;
      var cPad = 8;
      var hMode = c.headerMode || "none";
      var hHeight = hMode === "compact" ? 20 : (hMode === "normal" ? 28 : 0);
      var hGap = hMode === "none" ? 0 : 6;
      var cY = cPad + (hHeight > 0 ? (hHeight + hGap) : 0);
      var cWidth = Math.max(0, containerWidth - cPad * 2);
      var cHeight = Math.max(0, containerHeight - cY - cPad);
      var iMetrics = internalLayout.computeInternalMetrics(cWidth, cHeight, cols, rows, 6);
      if (iMetrics && iMetrics.valid) {
        var lRes = internalLayout.layoutBlocks(c, iMetrics);
        if (!lRes.fits) {
          var aIds = [];
          if (lRes.errors) {
            for (var pe = 0; pe < lRes.errors.length; pe++) {
              if (lRes.errors[pe].blockId) aIds.push(lRes.errors[pe].blockId);
            }
          }
          var firstErr = (lRes.errors && lRes.errors.length > 0) ? lRes.errors[0] : null;
          var errCode = (firstErr && firstErr.code) ? firstErr.code : "RESIZE_BREAKS_VISUAL_MINIMUM";
          return {
            ok: false,
            value: _clone(originalDraft),
            error: {
              code: errCode,
              containerId: c.id,
              blockIds: aIds,
              errors: lRes.errors
            }
          };
        }
      }
    }
  }

  var adaptive = _getAdaptiveLayout();
  var enabledContainers = [];
  for (var j = 0; j < normalized.containers.length; j++) {
    if (normalized.containers[j].enabled !== false) {
      enabledContainers.push(normalized.containers[j]);
    }
  }

  var mode = (typeof normalized.layoutMode === "string" && normalized.layoutMode === "manual") ? "manual" : "auto";
  var outerPack = adaptive.tryPackWidgets(enabledContainers, desktopMetrics, { layoutMode: mode });
  if (!outerPack || !outerPack.fits || !Array.isArray(outerPack.placements) || outerPack.placements.length !== enabledContainers.length) {
    var firstErr = (outerPack && outerPack.errors && outerPack.errors.length > 0) ? outerPack.errors[0] : null;
    var errCode = (firstErr && firstErr.code) ? firstErr.code : "DESKTOP_NO_SPACE";
    return {
      ok: false,
      value: _clone(originalDraft),
      error: {
        code: errCode,
        unplacedIds: (outerPack && outerPack.unplacedIds) ? outerPack.unplacedIds : [],
        errors: outerPack ? outerPack.errors : []
      }
    };
  }

  return {
    ok: true,
    value: normalized,
    error: null
  };
}

function _findContainerIndex(containers, containerId) {
  if (!Array.isArray(containers) || typeof containerId !== "string" || !containerId.trim()) {
    return -1;
  }
  var cid = containerId.trim();
  for (var i = 0; i < containers.length; i++) {
    var c = containers[i];
    if (c && typeof c.id === "string" && c.id.trim() === cid) {
      return i;
    }
  }
  return -1;
}

function _findBlockIndex(blocks, blockId) {
  if (!Array.isArray(blocks) || typeof blockId !== "string" || !blockId.trim()) {
    return -1;
  }
  var bid = blockId.trim();
  for (var i = 0; i < blocks.length; i++) {
    var b = blocks[i];
    if (b && typeof b.id === "string" && b.id.trim() === bid) {
      return i;
    }
  }
  return -1;
}

function _generateContainerId(containers) {
  var seen = Object.create(null);
  if (Array.isArray(containers)) {
    for (var i = 0; i < containers.length; i++) {
      if (containers[i] && typeof containers[i].id === "string") {
        seen[containers[i].id.trim()] = true;
      }
    }
  }
  var n = 1;
  while (seen["container_" + n]) {
    n++;
  }
  return "container_" + n;
}

function _generateBlockId(blocks) {
  var seen = Object.create(null);
  if (Array.isArray(blocks)) {
    for (var i = 0; i < blocks.length; i++) {
      if (blocks[i] && typeof blocks[i].id === "string") {
        seen[blocks[i].id.trim()] = true;
      }
    }
  }
  var n = 1;
  while (seen["block_" + n]) {
    n++;
  }
  return "block_" + n;
}

function _prepareDraft(draft) {
  if (!_isObject(draft)) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_CONFIG", details: [] }
    };
  }

  var configModel = _getConfigModel();
  var valRes = configModel.validateV2(draft);
  if (!valRes || !valRes.ok) {
    return {
      ok: false,
      value: _clone(draft),
      error: {
        code: "INVALID_CONFIG",
        details: (valRes && valRes.errors) ? valRes.errors : []
      }
    };
  }

  return {
    ok: true,
    value: valRes.value
  };
}

// =====================================================================
// Public API Functions
// =====================================================================

function _findFirstAvailableSlot(containers, colSpan, rowSpan, desktopMetrics) {
  var cols = (desktopMetrics && typeof desktopMetrics.columns === "number") ? desktopMetrics.columns : 6;
  var maxRows = (desktopMetrics && typeof desktopMetrics.maxRows === "number") ? desktopMetrics.maxRows : 4;

  var grid = [];
  for (var r = 0; r < maxRows; r++) {
    grid[r] = [];
    for (var c = 0; c < cols; c++) {
      grid[r][c] = false;
    }
  }

  for (var i = 0; i < containers.length; i++) {
    var cObj = containers[i];
    if (cObj && cObj.enabled !== false && typeof cObj.col === "number" && typeof cObj.row === "number") {
      var cW = cObj.colSpan || 1;
      var cH = cObj.rowSpan || 1;
      for (var dr = 0; dr < cH; dr++) {
        for (var dc = 0; dc < cW; dc++) {
          if ((cObj.row + dr) < maxRows && (cObj.col + dc) < cols) {
            grid[cObj.row + dr][cObj.col + dc] = true;
          }
        }
      }
    }
  }

  for (var r = 0; r <= maxRows - rowSpan; r++) {
    for (var c = 0; c <= cols - colSpan; c++) {
      var fits = true;
      for (var dr = 0; dr < rowSpan; dr++) {
        for (var dc = 0; dc < colSpan; dc++) {
          if (grid[r + dr][c + dc]) {
            fits = false;
            break;
          }
        }
        if (!fits) break;
      }
      if (fits) {
        return { col: c, row: r };
      }
    }
  }
  return null;
}

function validateDraft(draft, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }
  return _validateCandidate(prep.value, desktopMetrics, draft);
}

function tryAddContainer(draft, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var candidate = _clone(prep.value);
  var newId = _generateContainerId(candidate.containers);
  var newContainer = {
    id: newId,
    title: "",
    enabled: true,
    order: candidate.containers.length,
    colSpan: 1,
    rowSpan: 1,
    headerMode: "none",
    layoutMode: "auto",
    blocks: []
  };

  if (candidate.layoutMode === "manual") {
    var slot = _findFirstAvailableSlot(candidate.containers, newContainer.colSpan, newContainer.rowSpan, desktopMetrics);
    if (!slot) {
      return {
        ok: false,
        value: _clone(draft),
        error: { code: "DESKTOP_NO_SPACE" }
      };
    }
    newContainer.col = slot.col;
    newContainer.row = slot.row;
  }

  candidate.containers.push(newContainer);
  var res = _validateCandidate(candidate, desktopMetrics, draft);
  if (!res.ok) {
    return res;
  }

  return {
    ok: true,
    value: res.value,
    error: null,
    createdId: newId
  };
}

function tryAddContainerWithTemplate(draft, templateId, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var candidate = _clone(prep.value);
  var newId = _generateContainerId(candidate.containers);
  var reg = _getRegistry();
  var tplReg = _getTemplateRegistry();
  var tId = (typeof templateId === "string" && templateId.trim()) ? templateId.trim().toLowerCase() : "custom";

  var newContainer = tplReg.createContainerFromTemplate(tId, newId, reg);
  newContainer.order = candidate.containers.length;

  if (candidate.layoutMode === "manual") {
    var slot = _findFirstAvailableSlot(candidate.containers, newContainer.colSpan, newContainer.rowSpan, desktopMetrics);
    if (!slot) {
      var fallbacks = [];
      if (newContainer.colSpan === 2 && newContainer.rowSpan === 2) {
        fallbacks.push({ colSpan: 2, rowSpan: 1 });
        fallbacks.push({ colSpan: 1, rowSpan: 1 });
      } else if (newContainer.colSpan === 2 && newContainer.rowSpan === 1) {
        fallbacks.push({ colSpan: 1, rowSpan: 1 });
      }
      for (var f = 0; f < fallbacks.length; f++) {
        var fbSlot = _findFirstAvailableSlot(candidate.containers, fallbacks[f].colSpan, fallbacks[f].rowSpan, desktopMetrics);
        if (fbSlot) {
          newContainer.colSpan = fallbacks[f].colSpan;
          newContainer.rowSpan = fallbacks[f].rowSpan;
          slot = fbSlot;
          break;
        }
      }
    }
    if (!slot) {
      return {
        ok: false,
        value: _clone(draft),
        error: { code: "DESKTOP_NO_SPACE" }
      };
    }
    newContainer.col = slot.col;
    newContainer.row = slot.row;
  }

  candidate.containers.push(newContainer);
  var res = _validateCandidate(candidate, desktopMetrics, draft);
  if (!res.ok && res.error && res.error.code === "DESKTOP_NO_SPACE") {
    var fallbacks = [];
    if (newContainer.colSpan === 2 && newContainer.rowSpan === 2) {
      fallbacks.push({ colSpan: 2, rowSpan: 1 });
      fallbacks.push({ colSpan: 1, rowSpan: 1 });
    } else if (newContainer.colSpan === 2 && newContainer.rowSpan === 1) {
      fallbacks.push({ colSpan: 1, rowSpan: 1 });
    }
    for (var f = 0; f < fallbacks.length; f++) {
      newContainer.colSpan = fallbacks[f].colSpan;
      newContainer.rowSpan = fallbacks[f].rowSpan;
      var fRes = _validateCandidate(candidate, desktopMetrics, draft);
      if (fRes.ok) {
        res = fRes;
        break;
      }
    }
  }
  if (!res.ok) {
    return res;
  }

  return {
    ok: true,
    value: res.value,
    error: null,
    createdId: newId
  };
}

function tryRemoveContainer(draft, containerId, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  var candidate = _clone(prep.value);
  var idx = _findContainerIndex(candidate.containers, cid);
  if (idx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  candidate.containers.splice(idx, 1);
  for (var i = 0; i < candidate.containers.length; i++) {
    candidate.containers[i].order = i;
  }

  return _validateCandidate(candidate, desktopMetrics, draft);
}

function tryMoveContainer(draft, containerId, targetIndex, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  var candidate = _clone(prep.value);
  var fromIdx = _findContainerIndex(candidate.containers, cid);
  if (fromIdx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  if (typeof targetIndex !== "number" || !Number.isInteger(targetIndex) || targetIndex < 0 || targetIndex >= candidate.containers.length) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_TARGET_INDEX" }
    };
  }

  var moved = candidate.containers.splice(fromIdx, 1)[0];
  candidate.containers.splice(targetIndex, 0, moved);

  for (var i = 0; i < candidate.containers.length; i++) {
    candidate.containers[i].order = i;
  }

  return _validateCandidate(candidate, desktopMetrics, draft);
}

function trySetContainerPosition(draft, containerId, targetCol, targetRow, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  var candidate = _clone(prep.value);
  var idx = _findContainerIndex(candidate.containers, cid);
  if (idx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  if (typeof targetCol !== "number" || !Number.isInteger(targetCol) || targetCol < 0 ||
      typeof targetRow !== "number" || !Number.isInteger(targetRow) || targetRow < 0) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_TARGET_COORDINATES" }
    };
  }

  var c = candidate.containers[idx];
  c.col = targetCol;
  c.row = targetRow;

  return _validateCandidate(candidate, desktopMetrics, draft);
}

function tryResizeContainer(draft, containerId, colSpan, rowSpan, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  if (typeof colSpan !== "number" || !Number.isInteger(colSpan) || colSpan < 1 || colSpan > 4 ||
      typeof rowSpan !== "number" || !Number.isInteger(rowSpan) || rowSpan < 1 || rowSpan > 3) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_CONTAINER_SPAN" }
    };
  }

  var candidate = _clone(prep.value);
  var idx = _findContainerIndex(candidate.containers, cid);
  if (idx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  var container = candidate.containers[idx];
  var previousInternalColumns = container.colSpan * 2;
  var previousInternalRows = container.rowSpan * 2;
  container.colSpan = colSpan;
  container.rowSpan = rowSpan;

  // Check if resized internal space breaks existing blocks
  var internalLayout = _getInternalLayout();
  var cols = colSpan * 2;
  var rows = rowSpan * 2;
  if (container.layoutMode === "manual") {
    // Manual mode preserves the authored composition, not absolute cell
    // counts. Scale shared edges to the resized internal grid so growing a
    // container also grows its contents and shrinking it restores the same
    // proportions. Validation below still rejects impossible minimum sizes.
    for (var blockIndex = 0; blockIndex < container.blocks.length; blockIndex++) {
      var manualBlock = container.blocks[blockIndex];
      var oldLayout = manualBlock.layout;
      var oldRight = oldLayout.col + oldLayout.colSpan;
      var oldBottom = oldLayout.row + oldLayout.rowSpan;
      var nextCol = Math.round(oldLayout.col * cols / previousInternalColumns);
      var nextRow = Math.round(oldLayout.row * rows / previousInternalRows);
      var nextRight = Math.round(oldRight * cols / previousInternalColumns);
      var nextBottom = Math.round(oldBottom * rows / previousInternalRows);
      var nextColSpan = Math.max(1, nextRight - nextCol);
      var nextRowSpan = Math.max(1, nextBottom - nextRow);

      manualBlock.layout = {
        col: nextCol,
        row: nextRow,
        colSpan: nextColSpan,
        rowSpan: nextRowSpan
      };
      manualBlock.colSpan = nextColSpan;
      manualBlock.rowSpan = nextRowSpan;
    }

    var manVal = internalLayout.validateManualPlacements(container.blocks, cols, rows);
    if (!manVal.valid) {
      return {
        ok: false,
        value: _clone(draft),
        error: {
          code: "RESIZE_BREAKS_CONTENT",
          containerId: container.id,
          blockIds: (manVal.error && manVal.error.blockId) ? [manVal.error.blockId] : [],
          error: manVal.error
        }
      };
    }
  } else if (container.blocks.length > 1) {
    var packRes = internalLayout.tryPackBlocks(container.blocks, cols, rows);
    if (!packRes || !packRes.fits || !Array.isArray(packRes.placements) || packRes.placements.length !== container.blocks.length) {
      return {
        ok: false,
        value: _clone(draft),
        error: {
          code: "RESIZE_BREAKS_CONTENT",
          containerId: container.id,
          unplacedIds: (packRes && packRes.unplacedIds) ? packRes.unplacedIds : []
        }
      };
    }
  }

  // Check if actual pixel capacity meets visual minimums
  var dCellW = (desktopMetrics && desktopMetrics.cellWidth) ? desktopMetrics.cellWidth : 176;
  var dCellH = (desktopMetrics && desktopMetrics.cellHeight) ? desktopMetrics.cellHeight : 124;
  var dColGap = (desktopMetrics && typeof desktopMetrics.colGap === "number") ? desktopMetrics.colGap : 14;
  var dRowGap = (desktopMetrics && typeof desktopMetrics.rowGap === "number") ? desktopMetrics.rowGap : 12;

  var containerWidth = colSpan * dCellW + (colSpan - 1) * dColGap;
  var containerHeight = rowSpan * dCellH + (rowSpan - 1) * dRowGap;
  var cPad = 8;
  var hMode = container.headerMode || "none";
  var hHeight = hMode === "compact" ? 20 : (hMode === "normal" ? 28 : 0);
  var hGap = hMode === "none" ? 0 : 6;
  var cY = cPad + (hHeight > 0 ? (hHeight + hGap) : 0);
  var cWidth = Math.max(0, containerWidth - cPad * 2);
  var cHeight = Math.max(0, containerHeight - cY - cPad);

  var intMetrics = internalLayout.computeInternalMetrics(cWidth, cHeight, cols, rows, 6);
  var pixelVal = intMetrics && intMetrics.valid
    ? internalLayout.validateBlockPixelGeometry(container.blocks, intMetrics)
    : { fits: false, errors: [{ code: "INVALID_METRICS" }] };

  if (!pixelVal.fits) {
    var affectedBlockIds = [];
    if (pixelVal.errors) {
      for (var e = 0; e < pixelVal.errors.length; e++) {
        if (pixelVal.errors[e].blockId) {
          affectedBlockIds.push(pixelVal.errors[e].blockId);
        }
      }
    }
    return {
      ok: false,
      value: _clone(draft),
      error: {
        code: "RESIZE_BREAKS_VISUAL_MINIMUM",
        containerId: container.id,
        blockIds: affectedBlockIds,
        errors: pixelVal.errors
      }
    };
  }

  return _validateCandidate(candidate, desktopMetrics, draft);
}

function trySetContainerTitle(draft, containerId, title, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  if (typeof title !== "string") {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_CONTAINER_TITLE" }
    };
  }

  var candidate = _clone(prep.value);
  var idx = _findContainerIndex(candidate.containers, cid);
  if (idx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  candidate.containers[idx].title = title;
  return _validateCandidate(candidate, desktopMetrics, draft);
}

function trySetContainerHeaderMode(draft, containerId, headerMode, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  if (typeof headerMode !== "string" || ["none", "compact", "normal"].indexOf(headerMode) === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_HEADER_MODE" }
    };
  }

  var candidate = _clone(prep.value);
  var idx = _findContainerIndex(candidate.containers, cid);
  if (idx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  candidate.containers[idx].headerMode = headerMode;
  return _validateCandidate(candidate, desktopMetrics, draft);
}

function trySetContainerEnabled(draft, containerId, enabled, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  if (typeof enabled !== "boolean") {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_ENABLED_VALUE" }
    };
  }

  var candidate = _clone(prep.value);
  var idx = _findContainerIndex(candidate.containers, cid);
  if (idx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  candidate.containers[idx].enabled = enabled;
  return _validateCandidate(candidate, desktopMetrics, draft);
}

function _findAvailableManualSlot(blocks, cols, rows, blockColSpan, blockRowSpan) {
  var occupied = Object.create(null);
  for (var i = 0; i < blocks.length; i++) {
    var b = blocks[i];
    if (b && b.layout && typeof b.layout.col === "number" && typeof b.layout.row === "number") {
      var cs = (typeof b.layout.colSpan === "number") ? b.layout.colSpan : 1;
      var rs = (typeof b.layout.rowSpan === "number") ? b.layout.rowSpan : 1;
      for (var r = 0; r < rs; r++) {
        for (var c = 0; c < cs; c++) {
          occupied[(b.layout.col + c) + "," + (b.layout.row + r)] = true;
        }
      }
    }
  }

  for (var row = 0; row <= rows - blockRowSpan; row++) {
    for (var col = 0; col <= cols - blockColSpan; col++) {
      var fits = true;
      for (var dr = 0; dr < blockRowSpan; dr++) {
        for (var dc = 0; dc < blockColSpan; dc++) {
          if (occupied[(col + dc) + "," + (row + dr)]) {
            fits = false;
            break;
          }
        }
        if (!fits) break;
      }
      if (fits) {
        return { col: col, row: row };
      }
    }
  }
  return null;
}

function tryAddBlock(draft, containerId, kind, variant, source, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  var candidate = _clone(prep.value);
  var idx = _findContainerIndex(candidate.containers, cid);
  if (idx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  var container = candidate.containers[idx];
  if (typeof kind !== "string" || !kind.trim()) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_BLOCK_DEFINITION" }
    };
  }

  var k = kind.trim();
  var reg = _getRegistry();

  if (!_rendererAvailable(k)) {
    if (reg.has(k)) {
      return {
        ok: false,
        value: _clone(draft),
        error: { code: "RENDERER_UNAVAILABLE", kind: k }
      };
    }
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_BLOCK_DEFINITION" }
    };
  }

  if (typeof variant !== "string" || !variant.trim() || !reg.supportsVariant(k, variant.trim())) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_BLOCK_DEFINITION" }
    };
  }
  var v = variant.trim();

  // Validate metric source
  var s = "";
  if (k === "metric") {
    if (typeof source !== "string" || !source.trim() || !reg.supportsSource(k, source.trim())) {
      return {
        ok: false,
        value: _clone(draft),
        error: { code: "INVALID_BLOCK_DEFINITION" }
      };
    }
    s = source.trim();
  }

  // Singleton constraint check
  if (reg.isSingleton(k)) {
    var hasKind = false;
    for (var bi = 0; bi < container.blocks.length; bi++) {
      if (container.blocks[bi] && container.blocks[bi].kind === k) {
        hasKind = true;
        break;
      }
    }
    if (hasKind) {
      return {
        ok: false,
        value: _clone(draft),
        error: { code: "DUPLICATE_SINGLETON", kind: k, containerId: container.id }
      };
    }
  }

  var newBlockId = _generateBlockId(container.blocks);
  var rawBlock = {
    id: newBlockId,
    kind: k,
    variant: v,
    order: container.blocks.length,
    settings: (k === "time") ? { showSeconds: false } : {}
  };
  if (k === "metric") {
    rawBlock.source = s;
  }

  var normalizedBlock = reg.normalizeBlock(rawBlock);
  if (!normalizedBlock) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_BLOCK_DEFINITION" }
    };
  }

  if (container.layoutMode === "manual") {
    var cols = (container.colSpan || 1) * 2;
    var rows = (container.rowSpan || 1) * 2;
    var slot = _findAvailableManualSlot(container.blocks, cols, rows, normalizedBlock.colSpan, normalizedBlock.rowSpan);
    if (!slot) {
      return {
        ok: false,
        value: _clone(draft),
        error: { code: "CONTAINER_NO_SPACE", containerId: container.id }
      };
    }
    normalizedBlock.layout.col = slot.col;
    normalizedBlock.layout.row = slot.row;
  }

  container.blocks.push(normalizedBlock);
  var res = _validateCandidate(candidate, desktopMetrics, draft);
  if (!res.ok) {
    return res;
  }

  return {
    ok: true,
    value: res.value,
    error: null,
    createdId: newBlockId
  };
}

function tryRemoveBlock(draft, containerId, blockId, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  var bid = typeof blockId === "string" ? blockId.trim() : "";
  if (!bid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "BLOCK_NOT_FOUND", blockId: blockId }
    };
  }

  var candidate = _clone(prep.value);
  var cIdx = _findContainerIndex(candidate.containers, cid);
  if (cIdx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  var container = candidate.containers[cIdx];
  var bIdx = _findBlockIndex(container.blocks, bid);
  if (bIdx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "BLOCK_NOT_FOUND", blockId: bid }
    };
  }

  container.blocks.splice(bIdx, 1);
  for (var i = 0; i < container.blocks.length; i++) {
    container.blocks[i].order = i;
    if (container.layoutMode === "auto" && container.blocks[i].layout) {
      delete container.blocks[i].layout.col;
      delete container.blocks[i].layout.row;
    }
  }

  return _validateCandidate(candidate, desktopMetrics, draft);
}

function trySetBlockVariant(draft, containerId, blockId, variant, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  var bid = typeof blockId === "string" ? blockId.trim() : "";
  if (!bid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "BLOCK_NOT_FOUND", blockId: blockId }
    };
  }

  var candidate = _clone(prep.value);
  var cIdx = _findContainerIndex(candidate.containers, cid);
  if (cIdx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  var container = candidate.containers[cIdx];
  var bIdx = _findBlockIndex(container.blocks, bid);
  if (bIdx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "BLOCK_NOT_FOUND", blockId: bid }
    };
  }

  var block = container.blocks[bIdx];
  var reg = _getRegistry();
  if (typeof variant !== "string" || !variant.trim() || !reg.supportsVariant(block.kind, variant.trim())) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_BLOCK_DEFINITION" }
    };
  }
  var v = variant.trim();

  var nextBlock = {
    id: block.id,
    kind: block.kind,
    variant: v,
    order: block.order,
    settings: _clone(block.settings)
  };
  if (block.source !== undefined) {
    nextBlock.source = block.source;
  }
  if (block.layout && typeof block.layout === "object") {
    nextBlock.layout = _clone(block.layout);
  }
  if (block.presentationMode) {
    nextBlock.presentationMode = block.presentationMode;
  }

  var internalLayout = _getInternalLayout();
  var cols = container.colSpan * 2;
  var rows = container.rowSpan * 2;
  var repRes = internalLayout.canReplaceVariant(container.blocks, block.id, nextBlock, cols, rows);
  if (!repRes.ok) {
    return {
      ok: false,
      value: _clone(draft),
      error: {
        code: "CONTAINER_NO_SPACE",
        containerId: container.id,
        blockId: block.id
      }
    };
  }

  container.blocks = repRes.blocks;
  return _validateCandidate(candidate, desktopMetrics, draft);
}

function tryMoveBlock(draft, containerId, blockId, targetSlot, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  var bid = typeof blockId === "string" ? blockId.trim() : "";
  if (!bid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "BLOCK_NOT_FOUND", blockId: blockId }
    };
  }

  var candidate = _clone(prep.value);
  var cIdx = _findContainerIndex(candidate.containers, cid);
  if (cIdx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  var container = candidate.containers[cIdx];
  var bIdx = _findBlockIndex(container.blocks, bid);
  if (bIdx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "BLOCK_NOT_FOUND", blockId: bid }
    };
  }

  if (!targetSlot || typeof targetSlot !== "object" || Array.isArray(targetSlot) ||
      typeof targetSlot.col !== "number" || typeof targetSlot.row !== "number") {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_TARGET_SLOT" }
    };
  }

  var cols = container.colSpan * 2;
  var rows = container.rowSpan * 2;

  if (container.layoutMode === "manual") {
    var blk = container.blocks[bIdx];
    if (!blk.layout || typeof blk.layout !== "object" || Array.isArray(blk.layout)) {
      blk.layout = {};
    }
    blk.layout.col = targetSlot.col;
    blk.layout.row = targetSlot.row;
    return _validateCandidate(candidate, desktopMetrics, draft);
  }

  var slot = {
    columns: cols,
    rows: rows,
    col: targetSlot.col,
    row: targetSlot.row
  };

  var internalLayout = _getInternalLayout();
  var reorderRes = internalLayout.reorderBlocks(container.blocks, bid, slot);
  if (!reorderRes.ok) {
    return {
      ok: false,
      value: _clone(draft),
      error: reorderRes.error && reorderRes.error.code ? reorderRes.error : { code: "INVALID_TARGET_SLOT" }
    };
  }

  container.blocks = reorderRes.blocks;
  return _validateCandidate(candidate, desktopMetrics, draft);
}

function tryMoveBlockBetweenContainers(draft, sourceContainerId, targetContainerId, blockId, targetSlot, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) return prep;

  var srcCid = typeof sourceContainerId === "string" ? sourceContainerId.trim() : "";
  var dstCid = typeof targetContainerId === "string" ? targetContainerId.trim() : "";
  var bid = typeof blockId === "string" ? blockId.trim() : "";

  if (!srcCid) return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: sourceContainerId } };
  if (!dstCid) return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: targetContainerId } };
  if (!bid) return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: blockId } };

  if (srcCid === dstCid) {
    if (targetSlot) {
      return tryMoveBlock(draft, srcCid, bid, targetSlot, desktopMetrics);
    }
    return { ok: true, value: _clone(prep.value), error: null };
  }

  var candidate = _clone(prep.value);
  var srcIdx = _findContainerIndex(candidate.containers, srcCid);
  if (srcIdx === -1) return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: srcCid } };

  var dstIdx = _findContainerIndex(candidate.containers, dstCid);
  if (dstIdx === -1) return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: dstCid } };

  var srcContainer = candidate.containers[srcIdx];
  var dstContainer = candidate.containers[dstIdx];

  var bIdx = _findBlockIndex(srcContainer.blocks, bid);
  if (bIdx === -1) return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: bid } };

  var blockToMove = _clone(srcContainer.blocks[bIdx]);
  var reg = _getRegistry();

  if (reg.isSingleton(blockToMove.kind)) {
    for (var i = 0; i < dstContainer.blocks.length; i++) {
      if (dstContainer.blocks[i].kind === blockToMove.kind) {
        return { ok: false, value: _clone(draft), error: { code: "DUPLICATE_SINGLETON", kind: blockToMove.kind } };
      }
    }
  }

  var dstCols = dstContainer.colSpan * 2;
  var dstRows = dstContainer.rowSpan * 2;
  var fp = reg.footprint(blockToMove.kind, blockToMove.variant);
  if (!fp) {
    return { ok: false, value: _clone(draft), error: { code: "INVALID_BLOCK_VARIANT", kind: blockToMove.kind, variant: blockToMove.variant } };
  }

  if (fp.colSpan > dstCols || fp.rowSpan > dstRows) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NO_SPACE", containerId: dstCid } };
  }

  // Remove from source container and normalize source orders
  srcContainer.blocks.splice(bIdx, 1);
  for (var si = 0; si < srcContainer.blocks.length; si++) {
    srcContainer.blocks[si].order = si;
  }

  // Adjust block layout for destination container
  blockToMove.order = dstContainer.blocks.length;
  blockToMove.colSpan = fp.colSpan;
  blockToMove.rowSpan = fp.rowSpan;

  if (dstContainer.layoutMode === "manual") {
    var targetCol = (targetSlot && typeof targetSlot.col === "number") ? targetSlot.col : 0;
    var targetRow = (targetSlot && typeof targetSlot.row === "number") ? targetSlot.row : 0;
    blockToMove.layout = { col: targetCol, row: targetRow, colSpan: fp.colSpan, rowSpan: fp.rowSpan };
  } else {
    blockToMove.layout = { colSpan: fp.colSpan, rowSpan: fp.rowSpan };
  }

  dstContainer.blocks.push(blockToMove);

  if (dstContainer.layoutMode !== "manual" && targetSlot && typeof targetSlot.col === "number" && typeof targetSlot.row === "number") {
    var internalLayout = _getInternalLayout();
    var reorderRes = internalLayout.reorderBlocks(dstContainer.blocks, blockToMove.id, {
      columns: dstCols,
      rows: dstRows,
      col: targetSlot.col,
      row: targetSlot.row
    });
    if (reorderRes.ok) {
      dstContainer.blocks = reorderRes.blocks;
    }
  }

  return _validateCandidate(candidate, desktopMetrics, draft);
}

function createSnapshot(draft) {
  return _clone(draft);
}

function trySetContainerLayoutMode(draft, containerId, layoutMode, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: containerId }
    };
  }

  if (layoutMode !== "auto" && layoutMode !== "manual") {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "INVALID_LAYOUT_MODE" }
    };
  }

  var candidate = _clone(prep.value);
  var cIdx = _findContainerIndex(candidate.containers, cid);
  if (cIdx === -1) {
    return {
      ok: false,
      value: _clone(draft),
      error: { code: "CONTAINER_NOT_FOUND", containerId: cid }
    };
  }

  var container = candidate.containers[cIdx];
  var internalLayout = _getInternalLayout();
  var cols = container.colSpan * 2;
  var rows = container.rowSpan * 2;

  if (layoutMode === "manual" && container.layoutMode !== "manual") {
    var matRes = internalLayout.materializeManualPlacements(container.blocks, cols, rows);
    if (!matRes.ok) {
      return {
        ok: false,
        value: _clone(draft),
        error: matRes.error || { code: "CONTAINER_NO_SPACE", containerId: cid }
      };
    }
    container.blocks = matRes.blocks;
    container.layoutMode = "manual";
  } else if (layoutMode === "auto") {
    container.layoutMode = "auto";
    for (var bi = 0; bi < container.blocks.length; bi++) {
      var b = container.blocks[bi];
      if (b && b.layout) {
        delete b.layout.col;
        delete b.layout.row;
      }
    }
  }

  return _validateCandidate(candidate, desktopMetrics, draft);
}

function tryPlaceBlock(draft, containerId, blockId, col, row, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: containerId } };
  }
  var bid = typeof blockId === "string" ? blockId.trim() : "";
  if (!bid) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: blockId } };
  }
  if (typeof col !== "number" || col < 0 || Math.floor(col) !== col ||
      typeof row !== "number" || row < 0 || Math.floor(row) !== row) {
    return { ok: false, value: _clone(draft), error: { code: "INVALID_TARGET_SLOT" } };
  }

  var candidate = _clone(prep.value);
  var cIdx = _findContainerIndex(candidate.containers, cid);
  if (cIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: cid } };
  }
  var container = candidate.containers[cIdx];
  if (container.layoutMode !== "manual") {
    return { ok: false, value: _clone(draft), error: { code: "INVALID_LAYOUT_MODE" } };
  }
  var bIdx = _findBlockIndex(container.blocks, bid);
  if (bIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: bid } };
  }

  var block = container.blocks[bIdx];
  var cols = container.colSpan * 2;
  var rows = container.rowSpan * 2;
  var reg = _getRegistry();
  var fp = reg.footprint(block.kind, block.variant) || { colSpan: 1, rowSpan: 1 };
  var bColSpan = (block.layout && typeof block.layout.colSpan === "number") ? block.layout.colSpan : fp.colSpan;
  var bRowSpan = (block.layout && typeof block.layout.rowSpan === "number") ? block.layout.rowSpan : fp.rowSpan;

  if (col + bColSpan > cols || row + bRowSpan > rows) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_OUT_OF_BOUNDS", blockId: bid } };
  }

  for (var bi = 0; bi < container.blocks.length; bi++) {
    if (bi === bIdx) continue;
    var other = container.blocks[bi];
    if (other && other.layout && typeof other.layout.col === "number" && typeof other.layout.row === "number") {
      var otherFp = reg.footprint(other.kind, other.variant) || { colSpan: 1, rowSpan: 1 };
      var oColSpan = (typeof other.layout.colSpan === "number") ? other.layout.colSpan : otherFp.colSpan;
      var oRowSpan = (typeof other.layout.rowSpan === "number") ? other.layout.rowSpan : otherFp.rowSpan;
      if (col < other.layout.col + oColSpan && col + bColSpan > other.layout.col &&
          row < other.layout.row + oRowSpan && row + bRowSpan > other.layout.row) {
        return { ok: false, value: _clone(draft), error: { code: "BLOCK_COLLISION", blockId: bid } };
      }
    }
  }

  if (!block.layout || typeof block.layout !== "object" || Array.isArray(block.layout)) {
    block.layout = {};
  }
  block.layout.col = col;
  block.layout.row = row;

  return _validateCandidate(candidate, desktopMetrics, draft);
}

function tryResizeBlock(draft, containerId, blockId, colSpan, rowSpan, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: containerId } };
  }
  var bid = typeof blockId === "string" ? blockId.trim() : "";
  if (!bid) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: blockId } };
  }
  if (typeof colSpan !== "number" || colSpan < 1 || Math.floor(colSpan) !== colSpan ||
      typeof rowSpan !== "number" || rowSpan < 1 || Math.floor(rowSpan) !== rowSpan) {
    return { ok: false, value: _clone(draft), error: { code: "INVALID_BLOCK_LAYOUT" } };
  }

  var candidate = _clone(prep.value);
  var cIdx = _findContainerIndex(candidate.containers, cid);
  if (cIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: cid } };
  }
  var container = candidate.containers[cIdx];
  var bIdx = _findBlockIndex(container.blocks, bid);
  if (bIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: bid } };
  }

  var block = container.blocks[bIdx];
  var reg = _getRegistry();
  var fp = reg.footprint(block.kind, block.variant);
  if (!fp || colSpan < fp.colSpan || rowSpan < fp.rowSpan) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_BELOW_MINIMUM", blockId: bid } };
  }
  if (!reg.canAllocate(block.kind, block.variant, colSpan, rowSpan)) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_GROWTH_UNSUPPORTED", blockId: bid } };
  }

  var cols = container.colSpan * 2;
  var rows = container.rowSpan * 2;
  var cCol = (block.layout && typeof block.layout.col === "number") ? block.layout.col : 0;
  var cRow = (block.layout && typeof block.layout.row === "number") ? block.layout.row : 0;
  if (container.layoutMode === "manual") {
    if (cCol + colSpan > cols || cRow + rowSpan > rows) {
      return { ok: false, value: _clone(draft), error: { code: "BLOCK_OUT_OF_BOUNDS", blockId: bid } };
    }
    for (var bi = 0; bi < container.blocks.length; bi++) {
      if (bi === bIdx) continue;
      var other = container.blocks[bi];
      if (other && other.layout && typeof other.layout.col === "number" && typeof other.layout.row === "number") {
        var otherFp = reg.footprint(other.kind, other.variant) || { colSpan: 1, rowSpan: 1 };
        var oColSpan = (typeof other.layout.colSpan === "number") ? other.layout.colSpan : otherFp.colSpan;
        var oRowSpan = (typeof other.layout.rowSpan === "number") ? other.layout.rowSpan : otherFp.rowSpan;
        if (cCol < other.layout.col + oColSpan && cCol + colSpan > other.layout.col &&
            cRow < other.layout.row + oRowSpan && cRow + rowSpan > other.layout.row) {
          return { ok: false, value: _clone(draft), error: { code: "BLOCK_COLLISION", blockId: bid } };
        }
      }
    }
  }

  if (!block.layout || typeof block.layout !== "object" || Array.isArray(block.layout)) {
    block.layout = {};
  }
  block.layout.colSpan = colSpan;
  block.layout.rowSpan = rowSpan;
  block.colSpan = colSpan;
  block.rowSpan = rowSpan;

  return _validateCandidate(candidate, desktopMetrics, draft);
}

function trySetBlockPresentation(draft, containerId, blockId, presentationMode, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: containerId } };
  }
  var bid = typeof blockId === "string" ? blockId.trim() : "";
  if (!bid) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: blockId } };
  }
  if (typeof presentationMode !== "string" || ["auto", "icon", "compact", "detailed", "dashboard"].indexOf(presentationMode) === -1) {
    return { ok: false, value: _clone(draft), error: { code: "PRESENTATION_UNSUPPORTED", blockId: bid } };
  }

  var candidate = _clone(prep.value);
  var cIdx = _findContainerIndex(candidate.containers, cid);
  if (cIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: cid } };
  }
  var container = candidate.containers[cIdx];
  var bIdx = _findBlockIndex(container.blocks, bid);
  if (bIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: bid } };
  }

  var block = container.blocks[bIdx];
  var reg = _getRegistry();
  var supp = reg.supportedPresentations(block.kind, block.variant);
  if (supp.indexOf(presentationMode) === -1) {
    return { ok: false, value: _clone(draft), error: { code: "PRESENTATION_UNSUPPORTED", blockId: bid } };
  }

  block.presentationMode = presentationMode;
  return _validateCandidate(candidate, desktopMetrics, draft);
}

function trySetBlockSettings(draft, containerId, blockId, settings, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: containerId } };
  }
  var bid = typeof blockId === "string" ? blockId.trim() : "";
  if (!bid) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: blockId } };
  }

  var candidate = _clone(prep.value);
  var cIdx = _findContainerIndex(candidate.containers, cid);
  if (cIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: cid } };
  }
  var container = candidate.containers[cIdx];
  var bIdx = _findBlockIndex(container.blocks, bid);
  if (bIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: bid } };
  }

  var block = container.blocks[bIdx];
  var reg = _getRegistry();
  var sRes = reg.validateSettings(block.kind, settings, block.variant);
  if (!sRes.valid) {
    return { ok: false, value: _clone(draft), error: { code: sRes.error || "INVALID_BLOCK_SETTINGS", blockId: bid } };
  }

  block.settings = sRes.settings;
  return _validateCandidate(candidate, desktopMetrics, draft);
}

function tryApplyContainerPreset(draft, containerId, preset, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: containerId } };
  }

  var candidate = _clone(prep.value);
  var cIdx = _findContainerIndex(candidate.containers, cid);
  if (cIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: cid } };
  }
  var container = candidate.containers[cIdx];
  var internalLayout = _getInternalLayout();
  var cols = container.colSpan * 2;
  var rows = container.rowSpan * 2;

  var presRes = internalLayout.applyPreset(container.blocks, preset, cols, rows);
  if (!presRes.ok) {
    return { ok: false, value: _clone(draft), error: presRes.error || { code: "PRESET_CANNOT_FIT" } };
  }

  container.blocks = presRes.blocks;
  container.layoutMode = "manual";
  return _validateCandidate(candidate, desktopMetrics, draft);
}

function tryFillBlock(draft, containerId, blockId, desktopMetrics) {
  var prep = _prepareDraft(draft);
  if (!prep.ok) {
    return prep;
  }

  var cid = typeof containerId === "string" ? containerId.trim() : "";
  if (!cid) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: containerId } };
  }
  var bid = typeof blockId === "string" ? blockId.trim() : "";
  if (!bid) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: blockId } };
  }

  var candidate = _clone(prep.value);
  var cIdx = _findContainerIndex(candidate.containers, cid);
  if (cIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "CONTAINER_NOT_FOUND", containerId: cid } };
  }
  var container = candidate.containers[cIdx];
  var bIdx = _findBlockIndex(container.blocks, bid);
  if (bIdx === -1) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_NOT_FOUND", blockId: bid } };
  }

  var cols = container.colSpan * 2;
  var rows = container.rowSpan * 2;
  var block = container.blocks[bIdx];
  var reg = _getRegistry();
  if (!reg.canAllocate(block.kind, block.variant, cols, rows)) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_GROWTH_UNSUPPORTED", blockId: bid } };
  }

  if (container.layoutMode === "manual" && container.blocks.length > 1) {
    return { ok: false, value: _clone(draft), error: { code: "BLOCK_COLLISION", blockId: bid } };
  }

  if (container.layoutMode === "manual") {
    block.layout = { col: 0, row: 0, colSpan: cols, rowSpan: rows };
  } else {
    block.layout = { colSpan: cols, rowSpan: rows };
  }
  block.colSpan = cols;
  block.rowSpan = rows;

  return _validateCandidate(candidate, desktopMetrics, draft);
}

var ComposerModel = {
  validateDraft: validateDraft,
  tryAddContainer: tryAddContainer,
  tryAddContainerWithTemplate: tryAddContainerWithTemplate,
  tryRemoveContainer: tryRemoveContainer,
  tryMoveContainer: tryMoveContainer,
  trySetContainerPosition: trySetContainerPosition,
  tryResizeContainer: tryResizeContainer,
  trySetContainerTitle: trySetContainerTitle,
  trySetContainerHeaderMode: trySetContainerHeaderMode,
  trySetContainerEnabled: trySetContainerEnabled,
  tryAddBlock: tryAddBlock,
  tryRemoveBlock: tryRemoveBlock,
  trySetBlockVariant: trySetBlockVariant,
  tryMoveBlock: tryMoveBlock,
  tryMoveBlockBetweenContainers: tryMoveBlockBetweenContainers,
  createSnapshot: createSnapshot,
  trySetContainerLayoutMode: trySetContainerLayoutMode,
  tryPlaceBlock: tryPlaceBlock,
  tryResizeBlock: tryResizeBlock,
  trySetBlockPresentation: trySetBlockPresentation,
  trySetBlockSettings: trySetBlockSettings,
  tryApplyContainerPreset: tryApplyContainerPreset,
  tryFillBlock: tryFillBlock
};

if (typeof globalThis !== "undefined") {
  globalThis.ComposerModel = ComposerModel;
}
