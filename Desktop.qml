import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons as Commons
import "AdaptiveLayoutEngine.js" as LayoutEngine
import "ConfigModel.js" as ConfigModel
import "ComposerModel.js" as ComposerModel
import "editor" as Editor
import "components" as Components
import "blocks" as Blocks

// ArchyWidgets — Theme-aware desktop containers & blocks for Omarchy
// Fixed-geometry canvas with real-time streaming metrics and visual Studio arrangement.

Item {
  id: root

  // Omarchy Plugin Identity & Lifecycle Contract
  property string moduleName: "io.github.3bdullah-cys.archywidgets"
  readonly property bool opened: !root.deskClosed && root.shouldBeVisible

  // Injected by host
  property var shell: null
  property var manifest: null

  // Paths
  readonly property string pluginDir: decodeURIComponent(String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "").replace(/\/$/, ""))
  readonly property string statsScript: pluginDir + "/scripts/get_stats.py"
  readonly property string fanScript: pluginDir + "/scripts/set_fan.sh"
  readonly property string saveConfigScript: pluginDir + "/scripts/save_config.py"
  readonly property string userConfigFile: Quickshell.env("HOME") + "/.config/omarchy/archywidgets.json"
  readonly property string todoHelperScript: pluginDir + "/scripts/todo_helper.py"
  readonly property string notifHelperScript: pluginDir + "/scripts/notif_helper.py"
  readonly property string memoryCleanScript: pluginDir + "/scripts/clean_memory.sh"
  readonly property string todoItemsFile: Quickshell.env("HOME") + "/.config/omarchy/todo-list/items.json"
  readonly property string notifSettingsFile: Quickshell.env("HOME") + "/.local/state/omarchy/notifications.json"

  // Native Todo List State
  property var todoItems: []
  property var todoHistory: []
  property int todoOpenCount: 0
  property bool todoAvailable: false
  property var todoAddQueue: []

  // Native Notifications State
  property var recentNotifications: []
  property bool dndActive: false
  property bool notificationsAvailable: true

  // Settings
  property int targetWorkspace: 1
  property bool autoHideOnWindows: true
  property real occupiedOpacity: 0.0
  property real cardOpacity: 0.45
  property bool showClock: true
  property bool deskClosed: false

  // Screen & Adaptive Layout Bounds
  property real bottomInset: 22
  property real screenWidth: 1200
  property real screenHeight: 653
  property real totalContentHeight: 653

  // UI Interactive States
  property bool editMode: false
  property var pendingV2Candidate: null

  // Interactive Desktop Layout Editor State
  property var editSessionDraft: null
  property var editHistoryStack: []
  property int layoutRevision: 0
  property string activeDrawerContainerId: ""
  property string targetAddContainerId: ""
  property string selectedBlockId: ""
  property bool appPickerOpen: false
  property bool folderPickerOpen: false
  property string folderPickerMode: "folder"
  property bool blockDrawerOpen: false
  property string activeDragContainerId: ""
  property int ghostCol: 0
  property int ghostRow: 0
  property int ghostColSpan: 1
  property int ghostRowSpan: 1
  property bool ghostVisible: false

  signal v2CommitFinished(bool ok, string errorCode)

  property var portals: []

  // Live Metrics (Synchronous instantaneous updates)
  property int cpuPercent: 0
  property string cpuModel: ""
  property int cpuCores: 0
  property string kernelVer: ""
  property string hostname: ""
  property string osName: "Omarchy Linux"
  property string loadAvg: ""
  property int ramPercent: 0
  property string ramUsed: "0"
  property string ramTotal: "0"
  property int swapPercent: 0
  property string swapUsed: "0.0"
  property string swapTotal: "0.0"
  property int diskPercent: 0
  property string diskUsed: "0"
  property string diskTotal: "0"
  property string diskFree: "0"
  property string diskFreeStr: "0 GB"
  property string diskTotalStr: "0 GB"
  property string diskLabel: "System"
  property var disks: []
  property int diskHddPercent: 0
  property string diskHddUsed: "0"
  property string diskHddTotal: "0"
  property string diskHddFreeStr: "0 GB"
  property string diskHddLabel: "HDD"
  property bool diskHddAvailable: false
  property string netDown: "0 KB/s"
  property string netUp: "0 KB/s"
  property real netDownBps: 0
  property real netUpBps: 0
  property string netTotalDown: "0 KB"
  property string netTotalUp: "0 KB"
  property string netType: "Offline"
  property string netDevice: ""
  property string netIp: ""
  property string netSsid: "Disconnected"
  property bool batteryAvailable: false
  property int batteryPercent: 100
  property bool batteryCharging: true
  property string batteryTimeRemaining: ""
  property string batteryPowerWatts: ""
  property real tempCpu: 0
  property real tempGpu: 0
  property real tempNvme: 0
  property real tempHdd: 0
  property int fanMode: -1
  property string uptimeText: ""

  // Version 2 Runtime State (Active by default)
  readonly property bool v2PreviewForced: Quickshell.env("OMADESK_V2_PREVIEW") === "1"
  property bool v2PreviewSessionEnabled: true
  readonly property bool v2PreviewEnabled: root.v2PreviewForced || root.v2PreviewSessionEnabled
  property bool telemetryReady: false

  // Deterministic default V2 configuration
  readonly property var v2Fixture: ConfigModel.defaultConfig()
  readonly property var v2ValidationResult: ConfigModel.validateV2(v2Fixture)
  readonly property bool v2FixtureValid: v2ValidationResult.ok === true
  property var v2SessionConfig: ConfigModel.clone(v2ValidationResult.value)


  // Shared Data Hub (telemetry & time distribution for blocks)
  QtObject {
    id: sharedDataHub
    property int revision: 0
    property date now: new Date()
    readonly property int activeWorkspaceId: root.activeWsId
    readonly property bool telemetryAvailable: root.telemetryReady
    readonly property string networkName: root.netSsid
    readonly property string networkDownload: root.netDown
    readonly property string networkUpload: root.netUp
    readonly property real networkDownBps: root.netDownBps
    readonly property real networkUpBps: root.netUpBps
    readonly property string networkTotalDownload: root.netTotalDown
    readonly property string networkTotalUpload: root.netTotalUp
    readonly property string networkType: root.netType
    readonly property string networkDevice: root.netDevice
    readonly property string networkIp: root.netIp
    readonly property bool batteryAvailable: root.batteryAvailable
    readonly property int batteryPercent: root.batteryPercent
    readonly property bool batteryCharging: root.batteryCharging
    readonly property string batteryTimeRemaining: root.batteryTimeRemaining
    readonly property string batteryPowerWatts: root.batteryPowerWatts
    readonly property string cpuModel: root.cpuModel
    readonly property int cpuCores: root.cpuCores
    readonly property string loadAvg: root.loadAvg
    readonly property string ramUsedGb: root.ramUsed
    readonly property string ramTotalGb: root.ramTotal
    readonly property int swapPercent: root.swapPercent
    readonly property string swapUsedGb: root.swapUsed
    readonly property string swapTotalGb: root.swapTotal
    readonly property string diskUsedGb: root.diskUsed
    readonly property string diskTotalGb: root.diskTotal
    readonly property string diskFreeGb: root.diskFree
    readonly property string diskFreeStr: root.diskFreeStr
    readonly property string diskTotalStr: root.diskTotalStr
    readonly property string diskLabel: root.diskLabel
    readonly property var disks: root.disks
    readonly property string diskHddUsedGb: root.diskHddUsed
    readonly property string diskHddTotalGb: root.diskHddTotal
    readonly property string diskHddFreeStr: root.diskHddFreeStr
    readonly property string diskHddLabel: root.diskHddLabel
    readonly property bool diskHddAvailable: root.diskHddAvailable
    readonly property string uptimeText: root.uptimeText
    readonly property string hostname: root.hostname
    readonly property string kernelVer: root.kernelVer
    readonly property string osName: root.osName
    readonly property var todoItems: root.todoItems
    readonly property var todoHistory: root.todoHistory
    readonly property int todoOpenCount: root.todoOpenCount
    readonly property bool todoAvailable: root.todoAvailable
    readonly property var recentNotifications: root.recentNotifications
    readonly property bool dndActive: root.dndActive
    readonly property bool notificationsAvailable: root.notificationsAvailable

    function available(source) {
      if (!root.telemetryReady) return false
      if (!source || typeof source !== "string") return false

      switch (source) {
        case "cpu.percent":
          return typeof root.cpuPercent === "number" && isFinite(root.cpuPercent)
        case "ram.percent":
          return typeof root.ramPercent === "number" && isFinite(root.ramPercent)
        case "disk.percent":
          return typeof root.diskPercent === "number" && isFinite(root.diskPercent)
        case "disk.hdd":
          return root.diskHddAvailable
        case "temperature.cpu":
          return typeof root.tempCpu === "number" && isFinite(root.tempCpu) && root.tempCpu > 0
        case "temperature.gpu":
          return typeof root.tempGpu === "number" && isFinite(root.tempGpu) && root.tempGpu > 0
        case "temperature.nvme":
          return typeof root.tempNvme === "number" && isFinite(root.tempNvme) && root.tempNvme > 0
        case "temperature.hdd":
          return typeof root.tempHdd === "number" && isFinite(root.tempHdd) && root.tempHdd > 0
        case "network.down":
        case "network.download":
          return typeof root.netDown === "string" && root.netDown.length > 0
        case "network.up":
        case "network.upload":
          return typeof root.netUp === "string" && root.netUp.length > 0
        case "fan.mode":
          return typeof root.fanMode === "number" && isFinite(root.fanMode) && root.fanMode >= 0
        default:
          return false
      }
    }

    function value(source) {
      if (!available(source)) return null

      switch (source) {
        case "cpu.percent":
          return root.cpuPercent
        case "ram.percent":
          return root.ramPercent
        case "disk.percent":
          return root.diskPercent
        case "disk.hdd":
          return root.diskHddPercent
        case "temperature.cpu":
          return root.tempCpu
        case "temperature.gpu":
          return root.tempGpu
        case "temperature.nvme":
          return root.tempNvme
        case "temperature.hdd":
          return root.tempHdd
        case "network.down":
        case "network.download":
          return root.netDown
        case "network.up":
        case "network.upload":
          return root.netUp
        case "fan.mode":
          return root.fanMode
        default:
          return null
      }
    }

    function detail(source) {
      if (!available(source)) return ""

      switch (source) {
        case "cpu.percent":
          return root.cpuModel || ""
        case "ram.percent":
          return (root.ramUsed && root.ramTotal && root.ramTotal !== "0") ? (root.ramUsed + " / " + root.ramTotal + " GB") : ""
        case "disk.percent":
          if (root.diskTotalStr && root.diskTotalStr !== "0 GB") {
            return root.diskTotalStr + " · " + root.diskPercent + "%"
          }
          return (root.diskUsed && root.diskTotal && root.diskTotal !== "0") ? (root.diskUsed + " / " + root.diskTotal + " GB") : ""
        case "disk.hdd":
          if (root.diskHddTotal && root.diskHddTotal !== "0") {
            return root.diskHddTotal + " GB · " + root.diskHddPercent + "%"
          }
          return root.diskHddLabel
        case "temperature.cpu":
        case "temperature.gpu":
        case "temperature.nvme":
        case "temperature.hdd":
          var t = Number(value(source))
          if (isNaN(t) || t <= 0) return ""
          return t >= 80 ? "Hot" : (t >= 65 ? "Warm" : "Optimal")
        case "network.down":
        case "network.download":
          return root.netTotalDown ? ("Total ↓ " + root.netTotalDown) : ""
        case "network.up":
        case "network.upload":
          return root.netTotalUp ? ("Total ↑ " + root.netTotalUp) : ""
        case "fan.mode":
          var fm = Number(root.fanMode)
          if (fm === 0) return "Quiet"
          if (fm === 1) return "Standard"
          if (fm === 2) return "Clean"
          if (fm === 4) return "Boost"
          return ""
        default:
          return ""
      }
    }
  }

  // Preview-only 1-second timer updating sharedDataHub.now
  Timer {
    id: v2TimeTimer
    interval: 1000
    repeat: true
    running: root.v2PreviewEnabled && ((!root.deskClosed && root.shouldBeVisible && (!root.autoHideOnWindows || !root.hasAppWindows)) || root.editMode)
    onTriggered: {
      sharedDataHub.now = new Date()
    }
  }

  // Persistence Process
  Process {
    id: saveProcess
    onExited: function(exitCode, exitStatus) {
      if (root.pendingV2Candidate === null) return
      if (exitCode === 0) {
        root.v2SessionConfig = ConfigModel.clone(root.pendingV2Candidate)
        root.v2PreviewSessionEnabled = true
        root.pendingV2Candidate = null
        root.v2CommitFinished(true, "")
      } else {
        root.pendingV2Candidate = null
        root.v2CommitFinished(false, "PERSISTENCE_FAILED")
      }
    }
  }

  // Root-owned Fan Action Controller
  Process {
    id: fanProcess
    onExited: function(exitCode, exitStatus) {
      fanActionObj.busy = false
      if (exitCode === 0) {
        fanActionObj.lastSuccessfulMode = fanActionObj.requestedMode
        fanActionObj.lastError = ""
      } else {
        fanActionObj.lastError = "FAN_ACTION_FAILED"
      }
    }
  }

  // Root-owned Memory Cleanup Process
  Process {
    id: memoryCleanProcess
    onExited: function(exitCode, exitStatus) {
      fanActionObj.memoryCleaning = false
      if (exitCode === 0) {
        fanActionObj.lastMemoryCleanError = ""
        fanActionObj.lastMemoryCleanSuccess = Date.now()
      } else {
        fanActionObj.lastMemoryCleanError = "CLEANUP_FAILED_" + exitCode
      }
    }
  }

  // Dedicated Native Todo Task Creation Process
  // Transmits confidential task text exclusively via stdin pipe to prevent
  // cross-user process arguments disclosure via /proc/<pid>/cmdline.
  Process {
    id: todoAddProcess
    command: ["/usr/bin/python3", root.todoHelperScript, "add"]
    stdinEnabled: true
    onRunningChanged: {
      if (running && root.todoAddQueue.length > 0) {
        write(root.todoAddQueue[0] + "\n")
        stdinEnabled = false
      }
    }
    onExited: function(exitCode, exitStatus) {
      stdinEnabled = true
      if (root.todoAddQueue.length > 0) {
        var q = root.todoAddQueue.slice()
        q.shift()
        root.todoAddQueue = q
      }
      if (root.todoAddQueue.length > 0) {
        todoAddProcess.running = true
      }
    }
  }

  readonly property var fanActionHub: QtObject {
    id: fanActionObj
    property bool busy: false
    property int requestedMode: -1
    property int lastSuccessfulMode: -1
    property string lastError: ""
    property bool memoryCleaning: false
    property string lastMemoryCleanError: ""
    property var lastMemoryCleanSuccess: null

    function launchApp(command) {
      if (typeof command !== "string" || !command.trim()) return false
      var parts = command.trim().match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g)
      if (!parts || parts.length === 0) return false
      var argv = parts.map(function(p) {
        if ((p.startsWith('"') && p.endsWith('"')) || (p.startsWith("'") && p.endsWith("'"))) {
          return p.slice(1, -1)
        }
        return p
      })
      if (typeof Commons.Util.execArgv === "function") {
        Commons.Util.execArgv(argv)
      } else {
        Commons.Util.execDetached(command.trim())
      }
      return true
    }

    function openFolder(folderPath) {
      if (typeof folderPath !== "string" || !folderPath.trim()) return false
      var resolved = folderPath.replace(/^~/, Quickshell.env("HOME"))
      Commons.Util.execArgv(["/usr/bin/xdg-open", resolved])
      return true
    }

    function requestFanMode(modeKey) {
      if (typeof modeKey !== "number" || [0, 1, 2, 4].indexOf(modeKey) === -1) {
        fanActionObj.lastError = "FAN_MODE_UNSUPPORTED"
        return { ok: false, error: "FAN_MODE_UNSUPPORTED" }
      }
      if (fanActionObj.busy) {
        fanActionObj.lastError = "FAN_ACTION_BUSY"
        return { ok: false, error: "FAN_ACTION_BUSY" }
      }
      fanActionObj.busy = true
      fanActionObj.requestedMode = modeKey
      fanActionObj.lastError = ""
      fanProcess.command = ["/usr/bin/bash", root.fanScript, String(modeKey)]
      fanProcess.running = true
      return { ok: true }
    }

    function toggleTodo(itemId) {
      if (!itemId) return false
      var list = root.todoItems ? root.todoItems.slice() : []
      var delta = 0
      for (var i = 0; i < list.length; i++) {
        if (list[i] && list[i].id === itemId) {
          list[i].done = !list[i].done
          delta = list[i].done ? -1 : 1
          break
        }
      }
      root.todoItems = list
      root.todoOpenCount = Math.max(0, root.todoOpenCount + delta)
      var cmd = ["/usr/bin/python3", root.todoHelperScript, "toggle", String(itemId)]
      if (typeof Commons.Util.execArgv === "function") {
        Commons.Util.execArgv(cmd)
      } else {
        Commons.Util.execDetached(cmd.join(" "))
      }
      return true
    }

    function addTodo(text) {
      if (!text || !text.trim()) return false
      var t = text.trim()
      var tempId = "tmp_" + Date.now()
      var tempItem = { id: tempId, text: t, done: false, createdAt: Date.now(), completedAt: 0 }
      var list = root.todoItems ? root.todoItems.slice() : []
      list.unshift(tempItem)
      root.todoItems = list
      root.todoOpenCount += 1
      var q = root.todoAddQueue ? root.todoAddQueue.slice() : []
      q.push(t)
      root.todoAddQueue = q
      if (typeof todoAddProcess !== "undefined" && todoAddProcess && !todoAddProcess.running) {
        todoAddProcess.stdinEnabled = true
        todoAddProcess.running = true
      }
      return true
    }

    function deleteTodo(itemId) {
      if (!itemId) return false
      var list = root.todoItems ? root.todoItems.slice() : []
      var wasOpen = false
      var filtered = []
      for (var i = 0; i < list.length; i++) {
        if (list[i] && list[i].id === itemId) {
          if (!list[i].done) wasOpen = true
        } else {
          filtered.push(list[i])
        }
      }
      root.todoItems = filtered
      if (wasOpen && root.todoOpenCount > 0) root.todoOpenCount -= 1
      var cmd = ["/usr/bin/python3", root.todoHelperScript, "delete", String(itemId)]
      if (typeof Commons.Util.execArgv === "function") {
        Commons.Util.execArgv(cmd)
      } else {
        Commons.Util.execDetached(cmd.join(" "))
      }
      return true
    }

    function toggleDnd() {
      var cmd = ["/usr/bin/python3", root.notifHelperScript, "toggle_dnd"]
      if (typeof Commons.Util.execArgv === "function") {
        Commons.Util.execArgv(cmd)
      } else {
        Commons.Util.execDetached(cmd.join(" "))
      }
      return true
    }

    function clearNotifications() {
      var cmd = ["/usr/bin/python3", root.notifHelperScript, "clear"]
      if (typeof Commons.Util.execArgv === "function") {
        Commons.Util.execArgv(cmd)
      } else {
        Commons.Util.execDetached(cmd.join(" "))
      }
      root.recentNotifications = []
      return true
    }

    function cleanMemory() {
      if (fanActionObj.memoryCleaning || memoryCleanProcess.running) {
        return false
      }
      fanActionObj.memoryCleaning = true
      fanActionObj.lastMemoryCleanError = ""
      memoryCleanProcess.command = ["/usr/bin/bash", root.memoryCleanScript]
      memoryCleanProcess.running = true
      return true
    }
  }



  function saveConfig(cfg) {
    if (typeof cfg.targetWorkspace === "number") root.targetWorkspace = cfg.targetWorkspace
    if (typeof cfg.deskClosed === "boolean") root.deskClosed = cfg.deskClosed
    if (typeof cfg.autoHideOnWindows === "boolean") root.autoHideOnWindows = cfg.autoHideOnWindows
    if (typeof cfg.cardOpacity === "number") root.cardOpacity = cfg.cardOpacity
    if (typeof cfg.showClock === "boolean") root.showClock = cfg.showClock

    if (root.v2SessionConfig && typeof root.v2SessionConfig === "object") {
      var updatedV2 = ConfigModel.clone(root.v2SessionConfig)
      updatedV2.targetWorkspace = root.targetWorkspace
      updatedV2.deskClosed = root.deskClosed
      updatedV2.autoHideOnWindows = root.autoHideOnWindows
      updatedV2.cardOpacity = root.cardOpacity
      root.v2SessionConfig = updatedV2
      return root.saveV2Config(updatedV2)
    }

    return false
  }

  function getSafeRect(w, h) {
    var winW = (typeof w === "number" && w > 0) ? w : (root.screenWidth > 0 ? root.screenWidth : 1200)
    var winH = (typeof h === "number" && h > 0) ? h : ((root.screenHeight > 0 ? root.screenHeight : 653) + root.bottomInset)

    var outerMargin = Math.max(20, Commons.Style.gapsOut * 2)
    var colGap = 12
    var rowGap = 12

    var safeLeft = outerMargin
    var safeRight = winW - outerMargin
    var clockY = 34
    var clockH = 86
    // Reserve breathing room below the Omarchy bar instead of pinning the V2
    // dashboard to the first drawable pixel row.
    var dashboardTopInset = Math.max(44, outerMargin + 20)
    var safeTop = (root.showClock && !root.v2PreviewEnabled) ? (clockY + clockH + rowGap) : dashboardTopInset
    var safeBottom = winH - root.bottomInset - outerMargin

    return {
      safeLeft: safeLeft,
      safeTop: safeTop,
      safeRight: safeRight,
      safeBottom: safeBottom,
      safeWidth: Math.max(0, safeRight - safeLeft),
      safeHeight: Math.max(0, safeBottom - safeTop),
      colGap: colGap,
      rowGap: rowGap
    }
  }

  function getLayoutMetrics() {
    var rect = root.getSafeRect(root.screenWidth, root.screenHeight + root.bottomInset)
    return LayoutEngine.computeGridMetrics(
      root.screenWidth,
      root.screenHeight,
      rect.safeLeft,
      rect.safeTop,
      { colGap: rect.colGap, rowGap: rect.rowGap },
      6,
      rect
    )
  }

  function evaluateV2PreviewPacking() {
    var _rev = root.layoutRevision
    if (!root.v2PreviewEnabled || !root.v2FixtureValid) {
      return { fits: false, placements: [], cardOpacity: 0.45 }
    }
    var validatedCfg = (root.editMode && root.editSessionDraft)
      ? root.editSessionDraft
      : (root.v2SessionConfig || root.v2ValidationResult.value || root.v2Fixture)
    var rawContainers = Array.isArray(validatedCfg.containers) ? validatedCfg.containers : []
    var enabledContainers = []
    for (var i = 0; i < rawContainers.length; i++) {
      if (rawContainers[i].enabled !== false) {
        enabledContainers.push(rawContainers[i])
      }
    }
    if (enabledContainers.length === 0) {
      return { fits: true, placements: [], cardOpacity: 0.45 }
    }
    var metrics = root.getLayoutMetrics()
    var mode = (validatedCfg && validatedCfg.layoutMode === "manual") ? "manual" : "auto"
    var packed = LayoutEngine.tryPackWidgets(enabledContainers, metrics, { layoutMode: mode })
    if ((!packed || !packed.fits) && mode === "manual") {
      var fallbackPack = LayoutEngine.tryPackWidgets(enabledContainers, metrics, { layoutMode: "auto" })
      if (fallbackPack && fallbackPack.fits) {
        packed = fallbackPack
      }
    }
    if (!packed || !Array.isArray(packed.placements) || packed.placements.length === 0) {
      return { fits: false, placements: [], cardOpacity: 0.45 }
    }
    var containerPlacements = []
    for (var j = 0; j < packed.placements.length; j++) {
      var p = packed.placements[j]
      var origC = enabledContainers[p.index]
      if (!origC) continue
      containerPlacements.push({
        placement: p,
        containerData: origC,
        x: p.x,
        y: p.y,
        width: p.width,
        height: p.height
      })
    }
    return {
      fits: packed.fits === true,
      placements: containerPlacements,
      cardOpacity: typeof validatedCfg.cardOpacity === "number" ? validatedCfg.cardOpacity : 0.45
    }
  }

  function enterEditMode() {
    var base = root.v2SessionConfig || root.v2ValidationResult.value || root.v2Fixture
    root.editSessionDraft = JSON.parse(JSON.stringify(base))
    if (root.editSessionDraft.layoutMode === "manual") {
      var needsSnapshot = false
      var containers = root.editSessionDraft.containers || []
      for (var i = 0; i < containers.length; i++) {
        if (containers[i].enabled !== false && (typeof containers[i].col !== "number" || typeof containers[i].row !== "number")) {
          needsSnapshot = true
          break
        }
      }
      if (needsSnapshot) {
        var metrics = root.getLayoutMetrics()
        var evalAuto = LayoutEngine.tryPackWidgets(containers.filter(function(c) { return c.enabled !== false }), metrics, { layoutMode: "auto" })
        if (evalAuto && Array.isArray(evalAuto.placements)) {
          for (var p = 0; p < evalAuto.placements.length; p++) {
            var pl = evalAuto.placements[p]
            for (var c = 0; c < containers.length; c++) {
              if (containers[c].id === pl.id) {
                containers[c].col = pl.gridCol
                containers[c].row = pl.gridRow
                break
              }
            }
          }
        }
      }
    }
    root.editHistoryStack = [ComposerModel.createSnapshot(root.editSessionDraft)]
    root.editMode = true
    root.activeDrawerContainerId = ""
    root.selectedBlockId = ""
    root.blockDrawerOpen = false
    root.activeDragContainerId = ""
    root.ghostVisible = false
    root.layoutRevision++
  }

  function cancelEditMode() {
    if (root.v2SessionConfig) {
      if (typeof root.v2SessionConfig.cardOpacity === "number") {
        root.cardOpacity = root.v2SessionConfig.cardOpacity
      }
      if (typeof root.v2SessionConfig.autoHideOnWindows === "boolean") {
        root.autoHideOnWindows = root.v2SessionConfig.autoHideOnWindows
      }
      if (typeof root.v2SessionConfig.targetWorkspace === "number") {
        root.targetWorkspace = root.v2SessionConfig.targetWorkspace
      }
    }
    root.editSessionDraft = null
    root.editHistoryStack = []
    root.activeDrawerContainerId = ""
    root.selectedBlockId = ""
    root.blockDrawerOpen = false
    root.activeDragContainerId = ""
    root.ghostVisible = false
    root.editMode = false
    root.layoutRevision++
  }

  function commitEditMode() {
    if (!root.editSessionDraft) {
      root.cancelEditMode()
      return
    }
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.validateDraft(root.editSessionDraft, metrics)
    if (!res.ok) {
      return
    }
    if (typeof res.value.cardOpacity === "number") {
      root.cardOpacity = res.value.cardOpacity
    }
    if (typeof res.value.autoHideOnWindows === "boolean") {
      root.autoHideOnWindows = res.value.autoHideOnWindows
    }
    if (typeof res.value.targetWorkspace === "number") {
      root.targetWorkspace = res.value.targetWorkspace
    }
    root.v2SessionConfig = ConfigModel.clone(res.value)
    root.saveV2Config(res.value)
    root.cancelEditMode()
  }

  function pushDraftChange(nextDraft) {
    if (!nextDraft) return
    root.editSessionDraft = nextDraft
    var snap = ComposerModel.createSnapshot(nextDraft)
    var stack = root.editHistoryStack.slice()
    stack.push(snap)
    if (stack.length > 25) stack.shift()
    root.editHistoryStack = stack
    root.layoutRevision++
  }

  function undoEditMode() {
    if (root.editHistoryStack.length <= 1) return
    var stack = root.editHistoryStack.slice()
    stack.pop()
    var prev = stack[stack.length - 1]
    root.editHistoryStack = stack
    root.editSessionDraft = JSON.parse(JSON.stringify(prev))
    if (typeof prev.cardOpacity === "number") {
      root.cardOpacity = prev.cardOpacity
    }
    if (typeof prev.autoHideOnWindows === "boolean") {
      root.autoHideOnWindows = prev.autoHideOnWindows
    }
    if (typeof prev.targetWorkspace === "number") {
      root.targetWorkspace = prev.targetWorkspace
    }
    root.layoutRevision++
  }

  property string editorToastMessage: ""
  signal triggerEditorToast()

  function showEditorToast(msg) {
    root.editorToastMessage = msg
    root.triggerEditorToast()
  }

  function addEmptyContainer() {
    if (!root.editSessionDraft) return
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.tryAddContainer(root.editSessionDraft, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
      root.activeDrawerContainerId = res.createdId
    } else {
      root.showEditorToast("Desktop grid is full: cannot add container")
    }
  }

  function addContainerFromTemplate(templateId) {
    if (!root.editSessionDraft) return
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.tryAddContainerWithTemplate(root.editSessionDraft, templateId, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
      root.activeDrawerContainerId = res.createdId
    } else {
      root.showEditorToast("Cannot add container: not enough space on desktop")
    }
  }

  function toggleContainerLayoutMode(cid, nextMode) {
    if (!root.editSessionDraft) return
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.trySetContainerLayoutMode(root.editSessionDraft, cid, nextMode, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    }
  }

  function removeContainer(cid) {
    if (!root.editSessionDraft) return
    var candidate = JSON.parse(JSON.stringify(root.editSessionDraft))
    candidate.containers = candidate.containers.filter(function(c) { return c.id !== cid })
    for (var i = 0; i < candidate.containers.length; i++) {
      candidate.containers[i].order = i
    }
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.validateDraft(candidate, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
      if (root.activeDrawerContainerId === cid) {
        root.blockDrawerOpen = false
        root.activeDrawerContainerId = ""
      }
    }
  }

  function resizeContainer(cid, newColSpan, newRowSpan) {
    if (!root.editSessionDraft) return
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.tryResizeContainer(root.editSessionDraft, cid, newColSpan, newRowSpan, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    } else {
      if (res.error && res.error.code === "CONTAINER_COLLISION") {
        root.showEditorToast("Cannot resize: overlaps with adjacent container")
      } else if (res.error && res.error.code === "CONTAINER_OUT_OF_BOUNDS") {
        root.showEditorToast("Cannot resize: exceeds desktop bounds")
      } else {
        root.showEditorToast("Cannot resize container")
      }
    }
  }

  function autoPackContainers() {
    if (!root.editSessionDraft) return
    var candidate = JSON.parse(JSON.stringify(root.editSessionDraft))
    var metrics = root.getLayoutMetrics()
    var isManual = candidate.layoutMode === "manual"

    var evalPack = LayoutEngine.packWidgets(
      candidate.containers.filter(function(c) { return c.enabled !== false }),
      metrics,
      { layoutMode: "auto" }
    )
    if (evalPack && Array.isArray(evalPack.placements)) {
      for (var p = 0; p < evalPack.placements.length; p++) {
        var pl = evalPack.placements[p]
        for (var c = 0; c < candidate.containers.length; c++) {
          if (candidate.containers[c].id === pl.id) {
            if (isManual) {
              candidate.containers[c].col = pl.gridCol
              candidate.containers[c].row = pl.gridRow
            } else {
              delete candidate.containers[c].col
              delete candidate.containers[c].row
            }
            break
          }
        }
      }
    }
    var res = ComposerModel.validateDraft(candidate, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
      root.showEditorToast("Layout reflowed")
    }
  }

  function setDraftArrangementMode(mode) {
    if (!root.editSessionDraft) return
    var targetMode = (mode === "manual") ? "manual" : "auto"
    var candidate = JSON.parse(JSON.stringify(root.editSessionDraft))
    candidate.layoutMode = targetMode

    if (targetMode === "manual") {
      var metrics = root.getLayoutMetrics()
      var evalCurrent = LayoutEngine.tryPackWidgets(
        candidate.containers.filter(function(c) { return c.enabled !== false }),
        metrics,
        { layoutMode: "auto" }
      )
      if (evalCurrent && Array.isArray(evalCurrent.placements)) {
        for (var p = 0; p < evalCurrent.placements.length; p++) {
          var pl = evalCurrent.placements[p]
          for (var c = 0; c < candidate.containers.length; c++) {
            if (candidate.containers[c].id === pl.id) {
              candidate.containers[c].col = pl.gridCol
              candidate.containers[c].row = pl.gridRow
              break
            }
          }
        }
      }
    }
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.validateDraft(candidate, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
      root.showEditorToast(targetMode === "manual" ? "Switched to Manual Layout" : "Switched to Auto Arrange")
    } else {
      root.showEditorToast("Cannot switch mode: " + (res.error ? res.error.code : "invalid layout"))
    }
  }

  function handleContainerDragMove(cid, curX, curY) {
    var metrics = root.getLayoutMetrics()
    var slot = LayoutEngine.findNearestGridSlot(curX, curY, metrics)
    if (slot) {
      root.ghostCol = slot.col
      root.ghostRow = slot.row
      root.ghostVisible = true
    }
  }

  function handleContainerDragFinish(cid, curX, curY) {
    root.ghostVisible = false
    root.activeDragContainerId = ""
    if (!root.editSessionDraft || curX < 0 || curY < 0) return
    var metrics = root.getLayoutMetrics()
    var slot = LayoutEngine.findNearestGridSlot(curX, curY, metrics)
    if (!slot) return

    var res = ComposerModel.trySetContainerPosition(root.editSessionDraft, cid, slot.col, slot.row, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    } else {
      if (res.error) {
        if (res.error.code === "CONTAINER_COLLISION") {
          root.showEditorToast("Cannot move: space is already occupied")
        } else if (res.error.code === "CONTAINER_OUT_OF_BOUNDS") {
          root.showEditorToast("Cannot move: outside desktop grid")
        } else if (res.error.code === "DESKTOP_NO_SPACE") {
          root.showEditorToast("Cannot move: no space available")
        } else {
          root.showEditorToast("Move rejected")
        }
      }
    }
  }

  function addBlockToContainer(cid, kind, variant, source) {
    if (!root.editSessionDraft) return
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.tryAddBlock(root.editSessionDraft, cid, kind, variant || "compact", source || "", metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    }
  }

  function removeBlockFromContainer(cid, bid) {
    if (!root.editSessionDraft) return
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.tryRemoveBlock(root.editSessionDraft, cid, bid, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    }
  }

  function setBlockVariantInContainer(cid, bid, variant) {
    if (!root.editSessionDraft) return
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.trySetBlockVariant(root.editSessionDraft, cid, bid, variant, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    } else {
      root.showEditorToast(res.error || "Cannot change variant: insufficient space")
    }
  }

  function selectBlockOnDesktop(cid, bid) {
    root.activeDrawerContainerId = cid
    root.selectedBlockId = bid
    root.blockDrawerOpen = true
  }

  function expandContainerAndSetVariant(cid, bid, variant) {
    if (!root.editSessionDraft) return
    var c = null
    for (var i = 0; i < root.editSessionDraft.containers.length; i++) {
      if (root.editSessionDraft.containers[i].id === cid) {
        c = root.editSessionDraft.containers[i]
        break
      }
    }
    if (!c) return
    var metrics = root.getLayoutMetrics()
    var curCol = c.colSpan || 1
    var curRow = c.rowSpan || 1
    var targetCol = Math.max(curCol, 2)
    var targetRow = curRow
    var resizeRes = ComposerModel.tryResizeContainer(root.editSessionDraft, cid, targetCol, targetRow, metrics)
    if (!resizeRes.ok) {
      targetRow = Math.max(curRow, 2)
      resizeRes = ComposerModel.tryResizeContainer(root.editSessionDraft, cid, targetCol, targetRow, metrics)
    }
    var candidateDraft = resizeRes.ok ? resizeRes.value : root.editSessionDraft
    var varRes = ComposerModel.trySetBlockVariant(candidateDraft, cid, bid, variant, metrics)
    if (varRes.ok) {
      root.pushDraftChange(varRes.value)
      root.showEditorToast("Container expanded & variant applied")
    } else if (resizeRes.ok) {
      root.pushDraftChange(resizeRes.value)
      root.showEditorToast("Container expanded, but variant requires more space")
    } else {
      root.showEditorToast("Cannot expand container: no space on desktop")
    }
  }

  function updateBlockSettings(cid, bid, nextSettings) {
    if (!root.editSessionDraft) return
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.trySetBlockSettings(root.editSessionDraft, cid, bid, nextSettings, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    }
  }

  function expandContainerIfNeeded(cid, itemCount) {
    if (!root.editSessionDraft) return
    var c = null
    for (var i = 0; i < root.editSessionDraft.containers.length; i++) {
      if (root.editSessionDraft.containers[i].id === cid) {
        c = root.editSessionDraft.containers[i]
        break
      }
    }
    if (!c) return
    var curCol = c.colSpan || 1
    var curRow = c.rowSpan || 1
    var curCap = 4
    if (curCol === 1 && curRow === 1) curCap = 4
    else if (curCol === 2 && curRow === 1) curCap = 4
    else if (curCol === 1 && curRow === 2) curCap = 4
    else if (curCol === 2 && curRow === 2) curCap = 8
    else if (curCol === 3 && curRow === 2) curCap = 12
    else if (curCol >= 4 && curRow >= 2) curCap = 16

    if (itemCount > curCap) {
      var metrics = root.getLayoutMetrics()
      var targetCol = curCol
      var targetRow = curRow
      if (curCol === 1 && curRow === 1) {
        targetCol = 2; targetRow = 1
      } else if (curCol === 2 && curRow === 1) {
        targetCol = 2; targetRow = 2
      } else if (curCol === 1 && curRow === 2) {
        targetCol = 2; targetRow = 2
      } else if (curCol === 2 && curRow === 2) {
        targetCol = 3; targetRow = 2
      } else if (curCol === 3 && curRow === 2) {
        targetCol = 4; targetRow = 2
      }
      if (targetCol !== curCol || targetRow !== curRow) {
        var res = ComposerModel.tryResizeContainer(root.editSessionDraft, cid, targetCol, targetRow, metrics)
        if (res.ok) {
          root.pushDraftChange(res.value)
          root.showEditorToast("Container expanded to fit new items")
        }
      }
    }
  }

  function openAppPickerForContainer(cid) {
    root.targetAddContainerId = cid
    root.appPickerOpen = true
  }

  function openFolderPickerForContainer(cid, mode) {
    root.targetAddContainerId = cid
    root.folderPickerMode = mode || "folder"
    root.folderPickerOpen = true
  }

  function addShortcutToContainer(cid, kind, itemObj) {
    if (!root.editSessionDraft || !cid || !itemObj) return
    var metrics = root.getLayoutMetrics()
    var c = null
    for (var i = 0; i < root.editSessionDraft.containers.length; i++) {
      if (root.editSessionDraft.containers[i].id === cid) {
        c = root.editSessionDraft.containers[i]
        break
      }
    }
    if (!c) return

    // Find existing block of kind ('app-grid' or 'folder-grid')
    var targetBlock = null
    var blocks = Array.isArray(c.blocks) ? c.blocks : []
    for (var b = 0; b < blocks.length; b++) {
      if (blocks[b] && blocks[b].kind === kind) {
        targetBlock = blocks[b]
        break
      }
    }

    if (!itemObj.id) {
      itemObj.id = (kind === "app-grid" ? "app_" : "folder_") + Date.now().toString(36) + "_" + Math.random().toString(36).substr(2, 5)
    }

    // Check duplicate target within the same container
    if (targetBlock && targetBlock.settings && Array.isArray(targetBlock.settings.items)) {
      var curItems = targetBlock.settings.items
      for (var d = 0; d < curItems.length; d++) {
        var it = curItems[d]
        if (!it) continue
        if (kind === "app-grid") {
          var cmdA = (it.command || "").trim()
          var cmdB = (itemObj.command || "").trim()
          var dIdA = (it.desktopId || "").trim()
          var dIdB = (itemObj.desktopId || "").trim()
          if ((cmdA && cmdA === cmdB) || (dIdA && dIdA === dIdB)) {
            root.showEditorToast((itemObj.name || "App") + " is already in this container")
            return
          }
        } else {
          var pA = (it.path || "").trim().replace(/\/+$/, "")
          var pB = (itemObj.path || "").trim().replace(/\/+$/, "")
          if (pA && pA === pB) {
            root.showEditorToast((itemObj.name || (itemObj.isFile ? "File" : "Folder")) + " is already in this container")
            return
          }
        }
      }
    }

    if (!targetBlock) {
      // Create block first, then set its initial item
      var addRes = ComposerModel.tryAddBlock(root.editSessionDraft, cid, kind, "compact", "", metrics)
      if (addRes.ok) {
        root.pushDraftChange(addRes.value)
        var updatedC = null
        for (var j = 0; j < addRes.value.containers.length; j++) {
          if (addRes.value.containers[j].id === cid) {
            updatedC = addRes.value.containers[j]
            break
          }
        }
        if (updatedC && Array.isArray(updatedC.blocks)) {
          for (var k = 0; k < updatedC.blocks.length; k++) {
            if (updatedC.blocks[k] && updatedC.blocks[k].kind === kind) {
              var newBlock = updatedC.blocks[k]
              var initialItems = [ itemObj ]
              var setRes = ComposerModel.trySetBlockSettings(addRes.value, cid, newBlock.id, { items: initialItems }, metrics)
              if (setRes.ok) {
                root.pushDraftChange(setRes.value)
                root.expandContainerIfNeeded(cid, 1)
                root.showEditorToast("Added " + (itemObj.name || (kind === "app-grid" ? "Application" : "Folder")))
              }
              break
            }
          }
        }
      } else {
        root.showEditorToast("Cannot add " + kind + ": " + (addRes.error ? (addRes.error.code || addRes.error) : "no space"))
      }
    } else {
      // Append to existing block
      var updatedItems = (targetBlock.settings && Array.isArray(targetBlock.settings.items)) ? targetBlock.settings.items.slice() : []
      updatedItems.push(itemObj)
      var setExistingRes = ComposerModel.trySetBlockSettings(root.editSessionDraft, cid, targetBlock.id, { items: updatedItems }, metrics)
      if (setExistingRes.ok) {
        root.pushDraftChange(setExistingRes.value)
        root.expandContainerIfNeeded(cid, updatedItems.length)
        root.showEditorToast("Added " + (itemObj.name || (kind === "app-grid" ? "Application" : "Folder")))
      } else {
        root.showEditorToast("Failed to update: " + (setExistingRes.error ? setExistingRes.error.code : ""))
      }
    }
  }

  function removeShortcutItemFromContainer(cid, blockId, itemId) {
    if (!root.editSessionDraft || !itemId) return
    var metrics = root.getLayoutMetrics()
    var c = null
    for (var i = 0; i < root.editSessionDraft.containers.length; i++) {
      if (root.editSessionDraft.containers[i].id === cid) {
        c = root.editSessionDraft.containers[i]
        break
      }
    }
    if (!c || !Array.isArray(c.blocks)) return

    for (var b = 0; b < c.blocks.length; b++) {
      var blk = c.blocks[b]
      if (blk && (!blockId || blk.id === blockId) && blk.settings && Array.isArray(blk.settings.items)) {
        var prevCount = blk.settings.items.length
        var newItems = blk.settings.items.filter(function(it) {
          if (!it) return false
          if (it.id && it.id === itemId) return false
          if (it.command && it.command === itemId) return false
          if (it.path && it.path === itemId) return false
          if (it.name && it.name === itemId) return false
          return true
        })
        if (newItems.length < prevCount) {
          var setRes = ComposerModel.trySetBlockSettings(root.editSessionDraft, cid, blk.id, { items: newItems }, metrics)
          if (setRes.ok) {
            root.pushDraftChange(setRes.value)
            root.showEditorToast("Removed shortcut")
          }
          break
        }
      }
    }
  }

  function selectedDrawerContainer() {
    if (!root.editSessionDraft || !Array.isArray(root.editSessionDraft.containers) || !root.activeDrawerContainerId) {
      return null
    }
    for (var i = 0; i < root.editSessionDraft.containers.length; i++) {
      var c = root.editSessionDraft.containers[i]
      if (c && c.id === root.activeDrawerContainerId) {
        return c
      }
    }
    return null
  }

  function setDraftCardAlpha(alpha) {
    if (!root.editSessionDraft) return
    var candidate = JSON.parse(JSON.stringify(root.editSessionDraft))
    candidate.cardOpacity = alpha
    root.cardOpacity = alpha
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.validateDraft(candidate, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    }
  }

  function setDraftAutoHide(autoHide) {
    if (!root.editSessionDraft) return
    var candidate = JSON.parse(JSON.stringify(root.editSessionDraft))
    candidate.autoHideOnWindows = autoHide
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.validateDraft(candidate, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    }
  }

  function setDraftTargetWorkspace(ws) {
    if (!root.editSessionDraft) return
    var candidate = JSON.parse(JSON.stringify(root.editSessionDraft))
    candidate.targetWorkspace = ws
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.validateDraft(candidate, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    }
  }

  function toggleContainerVisibility(cid) {
    if (!root.editSessionDraft) return
    var candidate = JSON.parse(JSON.stringify(root.editSessionDraft))
    var containers = candidate.containers || []
    for (var i = 0; i < containers.length; i++) {
      if (containers[i].id === cid) {
        containers[i].enabled = (containers[i].enabled === false) ? true : false
        break
      }
    }
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.validateDraft(candidate, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    }
  }

  function setContainerTitle(cid, title) {
    if (!root.editSessionDraft) return
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.trySetContainerTitle(root.editSessionDraft, cid, title, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    }
  }

  function setContainerHeaderMode(cid, headerMode) {
    if (!root.editSessionDraft) return
    var metrics = root.getLayoutMetrics()
    var res = ComposerModel.trySetContainerHeaderMode(root.editSessionDraft, cid, headerMode, metrics)
    if (res.ok) {
      root.pushDraftChange(res.value)
    }
  }

  function applyV2SessionCandidate(candidate) {
    var metrics = root.getLayoutMetrics()
    var result = ComposerModel.validateDraft(candidate, metrics)
    if (!result || !result.ok) {
      return { ok: false, error: result ? result.error : { code: "INVALID_CONFIG" } }
    }
    return { ok: true, value: result.value, error: null }
  }

  function disableV2Preview(): bool {
    if (root.v2PreviewForced) {
      return false
    }
    root.v2PreviewSessionEnabled = false
    return true
  }

  function saveV2Config(candidate) {
    if (!candidate || saveProcess.running || root.pendingV2Candidate !== null) return false
    var normalized = ConfigModel.normalize(candidate)
    var valRes = ConfigModel.validateV2(normalized)
    if (!valRes || !valRes.ok) return false
    root.pendingV2Candidate = ConfigModel.clone(valRes.value)
    saveProcess.command = ["/usr/bin/python3", root.saveConfigScript, JSON.stringify(valRes.value), root.userConfigFile]
    saveProcess.running = true
    return true
  }

  readonly property var v2LayoutEval: root.evaluateV2PreviewPacking()

  function relayoutPortals(persist) {
    return true
  }

  function setPortalSpan(id, colSpan, rowSpan) {
    return false
  }

  function cyclePortalSpan(id) {
    return false
  }

  function toggleWorkspaceShortcut() {
    var currentWs = root.activeWsId > 0 ? root.activeWsId : 1

    if (currentWs === 1) {
      if (!root.deskClosed && (root.targetWorkspace === 1 || root.targetWorkspace === 0)) {
        // Visible on workspace 1 -> close/hide widget completely
        root.deskClosed = true
        root.saveConfig({ "deskClosed": true })
      } else {
        // Closed or on another workspace -> show on workspace 1
        root.deskClosed = false
        root.targetWorkspace = 1
        root.saveConfig({ "targetWorkspace": 1, "deskClosed": false })
      }
    } else {
      // On workspace N (e.g. 2, 3...)
      if (!root.deskClosed && root.targetWorkspace === currentWs) {
        // Visible on workspace N -> return to workspace 1
        root.deskClosed = false
        root.targetWorkspace = 1
        root.saveConfig({ "targetWorkspace": 1, "deskClosed": false })
      } else {
        // Not visible on workspace N -> move and show on workspace N
        root.deskClosed = false
        root.targetWorkspace = currentWs
        root.saveConfig({ "targetWorkspace": currentWs, "deskClosed": false })
      }
    }
  }

  function open(payload) {
    root.deskClosed = false
    if (payload === "edit" || (payload && payload.editMode === true)) {
      root.enterEditMode()
    }
  }

  function close() {
    root.deskClosed = true
    root.saveConfig({ "deskClosed": true })
  }

  function toggle() {
    if (root.opened) {
      root.close()
    } else {
      root.open()
    }
  }

  property bool todoOverlayOpen: false

  function toggleTodoOverlay() {
    root.todoOverlayOpen = !root.todoOverlayOpen
  }

  // Inter-Process Communication (IPC) Handler for ArchyWidgets
  IpcHandler {
    target: "archywidgets"

    function toggle(): string {
      root.toggleWorkspaceShortcut()
      return "ok"
    }

    function toggleWorkspace(): string {
      root.toggleWorkspaceShortcut()
      return "ok"
    }

    function toggleTodoOverlay(): string {
      root.todoOverlayOpen = !root.todoOverlayOpen
      return root.todoOverlayOpen ? "opened" : "closed"
    }

    function openTodoOverlay(): string {
      root.todoOverlayOpen = true
      return "opened"
    }

    function closeTodoOverlay(): string {
      root.todoOverlayOpen = false
      return "closed"
    }

    function showOnWorkspace(wsId: string): string {
      var id = parseInt(wsId)
      if (!isNaN(id)) {
        root.deskClosed = false
        root.targetWorkspace = id
        root.saveConfig({ "targetWorkspace": id, "deskClosed": false })
        return "ok"
      }
      return "invalid"
    }

    function close(): string {
      root.deskClosed = true
      root.saveConfig({ "deskClosed": true })
      return "ok"
    }

    function relayout(): string {
      var ok = root.relayoutPortals(true)
      return ok ? "ok" : "rejected"
    }

    function setSpan(id: string, colSpanStr: string, rowSpanStr: string): string {
      var c = parseInt(colSpanStr)
      var r = parseInt(rowSpanStr)
      if (!isNaN(c) && !isNaN(r)) {
        var ok = root.setPortalSpan(id, c, r)
        return ok ? "ok" : "rejected"
      }
      return "invalid"
    }

    function cycleSpan(id: string): string {
      var ok = root.cyclePortalSpan(id)
      return ok ? "ok" : "rejected"
    }

    function getLayout(): string {
      return JSON.stringify(root.v2SessionConfig ? root.v2SessionConfig.containers : [])
    }

    function toggleSettings(): string {
      root.deskClosed = false
      if (root.editMode && desktopEditSidebar && desktopEditSidebar.activeFlyout === "settings") {
        root.cancelEditMode()
      } else {
        root.enterEditMode()
        if (desktopEditSidebar) {
          desktopEditSidebar.openFlyout("settings")
        }
      }
      return "ok"
    }

    function openSettings(): string {
      root.deskClosed = false
      root.enterEditMode()
      if (desktopEditSidebar) {
        desktopEditSidebar.openFlyout("settings")
      }
      return "ok"
    }

    function openComposer(): string {
      root.deskClosed = false
      root.enterEditMode()
      return "ok"
    }

    function toggleEditMode(): string {
      root.deskClosed = false
      if (root.editMode) {
        root.cancelEditMode()
      } else {
        root.enterEditMode()
      }
      return "ok"
    }

    function status(): string {
      var scr = (Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0] : null
      return JSON.stringify({
        "targetWorkspace": root.targetWorkspace,
        "deskClosed": root.deskClosed,
        "activeWsId": root.activeWsId,
        "shouldBeVisible": root.shouldBeVisible,
        "effectiveVisible": !root.deskClosed && root.shouldBeVisible,
        "settingsOpen": false,
        "composerOpen": false,
        "rootWidth": root.screenWidth,
        "rootHeight": root.screenHeight,
        "scrWidth": scr ? scr.width : null,
        "scrHeight": scr ? scr.height : null
      })
    }
  }

  // Canonical Omarchy Reverse-DNS IPC Handler
  IpcHandler {
    target: root.moduleName

    function toggle(): string {
      root.toggleWorkspaceShortcut()
      return "ok"
    }

    function toggleWorkspace(): string {
      root.toggleWorkspaceShortcut()
      return "ok"
    }

    function toggleTodoOverlay(): string {
      root.todoOverlayOpen = !root.todoOverlayOpen
      return root.todoOverlayOpen ? "opened" : "closed"
    }

    function openTodoOverlay(): string {
      root.todoOverlayOpen = true
      return "opened"
    }

    function closeTodoOverlay(): string {
      root.todoOverlayOpen = false
      return "closed"
    }

    function showOnWorkspace(wsId: string): string {
      var id = parseInt(wsId)
      if (!isNaN(id)) {
        root.deskClosed = false
        root.targetWorkspace = id
        root.saveConfig({ "targetWorkspace": id, "deskClosed": false })
        return "ok"
      }
      return "invalid"
    }

    function close(): string {
      root.deskClosed = true
      root.saveConfig({ "deskClosed": true })
      return "ok"
    }

    function relayout(): string {
      var ok = root.relayoutPortals(true)
      return ok ? "ok" : "rejected"
    }

    function setSpan(id: string, colSpanStr: string, rowSpanStr: string): string {
      var c = parseInt(colSpanStr)
      var r = parseInt(rowSpanStr)
      if (!isNaN(c) && !isNaN(r)) {
        var ok = root.setPortalSpan(id, c, r)
        return ok ? "ok" : "rejected"
      }
      return "invalid"
    }

    function cycleSpan(id: string): string {
      var ok = root.cyclePortalSpan(id)
      return ok ? "ok" : "rejected"
    }

    function openSettings(): string {
      root.deskClosed = false
      root.enterEditMode()
      if (desktopEditSidebar) {
        desktopEditSidebar.openFlyout("settings")
      }
      return "ok"
    }

    function openComposer(): string {
      root.deskClosed = false
      root.enterEditMode()
      return "ok"
    }

    function toggleEditMode(): string {
      root.deskClosed = false
      if (root.editMode) {
        root.cancelEditMode()
      } else {
        root.enterEditMode()
      }
      return "ok"
    }

    function status(): string {
      var scr = (Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0] : null
      return JSON.stringify({
        "targetWorkspace": root.targetWorkspace,
        "deskClosed": root.deskClosed,
        "activeWsId": root.activeWsId,
        "shouldBeVisible": root.shouldBeVisible,
        "effectiveVisible": !root.deskClosed && root.shouldBeVisible,
        "settingsOpen": false,
        "composerOpen": false,
        "rootWidth": root.screenWidth,
        "rootHeight": root.screenHeight,
        "scrWidth": scr ? scr.width : null,
        "scrHeight": scr ? scr.height : null
      })
    }
  }

  // Config Watcher (hot reload on external or internal edit)
  FileView {
    id: userConfigWatcher
    path: root.userConfigFile
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadConfig(text())
    onFileChanged: reload()
    onLoadFailed: root.loadConfig("")
  }

  // Todo Items Watcher (~/.config/omarchy/todo-list/items.json)
  FileView {
    id: todoFileWatcher
    path: root.todoItemsFile
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadTodoJson(text())
    onFileChanged: reload()
    onLoadFailed: {
      root.todoAvailable = false
      root.todoItems = []
      root.todoHistory = []
      root.todoOpenCount = 0
    }
  }

  // Notification Settings Watcher (~/.local/state/omarchy/notifications.json)
  FileView {
    id: notifSettingsWatcher
    path: root.notifSettingsFile
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onLoaded: root.loadNotifSettings(text())
    onFileChanged: reload()
    onLoadFailed: {
      root.dndActive = false
    }
  }

  Component.onCompleted: {
    userConfigWatcher.reload()
    todoFileWatcher.reload()
    notifSettingsWatcher.reload()
  }

  function loadTodoJson(jsonText) {
    if (!jsonText || jsonText.trim() === "") {
      root.todoAvailable = false
      return
    }
    try {
      var data = JSON.parse(jsonText)
      root.todoAvailable = true
      root.todoItems = Array.isArray(data.items) ? data.items : []
      root.todoHistory = Array.isArray(data.history) ? data.history : []
      var count = 0
      for (var i = 0; i < root.todoItems.length; i++) {
        if (!root.todoItems[i].done) count++
      }
      root.todoOpenCount = count
    } catch (e) {
      console.warn("ArchyWidgets: Error parsing todo JSON:", e)
    }
  }

  function loadNotifSettings(jsonText) {
    if (!jsonText || jsonText.trim() === "") return
    try {
      var data = JSON.parse(jsonText)
      root.dndActive = (data.dnd === true)
    } catch (e) {
      console.warn("ArchyWidgets: Error parsing notif settings:", e)
    }
  }

  function loadConfig(jsonText) {
    if (!jsonText || jsonText.trim() === "") return
    try {
      var cfg = JSON.parse(jsonText)
      if (typeof cfg.targetWorkspace === "number") root.targetWorkspace = cfg.targetWorkspace
      if (typeof cfg.deskClosed === "boolean") root.deskClosed = cfg.deskClosed
      if (typeof cfg.autoHideOnWindows === "boolean") root.autoHideOnWindows = cfg.autoHideOnWindows
      if (typeof cfg.cardOpacity === "number") root.cardOpacity = cfg.cardOpacity
      if (typeof cfg.showClock === "boolean") root.showClock = cfg.showClock
      if (cfg.schemaVersion === 2 || (Array.isArray(cfg.containers) && cfg.containers.length > 0)) {
        var norm = ConfigModel.normalize(cfg)
        var val = ConfigModel.validateV2(norm)
        if (val && val.ok) {
          root.v2SessionConfig = ConfigModel.clone(val.value)
          root.v2PreviewSessionEnabled = true
        }
      } else if (Array.isArray(cfg.portals) && cfg.portals.length > 0) {
        var migrated = ConfigModel.migrate(cfg)
        var valMig = ConfigModel.validateV2(migrated)
        if (valMig && valMig.ok) {
          root.v2SessionConfig = ConfigModel.clone(valMig.value)
          root.v2PreviewSessionEnabled = true
        }
      }
    } catch (e) {
      console.warn("ArchyWidgets: Error parsing config JSON:", e)
    }
  }

  // Workspace & Window Detection
  readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
  readonly property bool hasAppWindows: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.toplevels.values.length > 0
  readonly property bool shouldBeVisible: root.targetWorkspace === 0 || (root.activeWsId === root.targetWorkspace)

  // Real-time continuous streaming stats process
  Process {
    id: statsProcess
    command: ["/usr/bin/python3", root.statsScript]
    running: (!root.deskClosed && root.shouldBeVisible && (!root.autoHideOnWindows || !root.hasAppWindows)) || root.editMode
    stdout: SplitParser {
      onRead: function(line) {
        try {
          var data = JSON.parse(String(line).trim())
          root.updateAllStats(data)
        } catch (e) {}
      }
    }
  }

  function updateAllStats(data) {
    // Synchronous assignment in one millisecond
    root.cpuPercent = data.cpu || 0
    root.cpuModel = data.cpu_model || ""
    root.cpuCores = (typeof data.cpu_cores === "number") ? data.cpu_cores : 0
    root.kernelVer = data.kernel || ""
    root.hostname = data.hostname || ""
    root.osName = data.os_name || "Omarchy"
    root.loadAvg = String(data.load_avg || "")
    root.ramPercent = data.ram_percent || 0
    root.ramUsed = String(data.ram_used_gb || "0")
    root.ramTotal = String(data.ram_total_gb || "0")
    root.swapPercent = (typeof data.swap_percent === "number") ? data.swap_percent : 0
    root.swapUsed = String(data.swap_used_gb || "0.0")
    root.swapTotal = String(data.swap_total_gb || "0.0")
    root.diskPercent = data.disk_percent || 0
    root.diskUsed = String(data.disk_used_gb || "0")
    root.diskTotal = String(data.disk_total_gb || "0")
    root.diskFree = String(data.disk_free_gb || "0")
    root.diskFreeStr = String(data.disk_free_str || (root.diskFree + " GB"))
    root.diskTotalStr = String(data.disk_total_str || (root.diskTotal + " GB"))
    root.diskLabel = String(data.disk_label || "System")
    root.disks = Array.isArray(data.disks) ? data.disks : []
    root.diskHddAvailable = Boolean(data.disk_hdd_available)
    root.diskHddPercent = (typeof data.disk_hdd_percent === "number") ? data.disk_hdd_percent : 0
    root.diskHddUsed = String(data.disk_hdd_used_gb || "0")
    root.diskHddTotal = String(data.disk_hdd_total_gb || "0")
    root.diskHddFreeStr = String(data.disk_hdd_free_str || "0 GB")
    root.diskHddLabel = String(data.disk_hdd_label || "HDD")
    root.netDown = data.net_down_str || "0 KB/s"
    root.netUp = data.net_up_str || "0 KB/s"
    root.netDownBps = (typeof data.net_down_bps === "number" && isFinite(data.net_down_bps)) ? Math.max(0, data.net_down_bps) : 0
    root.netUpBps = (typeof data.net_up_bps === "number" && isFinite(data.net_up_bps)) ? Math.max(0, data.net_up_bps) : 0
    root.netTotalDown = String(data.net_total_down_str || "0 KB")
    root.netTotalUp = String(data.net_total_up_str || "0 KB")
    root.netType = String(data.net_type || "Offline")
    root.netDevice = String(data.net_device || "")
    root.netIp = String(data.net_ip || "")
    root.netSsid = data.ssid || "Disconnected"
    root.batteryAvailable = data.battery_available === true
    root.batteryPercent = (typeof data.battery_percent === "number") ? data.battery_percent : 100
    root.batteryCharging = data.battery_charging === true
    root.batteryTimeRemaining = String(data.battery_time_str || "")
    root.batteryPowerWatts = String(data.battery_power_w || "")
    root.tempCpu = data.temp_cpu || 0
    root.tempGpu = data.temp_gpu || 0
    root.tempNvme = data.temp_nvme || 0
    root.tempHdd = data.temp_hdd || 0
    root.fanMode = (typeof data.fan_mode === "number") ? data.fan_mode : -1
    root.uptimeText = data.uptime || ""
    root.telemetryReady = true
    if (Array.isArray(data.recent_notifications)) {
      root.recentNotifications = data.recent_notifications
    }
    sharedDataHub.revision += 1
  }

  // Layer-shell Window
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: desktopWindow
      required property var modelData
      readonly property bool isTargetScreen: (!Quickshell.screens || Quickshell.screens.length === 0 || desktopWindow.screen === Quickshell.screens[0])

      screen: modelData
      color: "transparent"
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      Component.onCompleted: {
        if (desktopWindow.isTargetScreen && desktopWindow.screen && desktopWindow.screen.width > 0) {
          root.screenWidth = desktopWindow.screen.width
          root.screenHeight = desktopWindow.screen.height - root.bottomInset
        }
      }

      WlrLayershell.layer: WlrLayer.Bottom
      WlrLayershell.keyboardFocus: root.editMode ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore

      Shortcut {
        enabled: root.editMode
        sequence: "Escape"
        onActivated: {
          if (root.appPickerOpen) {
            root.appPickerOpen = false
            return
          }
          if (root.folderPickerOpen) {
            root.folderPickerOpen = false
            return
          }
          if (root.blockDrawerOpen) {
            root.blockDrawerOpen = false
            return
          }
          root.cancelEditMode()
        }
      }
      Shortcut {
        enabled: root.editMode && root.editHistoryStack.length > 1
        sequences: [StandardKey.Undo, "Ctrl+Z"]
        onActivated: root.undoEditMode()
      }
      Shortcut {
        enabled: root.editMode
        sequences: [StandardKey.Save, "Ctrl+S"]
        onActivated: root.commitEditMode()
      }

      // Disappears completely when closed by user, or apps are open on the workspace (unless editMode)
      visible: desktopWindow.isTargetScreen && !root.deskClosed && root.shouldBeVisible && (!root.autoHideOnWindows || !root.hasAppWindows || root.editMode)

      // Main Canvas Container
      Item {
        anchors.fill: parent

        opacity: (root.hasAppWindows && root.autoHideOnWindows && !root.editMode) ? 0.0 : 1.0

        Behavior on opacity {
          NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
        }

        Item {
          id: clockBanner
          visible: root.showClock && !root.v2PreviewEnabled
        }

        // Adaptive Bento Grid Canvas for Containers
        Item {
          id: portalsCanvas
          anchors.fill: parent

          onWidthChanged: {
            if (width >= 400 && width !== root.screenWidth) {
              root.screenWidth = width
            }
          }
          onHeightChanged: {
            if (height >= 300 && height !== root.screenHeight) {
              root.screenHeight = height
            }
          }

          Repeater {
            model: root.v2PreviewEnabled ? [] : root.portals
            Item {}
          }

          // Bento Slot Ghost for visual feedback during dragging
          Rectangle {
            id: ghostPlacementRect
            visible: root.editMode && root.ghostVisible
            readonly property bool collides: {
              if (!root.editMode || !root.ghostVisible || !root.editSessionDraft) return false
              var containers = root.editSessionDraft.containers || []
              var curId = root.activeDragContainerId
              var gCol = root.ghostCol
              var gRow = root.ghostRow
              var gW = root.ghostColSpan
              var gH = root.ghostRowSpan
              var m = root.getLayoutMetrics()
              if (!m || !m.valid) return true
              if (gCol + gW > m.columns || gRow + gH > m.maxRows) return true
              for (var i = 0; i < containers.length; i++) {
                var c = containers[i]
                if (c.id === curId || c.enabled === false) continue
                if (typeof c.col === "number" && typeof c.row === "number") {
                  var cW = c.colSpan || 1
                  var cH = c.rowSpan || 1
                  if (!(gCol + gW <= c.col || c.col + cW <= gCol || gRow + gH <= c.row || c.row + cH <= gRow)) {
                    return true
                  }
                }
              }
              return false
            }
            x: {
              var m = root.getLayoutMetrics()
              return (m && m.valid) ? m.startX + root.ghostCol * (m.cellWidth + m.colGap) : 0
            }
            y: {
              var m = root.getLayoutMetrics()
              return (m && m.valid) ? m.startY + root.ghostRow * (m.cellHeight + m.rowGap) : 0
            }
            width: {
              var m = root.getLayoutMetrics()
              return (m && m.valid) ? root.ghostColSpan * m.cellWidth + (root.ghostColSpan - 1) * m.colGap : 160
            }
            height: {
              var m = root.getLayoutMetrics()
              return (m && m.valid) ? root.ghostRowSpan * m.cellHeight + (root.ghostRowSpan - 1) * m.rowGap : 104
            }
            radius: Commons.Style.cornerRadius
            color: collides ? Commons.Util.alpha(Commons.Color.urgent, 0.22) : Commons.Util.alpha(Commons.Color.accent, 0.15)
            border.color: collides ? Commons.Color.urgent : Commons.Color.accent
            border.width: Commons.Style.normalBorderWidth
            z: 90

            Behavior on x { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
          }

          // Version 2 Containers
          Repeater {
            model: (root.v2PreviewEnabled && root.v2LayoutEval.fits) ? root.v2LayoutEval.placements : []

            ContainerHost {
              required property var modelData
              x: modelData.x
              y: modelData.y
              width: modelData.width
              height: modelData.height
              containerData: modelData.containerData
              dataHub: sharedDataHub
              actionHub: root.fanActionHub
              cardAlpha: root.v2LayoutEval.cardOpacity
              previewMode: true
              editMode: root.editMode
              selectedBlockId: root.selectedBlockId

              onBlockSelected: function(blockId) {
                root.selectBlockOnDesktop(modelData.containerData.id, blockId)
              }
              onBlockVariantRequested: function(containerId, blockId, variant) {
                root.setBlockVariantInContainer(containerId, blockId, variant)
              }
              onDragStarted: function(containerId, curX, curY) {
                root.activeDragContainerId = containerId
                root.ghostColSpan = modelData.containerData.colSpan || 1
                root.ghostRowSpan = modelData.containerData.rowSpan || 1
                root.handleContainerDragMove(containerId, curX, curY)
              }
              onDragMoved: function(containerId, curX, curY) {
                root.handleContainerDragMove(containerId, curX, curY)
              }
              onDragFinished: function(containerId, curX, curY) {
                root.handleContainerDragFinish(containerId, curX, curY)
              }
              onResizeSpanRequested: function(containerId, newColSpan, newRowSpan) {
                root.resizeContainer(containerId, newColSpan, newRowSpan)
              }
              onRemoveContainerRequested: function(containerId) {
                root.removeContainer(containerId)
              }
              onAddBlockRequested: function(containerId) {
                root.activeDrawerContainerId = containerId
                root.blockDrawerOpen = true
              }
              onAddApplicationRequested: function(containerId) {
                root.openAppPickerForContainer(containerId)
              }
              onAddFolderRequested: function(containerId) {
                root.openFolderPickerForContainer(containerId, "folder")
              }
              onAddFileRequested: function(containerId) {
                root.openFolderPickerForContainer(containerId, "file")
              }
              onItemAddRequested: function(containerId, blockId, kind) {
                if (kind === "app-grid") {
                  root.openAppPickerForContainer(containerId)
                } else {
                  root.openFolderPickerForContainer(containerId, "folder")
                }
              }
              onItemRemoveRequested: function(containerId, blockId, itemId) {
                root.removeShortcutItemFromContainer(containerId, blockId, itemId)
              }
              onBlockRemoveRequested: function(containerId, blockId) {
                root.removeBlockFromContainer(containerId, blockId)
              }
              onLayoutModeToggleRequested: function(containerId, nextMode) {
                root.toggleContainerLayoutMode(containerId, nextMode)
              }
            }
          }
        }

        // Discoverable V2 settings & layout studio entry.
        // Compact, horizontal, icon-only desktop toolbar anchored to the bottom-right.
        Components.DesktopToolbar {
          id: quickSettingsButton
          visible: root.v2PreviewEnabled && !root.editMode
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.rightMargin: Math.max(16, Commons.Style.gapsOut * 2)
          anchors.bottomMargin: root.bottomInset + Math.max(16, Commons.Style.gapsOut * 2)

          // text: "Customize"
          onEditLayoutRequested: root.enterEditMode()
          onSettingsRequested: {
            root.enterEditMode()
            if (desktopEditSidebar) {
              desktopEditSidebar.openFlyout("settings")
            }
          }
        }

        // 3. Edit Mode Floating Toolbar (Obsolete in V2)
        // Interactive Desktop Layout Studio Vertical Sidebar
        Editor.DesktopEditSidebar {
          id: desktopEditSidebar
          visible: root.editMode
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.leftMargin: 12
          anchors.topMargin: 24
          anchors.bottomMargin: root.bottomInset + 24
          canUndo: root.editHistoryStack.length > 1
          isDirty: root.editHistoryStack.length > 1
          containersList: (root.editSessionDraft && root.editSessionDraft.containers) || []
          currentCardAlpha: (root.editSessionDraft && typeof root.editSessionDraft.cardOpacity === "number") ? root.editSessionDraft.cardOpacity : root.cardOpacity
          currentAutoHide: (root.editSessionDraft && typeof root.editSessionDraft.autoHideOnWindows === "boolean") ? root.editSessionDraft.autoHideOnWindows : root.autoHideOnWindows
          currentTargetWorkspace: (root.editSessionDraft && typeof root.editSessionDraft.targetWorkspace === "number") ? root.editSessionDraft.targetWorkspace : root.targetWorkspace
          currentLayoutMode: (root.editSessionDraft && root.editSessionDraft.layoutMode) || "auto"
          z: 300

          onAddContainerRequested: root.addEmptyContainer()
          onEmptyContainerRequested: {
            root.addEmptyContainer()
            root.blockDrawerOpen = true
          }
          onContainerTemplateSelected: function(templateId) {
            root.addContainerFromTemplate(templateId)
          }
          onContainerVisibilityToggled: function(containerId) {
            root.toggleContainerVisibility(containerId)
          }
          onContainerAddBlocksRequested: function(containerId) {
            root.activeDrawerContainerId = containerId
            root.blockDrawerOpen = true
          }
          onContainerRemoved: function(containerId) {
            root.removeContainer(containerId)
          }
          onContainerTitleChanged: function(containerId, title) {
            root.setContainerTitle(containerId, title)
          }
          onContainerHeaderModeChanged: function(containerId, headerMode) {
            root.setContainerHeaderMode(containerId, headerMode)
          }
          onContainerSpanRequested: function(containerId, colSpan, rowSpan) {
            root.resizeContainer(containerId, colSpan, rowSpan)
          }
          onCardAlphaRequested: function(alpha) {
            root.setDraftCardAlpha(alpha)
          }
          onAutoHideRequested: function(autoHide) {
            root.setDraftAutoHide(autoHide)
          }
          onTargetWorkspaceRequested: function(ws) {
            root.setDraftTargetWorkspace(ws)
          }
          onLayoutModeRequested: function(mode) {
            root.setDraftArrangementMode(mode)
          }
          onAutoPackRequested: root.autoPackContainers()
          onUndoRequested: root.undoEditMode()
          onCancelRequested: root.cancelEditMode()
          onSaveRequested: root.commitEditMode()
        }

        // Slide-out Drawer for adding blocks to selected container
        Rectangle {
          id: blockDrawer
          visible: root.editMode && root.blockDrawerOpen
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          anchors.topMargin: 12
          anchors.bottomMargin: root.bottomInset + 12
          anchors.rightMargin: 12
          width: Math.min(380, parent.width - 24)
          radius: Commons.Style.cornerRadius
          color: Commons.Color.background
          border.color: Commons.Util.alpha(Commons.Color.foreground, 0.22)
          border.width: Commons.Style.normalBorderWidth
          z: 350
          clip: true

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
              Layout.fillWidth: true

              Text {
                text: "󱗼 Add / Configure Blocks"
                font.family: Commons.Style.fontFamily
                font.pixelSize: 13
                font.bold: true
                color: Commons.Color.foreground
                Layout.fillWidth: true
              }

              Rectangle {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                radius: Commons.Style.cornerRadius
                color: drawerCloseHov.hovered ? Commons.Color.urgent : Commons.Util.alpha(Commons.Color.foreground, 0.08)

                HoverHandler { id: drawerCloseHov; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: root.blockDrawerOpen = false }

                Text {
                  anchors.centerIn: parent
                  text: "✕"
                  font.family: Commons.Style.fontFamily
                  font.pixelSize: 11
                  color: drawerCloseHov.hovered ? Commons.Color.background : Commons.Color.foreground
                }
              }
            }

            Editor.BlockPalettePane {
              id: drawerPalette
              visible: root.blockDrawerOpen
              Layout.fillWidth: true
              Layout.fillHeight: true
              selectedContainer: root.selectedDrawerContainer()
              selectedBlockId: root.selectedBlockId
              showAllBlocks: true

              onBlockSelected: function(id) {
                root.selectedBlockId = id
              }
              onExpandAndApplyRequested: function(containerId, blockId, variant) {
                root.expandContainerAndSetVariant(containerId, blockId, variant)
              }
              onAddBlockRequested: function(kind, variant, source) {
                root.addBlockToContainer(root.activeDrawerContainerId, kind, variant, source)
              }
              onRemoveBlockRequested: function(id) {
                root.removeBlockFromContainer(root.activeDrawerContainerId, id)
              }
              onVariantRequested: function(id, variant) {
                root.setBlockVariantInContainer(root.activeDrawerContainerId, id, variant)
              }
              onSettingsUpdateRequested: function(bid, nextSettings) {
                root.updateBlockSettings(root.activeDrawerContainerId, bid, nextSettings)
                if (nextSettings && Array.isArray(nextSettings.items)) {
                  root.expandContainerIfNeeded(root.activeDrawerContainerId, nextSettings.items.length)
                }
              }
            }
          }
        }

        // Toast notification banner for editor feedback
        Rectangle {
          id: editorToastBox
          visible: opacity > 0.0
          opacity: 0.0
          anchors.horizontalCenter: parent.horizontalCenter
          anchors.bottom: parent.bottom
          anchors.bottomMargin: root.bottomInset + 24
          implicitWidth: toastRow.implicitWidth + 28
          implicitHeight: 36
          radius: Commons.Style.cornerRadius
          color: Commons.Color.urgent
          border.color: Commons.Util.alpha(Commons.Color.foreground, 0.3)
          border.width: Commons.Style.normalBorderWidth
          z: 500

          SequentialAnimation {
            id: toastAnim
            NumberAnimation { target: editorToastBox; property: "opacity"; to: 1.0; duration: 150 }
            PauseAnimation { duration: 3000 }
            NumberAnimation { target: editorToastBox; property: "opacity"; to: 0.0; duration: 250 }
          }

          Connections {
            target: root
            function onTriggerEditorToast() {
              toastAnim.restart()
            }
          }

          RowLayout {
            id: toastRow
            anchors.centerIn: parent
            spacing: 8

            Text {
              text: "⚠"
              font.pixelSize: 13
              color: "#ffffff"
            }

            Text {
              text: root.editorToastMessage
              font.family: Commons.Style.fontFamily
              font.pixelSize: 12
              font.bold: true
              color: "#ffffff"
            }
          }
        }

        Connections {
          target: root
          function onAppPickerOpenChanged() {
            rootAppPickerModal.active = root.appPickerOpen
          }
          function onFolderPickerOpenChanged() {
            rootFileFolderPickerModal.active = root.folderPickerOpen
          }
          function onFolderPickerModeChanged() {
            rootFileFolderPickerModal.mode = root.folderPickerMode
          }
        }

        // Global App and File/Folder Picker Modals for Direct Container Management
        Components.AppPickerModal {
          id: rootAppPickerModal
          anchors.fill: parent
          z: 2500
          active: root.appPickerOpen
          onClosed: root.appPickerOpen = false
          onAppSelected: function(name, icon, command, sub) {
            root.appPickerOpen = false
            root.addShortcutToContainer(root.targetAddContainerId, "app-grid", {
              name: name,
              icon: icon,
              command: command,
              sub: sub
            })
          }
        }

        Components.FileFolderPickerModal {
          id: rootFileFolderPickerModal
          anchors.fill: parent
          z: 2500
          mode: root.folderPickerMode
          active: root.folderPickerOpen
          onClosed: root.folderPickerOpen = false
          onItemSelected: function(name, path, isFile, icon) {
            root.folderPickerOpen = false
            root.addShortcutToContainer(root.targetAddContainerId, "folder-grid", {
              name: name,
              path: path,
              isFile: isFile,
              icon: icon
            })
          }
        }
      }
    }
  }

  // Centered Todo List Overlay Window (WlrLayer.Overlay)
  PanelWindow {
    id: todoOverlayWindow
    screen: (Quickshell.screens && Quickshell.screens.length > 0) ? Quickshell.screens[0] : null
    visible: root.todoOverlayOpen
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    color: "transparent"
    WlrLayershell.namespace: "archywidgets-todo-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.todoOverlayOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // Dimmed Scrim / Backdrop
    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.45)

      MouseArea {
        anchors.fill: parent
        onClicked: root.todoOverlayOpen = false
      }
    }

    // Keyboard Shortcuts inside Overlay
    Shortcut {
      enabled: root.todoOverlayOpen
      sequence: "Escape"
      onActivated: root.todoOverlayOpen = false
    }
    Shortcut {
      enabled: root.todoOverlayOpen
      sequence: "Super+Alt+L"
      onActivated: root.todoOverlayOpen = false
    }

    // Centered Dialog Card
    Rectangle {
      id: todoOverlayCard
      anchors.centerIn: parent
      width: Math.min(520, parent.width - 48)
      height: Math.min(Math.round(parent.height * 0.75), Math.max(340, overlayContent.implicitContentHeight + 40))
      radius: Commons.Style.cornerRadius || 12
      color: Commons.Color.background
      border.color: Commons.Util.alpha(Commons.Color.foreground, 0.16)
      border.width: Commons.Style.normalBorderWidth || 1
      clip: true

      // Prevent clicks inside card from dismissing backdrop
      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      Blocks.TodoBlock {
        id: overlayContent
        anchors.fill: parent
        anchors.margins: 12
        isOverlay: true
        blockData: ({ id: "overlay_todo", kind: "todo", variant: "list" })
        dataHub: sharedDataHub
        actionHub: root.fanActionHub
        resolvedPresentation: "dashboard"
        densityScale: 1.0
        onCloseRequested: root.todoOverlayOpen = false
      }
    }
  }
}
