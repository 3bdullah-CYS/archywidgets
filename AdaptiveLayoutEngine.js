/**
 * ArchyWidgets Adaptive Layout Engine
 * Intelligent 2D Bento-Grid Packing, Container-Aware Sizing, and Dynamic Reflow.
 * Phase 3: Compact Desktop Units, Centered Grid, and Strict Physical Bounds.
 */
.pragma library

/**
 * Validates a metrics object strictly and comprehensively.
 * Used by tryPackWidgets and findNearestGridSlot. Does not mutate metrics.
 */
function _validatePackingMetrics(metrics) {
  if (!metrics || typeof metrics !== "object" || Array.isArray(metrics)) {
    return false;
  }
  if (metrics.valid !== true) {
    return false;
  }

  // columns: finite positive integer
  if (typeof metrics.columns !== "number" || !isFinite(metrics.columns) || metrics.columns <= 0 || Math.floor(metrics.columns) !== metrics.columns) {
    return false;
  }

  // maxRows: finite non-negative integer
  if (typeof metrics.maxRows !== "number" || !isFinite(metrics.maxRows) || metrics.maxRows < 0 || Math.floor(metrics.maxRows) !== metrics.maxRows) {
    return false;
  }

  // cellWidth: finite and >= the product minimum outer-cell width
  if (typeof metrics.cellWidth !== "number" || !isFinite(metrics.cellWidth) || metrics.cellWidth < 144) {
    return false;
  }

  // cellHeight: finite and >= the product minimum outer-cell height
  if (typeof metrics.cellHeight !== "number" || !isFinite(metrics.cellHeight) || metrics.cellHeight < 96) {
    return false;
  }

  // colGap: finite and >= 0
  if (typeof metrics.colGap !== "number" || !isFinite(metrics.colGap) || metrics.colGap < 0) {
    return false;
  }

  // rowGap: finite and >= 0
  if (typeof metrics.rowGap !== "number" || !isFinite(metrics.rowGap) || metrics.rowGap < 0) {
    return false;
  }

  // startX, startY: finite
  if (typeof metrics.startX !== "number" || !isFinite(metrics.startX)) {
    return false;
  }
  if (typeof metrics.startY !== "number" || !isFinite(metrics.startY)) {
    return false;
  }

  // safeLeft, safeTop, safeRight, safeBottom: finite
  if (typeof metrics.safeLeft !== "number" || !isFinite(metrics.safeLeft) ||
      typeof metrics.safeTop !== "number" || !isFinite(metrics.safeTop) ||
      typeof metrics.safeRight !== "number" || !isFinite(metrics.safeRight) ||
      typeof metrics.safeBottom !== "number" || !isFinite(metrics.safeBottom)) {
    return false;
  }

  // safeRight >= safeLeft, safeBottom >= safeTop
  if (metrics.safeRight < metrics.safeLeft || metrics.safeBottom < metrics.safeTop) {
    return false;
  }

  var EPSILON = 1e-6;

  var gridWidth = metrics.columns * metrics.cellWidth + (metrics.columns - 1) * metrics.colGap;
  var gridHeight = metrics.maxRows > 0
    ? metrics.maxRows * metrics.cellHeight + (metrics.maxRows - 1) * metrics.rowGap
    : 0;

  if (gridWidth <= 0) {
    return false;
  }

  if (metrics.startX < metrics.safeLeft - EPSILON ||
      metrics.startX + gridWidth > metrics.safeRight + EPSILON ||
      metrics.startY < metrics.safeTop - EPSILON ||
      metrics.startY + gridHeight > metrics.safeBottom + EPSILON) {
    return false;
  }

  // Optional fields consistency checks
  if (metrics.safeWidth !== undefined) {
    if (typeof metrics.safeWidth !== "number" || !isFinite(metrics.safeWidth) || metrics.safeWidth < 0 ||
        Math.abs(metrics.safeWidth - (metrics.safeRight - metrics.safeLeft)) > EPSILON) {
      return false;
    }
  }

  if (metrics.safeHeight !== undefined) {
    if (typeof metrics.safeHeight !== "number" || !isFinite(metrics.safeHeight) || metrics.safeHeight < 0 ||
        Math.abs(metrics.safeHeight - (metrics.safeBottom - metrics.safeTop)) > EPSILON) {
      return false;
    }
  }

  if (metrics.gridWidth !== undefined) {
    if (typeof metrics.gridWidth !== "number" || !isFinite(metrics.gridWidth) || metrics.gridWidth < 0 ||
        Math.abs(metrics.gridWidth - gridWidth) > EPSILON) {
      return false;
    }
  }

  if (metrics.gridHeight !== undefined) {
    if (typeof metrics.gridHeight !== "number" || !isFinite(metrics.gridHeight) || metrics.gridHeight < 0 ||
        Math.abs(metrics.gridHeight - gridHeight) > EPSILON) {
      return false;
    }
  }

  return true;
}

/**
 * Calculates responsive columns, max rows, cell dimensions, and safe rectangle boundaries.
 */
function computeGridMetrics(containerWidth, containerHeight, startX, startY, gaps, maxCols, customBounds) {
  if (typeof containerWidth !== "number" || !isFinite(containerWidth) || containerWidth <= 0 ||
      typeof containerHeight !== "number" || !isFinite(containerHeight) || containerHeight <= 0) {
    return {
      valid: false,
      columns: 0,
      maxRows: 0,
      cellWidth: 0,
      cellHeight: 0,
      safeLeft: 0,
      safeTop: 0,
      safeRight: 0,
      safeBottom: 0,
      safeWidth: 0,
      safeHeight: 0,
      error: { code: "INVALID_METRICS" }
    };
  }

  var colGap = 12;
  var rowGap = 12;

  if (gaps !== undefined && gaps !== null) {
    if (typeof gaps !== "object" || Array.isArray(gaps)) {
      return {
        valid: false,
        columns: 0,
        maxRows: 0,
        cellWidth: 0,
        cellHeight: 0,
        safeLeft: 0,
        safeTop: 0,
        safeRight: 0,
        safeBottom: 0,
        safeWidth: 0,
        safeHeight: 0,
        error: { code: "INVALID_METRICS" }
      };
    }
    if (gaps.colGap !== undefined) {
      if (typeof gaps.colGap !== "number" || !isFinite(gaps.colGap) || gaps.colGap < 0) {
        return {
          valid: false,
          columns: 0,
          maxRows: 0,
          cellWidth: 0,
          cellHeight: 0,
          safeLeft: 0,
          safeTop: 0,
          safeRight: 0,
          safeBottom: 0,
          safeWidth: 0,
          safeHeight: 0,
          error: { code: "INVALID_METRICS" }
        };
      }
      colGap = gaps.colGap;
    }
    if (gaps.rowGap !== undefined) {
      if (typeof gaps.rowGap !== "number" || !isFinite(gaps.rowGap) || gaps.rowGap < 0) {
        return {
          valid: false,
          columns: 0,
          maxRows: 0,
          cellWidth: 0,
          cellHeight: 0,
          safeLeft: 0,
          safeTop: 0,
          safeRight: 0,
          safeBottom: 0,
          safeWidth: 0,
          safeHeight: 0,
          error: { code: "INVALID_METRICS" }
        };
      }
      rowGap = gaps.rowGap;
    }
  }

  // Strict validation of maxCols: null/undefined -> 6; if supplied, must be finite positive integer
  var effectiveMaxColumns = 6;
  if (maxCols !== undefined && maxCols !== null) {
    if (typeof maxCols !== "number" || !isFinite(maxCols) || maxCols <= 0 || Math.floor(maxCols) !== maxCols) {
      return {
        valid: false,
        columns: 0,
        maxRows: 0,
        cellWidth: 0,
        cellHeight: 0,
        safeLeft: 0,
        safeTop: 0,
        safeRight: 0,
        safeBottom: 0,
        safeWidth: 0,
        safeHeight: 0,
        error: { code: "INVALID_METRICS" }
      };
    }
    effectiveMaxColumns = Math.min(6, maxCols);
  }

  var safeLeft = (typeof startX === "number" && isFinite(startX)) ? startX : 30;
  var safeTop = (typeof startY === "number" && isFinite(startY)) ? startY : 132;
  var safeRight = containerWidth - safeLeft;
  var safeBottom = containerHeight;

  if (customBounds !== undefined && customBounds !== null) {
    if (typeof customBounds !== "object" || Array.isArray(customBounds)) {
      return {
        valid: false,
        columns: 0,
        maxRows: 0,
        cellWidth: 0,
        cellHeight: 0,
        safeLeft: 0,
        safeTop: 0,
        safeRight: 0,
        safeBottom: 0,
        safeWidth: 0,
        safeHeight: 0,
        error: { code: "INVALID_METRICS" }
      };
    }
    if (customBounds.safeLeft !== undefined) {
      if (typeof customBounds.safeLeft !== "number" || !isFinite(customBounds.safeLeft)) {
        return { valid: false, columns: 0, maxRows: 0, cellWidth: 0, cellHeight: 0, safeLeft: 0, safeTop: 0, safeRight: 0, safeBottom: 0, safeWidth: 0, safeHeight: 0, error: { code: "INVALID_METRICS" } };
      }
      safeLeft = customBounds.safeLeft;
    }
    if (customBounds.safeTop !== undefined) {
      if (typeof customBounds.safeTop !== "number" || !isFinite(customBounds.safeTop)) {
        return { valid: false, columns: 0, maxRows: 0, cellWidth: 0, cellHeight: 0, safeLeft: 0, safeTop: 0, safeRight: 0, safeBottom: 0, safeWidth: 0, safeHeight: 0, error: { code: "INVALID_METRICS" } };
      }
      safeTop = customBounds.safeTop;
    }
    if (customBounds.safeRight !== undefined) {
      if (typeof customBounds.safeRight !== "number" || !isFinite(customBounds.safeRight)) {
        return { valid: false, columns: 0, maxRows: 0, cellWidth: 0, cellHeight: 0, safeLeft: 0, safeTop: 0, safeRight: 0, safeBottom: 0, safeWidth: 0, safeHeight: 0, error: { code: "INVALID_METRICS" } };
      }
      safeRight = customBounds.safeRight;
    }
    if (customBounds.safeBottom !== undefined) {
      if (typeof customBounds.safeBottom !== "number" || !isFinite(customBounds.safeBottom)) {
        return { valid: false, columns: 0, maxRows: 0, cellWidth: 0, cellHeight: 0, safeLeft: 0, safeTop: 0, safeRight: 0, safeBottom: 0, safeWidth: 0, safeHeight: 0, error: { code: "INVALID_METRICS" } };
      }
      safeBottom = customBounds.safeBottom;
    }
  }

  // Reject empty or inverted safe bounds before clamping
  if (safeRight <= safeLeft || safeBottom <= safeTop) {
    return {
      valid: false,
      columns: 0,
      maxRows: 0,
      cellWidth: 0,
      cellHeight: 0,
      safeLeft: safeLeft,
      safeTop: safeTop,
      safeRight: safeRight,
      safeBottom: safeBottom,
      safeWidth: 0,
      safeHeight: 0,
      error: { code: "NO_USABLE_AREA" }
    };
  }

  // Clamp resolved bounds to the physical canvas
  safeLeft = Math.max(0, Math.min(containerWidth, safeLeft));
  safeRight = Math.max(safeLeft, Math.min(containerWidth, safeRight));
  safeTop = Math.max(0, Math.min(containerHeight, safeTop));
  safeBottom = Math.max(safeTop, Math.min(containerHeight, safeBottom));

  var safeWidth = Math.max(0, safeRight - safeLeft);
  var safeHeight = Math.max(0, safeBottom - safeTop);

  if (safeWidth <= 0 || safeHeight <= 0) {
    return {
      valid: false,
      columns: 0,
      maxRows: 0,
      cellWidth: 0,
      cellHeight: 0,
      safeLeft: safeLeft,
      safeTop: safeTop,
      safeRight: safeRight,
      safeBottom: safeBottom,
      safeWidth: safeWidth,
      safeHeight: safeHeight,
      error: { code: "NO_USABLE_AREA" }
    };
  }

  var minCellWidth = 144;
  var minCellHeight = 96;
  var preferredCellWidth = 160;
  var preferredCellHeight = 104;

  if (safeWidth < minCellWidth || safeHeight < minCellHeight) {
    return {
      valid: false,
      columns: 0,
      maxRows: 0,
      cellWidth: 0,
      cellHeight: 0,
      safeLeft: safeLeft,
      safeTop: safeTop,
      safeRight: safeRight,
      safeBottom: safeBottom,
      safeWidth: safeWidth,
      safeHeight: safeHeight,
      gridWidth: 0,
      gridHeight: 0,
      errorCode: "NO_RENDERABLE_CELL",
      error: { code: "NO_RENDERABLE_CELL" }
    };
  }

  var fitColumns = Math.floor((safeWidth + colGap) / (minCellWidth + colGap));
  var cols = Math.min(effectiveMaxColumns, Math.max(1, fitColumns));
  var preferredGridWidth = cols * preferredCellWidth + (cols - 1) * colGap;
  var cellWidth = preferredGridWidth <= safeWidth
    ? preferredCellWidth
    : (safeWidth - (cols - 1) * colGap) / cols;

  var maxRows = Math.floor((safeHeight + rowGap) / (minCellHeight + rowGap));
  var preferredGridHeight = maxRows * preferredCellHeight + Math.max(0, maxRows - 1) * rowGap;
  var cellHeight = preferredGridHeight <= safeHeight
    ? preferredCellHeight
    : (safeHeight - Math.max(0, maxRows - 1) * rowGap) / maxRows;

  var gridWidth = cols * cellWidth + (cols - 1) * colGap;
  var gridStartX = safeLeft + (safeWidth - gridWidth) / 2;
  var gridHeight = maxRows > 0 ? (maxRows * cellHeight + (maxRows - 1) * rowGap) : 0;

  return {
    valid: true,
    columns: cols,
    maxRows: maxRows,
    cellWidth: cellWidth,
    cellHeight: cellHeight,
    colGap: colGap,
    rowGap: rowGap,
    startX: gridStartX,
    startY: safeTop,
    gridWidth: gridWidth,
    gridHeight: gridHeight,
    availWidth: safeWidth,
    availHeight: safeHeight,
    safeLeft: safeLeft,
    safeTop: safeTop,
    safeRight: safeRight,
    safeBottom: safeBottom,
    safeWidth: safeWidth,
    safeHeight: safeHeight
  };
}

/**
 * Pure 2D Grid Occupancy First-Fit Bounded Packing Algorithm.
 * Strictly guarantees that all placements lie within safeRect and maxRows.
 * Rejects placements that exceed bounds, returning fits: false and unplacedIds.
 */
function tryPackWidgets(widgets, metrics, options) {
  var layoutMode = "auto";
  if (options && typeof options.layoutMode === "string") {
    layoutMode = options.layoutMode;
  } else if (metrics && typeof metrics.layoutMode === "string") {
    layoutMode = metrics.layoutMode;
  }

  if (!Array.isArray(widgets)) {
    return {
      fits: false,
      placements: [],
      unplacedIds: [],
      errors: [{ code: "INVALID_WIDGET_LIST" }],
      columns: 0,
      maxRows: 0,
      rows: 0,
      cellWidth: 0,
      cellHeight: 0,
      usedCells: 0,
      totalCells: 0,
      totalHeight: 0
    };
  }

  if (!_validatePackingMetrics(metrics)) {
    return {
      fits: false,
      placements: [],
      unplacedIds: [],
      errors: [{ code: "INVALID_METRICS" }],
      columns: 0,
      maxRows: 0,
      rows: 0,
      cellWidth: 0,
      cellHeight: 0,
      usedCells: 0,
      totalCells: 0,
      totalHeight: 0
    };
  }

  var seenIds = Object.create(null);
  var activeList = [];

  for (var i = 0; i < widgets.length; i++) {
    var w = widgets[i];
    if (w && w.enabled === false) {
      continue;
    }

    if (!w || typeof w !== "object" || Array.isArray(w)) {
      return {
        fits: false,
        placements: [],
        unplacedIds: [],
        errors: [{ code: "INVALID_WIDGET_DEFINITION" }],
        columns: metrics.columns,
        maxRows: metrics.maxRows,
        rows: 0,
        cellWidth: metrics.cellWidth,
        cellHeight: metrics.cellHeight,
        usedCells: 0,
        totalCells: metrics.columns * metrics.maxRows,
        totalHeight: (typeof metrics.startY === "number") ? metrics.startY : 0
      };
    }

    if (typeof w.id !== "string" || !w.id.trim()) {
      return {
        fits: false,
        placements: [],
        unplacedIds: [],
        errors: [{ code: "INVALID_WIDGET_ID" }],
        columns: metrics.columns,
        maxRows: metrics.maxRows,
        rows: 0,
        cellWidth: metrics.cellWidth,
        cellHeight: metrics.cellHeight,
        usedCells: 0,
        totalCells: metrics.columns * metrics.maxRows,
        totalHeight: (typeof metrics.startY === "number") ? metrics.startY : 0
      };
    }

    var cid = w.id.trim();
    var idKey = "id:" + cid;
    if (seenIds[idKey]) {
      return {
        fits: false,
        placements: [],
        unplacedIds: [],
        errors: [{ code: "DUPLICATE_WIDGET_ID", widgetId: cid }],
        columns: metrics.columns,
        maxRows: metrics.maxRows,
        rows: 0,
        cellWidth: metrics.cellWidth,
        cellHeight: metrics.cellHeight,
        usedCells: 0,
        totalCells: metrics.columns * metrics.maxRows,
        totalHeight: (typeof metrics.startY === "number") ? metrics.startY : 0
      };
    }
    seenIds[idKey] = true;

    var cs = (w.colSpan === undefined) ? 1 : w.colSpan;
    var rs = (w.rowSpan === undefined) ? 1 : w.rowSpan;

    if (typeof cs !== "number" || !isFinite(cs) || cs <= 0 || Math.floor(cs) !== cs ||
        typeof rs !== "number" || !isFinite(rs) || rs <= 0 || Math.floor(rs) !== rs) {
      return {
        fits: false,
        placements: [],
        unplacedIds: [],
        errors: [{ code: "INVALID_WIDGET_SPAN", widgetId: cid }],
        columns: metrics.columns,
        maxRows: metrics.maxRows,
        rows: 0,
        cellWidth: metrics.cellWidth,
        cellHeight: metrics.cellHeight,
        usedCells: 0,
        totalCells: metrics.columns * metrics.maxRows,
        totalHeight: (typeof metrics.startY === "number") ? metrics.startY : 0
      };
    }

    activeList.push({
      origIndex: i,
      id: cid,
      colSpan: cs,
      rowSpan: rs,
      order: (typeof w.order === "number" && isFinite(w.order)) ? w.order : i,
      data: w
    });
  }

  if (activeList.length === 0) {
    return {
      fits: true,
      placements: [],
      unplacedIds: [],
      errors: [],
      columns: metrics.columns,
      maxRows: metrics.maxRows,
      rows: 0,
      cellWidth: metrics.cellWidth,
      cellHeight: metrics.cellHeight,
      usedCells: 0,
      totalCells: metrics.columns * metrics.maxRows,
      totalHeight: (typeof metrics.startY === "number") ? metrics.startY : 0
    };
  }

  activeList.sort(function(a, b) {
    if (a.order !== b.order) {
      return a.order - b.order;
    }
    return a.origIndex - b.origIndex;
  });

  var cols = metrics.columns;
  var maxRows = metrics.maxRows;
  var grid = [];
  for (var r = 0; r < maxRows; r++) {
    var rowArr = [];
    for (var c = 0; c < cols; c++) {
      rowArr.push(null);
    }
    grid.push(rowArr);
  }

  var placements = [];
  var unplacedIds = [];
  var errors = [];
  var usedCells = 0;
  var totalRows = 0;
  var fits = true;

  var colGap = (typeof metrics.colGap === "number") ? metrics.colGap : 14;
  var rowGap = (typeof metrics.rowGap === "number") ? metrics.rowGap : 12;
  var cellW = metrics.cellWidth;
  var cellH = metrics.cellHeight;
  var startX = metrics.startX;
  var startY = metrics.startY;
  var safeLeft = (typeof metrics.safeLeft === "number") ? metrics.safeLeft : startX;
  var safeTop = (typeof metrics.safeTop === "number") ? metrics.safeTop : startY;
  var safeRight = (typeof metrics.safeRight === "number") ? metrics.safeRight : (safeLeft + (metrics.safeWidth || metrics.availWidth || 0));
  var safeBottom = (typeof metrics.safeBottom === "number") ? metrics.safeBottom : (safeTop + (metrics.safeHeight || metrics.availHeight || 0));

  var EPSILON = 1e-6;

  // Filter out any items that exceed grid dimensions completely
  for (var k = 0; k < activeList.length; k++) {
    var item = activeList[k];
    item.placed = false;
    item.placedRow = -1;
    item.placedCol = -1;
    item.pixelX = 0;
    item.pixelY = 0;
    item.pixelW = 0;
    item.pixelH = 0;

    var spanW = item.colSpan;
    var spanH = item.rowSpan;

    if (spanW > cols || spanH > maxRows) {
      fits = false;
      unplacedIds.push(item.id);
      errors.push({ code: "DESKTOP_NO_SPACE", widgetId: item.id });
      item.oversized = true;
    }
  }

  // Pass 1: Explicit Coordinates Placement
  // For items that specify both col and row coordinates as non-negative integers.
  for (var k = 0; k < activeList.length; k++) {
    var item = activeList[k];
    if (item.oversized) {
      continue;
    }

    var targetCol = (item.data && typeof item.data.col === "number" && isFinite(item.data.col)) ? item.data.col : null;
    var targetRow = (item.data && typeof item.data.row === "number" && isFinite(item.data.row)) ? item.data.row : null;

    if (targetCol === null || targetRow === null || targetCol < 0 || targetRow < 0 ||
        Math.floor(targetCol) !== targetCol || Math.floor(targetRow) !== targetRow) {
      continue;
    }

    var spanW = item.colSpan;
    var spanH = item.rowSpan;

    // Check if within grid bounds
    if (targetCol + spanW > cols || targetRow + spanH > maxRows) {
      if (layoutMode === "manual") {
        fits = false;
        unplacedIds.push(item.id);
        errors.push({ code: "CONTAINER_OUT_OF_BOUNDS", widgetId: item.id });
      }
      continue; // Let Pass 2 find a first-fit slot if explicit position is out-of-bounds
    }

    // Check collision with already placed items
    var canPlace = true;
    for (var dr = 0; dr < spanH; dr++) {
      for (var dc = 0; dc < spanW; dc++) {
        if (grid[targetRow + dr][targetCol + dc] !== null) {
          canPlace = false;
          break;
        }
      }
      if (!canPlace) break;
    }

    if (!canPlace) {
      if (layoutMode === "manual") {
        fits = false;
        unplacedIds.push(item.id);
        errors.push({ code: "CONTAINER_COLLISION", widgetId: item.id });
      }
      continue; // Collision: defer to Pass 2
    }

    // Check safe bounds
    var pixelX = startX + targetCol * (cellW + colGap);
    var pixelY = startY + targetRow * (cellH + rowGap);
    var pixelW = spanW * cellW + (spanW - 1) * colGap;
    var pixelH = spanH * cellH + (spanH - 1) * rowGap;

    if (pixelX < safeLeft - EPSILON ||
        pixelY < safeTop - EPSILON ||
        (pixelX + pixelW) > safeRight + EPSILON ||
        (pixelY + pixelH) > safeBottom + EPSILON) {
      if (layoutMode === "manual") {
        fits = false;
        unplacedIds.push(item.id);
        errors.push({ code: "DESKTOP_NO_SPACE", widgetId: item.id });
      }
      continue; // Defer to Pass 2
    }

    // Commit placement
    for (var dr = 0; dr < spanH; dr++) {
      for (var dc = 0; dc < spanW; dc++) {
        grid[targetRow + dr][targetCol + dc] = item.id;
      }
    }
    usedCells += (spanW * spanH);
    item.placed = true;
    item.placedCol = targetCol;
    item.placedRow = targetRow;
    item.pixelX = pixelX;
    item.pixelY = pixelY;
    item.pixelW = pixelW;
    item.pixelH = pixelH;

    if (targetRow + spanH > totalRows) {
      totalRows = targetRow + spanH;
    }
  }

  // Pass 2: Floating First-Fit Placement
  // In "manual" layout mode, floating is DISABLED. Containers must not automatically move or occupy empty spaces.
  if (layoutMode !== "manual") {
    for (var k = 0; k < activeList.length; k++) {
      var item = activeList[k];
      if (item.placed || item.oversized) {
        continue;
      }

      var spanW = item.colSpan;
      var spanH = item.rowSpan;
      var placedRow = -1;
      var placedCol = -1;

      for (var row = 0; row <= (maxRows - spanH); row++) {
        for (var col = 0; col <= (cols - spanW); col++) {
          var canPlace = true;
          for (var dr = 0; dr < spanH; dr++) {
            for (var dc = 0; dc < spanW; dc++) {
              if (grid[row + dr][col + dc] !== null) {
                canPlace = false;
                break;
              }
            }
            if (!canPlace) break;
          }

          if (canPlace) {
            var pX = startX + col * (cellW + colGap);
            var pY = startY + row * (cellH + rowGap);
            var pW = spanW * cellW + (spanW - 1) * colGap;
            var pH = spanH * cellH + (spanH - 1) * rowGap;

            if (pX >= safeLeft - EPSILON &&
                pY >= safeTop - EPSILON &&
                (pX + pW) <= safeRight + EPSILON &&
                (pY + pH) <= safeBottom + EPSILON) {
              placedRow = row;
              placedCol = col;
              break;
            }
          }
        }
        if (placedRow !== -1) {
          break;
        }
      }

      if (placedRow === -1) {
        fits = false;
        unplacedIds.push(item.id);
        errors.push({ code: "DESKTOP_NO_SPACE", widgetId: item.id });
        continue;
      }

      var pixelX = startX + placedCol * (cellW + colGap);
      var pixelY = startY + placedRow * (cellH + rowGap);
      var pixelW = spanW * cellW + (spanW - 1) * colGap;
      var pixelH = spanH * cellH + (spanH - 1) * rowGap;

      for (var dr = 0; dr < spanH; dr++) {
        for (var dc = 0; dc < spanW; dc++) {
          grid[placedRow + dr][placedCol + dc] = item.id;
        }
      }
      usedCells += (spanW * spanH);
      item.placed = true;
      item.placedCol = placedCol;
      item.placedRow = placedRow;
      item.pixelX = pixelX;
      item.pixelY = pixelY;
      item.pixelW = pixelW;
      item.pixelH = pixelH;

      if (placedRow + spanH > totalRows) {
        totalRows = placedRow + spanH;
      }
    }
  } else {
    // In manual mode, any item that was not placed in Pass 1 is an unplaced error
    for (var k = 0; k < activeList.length; k++) {
      var item = activeList[k];
      if (!item.placed && !item.oversized) {
        fits = false;
        if (unplacedIds.indexOf(item.id) === -1) unplacedIds.push(item.id);
        if (errors.length === 0) errors.push({ code: "CONTAINER_UNPLACED", widgetId: item.id });
      }
    }
  }

  // Populate placements in activeList order
  for (var k = 0; k < activeList.length; k++) {
    var item = activeList[k];
    if (item.placed) {
      placements.push({
        id: item.id,
        index: item.origIndex,
        gridCol: item.placedCol,
        gridRow: item.placedRow,
        colSpan: item.colSpan,
        rowSpan: item.rowSpan,
        x: item.pixelX,
        y: item.pixelY,
        width: item.pixelW,
        height: item.pixelH
      });
    }
  }

  if (unplacedIds.length > 0 || errors.length > 0) {
    fits = false;
  }

  var totalCells = cols * maxRows;
  var totalH = totalRows > 0 ? (startY + totalRows * cellH + (totalRows - 1) * rowGap) : startY;

  return {
    fits: fits,
    placements: placements,
    unplacedIds: unplacedIds,
    errors: errors,
    columns: cols,
    maxRows: maxRows,
    rows: totalRows,
    cellWidth: cellW,
    cellHeight: cellH,
    usedCells: usedCells,
    totalCells: totalCells,
    totalHeight: totalH
  };
}

/**
 * Compatibility wrapper for packWidgets.
 */
function packWidgets(widgets, metrics, options) {
  return tryPackWidgets(widgets, metrics, options);
}

/**
 * Finds the closest grid cell (col, row) for a dragged point (targetX, targetY).
 */
function findNearestGridSlot(targetX, targetY, metrics) {
  if (typeof targetX !== "number" || !isFinite(targetX) ||
      typeof targetY !== "number" || !isFinite(targetY)) {
    return null;
  }

  if (!_validatePackingMetrics(metrics)) {
    return null;
  }

  if (metrics.maxRows === 0) {
    return null;
  }

  var colGap = (typeof metrics.colGap === "number") ? metrics.colGap : 14;
  var rowGap = (typeof metrics.rowGap === "number") ? metrics.rowGap : 12;
  var strideX = metrics.cellWidth + colGap;
  var strideY = metrics.cellHeight + rowGap;

  if (strideX <= 0 || strideY <= 0) {
    return null;
  }

  var startX = (typeof metrics.startX === "number") ? metrics.startX : 0;
  var startY = (typeof metrics.startY === "number") ? metrics.startY : 0;

  var col = Math.round((targetX - startX) / strideX);
  var row = Math.round((targetY - startY) / strideY);

  col = Math.max(0, Math.min(metrics.columns - 1, col));
  row = Math.max(0, Math.min(metrics.maxRows - 1, row));

  return { col: col, row: row };
}

var AdaptiveLayoutEngine = {
  computeGridMetrics: computeGridMetrics,
  tryPackWidgets: tryPackWidgets,
  packWidgets: packWidgets,
  findNearestGridSlot: findNearestGridSlot
};

if (typeof globalThis !== "undefined") {
  globalThis.AdaptiveLayoutEngine = AdaptiveLayoutEngine;
}
