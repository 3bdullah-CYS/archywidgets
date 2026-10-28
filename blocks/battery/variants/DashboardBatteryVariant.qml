pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive
import "../../../components" as Components

// OmaDesk — DashboardBatteryVariant
// 2x2+ Large power and battery dashboard with hero readout and telemetry statistics.
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
  property string powerWattsText: ""

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(10, 8)
    spacing: root.dp(8, 4)

    // Header Row: Icon Badge + Title + State Pill
    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(8, 4)

      Rectangle {
        Layout.preferredWidth: root.dp(28, 22)
        Layout.preferredHeight: root.dp(28, 22)
        radius: root.dp(6, 4)
        color: root.isUrgent
          ? Commons.Util.alpha(Commons.Color.urgent, 0.18)
          : (root.charging ? Commons.Util.alpha(Commons.Color.accent, 0.18) : Commons.Util.alpha(Commons.Color.foreground, 0.10))

        Text {
          anchors.centerIn: parent
          text: root.batteryIcon
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(15, 12)
          color: root.isUrgent ? Commons.Color.urgent : (root.charging ? Commons.Color.accent : Commons.Color.foreground)
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
          text: "Battery & Power"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(12, 10)
          font.bold: true
          color: Commons.Color.foreground
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }

        Text {
          text: root.charging ? "AC Connected · Charging" : (root.batteryAvailable ? "Running on Battery" : "AC Desktop Power")
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }
      }

      Rectangle {
        Layout.preferredHeight: root.dp(20, 16)
        implicitWidth: battStatePill.implicitWidth + root.dp(10, 6)
        radius: root.dp(4, 2)
        color: root.isUrgent
          ? Commons.Util.alpha(Commons.Color.urgent, 0.18)
          : (root.charging ? Commons.Util.alpha(Commons.Color.accent, 0.16) : Commons.Util.alpha(Commons.Color.foreground, 0.10))

        Text {
          id: battStatePill
          anchors.centerIn: parent
          text: root.stateText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: root.isUrgent ? Commons.Color.urgent : (root.charging ? Commons.Color.accent : Commons.Color.foreground)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }

    // Middle Row: Hero Percentage & Stats Grid
    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: root.dp(12, 6)

      // Hero Column
      ColumnLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: 0

        Text {
          text: root.batteryAvailable ? (String(root.percent) + "%") : "AC"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(30, 20)
          font.bold: true
          color: root.isUrgent ? Commons.Color.urgent : (root.charging ? Commons.Color.accent : Commons.Color.foreground)
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Text {
          text: root.charging ? "Plugged in" : (root.isUrgent ? "Connect charger" : "Healthy")
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.60)
          elide: Text.ElideRight
          maximumLineCount: 1
        }
      }

      // Stats Column
      ColumnLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: root.dp(4, 2)

        RowLayout {
          Layout.fillWidth: true
          spacing: root.dp(6, 4)

          Text {
            text: "󱎫"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(11, 10)
            color: Commons.Color.accent
          }
          Text {
            text: "Time Left:"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(10, 10)
            color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
          }
          Item { Layout.fillWidth: true }
          Text {
            text: root.timeRemainingText.length > 0 ? root.timeRemainingText : (root.charging ? "Full soon" : "Calculating...")
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(10, 10)
            font.bold: true
            color: Commons.Color.foreground
            elide: Text.ElideRight
            maximumLineCount: 1
          }
        }

        RowLayout {
          visible: root.powerWattsText.length > 0
          Layout.fillWidth: true
          spacing: root.dp(6, 4)

          Text {
            text: "󱐋"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(11, 10)
            color: Commons.Color.accent
          }
          Text {
            text: root.charging ? "Charge Rate:" : "Discharge Rate:"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(10, 10)
            color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
          }
          Item { Layout.fillWidth: true }
          Text {
            text: root.powerWattsText
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(10, 10)
            font.bold: true
            color: Commons.Color.accent
            elide: Text.ElideRight
            maximumLineCount: 1
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: root.dp(6, 4)

          Text {
            text: root.charging ? "󱐋" : "󰁹"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(11, 10)
            color: Commons.Color.accent
          }
          Text {
            text: "Power Source:"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(10, 10)
            color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
          }
          Item { Layout.fillWidth: true }
          Text {
            text: root.charging ? "AC Power" : "Battery"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(10, 10)
            font.bold: true
            color: Commons.Color.foreground
            elide: Text.ElideRight
            maximumLineCount: 1
          }
        }
      }
    }

    // Bottom Charge Gauge Bar
    Components.LinearGauge {
      Layout.fillWidth: true
      gaugeHeight: root.dp(6, 4)
      value: root.batteryAvailable ? root.fraction : 1.0
      maxValue: 1.0
      gaugeColor: root.isUrgent ? Commons.Color.urgent : (root.charging ? Commons.Color.accent : Commons.Color.foreground)
    }
  }
}
