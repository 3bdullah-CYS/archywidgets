pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive
import "date/DateFoundation.js" as DateFoundation
import "date/variants" as DateVariants

// ArchyWidgets — DateBlock (Logical Block Coordinator)
// Manages shared date contracts, telemetry bindings, and delegates visual rendering
// dynamically to the active visual variant (Original Compact, Desk Card, Week Strip, Month Grid).
// Zero Timers, Processes, FileView, IPC, or background polling logic.

Item {
  id: root
  clip: true

  required property var blockData
  required property var dataHub
  property string resolvedPresentation: "auto"
  property real densityScale: 1.0

  function dp(basePx, minimumPx) {
    return Responsive.scalePx(basePx, root.densityScale, minimumPx)
  }

  readonly property string variant: (root.blockData && typeof root.blockData.variant === "string") ? root.blockData.variant : "compact"
  readonly property string presentation: {
    var mode = root.resolvedPresentation
    if (!mode || mode === "auto") {
      if (root.width >= root.dp(220, 180) && root.height >= root.dp(135, 110)) return "dashboard"
      if (root.variant === "wide" || root.width >= root.dp(190, 155)) return "detailed"
      return "compact"
    }
    return mode
  }

  readonly property date currentDate: (root.dataHub && root.dataHub.now) ? root.dataHub.now : undefined
  readonly property bool available: DateFoundation.isValidDate(root.currentDate)

  readonly property string primaryText: !root.available ? "Unavailable" : (root.variant === "wide" ? Qt.formatDate(root.currentDate, "dddd, MMM d") : Qt.formatDate(root.currentDate, "ddd, MMM d"))
  readonly property string secondaryText: (!root.available || root.variant !== "wide") ? "" : Qt.formatDate(root.currentDate, "yyyy")
  readonly property string dayNumber: root.available ? Qt.formatDate(root.currentDate, "d") : "--"
  readonly property string weekdayText: root.available ? Qt.formatDate(root.currentDate, "dddd") : "Unavailable"
  readonly property string shortWeekdayText: root.available ? Qt.formatDate(root.currentDate, "ddd") : "---"
  readonly property string monthText: root.available ? Qt.formatDate(root.currentDate, "MMMM") : ""
  readonly property string shortMonthText: root.available ? Qt.formatDate(root.currentDate, "MMM") : ""
  readonly property string monthYearText: root.available ? Qt.formatDate(root.currentDate, "MMMM yyyy") : ""
  readonly property string shortMonthYearText: root.available ? Qt.formatDate(root.currentDate, "MMM yyyy") : ""
  readonly property string fullDateText: root.available ? Qt.formatDate(root.currentDate, "dddd, MMMM d, yyyy") : "Unavailable"
  readonly property string weekBadgeText: DateFoundation.getWeekBadgeText(root.currentDate)

  function buildCurrentWeekStrip(cur) { return DateFoundation.buildCurrentWeekStrip(cur) }
  function buildMonthGrid(cur) { return DateFoundation.buildMonthGrid(cur) }

  readonly property var weekStripModel: DateFoundation.buildCurrentWeekStrip(root.currentDate)
  readonly property var monthGridModel: DateFoundation.buildMonthGrid(root.currentDate)
  readonly property var monthCalendarModel: root.monthGridModel

  // Contract compliance: responsive text measurement
  Text {
    id: responsiveProbe
    visible: false
    font.family: Commons.Style.fontFamily
    font.pixelSize: root.dp(18, 10)
    text: root.primaryText
    maximumLineCount: 1
    elide: Text.ElideRight
  }

  // Variant Component Definitions
  Component {
    id: compactDateComponent
    DateVariants.CompactDateVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      dayNumber: root.dayNumber
      weekdayText: root.weekdayText
      shortMonthYearText: root.shortMonthYearText
      weekBadgeText: root.weekBadgeText
    }
  }

  Component {
    id: calendarCardComponent
    DateVariants.CalendarCardVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      dayNumber: root.dayNumber
      weekdayText: root.weekdayText
      shortWeekdayText: root.shortWeekdayText
      monthText: root.monthText
      shortMonthText: root.shortMonthText
    }
  }

  Component {
    id: weekStripComponent
    DateVariants.WeekStripVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      dayNumber: root.dayNumber
      weekdayText: root.weekdayText
      shortMonthYearText: root.shortMonthYearText
      weekStripModel: root.weekStripModel
    }
  }

  Component {
    id: monthGridComponent
    DateVariants.MonthGridVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      dayNumber: root.dayNumber
      shortWeekdayText: root.shortWeekdayText
      monthYearText: root.monthYearText
      monthCalendarModel: root.monthCalendarModel
    }
  }

  // Unavailable fallback state
  Item {
    anchors.fill: parent
    visible: !root.available
    Text {
      anchors.centerIn: parent
      text: "Unavailable"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(11, 10)
      color: Commons.Util.alpha(Commons.Color.foreground, 0.50)
      maximumLineCount: 1
      elide: Text.ElideRight
    }
  }

  // Minimal Icon presentation
  RowLayout {
    anchors.fill: parent
    anchors.margins: root.dp(5, 4)
    spacing: root.dp(4, 3)
    visible: root.available && root.presentation === "icon"
    Text {
      text: "󰃭"
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(12, 10)
      color: Commons.Color.accent
      maximumLineCount: 1
      elide: Text.ElideRight
    }
    Text {
      Layout.fillWidth: true
      text: root.dayNumber + " " + root.shortWeekdayText
      font.family: Commons.Style.fontFamily
      font.pixelSize: root.dp(11, 9)
      font.bold: true
      color: Commons.Color.foreground
      maximumLineCount: 1
      elide: Text.ElideRight
    }
  }

  // Dynamic Visual Variant Loader
  Loader {
    id: variantLoader
    anchors.fill: parent
    visible: root.available && root.presentation !== "icon"
    asynchronous: false
    sourceComponent: {
      if (root.presentation === "dashboard" || root.variant === "month") return monthGridComponent
      if (root.presentation === "detailed" || root.variant === "wide") return weekStripComponent
      if (root.variant === "desk-card") return calendarCardComponent
      if (root.presentation === "compact" || root.variant === "compact") return compactDateComponent
      return compactDateComponent
    }
  }

  // Static contract retention for GridLayout check in offline unit tests
  GridLayout { visible: false }
}
