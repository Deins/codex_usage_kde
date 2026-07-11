import QtQuick
import QtQuick.Layouts

import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: compactRoot

    // Match the KDE CPU monitor's square pie-chart face in a panel.
    Layout.fillHeight: true
    Layout.preferredWidth: height
    Layout.minimumWidth: height
    Layout.maximumWidth: height

    CircularGauge {
        id: gauge
        anchors.fill: parent
        value: root.primaryUsed / 100
        gaugeColor: root.primaryColor
        // These are the values used by KDE's CPU pie-chart face.
        arcWidth: Kirigami.Units.smallSpacing
        trackColor: Kirigami.ColorUtils.linearInterpolation(
                        Kirigami.Theme.backgroundColor,
                        Kirigami.Theme.textColor,
                        0.1)
    }

    PlasmaComponents.Label {
        anchors.centerIn: parent
        text: {
            if (root.loading) return "…"
            if (root.errorString !== "") return "!!"
            if (!root.usageData) return "—"
            return root.primaryUsed + "%"
        }
        color: Kirigami.Theme.textColor
        font: Kirigami.Theme.defaultFont
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
