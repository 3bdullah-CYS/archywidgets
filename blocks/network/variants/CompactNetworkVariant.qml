pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — CompactNetworkVariant
// 1x1 Compact network glance tile showing connection and live speed.
// Pure presentation delegate — zero timers, zero background processes.

Item {
  id: root
  anchors.fill: parent
  clip: true

  property real densityScale: 1.0
  property bool connected: false
  property string connectionIcon: "󰤨"
  property string networkName: ""
  property string downloadText: "0 KB/s"
  property string uploadText: "0 KB/s"
  property string interfaceSummary: ""
  property string networkIp: ""
  property string totalDownloadText: ""
  property string totalUploadText: ""

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(4, 2)
    spacing: root.dp(3, 2)

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(5, 3)

      Text {
        text: root.connectionIcon
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(14, 11)
        color: root.connected ? Commons.Color.accent : Commons.Color.muted
      }

      Text {
        textFormat: Text.PlainText
        text: root.connected ? root.networkName : "Disconnected"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(11, 10)
        font.bold: true
        color: root.connected ? Commons.Color.foreground : Commons.Color.muted
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(6, 3)

      Text {
        text: "↓ " + root.downloadText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.78)
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }

      Text {
        text: "↑ " + root.uploadText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.70)
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.alignment: Qt.AlignRight
      }
    }

    // Extra metadata shown automatically when compact block is tall (e.g. 1x2)
    ColumnLayout {
      Layout.fillWidth: true
      visible: root.height >= root.dp(110, 88)
      spacing: root.dp(2, 1)

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
      }

      Text {
        textFormat: Text.PlainText
        text: root.connected && root.networkIp.length > 0 ? (root.interfaceSummary + " • " + root.networkIp) : root.interfaceSummary
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        color: Commons.Color.accent
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }

      Text {
        text: "Σ ↓ " + root.totalDownloadText + "  ↑ " + root.totalUploadText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }
    }
  }
}
