pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons as Commons

// OmaDesk — WidgetTooltip
// Lightweight, accessible tooltip overlay for icon-only buttons and indicators.

Rectangle {
  id: root

  property alias text: label.text
  property bool active: false

  visible: opacity > 0.0
  opacity: root.active ? 1.0 : 0.0

  Behavior on opacity {
    NumberAnimation { duration: 140; easing.type: Easing.OutQuad }
  }

  implicitWidth: label.implicitWidth + 14
  implicitHeight: label.implicitHeight + 8
  radius: Math.max(3, Math.round(((Commons.Style && Commons.Style.cornerRadius) || 8) * 0.45))
  color: (Commons.Color && Commons.Color.background) ? Commons.Color.background : "#101315"
  border.color: Commons.Util.alpha(((Commons.Color && Commons.Color.foreground) || "#ffffff"), 0.22)
  border.width: (Commons.Style && Commons.Style.normalBorderWidth) || 1
  z: 1000

  Text {
    id: label
    anchors.centerIn: parent
    font.family: (Commons.Style && Commons.Style.fontFamily) || "monospace"
    font.pixelSize: 10
    font.bold: true
    color: (Commons.Color && Commons.Color.foreground) || "#ffffff"
  }
}
