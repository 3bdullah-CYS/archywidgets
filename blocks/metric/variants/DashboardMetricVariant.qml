pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive
import "../../../components" as Components

// OmaDesk — DashboardMetricVariant
// Large 2x2+ telemetry and storage dashboard presentation.
// Pure presentation delegate — no timers, no background processes.

Item {
  id: root
  anchors.fill: parent

  property real densityScale: 1.0
  property string sourceIcon: "󰘚"
  property string label: "RAM"
  property string formattedValue: "--"
  property string detailText: ""
  property string statusBadgeText: "Optimal"
  property real progressFraction: 0.0
  property bool isHighLoad: false
  property bool hasProgressBar: true
  property bool isDiskMetric: false
  property var diskVolumes: []

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(8, 6)
    spacing: root.dp(6, 4)

    // Header Row
    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(6, 4)

      Rectangle {
        Layout.preferredWidth: root.dp(30, 22)
        Layout.preferredHeight: root.dp(30, 22)
        radius: root.dp(6, 3)
        color: root.isHighLoad
          ? Commons.Util.alpha(Commons.Color.urgent, 0.18)
          : Commons.Util.alpha(Commons.Color.accent, 0.18)

        Text {
          anchors.centerIn: parent
          text: root.sourceIcon
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(15, 12)
          color: root.isHighLoad ? Commons.Color.urgent : Commons.Color.accent
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
          text: (root.isDiskMetric && root.diskVolumes.length > 1) ? "Storage Volumes" : root.label
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(12, 10)
          font.bold: true
          color: Commons.Color.foreground
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }

        Text {
          visible: root.detailText.length > 0 && !(root.isDiskMetric && root.diskVolumes.length > 1)
          text: root.detailText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.68)
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }
      }

      Components.BadgeTag {
        Layout.preferredHeight: root.dp(20, 16)
        badgeColor: root.isHighLoad ? Commons.Color.urgent : Commons.Color.accent
        text: (root.isDiskMetric && root.diskVolumes.length > 1) ? (root.diskVolumes.length + " Disks") : root.statusBadgeText
      }
    }

    // Single-metric Dashboard Body
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: !(root.isDiskMetric && root.diskVolumes.length > 1)
      spacing: root.dp(4, 2)

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Text {
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          text: root.formattedValue
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(26, 16)
          font.bold: true
          color: root.isHighLoad ? Commons.Color.urgent : Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
          width: Math.max(0, parent.width - root.dp(4, 2))
        }
      }

      Components.LinearGauge {
        visible: root.hasProgressBar
        Layout.fillWidth: true
        gaugeHeight: root.dp(8, 5)
        value: root.progressFraction
        maxValue: 1.0
        gaugeColor: root.isHighLoad ? Commons.Color.urgent : Commons.Color.accent
      }
    }

    // Multi-Disk Dashboard Body
    Flickable {
      Layout.fillWidth: true
      Layout.fillHeight: true
      visible: root.isDiskMetric && root.diskVolumes.length > 1
      contentWidth: width
      contentHeight: diskListCol.implicitHeight
      clip: true

      ColumnLayout {
        id: diskListCol
        width: parent.width
        spacing: root.dp(6, 4)

        Repeater {
          model: root.diskVolumes

          ColumnLayout {
            required property var modelData
            required property int index

            Layout.fillWidth: true
            spacing: root.dp(2, 1)

            RowLayout {
              Layout.fillWidth: true
              spacing: root.dp(4, 2)

              Text {
                text: modelData.label || "Disk"
                font.family: Commons.Style.fontFamily
                font.pixelSize: root.dp(11, 10)
                font.bold: true
                color: Commons.Color.foreground
                elide: Text.ElideRight
                maximumLineCount: 1
              }

              Text {
                text: "(" + (modelData.mount || "/") + ")"
                font.family: Commons.Style.fontFamily
                font.pixelSize: root.dp(9, 8)
                color: Commons.Util.alpha(Commons.Color.foreground, 0.50)
                elide: Text.ElideRight
                maximumLineCount: 1
                Layout.fillWidth: true
              }

              Text {
                text: (modelData.available_str || "0 GB") + " Free"
                font.family: Commons.Style.fontFamily
                font.pixelSize: root.dp(11, 10)
                font.bold: true
                color: (modelData.percent >= 85) ? Commons.Color.urgent : Commons.Color.accent
                Layout.alignment: Qt.AlignRight
              }
            }

            Components.LinearGauge {
              Layout.fillWidth: true
              gaugeHeight: root.dp(5, 3)
              value: Math.max(0.0, Math.min(1.0, (modelData.percent || 0) * 0.01))
              maxValue: 1.0
              gaugeColor: (modelData.percent >= 85) ? Commons.Color.urgent : Commons.Color.accent
            }

            RowLayout {
              Layout.fillWidth: true

              Text {
                text: "Total: " + (modelData.total_str || "0 GB")
                font.family: Commons.Style.fontFamily
                font.pixelSize: root.dp(9, 8)
                color: Commons.Util.alpha(Commons.Color.foreground, 0.60)
              }

              Item { Layout.fillWidth: true }

              Text {
                text: (modelData.percent || 0) + "% used"
                font.family: Commons.Style.fontFamily
                font.pixelSize: root.dp(9, 8)
                color: Commons.Util.alpha(Commons.Color.foreground, 0.60)
              }
            }
          }
        }
      }
    }
  }
}
