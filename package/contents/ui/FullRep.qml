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
        var d = Math.floor(diff / 86400)
        var h = Math.floor((diff % 86400) / 3600)
        var m = Math.floor((diff % 3600) / 60)
        if (d > 0) return d + "d " + h + "h"
        if (h > 0) return h + "h " + m + "m"
        return Math.max(1, m) + "m"
    }

    function windowName(minutes) {
        if (minutes === 10080) return i18n("Weekly")
        if (minutes >= 60 && minutes % 60 === 0) return i18n("%1-hour", minutes / 60)
        return i18n("%1-minute", minutes)
    }

    function remainingPerDay() {
        if (!root.usageData) return "—"
        var resetsAt = null
        var used = 0
        if (root.usageData.secondary_window_minutes >= 1440) {
            resetsAt = root.usageData.secondary_resets_at
            used = root.secondaryUsed
        } else if (root.usageData.primary_window_minutes >= 1440) {
            resetsAt = root.usageData.primary_resets_at
            used = root.primaryUsed
        }
        if (!resetsAt) return "—"
        var daysLeft = (resetsAt - Date.now() / 1000) / 86400
        if (daysLeft <= 0) return "—"
        return i18n("%1% / day", ((100 - used) / daysLeft).toFixed(1))
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
                trackColor: Kirigami.ColorUtils.linearInterpolation(
                                Kirigami.Theme.backgroundColor,
                                Kirigami.Theme.textColor,
                                0.1)

                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -primaryGauge.height * 0.015
                    spacing: primaryGauge.height * 0.025

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0

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
                            text: root.usageData
                                  ? i18n("%1 usage", windowName(root.usageData.primary_window_minutes))
                                  : ""
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: primaryGauge.height * 0.06
                            visible: root.usageData !== null
                        }
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.usageData !== null
                        spacing: 0

                        PlasmaComponents.Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: remainingPerDay()
                            color: Kirigami.Theme.textColor
                            font.pixelSize: primaryGauge.height * 0.09
                            font.bold: true
                        }

                        PlasmaComponents.Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: i18n("Remaining allowance")
                            color: Kirigami.Theme.disabledTextColor
                            font.pixelSize: primaryGauge.height * 0.05
                        }
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
                text: root.usageData
                      ? i18n("%1 usage:", windowName(root.usageData.primary_window_minutes))
                      : ""
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
                        color: Kirigami.ColorUtils.linearInterpolation(
                                   Kirigami.Theme.backgroundColor,
                                   Kirigami.Theme.textColor,
                                   0.1)
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
                text: root.usageData
                      ? i18n("%1 usage:", windowName(root.usageData.secondary_window_minutes))
                      : ""
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                visible: root.usageData && root.usageData.secondary_window_minutes > 0
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing
                visible: root.usageData && root.usageData.secondary_window_minutes > 0
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 6
                    Rectangle {
                        id: barSecondaryTrack
                        anchors.fill: parent
                        height: 6
                        radius: 3
                        color: Kirigami.ColorUtils.linearInterpolation(
                                   Kirigami.Theme.backgroundColor,
                                   Kirigami.Theme.textColor,
                                   0.1)
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
                text: root.usageData
                      ? i18n("%1 resets in:", windowName(root.usageData.primary_window_minutes))
                      : ""
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.usageData ? fmtTimeLeft(root.usageData.primary_resets_at) : ""
                font.pointSize: Kirigami.Theme.smallFont.pointSize
            }

            PlasmaComponents.Label {
                text: root.usageData
                      ? i18n("%1 resets in:", windowName(root.usageData.secondary_window_minutes))
                      : ""
                color: Kirigami.Theme.disabledTextColor
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                visible: root.usageData && root.usageData.secondary_window_minutes > 0
            }
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: root.usageData ? fmtTimeLeft(root.usageData.secondary_resets_at) : ""
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                visible: root.usageData && root.usageData.secondary_window_minutes > 0
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
