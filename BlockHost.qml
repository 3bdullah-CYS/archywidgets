pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "blocks" as Blocks
import "ResponsiveMetrics.js" as Responsive
import "BlockRegistry.js" as BlockRegistry

// ArchyWidgets — BlockHost
// Stable component dispatcher for composable blocks.
// Uses exactly one Loader with a hardcoded allowlist for supported kinds.
// Content and telemetry updates never change Loader.sourceComponent.

Item {
  id: root

  required property var blockData
  required property var dataHub
  property var actionHub: null
  property string resolvedPresentation: "auto"
  property bool editMode: false
  property bool previewMode: false
  property real densityScale: 1.0

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  property bool isSelected: false
  signal selected()
  signal variantRequested(string variant)
  signal moveRequested(var targetSlot)
  signal removeRequested()
  signal itemAddRequested()
  signal itemRemoveRequested(string itemId)

  // Hardcoded Component definitions for supported block kinds
  Component {
    id: timeComponent
    Blocks.TimeBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
    }
  }

  Component {
    id: metricComponent
    Blocks.MetricBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      actionHub: root.actionHub
      editMode: root.editMode
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
    }
  }

  Component {
    id: dateComponent
    Blocks.DateBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
    }
  }

  Component {
    id: workspaceComponent
    Blocks.WorkspaceBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
    }
  }

  Component {
    id: networkComponent
    Blocks.NetworkBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
    }
  }

  Component {
    id: batteryComponent
    Blocks.BatteryBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
    }
  }

  Component {
    id: appGridComponent
    Blocks.AppGridBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      actionHub: root.actionHub
      editMode: root.editMode
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
      onItemAddRequested: root.itemAddRequested()
      onItemRemoveRequested: function(itemId) { root.itemRemoveRequested(itemId) }
    }
  }

  Component {
    id: folderGridComponent
    Blocks.FolderGridBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      actionHub: root.actionHub
      editMode: root.editMode
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
      onItemAddRequested: root.itemAddRequested()
      onItemRemoveRequested: function(itemId) { root.itemRemoveRequested(itemId) }
    }
  }

  Component {
    id: fanControlComponent
    Blocks.FanControlBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      actionHub: root.actionHub
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
    }
  }

  Component {
    id: sysInfoComponent
    Blocks.SystemInfoBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
    }
  }

  Component {
    id: todoComponent
    Blocks.TodoBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      actionHub: root.actionHub
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
    }
  }

  Component {
    id: notificationsComponent
    Blocks.NotificationBlock {
      anchors.fill: parent
      blockData: root.blockData
      dataHub: root.dataHub
      actionHub: root.actionHub
      resolvedPresentation: root.resolvedPresentation
      densityScale: root.densityScale
    }
  }

  Component {
    id: unsupportedComponent
    Rectangle {
      anchors.fill: parent
      color: Commons.Util.alpha(Commons.Color.background, 0.40)
      border.color: Commons.Util.alpha(Commons.Color.foreground, 0.20)
      border.width: 1
      radius: Commons.Style.cornerRadius

      Text {
        anchors.centerIn: parent
        text: "Unsupported (" + ((root.blockData && root.blockData.kind) ? root.blockData.kind : "?") + ")"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(11, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.60)
      }
    }
  }

  // Single stable Loader dispatched only on blockData.kind
  Loader {
    id: blockLoader
    anchors.fill: parent
    clip: true
    sourceComponent: {
      var kind = (root.blockData && typeof root.blockData.kind === "string") ? root.blockData.kind : ""
      if (kind === "time") return timeComponent
      if (kind === "metric") return metricComponent
      if (kind === "date") return dateComponent
      if (kind === "workspace") return workspaceComponent
      if (kind === "network") return networkComponent
      if (kind === "battery") return batteryComponent
      if (kind === "app-grid") return appGridComponent
      if (kind === "folder-grid") return folderGridComponent
      if (kind === "fan-control") return fanControlComponent
      if (kind === "sys-info") return sysInfoComponent
      if (kind === "todo") return todoComponent
      if (kind === "notifications") return notificationsComponent
      return unsupportedComponent
    }
  }

  readonly property string blockKind: (root.blockData && typeof root.blockData.kind === "string") ? root.blockData.kind : ""
  readonly property string currentVariant: (root.blockData && typeof root.blockData.variant === "string") ? root.blockData.variant : "compact"
  readonly property var supportedVariants: BlockRegistry.variants(root.blockKind)
  readonly property bool hasMultipleVariants: Boolean(root.supportedVariants && root.supportedVariants.length > 1)

  // Edit / selection feedback overlay
  Rectangle {
    id: editHighlight
    anchors.fill: parent
    visible: root.editMode
    color: root.isSelected
      ? Commons.Util.alpha(Commons.Color.accent, 0.12)
      : (tapHandler.pressed ? Commons.Util.alpha(Commons.Color.accent, 0.08) : "transparent")
    border.color: root.isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.25)
    border.width: root.isSelected ? root.dp(2, 1.5) : root.dp(1, 1)
    radius: 3
    z: 10

    // Direct On-Widget Variant Quick Switcher (appears only when selected)
    Rectangle {
      id: onWidgetSwitcher
      visible: root.editMode && root.isSelected && root.hasMultipleVariants
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.margins: 2
      height: root.dp(18, 16)
      implicitWidth: switcherRow.implicitWidth + 8
      radius: 3
      color: Commons.Util.alpha(Commons.Color.background, 0.92)
      border.color: Commons.Color.accent
      border.width: 1
      z: 30

      RowLayout {
        id: switcherRow
        anchors.centerIn: parent
        spacing: 2

        // Previous variant button (<)
        Rectangle {
          Layout.preferredWidth: root.dp(14, 12)
          Layout.preferredHeight: root.dp(14, 12)
          radius: 2
          color: prevHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.3) : "transparent"

          HoverHandler { id: prevHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: {
              var vars = root.supportedVariants
              var curIdx = -1
              for (var i = 0; i < vars.length; i++) {
                if (vars[i].variant === root.currentVariant) { curIdx = i; break; }
              }
              var nextIdx = (curIdx <= 0) ? (vars.length - 1) : (curIdx - 1)
              root.variantRequested(vars[nextIdx].variant)
            }
          }

          Text {
            anchors.centerIn: parent
            text: "‹"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(12, 10)
            font.bold: true
            color: Commons.Color.accent
          }
        }

        // Current variant indicator
        Text {
          text: {
            for (var i = 0; i < root.supportedVariants.length; i++) {
              if (root.supportedVariants[i].variant === root.currentVariant) {
                return (root.supportedVariants[i].icon ? (root.supportedVariants[i].icon + " ") : "") + root.supportedVariants[i].label
              }
            }
            return root.currentVariant
          }
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(9, 8)
          font.bold: true
          color: Commons.Color.foreground
          Layout.maximumWidth: root.dp(90, 60)
          elide: Text.ElideRight
        }

        // Next variant button (>)
        Rectangle {
          Layout.preferredWidth: root.dp(14, 12)
          Layout.preferredHeight: root.dp(14, 12)
          radius: 2
          color: nextHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.3) : "transparent"

          HoverHandler { id: nextHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: {
              var vars = root.supportedVariants
              var curIdx = -1
              for (var i = 0; i < vars.length; i++) {
                if (vars[i].variant === root.currentVariant) { curIdx = i; break; }
              }
              var nextIdx = (curIdx >= vars.length - 1) ? 0 : (curIdx + 1)
              root.variantRequested(vars[nextIdx].variant)
            }
          }

          Text {
            anchors.centerIn: parent
            text: "›"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(12, 10)
            font.bold: true
            color: Commons.Color.accent
          }
        }
      }
    }

    Rectangle {
      id: blockRemoveBtn
      visible: root.editMode
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.margins: 2
      width: root.dp(16, 14)
      height: root.dp(16, 14)
      radius: 3
      color: blockRemoveHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.background, 0.85)
      border.color: blockRemoveHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.urgent, 0.5)
      border.width: 1
      z: 20

      HoverHandler { id: blockRemoveHov; cursorShape: Qt.PointingHandCursor }
      TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.removeRequested()
      }

      Text {
        anchors.centerIn: parent
        text: "󰅖"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(9, 8)
        color: blockRemoveHov.hovered ? Commons.Color.background : Commons.Color.urgent
      }
    }
  }

  TapHandler {
    id: tapHandler
    enabled: root.editMode
    gesturePolicy: TapHandler.ReleaseWithinBounds
    onTapped: root.selected()
  }
}
