// A low-emphasis action: no fill at rest, a small icon and a caption-size label. The long explanation lives
// in the tooltip. `danger` turns the hover tint red, so a destructive action is quiet until you reach for it.
import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Button {
  id: root

  property bool danger: false

  fontSize: Style.font.caption
  iconSize: Style.font.caption + 1
  accent: danger ? Commons.Color.urgent : Commons.Color.accent
  bordered: false
  verticalPadding: Style.space(6)
}
