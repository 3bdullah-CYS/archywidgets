pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — CalendarCardVariant
// Classic tear-off desk calendar card visual variant.
// Pure presentation delegate — zero timers, zero background processes, 100% reactive theme tokens.

Item {
  id: root
  anchors.fill: parent
  clip: true

  property real densityScale: 1.0
  property string dayNumber: "--"
  property string weekdayText: "Unavailable"
  property string shortWeekdayText: "---"
  property string monthText: ""
  property string shortMonthText: ""

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  // Outer Card Surface
  Rectangle {
    id: outerCard
    anchors.fill: parent
    radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.55))
    color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
    border.color: Commons.Util.alpha(Commons.Color.foreground, 0.12)
    border.width: 1

    // 1. Top Header Banner (solid accent bar with month name)
    Rectangle {
      id: headerBanner
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.topMargin: 1
      anchors.leftMargin: 1
      anchors.rightMargin: 1
      height: Math.max(root.dp(18, 14), Math.round(parent.height * 0.28))
      radius: Math.max(0, outerCard.radius - 1)
      color: Commons.Color.accent

      // Squared bottom to seal corners with card body
      Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.radius
        color: parent.color
      }

      Text {
        anchors.centerIn: parent
        anchors.leftMargin: root.dp(4, 2)
        anchors.rightMargin: root.dp(4, 2)
        text: (root.width >= root.dp(80, 60) ? root.monthText : root.shortMonthText).toUpperCase()
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(9, 7)
        font.bold: true
        color: Commons.Color.background
        maximumLineCount: 1
        elide: Text.ElideRight
      }
    }

    // 2. Card Body (Big day number + uppercase weekday)
    Item {
      anchors.top: headerBanner.bottom
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right

      ColumnLayout {
        anchors.centerIn: parent
        spacing: 0

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: root.dayNumber
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.height >= root.dp(85, 70) ? root.dp(28, 20) : root.dp(22, 16)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          visible: root.height >= root.dp(50, 42)
          text: (root.width >= root.dp(85, 65) ? root.weekdayText : root.shortWeekdayText).toUpperCase()
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(9, 7)
          font.bold: true
          color: Commons.Util.alpha(Commons.Color.foreground, 0.70)
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }
  }
}
