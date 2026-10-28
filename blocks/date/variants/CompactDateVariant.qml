pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — CompactDateVariant
// Original compact 1x1 date glance card (accent weekday pill, bold day number, month & year).
// Pure presentation delegate — zero timers, zero background processes.

Item {
  id: root
  anchors.fill: parent
  clip: true

  property real densityScale: 1.0
  property string dayNumber: "--"
  property string weekdayText: "Unavailable"
  property string shortMonthYearText: ""
  property string weekBadgeText: ""

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  // Subtle background card
  Rectangle {
    anchors.fill: parent
    radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.55))
    color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
    border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
    border.width: 1
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(7, 5)
    spacing: root.dp(3, 2)

    // Top Accent Header Pill (Weekday + Week number)
    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: root.dp(18, 15)
      radius: Math.max(3, Math.round(Commons.Style.cornerRadius * 0.35))
      color: Commons.Util.alpha(Commons.Color.accent, 0.16)
      border.color: Commons.Util.alpha(Commons.Color.accent, 0.32)
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.dp(6, 4)
        anchors.rightMargin: root.dp(6, 4)
        spacing: root.dp(4, 3)

        Text {
          Layout.fillWidth: true
          text: root.weekdayText.toUpperCase()
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(8, 7)
          font.bold: true
          color: Commons.Color.accent
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Text {
          text: root.weekBadgeText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(8, 7)
          font.bold: true
          color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }

    // Center Hero: Big Day Number + Month/Year
    RowLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: root.dp(7, 5)

      Text {
        text: root.dayNumber
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.height >= root.dp(85, 70) ? root.dp(24, 18) : root.dp(18, 14)
        font.bold: true
        color: Commons.Color.foreground
        maximumLineCount: 1
        elide: Text.ElideRight
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Text {
          Layout.fillWidth: true
          text: root.shortMonthYearText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 9)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          visible: root.height >= root.dp(60, 50)
          text: "Today · " + root.weekBadgeText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(8, 7)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.60)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }
  }
}
