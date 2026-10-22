// The bar icon and its card. The icon is the plugin's "D" mark, coloured by how the dock is doing; clicking
// it opens a card that says in a sentence what is going on and offers only actions that apply, each with
// a line saying what it will do. What it shows comes from a file the service keeps up to date (line 1 the
// state, line 2 a sentence, line 3 the action that would help), because the icon and the service are
// separate instances.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.bmaltais.omadisplaylink"

  readonly property string pluginId: "io.github.bmaltais.omadisplaylink"
  readonly property string statusFile: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/OmaDisplayLink/status"
  readonly property string guideUrl: "https://github.com/bmaltais/OmaDisplayLink#readme"

  property string kind: "unconfigured"
  property string message: "DisplayLink status is not known yet."
  // What would help, or "": setup, relogin, reinstall, patch (rebuild the NVIDIA fix) or service (restart displaylink.service).
  property string action: ""
  property bool popupOpen: false

  readonly property color markColor: kind === "attention" ? Commons.Color.urgent
    : kind === "ok" || kind === "pending" ? Commons.Color.accent
    : (root.bar ? root.bar.barForeground : Commons.Color.foreground)
  readonly property real markOpacity: kind === "idle" ? 0.6 : kind === "unconfigured" ? 0.4 : 1.0

  function close() { popupOpen = false }
  function run(what) {
    popupOpen = false
    if (root.bar) root.bar.run("omarchy-shell " + root.pluginId + " " + what)
  }
  function openGuide() {
    popupOpen = false
    Quickshell.execDetached(["xdg-open", root.guideUrl])
  }

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
      root.kind = ["unconfigured", "pending", "idle", "ok", "attention"].indexOf(k) >= 0 ? k : "unconfigured"
      root.message = (lines[1] || "").trim() || root.message
      root.action = (lines[2] || "").trim()
    }
    onLoadFailed: root.kind = "unconfigured"
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: "DisplayLink: " + root.message
    iconComponent: Component {
      Item {
        DisplayLinkMark {
          x: (parent.width - width) / 2
          y: (parent.height - height) / 2
          iconSize: button.iconSize
          color: root.markColor
          opacity: root.markOpacity
          linked: root.kind === "ok" || root.kind === "attention"
        }
      }
    }
    onPressed: function (mouse) {
      if (mouse === Qt.RightButton) root.run("refresh")
      else root.popupOpen = !root.popupOpen
    }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(320))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(10)

      Row {
        spacing: Style.space(10)
        width: parent.width

        DisplayLinkMark {
          anchors.verticalCenter: parent.verticalCenter
          iconSize: Style.space(32)
          color: root.markColor
          linked: root.kind === "ok" || root.kind === "attention"
        }

        Column {
          width: parent.width - Style.space(42)
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)

          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: "DisplayLink dock"
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }
          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: root.message
            color: root.kind === "attention" ? Commons.Color.urgent : Qt.darker(root.bar.foreground, 1.3)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
          }
        }
      }

      PanelSeparator { width: parent.width; foreground: root.bar.foreground }

      // Only the actions that apply. Each says what it will do before it does it.
      Repeater {
        model: {
          var items = []
          if (root.action === "setup") items.push({ id: "setup", label: "Set up DisplayLink",
            note: "Walks through the install step by step in a terminal. Asks before it changes anything, and for your password where a step needs it." })
          if (root.action === "relogin") items.push({ id: "relogin", label: "Log out now",
            note: "Closes your session and returns to the login screen so the setup takes effect. Save your work first." })
          if (root.action === "reinstall") items.push({ id: "reinstall", label: "Reinstall",
            note: "The evdi kernel module is missing for this kernel. Rebuilds it and restarts the service; asks for your password." })
          if (root.action === "patch") items.push({ id: "repair", label: "Repair the NVIDIA fix",
            note: "An update replaced the patched Aquamarine. Rebuilds it in a terminal and asks for your password." })
          if (root.action === "service") items.push({ id: "repair", label: "Restart the DisplayLink service",
            note: "Restarts displaylink.service in a terminal and asks for your password." })
          items.push({ id: "report", label: "Copy report",
            note: "Copies a sanitized report to the clipboard to paste into a GitHub issue. Changes nothing." })
          items.push({ id: "guide", label: "Open the guide",
            note: "Opens the README in your browser." })
          return items
        }

        ActionRow {
          width: column.width
          label: modelData.label
          note: modelData.note
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          onTriggered: modelData.id === "guide" ? root.openGuide() : root.run(modelData.id)
        }
      }

      // Reinstall and uninstall only make sense once something is installed.
      PanelSeparator { width: parent.width; foreground: root.bar.foreground; visible: root.kind !== "unconfigured" }
      PanelSectionHeader {
        width: parent.width
        visible: root.kind !== "unconfigured"
        text: "MAINTENANCE"
        foreground: root.bar.foreground
        fontFamily: root.bar.fontFamily
      }
      Repeater {
        model: {
          if (root.kind === "unconfigured") return []
          var items = []
          if (root.action !== "reinstall") items.push({ id: "reinstall", label: "Reinstall",
            note: "Rebuilds the evdi kernel module and restarts the DisplayLink service. Use it after a kernel update, or if the dock stopped working." })
          items.push({ id: "uninstall", label: "Uninstall",
            note: "Removes the driver and everything setup added. The dock screens go dark. A terminal shows each step and asks first." })
          return items
        }

        ActionRow {
          width: column.width
          label: modelData.label
          note: modelData.note
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          onTriggered: root.run(modelData.id)
        }
      }
    }
  }
}
