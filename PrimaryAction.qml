// The one thing to do now: an accent-filled button with an icon, and under it a line saying what it will do.
// A card shows at most one of these; everything else is quiet (see QuietButton.qml).
import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Column {
  id: row

  property string label: ""
  property string icon: ""
  property string note: ""
  property color foreground: Commons.Color.foreground
  property string fontFamily: Style.font.family
  signal triggered()

  spacing: Style.space(6)

  // Filled with the theme's accent, the only filled thing on the card. The label takes whichever of the
  // theme's dark or light colour reads better on that accent.
  Rectangle {
    id: fill
    width: parent.width
    height: Style.space(44)
    radius: Style.cornerRadius
    readonly property color accent: Commons.Color.accent
    readonly property real luminance: 0.299 * accent.r + 0.587 * accent.g + 0.114 * accent.b
    readonly property color onAccent: luminance > 0.55 ? Commons.Color.background : Commons.Color.foreground
    color: mouse.pressed ? Qt.darker(accent, 1.15) : mouse.containsMouse ? Qt.lighter(accent, 1.12) : accent
    Behavior on color { ColorAnimation { duration: Style.duration(120) } }

    Row {
      anchors.centerIn: parent
      spacing: Style.space(8)

      Text {
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: row.icon
        color: fill.onAccent
        font.family: row.fontFamily
        font.pixelSize: Style.font.body + 2
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: row.label
        color: fill.onAccent
        font.family: row.fontFamily
        font.pixelSize: Style.font.body
        font.bold: true
      }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: row.triggered()
    }
  }
  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: row.note
    color: Qt.darker(row.foreground, 1.4)
    font.family: row.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
