pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — MonthGridVariant
// Large 2x2 Full 42-day monthly calendar grid with today highlight.
// Pure presentation delegate — zero timers, zero background processes.

Item {
  id: root
  anchors.fill: parent
  clip: true

  property real densityScale: 1.0
  property string dayNumber: "--"
  property string shortWeekdayText: "---"
  property string monthYearText: ""
  property var monthCalendarModel: []

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

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: root.dp(10, 8)
    anchors.rightMargin: root.dp(10, 8)
    anchors.topMargin: root.dp(7, 5)
    anchors.bottomMargin: root.dp(7, 5)
    spacing: root.dp(4, 3)

    // Top Header: Month & Year + Today Pill
    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(6, 4)

      RowLayout {
        Layout.fillWidth: true
        spacing: root.dp(5, 4)

        Text {
          text: "󰃭"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(12, 10)
          color: Commons.Color.accent
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          text: root.monthYearText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 10)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }

      Rectangle {
        radius: root.dp(8, 6)
        color: Commons.Util.alpha(Commons.Color.accent, 0.16)
        border.color: Commons.Util.alpha(Commons.Color.accent, 0.35)
        border.width: 1
        implicitWidth: todayPillText.implicitWidth + root.dp(12, 10)
        implicitHeight: root.dp(18, 15)

        Text {
          id: todayPillText
          anchors.centerIn: parent
          text: root.shortWeekdayText + " " + root.dayNumber
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(8, 7)
          font.bold: true
          color: Commons.Color.accent
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }

    // Weekday Header Row (S M T W T F S)
    GridLayout {
      Layout.fillWidth: true
      columns: 7
      columnSpacing: root.dp(2, 1)
      rowSpacing: 0

      Repeater {
        model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        Item {
          id: dowHeaderItem
          required property string modelData
          required property int index
          Layout.fillWidth: true
          Layout.preferredHeight: root.dp(13, 11)

          Text {
            anchors.centerIn: parent
            text: root.width >= root.dp(270, 220) ? dowHeaderItem.modelData : dowHeaderItem.modelData.charAt(0)
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(8, 7)
            font.bold: true
            color: (dowHeaderItem.index === 0 || dowHeaderItem.index === 6)
              ? Commons.Util.alpha(Commons.Color.accent, 0.78)
              : Commons.Util.alpha(Commons.Color.foreground, 0.52)
            maximumLineCount: 1
            elide: Text.ElideRight
          }
        }
      }
    }

    // 6x7 Month Days Grid
    GridLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      columns: 7
      rows: 6
      columnSpacing: root.dp(2, 1)
      rowSpacing: root.dp(2, 1)

      Repeater {
        model: root.monthCalendarModel

        Rectangle {
          id: monthDayCell
          required property var modelData
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: Math.max(3, Math.round(Commons.Style.cornerRadius * 0.35))
          color: monthDayCell.modelData.isToday
            ? Commons.Color.accent
            : (monthDayCell.modelData.inMonth
              ? Commons.Util.alpha(Commons.Color.foreground, 0.04)
              : "transparent")
          border.color: monthDayCell.modelData.isToday
            ? Commons.Color.accent
            : "transparent"
          border.width: monthDayCell.modelData.isToday ? 1 : 0

          Text {
            anchors.centerIn: parent
            text: monthDayCell.modelData.dayNum
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(9, 7)
            font.bold: monthDayCell.modelData.isToday || monthDayCell.modelData.inMonth
            color: monthDayCell.modelData.isToday
              ? Commons.Color.background
              : (monthDayCell.modelData.inMonth
                ? (monthDayCell.modelData.isWeekend
                  ? Commons.Util.alpha(Commons.Color.foreground, 0.75)
                  : Commons.Color.foreground)
                : Commons.Util.alpha(Commons.Color.foreground, 0.24))
            maximumLineCount: 1
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
