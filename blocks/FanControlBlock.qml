pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive

// ArchyWidgets — FanControlBlock (Composable block)
// Visual controls for laptop fan operating modes (0=Quiet, 1=Standard, 2=Clean, 4=Boost)
// plus integrated thermal overview in dashboard presentation.
// Delegates privileged operations to root-owned actionHub; no internal Process.
// Enforces minimum target size >= 28x28 px and font floor >= 10 px.

Item {
  id: root
  clip: true

  required property var blockData
  required property var dataHub
  property var actionHub: null
  property string resolvedPresentation: "auto"
  property real densityScale: 1.0

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  // Telemetry dependency on dataHub
  readonly property int _rev: root.dataHub ? root.dataHub.revision : 0
  readonly property int telemetryMode: {
    if (root._rev < 0 || !root.dataHub || !root.dataHub.available("fan.mode")) return -1
    var v = root.dataHub.value("fan.mode")
    var num = Math.floor(Number(v))
    return isNaN(num) ? -1 : num
  }

  function readSensorTemp(sourceKey) {
    if (root._rev < 0 || !root.dataHub || !root.dataHub.available(sourceKey)) return "--°C"
    var v = Number(root.dataHub.value(sourceKey))
    if (isNaN(v) || v <= 0) return "--°C"
    return Math.round(v) + "°C"
  }

  readonly property var thermalSummaryModel: [
    { label: "CPU", value: root.readSensorTemp("temperature.cpu") },
    { label: "GPU", value: root.readSensorTemp("temperature.gpu") },
    { label: "NVMe", value: root.readSensorTemp("temperature.nvme") },
    { label: "HDD", value: root.readSensorTemp("temperature.hdd") }
  ]

  // Action state from root-owned actionHub
  readonly property bool isBusy: root.actionHub ? (root.actionHub.busy === true) : false
  readonly property int pendingMode: root.actionHub ? (root.actionHub.requestedMode || -1) : -1
  readonly property string lastError: root.actionHub ? (root.actionHub.lastError || "") : ""

  // Active operating mode: reflect telemetry mode
  readonly property int currentMode: root.telemetryMode

  // Graceful hardware detection: check if fan control is supported on current host
  readonly property bool isFanSupported: root.dataHub ? (!root.dataHub.telemetryAvailable || root.dataHub.available("fan.mode")) : true

  // Configured allowed modes
  readonly property var enabledModes: {
    if (root.blockData && root.blockData.settings && Array.isArray(root.blockData.settings.modes)) {
      return root.blockData.settings.modes
    }
    return [0, 1, 2, 4]
  }

  readonly property string effectivePresentation: {
    if (root.resolvedPresentation && root.resolvedPresentation !== "auto") {
      return root.resolvedPresentation
    }
    if (root.height >= root.dp(135, 110) && root.width >= root.dp(220, 180)) {
      return "dashboard"
    }
    if (root.height >= root.dp(64, 50) && root.width >= root.dp(152, 120)) {
      return "detailed"
    }
    if (root.height >= root.dp(42, 36)) {
      return "compact"
    }
    return "icon"
  }

  function getModeMeta(modeKey) {
    switch (modeKey) {
      case 0:
        return { key: 0, label: "Quiet", icon: "󰈐", desc: "Silent operation" }
      case 1:
        return { key: 1, label: "Standard", icon: "󰈐", desc: "Balanced automatic profile" }
      case 2:
        return { key: 2, label: "Clean", icon: "󰃢", desc: "High-speed dust clearance" }
      case 4:
        return { key: 4, label: "Boost", icon: "󰓅", desc: "Full performance boost" }
      default:
        return { key: modeKey, label: "Mode " + modeKey, icon: "󰈐", desc: "" }
    }
  }

  readonly property string currentModeName: {
    if (!root.isFanSupported) return "Unsupported"
    var meta = getModeMeta(root.currentMode)
    return root.currentMode >= 0 ? meta.label : "Auto"
  }

  readonly property string currentModeDesc: {
    if (!root.isFanSupported) return "Fan control is not supported on this device"
    var meta = getModeMeta(root.currentMode)
    return (root.currentMode >= 0 && meta.desc) ? meta.desc : "Automatic thermal control"
  }

  function requestMode(modeKey) {
    if (root.actionHub && typeof root.actionHub.requestFanMode === "function") {
      root.actionHub.requestFanMode(modeKey)
    }
  }

  // Main Container Column
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(4, 2)
    spacing: root.dp(4, 2)

    // Detailed / Dashboard Header
    RowLayout {
      Layout.fillWidth: true
      visible: root.effectivePresentation === "detailed" || root.effectivePresentation === "dashboard"
      spacing: root.dp(6, 4)

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
          text: root.effectivePresentation === "dashboard" ? "Fan & Thermal Profile" : "Fan Profile"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 10)
          font.bold: true
          color: Commons.Util.alpha(Commons.Color.foreground, 0.78)
          Layout.fillWidth: true
          elide: Text.ElideRight
          maximumLineCount: 1
        }

        Text {
          visible: root.effectivePresentation === "dashboard"
          text: root.currentModeDesc
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.62)
          Layout.fillWidth: true
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }

      Text {
        text: root.isBusy ? "Applying..." : (root.lastError !== "" ? "⚠ Error" : root.currentModeName)
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(11, 10)
        font.bold: true
        color: root.lastError !== "" ? Commons.Color.urgent : Commons.Color.accent
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }

    // Dashboard Thermal Sensor Strip (CPU / GPU / NVMe / HDD)
    RowLayout {
      Layout.fillWidth: true
      visible: root.effectivePresentation === "dashboard"
      spacing: root.dp(4, 2)

      Repeater {
        model: root.thermalSummaryModel

        Rectangle {
          id: sensorChip
          required property var modelData
          required property int index

          Layout.fillWidth: true
          Layout.preferredHeight: root.dp(34, 26)
          radius: root.dp(4, 2)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
          border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
          border.width: 1

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            Text {
              text: String(sensorChip.modelData.label)
              font.family: Commons.Style.fontFamily
              font.pixelSize: root.dp(10, 10)
              color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
              Layout.alignment: Qt.AlignHCenter
              elide: Text.ElideRight
              maximumLineCount: 1
            }

            Text {
              text: String(sensorChip.modelData.value)
              font.family: Commons.Style.fontFamily
              font.pixelSize: root.dp(11, 10)
              font.bold: true
              color: Commons.Color.foreground
              Layout.alignment: Qt.AlignHCenter
              elide: Text.ElideRight
              maximumLineCount: 1
            }
          }
        }
      }
    }

    // Action Buttons Row (Interactive targets >= 28x28)
    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: root.dp(4, 2)

      Repeater {
        model: root.enabledModes

        Rectangle {
          id: modeBtn
          required property var modelData
          required property int index

          readonly property int modeKey: Number(modelData)
          readonly property var meta: root.getModeMeta(modeKey)
          readonly property bool isSelected: root.currentMode === modeKey
          readonly property bool isPending: root.isBusy && root.pendingMode === modeKey

          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.minimumWidth: 28
          Layout.minimumHeight: 28
          opacity: root.isFanSupported ? 1.0 : 0.45

          radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.5))
          color: modeTap.pressed
            ? Commons.Util.alpha(Commons.Color.accent, 0.30)
            : (modeHover.hovered
              ? Commons.Util.alpha(Commons.Color.accent, 0.16)
              : (isSelected
                ? Commons.Util.alpha(Commons.Color.accent, 0.22)
                : Commons.Util.alpha(Commons.Color.foreground, 0.05)))

          border.color: isSelected
            ? Commons.Color.accent
            : (modeHover.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.50) : Commons.Util.alpha(Commons.Color.foreground, 0.10))
          border.width: isSelected ? 2 : Commons.Style.normalBorderWidth

          HoverHandler {
            id: modeHover
            enabled: root.isFanSupported
            cursorShape: Qt.PointingHandCursor
          }

          TapHandler {
            id: modeTap
            enabled: root.isFanSupported
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: root.requestMode(modeBtn.modeKey)
          }

          ColumnLayout {
            anchors.centerIn: parent
            spacing: root.dp(2, 1)

            Text {
              text: modeBtn.meta.icon
              font.family: Commons.Style.fontFamily
              font.pixelSize: root.dp(15, 12)
              color: modeBtn.isSelected ? Commons.Color.accent : Commons.Color.foreground
              Layout.alignment: Qt.AlignHCenter
            }

            Text {
              visible: root.effectivePresentation === "detailed" || root.effectivePresentation === "dashboard"
              text: modeBtn.meta.label
              font.family: Commons.Style.fontFamily
              font.pixelSize: root.dp(10, 10)
              font.bold: modeBtn.isSelected
              color: modeBtn.isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.80)
              Layout.alignment: Qt.AlignHCenter
              elide: Text.ElideRight
              maximumLineCount: 1
            }
          }
        }
      }
    }

    // Compact mode indicator footer (Only in compact presentation)
    RowLayout {
      Layout.fillWidth: true
      visible: root.effectivePresentation === "compact"
      spacing: root.dp(4, 2)

      Text {
        text: root.isFanSupported ? ("Fan: " + root.currentModeName) : "Fan control unsupported"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.60)
        Layout.alignment: Qt.AlignHCenter
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }
  }
}
