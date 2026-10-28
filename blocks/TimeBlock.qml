pragma ComponentBehavior: Bound
import QtQuick
import qs.Commons as Commons
import "../ResponsiveMetrics.js" as Responsive
import "time/TimeFoundation.js" as TimeFoundation
import "time/variants" as TimeVariants

// ArchyWidgets — TimeBlock (Logical Block Coordinator)
// Manages shared time contracts, telemetry bindings, and delegates visual rendering
// dynamically to the active visual variant (Digital, Analog, Cards, Minimal).
// Zero Timers, Processes, or background polling logic.

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

  readonly property bool showSeconds: (blockData && blockData.settings && typeof blockData.settings.showSeconds === "boolean") ? blockData.settings.showSeconds : false
  readonly property string variant: (blockData && typeof blockData.variant === "string") ? blockData.variant : "compact"
  readonly property string presentation: {
    if (root.resolvedPresentation && root.resolvedPresentation !== "auto") {
      return root.resolvedPresentation
    }
    if (root.width >= root.dp(220, 180) && root.height >= root.dp(135, 110)) {
      return "dashboard"
    }
    return root.variant === "wide" ? "detailed" : "compact"
  }

  readonly property date currentDate: (root.dataHub && root.dataHub.now) ? root.dataHub.now : undefined
  readonly property bool timeAvailable: TimeFoundation.isValidDate(root.currentDate)
  readonly property string uptimeText: (root.dataHub && typeof root.dataHub.uptimeText === "string") ? root.dataHub.uptimeText : ""
  readonly property string hostnameText: (root.dataHub && typeof root.dataHub.hostname === "string" && root.dataHub.hostname.length > 0) ? root.dataHub.hostname : "Omarchy"
  readonly property string kernelText: (root.dataHub && typeof root.dataHub.kernelVer === "string") ? root.dataHub.kernelVer : ""

  readonly property string hoursString: TimeFoundation.getHours(root.currentDate)
  readonly property string minutesString: TimeFoundation.getMinutes(root.currentDate)
  readonly property string secondsString: TimeFoundation.getSeconds(root.currentDate)
  readonly property string hmString: TimeFoundation.getHmString(root.currentDate)
  readonly property string timeString: TimeFoundation.getTimeString(root.currentDate, root.showSeconds)

  readonly property string fullDateString: {
    if (!root.timeAvailable) return ""
    return Qt.formatDate(root.currentDate, "dddd, d MMMM yyyy")
  }

  // Contract compliance: responsive text measurement
  Text {
    id: responsiveProbe
    visible: false
    font.family: Commons.Style.fontFamily
    font.pixelSize: root.dp(18, 10)
    text: root.timeString
  }

  // Variant Component Definitions
  Component {
    id: digitalVariantComponent
    TimeVariants.DigitalClockVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      presentation: root.presentation
      showSeconds: root.showSeconds
      timeString: root.timeString
      hmString: root.hmString
      secondsString: root.secondsString
      uptimeText: root.uptimeText
      hostnameText: root.hostnameText
      kernelText: root.kernelText
      fullDateString: root.fullDateString
    }
  }

  Component {
    id: analogVariantComponent
    TimeVariants.AnalogClockVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      currentDate: root.currentDate
    }
  }

  Component {
    id: cardsVariantComponent
    TimeVariants.FlipCardsVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      hoursString: root.hoursString
      minutesString: root.minutesString
    }
  }

  Component {
    id: minimalVariantComponent
    TimeVariants.MinimalClockVariant {
      anchors.fill: parent
      densityScale: root.densityScale
      currentDate: root.currentDate
      hoursString: root.hoursString
      minutesString: root.minutesString
    }
  }

  // Active Variant Delegate Loader (Instantiates ONLY the active visual design)
  Loader {
    id: variantLoader
    anchors.fill: parent
    sourceComponent: {
      switch (root.variant) {
        case "analog":
          return analogVariantComponent
        case "cards":
          return cardsVariantComponent
        case "minimal":
          return minimalVariantComponent
        case "compact":
        case "wide":
        default:
          return digitalVariantComponent
      }
    }
  }
}
