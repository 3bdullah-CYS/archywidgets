pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive
import "../../../components" as Components

// OmaDesk — BarMetricVariant
// Wide horizontal bar gauge presentation for metrics (2x1 detailed mode).
// Pure presentation delegate — no timers, no background processes.

Item {
  id: root
  anchors.fill: parent

  property real densityScale: 1.0
  property string sourceIcon: "󰘚"
  property string label: "RAM"
  property string formattedValue: "--"
  property string detailText: ""
  property real progressFraction: 0.0
  property bool isHighLoad: false
  property bool hasProgressBar: true

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(10, 8)
    spacing: root.dp(4, 2)

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(6, 4)

      Rectangle {
        Layout.preferredWidth: root.dp(22, 18)
        Layout.preferredHeight: root.dp(22, 18)
        radius: root.dp(5, 3)
        color: root.isHighLoad
          ? Commons.Util.alpha(Commons.Color.urgent, 0.18)
          : Commons.Util.alpha(Commons.Color.accent, 0.16)

        Text {
          anchors.centerIn: parent
          text: root.sourceIcon
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(13, 10)
          color: root.isHighLoad ? Commons.Color.urgent : Commons.Color.accent
        }
      }

      Text {
        text: root.label
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(12, 10)
        font.bold: true
        color: Commons.Color.foreground
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }

      Text {
        text: root.formattedValue
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(14, 11)
        font.bold: true
        color: root.isHighLoad ? Commons.Color.urgent : Commons.Color.foreground
        Layout.alignment: Qt.AlignRight
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }

    Text {
      visible: root.detailText.length > 0 && root.height >= root.dp(46, 38)
      text: root.detailText
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 10)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
      elide: Text.ElideRight
      maximumLineCount: 1
      Layout.fillWidth: true
    }

    Components.LinearGauge {
      Layout.fillWidth: true
      Layout.preferredHeight: root.dp(6, 3)
      gaugeHeight: root.dp(6, 3)
      value: root.progressFraction
      maxValue: 1.0
      gaugeColor: root.isHighLoad ? Commons.Color.urgent : Commons.Color.accent
    }
  }
}
