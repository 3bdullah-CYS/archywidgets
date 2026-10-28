pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — CompactBatteryVariant
// 1x1 Compact glance tile for battery and charging status.
// Pure presentation delegate — zero timers, zero background processes.

Item {
  id: root
  anchors.fill: parent
  clip: true

  property real densityScale: 1.0
  property bool batteryAvailable: true
  property bool percentValid: true
  property int percent: 0
  property real fraction: 0.0
  property bool charging: false
  property bool isUrgent: false
  property string batteryIcon: "󰁹"
  property string stateText: "Discharging"
  property string timeRemainingText: ""

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  // 1. No battery state (desktop AC power)
  ColumnLayout {
    anchors.centerIn: parent
    visible: !root.batteryAvailable
    spacing: root.dp(2, 1)

    Text {
      text: "󱉝"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(16, 12)
      color: Commons.Color.muted
      Layout.alignment: Qt.AlignHCenter
    }

    Text {
      text: "No battery"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 10)
      color: Commons.Color.muted
      Layout.alignment: Qt.AlignHCenter
      Layout.maximumWidth: Math.max(0, root.width - root.dp(8, 4))
      elide: Text.ElideRight
      maximumLineCount: 1
    }
  }

  // 2. Real battery state (1x1)
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(6, 4)
    visible: root.batteryAvailable && root.percentValid
    spacing: root.dp(2, 1)

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(4, 2)

      Text {
        text: root.batteryIcon
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(14, 11)
        color: root.isUrgent ? Commons.Color.urgent : (root.charging ? Commons.Color.accent : Commons.Color.foreground)
      }

      Text {
        text: root.stateText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        font.bold: true
        color: Commons.Util.alpha(Commons.Color.foreground, 0.75)
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }

      Text {
        text: String(root.percent) + "%"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(13, 10)
        font.bold: true
        color: root.isUrgent ? Commons.Color.urgent : Commons.Color.foreground
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.alignment: Qt.AlignRight
      }
    }

    Text {
      visible: root.timeRemainingText.length > 0 && root.height >= root.dp(52, 40)
      text: root.timeRemainingText
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 10)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.60)
      elide: Text.ElideRight
      maximumLineCount: 1
      Layout.fillWidth: true
    }

    Rectangle {
      visible: root.height >= root.dp(36, 28)
      Layout.fillWidth: true
      Layout.preferredHeight: root.dp(3, 2)
      radius: root.dp(2, 1)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.14)
      clip: true

      Rectangle {
        height: parent.height
        width: Math.round(parent.width * root.fraction)
        radius: parent.radius
        color: root.isUrgent ? Commons.Color.urgent : Commons.Color.accent
      }
    }
  }
}
