pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "InternalLayoutEngine.js" as InternalLayout
import "ResponsiveMetrics.js" as Responsive
import "BlockRegistry.js" as BlockRegistry
import "components" as Components

// ArchyWidgets — ContainerHost
// Presentational host for composable containers and internal block grids.
// Bounded by outer desktop geometry; computes block geometry via InternalLayoutEngine.
// Fail-closed: invalid layout or schema instantiates zero BlockHost delegates.

Item {
  id: root

  required property var containerData
  required property var dataHub
  property var actionHub: null
  property real cardAlpha: 0.45
  property bool editMode: false
  property bool previewMode: false

  signal blockMoveRequested(string blockId, var targetSlot)
  signal blockSelected(string blockId)
  signal blockVariantRequested(string containerId, string blockId, string variant)
  signal blockRemoveRequested(string containerId, string blockId)
  property string selectedBlockId: ""
  signal dragStarted(string containerId, real globalX, real globalY)
  signal dragMoved(string containerId, real globalX, real globalY)
  signal dragFinished(string containerId, real globalX, real globalY)
  signal resizeSpanRequested(string containerId, int newColSpan, int newRowSpan)
  signal removeContainerRequested(string containerId)
  signal addBlockRequested(string containerId)
  signal addApplicationRequested(string containerId)
  signal addFolderRequested(string containerId)
  signal addFileRequested(string containerId)
  signal itemRemoveRequested(string containerId, string blockId, string itemId)
  signal itemAddRequested(string containerId, string blockId, string kind)
  signal layoutModeToggleRequested(string containerId, string nextMode)

  property bool isDragging: false
  property bool isResizing: false
  property bool addMenuOpen: false
  onEditModeChanged: {
    if (!root.editMode) root.addMenuOpen = false
  }
  readonly property string containerId: (root.containerData && root.containerData.id) ? root.containerData.id : ""

  scale: root.isDragging ? 1.03 : 1.0
  z: root.isDragging ? 100 : (root.editMode ? 10 : 1)
  opacity: root.isDragging ? 0.9 : 1.0
  Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

  clip: !root.editMode

  readonly property string containerDomain: BlockRegistry.inferContainerDomain(root.containerData)
  readonly property var domainMeta: BlockRegistry.containerDomain(root.containerDomain)

  // Layout parameters
  readonly property real outerColSpan: (root.containerData && typeof root.containerData.colSpan === "number") ? root.containerData.colSpan : 1
  readonly property real outerRowSpan: (root.containerData && typeof root.containerData.rowSpan === "number") ? root.containerData.rowSpan : 1
  readonly property real referenceWidth: root.outerColSpan * 160 + Math.max(0, root.outerColSpan - 1) * 12
  readonly property real referenceHeight: root.outerRowSpan * 104 + Math.max(0, root.outerRowSpan - 1) * 12
  readonly property var density: Responsive.computeDensity(root.width, root.height, root.referenceWidth, root.referenceHeight)
  readonly property real densityScale: root.density.valid ? root.density.scale : 1.0
  readonly property bool tooSmall: root.density.mode === "too-small"
  readonly property bool isCompactHeader: root.width < 220 || root.outerColSpan <= 1

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  readonly property real containerPadding: root.dp(8, 5)
  readonly property real internalGap: root.dp(6, 3)

  readonly property int internalColumns: (root.containerData && typeof root.containerData.colSpan === "number") ? root.containerData.colSpan * 2 : 2
  readonly property int internalRows: (root.containerData && typeof root.containerData.rowSpan === "number") ? root.containerData.rowSpan * 2 : 2

  readonly property string headerMode: (root.containerData && typeof root.containerData.headerMode === "string") ? root.containerData.headerMode : "none"
  readonly property bool isHeaderSupported: headerMode === "none" || headerMode === "compact" || headerMode === "normal"

  readonly property real headerHeight: headerMode === "compact" ? root.dp(20, 14) : (headerMode === "normal" ? root.dp(28, 18) : 0)
  readonly property real headerGap: headerMode === "none" ? 0 : root.dp(6, 3)

  readonly property real contentX: root.containerPadding
  readonly property real contentY: root.containerPadding + (root.headerHeight > 0 ? (root.headerHeight + root.headerGap) : 0)
  readonly property real contentWidth: Math.max(0, root.width - root.containerPadding * 2)
  readonly property real contentHeight: Math.max(0, root.height - root.contentY - root.containerPadding)

  // Internal layout evaluation
  readonly property var layoutResult: {
    if (!root.containerData || typeof root.containerData !== "object" || Array.isArray(root.containerData)) {
      return { valid: false, errorCode: "INVALID_CONTAINER_DATA", placements: [] }
    }
    // Repeater modelData crosses a QML QVariant boundary. Clone it back to a
    // native JS object so nested `blocks` remains a real Array for the pure JS
    // layout engine (Array.isArray(QVariantList) is false at runtime).
    var containerSnapshot
    try {
      containerSnapshot = JSON.parse(JSON.stringify(root.containerData))
    } catch (e) {
      return { valid: false, errorCode: "INVALID_CONTAINER_DATA", placements: [] }
    }
    if (!root.isHeaderSupported) {
      return { valid: false, errorCode: "INVALID_HEADER_MODE", placements: [] }
    }
    if (root.contentWidth <= 0 || root.contentHeight <= 0) {
      return { valid: false, errorCode: "INVALID_CONTENT_DIMENSIONS", placements: [] }
    }

    var blocks = Array.isArray(containerSnapshot.blocks) ? containerSnapshot.blocks : []
    var metrics = InternalLayout.computeInternalMetrics(
      root.contentWidth,
      root.contentHeight,
      root.internalColumns,
      root.internalRows,
      root.internalGap
    )

    if (!metrics || !metrics.valid) {
      return { valid: false, errorCode: "INVALID_CONTAINER_LAYOUT", placements: [] }
    }

    var packed = InternalLayout.layoutBlocks(containerSnapshot, metrics)
    if (!packed || !packed.fits || !Array.isArray(packed.placements) || packed.placements.length !== blocks.length) {
      var errCode = (packed && packed.errors && packed.errors.length > 0 && packed.errors[0].code) ? packed.errors[0].code : "INVALID_CONTAINER_LAYOUT"
      return { valid: false, errorCode: errCode, placements: [] }
    }

    // Map internal cells to pixel geometry relative to content area
    var blockPlacements = []
    for (var i = 0; i < packed.placements.length; i++) {
      var p = packed.placements[i]
      var originalBlock = blocks[p.index]
      if (!originalBlock) continue

      blockPlacements.push({
        placement: p,
        blockData: originalBlock,
        x: p.x,
        y: p.y,
        width: p.width,
        height: p.height,
        resolvedPresentation: p.resolvedPresentation || "auto"
      })
    }

    return {
      valid: true,
      errorCode: "",
      placements: blockPlacements,
      metrics: metrics
    }
  }

  readonly property var blockDensity: {
    if (!root.layoutResult.valid || !root.layoutResult.metrics) return root.density
    var cellDensity = Responsive.computeDensity(
      root.layoutResult.metrics.cellWidth,
      root.layoutResult.metrics.cellHeight,
      77,
      51
    )
    if (!cellDensity.valid) return root.density
    return {
      valid: true,
      rawScale: Math.min(root.density.rawScale, cellDensity.rawScale),
      scale: Math.min(root.densityScale, cellDensity.scale),
      mode: (root.tooSmall || cellDensity.mode === "too-small") ? "too-small" :
            ((root.density.mode === "compact" || cellDensity.mode === "compact") ? "compact" : "normal")
    }
  }

  // Outer container background surface
  Rectangle {
    id: bgSurface
    anchors.fill: parent
    radius: Commons.Style.cornerRadius
    color: Commons.Util.alpha(Commons.Color.background, root.cardAlpha)
    border.color: Commons.Util.alpha(Commons.Color.foreground, 0.14)
    border.width: Commons.Style.normalBorderWidth
  }

  // Header row (rendered only if headerMode is compact or normal)
  RowLayout {
    id: headerRow
    visible: !root.editMode && root.headerMode !== "none" && root.headerHeight > 0
    x: root.containerPadding
    y: root.containerPadding
    width: root.contentWidth
    height: root.headerHeight
    spacing: root.dp(6, 3)

    Text {
      text: (root.domainMeta && root.domainMeta.icon) ? root.domainMeta.icon : "󰍛"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.headerMode === "compact" ? root.dp(11, 10) : root.dp(13, 10)
      color: Commons.Color.accent
      Layout.alignment: Qt.AlignVCenter
    }

    Text {
      text: (root.containerData && root.containerData.title)
        ? root.containerData.title
        : ((root.domainMeta && root.domainMeta.title) ? root.domainMeta.title : "")
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.headerMode === "compact" ? root.dp(11, 10) : root.dp(13, 10)
      font.bold: true
      color: Commons.Color.foreground
      elide: Text.ElideRight
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignVCenter
    }

    Components.BadgeTag {
      visible: root.width >= root.dp(170, 140) && Boolean(root.domainMeta && root.domainMeta.shortLabel)
      Layout.preferredHeight: root.dp(16, 13)
      badgeColor: Commons.Color.accent
      text: (root.domainMeta && root.domainMeta.shortLabel) ? root.domainMeta.shortLabel : ""
      Layout.alignment: Qt.AlignVCenter
    }
  }

  // Content area housing block delegates
  Item {
    id: contentArea
    x: root.contentX
    y: root.contentY
    width: root.contentWidth
    height: root.contentHeight
    visible: root.layoutResult.valid && !root.tooSmall

    Repeater {
      model: root.layoutResult.valid ? root.layoutResult.placements : []

      BlockHost {
        required property var modelData
        x: modelData.x
        y: modelData.y
        width: modelData.width
        height: modelData.height
        blockData: modelData.blockData
        dataHub: root.dataHub
        actionHub: root.actionHub
        resolvedPresentation: modelData.resolvedPresentation || "auto"
        densityScale: root.blockDensity.scale
        editMode: root.editMode
        previewMode: root.previewMode
        isSelected: Boolean(modelData.blockData && modelData.blockData.id === root.selectedBlockId)
        onSelected: root.blockSelected(modelData.blockData.id)
        onVariantRequested: function(variant) {
          root.blockVariantRequested(root.containerId, modelData.blockData.id, variant)
        }
        onMoveRequested: function(targetSlot) {
          root.blockMoveRequested(modelData.blockData.id, targetSlot)
        }
        onRemoveRequested: {
          root.blockRemoveRequested(root.containerId, modelData.blockData.id)
        }
        onItemAddRequested: {
          var k = (modelData.blockData && modelData.blockData.kind) ? modelData.blockData.kind : ""
          root.itemAddRequested(root.containerId, modelData.blockData.id, k)
        }
        onItemRemoveRequested: function(itemId) {
          root.itemRemoveRequested(root.containerId, modelData.blockData.id, itemId)
        }
      }
    }

    // Empty container prompt state
    Rectangle {
      id: emptyContainerPrompt
      anchors.centerIn: parent
      width: Math.min(parent.width - 16, 160)
      height: Math.min(parent.height - 16, 40)
      visible: root.layoutResult.valid && root.layoutResult.placements.length === 0 && !root.tooSmall
      radius: Commons.Style.cornerRadius
      color: emptyHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.22) : Commons.Util.alpha(Commons.Color.foreground, 0.06)
      border.color: emptyHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.18)
      border.width: Commons.Style.normalBorderWidth

      HoverHandler { id: emptyHov; cursorShape: Qt.PointingHandCursor }
      TapHandler {
        onTapped: root.addBlockRequested(root.containerId)
      }

      RowLayout {
        anchors.centerIn: parent
        spacing: 6

        Text {
          text: "󰐕"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 14
          color: Commons.Color.accent
        }

        Text {
          text: "Add Blocks"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }
      }
    }
  }

  // Contained error state for invalid schema or layout
  Rectangle {
    id: errorState
    anchors.fill: parent
    anchors.margins: 6
    visible: !root.layoutResult.valid || root.tooSmall
    radius: Commons.Style.cornerRadius
    color: Commons.Util.alpha(Commons.Color.background, 0.90)
    border.color: Commons.Util.alpha(Commons.Color.urgent, 0.60)
    border.width: 1
    z: 40

    ColumnLayout {
      anchors.centerIn: parent
      spacing: 4

      Text {
        text: root.tooSmall ? "Too small" : "⚠ Layout Error"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(11, 10)
        font.bold: true
        color: Commons.Color.urgent
        Layout.alignment: Qt.AlignHCenter
      }

      Text {
        text: root.tooSmall ? "Resize the container" : (root.layoutResult.errorCode || "INVALID_CONTAINER_LAYOUT")
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(10, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.70)
        Layout.alignment: Qt.AlignHCenter
      }
    }
  }

  // Edit / focus feedback overlay
  Rectangle {
    id: editOverlay
    anchors.fill: parent
    radius: Commons.Style.cornerRadius
    color: root.isDragging ? Commons.Util.alpha(Commons.Color.accent, 0.08) : "transparent"
    border.color: Commons.Color.accent
    border.width: Commons.Style.normalBorderWidth
    visible: root.editMode
    z: 50

    // Dismiss contextual menu when clicking outside
    MouseArea {
      anchors.fill: parent
      visible: root.addMenuOpen
      z: 1500
      onClicked: root.addMenuOpen = false
    }

    // Top action bar with drag handle and quick buttons
    Rectangle {
      id: editHeaderBar
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 24
      radius: Commons.Style.cornerRadius
      color: Commons.Util.alpha(Commons.Color.background, 0.98)
      border.color: Commons.Util.alpha(Commons.Color.accent, 0.40)
      border.width: Commons.Style.normalBorderWidth

      // Drag area
      MouseArea {
        anchors.fill: parent
        anchors.rightMargin: actionButtonsRow.implicitWidth + 12
        cursorShape: Qt.SizeAllCursor
        preventStealing: true

        property real grabOffsetX: 0
        property real grabOffsetY: 0

        onPressed: function(mouse) {
          root.isDragging = true
          grabOffsetX = mouse.x
          grabOffsetY = mouse.y
          var curX = root.x
          var curY = root.y
          root.dragStarted(root.containerId, curX, curY)
        }
        onPositionChanged: function(mouse) {
          if (!root.isDragging) return
          var curX = root.x + mouse.x - grabOffsetX
          var curY = root.y + mouse.y - grabOffsetY
          root.dragMoved(root.containerId, curX, curY)
        }
        onReleased: function(mouse) {
          if (root.isDragging) {
            root.isDragging = false
            var curX = root.x + mouse.x - grabOffsetX
            var curY = root.y + mouse.y - grabOffsetY
            root.dragFinished(root.containerId, curX, curY)
          }
        }
        onCanceled: {
          if (root.isDragging) {
            root.isDragging = false
            root.dragFinished(root.containerId, -1, -1)
          }
        }
      }

      // Title & size badge
      RowLayout {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.right: actionButtonsRow.left
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
          text: "󰇙󰇙"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 10
          color: Commons.Color.accent
        }

        Text {
          text: (root.containerData && root.containerData.title) ? root.containerData.title : "Container"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 10
          font.bold: true
          color: Commons.Color.foreground
          elide: Text.ElideRight
          Layout.fillWidth: true
          Layout.minimumWidth: 20
        }

        // Span badge with click-to-cycle
        Rectangle {
          Layout.preferredHeight: 16
          implicitWidth: spanBadgeText.implicitWidth + 6
          radius: 3
          color: spanHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.20)
          border.color: Commons.Color.accent
          border.width: 1

          HoverHandler { id: spanHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              var nextCol = (root.outerColSpan % 4) + 1
              root.resizeSpanRequested(root.containerId, nextCol, root.outerRowSpan)
            }
          }

          Text {
            id: spanBadgeText
            anchors.centerIn: parent
            text: root.outerColSpan + (root.isCompactHeader ? "×" : " × ") + root.outerRowSpan
            font.family: Commons.Style.fontFamily
            font.pixelSize: 9
            font.bold: true
            color: spanHov.hovered ? Commons.Color.background : Commons.Color.accent
          }
        }

        // Auto / Manual Reflow mode badge
        Rectangle {
          visible: root.width >= 165
          Layout.preferredHeight: 16
          implicitWidth: modeBadgeText.implicitWidth + (root.isCompactHeader ? 6 : 8)
          radius: 3
          readonly property bool isAuto: (root.containerData && root.containerData.layoutMode !== "manual")
          color: modeHov.hovered ? Commons.Color.accent : (isAuto ? Commons.Util.alpha(Commons.Color.accent, 0.20) : Commons.Util.alpha(Commons.Color.foreground, 0.10))
          border.color: isAuto ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.25)
          border.width: 1

          HoverHandler { id: modeHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              var nextMode = (root.containerData && root.containerData.layoutMode === "manual") ? "auto" : "manual"
              root.layoutModeToggleRequested(root.containerId, nextMode)
            }
          }

          Text {
            id: modeBadgeText
            anchors.centerIn: parent
            text: root.isCompactHeader
              ? ((root.containerData && root.containerData.layoutMode === "manual") ? "󰘳" : "󰑓")
              : ((root.containerData && root.containerData.layoutMode === "manual") ? "󰘳 Manual" : "󰑓 Auto")
            font.family: Commons.Style.fontFamily
            font.pixelSize: 9
            font.bold: true
            color: modeHov.hovered ? Commons.Color.background : (parent.isAuto ? Commons.Color.accent : Commons.Color.foreground)
          }
        }
      }

      // Action buttons (+ Block, Delete)
      RowLayout {
        id: actionButtonsRow
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Rectangle {
          id: addBlockBtn
          Layout.preferredHeight: 18
          implicitWidth: root.isCompactHeader ? 18 : (addBlockBtnText.implicitWidth + 8)
          radius: 3
          color: (addBlockHov.hovered || root.addMenuOpen) ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.background, 0.85)
          border.color: Commons.Color.accent
          border.width: 1

          HoverHandler { id: addBlockHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: root.addMenuOpen = !root.addMenuOpen
          }

          Text {
            id: addBlockBtnText
            anchors.centerIn: parent
            text: root.isCompactHeader ? "󰐕" : "+ Block"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.isCompactHeader ? 11 : 9
            font.bold: true
            color: (addBlockHov.hovered || root.addMenuOpen) ? Commons.Color.background : Commons.Color.accent
          }
        }

        Rectangle {
          Layout.preferredWidth: 18
          Layout.preferredHeight: 18
          radius: 3
          color: delContainerHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.background, 0.85)
          border.color: delContainerHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.urgent, 0.5)
          border.width: 1

          HoverHandler { id: delContainerHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: root.removeContainerRequested(root.containerId)
          }

          Text {
            anchors.centerIn: parent
            text: "󰆴"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 9
            color: delContainerHov.hovered ? "#ffffff" : Commons.Color.urgent
          }
        }
      }
    }

    // Contextual Add Dropdown Menu
    Rectangle {
      id: addContextMenu
      visible: root.addMenuOpen && root.editMode
      z: 2000
      anchors.top: editHeaderBar.bottom
      anchors.topMargin: 4
      anchors.right: editHeaderBar.right
      anchors.rightMargin: 6
      width: 180
      height: addMenuCol.implicitHeight + 10
      radius: Commons.Style.cornerRadius
      color: Commons.Util.alpha(Commons.Color.background, 0.96)
      border.color: Commons.Color.accent
      border.width: Commons.Style.normalBorderWidth || 1

      ColumnLayout {
        id: addMenuCol
        anchors.fill: parent
        anchors.margins: 5
        spacing: 2

        // 1. Add Application
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 26
          radius: Math.max(3, Math.round(Commons.Style.cornerRadius * 0.35))
          color: addAppHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.20) : "transparent"
          HoverHandler { id: addAppHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              root.addMenuOpen = false
              root.addApplicationRequested(root.containerId)
            }
          }
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8
            Text {
              text: "󰀻"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 12
              color: Commons.Color.accent
            }
            Text {
              Layout.fillWidth: true
              text: "Add Application..."
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: Commons.Color.foreground
              elide: Text.ElideRight
            }
          }
        }

        // 2. Add Folder
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 26
          radius: Math.max(3, Math.round(Commons.Style.cornerRadius * 0.35))
          color: addFldHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.20) : "transparent"
          HoverHandler { id: addFldHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              root.addMenuOpen = false
              root.addFolderRequested(root.containerId)
            }
          }
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8
            Text {
              text: "󰉋"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 12
              color: Commons.Color.accent
            }
            Text {
              Layout.fillWidth: true
              text: "Add Folder..."
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: Commons.Color.foreground
              elide: Text.ElideRight
            }
          }
        }

        // 3. Add File
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 26
          radius: Math.max(3, Math.round(Commons.Style.cornerRadius * 0.35))
          color: addFilHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.20) : "transparent"
          HoverHandler { id: addFilHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              root.addMenuOpen = false
              root.addFileRequested(root.containerId)
            }
          }
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8
            Text {
              text: "󰈙"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 12
              color: Commons.Color.accent
            }
            Text {
              Layout.fillWidth: true
              text: "Add File..."
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: true
              color: Commons.Color.foreground
              elide: Text.ElideRight
            }
          }
        }

        // Divider
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 1
          color: Commons.Util.alpha(Commons.Color.foreground, 0.12)
        }

        // 4. More Blocks (Drawer)
        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 26
          radius: Math.max(3, Math.round(Commons.Style.cornerRadius * 0.35))
          color: addMoreHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.20) : "transparent"
          HoverHandler { id: addMoreHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              root.addMenuOpen = false
              root.addBlockRequested(root.containerId)
            }
          }
          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8
            Text {
              text: "󱗼"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 12
              color: Commons.Color.muted
            }
            Text {
              Layout.fillWidth: true
              text: "More Blocks (Drawer)..."
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: Commons.Color.muted
              elide: Text.ElideRight
            }
          }
        }
      }
    }

    // Corner Resize Grip
    Rectangle {
      id: resizeGrip
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      width: 22
      height: 22
      radius: Commons.Style.cornerRadius
      color: resizeGripHov.hovered || root.isResizing
        ? Commons.Color.accent
        : Commons.Util.alpha(Commons.Color.background, 0.90)
      border.color: Commons.Color.accent
      border.width: Commons.Style.normalBorderWidth
      z: 70

      HoverHandler { id: resizeGripHov; cursorShape: Qt.SizeFDiagCursor }

      Text {
        anchors.centerIn: parent
        text: "󰛲"
        font.family: Commons.Style.fontFamily
        font.pixelSize: 11
        color: resizeGripHov.hovered || root.isResizing ? Commons.Color.background : Commons.Color.accent
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.SizeFDiagCursor
        preventStealing: true

        property real grabOffsetX: 0
        property real grabOffsetY: 0
        property real colPitch: 172
        property real rowPitch: 116
        property real colGap: 12
        property real rowGap: 12

        onPressed: function(mouse) {
          root.isResizing = true
          var p = mapToItem(root, mouse.x, mouse.y)
          grabOffsetX = root.width - p.x
          grabOffsetY = root.height - p.y
          colGap = 12
          rowGap = 12
          var spanC = Math.max(1, root.outerColSpan)
          var spanR = Math.max(1, root.outerRowSpan)
          colPitch = (root.width > 0 && spanC > 0) ? (root.width + colGap) / spanC : 172
          rowPitch = (root.height > 0 && spanR > 0) ? (root.height + rowGap) / spanR : 116
          if (colPitch <= 0) colPitch = 172
          if (rowPitch <= 0) rowPitch = 116
        }

        onPositionChanged: function(mouse) {
          if (!root.isResizing) return
          var p = mapToItem(root, mouse.x, mouse.y)
          var intendedWidth = p.x + grabOffsetX
          var intendedHeight = p.y + grabOffsetY
          var targetColSpan = Math.max(1, Math.min(4, Math.round((intendedWidth + colGap) / colPitch)))
          var targetRowSpan = Math.max(1, Math.min(3, Math.round((intendedHeight + rowGap) / rowPitch)))
          if (targetColSpan !== root.outerColSpan || targetRowSpan !== root.outerRowSpan) {
            root.resizeSpanRequested(root.containerId, targetColSpan, targetRowSpan)
          }
        }

        onReleased: function(mouse) {
          root.isResizing = false
        }
        onCanceled: {
          root.isResizing = false
        }
      }
    }
  }
}
