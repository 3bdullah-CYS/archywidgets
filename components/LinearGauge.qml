pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons as Commons

// OmaDesk — LinearGauge
// Lightweight, reactive linear metric indicator for CPU, RAM, Disk, and Battery.

Item {
  id: root

  property real value: 0.0 // 0.0 to 1.0 or 0 to 100
  property real maxValue: 100.0
  property color gaugeColor: Commons.Color.accent
  property real trackAlpha: 0.10
  property real gaugeHeight: 4

  readonly property real normalizedValue: Math.max(0.0, Math.min(1.0, root.maxValue > 0 ? (root.value / root.maxValue) : 0.0))

  implicitWidth: 120
  implicitHeight: root.gaugeHeight

  Rectangle {
    id: track
    anchors.fill: parent
    radius: Math.round(parent.height / 2)
    color: Commons.Util.alpha(Commons.Color.foreground, root.trackAlpha)

    Rectangle {
      id: fillBar
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: Math.round(parent.width * root.normalizedValue)
      radius: Math.round(parent.height / 2)
      color: root.gaugeColor

      Behavior on width {
        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
      }
    }
  }
}
