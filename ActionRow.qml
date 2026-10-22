// One action on the card: a button, and under it a line that says what pressing it will do.
import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Column {
  id: row

  property string label: ""
  property string note: ""
  property color foreground: Commons.Color.foreground
  property string fontFamily: Style.font.family
  signal triggered()

  spacing: Style.space(2)

  Button {
    width: parent.width
    text: row.label
    foreground: row.foreground
    fontFamily: row.fontFamily
    bordered: true
    onClicked: row.triggered()
  }
  Text {
    width: parent.width
    textFormat: Text.PlainText
    text: row.note
    color: Qt.darker(row.foreground, 1.5)
    font.family: row.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
