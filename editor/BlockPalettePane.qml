pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../BlockRegistry.js" as BlockRegistry
import "../components" as Components

// ArchyWidgets — BlockPalettePane
// Domain-scoped block toggle & tuning panel.
// Shows only blocks belonging to the selected container domain as direct Show or Hide toggles,
// plus active block ordering and footprint variant selectors.

Rectangle {
  id: root

  required property var selectedContainer
  required property string selectedBlockId

  signal blockSelected(string id)
  signal addBlockRequested(string kind, string variant, string source)
  signal removeBlockRequested(string id)
  signal moveBlockRequested(string id, int direction)
  signal variantRequested(string id, string variant)
  signal expandAndApplyRequested(string containerId, string blockId, string variant)
  signal settingsUpdateRequested(string id, var nextSettings)

  color: Commons.Util.alpha(Commons.Color.background, 0.40)
  border.color: Commons.Util.alpha(Commons.Color.foreground, 0.12)
  border.width: Commons.Style.normalBorderWidth
  radius: Commons.Style.cornerRadius
  clip: true

  readonly property var blockList: (root.selectedContainer && Array.isArray(root.selectedContainer.blocks)) ? root.selectedContainer.blocks : []
  readonly property string containerDomain: BlockRegistry.inferContainerDomain(root.selectedContainer)
  readonly property var domainMeta: BlockRegistry.containerDomain(root.containerDomain)
  property bool showAllBlocks: true

  readonly property var activeSelectedBlock: {
    if (!root.selectedBlockId) return null
    for (let i = 0; i < root.blockList.length; i++) {
      if (root.blockList[i] && root.blockList[i].id === root.selectedBlockId) {
        return root.blockList[i]
      }
    }
    return null
  }

  function getBlockIcon(b) {
    if (!b) return "󰍛"
    if (b.kind === "time") return "󰥔"
    if (b.kind === "date") return "󰃭"
    if (b.kind === "workspace") return "󰖲"
    if (b.kind === "network") return "󰤨"
    if (b.kind === "battery") return "󰁹"
    if (b.kind === "fan-control") return "󰈐"
    if (b.kind === "app-grid") return "󰅩"
    if (b.kind === "folder-grid") return "󰉋"
    if (b.kind === "sys-info") return "󰌽"
    if (b.kind === "todo") return "󰄲"
    if (b.kind === "notifications") return "󰂚"
    if (b.source === "cpu.percent") return "󰍛"
    if (b.source === "ram.percent") return "󰘚"
    if (b.source === "disk.percent" || b.source === "disk.hdd") return "󰋊"
    if (b.source && b.source.indexOf("temperature") !== -1) return "󰔏"
    if (b.source === "network.download") return "󰇚"
    if (b.source === "network.upload") return "󰕒"
    return "󰍛"
  }

  function getBlockTitle(b) {
    if (!b) return "Block"
    if (b.kind === "time") return "Clock"
    if (b.kind === "date") return "Date"
    if (b.kind === "workspace") return "Workspace"
    if (b.kind === "network") return "Network"
    if (b.kind === "battery") return "Battery"
    if (b.kind === "fan-control") return "Fan Controls"
    if (b.kind === "app-grid") return "App Grid"
    if (b.kind === "folder-grid") return "Folder Grid"
    if (b.kind === "sys-info") return "System Identity"
    if (b.kind === "todo") return "Todo List"
    if (b.kind === "notifications") return "Notifications"
    if (b.source === "cpu.percent") return "CPU Usage"
    if (b.source === "ram.percent") return "Memory Usage"
    if (b.source === "disk.percent") return "Storage Usage"
    if (b.source === "disk.hdd") return "HDD Storage"
    if (b.source === "temperature.cpu") return "CPU Temp"
    if (b.source === "temperature.gpu") return "GPU Temp"
    if (b.source === "temperature.nvme") return "NVMe Temp"
    if (b.source === "temperature.hdd") return "HDD Temp"
    if (b.source === "network.download") return "Network Down"
    if (b.source === "network.upload") return "Network Up"
    if (b.source === "fan.mode") return "Fan Mode"
    return b.source || b.kind || "Block"
  }

  function findActiveBlockId(kind, source) {
    const normSrc = (typeof source === "string") ? source.trim() : ""
    for (let i = 0; i < root.blockList.length; i++) {
      const b = root.blockList[i]
      if (!b || b.kind !== kind) continue
      if (kind === "metric") {
        if (String(b.source || "").trim() === normSrc) {
          return String(b.id || "")
        }
      } else {
        return String(b.id || "")
      }
    }
    return ""
  }

  function findActiveBlock(kind, source) {
    const normSrc = (typeof source === "string") ? source.trim() : ""
    for (let i = 0; i < root.blockList.length; i++) {
      const b = root.blockList[i]
      if (!b || b.kind !== kind) continue
      if (kind === "metric") {
        if (String(b.source || "").trim() === normSrc) {
          return b
        }
      } else {
        return b
      }
    }
    return null
  }

  function findActiveGridBlock() {
    if (root.selectedBlockId) {
      for (let i = 0; i < root.blockList.length; i++) {
        const b = root.blockList[i]
        if (b && b.id === root.selectedBlockId && (b.kind === "app-grid" || b.kind === "folder-grid")) {
          return b
        }
      }
    }
    for (let i = 0; i < root.blockList.length; i++) {
      const b = root.blockList[i]
      if (b && (b.kind === "app-grid" || b.kind === "folder-grid")) {
        return b
      }
    }
    return null
  }

  function findGridBlock(kind) {
    if (root.selectedBlockId) {
      for (let i = 0; i < root.blockList.length; i++) {
        const b = root.blockList[i]
        if (b && b.id === root.selectedBlockId && b.kind === kind) {
          return b
        }
      }
    }
    for (let i = 0; i < root.blockList.length; i++) {
      const b = root.blockList[i]
      if (b && b.kind === kind) {
        return b
      }
    }
    return null
  }

  function addShortcutItem(kind, itemObj) {
    var gb = root.findGridBlock(kind)
    if (!gb) {
      root.addBlockRequested(kind, "compact", "")
      return
    }
    if (!itemObj.id) {
      itemObj.id = (kind === "app-grid" ? "app_" : "folder_") + Date.now().toString(36) + "_" + Math.random().toString(36).substr(2, 5)
    }
    var items = (gb.settings && Array.isArray(gb.settings.items)) ? gb.settings.items.slice() : []
    items.push(itemObj)
    root.settingsUpdateRequested(gb.id, { items: items })
  }

  // Canonical working metric sources
  readonly property var enabledMetricSources: [
    { source: "cpu.percent", label: "CPU Usage", subtitle: "Processor load & hardware model", icon: "󰍛" },
    { source: "ram.percent", label: "Memory Usage", subtitle: "RAM utilization & used/total GB", icon: "󰘚" },
    { source: "disk.percent", label: "Storage Usage", subtitle: "Filesystem capacity & disk usage", icon: "󰋊" },
    { source: "disk.hdd", label: "HDD Storage", subtitle: "Secondary drive capacity & usage", icon: "󰋊" },
    { source: "temperature.cpu", label: "CPU Temp", subtitle: "Processor package thermal sensor", icon: "󰔏" },
    { source: "temperature.gpu", label: "GPU Temp", subtitle: "Graphics core thermal sensor", icon: "󰔏" },
    { source: "temperature.nvme", label: "NVMe Temp", subtitle: "Solid-state drive thermal sensor", icon: "󰔏" },
    { source: "temperature.hdd", label: "HDD Temp", subtitle: "Secondary storage thermal sensor", icon: "󰔏" },
    { source: "network.download", label: "Network Down", subtitle: "Dedicated live download speed gauge", icon: "󰇚" },
    { source: "network.upload", label: "Network Up", subtitle: "Dedicated live upload speed gauge", icon: "󰕒" },
    { source: "fan.mode", label: "Fan Mode", subtitle: "Active cooling mode readout", icon: "󰈐" }
  ]

  readonly property var enabledGridKinds: [
    { kind: "app-grid", label: "Applications", icon: "󰅩" },
    { kind: "folder-grid", label: "Folders", icon: "󰉋" }
  ]
  readonly property var disabledFutureKinds: []

  Flickable {
    anchors.fill: parent
    anchors.margins: 12
    contentHeight: mainCol.implicitHeight
    clip: true

    ColumnLayout {
      id: mainCol
      width: parent.width
      spacing: 10

      // =================================================================
      // Domain Identity Header Card
      // =================================================================
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 54
        radius: Math.max(5, Math.round(Commons.Style.cornerRadius * 0.55))
        color: Commons.Util.alpha(Commons.Color.accent, 0.10)
        border.color: Commons.Util.alpha(Commons.Color.accent, 0.28)
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 10

          Rectangle {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            radius: 6
            color: Commons.Util.alpha(Commons.Color.accent, 0.18)
            border.color: Commons.Util.alpha(Commons.Color.accent, 0.35)
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: (root.domainMeta && root.domainMeta.icon) ? root.domainMeta.icon : "󰍛"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 15
              color: Commons.Color.accent
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                Layout.fillWidth: true
                text: ((root.domainMeta && root.domainMeta.title) ? root.domainMeta.title : "Container") + " Blocks"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 12
                font.bold: true
                color: Commons.Color.foreground
                elide: Text.ElideRight
              }

              Rectangle {
                Layout.preferredHeight: 16
                implicitWidth: domTag.implicitWidth + 8
                radius: 3
                color: Commons.Util.alpha(Commons.Color.accent, 0.18)

                Text {
                  id: domTag
                  anchors.centerIn: parent
                  text: (root.domainMeta && root.domainMeta.shortLabel) ? root.domainMeta.shortLabel : "Scoped"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 10
                  font.bold: true
                  color: Commons.Color.accent
                }
              }
            }

            Text {
              Layout.fillWidth: true
              text: (root.domainMeta && root.domainMeta.description) ? root.domainMeta.description : "Toggle blocks dedicated to this container."
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: Commons.Color.muted
              elide: Text.ElideRight
            }
          }
        }
      }

      // =================================================================
      // Pinned Active Widget Inspector
      // Appears prominently at the top when a widget is selected.
      // Shows current variant, visual mini-previews of all alternatives,
      // fit/sizing requirements, and "Expand & Apply" action.
      // =================================================================
      Rectangle {
        id: selectedBlockInspector
        visible: Boolean(root.activeSelectedBlock)
        Layout.fillWidth: true
        implicitHeight: inspectorCol.implicitHeight + 20
        radius: Commons.Style.cornerRadius
        color: Commons.Util.alpha(Commons.Color.accent, 0.12)
        border.color: Commons.Color.accent
        border.width: 1.5

        ColumnLayout {
          id: inspectorCol
          anchors.fill: parent
          anchors.margins: 10
          spacing: 8

          // Inspector Header: Icon, Name, Current Variant Badge, Deselect
          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              radius: 5
              color: Commons.Util.alpha(Commons.Color.accent, 0.25)
              border.color: Commons.Color.accent
              border.width: 1

              Text {
                anchors.centerIn: parent
                text: root.getBlockIcon(root.activeSelectedBlock)
                font.family: Commons.Style.fontFamily
                font.pixelSize: 14
                color: Commons.Color.accent
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                  text: root.getBlockTitle(root.activeSelectedBlock)
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 12
                  font.bold: true
                  color: Commons.Color.foreground
                }

                Rectangle {
                  Layout.preferredHeight: 18
                  implicitWidth: activeVariantBadgeText.implicitWidth + 8
                  radius: 3
                  color: Commons.Color.accent

                  Text {
                    id: activeVariantBadgeText
                    anchors.centerIn: parent
                    text: root.activeSelectedBlock ? (root.activeSelectedBlock.variant || "compact").toUpperCase() : ""
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                    color: Commons.Color.background
                  }
                }
              }

              Text {
                text: "Select a visual variant below or tune its layout"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
              }
            }

            // Deselect Button
            Rectangle {
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              radius: 4
              color: deselectHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.15) : "transparent"
              border.color: Commons.Util.alpha(Commons.Color.foreground, 0.20)
              border.width: 1

              HoverHandler { id: deselectHov; cursorShape: Qt.PointingHandCursor }
              TapHandler {
                onTapped: root.blockSelected("")
              }

              Text {
                anchors.centerIn: parent
                text: "✕"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 11
                color: Commons.Color.foreground
              }
            }
          }

          // Visual Variant Cards Grid
          GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
              model: root.activeSelectedBlock ? BlockRegistry.variants(root.activeSelectedBlock.kind) : []

              delegate: Rectangle {
                id: variantCardDelegate
                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.preferredHeight: 82
                radius: 5

                readonly property bool isCurrent: Boolean(root.activeSelectedBlock && root.activeSelectedBlock.variant === variantCardDelegate.modelData.variant)
                readonly property var fp: BlockRegistry.footprint(root.activeSelectedBlock.kind, variantCardDelegate.modelData.variant)
                readonly property int cCols: (root.selectedContainer && root.selectedContainer.colSpan) ? (root.selectedContainer.colSpan * 2) : 2
                readonly property int cRows: (root.selectedContainer && root.selectedContainer.rowSpan) ? (root.selectedContainer.rowSpan * 2) : 2
                readonly property bool needsExpand: Boolean(variantCardDelegate.fp && (variantCardDelegate.fp.colSpan > variantCardDelegate.cCols || variantCardDelegate.fp.rowSpan > variantCardDelegate.cRows || ((root.selectedContainer && root.selectedContainer.colSpan === 1) && (variantCardDelegate.fp.colSpan > 1 || variantCardDelegate.modelData.variant === "wide" || variantCardDelegate.modelData.variant === "cards"))))

                color: variantCardDelegate.isCurrent
                  ? Commons.Util.alpha(Commons.Color.accent, 0.22)
                  : (vHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.10) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
                border.color: variantCardDelegate.isCurrent
                  ? Commons.Color.accent
                  : (vHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.5) : Commons.Util.alpha(Commons.Color.foreground, 0.15))
                border.width: variantCardDelegate.isCurrent ? 2 : 1

                HoverHandler { id: vHov; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                  enabled: !variantCardDelegate.isCurrent && !variantCardDelegate.needsExpand
                  onTapped: {
                    root.variantRequested(root.activeSelectedBlock.id, variantCardDelegate.modelData.variant)
                  }
                }

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 6
                  spacing: 4

                  // Top info row with mini-preview thumbnail
                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Mini-preview thumbnail box
                    Rectangle {
                      Layout.preferredWidth: 34
                      Layout.preferredHeight: 32
                      radius: 4
                      color: Commons.Util.alpha(Commons.Color.background, 0.70)
                      border.color: Commons.Util.alpha(Commons.Color.foreground, 0.15)
                      border.width: 1
                      clip: true

                      // 1. Analog mini preview
                      Item {
                        anchors.fill: parent
                        visible: variantCardDelegate.modelData.variant === "analog"

                        Rectangle {
                          anchors.centerIn: parent
                          width: 22
                          height: 22
                          radius: 11
                          color: "transparent"
                          border.color: Commons.Color.accent
                          border.width: 1

                          Rectangle {
                            x: 10; y: 6; width: 1.5; height: 5
                            color: Commons.Color.foreground
                            antialiasing: true
                          }
                          Rectangle {
                            x: 10; y: 10; width: 5; height: 1.5
                            color: Commons.Color.accent
                            antialiasing: true
                          }
                        }
                      }

                      // 2. Flip Cards mini preview
                      Row {
                        anchors.centerIn: parent
                        spacing: 2
                        visible: variantCardDelegate.modelData.variant === "cards"

                        Rectangle {
                          width: 10; height: 16; radius: 2
                          color: Commons.Util.alpha(Commons.Color.accent, 0.35)
                          border.color: Commons.Color.accent
                          border.width: 0.5
                          Text { anchors.centerIn: parent; text: "1"; font.pixelSize: 8; font.bold: true; color: Commons.Color.foreground }
                        }
                        Rectangle {
                          width: 10; height: 16; radius: 2
                          color: Commons.Util.alpha(Commons.Color.accent, 0.35)
                          border.color: Commons.Color.accent
                          border.width: 0.5
                          Text { anchors.centerIn: parent; text: "2"; font.pixelSize: 8; font.bold: true; color: Commons.Color.foreground }
                        }
                      }

                      // 3. Digital Clock / Minimal mini preview
                      Text {
                        anchors.centerIn: parent
                        visible: variantCardDelegate.modelData.variant === "digital" || variantCardDelegate.modelData.variant === "minimal" || (variantCardDelegate.modelData.variant === "compact" && root.activeSelectedBlock.kind === "time")
                        text: "12:00"
                        font.family: Commons.Style.fontFamily
                        font.pixelSize: variantCardDelegate.modelData.variant === "minimal" ? 7 : 8
                        font.bold: variantCardDelegate.modelData.variant !== "minimal"
                        color: Commons.Color.foreground
                      }

                      // 4. Bar Gauge mini preview
                      Column {
                        anchors.centerIn: parent
                        spacing: 3
                        visible: variantCardDelegate.modelData.variant === "bar"

                        Row {
                          spacing: 3
                          Rectangle { width: 14; height: 3; radius: 1; color: Commons.Color.accent }
                          Text { text: "65%"; font.pixelSize: 6; color: Commons.Color.muted }
                        }
                        Rectangle {
                          width: 24; height: 4; radius: 2
                          color: Commons.Util.alpha(Commons.Color.foreground, 0.15)
                          Rectangle { width: 14; height: parent.height; radius: 2; color: Commons.Color.accent }
                        }
                      }

                      // 5. Default Icon mini preview (if none of the above)
                      Text {
                        anchors.centerIn: parent
                        visible: variantCardDelegate.modelData.variant !== "analog" &&
                                 variantCardDelegate.modelData.variant !== "cards" &&
                                 variantCardDelegate.modelData.variant !== "bar" &&
                                 !(root.activeSelectedBlock.kind === "time" && (variantCardDelegate.modelData.variant === "digital" || variantCardDelegate.modelData.variant === "minimal" || variantCardDelegate.modelData.variant === "compact"))
                        text: variantCardDelegate.modelData.icon || "󰒓"
                        font.family: Commons.Style.fontFamily
                        font.pixelSize: 13
                        color: Commons.Color.accent
                      }
                    }

                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 1

                      RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                          text: variantCardDelegate.modelData.label || variantCardDelegate.modelData.variant
                          font.family: Commons.Style.fontFamily
                          font.pixelSize: 10
                          font.bold: true
                          color: Commons.Color.foreground
                          elide: Text.ElideRight
                          Layout.fillWidth: true
                        }

                        Text {
                          visible: variantCardDelegate.isCurrent
                          text: "✓"
                          font.family: Commons.Style.fontFamily
                          font.pixelSize: 9
                          font.bold: true
                          color: Commons.Color.accent
                        }
                      }

                      Text {
                        text: variantCardDelegate.fp ? (variantCardDelegate.fp.label || (variantCardDelegate.fp.colSpan + "×" + variantCardDelegate.fp.rowSpan)) : ""
                        font.family: Commons.Style.fontFamily
                        font.pixelSize: 8
                        color: Commons.Color.muted
                      }
                    }
                  }

                  // Sizing / Action Status
                  Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 20

                    Text {
                      visible: variantCardDelegate.isCurrent
                      anchors.left: parent.left
                      anchors.verticalCenter: parent.verticalCenter
                      text: "Active design"
                      font.family: Commons.Style.fontFamily
                      font.pixelSize: 8
                      color: Commons.Color.accent
                    }

                    Text {
                      visible: !variantCardDelegate.isCurrent && !variantCardDelegate.needsExpand
                      anchors.left: parent.left
                      anchors.verticalCenter: parent.verticalCenter
                      text: "Click to apply"
                      font.family: Commons.Style.fontFamily
                      font.pixelSize: 8
                      color: Commons.Util.alpha(Commons.Color.accent, 0.85)
                    }

                    Rectangle {
                      visible: !variantCardDelegate.isCurrent && variantCardDelegate.needsExpand
                      anchors.fill: parent
                      radius: 3
                      color: expHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.20)
                      border.color: Commons.Color.accent
                      border.width: 1

                      HoverHandler { id: expHov; cursorShape: Qt.PointingHandCursor }
                      TapHandler {
                        onTapped: {
                          root.expandAndApplyRequested(root.selectedContainer.id, root.activeSelectedBlock.id, variantCardDelegate.modelData.variant)
                        }
                      }

                      RowLayout {
                        anchors.centerIn: parent
                        spacing: 3

                        Text {
                          text: "󰁌 Expand & Apply"
                          font.family: Commons.Style.fontFamily
                          font.pixelSize: 8
                          font.bold: true
                          color: expHov.hovered ? Commons.Color.background : Commons.Color.accent
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          // Explicit Remove Block Button
          Rectangle {
            Layout.preferredHeight: 28
            Layout.fillWidth: true
            radius: 4
            color: rmSelHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.urgent, 0.15)
            border.color: Commons.Color.urgent
            border.width: 1

            HoverHandler { id: rmSelHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                var bid = root.activeSelectedBlock ? root.activeSelectedBlock.id : ""
                root.blockSelected("")
                if (bid) root.removeBlockRequested(bid)
              }
            }

            RowLayout {
              anchors.centerIn: parent
              spacing: 6

              Text {
                text: "󰅖 Remove Block from Container"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                font.bold: true
                color: rmSelHov.hovered ? Commons.Color.background : Commons.Color.urgent
              }
            }
          }
        }
      }

      // =================================================================
      // Section 1: Dedicated Domain Block Toggles (Scoped to Container)
      // =================================================================
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: root.showAllBlocks ? "All Available Blocks" : "Dedicated Domain Toggles"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 12
          font.bold: true
          color: Commons.Color.foreground
        }

        Item { Layout.fillWidth: true }

        Rectangle {
          Layout.preferredHeight: 22
          implicitWidth: modeToggleText.implicitWidth + 14
          radius: 11
          color: root.showAllBlocks
            ? Commons.Util.alpha(Commons.Color.accent, 0.25)
            : Commons.Util.alpha(Commons.Color.foreground, 0.08)
          border.color: root.showAllBlocks ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.15)
          border.width: 1

          HoverHandler { cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.showAllBlocks = !root.showAllBlocks }

          Text {
            id: modeToggleText
            anchors.centerIn: parent
            text: root.showAllBlocks ? "🌐 All Blocks" : "🎯 Scoped"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 10
            font.bold: true
            color: root.showAllBlocks ? Commons.Color.accent : Commons.Color.foreground
          }
        }
      }

      // Time Block toggle (Clock domain only)
      Rectangle {
        id: timeToggleCard
        readonly property string activeId: root.findActiveBlockId("time", "")
        readonly property bool isActive: activeId.length > 0
        readonly property bool isSelected: Boolean(timeToggleCard.isActive && timeToggleCard.activeId === root.selectedBlockId)
        visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, "time", "")
        Layout.fillWidth: true
        Layout.preferredHeight: timeToggleCard.isActive ? 42 : 68
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: timeToggleCard.isSelected
          ? Commons.Util.alpha(Commons.Color.accent, 0.22)
          : (timeToggleCard.isActive
              ? Commons.Util.alpha(Commons.Color.accent, 0.12)
              : (timeHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04)))
        border.color: timeToggleCard.isSelected
          ? Commons.Color.accent
          : (timeToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12))
        border.width: timeToggleCard.isSelected ? 2 : 1

        HoverHandler { id: timeHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (timeToggleCard.isActive) {
              root.blockSelected(timeToggleCard.activeId)
            } else {
              root.addBlockRequested("time", "compact", "")
            }
          }
        }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: 6
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 4

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
              text: "󰥔"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 13
              color: timeToggleCard.isActive ? Commons.Color.accent : Commons.Color.muted
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                text: "Clock"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: Commons.Color.foreground
              }

              Text {
                text: "Digital clock, uptime & host badge"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                color: Commons.Color.muted
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            Rectangle {
              Layout.preferredHeight: 22
              implicitWidth: timeBadgeTxt.implicitWidth + 12
              radius: 4
              color: timeToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

              Text {
                id: timeBadgeTxt
                anchors.centerIn: parent
                text: timeToggleCard.isActive ? (timeToggleCard.isSelected ? "✓ Selected" : "✓ Active") : "+ Add"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                font.bold: true
                color: timeToggleCard.isActive ? Commons.Color.background : Commons.Color.accent
              }
            }

            // Separate Remove Button (Eliminates the Toggle Trap)
            Rectangle {
              visible: timeToggleCard.isActive
              Layout.preferredWidth: 22
              Layout.preferredHeight: 22
              radius: 3
              color: rmTimeHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

              HoverHandler { id: rmTimeHov; cursorShape: Qt.PointingHandCursor }
              TapHandler {
                onTapped: {
                  if (timeToggleCard.isSelected) root.blockSelected("")
                  root.removeBlockRequested(timeToggleCard.activeId)
                }
              }

              Text {
                anchors.centerIn: parent
                text: "✕"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 9
                color: rmTimeHov.hovered ? Commons.Color.background : Commons.Color.muted
              }
            }
          }

          // Direct Variant Selection on Add (when not active)
          RowLayout {
            visible: !timeToggleCard.isActive
            Layout.fillWidth: true
            Layout.leftMargin: 20
            spacing: 4

            Repeater {
              model: [
                { v: "compact", l: "Digital" },
                { v: "analog", l: "Analog" },
                { v: "cards", l: "Cards" },
                { v: "minimal", l: "Minimal" }
              ]
              delegate: Rectangle {
                required property var modelData
                Layout.preferredHeight: 18
                implicitWidth: timeChipTxt.implicitWidth + 8
                radius: 3
                color: timeChipHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.3) : Commons.Util.alpha(Commons.Color.foreground, 0.06)
                border.color: Commons.Util.alpha(Commons.Color.accent, 0.4)
                border.width: 0.5

                HoverHandler { id: timeChipHov; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                  onTapped: root.addBlockRequested("time", modelData.v, "")
                }
                Text {
                  id: timeChipTxt
                  anchors.centerIn: parent
                  text: "+ " + modelData.l
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 8
                  color: Commons.Color.accent
                }
              }
            }
          }
        }
      }

      // Date Block toggle (Clock domain only)
      Rectangle {
        id: dateToggleCard
        readonly property string activeId: root.findActiveBlockId("date", "")
        readonly property bool isActive: activeId.length > 0
        readonly property bool isSelected: Boolean(dateToggleCard.isActive && dateToggleCard.activeId === root.selectedBlockId)
        visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, "date", "")
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: dateToggleCard.isSelected
          ? Commons.Util.alpha(Commons.Color.accent, 0.22)
          : (dateToggleCard.isActive
              ? Commons.Util.alpha(Commons.Color.accent, 0.12)
              : (dateHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04)))
        border.color: dateToggleCard.isSelected
          ? Commons.Color.accent
          : (dateToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12))
        border.width: dateToggleCard.isSelected ? 2 : 1

        HoverHandler { id: dateHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (dateToggleCard.isActive) {
              root.blockSelected(dateToggleCard.activeId)
            } else {
              root.addBlockRequested("date", "compact", "")
            }
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Text {
            text: "󰃭"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 13
            color: dateToggleCard.isActive ? Commons.Color.accent : Commons.Color.muted
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: "Date"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.foreground
            }

            Text {
              text: "Day, 7-day week strip & monthly calendar"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: Commons.Color.muted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Rectangle {
            Layout.preferredHeight: 22
            implicitWidth: dateBadgeTxt.implicitWidth + 12
            radius: 4
            color: dateToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            Text {
              id: dateBadgeTxt
              anchors.centerIn: parent
              text: dateToggleCard.isActive ? (dateToggleCard.isSelected ? "✓ Selected" : "✓ Active") : "+ Show"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: dateToggleCard.isActive ? Commons.Color.background : Commons.Color.accent
            }
          }

          Rectangle {
            visible: dateToggleCard.isActive
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 3
            color: rmDateHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            HoverHandler { id: rmDateHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                if (dateToggleCard.isSelected) root.blockSelected("")
                root.removeBlockRequested(dateToggleCard.activeId)
              }
            }

            Text {
              anchors.centerIn: parent
              text: "✕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              color: rmDateHov.hovered ? Commons.Color.background : Commons.Color.muted
            }
          }
        }
      }

      // Workspace Block toggle (Clock domain only)
      Rectangle {
        id: wsToggleCard
        readonly property string activeId: root.findActiveBlockId("workspace", "")
        readonly property bool isActive: activeId.length > 0
        readonly property bool isSelected: Boolean(wsToggleCard.isActive && wsToggleCard.activeId === root.selectedBlockId)
        visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, "workspace", "")
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: wsToggleCard.isSelected
          ? Commons.Util.alpha(Commons.Color.accent, 0.22)
          : (wsToggleCard.isActive
              ? Commons.Util.alpha(Commons.Color.accent, 0.12)
              : (wsHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04)))
        border.color: wsToggleCard.isSelected
          ? Commons.Color.accent
          : (wsToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12))
        border.width: wsToggleCard.isSelected ? 2 : 1

        HoverHandler { id: wsHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (wsToggleCard.isActive) {
              root.blockSelected(wsToggleCard.activeId)
            } else {
              root.addBlockRequested("workspace", "compact", "")
            }
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Text {
            text: "󰖲"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 13
            color: wsToggleCard.isActive ? Commons.Color.accent : Commons.Color.muted
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: "Workspace"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.foreground
            }

            Text {
              text: "Active Hyprland workspace indicator"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: Commons.Color.muted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Rectangle {
            Layout.preferredHeight: 22
            implicitWidth: wsBadgeTxt.implicitWidth + 12
            radius: 4
            color: wsToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            Text {
              id: wsBadgeTxt
              anchors.centerIn: parent
              text: wsToggleCard.isActive ? (wsToggleCard.isSelected ? "✓ Selected" : "✓ Active") : "+ Show"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: wsToggleCard.isActive ? Commons.Color.background : Commons.Color.accent
            }
          }

          Rectangle {
            visible: wsToggleCard.isActive
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 3
            color: rmWsHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            HoverHandler { id: rmWsHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                if (wsToggleCard.isSelected) root.blockSelected("")
                root.removeBlockRequested(wsToggleCard.activeId)
              }
            }

            Text {
              anchors.centerIn: parent
              text: "✕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              color: rmWsHov.hovered ? Commons.Color.background : Commons.Color.muted
            }
          }
        }
      }

      // Network Block toggle (Network domain only)
      Rectangle {
        id: netToggleCard
        readonly property string activeId: root.findActiveBlockId("network", "")
        readonly property bool isActive: activeId.length > 0
        readonly property bool isSelected: Boolean(netToggleCard.isActive && netToggleCard.activeId === root.selectedBlockId)
        visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, "network", "")
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: netToggleCard.isSelected
          ? Commons.Util.alpha(Commons.Color.accent, 0.22)
          : (netToggleCard.isActive
              ? Commons.Util.alpha(Commons.Color.accent, 0.12)
              : (netHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04)))
        border.color: netToggleCard.isSelected
          ? Commons.Color.accent
          : (netToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12))
        border.width: netToggleCard.isSelected ? 2 : 1

        HoverHandler { id: netHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (netToggleCard.isActive) {
              root.blockSelected(netToggleCard.activeId)
            } else {
              root.addBlockRequested("network", "compact", "")
            }
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Text {
            text: "󰤨"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 13
            color: netToggleCard.isActive ? Commons.Color.accent : Commons.Color.muted
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: "Network"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.foreground
            }

            Text {
              text: "SSID, IPv4, interface & traffic totals"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: Commons.Color.muted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Rectangle {
            Layout.preferredHeight: 22
            implicitWidth: netBadgeTxt.implicitWidth + 12
            radius: 4
            color: netToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            Text {
              id: netBadgeTxt
              anchors.centerIn: parent
              text: netToggleCard.isActive ? (netToggleCard.isSelected ? "✓ Selected" : "✓ Active") : "+ Show"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: netToggleCard.isActive ? Commons.Color.background : Commons.Color.accent
            }
          }

          Rectangle {
            visible: netToggleCard.isActive
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 3
            color: rmNetHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            HoverHandler { id: rmNetHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                if (netToggleCard.isSelected) root.blockSelected("")
                root.removeBlockRequested(netToggleCard.activeId)
              }
            }

            Text {
              anchors.centerIn: parent
              text: "✕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              color: rmNetHov.hovered ? Commons.Color.background : Commons.Color.muted
            }
          }
        }
      }

      // Battery Block toggle (Network & Power domain only)
      Rectangle {
        id: battToggleCard
        readonly property string activeId: root.findActiveBlockId("battery", "")
        readonly property bool isActive: activeId.length > 0
        readonly property bool isSelected: Boolean(battToggleCard.isActive && battToggleCard.activeId === root.selectedBlockId)
        visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, "battery", "")
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: battToggleCard.isSelected
          ? Commons.Util.alpha(Commons.Color.accent, 0.22)
          : (battToggleCard.isActive
              ? Commons.Util.alpha(Commons.Color.accent, 0.12)
              : (battHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04)))
        border.color: battToggleCard.isSelected
          ? Commons.Color.accent
          : (battToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12))
        border.width: battToggleCard.isSelected ? 2 : 1

        HoverHandler { id: battHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (battToggleCard.isActive) {
              root.blockSelected(battToggleCard.activeId)
            } else {
              root.addBlockRequested("battery", "compact", "")
            }
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Text {
            text: "󰁹"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 13
            color: battToggleCard.isActive ? Commons.Color.accent : Commons.Color.muted
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: "Battery"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.foreground
            }

            Text {
              text: "Charge level, wattage & remaining time"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: Commons.Color.muted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Rectangle {
            Layout.preferredHeight: 22
            implicitWidth: battBadgeTxt.implicitWidth + 12
            radius: 4
            color: battToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            Text {
              id: battBadgeTxt
              anchors.centerIn: parent
              text: battToggleCard.isActive ? (battToggleCard.isSelected ? "✓ Selected" : "✓ Active") : "+ Show"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: battToggleCard.isActive ? Commons.Color.background : Commons.Color.accent
            }
          }

          Rectangle {
            visible: battToggleCard.isActive
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 3
            color: rmBattHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            HoverHandler { id: rmBattHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                if (battToggleCard.isSelected) root.blockSelected("")
                root.removeBlockRequested(battToggleCard.activeId)
              }
            }

            Text {
              anchors.centerIn: parent
              text: "✕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              color: rmBattHov.hovered ? Commons.Color.background : Commons.Color.muted
            }
          }
        }
      }

      // To-Do Block toggle
      Rectangle {
        id: todoToggleCard
        readonly property string activeId: root.findActiveBlockId("todo", "")
        readonly property bool isActive: activeId.length > 0
        readonly property bool isSelected: Boolean(todoToggleCard.isActive && todoToggleCard.activeId === root.selectedBlockId)
        visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, "todo", "")
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: todoToggleCard.isSelected
          ? Commons.Util.alpha(Commons.Color.accent, 0.22)
          : (todoToggleCard.isActive
              ? Commons.Util.alpha(Commons.Color.accent, 0.12)
              : (todoHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04)))
        border.color: todoToggleCard.isSelected
          ? Commons.Color.accent
          : (todoToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12))
        border.width: todoToggleCard.isSelected ? 2 : 1

        HoverHandler { id: todoHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (todoToggleCard.isActive) {
              root.blockSelected(todoToggleCard.activeId)
            } else {
              root.addBlockRequested("todo", "list", "")
            }
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Text {
            text: "󰄱"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 13
            color: todoToggleCard.isActive ? Commons.Color.accent : Commons.Color.muted
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: "To-Do List"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.foreground
            }

            Text {
              text: "Interactive task checklist linked to Omarchy bar"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: Commons.Color.muted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Rectangle {
            Layout.preferredHeight: 22
            implicitWidth: todoBadgeTxt.implicitWidth + 12
            radius: 4
            color: todoToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            Text {
              id: todoBadgeTxt
              anchors.centerIn: parent
              text: todoToggleCard.isActive ? (todoToggleCard.isSelected ? "✓ Selected" : "✓ Active") : "+ Show"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: todoToggleCard.isActive ? Commons.Color.background : Commons.Color.accent
            }
          }

          Rectangle {
            visible: todoToggleCard.isActive
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 3
            color: rmTodoHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            HoverHandler { id: rmTodoHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                if (todoToggleCard.isSelected) root.blockSelected("")
                root.removeBlockRequested(todoToggleCard.activeId)
              }
            }

            Text {
              anchors.centerIn: parent
              text: "✕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              color: rmTodoHov.hovered ? Commons.Color.background : Commons.Color.muted
            }
          }
        }
      }

      // Notifications Block toggle
      Rectangle {
        id: notifToggleCard
        readonly property string activeId: root.findActiveBlockId("notifications", "")
        readonly property bool isActive: activeId.length > 0
        readonly property bool isSelected: Boolean(notifToggleCard.isActive && notifToggleCard.activeId === root.selectedBlockId)
        visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, "notifications", "")
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: notifToggleCard.isSelected
          ? Commons.Util.alpha(Commons.Color.accent, 0.22)
          : (notifToggleCard.isActive
              ? Commons.Util.alpha(Commons.Color.accent, 0.12)
              : (notifHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04)))
        border.color: notifToggleCard.isSelected
          ? Commons.Color.accent
          : (notifToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12))
        border.width: notifToggleCard.isSelected ? 2 : 1

        HoverHandler { id: notifHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (notifToggleCard.isActive) {
              root.blockSelected(notifToggleCard.activeId)
            } else {
              root.addBlockRequested("notifications", "recent", "")
            }
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Text {
            text: "󰂚"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 13
            color: notifToggleCard.isActive ? Commons.Color.accent : Commons.Color.muted
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: "Notifications Feed"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.foreground
            }

            Text {
              text: "Recent system alerts & DND quiet mode switch"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: Commons.Color.muted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Rectangle {
            Layout.preferredHeight: 22
            implicitWidth: notifBadgeTxt.implicitWidth + 12
            radius: 4
            color: notifToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            Text {
              id: notifBadgeTxt
              anchors.centerIn: parent
              text: notifToggleCard.isActive ? (notifToggleCard.isSelected ? "✓ Selected" : "✓ Active") : "+ Show"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: notifToggleCard.isActive ? Commons.Color.background : Commons.Color.accent
            }
          }

          Rectangle {
            visible: notifToggleCard.isActive
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 3
            color: rmNotifHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            HoverHandler { id: rmNotifHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                if (notifToggleCard.isSelected) root.blockSelected("")
                root.removeBlockRequested(notifToggleCard.activeId)
              }
            }

            Text {
              anchors.centerIn: parent
              text: "✕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              color: rmNotifHov.hovered ? Commons.Color.background : Commons.Color.muted
            }
          }
        }
      }

      // Fan Controls Block toggle (Thermal & Fan domain only)
      Rectangle {
        id: fanToggleCard
        readonly property string activeId: root.findActiveBlockId("fan-control", "")
        readonly property bool isActive: activeId.length > 0
        readonly property bool isSelected: Boolean(fanToggleCard.isActive && fanToggleCard.activeId === root.selectedBlockId)
        visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, "fan-control", "")
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: fanToggleCard.isSelected
          ? Commons.Util.alpha(Commons.Color.accent, 0.22)
          : (fanToggleCard.isActive
              ? Commons.Util.alpha(Commons.Color.accent, 0.12)
              : (fanHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04)))
        border.color: fanToggleCard.isSelected
          ? Commons.Color.accent
          : (fanToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12))
        border.width: fanToggleCard.isSelected ? 2 : 1

        HoverHandler { id: fanHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (fanToggleCard.isActive) {
              root.blockSelected(fanToggleCard.activeId)
            } else {
              root.addBlockRequested("fan-control", "controls", "")
            }
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Text {
            text: "󰈐"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 13
            color: fanToggleCard.isActive ? Commons.Color.accent : Commons.Color.muted
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: "Fan Controls"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.foreground
            }

            Text {
              text: "Quiet, Standard, Clean & Boost profiles"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: Commons.Color.muted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Rectangle {
            Layout.preferredHeight: 22
            implicitWidth: fanBadgeTxt.implicitWidth + 12
            radius: 4
            color: fanToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            Text {
              id: fanBadgeTxt
              anchors.centerIn: parent
              text: fanToggleCard.isActive ? (fanToggleCard.isSelected ? "✓ Selected" : "✓ Active") : "+ Show"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: fanToggleCard.isActive ? Commons.Color.background : Commons.Color.accent
            }
          }

          Rectangle {
            visible: fanToggleCard.isActive
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 3
            color: rmFanHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            HoverHandler { id: rmFanHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                if (fanToggleCard.isSelected) root.blockSelected("")
                root.removeBlockRequested(fanToggleCard.activeId)
              }
            }

            Text {
              anchors.centerIn: parent
              text: "✕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              color: rmFanHov.hovered ? Commons.Color.background : Commons.Color.muted
            }
          }
        }
      }

      // Application and folder launchers (Apps / Folders domains only)
      Repeater {
        model: root.enabledGridKinds

        delegate: Rectangle {
          id: gridDelegate
          required property var modelData

          readonly property string gridKind: modelData.kind
          readonly property string gridLabel: modelData.label
          readonly property string gridIcon: modelData.icon
          readonly property string activeId: root.findActiveBlockId(gridDelegate.gridKind, "")
          readonly property bool isActive: activeId.length > 0

          visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, gridDelegate.gridKind, "")
          Layout.fillWidth: true
          Layout.preferredHeight: 42
          radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
          color: gridDelegate.isActive
            ? Commons.Util.alpha(Commons.Color.accent, 0.14)
            : (gridHover.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
          border.color: gridDelegate.isActive
            ? Commons.Color.accent
            : Commons.Util.alpha(Commons.Color.foreground, 0.12)
          border.width: 1

          HoverHandler { id: gridHover; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              if (gridDelegate.isActive) {
                root.blockSelected(gridDelegate.activeId)
              } else {
                root.addBlockRequested(gridDelegate.gridKind, "compact", "")
              }
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
              text: gridDelegate.gridIcon
              font.family: Commons.Style.fontFamily
              font.pixelSize: 13
              color: gridDelegate.isActive ? Commons.Color.accent : Commons.Color.muted
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                text: gridDelegate.gridLabel
                font.family: Commons.Style.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: Commons.Color.foreground
              }

              Text {
                text: gridDelegate.isActive
                  ? (gridDelegate.gridKind + " • Active · نشط")
                  : (gridDelegate.gridKind + " • 2×2 internal")
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                color: gridDelegate.isActive ? Commons.Color.accent : Commons.Color.muted
              }
            }

            Rectangle {
              id: gridBadgeBtn
              Layout.preferredHeight: 22
              implicitWidth: gridBadgeTxt.implicitWidth + 14
              radius: 4
              color: gridBadgeHov.hovered
                ? Commons.Color.accent
                : (gridDelegate.isActive ? Commons.Util.alpha(Commons.Color.accent, 0.22) : Commons.Util.alpha(Commons.Color.foreground, 0.08))
              border.color: Commons.Color.accent
              border.width: gridDelegate.isActive ? 1 : 0

              HoverHandler { id: gridBadgeHov; cursorShape: Qt.PointingHandCursor }
              TapHandler {
                onTapped: {
                  if (gridDelegate.isActive) {
                    root.blockSelected(gridDelegate.activeId)
                    if (gridDelegate.gridKind === "app-grid") {
                      appPickerModal.active = true
                    } else if (gridDelegate.gridKind === "folder-grid") {
                      fileFolderPickerModal.mode = "folder"
                      fileFolderPickerModal.active = true
                    }
                  } else {
                    root.addBlockRequested(gridDelegate.gridKind, "compact", "")
                  }
                }
              }

              Text {
                id: gridBadgeTxt
                anchors.centerIn: parent
                text: gridDelegate.isActive ? "+ Add Item" : "+ Show"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                font.bold: true
                color: (gridBadgeHov.hovered || gridDelegate.isActive) ? Commons.Color.accent : Commons.Color.accent
              }
            }
          }
        }
      }

      // Metric Blocks options (Filtered strictly to selected container domain)
      Repeater {
        model: root.enabledMetricSources

        delegate: Rectangle {
          id: metricDelegate
          required property var modelData
          required property int index

          readonly property var mItem: modelData
          readonly property string mSource: (mItem && typeof mItem.source === "string") ? mItem.source : ""
          readonly property string mLabel: (mItem && typeof mItem.label === "string") ? mItem.label : mSource
          readonly property string mSub: (mItem && typeof mItem.subtitle === "string") ? mItem.subtitle : (mSource + " • compact")
          readonly property string mIcon: (mItem && typeof mItem.icon === "string") ? mItem.icon : "󰍛"
          readonly property string activeId: root.findActiveBlockId("metric", metricDelegate.mSource)
          readonly property bool isActive: activeId.length > 0
          readonly property bool isSelected: Boolean(metricDelegate.isActive && metricDelegate.activeId === root.selectedBlockId)

          visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, "metric", metricDelegate.mSource)
          Layout.fillWidth: true
          Layout.preferredHeight: 42
          radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
          color: metricDelegate.isSelected
            ? Commons.Util.alpha(Commons.Color.accent, 0.22)
            : (metricDelegate.isActive
                ? Commons.Util.alpha(Commons.Color.accent, 0.12)
                : (mHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04)))
          border.color: metricDelegate.isSelected
            ? Commons.Color.accent
            : (metricDelegate.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12))
          border.width: metricDelegate.isSelected ? 2 : 1

          HoverHandler { id: mHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              if (metricDelegate.isActive) {
                root.blockSelected(metricDelegate.activeId)
              } else {
                root.addBlockRequested("metric", "compact", metricDelegate.mSource)
              }
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
              text: metricDelegate.mIcon
              font.family: Commons.Style.fontFamily
              font.pixelSize: 13
              color: metricDelegate.isActive ? Commons.Color.accent : Commons.Color.muted
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                text: metricDelegate.mLabel
                font.family: Commons.Style.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: Commons.Color.foreground
              }

              Text {
                text: metricDelegate.mSub
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                color: Commons.Color.muted
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            Rectangle {
              Layout.preferredHeight: 22
              implicitWidth: mBadgeTxt.implicitWidth + 12
              radius: 4
              color: metricDelegate.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

              Text {
                id: mBadgeTxt
                anchors.centerIn: parent
                text: metricDelegate.isActive ? (metricDelegate.isSelected ? "✓ Selected" : "✓ Active") : "+ Show"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                font.bold: true
                color: metricDelegate.isActive ? Commons.Color.background : Commons.Color.accent
              }
            }

            Rectangle {
              visible: metricDelegate.isActive
              Layout.preferredWidth: 22
              Layout.preferredHeight: 22
              radius: 3
              color: rmMHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

              HoverHandler { id: rmMHov; cursorShape: Qt.PointingHandCursor }
              TapHandler {
                onTapped: {
                  if (metricDelegate.isSelected) root.blockSelected("")
                  root.removeBlockRequested(metricDelegate.activeId)
                }
              }

              Text {
                anchors.centerIn: parent
                text: "✕"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 9
                color: rmMHov.hovered ? Commons.Color.background : Commons.Color.muted
              }
            }
          }
        }
      }

      // System Identity Block toggle (System domain)
      Rectangle {
        id: sysInfoToggleCard
        readonly property string activeId: root.findActiveBlockId("sys-info", "")
        readonly property bool isActive: activeId.length > 0
        readonly property bool isSelected: Boolean(sysInfoToggleCard.isActive && sysInfoToggleCard.activeId === root.selectedBlockId)
        visible: root.showAllBlocks || BlockRegistry.isBlockAllowedInDomain(root.containerDomain, "sys-info", "")
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: sysInfoToggleCard.isSelected
          ? Commons.Util.alpha(Commons.Color.accent, 0.22)
          : (sysInfoToggleCard.isActive
              ? Commons.Util.alpha(Commons.Color.accent, 0.12)
              : (sysInfoHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04)))
        border.color: sysInfoToggleCard.isSelected
          ? Commons.Color.accent
          : (sysInfoToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12))
        border.width: sysInfoToggleCard.isSelected ? 2 : 1

        HoverHandler { id: sysInfoHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (sysInfoToggleCard.isActive) {
              root.blockSelected(sysInfoToggleCard.activeId)
            } else {
              root.addBlockRequested("sys-info", "compact", "")
            }
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          Text {
            text: "󰌽"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 13
            color: sysInfoToggleCard.isActive ? Commons.Color.accent : Commons.Color.muted
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: "System Identity · معلومات النظام"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.foreground
            }

            Text {
              text: "OS, hostname, kernel, CPU, load avg & swap"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: Commons.Color.muted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          Rectangle {
            Layout.preferredHeight: 22
            implicitWidth: sysInfoBadgeTxt.implicitWidth + 12
            radius: 4
            color: sysInfoToggleCard.isActive ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            Text {
              id: sysInfoBadgeTxt
              anchors.centerIn: parent
              text: sysInfoToggleCard.isActive ? (sysInfoToggleCard.isSelected ? "✓ Selected" : "✓ Active") : "+ Show"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: sysInfoToggleCard.isActive ? Commons.Color.background : Commons.Color.accent
            }
          }

          Rectangle {
            visible: sysInfoToggleCard.isActive
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 3
            color: rmSysHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            HoverHandler { id: rmSysHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                if (sysInfoToggleCard.isSelected) root.blockSelected("")
                root.removeBlockRequested(sysInfoToggleCard.activeId)
              }
            }

            Text {
              anchors.centerIn: parent
              text: "✕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              color: rmSysHov.hovered ? Commons.Color.background : Commons.Color.muted
            }
          }
        }
      }

      // Direct Inline App / Folder Item Editor (Apps & Folders domains)
      Rectangle {
        id: inlineGridEditorCard
        readonly property var gridBlock: root.findActiveGridBlock()
        readonly property bool isApps: Boolean(gridBlock && gridBlock.kind === "app-grid")
        readonly property var gridItems: {
          if (!gridBlock || !gridBlock.settings || !gridBlock.settings.items) return []
          var items = gridBlock.settings.items
          return Array.isArray(items) ? items : (typeof items.length === "number" ? Array.prototype.slice.call(items) : [])
        }
        readonly property int cols: root.selectedContainer ? (root.selectedContainer.colSpan || 1) : 1
        readonly property int rows: root.selectedContainer ? (root.selectedContainer.rowSpan || 1) : 1
        readonly property int maxCap: Math.max(16, cols * rows * 8)

        visible: Boolean(gridBlock)
        Layout.fillWidth: true
        implicitHeight: inlineGridCol.implicitHeight + 16
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: Commons.Util.alpha(Commons.Color.foreground, 0.04)
        border.color: Commons.Util.alpha(Commons.Color.accent, 0.25)
        border.width: 1

        ColumnLayout {
          id: inlineGridCol
          anchors.fill: parent
          anchors.margins: 8
          spacing: 6

          RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
              text: inlineGridEditorCard.isApps ? "Pinned Apps · التطبيقات المثبتة" : "Pinned Shortcuts · الاختصارات المثبتة"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.accent
            }

            Item { Layout.fillWidth: true }

            Text {
              text: inlineGridEditorCard.gridItems.length + " items"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: Commons.Color.muted
            }
          }

          Repeater {
            model: inlineGridEditorCard.gridItems

            delegate: Rectangle {
              id: inlineItemRow
              required property var modelData
              required property int index

              Layout.fillWidth: true
              Layout.preferredHeight: 30
              radius: 4
              color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
              border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
              border.width: 1

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 6
                spacing: 6

                Text {
                  text: String((inlineItemRow.modelData && inlineItemRow.modelData.icon) || (inlineGridEditorCard.isApps ? "󰀻" : ((inlineItemRow.modelData && inlineItemRow.modelData.isFile) ? "󰈙" : "󰉋")))
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 12
                  color: Commons.Color.accent
                }

                Text {
                  Layout.preferredWidth: 70
                  text: String((inlineItemRow.modelData && inlineItemRow.modelData.name) || "")
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 10
                  font.bold: true
                  color: Commons.Color.foreground
                  elide: Text.ElideRight
                }

                Rectangle {
                  visible: !inlineGridEditorCard.isApps
                  Layout.preferredHeight: 16
                  implicitWidth: typeTagTxt.implicitWidth + 8
                  radius: 2
                  color: Commons.Util.alpha(Commons.Color.accent, 0.12)
                  Text {
                    id: typeTagTxt
                    anchors.centerIn: parent
                    text: (inlineItemRow.modelData && inlineItemRow.modelData.isFile) ? "File" : "Folder"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 8
                    font.bold: true
                    color: Commons.Color.accent
                  }
                }

                Text {
                  Layout.fillWidth: true
                  text: inlineGridEditorCard.isApps
                    ? String((inlineItemRow.modelData && (inlineItemRow.modelData.sub || inlineItemRow.modelData.command)) || "")
                    : String((inlineItemRow.modelData && inlineItemRow.modelData.path) || "")
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 10
                  color: Commons.Color.muted
                  elide: Text.ElideRight
                }

                // Reorder: Move Up
                Rectangle {
                  Layout.preferredWidth: 18
                  Layout.preferredHeight: 18
                  radius: 3
                  visible: inlineItemRow.index > 0
                  color: upItemHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.20) : "transparent"
                  HoverHandler { id: upItemHov; cursorShape: Qt.PointingHandCursor }
                  TapHandler {
                    onTapped: {
                      const gb = inlineGridEditorCard.gridBlock
                      if (!gb || !gb.id) return
                      const nextList = inlineGridEditorCard.gridItems.slice()
                      const cur = nextList.splice(inlineItemRow.index, 1)[0]
                      nextList.splice(inlineItemRow.index - 1, 0, cur)
                      root.settingsUpdateRequested(gb.id, { items: nextList })
                    }
                  }
                  Text {
                    anchors.centerIn: parent
                    text: "▲"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 8
                    color: upItemHov.hovered ? Commons.Color.accent : Commons.Color.muted
                  }
                }

                // Reorder: Move Down
                Rectangle {
                  Layout.preferredWidth: 18
                  Layout.preferredHeight: 18
                  radius: 3
                  visible: inlineItemRow.index < inlineGridEditorCard.gridItems.length - 1
                  color: downItemHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.20) : "transparent"
                  HoverHandler { id: downItemHov; cursorShape: Qt.PointingHandCursor }
                  TapHandler {
                    onTapped: {
                      const gb = inlineGridEditorCard.gridBlock
                      if (!gb || !gb.id) return
                      const nextList = inlineGridEditorCard.gridItems.slice()
                      const cur = nextList.splice(inlineItemRow.index, 1)[0]
                      nextList.splice(inlineItemRow.index + 1, 0, cur)
                      root.settingsUpdateRequested(gb.id, { items: nextList })
                    }
                  }
                  Text {
                    anchors.centerIn: parent
                    text: "▼"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 8
                    color: downItemHov.hovered ? Commons.Color.accent : Commons.Color.muted
                  }
                }

                // Delete Item
                Rectangle {
                  Layout.preferredWidth: 20
                  Layout.preferredHeight: 20
                  radius: 3
                  color: delItemHov.hovered ? Commons.Util.alpha(Commons.Color.urgent, 0.22) : "transparent"

                  HoverHandler { id: delItemHov; cursorShape: Qt.PointingHandCursor }
                  TapHandler {
                    onTapped: {
                      const gb = inlineGridEditorCard.gridBlock
                      if (!gb || !gb.id) return
                      const nextList = inlineGridEditorCard.gridItems.slice()
                      nextList.splice(inlineItemRow.index, 1)
                      root.settingsUpdateRequested(gb.id, { items: nextList })
                    }
                  }

                  Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 10
                    color: delItemHov.hovered ? Commons.Color.urgent : Commons.Color.muted
                  }
                }
              }
            }
          }

          // Action Buttons: Graphical pickers for Apps / Folders / Files
          Rectangle {
            visible: inlineGridEditorCard.isApps
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 4
            color: addAppBtnHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.16)
            border.color: Commons.Color.accent
            border.width: 1

            HoverHandler { id: addAppBtnHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: appPickerModal.active = true
            }

            RowLayout {
              anchors.centerIn: parent
              spacing: 6

              Text {
                text: "󰐕"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 12
                color: addAppBtnHov.hovered ? Commons.Color.background : Commons.Color.accent
              }

              Text {
                text: "+ Add Application"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: addAppBtnHov.hovered ? Commons.Color.background : Commons.Color.accent
              }
            }
          }

          RowLayout {
            visible: !inlineGridEditorCard.isApps
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 30
              radius: 4
              color: addFolderBtnHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.16)
              border.color: Commons.Color.accent
              border.width: 1

              HoverHandler { id: addFolderBtnHov; cursorShape: Qt.PointingHandCursor }
              TapHandler {
                onTapped: {
                  fileFolderPickerModal.mode = "folder"
                  fileFolderPickerModal.active = true
                }
              }

              RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                  text: "󰉋"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 12
                  color: addFolderBtnHov.hovered ? Commons.Color.background : Commons.Color.accent
                }

                Text {
                  text: "+ Add Folder"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 11
                  font.bold: true
                  color: addFolderBtnHov.hovered ? Commons.Color.background : Commons.Color.accent
                }
              }
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 30
              radius: 4
              color: addFileBtnHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.16)
              border.color: Commons.Color.accent
              border.width: 1

              HoverHandler { id: addFileBtnHov; cursorShape: Qt.PointingHandCursor }
              TapHandler {
                onTapped: {
                  fileFolderPickerModal.mode = "file"
                  fileFolderPickerModal.active = true
                }
              }

              RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                  text: "󰈙"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 12
                  color: addFileBtnHov.hovered ? Commons.Color.background : Commons.Color.accent
                }

                Text {
                  text: "+ Add File"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 11
                  font.bold: true
                  color: addFileBtnHov.hovered ? Commons.Color.background : Commons.Color.accent
                }
              }
            }
          }

          // Quick Add New App / Folder Row (Manual input)
          RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
              Layout.preferredWidth: 32
              Layout.preferredHeight: 28
              radius: 4
              color: Commons.Util.alpha(Commons.Color.foreground, 0.06)
              border.color: newIconInput.activeFocus ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.14)
              border.width: 1

              TextInput {
                id: newIconInput
                anchors.fill: parent
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter
                font.family: Commons.Style.fontFamily
                font.pixelSize: 11
                color: Commons.Color.foreground
                text: inlineGridEditorCard.isApps ? "󰀻" : "󰉋"
              }
            }

            Rectangle {
              Layout.preferredWidth: 78
              Layout.preferredHeight: 28
              radius: 4
              color: Commons.Util.alpha(Commons.Color.foreground, 0.06)
              border.color: newNameInput.activeFocus ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.14)
              border.width: 1

              TextInput {
                id: newNameInput
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                verticalAlignment: TextInput.AlignVCenter
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                color: Commons.Color.foreground
                clip: true

                Text {
                  anchors.fill: parent
                  verticalAlignment: Text.AlignVCenter
                  visible: !newNameInput.text && !newNameInput.activeFocus
                  text: "Name..."
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 10
                  color: Commons.Color.muted
                }
              }
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 28
              radius: 4
              color: Commons.Util.alpha(Commons.Color.foreground, 0.06)
              border.color: newTargetInput.activeFocus ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.14)
              border.width: 1

              TextInput {
                id: newTargetInput
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                verticalAlignment: TextInput.AlignVCenter
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                color: Commons.Color.foreground
                clip: true

                Text {
                  anchors.fill: parent
                  verticalAlignment: Text.AlignVCenter
                  visible: !newTargetInput.text && !newTargetInput.activeFocus
                  text: inlineGridEditorCard.isApps ? "Command..." : "~/Path..."
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 10
                  color: Commons.Color.muted
                }
              }
            }

            Rectangle {
              Layout.preferredWidth: 46
              Layout.preferredHeight: 28
              radius: 4
              color: addQuickHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.22)
              border.color: Commons.Color.accent
              border.width: 1

              HoverHandler { id: addQuickHov; cursorShape: Qt.PointingHandCursor }
              TapHandler {
                onTapped: {
                  const gb = inlineGridEditorCard.gridBlock
                  const nm = newNameInput.text.trim()
                  const tg = newTargetInput.text.trim()
                  const ic = newIconInput.text.trim() || (inlineGridEditorCard.isApps ? "󰀻" : "󰉋")
                  if (!gb || !gb.id || !nm || !tg) return
                  const nextList = inlineGridEditorCard.gridItems.slice()
                  const itemId = (inlineGridEditorCard.isApps ? "app_" : "folder_") + Date.now().toString(36) + "_" + Math.random().toString(36).substr(2, 5)
                  if (inlineGridEditorCard.isApps) {
                    nextList.push({ id: itemId, name: nm, command: tg, icon: ic, sub: tg })
                  } else {
                    nextList.push({ id: itemId, name: nm, path: tg, icon: ic, isFile: false })
                  }
                  root.settingsUpdateRequested(gb.id, { items: nextList })
                  newNameInput.text = ""
                  newTargetInput.text = ""
                }
              }

              Text {
                anchors.centerIn: parent
                text: "+ Add"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                font.bold: true
                color: addQuickHov.hovered ? Commons.Color.background : Commons.Color.accent
              }
            }
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Commons.Util.alpha(Commons.Color.foreground, 0.08)
      }

      // =================================================================
      // Section 2: Active Container Blocks Order & Footprint Tuning
      // =================================================================
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: "Active Blocks Order & Size"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 12
          font.bold: true
          color: Commons.Color.foreground
        }

        Rectangle {
          Layout.preferredHeight: 18
          implicitWidth: countText.implicitWidth + 10
          radius: 9
          color: Commons.Util.alpha(Commons.Color.accent, 0.16)

          Text {
            id: countText
            anchors.centerIn: parent
            text: String(root.blockList.length)
            font.family: Commons.Style.fontFamily
            font.pixelSize: 10
            font.bold: true
            color: Commons.Color.accent
          }
        }
      }

      // Active Block list
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
          model: root.blockList

          delegate: Rectangle {
            id: blockDelegate
            required property var modelData
            required property int index

            readonly property var bData: modelData
            readonly property bool isSelected: Boolean(bData && bData.id && bData.id === root.selectedBlockId)
            readonly property string bId: (bData && typeof bData.id === "string") ? bData.id : ""
            readonly property string bKind: (bData && typeof bData.kind === "string") ? bData.kind : ""
            readonly property string bVariant: (bData && typeof bData.variant === "string") ? bData.variant : "compact"
            readonly property string bSource: (bData && typeof bData.source === "string") ? bData.source : ""

            Layout.fillWidth: true
            Layout.preferredHeight: 72
            radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
            color: blockDelegate.isSelected
              ? Commons.Util.alpha(Commons.Color.accent, 0.18)
              : (bHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
            border.color: blockDelegate.isSelected
              ? Commons.Color.accent
              : Commons.Util.alpha(Commons.Color.foreground, 0.12)
            border.width: blockDelegate.isSelected ? 2 : Commons.Style.normalBorderWidth

            HoverHandler { id: bHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: root.blockSelected(blockDelegate.bId)
            }

            ColumnLayout {
              anchors.fill: parent
              anchors.margins: 6
              spacing: 3

              // Row 1: Header / info + actions
              RowLayout {
                Layout.fillWidth: true
                spacing: 6

                // Kind icon / badge
                Rectangle {
                  Layout.preferredWidth: 22
                  Layout.preferredHeight: 22
                  radius: 4
                  color: Commons.Util.alpha(Commons.Color.accent, 0.15)

                  Text {
                    anchors.centerIn: parent
                    text: {
                      if (blockDelegate.bKind === "time") return "󰥔"
                      if (blockDelegate.bKind === "date") return "󰃭"
                      if (blockDelegate.bKind === "workspace") return "󰖲"
                      if (blockDelegate.bKind === "network") return "󰤨"
                      if (blockDelegate.bKind === "battery") return "󰁹"
                      if (blockDelegate.bKind === "fan-control") return "󰈐"
                      if (blockDelegate.bKind === "app-grid") return "󰅩"
                      if (blockDelegate.bKind === "folder-grid") return "󰉋"
                      if (blockDelegate.bKind === "sys-info") return "󰌽"
                      return "󰍛"
                    }
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 11
                    color: Commons.Color.accent
                  }
                }

                // Info
                Text {
                  Layout.fillWidth: true
                  text: {
                    if (blockDelegate.bKind === "time") return "Clock"
                    if (blockDelegate.bKind === "date") return "Date"
                    if (blockDelegate.bKind === "workspace") return "Workspace"
                    if (blockDelegate.bKind === "network") return "Network"
                    if (blockDelegate.bKind === "battery") return "Battery"
                    if (blockDelegate.bKind === "fan-control") return "Fan Controls"
                    if (blockDelegate.bKind === "app-grid") return "App Grid"
                    if (blockDelegate.bKind === "folder-grid") return "Folder Grid"
                    if (blockDelegate.bKind === "sys-info") return "System Identity"
                    if (blockDelegate.bSource === "cpu.percent") return "CPU Usage"
                    if (blockDelegate.bSource === "ram.percent") return "Memory Usage"
                    if (blockDelegate.bSource === "disk.percent") return "Storage Usage"
                    if (blockDelegate.bSource === "temperature.cpu") return "CPU Temp"
                    if (blockDelegate.bSource === "temperature.gpu") return "GPU Temp"
                    if (blockDelegate.bSource === "temperature.nvme") return "NVMe Temp"
                    if (blockDelegate.bSource === "temperature.hdd") return "HDD Temp"
                    if (blockDelegate.bSource === "network.download") return "Network Down"
                    if (blockDelegate.bSource === "network.upload") return "Network Up"
                    return (blockDelegate.bSource.length > 0 ? blockDelegate.bSource : "Metric")
                  }
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 11
                  font.bold: true
                  color: Commons.Color.foreground
                  elide: Text.ElideRight
                }

                // Up button
                Rectangle {
                  Layout.preferredWidth: 28
                  Layout.preferredHeight: 28
                  radius: 3
                  color: upHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.15) : Qt.rgba(0, 0, 0, 0)
                  opacity: blockDelegate.index > 0 ? 1.0 : 0.25

                  HoverHandler { id: upHov; cursorShape: blockDelegate.index > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor }
                  TapHandler {
                    enabled: blockDelegate.index > 0
                    onTapped: root.moveBlockRequested(blockDelegate.bId, -1)
                  }

                  Text {
                    anchors.centerIn: parent
                    text: "▲"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 10
                    color: Commons.Color.foreground
                  }
                }

                // Down button
                Rectangle {
                  Layout.preferredWidth: 28
                  Layout.preferredHeight: 28
                  radius: 3
                  color: dnHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.15) : Qt.rgba(0, 0, 0, 0)
                  opacity: blockDelegate.index < (root.blockList.length - 1) ? 1.0 : 0.25

                  HoverHandler { id: dnHov; cursorShape: blockDelegate.index < (root.blockList.length - 1) ? Qt.PointingHandCursor : Qt.ArrowCursor }
                  TapHandler {
                    enabled: blockDelegate.index < (root.blockList.length - 1)
                    onTapped: root.moveBlockRequested(blockDelegate.bId, 1)
                  }

                  Text {
                    anchors.centerIn: parent
                    text: "▼"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 10
                    color: Commons.Color.foreground
                  }
                }

                // Remove / Hide button
                Rectangle {
                  Layout.preferredWidth: 28
                  Layout.preferredHeight: 28
                  radius: 3
                  color: rmHov.hovered ? Commons.Util.alpha(Commons.Color.urgent, 0.25) : Qt.rgba(0, 0, 0, 0)

                  HoverHandler { id: rmHov; cursorShape: Qt.PointingHandCursor }
                  TapHandler {
                    onTapped: root.removeBlockRequested(blockDelegate.bId)
                  }

                  Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 10
                    color: rmHov.hovered ? Commons.Color.urgent : Commons.Color.muted
                  }
                }
              }

              // Row 2: Explicit variant selectors
              RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                  model: BlockRegistry.variants(blockDelegate.bKind)

                  Rectangle {
                    id: varBtn
                    required property var modelData
                    readonly property bool isActive: varBtn.modelData.variant === blockDelegate.bVariant

                    Layout.preferredHeight: 28
                    implicitWidth: varBtnRow.implicitWidth + 12
                    radius: 3
                    color: varBtn.isActive
                      ? Commons.Util.alpha(Commons.Color.accent, 0.35)
                      : (varBtnHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.12) : Commons.Util.alpha(Commons.Color.foreground, 0.05))
                    border.color: varBtn.isActive
                      ? Commons.Color.accent
                      : Commons.Util.alpha(Commons.Color.foreground, 0.15)
                    border.width: 1

                    HoverHandler {
                      id: varBtnHov
                      cursorShape: varBtn.isActive ? Qt.ArrowCursor : Qt.PointingHandCursor
                    }

                    TapHandler {
                      enabled: !varBtn.isActive
                      onTapped: root.variantRequested(blockDelegate.bId, varBtn.modelData.variant)
                    }

                    RowLayout {
                      id: varBtnRow
                      anchors.centerIn: parent
                      spacing: 4

                      Text {
                        visible: Boolean(varBtn.modelData.icon)
                        text: varBtn.modelData.icon || ""
                        font.family: Commons.Style.fontFamily
                        font.pixelSize: 10
                        color: varBtn.isActive ? Commons.Color.accent : Commons.Color.foreground
                      }

                      Text {
                        id: varBtnText
                        text: varBtn.modelData.label
                        font.family: Commons.Style.fontFamily
                        font.pixelSize: 10
                        font.bold: varBtn.isActive
                        color: varBtn.isActive ? Commons.Color.accent : Commons.Color.foreground
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Empty block message
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: 40
          visible: root.blockList.length === 0

          Text {
            anchors.centerIn: parent
            text: root.selectedContainer ? "All blocks in this container are hidden.\nToggle a domain block above to show it." : "Select a container to manage blocks."
            horizontalAlignment: Text.AlignHCenter
            font.family: Commons.Style.fontFamily
            font.pixelSize: 10
            color: Commons.Color.muted
          }
        }
      }
    }

    Components.AppPickerModal {
      id: appPickerModal
      anchors.fill: parent
      z: 2000
      onClosed: active = false
      onAppSelected: function(name, icon, command, sub) {
        active = false
        root.addShortcutItem("app-grid", {
          name: name,
          icon: icon,
          command: command,
          sub: sub
        })
      }
    }

    Components.FileFolderPickerModal {
      id: fileFolderPickerModal
      anchors.fill: parent
      z: 2000
      onClosed: active = false
      onItemSelected: function(name, path, isFile, icon) {
        active = false
        root.addShortcutItem("folder-grid", {
          name: name,
          path: path,
          isFile: isFile,
          icon: icon
        })
      }
    }
  }
}
