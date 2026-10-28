/**
 * ArchyWidgets responsive density helpers.
 * Pure, deterministic, non-mutating, and safe for QML JavaScript imports.
 */
.pragma library

function _finitePositive(value) {
  return typeof value === "number" && isFinite(value) && value > 0;
}

function _clampScale(value) {
  if (typeof value !== "number" || !isFinite(value)) return 1.0;
  return Math.max(0.62, Math.min(1.0, value));
}

function computeDensity(width, height, referenceWidth, referenceHeight) {
  if (!_finitePositive(width) || !_finitePositive(height) ||
      !_finitePositive(referenceWidth) || !_finitePositive(referenceHeight)) {
    return { valid: false, rawScale: 0, scale: 1, mode: "normal" };
  }

  var rawScale = Math.min(width / referenceWidth, height / referenceHeight);
  var mode = rawScale >= 0.90 ? "normal" : (rawScale >= 0.62 ? "compact" : "too-small");
  return {
    valid: true,
    rawScale: rawScale,
    scale: _clampScale(rawScale),
    mode: mode
  };
}

function scalePx(basePx, scale, minimumPx) {
  if (!_finitePositive(basePx)) return 0;
  var base = Math.round(basePx);
  if (!_finitePositive(minimumPx)) return base;
  if (typeof scale !== "number" || !isFinite(scale)) return base;
  return Math.max(minimumPx, Math.round(basePx * _clampScale(scale)));
}

function classifySpan(colSpan, rowSpan) {
  if (typeof colSpan !== "number" || !isFinite(colSpan) || colSpan <= 0 || Math.floor(colSpan) !== colSpan ||
      typeof rowSpan !== "number" || !isFinite(rowSpan) || rowSpan <= 0 || Math.floor(rowSpan) !== rowSpan) {
    return {
      valid: false,
      columns: 0,
      rows: 0,
      mode: "invalid"
    };
  }

  var mode = "invalid";
  if (colSpan === 1 && rowSpan === 1) {
    mode = "compact";
  } else if (colSpan > 1 && rowSpan === 1) {
    mode = "wide";
  } else if (colSpan === 1 && rowSpan > 1) {
    mode = "tall";
  } else if (colSpan > 1 && rowSpan > 1) {
    mode = "large";
  }

  return {
    valid: true,
    columns: colSpan,
    rows: rowSpan,
    mode: mode
  };
}

var ResponsiveMetrics = {
  computeDensity: computeDensity,
  scalePx: scalePx,
  classifySpan: classifySpan
};

if (typeof globalThis !== "undefined") {
  globalThis.ResponsiveMetrics = ResponsiveMetrics;
}
