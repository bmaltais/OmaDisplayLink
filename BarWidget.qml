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
  property string message: "DisplayLink is not set up yet."
  // What would help, or "": setup, relogin, reinstall, patch (rebuild the NVIDIA fix) or service (restart displaylink.service).
  // Starts as setup: until the service has written the status file this is a first run, and setup is the one thing to do.
  property string action: "setup"
  property bool popupOpen: false

  readonly property color markColor: kind === "attention" ? Commons.Color.urgent
    : kind === "ok" || kind === "pending" ? Commons.Color.accent
    : (root.bar ? root.bar.barForeground : Commons.Color.foreground)
  readonly property real markOpacity: kind === "idle" || kind === "updating" ? 0.6 : kind === "unconfigured" ? 0.4 : 1.0

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
      root.kind = ["unconfigured", "pending", "idle", "ok", "attention", "updating"].indexOf(k) >= 0 ? k : "unconfigured"
      root.message = (lines[1] || "").trim() || root.message
      root.action = (lines[2] || "").trim()
    }
    onLoadFailed: { root.kind = "unconfigured"; root.action = "setup" }
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
          // BarIconButton.iconSize only exists on newer shells; the bar tokens exist on all.
          iconSize: Math.min(Style.bar.iconCanvas, Style.bar.iconSize || Style.bar.iconCanvas)
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

  // Font Awesome glyphs from the Nerd Font the bar already uses.
  readonly property var icons: ({
    setup: "\uf019",     // download
    relogin: "\uf08b",   // sign out
    reinstall: "\uf021", // refresh
    repair: "\uf0ad",    // wrench
    report: "\uf0ea",    // clipboard
    guide: "\uf02d",     // book
    uninstall: "\uf1f8"  // trash
  })
  readonly property var stateLabels: ({
    unconfigured: "NOT INSTALLED",
    pending: "LOG OUT TO FINISH",
    idle: "NO DOCK PLUGGED IN",
    ok: "WORKING",
    attention: "NEEDS ATTENTION",
    updating: "UPDATE IN PROGRESS"
  })

  // The one filled action for the state, or null when nothing needs doing.
  readonly property var primary: {
    if (action === "setup") return { id: "setup", label: "Set up DisplayLink", icon: icons.setup,
      note: "Walks through the install step by step in a terminal. Asks before it changes anything, and for your password where a step needs it." }
    if (action === "relogin") return { id: "relogin", label: "Log out now", icon: icons.relogin,
      note: "Closes your session and returns to the login screen so the setup takes effect. Save your work first." }
    if (action === "reinstall") return { id: "reinstall", label: "Reinstall", icon: icons.reinstall,
      note: "The evdi kernel module is missing for this kernel. Rebuilds it and restarts the service; asks for your password." }
    if (action === "patch") return { id: "repair", label: "Repair the NVIDIA fix", icon: icons.repair,
      note: "An update replaced the patched Aquamarine. Rebuilds it in a terminal and asks for your password." }
    if (action === "service") return { id: "repair", label: "Restart the DisplayLink service", icon: icons.repair,
      note: "Restarts displaylink.service in a terminal and asks for your password." }
    return null
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(340))
    contentHeight: popup.fittedContentHeight(column.implicitHeight)

    Column {
      id: column
      anchors.fill: parent
      spacing: Style.space(12)

      // Status first: a band tinted with the state colour says at a glance whether the dock is fine.
      Rectangle {
        width: parent.width
        implicitHeight: band.implicitHeight + Style.space(24)
        height: implicitHeight
        radius: Style.cornerRadius
        color: Util.alpha(root.markColor, 0.10)
        border.width: 1
        border.color: Util.alpha(root.markColor, 0.35)

        Column {
          id: band
          x: Style.space(12)
          y: Style.space(12)
          width: parent.width - Style.space(24)
          spacing: Style.space(8)

          PanelHero {
            width: parent.width
            title: "DisplayLink"
            meta: root.stateLabels[root.kind]
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            iconComponent: Component {
              DisplayLinkMark {
                iconSize: Style.space(38)
                color: root.markColor
                linked: root.kind === "ok" || root.kind === "attention"
              }
            }
          }
          Text {
            width: parent.width
            textFormat: Text.PlainText
            text: root.message
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
            wrapMode: Text.WordWrap
          }
        }
      }

      // The one thing to do now. Not shown when everything is fine.
      PrimaryAction {
        visible: root.primary !== null
        width: parent.width
        label: root.primary ? root.primary.label : ""
        icon: root.primary ? root.primary.icon : ""
        note: root.primary ? root.primary.note : ""
        foreground: root.bar.foreground
        fontFamily: root.bar.fontFamily
        onTriggered: root.run(root.primary.id)
      }

      Row {
        width: parent.width
        spacing: Style.space(8)

        QuietButton {
          width: (parent.width - parent.spacing) / 2
          text: "Copy report"
          iconText: root.icons.report
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          tooltipText: "Copies a sanitized report to the clipboard, to paste into a GitHub issue. Changes nothing."
          onClicked: root.run("report")
        }
        QuietButton {
          width: (parent.width - parent.spacing) / 2
          text: "Guide"
          iconText: root.icons.guide
          foreground: root.bar.foreground
          fontFamily: root.bar.fontFamily
          tooltipText: "Opens the README in your browser."
          onClicked: root.openGuide()
        }
      }

      // Reinstall and uninstall only make sense once something is installed, and are never the loudest thing.
      Column {
        width: parent.width
        spacing: Style.space(8)
        visible: root.kind !== "unconfigured"

        PanelSeparator { width: parent.width; foreground: root.bar.foreground }

        Item {
          width: parent.width
          height: Math.max(maintenanceLabel.implicitHeight, maintenanceButtons.implicitHeight)

          PanelSectionHeader {
            id: maintenanceLabel
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: "MAINTENANCE"
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
          }
          Row {
            id: maintenanceButtons
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Style.space(4)

            QuietButton {
              visible: root.action !== "reinstall"
              text: "Reinstall"
              iconText: root.icons.reinstall
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              tooltipText: "Rebuilds the evdi kernel module and restarts the DisplayLink service. Use it after a kernel update, or if the dock stopped working."
              onClicked: root.run("reinstall")
            }
            QuietButton {
              danger: true
              text: "Uninstall"
              iconText: root.icons.uninstall
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              tooltipText: "Removes the driver and everything setup added. The dock screens go dark. A terminal shows each step and asks first."
              onClicked: root.run("uninstall")
            }
          }
        }
      }
    }
  }
}
