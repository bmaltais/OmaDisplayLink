// The bar icon: a desktop that says how the DisplayLink dock is doing, and opens setup or the doctor.
// What it draws comes from a file the service keeps up to date (line 1 the state, line 2 a sentence),
// because the icon and the service are separate instances.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.bmaltais.omadisplaylink"

  readonly property string statusFile: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/OmaDisplayLink/status"
  readonly property var glyphs: ({
    unconfigured: "", // plus: nothing installed yet
    idle: "",         // desktop: installed, no dock plugged in
    ok: "",           // desktop: dock screens are working
    attention: ""     // warning triangle
  })
  property string kind: "unconfigured"
  property string message: "DisplayLink status is not known yet."

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView {
    path: root.statusFile
    // Missing until the service has first looked (a fresh install): that is "unconfigured", not an error.
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      var lines = text().split("\n")
      var k = lines[0].trim()
      root.kind = root.glyphs[k] !== undefined ? k : "unconfigured"
      root.message = lines.slice(1).join(" ").trim() || root.message
    }
    onLoadFailed: root.kind = "unconfigured"
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyphs[root.kind]
    tooltipText: "OmaDisplayLink: " + root.message
    // Lit while the dock is working; red when something needs a look.
    active: root.kind === "ok" || root.kind === "attention"
    useActiveColor: true
    activeColor: root.kind === "attention" ? Color.urgent : Color.accent
    onPressed: function (mouse) {
      if (!root.bar) return
      // Right click looks again; left click opens setup (nothing installed) or the doctor.
      if (mouse === Qt.RightButton) root.bar.run("omarchy-shell io.github.bmaltais.omadisplaylink refresh")
      else root.bar.run("omarchy-shell io.github.bmaltais.omadisplaylink open")
    }
  }
}
