pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — MinimalClockVariant
// Minimalist Typography Clock visual variant.
// Pure presentation delegate — no timers, no background processes.

Item {
  id: root
  anchors.fill: parent

  property real densityScale: 1.0
  property var currentDate: undefined
  property string hoursString: "--"
  property string minutesString: "--"

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  ColumnLayout {
    anchors.centerIn: parent
    spacing: 0

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: root.dp(4, 2)

      Text {
        text: root.hoursString
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(34, 20)
        font.bold: true
        color: Commons.Color.foreground
      }

      Text {
        text: ":"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(30, 18)
        font.bold: true
        color: Commons.Color.accent
      }

      Text {
        text: root.minutesString
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(34, 20)
        font.bold: true
        color: Commons.Color.accent
      }
    }

    Text {
      visible: root.height >= root.dp(50, 36) && root.currentDate !== undefined
      text: Qt.formatDate(root.currentDate, "ddd, MMM d")
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 8)
      font.bold: true
      color: Commons.Color.muted
      Layout.alignment: Qt.AlignHCenter
    }
  }
}
