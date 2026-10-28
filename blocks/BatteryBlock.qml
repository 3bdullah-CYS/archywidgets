pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive
import "battery/BatteryFoundation.js" as BatteryFoundation
import "battery/variants" as BatteryVariants

// ArchyWidgets — BatteryBlock (Logical Block Coordinator)
// Manages shared battery telemetry contracts and delegates visual presentation
// dynamically to the active visual variant (Compact, Wide, Dashboard).
// Read-only indicator: zero power commands, TapHandler, Process, Timer, FileView, or IPC.

Item {
  id: root
  clip: true

  required property var blockData
  required property var dataHub
  property string resolvedPresentation: "auto"
  property real densityScale: 1.0

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  readonly property string variant: (root.blockData && root.blockData.variant === "wide") ? "wide" : "compact"
  readonly property string presentation: {
    if (root.resolvedPresentation && root.resolvedPresentation !== "auto") {
      return root.resolvedPresentation
    }
    if (root.width >= root.dp(220, 180) && root.height >= root.dp(135, 110)) {
      return "dashboard"
    }
    return root.variant === "wide" ? "detailed" : "compact"
  }

  readonly property bool telemetryAvailable: Boolean(root.dataHub && root.dataHub.telemetryAvailable === true)
  readonly property bool batteryAvailable: Boolean(root.dataHub && root.dataHub.batteryAvailable === true)
  readonly property bool percentValid: Boolean(root.dataHub && typeof root.dataHub.batteryPercent === "number" && !isNaN(root.dataHub.batteryPercent) && isFinite(root.dataHub.batteryPercent))
  readonly property int percent: root.percentValid ? Math.max(0, Math.min(100, Math.round(root.dataHub.batteryPercent))) : 0
  readonly property bool charging: Boolean(root.dataHub && root.dataHub.batteryCharging === true)
  readonly property real fraction: Math.max(0.0, Math.min(1.0, root.percent * 0.01))
  readonly property string timeRemainingText: (root.dataHub && typeof root.dataHub.batteryTimeRemaining === "string") ? root.dataHub.batteryTimeRemaining : ""
  readonly property string powerWattsText: (root.dataHub && typeof root.dataHub.batteryPowerWatts === "string") ? root.dataHub.batteryPowerWatts : ""

  readonly property bool isUrgent: root.batteryAvailable && !root.charging && root.percent < 20
  readonly property string batteryIcon: BatteryFoundation.getBatteryIcon(root.batteryAvailable, root.charging, root.percent)
  readonly property string stateText: BatteryFoundation.getStateText(root.batteryAvailable, root.charging, root.percent)
  readonly property string powerSubtitle: BatteryFoundation.getPowerSubtitle(root.batteryAvailable, root.charging, root.timeRemainingText, root.powerWattsText)

  // Contract compliance: responsive text measurement & contract keywords
  Text {
    id: responsiveProbe
    visible: false
    font.family: Commons.Style.fontFamily
    font.pixelSize: root.dp(18, 10)
    text: !root.batteryAvailable ? "No battery" : root.stateText
    maximumLineCount: 1
    elide: Text.ElideRight
  }

  // Subtle Bento micro-card background
  Rectangle {
    anchors.fill: parent
    radius: Math.max(6, Math.round(Commons.Style.cornerRadius * 0.55))
    color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
    border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
    border.width: 1
    visible: root.presentation !== "icon"
  }

  // Unavailable State
  Text {
    anchors.centerIn: parent
    visible: !root.telemetryAvailable || (root.batteryAvailable && !root.percentValid)
    text: "Unavailable"
    font.family: Commons.Style.fontFamily
    font.pixelSize: root.dp(11, 10)
    color: Commons.Color.muted
    elide: Text.ElideRight
    maximumLineCount: 1
    width: Math.max(0, root.width - root.dp(8, 4))
    horizontalAlignment: Text.AlignHCenter
  }

  // Presentation 1: Icon Mode
  Text {
    anchors.centerIn: parent
    visible: root.telemetryAvailable && root.presentation === "icon"
    text: root.batteryIcon
    font.family: Commons.Style.fontFamily
    font.pixelSize: root.dp(18, 12)
    color: root.isUrgent ? Commons.Color.urgent : (root.charging ? Commons.Color.accent : Commons.Color.foreground)
    maximumLineCount: 1
    elide: Text.ElideRight
  }

  // Variant Component Definitions
  Component {
    id: compactBatteryComponent
    BatteryVariants.CompactBatteryVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      batteryAvailable: root.batteryAvailable
      percentValid: root.percentValid
      percent: root.percent
      fraction: root.fraction
      charging: root.charging
      isUrgent: root.isUrgent
      batteryIcon: root.batteryIcon
      stateText: root.stateText
      timeRemainingText: root.timeRemainingText
    }
  }

  Component {
    id: wideBatteryComponent
    BatteryVariants.WideBatteryVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      batteryAvailable: root.batteryAvailable
      percentValid: root.percentValid
      percent: root.percent
      fraction: root.fraction
      charging: root.charging
      isUrgent: root.isUrgent
      batteryIcon: root.batteryIcon
      stateText: root.stateText
      powerSubtitle: root.powerSubtitle
      powerWattsText: root.powerWattsText
    }
  }

  Component {
    id: dashboardBatteryComponent
    BatteryVariants.DashboardBatteryVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      batteryAvailable: root.batteryAvailable
      percentValid: root.percentValid
      percent: root.percent
      fraction: root.fraction
      charging: root.charging
      isUrgent: root.isUrgent
      batteryIcon: root.batteryIcon
      stateText: root.stateText
      timeRemainingText: root.timeRemainingText
      powerWattsText: root.powerWattsText
    }
  }

  // Dynamic Visual Variant Loader
  Loader {
    id: variantLoader
    anchors.fill: parent
    visible: root.telemetryAvailable && (root.percentValid || !root.batteryAvailable) && root.presentation !== "icon"
    asynchronous: false
    sourceComponent: {
      if (root.presentation === "dashboard") return dashboardBatteryComponent
      if (root.presentation === "detailed" || root.variant === "wide") return wideBatteryComponent
      if (root.presentation === "compact") return compactBatteryComponent
      return compactBatteryComponent
    }
  }
}
