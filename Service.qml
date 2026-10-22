// OmaDisplayLink: keeps the bar icon's status current and runs setup or repair in a floating
// terminal (installing needs sudo, so it happens where you can see and answer it). All the work is
// done by bin/omadisplaylink; this file only asks it, on a timer and when something happens.
//
//   omarchy-shell io.github.bmaltais.omadisplaylink setup     guided install and configure
//   omarchy-shell io.github.bmaltais.omadisplaylink repair    fix what the card says is wrong
//   omarchy-shell io.github.bmaltais.omadisplaylink report    copy a sanitized report to the clipboard
//   omarchy-shell io.github.bmaltais.omadisplaylink refresh   look at the dock again now
// The card itself (BarWidget.qml) is opened by clicking the bar icon.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
  id: root

  // Injected by omarchy-shell (the plugin service loader).
  property var shell: null

  readonly property string cli: Qt.resolvedUrl("bin/omadisplaylink").toString().replace("file://", "")
  property string kind: "unconfigured"
  property string message: ""

  function refresh() { if (!statusProc.running) statusProc.running = true }
  function launch(what) {
    if (launchProc.running) return
    launchProc.command = [root.cli, "launch", what]
    launchProc.running = true
  }

  Component.onCompleted: refresh()

  // A dock is plugged in or removed, or an update changes things, at any time; a minute is soon
  // enough for an icon, and the status command is cheap.
  Timer {
    interval: 60000
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    command: [root.cli, "status", "--write"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var s = JSON.parse(String(text || "{}"))
          root.kind = s.kind || "unconfigured"
          root.message = s.message || ""
        } catch (e) { /* keep the last state */ }
      }
    }
  }

  // The terminal closes when setup or the doctor is done; look at the dock again then.
  Process {
    id: launchProc
    onExited: root.refresh()
  }

  IpcHandler {
    target: "io.github.bmaltais.omadisplaylink"
    function setup(): void { root.launch("setup") }
    function repair(): void { root.launch("repair") }
    function report(): void { Quickshell.execDetached([root.cli, "report"]) }
    function refresh(): void { root.refresh() }
    function state(): string { return JSON.stringify({ kind: root.kind, message: root.message }) }
  }
}
