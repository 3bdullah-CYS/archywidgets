pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive
import "../TimeFoundation.js" as TimeFoundation

// OmaDesk — AnalogClockVariant
// Modern Geometric Vector Analog Clock visual variant.
// Pure presentation delegate — no timers, no background processes.

Item {
  id: root
  anchors.fill: parent

  property real densityScale: 1.0
  property var currentDate: undefined

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  readonly property var angles: TimeFoundation.getAnalogAngles(root.currentDate)
  readonly property real hoursAngle: angles.hoursAngle
  readonly property real minutesAngle: angles.minutesAngle

  Item {
    id: analogFace
    anchors.centerIn: parent
    width: Math.max(20, Math.min(root.width - root.dp(12, 6), root.height - root.dp(12, 6)))
    height: width

    readonly property real clockRadius: width / 2

    // Outer Dial
    Rectangle {
      anchors.fill: parent
      radius: analogFace.clockRadius
      color: Commons.Util.alpha(Commons.Color.foreground, 0.03)
      border.color: Commons.Util.alpha(Commons.Color.foreground, 0.16)
      border.width: Commons.Style.normalBorderWidth
    }

    // 12-Hour Markers
    Repeater {
      model: 12
      Item {
        id: markerItem
        required property int index
        anchors.fill: parent
        rotation: markerItem.index * 30
        Rectangle {
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.top: parent.top
          anchors.topMargin: root.dp(4, 2)
          width: (markerItem.index % 3 === 0) ? root.dp(3, 2) : root.dp(1.5, 1)
          height: (markerItem.index % 3 === 0) ? root.dp(7, 4) : root.dp(4, 2.5)
          radius: 1
          color: (markerItem.index % 3 === 0) ? Commons.Color.foreground : Commons.Color.muted
        }
      }
    }

    // Hour Hand
    Item {
      anchors.fill: parent
      rotation: root.hoursAngle
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        width: root.dp(3.5, 2.5)
        height: analogFace.clockRadius * 0.52
        radius: 2
        color: Commons.Color.foreground
      }
    }

    // Minute Hand
    Item {
      anchors.fill: parent
      rotation: root.minutesAngle
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.verticalCenter
        width: root.dp(2.5, 1.5)
        height: analogFace.clockRadius * 0.74
        radius: 1.5
        color: Commons.Color.accent
      }
    }

    // Center Pivot Pin
    Rectangle {
      width: root.dp(7, 5)
      height: width
      radius: width / 2
      anchors.centerIn: parent
      color: Commons.Color.accent
      border.color: Commons.Color.background
      border.width: 1.5
    }
  }
}
