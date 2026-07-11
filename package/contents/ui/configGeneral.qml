import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.components as PlasmaComponents

KCM.SimpleKCM {
    property alias cfg_refreshInterval: intervalSpin.value
    property alias cfg_codexBinaryPath: codexPathField.text
    property alias cfg_creditRate: creditRateField.text
    property alias cfg_currencySymbol: currencyField.text

    Kirigami.FormLayout {
        PlasmaComponents.SpinBox {
            id: intervalSpin
            from: 120
            to: 3600
            stepSize: 60
            Kirigami.FormData.label: i18n("Refresh interval (seconds):")
        }

        PlasmaComponents.TextField {
            id: codexPathField
            Kirigami.FormData.label: i18n("Codex binary path:")
            placeholderText: i18n("auto-detect (leave empty)")
        }

        PlasmaComponents.Label {
            Kirigami.FormData.label: ""
            text: i18n("Full path to the codex executable. Leave empty to auto-detect from PATH.")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        Kirigami.Separator {
            Kirigami.FormData.label: ""
            Kirigami.FormData.isSection: true
        }

        PlasmaComponents.TextField {
            id: creditRateField
            Kirigami.FormData.label: i18n("Credit rate:")
            placeholderText: "0.04"
            validator: DoubleValidator { bottom: 0; top: 1000; decimals: 4; notation: DoubleValidator.StandardNotation }
        }

        PlasmaComponents.Label {
            Kirigami.FormData.label: ""
            text: i18n("Conversion rate: 1 credit = N in your currency. Default: 0.04 (500 credits ≈ €20).")
            font.pointSize: Kirigami.Theme.smallFont.pointSize
            color: Kirigami.Theme.disabledTextColor
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        PlasmaComponents.TextField {
            id: currencyField
            Kirigami.FormData.label: i18n("Currency symbol:")
            placeholderText: "€"
        }
    }
}
