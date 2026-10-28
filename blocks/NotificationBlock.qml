pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive

// OmaDesk — NotificationBlock (Presentation-only block)
// Displays recent system notifications and DND toggle via shared dataHub.
// Zero internal Timer or Process objects.

Item {
  id: root
  clip: true

  required property var blockData
  required property var dataHub
  property var actionHub: null
  property string resolvedPresentation: "auto"
  property real densityScale: 1.0

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  readonly property var notifsList: (root.dataHub && Array.isArray(root.dataHub.recentNotifications)) ? root.dataHub.recentNotifications : []
  readonly property bool dndActive: Boolean(root.dataHub && root.dataHub.dndActive)
  readonly property bool isAvailable: Boolean(root.dataHub && root.dataHub.notificationsAvailable)

  function formatTimeAgo(ts) {
    if (!ts || typeof ts !== "number") return ""
    var diffMs = Date.now() - ts
    if (diffMs < 60000) return "Just now"
    var mins = Math.floor(diffMs / 60000)
    if (mins < 60) return mins + "m ago"
    var hrs = Math.floor(mins / 60)
    if (hrs < 24) return hrs + "h ago"
    return Math.floor(hrs / 24) + "d ago"
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(8, 4)
    spacing: root.dp(6, 4)

    // Header Strip: Title, DND Toggle Chip & Clear Button
    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(6, 4)

      Text {
        text: root.dndActive ? "󰂛" : "󰂚"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(14, 11)
        color: root.dndActive ? Commons.Color.urgent : Commons.Color.accent
      }

      Text {
        text: "Notifications"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(12, 10)
        font.bold: true
        color: Commons.Color.foreground
        Layout.fillWidth: true
      }

      // DND Toggle Button
      Rectangle {
        Layout.preferredHeight: root.dp(20, 16)
        implicitWidth: dndTxt.implicitWidth + root.dp(12, 8)
        radius: root.dp(10, 8)
        color: root.dndActive ? Commons.Util.alpha(Commons.Color.urgent, 0.20) : (dndHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.10) : Commons.Util.alpha(Commons.Color.foreground, 0.05))
        border.color: root.dndActive ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.15)
        border.width: 1

        HoverHandler { id: dndHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (root.actionHub && typeof root.actionHub.toggleDnd === "function") {
              root.actionHub.toggleDnd()
            }
          }
        }

        RowLayout {
          anchors.centerIn: parent
          spacing: root.dp(3, 2)

          Text {
            text: root.dndActive ? "󰂛" : "󰂚"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(9, 8)
            color: root.dndActive ? Commons.Color.urgent : Commons.Color.muted
          }

          Text {
            id: dndTxt
            text: root.dndActive ? "DND: ON" : "DND: OFF"
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(9, 8)
            font.bold: true
            color: root.dndActive ? Commons.Color.urgent : Commons.Color.muted
          }
        }
      }

      // Clear History Button
      Rectangle {
        visible: root.notifsList.length > 0
        Layout.preferredHeight: root.dp(20, 16)
        Layout.preferredWidth: root.dp(20, 16)
        radius: root.dp(10, 8)
        color: clearHov.hovered ? Commons.Util.alpha(Commons.Color.urgent, 0.22) : Commons.Util.alpha(Commons.Color.foreground, 0.05)
        border.color: clearHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.12)
        border.width: 1

        HoverHandler { id: clearHov; cursorShape: Qt.PointingHandCursor }
        TapHandler {
          onTapped: {
            if (root.actionHub && typeof root.actionHub.clearNotifications === "function") {
              root.actionHub.clearNotifications()
            }
          }
        }

        Text {
          anchors.centerIn: parent
          text: "󰆴"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 8)
          color: clearHov.hovered ? Commons.Color.urgent : Commons.Color.muted
        }
      }
    }

    // List of Notifications or Calm Empty State
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true

      // Empty State
      ColumnLayout {
        anchors.centerIn: parent
        visible: root.notifsList.length === 0
        spacing: root.dp(4, 2)

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: root.dndActive ? "󰂛" : "󰂚"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(24, 18)
          color: root.dndActive ? Commons.Color.urgent : Commons.Color.muted
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: root.dndActive ? "Do Not Disturb active" : "No recent alerts"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 9)
          font.bold: true
          color: Commons.Color.foreground
        }

        Text {
          Layout.alignment: Qt.AlignHCenter
          text: root.dndActive ? "Incoming notifications are silenced." : "System and app notices will appear here."
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(9, 8)
          color: Commons.Color.muted
        }
      }

      // Notifications Stack
      Flickable {
        anchors.fill: parent
        visible: root.notifsList.length > 0
        contentHeight: notifCol.implicitHeight
        clip: true

        ColumnLayout {
          id: notifCol
          width: parent.width
          spacing: root.dp(4, 2)

          Repeater {
            model: root.notifsList

            Rectangle {
              id: notifCard
              required property var modelData
              required property int index
              Layout.fillWidth: true
              implicitHeight: Math.max(root.dp(34, 26), cardCol.implicitHeight + root.dp(8, 4))
              radius: Math.max(3, Math.round(Commons.Style.cornerRadius * 0.35))
              color: cardHov.hovered ? Commons.Util.alpha(Commons.Color.foreground, 0.07) : Commons.Util.alpha(Commons.Color.foreground, 0.03)
              border.color: notifCard.modelData.urgency === 2 ? Commons.Color.urgent : (cardHov.hovered ? Commons.Util.alpha(Commons.Color.accent, 0.30) : Commons.Util.alpha(Commons.Color.foreground, 0.08))
              border.width: 1

              HoverHandler { id: cardHov }

              ColumnLayout {
                id: cardCol
                anchors.fill: parent
                anchors.margins: root.dp(6, 4)
                spacing: root.dp(2, 1)

                // App + Timestamp Line
                RowLayout {
                  Layout.fillWidth: true
                  spacing: root.dp(4, 2)

                  Text {
                    text: notifCard.modelData.app || "System"
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: root.dp(9, 8)
                    font.bold: true
                    color: notifCard.modelData.urgency === 2 ? Commons.Color.urgent : Commons.Color.accent
                  }

                  Text {
                    text: "· " + root.formatTimeAgo(notifCard.modelData.timestamp)
                    font.family: Commons.Style.fontFamily
                    font.pixelSize: root.dp(9, 8)
                    color: Commons.Color.muted
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                  }
                }

                // Summary
                Text {
                  Layout.fillWidth: true
                  text: notifCard.modelData.summary || ""
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: root.dp(10, 9)
                  font.bold: true
                  color: Commons.Color.foreground
                  elide: Text.ElideRight
                  maximumLineCount: 1
                }

                // Body (if available)
                Text {
                  visible: (notifCard.modelData.body && notifCard.modelData.body.length > 0)
                  Layout.fillWidth: true
                  text: notifCard.modelData.body || ""
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: root.dp(9, 8)
                  color: Commons.Color.muted
                  elide: Text.ElideRight
                  maximumLineCount: 2
                  wrapMode: Text.WordWrap
                }
              }
            }
          }
        }
      }
    }
  }
}
