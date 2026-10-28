pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons as Commons

// OmaDesk — IconButton
// Compact, accessible, theme-reactive icon button for toolbars and widgets.

Rectangle {
  id: root

  property alias icon: iconText.text
  property string tooltipText: ""
  property alias iconPixelSize: iconText.font.pixelSize
  property alias iconColor: iconText.color
  property bool active: false
  property string accessibleName: ""

  signal clicked()

  implicitWidth: 28
  implicitHeight: 28
  radius: Math.max(4, Math.round(((Commons.Style && Commons.Style.cornerRadius) || 8) * 0.55))

  readonly property bool isHovered: hoverHandler.hovered
  readonly property bool isPressed: tapHandler.pressed

  color: root.isPressed
    ? Commons.Util.alpha(Commons.Color.accent, 0.28)
    : (root.isHovered || root.active
      ? Commons.Util.alpha(Commons.Color.accent, 0.16)
      : "transparent")

  border.color: (root.isHovered || root.active)
    ? Commons.Util.alpha(Commons.Color.accent, 0.40)
    : (root.activeFocus ? Commons.Color.accent : "transparent")

  border.width: (Commons.Style && Commons.Style.normalBorderWidth) || 1

  HoverHandler {
    id: hoverHandler
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    id: tapHandler
    gesturePolicy: TapHandler.ReleaseWithinBounds
    onTapped: root.clicked()
  }

  Accessible.role: Accessible.Button
  Accessible.name: root.accessibleName ? root.accessibleName : root.tooltipText
  Accessible.description: root.tooltipText

  Text {
    id: iconText
    anchors.centerIn: parent
    font.family: (Commons.Style && Commons.Style.fontFamily) || "monospace"
    font.pixelSize: 13
    color: (root.isHovered || root.active)
      ? Commons.Color.accent
      : Commons.Color.foreground
  }

  WidgetTooltip {
    id: tooltip
    anchors.bottom: parent.top
    anchors.bottomMargin: 6
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.tooltipText
    active: root.isHovered && root.tooltipText.length > 0
  }
}
