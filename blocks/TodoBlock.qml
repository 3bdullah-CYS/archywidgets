pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive

// OmaDesk — TodoBlock (Presentation-only block)
// Displays tasks from Omarchy To-Do List plugin via shared dataHub.
// Interactive checkbox toggles task completion through actionHub.
// Supports inline task creation and deletion with atomic synchronization.
// Zero internal Timer or Process objects.

Item {
  id: root
  clip: true

  required property var blockData
  required property var dataHub
  property var actionHub: null
  property string resolvedPresentation: "auto"
  property real densityScale: 1.0
  property bool isOverlay: false
  property bool showAddInput: isOverlay || false

  signal closeRequested()

  readonly property int implicitContentHeight: mainCol.implicitHeight

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  readonly property var itemsList: (root.dataHub && Array.isArray(root.dataHub.todoItems)) ? root.dataHub.todoItems : []
  readonly property int openCount: (root.dataHub && typeof root.dataHub.todoOpenCount === "number") ? root.dataHub.todoOpenCount : root.itemsList.length
  readonly property bool isAvailable: Boolean(root.dataHub && root.dataHub.todoAvailable)

  function submitTask() {
    var t = taskInput.text ? taskInput.text.trim() : ""
    if (t.length > 0) {
      if (root.actionHub && typeof root.actionHub.addTodo === "function") {
        root.actionHub.addTodo(t)
      }
      taskInput.text = ""
    }
  }

  function focusInput() {
    if (taskInput) {
      taskInput.forceActiveFocus()
    }
  }

  Component.onCompleted: {
    if (root.isOverlay) {
      Qt.callLater(root.focusInput)
    }
  }

  ColumnLayout {
    id: mainCol
    anchors.fill: parent
    anchors.margins: root.dp(8, 4)
    spacing: root.dp(6, 4)

    // Header strip with Task Count Chip & Actions
    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(6, 4)

      Text {
        text: "󰄱"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(14, 11)
        color: Commons.Color.accent
      }

      Text {
        text: root.isOverlay ? "To-Do List" : "Tasks"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(12, 10)
        font.bold: true
        color: Commons.Color.foreground
        Layout.fillWidth: true
      }

      Rectangle {
        Layout.preferredHeight: root.dp(18, 14)
        implicitWidth: countText.implicitWidth + root.dp(10, 6)
        radius: root.dp(9, 7)
        color: root.openCount > 0 ? Commons.Util.alpha(Commons.Color.accent, 0.18) : Commons.Util.alpha(Commons.Color.foreground, 0.08)
        border.color: root.openCount > 0 ? Commons.Util.alpha(Commons.Color.accent, 0.35) : "transparent"
        border.width: 1

        Text {
          id: countText
          anchors.centerIn: parent
          text: root.openCount > 0 ? (root.openCount + " open") : "All done"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(9, 8)
          font.bold: true
          color: root.openCount > 0 ? Commons.Color.accent : Commons.Color.muted
        }
      }

      // Add Task toggle button in header (for container mode)
      Rectangle {
        id: toggleAddBtn
        visible: !root.isOverlay
        Layout.preferredWidth: root.dp(20, 16)
        Layout.preferredHeight: root.dp(20, 16)
        radius: root.dp(4, 3)
        color: addTogHov.hovered
          ? Commons.Util.alpha(Commons.Color.accent, 0.20)
          : (root.showAddInput ? Commons.Util.alpha(Commons.Color.accent, 0.12) : "transparent")
        border.color: root.showAddInput ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.15)
        border.width: 1

        HoverHandler { id: addTogHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            root.showAddInput = !root.showAddInput
            if (root.showAddInput) Qt.callLater(root.focusInput)
          }
        }

        Text {
          anchors.centerIn: parent
          text: root.showAddInput ? "󰅖" : "󰐕"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 9)
          color: root.showAddInput ? Commons.Color.accent : Commons.Color.foreground
        }
      }

      // Close button in header (for overlay mode)
      Rectangle {
        id: closeBtn
        visible: root.isOverlay
        Layout.preferredWidth: root.dp(22, 18)
        Layout.preferredHeight: root.dp(22, 18)
        radius: root.dp(4, 3)
        color: closeHov.hovered ? Commons.Util.alpha(Commons.Color.urgent, 0.20) : "transparent"
        border.color: closeHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.15)
        border.width: 1

        HoverHandler { id: closeHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: root.closeRequested()
        }

        Text {
          anchors.centerIn: parent
          text: "󰅖"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(12, 10)
          color: closeHov.hovered ? Commons.Color.urgent : Commons.Color.muted
        }
      }
    }

    // Add Task Input Box
    Rectangle {
      id: addInputContainer
      visible: root.showAddInput || root.isOverlay || root.itemsList.length === 0
      Layout.fillWidth: true
      Layout.preferredHeight: root.dp(30, 24)
      radius: Math.max(3, Math.round(Commons.Style.cornerRadius * 0.35))
      color: Commons.Util.alpha(Commons.Color.foreground, 0.04)
      border.color: taskInput.activeFocus ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.15)
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.dp(8, 6)
        anchors.rightMargin: root.dp(6, 4)
        spacing: root.dp(6, 4)

        Text {
          text: "󰐕"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(12, 10)
          color: taskInput.activeFocus ? Commons.Color.accent : Commons.Color.muted
        }

        TextInput {
          id: taskInput
          Layout.fillWidth: true
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 9)
          color: Commons.Color.foreground
          clip: true
          selectByMouse: true

          Text {
            anchors.fill: parent
            text: "Add a task... (Press Enter)"
            font.family: parent.font.family
            font.pixelSize: parent.font.pixelSize
            color: Commons.Color.muted
            visible: !taskInput.text && !taskInput.activeFocus
            verticalAlignment: Text.AlignVCenter
          }

          onAccepted: root.submitTask()
        }

        // Submit action button
        Rectangle {
          id: submitBtn
          visible: taskInput.text && taskInput.text.trim().length > 0
          Layout.preferredWidth: root.dp(20, 16)
          Layout.preferredHeight: root.dp(20, 16)
          radius: root.dp(4, 3)
          color: submitHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.80)

          HoverHandler { id: submitHov; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: root.submitTask()
          }

          Text {
            anchors.centerIn: parent
            text: "󰄬"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(11, 9)
            color: Commons.Color.background
          }
        }
      }
    }

    // Task List or Empty State
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true

      // Empty / Completed State
      ColumnLayout {
        anchors.centerIn: parent
        visible: root.itemsList.length === 0
        spacing: root.dp(4, 2)

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: root.isAvailable ? "󰄬" : "󰄱"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(24, 18)
          color: root.isAvailable ? Commons.Color.accent : Commons.Color.muted
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: root.isAvailable ? "All caught up!" : "No tasks found"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 9)
          font.bold: true
          color: Commons.Color.foreground
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: root.isAvailable ? "Great job, enjoy your focus time." : "Type above to add your first task."
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(9, 8)
          color: Commons.Color.muted
        }
      }

      // Active Items Flickable List
      Flickable {
        id: flick
        anchors.fill: parent
        visible: root.itemsList.length > 0
        contentHeight: listCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
          id: listCol
          width: flick.width
          spacing: root.dp(4, 2)

          Repeater {
            model: root.itemsList

            Rectangle {
              id: taskRow
              required property var modelData
              required property int index
              Layout.fillWidth: true
              implicitHeight: Math.max(root.dp(28, 22), rowContent.implicitHeight + root.dp(6, 4))
              radius: Math.max(3, Math.round(Commons.Style.cornerRadius * 0.35))
              color: rowHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.06) : Commons.Util.alpha(Commons.Color.foreground, 0.02)
              border.color: rowHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.25) : "transparent"
              border.width: 1

              HoverHandler { id: rowHov }

              RowLayout {
                id: rowContent
                anchors.fill: parent
                anchors.leftMargin: root.dp(6, 4)
                anchors.rightMargin: root.dp(6, 4)
                spacing: root.dp(6, 4)

                // Interactive Checkbox
                Rectangle {
                  id: checkContainer
                  Layout.preferredWidth: root.dp(16, 12)
                  Layout.preferredHeight: root.dp(16, 12)
                  radius: root.dp(4, 3)
                  color: taskRow.modelData.done ? Commons.Color.accent : "transparent"
                  border.color: taskRow.modelData.done ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.30)
                  border.width: Commons.Style.normalBorderWidth

                  HoverHandler { id: checkHov; cursorShape: Qt.PointingHandCursor }
                  TapHandler {
                    onTapped: {
                      if (root.actionHub && typeof root.actionHub.toggleTodo === "function") {
                        root.actionHub.toggleTodo(taskRow.modelData.id)
                      }
                    }
                  }

                  Text {
                    anchors.centerIn: parent
                    visible: taskRow.modelData.done
                    text: "✓"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: root.dp(10, 8)
                    font.bold: true
                    color: Commons.Color.background
                  }
                }

                // Interactive Task Text
                Text {
                  id: taskTextItem
                  Layout.fillWidth: true
                  textFormat: Text.PlainText
                  text: taskRow.modelData.text || ""
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: root.dp(11, 9)
                  font.strikeout: taskRow.modelData.done
                  color: taskRow.modelData.done ? Commons.Color.muted : Commons.Color.foreground
                  elide: Text.ElideRight
                  maximumLineCount: 2
                  wrapMode: Text.WordWrap

                  HoverHandler { id: textHov; cursorShape: Qt.PointingHandCursor }
                  TapHandler {
                    onTapped: {
                      if (root.actionHub && typeof root.actionHub.toggleTodo === "function") {
                        root.actionHub.toggleTodo(taskRow.modelData.id)
                      }
                    }
                  }
                }

                // Delete Action Button
                Rectangle {
                  id: delBtn
                  Layout.preferredWidth: root.dp(20, 16)
                  Layout.preferredHeight: root.dp(20, 16)
                  radius: root.dp(4, 3)
                  opacity: (rowHov.hovered || delHov.hovered) ? 1.0 : 0.0
                  color: delHov.hovered ? Commons.Util.alpha(Commons.Color.urgent, 0.20) : "transparent"
                  border.color: delHov.hovered ? Commons.Color.urgent : "transparent"
                  border.width: 1

                  Behavior on opacity { NumberAnimation { duration: 120 } }

                  HoverHandler { id: delHov; cursorShape: Qt.PointingHandCursor }
                  TapHandler {
                    onTapped: {
                      if (root.actionHub && typeof root.actionHub.deleteTodo === "function") {
                        root.actionHub.deleteTodo(taskRow.modelData.id)
                      }
                    }
                  }

                  Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: root.dp(11, 9)
                    color: delHov.hovered ? Commons.Color.urgent : Commons.Color.muted
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
