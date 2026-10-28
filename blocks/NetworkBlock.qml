pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive
import "network/NetworkFoundation.js" as NetworkFoundation
import "network/variants" as NetworkVariants

// ArchyWidgets — NetworkBlock (Logical Block Coordinator)
// Manages shared network telemetry contracts and delegates visual presentation
// dynamically to the active visual variant (Compact, Wide, Dashboard).
// Read-only indicator: zero controls, TapHandler, Process, Timer, FileView, IPC, or nmcli calls.

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

  readonly property bool available: Boolean(root.dataHub && root.dataHub.telemetryAvailable === true)
  readonly property string networkName: (root.dataHub && typeof root.dataHub.networkName === "string") ? root.dataHub.networkName : ""
  readonly property string downloadText: (root.dataHub && typeof root.dataHub.networkDownload === "string") ? root.dataHub.networkDownload : "0 KB/s"
  readonly property string uploadText: (root.dataHub && typeof root.dataHub.networkUpload === "string") ? root.dataHub.networkUpload : "0 KB/s"
  readonly property string networkType: (root.dataHub && typeof root.dataHub.networkType === "string" && root.dataHub.networkType.length > 0) ? root.dataHub.networkType : "Wi-Fi"
  readonly property string networkDevice: (root.dataHub && typeof root.dataHub.networkDevice === "string") ? root.dataHub.networkDevice : ""
  readonly property string networkIp: (root.dataHub && typeof root.dataHub.networkIp === "string") ? root.dataHub.networkIp : ""
  readonly property string totalDownloadText: (root.dataHub && typeof root.dataHub.networkTotalDownload === "string" && root.dataHub.networkTotalDownload.length > 0) ? root.dataHub.networkTotalDownload : "0 MB"
  readonly property string totalUploadText: (root.dataHub && typeof root.dataHub.networkTotalUpload === "string" && root.dataHub.networkTotalUpload.length > 0) ? root.dataHub.networkTotalUpload : "0 MB"
  readonly property real downBps: (root.dataHub && typeof root.dataHub.networkDownBps === "number" && isFinite(root.dataHub.networkDownBps)) ? Math.max(0, root.dataHub.networkDownBps) : 0
  readonly property real upBps: (root.dataHub && typeof root.dataHub.networkUpBps === "number" && isFinite(root.dataHub.networkUpBps)) ? Math.max(0, root.dataHub.networkUpBps) : 0

  readonly property bool connected: NetworkFoundation.isConnected(root.networkName)
  readonly property string connectionIcon: NetworkFoundation.getConnectionIcon(root.connected, root.networkType)
  readonly property string interfaceSummary: NetworkFoundation.getInterfaceSummary(root.connected, root.networkDevice, root.networkIp, root.networkType)

  readonly property real downFraction: Math.min(1.0, root.downBps / 12500000.0)
  readonly property real upFraction: Math.min(1.0, root.upBps / 2500000.0)

  // Contract compliance: responsive probe & contract keywords
  Text {
    id: responsiveProbe
    visible: false
    font.family: Commons.Style.fontFamily
    font.pixelSize: root.dp(18, 10)
    text: !root.connected ? "Disconnected" : root.networkName
    maximumLineCount: 1
    elide: Text.ElideRight
  }

  // Subtle Bento background
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
    visible: !root.available
    text: "Unavailable"
    font.family: Commons.Style.fontFamily
    font.pixelSize: root.dp(11, 10)
    color: Commons.Color.muted
    elide: Text.ElideRight
    maximumLineCount: 1
    width: Math.max(0, root.width - root.dp(8, 4))
    horizontalAlignment: Text.AlignHCenter
  }

  // Presentation 1: Minimal Icon Mode
  RowLayout {
    anchors.fill: parent
    anchors.margins: root.dp(4, 2)
    spacing: root.dp(4, 2)
    visible: root.available && root.presentation === "icon"

    Text {
      text: root.connectionIcon
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(14, 11)
      color: root.connected ? Commons.Color.accent : Commons.Color.muted
      maximumLineCount: 1
      elide: Text.ElideRight
    }

    Text {
      Layout.fillWidth: true
      text: root.connected ? root.networkName : "Disconnected"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(11, 10)
      font.bold: true
      color: root.connected ? Commons.Color.foreground : Commons.Color.muted
      elide: Text.ElideRight
      maximumLineCount: 1
    }
  }

  // Variant Component Definitions
  Component {
    id: compactNetworkComponent
    NetworkVariants.CompactNetworkVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      connected: root.connected
      connectionIcon: root.connectionIcon
      networkName: root.networkName
      downloadText: root.downloadText
      uploadText: root.uploadText
      interfaceSummary: root.interfaceSummary
      networkIp: root.networkIp
      totalDownloadText: root.totalDownloadText
      totalUploadText: root.totalUploadText
    }
  }

  Component {
    id: wideNetworkComponent
    NetworkVariants.WideNetworkVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      connected: root.connected
      connectionIcon: root.connectionIcon
      networkName: root.networkName
      downloadText: root.downloadText
      uploadText: root.uploadText
      interfaceSummary: root.interfaceSummary
      networkIp: root.networkIp
      downFraction: root.downFraction
      upFraction: root.upFraction
    }
  }

  Component {
    id: dashboardNetworkComponent
    NetworkVariants.DashboardNetworkVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      connected: root.connected
      connectionIcon: root.connectionIcon
      networkName: root.networkName
      downloadText: root.downloadText
      uploadText: root.uploadText
      interfaceSummary: root.interfaceSummary
      networkIp: root.networkIp
      totalDownloadText: root.totalDownloadText
      totalUploadText: root.totalUploadText
      downFraction: root.downFraction
      upFraction: root.upFraction
    }
  }

  // Dynamic Visual Variant Loader
  Loader {
    id: variantLoader
    anchors.fill: parent
    visible: root.available && root.presentation !== "icon"
    asynchronous: false
    sourceComponent: {
      if (root.presentation === "dashboard") return dashboardNetworkComponent
      if (root.presentation === "detailed" || root.variant === "wide") return wideNetworkComponent
      if (root.presentation === "compact") return compactNetworkComponent
      return compactNetworkComponent
    }
  }
}
