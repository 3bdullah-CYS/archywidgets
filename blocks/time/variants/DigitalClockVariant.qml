pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../../../ResponsiveMetrics.js" as Responsive

// OmaDesk — DigitalClockVariant
// Visual presentation for digital clock (icon, compact, detailed wide, and dashboard modes).
// Pure presentation delegate — no timers, no processes.

Item {
  id: root
  anchors.fill: parent

  property real densityScale: 1.0
  property string presentation: "compact"
  property bool showSeconds: false
  property string timeString: "--:--"
  property string hmString: "--:--"
  property string secondsString: "00"
  property string uptimeText: ""
  property string hostnameText: "Omarchy"
  property string kernelText: ""
  property string fullDateString: ""

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  // Presentation 1: Icon Mode
  Text {
    anchors.centerIn: parent
    visible: root.presentation === "icon"
    text: "󰥔"
    font.family: Commons.Style.fontFamily
    font.pixelSize: root.dp(18, 12)
    color: Commons.Color.accent
    maximumLineCount: 1
    elide: Text.ElideRight
  }

  // Presentation 2: Compact Mode (1x1)
  ColumnLayout {
    anchors.centerIn: parent
    visible: root.presentation === "compact"
    spacing: root.dp(2, 1)

    Text {
      text: root.timeString
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(18, 10)
      font.bold: true
      color: Commons.Color.foreground
      Layout.alignment: Qt.AlignHCenter
      maximumLineCount: 1
      elide: Text.ElideRight
      Layout.maximumWidth: Math.max(0, root.width - 4)
    }

    Text {
      visible: root.height >= root.dp(95, 76) && root.uptimeText.length > 0
      text: "Up " + root.uptimeText
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 10)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
      Layout.alignment: Qt.AlignHCenter
      maximumLineCount: 1
      elide: Text.ElideRight
      Layout.maximumWidth: Math.max(0, root.width - 4)
    }
  }

  // Presentation 3: Detailed Mode (2x1)
  ColumnLayout {
    anchors.centerIn: parent
    width: Math.max(0, root.width - root.dp(8, 4))
    visible: root.presentation === "detailed"
    spacing: root.dp(2, 1)

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: root.dp(6, 4)

      Text {
        text: root.timeString
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(30, 18)
        font.bold: true
        color: Commons.Color.foreground
        maximumLineCount: 1
        elide: Text.ElideRight
        Layout.maximumWidth: Math.max(0, root.width - root.dp(44, 28))
      }

      Rectangle {
        visible: !root.showSeconds && root.width >= root.dp(150, 120)
        Layout.preferredHeight: root.dp(20, 16)
        implicitWidth: secBadge.implicitWidth + root.dp(8, 6)
        radius: root.dp(4, 2)
        color: Commons.Util.alpha(Commons.Color.accent, 0.16)
        Layout.alignment: Qt.AlignVCenter

        Text {
          id: secBadge
          anchors.centerIn: parent
          text: ":" + root.secondsString
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(11, 10)
          font.bold: true
          color: Commons.Color.accent
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }

    Text {
      visible: root.uptimeText.length > 0 && root.height >= root.dp(54, 44)
      text: "󰔟 Up " + root.uptimeText
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(10, 10)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.68)
      Layout.alignment: Qt.AlignHCenter
      maximumLineCount: 1
      elide: Text.ElideRight
      Layout.maximumWidth: Math.max(0, root.width - root.dp(8, 4))
    }
  }

  // Presentation 4: Dashboard Mode (2x2+ full clock & system status dashboard)
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.dp(6, 4)
    visible: root.presentation === "dashboard"
    spacing: root.dp(6, 4)

    RowLayout {
      Layout.fillWidth: true
      spacing: root.dp(6, 4)

      Text {
        text: "󰥔 System Clock"
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(11, 10)
        font.bold: true
        color: Commons.Util.alpha(Commons.Color.foreground, 0.72)
        elide: Text.ElideRight
        maximumLineCount: 1
        Layout.fillWidth: true
      }

      Rectangle {
        Layout.preferredHeight: root.dp(20, 16)
        implicitWidth: hostBadge.implicitWidth + root.dp(10, 6)
        radius: root.dp(4, 2)
        color: Commons.Util.alpha(Commons.Color.accent, 0.15)

        Text {
          id: hostBadge
          anchors.centerIn: parent
          text: root.hostnameText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          font.bold: true
          color: Commons.Color.accent
          maximumLineCount: 1
          elide: Text.ElideRight
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: root.dp(3, 2)

      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: root.dp(8, 4)

        Text {
          text: root.hmString
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(36, 22)
          font.bold: true
          color: Commons.Color.foreground
          maximumLineCount: 1
          elide: Text.ElideRight
        }

        Rectangle {
          Layout.preferredHeight: root.dp(24, 18)
          implicitWidth: dashSecText.implicitWidth + root.dp(10, 6)
          radius: root.dp(5, 3)
          color: Commons.Util.alpha(Commons.Color.accent, 0.18)
          border.color: Commons.Util.alpha(Commons.Color.accent, 0.40)
          border.width: 1
          Layout.alignment: Qt.AlignVCenter

          Text {
            id: dashSecText
            anchors.centerIn: parent
            text: ":" + root.secondsString
            font.family: Commons.Style.fontFamily
            font.pixelSize: root.dp(13, 10)
            font.bold: true
            color: Commons.Color.accent
            maximumLineCount: 1
            elide: Text.ElideRight
          }
        }
      }

      Text {
        visible: root.fullDateString.length > 0
        text: root.fullDateString
        font.family: Commons.Style.fontFamily
        font.pixelSize: root.dp(11, 10)
        color: Commons.Util.alpha(Commons.Color.foreground, 0.78)
        Layout.alignment: Qt.AlignHCenter
        maximumLineCount: 1
        elide: Text.ElideRight
        Layout.maximumWidth: Math.max(0, root.width - root.dp(12, 6))
      }
    }

    Rectangle {
      Layout.fillWidth: true
      Layout.preferredHeight: root.dp(26, 20)
      radius: root.dp(5, 3)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.05)
      border.color: Commons.Util.alpha(Commons.Color.foreground, 0.10)
      border.width: 1

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: root.dp(8, 4)
        anchors.rightMargin: root.dp(8, 4)
        spacing: root.dp(8, 4)

        Text {
          text: root.uptimeText.length > 0 ? ("󰔟 Up " + root.uptimeText) : "󰔟 Active"
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.75)
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.fillWidth: true
        }

        Text {
          visible: root.kernelText.length > 0
          text: "󰌽 " + root.kernelText
          font.family: Commons.Style.fontFamily
          font.pixelSize: root.dp(10, 10)
          color: Commons.Util.alpha(Commons.Color.foreground, 0.65)
          elide: Text.ElideRight
          maximumLineCount: 1
          Layout.alignment: Qt.AlignRight
        }
      }
    }
  }
}
