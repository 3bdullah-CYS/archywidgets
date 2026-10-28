pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive
import "../components" as Components

// ArchyWidgets — AppGridBlock
// Pure presentation leaf for application launcher grids.
// Smart Aspect-Ratio Grid System with responsive ShortcutTile delegates:
// - Tall (1x2, height > width * 1.15): 1 column, items stacked vertically in full-width rows
// - Square (1x1): 2 columns (2x2 grid)
// - Wide / Large (2x1, 2x2): 3 to 4 columns with automatic row wrapping underneath
// Zero Process, Timer, FileView, or IPC inside the block.

Item {
  id: root

  required property var blockData
  required property var dataHub
  property var actionHub: null
  property string resolvedPresentation: "auto"
  property real densityScale: 1.0
  property bool editMode: false

  signal itemAddRequested()
  signal itemRemoveRequested(string itemId)

  clip: true

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  readonly property string variant: (root.blockData && typeof root.blockData.variant === "string") ? root.blockData.variant : "compact"
  readonly property string presentation: {
    var mode = root.resolvedPresentation
    if (!mode || mode === "auto") {
      if (root.width >= root.dp(220, 180) && root.height >= root.dp(135, 110)) return "dashboard"
      return root.variant === "wide" ? "detailed" : "compact"
    }
    return mode
  }
  // Smart Aspect-Ratio Grid Columns & Dynamic Capacity
  readonly property bool isTallLayout: root.height > root.width * 1.15
  readonly property int gridColumns: {
    if (root.isTallLayout) return 1
    if (root.width >= root.dp(400, 320)) return 5
    if (root.width >= root.dp(300, 240)) return 4
    if (root.width >= root.dp(200, 160) || root.variant === "wide") return 3
    return 2
  }
  readonly property int gridRows: Math.max(1, Math.floor((root.height + root.dp(6, 4)) / root.dp(38, 28)))
  readonly property int maxCapacity: Math.max(4, root.gridColumns * root.gridRows)

  readonly property var itemsModel: {
    var settings = (root.blockData && root.blockData.settings && typeof root.blockData.settings === "object") ? root.blockData.settings : null
    if (!settings || !settings.items) return []
    var raw = Array.isArray(settings.items) ? settings.items : (typeof settings.items.length === "number" ? Array.prototype.slice.call(settings.items) : [])
    return raw.slice(0, Math.max(root.maxCapacity, raw.length))
  }

  readonly property var displayItems: {
    var list = root.itemsModel.slice()
    if (root.editMode) {
      list.push({
        id: "__add_app_tile__",
        isAddTile: true,
        name: "+ Add App",
        icon: "󰐕",
        sub: "Add shortcut"
      })
    }
    return list
  }

  // Empty fallback state (shown only when not in editMode and no apps configured)
  Rectangle {
    anchors.fill: parent
    visible: root.displayItems.length === 0
    radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.55))
    color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
    border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
    border.width: 1

    Text {
      anchors.centerIn: parent
      text: "No Apps Configured"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 10)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.55)
      maximumLineCount: 1
      elide: Text.ElideRight
    }
  }

  GridLayout {
    anchors.fill: parent
    visible: root.displayItems.length > 0
    columns: root.gridColumns
    rowSpacing: root.dp(6, 4)
    columnSpacing: root.dp(6, 4)

    Repeater {
      model: root.displayItems

      Components.ShortcutTile {
        id: appCell
        required property var modelData
        required property int index
        Layout.fillWidth: true
        Layout.fillHeight: true
        densityScale: root.densityScale
        isRowMode: root.gridColumns === 1
        editMode: root.editMode
        isAddTile: Boolean(appCell.modelData && appCell.modelData.isAddTile)
        iconText: (appCell.modelData && appCell.modelData.icon) ? String(appCell.modelData.icon) : "󰀻"
        labelText: (appCell.modelData && appCell.modelData.name) ? String(appCell.modelData.name) : "App"
        subText: (appCell.modelData && appCell.modelData.sub)
          ? String(appCell.modelData.sub)
          : ((appCell.modelData && appCell.modelData.command) ? String(appCell.modelData.command) : "Launch")

        onClicked: {
          if (appCell.modelData && appCell.modelData.isAddTile) {
            root.itemAddRequested()
            return
          }
          if (root.editMode) return
          var cmd = (appCell.modelData && typeof appCell.modelData.command === "string") ? appCell.modelData.command.trim() : ""
          if (cmd && root.actionHub && typeof root.actionHub.launchApp === "function") {
            root.actionHub.launchApp(cmd)
          }
        }

        onDeleteClicked: {
          var itId = (appCell.modelData && appCell.modelData.id) ? appCell.modelData.id : ((appCell.modelData && appCell.modelData.command) ? appCell.modelData.command : appCell.modelData.name)
          root.itemRemoveRequested(String(itId))
        }
      }
    }
  }
}
