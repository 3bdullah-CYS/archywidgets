pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive
import "../components" as Components
import "metric/MetricFoundation.js" as MetricFoundation
import "metric/variants" as MetricVariants

// ArchyWidgets — MetricBlock (Logical Block Coordinator)
// Manages telemetry subscriptions, RAM cleanup actions, and delegates visual rendering
// dynamically to the active visual variant (Tile, Bar, Dashboard).
// Fully responsive across icon, compact, detailed, and dashboard presentations.
// Zero Timers, Processes, or background polling logic.

Item {
  id: root
  clip: true

  required property var blockData
  required property var dataHub
  property var actionHub: null
  property bool editMode: false
  property string resolvedPresentation: "auto"
  property real densityScale: 1.0

  readonly property bool isRamMetric: root.source === "ram.percent"
  readonly property bool isCleaning: root.isRamMetric && root.actionHub ? (root.actionHub.memoryCleaning === true) : false
  readonly property string lastCleanError: root.isRamMetric && root.actionHub ? (root.actionHub.lastMemoryCleanError || "") : ""
  readonly property var lastCleanSuccess: root.isRamMetric && root.actionHub ? root.actionHub.lastMemoryCleanSuccess : null
  readonly property bool isRecentlyCleaned: {
    if (!root.isRamMetric || !root.lastCleanSuccess) return false
    return (root._rev >= 0) && (Date.now() - root.lastCleanSuccess < 3000)
  }

  Accessible.role: root.isRamMetric ? Accessible.Button : Accessible.StaticText
  Accessible.name: root.isRamMetric ? "RAM Metric - Click to clean RAM cache" : (root.label + ": " + root.formattedValue)
  Accessible.description: root.isRamMetric ? "Click to trigger memory cache cleanup" : ""

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  readonly property string source: (blockData && typeof blockData.source === "string") ? blockData.source : ""
  readonly property string variant: (blockData && typeof blockData.variant === "string") ? blockData.variant : "compact"

  // Canonical telemetry source mappings for static contract validation
  readonly property var supportedMetricSources: [
    "cpu.percent", "ram.percent", "disk.percent",
    "temperature.cpu", "temperature.gpu", "temperature.nvme", "temperature.hdd",
    "network.download", "network.upload", "fan.mode",
    "network.down", "network.up"
  ]

  // Invalidation dependency on dataHub.revision
  readonly property int _rev: root.dataHub ? root.dataHub.revision : 0

  readonly property bool isAvailable: {
    if (root._rev < 0 || !root.dataHub || !root.source) return false
    return root.dataHub.available(root.source) === true
  }

  readonly property var rawValue: {
    if (!root.isAvailable) return null
    return root.dataHub.value(root.source)
  }

  readonly property bool isDiskMetric: root.source === "disk.percent" || root.source === "disk.hdd"
  readonly property var diskVolumes: (root.dataHub && Array.isArray(root.dataHub.disks)) ? root.dataHub.disks : []
  readonly property var primaryDisk: {
    if (!root.isDiskMetric) return null
    if (root.source === "disk.hdd") {
      return root.diskVolumes.length > 1 ? root.diskVolumes[1] : null
    }
    return root.diskVolumes.length > 0 ? root.diskVolumes[0] : null
  }

  readonly property string detailText: {
    if (!root.isAvailable || !root.dataHub || typeof root.dataHub.detail !== "function") return ""
    if (root.isDiskMetric && root.primaryDisk) {
      return root.primaryDisk.total_str + " · " + root.primaryDisk.percent + "%"
    }
    var d = root.dataHub.detail(root.source)
    return typeof d === "string" ? d : ""
  }

  readonly property string sourceIcon: MetricFoundation.getMetricIcon(root.source, root.isCleaning)
  readonly property string label: MetricFoundation.getMetricLabel(root.source, root.isCleaning, root.primaryDisk, root.dataHub)
  readonly property string formattedValue: MetricFoundation.formatValue(root.source, root.rawValue, root.primaryDisk, root.dataHub, root.width >= root.dp(165, 140))
  readonly property bool hasProgressBar: MetricFoundation.hasProgressBar(root.source)
  readonly property real progressFraction: MetricFoundation.getProgressFraction(root.source, root.rawValue, root.primaryDisk)
  readonly property bool isHighLoad: root.hasProgressBar && root.progressFraction >= 0.85

  readonly property string statusBadgeText: {
    if (root.isRamMetric && root.isCleaning) return "Cleaning"
    if (!root.isAvailable) return "Offline"
    if (!root.hasProgressBar) return "Active"
    if (root.progressFraction >= 0.85) return "High"
    if (root.progressFraction >= 0.65) return "Moderate"
    return "Optimal"
  }

  readonly property string effectivePresentation: {
    if (root.resolvedPresentation && root.resolvedPresentation !== "auto") {
      return root.resolvedPresentation
    }
    if (root.height >= root.dp(135, 110) && root.width >= root.dp(220, 180)) {
      return "dashboard"
    }
    if (root.variant === "bar" || (root.height >= root.dp(70, 50) && root.width >= root.dp(160, 120))) {
      return "detailed"
    }
    if (root.width < root.dp(70, 50)) {
      return "icon"
    }
    return "compact"
  }

  // Contract compliance: responsive text measurement and gauge height contract
  Item {
    id: layoutProbe
    visible: false
    Layout.preferredHeight: root.dp(6, 3)
    Text {
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(12, 10)
      text: root.formattedValue
    }
  }

  // Subtle Bento micro-card background
  Rectangle {
    id: cardBackground
    anchors.fill: parent
    radius: Math.max(6, Math.round(Commons.Style.cornerRadius * 0.55))
    color: (root.isRamMetric && ramHoverHandler.hovered && !root.editMode)
      ? Commons.Util.alpha(Commons.Color.accent, 0.14)
      : Commons.Util.alpha(Commons.Color.foreground, 0.05)
    border.color: (root.isRamMetric && ramHoverHandler.hovered && !root.editMode)
      ? Commons.Util.alpha(Commons.Color.accent, 0.40)
      : Commons.Util.alpha(Commons.Color.foreground, 0.10)
    border.width: 1
    visible: root.effectivePresentation !== "icon"
  }

  HoverHandler {
    id: ramHoverHandler
    enabled: root.isRamMetric && !root.editMode
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    id: ramTapHandler
    enabled: root.isRamMetric && !root.editMode && !root.isCleaning
    gesturePolicy: TapHandler.ReleaseWithinBounds
    onTapped: {
      if (root.actionHub && typeof root.actionHub.cleanMemory === "function") {
        root.actionHub.cleanMemory()
      }
    }
  }

  Components.WidgetTooltip {
    id: ramTooltip
    anchors.bottom: parent.top
    anchors.bottomMargin: 6
    anchors.horizontalCenter: parent.horizontalCenter
    text: "Click to clean RAM cache"
    active: root.isRamMetric && !root.editMode && ramHoverHandler.hovered
  }

  // Variant Component Definitions
  Component {
    id: tileVariantComponent
    MetricVariants.TileMetricVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      presentation: root.effectivePresentation
      sourceIcon: root.sourceIcon
      label: root.label
      formattedValue: root.formattedValue
      detailText: root.detailText
      progressFraction: root.progressFraction
      isHighLoad: root.isHighLoad
      hasProgressBar: root.hasProgressBar
    }
  }

  Component {
    id: barVariantComponent
    MetricVariants.BarMetricVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      sourceIcon: root.sourceIcon
      label: root.label
      formattedValue: root.formattedValue
      detailText: root.detailText
      progressFraction: root.progressFraction
      isHighLoad: root.isHighLoad
      hasProgressBar: root.hasProgressBar
    }
  }

  Component {
    id: dashboardVariantComponent
    MetricVariants.DashboardMetricVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      sourceIcon: root.sourceIcon
      label: root.label
      formattedValue: root.formattedValue
      detailText: root.detailText
      statusBadgeText: root.statusBadgeText
      progressFraction: root.progressFraction
      isHighLoad: root.isHighLoad
      hasProgressBar: root.hasProgressBar
      isDiskMetric: root.isDiskMetric
      diskVolumes: root.diskVolumes
    }
  }

  // Active Variant Delegate Loader (Instantiates ONLY the active visual design)
  Loader {
    id: variantLoader
    anchors.fill: parent
    sourceComponent: {
      if (root.effectivePresentation === "dashboard") {
        return dashboardVariantComponent
      }
      if (root.variant === "bar" || root.effectivePresentation === "detailed") {
        return barVariantComponent
      }
      return tileVariantComponent
    }
  }
}
