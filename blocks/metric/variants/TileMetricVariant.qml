pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive
import "../../../components" as Components

// OmaDesk — TileMetricVariant
// Compact glance tile presentation for metrics (icon and compact 1x1 tile).
// Pure presentation delegate — no timers, no background processes.

Item {
  id: root
  anchors.fill: parent

  property real densityScale: 1.0
  property string presentation: "compact"
  property string sourceIcon: "󰘚"
  property string label: "RAM"
  property string formattedValue: "--"
  property string detailText: ""
  property real progressFraction: 0.0
  property bool isHighLoad: false
  property bool hasProgressBar: false

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  // Presentation 1: Icon Mode (minimal icon + value)
  RowLayout {
    anchors.centerIn: parent
    visible: root.presentation === "icon"
    spacing: root.dp(4, 2)

    Text {
      text: root.sourceIcon
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(14, 11)
      color: root.isHighLoad ? Commons.Color.urgent : Commons.Color.accent
    }

    Text {
      text: root.formattedValue
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(11, 9)
      font.bold: true
      color: root.isHighLoad ? Commons.Color.urgent : Commons.Color.foreground
      maximumLineCount: 1
      elide: Text.ElideRight
      Layout.maximumWidth: Math.max(0, root.width - root.dp(22, 16))
    }
  }

  // Presentation 2: Compact Tile Mode (1x1)
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(7, 5)
    visible: root.presentation === "compact"
    spacing: root.dp(3, 2)

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(4, 2)

      RowLayout {
        spacing: root.dp(4, 2)
        Layout.fillWidth: true

        Text {
          text: root.sourceIcon
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 9)
          color: root.isHighLoad ? Commons.Color.urgent : Commons.Color.accent
        }

        Text {
          text: root.label
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(9, 8)
          font.bold: true
          color: Commons.Util.alpha(Commons.Color.foreground, 0.75)
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }
      }

      Text {
        text: root.formattedValue
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(12, 10)
        font.bold: true
        color: root.isHighLoad ? Commons.Color.urgent : Commons.Color.foreground
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.alignment: Qt.AlignRight
      }
    }

    Text {
      visible: root.detailText.length > 0 && root.height >= root.dp(52, 40)
      text: root.detailText
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 10)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.60)
      elide: Text.ElideRight
      maximumLineCount: 1
      Layout.fillWidth: true
    }

    Components.LinearGauge {
      visible: root.hasProgressBar && root.height >= root.dp(36, 28)
      Layout.fillWidth: true
      gaugeHeight: root.dp(3, 2)
      value: root.progressFraction
      maxValue: 1.0
      gaugeColor: root.isHighLoad ? Commons.Color.urgent : Commons.Color.accent
    }
  }
}
