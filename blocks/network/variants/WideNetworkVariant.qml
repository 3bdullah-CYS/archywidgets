pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — WideNetworkVariant
// 2x1 Wide Banner network presentation with live traffic progress bars.
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
  property real downFraction: 0.0
  property real upFraction: 0.0

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(4, 2)
    spacing: root.dp(4, 2)

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(8, 4)

      Rectangle {
        Layout.preferredWidth: root.dp(28, 20)
        Layout.preferredHeight: root.dp(28, 20)
        radius: root.dp(6, 3)
        color: root.connected ? Commons.Util.alpha(Commons.Color.accent, 0.16) : Commons.Util.alpha(Commons.Color.foreground, 0.08)

        Text {
          anchors.centerIn: parent
          text: root.connectionIcon
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(14, 11)
          color: root.connected ? Commons.Color.accent : Commons.Color.muted
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
          text: root.connected ? root.networkName : "Disconnected"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(12, 10)
          font.bold: true
          color: root.connected ? Commons.Color.foreground : Commons.Color.muted
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }

        Text {
          text: root.connected && root.networkIp.length > 0 ? (root.interfaceSummary + " • " + root.networkIp) : root.interfaceSummary
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.68)
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(8, 4)

      ColumnLayout {
        Layout.fillWidth: true
        spacing: root.dp(2, 1)

        Text {
          text: "󰇚 " + root.downloadText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: Commons.Color.foreground
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: root.dp(4, 2)
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

      ColumnLayout {
        Layout.fillWidth: true
        spacing: root.dp(2, 1)

        Text {
          text: "󰕒 " + root.uploadText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: Commons.Color.foreground
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: root.dp(4, 2)
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
}
