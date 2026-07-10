import QtQuick
import QtQuick.Shapes

Shape {
    id: gauge

    property real value: 0.0
    property color gaugeColor: "#1d99f3"
    property real arcWidth: 12
    property color trackColor: Qt.rgba(1, 1, 1, 0.12)

    readonly property real startAngleRad: -Math.PI / 2
    readonly property real sweepRad: Math.PI * 2
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real radius: (Math.min(width, height) - arcWidth) / 2

    // Force smooth rendering via offscreen layer with 4x MSAA
    layer.enabled: true
    layer.samples: 4

    function arcPath(fromFraction, toFraction) {
        if (toFraction <= 0 || toFraction <= fromFraction) return ""
        var r = radius
        if (r <= 0) return ""
        var toF = Math.min(toFraction, 1)
        var fromA = startAngleRad + sweepRad * fromFraction
        var toA = startAngleRad + sweepRad * toF
        var x0 = cx + r * Math.cos(fromA)
        var y0 = cy + r * Math.sin(fromA)
        var x1 = cx + r * Math.cos(toA)
        var y1 = cy + r * Math.sin(toA)
        var delta = toA - fromA
        var largeArc = Math.abs(delta) > Math.PI ? 1 : 0
        return "M " + x0 + " " + y0 +
               " A " + r + " " + r +
               " 0 " + largeArc + " 1 " +
               x1 + " " + y1
    }

    function fullCirclePath() {
        var r = radius
        if (r <= 0) return ""
        return "M " + (cx - r) + " " + cy +
               " A " + r + " " + r +
               " 0 1 1 " + (cx + r) + " " + cy +
               " A " + r + " " + r +
               " 0 1 1 " + (cx - r) + " " + cy
    }

    ShapePath {
        strokeColor: gauge.trackColor
        strokeWidth: gauge.arcWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg { path: gauge.fullCirclePath() }
    }

    ShapePath {
        strokeColor: gauge.gaugeColor
        strokeWidth: gauge.arcWidth
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        PathSvg {
            path: {
                var v = Math.max(0, Math.min(1, gauge.value))
                if (v >= 1) return gauge.fullCirclePath()
                return gauge.arcPath(0, v)
            }
        }
    }
}
