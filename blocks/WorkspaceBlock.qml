pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive

// ArchyWidgets — WorkspaceBlock (Content-only block)
// Displays active workspace ID fed exclusively through shared dataHub.activeWorkspaceId.
// Read-only indicator: no TapHandler, shell dispatch, IPC, Timer, or Hyprland import.

Item {
  id: root
  clip: true

  required property var blockData
  required property var dataHub
  property string resolvedPresentation: "auto"
  property real densityScale: 1.0

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  readonly property string variant: (blockData && blockData.variant === "wide") ? "wide" : "compact"
  readonly property string presentation: root.resolvedPresentation !== "auto" ? root.resolvedPresentation : (root.variant === "wide" ? "detailed" : "compact")
  readonly property int activeWorkspaceId: {
    if (!root.dataHub || typeof root.dataHub.activeWorkspaceId !== "number") return -1
    const id = root.dataHub.activeWorkspaceId
    return (isFinite(id) && id > 0) ? Math.floor(id) : -1
  }
  readonly property bool available: root.activeWorkspaceId > 0

  // Compact Variant Layout (1x1)
  ColumnLayout {
    anchors.centerIn: parent
    visible: root.presentation === "compact"
    spacing: root.dp(2, 1)

    Text {
      text: "WS"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 10)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.70)
      Layout.alignment: Qt.AlignHCenter
      Layout.maximumWidth: Math.max(0, root.width - root.dp(8, 4))
      elide: Text.ElideRight
      maximumLineCount: 1
    }

    Text {
      text: root.available ? String(root.activeWorkspaceId) : "Unavailable"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.available ? root.dp(18, 12) : root.dp(11, 10)
      font.bold: true
      color: Commons.Color.foreground
      Layout.alignment: Qt.AlignHCenter
      Layout.maximumWidth: Math.max(0, root.width - root.dp(8, 4))
      elide: Text.ElideRight
      maximumLineCount: 1
    }
  }

  // Wide Variant Layout (2x1)
  RowLayout {
    anchors.centerIn: parent
    visible: root.presentation === "detailed"
    spacing: root.dp(10, 5)

    Rectangle {
      Layout.preferredWidth: root.dp(32, 20)
      Layout.preferredHeight: root.dp(32, 20)
      radius: root.dp(6, 3)
      color: Commons.Util.alpha(Commons.Color.accent, 0.15)

      Text {
        anchors.centerIn: parent
        text: "󰖲"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(16, 12)
        color: Commons.Color.accent
      }
    }

    ColumnLayout {
      spacing: root.dp(1, 1)
      Layout.maximumWidth: Math.max(0, root.width - root.dp(48, 30))

      Text {
        text: "Workspace"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(11, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.70)
        Layout.maximumWidth: Math.max(0, root.width - root.dp(48, 30))
        elide: Text.ElideRight
        maximumLineCount: 1
      }

      Text {
        text: root.available ? ("Workspace " + root.activeWorkspaceId) : "Unavailable"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(15, 11)
        font.bold: true
        color: Commons.Color.foreground
        Layout.maximumWidth: Math.max(0, root.width - root.dp(48, 30))
        elide: Text.ElideRight
        maximumLineCount: 1
      }
    }
  }

  Text {
    anchors.centerIn: parent
    visible: root.presentation === "icon"
    text: root.available ? String(root.activeWorkspaceId) : "󰖲"
    font.family: Commons.Style.fontFamily
    font.pixelSize: root.dp(18, 12)
    font.bold: true
    color: root.available ? Commons.Color.accent : Commons.Color.muted
  }
}
