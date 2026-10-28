pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons as Commons
import "." as Components

// OmaDesk — AppPickerModal
// Native, lightweight, theme-reactive modal for discovering and selecting installed desktop applications.

Rectangle {
  id: root

  property bool active: false

  signal appSelected(string name, string icon, string command, string sub)
  signal closed()

  onActiveChanged: {
    if (root.active && typeof searchInput !== "undefined" && searchInput) {
      searchInput.text = ""
    }
  }

  readonly property var rawApps: {
    if (!root.active) return []
    var list = []
    if (typeof DesktopEntries !== "undefined" && DesktopEntries && DesktopEntries.applications && DesktopEntries.applications.values) {
      list = DesktopEntries.applications.values
    }
    var res = []
    for (var i = 0; i < list.length; i++) {
      var e = list[i]
      if (!e || !e.name) continue
      var n = String(e.name).trim()
      var id = String(e.id || "").trim()
      var ic = String(e.icon || "").trim()
      var gn = String(e.genericName || e.comment || "").trim()
      if (!n) continue
      res.push({
        name: n,
        id: id,
        icon: ic,
        sub: gn,
        command: id ? ("gtk-launch " + (id.endsWith(".desktop") ? id : (id + ".desktop"))) : n.toLowerCase()
      })
    }
    res.sort(function(a, b) {
      return a.name.localeCompare(b.name)
    })
    return res
  }

  readonly property var filteredApps: {
    var apps = root.rawApps
    if (!apps || !Array.isArray(apps)) return []
    var query = (typeof searchInput !== "undefined" && searchInput && searchInput.text) ? searchInput.text.trim().toLowerCase() : ""
    if (!query) return apps
    return apps.filter(function(app) {
      if (!app) return false
      var nm = (app.name || "").toLowerCase()
      var sb = (app.sub || "").toLowerCase()
      var id = (app.id || "").toLowerCase()
      return nm.indexOf(query) !== -1 || sb.indexOf(query) !== -1 || id.indexOf(query) !== -1
    })
  }

  anchors.fill: parent
  visible: root.active
  color: Commons.Util.alpha(Commons.Color.background, 0.75)
  z: 1000

  // Click outside to dismiss
  TapHandler {
    onTapped: root.closed()
  }

  Rectangle {
    id: modalBox
    anchors.centerIn: parent
    width: Math.min(360, parent.width - 24)
    height: Math.min(480, parent.height - 32)
    radius: Commons.Style.cornerRadius
    color: Commons.Util.alpha(Commons.Color.background, 0.98)
    border.color: Commons.Util.alpha(Commons.Color.accent, 0.40)
    border.width: Commons.Style.normalBorderWidth
    clip: true

    // Intercept clicks so they don't dismiss modal
    TapHandler {
      gesturePolicy: TapHandler.WithinBounds
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 8

      // Header row
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
          text: "󰀻"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 14
          color: Commons.Color.accent
        }

        Text {
          text: "Select Application"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 12
          font.bold: true
          color: Commons.Color.foreground
          Layout.fillWidth: true
        }

        Rectangle {
          Layout.preferredWidth: 22
          Layout.preferredHeight: 22
          radius: 3
          color: closeHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

          HoverHandler { id: closeHov; cursorShape: Qt.PointingHandCursor }
          TapHandler { onTapped: root.closed() }

          Text {
            anchors.centerIn: parent
            text: "✕"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 10
            color: closeHov.hovered ? "#ffffff" : Commons.Color.foreground
          }
        }
      }

      // Search Box
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 30
        radius: 4
        color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
        border.color: searchInput.activeFocus ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.15)
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 8
          anchors.rightMargin: 8
          spacing: 6

          Text {
            text: "󰍉"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 12
            color: searchInput.activeFocus ? Commons.Color.accent : Commons.Color.muted
          }

          TextInput {
            id: searchInput
            Layout.fillWidth: true
            font.family: Commons.Style.fontFamily
            font.pixelSize: 11
            color: Commons.Color.foreground
            clip: true
            verticalAlignment: TextInput.AlignVCenter

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              visible: !searchInput.text && !searchInput.activeFocus
              text: "Search installed apps..."
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              color: Commons.Color.muted
            }
          }

          Text {
            visible: searchInput.text.length > 0
            text: "✕"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 10
            color: Commons.Color.muted
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: searchInput.text = "" }
          }
        }
      }

      // Results ListView
      ListView {
        id: appListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: root.filteredApps

        delegate: Rectangle {
          id: appDelegate
          required property var modelData
          required property int index

          width: appListView.width
          height: 36
          radius: 4
          color: appHover.hovered
            ? Commons.Util.alpha(Commons.Color.accent, 0.16)
            : Commons.Util.alpha(Commons.Color.foreground, 0.04)
          border.color: appHover.hovered
            ? Commons.Color.accent
            : Commons.Util.alpha(Commons.Color.foreground, 0.08)
          border.width: 1

          HoverHandler { id: appHover; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              root.appSelected(
                appDelegate.modelData.name,
                appDelegate.modelData.icon || "󰀻",
                appDelegate.modelData.command,
                appDelegate.modelData.sub
              )
              root.closed()
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            // App Icon
            Rectangle {
              Layout.preferredWidth: 24
              Layout.preferredHeight: 24
              radius: 4
              color: Commons.Util.alpha(Commons.Color.foreground, 0.06)
              clip: true

              Image {
                id: appIconImg
                anchors.fill: parent
                anchors.margins: 2
                source: (appDelegate.modelData && appDelegate.modelData.icon && typeof Quickshell !== "undefined" && typeof Quickshell.iconPath === "function")
                  ? Quickshell.iconPath(appDelegate.modelData.icon, true)
                  : ""
                visible: status === Image.Ready
                asynchronous: true
                fillMode: Image.PreserveAspectFit
              }

              Text {
                anchors.centerIn: parent
                visible: !appIconImg.visible
                text: "󰀻"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 13
                color: Commons.Color.accent
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Text {
                text: appDelegate.modelData.name
                font.family: Commons.Style.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: Commons.Color.foreground
                elide: Text.ElideRight
                Layout.fillWidth: true
              }

              Text {
                visible: Boolean(appDelegate.modelData.sub)
                text: appDelegate.modelData.sub
                font.family: Commons.Style.fontFamily
                font.pixelSize: 9
                color: Commons.Color.muted
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }

            Text {
              text: "󰐕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 12
              color: appHover.hovered ? Commons.Color.accent : Commons.Color.muted
            }
          }
        }

        // Empty state
        Text {
          anchors.centerIn: parent
          visible: !root.filteredApps || root.filteredApps.length === 0
          text: (searchInput && searchInput.text) ? "No matching applications" : "Loading applications..."
          font.family: Commons.Style.fontFamily
          font.pixelSize: 11
          color: Commons.Color.muted
        }
      }
    }
  }
}
