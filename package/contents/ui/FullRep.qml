import QtQuick
import QtQuick.Layouts

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

Item {
    id: full

    Layout.preferredWidth: 300
    Layout.preferredHeight: 380
    Layout.minimumWidth: 250
    Layout.minimumHeight: 300

    function fmtTimeLeft(unixTs) {
        if (!unixTs) return "—"
        var now = Math.floor(Date.now() / 1000)
        var diff = unixTs - now
        if (diff <= 0) return i18n("now")
        var h = Math.floor(diff / 3600)
        var m = Math.floor((diff % 3600) / 60)
        if (h > 0) return h + "h " + m + "m"
        return m + "m"
    }

    function fmtCredits(raw) {
        if (!raw) return "—"
        var val = parseFloat(raw)
        if (isNaN(val)) return "—"
        var rate = parseFloat(plasmoid.configuration.creditRate) || 0
        var converted = val * rate
        var sym = plasmoid.configuration.currencySymbol || "€"
        return i18n("%1  (~%2%3)", val.toFixed(1), sym, converted.toFixed(1))
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            Layout.fillWidth: true
            text: root.errorString
            color: Kirigami.Theme.negativeTextColor
            visible: root.errorString !== ""
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 120

            CircularGauge {
                id: primaryGauge
                anchors.centerIn: parent
                readonly property real gaugeSize: Math.min(parent.width, parent.height) - Kirigami.Units.gridUnit
                width: gaugeSize
                height: gaugeSize
                value: root.primaryUsed / 100
                gaugeColor: root.primaryColor
                arcWidth: Kirigami.Units.largeSpacing
                trackColor: Qt.tint(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor)

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    PlasmaComponents.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            if (root.loading) return "…"
                            if (root.errorString !== "") return "!!"
                            if (!root.usageData) return "—"
                            return root.primaryUsed + "%"
                        }
                        color: primaryGauge.gaugeColor
                        font.pixelSize: primaryGauge.height * 0.22
                        font.bold: true
                    }

                    PlasmaComponents.Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n("5-hour window")
                        color: Kirigami.Theme.disabledTextColor
                        font.pixelSize: primaryGauge.height * 0.06
                        visible: root.usageData !== null
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Kirigami.Units.smallSpacing
            rowSpacing: Math.round(Kirigami.Units.smallSpacing * 0.5)
            visible: root.usageData !== null && root.errorString === ""

            PlasmaComponents.Label {
                text: i18n("5-hour:")
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    Rectangle {
                        id: barPrimaryTrack
                        anchors.fill: parent
                        height: 6
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.12)
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: barPrimaryTrack.width * (root.primaryUsed / 100)
                        radius: 3
                        color: root.primaryColor
                    }
                }
                PlasmaComponents.Label {
                    text: root.primaryUsed + "%"
                    color: root.primaryColor
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.bold: true
                }
            }

            PlasmaComponents.Label {
                text: i18n("Weekly:")
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    Rectangle {
                        id: barSecondaryTrack
                        anchors.fill: parent
                        height: 6
                        radius: 3
                        color: Qt.rgba(1, 1, 1, 0.12)
                    }
                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: barSecondaryTrack.width * (root.secondaryUsed / 100)
                        radius: 3
                        color: root.secondaryColor
                    }
                }
                PlasmaComponents.Label {
                    text: root.secondaryUsed + "%"
                    color: root.secondaryColor
                    font.pointSize: Kirigami.Theme.smallFont.pointSize
                    font.bold: true
                }
            }

            PlasmaComponents.Label {
                text: i18n("5h resets in:")
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.usageData ? fmtTimeLeft(root.usageData.primary_resets_at) : ""
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }

            PlasmaComponents.Label {
                text: i18n("Weekly resets in:")
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.usageData ? fmtTimeLeft(root.usageData.secondary_resets_at) : ""
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }

            PlasmaComponents.Label {
                text: i18n("Credits:")
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                visible: root.usageData && root.usageData.credits_balance !== undefined
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.usageData ? fmtCredits(root.usageData.credits_balance) : ""
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                visible: root.usageData && root.usageData.credits_balance !== undefined
            }

            PlasmaComponents.Label {
                text: i18n("Plan:")
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.planType
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                font.capitalization: Font.Capitalize
            }
        }
    }
}
