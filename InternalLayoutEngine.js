/**
 * ArchyWidgets Internal Layout Engine
 * Pure JavaScript internal block layout engine for arranging Blocks inside one Container.
 * Bounded row-major first-fit packing, metrics calculation, and transactional mutations.
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

function _clone(value) {
  if (value === null || typeof value !== "object") {
    return value;
  }
  return JSON.parse(JSON.stringify(value));
}

/**
 * Validates a block list structurally and against the registry.
 * Does not mutate input. Returns validation result and normalized item metadata.
 */
function _validateBlockList(blocks) {
  if (!Array.isArray(blocks)) {
    return {
      valid: false,
      error: { code: "INVALID_BLOCK_LIST" }
    };
  }

  var reg = _getRegistry();
  var seenIds = Object.create(null);
  var items = [];

  for (var i = 0; i < blocks.length; i++) {
    var b = blocks[i];
    if (!b || typeof b !== "object" || Array.isArray(b)) {
      return {
        valid: false,
        error: { code: "INVALID_BLOCK_DEFINITION" }
      };
    }

    if (typeof b.id !== "string" || !b.id.trim()) {
      return {
        valid: false,
        error: { code: "INVALID_BLOCK_ID" }
      };
    }

    var cid = b.id.trim();
    var idKey = "id:" + cid;
    if (seenIds[idKey]) {
      return {
        valid: false,
        error: { code: "DUPLICATE_BLOCK_ID", blockId: cid }
      };
    }
    seenIds[idKey] = true;

    if (!reg.has(b.kind)) {
      return {
        valid: false,
        error: { code: "INVALID_BLOCK_DEFINITION", blockId: cid }
      };
    }

    if (!reg.supportsVariant(b.kind, b.variant)) {
      return {
        valid: false,
        error: { code: "INVALID_BLOCK_DEFINITION", blockId: cid }
      };
    }

    var regEntry = reg.get(b.kind);
    if (regEntry.requiresSource) {
      if (typeof b.source !== "string" || !reg.supportsSource(b.kind, b.source)) {
        return {
          valid: false,
          error: { code: "INVALID_BLOCK_DEFINITION", blockId: cid }
        };
      }
    }

    var fp = reg.footprint(b.kind, b.variant);
    if (!fp || typeof fp.colSpan !== "number" || typeof fp.rowSpan !== "number") {
      return {
        valid: false,
        error: { code: "INVALID_BLOCK_DEFINITION", blockId: cid }
      };
    }

    var allocatedColSpan = fp.colSpan;
    var allocatedRowSpan = fp.rowSpan;
    if (b.layout && typeof b.layout === "object" && !Array.isArray(b.layout)) {
      if (typeof b.layout.colSpan === "number" && isFinite(b.layout.colSpan) && Math.floor(b.layout.colSpan) === b.layout.colSpan) {
        allocatedColSpan = b.layout.colSpan;
      }
      if (typeof b.layout.rowSpan === "number" && isFinite(b.layout.rowSpan) && Math.floor(b.layout.rowSpan) === b.layout.rowSpan) {
        allocatedRowSpan = b.layout.rowSpan;
      }
    }
    if (allocatedColSpan < fp.colSpan || allocatedRowSpan < fp.rowSpan) {
      return { valid: false, error: { code: "BLOCK_BELOW_MINIMUM", blockId: cid } };
    }
    if (!reg.canAllocate(b.kind, b.variant, allocatedColSpan, allocatedRowSpan)) {
      return { valid: false, error: { code: "BLOCK_GROWTH_UNSUPPORTED", blockId: cid } };
    }

    var hasOrder = typeof b.order === "number" && isFinite(b.order) && b.order >= 0 && Math.floor(b.order) === b.order;
    items.push({
      originalIndex: i,
      id: cid,
      colSpan: allocatedColSpan,
      rowSpan: allocatedRowSpan,
      orderVal: hasOrder ? b.order : Infinity,
      block: b
    });
  }

  return {
    valid: true,
    items: items,
    seenIds: seenIds
  };
}

/**
 * Computes exact internal layout metrics for a container content area.
 */
function computeInternalMetrics(contentWidth, contentHeight, columns, rows, gap) {
  if (typeof contentWidth !== "number" || !isFinite(contentWidth) || contentWidth <= 0 ||
      typeof contentHeight !== "number" || !isFinite(contentHeight) || contentHeight <= 0) {
    return { valid: false, error: { code: "INVALID_METRICS" } };
  }

  if (typeof columns !== "number" || !isFinite(columns) || columns <= 0 || Math.floor(columns) !== columns ||
      typeof rows !== "number" || !isFinite(rows) || rows <= 0 || Math.floor(rows) !== rows) {
    return { valid: false, error: { code: "INVALID_METRICS" } };
  }

  if (typeof gap !== "number" || !isFinite(gap) || gap < 0) {
    return { valid: false, error: { code: "INVALID_METRICS" } };
  }

  var cellWidth = (contentWidth - gap * (columns - 1)) / columns;
  var cellHeight = (contentHeight - gap * (rows - 1)) / rows;

  if (cellWidth <= 0 || cellHeight <= 0) {
    return { valid: false, error: { code: "INVALID_METRICS" } };
  }

  return {
    valid: true,
    columns: columns,
    rows: rows,
    gap: gap,
    contentWidth: contentWidth,
    contentHeight: contentHeight,
    cellWidth: cellWidth,
    cellHeight: cellHeight
  };
}

/**
 * Attempts bounded row-major first-fit packing of blocks into a columns x rows grid.
 */
function tryPackBlocks(blocks, columns, rows) {
  if (typeof columns !== "number" || !isFinite(columns) || columns <= 0 || Math.floor(columns) !== columns ||
      typeof rows !== "number" || !isFinite(rows) || rows <= 0 || Math.floor(rows) !== rows) {
    return {
      fits: false,
      placements: [],
      unplacedIds: [],
      errors: [{ code: "INVALID_GRID" }]
    };
  }

  var validation = _validateBlockList(blocks);
  if (!validation.valid) {
    return {
      fits: false,
      placements: [],
      unplacedIds: [],
      errors: [validation.error]
    };
  }

  var items = validation.items.slice();
  if (items.length === 0) {
    return {
      fits: true,
      placements: [],
      unplacedIds: [],
      columns: columns,
      rows: rows,
      usedCells: 0,
      totalCells: columns * rows,
      errors: []
    };
  }

  // Deterministic stable sort by order, tie-breaking by original index
  items.sort(function(a, b) {
    if (a.orderVal !== b.orderVal) {
      return a.orderVal - b.orderVal;
    }
    return a.originalIndex - b.originalIndex;
  });

  // Occupancy matrix: rows x columns
  var grid = [];
  for (var r = 0; r < rows; r++) {
    var rowArr = [];
    for (var c = 0; c < columns; c++) {
      rowArr.push(null);
    }
    grid.push(rowArr);
  }

  var placements = [];
  var unplacedIds = [];
  var errors = [];
  var usedCells = 0;

  for (var k = 0; k < items.length; k++) {
    var item = items[k];
    var placed = false;

    if (item.colSpan <= columns && item.rowSpan <= rows) {
      for (var r = 0; r <= rows - item.rowSpan; r++) {
        for (var c = 0; c <= columns - item.colSpan; c++) {
          var canFit = true;
          for (var dr = 0; dr < item.rowSpan; dr++) {
            for (var dc = 0; dc < item.colSpan; dc++) {
              if (grid[r + dr][c + dc] !== null) {
                canFit = false;
                break;
              }
            }
            if (!canFit) {
              break;
            }
          }

          if (canFit) {
            for (var dr = 0; dr < item.rowSpan; dr++) {
              for (var dc = 0; dc < item.colSpan; dc++) {
                grid[r + dr][c + dc] = item.id;
              }
            }
            placements.push({
              id: item.id,
              index: item.originalIndex,
              gridCol: c,
              gridRow: r,
              colSpan: item.colSpan,
              rowSpan: item.rowSpan
            });
            usedCells += item.colSpan * item.rowSpan;
            placed = true;
            break;
          }
        }
        if (placed) {
          break;
        }
      }
    }

    if (!placed) {
      unplacedIds.push(item.id);
      errors.push({
        code: "CONTAINER_NO_SPACE",
        blockId: item.id
      });
    }
  }

  return {
    fits: unplacedIds.length === 0 && errors.length === 0,
    placements: placements,
    unplacedIds: unplacedIds,
    columns: columns,
    rows: rows,
    usedCells: usedCells,
    totalCells: columns * rows,
    errors: errors
  };
}

/**
 * Validates logical placement and physical pixel geometry against block registry minimums.
 * Returns fits: true/false, placements with pixel coordinates, and errors.
 */
function validateBlockPixelGeometry(blocks, metrics) {
  if (!metrics || typeof metrics !== "object" || metrics.valid !== true) {
    return {
      fits: false,
      placements: [],
      errors: [{ code: "INVALID_METRICS" }]
    };
  }

  if (typeof metrics.columns !== "number" || !isFinite(metrics.columns) || metrics.columns <= 0 ||
      typeof metrics.rows !== "number" || !isFinite(metrics.rows) || metrics.rows <= 0 ||
      typeof metrics.cellWidth !== "number" || !isFinite(metrics.cellWidth) || metrics.cellWidth <= 0 ||
      typeof metrics.cellHeight !== "number" || !isFinite(metrics.cellHeight) || metrics.cellHeight <= 0) {
    return {
      fits: false,
      placements: [],
      errors: [{ code: "INVALID_METRICS" }]
    };
  }

  var gap = (typeof metrics.gap === "number" && isFinite(metrics.gap) && metrics.gap >= 0) ? metrics.gap : 0;

  var packResult = tryPackBlocks(blocks, metrics.columns, metrics.rows);
  if (!packResult || !packResult.fits) {
    return {
      fits: false,
      placements: (packResult && Array.isArray(packResult.placements)) ? packResult.placements : [],
      errors: (packResult && Array.isArray(packResult.errors)) ? packResult.errors : [{ code: "CONTAINER_NO_SPACE" }]
    };
  }

  var reg = _getRegistry();
  var errors = [];
  var enrichedPlacements = [];

  var blockMap = Object.create(null);
  if (Array.isArray(blocks)) {
    for (var b = 0; b < blocks.length; b++) {
      if (blocks[b] && typeof blocks[b].id === "string") {
        blockMap[blocks[b].id.trim()] = blocks[b];
      }
    }
  }

  for (var i = 0; i < packResult.placements.length; i++) {
    var p = packResult.placements[i];
    var block = blockMap[p.id];
    var kind = block ? block.kind : "";
    var variant = block ? block.variant : "";

    var pixelWidth = p.colSpan * metrics.cellWidth + (p.colSpan - 1) * gap;
    var pixelHeight = p.rowSpan * metrics.cellHeight + (p.rowSpan - 1) * gap;

    var fp = reg.footprint(kind, variant);
    var minW = (fp && typeof fp.minPixelWidth === "number") ? fp.minPixelWidth : 0;
    var minH = (fp && typeof fp.minPixelHeight === "number") ? fp.minPixelHeight : 0;

    if (pixelWidth < minW || pixelHeight < minH) {
      errors.push({
        code: "BLOCK_BELOW_MIN_SIZE",
        blockId: p.id,
        required: { width: minW, height: minH },
        actual: { width: pixelWidth, height: pixelHeight }
      });
    }

    enrichedPlacements.push({
      id: p.id,
      index: p.index,
      gridCol: p.gridCol,
      gridRow: p.gridRow,
      colSpan: p.colSpan,
      rowSpan: p.rowSpan,
      x: p.gridCol * (metrics.cellWidth + gap),
      y: p.gridRow * (metrics.cellHeight + gap),
      width: pixelWidth,
      height: pixelHeight
    });
  }

  if (errors.length > 0) {
    return {
      fits: false,
      placements: enrichedPlacements,
      errors: errors
    };
  }

  return {
    fits: true,
    placements: enrichedPlacements,
    errors: []
  };
}

/**
 * Converts a content-local point (x, y) to the nearest internal cell coordinate.
 */
function findNearestBlockSlot(x, y, metrics) {
  if (!metrics || metrics.valid !== true) {
    return null;
  }
  if (typeof x !== "number" || !isFinite(x) || typeof y !== "number" || !isFinite(y)) {
    return null;
  }

  var strideX = metrics.cellWidth + metrics.gap;
  var strideY = metrics.cellHeight + metrics.gap;
  if (strideX <= 0 || strideY <= 0) {
    return null;
  }

  var col = Math.round(x / strideX);
  var row = Math.round(y / strideY);

  col = Math.max(0, Math.min(metrics.columns - 1, col));
  row = Math.max(0, Math.min(metrics.rows - 1, row));

  return { col: col, row: row };
}

/**
 * Reorders a block within a container to a target slot and validates packing.
 */
function reorderBlocks(blocks, blockId, targetSlot) {
  if (!Array.isArray(blocks)) {
    return {
      ok: false,
      blocks: [],
      layout: null,
      error: { code: "INVALID_BLOCK_LIST" }
    };
  }

  if (typeof blockId !== "string" || !blockId.trim()) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_BLOCK_ID" }
    };
  }
  var cid = blockId.trim();

  if (!targetSlot || typeof targetSlot !== "object" || Array.isArray(targetSlot)) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_TARGET_SLOT" }
    };
  }

  var cols = targetSlot.columns;
  var rws = targetSlot.rows;
  var targetCol = targetSlot.col;
  var targetRow = targetSlot.row;

  if (typeof cols !== "number" || !isFinite(cols) || cols <= 0 || Math.floor(cols) !== cols ||
      typeof rws !== "number" || !isFinite(rws) || rws <= 0 || Math.floor(rws) !== rws ||
      typeof targetCol !== "number" || !isFinite(targetCol) || Math.floor(targetCol) !== targetCol ||
      typeof targetRow !== "number" || !isFinite(targetRow) || Math.floor(targetRow) !== targetRow) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_TARGET_SLOT" }
    };
  }

  if (targetCol < 0 || targetCol >= cols || targetRow < 0 || targetRow >= rws) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_TARGET_SLOT" }
    };
  }

  // Validate complete block list structurally and against registry before touching elements
  var validation = _validateBlockList(blocks);
  if (!validation.valid) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: validation.error
    };
  }

  var idKey = "id:" + cid;
  if (!validation.seenIds[idKey]) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "BLOCK_NOT_FOUND", blockId: cid }
    };
  }

  var cloneList = _clone(blocks);
  var items = [];
  for (var i = 0; i < cloneList.length; i++) {
    var blk = cloneList[i];
    var hasOrder = typeof blk.order === "number" && isFinite(blk.order) && blk.order >= 0 && Math.floor(blk.order) === blk.order;
    items.push({
      originalIndex: i,
      block: blk,
      orderVal: hasOrder ? blk.order : Infinity
    });
  }

  items.sort(function(a, b) {
    if (a.orderVal !== b.orderVal) {
      return a.orderVal - b.orderVal;
    }
    return a.originalIndex - b.originalIndex;
  });

  var targetItem = null;
  var targetItemIndex = -1;
  for (var i = 0; i < items.length; i++) {
    if (typeof items[i].block.id === "string" && items[i].block.id.trim() === cid) {
      targetItem = items[i];
      targetItemIndex = i;
      break;
    }
  }

  items.splice(targetItemIndex, 1);

  var targetIndex = targetRow * cols + targetCol;
  targetIndex = Math.min(items.length, Math.max(0, targetIndex));
  items.splice(targetIndex, 0, targetItem);

  var candidate = [];
  for (var i = 0; i < items.length; i++) {
    var b = items[i].block;
    b.order = i;
    candidate.push(b);
  }

  var layout = tryPackBlocks(candidate, cols, rws);
  if (layout.fits) {
    return {
      ok: true,
      blocks: candidate,
      layout: layout,
      error: null
    };
  }

  return {
    ok: false,
    blocks: _clone(blocks),
    layout: layout,
    error: layout.errors && layout.errors.length > 0 ? layout.errors[0] : { code: "CONTAINER_NO_SPACE", blockId: cid }
  };
}

/**
 * Validates whether replacing a block with nextBlock fits in the container grid.
 */
function canReplaceVariant(blocks, blockId, nextBlock, columns, rows) {
  if (!Array.isArray(blocks)) {
    return {
      ok: false,
      blocks: [],
      layout: null,
      error: { code: "INVALID_BLOCK_LIST" }
    };
  }

  if (typeof blockId !== "string" || !blockId.trim()) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_BLOCK_ID" }
    };
  }
  var cid = blockId.trim();

  if (typeof columns !== "number" || !isFinite(columns) || columns <= 0 || Math.floor(columns) !== columns ||
      typeof rows !== "number" || !isFinite(rows) || rows <= 0 || Math.floor(rows) !== rows) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_GRID" }
    };
  }

  var matchIndex = -1;
  for (var i = 0; i < blocks.length; i++) {
    if (blocks[i] && typeof blocks[i].id === "string" && blocks[i].id.trim() === cid) {
      matchIndex = i;
      break;
    }
  }

  if (matchIndex === -1) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "BLOCK_NOT_FOUND", blockId: cid }
    };
  }

  var originalBlock = blocks[matchIndex];

  if (!nextBlock || typeof nextBlock !== "object" || Array.isArray(nextBlock)) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_BLOCK_DEFINITION" }
    };
  }

  if (typeof nextBlock.id !== "string" || nextBlock.id.trim() !== cid) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_BLOCK_ID" }
    };
  }

  var reg = _getRegistry();
  if (!reg.has(nextBlock.kind)) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_BLOCK_DEFINITION", blockId: cid }
    };
  }

  if (!reg.supportsVariant(nextBlock.kind, nextBlock.variant)) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_BLOCK_DEFINITION", blockId: cid }
    };
  }

  var regEntry = reg.get(nextBlock.kind);
  if (regEntry.requiresSource) {
    if (typeof nextBlock.source !== "string" || !reg.supportsSource(nextBlock.kind, nextBlock.source)) {
      return {
        ok: false,
        blocks: _clone(blocks),
        layout: null,
        error: { code: "INVALID_BLOCK_DEFINITION", blockId: cid }
      };
    }
  }

  var normalized = reg.normalizeBlock(nextBlock);
  if (!normalized) {
    return {
      ok: false,
      blocks: _clone(blocks),
      layout: null,
      error: { code: "INVALID_BLOCK_DEFINITION", blockId: cid }
    };
  }

  // Preserve original order value regardless of forged replacement order
  normalized.order = (typeof originalBlock.order === "number" && isFinite(originalBlock.order) && originalBlock.order >= 0)
    ? Math.floor(originalBlock.order)
    : 0;

  // Preserve manual layout coordinates if present, clamping within grid bounds
  if (originalBlock.layout && typeof originalBlock.layout === "object") {
    if (typeof originalBlock.layout.col === "number") {
      var maxCol = Math.max(0, columns - normalized.layout.colSpan);
      normalized.layout.col = Math.max(0, Math.min(originalBlock.layout.col, maxCol));
    }
    if (typeof originalBlock.layout.row === "number") {
      var maxRow = Math.max(0, rows - normalized.layout.rowSpan);
      normalized.layout.row = Math.max(0, Math.min(originalBlock.layout.row, maxRow));
    }
  }

  var candidate = _clone(blocks);
  candidate[matchIndex] = normalized;

  var layout = tryPackBlocks(candidate, columns, rows);
  if (layout.fits) {
    return {
      ok: true,
      blocks: candidate,
      layout: layout,
      error: null
    };
  }

  return {
    ok: false,
    blocks: _clone(blocks),
    layout: layout,
    error: layout.errors && layout.errors.length > 0 ? layout.errors[0] : { code: "CONTAINER_NO_SPACE", blockId: cid }
  };
}

function validateManualPlacements(blocks, columns, rows) {
  if (!Array.isArray(blocks)) {
    return { valid: false, placements: [], error: { code: "INVALID_BLOCK_LIST" } };
  }
  if (typeof columns !== "number" || !isFinite(columns) || columns <= 0 || Math.floor(columns) !== columns ||
      typeof rows !== "number" || !isFinite(rows) || rows <= 0 || Math.floor(rows) !== rows) {
    return { valid: false, placements: [], error: { code: "INVALID_GRID" } };
  }

  var reg = _getRegistry();
  var occupied = Object.create(null);
  var placements = [];

  for (var i = 0; i < blocks.length; i++) {
    var b = blocks[i];
    if (!b || typeof b !== "object" || Array.isArray(b)) {
      return { valid: false, placements: [], error: { code: "INVALID_BLOCK_DEFINITION" } };
    }
    if (typeof b.id !== "string" || !b.id.trim()) {
      return { valid: false, placements: [], error: { code: "INVALID_BLOCK_ID" } };
    }
    var bid = b.id.trim();

    if (!reg.has(b.kind) || !reg.supportsVariant(b.kind, b.variant)) {
      return { valid: false, placements: [], error: { code: "INVALID_BLOCK_DEFINITION", blockId: bid } };
    }

    var fp = reg.footprint(b.kind, b.variant);
    if (!fp) {
      return { valid: false, placements: [], error: { code: "INVALID_BLOCK_DEFINITION", blockId: bid } };
    }

    if (!b.layout || typeof b.layout !== "object" || Array.isArray(b.layout) ||
        typeof b.layout.col !== "number" || b.layout.col < 0 || Math.floor(b.layout.col) !== b.layout.col ||
        typeof b.layout.row !== "number" || b.layout.row < 0 || Math.floor(b.layout.row) !== b.layout.row) {
      return { valid: false, placements: [], error: { code: "INVALID_BLOCK_LAYOUT", blockId: bid } };
    }

    var col = b.layout.col;
    var row = b.layout.row;
    var colSpan = (typeof b.layout.colSpan === "number") ? Math.floor(b.layout.colSpan) : fp.colSpan;
    var rowSpan = (typeof b.layout.rowSpan === "number") ? Math.floor(b.layout.rowSpan) : fp.rowSpan;

    if (colSpan < fp.colSpan || rowSpan < fp.rowSpan) {
      return { valid: false, placements: [], error: { code: "BLOCK_BELOW_MINIMUM", blockId: bid } };
    }

    if (!reg.canAllocate(b.kind, b.variant, colSpan, rowSpan)) {
      return { valid: false, placements: [], error: { code: "BLOCK_GROWTH_UNSUPPORTED", blockId: bid } };
    }

    if (col + colSpan > columns || row + rowSpan > rows) {
      return { valid: false, placements: [], error: { code: "BLOCK_OUT_OF_BOUNDS", blockId: bid } };
    }

    for (var dr = 0; dr < rowSpan; dr++) {
      for (var dc = 0; dc < colSpan; dc++) {
        var cellKey = (col + dc) + "," + (row + dr);
        if (occupied[cellKey]) {
          return { valid: false, placements: [], error: { code: "BLOCK_COLLISION", blockId: bid } };
        }
        occupied[cellKey] = bid;
      }
    }

    placements.push({
      id: bid,
      index: i,
      gridCol: col,
      gridRow: row,
      colSpan: colSpan,
      rowSpan: rowSpan
    });
  }

  return { valid: true, placements: placements, error: null };
}

function materializeManualPlacements(blocks, columns, rows) {
  if (!Array.isArray(blocks)) {
    return { ok: false, blocks: [], error: { code: "INVALID_BLOCK_LIST" } };
  }
  var packRes = tryPackBlocks(blocks, columns, rows);
  if (!packRes || !packRes.fits) {
    return {
      ok: false,
      blocks: _clone(blocks),
      error: (packRes && packRes.errors && packRes.errors.length > 0) ? packRes.errors[0] : { code: "CONTAINER_NO_SPACE" }
    };
  }

  var cloned = _clone(blocks);
  // If there is only one block, expand it to fill the entire manual container grid
  // so switching from auto to manual mode does not collapse its size.
  if (cloned.length === 1 && packRes.placements.length === 1) {
    var reg = _getRegistry();
    var soleBlock = cloned[0];
    if (soleBlock && reg.canAllocate(soleBlock.kind, soleBlock.variant, columns, rows)) {
      if (!soleBlock.layout || typeof soleBlock.layout !== "object" || Array.isArray(soleBlock.layout)) {
        soleBlock.layout = {};
      }
      soleBlock.layout.col = 0;
      soleBlock.layout.row = 0;
      soleBlock.layout.colSpan = columns;
      soleBlock.layout.rowSpan = rows;
      soleBlock.colSpan = columns;
      soleBlock.rowSpan = rows;
      return { ok: true, blocks: cloned, error: null };
    }
  }

  for (var i = 0; i < packRes.placements.length; i++) {
    var p = packRes.placements[i];
    var b = cloned[p.index];
    if (b) {
      if (!b.layout || typeof b.layout !== "object" || Array.isArray(b.layout)) {
        b.layout = {};
      }
      b.layout.col = p.gridCol;
      b.layout.row = p.gridRow;
      b.layout.colSpan = p.colSpan;
      b.layout.rowSpan = p.rowSpan;
      b.colSpan = p.colSpan;
      b.rowSpan = p.rowSpan;
    }
  }

  return { ok: true, blocks: cloned, error: null };
}

function resolvePresentation(block, pixelWidth, pixelHeight) {
  if (!block || typeof block !== "object" || Array.isArray(block)) {
    return { ok: false, error: { code: "INVALID_BLOCK_DEFINITION" } };
  }
  if (typeof pixelWidth !== "number" || !isFinite(pixelWidth) || pixelWidth <= 0 ||
      typeof pixelHeight !== "number" || !isFinite(pixelHeight) || pixelHeight <= 0) {
    return { ok: false, error: { code: "INVALID_METRICS", blockId: block.id } };
  }

  var reg = _getRegistry();
  if (!reg.has(block.kind)) {
    return { ok: false, error: { code: "INVALID_BLOCK_DEFINITION", blockId: block.id } };
  }

  var supported = reg.supportedPresentations(block.kind, block.variant);
  var mode = (typeof block.presentationMode === "string" && block.presentationMode.trim())
    ? block.presentationMode.trim()
    : "auto";

  if (mode !== "auto") {
    if (supported.indexOf(mode) === -1) {
      return { ok: false, error: { code: "PRESENTATION_UNSUPPORTED", blockId: block.id, mode: mode } };
    }
    var minSize = reg.presentationMinimum(block.kind, block.variant, mode);
    var minW = minSize ? minSize.minPixelWidth : 0;
    var minH = minSize ? minSize.minPixelHeight : 0;
    if (pixelWidth < minW || pixelHeight < minH) {
      return {
        ok: false,
        error: {
          code: "PRESENTATION_TOO_LARGE",
          blockId: block.id,
          mode: mode,
          required: { width: minW, height: minH },
          actual: { width: pixelWidth, height: pixelHeight }
        }
      };
    }
    return { ok: true, presentation: mode };
  }

  var preference = ["dashboard", "detailed", "compact", "icon"];
  for (var i = 0; i < preference.length; i++) {
    var candidate = preference[i];
    if (supported.indexOf(candidate) !== -1) {
      // A presentation being technically renderable is not enough to make it
      // the right automatic choice. Use semantic breakpoints for auto mode so
      // a 1x1 container stays compact while a genuinely larger allocation can
      // expose the detailed or dashboard composition. Explicit user choices still
      // use the lower hard minimums above.
      var cMin = (typeof reg.autoPresentationMinimum === "function")
        ? reg.autoPresentationMinimum(block.kind, block.variant, candidate)
        : reg.presentationMinimum(block.kind, block.variant, candidate);
      var reqW = cMin ? cMin.minPixelWidth : 0;
      var reqH = cMin ? cMin.minPixelHeight : 0;
      if (pixelWidth >= reqW && pixelHeight >= reqH) {
        return { ok: true, presentation: candidate };
      }
    }
  }

  return {
    ok: false,
    error: {
      code: "PRESENTATION_TOO_LARGE",
      blockId: block.id,
      mode: "auto",
      actual: { width: pixelWidth, height: pixelHeight }
    }
  };
}

function _partitionGridUnits(total, groups) {
  if (typeof total !== "number" || typeof groups !== "number" || groups < 1 || groups > total) {
    return null;
  }
  var base = Math.floor(total / groups);
  var remainder = total % groups;
  var sizes = [];
  var offsets = [];
  var offset = 0;
  for (var i = 0; i < groups; i++) {
    var size = base + (i < remainder ? 1 : 0);
    offsets.push(offset);
    sizes.push(size);
    offset += size;
  }
  return { sizes: sizes, offsets: offsets };
}

/**
 * Distributes multiple auto-layout blocks across the whole internal grid.
 * The old first-fit path kept every block at its minimum footprint, so growing
 * an outer container only created empty cells and looked identical to the
 * smaller size. Candidate tile grids are scored by the blocks' natural aspect
 * ratio and presentation consistency; logical config data remains untouched.
 */
function _balancedAutoPlacements(blocks, metrics) {
  if (!Array.isArray(blocks) || blocks.length < 2 || !metrics || metrics.valid !== true) {
    return null;
  }

  var validation = _validateBlockList(blocks);
  if (!validation.valid) return null;

  var ordered = validation.items.slice();
  ordered.sort(function(a, b) {
    if (a.orderVal !== b.orderVal) return a.orderVal - b.orderVal;
    return a.originalIndex - b.originalIndex;
  });

  var reg = _getRegistry();
  var gap = (typeof metrics.gap === "number" && isFinite(metrics.gap) && metrics.gap >= 0) ? metrics.gap : 0;

  // Curated composition for 2x2 (4x4 internal) Clock & Calendar containers:
  // A digital clock needs only 1 header row while the 42-day monthly calendar
  // thrives on the remaining 3 rows.
  if (metrics.columns >= 4 && metrics.rows >= 4 && (ordered.length === 2 || ordered.length === 3)) {
    var timeItem = null;
    var dateItem = null;
    var wsItem = null;
    for (var ci = 0; ci < ordered.length; ci++) {
      var k = ordered[ci].block.kind;
      if (k === "time") timeItem = ordered[ci];
      else if (k === "date") dateItem = ordered[ci];
      else if (k === "workspace") wsItem = ordered[ci];
    }
    if (timeItem && dateItem && (ordered.length === 2 || wsItem)) {
      var topRowH = metrics.cellHeight;
      var calRows = metrics.rows - 1;
      var calH = calRows * metrics.cellHeight + (calRows - 1) * gap;
      var fullW = metrics.columns * metrics.cellWidth + (metrics.columns - 1) * gap;
      var timeCols = wsItem ? (metrics.columns - 1) : metrics.columns;
      var timeW = timeCols * metrics.cellWidth + (timeCols - 1) * gap;
      var timePres = resolvePresentation(timeItem.block, timeW, topRowH);
      var datePres = resolvePresentation(dateItem.block, fullW, calH);
      var wsPres = wsItem ? resolvePresentation(wsItem.block, metrics.cellWidth, topRowH) : { ok: true, presentation: "compact" };
      if (timePres.ok && datePres.ok && wsPres.ok) {
        var clockPlacements = [
          {
            id: timeItem.id,
            index: timeItem.originalIndex,
            gridCol: 0,
            gridRow: 0,
            colSpan: timeCols,
            rowSpan: 1,
            x: 0,
            y: 0,
            width: timeW,
            height: topRowH,
            resolvedPresentation: timePres.presentation
          }
        ];
        if (wsItem) {
          clockPlacements.push({
            id: wsItem.id,
            index: wsItem.originalIndex,
            gridCol: timeCols,
            gridRow: 0,
            colSpan: 1,
            rowSpan: 1,
            x: timeCols * (metrics.cellWidth + gap),
            y: 0,
            width: metrics.cellWidth,
            height: topRowH,
            resolvedPresentation: wsPres.presentation
          });
        }
        clockPlacements.push({
          id: dateItem.id,
          index: dateItem.originalIndex,
          gridCol: 0,
          gridRow: 1,
          colSpan: metrics.columns,
          rowSpan: calRows,
          x: 0,
          y: topRowH + gap,
          width: fullW,
          height: calH,
          resolvedPresentation: datePres.presentation
        });
        return clockPlacements;
      }
    }
  }

  // Heterogeneous composition: 1 or more full-width banner/control blocks + standard blocks
  // e.g. Fan & Thermals (fan-control + temperature metrics)
  var fwItems = [];
  var stdItems = [];
  for (var hi = 0; hi < ordered.length; hi++) {
    var hBlock = ordered[hi].block;
    var hFp = reg.footprint(hBlock.kind, hBlock.variant);
    if ((hFp && hFp.colSpan >= metrics.columns) || hBlock.kind === "fan-control") {
      fwItems.push(ordered[hi]);
    } else {
      stdItems.push(ordered[hi]);
    }
  }

  if (fwItems.length > 0 && stdItems.length > 0 && metrics.rows >= 2) {
    var fwRowBudget = 0;
    for (var fwi = 0; fwi < fwItems.length; fwi++) {
      var itemFw = fwItems[fwi];
      var fFp = reg.footprint(itemFw.block.kind, itemFw.block.variant);
      var fMinH = (fFp && fFp.rowSpan) ? fFp.rowSpan : 1;
      if (itemFw.block.kind === "fan-control" && metrics.rows >= 4 && (metrics.rows - 2) >= 1) {
        fMinH = 2;
      }
      fwRowBudget += fMinH;
    }

    if (fwRowBudget < metrics.rows) {
      var stdRowBudget = metrics.rows - fwRowBudget;
      var sTileRows = Math.min(stdRowBudget, Math.max(1, Math.ceil(stdItems.length / 2)));
      var sRowParts = _partitionGridUnits(stdRowBudget, sTileRows);

      if (sRowParts) {
        var stdPlacements = [];
        var stdValid = true;
        var sItemIdx = 0;

        for (var sTr = 0; sTr < sTileRows && stdValid; sTr++) {
          var sRemaining = stdItems.length - sItemIdx;
          var sItemsInThisRow = Math.min(Math.ceil(sRemaining / (sTileRows - sTr)), metrics.columns);
          var sColParts = _partitionGridUnits(metrics.columns, sItemsInThisRow);
          if (!sColParts) { stdValid = false; break; }

          for (var sTc = 0; sTc < sItemsInThisRow; sTc++) {
            var sItem = stdItems[sItemIdx++];
            var sColSpan = sColParts.sizes[sTc];
            var sRowSpan = sRowParts.sizes[sTr];
            if (!reg.canAllocate(sItem.block.kind, sItem.block.variant, sColSpan, sRowSpan)) {
              stdValid = false;
              break;
            }
            stdPlacements.push({
              item: sItem,
              relCol: sColParts.offsets[sTc],
              relRow: sRowParts.offsets[sTr],
              colSpan: sColSpan,
              rowSpan: sRowSpan
            });
          }
        }

        if (stdValid && stdPlacements.length === stdItems.length) {
          var avgFwOrder = 0;
          for (var i = 0; i < fwItems.length; i++) avgFwOrder += fwItems[i].orderVal;
          avgFwOrder /= fwItems.length;

          var avgStdOrder = 0;
          for (var i = 0; i < stdItems.length; i++) avgStdOrder += stdItems[i].orderVal;
          avgStdOrder /= stdItems.length;

          var startFwRow = (avgFwOrder < avgStdOrder) ? 0 : stdRowBudget;
          var startStdRow = (avgFwOrder < avgStdOrder) ? fwRowBudget : 0;

          var combined = [];
          var curFwRow = startFwRow;
          for (var f = 0; f < fwItems.length; f++) {
            var fItem = fwItems[f];
            var fFp = reg.footprint(fItem.block.kind, fItem.block.variant);
            var fSpanH = (fItem.block.kind === "fan-control" && fwRowBudget >= 2) ? 2 : ((fFp && fFp.rowSpan) ? fFp.rowSpan : 1);
            var pW = metrics.columns * metrics.cellWidth + (metrics.columns - 1) * gap;
            var pH = fSpanH * metrics.cellHeight + (fSpanH - 1) * gap;
            var pres = resolvePresentation(fItem.block, pW, pH);
            if (!pres.ok) { stdValid = false; break; }

            combined.push({
              id: fItem.id,
              index: fItem.originalIndex,
              gridCol: 0,
              gridRow: curFwRow,
              colSpan: metrics.columns,
              rowSpan: fSpanH,
              x: 0,
              y: curFwRow * (metrics.cellHeight + gap),
              width: pW,
              height: pH,
              resolvedPresentation: pres.presentation
            });
            curFwRow += fSpanH;
          }

          for (var s = 0; s < stdPlacements.length && stdValid; s++) {
            var sp = stdPlacements[s];
            var actualRow = startStdRow + sp.relRow;
            var actualCol = sp.relCol;
            var pW = sp.colSpan * metrics.cellWidth + (sp.colSpan - 1) * gap;
            var pH = sp.rowSpan * metrics.cellHeight + (sp.rowSpan - 1) * gap;
            var pres = resolvePresentation(sp.item.block, pW, pH);
            if (!pres.ok) { stdValid = false; break; }

            combined.push({
              id: sp.item.id,
              index: sp.item.originalIndex,
              gridCol: actualCol,
              gridRow: actualRow,
              colSpan: sp.colSpan,
              rowSpan: sp.rowSpan,
              x: actualCol * (metrics.cellWidth + gap),
              y: actualRow * (metrics.cellHeight + gap),
              width: pW,
              height: pH,
              resolvedPresentation: pres.presentation
            });
          }

          if (stdValid && combined.length === ordered.length) {
            return combined;
          }
        }
      }
    }
  }

  var best = null;
  var maxTileColumns = Math.min(ordered.length, metrics.columns);

  for (var tileColumns = 1; tileColumns <= maxTileColumns; tileColumns++) {
    var tileRows = Math.ceil(ordered.length / tileColumns);
    if (tileRows > metrics.rows) continue;

    var rowParts = _partitionGridUnits(metrics.rows, tileRows);
    if (!rowParts) continue;

    var candidate = [];
    var score = 0;
    var presentationKinds = Object.create(null);
    var automaticPlacementIndexes = [];
    var lowestAutomaticPresentationRank = Infinity;
    var itemIndex = 0;
    var valid = true;

    for (var tileRow = 0; tileRow < tileRows && valid; tileRow++) {
      var remaining = ordered.length - itemIndex;
      var itemsInRow = Math.min(tileColumns, remaining);
      var colParts = _partitionGridUnits(metrics.columns, itemsInRow);
      if (!colParts) {
        valid = false;
        break;
      }

      for (var tileCol = 0; tileCol < itemsInRow; tileCol++) {
        var item = ordered[itemIndex++];
        var block = item.block;
        var colSpan = colParts.sizes[tileCol];
        var rowSpan = rowParts.sizes[tileRow];
        if (!reg.canAllocate(block.kind, block.variant, colSpan, rowSpan)) {
          valid = false;
          break;
        }

        var pixelWidth = colSpan * metrics.cellWidth + (colSpan - 1) * gap;
        var pixelHeight = rowSpan * metrics.cellHeight + (rowSpan - 1) * gap;
        var pres = resolvePresentation(block, pixelWidth, pixelHeight);
        if (!pres.ok) {
          valid = false;
          break;
        }

        var fp = reg.footprint(block.kind, block.variant);
        var desiredAspect = (fp && fp.minPixelHeight > 0) ? (fp.minPixelWidth / fp.minPixelHeight) : 1.5;
        var actualAspect = pixelWidth / Math.max(1, pixelHeight);
        score += Math.abs(Math.log(Math.max(0.01, actualAspect / Math.max(0.01, desiredAspect))));
        presentationKinds[pres.presentation] = true;

        candidate.push({
          id: item.id,
          index: item.originalIndex,
          gridCol: colParts.offsets[tileCol],
          gridRow: rowParts.offsets[tileRow],
          colSpan: colSpan,
          rowSpan: rowSpan,
          x: colParts.offsets[tileCol] * (metrics.cellWidth + gap),
          y: rowParts.offsets[tileRow] * (metrics.cellHeight + gap),
          width: pixelWidth,
          height: pixelHeight,
          resolvedPresentation: pres.presentation
        });

        var requestedMode = (typeof block.presentationMode === "string" && block.presentationMode.trim())
          ? block.presentationMode.trim()
          : "auto";
        if (requestedMode === "auto") {
          var presentationRank = pres.presentation === "icon"
            ? 0
            : (pres.presentation === "compact" ? 1 : (pres.presentation === "detailed" ? 2 : 3));
          automaticPlacementIndexes.push(candidate.length - 1);
          lowestAutomaticPresentationRank = Math.min(lowestAutomaticPresentationRank, presentationRank);
        }
      }
    }

    if (!valid || candidate.length !== ordered.length) continue;

    // Auto siblings should read as one composition. If an uneven logical
    // partition gives only one tile enough room for a richer mode, keep every
    // automatic sibling at the richest mode they can all share. A genuinely
    // larger container still promotes the complete group together.
    if (automaticPlacementIndexes.length > 1 && lowestAutomaticPresentationRank !== Infinity) {
      var sharedPresentation = lowestAutomaticPresentationRank === 0
        ? "icon"
        : (lowestAutomaticPresentationRank === 1
          ? "compact"
          : (lowestAutomaticPresentationRank === 2 ? "detailed" : "dashboard"));
      for (var autoIndex = 0; autoIndex < automaticPlacementIndexes.length; autoIndex++) {
        candidate[automaticPlacementIndexes[autoIndex]].resolvedPresentation = sharedPresentation;
      }

      // When two geometries are both valid, prefer the one that can expose
      // meaningfully richer content. This prevents a wide clock, for example,
      // from stacking two extremely wide compact strips merely because their
      // raw aspect ratio is marginally closer to the registry footprint.
      if (sharedPresentation === "detailed") score += 0.25;
      if (sharedPresentation === "compact") score += 0.75;
      if (sharedPresentation === "icon") score += 1.5;
    }

    // Prefer a consistent information density among sibling blocks when two
    // tilings are otherwise comparable. Auto siblings are harmonized above;
    // this small residual penalty mainly applies to deliberate explicit modes.
    presentationKinds = Object.create(null);
    for (var candidateIndex = 0; candidateIndex < candidate.length; candidateIndex++) {
      presentationKinds[candidate[candidateIndex].resolvedPresentation] = true;
    }
    var presentationCount = Object.keys(presentationKinds).length;
    score += Math.max(0, presentationCount - 1) * 0.75;

    if (!best || score < best.score - 0.000001) {
      best = { score: score, placements: candidate };
    }
  }

  return best ? best.placements : null;
}

function applyPreset(blocks, preset, columns, rows) {
  if (!Array.isArray(blocks)) {
    return { ok: false, blocks: [], error: { code: "INVALID_BLOCK_LIST" } };
  }
  if (typeof columns !== "number" || !isFinite(columns) || columns <= 0 ||
      typeof rows !== "number" || !isFinite(rows) || rows <= 0) {
    return { ok: false, blocks: _clone(blocks), error: { code: "INVALID_GRID" } };
  }
  if (blocks.length === 0) {
    return { ok: true, blocks: [], error: null };
  }

  var reg = _getRegistry();
  var cloned = _clone(blocks);
  var n = cloned.length;

  if (preset === "fill") {
    if (n !== 1) {
      return { ok: false, blocks: _clone(blocks), error: { code: "PRESET_CANNOT_FIT" } };
    }
    var b = cloned[0];
    if (!reg.canAllocate(b.kind, b.variant, columns, rows)) {
      return { ok: false, blocks: _clone(blocks), error: { code: "PRESET_CANNOT_FIT" } };
    }
    b.layout = { col: 0, row: 0, colSpan: columns, rowSpan: rows };
    b.colSpan = columns;
    b.rowSpan = rows;
    return { ok: true, blocks: cloned, error: null };
  }

  if (preset === "equal-rows") {
    if (rows % n !== 0) {
      return { ok: false, blocks: _clone(blocks), error: { code: "PRESET_CANNOT_FIT" } };
    }
    var rSpan = rows / n;
    var cSpan = columns;
    for (var i = 0; i < n; i++) {
      var blk = cloned[i];
      if (!reg.canAllocate(blk.kind, blk.variant, cSpan, rSpan)) {
        return { ok: false, blocks: _clone(blocks), error: { code: "PRESET_CANNOT_FIT" } };
      }
      blk.layout = { col: 0, row: i * rSpan, colSpan: cSpan, rowSpan: rSpan };
      blk.colSpan = cSpan;
      blk.rowSpan = rSpan;
    }
    return { ok: true, blocks: cloned, error: null };
  }

  if (preset === "equal-cols") {
    if (columns % n !== 0) {
      return { ok: false, blocks: _clone(blocks), error: { code: "PRESET_CANNOT_FIT" } };
    }
    var cSpan = columns / n;
    var rSpan = rows;
    for (var i = 0; i < n; i++) {
      var blk = cloned[i];
      if (!reg.canAllocate(blk.kind, blk.variant, cSpan, rSpan)) {
        return { ok: false, blocks: _clone(blocks), error: { code: "PRESET_CANNOT_FIT" } };
      }
      blk.layout = { col: i * cSpan, row: 0, colSpan: cSpan, rowSpan: rSpan };
      blk.colSpan = cSpan;
      blk.rowSpan = rSpan;
    }
    return { ok: true, blocks: cloned, error: null };
  }

  if (preset === "balanced-grid") {
    var bestGridCols = -1;
    var bestGridRows = -1;
    var bestDiff = Infinity;
    for (var gr = 1; gr <= rows; gr++) {
      if (rows % gr === 0) {
        var gc = n / gr;
        if (Math.floor(gc) === gc && columns % gc === 0) {
          var diff = Math.abs(gc - gr);
          if (diff < bestDiff) {
            bestDiff = diff;
            bestGridCols = gc;
            bestGridRows = gr;
          }
        }
      }
    }

    if (bestGridCols === -1 || bestGridRows === -1) {
      return { ok: false, blocks: _clone(blocks), error: { code: "PRESET_CANNOT_FIT" } };
    }

    var cellCSpan = columns / bestGridCols;
    var cellRSpan = rows / bestGridRows;

    for (var i = 0; i < n; i++) {
      var blk = cloned[i];
      if (!reg.canAllocate(blk.kind, blk.variant, cellCSpan, cellRSpan)) {
        return { ok: false, blocks: _clone(blocks), error: { code: "PRESET_CANNOT_FIT" } };
      }
      var cCol = (i % bestGridCols) * cellCSpan;
      var cRow = Math.floor(i / bestGridCols) * cellRSpan;
      blk.layout = { col: cCol, row: cRow, colSpan: cellCSpan, rowSpan: cellRSpan };
      blk.colSpan = cellCSpan;
      blk.rowSpan = cellRSpan;
    }
    return { ok: true, blocks: cloned, error: null };
  }

  return { ok: false, blocks: _clone(blocks), error: { code: "PRESET_CANNOT_FIT" } };
}

function layoutBlocks(container, metrics) {
  if (!container || typeof container !== "object" || Array.isArray(container)) {
    return { fits: false, placements: [], errors: [{ code: "INVALID_CONTAINER_DEFINITION" }] };
  }
  if (!metrics || typeof metrics !== "object" || metrics.valid !== true) {
    return { fits: false, placements: [], errors: [{ code: "INVALID_METRICS" }] };
  }

  var blocks = Array.isArray(container.blocks) ? container.blocks : [];
  if (blocks.length === 0) {
    return { fits: true, placements: [], errors: [] };
  }

  var gap = (typeof metrics.gap === "number" && isFinite(metrics.gap) && metrics.gap >= 0) ? metrics.gap : 0;
  var layoutMode = (typeof container.layoutMode === "string" && container.layoutMode === "manual") ? "manual" : "auto";
  var placements = [];

  if (layoutMode === "manual") {
    var manVal = validateManualPlacements(blocks, metrics.columns, metrics.rows);
    if (!manVal.valid) {
      return { fits: false, placements: [], errors: [manVal.error] };
    }

    for (var i = 0; i < manVal.placements.length; i++) {
      var mp = manVal.placements[i];
      var blk = blocks[mp.index];
      var pxW = mp.colSpan * metrics.cellWidth + (mp.colSpan - 1) * gap;
      var pxH = mp.rowSpan * metrics.cellHeight + (mp.rowSpan - 1) * gap;
      var pres = resolvePresentation(blk, pxW, pxH);
      if (!pres.ok) {
        return { fits: false, placements: [], errors: [pres.error] };
      }
      placements.push({
        id: mp.id,
        index: mp.index,
        gridCol: mp.gridCol,
        gridRow: mp.gridRow,
        colSpan: mp.colSpan,
        rowSpan: mp.rowSpan,
        x: mp.gridCol * (metrics.cellWidth + gap),
        y: mp.gridRow * (metrics.cellHeight + gap),
        width: pxW,
        height: pxH,
        resolvedPresentation: pres.presentation
      });
    }

    return { fits: true, placements: placements, errors: [] };
  }

  // Auto mode
  // Sole block expands to fill full container content area
  if (blocks.length === 1) {
    var single = blocks[0];
    var fullW = metrics.columns * metrics.cellWidth + (metrics.columns - 1) * gap;
    var fullH = metrics.rows * metrics.cellHeight + (metrics.rows - 1) * gap;
    var pres = resolvePresentation(single, fullW, fullH);
    if (!pres.ok) {
      return { fits: false, placements: [], errors: [pres.error] };
    }
    return {
      fits: true,
      placements: [{
        id: single.id,
        index: 0,
        gridCol: 0,
        gridRow: 0,
        colSpan: metrics.columns,
        rowSpan: metrics.rows,
        x: 0,
        y: 0,
        width: fullW,
        height: fullH,
        resolvedPresentation: pres.presentation
      }],
      errors: []
    };
  }

  var balancedPlacements = _balancedAutoPlacements(blocks, metrics);
  if (balancedPlacements) {
    return { fits: true, placements: balancedPlacements, errors: [] };
  }

  var packResult = tryPackBlocks(blocks, metrics.columns, metrics.rows);
  if (!packResult || !packResult.fits) {
    return {
      fits: false,
      placements: (packResult && Array.isArray(packResult.placements)) ? packResult.placements : [],
      errors: (packResult && Array.isArray(packResult.errors)) ? packResult.errors : [{ code: "CONTAINER_NO_SPACE" }]
    };
  }

  var blockMap = Object.create(null);
  for (var b = 0; b < blocks.length; b++) {
    if (blocks[b] && typeof blocks[b].id === "string") {
      blockMap[blocks[b].id.trim()] = blocks[b];
    }
  }

  for (var i = 0; i < packResult.placements.length; i++) {
    var p = packResult.placements[i];
    var block = blockMap[p.id];
    var pxW = p.colSpan * metrics.cellWidth + (p.colSpan - 1) * gap;
    var pxH = p.rowSpan * metrics.cellHeight + (p.rowSpan - 1) * gap;
    var pres = resolvePresentation(block, pxW, pxH);
    if (!pres.ok) {
      return { fits: false, placements: [], errors: [pres.error] };
    }

    placements.push({
      id: p.id,
      index: p.index,
      gridCol: p.gridCol,
      gridRow: p.gridRow,
      colSpan: p.colSpan,
      rowSpan: p.rowSpan,
      x: p.gridCol * (metrics.cellWidth + gap),
      y: p.gridRow * (metrics.cellHeight + gap),
      width: pxW,
      height: pxH,
      resolvedPresentation: pres.presentation
    });
  }

  return { fits: true, placements: placements, errors: [] };
}

var InternalLayoutEngine = {
  computeInternalMetrics: computeInternalMetrics,
  tryPackBlocks: tryPackBlocks,
  validateBlockPixelGeometry: validateBlockPixelGeometry,
  findNearestBlockSlot: findNearestBlockSlot,
  reorderBlocks: reorderBlocks,
  canReplaceVariant: canReplaceVariant,
  validateManualPlacements: validateManualPlacements,
  materializeManualPlacements: materializeManualPlacements,
  resolvePresentation: resolvePresentation,
  applyPreset: applyPreset,
  layoutBlocks: layoutBlocks
};

if (typeof globalThis !== "undefined") {
  globalThis.InternalLayoutEngine = InternalLayoutEngine;
}
