pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons as Commons

// OmaDesk — BadgeTag
// Semantic status and category badge tag for containers and widgets.

Rectangle {
  id: root

  property alias text: tagLabel.text
  property color badgeColor: Commons.Color.accent

  implicitWidth: tagLabel.implicitWidth + 10
  implicitHeight: 18
  radius: Math.max(3, Math.round(((Commons.Style && Commons.Style.cornerRadius) || 8) * 0.40))

  color: Commons.Util.alpha(root.badgeColor, 0.12)
  border.color: Commons.Util.alpha(root.badgeColor, 0.25)
  border.width: 1

  Text {
    id: tagLabel
    anchors.centerIn: parent
    font.family: (Commons.Style && Commons.Style.fontFamily) || "monospace"
    font.pixelSize: 10
    font.bold: true
    color: root.badgeColor
  }
}
