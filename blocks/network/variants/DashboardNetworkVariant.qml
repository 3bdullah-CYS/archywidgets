pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — DashboardNetworkVariant
// 2x2+ Large network dashboard with connection details and session metrics.
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
  property real downFraction: 0.0
  property real upFraction: 0.0

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(6, 4)
    spacing: root.dp(6, 4)

    // Row 1: Connection Status Header & IP Pill
    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(8, 4)

      Rectangle {
        Layout.preferredWidth: root.dp(34, 24)
        Layout.preferredHeight: root.dp(34, 24)
        radius: root.dp(8, 4)
        color: root.connected ? Commons.Util.alpha(Commons.Color.accent, 0.18) : Commons.Util.alpha(Commons.Color.foreground, 0.08)

        Text {
          anchors.centerIn: parent
          text: root.connectionIcon
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(17, 13)
          color: root.connected ? Commons.Color.accent : Commons.Color.muted
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
          textFormat: Text.PlainText
          text: root.connected ? root.networkName : "Disconnected"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(14, 11)
          font.bold: true
          color: root.connected ? Commons.Color.foreground : Commons.Color.muted
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }

        Text {
          textFormat: Text.PlainText
          text: root.interfaceSummary
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.70)
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }
      }

      Rectangle {
        visible: root.connected && root.networkIp.length > 0
        Layout.preferredHeight: root.dp(22, 18)
        implicitWidth: ipBadgeText.implicitWidth + root.dp(12, 8)
        radius: root.dp(5, 3)
        color: Commons.Util.alpha(Commons.Color.accent, 0.14)
        border.color: Commons.Util.alpha(Commons.Color.accent, 0.35)
        border.width: 1

        Text {
          id: ipBadgeText
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: root.networkIp
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: Commons.Color.accent
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }
    }

    // Row 2: Live Throughput Sub-Cards (Download & Upload)
    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: root.dp(6, 4)

      // Download Sub-Card
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: root.dp(6, 4)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
        border.width: 1

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: root.dp(6, 4)
          spacing: root.dp(3, 2)

          Text {
            text: "󰇚 Download"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(10, 10)
            color: Commons.Util.alpha(Commons.Color.foreground, 0.70)
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.fillWidth: true
          }

          Text {
            text: root.downloadText
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(15, 12)
            font.bold: true
            color: Commons.Color.foreground
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.fillWidth: true
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.dp(5, 3)
            radius: root.dp(2, 1)
            color: Commons.Util.alpha(Commons.Color.foreground, 0.14)

            Rectangle {
              width: Math.round(parent.width * root.downFraction)
              height: parent.height
              radius: parent.radius
              color: Commons.Color.accent
            }
          }
        }
      }

      // Upload Sub-Card
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        radius: root.dp(6, 4)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
        border.width: 1

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: root.dp(6, 4)
          spacing: root.dp(3, 2)

          Text {
            text: "󰕒 Upload"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(10, 10)
            color: Commons.Util.alpha(Commons.Color.foreground, 0.70)
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.fillWidth: true
          }

          Text {
            text: root.uploadText
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(15, 12)
            font.bold: true
            color: Commons.Color.foreground
            elide: Text.ElideRight
            maximumLineCount: 1
            Layout.fillWidth: true
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.dp(5, 3)
            radius: root.dp(2, 1)
            color: Commons.Util.alpha(Commons.Color.foreground, 0.14)

            Rectangle {
              width: Math.round(parent.width * root.upFraction)
              height: parent.height
              radius: parent.radius
              color: Commons.Util.alpha(Commons.Color.accent, 0.75)
            }
          }
        }
      }
    }

    // Row 3: Session Total Traffic Footer
    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(8, 4)

      Text {
        text: "Session ↓ " + root.totalDownloadText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.72)
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }

      Text {
        text: "Session ↑ " + root.totalUploadText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.72)
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.alignment: Qt.AlignRight
      }
    }
  }
}
