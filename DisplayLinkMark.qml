// The plugin's mark: a rounded "D" for DisplayLink with a pixel inside it. Drawn here from scratch as a
// vector shape; it is not DisplayLink's logo, which belongs to Synaptics and is licensed to certified
// partners only. The pixel is the state: present while a dock is plugged in, absent when it is not.
import QtQuick
import QtQuick.Shapes
import qs.Commons
import qs.Commons as Commons

Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Commons.Color.foreground
  // The pixel inside the D: a dock is attached.
  property bool linked: false

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  Shape {
    anchors.fill: parent
    antialiasing: true
    layer.enabled: true
    layer.samples: 4

    // The D: a stem and a half-circle bowl, one stroke. Everything is a fraction of the icon so it
    // scales with the bar.
    ShapePath {
      strokeColor: root.color
      strokeWidth: Math.max(1.5, root.height * 0.13)
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin
      startX: root.width * 0.16
      startY: root.height * 0.10
      PathLine { x: root.width * 0.46; y: root.height * 0.10 }
      PathArc {
        x: root.width * 0.46
        y: root.height * 0.90
        radiusX: root.height * 0.40
        radiusY: root.height * 0.40
        direction: PathArc.Clockwise
      }
      PathLine { x: root.width * 0.16; y: root.height * 0.90 }
      PathLine { x: root.width * 0.16; y: root.height * 0.10 }
    }

    // The pixel.
    ShapePath {
      strokeWidth: 0
      fillColor: root.linked ? root.color : "transparent"
      startX: root.width * 0.34
      startY: root.height * 0.38
      PathLine { x: root.width * 0.54; y: root.height * 0.38 }
      PathLine { x: root.width * 0.54; y: root.height * 0.62 }
      PathLine { x: root.width * 0.34; y: root.height * 0.62 }
      PathLine { x: root.width * 0.34; y: root.height * 0.38 }
    }
  }
}
