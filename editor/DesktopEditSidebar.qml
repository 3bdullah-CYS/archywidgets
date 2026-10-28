pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ContainerTemplateRegistry.js" as ContainerTemplateRegistry

// OmaDesk — DesktopEditSidebar
// Non-obstructing left vertical rail for unified desktop layout editing and customization studio.
// Houses three flyout panels: Container Catalog, Active Containers, and Desktop Settings.

Rectangle {
  id: root

  property bool canUndo: false
  property bool isDirty: false
  property string activeFlyout: ""
  property bool catalogOpen: activeFlyout === "catalog"
  property var containersList: []
  property string expandedContainerId: ""
  property real currentCardAlpha: 0.45
  property bool currentAutoHide: false
  property int currentTargetWorkspace: 1
  property string currentLayoutMode: "auto"

  signal addContainerRequested()
  signal emptyContainerRequested()
  signal containerTemplateSelected(string templateId)
  signal containerVisibilityToggled(string containerId)
  signal containerAddBlocksRequested(string containerId)
  signal containerRemoved(string containerId)
  signal containerTitleChanged(string containerId, string title)
  signal containerHeaderModeChanged(string containerId, string headerMode)
  signal containerSpanRequested(string containerId, int colSpan, int rowSpan)
  signal cardAlphaRequested(real alpha)
  signal autoHideRequested(bool autoHide)
  signal targetWorkspaceRequested(int workspace)
  signal layoutModeRequested(string mode)
  signal autoPackRequested()
  signal undoRequested()
  signal cancelRequested()
  signal saveRequested()

  function openFlyout(name) {
    if (activeFlyout === name) {
      activeFlyout = ""
    } else {
      activeFlyout = name
    }
  }

  function closeFlyout() {
    activeFlyout = ""
  }

  function containerIcon(c) {
    if (!c) return ""
    var id = (c.id || "").toLowerCase()
    var domain = (c.domain || "").toLowerCase()
    if (domain === "system" || id.indexOf("clock") !== -1 || id.indexOf("date") !== -1) return "󰥔"
    if (domain === "telemetry" || domain === "hardware" || id.indexOf("hardware") !== -1) return "󰍛"
    if (domain === "files" || domain === "media" || id.indexOf("media") !== -1 || id.indexOf("files") !== -1) return "󰉋"
    if (domain === "apps" || id.indexOf("app") !== -1) return "󰀻"
    if (domain === "todo" || id.indexOf("todo") !== -1) return "󰄲"
    if (domain === "notifications" || id.indexOf("notif") !== -1) return "󰂚"
    return ""
  }

  function containerDisplayName(c) {
    if (!c) return ""
    if (c.title && c.title.trim()) return c.title
    var id = c.id || "Container"
    return id.replace(/_/g, " ").replace(/\b\w/g, function(l) { return l.toUpperCase() })
  }

  width: 52
  radius: Commons.Style.cornerRadius
  color: Commons.Util.alpha(Commons.Color.background, 0.94)
  border.color: Commons.Util.alpha(Commons.Color.accent, 0.5)
  border.width: Commons.Style.normalBorderWidth

  // =========================================================================
  // Flyout 1: Container Templates Catalog Panel
  // =========================================================================
  Rectangle {
    id: catalogFlyout
    visible: root.activeFlyout === "catalog"
    x: parent.width + 12
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 280
    radius: Commons.Style.cornerRadius
    color: Commons.Color.background
    border.color: Commons.Util.alpha(Commons.Color.accent, 0.45)
    border.width: Commons.Style.normalBorderWidth
    z: 500
    clip: true

    ColumnLayout {
      id: catalogCol
      anchors.fill: parent
      anchors.margins: 12
      spacing: 10

      // Header with Title and Close Button
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "󱗼 Add Container"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 13
          font.bold: true
          color: Commons.Color.foreground
          Layout.fillWidth: true
        }

        Rectangle {
          Layout.preferredWidth: 20
          Layout.preferredHeight: 20
          radius: 4
          color: closeHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

          HoverHandler { id: closeHov; cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.closeFlyout() }

          Text {
            anchors.centerIn: parent
            text: "✕"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 10
            color: closeHov.hovered ? "#ffffff" : Commons.Color.foreground
          }
        }
      }

      // 1. First-Class Empty Custom Container Card
      Rectangle {
        id: emptyCard
        Layout.fillWidth: true
        Layout.preferredHeight: 46
        radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
        color: emptyHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.22) : Commons.Util.alpha(Commons.Color.accent, 0.08)
        border.color: emptyHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.35)
        border.width: 1

        HoverHandler { id: emptyHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            root.emptyContainerRequested()
            root.closeFlyout()
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 10

          Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 4
            color: emptyHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.20)

            Text {
              anchors.centerIn: parent
              text: "󰐕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 14
              color: emptyHov.hovered ? Commons.Color.background : Commons.Color.accent
            }
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
              text: "Empty Container"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.foreground
              elide: Text.ElideRight
              Layout.fillWidth: true
            }

            Text {
              text: "Start from scratch · Blank card"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              color: Commons.Color.muted
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }
        }
      }

      // Section Divider for Preconfigured Templates
      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 1
          color: Commons.Util.alpha(Commons.Color.foreground, 0.12)
        }

        Text {
          text: "Preconfigured Templates"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 9
          font.bold: true
          color: Commons.Color.muted
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: 1
          color: Commons.Util.alpha(Commons.Color.foreground, 0.12)
        }
      }

      // 2. Scrollable List of Preconfigured Templates
      ListView {
        id: tplListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 6
        model: ContainerTemplateRegistry.getAllTemplates()

        delegate: Rectangle {
          id: tplItem
          required property var modelData
          required property int index

          width: ListView.view.width
          height: 40
          radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
          color: tplHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.18) : Commons.Util.alpha(Commons.Color.foreground, 0.04)
          border.color: tplHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.10)
          border.width: 1

          HoverHandler { id: tplHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              if (modelData && modelData.id) {
                root.containerTemplateSelected(modelData.id)
                root.closeFlyout()
              }
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Text {
              text: (modelData && modelData.icon) ? modelData.icon : "󰐕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 15
              color: tplHov.hovered ? Commons.Color.accent : Commons.Color.foreground
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                text: (modelData && modelData.title) ? modelData.title : ""
                font.family: Commons.Style.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: Commons.Color.foreground
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                text: (modelData && modelData.desc) ? modelData.desc : ""
                font.family: Commons.Style.fontFamily
                font.pixelSize: 9
                color: Commons.Color.muted
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            Rectangle {
              Layout.preferredHeight: 16
              implicitWidth: spanText.implicitWidth + 8
              radius: 3
              color: Commons.Util.alpha(Commons.Color.accent, 0.15)
              border.color: Commons.Util.alpha(Commons.Color.accent, 0.30)
              border.width: 1

              Text {
                id: spanText
                anchors.centerIn: parent
                text: (modelData && modelData.span) ? modelData.span : "1×1"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 9
                font.bold: true
                color: Commons.Color.accent
              }
            }
          }
        }
      }
    }
  }

  // =========================================================================
  // Flyout 2: Active Containers List Panel
  // =========================================================================
  Rectangle {
    id: containersFlyout
    visible: root.activeFlyout === "containers"
    x: parent.width + 12
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 280
    radius: Commons.Style.cornerRadius
    color: Commons.Color.background
    border.color: Commons.Util.alpha(Commons.Color.accent, 0.45)
    border.width: Commons.Style.normalBorderWidth
    z: 500
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 10

      // Header with Title and Close Button
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: " Active Containers"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 13
          font.bold: true
          color: Commons.Color.foreground
          Layout.fillWidth: true
        }

        Rectangle {
          Layout.preferredWidth: 20
          Layout.preferredHeight: 20
          radius: 4
          color: cCloseHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

          HoverHandler { id: cCloseHov; cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.closeFlyout() }

          Text {
            anchors.centerIn: parent
            text: "✕"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 10
            color: cCloseHov.hovered ? "#ffffff" : Commons.Color.foreground
          }
        }
      }

      // Container Count Subtitle
      Text {
        text: (root.containersList ? root.containersList.length : 0) + " container(s) on desktop"
        font.family: Commons.Style.fontFamily
        font.pixelSize: 10
        color: Commons.Color.muted
      }

      // Empty state hint
      Rectangle {
        visible: !root.containersList || root.containersList.length === 0
        Layout.fillWidth: true
        Layout.preferredHeight: 64
        radius: 4
        color: Commons.Util.alpha(Commons.Color.foreground, 0.03)
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.08)
        border.width: 1

        ColumnLayout {
          anchors.centerIn: parent
          spacing: 3

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "No active containers"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 11
            color: Commons.Color.muted
          }

          Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Add one from the Catalog (󰐕)"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 9
            color: Commons.Color.accent
          }
        }
      }

      // Scrollable List of Active Containers
      ListView {
        id: containersListView
        visible: root.containersList && root.containersList.length > 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 6
        model: root.containersList || []

        delegate: Rectangle {
          id: cItem
          required property var modelData
          required property int index

          readonly property bool isExpanded: root.expandedContainerId === (modelData && modelData.id)

          width: ListView.view.width
          height: isExpanded ? (cContentCol.implicitHeight + 16) : 48
          radius: Math.max(4, Math.round(Commons.Style.cornerRadius * 0.45))
          color: isExpanded ? Commons.Util.alpha(Commons.Color.accent, 0.10) : (cItemHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.15) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
          border.color: isExpanded ? Commons.Color.accent : (cItemHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.6) : Commons.Util.alpha(Commons.Color.foreground, 0.10))
          border.width: 1
          clip: true

          Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

          HoverHandler { id: cItemHov }

          ColumnLayout {
            id: cContentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 8

            // Top Summary Row (always visible)
            RowLayout {
              Layout.fillWidth: true
              spacing: 6

              // Domain / Category Icon
              Text {
                text: root.containerIcon(modelData)
                font.family: Commons.Style.fontFamily
                font.pixelSize: 16
                color: Commons.Color.accent
              }

              // Info (Title, Blocks count, Span)
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                  text: root.containerDisplayName(modelData)
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 11
                  font.bold: true
                  color: Commons.Color.foreground
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                RowLayout {
                  spacing: 4
                  Text {
                    text: (modelData && modelData.blocks ? modelData.blocks.length : 0) + " blocks"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 9
                    color: Commons.Color.muted
                  }
                  Text {
                    text: "· " + ((modelData && modelData.colSpan) || 1) + "×" + ((modelData && modelData.rowSpan) || 1)
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 9
                    color: Commons.Color.muted
                  }
                }
              }

              // Configure / Details Toggle Button
              Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 4
                color: cItem.isExpanded ? Commons.Color.accent : (cfgHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.25) : Commons.Util.alpha(Commons.Color.foreground, 0.06))

                HoverHandler { id: cfgHov; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                  onTapped: {
                    if (modelData && modelData.id) {
                      root.expandedContainerId = (root.expandedContainerId === modelData.id ? "" : modelData.id)
                    }
                  }
                }

                Text {
                  anchors.centerIn: parent
                  text: "󰒓"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 12
                  color: cItem.isExpanded ? Commons.Color.background : (cfgHov.hovered ? Commons.Color.accent : Commons.Color.foreground)
                }
              }

              // Add Blocks action button
              Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 4
                color: addBlockHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.3) : Commons.Util.alpha(Commons.Color.accent, 0.1)

                HoverHandler { id: addBlockHov; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                  onTapped: {
                    if (modelData && modelData.id) {
                      root.containerAddBlocksRequested(modelData.id)
                    }
                  }
                }

                Text {
                  anchors.centerIn: parent
                  text: "󰐕"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 12
                  color: Commons.Color.accent
                }
              }

              // Visibility toggle button
              Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 4
                color: visHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.15) : Commons.Util.alpha(Commons.Color.foreground, 0.06)

                HoverHandler { id: visHov; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                  onTapped: {
                    if (modelData && modelData.id) {
                      root.containerVisibilityToggled(modelData.id)
                    }
                  }
                }

                Text {
                  anchors.centerIn: parent
                  text: (modelData && modelData.enabled === false) ? "󰄱" : "󰄲"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 12
                  color: (modelData && modelData.enabled === false) ? Commons.Color.muted : Commons.Color.accent
                }
              }

              // Delete action button
              Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 4
                color: delHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.06)

                HoverHandler { id: delHov; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                  onTapped: {
                    if (modelData && modelData.id) {
                      root.containerRemoved(modelData.id)
                    }
                  }
                }

                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 10
                  font.bold: true
                  color: delHov.hovered ? "#ffffff" : Commons.Color.foreground
                }
              }
            }

            // Expanded Inline Details Section
            ColumnLayout {
              visible: cItem.isExpanded
              Layout.fillWidth: true
              spacing: 8

              // Divider
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Commons.Util.alpha(Commons.Color.accent, 0.20)
              }

              // 1. Title Input
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                  text: "Container Title"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 9
                  font.bold: true
                  color: Commons.Color.muted
                }

                Rectangle {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 26
                  radius: 4
                  color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
                  border.color: titleInput.activeFocus ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.15)
                  border.width: 1

                  TextInput {
                    id: titleInput
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    verticalAlignment: TextInput.AlignVCenter
                    text: (modelData && modelData.title) ? modelData.title : ""
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 11
                    color: Commons.Color.foreground
                    selectByMouse: true
                    clip: true

                    onEditingFinished: {
                      if (modelData && modelData.id && text !== (modelData.title || "")) {
                        root.containerTitleChanged(modelData.id, text.trim())
                      }
                    }
                  }
                }
              }

              // 2. Header Bar Mode
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                  text: "Header Bar Style"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 9
                  font.bold: true
                  color: Commons.Color.muted
                }

                RowLayout {
                  Layout.fillWidth: true
                  spacing: 4

                  Repeater {
                    model: [
                      { label: "None", mode: "none" },
                      { label: "Compact", mode: "compact" },
                      { label: "Normal", mode: "normal" }
                    ]

                    delegate: Rectangle {
                      required property var modelData
                      required property int index
                      Layout.fillWidth: true
                      Layout.preferredHeight: 22
                      radius: 3
                      readonly property bool isSelected: (cItem.modelData && (cItem.modelData.headerMode || "none") === modelData.mode)
                      color: isSelected ? Commons.Color.accent : (hModeHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
                      border.color: isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
                      border.width: 1

                      HoverHandler { id: hModeHov; cursorShape: Qt.PointingHandCursor }
                      TapHandler {
                        onTapped: {
                          if (cItem.modelData && cItem.modelData.id) {
                            root.containerHeaderModeChanged(cItem.modelData.id, modelData.mode)
                          }
                        }
                      }

                      Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.family: Commons.Style.fontFamily
                        font.pixelSize: 9
                        font.bold: parent.isSelected
                        color: parent.isSelected ? Commons.Color.background : Commons.Color.foreground
                      }
                    }
                  }
                }
              }

              // 3. Direct Size Picker (Columns x Rows)
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                  text: "Size (Cols × Rows)"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 9
                  font.bold: true
                  color: Commons.Color.muted
                }

                // Columns row
                RowLayout {
                  Layout.fillWidth: true
                  spacing: 4

                  Text {
                    text: "W:"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 9
                    color: Commons.Color.muted
                    Layout.preferredWidth: 14
                  }

                  Repeater {
                    model: [1, 2, 3, 4]

                    delegate: Rectangle {
                      required property var modelData
                      required property int index
                      Layout.fillWidth: true
                      Layout.preferredHeight: 22
                      radius: 3
                      readonly property int curCol: (cItem.modelData && cItem.modelData.colSpan) || 1
                      readonly property int curRow: (cItem.modelData && cItem.modelData.rowSpan) || 1
                      readonly property bool isSelected: curCol === modelData
                      color: isSelected ? Commons.Color.accent : (colHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
                      border.color: isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
                      border.width: 1

                      HoverHandler { id: colHov; cursorShape: Qt.PointingHandCursor }
                      TapHandler {
                        onTapped: {
                          if (cItem.modelData && cItem.modelData.id) {
                            root.containerSpanRequested(cItem.modelData.id, modelData, curRow)
                          }
                        }
                      }

                      Text {
                        anchors.centerIn: parent
                        text: modelData + "c"
                        font.family: Commons.Style.fontFamily
                        font.pixelSize: 9
                        font.bold: parent.isSelected
                        color: parent.isSelected ? Commons.Color.background : Commons.Color.foreground
                      }
                    }
                  }
                }

                // Rows row
                RowLayout {
                  Layout.fillWidth: true
                  spacing: 4

                  Text {
                    text: "H:"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: 9
                    color: Commons.Color.muted
                    Layout.preferredWidth: 14
                  }

                  Repeater {
                    model: [1, 2, 3]

                    delegate: Rectangle {
                      required property var modelData
                      required property int index
                      Layout.fillWidth: true
                      Layout.preferredHeight: 22
                      radius: 3
                      readonly property int curCol: (cItem.modelData && cItem.modelData.colSpan) || 1
                      readonly property int curRow: (cItem.modelData && cItem.modelData.rowSpan) || 1
                      readonly property bool isSelected: curRow === modelData
                      color: isSelected ? Commons.Color.accent : (rowHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
                      border.color: isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
                      border.width: 1

                      HoverHandler { id: rowHov; cursorShape: Qt.PointingHandCursor }
                      TapHandler {
                        onTapped: {
                          if (cItem.modelData && cItem.modelData.id) {
                            root.containerSpanRequested(cItem.modelData.id, curCol, modelData)
                          }
                        }
                      }

                      Text {
                        anchors.centerIn: parent
                        text: modelData + "r"
                        font.family: Commons.Style.fontFamily
                        font.pixelSize: 9
                        font.bold: parent.isSelected
                        color: parent.isSelected ? Commons.Color.background : Commons.Color.foreground
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  // =========================================================================
  // Flyout 3: Desktop Settings & Appearance Panel
  // =========================================================================
  Rectangle {
    id: settingsFlyout
    visible: root.activeFlyout === "settings"
    x: parent.width + 12
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 280
    radius: Commons.Style.cornerRadius
    color: Commons.Color.background
    border.color: Commons.Util.alpha(Commons.Color.accent, 0.45)
    border.width: Commons.Style.normalBorderWidth
    z: 500
    clip: true

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 12

      // Header with Title and Close Button
      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "⚙ Desktop Settings"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 13
          font.bold: true
          color: Commons.Color.foreground
          Layout.fillWidth: true
        }

        Rectangle {
          Layout.preferredWidth: 20
          Layout.preferredHeight: 20
          radius: 4
          color: sCloseHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

          HoverHandler { id: sCloseHov; cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.closeFlyout() }

          Text {
            anchors.centerIn: parent
            text: "✕"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 10
            color: sCloseHov.hovered ? "#ffffff" : Commons.Color.foreground
          }
        }
      }

      // Section: Container Arrangement Mode (Manual vs Auto Arrange)
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Text {
          text: "Arrangement Mode"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }

        Text {
          text: "Choose how containers are positioned on desktop"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 9
          color: Commons.Color.muted
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          // Option: Manual Layout
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: Commons.Style.cornerRadius
            property bool isSelected: root.currentLayoutMode === "manual"
            color: isSelected ? Commons.Util.alpha(Commons.Color.accent, 0.25) : (manHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
            border.color: isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
            border.width: isSelected ? 1.5 : 1

            HoverHandler { id: manHov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.layoutModeRequested("manual") }

            RowLayout {
              anchors.centerIn: parent
              spacing: 6

              Text {
                text: "󰘳"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 13
                color: parent.parent.isSelected ? Commons.Color.accent : Commons.Color.foreground
              }

              Text {
                text: "Manual"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                font.bold: parent.parent.isSelected
                color: parent.parent.isSelected ? Commons.Color.accent : Commons.Color.foreground
              }
            }
          }

          // Option: Auto Arrange
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: Commons.Style.cornerRadius
            property bool isSelected: root.currentLayoutMode !== "manual"
            color: isSelected ? Commons.Util.alpha(Commons.Color.accent, 0.25) : (autoHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
            border.color: isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
            border.width: isSelected ? 1.5 : 1

            HoverHandler { id: autoHov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.layoutModeRequested("auto") }

            RowLayout {
              anchors.centerIn: parent
              spacing: 6

              Text {
                text: "󰑓"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 13
                color: parent.parent.isSelected ? Commons.Color.accent : Commons.Color.foreground
              }

              Text {
                text: "Auto Arrange"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                font.bold: parent.parent.isSelected
                color: parent.parent.isSelected ? Commons.Color.accent : Commons.Color.foreground
              }
            }
          }
        }

        Text {
          Layout.fillWidth: true
          text: root.currentLayoutMode === "manual" ? "Independent positioning: moving containers will not shift neighbors." : "Automatic packing: containers automatically compact into empty space."
          font.family: Commons.Style.fontFamily
          font.pixelSize: 9
          color: Commons.Color.muted
          wrapMode: Text.WordWrap
        }
      }

      // Divider
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Commons.Util.alpha(Commons.Color.foreground, 0.12)
      }

      // Section 1: Card Transparency Presets
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
          text: "Card Transparency"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }

        Text {
          text: "Background opacity for desktop cards"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 9
          color: Commons.Color.muted
        }

        // 4 Presets in a 2x2 grid
        GridLayout {
          Layout.fillWidth: true
          columns: 2
          rowSpacing: 6
          columnSpacing: 6

          // Preset 1: 30% Glass
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 4
            property real presetVal: 0.30
            property bool isSelected: Math.abs(root.currentCardAlpha - presetVal) < 0.05
            color: isSelected ? Commons.Util.alpha(Commons.Color.accent, 0.25) : (p1Hov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
            border.color: isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
            border.width: isSelected ? 1.5 : 1

            HoverHandler { id: p1Hov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.cardAlphaRequested(0.30) }

            Text {
              anchors.centerIn: parent
              text: "30% Glass"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: parent.isSelected
              color: parent.isSelected ? Commons.Color.accent : Commons.Color.foreground
            }
          }

          // Preset 2: 45% Balanced
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 4
            property real presetVal: 0.45
            property bool isSelected: Math.abs(root.currentCardAlpha - presetVal) < 0.05
            color: isSelected ? Commons.Util.alpha(Commons.Color.accent, 0.25) : (p2Hov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
            border.color: isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
            border.width: isSelected ? 1.5 : 1

            HoverHandler { id: p2Hov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.cardAlphaRequested(0.45) }

            Text {
              anchors.centerIn: parent
              text: "45% Balanced"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: parent.isSelected
              color: parent.isSelected ? Commons.Color.accent : Commons.Color.foreground
            }
          }

          // Preset 3: 65% Solid
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 4
            property real presetVal: 0.65
            property bool isSelected: Math.abs(root.currentCardAlpha - presetVal) < 0.05
            color: isSelected ? Commons.Util.alpha(Commons.Color.accent, 0.25) : (p3Hov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
            border.color: isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
            border.width: isSelected ? 1.5 : 1

            HoverHandler { id: p3Hov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.cardAlphaRequested(0.65) }

            Text {
              anchors.centerIn: parent
              text: "65% Solid"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: parent.isSelected
              color: parent.isSelected ? Commons.Color.accent : Commons.Color.foreground
            }
          }

          // Preset 4: 85% Opaque
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            radius: 4
            property real presetVal: 0.85
            property bool isSelected: Math.abs(root.currentCardAlpha - presetVal) < 0.05
            color: isSelected ? Commons.Util.alpha(Commons.Color.accent, 0.25) : (p4Hov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.08) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
            border.color: isSelected ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
            border.width: isSelected ? 1.5 : 1

            HoverHandler { id: p4Hov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.cardAlphaRequested(0.85) }

            Text {
              anchors.centerIn: parent
              text: "85% Opaque"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: parent.isSelected
              color: parent.isSelected ? Commons.Color.accent : Commons.Color.foreground
            }
          }
        }
      }

      // Divider
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Commons.Util.alpha(Commons.Color.foreground, 0.12)
      }

      // Section 2: Auto-hide on Windows
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        radius: 4
        color: autoHideHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.06) : Commons.Util.alpha(Commons.Color.foreground, 0.03)
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
        border.width: 1

        HoverHandler { id: autoHideHov; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: root.autoHideRequested(!root.currentAutoHide) }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 8

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
              text: "Auto-hide on Windows"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              font.bold: true
              color: Commons.Color.foreground
            }

            Text {
              text: "Hide when windows overlap"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              color: Commons.Color.muted
            }
          }

          // Toggle pill switch
          Rectangle {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 20
            radius: 10
            color: root.currentAutoHide ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.18)

            Rectangle {
              anchors.verticalCenter: parent.verticalCenter
              x: root.currentAutoHide ? (parent.width - width - 2) : 2
              width: 16
              height: 16
              radius: 8
              color: root.currentAutoHide ? Commons.Color.background : Commons.Color.foreground
              Behavior on x { NumberAnimation { duration: 150 } }
            }
          }
        }
      }

      // Divider
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 1
        color: Commons.Util.alpha(Commons.Color.foreground, 0.12)
      }

      // Section 3: Target Workspace
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        Text {
          text: "Target Workspace"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }

        Text {
          text: "Desktop workspace where ArchyWidgets is visible"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 9
          color: Commons.Color.muted
        }

        // Workspace Segmented Row: [All (0), 1, 2, 3, 4]
        RowLayout {
          Layout.fillWidth: true
          spacing: 4

          Repeater {
            model: [
              { label: "All", ws: 0 },
              { label: "1", ws: 1 },
              { label: "2", ws: 2 },
              { label: "3", ws: 3 },
              { label: "4", ws: 4 }
            ]

            delegate: Rectangle {
              required property var modelData
              required property int index
              Layout.fillWidth: true
              Layout.preferredHeight: 28
              radius: 4
              property bool isCurrent: root.currentTargetWorkspace === modelData.ws
              color: isCurrent ? Commons.Color.accent : (wsHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.10) : Commons.Util.alpha(Commons.Color.foreground, 0.04))
              border.color: isCurrent ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
              border.width: 1

              HoverHandler { id: wsHov; cursorShape: Qt.PointingHandCursor }
              TapHandler { onTapped: root.targetWorkspaceRequested(modelData.ws) }

              Text {
                anchors.centerIn: parent
                text: modelData.label
                font.family: Commons.Style.fontFamily
                font.pixelSize: 10
                font.bold: parent.isCurrent
                color: parent.isCurrent ? Commons.Color.background : Commons.Color.foreground
              }
            }
          }
        }
      }

      // Spacer
      Item {
        Layout.fillHeight: true
      }

      // Live feedback hint at bottom
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        radius: 4
        color: Commons.Util.alpha(Commons.Color.accent, 0.08)
        border.color: Commons.Util.alpha(Commons.Color.accent, 0.20)
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.margins: 6
          spacing: 6

          Text {
            text: "ℹ"
            font.pixelSize: 12
            color: Commons.Color.accent
          }

          Text {
            Layout.fillWidth: true
            text: "Live desktop preview active. Click ✓ to apply changes."
            font.family: Commons.Style.fontFamily
            font.pixelSize: 9
            color: Commons.Color.muted
            wrapMode: Text.WordWrap
          }
        }
      }
    }
  }

  // =========================================================================
  // Vertical Left Rail Action Bar (52px wide)
  // =========================================================================
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 8
    spacing: 10

    // Studio Icon Badge
    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      radius: Commons.Style.cornerRadius
      color: Commons.Util.alpha(Commons.Color.accent, 0.15)
      border.color: Commons.Util.alpha(Commons.Color.accent, 0.3)
      border.width: Commons.Style.normalBorderWidth

      Text {
        anchors.centerIn: parent
        text: "󱗼"
        font.family: Commons.Style.fontFamily
        font.pixelSize: 18
        color: Commons.Color.accent
      }
    }

    // Divider
    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 28
      Layout.preferredHeight: 1
      color: Commons.Util.alpha(Commons.Color.foreground, 0.15)
    }

    // Button 1: Add Container Catalog
    Rectangle {
      id: addBtn
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      radius: Commons.Style.cornerRadius
      color: (addHov.hovered || root.activeFlyout === "catalog") ? Commons.Util.alpha(Commons.Color.accent, 0.22) : Commons.Util.alpha(Commons.Color.foreground, 0.05)
      border.color: (addHov.hovered || root.activeFlyout === "catalog") ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
      border.width: Commons.Style.normalBorderWidth

      HoverHandler { id: addHov; cursorShape: Qt.PointingHandCursor }
      TapHandler {
        onTapped: root.openFlyout("catalog")
      }

      Text {
        anchors.centerIn: parent
        text: "󰐕"
        font.family: Commons.Style.fontFamily
        font.pixelSize: 16
        color: (addHov.hovered || root.activeFlyout === "catalog") ? Commons.Color.accent : Commons.Color.foreground
      }

      // Tooltip
      Rectangle {
        visible: addHov.hovered && root.activeFlyout !== "catalog"
        x: parent.width + 8
        anchors.verticalCenter: parent.verticalCenter
        width: addTipText.implicitWidth + 12
        height: 24
        radius: Commons.Style.cornerRadius
        color: Commons.Color.background
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.2)
        border.width: Commons.Style.normalBorderWidth
        z: 400

        Text {
          id: addTipText
          anchors.centerIn: parent
          text: "Container Catalog"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }
      }
    }

    // Button 2: Active Containers
    Rectangle {
      id: containersBtn
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      radius: Commons.Style.cornerRadius
      color: (containersHov.hovered || root.activeFlyout === "containers") ? Commons.Util.alpha(Commons.Color.accent, 0.22) : Commons.Util.alpha(Commons.Color.foreground, 0.05)
      border.color: (containersHov.hovered || root.activeFlyout === "containers") ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
      border.width: Commons.Style.normalBorderWidth

      HoverHandler { id: containersHov; cursorShape: Qt.PointingHandCursor }
      TapHandler {
        onTapped: root.openFlyout("containers")
      }

      Text {
        anchors.centerIn: parent
        text: ""
        font.family: Commons.Style.fontFamily
        font.pixelSize: 15
        color: (containersHov.hovered || root.activeFlyout === "containers") ? Commons.Color.accent : Commons.Color.foreground
      }

      // Tooltip
      Rectangle {
        visible: containersHov.hovered && root.activeFlyout !== "containers"
        x: parent.width + 8
        anchors.verticalCenter: parent.verticalCenter
        width: containersTipText.implicitWidth + 12
        height: 24
        radius: Commons.Style.cornerRadius
        color: Commons.Color.background
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.2)
        border.width: Commons.Style.normalBorderWidth
        z: 400

        Text {
          id: containersTipText
          anchors.centerIn: parent
          text: "Active Containers"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }
      }
    }

    // Button 3: Desktop Settings & Appearance
    Rectangle {
      id: settingsBtn
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      radius: Commons.Style.cornerRadius
      color: (settingsHov.hovered || root.activeFlyout === "settings") ? Commons.Util.alpha(Commons.Color.accent, 0.22) : Commons.Util.alpha(Commons.Color.foreground, 0.05)
      border.color: (settingsHov.hovered || root.activeFlyout === "settings") ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
      border.width: Commons.Style.normalBorderWidth

      HoverHandler { id: settingsHov; cursorShape: Qt.PointingHandCursor }
      TapHandler {
        onTapped: root.openFlyout("settings")
      }

      Text {
        anchors.centerIn: parent
        text: "⚙"
        font.family: Commons.Style.fontFamily
        font.pixelSize: 16
        color: (settingsHov.hovered || root.activeFlyout === "settings") ? Commons.Color.accent : Commons.Color.foreground
      }

      // Tooltip
      Rectangle {
        visible: settingsHov.hovered && root.activeFlyout !== "settings"
        x: parent.width + 8
        anchors.verticalCenter: parent.verticalCenter
        width: settingsTipText.implicitWidth + 12
        height: 24
        radius: Commons.Style.cornerRadius
        color: Commons.Color.background
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.2)
        border.width: Commons.Style.normalBorderWidth
        z: 400

        Text {
          id: settingsTipText
          anchors.centerIn: parent
          text: "Desktop Settings"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }
      }
    }

    // Button 4: Auto-Reflow
    Rectangle {
      id: reflowBtn
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      radius: Commons.Style.cornerRadius
      color: reflowHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.22) : Commons.Util.alpha(Commons.Color.foreground, 0.05)
      border.color: reflowHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
      border.width: Commons.Style.normalBorderWidth

      HoverHandler { id: reflowHov; cursorShape: Qt.PointingHandCursor }
      TapHandler {
        onTapped: root.autoPackRequested()
      }

      Text {
        anchors.centerIn: parent
        text: "󰕰"
        font.family: Commons.Style.fontFamily
        font.pixelSize: 16
        color: reflowHov.hovered ? Commons.Color.accent : Commons.Color.foreground
      }

      // Tooltip
      Rectangle {
        visible: reflowHov.hovered
        x: parent.width + 8
        anchors.verticalCenter: parent.verticalCenter
        width: reflowTipText.implicitWidth + 12
        height: 24
        radius: Commons.Style.cornerRadius
        color: Commons.Color.background
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.2)
        border.width: Commons.Style.normalBorderWidth
        z: 400

        Text {
          id: reflowTipText
          anchors.centerIn: parent
          text: root.currentLayoutMode === "manual" ? "Reflow to Auto (Snapshots)" : "Auto-Reflow Layout"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }
      }
    }

    // Button 5: Undo
    Rectangle {
      id: undoBtn
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      radius: Commons.Style.cornerRadius
      opacity: root.canUndo ? 1.0 : 0.35
      color: (root.canUndo && undoHov.hovered) ? Commons.Util.alpha(Commons.Color.accent, 0.22) : Commons.Util.alpha(Commons.Color.foreground, 0.05)
      border.color: (root.canUndo && undoHov.hovered) ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
      border.width: Commons.Style.normalBorderWidth

      HoverHandler { id: undoHov; cursorShape: root.canUndo ? Qt.PointingHandCursor : Qt.ArrowCursor }
      TapHandler {
        enabled: root.canUndo
        onTapped: root.undoRequested()
      }

      Text {
        anchors.centerIn: parent
        text: "↶"
        font.family: Commons.Style.fontFamily
        font.pixelSize: 17
        font.bold: true
        color: (root.canUndo && undoHov.hovered) ? Commons.Color.accent : Commons.Color.foreground
      }

      // Tooltip
      Rectangle {
        visible: root.canUndo && undoHov.hovered
        x: parent.width + 8
        anchors.verticalCenter: parent.verticalCenter
        width: undoTipText.implicitWidth + 12
        height: 24
        radius: Commons.Style.cornerRadius
        color: Commons.Color.background
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.2)
        border.width: Commons.Style.normalBorderWidth
        z: 400

        Text {
          id: undoTipText
          anchors.centerIn: parent
          text: "Undo (Ctrl+Z)"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }
      }
    }

    // Flexible spacer
    Item {
      Layout.fillHeight: true
    }

    // Divider
    Rectangle {
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 28
      Layout.preferredHeight: 1
      color: Commons.Util.alpha(Commons.Color.foreground, 0.15)
    }

    // Button 6: Cancel
    Rectangle {
      id: cancelBtn
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      radius: Commons.Style.cornerRadius
      color: cancelHov.hovered ? Commons.Util.alpha(Commons.Color.urgent, 0.22) : Commons.Util.alpha(Commons.Color.foreground, 0.05)
      border.color: cancelHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
      border.width: Commons.Style.normalBorderWidth

      HoverHandler { id: cancelHov; cursorShape: Qt.PointingHandCursor }
      TapHandler {
        onTapped: root.cancelRequested()
      }

      Text {
        anchors.centerIn: parent
        text: "✕"
        font.family: Commons.Style.fontFamily
        font.pixelSize: 14
        font.bold: true
        color: cancelHov.hovered ? Commons.Color.urgent : Commons.Color.foreground
      }

      // Tooltip
      Rectangle {
        visible: cancelHov.hovered
        x: parent.width + 8
        anchors.verticalCenter: parent.verticalCenter
        width: cancelTipText.implicitWidth + 12
        height: 24
        radius: Commons.Style.cornerRadius
        color: Commons.Color.background
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.2)
        border.width: Commons.Style.normalBorderWidth
        z: 400

        Text {
          id: cancelTipText
          anchors.centerIn: parent
          text: "Cancel (Esc)"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }
      }
    }

    // Button 7: Save & Apply
    Rectangle {
      id: saveBtn
      Layout.alignment: Qt.AlignHCenter
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      radius: Commons.Style.cornerRadius
      color: saveHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.25)
      border.color: Commons.Color.accent
      border.width: Commons.Style.normalBorderWidth

      HoverHandler { id: saveHov; cursorShape: Qt.PointingHandCursor }
      TapHandler {
        onTapped: root.saveRequested()
      }

      Text {
        anchors.centerIn: parent
        text: "✓"
        font.family: Commons.Style.fontFamily
        font.pixelSize: 16
        font.bold: true
        color: saveHov.hovered ? Commons.Color.background : Commons.Color.accent
      }

      // Tooltip
      Rectangle {
        visible: saveHov.hovered
        x: parent.width + 8
        anchors.verticalCenter: parent.verticalCenter
        width: saveTipText.implicitWidth + 12
        height: 24
        radius: Commons.Style.cornerRadius
        color: Commons.Color.background
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.2)
        border.width: Commons.Style.normalBorderWidth
        z: 400

        Text {
          id: saveTipText
          anchors.centerIn: parent
          text: "Save & Apply (Ctrl+S)"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          font.bold: true
          color: Commons.Color.foreground
        }
      }
    }
  }
}
