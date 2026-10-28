pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive

// ArchyWidgets — SystemInfoBlock
// Pure presentation leaf for glanceable system identity & health (OS, Host, Kernel, CPU, Uptime, Load Average, Swap).
// Zero Process, Timer, FileView, or IPC inside the block.

Item {
  id: root

  required property var blockData
  required property var dataHub
  property string resolvedPresentation: "auto"
  property real densityScale: 1.0

  clip: true

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  readonly property string variant: (root.blockData && typeof root.blockData.variant === "string") ? root.blockData.variant : "compact"
  readonly property string presentation: {
    var mode = root.resolvedPresentation
    if (!mode || mode === "auto") {
      if (root.width >= root.dp(220, 180) && root.height >= root.dp(120, 95)) return "dashboard"
      if (root.variant === "wide" || root.width >= root.dp(170, 140)) return "detailed"
      return "compact"
    }
    return mode
  }

  readonly property string osNameText: (root.dataHub && root.dataHub.osName) ? String(root.dataHub.osName) : "Omarchy Linux"
  readonly property string hostnameText: (root.dataHub && root.dataHub.hostname) ? String(root.dataHub.hostname) : "omarchy-host"
  readonly property string kernelText: (root.dataHub && root.dataHub.kernelVer) ? String(root.dataHub.kernelVer) : "Linux"

  readonly property string uptimeText: {
    var _rev = root.dataHub ? root.dataHub.revision : 0
    void(_rev)
    return (root.dataHub && root.dataHub.uptimeText) ? String(root.dataHub.uptimeText) : "Active"
  }

  readonly property string cpuModelText: {
    var model = (root.dataHub && root.dataHub.cpuModel) ? String(root.dataHub.cpuModel) : "Processor"
    var cores = (root.dataHub && root.dataHub.cpuCores > 0) ? (" (" + root.dataHub.cpuCores + "T)") : ""
    return model + cores
  }

  readonly property string loadAvgText: {
    var _rev = root.dataHub ? root.dataHub.revision : 0
    void(_rev)
    return (root.dataHub && root.dataHub.loadAvg) ? String(root.dataHub.loadAvg) : "0.00 · 0.00 · 0.00"
  }

  readonly property string swapSummaryText: {
    var _rev = root.dataHub ? root.dataHub.revision : 0
    void(_rev)
    if (!root.dataHub || !root.dataHub.swapTotalGb || root.dataHub.swapTotalGb === "0.0") return "Swap Off"
    return String(root.dataHub.swapUsedGb || "0.0") + " / " + String(root.dataHub.swapTotalGb) + " GB (" + Number(root.dataHub.swapPercent || 0) + "%)"
  }

  // Subtle background card
  Rectangle {
    anchors.fill: parent
    radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.55))
    color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
    border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
    border.width: 1
  }

  // 1. Icon presentation
  RowLayout {
    anchors.fill: parent
    anchors.margins: root.dp(6, 4)
    spacing: root.dp(5, 4)
    visible: root.presentation === "icon"

    Text {
      text: "󰌽"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(14, 12)
      color: Commons.Color.accent
    }

    Text {
      Layout.fillWidth: true
      text: root.hostnameText
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(11, 10)
      font.bold: true
      color: Commons.Color.foreground
      maximumLineCount: 1
      elide: Text.ElideRight
    }
  }

  // 2. Compact presentation (1x1)
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(8, 6)
    spacing: root.dp(3, 2)
    visible: root.presentation === "compact"

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(5, 4)

      Text {
        text: "󰌽"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(13, 11)
        color: Commons.Color.accent
      }

      Text {
        Layout.fillWidth: true
        text: root.osNameText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(11, 10)
        font.bold: true
        color: Commons.Color.foreground
        maximumLineCount: 1
        elide: Text.ElideRight
      }
    }

    Text {
      Layout.fillWidth: true
      text: root.hostnameText + " · " + root.kernelText
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 10)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.68)
      maximumLineCount: 1
      elide: Text.ElideRight
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(4, 3)

      Text {
        text: "󰅐"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        color: Commons.Color.accent
      }

      Text {
        Layout.fillWidth: true
        text: root.uptimeText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        font.bold: true
        color: Commons.Util.alpha(Commons.Color.foreground, 0.85)
        maximumLineCount: 1
        elide: Text.ElideRight
      }
    }
  }

  // 3. Detailed presentation (2x1 Wide strip)
  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: root.dp(10, 8)
    anchors.rightMargin: root.dp(10, 8)
    anchors.topMargin: root.dp(6, 4)
    anchors.bottomMargin: root.dp(6, 4)
    spacing: root.dp(10, 8)
    visible: root.presentation === "detailed"

    // Left: OS badge + Hostname & Kernel
    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(8, 6)

      Rectangle {
        Layout.preferredWidth: root.dp(28, 24)
        Layout.preferredHeight: root.dp(28, 24)
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: Commons.Util.alpha(Commons.Color.accent, 0.16)
        border.color: Commons.Util.alpha(Commons.Color.accent, 0.35)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "󰌽"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(15, 12)
          color: Commons.Color.accent
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: root.dp(1, 1)

        Text {
          Layout.fillWidth: true
          text: root.osNameText + " (" + root.hostnameText + ")"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 10)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: "Kernel " + root.kernelText + " · Up " + root.uptimeText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.68)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }

    // Right: Load Average pill
    Rectangle {
      visible: root.width >= root.dp(230, 190)
      Layout.preferredWidth: Math.min(root.dp(118, 96), Math.round(root.width * 0.38))
      Layout.preferredHeight: root.dp(26, 22)
      radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.4))
      color: Commons.Util.alpha(Commons.Color.foreground, 0.06)
      border.color: Commons.Util.alpha(Commons.Color.foreground, 0.12)
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: root.dp(6, 4)
        anchors.rightMargin: root.dp(6, 4)
        spacing: 0

        Text {
          Layout.fillWidth: true
          text: "LOAD AVG"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: Commons.Color.accent
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: root.loadAvgText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }
  }

  // 4. Dashboard presentation (2x2 Large overview)
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(10, 8)
    spacing: root.dp(6, 4)
    visible: root.presentation === "dashboard"

    // Header row: OS + Hostname badge
    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(8, 6)

      Rectangle {
        Layout.preferredWidth: root.dp(30, 26)
        Layout.preferredHeight: root.dp(30, 26)
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: Commons.Util.alpha(Commons.Color.accent, 0.16)
        border.color: Commons.Util.alpha(Commons.Color.accent, 0.35)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: "󰌽"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(16, 13)
          color: Commons.Color.accent
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
          Layout.fillWidth: true
          text: root.osNameText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 10)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: root.hostnameText + " · Linux " + root.kernelText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(9, 8)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.68)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      height: 1
      color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
    }

    // 2x2 Info Grid: CPU, Uptime, Load Avg, Swap
    GridLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      columns: 2
      rowSpacing: root.dp(5, 4)
      columnSpacing: root.dp(8, 6)

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
          text: "PROCESSOR"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: Commons.Util.alpha(Commons.Color.foreground, 0.50)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
        Text {
          Layout.fillWidth: true
          text: root.cpuModelText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 10)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
          text: "UPTIME"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: Commons.Util.alpha(Commons.Color.foreground, 0.50)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
        Text {
          Layout.fillWidth: true
          text: root.uptimeText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 10)
          font.bold: true
          color: Commons.Color.accent
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
          text: "LOAD AVERAGE"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: Commons.Util.alpha(Commons.Color.foreground, 0.50)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
        Text {
          Layout.fillWidth: true
          text: root.loadAvgText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 10)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1
        Text {
          text: "SWAP MEMORY"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: Commons.Util.alpha(Commons.Color.foreground, 0.50)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
        Text {
          Layout.fillWidth: true
          text: root.swapSummaryText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 10)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }
  }
}
