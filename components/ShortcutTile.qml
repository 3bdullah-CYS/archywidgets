pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive
import "." as Components

// OmaDesk — ShortcutTile
// Shared, responsive tile delegate for folder and application grids.
// Top-left compact icon with horizontally centered label.
// Distinct layout responsibilities prevent icon/label overlap and clipping.

Rectangle {
  id: root

  property string iconText: ""
  property string labelText: ""
  property string subText: ""
  property string tooltipText: labelText + (subText ? (" · " + subText) : "")
  property real densityScale: 1.0
  property bool isRowMode: false  // true for 1-column vertical list mode
  property bool editMode: false
  property bool isAddTile: false

  signal clicked()
  signal deleteClicked()

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  function resolveIcon(rawIcon, fallback) {
    if (!rawIcon || typeof rawIcon !== "string") return fallback || "󰉋"
    var ic = rawIcon.trim()
    if (ic.length === 1 || (ic.length === 2 && ic.charCodeAt(0) >= 0xD800)) {
      return ic
    }
    switch (ic) {
      case "folder-home": return "󰋜"
      case "folder-download": return "󰉍"
      case "folder-documents": return "󰈙"
      case "folder-pictures": return "󰉏"
      case "folder-music": return "󰝚"
      case "folder-videos": return "󰕧"
      case "folder-development": return "󰲋"
      case "folder-config": return "󰒓"
      case "utilities-terminal": return "󰆍"
      case "web-browser": return "󰖟"
      case "text-editor": return "󰷈"
      case "system-file-manager": return "󰉋"
      case "file-document": return "󰈙"
      case "file-code": return "󰅪"
      case "file-image": return "󰉏"
      case "file-video": return "󰕧"
      case "file-audio": return "󰝚"
      default:
        var lower = ic.toLowerCase()
        if (lower.indexOf("folder") !== -1) return "󰉋"
        if (lower.indexOf("terminal") !== -1 || lower.indexOf("console") !== -1) return "󰆍"
        if (lower.indexOf("browser") !== -1 || lower.indexOf("firefox") !== -1 || lower.indexOf("chrome") !== -1) return "󰖟"
        if (lower.indexOf("edit") !== -1 || lower.indexOf("code") !== -1) return "󰷈"
        if (lower.indexOf("pdf") !== -1 || lower.indexOf("doc") !== -1 || lower.indexOf("txt") !== -1 || lower.indexOf("md") !== -1) return "󰈙"
        if (lower.indexOf("image") !== -1 || lower.indexOf("photo") !== -1 || lower.indexOf("png") !== -1 || lower.indexOf("jpg") !== -1) return "󰉏"
        if (lower.indexOf("music") !== -1 || lower.indexOf("audio") !== -1 || lower.indexOf("sound") !== -1) return "󰝚"
        if (lower.indexOf("video") !== -1 || lower.indexOf("movie") !== -1) return "󰕧"
        if (lower.indexOf("file") !== -1) return "󰈔"
        return fallback || "󰀻"
    }
  }

  readonly property string resolvedIcon: root.isAddTile ? "󰐕" : resolveIcon(root.iconText, root.isRowMode ? "󰉋" : "󰀻")

  radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
  color: root.isAddTile
    ? (cellHover.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.22) : Commons.Util.alpha(Commons.Color.accent, 0.08))
    : (cellHover.hovered
        ? Commons.Util.alpha(Commons.Color.accent, 0.18)
        : Commons.Util.alpha(Commons.Color.foreground, 0.05))
  border.color: root.isAddTile
    ? Commons.Color.accent
    : (cellHover.hovered
        ? Commons.Color.accent
        : Commons.Util.alpha(Commons.Color.foreground, 0.10))
  border.width: Commons.Style.normalBorderWidth || 1
  clip: true

  Accessible.role: Accessible.Button
  Accessible.name: root.tooltipText
  Accessible.description: root.subText

  HoverHandler {
    id: cellHover
    cursorShape: Qt.PointingHandCursor
  }

  TapHandler {
    id: cellTap
    gesturePolicy: TapHandler.ReleaseWithinBounds
    onTapped: {
      if (root.editMode && !root.isAddTile) return
      root.clicked()
    }
  }

  // Delete Control badge in Edit Mode (hidden on Add tile)
  Rectangle {
    id: delBtn
    visible: root.editMode && !root.isAddTile
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: root.dp(3, 2)
    anchors.rightMargin: root.dp(3, 2)
    width: root.dp(16, 14)
    height: width
    radius: width / 2
    color: delBtnHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.urgent, 0.25)
    border.color: Commons.Color.urgent
    border.width: 1
    z: 20

    HoverHandler { id: delBtnHov; cursorShape: Qt.PointingHandCursor }
    TapHandler {
      gesturePolicy: TapHandler.ReleaseWithinBounds
      onTapped: root.deleteClicked()
    }

    Text {
      anchors.centerIn: parent
      text: "✕"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(8, 7)
      font.bold: true
      color: delBtnHov.hovered ? "#ffffff" : Commons.Color.urgent
    }
  }

  // -------------------------------------------------------------
  // Mode A: 1-Column Row Mode (when container is vertical 1x2)
  // -------------------------------------------------------------
  RowLayout {
    id: rowLayout
    anchors.fill: parent
    anchors.leftMargin: root.dp(9, 7)
    anchors.rightMargin: root.dp(9, 7)
    anchors.topMargin: root.dp(4, 3)
    anchors.bottomMargin: root.dp(4, 3)
    spacing: root.dp(8, 6)
    visible: root.isRowMode

    Rectangle {
      Layout.preferredWidth: root.dp(26, 22)
      Layout.preferredHeight: root.dp(26, 22)
      radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
      color: cellHover.hovered
        ? Commons.Util.alpha(Commons.Color.accent, 0.24)
        : Commons.Util.alpha(Commons.Color.foreground, 0.08)

      Text {
        anchors.centerIn: parent
        text: root.resolvedIcon
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(14, 12)
        color: Commons.Color.accent
        maximumLineCount: 1
        elide: Text.ElideRight
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 1

      Text {
        Layout.fillWidth: true
        textFormat: Text.PlainText
        text: root.labelText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        font.bold: true
        color: Commons.Color.foreground
        maximumLineCount: 1
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        visible: Boolean(root.subText) && root.height >= root.dp(34, 28)
        textFormat: Text.PlainText
        text: root.subText
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.55)
        maximumLineCount: 1
        elide: Text.ElideRight
      }
    }

    Text {
      text: "󰅂"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(11, 10)
      color: cellHover.hovered
        ? Commons.Color.accent
        : Commons.Util.alpha(Commons.Color.foreground, 0.35)
      maximumLineCount: 1
      elide: Text.ElideRight
    }
  }

  // -------------------------------------------------------------
  // Mode B: Multi-Column Grid Tile Mode (2, 3, or 4 columns)
  // Responsive layout: Small top-left icon + Horizontally centered label
  // -------------------------------------------------------------

  // Top-Left Small Unobtrusive Icon
  Text {
    id: gridIcon
    visible: !root.isRowMode
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.topMargin: root.dp(5, 3)
    anchors.leftMargin: root.dp(6, 4)
    text: root.resolvedIcon
    font.family: Commons.Style.fontFamily
    font.pixelSize: (root.height < root.dp(40, 32) || root.width < root.dp(70, 55))
      ? root.dp(11, 9)
      : root.dp(13, 11)
    color: cellHover.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.85)
    maximumLineCount: 1
    elide: Text.ElideRight
    z: 2
  }

  // Horizontally Centered Content Area
  ColumnLayout {
    id: gridContentCol
    visible: !root.isRowMode
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter
    anchors.verticalCenterOffset: (root.height < root.dp(44, 36)) ? root.dp(2, 1) : 0
    width: Math.max(10, parent.width - root.dp(14, 10))
    spacing: 1
    z: 1

    // Main Centered Label
    Text {
      id: gridTitle
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      textFormat: Text.PlainText
      text: root.labelText
      font.family: Commons.Style.fontFamily
      font.pixelSize: (root.height < root.dp(36, 30) || root.width < root.dp(65, 50))
        ? root.dp(9, 8)
        : root.dp(10, 9)
      font.bold: true
      color: cellHover.hovered ? Commons.Color.foreground : Commons.Util.alpha(Commons.Color.foreground, 0.90)
      wrapMode: (root.height >= root.dp(46, 38) && root.width < root.dp(90, 70)) ? Text.Wrap : Text.NoWrap
      maximumLineCount: (root.height >= root.dp(46, 38) && !gridSub.visible) ? 2 : 1
      elide: Text.ElideRight
    }

    // Secondary Subtitle (Path / Command) - Only when space is generous
    Text {
      id: gridSub
      Layout.fillWidth: true
      horizontalAlignment: Text.AlignHCenter
      visible: Boolean(root.subText) && (root.height >= root.dp(56, 46))
      textFormat: Text.PlainText
      text: root.subText
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(9, 8)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.55)
      maximumLineCount: 1
      elide: Text.ElideRight
    }
  }

  // Hover Tooltip for complete label identification
  Components.WidgetTooltip {
    id: tileTooltip
    anchors.bottom: parent.top
    anchors.bottomMargin: 4
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.tooltipText
    active: cellHover.hovered && (gridTitle.truncated || (gridSub.visible && gridSub.truncated) || root.width < root.dp(85, 65))
    z: 100
  }
}
