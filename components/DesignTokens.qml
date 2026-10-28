pragma Singleton
import QtQuick
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive

// OmaDesk — Unified Design System Tokens
// Bridges host Omarchy theme (Commons.Color and Commons.Style) to OmaDesk widgets,
// containers, and toolbars, ensuring unified typography, spacing, radii, and semantic alphas.

QtObject {
  id: root

  // ---------------------------------------------------------- Typography
  // Inherit the active Omarchy system font alias ("monospace" -> JetBrainsMono Nerd Font)
  readonly property string fontFamily: (Commons.Style && Commons.Style.fontFamily) ? Commons.Style.fontFamily : "monospace"
  readonly property string resolvedFontFamily: (Commons.Style && Commons.Style.resolvedFontFamily) ? Commons.Style.resolvedFontFamily : "monospace"

  // Dedicated fallback for Arabic and complex scripts to prevent distortion or tofu
  readonly property string arabicFallback: "Noto Sans Arabic, Noto Sans Arabic UI, sans-serif"

  // Standard type scale (pixel sizes)
  readonly property int fontCaption: 10
  readonly property int fontBodySmall: 11
  readonly property int fontBody: 12
  readonly property int fontSubtitle: 13
  readonly property int fontTitle: 14
  readonly property int fontHeading: 16
  readonly property int fontStatValue: 18
  readonly property int fontDisplay: 24
  readonly property int fontDisplayLarge: 32

  // ---------------------------------------------------------- Spacing Scale
  readonly property int spaceHairline: 1
  readonly property int spaceXs: 3
  readonly property int spaceSm: 6
  readonly property int spaceMd: 8
  readonly property int spaceLg: 12
  readonly property int spaceXl: 16
  readonly property int spaceXxl: 24

  // Outer layout gaps & margins
  readonly property int defaultColGap: 12
  readonly property int defaultRowGap: 12
  readonly property int containerPadding: 8
  readonly property int internalBlockGap: 6

  // ---------------------------------------------------------- Corner Radii
  // Tracks Hyprland / Omarchy rounding with proportional scaling for smaller elements
  readonly property int cornerRadius: (Commons.Style && typeof Commons.Style.cornerRadius === "number") ? Commons.Style.cornerRadius : 8
  readonly property int buttonRadius: Math.max(4, Math.round(root.cornerRadius * 0.65))
  readonly property int badgeRadius: Math.max(3, Math.round(root.cornerRadius * 0.40))
  readonly property int cardRadius: root.cornerRadius

  // ---------------------------------------------------------- Border Widths
  readonly property int normalBorderWidth: (Commons.Style && typeof Commons.Style.normalBorderWidth === "number") ? Commons.Style.normalBorderWidth : 1
  readonly property int activeBorderWidth: Math.max(1, root.normalBorderWidth)

  // ---------------------------------------------------------- Semantic Surface Alphas
  readonly property real cardBackgroundAlpha: 0.45
  readonly property real subtleFillAlpha: 0.06
  readonly property real hoverFillAlpha: 0.16
  readonly property real activeFillAlpha: 0.24
  readonly property real borderSubtleAlpha: 0.14
  readonly property real borderMediumAlpha: 0.22
  readonly property real borderAccentAlpha: 0.40

  // ---------------------------------------------------------- Colors
  readonly property color foreground: (Commons.Color && Commons.Color.foreground) ? Commons.Color.foreground : "#cacccc"
  readonly property color background: (Commons.Color && Commons.Color.background) ? Commons.Color.background : "#101315"
  readonly property color accent: (Commons.Color && Commons.Color.accent) ? Commons.Color.accent : "#cacccc"
  readonly property color urgent: (Commons.Color && Commons.Color.urgent) ? Commons.Color.urgent : "#a55555"
  readonly property color muted: (Commons.Color && Commons.Color.muted) ? Commons.Color.muted : "#707880"

  // ---------------------------------------------------------- Density Sizing Helper
  function dp(basePx, densityScale, minimumPx) {
    var scale = (typeof densityScale === "number" && isFinite(densityScale)) ? densityScale : 1.0
    return Responsive.scalePx(basePx, scale, minimumPx)
  }
}
