pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — FlipCardsVariant
// Bento Segmented Flip Cards Clock visual variant.
// Pure presentation delegate — no timers, no background processes.

Item {
  id: root
  anchors.fill: parent

  property real densityScale: 1.0
  property string hoursString: "--"
  property string minutesString: "--"

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  RowLayout {
    anchors.centerIn: parent
    spacing: root.dp(6, 4)

    // Hour card
    Rectangle {
      Layout.preferredWidth: root.dp(46, 28)
      Layout.preferredHeight: root.dp(46, 28)
      radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.4))
      color: Commons.Util.alpha(Commons.Color.foreground, 0.08)
      border.color: Commons.Util.alpha(Commons.Color.foreground, 0.16)
      border.width: Commons.Style.normalBorderWidth

      Text {
        anchors.centerIn: parent
        text: root.hoursString
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(22, 14)
        font.bold: true
        color: Commons.Color.foreground
      }
    }

    // Colon divider dots
    ColumnLayout {
      spacing: root.dp(4, 2)
      Rectangle {
        width: root.dp(4, 3)
        height: width
        radius: width / 2
        color: Commons.Color.accent
      }
      Rectangle {
        width: root.dp(4, 3)
        height: width
        radius: width / 2
        color: Commons.Color.accent
      }
    }

    // Minute card
    Rectangle {
      Layout.preferredWidth: root.dp(46, 28)
      Layout.preferredHeight: root.dp(46, 28)
      radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.4))
      color: Commons.Util.alpha(Commons.Color.accent, 0.14)
      border.color: Commons.Util.alpha(Commons.Color.accent, 0.35)
      border.width: Commons.Style.normalBorderWidth

      Text {
        anchors.centerIn: parent
        text: root.minutesString
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(22, 14)
        font.bold: true
        color: Commons.Color.accent
      }
    }
  }
}
