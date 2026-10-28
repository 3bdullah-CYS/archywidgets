pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — WeekStripVariant
// Wide 2x1 Banner date presentation with left badge and right 7-day week strip.
// Pure presentation delegate — zero timers, zero background processes.

Item {
  id: root
  anchors.fill: parent
  clip: true

  property real densityScale: 1.0
  property string dayNumber: "--"
  property string weekdayText: "Unavailable"
  property string shortMonthYearText: ""
  property var weekStripModel: []

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  // Card Background
  Rectangle {
    anchors.fill: parent
    radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.55))
    color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
    border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
    border.width: 1
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: root.dp(10, 8)
    anchors.rightMargin: root.dp(10, 8)
    anchors.topMargin: root.dp(6, 5)
    anchors.bottomMargin: root.dp(6, 5)
    spacing: root.dp(10, 8)

    // Left: Day number badge + Weekday/Month stack
    RowLayout {
      Layout.fillHeight: true
      Layout.preferredWidth: root.width >= root.dp(240, 195) ? Math.min(root.dp(125, 102), Math.round(root.width * 0.42)) : -1
      Layout.fillWidth: root.width < root.dp(240, 195)
      spacing: root.dp(8, 6)

      Rectangle {
        Layout.preferredWidth: root.dp(34, 28)
        Layout.preferredHeight: root.dp(34, 28)
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.5))
        color: Commons.Util.alpha(Commons.Color.accent, 0.16)
        border.color: Commons.Util.alpha(Commons.Color.accent, 0.40)
        border.width: 1

        Text {
          anchors.centerIn: parent
          text: root.dayNumber
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(15, 12)
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
          Layout.fillWidth: true
          text: root.weekdayText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 9)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: root.shortMonthYearText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(9, 8)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }

    // Right: 7-day week strip (when width fits)
    RowLayout {
      visible: root.width >= root.dp(240, 195)
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: root.dp(3, 2)

      Repeater {
        model: root.weekStripModel

        Rectangle {
          id: wideDayCell
          required property var modelData
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.maximumHeight: root.dp(38, 30)
          radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.4))
          color: wideDayCell.modelData.isToday
            ? Commons.Util.alpha(Commons.Color.accent, 0.22)
            : Commons.Util.alpha(Commons.Color.foreground, 0.04)
          border.color: wideDayCell.modelData.isToday
            ? Commons.Color.accent
            : "transparent"
          border.width: wideDayCell.modelData.isToday ? 1 : 0

          ColumnLayout {
            anchors.centerIn: parent
            spacing: 1

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: wideDayCell.modelData.label
              font.family: Commons.Style.fontFamily
              font.pixelSize: root.dp(7, 6)
              font.bold: true
              color: wideDayCell.modelData.isToday
                ? Commons.Color.accent
                : Commons.Util.alpha(Commons.Color.foreground, 0.48)
              maximumLineCount: 1
              elide: Text.ElideRight
            }

            Text {
              Layout.alignment: Qt.AlignHCenter
              text: wideDayCell.modelData.dayNum
              font.family: Commons.Style.fontFamily
              font.pixelSize: root.dp(9, 8)
              font.bold: wideDayCell.modelData.isToday
              color: wideDayCell.modelData.isToday
                ? Commons.Color.foreground
                : Commons.Util.alpha(Commons.Color.foreground, 0.78)
              maximumLineCount: 1
              elide: Text.ElideRight
            }
          }
        }
      }
    }
  }
}
