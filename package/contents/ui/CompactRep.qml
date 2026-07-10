import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    // Match KDE system monitor: square, fills panel height
    Layout.fillHeight: true
    Layout.preferredWidth: height
    Layout.minimumWidth: height
    Layout.maximumWidth: height

    CircularGauge {
        id: gauge
        anchors.fill: parent
        anchors.margins: 1
        value: root.primaryUsed / 100
        gaugeColor: root.primaryColor
        // Thin ring like KDE system monitor (Kirigami.Units.smallSpacing)
        arcWidth: Math.round(Math.min(width, height) / 10)
        // Track color: linearInterpolation(backgroundColor, textColor, 0.1) — same as KDE
        trackColor: Qt.tint(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor)
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        text: {
            if (root.loading) return "…"
            if (root.errorString !== "") return "!!"
            if (!root.usageData) return "—"
            return root.primaryUsed + "%"
        }
        color: root.primaryColor
        font.pixelSize: Math.min(gauge.width, gauge.height) * 0.3
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        fontSizeMode: Text.HorizontalFit
        minimumPointSize: Kirigami.Theme.smallFont.pointSize * 0.8
    }

    MouseArea {
        anchors.fill: compactRoot
        onClicked: root.expanded = !root.expanded
    }
}
