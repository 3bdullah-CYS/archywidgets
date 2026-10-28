pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive
import "../../../components" as Components

// OmaDesk — WideBatteryVariant
// 2x1 Wide Banner for battery and power metrics with linear gauge.
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
  property string powerSubtitle: ""
  property string powerWattsText: ""

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  // 1. No battery (2x1)
  RowLayout {
    anchors.centerIn: parent
    visible: !root.batteryAvailable
    spacing: root.dp(10, 5)

    Rectangle {
      Layout.preferredWidth: root.dp(32, 20)
      Layout.preferredHeight: root.dp(32, 20)
      radius: root.dp(6, 3)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.08)

      Text {
        anchors.centerIn: parent
        text: "󱉝"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(16, 12)
        color: Commons.Color.muted
      }
    }

    ColumnLayout {
      spacing: root.dp(1, 1)
      Layout.maximumWidth: Math.max(0, root.width - root.dp(48, 30))

      Text {
        text: "Battery"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(11, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.70)
        Layout.maximumWidth: Math.max(0, root.width - root.dp(48, 30))
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      Text {
        text: "No battery"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(13, 11)
        font.bold: true
        color: Commons.Color.muted
        Layout.maximumWidth: Math.max(0, root.width - root.dp(48, 30))
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }
  }

  // 2. Real Battery (2x1)
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(10, 8)
    visible: root.batteryAvailable && root.percentValid
    spacing: root.dp(4, 2)

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(6, 4)

      Rectangle {
        Layout.preferredWidth: root.dp(22, 18)
        Layout.preferredHeight: root.dp(22, 18)
        radius: root.dp(5, 3)
        color: root.isUrgent
          ? Commons.Util.alpha(Commons.Color.urgent, 0.18)
          : (root.charging ? Commons.Util.alpha(Commons.Color.accent, 0.18) : Commons.Util.alpha(Commons.Color.foreground, 0.10))

        Text {
          anchors.centerIn: parent
          text: root.batteryIcon
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(13, 10)
          color: root.isUrgent ? Commons.Color.urgent : (root.charging ? Commons.Color.accent : Commons.Color.foreground)
        }
      }

      Text {
        text: root.stateText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(12, 10)
        font.bold: true
        color: Commons.Color.foreground
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      Rectangle {
        Layout.preferredHeight: root.dp(16, 14)
        implicitWidth: detPillText.implicitWidth + root.dp(8, 4)
        radius: root.dp(4, 2)
        color: root.isUrgent
          ? Commons.Util.alpha(Commons.Color.urgent, 0.18)
          : (root.charging ? Commons.Util.alpha(Commons.Color.accent, 0.16) : Commons.Util.alpha(Commons.Color.foreground, 0.08))

        Text {
          id: detPillText
          anchors.centerIn: parent
          text: root.charging ? "AC" : (root.powerWattsText || "Battery")
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: root.isUrgent ? Commons.Color.urgent : (root.charging ? Commons.Color.accent : Commons.Color.foreground)
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }

      Item {
        Layout.fillWidth: true
      }

      Text {
        text: String(root.percent) + "%"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(14, 11)
        font.bold: true
        color: root.isUrgent ? Commons.Color.urgent : Commons.Color.foreground
        Layout.alignment: Qt.AlignRight
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }

    Text {
      visible: root.powerSubtitle.length > 0 && root.height >= root.dp(46, 38)
      text: root.powerSubtitle
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 10)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
      elide: Text.ElideRight
      maximumLineCount: 1
      Layout.fillWidth: true
    }

    Components.LinearGauge {
      Layout.fillWidth: true
      gaugeHeight: root.dp(5, 3)
      value: root.fraction
      maxValue: 1.0
      gaugeColor: root.isUrgent ? Commons.Color.urgent : (root.charging ? Commons.Color.accent : Commons.Color.foreground)
    }
  }
}
