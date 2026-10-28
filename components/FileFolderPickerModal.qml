pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.Commons as Commons
import "." as Components

// OmaDesk — FileFolderPickerModal
// Native, lightweight, process-free modal for browsing and selecting folders and files.

Rectangle {
  id: root

  property bool active: false
  property string mode: "folder" // "folder" or "file"

  readonly property string homePath: Quickshell.env("HOME") || "/home"
  property string currentFolder: homePath

  signal itemSelected(string name, string path, bool isFile, string icon)
  signal closed()

  anchors.fill: parent
  visible: root.active
  color: Commons.Util.alpha(Commons.Color.background, 0.75)
  z: 1000

  // Click outside to dismiss
  TapHandler {
    onTapped: root.closed()
  }

  function resolveFileIcon(fileName) {
    if (!fileName || typeof fileName !== "string") return "󰈔"
    var lower = fileName.toLowerCase()
    var ext = lower.lastIndexOf(".") !== -1 ? lower.slice(lower.lastIndexOf(".")) : ""
    switch (ext) {
      case ".pdf":
      case ".doc":
      case ".docx":
      case ".txt":
      case ".md":
      case ".odt":
        return "󰈙"
      case ".png":
      case ".jpg":
      case ".jpeg":
      case ".svg":
      case ".webp":
      case ".gif":
        return "󰉏"
      case ".mp4":
      case ".mkv":
      case ".avi":
      case ".mov":
      case ".webm":
        return "󰕧"
      case ".mp3":
      case ".flac":
      case ".wav":
      case ".ogg":
        return "󰝚"
      case ".sh":
      case ".bash":
      case ".py":
      case ".js":
      case ".qml":
      case ".cpp":
      case ".c":
      case ".rs":
      case ".json":
        return "󰅪"
      case ".zip":
      case ".tar":
      case ".gz":
      case ".xz":
      case ".7z":
        return "󰛫"
      default:
        return "󰈔"
    }
  }

  function displayPath(fullPath) {
    if (!fullPath) return "~"
    if (fullPath.startsWith(root.homePath)) {
      return "~" + fullPath.slice(root.homePath.length)
    }
    return fullPath
  }

  Rectangle {
    id: modalBox
    anchors.centerIn: parent
    width: Math.min(390, parent.width - 24)
    height: Math.min(500, parent.height - 32)
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
          text: root.mode === "folder" ? "󰉋" : "󰈔"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 14
          color: Commons.Color.accent
        }

        Text {
          text: root.mode === "folder" ? "Select Folder" : "Select File"
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

      // Quick Bookmarks Bar
      RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: [
            { label: "~ Home", path: root.homePath },
            { label: "Downloads", path: root.homePath + "/Downloads" },
            { label: "Documents", path: root.homePath + "/Documents" },
            { label: "Projects", path: root.homePath + "/Projects" }
          ]

          Rectangle {
            id: bkmBtn
            required property var modelData
            Layout.preferredHeight: 22
            implicitWidth: bkmTxt.implicitWidth + 10
            radius: 3
            color: bkmHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

            HoverHandler { id: bkmHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: root.currentFolder = bkmBtn.modelData.path
            }

            Text {
              id: bkmTxt
              anchors.centerIn: parent
              text: bkmBtn.modelData.label
              font.family: Commons.Style.fontFamily
              font.pixelSize: 9
              font.bold: true
              color: bkmHov.hovered ? Commons.Color.background : Commons.Color.foreground
            }
          }
        }
      }

      // Current Path & Up Directory Bar
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 28
        radius: 4
        color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
        border.color: Commons.Util.alpha(Commons.Color.foreground, 0.12)
        border.width: 1

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 6
          anchors.rightMargin: 6
          spacing: 6

          Rectangle {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            radius: 3
            color: upHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.foreground, 0.10)

            HoverHandler { id: upHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
              onTapped: {
                if (folderModel.parentFolder && String(folderModel.parentFolder).length > 0) {
                  var p = String(folderModel.parentFolder)
                  if (p.startsWith("file://")) p = p.slice(7)
                  root.currentFolder = p
                }
              }
            }

            Text {
              anchors.centerIn: parent
              text: "󰁝"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 11
              color: upHov.hovered ? Commons.Color.background : Commons.Color.accent
            }
          }

          Text {
            Layout.fillWidth: true
            text: root.displayPath(root.currentFolder)
            font.family: Commons.Style.fontFamily
            font.pixelSize: 10
            font.bold: true
            color: Commons.Color.foreground
            elide: Text.ElideMiddle
          }
        }
      }

      // FolderListModel
      FolderListModel {
        id: folderModel
        folder: "file://" + root.currentFolder
        showDirs: true
        showFiles: root.mode === "file"
        showDotAndDotDot: false
        sortField: FolderListModel.Type
      }

      // Files / Folders List
      ListView {
        id: entriesListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 3
        model: folderModel

        delegate: Rectangle {
          id: entryDelegate
          required property string fileName
          required property string filePath
          required property bool fileIsDir
          required property int index

          width: entriesListView.width
          height: 32
          radius: 3
          color: entryHover.hovered
            ? Commons.Util.alpha(Commons.Color.accent, 0.16)
            : Commons.Util.alpha(Commons.Color.foreground, 0.03)
          border.color: entryHover.hovered
            ? Commons.Color.accent
            : Commons.Util.alpha(Commons.Color.foreground, 0.06)
          border.width: 1

          HoverHandler { id: entryHover; cursorShape: Qt.PointingHandCursor }
          TapHandler {
            onTapped: {
              if (entryDelegate.fileIsDir) {
                // Navigate into directory
                var p = String(entryDelegate.filePath)
                if (p.startsWith("file://")) p = p.slice(7)
                root.currentFolder = p
              } else {
                // File selected
                var fp = String(entryDelegate.filePath)
                if (fp.startsWith("file://")) fp = fp.slice(7)
                root.itemSelected(
                  entryDelegate.fileName,
                  fp,
                  true,
                  root.resolveFileIcon(entryDelegate.fileName)
                )
                root.closed()
              }
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 8

            Text {
              text: entryDelegate.fileIsDir ? "󰉋" : root.resolveFileIcon(entryDelegate.fileName)
              font.family: Commons.Style.fontFamily
              font.pixelSize: 12
              color: entryDelegate.fileIsDir ? Commons.Color.accent : Commons.Color.muted
            }

            Text {
              Layout.fillWidth: true
              text: entryDelegate.fileName
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              font.bold: entryDelegate.fileIsDir
              color: Commons.Color.foreground
              elide: Text.ElideRight
            }

            Text {
              text: entryDelegate.fileIsDir ? "󰅂" : "󰐕"
              font.family: Commons.Style.fontFamily
              font.pixelSize: 10
              color: entryHover.hovered ? Commons.Color.accent : Commons.Color.muted
            }
          }
        }

        Text {
          anchors.centerIn: parent
          visible: folderModel.count === 0
          text: root.mode === "folder" ? "No subfolders in this directory" : "No files or subfolders"
          font.family: Commons.Style.fontFamily
          font.pixelSize: 10
          color: Commons.Color.muted
        }
      }

      // Bottom Bar with "Select Current Folder" action for folder mode
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 34
        radius: 4
        color: selectCurrentHov.hovered ? Commons.Color.accent : Commons.Util.alpha(Commons.Color.accent, 0.20)
        border.color: Commons.Color.accent
        border.width: 1

        HoverHandler { id: selectCurrentHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            var parts = root.currentFolder.split("/")
            var folderName = parts[parts.length - 1] || "Folder"
            if (root.currentFolder === root.homePath) folderName = "Home"
            root.itemSelected(
              folderName,
              root.currentFolder,
              false,
              (root.currentFolder === root.homePath) ? "folder-home" : "folder"
            )
            root.closed()
          }
        }

        RowLayout {
          anchors.centerIn: parent
          spacing: 6

          Text {
            text: "✓"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 11
            font.bold: true
            color: selectCurrentHov.hovered ? Commons.Color.background : Commons.Color.accent
          }

          Text {
            text: root.mode === "folder" ? ("Select Folder: " + root.displayPath(root.currentFolder)) : "Select Folder"
            font.family: Commons.Style.fontFamily
            font.pixelSize: 10
            font.bold: true
            color: selectCurrentHov.hovered ? Commons.Color.background : Commons.Color.accent
            elide: Text.ElideMiddle
            Layout.maximumWidth: modalBox.width - 60
          }
        }
      }
    }
  }
}
