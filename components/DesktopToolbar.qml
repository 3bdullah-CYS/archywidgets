pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons

// OmaDesk — DesktopToolbar
// Compact, unified single-action desktop entry point anchored to the bottom-right.
// Directly launches the unified layout studio and customization sidebar.

Rectangle {
  id: root

  signal editLayoutRequested()
  signal settingsRequested()

  implicitWidth: rowLayout.implicitWidth + 12
  implicitHeight: 30
  radius: Math.max(5, Math.round(((Commons.Style && Commons.Style.cornerRadius) || 8) * 0.55))

  color: Commons.Util.alpha(Commons.Color.background, 0.70)
  border.color: Commons.Util.alpha(Commons.Color.foreground, 0.14)
  border.width: (Commons.Style && Commons.Style.normalBorderWidth) || 1
  z: 150

  RowLayout {
    id: rowLayout
    anchors.centerIn: parent
    spacing: 4

    IconButton {
      id: editBtn
      icon: "󱗼"
      tooltipText: "Customize Desktop"
      accessibleName: "Customize Desktop"
      iconPixelSize: 13
      implicitWidth: 24
      implicitHeight: 24
      onClicked: {
        root.editLayoutRequested()
        root.settingsRequested()
      }
    }
  }
}
